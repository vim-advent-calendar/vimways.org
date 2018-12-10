---
title: "Death by a thousand files"
publishDate: 2018-12-10
draft: true
description: "Free yourself from the tyranny of files"
slug: "death-by-a-thousand-files"
author:
  name: "Romain Lafourcade"
  github: "romainl"
---


> A guy told me one time, "Don't let yourself get attached to anything you are
> not willing to walk out on in 30 seconds flat if you feel the heat around the
> corner."
>
> – Neil McCauley (1995)

## Moving with intent

Right after we learn Vim's most mundane commands (for writing, quitting, etc.)
some of the most immediately useful features are motions: `w` for "beginning of
next word", `B` for "beginning of current or previous WORD", etc. and the
grammar that allows us to combine them with various operators to form whatever
spell we need for the task at hand: `gqip` to "format this paragraph", etc.

Taking `w` as an example; that motion is demonstrated in *every* beginner-level
tutorial and typically used dozens of times a day by almost every vimmer but,
however useful it might be, it can easily be overused by mashing it until you
arrive at or near your destination.

Repeating intermediary jumps with `w` is only marginally better than repeating
`<Right>` or `l`. Sure it *may* take fewer keystrokes but we still go through
an undefined number of intermediary steps that are far removed from our actual
goal. A goal which, more often than not, is more in the vein of "go there"
rather than "go there, there, there, there, and finally *there*".

Zooming out a bit, it's easy to see that we tend to go through those
intermediary steps *a lot*:

* at the line level, by repeating short jumps,

* at the block level by jumping to its beginning or end,

* at the screen level by jumping from block to block,

* at the buffer level by jumping from screen to screen,

* and at the project level by jumping to a file to reach a symbol *within* that
  file.

What if we actually "went *there*" directly instead, in a more deterministic way?

At the line, block, and screen levels, incremental search helps tremendously.
We have our eyes on `getUserName` and we simply type `/` or `?`, followed by as
much of our target as necessary to land the cursor on it.

At the buffer level, commands like `:g/pattern/#` or `:ilist /pattern` help
a lot by letting us choose our destination from a list rather than jumping from
match to match. There's also `gD` to jump directly to the first instance of the
word under the cursor.

At the project level… it gets a little complicated.

Directories, files, paragraphs, lines, words, numbers, signs, etc. The way
computers have been designed for the last 40+ years make us think about those
things as… *things*. Physical objects with which we interact as if they were
*real*. We "cut" them as if they were tomatoes, "navigate" from one to another
as if they were harbors, etc.

But how necessary are those metaphors for thinking about our program/data flow?
Why should we care about paths, directories, or file names at all?

## Source code as a hierarchy

Because the file system is usually exposed as a hierarchy of (hierarchies of)
directories and files, knowledge workers naturally store the matter on which
they work and the fruit of their work into directories and files.  Directories
and files are where we, programmers, store the instructions that make our
program, just like our forefathers did with punch cards in file cabinets or
like ancient librarians did with rolls in Alexandria. Hell, some frameworks
even go to great lengths to enforce a "standard" directory structure in the
hope of making projects easier to grok, by people and machines alike.

There's nothing inherently wrong with any of that, of course: we are just using
a convenient and well understood metaphor.

But there are a number of fundamental limitations with that approach when
considered from a programmer's point of view.

### There's only one way to get from point A to point B

This is obviously not a problem when A and B are next to each other. 
But move B away from A, and the task of going from A to B suddenly turns
into a hassle because the path to B from A became harder to remember.

Reaching a different node (or leaf, as such hierarchies are often called trees)
implies moving up to a common root before moving down again.

### Moving stuff around can and do cause ripple-like undesirable effects across the whole project

Once you have moved B to a new location, every reference to B has to be updated
in A, C, R, etc., *with a different path from each node*. Sure you can let your
IDE deal with that but who can seriously pretend it *always* works as planned?
Automated tools are too greedy or too lazy and humans always fuck up their
"quick search & replace".

### Two different things can have the same name but be in different locations

Now, suppose you are currently fiddling with A and you need to take a look at
B. You summon your fuzzy finder and type away only to find out that there are
a bunch of resources called B. Ideally, figuring out which B is the right one
should be quick and easy, but keeping track of all those relationships between
resources is taxing and rebuilding a mental index each time you try to access
a resource is bound to break the flow.

### We need to maintain a complex map of our source code

To add to that mess, programming projects are rarely limited to just two
resources. We have dozens upon dozens of our own "things" and hundreds of
third-party dependencies to think about. That means thousands of ever-changing
relationships to keep in our head *at all times*. One huge cross-referenced map
that must be maintained in real time.

But what to do with that *other* project? And that one? More maps, more
juggling.

### The tree that hides the forest

I intentionally avoided talking about "files" and "directories" in this section
because the problem—and the maps we maintain to make sense of it—is not
restricted to files and directories. In fact, the fundamental "things" we deal
with when programming are not files and directories; **we actually deal with
the *symbols* that are stored in those files and directories**.

**Those symbols are what makes our program**, not files. Files and directories
are byproducts of the way we *organize* our source code, not our primary matter.
I believe those metaphors and the rigid, hierarchical vision that comes with
them, are dragging us down and forcing us to look in the wrong place for
solutions to largely imaginary problems.

### See the forest for the trees

The core issue, here is 

### Conventions to the rescue

## Moving with intent II

[//]: # ( Vim: set spell spelllang=en tw=80: )
