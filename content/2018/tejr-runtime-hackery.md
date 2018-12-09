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

In an earlier article on beginning the process of breaking up a long vimrc into
a .vim runtime directory, we hinted at a few more specific possibilities for
leveraging the runtime directory structure, but did not go into any detail:

1. Preventing specific code in the stock runtime directory from running
2. Using the `:compiler` command
3. Automatically loading functions only when they’re needed

In this followup article, we’ll go through each of these, further demonstrating
how you can use the `'runtimepath'` structure and logic to your benefit.

That’s nice, but it’s wrong
---------------------------

Sometimes, you just plain don’t like something that the stock runtime files do,
but you don’t want to edit the runtime files directly, because they’ll just get
overwritten again the next time you upgrade Vim. Similarly, you don’t want to
maintain a hacked-up copy of the full runtime files in your own configuration,
just to change a few lines; it would be better to work *around* them, if we
can.

### Variable options

Accommodating plugin authors will sometimes provide variable options to allow
you to tweak commonly-requested things. For example, the stock indenting
behaviour for the `html` filetype does not add a level of indent after opening
a `<p>` paragraph block, as it does for an element like `<body>`. Fortunately,
there’s a documented option variable that switches this behaviour named
`html_indent_inctags`, which we can define in `~/.vim/indent/html.vim`. This
will get loaded just *before* `$VIMRUNTIME/indent/html.vim`:

    " Indent after <p> paragraph tags too
    let html_indent_inctags = 'p'

Ideally, we should clear the variable away again afterwards in
`$VIMRUNTIME/after/indent/html.vim`, since after the stock file has run, this
global variable has done its job:

    unlet html_indent_inctags

### Reversing unwanted configuration

Other times, the thing annoying you may be just a little thing that’s not
configurable, but it’s easy enough to *reverse* it. For example, if you’re a
Perl developer, you might find it annoying that when editing buffers with the
`perl` filetype, the `#` comment leader is automatically added when you press
"Enter" in insert mode while composing a comment. You would rather type (or not
type) it yourself, as the `python` filetype does by default.

You might check the Vim documentation, and find this unwanted behaviour is
caused by the `r` flag in the `'formatoptions'` option. Since the previous
article, now that you know where to look, you start by checking
`$VIMRUNTIME/ftplugin/perl.vim`, and sure enough, you find this:

    setlocal formatoptions+=crqol

It doesn’t look like there’s a variable option you can set to fix it, and so
you add in a couple of lines to `~/.vim/after/ftplugin/perl.vim` to *correct*
the option after loading instead, and you’re done:

    setlocal formatoptions-=r

Note that you don’t need to add a `b:undo_ftplugin` command here, either; the
stock filetype plugin already includes a revert command for `'formatoptions'`,
so you can fix this annoying problem with just one line. You can do all this
without having to touch the main runtime files at all.

### Blocking unwanted configuration

Perhaps the filetype plugin or indent plugin for your favourite language is
just irredeemably wrong for you. For example, suppose you’re annoyed with the
stock indenting behaviour for `php`; you find you just can’t predict where
you’ll end up on any given new line, and it’s just too frustrating to deal with
it. Rather than carefully undoing each of its settings, you decide it would be
better if all near-1000 lines of `$VIMRUNTIME/indent/php.vim` just didn’t load
at all, so you can go back to `'autoindent'` until you can find or write
something better.

Fortunately, at the very beginning of the disliked file, we find a **load
guard**:

    if exists("b:did_indent")
        finish
    endif
    let b:did_indent = 1

This cuts the whole script off if `b:did_indent` has been set. This suggests
that if we set that variable *before* this script loads, we could avoid the
indent mess and do things our way.

Indeed, three lines later in a new file in `~/.vim/indent/php.vim`, and we’re
done:

    let b:did_indent = 1
    setlocal autoindent
    let b:undo_indent = 'setlocal autoindent<'

The stock `$VIMRUNTIME/indent/php.vim` still loads after this script, but it
reaches its load guard and halts, leaving our single setting intact. In doing
this, we’ve now replaced the `php` indent plugin with our own. Perhaps we’ll
refine it a bit more later, or write an `'indentexpr'` for it that we prefer.

### Advanced example

Sometimes, working around this type of issue requires a little more careful
analysis of the order in which things are sourced, and a bit more tweaking.

For example, suppose you don’t like the fact that the `html` filetype plugin is
loaded for `markdown` buffers, and set out to prevent this behavior. You hope
that there’s going to be an option that allows you to do this, and you start by
looking in `$VIMRUNTIME/ftplugin/markdown.vim`.

Unfortunately, in that file you find that the behaviour is hard-coded, and runs
unconditionally:

    runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim

That line runs all the filetype plugins it can find for the `html` filetype. We
can’t coax the stock plugin into disabling the unwanted behaviour, but we don’t
want to completely *disable* the stock plugin for `markdown` or `html` either
as primary buffer filetypes.  What to do?

Perhaps there’s a way to disable *just* the filetype plugins for `html`, and
*only* when the active buffer is actually a `markdown` buffer? Looking at
`$VIMRUNTIME/ftplugin/html.vim`, we notice our old friend the load guard:

    if exists("b:did_ftplugin") | finish | endif

So, it looks like if we can arrange things so that `b:did_ftplugin` is set just
before this script loads, we can meet our goal. Sure enough, putting this in
`~/.vim/ftplugin/html.vim` does the trick:

    if &filetype ==# 'markdown'
      let b:did_ftplugin = 1
    endif

