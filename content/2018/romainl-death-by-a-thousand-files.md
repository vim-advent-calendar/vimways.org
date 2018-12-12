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

Right after we learn Vim's most mundane commands (for writing, quitting, etc.) some of the most immediately useful features are motions: `w` for "beginning of next word", `B` for "beginning of current or previous WORD", etc. and the grammar that allows us to combine them with various operators to form whatever spell we need for the task at hand: `gqip` to "format this paragraph", etc.

Taking `w` as an example; that motion is demonstrated in *every* beginner-level tutorial and typically used dozens of times a day by almost every vimmer but, however useful it might be, it can easily be overused by mashing it until you arrive at or near your destination.

Repeating intermediary jumps with `w` is only marginally better than repeating `
<Right>` or `l`. Sure it *may* take fewer keystrokes but we still go through an undefined number of intermediary steps that are far removed from our actual goal. A goal which, more often than not, is more in the vein of "go there" rather than "go there, there, there, there, and finally *there*".

Zooming out a bit, it's easy to see that we tend to go through those intermediary steps *a lot*:

* at the line level, by repeating short jumps,

* at the block level by jumping to its beginning or end,

* at the screen level by jumping from block to block,

* at the buffer level by jumping from screen to screen,

* and at the project level by jumping to a file to reach a symbol *within* that file.

What if we actually "went *there*" directly instead, in a more deterministic way?

At the line, block, and screen levels, incremental search helps tremendously. We have our eyes on `getUserName` and we simply type `/` or `?`, followed by as much of our target as necessary to land the cursor on it.

At the buffer level, commands like `:g/pattern/#` or `:ilist /pattern` help a lot by letting us choose our destination from a list rather than jumping from match to match. There's also `gD` to jump directly to the first instance of the word under the cursor.

At the project level… it gets a little complicated.

Directories, files, paragraphs, lines, words, numbers, signs, etc. The way computers have been designed for the last 40+ years make us think about those things as… *things*. Physical objects with which we interact as if they were *real*.

But how necessary are those metaphors for thinking about our program/data flow? Why should we care about paths, directories, or file names at all?

## Source code as a hierarchy

Because the file system is usually exposed as a hierarchy of (hierarchies of) directories and files, knowledge workers naturally store their stuff into directories and files. Directories and files are where we, programmers, store the instructions that make our program, just like our forefathers did with punch cards in file cabinets or like ancient librarians did with rolls in Alexandria. Hell, some frameworks even go to great lengths to enforce a "standard" directory structure in the hope of making projects easier to grok, by people and machines alike.

There's nothing inherently wrong with any of that, of course: we are just using a convenient and well understood metaphor. But there are a number of fundamental limitations with that approach when considered from a programmer's point of view.

### There's only one way to get from point A to point B

This is obviously not a problem when A and B are next to each other. But move B away from A, and the task of going from A to B suddenly turns into a hassle because the path to B from A became harder to remember.

Reaching a different node (or leaf, as such hierarchies are often called trees) implies moving up to a common root before moving down again.

### Moving stuff around can and do cause ripple-like undesirable effects across the whole project

Once you have moved B to a new location, every reference to B has to be updated in A, C, R, etc., *with a different path from each node*. Sure you can let your IDE deal with that but who can seriously pretend it *always* works as planned? Automated tools are too greedy or too lazy and humans always fuck up their "quick search & replace".

### Two different things can have the same name but be in different locations

Now, suppose you are currently fiddling with A and you need to take a look at B. You summon your fuzzy finder and type away only to find out that there are a bunch of resources called B. Ideally, figuring out which B is the right one should be quick and easy, but keeping track of all those relationships between resources is taxing and rebuilding a mental index each time you try to access a resource is bound to break the flow.

### We need to maintain a complex map of our source code

To add to that mess, programming projects are rarely limited to just two resources. We have dozens upon dozens of our own "things" and hundreds of third-party dependencies to think about. That means thousands of ever-changing relationships to keep in our head *at all times*. One huge cross-referenced map that must be maintained in real time.

