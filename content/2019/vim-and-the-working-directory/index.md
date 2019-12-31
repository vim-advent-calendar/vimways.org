---
title: "Vim and the Working Directory"
publishDate: 2019-12-28
draft: false
description: "Working with several working directories in Vim"
author:
  email: "d.merej@gmail.com"
  github: "dmerejkowsky"
  homepage: "https://dmerej.info/"
  freenode: "dmerejkowsky"
  name: "Dimitri Merejkowsky"
  picture: "https://dmerej.info/pub/avatar.png"
  twitter: "@d_merej"
---

> If you assume that there’s no hope, you guarantee that there will be
> no hope. If you assume that there is an instinct for freedom, there are
> opportunities to change things, there’s a chance you may contribute to
> making a better world
>
> – Noam Chomsky

## What is the cwd in a command line prompt?

`cwd` is short for "current working directory".

Every command you run has its own current working directory. When you start
a terminal emulator, your first `cwd` is your home directory (`/home/user` on
Linux, `/Users/user` on macOS, `C:\\Users\user` on Windows), and then you can
use `cd` to change the working directory.

At any time you can display your working directory by typing `pwd`, and usually your
prompt is configured to give you this information.

Here the prompt is configured to display the working directory between square
brackets:

```bash
[/home/user] $ pwd
/home/user
[/home/user] $ cd /foo/bar
[/foo/bar] $ pwd
/foo/bar
```

Setting the working directory allows you, among other things, to type relative
paths instead of full paths.

For instance, let's assume you have some C code in `/path/to/foo/src`, and you
need to edit the source code for `bar` and its header.

You could run:

```bash
[/home/user] $ vim /path/to/foo/src/bar.c
[/home/user] $ vim /path/to/foo/src/bar.h
```

But it's much more convenient to use:

```bash
[/home/user] $ cd /path/to/foo/src
[/path/to/foo] $ vim bar.c
[/path/to/foo] $ vim bar.h
```

## What is the cwd in Vim?

Vim is no different. When you start vim, it gets the working directory of your
shell. And then you can type commands like `:e` to open paths relative to your
working directory.

Using the same example, after:

```bash
[/home/user] $ cd /path/to/foo/src
[/path/to/foo] $ vim
```

you can run `:e bar.c` to open a window containing the contents of the `bar.c` file,
and then `:sp bar.h` to split the window horizontally and open a buffer for `bar.h`.

## The problem: working with several directories

This is all well and good, but what happens when you start working on
**several** projects ?

For instance, you could be working on the HTML documentation of your project,
in `/path/to/foo/doc`.

You need to see the `.html` and `.css` files when you are editing the
documentation, but also sometimes you want to have a look at the actual code.

An obvious solution is to create a new tab, with `:tabnew doc`, but then if you
want to edit `index.html` you have to type
`:e ../doc/index.html`.

An then if you want to edit the CSS you have to run: `:sp ../doc/style.css`

So you have to keep typing `../doc/` and it's annoying.

## My journey to the prefect workflow

I've had this issue for **years**. It's taken me a long time to find a solution
for this problem, so I thought I'd share this process with you.

### Step 1: using autochdir

Vim has an option for this. Here's the documentation:

```text
'autochdir' 'acd'	boolean (default off)
			global
	When on, Vim will change the current working directory whenever you
	open a file, switch buffers, delete a buffer or open/close a window.
	It will change to the directory containing the file which was opened
	or selected.
	Note: When this option is on some plugins may not work.
```

That was my first try.

I think it's not a good solution (and not only because it's what Emacs does by
default :P)

Here's why.

Let's assume your project is getting more complex, and you have to deal with
a subproject called `baz`.

Here's what your source code looks like:

```text
<foo>
  src
    bar.h
    bar.c
    baz
        baz.c
   doc
      index.html
      baz
          baz.html
```

When you are editing `bar.h`, you can type `:e baz/baz.c` and it feels natural.

But then, if you want to go back from `baz/baz.c` to `bar.h`, you have to use
`:e ../bar.h` which feels strange…

Worse, let's assume you have:

```C
/* in baz/baz.h */
#include <bar.h>

```

You may want to open `bar.h` by using `gf`, or auto-complete the path to the
header using `CTRL-X CTRL-F`, but you can't since you don't have the correct
working directory!

