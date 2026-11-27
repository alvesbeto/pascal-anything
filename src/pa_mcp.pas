unit pa_mcp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, pa_util, pa_cmds;

function CmdMcp: Integer;

implementation

const
  ProtocolVersion = '2025-06-18';

procedure WriteLine(const S: string);
begin
  WriteLn(S);
  Flush(Output);
end;

function OkResult(Id: TJSONData; ResultObj: TJSONData): string;
var
  Resp: TJSONObject;
begin
  Resp := TJSONObject.Create;
  try
    Resp.Add('jsonrpc', '2.0');
    if Id <> nil then
      Resp.Add('id', Id.Clone);
    Resp.Add('result', ResultObj);
    Result := Resp.AsJSON;
  finally
    Resp.Free;
  end;
end;

function ErrResult(Id: TJSONData; Code: Integer; const Msg: string): string;
var
  Resp, Err: TJSONObject;
begin
  Resp := TJSONObject.Create;
  Err := TJSONObject.Create;
  try
    Resp.Add('jsonrpc', '2.0');
    if Id <> nil then
      Resp.Add('id', Id.Clone)
    else
      Resp.Add('id', TJSONNull.Create);
    Err.Add('code', Code);
    Err.Add('message', Msg);
    Resp.Add('error', Err);
    Result := Resp.AsJSON;
  finally
    Resp.Free;
  end;
end;

function ToolDef(const Name, Desc: string; Schema: TJSONObject): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('name', Name);
  Result.Add('description', Desc);
  Result.Add('inputSchema', Schema);
end;

function StringProp(Schema: TJSONObject; const Name, Desc: string; Required: Boolean): TJSONObject;
var
  Props, Prop: TJSONObject;
  Req: TJSONArray;
begin
  Props := TJSONObject(Schema.Find('properties'));
  if Props = nil then
  begin
    Props := TJSONObject.Create;
    Schema.Add('properties', Props);
  end;
  Prop := TJSONObject.Create;
  Prop.Add('type', 'string');
  Prop.Add('description', Desc);
  Props.Add(Name, Prop);
  if Required then
  begin
    Req := TJSONArray(Schema.Find('required'));
    if Req = nil then
    begin
      Req := TJSONArray.Create;
      Schema.Add('required', Req);
    end;
    Req.Add(Name);
  end;
  Result := Schema;
end;

function EmptySchema: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('type', 'object');
  Result.Add('properties', TJSONObject.Create);
end;

function CrateSchema: TJSONObject;
begin
  Result := EmptySchema;
  StringProp(Result, 'crate', 'Bridge crate folder', True);
end;

function ToolsList: TJSONArray;
var
  S: TJSONObject;
begin
  Result := TJSONArray.Create;
  S := EmptySchema;
  StringProp(S, 'root', 'Repository root', False);
  Result.Add(ToolDef('analyze', 'Map a repository for Pascal/Lazarus migration', S));

  S := EmptySchema;
  StringProp(S, 'root', 'Repository root', True);
  StringProp(S, 'unit', 'Unit path from analyze', True);
  Result.Add(ToolDef('bridge', 'Scaffold FPC package for one unit', S));

  S := EmptySchema;
  StringProp(S, 'crate', 'Bridge crate folder', True);
  StringProp(S, 'inputs', 'Optional JSONL of cases', False);
  Result.Add(ToolDef('record', 'Record original behavior into cases.jsonl', S));

  Result.Add(ToolDef('build', 'Compile harness with fpc', CrateSchema));
  Result.Add(ToolDef('diff', 'Replay cases against Pascal harness', CrateSchema));
  Result.Add(ToolDef('gate', 'Definition of done for one port', CrateSchema));
  Result.Add(ToolDef('doctor', 'Check toolchains', EmptySchema));
  Result.Add(ToolDef('rules', 'Porting rules', EmptySchema));
end;

function TextContent(const Text: string; IsError: Boolean): TJSONObject;
var
  Arr: TJSONArray;
  Item: TJSONObject;
begin
  Result := TJSONObject.Create;
  Arr := TJSONArray.Create;
  Item := TJSONObject.Create;
  Item.Add('type', 'text');
  Item.Add('text', Text);
  Arr.Add(Item);
  Result.Add('content', Arr);
  Result.Add('isError', IsError);
end;

function ArgStr(Args: TJSONObject; const Key, DefaultVal: string): string;
var
  D: TJSONData;
begin
  if Args = nil then
    Exit(DefaultVal);
  D := Args.Find(Key);
  if D = nil then
    Result := DefaultVal
  else
    Result := D.AsString;
