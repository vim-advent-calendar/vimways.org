---
title: "Vim and Mercurial"
publishDate: 2018-12-23
draft: false
description: Tips for integrating Vim and Mercurial.
slug: "vim-and-mercurial"
author:
  name: "Ludovic Chabant"
  email: "ludovic@chabant.com"
  github: "ludovicchabant"
  picture: https://secure.gravatar.com/avatar/c7cbfd8ce858aa738a29329a89cc2fe5
  twitter: "@ludovicchabant"
  irc: "ludovicchabant"
  homepage: "https://ludovic.chabant.com"
---

In a [previous entry][2] in this year's Vimways advent blogging, Samuel Walladge
detailed how to make Vim and Git work together... since it was quite good,
I figured I would write a similar entry about making Vim and Mercurial work
together! And to do so, I'm totally going to plagiarize Samuel's article
structure! Let's dive in.


## The Mercurial perspective

Just like Git, Mercurial needs to open a text editor for some operations:

- editing commit messages.

- editing history (the "interactive" half of what Git calls "interactive
  rebasing").

Mercurial also needs to open some kind of tool (not necessarily a text editor...
but you can guess which tool we'll use!) for some other operations:

- showing a diff.

- resolving a merge.

### Editing commit messages

Just like Git and pretty much every other tool in existence, Mercurial checks
the `$EDITOR` environment variable to know what text editor to use. And just
like Git, it also offers a configuration setting for when it's easier to set it
this way:

```config
[ui]
editor = vim
```

If you have both `$EDITOR` and `ui.editor` set, Mercurial favours `ui.editor`.

Once you've run `hg commit` and Vim opens, you can type your commit message as
usual. If you change your mind, you can do `:cq` and exit Vim with a non-zero
exit code, which Mercurial will detect and abort the commit. Otherwise, `:wq`
will exit normally and Mercurial will proceed.

### Editing history

Where Git has `git rebase --interactive` to do both rebasing and history
editing, Mercurial has two different operations: `hg rebase` to rebase, and `hg
histedit` to edit history. Rebasing doesn't require the involvement of a text
editor, but history editing does.

First, Mercurial doesn't let you edit history by default. It wants you to
consciously opt-in to this type of tricky command, by enabling the extension it
comes in:

```config
[extensions]
histedit =
```

Once that's done, you'll get the `hg histedit` command, which as usual reads the
`$EDITOR` environment variable and the `ui.editor` configuration setting. The
text buffer that will open in Vim will look very similar to the one from Git's
interactive rebase, so just use `ciw`, `dd`, and `p` or `P`.

## Showing a diff

Using `hg diff` prints out a diff in the terminal. To use an external tool,
you'll need to enable another extension (yes, Mercurial is [big on forcing you
to enable extensions][3], sadly):

```config
[extensions]
extdiff =
```

Then you can configure one or more "external diff tools" for Mercurial to use,
like, for instance:

```config
[extdiff]
cmd.vimdiff = vimdiff
```

You can then run `hg vimdiff ...` and it will open Vim in diff mode over the
changed file. Sadly, it only works fine for cases where you're only diffing
a single file. If you pass a revision that touched multiple files, the `extdiff`
extension will copy the previous/next versions of those files into a pair of
temporary directories, and pass those to Vim. Vim doesn't have anything to
handle directory diffing out of the box.

The standard solution for this is to install the [DirDiff][] Vim plugin, which
does exactly what the title implies. Its only drawback is that it's not very
friendly to non-traditional Unix setups -- Windows, or using Fish as your shell,
among other examples, make the Vim plugin fail.

You can still try it yourself by following the example on the [Extdiff
extension][extdiff]'s wiki page:

```config
[extdiff]
# add new command called vimdiff, runs gvimdiff with DirDiff plugin
# (see http://www.vim.org/scripts/script.php?script_id=102)
# Non english user, be sure to put "let g:DirDiffDynamicDiffText = 1" in
# your .vimrc
cmd.vimdiff = vim
opts.vimdiff = -f '+next' '+execute "DirDiff" fnameescape(argv(0)) fnameescape(argv(1))'
```

#### A note on your working directory

Watch out for plugins or scripts you might have in your `.vimrc` that change the
working directory! I had some issues with my configuration of `vim-projectroot`
which I had setup to automatically `cd` into the current buffer's project root.
This messed up `extdiff` because the way it runs the external tool is:

- Set the current working directory to a temporary folder that contains the
  2 sub-folders with all the files' snapshots.

- Pass the name of those 2 sub-folders as arguments to the external tool.

As such, if Vim's current working directory is changed by the time it executes
`DirDiff`, it will fail to find anything.


## Resolving a merge

Thankfully, resolving merges with Vim's 3-way diff mode is supported pretty much
out of the box. In most distros' Mercurial package, there's actually a _lot_ of
external tools supported for resolving merges in Mercurial. Check them out by
typing `hg config merge-tools`.

