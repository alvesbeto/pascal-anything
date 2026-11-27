program pascalanything;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, pa_util, pa_cmds, pa_mcp;

function HasFlag(const Flag: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if ParamStr(I) = Flag then
      Exit(True);
end;

function OptValue(const Flag: string; const DefaultVal: string = ''): string;
var
  I: Integer;
begin
  Result := DefaultVal;
  for I := 1 to ParamCount - 1 do
    if ParamStr(I) = Flag then
      Exit(ParamStr(I + 1));
end;

function CollectAfterDashDash: TStringList;
var
  I: Integer;
  Seen: Boolean;
begin
  Result := TStringList.Create;
  Seen := False;
  for I := 1 to ParamCount do
  begin
    if Seen then
      Result.Add(ParamStr(I))
    else if ParamStr(I) = '--' then
      Seen := True;
  end;
end;

function NextPositional(var Idx: Integer): string;
var
  S: string;
begin
  Result := '';
  while Idx <= ParamCount do
  begin
    S := ParamStr(Idx);
    Inc(Idx);
    if S = '--' then
    begin
      Result := '';
      Exit;
    end;
    if (S = '--json') or (S = '--whole-app') or (S = '--force') then
      Continue;
    if (S = '--lang') or (S = '-o') or (S = '--out') or (S = '--name') or
       (S = '--count') or (S = '--inputs') then
    begin
      Inc(Idx); { skip value }
      Continue;
    end;
    if (Length(S) > 0) and (S[1] = '-') then
      Continue;
    Exit(S);
  end;
end;

var
  Cmd: string;
  Idx: Integer;
  Root, UnitId, OutDir, Name, Lang, OutFile, Inputs: string;
  Count: Integer;
  Workload: TStringList;
  Code: Integer;
  RepoRoot: string;
begin
  if ParamCount < 1 then
  begin
    Halt(CmdHelp);
  end;

  Cmd := LowerCase(ParamStr(1));
  Idx := 2;
  RepoRoot := AbsolutePath(PathJoin(ExtractFilePath(ParamStr(0)), '..'));
  if not DirectoryExists(PathJoin(RepoRoot, 'skills')) then
    RepoRoot := GetCurrentDir;

  case Cmd of
    'help', '-h', '--help':
      Code := CmdHelp;
    'version', '-V', '--version':
      Code := CmdVersion;
    'doctor':
      Code := CmdDoctor;
    'rules':
      Code := CmdRules;
    'setup':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := RepoRoot;
        Code := CmdSetup(AbsolutePath(Root));
      end;
    'analyze':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Lang := OptValue('--lang', '');
        OutFile := OptValue('-o', OptValue('--out', ''));
        Code := CmdAnalyze(Root, HasFlag('--json'), HasFlag('--whole-app'),
          OutFile, Lang);
      end;
    'bridge':
      begin
        Root := NextPositional(Idx);
        UnitId := NextPositional(Idx);
        if (Root = '') or (UnitId = '') then
        begin
          SayErr('uso: pascal-anything bridge <root> <unit>');
          Code := 2;
        end
        else
        begin
          OutDir := OptValue('--out', '');
          Name := OptValue('--name', '');
          Code := CmdBridge(Root, UnitId, OutDir, Name, HasFlag('--force'));
        end;
      end;
    'record':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Count := StrToIntDef(OptValue('--count', '200'), 200);
        Inputs := OptValue('--inputs', '');
        Code := CmdRecord(Root, Count, Inputs);
      end;
    'build':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Code := CmdBuild(Root);
      end;
    'diff':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Code := CmdDiff(Root);
      end;
    'gate':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Code := CmdGate(Root);
      end;
    'go':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Workload := CollectAfterDashDash;
        try
          Code := CmdGo(Root, Workload);
        finally
          Workload.Free;
        end;
      end;
    'enable':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Code := CmdEnable(Root, True);
      end;
    'disable':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Code := CmdEnable(Root, False);
      end;
    'report':
      begin
        Root := NextPositional(Idx);
        if Root = '' then
          Root := '.';
        Code := CmdReport(Root);
      end;
    'mcp':
      Code := CmdMcp;
  else
    SayErr('comando desconhecido: ' + Cmd);
    Code := CmdHelp;
    if Code = 0 then
      Code := 2;
  end;

  Halt(Code);
end.
