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
[vimrc][rc] into a `~/.vim` runtime directory, we hinted at a few more specific
possibilities for leveraging the runtime directory structure, but did not go
into any detail:

1. Preventing specific code in the stock runtime directory from running
2. Writing custom compiler definitions
3. Automatically loading functions only when they’re called

In this followup article, we’ll go through each of these, further demonstrating
how you can use the [`'runtimepath'`][ro] structure and logic to your benefit.

That’s nice, but it’s wrong
---------------------------

Sometimes, you just plain don’t like something that the stock runtime files do.
You don’t want to edit the included runtime files directly, because they’ll
just get overwritten again the next time you upgrade Vim, and you can’t carry
them around as part of your personal configuration. You don’t want to maintain
a hacked-up copy of the full runtime files in your own configuration, either.
It would be better to work *around* the unwanted lines, if we could.
Fortunately, `'runtimepath'` lets us do exactly that.

### Variable options

Accommodating plugin authors will sometimes provide variable options to allow
you to tweak commonly-requested things. You should always look for these first;
you may not even need to read any Vim script to do it, as they are often
described in [`:help`][he] topics.

For example, the stock indenting behaviour for the `html` filetype does not add
a level of indent after opening a paragraph block with a `<p>` tag, even though
it *does* add indentation after an element like `<body>`. Fortunately, there’s
a [documented option variable][hi] that switches this behaviour named
`html_indent_inctags`, which we can define in `~/.vim/indent/html.vim`. This
will get loaded just *before* `$VIMRUNTIME/indent/html.vim`:

```vim
" Indent after <p> paragraph tags too
let html_indent_inctags = 'p'
```

This changes the behaviour in the way we need. To be tidy, we should clear the
variable away again afterwards in `$VIMRUNTIME/after/indent/html.vim`, since
after the stock file has run, this global variable has done its job:

```vim
" Clear away global variable set as indent option
unlet html_indent_inctags
```

### Reversing unwanted configuration

Other times, the behavior annoying you may be just a little thing that’s not
directly configurable, but it’s still easy enough to *reverse* it. For example,
if you’re a Perl developer, you might find it annoying that when editing
buffers with the `perl` filetype, the `#` **comment leader** is automatically
added when you press "Enter" in insert mode while composing a comment. You
would rather type (or not type) it yourself, as the `python` filetype does by
default.

You might check the Vim documentation, and find this unwanted behaviour is
caused by the [`r` flag][ft] in the [`'formatoptions'`][fo] option. You then
check `$VIMRUNTIME/ftplugin/perl.vim`, and sure enough, you find this line:

```vim
setlocal formatoptions+=crqol
```

It doesn’t look like there’s a variable option you can set to *prevent* the
setting, and so you add in a couple of lines to
`~/.vim/after/ftplugin/perl.vim` to *correct* it instead:

```vim
setlocal formatoptions-=r
```

This does the trick. Note that you don’t need to add a [`b:undo_ftplugin`][uf]
command here, either; the stock filetype plugin already includes a revert
command for `'formatoptions'`, so you can fix this annoying problem with just
one line.

### Blocking unwanted configuration

Perhaps a filetype plugin or indent plugin for a given language is just
irredeemably wrong for you. For example, suppose you’re annoyed with the stock
indenting behaviour for `php`. You just can’t predict where you’ll end up on
any new line, you can’t configure it to make it work the way you want it to,
and it’s just too frustrating to deal with it. Rather than carefully undoing
each of the plugin’s settings, you decide it would be better if all near-1000
lines of `$VIMRUNTIME/indent/php.vim` just didn’t load at all, so you can go
back to plain old [`'autoindent'`][ai] until you can find or write something
better.

Fortunately, at the very beginning of the disliked file, we find a **load
guard**:

```vim
if exists("b:did_indent")
    finish
endif
let b:did_indent = 1
```

This cuts the whole script off if `b:did_indent` has been set. This suggests
that if we set that variable *before* this script loads, we could avoid the
indent mess entirely, and do things our way. We add three lines to a new file
in `~/.vim/indent/php.vim`, and we’re done:

