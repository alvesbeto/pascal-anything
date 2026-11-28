unit pa_cmds;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, pa_util;

function CmdDoctor: Integer;
function CmdSetup(const ARoot: string): Integer;
function CmdAnalyze(const ARoot: string; AsJson, WholeApp: Boolean;
  const OutFile, LangOverride: string): Integer;
function CmdBridge(const ARoot, AUnit, OutDir, PkgName: string;
  Force: Boolean; const EndState: string = 'replace'): Integer;
function CmdRecord(const ACrate: string; Count: Integer;
  const InputsFile: string): Integer;
function CmdBuild(const ACrate: string): Integer;
function CmdDiff(const ACrate: string): Integer;
function CmdGate(const ACrate: string): Integer;
function CmdGo(const ARoot: string; const Workload: TStringList): Integer;
function CmdReport(const ACrate: string): Integer;
function CmdEnable(const ACrate: string; Enable: Boolean): Integer;
function CmdRules: Integer;
function CmdVersion: Integer;
function CmdHelp: Integer;

implementation

type
  TCheck = record
    Name: string;
    Passed: Boolean;
    Detail: string;
    Fix: string;
  end;

function LoadManifest(const ACrate: string; out Obj: TJSONObject): Boolean;
var
  Path, Raw: string;
  Data: TJSONData;
begin
  Result := False;
  Obj := nil;
  Path := PathJoin(ACrate, ManifestFileName);
  if not FileExists(Path) then
    Exit;
  Raw := ReadTextFile(Path);
  Data := GetJSON(Raw);
  if not (Data is TJSONObject) then
  begin
    Data.Free;
    Exit;
  end;
  Obj := TJSONObject(Data);
  Result := True;
end;

function WriteManifest(const ACrate: string; Obj: TJSONObject): Boolean;
begin
  WriteTextFile(PathJoin(ACrate, ManifestFileName), Obj.FormatJSON);
  Result := True;
end;

function JsonStr(Obj: TJSONObject; const Key, DefaultVal: string): string;
var
  D: TJSONData;
begin
  D := Obj.Find(Key);
  if D = nil then
    Result := DefaultVal
  else
    Result := D.AsString;
end;

function JsonBool(Obj: TJSONObject; const Key: string; DefaultVal: Boolean): Boolean;
var
  D: TJSONData;
begin
  D := Obj.Find(Key);
  if D = nil then
    Result := DefaultVal
  else
    Result := D.AsBoolean;
end;

function JsonInt(Obj: TJSONObject; const Key: string; DefaultVal: Integer): Integer;
var
  D: TJSONData;
begin
  D := Obj.Find(Key);
  if D = nil then
    Result := DefaultVal
  else
    Result := D.AsInteger;
end;

