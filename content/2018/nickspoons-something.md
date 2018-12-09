---
title: "TBD"
publishDate: 2018-12-26
date: 2018-12-26
draft: true
description: "A little bit of vimscript never hurt anybody. If you know what I mean."
slug: "some-kind-of-url"
author:
  name: "Nick Jensen"
  github: "nickspoons"
  email: "nickspoon@gmail.com"
---

This article is going to walk through a process of finding an interesting
feature of Vim, and incorporating it into a workflow. This is a strong Vim
tradition, and part of how we each make our Vim our own - whether it means a
couple of mappings, or an over-engineered pile of vimscript as will be presented
here.

## A quick, quick quickfix intro

Vim's quickfix feature is a powerful central function of the editor. At its
core, a quickfix list is a list of file locations, and a set of commands for
navigating between them. It can be populated in many different ways, and is
generally used for referencing errors and search results.

A simple way to start out with the quickfix list is to use Vim's internal search
tool, [`:vimgrep`][aa].

```vim
:vimgrep /^set/j ~/.vimrc
```

This command searches for string `set` occurring at the start of lines in file
`~./vimrc`. The `j` flag at the end of the search string indicates that Vim
should not jump to the first match.

In a clean Vim environment, the above doesn't appear to actually do anything. We
can verify that it _has_ by navigating to the first match with `:cfirst`
(assuming your `~/.vimrc` actually does contain at least one `set` statement),
and to other matches with `:cnext`, `:cprevious` and `:clast`.

But to get a real overview of your quickfix list, you can't beat opening the
quickfix window with `:copen`. This is a vim buffer where each line represents a
quickfix entry, and you can navigate to one by simply moving the cursor over the
associated line and hitting `<CR>` (Enter/Return). The other command to open the
quickfix window is `:cwindow`, which only opens the quickfix window if there
quickfix list contains any records. Use `:cclose` to close the quickfix window,
or just `:q` it when the quickfix window is focused.

Note the common `c` prefix of all of the preceding commands relating to the
quickfix list and window.

### Locations

In addition to the single quickfix list that vim maintains, each window also has
a "location list". This is essentially exactly the same as the quickfix list,
except that there are many of them - potentially as many as the number of
windows that you have split and tabbed your vim into. These can be populated in the
same way as the quickfix list, but with `l` prefixed commands. So the `:vimgrep`
command above becomes `:lvimgrep` when you want the results to go to the
window's location list:

```vim
:lvimgrep /^set/j ~/.vimrc
```

Navigate with `:lfirst`, `:lnext`, `:lprevious`, `:llast`, and open and close
the location list window for the current window with `:lopen`/`:lwindow` and
`:lclose` - all the `l` equivalent of their `c` quickfix counterparts.

### Out with the old, in with the new

After performing several searches with `:vimgrep`, you may realise that you want
to see the results of an earlier search again. Of course you can recreate the
search, but do you have to? Chances are that Vim still has your earlier quickfix
list.

In fact, Vim remembers the last ten quickfix lists, and the last ten location
lists for each window. The earlier quickfix and location lists can be accessed
by using the `:colder` and `:lolder` commands respectively. This is always
easiest to do while the quickfix or location windows are open, so the updated
list is clearly visible. `:cnewer` and `:lnewer` navigate forward again through
the quickfix/location list stack.

## Time to customise

Using commands to move back and forth through the quickfix lists is not a
particularly nice experience. If we're going to use thesse commands often, we
can benefit from some mappings. `:colder` and `:cnewer` can be used from
anywhere, but since they are most useful when the quickfix window is open, then
creating mappings that apply only to the quickfix window make sense. And since
only vertical cursor movement is necessary in the quickfix window, we have some
nice keys available for remapping: `<Left>` and `<Right>`.

So let's create an ftplugin script for filetype `qf`, the filetype Vim uses for
both quickfix and location list windows:

```vim
" ~/.vim/after/ftplugin/qf.vim
nnoremap <buffer> <Left> :colder<CR>
nnoremap <buffer> <Right> :cnewer<CR>
```

Now close your quickfix window if it's open, then open/re-open it and try
hitting your keyboard's `<Left>` and `<Right>` keys to move through the quickfix
lists. Pretty good?

Of course the trouble is that this doesn't do us any good in location windows.
The `<Left>` and `<Right>` keys don't appear to do anything in a location window
... unless you still have the quickfix window open too, in which case you'll be
able to see the quickfix list changing ... not the location list!

So to make the mappings work in location lists _and_ quickfix lists, we need a
way to tell which the current window is, and then decide which command to call.
While it is possible to do all that in an `<expr>` mapping, this is already
starting to get complicated, so lets refactor and create some functions:

```vim
" ~/.vim/after/ftplugin/qf.vim
function! s:SwitchQFList(isNewer)
  " Get dictionary of properties of the current window
  let wininfo = filter(getwininfo(), {i,v -> v.winnr == winnr()})[0]
  " Requires a reasonably new vim; loclist added to getwininfo() in 7.4.2215
  let isloc = l:info.loclist
  let cmd = (isloc ? 'l' : 'c') . (a:newer ? 'newer' : 'older')
  execute cmd
endfunction

function! QFNewer()
  call s:SwitchQFList(1)
endfunction

function! QFOlder()
  call s:SwitchQFList(0)
endfunction

nnoremap <buffer> <Left> :call QFOlder()<CR>
nnoremap <buffer> <Right> :call QFNewer()<CR>
```

[aa]: http://vimhelp.appspot.com/quickfix.txt.html#%3Avimgrep