```vim
let b:did_indent = 1
setlocal autoindent
let b:undo_indent = 'setlocal autoindent<'
```

The stock `$VIMRUNTIME/indent/php.vim` still loads after this script, but
execution never gets past the load guard, leaving our single setting of
`'autoindent'`intact. In doing this, we’ve now replaced the `php` indent plugin
with our own. Perhaps we’ll refine it a bit more later, or write an
[`'indentexpr'`][ie] for it that we prefer.

### Advanced example

Sometimes, working around this type of issue requires a little more careful
analysis of the order in which things are sourced, and a bit more tweaking.

For example, suppose you don’t like the fact that the `html` filetype plugin is
loaded for `markdown` buffers, and set out to prevent this behavior. You hope
that there’s going to be an option that allows you to do this, and you start by
looking in `$VIMRUNTIME/ftplugin/markdown.vim`.

Unfortunately, in that file you find that the behaviour is hard-coded, and runs
unconditionally:

```vim
runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
```

That line runs all the filetype plugins it can find for the `html` filetype. We
can’t coax the stock plugin into disabling the unwanted behaviour, but we don’t
want to completely *disable* the stock plugin for `markdown` or `html` as
primary buffer filetypes, either.  What to do?

Perhaps there’s a way to disable *just* the filetype plugins for `html`, and
*only* when the active buffer is actually a `markdown` buffer? Looking at
`$VIMRUNTIME/ftplugin/html.vim`, we notice our old friend the load guard:

```vim
if exists("b:did_ftplugin") | finish | endif
```

It looks like if we can arrange things so that `b:did_ftplugin` is set just
before this script loads, we can meet our goal. Sure enough, putting this in
`~/.vim/ftplugin/html.vim` does the trick:

```vim
if &filetype ==# 'markdown'
  let b:did_ftplugin = 1
endif
```

Checker, linter, candlestick-maker
----------------------------------

One of the lesser-used subdirectories in the Vim runtime directory structure is
`compiler`. This is for files that set [`'makeprg'`][mp] and
[`'errorformat'`][ef] options, so that the right [`:make`][mk] or
[`:lmake`][ml] command runs for the current buffer, and any output or errors
that program returns are correctly interpreted according to the value of
`'errorformat'` for use in the quickfix and location lists. The files defining
these two options are sourced using the [`:compiler`][cm] command.

Vim includes some `:compiler` definitions in its runtime files, and not just
for C or C++ compilers; there’s `$VIMRUNTIME/compiler/tidy.vim` for HTML
checking, and `$VIMRUNTIME/compiler/perl.vim` for Perl syntax checking, to name
just a couple. Note that there’s no particular need for the program named by
`'makeprg'` to have anything to do with an actual `make` program, or a compiler
for a compiled language; it can just as easily be a **syntax checker** to
identify erroneous constructs, or a **linter**, to point out bad practices that
aren’t necessarily errors. What the `:compiler` command provides for the user
is an abstraction for configuring these, and switching between them cleanly.

### Switching between compilers

As an example to make the usefulness of this clear, consider how we might like
to specify `'makeprg'` and `'errorformat'` for editing shell scripts written
for GNU Bash. Bash can be an awkward and difficult language, and if we have to
write a lot of it, ideally we’d want a linter as well as a syntax checker to
let us know if we write anything potentially erroneous.

Here are two different tools for syntax checking and linting Bash, and
candidates for new `:compiler` definitions:

* [`bash -n`][bn] will **check** the syntax of a shell script, to establish
  whether it will run at all.
* [`shellcheck -s bash`][sc] will **lint** it, looking for bad practices in a
  shell script that might misbehave in unexpected ways.

Ideally, a Bash programmer would want to be able to run *either*, switching
between them as needed, without losing the benefit of showing the output in the
quickfix or location list when `:make` or `:lmake` is run.

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
mappings like this, using `,b` for `bash` and `,s` for `shellcheck`:

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
often, it can slow down your startup time. This isn’t so much of a problem if
the functionality is really useful *and* will always be needed promptly in
every editor session, but for functions that are called less often—particularly
for `map` and `autocmd` targets that are specific to certain filetypes—it would
be preferable to arrange for function definitions to be loaded only at the time
they’re actually needed, to keep Vim startup snappy.

