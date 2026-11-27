unit pa_util;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

const
  AppName = 'pascal-anything';
  AppVersion = '0.2.1';
  SchemaBridge = 'pascal-anything/bridge@1';
  SchemaAnalyze = 'pascal-anything/analyze@1';
  CasesFileName = 'cases.jsonl';
  ManifestFileName = 'pascal-anything.json';
  KnownDiffsFileName = 'known-diffs.jsonl';
  TaskFileName = 'TASK.md';

function AbsolutePath(const APath: string): string;
function PathJoin(const A, B: string): string;
function PathJoin3(const A, B, C: string): string;
function ReadTextFile(const APath: string): string;
procedure WriteTextFile(const APath, AContent: string);
procedure EnsureDir(const APath: string);
function FileExistsSafe(const APath: string): Boolean;
function DirExistsSafe(const APath: string): Boolean;
function Which(const ACmd: string): string;
function RunCapture(const AExe: string; const AArgs: array of string;
  out AStdout, AStderr: string; out AExit: Integer;
  const AWorkDir: string = ''): Boolean;
function RunOk(const AExe: string; const AArgs: array of string;
  const AWorkDir: string = ''): Boolean;
procedure Say(const AMsg: string);
procedure SayErr(const AMsg: string);
procedure BeginCapture;
function EndCapture: string;
function RelPath(const ARoot, APath: string): string;
function SanitizeIdent(const S: string): string;
function DetectLang(const ARoot: string): string;
function StartsWithPath(const AFull, APrefix: string): Boolean;
function SplitPathEnv(const APathEnv: string): TStringList;

implementation

threadvar
  CaptureBuf: TStringList;

procedure BeginCapture;
begin
  if CaptureBuf = nil then
    CaptureBuf := TStringList.Create
  else
    CaptureBuf.Clear;
end;

function EndCapture: string;
begin
  if CaptureBuf = nil then
    Result := ''
  else
  begin
    Result := CaptureBuf.Text;
    FreeAndNil(CaptureBuf);
  end;
end;

function AbsolutePath(const APath: string): string;
begin
  if APath = '' then
    Result := GetCurrentDir
  else
    Result := ExpandFileName(APath);
end;

function PathJoin(const A, B: string): string;
begin
  Result := IncludeTrailingPathDelimiter(A) + B;
end;

function PathJoin3(const A, B, C: string): string;
begin
  Result := PathJoin(PathJoin(A, B), C);
end;

function ReadTextFile(const APath: string): string;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(APath);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure WriteTextFile(const APath, AContent: string);
var
  SL: TStringList;
  Dir: string;
begin
  Dir := ExtractFilePath(APath);
  EnsureDir(Dir);
  SL := TStringList.Create;
  try
    SL.Text := AContent;
    SL.SaveToFile(APath);
  finally
    SL.Free;
  end;
end;

procedure EnsureDir(const APath: string);
begin
  if (APath <> '') and (not DirectoryExists(APath)) then
    ForceDirectories(APath);
end;

function FileExistsSafe(const APath: string): Boolean;
begin
  Result := FileExists(APath);
end;

function DirExistsSafe(const APath: string): Boolean;
begin
  Result := DirectoryExists(APath);
end;

function SplitPathEnv(const APathEnv: string): TStringList;
var
  I, Start: Integer;
  S: string;
begin
  Result := TStringList.Create;
  S := APathEnv;
  Start := 1;
  for I := 1 to Length(S) + 1 do
  begin
    if (I > Length(S)) or (S[I] = PathSeparator) then
    begin
      if I > Start then
        Result.Add(Copy(S, Start, I - Start));
      Start := I + 1;
    end;
  end;
end;

function Which(const ACmd: string): string;
var
  Parts: TStringList;
  I: Integer;
  Candidate: string;
begin
  Result := '';
  if (Pos(PathDelim, ACmd) > 0) and FileExists(ACmd) then
    Exit(ACmd);
  Parts := SplitPathEnv(GetEnvironmentVariable('PATH'));
  try
    for I := 0 to Parts.Count - 1 do
    begin
      if Parts[I] = '' then
        Continue;
      Candidate := PathJoin(Parts[I], ACmd);
      if FileExists(Candidate) then
        Exit(Candidate);
    end;
  finally
    Parts.Free;
  end;
end;

function RunCapture(const AExe: string; const AArgs: array of string;
  out AStdout, AStderr: string; out AExit: Integer;
  const AWorkDir: string): Boolean;
var
  P: TProcess;
  I: Integer;
  OutS, ErrS: TStringStream;
  Resolved: string;
