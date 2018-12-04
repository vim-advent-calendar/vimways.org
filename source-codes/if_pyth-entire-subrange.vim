py << EOF
import vim
import re

def my_replace_with_numbers(myrange):
    idx = [0]
    def _replace(m):
        idx[0] += 1
        return str(idx[0])
    new_string = re.sub("\\(index\\)", _replace, '\n'.join(myrange[:]))
    myrange[:] = new_string.split('\n')

EOF

command! -range IndexBuf :<line1>,<line2>py my_replace_with_numbers(vim.current.range)
