---
title: "Don't use Vim"
publishDate: 2018-12-18
draft: true
description: "Don't use Vim for the wrong reasons"
slug: "dont-use-vim"
author:
  name: "Romain Lafourcade"
  github: "romainl"
---


> Don't do the crime, if you can't do the time.
>
> -- Anthony Vincenzo "Tony" Baretta


Vim is an amazing text editor. I love it. Really, I wouldn't [organize][organize] a Vim advent calendar if I didn't. But, as amazing as it is, **Vim is not for everyone**. It can't solve all your problems, or be a TUI version of your favorite IDE, or make you a better programmer, or land you that dream job in the Bay Area, but Vim *can* help you be more mindful, focused, and efficient, as long as you approach it with the right mindset.

Don't get me wrong, I certainly welcome you to try Vim, but I'm not a proselyte. I don't strive on newbies. I just want *you* to use the right tool for the job and not waste *your*--and anyone's--time on a fruitless quest.

## Don't use Vim…

### if you think you can get the features of your IDE without the weight and the sluggishness

While some recent advancements may hint at future changes in that direction, Vim currently lacks everything it would need to be considered/used as an IDE. From sketchy terminal integration, to being single-threaded, via the lack of anything resembling a proper internal plugin API, nothing in Vim can be leveraged to give you a convincing **Integrated** Development **Environment**.

From the user's point of view, an IDE is mostly a smart text editor with a bunch of utility windows tacked on. After all, the editor is the largest window, right? If that's all you see in your IDE then I guess you can be excused for believing all those "Vim as a $LANGUAGE IDE" posts from years ago.

Sadly, that's not how an IDE works *at all*. How it works, and the way it is architectured, can't currently be replicated in Vim. The best you can get is something that looks like your IDE--an editor window with tacked-on utility windows--if you squint hard enough, but you won't get a true IDE.

Additionally, IDEs are not bloated and sluggish and hungry for RAM and disc space because their developers are sloppy or whatever. They eat resources and threads because they do *a lot*. Strip away everything that makes them IDEs and you get a lightweight editor. Add random incompatible IDE features to a lightweight editor that's not at all designed for that and you get a resource-hungry monster.

If you need IDE features, use an IDE.

### if you want an experience entirely focused on your technology stack

Vim has quite the history with C but, other than that, it's not particularly suited for anything specific like Front-end development, or Scala, or statistics, or functional programming, etc. It's a fine plain text editor that comes with minimal support hundreds of languages out-of-the-box and can be extended with many plugins of varying quality if the built-in features and your own customizations don't cut it. But don't pay attention to claims that "Vim is the perfect $LANGUAGE IDE": they are usually followed by long lists of plugins that never work well together and often replicate built-in features the people behind those claims don't even knew about.

You can develop large C++ applications, work on React apps, build Go microservices, or write your CS thesis with Vim, and even have fun doing it, but thinking about Vim as a specialized C++/React/Go/LaTEX editor would be counterproductive.

### if you think it's everywhere

Vim *can* be compiled for almost every platform/OS/hardware combination but it *is not* everywhere; hell, it's not on Windows, for starter, and Windows is the most widely used OS.

Vim is a vi clone and the whole justification for shipping your UNIX-like OS with a vi clone is that you want to ensure *partial* [POSIX][posix] compatibility. Most Linux distributions use Vim for that while a few have been using vi since its legal status has been cleared. On BSD you generally get Nvi. On minimalist distributions used for embedded devices or containers you get [BusyBox vi][busybox-vi]…

Also, your new favorite editor can be compiled with different features, sometimes--but not exclusively--grouped in meta features called "Tiny", "Small", "Normal", "Big", and "Huge", and the Vim you get by default, if any, is rarely the full-fledged version you would expect. Clipboard support, for example, is a pretty basic feature that is never built-in in default Vim and doesn't exist anyway in vi or Nvi.

What's (not) "everywhere" is slightly different interpretations of [the standardized feature-set of vi][the-standardized-feature-set-of-vi], and vi is far from having all the bells and whistles that attracted to Vim in the first place.

### if you need to get up to speed in an afternoon

The learning curve is *real* and the productivity hit of learning Vim on the spot is even realer. It will take days to internalize the most basic stuff taught to you in `$ vimtutor` and it will take weeks or months to reach your previous productivity level. If you are serious about learning Vim, I recommend doing it on the side, progressively, without taking any of the shortcuts you would be tempted to take if you had to learn it on the spot.

If you are in a hurry, use a familiar editor/IDE.

### if you only care about street credibility

If you are here because of fancy screenshots and the desire to look cool and belong to what you *believe* is an elite community then go away. That's a shallow attitude and the amount of time and effort required to even become a passable vimmer is guaranteed to turn you off sooner or later. Vim is only *one* tool among *many* for editing text and **no one** cares about it beyond our little coterie. And even then, most of us treat Vim as a power tool, not as a badge.

![Urinal etiquette][urinal-etiquette]

Your next recruiter, your next colleagues, your next crush won't care about Vim. Vim is not cool and you are not cool for using Vim.

### if you can't afford the time and effort it requires to learn it

It will take time to feel comfortable and it will take more time to feel comfortable enough that you don't think about reaching to your previous editor. We are talking months before you can work at least as efficiently as before. Can you afford that? Are you OK with the idea of reading the fucking manual? Or are you on a hurry to show off your eliteness to your coworkers and you don't have time to waste on boring reading?

Vim is a very powerful text editor that exposes an incredible breadth and depth of functionalities. Learning everything would take a lifetime and learning what you need *right now* takes months. If you lack the curiosity and the drive required to go past those months, then you should keep using your current text editor.