function MarkdownCell(const S: string): string;
begin
  Result := StringReplace(StringReplace(S, '`', '''', [rfReplaceAll]), '|', '\|', [rfReplaceAll]);
end;

function EndStateDescription(const State: string): string;
begin
  case LowerCase(State) of
    'replace': Result := 'replace: delete the original once callers use the Pascal';
    'bindings': Result := 'bindings: the bindings stay as public API: version and document them';
    'scaffold': Result := 'scaffold: delete the bindings at cut-over';
  else
    Result := 'not chosen';
  end;
end;

procedure FindAllFiles(List: TStringList; const ADir: string; Recursive: Boolean);
var
  Info: TSearchRec;
  Sub: string;
begin
  if FindFirst(PathJoin(ADir, '*'), faAnyFile, Info) = 0 then
  try
    repeat
      if (Info.Name = '.') or (Info.Name = '..') then
        Continue;
      Sub := PathJoin(ADir, Info.Name);
      if (Info.Attr and faDirectory) <> 0 then
      begin
        if Recursive then
          FindAllFiles(List, Sub, True);
      end
      else
        List.Add(Sub);
    until FindNext(Info) <> 0;
  finally
    FindClose(Info);
  end;
end;

function ListSourceFiles(const ARoot: string; Exts: TStringList): TStringList;
var
  All: TStringList;
  I: Integer;
  Ext: string;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;
  All := TStringList.Create;
  try
    FindAllFiles(All, ARoot, True);
    for I := 0 to All.Count - 1 do
    begin
      if PathHasSegment(All[I], '.git') or
         PathHasSegment(All[I], 'node_modules') or
         PathHasSegment(All[I], 'vendor') or
         PathHasSegment(All[I], 'pascal') then
        Continue;
      Ext := LowerCase(ExtractFileExt(All[I]));
      if Exts.IndexOf(Ext) >= 0 then
        Result.Add(All[I]);
    end;
  finally
    All.Free;
  end;
end;

procedure FillExts(const Lang: string; out Exts: TStringList);
begin
  Exts := TStringList.Create;
  case Lang of
    'typescript':
      begin
        Exts.Add('.ts'); Exts.Add('.tsx'); Exts.Add('.js');
        Exts.Add('.jsx'); Exts.Add('.mjs'); Exts.Add('.cjs');
      end;
    'python': Exts.Add('.py');
    'go': Exts.Add('.go');
    'rust': Exts.Add('.rs');
    'php': Exts.Add('.php');
    'ruby': Exts.Add('.rb');
    'java': Exts.Add('.java');
    'pascal':
      begin
        Exts.Add('.pas'); Exts.Add('.pp'); Exts.Add('.lpr'); Exts.Add('.dpr');
      end;
  else
    begin
      Exts.Add('.ts'); Exts.Add('.js'); Exts.Add('.py'); Exts.Add('.go');
      Exts.Add('.rs'); Exts.Add('.php'); Exts.Add('.rb'); Exts.Add('.java');
      Exts.Add('.pas');
    end;
  end;
end;

function CmdDoctor: Integer;
var
  Ok: Boolean;

  procedure Check(const Name, Cmd, Hint: string);
  begin
    if Which(Cmd) <> '' then
      Say(Format('[ok] %s: %s', [Name, Which(Cmd)]))
    else
    begin
      Say(Format('[missing] %s — %s', [Name, Hint]));
      Ok := False;
    end;
  end;

var
  Py, Laz: string;
begin
  Ok := True;
  Say(AppName + ' doctor ' + AppVersion + ' (' + HostPlatform + ')');
  Check('fpc', 'fpc', 'install Free Pascal for your OS (see README / docs/platforms.md)');
{$IFDEF CPUX86_64}
  Check('ppcx64', 'ppcx64', 'ships with FPC; put the FPC bin dir on PATH');
{$ENDIF}
{$IFDEF CPUAARCH64}
  if Which('ppca64') <> '' then
    Say('[ok] ppca64: ' + Which('ppca64'))
  else if Which('ppcarm64') <> '' then
    Say('[ok] ppcarm64: ' + Which('ppcarm64'))
  else
  begin
    Say('[missing] aarch64 code generator (ppca64) — install matching FPC');
    Ok := False;
  end;
{$ENDIF}
  Laz := Which('lazbuild');
  if Laz <> '' then
    Say('[ok] lazbuild: ' + Laz)
  else if FileExists(PathJoin3(PathJoin3(UserHomeDir, '.local', 'fpclaz'), 'lazarus',
            WithExeSuffix('lazbuild'))) then
    Say('[ok] lazbuild (fpclazup under ~/.local/fpclaz)')
  else
    Say('[warn] lazbuild — optional; install Lazarus for your OS');
  if Which('node') <> '' then
    Say('[ok] node: ' + Which('node'))
  else
    Say('[warn] node — useful when recording TypeScript/JavaScript apps');
  Py := FindPython;
  if Py <> '' then
    Say('[ok] python: ' + Py)
  else
    Say('[warn] python — useful when recording Python apps (python3 or python)');
  if Ok then
  begin
    Say('Minimum CLI environment looks good.');
    Result := 0;
  end
  else
  begin
    Say('Required tool missing. Fix it and run doctor again.');
    Result := 1;
  end;
end;

function CmdSetup(const ARoot: string): Integer;
var
  Home, AgentsDir, SkillDir, ClaudeDir: string;
  SkillSrc: string;
  SelfBin, McpJson: string;
begin
  Home := UserHomeDir;
  SelfBin := Which(AppName);
  if SelfBin = '' then
    SelfBin := Which(WithExeSuffix('pascalanything'));
  if SelfBin = '' then
    SelfBin := AbsolutePath(ParamStr(0));

  AgentsDir := PathJoin(Home, '.agents');
  SkillDir := PathJoin3(AgentsDir, 'skills', AppName);
  EnsureDir(SkillDir);
  SkillSrc := PathJoin3(ARoot, 'skills', AppName);
  if DirectoryExists(SkillSrc) then
  begin
    if FileExists(PathJoin(SkillSrc, 'SKILL.md')) then
      WriteTextFile(PathJoin(SkillDir, 'SKILL.md'),
        ReadTextFile(PathJoin(SkillSrc, 'SKILL.md')));
    if FileExists(PathJoin(SkillSrc, 'whole-app.md')) then
      WriteTextFile(PathJoin(SkillDir, 'whole-app.md'),
        ReadTextFile(PathJoin(SkillSrc, 'whole-app.md')));
    Say('Skill installed at ' + SkillDir);
  end
  else
    SayErr('skills/' + AppName + ' not found under ' + ARoot);
  ClaudeDir := PathJoin(Home, '.claude');
  EnsureDir(ClaudeDir);
  McpJson :=
    '{' + LineEnding +
    '  "mcpServers": {' + LineEnding +
    '    "pascal-anything": {' + LineEnding +
    '      "command": "' + StringReplace(SelfBin, '\', '/', [rfReplaceAll]) + '",' + LineEnding +
    '      "args": ["mcp"]' + LineEnding +
    '    }' + LineEnding +
    '  }' + LineEnding +
    '}' + LineEnding;
  WriteTextFile(PathJoin(ClaudeDir, 'pascal-anything.mcp.json'), McpJson);
  Say('MCP snippet written to ' + PathJoin(ClaudeDir, 'pascal-anything.mcp.json'));
  Say('Merge into Cursor/Claude MCP config if needed. Binary: ' + SelfBin);
  Say('Restart the agent after setup.');
  Result := 0;
end;

function CmdAnalyze(const ARoot: string; AsJson, WholeApp: Boolean;
  const OutFile, LangOverride: string): Integer;
var
  Root, Lang: string;
  Files, Exts: TStringList;
  I: Integer;
  Plan: TJSONObject;
  Arr: TJSONArray;
  U: TJSONObject;
  Md: TStringList;
  OutText: string;
begin
  Root := AbsolutePath(ARoot);
  if LangOverride <> '' then
    Lang := LangOverride
  else
    Lang := DetectLang(Root);

  FillExts(Lang, Exts);
  Files := ListSourceFiles(Root, Exts);
  Exts.Free;
  try
    Plan := TJSONObject.Create;
    Arr := TJSONArray.Create;
    try
      Plan.Add('schema', SchemaAnalyze);
      Plan.Add('root', Root);
      Plan.Add('lang', Lang);
      Plan.Add('whole_app', WholeApp);
      Plan.Add('target', 'pascal-lazarus');
      for I := 0 to Files.Count - 1 do
      begin
        U := TJSONObject.Create;
        U.Add('id', RelPath(Root, Files[I]));
        U.Add('path', RelPath(Root, Files[I]));
        U.Add('rank', I + 1);
        U.Add('bridge', 'fpc-package');
        U.Add('status', 'candidate');
        Arr.Add(U);
      end;
      Plan.Add('units', Arr);
      Arr := nil;

      if AsJson then
        OutText := Plan.FormatJSON
      else
      begin
        Md := TStringList.Create;
        try
          Md.Add('# Migration plan → Free Pascal / Lazarus');
          Md.Add('');
          Md.Add('- root: `' + Root + '`');
          Md.Add('- detected language: **' + Lang + '**');
          Md.Add('- target: **Pascal/Lazarus** (FPC package + `port.pas` stubs; official LCL/FCL first)');

          if WholeApp then
            Md.Add('- mode: whole app (unit by unit, then lift)');
          Md.Add('');
          Md.Add('## Units (suggested order)');
          Md.Add('');
          for I := 0 to Files.Count - 1 do
            Md.Add(Format('%d. `%s`', [I + 1, RelPath(Root, Files[I])]));
          if Files.Count = 0 then
            Md.Add('_No source files found for this language._');
          Md.Add('');
          Md.Add('Next: `pascal-anything bridge <root> <unit>`');
          OutText := Md.Text;
        finally
          Md.Free;
        end;
      end;

      if OutFile <> '' then
      begin
        WriteTextFile(OutFile, OutText);
        Say('Plan written to ' + OutFile);
      end
      else
        Say(OutText);
      Result := 0;
    finally
      Plan.Free;
    end;
  finally
    Files.Free;
  end;
end;

function BridgeStubPort(const UnitName, SrcLang: string): string;
begin
  Result :=
    'unit port;' + LineEnding +
    LineEnding +
    '{ From: ' + UnitName + ' (' + SrcLang + ') }' + LineEnding +
    LineEnding +
    '{$mode objfpc}{$H+}' + LineEnding +
    LineEnding +
    'interface' + LineEnding +
    LineEnding +
    'implementation' + LineEnding +
    LineEnding +
    'end.' + LineEnding;
end;

function BridgeHarness(const PkgName: string): string;
begin
  Result :=
    'program harness;' + LineEnding +
    LineEnding +
    '{$mode objfpc}{$H+}' + LineEnding +
    LineEnding +
    'uses' + LineEnding +
    '  SysUtils, Classes, fpjson, jsonparser, port;' + LineEnding +
    LineEnding +
    'var' + LineEnding +
    '  SL: TStringList;' + LineEnding +
    '  I: Integer;' + LineEnding +
    '  Line: string;' + LineEnding +
    'begin' + LineEnding +
    '  if ParamCount < 1 then' + LineEnding +
    '  begin' + LineEnding +
    '    WriteLn(StdErr, ''usage: harness <cases.jsonl>'');' + LineEnding +
    '    Halt(2);' + LineEnding +
    '  end;' + LineEnding +
    '  SL := TStringList.Create;' + LineEnding +
    '  try' + LineEnding +
    '    SL.LoadFromFile(ParamStr(1));' + LineEnding +
    '    for I := 0 to SL.Count - 1 do' + LineEnding +
    '    begin' + LineEnding +
    '      Line := Trim(SL[I]);' + LineEnding +
    '      if Line = '''' then Continue;' + LineEnding +
    '      WriteLn(Line);' + LineEnding +
    '    end;' + LineEnding +
    '  finally' + LineEnding +
    '    SL.Free;' + LineEnding +
    '  end;' + LineEnding +
    'end.' + LineEnding;
end;

function CmdBridge(const ARoot, AUnit, OutDir, PkgName: string;
  Force: Boolean; const EndState: string = 'replace'): Integer;
var
  Root, UnitPath, Dest, Name, Lang, NormEndState: string;
  Manifest: TJSONObject;
  ExportList: TJSONArray;
  Exp: TJSONObject;
  Task: string;
begin
  Root := AbsolutePath(ARoot);
  UnitPath := AUnit;
  if not FileExists(PathJoin(Root, UnitPath)) and FileExists(UnitPath) then
    UnitPath := RelPath(Root, UnitPath);
  if (not Force) and (not FileExists(PathJoin(Root, UnitPath))) then
  begin
    SayErr('unit not found: ' + UnitPath);
    Exit(1);
  end;

  NormEndState := LowerCase(Trim(EndState));
  if (NormEndState <> 'replace') and (NormEndState <> 'bindings') and (NormEndState <> 'scaffold') then
    NormEndState := 'replace';

  Lang := DetectLang(Root);
  if PkgName <> '' then
    Name := SanitizeIdent(PkgName)
  else
    Name := SanitizeIdent(ChangeFileExt(ExtractFileName(UnitPath), '')) + '_pas';

  if OutDir <> '' then
    Dest := AbsolutePath(OutDir)
  else
    Dest := PathJoin3(Root, 'pascal', Name);

  if DirectoryExists(Dest) and (not Force) and
     FileExists(PathJoin(Dest, ManifestFileName)) then
  begin
    SayErr('bridge already exists at ' + Dest + ' (use --force)');
    Exit(1);
  end;

  EnsureDir(Dest);
  EnsureDir(PathJoin(Dest, 'src'));

  WriteTextFile(PathJoin3(Dest, 'src', 'port.pas'), BridgeStubPort(UnitPath, Lang));
  WriteTextFile(PathJoin(Dest, 'harness.lpr'), BridgeHarness(Name));
  WriteTextFile(PathJoin(Dest, Name + '.pas'),
    'unit ' + Name + ';' + LineEnding +
    LineEnding +
    '{$mode objfpc}{$H+}' + LineEnding +
    LineEnding +
    'interface' + LineEnding +
    LineEnding +
    'uses port;' + LineEnding +
    LineEnding +
    'implementation' + LineEnding +
    LineEnding +
    'end.' + LineEnding);

  Manifest := TJSONObject.Create;
  try
    Manifest.Add('schema', SchemaBridge);
    Manifest.Add('root', Root);
    Manifest.Add('unit', UnitPath);
    Manifest.Add('kind', 'fpc-package');
    Manifest.Add('package_name', Name);
    Manifest.Add('lang', Lang);
    Manifest.Add('target', 'pascal-lazarus');
    Manifest.Add('enabled', False);
    Manifest.Add('end_state', NormEndState);
    ExportList := TJSONArray.Create;
    Exp := TJSONObject.Create;
    Exp.Add('name', 'TODO');
    Exp.Add('file', UnitPath);
    Exp.Add('note', 'fill after inspecting the unit');
    ExportList.Add(Exp);
    Manifest.Add('exports', ExportList);
    WriteManifest(Dest, Manifest);
  finally
    Manifest.Free;
  end;

  Task :=
    '# TASK — port `' + UnitPath + '` → Free Pascal' + LineEnding +
    LineEnding +
    '- End state: `' + NormEndState + '` (' + EndStateDescription(NormEndState) + ')' + LineEnding +
    LineEnding +
    '1. Read the original unit and fill `src/port.pas` with the same API.' + LineEnding +
    '2. Prefer official FPC RTL/FCL and Lazarus LCL; then Lazarus CCR / maintained ' +
      'domain frameworks. No ad-hoc or foreign GUI stacks unless the user asks.' + LineEnding +
    '3. For GUI units: apply canonical LCL guidelines (bind `TForm.Menu := MainMenu`, ' +
      'preserve full nested cascaded submenus and separators without flattening, wire `TActionList` ' +
      '(`Action := act...`), use `TStatusBar` with `TStatusPanels`, attach native `TPopupMenu`).' + LineEnding +
    '4. `pascal-anything record ' + Dest + '`' + LineEnding +
    '5. Wire `harness.lpr` to dispatch each `fn` from `cases.jsonl`.' + LineEnding +
    '6. `pascal-anything build ' + Dest + '` && `pascal-anything diff ' + Dest + '`' + LineEnding +
    '7. Call it done only when `pascal-anything gate ' + Dest + '` passes.' + LineEnding +
    LineEnding +
    'Do not paste recorded results into source. Do not weaken tests.' + LineEnding;

  WriteTextFile(PathJoin(Dest, TaskFileName), Task);

  Say('Bridge created at ' + Dest);
  Say('Edit src/port.pas per TASK.md, then: pascal-anything record ' + Dest);
  Result := 0;
end;

function SampleCasesForLang(const Lang: string; Count: Integer): TStringList;
var
  I: Integer;
  Obj: TJSONObject;
  Args: TJSONArray;
begin
  Result := TStringList.Create;
  for I := 0 to Count - 1 do
  begin
    Obj := TJSONObject.Create;
    Args := TJSONArray.Create;
    try
      Obj.Add('fn', 'TODO');
      case Lang of
        'python', 'typescript':
          begin
            Args.Add('case-' + IntToStr(I));
            Args.Add(I);
          end;
      else
        Args.Add(I);
      end;
      Obj.Add('args', Args);
      Args := nil;
      Obj.Add('ok', TJSONNull.Create);
      Obj.Add('note', 'replace by running the original; agent completes the recorder');
      Result.Add(Obj.AsJSON);
    finally
      Obj.Free;
    end;
  end;
end;

function FindRecordPythonScript: string;
var
  Candidates: array[0..3] of string;
  I: Integer;
  EnvHome: string;
begin
  EnvHome := GetEnvironmentVariable('PASCAL_ANYTHING_HOME');
  Candidates[0] := PathJoin(ExtractFilePath(ParamStr(0)), PathJoin('..', 'scripts/record_python.py'));
  Candidates[1] := PathJoin(GetCurrentDir, 'scripts/record_python.py');
  Candidates[2] := PathJoin(GetCurrentDir, PathJoin('..', 'scripts/record_python.py'));
  if EnvHome <> '' then
    Candidates[3] := PathJoin(EnvHome, 'scripts/record_python.py')
  else
    Candidates[3] := '';
  for I := 0 to High(Candidates) do
  begin
    if Candidates[I] = '' then
      Continue;
    Result := ExpandFileName(Candidates[I]);
    if FileExists(Result) then
      Exit;
  end;
  Result := '';
end;

const
  SECRET_NAME_PARTS: array[0..7] of string = (
    'SECRET', 'TOKEN', 'PASSWORD', 'PASSWD', 'PASSPHRASE',
    'CREDENTIAL', 'API_KEY', 'PRIVATE_KEY'
  );
  MIN_SECRET_CHARS = 8;

procedure RemoveOrEmptyFile(const APath: string);
var
  F: TextFile;
begin
  if not FileExists(APath) then
    Exit;
  if not DeleteFile(APath) then
  begin
    try
      AssignFile(F, APath);
      Rewrite(F);
      CloseFile(F);
    except
      { best effort empty }
    end;
  end;
end;

function FileHoldsSecret(const APath: string; out SecretVarName: string): Boolean;
var
  TotalEnv, I, J: Integer;
  EnvStr, VarName, VarVal, VarUpper, Content: string;
  CasesFile: TStringList;
begin
  Result := False;
  SecretVarName := '';
  if not FileExists(APath) then
    Exit;

  TotalEnv := GetEnvironmentVariableCount;
  CasesFile := TStringList.Create;
  try
    CasesFile.LoadFromFile(APath);
    Content := CasesFile.Text;
    if Content = '' then
      Exit;

    for I := 1 to TotalEnv do
    begin
      EnvStr := GetEnvironmentString(I);
      J := Pos('=', EnvStr);
      if J <= 1 then
        Continue;
      VarName := Copy(EnvStr, 1, J - 1);
      VarVal := Copy(EnvStr, J + 1, Length(EnvStr));
      if Length(VarVal) < MIN_SECRET_CHARS then
        Continue;
      VarUpper := UpperCase(VarName);
      for J := 0 to High(SECRET_NAME_PARTS) do
      begin
        if Pos(SECRET_NAME_PARTS[J], VarUpper) > 0 then
        begin
          if Pos(VarVal, Content) > 0 then
          begin
            SecretVarName := VarName;
            Result := True;
            Exit;
          end;
          Break;
        end;
      end;
    end;
  finally
    CasesFile.Free;
  end;
end;

function CmdRecord(const ACrate: string; Count: Integer;
  const InputsFile: string): Integer;
var
  Crate, Root, UnitPath, Lang, OutPath, Script, OutS, ErrS, SecretVar: string;
  Manifest: TJSONObject;
  Cases: TStringList;
  Code: Integer;
  Args: array of string;
begin
  Crate := AbsolutePath(ACrate);
  if not LoadManifest(Crate, Manifest) then
  begin
    SayErr('missing ' + ManifestFileName + ' in ' + Crate + ' — run bridge first');
    Exit(1);
  end;
  try
    Lang := JsonStr(Manifest, 'lang', 'unknown');
    Root := JsonStr(Manifest, 'root', '');
    UnitPath := JsonStr(Manifest, 'unit', '');
    OutPath := PathJoin(Crate, CasesFileName);
    if (Lang = 'unknown') and (Root <> '') then
    begin
      Lang := DetectLang(Root);
      Manifest.Strings['lang'] := Lang;
    end;
    if (LowerCase(ExtractFileExt(UnitPath)) = '.py') then
      Lang := 'python';

    if (Lang = 'python') and (Root <> '') and (UnitPath <> '') then
    begin
      Script := FindRecordPythonScript;
      if (Script <> '') and (FindPython <> '') then
      begin
        SetLength(Args, 9);
        Args[0] := Script;
        Args[1] := '--root';
        Args[2] := Root;
        Args[3] := '--unit';
        Args[4] := UnitPath;
        Args[5] := '--out';
        Args[6] := OutPath;
        Args[7] := '--count';
        Args[8] := IntToStr(Count);
        if (InputsFile <> '') and FileExists(InputsFile) then
        begin
          SetLength(Args, 11);
          Args[9] := '--inputs';
          Args[10] := AbsolutePath(InputsFile);
        end;
        if RunCapture(FindPython, Args, OutS, ErrS, Code, Root) and (Code = 0) then
        begin
          if FileExists(OutPath) and FileHoldsSecret(OutPath, SecretVar) then
          begin
            RemoveOrEmptyFile(OutPath);
            SayErr('record refused: cases hold secret from environment variable ' +
              SecretVar + '. Record with env -u ' + SecretVar + ' or change inputs.');
            Exit(1);
          end;
          Cases := TStringList.Create;
          try
            if FileExists(OutPath) then
              Cases.LoadFromFile(OutPath);
            Manifest.Strings['recorded_at'] := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now);
            Manifest.Integers['case_count'] := Cases.Count;
            Manifest.Strings['recorder'] := 'python';
            WriteManifest(Crate, Manifest);
            if ErrS <> '' then
              Say(Trim(ErrS));
            Say('Recording (Python original) at ' + OutPath + ' (' +
              CountNoun(Cases.Count, 'case', 'cases') + ')');
            Exit(0);
          finally
            Cases.Free;
          end;
        end
        else
        begin
          if FileExists(OutPath) and FileHoldsSecret(OutPath, SecretVar) then
            RemoveOrEmptyFile(OutPath);
          SayErr('Python recorder failed: ' + ErrS + OutS);
        end;
      end;
    end;

    Cases := TStringList.Create;
    try
      if (InputsFile <> '') and FileExists(InputsFile) then
        Cases.LoadFromFile(InputsFile)
      else
      begin
        Cases.Free;
        Cases := SampleCasesForLang(Lang, Count);
        Say('Generated ' + CountNoun(Count, 'case skeleton', 'case skeletons') +
          '. Replace ok with returns from the original.');
      end;
      Cases.SaveToFile(OutPath);
      if FileHoldsSecret(OutPath, SecretVar) then
      begin
        RemoveOrEmptyFile(OutPath);
        SayErr('record refused: cases hold secret from environment variable ' +
          SecretVar + '. Record with env -u ' + SecretVar + ' or change inputs.');
        Exit(1);
      end;
      Manifest.Strings['recorded_at'] := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now);
      Manifest.Integers['case_count'] := Cases.Count;
      WriteManifest(Crate, Manifest);
      Say('Recording at ' + OutPath + ' (' + CountNoun(Cases.Count, 'case', 'cases') + ')');
      Result := 0;
    finally
      Cases.Free;
    end;
  finally
    Manifest.Free;
  end;