Checker, linter, candlestick-maker
----------------------------------

One of the lesser-used subdirectories in the Vim runtime directory structure is
`compiler`. This is for files that set `'makeprg'` and `'errorformat'` options,
so that the right `:make` or `:lmake` command runs for the current buffer, and
so that any output or errors that program returns are correctly interpreted
according to `'errorformat'` for use in the quickfix and location lists. These
files are sourced using the `:compiler` command.

Vim includes some `:compiler` definitions in its included runtime files, and
not just for C or C++ compilers; there’s `$VIMRUNTIME/compiler/tidy.vim` for
HTML checking, and `$VIMRUNTIME/compiler/perl.vim` for Perl syntax checking, to
name a couple. This is because there’s no particular need for the program named
by `'makeprg'` to have anything to do with the `make` program, or a compiler
for a compiled language; it can just as easily be a **syntax checker** to
identify erroneous constructs, or a **linter**, to point out bad practices that
aren’t necessarily errors. What the `:compiler` command provides the user is an
abstraction for configuring these, and switching between them cleanly.

### Switching between compilers

As an example to make the usefulness of this clear, consider how we might like
to specify `'makeprg'` for editing shell scripts written for GNU Bash. Bash can
be an awkward and difficult language, and ideally we’d want a linter as well as
a syntax checker to let us know if we right anything potentially erroneous.

Here are two different tools for syntax checking and linting Bash, both
candidates for a new `:compiler` definition:

* `bash -n` will **check** the syntax of a shell script, to establish whether
  it will run at all.
* `shellcheck -s bash` will **lint** it, looking for bad practices in a shell
  script that might misbehave in unexpected ways.

Ideally, a Bash programmer would want to be able to run *either*, switching
between them as needed, without losing the benefit of the quickfix or location
list when `:make` or `:lmake` is run.

First of all, with our new knowledge of the Vim runtime directory structure, we
know that because this logic is specific to the `sh` filetype, we should put it
in a filetype plugin in `~/.vim/after/ftplugin/sh/compilers.vim`. There’s no
point enabling switching between these two programs for any other filetype.

After experimenting with the values for ``makeprg'` and `'errorformat'`, and
running `:make` on a few Bash files and inspecting the output in the quickfix
list with `:copen`, we find the following values work well:

    makeprg=bash\ -n\ --\ %:S
    errorformat=%f:\ line\ %l:\ %m

    makeprg=shellcheck\ -s\ bash\ -f\ gcc\ --\ %:S
    errorformat=%f:%l:%c:\ %m\ [SC%n]

To switch between them, we might set up functions and mappings like this, to
set the options appropriately for the two different programs, using `,cb` for
`bash` and `,cs` for `shellcheck`:

    function! s:SwitchCompilerBash() abort
      setlocal makeprg=bash\ -n\ --\ %:S
      setlocal errorformat=%f:\ line\ %l:\ %m
    endfunction
    function! s:SwitchCompilerShellCheck() abort
      setlocal makeprg=shellcheck\ -s\ bash\ -f\ gcc\ --\ %:S
      setlocal errorformat=%f:%l:%c:\ %m\ [SC%n]
    endfunction
    nnoremap <buffer> ,cb
          \ :<C-U>call <SID>SwitchCompilerBash()<CR>
    nnoremap <buffer> ,cs
          \ :<C-U>call <SID>SwitchCompilerShellCheck()<CR>
    let b:undo_ftplugin .= '|setlocal makeprg< errorformat<'
          \ . '|nunmap <buffer> ,cb'
          \ . '|nunmap <buffer> ,cs'

This works OK, but there’s quite a lot going on here for something that seems
like it should be simpler. It would be nice to avoid all the script-local
function guff, too.

### Separating compiler definitions out

The `:compiler` command allows us to separate this logic out somewhat, by
putting the options settings in separate files in `~/.vim/compilers`.

Our `~/.vim/compiler/bash.vim` file might look like this:

    setlocal makeprg=bash\ -n\ --\ %:S
    setlocal errorformat=%f:\ line\ %l:\ %m

Similarly, our `~/.vim/compiler/shellcheck.vim` might look like this:

    setlocal makeprg=shellcheck\ -s\ bash\ -f\ gcc\ --\ %:S
    setlocal errorformat=%f:%l:%c:\ %m\ [SC%n]

With these files installed, we can test switching between them with
`:compiler`:

    :compiler bash
    :set errorformat? makeprg?
      errorformat=%f: line %l: %m
      makeprg=bash -n -- %:S
    :compiler shellcheck
    :set errorformat? makeprg?
      errorformat=%f:%l:%c: %m [SC%n]
      makeprg=shellcheck -s bash -f gcc -- %:S

This simple abstraction allows us to refactor the compiler-switching code in
our ftplugin to the following, foregoing any need for the functions:

    nnoremap <buffer> ,cb
          \ :<C-U>compiler bash<CR>
    nnoremap <buffer> ,cs
          \ :<C-U>compiler shellcheck<CR>
    let b:undo_ftplugin .= '|setlocal makeprg< errorformat<'
          \ . '|nunmap <buffer> ,cb'
          \ . '|nunmap <buffer> ,cs'

Note that the above compiler file examples are greatly simplified from the
recommended practices in `:help write-compiler-plugin`. For example, you would
ideally use the `:CompilerSet` command for the options settings. For the
purposes of configuring things your way for your personal `~/.vim` runtime
directory, though, this is mostly a detail.

Automatic for the people
------------------------

Don’t stop me now
-----------------
