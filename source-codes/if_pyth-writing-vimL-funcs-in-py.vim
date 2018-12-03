py << EOF
import vim
import string

def vim_replace():
    s = vim.eval('g:for_py_string')
    needle = vim.eval('g:for_py_needle')
    repl = vim.eval('g:for_py_repl')
    ret = string.replace(s, needle, repl)
    return ret

EOF

function! MyReplace(str, needle, repl)
    let g:for_py_string = a:str
    let g:for_py_needle = a:needle
    let g:for_py_repl = a:repl
    return pyeval('vim_replace()')
endfunction
