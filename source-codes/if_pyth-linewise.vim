py << EOF
import vim
import string

def my_replace_string(s, needle, repl):
    return string.replace(s, needle, repl)

EOF

command! -range ReplaceToken :<line1>,<line2>pydo return my_replace_string(line, "(token)", "MyReplacement");
