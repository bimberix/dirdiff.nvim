if exists("s:is_load")
    finish
endif
let s:is_load = 1

lua dirdiff = require("dirdiff")

"he command-completion-customlist
command -nargs=+ -complete=customlist,v:lua.dirdiff.cmdcomplete DDiff call v:lua.dirdiff.diff_dir(v:false, <f-args>)
command -nargs=+ -complete=customlist,v:lua.dirdiff.cmdcomplete DDiffRec call v:lua.dirdiff.diff_dir(v:true, <f-args>)
