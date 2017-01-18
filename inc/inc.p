program Project1;

Uses sysutils;

{$mode objfpc}

var
  I,r: QWord;
begin

  r:=StrToQWord(ParamStr(1));

  for I := 1 to r do
     (* WriteLn(I); *)
end.

