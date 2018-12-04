py << EOF
import vim
import string

def var_replace(s):
    needle = vim.eval('needle')
    replacement = vim.eval('@a')
    return string.replace(s, needle, replacement)

EOF

command! -range VarBasedReplace :<line1>,<line2>pydo return var_replace(line);