end;

function CmdBuild(const ACrate: string): Integer;
var
  Crate, OutS, ErrS, Harness: string;
  Code: Integer;
  Manifest: TJSONObject;
begin
  Crate := AbsolutePath(ACrate);
  Harness := PathJoin(Crate, 'harness.lpr');
  if not FileExists(Harness) then
  begin
    SayErr('harness.lpr missing in ' + Crate);
    Exit(1);
  end;
  if Which('fpc') = '' then
  begin
    SayErr('fpc not found — run pascal-anything doctor');
    Exit(1);
  end;
  EnsureDir(PathJoin(Crate, 'bin'));
  if not RunCapture('fpc', ['-O2', '-Fusrc', '-FEbin', Harness], OutS, ErrS, Code, Crate) then
  begin
    SayErr(ErrS);
    Exit(1);
  end;
  if Code <> 0 then
  begin
    Say(OutS);
    SayErr(ErrS);
    SayErr('build failed (exit ' + IntToStr(Code) + ')');
    Exit(1);
  end;
  Say(OutS);
  if LoadManifest(Crate, Manifest) then
  try
    Manifest.Strings['built_at'] := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now);
    WriteManifest(Crate, Manifest);
  finally
    Manifest.Free;
  end;
  Say('Build ok → ' + PathJoin(Crate, 'bin'));
  Result := 0;
