---
title: "Death by a thousand files"
date: 2018-10-14T11:11:59+02:00
publishDate: 2018-12-09
draft: true
description: An article on this or that.
---


> A guy told me one time, "Don't let yourself get attached to anything you are not willing to walk out on in 30 seconds flat if you feel the heat around the corner."
>
> - Neil McCauley (1995)

## Moving with intent

Right after we learn Vim's most mundane commands (for writing, quitting, etc.) some of the most immediately useful features are motions: `w` for "beginning of next word", `B` for "beginning of current or previous WORD", etc. and the grammar that allows us to combine them with various operators to form whatever spell we need for the task at hand.

Taking `w` as an example; that motion is demonstrated in *every* beginner-level tutorial and typically used dozens of times a day by almost every vimmer but, however useful it might be, it can easily be overused by mashing it until you arrive at or near your destination.

Repeating intermediary jumps with `w` is only marginally better than repeating `<Right>` or `l`. Sure it *may* take fewer keystrokes but we still go through an undefined number of intermediary steps that are far removed from our actual goal. A goal which, more often than not, is "go there" rather than "go there, there, there, there, and finally *there*".

Zooming out a bit, it's easy to see that we tend to go through those intermediary steps *a lot*:

* at the line level, by repeating short jumps,
* at the block level by jumping to its beginning or end,
* at the screen level by jumping from block to block,
* at the buffer level by jumping from screen to screen,
* and at the project level by jumping to a symbol *via* jumping to its file.

What if we actually "went *there*" directly instead?

At the line, block, and screen levels, incremental search helps tremendously. We have our eyes on `getUserName` and we simply type `/` or `?`, followed by as much of our target as necessary to land the cursor on it.

At the buffer level, commands like `:g/pattern/#` or `:ilist /pattern` help a lot by letting us choose our destination from a list rather than jumping from match to match. There's also `gD` to jump directly to the first instance of the word under the cursor.

At the project level… it gets a little complicated.

Directories, files, paragraphs, lines, words, numbers, signs, etc. The way computers have been designed for the last 40+ years make us think about those things as… *things*. Physical objects with which we interact as if they were *real*. We "cut" them as if they were tomatoes, "navigate" from one to another as if they were harbors, etc.

But how necessary are those metaphors for thinking about our program/data flow? Why should we care about paths, directories, or file names at all? Why do we have to juggle with so many pieces of information when we already have the exact name of what we want to see next, right under our nose/cursor?

## Source code as a hierarchy

Because the file system is usually exposed to us as a hierarchy of (hierarchies of) directories and files, programmers naturally store the symbols and instructions that make their programs into files, themselves stored within directories and subdirectories. Just like our forefathers did with punch cards in file cabinets. Some languages or frameworks may even enforce a "standard" directory structure in the hope of making projects easier to grok, by people and machines alike. There's nothing inherently wrong with any of that, of course: we are just using a convenient metaphor and things are well categorized and organized, right?

But there is a fundamental limitation with that approach: it is completely at odds with how we think when coding, which is .

* Moving stuff around can and do cause undesirable effects across the whole project.

  

* There's only one way to get from point A to point B.
* One thing can't be in two places.
* Two things can have the same name but be in different locations.

* We need to maintain a rather complex map of our source code



## Source code as a network

## Symbols, not files

[//]: # ( Vim: set spell spelllang=en: )
