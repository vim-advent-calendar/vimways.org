---
title: "Runtime hackery"
draft: true
description: "Disabling runtime files, setting compilers, and autoloading."
slug: "runtime-hackery"
author:
  name: "Tom Ryder"
  email: "tom@sanctum.geek.nz"
  irc: "tejr"
  homepage: "https://sanctum.geek.nz/"
---

> You have your way. I have my way. As for the right way, the correct way, and
> the only way, it does not exist.
>
> — Friedrich Nietzsche

Enhanced runtime powers
-----------------------

In [an earlier article][ea] on beginning the process of breaking up a long
[vimrc][rc] into a `~/.vim` runtime directory, we hinted at a few more
possibilities for leveraging the runtime directory structure:

1. Disabling specific parts of the stock runtime directory
2. Writing custom compiler definitions
3. Automatically loading functions only when they’re called

In this followup article, we’ll go through each of these, further demonstrating
how you can use the [`'runtimepath'`][ro] structure and logic to your benefit.

That’s nice, but it’s wrong
---------------------------

Sometimes, you just plain don’t like something that the stock runtime files
bundled with Vim do. You don’t want to edit the included runtime files
directly, because they’ll just get overwritten again the next time you upgrade
Vim. You don’t want to maintain a hacked-up copy of the full runtime files in
your own configuration, either. It would be best to find a way to work *around*
the unwanted lines. Fortunately, `'runtimepath'` lets us do exactly that.

### Variable options

Accommodating plugin authors will sometimes provide **variable options**,
allowing you to tweak the way the plugin works. You should always look for
these first; you may not even need to read any Vim script to do what you want,
as the relevant options are often described in [`:help`][he] topics.

For example, the stock indenting behavior for the `html` filetype does not add
a level of indentation after opening a paragraph block with a `<p>` tag, even
though it *does* add indentation after an element like `<body>`. Fortunately,
there’s a [documented option variable][hi] that modifies this behavior named
`html_indent_inctags`, which we can define in `~/.vim/indent/html.vim`. This
will get loaded just *before* `$VIMRUNTIME/indent/html.vim`:

```vim
" Indent after <p> paragraph tags too
let html_indent_inctags = 'p'
```

This changes the behavior in the way we need. To be tidy, we should clear the
variable away again afterwards in `$VIMRUNTIME/after/indent/html.vim`, since
after the stock file has run, this global variable has done its job:

```vim
" Clear away global variable set as indent option
unlet html_indent_inctags
```

### Reversing unwanted configuration

Other times, the behavior annoying you may be just a little thing that’s not
directly configurable, but it’s still easy enough to *reverse* it.

For example, if you’re a Perl developer, you might find it annoying that when
editing buffers with the `perl` filetype, the `#` **comment leader** is
automatically added when you press "Enter" in insert mode while composing a
comment. You would rather type (or not type) it yourself, as the `python`
filetype does by default.

You might check the Vim documentation, and find this unwanted behavior is
caused by the [`r` flag][ft]’s presence in the value of the
[`'formatoptions'`][fo] option. You didn’t set that in your vimrc, and it only
happens to buffers with the `perl` filetype, so you check
`$VIMRUNTIME/ftplugin/perl.vim` to find what’s setting the unwanted flag.

Sure enough, you find this line:

```vim
setlocal formatoptions+=crqol
```

It doesn’t look like there’s a variable option you can set to *prevent* the
setting, so instead you add in a couple of lines to
`~/.vim/after/ftplugin/perl.vim` to *correct* it after the stock plugin has
loaded:

```vim
setlocal formatoptions-=r
```

You reload your `perl` buffer, and examine the value of `'formatoptions'`; sure
enough, the `r` flag has gone, and the unwanted behavior has stopped.

```vim
:set formatoptions?
  formatoptions=jcrqol
```

Note that you didn’t need to add a [`b:undo_ftplugin`][uf] command in this
case, because the stock filetype plugin already includes a revert command for
`'formatoptions'`, so you can fix this problem with just one line.

