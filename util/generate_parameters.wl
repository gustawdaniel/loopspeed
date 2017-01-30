(*MathematicaScript -script util/generate_parameters.wl*)

Needs["DatabaseLink`"]
conn = OpenSQLConnection[
  JDBC["SQLite", $InitialDirectory <> "/log/log.db"]];

Print["Conection with database established..."];

list = Flatten[
  SQLExecute[conn, "SELECT name FROM log GROUP BY name"]];
data = Table[{i,
  SQLExecute[conn,
    "SELECT size,time FROM log WHERE name='" <> ToString[i] <>
        "'"]}, {i, list}];

Print["Data extracted from database..."];

nlm = NonlinearModelFit[Log[data[[#, 2]]],
  Log[Exp[a] Exp[x] + b^2], {a, b}, x] & /@ Range[list // Length];

Print["Nonlienear models calculated..."];

nameABlist = {list[[#]],
  Exp[a],
  b^2,
  Exp[a]*nlm[[#]]["ParameterErrors"][[1]],
  Abs[2*b]*nlm[[#]]["ParameterErrors"][[2]]} /. nlm[[#, 1, 2]] & /@
    Range[Length[list]];

Print["Parameters extracted from models..."];

Export[$InitialDirectory <> "/config/parameters.csv",
  SetPrecision[nameABlist, 10]];

Print["Parameters saved to file. Process finished correctly."];
Exit[];
