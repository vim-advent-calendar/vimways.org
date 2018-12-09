---
title: "The Road to Integration"
publishDate: 2018-12-04
draft: true
description: An article on this or that.
---

The Road to Integration
=======================================================================

Topic thesis (WIP, from topics.md):

Dev workflows vary from person to person, although they do share some
common tasks such as kicking off build processes, linting, formatting,
testing, running code, etc. This article will talk about integrating
these tasks into Vim.

Personal notes:

- Re: title: obviously still WIP since I still have to write the whole
  article, but I like how "Road to Integration" implies that instead of
  supplying pre-packaged solutions (which is what IDEs do better), the
  article will instead help the reader build his own tailor-fit
  customizations to match his unique workflow better.
- What to cover -- the major points:
  - Build processes, so `:make` and related settings
  - Linting. Should fall under `:make`, but it might do well to point
    out that the feature can be used for more than just literally `make`
    and other build runners. Might still need new ideas, since there's
    already material out there, e.g. [vimgor's why you don't need
    Syntastic][1]
  - Formatting, so `gq`, `=`, and related settings
  - Running code. Quickly running through an interpreter is fine. Might
    even be able to still take advantage of `:make` for this.
    Interacting with REPLs is trickier. Might merit plugin suggestions
    here since I use one to interact with tmux panes (as well as taking
    advantage of file watchers). I'll also need to do research re: how
    to take advantage of `:terminal` for this.
  - Debugging? I'll need to do a *lot* of research if I include this,
    since I don't debug from within Vim myself. `:terminal` was followed
    closely by a `termdebug` package, so this merits some thought.
  - Completion? Still unsure if this should be included, but I'm
    currently leaning towards "No". Some other topics like LSP and such
    are more suited, and leaving this out conveniently gives me a more
    focused "`:make` and quickfix to the fullest" theme.
  - Search? Same boat as completion above
  - Re: "Jump to definition". I'd definitely leave this one out, since a
    whole article is already being devoted to tags.
- Bonus minor ideas:
  - Fugitive's `:Gmerge`, which I find extra useful after having `git
    merge` result in conflicts, since it loads up the conflicts in the
    quickfix.
  - Client/server feature. A combination of this feature, a short
    script, and some cool tooling bundled with React Native allows me to
    tap on errors in the stack trace on my test device and have the
    relevant file pop up in my current running Vim on my dev machine.
    Definitely bumped down to "minor" status for being very specific in
    its use case, but might make for a great point to discuss,
    especially in an "integrating Vim with the dev environment" article.

[1]: https://gist.github.com/ajh17/a8f5f194079818b99199
