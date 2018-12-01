---
title: "if_pyth (= the python interface) cookbook"
date: 2018-10-14T11:11:59+02:00
publishDate: 2018-12-10
draft: true
description: An article on this or that.
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
python interface. I do not wish to particularly endorse python out of all
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

command -range ReplaceToken :<line1>,<line2>pydo return my_replace_string(line, "(token)", "MyReplacement");
```

Save this as `if_pyth-linewise.vim` and then `:source` it and you can do
`:%ReplaceToken` or similar, like this:

- Processing an entire subrange / selection of lines at once
- Accessing vimscript variables and registers
- Writing vimscript functions in python.

Ideas/comments/feedback appreciated :)
