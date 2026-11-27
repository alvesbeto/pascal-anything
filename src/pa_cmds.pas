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
  Force: Boolean): Integer;
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
      if (Pos(PathDelim + '.git' + PathDelim, All[I]) > 0) or
         (Pos(PathDelim + 'node_modules' + PathDelim, All[I]) > 0) or
         (Pos(PathDelim + 'vendor' + PathDelim, All[I]) > 0) or
         (Pos(PathDelim + 'pascal' + PathDelim, All[I]) > 0) then
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

begin
  Ok := True;
  Say(AppName + ' doctor ' + AppVersion);
  Check('fpc', 'fpc', 'instale Free Pascal (já em ~/.local/bin se usou o tarball)');
  Check('ppcx64', 'ppcx64', 'vem com o FPC; coloque ~/.local/lib/fpc/3.2.2 no PATH');
  if Which('lazbuild') <> '' then
    Say('[ok] lazbuild: ' + Which('lazbuild'))
  else if FileExists(ExpandFileName('~/.local/fpclaz/lazarus/lazbuild')) then
    Say('[ok] lazbuild: ~/.local/fpclaz/lazarus/lazbuild (fpclazup)')
  else
    Say('[warn] lazbuild — fpclazup headless em ~/.local/fpclaz, ou sudo apt install lazarus');
  if Which('node') <> '' then
    Say('[ok] node: ' + Which('node'))
  else
    Say('[warn] node — útil para gravar apps TypeScript/JavaScript');
  if Which('python3') <> '' then
    Say('[ok] python3: ' + Which('python3'))
  else
    Say('[warn] python3 — útil para gravar apps Python');
  if Ok then
  begin
    Say('Ambiente mínimo para o CLI ok.');
    Result := 0;
  end
  else
  begin
    Say('Falta ferramenta obrigatória. Corrija e rode de novo.');
    Result := 1;
  end;
end;

function CmdSetup(const ARoot: string): Integer;
var
  Home, AgentsDir, SkillDir, CursorDir, ClaudeDir: string;
  SkillSrc, SkillDst: string;
  SelfBin, McpJson: string;
begin
  Home := GetEnvironmentVariable('HOME');
  if Home = '' then
    Home := ExpandFileName('~');
  SelfBin := Which(AppName);
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
    Say('Skill instalada em ' + SkillDir);
  end
  else
    SayErr('skills/' + AppName + ' não encontrada em ' + ARoot);

  CursorDir := PathJoin3(Home, '.cursor', 'mcp.json');
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
  Say('Snippet MCP gravado em ' + PathJoin(ClaudeDir, 'pascal-anything.mcp.json'));
  Say('Mescle no MCP do Cursor/Claude se ainda não estiver. Binário: ' + SelfBin);
  Say('Reinicie o agente após o setup.');
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
          Md.Add('# Plano de migração → Free Pascal / Lazarus');
          Md.Add('');
          Md.Add('- raiz: `' + Root + '`');
          Md.Add('- linguagem detectada: **' + Lang + '**');
          Md.Add('- alvo: **Pascal/Lazarus** (pacote FPC + stubs em `port.pas`)');
          if WholeApp then
            Md.Add('- modo: app inteiro (unidade a unidade, depois lift)');
          Md.Add('');
          Md.Add('## Unidades (ordem sugerida)');
          Md.Add('');
          for I := 0 to Files.Count - 1 do
            Md.Add(Format('%d. `%s`', [I + 1, RelPath(Root, Files[I])]));
          if Files.Count = 0 then
            Md.Add('_Nenhum fonte encontrado para a linguagem._');
          Md.Add('');
          Md.Add('Próximo passo: `pascal-anything bridge <raiz> <unidade>`');
          OutText := Md.Text;
        finally
          Md.Free;
        end;
      end;

      if OutFile <> '' then
      begin
        WriteTextFile(OutFile, OutText);
        Say('Plano escrito em ' + OutFile);
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
    '{ Port stubs — reescreva o comportamento da unidade original aqui.' + LineEnding +
    '  Fonte: ' + UnitName + ' (' + SrcLang + ')' + LineEnding +
    '  Critério de pronto: `pascal-anything gate` passa.' + LineEnding +
    '}' + LineEnding +
    'unit port;' + LineEnding +
    LineEnding +
    '{$mode objfpc}{$H+}' + LineEnding +
    LineEnding +
    'interface' + LineEnding +
    LineEnding +
    '{ TODO: declare as funções exportadas espelhando a API original }' + LineEnding +
    LineEnding +
    'implementation' + LineEnding +
    LineEnding +
    '{ TODO: implemente; não grave resultados de cases.jsonl no código }' + LineEnding +
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
    '{ Lê cases.jsonl e chama as funções de port; imprime JSONL de resultados.' + LineEnding +
    '  O agente completa o despacho por nome de função. }' + LineEnding +
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
    '      { TODO: parse Line, call port, print {"fn":...,"ok":...} or {"fn":...,"err":...} }' + LineEnding +
    '      WriteLn(Line);' + LineEnding +
    '    end;' + LineEnding +
    '  finally' + LineEnding +
    '    SL.Free;' + LineEnding +
    '  end;' + LineEnding +
    'end.' + LineEnding;
