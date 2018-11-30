---
title: "Vim and Git"
date: 2018-10-14T11:11:59+02:00
publishDate: 2018-12-12
draft: true
description: An article on this or that.
---

# Vim and Git



It is impossible to lay out a definitive set of rules to follow for working with
Git from a Vim user's perspective. There are so many workflows and so many
options for integrating Vim and Git together. If we were talking about an IDE,
then the easy answer would be to use the IDE's Git integration. But this is Vim,
where we build our own IDE.

Getting to assemble our own IDE is awesome for several reasons. Firstly,
developers are unique individuals with unique workflows; building our own means
the result will be tailor made. Secondly, building an IDE with Vim can follow
the Unix philosophy of "do one thing and do it well".

This flexibility and power comes with some challenges though. How do you
decide on the "best" workflow without spending a large amount of time trying
all the possibilities? How can you find what options are available? How can you
overcome muscle memory and begin adopting a new workflow?

Hopefully this article will help with the above questions by describing various
workflows and providing tips for getting the most out of each. Obviously I'm
only authoritative on my particular workflow (which I believe needs improving),
so take this as a best effort attempt.

Here goes.


## Workflows

- "vanilla" Vim
- Tmux
- Fugitive
- `¯\_(ツ)_/¯`


### Vanilla

It's possible to have a perfectly legit setup with vanilla Vim, the command line
Git client, and a terminal. Sometimes this is the only option if you need to
speedily edit something on a server, virtual machine, or new installation.

Tips

Vim is just a process running inside the shell. We can take advantage of that by
suspending the process with `<c-z>`. This drops up back to the shell were we can
run Git commands as required. Then resume Vim and get back to editing by the
`fg` command.


If checking out different versions of a file in Git while that file, Vim will
complain about the file being changed externally and prompt for an action to
take. With `:set autoread`, external changes will be automatically loaded into
the buffer for a smoother workflow. `u` will undo the change.


If you don't want to leave vim, it is simple to run a git command by shelling
out. For example: `:!git status`. `%` expands to the current filename, so
something like `:!git log %` will show the commit history of the file open in
the current buffer.

New Vim and Neovim versions also have an integrated terminal. `:terminal`

TODO

### Tmux

- popular
- switch between tmux panes/windows; one for vim, another for shell/git
- no suspend/fg required


### Plugins

- plugins can augment the above
- plugins can replace the above


## Let's talk about plugins


### Fugitive

**The** git plugin. There are many articles about Fugitive so I won't go into it
in much detail. Basically, it provides


### Committia

for editing commit messages. more about this later.

### signify/gitgutter

diff status in the gutter


### :GV

tig-style browser in vim


### tig-explorer

newer plugin for integrating tig with vim

### vimagit

attempt to bring some magit style to vim

- slow?


### others?

add more lesser-known niche git plugins (there are several)



## Config


vim config things here?


## Git config

We can't discuss using vim with git without covering how to work with git's
configuration to help integrate it better!

- `$HOME/.gitconfig`
- global and project-local
- mergetool setup for vim and nvim
- vim-fugitive with mergetool (should this be here or under fugitive section? so
  many cross-cutting concerns I'm not sure how to structure the article...)
- diff - from git's side


## Neovim vs Vim

- differences that affect working with git
- no interactive stdin with `:!command` in neovim
- less differences now both have async and :terminal



## Tips and tricks (aka I don't know where to put these)

### Editing commit messages

`:cq` in vim to exit with a non-zero status. This will abort the commit even if
you had begun writing a message. If the editor is exited normally without
writing any message, the commit will be aborted anyway.


#### [committia.vim](https://github.com/rhysd/committia.vim)

Committia is a simple plugin to help make editing commit messages smoother.
This is separate to other plugins like fugitive. If you are already in vim, then fugitive will give a more advanced
commit workflow. However, committia is useful when you are working on the
command line and just want to commit with `git commit ...`. In this case, your
configured editor will launch with the `COMMIT_EDITMSG` file to edit the commit
message. If you `git commit -v ...`, then you already get the diff view, but
committia adds some niceties:

- shows diff and status sections in separate buffers, split so everything is
  visible.
- `<Plug>` mappings for scrolling the diff buffer from the edit buffer.
- hook functions for opening windows event.

The workflow can then be along these lines:

1. Run `git commit` from the shell.
2. Vim opens and committia sorts out the buffers.
3. Begin typing the commit message.
4. Press your keybinds to scroll the diff to view more to help draft the commit
   message.
5. Close vim to finalize the commit.


### Tig and friends?

???

### github-specific

- autocompletion for github issues
- hub
- `:Gbrowse` with fugitive and rhubarb