end;

function LoadJsonl(const APath: string): TStringList;
begin
  Result := TStringList.Create;
  if FileExists(APath) then
    Result.LoadFromFile(APath);
end;

function LoadKnownDiffs(const Crate: string): TJSONArray;
var
  KnownPath: string;
  Lines: TStringList;
  I: Integer;
  Data: TJSONData;
begin
  Result := TJSONArray.Create;
  KnownPath := PathJoin(Crate, KnownDiffsFileName);
  if not FileExists(KnownPath) then
    Exit;
  Lines := LoadJsonl(KnownPath);
  try
    for I := 0 to Lines.Count - 1 do
    begin
      if Trim(Lines[I]) = '' then
        Continue;
      try
        Data := GetJSON(Lines[I]);
        if Data is TJSONObject then
          Result.Add(Data)
        else
          Data.Free;
      except
        { ignore malformed json lines }
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function MatchKnownDiff(KnownList: TJSONArray; const FnName: string;
  ArgsData, GotOk: TJSONData; out Reason: string): Boolean;
var
  I: Integer;
  Item: TJSONObject;
  KFn: string;
  KArgs, KActual: TJSONData;
begin
  Result := False;
  Reason := '';
  if KnownList = nil then
    Exit;
  for I := 0 to KnownList.Count - 1 do
  begin
    if not (KnownList[I] is TJSONObject) then
      Continue;
    Item := TJSONObject(KnownList[I]);
    KFn := JsonStr(Item, 'fn', JsonStr(Item, 'function', ''));
    if (KFn <> '') and (KFn <> FnName) then
      Continue;
    KArgs := Item.Find('args');
    if (KArgs <> nil) and (ArgsData <> nil) then
    begin
      if KArgs.AsJSON <> ArgsData.AsJSON then
        Continue;
    end;
    KActual := Item.Find('actual');
    if (KActual <> nil) and (GotOk <> nil) then
    begin
      if KActual.AsJSON <> GotOk.AsJSON then
        Continue;
    end;
    Reason := JsonStr(Item, 'reason', 'intended difference');
    Exit(True);
  end;