end;

function CmdBridge(const ARoot, AUnit, OutDir, PkgName: string;
  Force: Boolean): Integer;
var
  Root, UnitPath, Dest, Name, Lang: string;
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
    SayErr('unidade não encontrada: ' + UnitPath);
    Exit(1);
  end;

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
    SayErr('já existe bridge em ' + Dest + ' (use --force)');
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
    ExportList := TJSONArray.Create;
    Exp := TJSONObject.Create;
    Exp.Add('name', 'TODO');
    Exp.Add('file', UnitPath);
    Exp.Add('note', 'preencha após analisar a unidade');
    ExportList.Add(Exp);
    Manifest.Add('exports', ExportList);
    WriteManifest(Dest, Manifest);
  finally
    Manifest.Free;
  end;

  Task :=
    '# TASK — portar `' + UnitPath + '` → Free Pascal' + LineEnding +
    LineEnding +
    '1. Leia a unidade original e preencha `src/port.pas` com a mesma API.' + LineEnding +
    '2. `pascal-anything record ' + Dest + '`' + LineEnding +
    '3. Complete `harness.lpr` para despachar cada `fn` de `cases.jsonl`.' + LineEnding +
    '4. `pascal-anything build ' + Dest + '` && `pascal-anything diff ' + Dest + '`' + LineEnding +
    '5. Só chame pronto quando `pascal-anything gate ' + Dest + '` passar.' + LineEnding +
    LineEnding +
    'Não copie resultados gravados para dentro do código. Não enfraqueça testes.' + LineEnding;
  WriteTextFile(PathJoin(Dest, TaskFileName), Task);

  Say('Bridge criado em ' + Dest);
  Say('Edite src/port.pas conforme TASK.md, depois: pascal-anything record ' + Dest);
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
      Obj.Add('note', 'substitua rodando o original; agent completa o gravador');
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
  Home: string;
begin
  Home := GetEnvironmentVariable('HOME');
  Candidates[0] := PathJoin(ExtractFilePath(ParamStr(0)), '../scripts/record_python.py');
  Candidates[1] := PathJoin(GetCurrentDir, 'scripts/record_python.py');
  Candidates[2] := PathJoin(Home, 'Documentos/dev/Repositorios/pascal-anything/scripts/record_python.py');
  Candidates[3] := '/home/beto/Documentos/dev/Repositorios/pascal-anything/scripts/record_python.py';
  for I := 0 to High(Candidates) do
  begin
    Result := ExpandFileName(Candidates[I]);
    if FileExists(Result) then
      Exit;
  end;
  Result := '';
end;

function CmdRecord(const ACrate: string; Count: Integer;
  const InputsFile: string): Integer;
var
  Crate, Root, UnitPath, Lang, OutPath, Script, OutS, ErrS: string;
  Manifest: TJSONObject;
  Cases: TStringList;
  Code: Integer;
  Args: array of string;