### Blocking unwanted configuration

Maybe it’s not just a little thing, though. Perhaps a filetype plugin or indent
plugin for a given language just does everything completely wrong for you.

For example, suppose you’re annoyed with the stock indenting behavior for
`php`. You can’t predict where you’ll end up on any new line, you can’t
configure it to make it work the way you want it to, and it’s too frustrating
to deal with it. Rather than carefully undoing each of the plugin’s settings,
you decide it would be better if all near-1000 lines of
`$VIMRUNTIME/indent/php.vim` just didn’t load at all, so you can go back to
plain old [`'autoindent'`][ai] until you can find or write something better.

Fortunately, at the very beginning of the disliked file, we find a **load
guard**:

```vim
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1
```

This cuts the whole script off at the [`:finish`][fi] command if `b:did_indent`
has been set. This suggests that if we set that variable *before* this script
loads, we could avoid its mess entirely. We add three lines to a new file in
`~/.vim/indent/php.vim`, and we’re done:

```vim
let b:did_indent = 1
setlocal autoindent
let b:undo_indent = 'setlocal autoindent<'
```

The stock `$VIMRUNTIME/indent/php.vim` still loads after this script, and will
still appear in the output of [`:scriptnames`][sn], but execution never gets
past the load guard, leaving our single setting of `'autoindent'`intact.

In doing the above, we’ve now replaced the `php` indent plugin with our own.
Perhaps we’ll refine it a bit more later, or write an [`'indentexpr'`][ie] for
it that we prefer.

### Advanced example

Sometimes, working around this type of issue requires a little more careful
analysis of the order in which things are sourced, and a bit more tweaking.

For example, suppose you don’t like the fact that the `html` filetype plugin is
loaded for `markdown` buffers, and set out to prevent this behavior. You hope
that there’s going to be an option that allows you to do this, and you start by
looking in `$VIMRUNTIME/ftplugin/markdown.vim`.

Unfortunately, in that file you find that the behavior is hard-coded, and runs
unconditionally:

```vim
runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
```

That line runs all the filetype plugins it can find for the `html` filetype. We
can’t coax the stock plugin into disabling the unwanted behavior, but we don’t
want to completely *disable* the stock plugin for `markdown` or `html` as
primary buffer filetypes, either. What to do?

Perhaps there’s a way to disable *just* the filetype plugins for `html`, and
*only* when the active buffer is actually a `markdown` buffer? Looking at
`$VIMRUNTIME/ftplugin/html.vim`, we notice our old friend the load guard:

```vim
if exists("b:did_ftplugin") | finish | endif
```

It looks like if we can set `b:did_ftplugin` immediately before this script
loads, we can meet our goal. Sure enough, putting this in
`~/.vim/ftplugin/html.vim` does the trick:

```vim
if &filetype ==# 'markdown'
  let b:did_ftplugin = 1
endif
```

Checker, linter, candlestick-maker
----------------------------------

One of the lesser-used subdirectories in the Vim runtime directory structure is
`compiler`. This is for files that set the [`'makeprg'`][mp] and
[`'errorformat'`][ef] options so that a useful [`:make`][mk] or [`:lmake`][ml]
command runs for the current buffer, and any output or errors that the program
returns are correctly interpreted according to the value of `'errorformat'` for
use in the [quickfix][qf] or [location][ll] lists. The files defining these two
options are sourced using the [`:compiler`][cm] command.

Vim includes some `compiler` definitions in its runtime files, and not just for
C or C++ compilers; there’s `$VIMRUNTIME/compiler/tidy.vim` for HTML checking,
and `$VIMRUNTIME/compiler/perl.vim` for Perl syntax checking, to name just a
couple. You can also write your own definitions, and put them in
`~/.vim/compiler`.

Note that there’s no particular need for the program named by `'makeprg'` to
have anything to do with an actual `make` program, nor a compiler for a
compiled language; it can just as easily be a **syntax checker** to identify
erroneous constructs, or a **linter** to point out bad practices that aren’t
necessarily errors. What the `:compiler` command provides for the user is an
abstraction for configuring these, and switching between them cleanly.