begin
  AStdout := '';
  AStderr := '';
  AExit := -1;
  Result := False;
  Resolved := Which(AExe);
  if Resolved = '' then
  begin
    AStderr := 'command not found: ' + AExe;
    Exit;
  end;
  P := TProcess.Create(nil);
  OutS := TStringStream.Create('');
  ErrS := TStringStream.Create('');
  try
    P.Executable := Resolved;
    for I := 0 to High(AArgs) do
      P.Parameters.Add(AArgs[I]);
    if AWorkDir <> '' then
      P.CurrentDirectory := AWorkDir;
    P.Options := [poUsePipes, poWaitOnExit];
    try
      P.Execute;
      if P.Output.NumBytesAvailable > 0 then
        OutS.CopyFrom(P.Output, P.Output.NumBytesAvailable)
      else
        OutS.CopyFrom(P.Output, 0);
      if P.Stderr.NumBytesAvailable > 0 then
        ErrS.CopyFrom(P.Stderr, P.Stderr.NumBytesAvailable)
      else
        ErrS.CopyFrom(P.Stderr, 0);
      AStdout := OutS.DataString;
      AStderr := ErrS.DataString;
      AExit := P.ExitCode;
      Result := True;
    except
      on E: Exception do
      begin
        AStderr := E.Message;
        Result := False;
      end;
    end;
  finally
    OutS.Free;
    ErrS.Free;
    P.Free;
  end;
end;

function RunOk(const AExe: string; const AArgs: array of string;
  const AWorkDir: string): Boolean;
var
  OutS, ErrS: string;
  Code: Integer;
begin
  Result := RunCapture(AExe, AArgs, OutS, ErrS, Code, AWorkDir) and (Code = 0);
end;

procedure Say(const AMsg: string);
begin
  if CaptureBuf <> nil then
    CaptureBuf.Add(AMsg)
  else
    WriteLn(AMsg);
end;

procedure SayErr(const AMsg: string);
begin
  if CaptureBuf <> nil then
    CaptureBuf.Add(AMsg)
  else
    WriteLn(StdErr, AMsg);
end;

function StartsWithPath(const AFull, APrefix: string): Boolean;
begin
  Result := (Length(AFull) >= Length(APrefix)) and
    (Copy(AFull, 1, Length(APrefix)) = APrefix);
end;

function RelPath(const ARoot, APath: string): string;
var
  R, P: string;
begin
  R := IncludeTrailingPathDelimiter(AbsolutePath(ARoot));
  P := AbsolutePath(APath);
  if StartsWithPath(P, R) then
    Result := Copy(P, Length(R) + 1, MaxInt)
  else
    Result := P;
end;

function SanitizeIdent(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if C in ['a'..'z', 'A'..'Z', '0'..'9', '_'] then
      Result := Result + C
    else if C in ['-', '.', '/', '\', ' '] then
      Result := Result + '_';
  end;
  if (Result = '') or (Result[1] in ['0'..'9']) then
    Result := 'u_' + Result;
end;

function HasPasSources(const ARoot: string): Boolean;
var
  Info: TSearchRec;
  Src: string;
begin
  Result := False;
  Src := PathJoin(ARoot, 'src');
  if not DirectoryExists(Src) then
    Exit;
  if FindFirst(PathJoin(Src, '*.pas'), faAnyFile, Info) = 0 then
  begin
    Result := True;
    FindClose(Info);
  end;
end;

function HasExt(const ARoot, AExt: string): Boolean;
var
  Info: TSearchRec;
begin
  Result := False;
  if FindFirst(PathJoin(ARoot, '*' + AExt), faAnyFile, Info) = 0 then
  begin
    Result := True;
    FindClose(Info);
  end;
end;

function DetectLang(const ARoot: string): string;
begin
  if FileExists(PathJoin(ARoot, 'package.json')) then
    Exit('typescript');
  if FileExists(PathJoin(ARoot, 'pyproject.toml')) or
     FileExists(PathJoin(ARoot, 'setup.py')) or
     FileExists(PathJoin(ARoot, 'requirements.txt')) or
     HasExt(ARoot, '.py') then
    Exit('python');
  if FileExists(PathJoin(ARoot, 'go.mod')) then
    Exit('go');
  if FileExists(PathJoin(ARoot, 'Cargo.toml')) then
    Exit('rust');
  if FileExists(PathJoin(ARoot, 'composer.json')) then
    Exit('php');
  if FileExists(PathJoin(ARoot, 'Gemfile')) then
    Exit('ruby');
  if FileExists(PathJoin(ARoot, 'pom.xml')) or
     FileExists(PathJoin(ARoot, 'build.gradle')) or
     FileExists(PathJoin(ARoot, 'build.gradle.kts')) then
    Exit('java');
  if HasPasSources(ARoot) or FileExists(PathJoin(ARoot, 'pascal-anything.json')) then
    Exit('pascal');
  Result := 'unknown';
end;

end.