We’ve already seen that putting such code in filetype-specific plugins where
possible is a great start. We can build further on this with another useful
application of Vim’s runtime directory structure—the **autoload** structure.
This approach loads functions at the time they’re called, just before executing
them.

Consider the following script-local variable `s:pattern` and functions
`s:Format()`, `s:Bump`, `s:BumpMinor` and `s:BumpMajor` from a filetype plugin.
This plugin does something very specific: it find and increments version
numbers in buffers of the `perl` filetype.

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

The script ends with mapping targets to its last two functions:

    nnoremap <buffer> <Plug>(PerlBumpMinor)
          \ :<C-U>call <SID>BumpMinor()<CR>
    nnoremap <buffer> <Plug>(PerlBumpMajor)
          \ :<C-U>call <SID>BumpMajor()<CR>

These [`<Plug>` targets][pm] need to be mapped to by the user’s configuration
in `~/.vim/after/ftplugin/perl.vim`, with the keys they actually want; here,
we’ve used `,b` and `,B`:

    nmap <buffer> ,b <Plug>(PerlBumpMinor)
    nmap <buffer> ,B <Plug>(PerlBumpMajor)

There’s no way you would need to load such niche code every time Vim starts.
You probably wouldn’t even want all of it to load it every time you edit a Perl
file—after all, how likely are you to bump the version number of a script every
time you look at it?

Ideally, you’d just define the mappings in some special way so that Vim knows
where to load the rest of it, and does so only when they’re actually called.
Once loaded, the functions and any variables would then stay defined as normal
for the rest of the Vim session—a kind of **dynamic plugin**.

Indeed, this is exactly what `autoload` makes possible. We can put the entirety
of the script functions up to the mappings into a file
`~/.vim/autoload/perl/version/bump.vim`, and rename the last two functions
using the `#` syntax for autoloading:

    " Interface functions
    function! perl#version#bump#BumpMinor() abort
      call s:Bump(0)
    endfunction
    function! perl#version#bump#BumpMajor() abort
      call s:Bump(1)
    endfunction

### Autoload identifier prefixes

The prefix `perl#version#bump#` for the new function names specifies the
relative runtime path at which the autoloader should look for the file
containing the function definitions. All of the `#` symbols bar the last one
are replaced with filesystem slashes `/`, and the last one is replaced with
`.vim`. This is how the autoloading process finds the function’s definition at
the time it needs it.

Similar to the previous `:runtime` wrappers we’ve observed, the process is to
iterate through the `autoload` directories of each directory in
`'runtimepath'`, in order, until a file with a relative path corresponding to
the called function’s prefix is found and sourced.

Here are some other examples of autoloaded function names, and where Vim looks
for them:

* `foo#Example()` goes in `~/.vim/autoload/foo.vim`
* `foo#bar#baz#Example()` goes in `~/.vim/autoload/foo/bar/baz.vim`
* `foo#bar#()` goes in `~/.vim/autoload/foo/bar.vim`

Note that as demonstrated in the last example above, there doesn’t actually
have to be a function name following the final `#`. You can use this to load
only one function per file, if you wish.

### Autoloading encapsulation

You might be wondering why we only have to rename the last two functions in our
example. How can this still work if the `s:pattern` variable and the
`s:Format()` and `s:Bump()` functions are still using the `s:` prefix for
script-local scope?

The reason this works is that their definitions are still loaded as part of the
autoloaded file, even though they weren’t explicitly referenced or called
themselves. They are thereby pulled in *indirectly* by the
`perl#version#bump#BumpMinor()` and `perl#version#bump#BumpMajor()` functions’
autoload processes, and remain visible to those functions in the same
script-level scope. Because they’re only used internally by our mapped
functions, and don’t need to be callable from outside the script, there’s no
need to rename them, and we still get the benefit of deferring their loading.

In object-oriented terms, you can therefore think of the autoloaded functions
as the **interface** to the plugin, and any script-local variables or functions
that they use as the plugin’s **implementation**.

### Reducing a plugin to just a few lines

