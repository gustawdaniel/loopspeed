(*http://reference.wolfram.com/language/tutorial/WolframLanguageScripts.html*)
(*https://www.wolfram.com/mathematica/new-in-8/mathematica-shell-scripts/create-mathematica-script-from-your-code.html*)
(*/usr/local/bin/MathematicaScript -script inc.wl 40*)

num  = ToExpression[$ScriptCommandLine[[2]]];
For[i = 0, i < num, i++];
Exit[];
