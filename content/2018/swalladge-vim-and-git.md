---
title: "Vim and Git"
publishDate: 2018-12-05
date: 2018-12-05
draft: false
description: Tips for integrating Vim and Git.
slug: "vim-and-git"
author:
  name: "Samuel Walladge"
  email: "samuel@swalladge.id.au"
  github: "swalladge"
  picture: "https://www.gravatar.com/avatar/e1dc4dfcc798a49c1de0b2dcca4dee3c.jpg?s=512"
  twitter: "@srwalladge"
  irc: "swalladge"
  homepage: "https://swalladge.id.au"
---

Vim and Git are both highly complex, configurable developer tools. Developers
who use Vim are likely to also need to use Git frequently. This article attempts
to explore how these two tools can interact in many ways.

First off, I'm not going to prescribe any particular workflows, or argue for or
against a particular method. There are just too many options and you are
encouraged to develop your own workflow.

Vim and Git are two separate tools and can of course be used that way. However,
it can be useful, time-saving, and convenient to integrate the two.

Note: I personally use Neovim, but practically everything will work the same in
Vim. Assume "Vim" in the post refers to both Neovim and Vim unless a distinction
is explicitly made.


## The Git perspective

From the perspective of Git there are several opportunities to utilize Vim:

- editing commit/tag messages,
- resolving merge conflicts (yay!),
- interactive rebasing

### Editing commit messages

If you have the `EDITOR` environment variable already set to Vim, Git should
automatically use Vim to edit messages. If environment variables aren't to be
relied on, the `core.editor` git config can be set:

```config
[core]
    editor = "vim"
```

When editing a commit message in Vim and you wish to abort, you can use the `:cq`
command to exit with a non-zero status. This will cause Git to abort the commit,
even if you had begun writing a message. Similarly, this trick can be used to
abort a merge or exit `difftool` if the corresponding `trustExitCode` option is
set to `true`:

```gitconfig
[difftool]
    trustExitCode = true

# the option is mergetool.<tool>.trustExitCode
# replace nvimdiff4 with the name of the mergetool you use
[mergetool "nvimdiff4"]
    trustExitCode = true
    ...
```

Additionally, be sure to use `git commit -v` or set `commit.verbose = true` in
your gitconfig file to have the full patch shown in Vim when editing the commit
message.


### Resolving merge conflicts

Before resorting to external diff tools to resolve conflicts, consider using
Vim's excellent diff mode to help! Vim can be configured to be used as Git's
`mergetool`, so it can be automatically launched with the correct configuration
and files ready to perform the merge when you run `git mergetool`. There are two
main methods which I've used: vanilla Vim (or Neovim) launched in diffmode, and
the `Gdiff` command supplied by [vim-fugitive][vim-fugitive]. Example
configuration below (this is my config with Neovim; launching Vim in diffmode is
slightly different):

```config
[merge]
    tool = nvimdiff4
    # if not using a tool name with builtin support, must supply mergetool cmd
    # as below

[mergetool "nvimdiff4"]
    cmd = nvim -d $LOCAL $BASE $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'

[mergetool "nfugitive"]
    cmd = nvim -f -c "Gdiff" "$MERGED"
```

The first method requires no plugins. It is simply Vim (Neovim) launched in
diffmode with the 4 files Git provides in environment variables. The wincmds
executed move the working file to full-width along the lower half of the window.

The second method uses the vim-fugitive plugin to automatically set up the
layout (it will choose horizontal or vertical splits depending on the terminal
size. It still uses Vim's diffmode, but only shows 3 files (local, remote, and
index).

For both methods, use `diffget` and `diffput` commands (with corresponding `do`
and `dp` bindings) to resolve conflicts.  Something I find helpful is to include
the buffer number in the status line as a quick reference when giving the buffer
number to `do` or `dp`. The item `%n` will do that. See `:h 'statusline'` for
more.

For further information, I recommend the [Vimcasts screencast on resolving merge
conflicts][vimcasts-vimdiff].

Likewise, `git difftool` can be set to use Vim too for displaying diffs:

```config
[diff]
    tool = nvimdiff2

[difftool "nvimdiff2"]
    cmd = nvim -d $LOCAL $REMOTE
```

### Interactive rebasing

I haven't had to perform rebases very often and so can't speak authoritatively
on the subject. I need to include it here though for completeness.