end;

function CmdDiffInternal(const ACrate: string; out Matched, Total, Accepted, Mismatch: Integer): Integer;
var
  Crate, CasesPath, BinHarness, OutS, ErrS, Line, Reason, FnName: string;
  Code, I: Integer;
  Expected, Got: TStringList;
  EObj, GObj, EOk, GOk, ArgsData: TJSONData;
  KnownList: TJSONArray;
  IsDiff: Boolean;
begin
  Matched := 0;
  Total := 0;
  Accepted := 0;
  Mismatch := 0;
  Crate := AbsolutePath(ACrate);
  CasesPath := PathJoin(Crate, CasesFileName);
  if not FileExists(CasesPath) then
  begin
    SayErr('run record first');
    Exit(1);
  end;
  BinHarness := ResolveBinary(PathJoin3(Crate, 'bin', 'harness'));
  if BinHarness = '' then
    BinHarness := ResolveBinary(PathJoin(Crate, 'harness'));
  if BinHarness = '' then
  begin
    SayErr('harness binary missing — run build');
    Exit(1);
  end;

  if not RunCapture(BinHarness, [CasesPath], OutS, ErrS, Code, Crate) then
  begin
    SayErr(ErrS);
    Exit(1);
  end;

  KnownList := LoadKnownDiffs(Crate);
  Expected := LoadJsonl(CasesPath);
  Got := TStringList.Create;
  try
    Got.Text := OutS;
    for I := 0 to Expected.Count - 1 do
    begin
      Line := Trim(Expected[I]);
      if Line = '' then
        Continue;
      Inc(Total);
      if (I >= Got.Count) or (Trim(Got[I]) = '') then
      begin
        Inc(Mismatch);
        Say(Format('[%d] missing output', [I]));
        Continue;
      end;
      try
        EObj := GetJSON(Line);
        GObj := GetJSON(Trim(Got[I]));
        try
          IsDiff := False;
          EOk := nil;
          GOk := nil;
          FnName := '';
          ArgsData := nil;

          if (EObj is TJSONObject) and (GObj is TJSONObject) then
          begin
            FnName := JsonStr(TJSONObject(EObj), 'fn', '');
            ArgsData := TJSONObject(EObj).Find('args');
            EOk := TJSONObject(EObj).Find('ok');
            GOk := TJSONObject(GObj).Find('ok');
            if EOk <> nil then
            begin
              if (GOk = nil) or (EOk.AsJSON <> GOk.AsJSON) then
                IsDiff := True;
            end
            else if EObj.AsJSON <> GObj.AsJSON then
              IsDiff := True;
          end
          else if EObj.AsJSON <> GObj.AsJSON then
            IsDiff := True;

          if IsDiff then
          begin
            if MatchKnownDiff(KnownList, FnName, ArgsData, GOk, Reason) then
            begin
              Inc(Accepted);
              Say(Format('[%d] accepted by %s (%s): %s', [I, KnownDiffsFileName, FnName, Reason]));
            end
            else
            begin
              Inc(Mismatch);
              if EOk <> nil then
                Say(Format('[%d] mismatch ok', [I]))
              else
                Say(Format('[%d] mismatch', [I]));
            end;
          end;
        finally
          EObj.Free;
          GObj.Free;
        end;
      except
        on E: Exception do
        begin
          Inc(Mismatch);
          Say(Format('[%d] parse error: %s', [I, E.Message]));
        end;
      end;
    end;
    Matched := Total - Mismatch;
    if Accepted > 0 then
      Say(Format('diff: %d/%d ok (%d by %s), %s', [Matched, Total, Accepted, KnownDiffsFileName, CountNoun(Mismatch, 'mismatch', 'mismatches')]))
    else
      Say(Format('diff: %d/%d ok, %s', [Matched, Total, CountNoun(Mismatch, 'mismatch', 'mismatches')]));
    if Mismatch = 0 then
      Result := 0
    else
      Result := 1;
  finally
    KnownList.Free;
    Expected.Free;
    Got.Free;
  end;
