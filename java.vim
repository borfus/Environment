if exists("*CSyntaxAfter")
    call CSyntaxAfter()
endif

syn region javaFuncDef start=+^\s\+\(\(public\|protected\|private\|static\|abstract\|final\|native\|synchronized\)\s\+\)*\(\(void\|boolean\|char\|byte\|short\|int\|long\|float\|double\|\([A-Za-z_][A-Za-z0-9_$]*\.\)*[A-Z][A-Za-z0-9_$]*\)\(<[^>]*>\)\=\(\[\]\)*\s\+[a-z][A-Za-z0-9_$]*\|[A-Z][A-Za-z0-9_$]*\)\s*\ze(+ end=+\ze(+ contains=javaScopeDecl,javaType,javaStorageClass,javaComment,javaLineComment,@javaClasses
let java_highlight_functions = 1
let java_highlight_all = 1

highlight link javaScopeDecl Statement
highlight link javaType Type
highlight link javaDocTags PreProc

syntax match ClassName display '\<\([A-Z][a-z0-9]*\)\+\>'
syntax match ClassName display '\.\@<=\*'
highlight link ClassName Identifier

syntax match Constructor display '\(\(public\|protected\|private\)\s\+\)\@<=\([A-Z][a-z0-9]*\)\+\( *(\)\@='
highlight link Constructor PreProc

syntax match Final '\<[A-Z][A-Z0-9]\+\%(_[A-Z0-9]\+\)*\>'
highlight Final ctermfg=61

syn match javaAnnotation "@\([_$a-zA-Z][_$a-zA-Z0-9]*\.\)*[_$a-zA-Z][_$a-zA-Z0-9]*\>"