begin
  Crate := AbsolutePath(ACrate);
  if not LoadManifest(Crate, Manifest) then
  begin
    SayErr('sem ' + ManifestFileName + ' em ' + Crate + ' — rode bridge antes');
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
      if (Script <> '') and (Which('python3') <> '') then
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
        if RunCapture('python3', Args, OutS, ErrS, Code, Root) and (Code = 0) then
        begin
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
            Say('Gravação (original Python) em ' + OutPath + ' (' +
              IntToStr(Cases.Count) + ' casos)');
            Exit(0);
          finally
            Cases.Free;
          end;
        end
        else
          SayErr('recorder Python falhou: ' + ErrS + OutS);
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
        Say('Gerados ' + IntToStr(Count) +
          ' esqueletos de caso. Substitua `ok` pelos retornos do original.');
      end;
      Cases.SaveToFile(OutPath);
      Manifest.Strings['recorded_at'] := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now);
      Manifest.Integers['case_count'] := Cases.Count;
      WriteManifest(Crate, Manifest);
      Say('Gravação em ' + OutPath + ' (' + IntToStr(Cases.Count) + ' casos)');
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
    SayErr('harness.lpr ausente em ' + Crate);
    Exit(1);
  end;
  if Which('fpc') = '' then
  begin
    SayErr('fpc não encontrado — rode pascal-anything doctor');
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
    SayErr('build falhou (exit ' + IntToStr(Code) + ')');
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

function CmdDiff(const ACrate: string): Integer;
var
  Crate, CasesPath, BinHarness, OutS, ErrS, Line: string;
  Code, I, Mismatch, Total: Integer;
  Expected, Got: TStringList;
  EObj, GObj: TJSONData;
begin
  Crate := AbsolutePath(ACrate);
  CasesPath := PathJoin(Crate, CasesFileName);
  if not FileExists(CasesPath) then
  begin
    SayErr('rode record antes');
    Exit(1);
  end;
  BinHarness := PathJoin3(Crate, 'bin', 'harness');
  if not FileExists(BinHarness) then
    BinHarness := PathJoin(Crate, 'harness');
  if not FileExists(BinHarness) then
  begin
    SayErr('binário harness ausente — rode build');
    Exit(1);
  end;

  if not RunCapture(BinHarness, [CasesPath], OutS, ErrS, Code, Crate) then
  begin
    SayErr(ErrS);
    Exit(1);
  end;

  Expected := LoadJsonl(CasesPath);
  Got := TStringList.Create;
  try
    Got.Text := OutS;
    Mismatch := 0;
    Total := 0;
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
          if EObj.AsJSON <> GObj.AsJSON then
          begin
            if (EObj is TJSONObject) and (GObj is TJSONObject) and
               (TJSONObject(EObj).Find('ok') <> nil) then
            begin
              if (TJSONObject(GObj).Find('ok') = nil) or
                 (TJSONObject(EObj).Find('ok').AsJSON <>
                  TJSONObject(GObj).Find('ok').AsJSON) then
              begin
                Inc(Mismatch);
                Say(Format('[%d] mismatch ok', [I]));
              end;
            end
            else
            begin
              Inc(Mismatch);
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
    Say(Format('diff: %d/%d ok, %d mismatch', [Total - Mismatch, Total, Mismatch]));
    if Mismatch = 0 then
      Result := 0
    else
      Result := 1;
  finally
    Expected.Free;
    Got.Free;
  end;
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
begin
  Crate := AbsolutePath(ACrate);
  Failures := 0;
  Say('gate ' + Crate);

  GateCheck('manifest', FileExists(PathJoin(Crate, ManifestFileName)),
    ManifestFileName, 'pascal-anything bridge ...', Failures);

  PortPath := PathJoin3(Crate, 'src', 'port.pas');
  GateCheck('port.pas', FileExists(PortPath), PortPath,
    'preencha src/port.pas', Failures);

  if FileExists(PortPath) then
  begin
    PortSrc := ReadTextFile(PortPath);
    HasTodo := (Pos('TODO', PortSrc) > 0);
    GateCheck('ported', not HasTodo, 'sem marcadores TODO em port.pas',
      'implemente as funções ainda stubadas', Failures);
  end;

  CasesPath := PathJoin(Crate, CasesFileName);
  GateCheck('recording', FileExists(CasesPath), CasesFileName,
    'pascal-anything record ' + Crate, Failures);

  GateCheck('build',
    FileExists(PathJoin3(Crate, 'bin', 'harness')) or FileExists(PathJoin(Crate, 'harness')),
    'binário harness', 'pascal-anything build ' + Crate, Failures);

  if FileExists(CasesPath) and
     (FileExists(PathJoin3(Crate, 'bin', 'harness')) or FileExists(PathJoin(Crate, 'harness'))) then
  begin
    if CmdDiff(Crate) = 0 then
      GateCheck('behavior', True, 'todos os casos batem', '', Failures)
    else
      GateCheck('behavior', False, 'há mismatches',
        'pascal-anything diff ' + Crate, Failures);
  end;

  if LoadManifest(Crate, Manifest) then
  try
    Manifest.Booleans['gate_passed'] := Failures = 0;
    Manifest.Strings['gate_at'] := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now);
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
    Say('GATE FAIL (' + IntToStr(Failures) + ')');
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
      SayErr('nenhuma unidade candidata em ' + Root);
      Exit(1);
    end;
    UnitId := RelPath(Root, Files[0]);
    Say('go: perfil simples → unidade quente candidata: ' + UnitId);
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
    Say('Portar ' + PathJoin(Dest, 'src/port.pas') + ' conforme TASK.md, depois:');
    Say('  pascal-anything build ' + Dest);
    Say('  pascal-anything gate ' + Dest);
  finally
    Files.Free;
  end;
