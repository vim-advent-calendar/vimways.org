---
title: "Colder quickfix lists"
publishDate: 2018-12-26
date: 2018-12-26
draft: true
description: "A little bit of vimscript never hurt anybody. If you know what I mean."
slug: "colder-quickfix-lists"
author:
  name: "Nick Jensen"
  github: "nickspoons"
  email: "nickspoon@gmail.com"
---

> I may be an oldie, but I'm a goodie too
>
> – "Eighteen with a Bullet", Pete Wingfield

This article is going to walk through a process of finding an interesting
feature of Vim, and incorporating it into a workflow. This is a strong Vim
tradition, and part of how we each make our Vim our own - whether it means a
couple of mappings, or an over-engineered pile of vimscript as will be presented
here.

## A quick, quick quickfix introduction

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
quickfix window is `:cwindow`, which only opens the quickfix window if the
quickfix list contains any records. Use `:cclose` to close the quickfix window,
or just `:q` it when the quickfix window is focused.

Note the common `c` prefix of all of the preceding commands relating to the
quickfix list and window.

### What is your location?

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

### I may be an oldie, but I'm a goodie too

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
starting to get complicated, so lets refactor and create a function.

```vim
" ~/.vim/after/ftplugin/qf.vim
function! QFHistory(goNewer)
  " Get dictionary of properties of the current window
  let wininfo = filter(getwininfo(), {i,v -> v.winnr == winnr()})[0]
  let isloc = wininfo.loclist
  " Build the command: one of colder/cnewer/lolder/lnewer
  let cmd = (isloc ? 'l' : 'c') . (a:goNewer ? 'newer' : 'older')
  execute cmd
endfunction

nnoremap <buffer> <Left> :call QFHistory(0)<CR>
nnoremap <buffer> <Right> :call QFHistory(1)<CR>
```

> Do these work?
>
> I don't know. Look nice though, don't they?
>
> – Bacon and Tom

This looks good, the mappings are simple with all the logic moved into function
`QFHistory`, so let's reopen a quickfix or location window and try it...

```
E127: Cannot redefine function QFHistory: It is in use
```

Oops. What does this mean? Well, the error message is actually explaining what's
happening here pretty well - when we use `:colder` etc., the quickfix/location
window is being recreated with the new list - which means that the ftplugin
script we're currently executing is getting sourced. Because the script creates
a function, the function is now being re-read and re-defined. This was not our
intention but highlights why defining functions in an ftplugin script may not be
such a good idea after all: even when it doesn't cause an error, it's a messy
and unnecessary overhead in a script that may be sourced dozens or hundreds of
times in a session.

So where should we put it? The script could go straight into our .vimrc, but why
not make it an [autoload][ab] function instead? This is an ideal candidate for an
autoload function; a function that may not ever be called in a vim session, so
doesn't need to be read at all until we want to use it.

An autoload function needs to have a name that corresponds to its script
filename. Let's call this one `quickfixed#history()`, and put it in a new file
`~/.vim/autoload/quickfixed.vim`:

```vim
" ~/.vim/autoload/quickfixed.vim
function! quickfixed#history(goNewer)
  " Get dictionary of properties of the current window
  let wininfo = filter(getwininfo(), {i,v -> v.winnr == winnr()})[0]
  let isloc = wininfo.loclist
  " Build the command: one of colder/cnewer/lolder/lnewer
  let cmd = (isloc ? 'l' : 'c') . (a:goNewer ? 'newer' : 'older')
  execute cmd
endfunction
```

```vim
" ~/.vim/after/ftplugin/qf.vim
nnoremap <buffer> <Left> :call quickfixed#history(0)<CR>
nnoremap <buffer> <Right> :call quickfixed#history(1)<CR>
```

> Very nice, Harry. What's it for?
>
> – Barry the Baptist

Now we're getting somewhere. Close any open quickfix or location window and
re-open it, and the `<Left>` and `<Right>` keys now move through the available
lists.

But once again we quickly hit an issue: `<Left>` when we're at the oldest
list or `<Right>` when we're at the newest raise errors. Well that's easily
fixed by wrapping the final command in a `:try` block:

```vim
try | execute cmd | catch | endtry
```

*Note*: Until this point we have been able to see the results of any changes
just by closing and reopening a quickfix or location window. This was because,
as has been noted, the ftplugin script gets re-sourced every time a quickfix
list is opened. This is _not_ the case for the autoload script we have just
created.  It will only ever be sourced once by Vim, unless we tell it otherwise.
So to see changes to this script in the current session, source it manually with
`:source ~/.vim/autoload/quickfixed.vim`, or this shorter form `:so %` from the
quickfixed.vim buffer.