In general: if you are used to $FOO and consider switching to $BAR, learn $BAR before actually switching to it.

### if you are not ready to change your habits and workflow

Vim is different. It has modes, it has commands all over the keyboard, it has tabs that are not tabs, it has different shortcuts than what you are used to, it lacks basic features and comes with incredibly useful ones no one knows about, it's a TUI, it's incredibly dumb and incredibly smart at the same time, it puts you in the driver seat, it uses its own weird language for extension, it's old and buggy, etc.

The features you are used to may or may not be built-in or they may or may not require a plugin--or three. The way you are used to handle files may or may not match with Vim's built-in file navigation features. In any case, forcing your usual features and behaviors into Vim is an exercise in futility. You will get more value from learning it properly and leveraging its built-in features than from replicating your previous workflow.

An example of thing you might want to adjust to rather than fight against would be "tabs": Vim's tabs, called [tab pages][tab-pages], don't work like other editor's tabs *at all*, so your usual tab-centric workflow *must*, at the very least, be changed to a buffer-centric one.

Besides, if you don't want to change your habits, why change editors in the first place?

### if the job can be done better with another tool

`sed`, `awk`, `cut`, a quick bash one-liner, a simpler editor, an infinitely more powerful IDE, an actual IRC or mail client, an actual presentation program, some online CSV-to-JSON converter... specialized tools are very often better alternatives to Vim. Even pen and paper (or marker on whiteboard) can be better for many uses.

Yes, you have reached the *"Vim everywhere for everything"* but that's just a phase and you will get out of it, eventually.

## How to approach Vim

### Be open minded

What's different between Vim and other editors is why you are here so you should keep that open mind throughout your learning. Some of what Vim does *will* feel weird at first but, if you cultivate the right mindset, everything will eventually fall into place.

### Be patient and mindful

There's a lot to learn but there's no point whatsoever in learning *everything*… and there's no way to do that in a single-seating anyway. In fact people use Vim for 15 years and still learn new tricks regularly, when a new need arise or when they feel something they are doing could be improved. On that note, this advice from Bram Moolenaar's seminal ["Seven habits of effective text editing"][seven-habits-of-effective-text-editing] is absolute gold:

> There are three basic steps:
>
> 1. While you are editing, keep an eye out for actions you repeat and/or spend quite a bit of time on.
>
> 2. Find out if there is an editor command that will do this action quicker. Read the documentation, ask a friend, or look at how others do this.
>
> 3. Train using the command. Do this until your fingers type it without thinking.

### Read and experiment

Here are the three most important written resources to be aware of:

1. `$ vimtutor` is an interactive tutorial that teaches you the most basic concept. New users are expected to go through it as many times as necessary to internalize it as it covers everything a casual user should know.

2. The user manual is exactly what its name implies: a mandatory reading for every vimmer that touches on every feature present in your editor. Just read it if you don't like poking in the dark. Well, read it even if you do.

3. The reference manual contains everything about everything. Using it is easy and explained in the first scene of `:help`. Whatever question you might have on Vim has its answer here so… always ask Vim first.

### Ask

And when the answer you got from Vim is puzzling or when you have tried something based on what you found in the manual doesn't work as expected, you can ask fellow users for help:

* on [Reddit][reddit],

* on [Stack Overflow][stack-overflow],

* on [the vi and Vim stack exchange][the-vi-and-vim-stack-exchange],

* on [#vim][#vim] on [Freenode][freenode].

In any case, be sure to prepare a minimum test case and explain what you are trying to do in order to avoid [the XY problem][the-xy-problem].

## Parting words

Vim is a complex program that lives in a bubble of its own. Its, shall we say, many peculiarities make it impossible to pick it up like one would pick Atom or Sublime Text up. Unlike those editors, Vim requires serious learning and unlearning before even being able to perform the slightest edit. Yes, it will take months before you use it more or less correctly and it will take decades to master it. Will it be worth it? I can't tell. It certainly has been worth it for me and many others while many more gave up or switched to other editors.

Learning Vim, or any other powerful program like Photoshop or Blender, requires a patience and a discipline that not everyone can afford and that's OK because not everyone has to learn those things. *If you don't have the required discipline you won't reap the expected benefits.*

---

_This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License][license].  Permissions beyond the scope of this license may be available by contacting the author._


[license]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[organize]: ../romainl-dont-use-vim/organize.jpg
[your-development-environment]: https://sanctum.geek.nz/arabesque/series/unix-as-ide/
[urinal-etiquette]: ../romainl-dont-use-vim/urinal-etiquette.jpg
[posix]: https://pubs.opengroup.org/onlinepubs/9699919799/
[busybox-vi]: https://git.busybox.net/busybox/tree/editors/vi.c?h=1_29_stable
[the-standardized-feature-set-of-vi]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/vi.html
[tab-pages]: http://vimdoc.sourceforge.net/htmldoc/tabpage.html#tab-page
[seven-habits-of-effective-text-editing]: https://moolenaar.net/habits.html
[#vim]: https://www.vi-improved.org/faq/
[freenode]: https://freenode.net/kb/answer/registration
[reddit]: https://www.reddit.com/r/vim/
[stack-overflow]: https://stackoverflow.com/questions/tagged/vim
[the-vi-and-vim-stack-exchange]: https://vi.stackexchange.com/
[the-xy-problem]: https://en.wikipedia.org/wiki/XY_problem


[//]: # ( Vim: set spell spelllang=en: )
