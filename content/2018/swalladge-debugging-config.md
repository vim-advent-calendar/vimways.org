---
title: "Debugging Vim Config"
publishDate: 2018-12-30
draft: true
description: Something's broken, why???
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
obscure bug, it can be a nightmare to ferret out the problem. Some combinations
of options can cause unexpected behaviour when editing.

This article is going to cover a range of techniques and ideas I've learnt over
the years for maintaining a working config and quickly finding sources
of issues. This _isn't_ going to cover debugging Vim itself or using debugging
mode.


## Understand the startup process

Vim's startup procedure is complex and results in scripts being sourced from
many locations and in a particular order. Understanding what files are sourced
and when scripts are run is important when it comes to understanding potential
issues and how to debug them. The best resource for this is [`:h
startup`][startup].

For example, it is not possible to run a function defined in a plugin from
`~/.vimrc`, because Vim sources `~/.vimrc` _before_ sourcing any `plugin`.
However, you could put the function in an `after` directory, because they are
sourced after normal plugin scripts.

If you need to see what scripts Vim has sourced once it has started up, you can
use the `:scriptnames` command to list them.


## Clean code!

I know this isn't a software project with code quality standards or required
TDD, but it is still helpful to write clean vimscript and part of that is
organizing everything neatly. Make the most of Vim's runtime directories
structure. See the post ["From .vimrc to .vim"][vimrc-to-vim] on Vimways for
some ideas in this direction.

Put code specific to a certain plugin in separate files with an include guard.
For example I store the following config for [fzf.vim][fzf-vim] in
`~/.vim/after/plugin/config/fzf.vim`.

```vimscript
" include guard; quit if fzf isn't loaded
if ! exists(':FZF')
    finish
endif

map <silent> <c-space> :Files<cr>
map <silent> <leader>t :Tags<cr>
map <silent> <leader>m :Marks<cr>
let g:fzf_layout = { 'down': '~20%' }
```

Putting it in an `after` directory means that it will only be sourced _after_
all other non-after plugins have loaded, so we can check if fzf has loaded
before binding any mappings.  Using a load guard means that I can temporarily
remove the fzf.vim plugin and know that nothing will crash and there won't be
any zombie mappings.

If all plugin-specific config is behind load guards, it's really easy
to disable any set of plugins to help narrow down the cause of an issue.

Finally, some plugins might require some global options set _before_ they are
loaded for them to take effect. For example, for Deoplete, I have a script
under `~/.vim/plugin/` that contains:

```
let g:deoplete#enable_at_startup = 1
```

And then further config under `~/.vim/after/plugin/` that will only run if
Deoplete is loaded. See, it _is_ useful to understand Vim's startup order!


### VCS

If you don't already, please consider storing your config in a version control
system! At the very least this will give you timestamped checkpoints and help
narrow down the source of a recently introduced bug. Future you will be forever
thankful.



## Why is Vim's startup slow?

OK, we've seen that Vim could end up sourcing many files on startup, especially
if many plugins are installed. It may happen that Vim can start taking a long
time to startup, and it can be useful to discover the culprit.

Start Vim with the `--startuptime <fname>` argument to profile the startup
process. This will produce a file containing lines such as:

```
069.228  004.840  004.646: sourcing /home/samuel/.vim/pack/bundle/opt/vimwiki/ftplugin/vimwiki.vim
070.164  000.018  000.018: sourcing /usr/share/nvim/runtime/autoload/provider.vim
317.745  247.930  247.912: sourcing /home/samuel/.vim/pack/bundle/opt/taskwiki/ftplugin/vimwiki/taskwiki.vim
331.351  012.951  012.951: sourcing /home/samuel/.config/nvim/after/ftplugin/vimwiki.vim
```

Hmm, taskwiki is taking over 200ms to load...

Vim also has good support for profile individual scripts. See [`:h
profile`][profile] for more information.


## Verbose

[`:verbose`][verbose] is your friend. This command executes its arguments as a
command but with the [`'verbose'`] option set to 1. This helps with what comes
next...

## Where did that option/mapping/command come from??

Sometimes you may want to figure out just what script last set an option,
mapping, command, etc. 

### Options

Vim has over 300 options ([:h option-list][option-list]) that can be set.  A
common issue is that a particular option may be unexpectedly set by a plugin
and you want to find out which plugin and why. (Eg. _Who turned off
`expandtab`?_) Here, you can use `:verbose` and the `?` modifier to `:set`:

```
:verbose set shiftwidth?
```

This will display something like:

```
shiftwidth=2
      Last set from ~/.vim/pack/bundle/start/vim-sleuth/plugin/sleuth.vim
```

This tells me that `shiftwidth` was set to `2` by the [sleuth][sleuth] plugin.

Note that if the option was set manually instead of inside a function, command,
or autocmd, it won't display where it was last set.

Similarly many other things can be listed and traced to their source:

### Mappings

Example command and output:

```
:verbose map <c-a>
x  <C-A>         <Plug>SpeedDatingUp
        Last set from ~/.vim/pack/bundle/opt/vim-speeddating/plugin/speeddating.vim
n  <C-A>         <Plug>SpeedDatingUp
        Last set from ~/.vim/pack/bundle/opt/vim-speeddating/plugin/speeddating.vim
```