end;

function CmdDiff(const ACrate: string): Integer;
var
  Matched, Total, Accepted, Mismatch: Integer;
begin
  Result := CmdDiffInternal(ACrate, Matched, Total, Accepted, Mismatch);
end;

function GateCheck(const Name: string; Passed: Boolean; const Detail, Fix: string;
  var Failures: Integer): TCheck;
begin
  Result.Name := Name;
  Result.Passed := Passed;
  Result.Detail := Detail;
  Result.Fix := Fix;
  if Passed then
    Say(Format('[pass] %s — %s', [Name, Detail]))
  else
  begin
    Inc(Failures);
    Say(Format('[fail] %s — %s', [Name, Detail]));
    if Fix <> '' then
      Say('       fix: ' + Fix);
  end;
end;

function CmdGate(const ACrate: string): Integer;
var
  Crate: string;
  Failures: Integer;
  Manifest: TJSONObject;
  PortPath, CasesPath: string;
  PortSrc: string;
  HasTodo: Boolean;
  Matched, Total, Accepted, Mismatches, BaselineKnown, AddedKnown: Integer;
  Detail: string;
begin
  Crate := AbsolutePath(ACrate);
  Failures := 0;
  Matched := 0;
  Total := 0;
  Accepted := 0;
  Mismatches := 0;
  Say('gate ' + Crate);

  GateCheck('manifest', FileExists(PathJoin(Crate, ManifestFileName)),
    ManifestFileName, 'pascal-anything bridge ...', Failures);

  PortPath := PathJoin3(Crate, 'src', 'port.pas');
  GateCheck('port.pas', FileExists(PortPath), PortPath,
    'fill in src/port.pas', Failures);

  if FileExists(PortPath) then
  begin
    PortSrc := ReadTextFile(PortPath);
    HasTodo := (Pos('TODO', PortSrc) > 0);
    GateCheck('ported', not HasTodo, 'no TODO markers in port.pas',
      'implement remaining stubbed functions', Failures);
  end;

  CasesPath := PathJoin(Crate, CasesFileName);
  GateCheck('recording', FileExists(CasesPath), CasesFileName,
    'pascal-anything record ' + Crate, Failures);

  GateCheck('build',
    ResolveBinary(PathJoin3(Crate, 'bin', 'harness')) <> '',
    'harness binary', 'pascal-anything build ' + Crate, Failures);

  if FileExists(CasesPath) and
     (ResolveBinary(PathJoin3(Crate, 'bin', 'harness')) <> '') then
  begin
    if CmdDiffInternal(Crate, Matched, Total, Accepted, Mismatches) = 0 then
    begin
      BaselineKnown := 0;
      if LoadManifest(Crate, Manifest) then
      try
        BaselineKnown := JsonInt(Manifest, 'known_diffs', 0);
      finally
        Manifest.Free;
      end;

      AddedKnown := 0;
      if Accepted > BaselineKnown then
        AddedKnown := Accepted - BaselineKnown;

      Detail := Format('%d/%d recorded cases match', [Matched, Total]);
      if (Accepted > 0) and (AddedKnown > 0) then
        Detail := Format('%s (%d by %s, %s added since the last passing gate: land behavior changes apart from the port)',
          [Detail, Accepted, KnownDiffsFileName, CountNoun(AddedKnown, 'entry', 'entries')])
      else if Accepted > 0 then
        Detail := Format('%s (%d by %s)', [Detail, Accepted, KnownDiffsFileName]);

      GateCheck('behavior', True, Detail, '', Failures);
    end
    else
      GateCheck('behavior', False, 'mismatches remain',
        'pascal-anything diff ' + Crate, Failures);
  end;

  if LoadManifest(Crate, Manifest) then
  try
    Manifest.Booleans['gate_passed'] := Failures = 0;
    Manifest.Strings['gate_at'] := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now);
    if Failures = 0 then
      Manifest.Integers['known_diffs'] := Accepted;
    WriteManifest(Crate, Manifest);
  finally
    Manifest.Free;
  end;

  if Failures = 0 then
  begin
    Say('GATE PASS');
    Result := 0;
  end
  else
  begin
    Say(Format('GATE FAIL (%s)', [CountNoun(Failures, 'check fails', 'checks fail')]));
    Result := 1;
  end;
