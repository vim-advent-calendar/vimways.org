---
title: "if_pyth (= the python interface) cookbook"
date: 2018-10-14T11:11:59+02:00
publishDate: 2018-12-10
draft: true
description: Describe how to achieve some commonly desired idioms using the vim python interface
author:
  name: "Shlomi Fish"
  email: "shlomif@cpan.org"
  github: "shlomif"
  picture: "https://secure.gravatar.com/avatar/ac125fe03b42874a2d82175f16f5b8e3?s=400"
  twitter: "@shlomif"
  irc: "rindolf"
  homepage: "https://www.shlomifish.org/"
---

# if_pyth (= the python interface) cookbook

## Why if_pyth

We might as well admit that Vimscript has its share of limitations and quirky
behaviours. Luckily, Vim (and NeoVim) provides binding to
[Python](https://en.wikipedia.org/wiki/Python_%28programming_language%29),
[Perl](https://en.wikipedia.org/wiki/Perl),
[Ruby](https://en.wikipedia.org/wiki/Ruby_%28programming_language%29),
and other programming languages. Using them also allows you to use packages
from these languages' package repositories such as
[PyPI](https://en.wikipedia.org/wiki/Python_Package_Index) and to write or use
extensions in C, C++ or similar.

This article aims to be a cookbook for using
[if_pyth](http://vimdoc.sourceforge.net/htmldoc/if_pyth.html) which is Vim's
Python interface. I do not wish to particularly endorse Python out of all
possible languages, it's just that I am now trying to learn it better and so am
trying to use it as much as possible.

## Processing/filtering each line in a range of lines

For this example, we will replace all occurrences of the raw string `(token)`
with the replacement string `MyReplacement` in each line in a range:

```vim
py << EOF
import vim
import string

def my_replace_string(s, needle, repl):
    return string.replace(s, needle, repl)

EOF

command! -range ReplaceToken :<line1>,<line2>pydo return my_replace_string(line, "(token)", "MyReplacement");
```

Save this as `if_pyth-linewise.vim` and then `:source` it and you can do
`:%ReplaceToken` or similar, like this:

![Linewise Filtering Demo](shlomif-if_pyth--termtosvg--linewise.svg)

## Processing an entire subrange / selection of lines at once

For this example, we will replace all occurrences of the raw string `(index)`
with consecutive indices in a range:

```vim
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
```

Some notes:

1. Note the use of `join` and `split` to convert from a list/array of lines to a single, multi-line, string and back.
2. Wrapping the index inside a list is needed so it can be changed by the inner subroutine.
3. `vim.current.range` contains the current range.

## Accessing Vimscript variables and registers

The only reliable way I found to access Vimscript variables and registers is by using
`vim.eval('myvar')` or `vim.eval('@a')` (for accessing the `a` register). E.g.:

```vim
py << EOF
import vim
import string

def var_replace(s):
    needle = vim.eval('needle')
    replacement = vim.eval('@a')
    return string.replace(s, needle, replacement)

EOF

command! -range VarBasedReplace :<line1>,<line2>pydo return var_replace(line);
```

## Writing Vimscript functions in python.

In order to this reliably, I was able to pass values using vim global variables,
and use `pyeval()` and `vim.eval()`. E.g:

```vim
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
```

Now we are able to do:

```vim
:echo MyReplace("rescue Brian", "r", "w")
```