I do know that Vim is perfectly suited to the task though. Common actions map
neatly to Vim idioms:

Task | Vim commands
---|---
Change a command | `ciw`
Remove a commit | `dd`
Reorder lines | `<count>dd`, move up/down, `p` or `P`

Vim also includes commands to quickly change a command (`:Pick`, `:Squash`, etc.)
or cycle between them (`:Cycle`). See [gitrebase.vim][tpope-gitrebase] for all
available commands. Add keybindings for these for even more efficiency!

## The Vim perspective

OK, so the flip side: how can Git be integrated into Vim?

### Vanilla

Let's begin with useful things you can do with no plugins required.

#### `:!git`

One way is to shell out directly to Git to run a command. Be aware that
interactive stdin is impossible currently in Neovim so any commands that prompt
for input will fail.

```vim
:!git stash
```

#### `:terminal`

Neovim, and more recently Vim, have embedded terminals that can be launched with
the `:terminal` command. This enables having a complete shell (and Git command
line tools) within Vim. Very useful if using Gvim, or don't want to suspend/quit
Vim to get back to a shell.


### Configuration

The `autoread` option will make Vim automatically read the file again if it
detects the file has been changed outside of Vim. The `:checktime` command
checks if any buffers have been changed outside of Vim. This is especially
useful when in an autocmd that runs `:checktime` in cases where a file is likely
to have changed outside of Vim (I use `FocusGained` and `CursorHold`). Together
they are very useful when checking out different commits and don't want Vim
complaining that a file has changed on disk and prompting for an action.

```vim
set autoread
autocmd FocusGained,CursorHold ?* if getcmdwintype() == '' | checktime | endif
```

Warning: with this configuration, changes to a buffer from inside Vim are lost
when it reloads the changed file from disk. This may be safer with a Vim config
that automatically writes files. See [this blog post][alberto-autowrite] for
more info on the topic.

Nobody wants to commit merge conflict markers, so let's highlight these so we
can't miss them:

```vim
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'
```

Generally the first line of commit messages should be a maximum of 50 characters
long, and the body 72 characters. Correct spelling is also nice. With some
config, Vim can help!

```vim
" Note: put this in ftplugin/gitcommit.vim or in a filetype autocmd.

" show the body width boundary
setlocal colorcolumn=73
setlocal textwidth=72

" warning if first line too long
match ErrorMsg /\%1l.\%>51v/

" spell check on
setlocal spell
```

### Plugins

#### [Fugitive.vim][vim-fugitive]

**The** Git plugin. There are many articles about Fugitive so I won't go into it
in much detail. Basically, it provides many Vim commands for working with the
repo, a diffing setup for staging changes, interactive status window, etc. It is
very powerful and it's worth reading the docs and other resources for learning more
about what can be achieved with Fugitive. I highly recommend the [Vimcasts
series on Fugitive][vimcasts-fugitive].

Some of its features I use consistently are:

- `%{FugitiveStatusline()}` to display the current branch in the statusline.
- `:Gblame` for instant `git blame` in Vim.
- `:Gdiff` for staging hunks and viewing diffs.


#### GitGutter/Signify

[GitGutter][gitgutter] and [Signify][signify] are both plugins whose job is to
show diff information in the sign column. GitGutter is tailored for Git, and
provides some useful extras, such as undoing hunks. Signify has historically
been faster, but recent refactoring efforts in GitGutter has levelled the
playing field. I'd recommend GitGutter for its extra features if you only use
Git, or Signify if you also need support for other VCSs.

Both plugins support functions to embed the number of added/removed/modified lines
in the statusline. For example, my current statusline generating function
includes:

```vim
let l:hunks = GitGutterGetHunkSummary()
if l:hunks[0] || l:hunks[1] || l:hunks[2]
  let l:line .= '%#GitGutterAdd# +' . l:hunks[0] .
              \ ' %#GitGutterChange#~' . l:hunks[1] .
              \ ' %#GitGutterDelete#-' . l:hunks[2] . ' '
```


#### GV

[GV][gv] is an excellent Git browser for Vim.

#### Vimagit

[Vimagit][vimagit] is an attempt to bring some of Emacs's famous [Magit][magit]
to Vim.  It provides a single buffer where you can launch Git commands, stage
hunks/files, and commit.  Its interface is very nice (IMHO), but unfortunately
it suffers from low performance. Worth checking out but is perhaps not mature
enough to support efficient workflows yet.