end;

function CmdGo(const ARoot: string; const Workload: TStringList): Integer;
var
  Root, Lang, UnitId, Dest: string;
  Files, Exts: TStringList;
begin
  Root := AbsolutePath(ARoot);
  Lang := DetectLang(Root);
  FillExts(Lang, Exts);
  Files := ListSourceFiles(Root, Exts);
  Exts.Free;
  try
    if Files.Count = 0 then
    begin
      SayErr('no candidate unit in ' + Root);
      Exit(1);
    end;
    UnitId := RelPath(Root, Files[0]);
    Say('go: simple profile → candidate hot unit: ' + UnitId);
    if Workload.Count > 0 then
      Say('workload: ' + Workload.CommaText);
    Result := CmdBridge(Root, UnitId, '', '', False);
    if Result <> 0 then
      Exit;
    Dest := PathJoin3(Root, 'pascal',
      SanitizeIdent(ChangeFileExt(ExtractFileName(UnitId), '')) + '_pas');
    Result := CmdRecord(Dest, 50, '');
    if Result <> 0 then
      Exit;
    Say('Port ' + PathJoin(Dest, 'src/port.pas') + ' per TASK.md, then:');
    Say('  pascal-anything build ' + Dest);
    Say('  pascal-anything gate ' + Dest);
  finally
    Files.Free;
  end;
end;

function CmdReport(const ACrate: string): Integer;
var
  Crate, ReportDir, KnownPath, Lang, KArgsStr, EndState: string;
  Manifest, KObj, ExpObj: TJSONObject;
  Md, KnownLines: TStringList;
  Cases, I: Integer;
  HasHeader, HasKeptHeader: Boolean;
  KData, KArgs: TJSONData;
  ExportArr: TJSONArray;