Also note that `:map` lists all mappings that _begin with_ the key sequence
given. This is helpful for things like listing all insert mode mappings that
begin with the leader key:

```
:verbose imap <leader>
```


### Abbreviations

```
:verbose ab teh
i  teh           the
        Last set from ~/.vim/autoload/functions.vim
```

### Highlight groups

```
:verbose highlight Visual
Visual         xxx cterm=reverse ctermfg=10 ctermbg=8 gui=reverse guifg=#586e75 guibg=#002b36
        Last set from ~/.vim/pack/bundle/opt/flattened/colors/flattened_dark.vim
```

#### scriptease.vim

Let's just digress a moment to introduce a useful plugin!

[scriptease.vim][scriptease] is a helpful plugin by Tim Pope that provides some
commands and mappings to help debug scripts. Some commands are related to
debugging vimscript which is out of scope for this article, but others are more
relevant. Commands like `:Scriptnames` and `:Messages` are wrappers around the
native Vim counterparts that saves the output into the quickfix list for later
use.

Anyway, `zS` is a mapping provided by scriptease.vim that echos syntax
highlighting groups under the cursor. You can't show details on a highlight
group if you don't know what highlight group you want!

### Commands

```
:verbose command Sedit
    Name        Args       Address   Complete  Definition
    Sedit       *                                  call local#scratch#edit('edit', <q-args>)
        Last set from ~/.vim/init.vim
```


### Functions

```
:verbose function local#scratch#edit
   function local#scratch#edit(cmd, options)
        Last set from ~/.vim/autoload/local/scratch.vim
1    " use a system provided temporary file
<snip> (the whole function body is listed)
```

## It's more complicated than a single option/mapping/something

Sometimes it is helpful to run Vim with the bare minimum of config to see if
certain behaviour is present in vanilla Vim or in a particular plugin within a
clean environment. A combination of command line arguments can be used as shown
below (table taken from `:h --noplugin`):

argument     | load vimrc files  | load plugins
---          | ---               | ---
(nothing)    | yes               | yes
`-u NONE`    | no                | no
`-u NORC`    | no                | yes
`--noplugin` | yes               | no

`-u` can also be used to specify an alternative vimrc file to load. Be careful
though! `vim -u my-vimrc` will still load other scripts from `~/.vim/` as
usual. `vim -u my-vimrc --noplugin` will disable this behaviour and load only
from the `my-vimrc` file. Something to note is that Vim (not Neovim) also has a
`-U` argument which controls the gvimrc file sourced, which is relevant if you
use GVim.

An example minimal config for testing a particular plugin might look like:

```vimscript
" my-vimrc

" any required settings
set nocompatible
syntax on
filetype plugin indent on

" add the plugin to test here
" eg. (assuming available in an opt dir under packpath)
" this will work neatly with --noplugin
packadd nuake
```

Alternately, don't use `--noplugin` and manually set the `runtimepath` or
`packpath` to make sure the correct plugins are loaded. You should also decide
whether or not you want the system shipped runtime files loaded or not too.


## Something is still wrong?!?

Sometimes there can still be unexpected behaviour that can be difficult to
debug, especially if caused by plugins conflicting.  If your config is neatly
structured this is going to be easy! Otherwise, I would recommend pausing and
spending some time organizing config.  Anyway, we can use binary search to
locate the source of trouble!

The idea is to start by commenting out approximately half of your Vim
configuration. Start Vim and try to reproduce the unexpected behaviour. If the
behaviour is still there, then you know it's in the uncommented half of the
config. Otherwise, it's in the commented half. Then, with the remaining half,
comment out half of that and repeat. This can quickly hone in on a line in your
config causing the issue.

The `:finish` command can be helpful during this process; it stops sourcing the
script at that point so no code below `:finish` will be executed.

I find this technique helpful to find out which plugin is causing the issue. If
you use a plugin package manager or store plugins under `pack/*/opt/`, this is
as simple as commenting out the package manager commands or `:packadd` lines.

There is a plugin developed to automate this binary search process:
[Bisectly][bisectly]. I have never used it so I can't vouch for it. It is
however the only plugin I could find that advertises this functionality and may
be worth a look.


## The issue is in a plugin!

If you narrow the issue down to a plugin developed by someone else, then it's a
good idea (as with all open source projects) to open an issue on the plugin's
project page to alert maintainers and other users. If you can fix the issue
locally, consider opening a pull request to share the fix! Finally, if you
can't wait for a fix to be added upstream, open source means you can freely
fork the project, commit your fixes, and track your fork in your Vim config.


## Conclusion

With these techniques you should now be better equipped to track down and
squash those config bugs!


---

_This work is licensed under a [Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License][license].
Permissions beyond the scope of this license may be available by
contacting the author._

[license]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[option-list]: https://vimhelp.appspot.com/quickref.txt.html#option-list
[sleuth]: https://github.com/tpope/vim-sleuth
[startup]: https://vimhelp.appspot.com/starting.txt.html#startup
[vimrc-to-vim]: https://vimways.org/2018/from-vimrc-to-vim/
[fzf-vim]: https://github.com/junegunn/fzf.vim
[verbose]: https://vimhelp.appspot.com/various.txt.html#:verbose
[scriptease]: https://github.com/tpope/vim-scriptease
[profile]: https://vimhelp.appspot.com/repeat.txt.html#profile
[bisectly]: https://github.com/dahu/bisectly