But what to do with that *other* project? And that one? More maps, more
juggling.

## The tree that hides the forest

I intentionally avoided talking about "files" and "directories" in the previous section because the problem—and the maps we maintain to make sense of it—is not restricted to files and directories. In fact, the fundamental "things" we deal with when programming are not files and directories; **we actually deal with the *symbols* that are stored in those files and directories**.

**Those symbols are the meat and bones of our program**, not files. Files and directories are byproducts of the way we *organize* our source code, not our primary matter. I believe those metaphors and the rigid, hierarchical vision that comes with them, are dragging us down and forcing us to look in the wrong place for solutions to largely imaginary problems.

The thing is… most of the programming paradigms, languages, and frameworks we use come with their own hierarchies and metaphors that must be handled on top of the file system. That's even more resources to add to our mental maps *and more indirections* to deal with.

B may be a file but it can be a symbol stored in a file named after B or after something else entirely and we have to keep a map of what symbol is in what file on top of a map of files and directories. Or worse: rebuild that map every time we need to access B! Sadly, we tend to **default to the same base strategy** whether we are looking for a symbol or a file: files and directories. Whatever tool we use, be it a classic file explorer or the fuzzy finder *du jour*, **looking up a *file* in order to access a *symbol* within that file is not efficient**.

It's slow because it's a two-steps process. It's mentally taxing because we must summon that infamous multi-layered map. It's error-prone because that map is rarely complete or even accurate. It's non-deterministic because the effort it takes to access the desired resource *will* vary with the use case and because we always start from a different point on the map anyway.

But the worst aspect of that strategy is that we inevitably try to optimize the wrong things. My strategy is still fundamentally broken but by God that plugin is so *smooth* and *asynchronous* and *blazing fast* that I stopped caring!!

## Moving with intent II

Like with the smaller motions mentioned earlier, Vim offers many ways to move from one symbol to another without unnecessary intermediate jumps.

Before we get to demonstrate the three following techniques with realistic examples, we will have to describe them succinctly, from the most generic to the most specific.

### Text search

Searching for a given pattern in a given directory or set of files is quite possibly the most generic way to find a symbol across a project. It is typically done by populating the quickfix list with `:vimgrep` or `:grep`, and jumping to or operating on the items in the list.

#### `:vimgrep`

`:vimgrep` 

#### `:grep`

#### The quickfix list

#### Tricks

Search, especially the way it is implemented in Vim, is an amazingly useful feature when you are searching for *text* but it is considerably less useful when it comes to *symbols*:

* it can only be used to find *text* in *text* so searching for the definition of *this* function, and not the dozen of other similarly named functions in the project can be involved,

* it doesn't know the difference between a list, a function, and just text in a comment so results tend to be noisy and thus less useful,

* it *can* be optimized for speed, or for honoring your `.gitignore`, or for searching in files with the same extension as the current buffer, or for searching from the current directory by default but, in the end, all of that is just *text* and we are looking for things that are infinitely more specific: *symbols*,

* unless instructed otherwise (with potentially hairy exclusion/inclusion patterns), it will almost always search in irrelevant files and directories.

### Tag search

Searching for tags is *still* searching but instead of searching for arbitrary text across many files, we let an external program update an index of our project—and possibly other places—and we search *in that index*.

This is a considerable improvement over text search because we only get actual symbols found in actual source without having to specify/include/exclude anything.

    :tag
    ^]

Tag search is not a silver bullet, though. 

### Includes

    sddsds

	dsdsdd
	if (sdsdsd) {
		sdksfdsgdf
	}

### Tricks

























> ## Conventions: seeing the forest for the trees

> In focusing too much on the file system we tend to forget that our languages and > frameworks and programming patterns *also* enforce **conventions**. Conventions > that should be leveraged to make our lives easier.

> Some conventions deal with *naming* files, directories, and symbols.

> Other conventions deal with *relationships* between those things.


[//]: # ( Vim: set spell spelllang=en: )