The `:try` wrapper got rid of the errors nicely, and we see an informative
description of each list echoed to the command line:

```
error list 1 of 3; 11 errors      :lvimgrep /^set/j ~/.vim/vimrc
```

This is good. This is _usable_. It could be a little flashier...

### Cosmetics

That output line above is is a bit ugly. For one thing, it is calling whatever
we have in the quickfix list an "error". This is of course due to the history of
the quickfix lists and their primary/original purpose of describing error
locations, but it looks a bit silly when we are looking at `:vimgrep` results,
or linter warnings etc.

The line is also getting echoed to Vim's [message-history][ad] - try running
`:messages` and see. This isn't very useful, we're generating a lot of noise and
making it harder to see more important messages.

What about empty quickfix lists? If we have a search result that didn't include
any matches, we're not particularly interested in revisiting the results of that
search later on. It'd be nice to skip past these.

Finally, the default 10-row quickfix list is wasting screen real estate when
there are fewer than 10 results. We can resize it for smaller quickfix lists to
maximise the screen space (idea inspired by [romainl/vim-qf][na]).

Let's get to work.

```vim
" ~/.vim/autoload/quickfixed.vim
function! quickfixed#history(goNewer)
  " Get dictionary of properties of the current window
  let wininfo = filter(getwininfo(), {i,v -> v.winnr == winnr()})[0]
  let isloc = wininfo.loclist

  " Build the command: one of colder/cnewer/lolder/lnewer
  let cmd = (isloc ? 'l' : 'c') . (a:goNewer ? 'newer' : 'older')

  " Funcref to calculate the size of the current list
  let Len = {-> len(isloc ? getloclist(0) : getqflist())}
  " Funcref to extrace a property value from the list
  let GetProp = {args -> isloc ? getloclist(0, args) : getqflist(args)}
  " Funcrefs to use the quickfix 'nr' property to check for first/last
  let IsFirst = {-> GetProp({'nr': 0}).nr <= 1}
  let IsLast = {-> GetProp({'nr': 0}).nr == GetProp({'nr': '$'}).nr}

  " Apply the cmd repeatedly until we hit a non-empty list, or first/last list
  " is reached
  while 1
    if (a:goNewer && IsLast()) || (!a:goNewer && IsFirst())
      break
    endif
    " Run the command. Use :silent to suppress message-history output.
    " Note that the :try wrapper is no longer necessary
    silent execute cmd
    if Len()
      break
    endif
  endwhile

  " Set the height of the quickfix window to the size of the list, max-height 10
  execute 'resize' min([ 10, max([ 1, Len() ]) ])

  " Echo a description of the new quickfix / location list.
  " And make it look like a rainbow.
  let nr = GetProp({'nr': 0}).nr
  let last = GetProp({'nr': '$'}).nr
  echohl MoreMsg | echon '('
  echohl Identifier | echon nr
  if last > 1
    echohl LineNr | echon ' of '
    echohl Identifier | echon last
  endif
  echohl MoreMsg | echon ') '
  echohl MoreMsg | echon '['
  echohl Identifier | echon Len()
  echohl MoreMsg | echon '] '
  echohl Normal | echon GetProp({'title': 0}).title
  echohl None
endfunction
```

```vim
" ~/.vim/after/ftplugin/qf.vim
" Use <silent> so ":call quickfixed#history(0)" isn't output to the command line
nnoremap <silent> <buffer> <Left> :call quickfixed#history(0)<CR>
nnoremap <silent> <buffer> <Right> :call quickfixed#history(1)<CR>
```

And after all that, this is how it looks (with Vim's default colorscheme):

<script id="asciicast-uzXeism6I3JH3vvqjuYuqEytt" src="https://asciinema.org/a/YL035raOlEbadoWNLpj5cBXan.js" async></script>

Please note the the scripts here require reasonably recent versions of Vim;
[lambdas][zy] were added in 7.4.2044 and the `loclist` property of
[`getwininfo()`][zz] was added in 7.4.2215

> There is one more thing... It's been emotional.
>
> – Big Chris

[aa]: http://vimhelp.appspot.com/quickfix.txt.html#%3Avimgrep
[ab]: http://vimhelp.appspot.com/eval.txt.html#autoload
[ad]: http://vimhelp.appspot.com/message.txt.html#message-history
[na]: https://github.com/romainl/vim-qf
[zy]: http://vimhelp.appspot.com/eval.txt.html#lambda
[zz]: http://vimhelp.appspot.com/eval.txt.html#getwininfo%28%29