The one we're interested in is, of course, declared as `vimdiff`. Unless your
Mercurial install was somehow packaged differently for your OS, it should look
a bit like this:

```config
merge-tools.vimdiff.args=$local $other $base -c 'redraw | echomsg "hg merge conflict, type \":cq\" to abort vimdiff"'
merge-tools.vimdiff.check=changed
merge-tools.vimdiff.priority=-10
```

At this point, you just need to bump the priority in your own `.hgrc` if it
doesn't pick it up by default because it finds another available tool with
a higher priority on your system:

```config
[merge-tools]
vimdiff.priority = 99
```

The default configuration puts the "local" file on the left, the "other" file in
the centre, and the "base" file on the right. I prefer to have the "base" file
in the middle, so I can better reason about how each side (left and right)
modified the code from that base version... so I just copied the default setting
and switched up the arguments in my configuration file:

```config
[merge-tools]
vimdiff.args=$local $base $other -c 'redraw | echomsg "hg merge conflict, type \":cq\" to abort vimdiff"'
vimdiff.priority=99
```

From there, you can do a mix of `diffget`/`diffput` (with `do` and `dp` as their
default bindings... people usually remember `do` as "_diff obtain_"), and ad-hoc
editing for trickier situations. Unlike a normal diff, however, you can't use
`do` and `dp` directly: you have to specify which buffer you're putting in or
obtaining from. The buffers in this case are simply numbered from left to right
(1 is "local", 2 is "base", 3 is "remote") so you can do `3do` or `1dp` and
such. Alternatively, you can change your `statusline` to display `%n` when
a buffer has `&diff` enabled, but I don't find that necessary.


## The Vim perspective

### Vanilla

As the [original article][2] explains with Git, a quick way to run Mercurial
from inside Vim is to use any of:

- `:!hg`, which will execute the Mercurial process in a new shell. Unless you
  add some fancy syntax around it, it has the downsides of blocking Vim until the
  process exits, and not being able to interact with that process (like entering
  input).

  Here you can make use of Vim's `%` shorthand for the current buffer, like with
  `:!hg add %`.

- `:terminal`, which gives you a shell where you can run Mercurial and any other
  command line tool.

And, again from the [original article][2], you can check some common Vim
configuration details to auto-reload files when you do an operation that changes
your working copy (_e.g._ `hg update`), highlight conflict markers, and so on.

#### A note on conflict markers

Note however that Mercurial doesn't leave conflict markers by default. That's
because it will just run some non-interactive pre-merge step using its own
internal merging algorithm, and will run the external tool (which we just
configured above to be Vim) if it finds any conflicts... in which case it shows
you "clean" files for you to resolve.

As a result, you will only see conflict markers if you specifically changed
Mercurial's configuration to do that. For example, you may change the pre-merge
step to be `:keep-merge3`.

Given the sheer amount of customizability that Mercurial's merging gives you,
this goes way out of scope for this article, but if you're not happy with how it
works, check out the [`merge-tools` configuration section help][5] and the [help
page on merge tools][4]. There's really little chance you can make it work
exactly the way you want.


### Plugins

Since Mercurial is a lot less popular than Git, it also has a lot less available
plugins for Vim.

#### [Lawrencium][]

I can start with a shameless plug (hohoho) for my plugin!

Written by yours truly, it started as a port of [Fugitive][] for Mercurial, but
it has since taken a life of its own. I think it's pretty solid, but you may
find that it breaks down a bit if your workflow differs too much from mine.
That's what bug reports and pull request are for, though!

It provides you with an interactive `hg status` window, easy ways to show diffs
in various ways, some basic `hg log` and `hg annotate` views, and more.

[Check it out][lawrencium] and report back!

#### [Signify][]

Already mentioned in the [original article][2], Signify gives you an idea of
what you modified in the current buffer. Unlike [Gitgutter][], which the
original article also recommends, Signify works with a multitude of VCSes,
including Mercurial.

---

This article was originally posted [on the author's blog][original].


[vimways]: https://vimways.org
[2]: https://vimways.org/2018/vim-and-git/
[4]: https://www.mercurial-scm.org/doc/hg.1.html#merge-tools
[5]: https://www.mercurial-scm.org/doc/hgrc.5.html#merge-tools
[extdiff]: https://www.mercurial-scm.org/wiki/ExtdiffExtension
[dirdiff]: https://github.com/will133/vim-dirdiff
[mergetools]: https://www.mercurial-scm.org/doc/hgrc.5.html#merge-tools
[lawrencium]: https://bolt80.com/lawrencium/
[fugitive]: https://github.com/tpope/vim-fugitive
[signify]: https://github.com/mhinz/vim-signify
[gitgutter]: https://github.com/airblade/vim-gitgutter
[original]: https://ludovic.chabant.com/devblog/2018/12/23/vim-and-mercurial/
