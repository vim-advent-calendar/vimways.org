---
title: "Writing Vim Plugin"
publishDate: 2019-12-01
draft: true
description: "Article not about writing plugins"
author:
  email: "lukasz@niemier.pl"
  github: "hauleth"
  homepage: "https://hauleth.dev/"
  irc: "hauleth"
  name: "Łukasz Jan Niemier"
  twitter: "@hauleth"
---

While there is a lot of "tutorials" for writing plugins in Vim, I hope this one
will be a little different form what is out there, because I will not write
about writing plugin per se. If you want to find information about that then you
should check out `:h write-plugin`. In this article I want to provide you a
tutorial about how plugin becomes a thing using as example my own experience on
writing [`vim-backscratch`][scratch].

## Problem

All plugins should start with a problem, if there is no problem, then there
should be no code, there is no better code than [no code][]. In this case
my problem was pretty trivial - I wanted temporary buffer to be able to provide
quick edits and view into SQL queries while optimising them (and run them from
there with [`dadbod`][dadbod]).

## "Simple obvious solution"

When we have defined problem, then we need to check the first possible solution,
in our case it is opening new buffer in new window, edit it, and then close it
when no longer needed. It is simple in Vim

```viml
:new
" Edits
:bd!
```

Unfortunately this has bunch of problems:

- If we forgot to close that buffer, then it will hang there indefinitely
- If we run `:bd!` in wrong buffer, then it can have unpleasant consequences
- Such buffer is still listed in `:ls`, which is unneeded (as this is only
  temporary)

## Systematic solution in Vim

Fortunately Vim has solution for all of our problems `:h scratch-buffer`, which
solves first two problems, and `:h unlisted-buffer` which solves third problem.
So now our solution looks like:

```viml
:new
:setlocal nobuflisted buftype=nofile bufhidden=delete noswapfile
" Edits
:bd
```

However that is long chain of commands to write, of course we could shorten
first two to one:

```viml
:new ++nobuflisted ++buftype=nofile ++bufhidden=delete ++noswapfile
```

But in reality that do not shorten nothing.

## Create command

Fortunately we can create our own commands in Vim, so we can shorten that to
single, easy to remember command:

```viml
command! Scratch new ++nobuflisted ++buftype=nofile ++bufhidden=delete ++noswap
```

However I, for better flexibility prefer it to be:

```viml
command! Scratchify setlocal nobuflisted buftype=nofile bufhidden=delete noswap
command! Scratch new +Scratchify
```

We can also add few new commands to allow us to better control where our new
window will appear:

```viml
command! VScratch vnew +Scratchify
command! TScratch tabnew +Scratchify
```

That will open new vertical buffer and buffer in new tab, respectively.

## Make it more "vimmy" citizen

While our commands `:Scratch` and `:VScratch` are nice, these are still not
flexible enough. In Vim we can use modifiers like `:aboveleft` to define exactly
where we want window to appear and our current commands do not respect that. To
fix it we can simply squash all commands into one:

```viml
command! Scratch <mods>new +Scratchify
```

And we can remove `:VScratch` and `:TScratch` as these can be now done via
`:vert Scratch` and `:tab Scratch` (of course you can keep them if you like, I
just wanted UX to be minimal).

## Make it powerful

In the form I have described it above it have been in `$MYVIMRC` for some time,
but after that I have found [Romain Lafourcade's snippet][redir] that provided
one additional feature - it allowed to open our scratch with output of Vim
command or shell command. My first thought was - hey, I know that, but I know I
can make it better! So we can crate simple VimL function (which is mostly copied
from romainl snippet, but few updates):

```viml
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

- Special case for empty command, it will just open empty buffer
- Use of `is#` instead of `==`
- Use of `:h execute()` instead of `:redir`

As it is quite self-contained and (let's be honest) to specific for `$MYVIMRC`
now we can can extract it to its own location in `.vim/plugin/scratch.vim` (or
respectively `./config/nvim/plugin/scratch.vim` for NeoVim), but to do so
properly we need one additional thing, command to prevent file from being loaded
twice. So in the end we have file like:

```viml
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
simply list of actions stored in Vim register. Maybe it would be nice to have
access to that as well in our command. So just add new branch to our if, that
checks if `a:cmd` begins with `@` sign and is only 2 letter long, if so, then
set `l:output` to spliced content of the register:

```viml
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

This gives us pretty powerful solution where we can use `:Scratch @a` to open
content of the register `A` in the scratch buffer, edit it, and yank it back via
`"ayy`.

## Pluginize

Now, when we see how useful it is, it would be shame to keep it for ourselves,
let's share this with the big world. In this case we need:

- Proper project structure
- Documentation
- Good catchy name

About first two you can read more on `:h write-plugin` and `:h
write-local-help` or in any of the bazillion tutorials in the internet.

About last one I cannot provide much help. I have picked `vim-backscratch`,
because I like back scratches (everyone like them) and as a nice coincidence
it also has "scratch" in the name.

## Summary

Creating plugins for Vim is easy, but not every one functionality need to be a
plugin from the day one. Start easy and small. If something can be done by a
simple command/mapping, then it should be it at first. If you find it really
useful then, and only then, you should think about making it into plugin. Whole
process described in this article wasn't done in week or two. The step *Make it
more "vimmy" citizen* took about a year before I found romainl script on IRC. I
didn't need anything more, so take your time.

Additional pro-tips:

- Make it small, big plugins will require a lot of maintenance, small plugins
  are much simpler to maintain
- If something can be done via command then it should be made as a command, do
  not force your mappings on users

[scratch]: https://github.com/hauleth/vim-backscratch
[no code]: https://github.com/kelseyhightower/nocode
[dadbod]: https://github.com/tpope/vim-dadbod
