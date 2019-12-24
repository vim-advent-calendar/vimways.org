---
title: "You Should Be Using Tags In Vim"
publishDate: 2018-12-02
draft: false
description: "You may not know it, but Vim already does what you installed a Jedi plugin to do"
slug: "you-should-be-using-tags-in-vim"
author:
  name: "Daniel Moch"
  email: "daniel@danielmoch.com"
  github: "djmoch"
  picture: "https://secure.gravatar.com/avatar/9709a880ad3885e14781a3cb757e09f3?s=400"
  twitter: "@\_djmoch"
  freenode: "djmoch"
  homepage: "https://www.danielmoch.com"
---

> I love you; you complete me.
>
> – Dr. Evil

I first came to Vim by recommendation. I was looking for a good Python
IDE (at the time I was new to the language) and one recommendation was
to use Vim with a variety of plugins added on top. That Vim could do a
lot of the things I thought only an IDE could do came as a bit of a
shock. I spent a summer as an intern using Emacs at a Unix terminal, but
didn't have enough curiosity at the time to use it any differently from
`notepad.exe`. I spent that summer wishing I had automatic features for
completion, indentation, and all the things that made me appreciate
the IDEs I used in college.  How naive I was!

So how was I directed to achieve powerful programming completions in
Vim? By the use of a plugin called YouCompleteMe. My experience with it
was okay, at least to start with. It took a while to install and get
working, but that didn't bother me at the time since I was just playing
around with it at home and the stakes were low if it suddenly broke. I
did notice it slowed Vim down. Like a lot. But that was mainly when it
was starting up and I didn't know enough to find it frustrating.
Probably the first thing that really bothered me about the plugin was
that the embedded Jedi language server used more memory than Vim itself.
The other recommended plugins were similarly laggy, and I eventually
went in search of something better.

What I found was Vim itself.

Did you know that Vim has built-in facilities for completions? It works
admirably well out of the box too, but with a little bit of additional
setup it can be great. Let's take a look at what Vim has on offer
regarding completion and see what it takes to fully leverage it.

## Completion in Vim

Completion in Vim is powerful, but not necessarily straightforward. Read
[`:h ins-completion`][ic] and you'll see what I mean:

```text
Completion can be done for:

1. Whole lines                                   |i_CTRL-X_CTRL-L|
2. keywords in the current file                  |i_CTRL-X_CTRL-N|
3. keywords in 'dictionary'                      |i_CTRL-X_CTRL-K|
4. keywords in 'thesaurus', thesaurus-style      |i_CTRL-X_CTRL-T|
5. keywords in the current and included files    |i_CTRL-X_CTRL-I|
6. tags                                          |i_CTRL-X_CTRL-]|
7. file names                                    |i_CTRL-X_CTRL-F|
8. definitions or macros                         |i_CTRL-X_CTRL-D|
9. Vim command-line                              |i_CTRL-X_CTRL-V|
10. User defined completion                      |i_CTRL-X_CTRL-U|
11. omni completion                              |i_CTRL-X_CTRL-O|
12. Spelling suggestions                         |i_CTRL-X_s|
13. keywords in 'complete'                       |i_CTRL-N| |i_CTRL-P|
```

Vim is smart enough to pull completion data from a variety of sources,
but in turn expects users to know which source will provide the best
answer and to invoke the correct keymap to draw the desired completions.
It's not a huge hurdle in terms of a learning curve, but it's not as
simple as hitting tab either.

The first thing one should do when trying to learn Vim's completion
system is to disable any completion plugins and learn these keymaps.
Getting comfortable with them will also help you learn and remember
where Vim can pull completion information from. You should also read [`:h
'completefunc'`][cf] and [`:h 'complete'`][co] for more information on
user-defined completion and the `complete` option.

Now that we have a cursory understanding of completion in Vim, let's
take a deeper look at tags and how they figure into completion.

## Introduction to `tags` in Vim

One source of completion in Vim is tag completion, which pulls from a
special file called–appropriately—a tags file. Tags files are collections
of identifiers (e.g., function names) that are compiled into a single
file along with references to their location in a source tree.  Vim is
capable of using a (properly formatted) tags file for a variety of use
cases, among them navigating your source code à la Visual Studio and
providing code completion.

By default Vim doesn't do anything with a tags file except read it. See
[`:h 'tags'`][to] to learn how to configure where Vim looks for tags
files. Vimdoc also contains a very good [introduction][ti] to tags more
generally, so I won't spend any more time here introducing them. Let's
move on and take a look at how we generate tags files.

## Introduction to `ctags`

Tags files solve the problem of navigating and completing code in a
given project, but they also create a problem: how do we create the tags
file, and how do we keep it up to date? It would be a pain to manually
maintain the tags file even for a small project; it would be all but
impossible to do it for a large project like the Linux kernel. Luckily
no one has to maintain a tags file. There are plenty of utilities to do
that for you, usually bearing the name ctags, or some variant. One very
popular choice is called [Exuberant Ctags][ec], which has the virtue of
being extendable via regular expressions placed into a `.ctags` file,
but the drawback of not having been updated since 2009.  Another
increasingly popular option is [Universal Ctags][uc], which functions as
a drop-in replacement for Exuberant Ctags and is actively maintained.
I've had good luck with both.

Tags files and the tools that generate them have a long history
alongside advanced text editors. The history-of-computing nerd in me
likes knowing that I'm using the same tool programmers have used since
the early days of BSD Unix. It's also a testament to how strong of a
solution they provide that folks are still using them 40 years later.