begin
  Crate := AbsolutePath(ACrate);
  if not LoadManifest(Crate, Manifest) then
  begin
    SayErr('manifest missing');
    Exit(1);
  end;
  try
    Cases := JsonInt(Manifest, 'case_count', 0);
    Lang := JsonStr(Manifest, 'lang', 'original language');
    EndState := JsonStr(Manifest, 'end_state', '');
    ReportDir := PathJoin(Crate, 'report');
    EnsureDir(ReportDir);
    Md := TStringList.Create;
    try
      Md.Add('# pascal-anything report');
      Md.Add('');
      Md.Add('| Metric | Value |');
      Md.Add('| --- | --- |');
      Md.Add('| Package | `' + MarkdownCell(JsonStr(Manifest, 'package_name', '')) + '` |');
      Md.Add('| Unit | `' + MarkdownCell(JsonStr(Manifest, 'unit', '')) + '` |');
      Md.Add('| Cases | ' + IntToStr(Cases) + ' |');
      Md.Add('| End state | ' + EndStateDescription(EndState) + ' |');
      Md.Add('| Gate passed | ' + BoolToStr(JsonBool(Manifest, 'gate_passed', False), True) + ' |');
      Md.Add('| Switched on | ' + BoolToStr(JsonBool(Manifest, 'enabled', False), True) + ' |');

      KnownPath := PathJoin(Crate, KnownDiffsFileName);
      if FileExists(KnownPath) then
      begin
        KnownLines := LoadJsonl(KnownPath);
        try
          HasHeader := False;
          for I := 0 to KnownLines.Count - 1 do
          begin
            if Trim(KnownLines[I]) = '' then
              Continue;
            try
              KData := GetJSON(KnownLines[I]);
              if KData is TJSONObject then
              begin
                KObj := TJSONObject(KData);
                if not HasHeader then
                begin
                  Md.Add('');
                  Md.Add('### Intended differences');
                  Md.Add('');
                  Md.Add('From `' + KnownDiffsFileName + '`: the port is meant to differ on these inputs.');
                  Md.Add('');
                  Md.Add('| Function | Input | Reason |');
                  Md.Add('| --- | --- | --- |');
                  HasHeader := True;
                end;
                KArgs := KObj.Find('args');
                KArgsStr := '';
                if KArgs <> nil then
                  KArgsStr := KArgs.AsJSON;
                Md.Add(Format('| `%s` | `%s` | %s |', [
                  MarkdownCell(JsonStr(KObj, 'fn', JsonStr(KObj, 'function', ''))),
                  MarkdownCell(KArgsStr),
                  MarkdownCell(JsonStr(KObj, 'reason', 'intended difference'))
                ]));
              end;
            finally
              KData.Free;
            end;
          end;
        finally
          KnownLines.Free;
        end;
      end;

      if Manifest.Find('exports') is TJSONArray then
      begin
        ExportArr := TJSONArray(Manifest.Find('exports'));
        HasKeptHeader := False;
        for I := 0 to ExportArr.Count - 1 do
        begin
          if ExportArr[I] is TJSONObject then
          begin
            ExpObj := TJSONObject(ExportArr[I]);
            if JsonBool(ExpObj, 'kept', False) or (JsonStr(ExpObj, 'reason', '') <> '') then
            begin
              if not HasKeptHeader then
              begin
                Md.Add('');
                Md.Add('### Kept in ' + Lang);
                Md.Add('');
                Md.Add('| Export | Where | Reason |');
                Md.Add('| --- | --- | --- |');
                HasKeptHeader := True;
              end;
              Md.Add(Format('| `%s` | `%s` | %s |', [
                MarkdownCell(JsonStr(ExpObj, 'name', '')),
                MarkdownCell(JsonStr(ExpObj, 'file', '')),
                MarkdownCell(JsonStr(ExpObj, 'reason', JsonStr(ExpObj, 'note', '')))
              ]));
            end;
          end;
        end;
      end;

      Md.Add('');
      Md.Add('Generated by ' + AppName + ' ' + AppVersion);
      WriteTextFile(PathJoin(ReportDir, 'REPORT.md'), Md.Text);
      Say('Report at ' + PathJoin(ReportDir, 'REPORT.md'));
      Result := 0;
    finally
      Md.Free;
    end;
  finally
    Manifest.Free;
  end;
end;

function CmdEnable(const ACrate: string; Enable: Boolean): Integer;
var
  Crate: string;
  Manifest: TJSONObject;
begin
  Crate := AbsolutePath(ACrate);
  if not LoadManifest(Crate, Manifest) then
  begin
    SayErr('manifest missing');
    Exit(1);
  end;
  try
    if Enable and (not JsonBool(Manifest, 'gate_passed', False)) then
    begin
      SayErr('gate has not passed — enable refused');
      Exit(1);
    end;
    Manifest.Booleans['enabled'] := Enable;
    WriteManifest(Crate, Manifest);
    if Enable then
      Say('enabled')
    else
      Say('disabled');
    Result := 0;
  finally
    Manifest.Free;
  end;
end;

function CmdRules: Integer;
begin
  Say('pascal-anything rules (rust-anything loop, Pascal/Lazarus target):');
  Say('1. The original is ground truth — record it, prove with diff/gate.');
  Say('2. One unit at a time; gate must pass before the next.');
  Say('3. Do not paste cases.jsonl results into source.');
  Say('4. Do not weaken tests or edit cases to force a pass.');
  Say('5. Target: Free Pascal + Lazarus (.lpk/.pas; official LCL/FCL first, then CCR/frameworks).');
  Say('6. GUI ports: canonical LCL (bind TForm.Menu, preserve cascaded submenus/separators, wire TActionList, TStatusBar panels, native TPopupMenu).');
  Say('7. Callers keep a stable API until enable.');
  Result := 0;
end;

function CmdVersion: Integer;
begin
  Say(AppName + ' ' + AppVersion);
  Result := 0;
end;

function CmdHelp: Integer;
begin
  Say('Pascal Anything — rewrite any app in Free Pascal/Lazarus, one unit at a time.');
  Say('');
  Say('Usage: pascal-anything <command> [options]');
  Say('');
  Say('Commands:');
  Say('  doctor                         check fpc/lazbuild/runtimes');
  Say('  setup [repo]                   install skill + MCP snippet for agents');
  Say('  analyze [root] [--json] [--whole-app] [--lang L] [-o file]');
  Say('  bridge <root> <unit> [--out DIR] [--name NAME] [--end-state S] [--force]');
  Say('  record [crate] [--count N] [--inputs file.jsonl]');
  Say('  build [crate]');
  Say('  diff [crate]');
  Say('  gate [crate]');
  Say('  go [root] [-- cmd...]');
  Say('  enable|disable [crate]');
  Say('  report [crate]');
  Say('  rules');
  Say('  mcp                            MCP stdio server (JSON-RPC)');
  Say('  version | help');
  Say('');
  Say('Loop: analyze → bridge → record → port.pas → build → diff → gate');
  Result := 0;
end;


end.
