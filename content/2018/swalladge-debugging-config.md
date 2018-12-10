---
title: "Debugging Vim Config"
publishDate: 2018-12-30
draft: true
description: TODO
slug: "debugging-vim-config"
author:
  name: "Samuel Walladge"
  email: "samuel@swalladge.id.au"
  github: "swalladge"
  picture: "https://www.gravatar.com/avatar/e1dc4dfcc798a49c1de0b2dcca4dee3c.jpg?s=512"
  twitter: "@srwalladge"
  irc: "swalladge"
  homepage: "https://swalladge.id.au"
---


Vim configuration is powerful and complex. I mean, this isn't setting a few
options in an INI file; we're talking about a Turing complete programming
language tailor made for scripting an editor. Thus, your config is a computer
program in itself, and of course this means that there will be bugs...

There can be many plugins and script files sourced, each one can run code at
basically any time, and each can set global variables and change global or
buffer options. If one script doesn't play well with another, or there is some
obscure bug, it can be a nightmare to ferret out the problem. Finally, some
combinations of options can cause unexpected behaviour when editing.

This article is going to cover a range of techniques and ideas I've learnt over
the years for maintaining a working configuration and quickly finding sources
of issues. This _isn't_ going to cover debugging complex plugins or Vim itself.


## Types of issues

There are a range of issues one might encounter:

- Crashes and errors
- Unexpected behaviour
- Confli




### Who turned on that option??

Vim has over 300 options ([:h option-list][option-list]) that can be set.
A common issue is that a particular option may be unexpectedly set by a plugin
and you want to find out which plugin and why. Here, you can use `:verbose` and
the `?` modifier to `:set`:

```
:verbose set shiftwidth?
```

This will display something like:

```
shiftwidth=2
      Modifié la dernière fois dans ~/.vim/pack/bundle/start/vim-sleuth/plugin/sleuth.vim
```

This tells me that `shiftwidth` was set to `2` by the [sleuth][sleuth] plugin.


NOTES:

things to cover:

- understanding script loading order
- showing autocmds, highlights, options, mappings set
  - :ab, :map, :scriptnames, :verbose
  - :map x lists mappings _starting with_ x
- organizing config
  - logical groupings
  - check if plugins loaded
- possibility of binary search debugging
- `:finish`
- -u/-U NONE/NORC, --noplugin
- possible plugins to help?
- vim log messages to file?
- :messages
- --startuptime
- verbose and verbosefile ref 

other overlapping articles or resources:

- http://inlehmansterms.net/2014/10/31/debugging-vim/
- https://vi.stackexchange.com/questions/2003/how-do-i-debug-my-vimrc-file
- http://of-vim-and-vigor.blogspot.com/2013/04/bisectly.html
- https://github.com/tpope/vim-scriptease





---

_This work is licensed under a [Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License][license].
Permissions beyond the scope of this license may be available by
contacting the author._

[license]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[option-list]: https://vimhelp.appspot.com/quickref.txt.html#option-list
[sleuth]: https://github.com/tpope/vim-sleuth
