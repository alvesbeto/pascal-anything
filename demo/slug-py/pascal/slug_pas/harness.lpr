program harness;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, fpjson, jsonparser, port;

var
  SL: TStringList;
  I: Integer;
  Line: string;
  Data: TJSONData;
  Obj: TJSONObject;
  Args: TJSONArray;
  OutObj: TJSONObject;
  Fn, Arg0: string;
begin
  if ParamCount < 1 then
  begin
    WriteLn(StdErr, 'usage: harness <cases.jsonl>');
    Halt(2);
  end;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(ParamStr(1));
    for I := 0 to SL.Count - 1 do
    begin
      Line := Trim(SL[I]);
      if Line = '' then Continue;
      Data := GetJSON(Line);
      try
        Obj := TJSONObject(Data);
        Fn := Obj.Strings['fn'];
        Args := TJSONArray(Obj.Find('args'));
        OutObj := TJSONObject.Create;
        try
          OutObj.Add('fn', Fn);
          if (Fn = 'slugify') and (Args <> nil) and (Args.Count > 0) then
          begin
            Arg0 := Args.Strings[0];
            OutObj.Add('ok', slugify(Arg0));
          end
          else
            OutObj.Add('err', 'unknown fn');
          WriteLn(OutObj.AsJSON);
        finally
          OutObj.Free;
        end;
      finally
        Data.Free;
      end;
    end;
  finally
    SL.Free;
  end;
end.
