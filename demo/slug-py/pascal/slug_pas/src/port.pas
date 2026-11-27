unit port;

{$mode objfpc}{$H+}

interface

function slugify(const Text: string): string;

implementation

uses
  SysUtils;

function slugify(const Text: string): string;
var
  S: string;
  I: Integer;
  C: Char;
  LastDash: Boolean;
begin
  S := LowerCase(Trim(Text));
  Result := '';
  LastDash := True;
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if C in ['a'..'z', '0'..'9'] then
    begin
      Result := Result + C;
      LastDash := False;
    end
    else if not LastDash then
    begin
      Result := Result + '-';
      LastDash := True;
    end;
  end;
  if (Result <> '') and (Result[Length(Result)] = '-') then
    SetLength(Result, Length(Result) - 1);
end;

end.
