---
title: "Indentation Without Dents"
publishDate: 2019-12-04
draft: true
description: "Indenting by expression to change your expression into a happy one"
author:
  name: "Axel Forsman"
  email: "axelsfor@gmail.com"
  github: "axelf4"
---

> Multiline function invocations generally follow the same rule as for
> signatures.  However, if the final argument begins a new block, the contents
> of the block may begin on a new line, indented one level.
>
> – Style Guidelines, Rust Documentation

Automatic indentation can be a great joy to use - but also equally irritating when implemented incorrectly. In this article I will attempt to guide you through writing a Vim indentation plugin for a subset of the MATLAB programming language. Just so that we are all on the same page, here is an example of what we want to be able to indent:

```matlab
if true, disp foo, end

if true, if true
		A = [8 1
			3 5];
	end, end
```

While Vim indentation plugins are just files with Ex commands like any other Vim runtime files, there exist some hoops that facilitate interplay between plugins and the user's configuration. Filetype specific indenting is enabled by the `filetype indent on` command (see [`help :filetype-indent-on`][cmd-filetype-indent-on]). What this does is load the [`indent.vim`][vim-indent] file, which adds an autocommand that runs `runtime indent/{filetype}.vim` once per buffer for the current filetypes.
Recall that [`:runtime`][cmd-runtime] sources the file in each directory in the order they are found in [`'runtimepath'`][opt-runtimepath], which on Unix-like systems defaults to something like: `"$HOME/.vim, …, $VIMRUNTIME, …"`. Now say that we create a new MATLAB indent plugin in `$HOME/.vim/indent/matlab.vim` to replace the default one found at `$VIMRUNTIME/indent/matlab.vim`. How would Vim know which one to choose?

The answer to that question is that indent plugins are assumed to start off with a so-called *load guard:*

```vim
" Only load if no other indent file is loaded
if exists('b:did_indent') | finish | endif
let b:did_indent = 1
```

This checks whether the current buffer has the `b:did_indent` variable defined (the `b:` prefix designates a variable local to the current buffer). If so, we halt execution, otherwise we define it and continue. Since our home directory by default is earlier in `'runtimepath'` than `$VIMRUNTIME`, our new plugin gets a shot first at configuring indentation, and so the default plugin stops and does nothing!

## How to indent: `'indentexpr'`

Next up we will have to actually hook into Vim's indentation mechanism. Vim already has good support for indenting C-like languages. For other languages, however, this is done through two options, of which we will start with the first one: [`'indentexpr'`][opt-indentexpr]. When Vim calculates the proper indent for a line it evaluates `'indentexpr'` with the [`v:lnum`][var-lnum] variable and cursor set to the line in question. The result should be the number of spaces of indentation (or `-1` for keeping the current indent).
Writing the whole indent routine in a string expression would get cramped, so let's define a function `GetMatlabIndent()` and set `'indentexpr'` to call it:

```vim
setlocal indentexpr=GetMatlabIndent()

" Only define the function once
if exists("*GetMatlabIndent") | finish | endif

function! GetMatlabIndent()
	return 0
endfunction
```

We use [`:setlocal`][cmd-setlocal] to only set `'indentexpr'` in the current buffer. While this has to be done once per buffer, it suffices to define `GetMatlabIndent()` only when running the script for the first time. Thus we check and only define the function when necessary (remember to comment out when developing iteratively!). For now we will have the code stick to the left margin by always returning an indentation of zero spaces for every line.

Later we are going to want to return other indentations than zero. To honor the user's choice of [`'shiftwidth'`][opt-shiftwidth], the number of spaces to use per indent step, we will shift focus to indentation levels and therefore return `indentlvl * shiftwidth()` instead, which is also easier to reason about. (Sidenote: [`shiftwidth()`][func-shiftwidth] is a simple wrapper around the user option `'shiftwidth'`, that takes care of some intricacies such as using [`'tabstop'`][opt-tabstop] when `'shiftwidth'` is zero.)

So how do we actually obtain the indentation level? Well, this is obviously going to depend a lot on the language. In the existence of some official style guide, trying to make indentation conform to that would be a great idea. Here I have tried to mimic the MATLAB R2018b editor. Let's start with what a naïve implementation could look like:

