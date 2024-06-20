return enum("Dox.SYNTAX",
{
"ADA",
"ASSEMBLY_NASM",
"C",
"C_SHARP",
"C_PLUS_PLUS",
"CSS",
"DART",
"ELM",
"F_SHARP",
"FORTRAN",
"GO",
"GROOVY",
"HASKELL",
"HTML",
"JAVA",
"JAVASCRIPT",
"JULIA",
"KOTLIN",
"LUA",
"MATLAB",
"OBJECTIVE_C",
"PERL",
"PHP",
"PYTHON",
"RUBY",
"RUST",
"SCALA",
"SWIFT",
"TYPESCRIPT",
"XML"
},
{
DoxSyntax("Ada",                  "--",       "--",       "\\",     "ada"),
DoxSyntax("Assembly (NASM)",      "%{",       "%}",       "\\",     "asm6502"),
DoxSyntax("C",                    "/*",       "*/",       "\\",     "c"),
DoxSyntax("C#",                   "/*",       "*/",       "\\",     "csharp"),
DoxSyntax("C++",                  "/*",       "*/",       "\\",     "cpp"),
DoxSyntax("CSS",                  "/*",       "*/",       "\\",     "css"),
DoxSyntax("Dart",                 "/*",       "*/",       "\\",     "dart"),
DoxSyntax("Elm",                  "{-",       "-}",       "\\",     "elm"),
DoxSyntax("F#",                   "(*",       "*)",       "\\",     "fsharp"),
DoxSyntax("Fortran",              "!",        "\\n",      "\\",     "fortran"),
DoxSyntax("Go",                   "/*",       "*/",       "\\",     "go"),
DoxSyntax("Groovy",               "/*",       "*/",       "\\",     "groovy"),
DoxSyntax("Haskell",              "{-",       "-}",       "\\",     "haskell"),
DoxSyntax("HTML",                 "<!--",     "-->",      "\\",     "markup"),
DoxSyntax("Java",                 "/*",       "*/",       "\\",     "java"),
DoxSyntax("JavaScript",           "/*",       "*/",       "\\",     "javascript"),
DoxSyntax("Julia",                "#=",       "=#",       "\\",     "julia"),
DoxSyntax("Kotlin",               "/*",       "*/",       "\\",     "kotlin"),
DoxSyntax("Lua",                  "--[[",     "]]",       "\\",     "lua"),
DoxSyntax("Matlab",               "%{",       "%}",       "\\",     "matlab"),
DoxSyntax("Objective-C",          "/*",       "*/",       "\\",     "objectivec"),
DoxSyntax("Perl",                 "=pod",     "=cut",     "\\",     "perl"),
DoxSyntax("PHP",                  "/*",       "*/",       "\\",     "php"),
DoxSyntax("Python",               '"""',      '"""',      "\\",     "python"),
DoxSyntax("Ruby",                 "=begin",   "=end",     "\\",     "ruby"),
DoxSyntax("Rust",                 "/*",       "*/",       "\\",     "rust"),
DoxSyntax("Scala",                "/*",       "*/",       "\\",     "scala"),
DoxSyntax("Swift",                "/*",       "*/",       "\\",     "swift"),
DoxSyntax("TypeScript",           "/*",       "*/",       "\\",     "typescript"),
DoxSyntax("XML",                  "<!--",     "-->",      "\\",     "markup"),
},
true);