end;

function CallTool(const Name: string; Args: TJSONObject): TJSONObject;
var
  Code: Integer;
  Root, UnitId, Crate, Inputs, OutText: string;
begin
  Root := ArgStr(Args, 'root', '.');
  UnitId := ArgStr(Args, 'unit', '');
  Crate := ArgStr(Args, 'crate', '.');
  Inputs := ArgStr(Args, 'inputs', '');

  if (Name = 'bridge') and ((ArgStr(Args, 'root', '') = '') or (UnitId = '')) then
    Exit(TextContent('root and unit required', True));
  if Name = '' then
    Exit(TextContent('unknown tool', True));

  Code := 1;
  BeginCapture;
  try
    case Name of
      'doctor': Code := CmdDoctor;
      'rules': Code := CmdRules;
      'analyze': Code := CmdAnalyze(Root, False, False, '', '');
      'bridge': Code := CmdBridge(ArgStr(Args, 'root', ''), UnitId, '', '', False);
      'record': Code := CmdRecord(Crate, 50, Inputs);
      'build': Code := CmdBuild(Crate);
      'diff': Code := CmdDiff(Crate);
      'gate': Code := CmdGate(Crate);
    else
      Code := 1;
      Say('unknown tool: ' + Name);
    end;
  finally
    OutText := EndCapture;
  end;
  if Code = 0 then
    Result := TextContent(OutText, False)
  else
    Result := TextContent(OutText + LineEnding + Name + ' failed (exit ' +
      IntToStr(Code) + ')', True);
end;

function Handle(Request: TJSONObject): string;
var
  Method: string;
  Id: TJSONData;
  Params, ResultObj, Caps, Tools, ServerInfo: TJSONObject;
  Arr: TJSONArray;
  Name: string;
  Args: TJSONObject;
begin
  Result := '';
  Method := '';
  if Request.Find('method') <> nil then
    Method := Request.Strings['method'];
  Id := Request.Find('id');

  if Method = 'initialize' then
  begin
    ResultObj := TJSONObject.Create;
    Caps := TJSONObject.Create;
    Tools := TJSONObject.Create;
    ServerInfo := TJSONObject.Create;
    Caps.Add('tools', Tools);
    ServerInfo.Add('name', AppName);
    ServerInfo.Add('version', AppVersion);
    ResultObj.Add('protocolVersion', ProtocolVersion);
    ResultObj.Add('capabilities', Caps);
    ResultObj.Add('serverInfo', ServerInfo);
    Exit(OkResult(Id, ResultObj));
  end;

  if Method = 'notifications/initialized' then
    Exit('');

  if Method = 'ping' then
    Exit(OkResult(Id, TJSONObject.Create));

  if Method = 'tools/list' then
  begin
    ResultObj := TJSONObject.Create;
    Arr := ToolsList;
    ResultObj.Add('tools', Arr);
    Exit(OkResult(Id, ResultObj));
  end;

  if Method = 'tools/call' then
  begin
    Params := TJSONObject(Request.Find('params'));
    if Params = nil then
      Exit(ErrResult(Id, -32602, 'missing params'));
    Name := '';
    if Params.Find('name') <> nil then
      Name := Params.Strings['name'];
    Args := nil;
    if Params.Find('arguments') is TJSONObject then
      Args := TJSONObject(Params.Find('arguments'));
    Exit(OkResult(Id, CallTool(Name, Args)));
  end;

  if Method = 'prompts/list' then
  begin
    ResultObj := TJSONObject.Create;
    Arr := TJSONArray.Create;
    ResultObj.Add('prompts', Arr);
    Exit(OkResult(Id, ResultObj));
  end;

  if Id <> nil then
    Result := ErrResult(Id, -32601, 'method not found: ' + Method);
end;

function CmdMcp: Integer;
var
  Line, Resp: string;
  Data: TJSONData;
  Req: TJSONObject;
begin
  while not EOF(Input) do
  begin
    ReadLn(Line);
    if Trim(Line) = '' then
      Continue;
    try
      Data := GetJSON(Line);
    except
      on E: Exception do
      begin
        WriteLine(ErrResult(nil, -32700, 'parse error: ' + E.Message));
        Continue;
      end;
    end;
    try
      if not (Data is TJSONObject) then
      begin
        WriteLine(ErrResult(nil, -32600, 'request must be object'));
        Continue;
      end;
      Req := TJSONObject(Data);
      Resp := Handle(Req);
      if Resp <> '' then
        WriteLine(Resp);
    finally
      Data.Free;
    end;
  end;
  Result := 0;
end;

end.