### Switching between compilers

As an example to make the usefulness of this clear, consider how we might like
to specify `'makeprg'` and `'errorformat'` for editing shell scripts written
for GNU Bash. Bash can be an [awkward and difficult language][pf], and if we
have to write a lot of it, ideally we’d want a linter as well as a syntax
checker to let us know if we write anything potentially erroneous.

Here are two different tools for syntax checking and linting Bash, both with
potential as `compiler` definitions:

* [`bash -n`][bn] will **check** the syntax of a shell script, to establish
  whether it will run at all.
* [`shellcheck -s bash`][sc] will **lint** it, looking for bad practices in a
  shell script that might misbehave in unexpected ways.

Ideally, a Bash programmer would want to be able to run *either* of these
programs, switching between them as needed, without losing the benefit of
showing the output in the quickfix or location list when `:make` or `:lmake` is
run. So, let’s write a script to accommodate that.

First of all, because this logic is specific to the `sh` filetype, we decide to
put it in a filetype plugin in `~/.vim/after/ftplugin`, perhaps named
`compiler.vim`. This is because there’s no point enabling switching between
these two programs for any other filetype.

After experimenting with the values for ``makeprg'` and `'errorformat'`, and
testing them by running `:make` on a few Bash files and inspecting the output
in the quickfix list with `:copen`, we find the following values work well:

```vim
" Bash
makeprg=bash\ -n\ --\ %:S
errorformat=%f:\ line\ %l:\ %m
" ShellCheck
makeprg=shellcheck\ -s\ bash\ -f\ gcc\ --\ %:S
errorformat=%f:%l:%c:\ %m\ [SC%n]
```

To switch between the two sets of values, we might set up functions and
mappings like so, using `,b` for `bash` and `,s` for `shellcheck`:

```vim
function! s:SwitchCompilerBash() abort
  setlocal makeprg=bash\ -n\ --\ %:S
  setlocal errorformat=%f:\ line\ %l:\ %m
endfunction
function! s:SwitchCompilerShellCheck() abort
  setlocal makeprg=shellcheck\ -s\ bash\ -f\ gcc\ --\ %:S
  setlocal errorformat=%f:%l:%c:\ %m\ [SC%n]
endfunction
nnoremap <buffer> ,b
      \ :<C-U>call <SID>SwitchCompilerBash()<CR>
nnoremap <buffer> ,s
      \ :<C-U>call <SID>SwitchCompilerShellCheck()<CR>
let b:undo_ftplugin .= '|setlocal makeprg< errorformat<'
      \ . '|nunmap <buffer> ,b'
      \ . '|nunmap <buffer> ,s'
```

This works, but there’s quite a lot going on here for something that seems like
it should be simpler. It would be nice to avoid all the [script-variable][sv]
function scaffolding in particular, preferably without having to try to work
the complex definitions for the settings into the mappings directly.

### Separating compiler definitions out

The `:compiler` command allows us to separate this logic out somewhat, by
putting the options settings in separate files in `~/.vim/compiler`.

Our `~/.vim/compiler/bash.vim` file might look like this:

```vim
setlocal makeprg=bash\ -n\ --\ %:S
setlocal errorformat=%f:\ line\ %l:\ %m
```

Similarly, our `~/.vim/compiler/shellcheck.vim` might look like this:

```vim
setlocal makeprg=shellcheck\ -s\ bash\ -f\ gcc\ --\ %:S
setlocal errorformat=%f:%l:%c:\ %m\ [SC%n]
```

With these files installed, we can test switching between them with
`:compiler`:

```vim
:compiler bash
:set errorformat? makeprg?
  errorformat=%f: line %l: %m
  makeprg=bash -n -- %:S
:compiler shellcheck
:set errorformat? makeprg?
  errorformat=%f:%l:%c: %m [SC%n]
  makeprg=shellcheck -s bash -f gcc -- %:S
```

This simple abstraction allows us to refactor the compiler-switching code in
our filetype plugin to the following, foregoing any need for the functions:

```vim
nnoremap <buffer> ,b
      \ :<C-U>compiler bash<CR>
nnoremap <buffer> ,s
      \ :<C-U>compiler shellcheck<CR>
let b:undo_ftplugin .= '|setlocal makeprg< errorformat<'
      \ . '|nunmap <buffer> ,b'
      \ . '|nunmap <buffer> ,s'
```

Note that the above compiler file examples are greatly simplified from the
recommended practices in `:help write-compiler-plugin`. For example, you would
ideally use the `:CompilerSet` command for the options settings. However, for
the purposes of configuring things in your personal `~/.vim`, this is mostly a
detail; you may prefer to keep things simple.

Automatic for the people
------------------------

If a particular script defines long functions that are not actually called that
often, it can make Vim slow to start. This may not be so much of a problem if
the functionality is really useful *and* will always be needed promptly in
every editor session. For functions that are called less often, it would be
preferable to arrange for function definitions to be loaded only at the time
they’re actually needed, to keep Vim startup snappy. This would be particularly
applicable for [`:map`][ma] and [`:autocmd`][ac] targets that are specific to
certain filetypes, especially so if they’re not needed very often.

We’ve already seen that putting such code in filetype-specific plugins where
possible is a great start. We can build further on this with another useful
application of Vim’s runtime directory structure—the [**autoload** system][al].
This approach loads functions at the time they’re called, just before executing
them.

### Candidates for autoloading

Consider the following script-local variable `s:pattern`, and functions
`s:Format()`, `s:Bump`, `s:BumpMinor`, and `s:BumpMajor`, from a filetype
plugin, `perl_version_bump.vim`. This plugin does something very specific: it
finds and increments version numbers in buffers of the `perl` filetype.

```vim
let s:pattern = '\m\C^'
      \ . '\(our\s\+\$VERSION\s*=\D*\)'
      \ . '\(\d\+\)\.\(\d\+\)'
      \ . '\(.*\)'

" Helper function to format a number without decreasing its digit count
function! s:Format(old, new) abort
  return repeat('0', strlen(a:old) - strlen(a:new)).a:new
endfunction

" Version number bumper
function! s:Bump(major) abort
  let l:view = winsaveview()
  let l:li = search(s:pattern)
  if !l:li
    echomsg 'No version number declaration found'
    return
  endif
  let l:matches = matchlist(getline(l:li), s:pattern)
  let [l:lvalue, l:major, l:minor, l:rest]
        \ = matchlist(getline(l:li), s:pattern)[1:4]
  if a:major
    let l:major = s:Format(l:major, l:major + 1)
    let l:minor = s:Format(l:minor, 0)
  else
    let l:minor = s:Format(l:minor, l:minor + 1)
  endif
  let l:version = l:major.'.'.l:minor
  call setline(l:li, l:lvalue.l:version.l:rest)
  if a:major
    echomsg 'Bumped major $VERSION: '.l:version
  else
    echomsg 'Bumped minor $VERSION: '.l:version
  endif
  call winrestview(l:view)
endfunction

" Interface functions
function! s:BumpMinor() abort
  call s:Bump(0)
endfunction
function! s:BumpMajor() abort
  call s:Bump(1)
endfunction
```

There’s no way you would need to load such niche code every time Vim starts.
You probably wouldn’t even want all of it to load it every time you edit a Perl
file—after all, how likely are you to bump the version number of a script every
time you look at it? We’d like to arrange to load all this only when it’s
actually needed.

### Autoloading from mappings to functions

The version bumping plugin ends with mapping targets to its last two functions:

```vim
nnoremap <buffer> <Plug>(PerlBumpMinor)
      \ :<C-U>call <SID>BumpMinor()<CR>
nnoremap <buffer> <Plug>(PerlBumpMajor)
      \ :<C-U>call <SID>BumpMajor()<CR>
```

These [`<Plug>` targets][pt] need to be mapped to by the user’s configuration
in `~/.vim/after/ftplugin/perl.vim`, with the actual keys they want to use.
Here, we’ve used `,b` and `,B`:

```vim
nmap <buffer> ,b <Plug>(PerlBumpMinor)
nmap <buffer> ,B <Plug>(PerlBumpMajor)
```

Ideally, you’d define the `<Plug>` mapping targets in such a way that Vim knows
where to load definitions for the functions they call, and does so only when
they’re actually called. Once loaded, the functions and any variables would
then stay defined as normal for the rest of the Vim session—enabling a kind of
dynamic plugin.

### Autoloading identifier prefixes

Indeed, this is exactly what `autoload` makes possible. We can put the entirety
of the script functions excluding the mapping targets into a file
`~/.vim/autoload/perl/version/bump.vim`, changing nothing except to rename the
last two functions, using the `#`-separated path prefix syntax for autoloading:

```vim
" Interface functions
function! perl#version#bump#BumpMinor() abort
  call s:Bump(0)
endfunction
function! perl#version#bump#BumpMajor() abort
  call s:Bump(1)
endfunction
```

The prefix `perl#version#bump#` for the new function names specifies the
relative runtime path at which Vim should look for the file containing the
function definitions. All of the `#` symbols bar the last one are replaced with
filesystem slashes `/`, and the last one is replaced with `.vim`. This is how
the autoloading process finds the function’s definition at the time it needs
it.

Here are some other examples of autoloaded function names, and where in
`~/.vim` that Vim looks for them:

* `foo#Example()` goes in `~/.vim/autoload/foo.vim`
* `foo#bar#baz#Example()` goes in `~/.vim/autoload/foo/bar/baz.vim`
* `foo#bar#()` goes in `~/.vim/autoload/foo/bar.vim`

Per the last example above, note that there doesn’t actually have to be a
function name following the final `#`. You can use this to load only one
function per file, if you wish.

Similar to the previous [`:runtime`][rt] wrappers we’ve observed, Vim looks
through any `autoload` subdirectories of each directory in `'runtimepath'`, in
order, until a file with a relative path corresponding to the called function’s
prefix is found and sourced.

### Autoloading encapsulation

You might be wondering why we only have to rename the last two functions in our
example. How can this still work if the `s:pattern` variable and the
`s:Format()` and `s:Bump()` functions are still using the `s:` prefix for
script-local scope?

These definitions are still loaded as part of the autoloaded file, even though
they weren’t explicitly referenced or called themselves. They are thereby
pulled in *indirectly* by `perl#version#bump#BumpMinor()` or
`perl#version#bump#BumpMajor()` being autoloaded, and remain visible to those
functions in the same script-level scope. Because they’re only used internally
by our mapped functions, and don’t need to be callable from outside the script,
there’s no need to rename them, and we still get the benefit of deferring their
loading.

In object-oriented terms, you can therefore think of the autoloaded functions
as the **interface** to the plugin, and any script-local variables or functions
that they use as the plugin’s **implementation**.

### Reducing a plugin to just a few lines

With the above restructuring done, we just need to adjust the `<Plug>` mappings
still left in the `ftplugin` to use the new function names. This filetype
plugin now only loads two mappings when the buffer’s `'filetype'` is set to
`perl`. Here is the `ftplugin` file in its entirety:

```vim
nnoremap <buffer> <Plug>(PerlBumpMinor)
      \ :<C-U>call perl#version#bump#BumpMinor()<CR>
nnoremap <buffer> <Plug>(PerlBumpMajor)
      \ :<C-U>call perl#version#bump#BumpMajor()<CR>
let b:undo_ftplugin .= '|nunmap <buffer> <Plug>(PerlBumpMinor)'
      \ . '|nunmap <buffer> <Plug>(PerlBumpMajor)'
```

Applying this process rigorously can shave a lot of wasted time from your Vim
startup process. This was the main design goal for autoloading, as the Vim
plugin ecosystem grew towards the first release of the feature in Vim 7.0.