```vim
let prevlnum = prevnonblank(v:lnum - 1) " Get number of last non-blank line
let result = 0
if getline(prevlnum) =~ '\C^\s*\%(for\|if\| ... \|enumeration\)\>'
	let result += 1 " If last line opened a block: indent one level
endif
if getline(v:lnum) =~ '\C^\s*\%(end\|else\|elseif\|case\|otherwise\|catch\)\>'
	let result -= 1 " If current line closes a block: dedent one level
endif
" Get indentation level of last line and add new contribution
return (prevlnum > 0) * indent(prevlnum) + result * shiftwidth()
```

While a great start, this falls down pretty quickly, the reason being that MATLAB, like many other languages, supports opening multiple blocks per line. For example:

```matlab
if true, if true
		disp Hello
	end
end
```

## Counting stuff with `search*()` and friends

Clearly we a way to need to count all block openers/closers and not only the first on each line. Let us define a function `s:SubmatchCount()` that takes a line number, a pattern and optionally a column and counts the occurrences of each [*sub-expression*][doc-sub-expression] in the pattern on the specified line, up to a given column, or, otherwise, the whole line:

```vim
function! s:SubmatchCount(lnum, pattern, ...)
	let endcol = a:0 >= 1 ? a:1 : 1 / 0
	...
endfunction
```

Some peculiarities about optional parameters in Vimscript: the `...` specifies that the function takes a variable number of extra arguments, the number of which is given by `a:0` - `a:1` would then be the first extra argument. So if there is at least an extra argument we set `endcol` to it, otherwise to `1 / 0` which evaluates to `Infinity`. Then in the function body we employ `searchpos()` to find the next match:

```vim
let x = [0, 0, 0, 0] " Create List to store counts in
call cursor(a:lnum, 1) " Set cursor to start of line
while 1
	" Search for pattern and move cursor to match
	" The `c` flag means we accept a match at the cursor position
	" And the `e` flag says that the cursor should be placed at the end of the match
	" With the `p` flag we get the index of the submatch that matched
	let [lnum, c, submatch] = searchpos(a:pattern, 'cpe', a:lnum)
	" If found no match, or match is past endcol, break
	if !submatch || c >= endcol | break | endif
	" If the match is not part of a comment or a string
	if !s:IsCommentOrString(lnum, c)
		" Increment counter. submatch is one more than the first submatch in the pattern
		let x[submatch - 2] += 1
	endif
	" Try to move the cursor one step to the right to not match the same text again
	" If it remained in place we hit the end of the line: break
	if cursor(0, c + 1) == -1 || col('.') == c | break | endif
endwhile
return x
```

The list `x` contains four elements because that many ought to be enough. The referenced function `s:IsCommentOrString()` is interesting because it is very useful for most indentation scripts. Here is how we define it:

```vim
" Returns whether a comment or string envelops the specified column.
function! s:IsCommentOrString(lnum, col)
	return synIDattr(synID(a:lnum, a:col, 1), "name")
		\ =~# 'matlabComment\|matlabMultilineComment\|matlabMultilineComment\|matlabString'
endfunction
```

We hook into Vim's syntax machinery to query the name of the syntax item at the specified cursor position and return whether it is a comment or a string. It should also be noted that this is a pretty expensive operation performance wise. Nevertheless, all combined this allows us to accomplish what we set out to do:

```vim
function! s:GetOpenCloseCount(lnum, pattern, ...)
	let counts = call('s:SubmatchCount', [a:lnum, a:pattern] + a:000)
	return counts[0] - counts[1]
endfunction
```

That is, define `s:GetOpenCloseCount()` which returns how many blocks the line opens relative to how many it closes, given a pattern with sub-expressions for opening and closing patterns. The `[…] + a:000` syntax is Vim for concatenating two `List`:s, where `a:000` is a `List` of all extra arguments.

> **A word on `search*()`**: The `search*()` family of functions all accept the `z` flag. What it does is start searching at specified start column, instead of starting at column zero and skipping matches that occur before ([relevant line in source code][vim-search]). I guess this could end up making a difference if `\zs` was used in the pattern, but that is pretty niche. Additionally, adding the `z` flag to all `search*()` invocations lead to a 35% reduction in run time in a quick-and-dirty benchmark (10 s vs 15 s on a 5000 lines long file). The `z` flag was added fairly recently in patch `7.4.984` so you can use:
```vim
let s:zflag = has('patch-7.4.984') ? 'z' : ''
```
to check for it.

## Pay homage to Zalgo