#### Committia

[Committia][committia] Committia is a simple plugin to help make editing commit
messages smoother by displaying the diff in a vertical split. I found it really
useful until I discovered verbose mode for `git commit` which loads the diff
into the buffer too. I think it still has potential due to the neat layout it
provides and bindings to navigate the diff buffer. YMMV.


### Branch managers

I recently discovered some cool plugins for managing Git branches (and related
tasks). [Twiggy][twiggy] and [Merginal][merginal] are both very similar and
provide a command to open a buffer in a vertical split for performing actions on
branches, such as switching, merging, pulling, pushing, stashing, and deleting.
These are recent discoveries and I believe show much promise. I also think that
these finds highlight the richness of the Vim plugin ecosystem. There are so
many lesser-known and useful plugins which may fit in perfectly with your
workflow.


## Github specific goodies

Github is one of the most popular Git repository hosting services, and it
follows that there are some helpful Vim plugins for further Git repository
integration if hosted on Github.

[rhubarb][rhubarb] is a Vim plugin to complement Fugitive that enables opening a
Git object on Github in the browser. It's very convenient when you are working
in Vim on a local repository and wish to refer someone to a particular line or
file. For example:

```vim
:1,5Gbrowse
```

Rhubarb also contains an autocompleter for Github issues when editing commit/tag
messages.


## My workflow

So what about my workflow, you may ask. Well I consider my workflow to be very
scattered. I use whichever method of performing a Git action as happens to be
most convenient at the time. Generally I use Tmux and have a pane/window open
that I can switch to and run Git commands when I need to do a series of
Git-specific actions. Otherwise I try to stay in Vim as much as possible to
avoid context switching. To this end, I find GitGutter great in Vim to see which
lines have been changed and not staged. I'm also beginning to use Fugitive more
frequently, and often experiment with other plugins to see how they can help.

Something I can't stress enough is the importance of learning a tool and forcing
yourself to use that tool everywhere possible until it reaches muscle memory if
it's to actually be an improvement to your workflow. I've found that there's no
point having convenient plugins installed if I end up forgetting about them and
falling back to less efficient methods simply because they are the ones I'm most
familiar with. That said, sometimes the most efficient method is the one that
requires less context switching. If in the CLI, then `git status` is faster than
switching to Vim and running `:Gstatus`, and vice versa.


## Conclusion/Takeaways

Vim and Git are two powerful tools which can complement each other with a bit of
configuration work.

If you only want to install the minimum of Vim plugins, make one of them
Fugitive.vim, and the other GitGutter.

Experiment! You are working with two mature, powerful tools which can be used
and extended in many ways to suit your workflow.



_This work is licensed under a [Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License][license].
Permissions beyond the scope of this license may be available by
contacting the author._


[committia]: https://github.com/rhysd/committia.vim
[gitgutter]: https://github.com/airblade/vim-gitgutter
[gv]: https://github.com/junegunn/gv.vim
[magit]: https://magit.vc/
[merginal]: https://github.com/idanarye/vim-merginal
[rhubarb]: https://github.com/tpope/vim-rhubarb
[signify]: https://github.com/mhinz/vim-signify
[tig-exploror]: https://github.com/iberianpig/tig-explorer.vim
[tig]: https://github.com/jonas/tig
[twiggy]: https://github.com/sodapopcan/vim-twiggy
[vim-fugitive]: https://github.com/tpope/vim-fugitive
[vimagit]: https://github.com/jreybert/vimagit
[vimcasts-vimdiff]: http://vimcasts.org/episodes/fugitive-vim-resolving-merge-conflicts-with-vimdiff/
[reddit-rebase-bindings]: https://www.reddit.com/r/git/comments/6lln75/vim_keybindings_for_interactive_rebase/
[vimcasts-fugitive]: http://vimcasts.org/blog/2011/05/the-fugitive-series/
[tpope-gitrebase]: https://github.com/tpope/vim-git/blob/master/ftplugin/gitrebase.vim
[csswizardry-tweet]: https://twitter.com/csswizardry/status/841666536267997185
[license]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[alberto-autowrite]: http://albertomiorin.com/blog/2012/12/10/autoread-and-autowrite-in-vim/index.html