Plus the doc says it may break some plugins…

### Step 2: using :cd

Vim has a command to change the working directory as well.

So back to our example, we can do:

```text
:cd /path/to/foo
:cd src
:e bar.c
:e baz/baz.h
:tabnew
:cd ../doc
:e index.html
```

Well that's much better! There's still a problem though: `:cd` changes the
working directory for the whole vim process.

So if you run `tabprevious` to go back editing the `C` code, your working
directory is no longer correct, and you have to re-type `:cd src`.

### Step 3: using :lcd

Luckily, vim has a command to change the working directory just for the current
window: `:lcd`. So I started using that.

And then I realized I often started vim directly from my home directory, so I
had to type things like:

```text
:e /path/to/foo/src.c
# Ah, I need to change the working directory…
:cd /path/to/foo/
```

That's awful. You type the same path twice!

Or I used to type:

```text
:cd /path/to/foo/src
:e foo.h
# Time to fix the doc
:tabnew ../doc
:cd ../doc
# Shoot! I meant :lcd…
```

### Step 4: using a custom command

I don't recall how I found it, but here's what has been in my `.vimrc` for some
time:

```vim
" 'cd' towards the directory in which the current file is edited
" but only change the path for the current window
nnoremap <leader>cd :lcd %:h<CR>
```

Explanation:

* `noremap` defines a new non-recursive normal mode mapping.
* `<leader>` is replaced by what you set with `let mapleader`. Default is
  backslash, but you can use any character for this.
* `lcd` is the command we just talked about
* `%` represents the current file, and what's after the `:` is called a
  "filename modifier"
* `h` is a filename modifier corresponding to the "dirname" of the file

You can see the full list of filename modifiers with `:help
filename-modifiers`, and to use them from Vimscript you can use the
`fnamemodify()` or `expand()` functions.

Well, that's much better. You can start opening a long path, and then change
the working directory without retyping all the path components.

Also, you are always using `:lcd`, so you never change the path globally.

This quickly became **the** shortcut I could no longer live without…

### Step 5: using `<leader>ew`

This is another trick you can use when you know are going to edit a file that
is "near" the file you are currently editing, but don't
want to change the working directory at all.

The code looks like this:

```vim
" Open files located in the same dir in with the current file is edited
nnoremap <leader>ew :e <C-R>=expand("%:.:h") . "/"<CR>
```

Explanation:

* `<C-R>=` is short for `Ctrl-R` followed by the _equals_ sign. It allows to
  enter a vim _expression_.
* `expand(%:.:h)`: we see our `%` friend, which still represents the current
  filename
* `:.:h`: two file modifiers: one to get the path relative to the current
  directory (`:.`), and the other to find the dirname (`:h`)
* Then we add a `/` so that we can start typing the filename right away.

Here's how you use it

```text
:e /some/long/path/to/foo.c
<leader>ew foo.h
# opens /some/long/path/to/foo.h
```

### Step 6: A feature request

There are a lots of ways to use tab pages within Vim. Personally, I like the
"one tab page per project" way, and I used the following vimscript to enforce
one working directory per project:

```vim
function! OnTabEnter(path)
  if isdirectory(a:path)
    let dirname = a:path
  else
    let dirname = fnamemodify(a:path, ":h")
  endif
  execute "tcd ". dirname
endfunction

autocmd TabNewEntered * call OnTabEnter(expand("<amatch>"))
```

Note: this only works in Neovim. In Vim, there are events named `TabNew` and `TabEnter`
but the callback is *not* called with the tab name.

If you like, you can try and make it work by adapting the code and using the `WinEnter`
event. [This old bug](https://github.com/vim/vim/issues/1660) seems related.

## Conclusion

And that's all there is to it!

Full disclosure, I'm now using Kakoune (in which there are only buffers and no windows nor tabs).

But the same principle sticks:

* One i3 workspace per project
* One working dir per project
* One kakoune server per project

This should convince you there is value in taking time to think more about how _you_ handle working directories
in your everyday work.

Cheers!

---

_This article is licensed under the [Creative Common Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/). You are free to share and adapt this
article provided you give appropriate credits. Enjoy!_


[//]: # ( Vim: set spell spelllang=en: )