Equipped with the tool to count things that open/close blocks but one question remains: What are we supposed to search for? Time to bring out the ol' trusty regex hammer. Let us define `pair_pat` as the pattern to pass to `s:GetOpenCloseCount()`:

```vim
" All keywords that open blocks
let open_pat = 'function\|for\|if\|parfor\|spmd\|switch\|try\|while\|classdef\|properties\|methods\|events\|enumeration'

let pair_pat = '\C\<\(' . open_pat . '\|'
		\ . '\%(^\s*\)\@<=\%(else\|elseif\|case\|otherwise\|catch\)\)\>'
		\ . '\|\S\s*\zs\(\<end\>\)'
```

Hopefully we can discern the two sub-expressions enclosed by `\(…\)`. Remember that the first one matches things that indent, and the second, things that dedent. So indent for each `open_pat` match in the previous line and on `else/elseif/case/otherwise/catch` at the start of the line ([`\@<=`][doc-lookbehind] signifies positive lookbehind; `^\s*` has to match before what follows). Then we dedent for each `end` that is not at the start of the line (which is handled separately). Now we are able to replace:

```vim
if getline(prevlnum) =~ '\C^\s*\%(for\|if\|enumeration\)\>'
	let result += 1 " If last line opened a block: indent one level
endif
```

with

```vim
if prevlnum
	let result += s:GetOpenCloseCount(prevlnum, pair_pat)
endif
```

Just this alone makes for a rather robust solution for simple languages.

## Reusing intermediate calculations

All warmed up yet? Great! Next I thought it would be fun to see how one could go about implementing indenting of MATLAB brackets. These are interesting for one reason: They require context beyond the current line and the one above. Take, for example, this cell array literal:

```matlab
myCell = {'text'
	{11;
	22; % <-- Not indented twice

	33}
	};
```

When indenting the line containing `22` we have to be aware that we were already inside one pair of braces. We can formulate the following set of rules for indenting the current line, given that `bracketlevel` is the number of nested brackets at the end of the line two lines above the current one, and `curbracketlevel`, one line above:

|                         | `curbracketlevel == 0` | `curbracketlevel > 0` |
|:-----------------------:|:----------------------:|:---------------------:|
| **`bracketlevel == 0`** | -                      | indent                |
| **`bracketlevel > 0`**  | dedent                 | -                     |

Having access to our function `s:GetOpenCloseCount()`, calculating `bracketlevel` and `curbracketlevel` should not prove too much of a hassle. If we are clever we can also deduce that it suffices to only consider lines above with the same indentation, plus the one with less - assuming prior lines are correctly indented. The code becomes, with `s:bracket_pair_pat` as `'\(\[\|{\)\|\(\]\|}\)'`:

```vim
let bracketlevel = 0
let previndent = indent(prevlnum) | let l = prevlnum
while 1
	let l = prevnonblank(l - 1)
	let indent = indent(l)
	if l <= 0 || previndent < indent | break | endif
	let bracketlevel += s:GetOpenCloseCount(l, s:bracket_pair_pat)
	if previndent != indent | break | endif
endwhile

let curbracketlevel = bracketlevel + s:GetOpenCloseCount(prevlnum, s:bracket_pair_pat)
```

Then we can calculate the indentation offset using the above table! However, with this algorithm indentation becomes `O(n^2)` with respect to the number of lines indented. For a single line using the `=` operator this won't matter, but imagine `gg=G` on a 3000 lines long file. Yikes! The key observation is that Vim indents lines in ascending order and that `curbracketlevel` becomes `bracketlevel` for the next line. So we make `bracketlevel` a buffer-local variable, `b:MATLAB_bracketlevel`, namespacing it as appropriate, and update it at the end of `GetMatlabIndent()`! Profit?

Well, now if we were to indent line 29 and then jump to line 42 and indent it as well, we would reuse the potentially wrong value for `b:MATLAB_bracketlevel`. Likewise if we indented a line, then edited it, and tried indenting the line below. Somehow the cache has to be invalidated. The solution lies in the [`b:changedtick`][var-changedtick] variable, which gets incremented for each change (crucially not in-between indenting multiple consecutive lines with `=` however!). Let us introduce `b:MATLAB_lastline` and `b:MATLAB_lasttick` and update these after indenting, allowing us to write:

```vim
if b:MATLAB_lasttick != b:changedtick || b:MATLAB_lastline != prevlnum
	... " Recalculate bracket count like above
endif
```

Back to `O(n)` time complexity again!

## When to indent: `'indentkeys'`

