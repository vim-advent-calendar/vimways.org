---
title: "Writing a Vim Plugin"
publishDate: 2019-12-01
draft: true
description: "An article not about writing plugins"
author:
  email: "lukasz@niemier.pl"
  github: "hauleth"
  homepage: "https://hauleth.dev/"
  irc: "hauleth"
  name: "Łukasz Jan Niemier"
  twitter: "@hauleth"
---

While there are many "tutorials" for writing plugins in Vim, I hope this one
will be a little bit different from what is out there, because it won't be
about writing plugin *per se*. If you want to find information about that then
you should check out [`:h write-plugin`][h-write-plugin]. I want this article to be about how
plugins come to life, using my own experience on writing
[`vim-backscratch`][scratch] as an example.

## Problem

All plugins should start with a problem. If there is no problem, then there
should be no code, as there is no better code than [no code][nocode]. In this
case, my problem was pretty trivial: I wanted a temporary buffer that would let
me perform quick edits and view SQL queries while optimising them (and run them
from there with Tim Pope's [dadbod][dadbod]).

## "Simple obvious solution"

Now that we have defined the problem, we need to try the first possible solution.
In our case, it is opening new buffer in new window, edit it, and then close it
when no longer needed. It is simple in Vim:

```vim
:new
" Edits
:bd!
```

Unfortunately this has bunch of problems:

- if we forgot to close that buffer, then it will hang there indefinitely,
- running `:bd!` in the wrong buffer, can have unpleasant consequences,
- this buffer is still listed in `:ls`, which is unneeded (as it is only
  temporary).

## Systematic solution in Vim

Fortunately Vim has solutions for all of our problems:

- the "scratch" section in [`:h special-buffers`][h-special-buffers], which
  solves the first two problems,
- [`:h unlisted-buffer`][h-unlisted-buffer], which solves the third problem.

So now our solution looks like:

```vim
:new
:setlocal nobuflisted buftype=nofile bufhidden=delete noswapfile
" Edits
:bd
```

However that is a long chain of commands to write. Of course we could condense
the first two into a single one:

```vim
:new ++nobuflisted ++buftype=nofile ++bufhidden=delete ++noswapfile
```

But in reality this does not shorten anything.

## Create a command

Fortunately we can create our own commands in Vim, so we can shorten that to a
single, easy to remember command:

```vim
command! Scratch new ++nobuflisted ++buftype=nofile ++bufhidden=delete ++noswap
```

For better flexibility, I prefer it to be:

```vim
command! Scratchify setlocal nobuflisted buftype=nofile bufhidden=delete noswap
command! Scratch new +Scratchify
```

We can also add a bunch of new commands to give us better control over our new
window's location:

```vim
command! VScratch vnew +Scratchify
command! TScratch tabnew +Scratchify
```

Those commands will open a new scratch buffer in a new vertical window, and
a new scratch buffer in a new tab page, respectively.

## Make it a more "vimmy" citizen

While our commands `:Scratch`, `:VScratch`, and `:TScratch` are nice, they are
still not flexible enough. In Vim we can use modifiers like [`:h
:aboveleft`][h-aboveleft] to define exactly where we want new windows to appear
and our current commands do not respect that. To fix this problem, we can
simply squash all the commands into one:

```vim
command! Scratch <mods>new +Scratchify
```

And we can remove `:VScratch` and `:TScratch` as these can be now done via
`:vert Scratch` and `:tab Scratch` (of course you can keep them if you like, I
just wanted the UX to be minimal).

## Make it powerful

This has been in my `$MYVIMRC` for some time in the form described above until
I found out [Romain Lafourcade's snippet][redir] that provided one additional
feature: it allowed to open a scratch buffer with the output of a Vim or shell
command. My first thought was - hey, I know that, but I know I can make it
better! So we can write a simple VimL function (which is mostly copied from
romainl's snippet, with a few improvements):

```vim
function! s:scratch(mods, cmd) abort
    if a:cmd is# ''
        let l:output = []
    elseif a:cmd[0] is# '!'
        let l:cmd = a:cmd =~' %' ? substitute(a:cmd, ' %', ' ' . expand('%:p'), '') : a:cmd
        let l:output = systemlist(matchstr(l:cmd, '^!\zs.*'))
    else
        let l:output = split(execute(a:cmd), "\n")
    endif

    execute a:mods . ' new'
    Scratchify
    call setline(1, l:output)
endfunction

command! Scratchify setlocal nobuflisted noswapfile buftype=nofile bufhidden=delete
command! -nargs=1 -complete=command Scratch call <SID>scratch('<mods>', <q-args>)
```

The main differences are:

- special case for empty command, it will just open an empty buffer,
- use of `is#` instead of `==`,
- use of `:h execute()` instead of `:redir`.

As it is quite self-contained and (let's be honest) too specific for `$MYVIMRC`
we can can extract it to its own location in `.vim/plugin/scratch.vim` (or
`./config/nvim/plugin/scratch.vim` for Neovim), but to do so properly we need
one additional thing, a command to prevent the script from being loaded twice:

```vim
if exists('g:loaded_scratch')
    finish
endif
let g:loaded_scratch = 1

function! s:scratch(mods, cmd) abort
    if a:cmd is# ''
        let l:output = []
    elseif a:cmd[0] is# '!'
        let l:cmd = a:cmd =~' %' ? substitute(a:cmd, ' %', ' ' . expand('%:p'), '') : a:cmd
        let l:output = systemlist(matchstr(l:cmd, '^!\zs.*'))
    else
        let l:output = split(execute(a:cmd), "\n")
    endif

    execute a:mods . ' new'
    Scratchify
    call setline(1, l:output)
endfunction

command! Scratchify setlocal nobuflisted noswapfile buftype=nofile bufhidden=delete
command! -nargs=1 -complete=command Scratch call <SID>scratch(<q-mods>, <q-args>)
```

## To boldly go…

Now my idea was, hey, I use Vim macros from time to time, and these are just
simply lists of keystrokes stored in Vim registers. Maybe it would be nice to have
access to that as well in our command. So we will just add a new condition that
checks if `a:cmd` begins with the `@` sign and has a length of two. If so, then
set `l:output` to the spliced content of the register:

```vim
function! s:scratch(mods, cmd) abort
    if a:cmd is# ''
        let l:output = ''
    elseif a:cmd[0] is# '@'
        if strlen(a:cmd) is# 2
            let l:output = getreg(a:cmd[1], 1, v:true)
        else
            throw 'Invalid register'
        endif
    elseif a:cmd[0] is# '!'
        let l:cmd = a:cmd =~' %' ? substitute(a:cmd, ' %', ' ' . expand('%:p'), '') : a:cmd
        let l:output = systemlist(matchstr(l:cmd, '^!\zs.*'))
    else
        let l:output = split(execute(a:cmd), "\n")
    endif

    execute a:mods . ' new'
    Scratchify
    call setline(1, l:output)
endfunction
```

This gives us a pretty powerful solution where we can use `:Scratch @a` to open
a new scratch buffer with the content of register `A`, edit it, and yank it
back via `"ayy`.

## Pluginize

Now, it would be shame to keep such a useful tool for ourselves so
let's share it with the big world. In this case we need:

- a proper project structure,
- documentation,
- a good catchy name.

You can find help on the two first topics in [`:h
write-plugin`][h-write-plugin] and [`:h write-local-help`][h-write-local-help]
or in any of the bazillion tutorials in the internet.

Finding a good name is something I can't help you with. I have picked
`vim-backscratch`, because I like back scratches (everyone likes them) and, as
a nice coincidence, because it contains the word "scratch".

## Summary

Creating plugins for Vim is easy, but not every functionality needs to be
a plugin from day one. Start easy and small. If something can be done with
a simple command/mapping, then it should be done with a simple command/mapping
at first. If you find your solution really useful, then, and only then, you
should think about turning it into plugin. The whole process described in this
article wasn't done in week or two. It took me about a year to reach the step
*Make it a more "vimmy" citizen*, when I heard about romainl's script on IRC.
I didn't need anything more, so take your time.

Additional pro-tips:

- make it small, big plugins will require a lot of maintenance, small plugins
  are much simpler to maintain,
- if something can be done via a command then it should be made as a command,
  do not force your mappings on users.

[scratch]: https://github.com/hauleth/vim-backscratch
[nocode]: https://github.com/kelseyhightower/nocode
[dadbod]: https://github.com/tpope/vim-dadbod
[h-write-plugin]: https://vimhelp.org/usr_41.txt.html#write-plugin
[h-write-local-help]: https://vimhelp.org/usr_41.txt.html#write-local-help
[h-special-buffers]: https://vimhelp.org/windows.txt.html#special-buffers
[h-unlisted-buffer]: https://vimhelp.org/windows.txt.html#unlisted-buffer
[h-aboveleft]: https://vimhelp.org/windows.txt.html#%3Aaboveleft

[//]: # ( Vim: set spell spelllang=en: )