Carefully examining what needs to load, and when—along with some careful
experimentation—will make clearer to you what code can have its loading
deferred until later. Autoloading is the second-closest thing you have to a
“magic bullet” in [quickening][qk] Vim. The closest thing, of course, is never
to load the code at all, especially if you learn that [the feature you wanted
is already built in][vt]…

Don’t stop me now
-----------------

Over both our articles on this topic, we’ve gone through a whirlwind tour of
the most important parts of good `:runtime` and `'runtimepath'` usage for your
own personal `~/.vim` directory—and yet, with every example, we’ve demonstrated
merely a few simple possibilities of what can be done with it.

The “overlaying” runtime directory approach Vim takes to its configuration is
one of the best things about the editor’s design. It strikes a balance between
enabling detailed customization by Vim enthusiasts and their particular areas
of editing interest, while still working just fine out of the box for everyone
and everything else. Because sharing vimrc files has been a cultural tradition
since the 90s, it’s so easy to overlook what’s possible outside the single-file
box. The Emacs community has adapted readily to sharing [`.emacs.d`
directories][ed], having had [the same problems as we do now][ep]—we need to
catch up!

The author hopes you have a new appreciation for the power that the
much-overlooked `'runtimepath'` design gives to you—all of it gained not by
mastering an entire language like Emacs Lisp, but merely by putting a few
small, relatively simple files in just the right places in your home directory.
There’s some kind of aesthetic appeal in that—maybe even a weird kind of beauty
that only a Vim enthusiast could love.

[ac]: https://vimhelp.appspot.com/autocmd.txt.html#%3Aautocmd
[ai]: https://vimhelp.appspot.com/options.txt.html#%27autoindent%27
[al]: https://vimhelp.appspot.com/eval.txt.html#autoload
[bn]: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
[cm]: https://vimhelp.appspot.com/quickfix.txt.html#%3Acompiler
[ea]: https://vimways.org/2018/from-vimrc-to-vim/
[ed]: http://whattheemacsd.com/
[ef]: https://vimhelp.appspot.com/options.txt.html#%27errorformat%27
[ep]: https://www.emacswiki.org/emacs/DotEmacsBankruptcy
[fn]: https://vimhelp.appspot.com/repeat.txt.html#%3Afinish
[fo]: https://vimhelp.appspot.com/options.txt.html#%27formatoptions%27
[ft]: https://vimhelp.appspot.com/change.txt.html#fo-table
[he]: https://vimhelp.appspot.com/helphelp.txt.html#%3Ahelp
[hi]: https://vimhelp.appspot.com/indent.txt.html#ft-html-indent
[ie]: https://vimhelp.appspot.com/options.txt.html#%27indentexpr%27
[ll]: https://vimhelp.appspot.com/quickfix.txt.html#location-list
[ma]: https://vimhelp.appspot.com/map.txt.html#%3Amap
[mk]: https://vimhelp.appspot.com/quickfix.txt.html#%3Amake
[ml]: https://vimhelp.appspot.com/quickfix.txt.html#%3Almake
[mp]: https://vimhelp.appspot.com/options.txt.html#%27makeprg%27
[pf]: https://mywiki.wooledge.org/BashPitfalls
[pt]: https://vimhelp.appspot.com/map.txt.html#%3CPlug%3E
[qf]: https://vimhelp.appspot.com/quickfix.txt.html#quickfix
[qk]: ../tejr-runtime-hackery/vim-quickening.jpg
[rc]: https://vimhelp.appspot.com/usr_05.txt.html#vimrc-intro
[ro]: https://vimhelp.appspot.com/options.txt.html#%27runtimepath%27
[rt]: https://vimhelp.appspot.com/repeat.txt.html#%3Aruntime
[sc]: https://www.shellcheck.net/
[sn]: https://vimhelp.appspot.com/repeat.txt.html#%3Ascriptnames
[sv]: https://vimhelp.appspot.com/eval.txt.html#script-variable
[uf]: https://vimhelp.appspot.com/usr_41.txt.html#undo_ftplugin
[vt]: https://vimways.org/2018/you-should-be-using-tags-in-vim/