The value of `'indentexpr'` is not evaluated on every keystroke. Instead the option [`'indentkeys'`][opt-indentkeys] defines a string of comma separated keys that should prompt recalculation of the indentation for the current line when typed in Insert mode. The keys follow a particular format that is pretty neatly documented in [`:help indentkeys-format`][doc-indentkeys-format] so I will not go into too much detail here. A cute little trick however is to append `0=elsei` to `'indentkeys'`, which will emulate IDE behavior by making the line jump back one level when typing the `i` before the `f` in `elseif`, as if indentation was calculated on every keystroke. It is just faking it but I find it fun.

## No sandbox play

Execution of indent scripts is not sandboxed; the regular Vim context is used. Changing the cursor position is the only side effect allowed by `'indentexpr'`; it is always restored. All other forms of side effects would become apparent to the user. Editing files is also out of bounds.

The user of your plugin may have several options set that change standard Vim behavior or differ from your configuration. One should be aware of case sensitivity and magic-ness when using regular expressions and strive to write the file such that it works with any option settings.
One such option is the compatible-options that offer vi compatibility; to combat this we can set them to their Vim defaults with [`set cpo&vim`][opt-cpo]. This would for example matter if we used line continuations. Like in so many other instances we store the value set by the user in a temporary in order to set it back to normal after execution:


```vim
let s:keepcpo = &cpo
set cpo&vim
...
let &cpo = s:keepcpo
unlet s:keepcpo
```

Also be aware of certain features not being compiled in. Use the [`has()`][func-has] function to check for available features and [`exists()`][func-exists] for functions, options, et cetera.

---

**Thanks for reading!** Hopefully this article will prove useful to you and generalize to whatever other languages you wish to support. One should also keep in mind that [`cindent()`][func-cindent] can be used to great effect even when using `'indentexpr'` to do some fix-ups, but that is out of scope of this article. Writing indentation scripts can be perilous - but with a healthy test suite set up it can also be rather rewarding. This article should also serve as some kind of argument for why you would want to use something like [*tree-sitter*][tree-sitter] instead of regexes.
The full MATLAB indent file authored by me can be found in [the Vim source tree][matlab-indent].

[CC BY 4.0][license]

[cmd-filetype-indent-on]: https://vimhelp.org/filetype.txt.html#:filetype-indent-on
[cmd-runtime]: https://vimhelp.org/repeat.txt.html#%3Aruntime
[cmd-setlocal]: https://vimhelp.org/options.txt.html#%3Asetlocal
[doc-indentkeys-format]: https://vimhelp.org/indent.txt.html#indentkeys-format
[doc-lookbehind]: https://vimhelp.org/pattern.txt.html#%2F%5C%40%3C%3D
[doc-sub-expression]: https://vimhelp.org/pattern.txt.html#%2F%5C%28
[func-cindent]: https://vimhelp.org/eval.txt.html#cindent%28%29
[func-exists]: https://vimhelp.org/eval.txt.html#exists%28%29
[func-has]: https://vimhelp.org/eval.txt.html#has%28%29
[func-shiftwidth]: https://vimhelp.org/eval.txt.html#shiftwidth%28%29
[license]: https://creativecommons.org/licenses/by/4.0/
[matlab-indent]: https://github.com/vim/vim/blob/53989554a44caca0964376d60297f08ec257c53c/runtime/indent/matlab.vim
[opt-cpo]: https://vimhelp.org/options.txt.html#%27cpo%27
[opt-indentexpr]: https://vimhelp.org/options.txt.html#%27indentexpr%27
[opt-indentkeys]: https://vimhelp.org/options.txt.html#%27indentkeys%27
[opt-runtimepath]: https://vimhelp.org/options.txt.html#%27runtimepath%27
[opt-shiftwidth]: https://vimhelp.org/options.txt.html#%27shiftwidth%27
[opt-tabstop]: https://vimhelp.org/options.txt.html#%27tabstop%27
[tree-sitter]: https://github.com/tree-sitter/tree-sitter
[var-changedtick]: https://vimhelp.org/eval.txt.html#changetick
[var-lnum]: https://vimhelp.org/eval.txt.html#v:lnum
[vim-indent]: https://github.com/vim/vim/blob/master/runtime/indent.vim
[vim-search]: https://github.com/vim/vim/blob/e4f5f3aa3d597ec9188e01b004013a02bceb4026/src/search.c#L751