end;

function CmdReport(const ACrate: string): Integer;
var
  Crate, ReportDir: string;
  Manifest: TJSONObject;
  Md: TStringList;
  Cases: Integer;
begin
  Crate := AbsolutePath(ACrate);
  if not LoadManifest(Crate, Manifest) then
  begin
    SayErr('manifest ausente');
    Exit(1);
  end;
  try
    Cases := JsonInt(Manifest, 'case_count', 0);
    ReportDir := PathJoin(Crate, 'report');
    EnsureDir(ReportDir);
    Md := TStringList.Create;
    try
      Md.Add('# Relatório pascal-anything');
      Md.Add('');
      Md.Add('- pacote: `' + JsonStr(Manifest, 'package_name', '') + '`');
      Md.Add('- unidade: `' + JsonStr(Manifest, 'unit', '') + '`');
      Md.Add('- casos: ' + IntToStr(Cases));
      Md.Add('- gate: ' + BoolToStr(JsonBool(Manifest, 'gate_passed', False), True));
      Md.Add('- enabled: ' + BoolToStr(JsonBool(Manifest, 'enabled', False), True));
      Md.Add('');
      Md.Add('Gerado por ' + AppName + ' ' + AppVersion);
      WriteTextFile(PathJoin(ReportDir, 'REPORT.md'), Md.Text);
      Say('Relatório em ' + PathJoin(ReportDir, 'REPORT.md'));
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
    SayErr('manifest ausente');
    Exit(1);
  end;
  try
    if Enable and (not JsonBool(Manifest, 'gate_passed', False)) then
    begin
      SayErr('gate ainda não passou — enable recusado');
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
  Say('Regras pascal-anything (espelho do fluxo rust-anything, alvo Pascal/Lazarus):');
  Say('1. O original é a verdade — grave com record, prove com diff/gate.');
  Say('2. Uma unidade por vez; gate passa antes da próxima.');
  Say('3. Não cole resultados de cases.jsonl no código.');
  Say('4. Não enfraqueça testes nem edite cases para forçar pass.');
  Say('5. Alvo: Free Pascal + Lazarus (pacotes .lpk/.pas, LCL quando for GUI).');
  Say('6. API dos callers permanece estável até o enable.');
  Result := 0;
end;

function CmdVersion: Integer;
begin
  Say(AppName + ' ' + AppVersion);
  Result := 0;
end;

function CmdHelp: Integer;
begin
  Say('Pascal Anything — reescreva qualquer app em Free Pascal/Lazarus, unidade a unidade.');
  Say('');
  Say('Uso: pascal-anything <comando> [opções]');
  Say('');
  Say('Comandos:');
  Say('  doctor                         verifica fpc/lazbuild/runtimes');
  Say('  setup [repo]                   instala skill + snippet MCP nos agentes');
  Say('  analyze [root] [--json] [--whole-app] [--lang L] [-o file]');
  Say('  bridge <root> <unit> [--out DIR] [--name NAME] [--force]');
  Say('  record [crate] [--count N] [--inputs file.jsonl]');
  Say('  build [crate]');
  Say('  diff [crate]');
  Say('  gate [crate]');
  Say('  go [root] [-- cmd...]');
  Say('  enable|disable [crate]');
  Say('  report [crate]');
  Say('  rules');
  Say('  version | help');
  Say('');
  Say('Loop: analyze → bridge → record → port.pas → build → diff → gate');
  Result := 0;
end;

end.