With the above restructuring done, we can adjust the `<Plug>` mappings to use
the new function names. This filetype plugin now loads only two commands when
the buffer’s `'filetype'` is set to `perl`; here it is in its entirety:

    nnoremap <buffer> <Plug>(PerlBumpMinor)
          \ :<C-U>call perl#version#bump#BumpMinor()<CR>
    nnoremap <buffer> <Plug>(PerlBumpMajor)
          \ :<C-U>call perl#version#bump#BumpMajor()<CR>
    let b:undo_ftplugin .= '|nunmap <buffer> <Plug>(PerlBumpMinor)'
          \ '|nunmap <buffer> <Plug>(PerlBumpMajor)'

Applying this process rigorously can shave a lot of wasted time from your Vim
startup process. This was the main design goal for autoloading, as the Vim
plugin ecosystem (and users’ startup times) grew towards the first release of
the feature in Vim 7.0.

Carefully examining what needs to load, and when, along with some careful
experimentation, will make clearer to you what code can be deferred until
later. Autoloading is the second-closest thing you have to a “magic bullet” in
speeding up Vim. The closest thing, of course, is never to load the code at
all, especially if you learn that [what you want is already built in to
Vim][vt]…

Don’t stop me now
-----------------

Over our two articles on this topic, we’ve gone through a whirlwind tour of the
most important parts of good `:runtime` and `'runtimepath'` usage for your own
personal `~/.vim` directory—and yet, with every example, we’ve demonstrated
merely a few simple possibilities of what can be done with this design.

The “overlaying” runtime directory approach Vim takes to its configuration is
one of the best things about the editor’s design. It strikes a balance between
user customizability for Vim enthusiasts and their particular areas of editing
interest, while still working just fine out of the box for everyone and
everything else. With trading vimrc files being a cultural tradition since the
90s, it’s so easy to overlook what’s possible just outside the single-file box.
The Emacs community has adapted readily to trading [`.emacs.d`
directories][ed], having had [just the same problems as we do now][ep]—we need
to catch up!

The author hopes you have a new appreciation for the power that the
much-overlooked `'runtimepath'` design gives to you—all of it gained not by
mastering an entire language like Emacs Lisp, but merely by putting a few
small, relatively simple files in just the right places in your home directory.
There’s some kind of aesthetic appeal in that—maybe even a weird kind of beauty
that only a Vim enthusiast could love.

[ai]: https://vimhelp.appspot.com/options.txt.html#%27autoindent%27
[bn]: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
[cm]: https://vimhelp.appspot.com/quickfix.txt.html#%3Acompiler
[ea]: https://vimways.org/2018/from-vimrc-to-vim/
[ef]: https://vimhelp.appspot.com/options.txt.html#%27errorformat%27
[fo]: https://vimhelp.appspot.com/options.txt.html#%27formatoptions%27
[ft]: https://vimhelp.appspot.com/change.txt.html#fo-table
[hi]: https://vimhelp.appspot.com/indent.txt.html#ft-html-indent
[ie]: https://vimhelp.appspot.com/options.txt.html#%27indentexpr%27
[mk]: https://vimhelp.appspot.com/quickfix.txt.html#%3Amake
[ml]: https://vimhelp.appspot.com/quickfix.txt.html#%3Almake
[mp]: https://vimhelp.appspot.com/options.txt.html#%27makeprg%27
[rc]: https://vimhelp.appspot.com/usr_05.txt.html#vimrc-intro
[ro]: https://vimhelp.appspot.com/options.txt.html#%27runtimepath%27
[sc]: https://www.shellcheck.net/
[sv]: https://vimhelp.appspot.com/eval.txt.html#script-variable
[uf]: https://vimhelp.appspot.com/usr_41.txt.html#undo_ftplugin
[vt]: https://vimways.org/2018/you-should-be-using-tags-in-vim/
[ep]: https://www.emacswiki.org/emacs/DotEmacsBankruptcy
[ed]: http://whattheemacsd.com/
[he]: http://vimhelp.appspot.com/helphelp.txt.html#%3Ahelp
[pt]: http://vimhelp.appspot.com/map.txt.html#%3CPlug%3E