## Generating `tags` Files

### Manually

When we speak of manually generating tags files, we're talking about
using any one of the aforementioned tags utilities to generate the tags
file. If you're the type of person who takes pleasure in at least
understanding how to do things from the command line, you should consult
the manual page for your selected tags utility. Take special note of the
flags necessary to recurse through all of the subdirectories if you want
to generate a tags file for an entire project in one shot.

### Automatically

You can always use your ctags utility to generate your tags files from
the command line, but that's a heck of a lot of back and forth between
your text editor and your shell, and I doubt anyone who tries to do that
will enjoy the experience for long. So let's look at ways to generate
them automatically.

If you only ever see yourself using tags files with Vim, then maybe a
plugin will interest you. I used [Gutentags][gt] for a long time, and
found it "just works" as advertised. It has sane defaults, but lots of
opportunities to customize its behavior, which you'll see if you visit
the above link.

In spite of that, I ended up moving in a different direction with
managing my tags files. There were several reasons, but the main one is
that I like to think of tags files as separate from Vim, something the
text editor consumes without having to manage. It's an opinionated view
of things, but I increasingly didn't like to configure my text editor to
manage my tags files. So I went in search of another method, and what I
found was the [Tim Pope][tp] method, which I've since implemented
myself. Rather than using Vim itself to manage tags files, this method
uses local [Git hooks][gh] to rebuild the tags whenever any of a handful of
common Git operations are performed. The result is a system that also
just works, but does so in a half-a-dozen lines of shell script rather
than a few _hundred_ lines of Vimscript. Gotta keep that Vim config
tight.

As a bonus, if you already use Tim Pope's [Fugitive Git
plugin][fugitive] (and you should), this method handily places your tags
file where that plugin tells Vim to look for it—in the `.git` folder.
Of course the shell-script approach is infinitely configurable, so you
can ultimately place the tags file wherever you want. One could also
tailor this for other distributed SCM tools (e.g., Mercurial).

Generically speaking, there are other options as well. You could set a
filesystem watcher to watch your project tree and run ctags any time a
file changes. A task runner like [Grunt][grunt] might be a viable option
too, especially for web developers. The goal is to automate the task of
(re)generating your tags file, so there is likely to be no shortage of
options.

## Tying It All Together

That brings us back to where we started, to the issue of code completion
in Vim. Yes, Vim does offer native code completion (completing from tags
is done with `C-x, C-]` in insert mode). No, it's probably not as
powerful as what you could get with something like a Jedi plugin à la
YouCompleteMe, but I've found it satisfies my needs more often than not,
with `:grep` (or my own [`:GrepJob`][mj]) filling the gap nicely in a
more native fashion.

There's more you can do here too. For instance, if you find yourself
instinctively reaching for the tab key in order to complete a word,
there is [VimCompletesMe][vcm], which takes advantage of all of Vim's
built-in completions through the clever use of an [omni completion
function][oc]. It works, but users do give up some control over selecting
what data source Vim uses for a particular completion. I used this
plugin for a while after I gave up on YouCompleteMe, but ultimately
removed it because it effectively made the tab key ambiguous in Insert
mode. Sometimes I wanted to insert an actual tab character, but got a
completion instead.

With all of this in place, it's natural to ask whether a language server
is even necessary with Vim. I don't intend here to suggest an answer to
that question, but I will say that many of the solutions to date for
language server integration in Vim have seemed like more trouble than
they're worth. That said, with the advent of Vim 8 and its asynchronous
capabilities, there is headroom for these solutions to improve, and I
expect the best among them to become more compelling in the near future.

I do not recommend coming to Vim with a mindset of creating an IDE in
your terminal. That said, Vim is a very powerful tool and if you invest
the time to learn how it works it will take you very far. In other
words, use Vim for all it's worth _before_ looking for a plugin to help
you out. Anyone who (like me) jumps right to installing a bunch of
plugins—whether in a spree of grabbing anything that looks interesting
or just to copy someone else's configuration—will likely end up with an
unmaintainable mess of a tool that doesn't work consistently, may not
work at all, or works about as slow as the IDE you wanted to break free
of.

_This work is licensed under a [Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License][license].
Permissions beyond the scope of this license may be available by
contacting the author._

[ic]: http://vimdoc.sourceforge.net/htmldoc/insert.html#ins-completion
[ec]: http://ctags.sourceforge.net/
[uc]: https://ctags.io/
[gt]: https://bolt80.com/gutentags/
[tp]: https://tbaggery.com/2011/08/08/effortless-ctags-with-git.html
[gh]: https://git-scm.com/docs/githooks
[fugitive]: https://github.com/tpope/vim-fugitive
[mj]: https://git.danielmoch.com/vim-makejob.git
[vcm]: https://github.com/ajh17/VimCompletesMe
[oc]: http://vimdoc.sourceforge.net/htmldoc/options.html#'omnifunc'
[github]: https://github.com/djmoch
[twitter]: https://twitter.com/_djmoch
[cf]: http://vimdoc.sourceforge.net/htmldoc/options.html#'completefunc'
[co]: http://vimdoc.sourceforge.net/htmldoc/options.html#'complete'
[to]: http://vimdoc.sourceforge.net/htmldoc/options.html#'tags'
[ti]: http://vimdoc.sourceforge.net/htmldoc/usr_29.html#29.1
[license]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[grunt]: https://gruntjs.com/
