---
title: "Latex in Vim"
publishDate: 2019-12-31
draft: true
description: "Writing effective Latex in Vim"
slug: "latex-in-vim"
author:
  name: "Jackson Woodruff"
  github: "j-c-w"
  email: J.C.Woodruff@sms.ed.ac.uk
---

Latex is a text-based description of document structure. Basic
text-formatting is augmented with a number of packages enabling mores
specific behaviour. Latex has become a standard in publishing in many
fields. But it's use is by no means restricted to that. I use Latex for
keeping notes, creating presentations and any other kind of formatting
where plain-text is not quite enough.

Search for Latex editors and you will find a plethora of Latex specific
editors: TexStudio, TexWorks, Lyx and many more. You need look no
further than Vim (which is often omitted for some reason). Latex is a
plain-text format, which automatically makes it well suited for Vim.

I'll discuss plugins (which I highly recommend) later, but it is
perfectly possible to write Latex in vanilla vim.

Latex in Vanilla Vim
====================

You don't really *need* any plugins to write Latex in Vim. Tex
highlighting is included. Spell check is important and should be setup,
but is excellent without any plugins (I have mine enable with an autocmd when I open a Tex file). Vim is perfectly usable for Latex
just like this. There are a couple other built-in features that I think
work well in a setup like this: completion and the `:make` command.

Completion
----------

I regularly find myself using `<C-N>` completion when writing Latex.
Most commands I use, I use more than once per document. `<C-N>`
autocomplete is a good-enough solution to reducing the amount of typing
required because getting the first few characters of a command (or, a
really long word) is enough to make the completion list short and fast
to navigate. Even better, `<C-N>` completion is powerful enough to
handle reference completion. I typically keep my .bib file(s) open in
other buffers. `<C-N>` will search these buffers when it looks for a
completion. Hey presto, there's a working bibliography completion!

Building
--------

Exiting Vim to run `pdflatex` or your favorite compiler isn't very fun
or efficient. Running something like `:!pdflatex %` is a bit better, but
if you can write a simple makefile, Vim can do better. Then you can use
the `:make` which means you can link the compiler output with a quickfix
list. If you aren't going to use a plugin, a simple make file is
probably best. But, while we're on the topic, this is where plugins
start to help.

So, why use plugins?
====================

There are a few obviously missing components. Vim only supports Tex
highlighting out-of-the-box. Auto-complete is good, but not on the level
that TexStudio or TexWorks exist at. Creating a makefile for every small
Latex project is over the top. There are a few rough ends integrating
Vim commands into the Latex ecosystem.

I have used two plugins extensively. The first is [Vim-LaTeX](http://vim-latex.sourceforge.net),
which provides extensive functionality but doesn't quite mesh
into the Vim ecosystem as well as it could. I moved away from it because
of its clunky integration with modern package managers and frustrating auto-expansions.
But, do not get me wrong: Vim-LaTeX is a very good Latex plugin.

I started using [vimtex](https://github.com/lervag/vimtex). vimtex provides the
functionality within Vim-LaTeX which the authors see as vim-like. vimtex
provides Latex-specific text-objects, such as within Latex environments
and delegates much of the Vim-LaTeX functionality to different plugins.

Now, this article is not a comparison of vim-latex plugins. But I will
talk about the features they provide; mostly from the perspective of a
vimtex user.

The first command I learned in both is how to compile. I map this to
`<localleader>ll`. Compiling pops up a quickfix window that can be
navigated to jump to the faulty source line (well, if you trust the
Latex compiler to give you an error on the right line, but that is
another topic). I have this window setup to open and close with
`<localleader>le` (Latex errors). Opening a PDF-viewer to see the results should be
similarly easy. I have this mapped to `<localleader>lv` (Latex view).

Completion (Round II)
---------------------

This deals with the overheads of a makefile for short documents. But vim
packages provide far more than this. The first is sensible
autocompletion. A typical reason I hear for not to switching to Vim for
Latex is "because the autocomplete is not as good." As discussed above,
I usually find that `<C-N>` is plenty for Latex. But I've written enough
Latex that I'm not usually scrounging for commands. vimtex provides an
omni-completion (`<C-X><C-O>`) that can intelligently suggest command
completions.

Fitting Latex within Vim
------------------------

Auto-completion is often a headline feature --- and rightly so. But
Latex plugins provide many other features. `K` links to the Latex
documentation when in a Latex document. The syntax highlighting is
better than the built-in documentation. Navigation commands, such as
`[[` and `]]` to jump between sections or `]m` `[m` to jump between environments.

vimtex introduces a few good commands: `cse` **c**hanges the
**s**urrounding **e**nvironment, for example if you want to change from
an `itemize` to an `enumerate`. In insert mode, `]]` automatically
closes an unclosed environment (i.e. produces the corresponding
`\end{X}` command.

Vim-LaTeX has some good (and some really bad!) auto expansions: typing
`__` produces `_{<cursor is left here>}<++>`, which means you can type the
subscript you want and then press `<C-J>` to jump outside of the
brackets. I liked some of this functionality so much I kept it when I
moved to vimtex. Similarly inspired by latex-suite, I map `mma` (using `iabbrev` to prevent words like "comma" expanding)
in insert mode to produce:

    \begin{align}
        <leave cursor here>
    \end{align}<++>

And have several similar mappings for other environments I regularly
use.  This means I can type `mma<Space>`, enter the text I want, and press `<C-J>` to jump to (and delete) the `<++>` character.

What is my workflow?
====================

Typically, I split the screen vertically in two. One half contains Vim,
and the other half contains a PDF viewer with the document I'm writing.

Vim is an editor that works well with different lines. `j`, `k`, `d`,
you name it, these commands each work on a line-by-line basis. With that
in mind, I highly suggest that you manually break each line (i.e. *not*
using `linebreak`, but manually pressing `<Enter>` at the end of each
line). Why? Because that means all of these commands *actually work
well* and you'll find yourself editing text in a more Vim-like way. If
each paragraph is a single line of text as far as Vim is concerned,
these commands are seriously handicapped.
Beyond this, if you type a paragraph per line and use persistent undo, you will find your persistent undo files becoming *huge*.
Essentially, Vim stores your persistent undo information line-by-line: and it stores the whole line every time. 
If you have lines thousands of characters long, you will find (like I did) that your persistent undo directory
uses all your hard disk space very quickly!

Of course, lots of documents are shared, and in my experience, people tend to prefer using a single line per paragraph,
so you may be stuck.

Plugin Configurations
=====================
I'm not going to go into a huge amount of detail here, just some
personal preferences, focusing on vimtex.  I like to set

	let g:vimtex_fold_enabled = 1

To turn on code folding for Tex files.
Using:

	let g:tex_flavor = 'latex'

Avoids opening an empty .tex file only to have vimtex recognize it as plain Tex rather than Latex.

If you use ALE (or other linting environment supporting Latex),
I suggest you disable it for Latex.  Many of these linting
environments cannot handle 100s of warnings efficiently,
and I find that Latex's warning suites give lots of
false warnings.

Conclusion
==========

If you are looking for a Latex editor, look no further, Vim is what you
are after. There are a million more ways to edit Latex in Vim than what
I've talked about here. I don't have space (nor desire!) to reproduce
the documentation for vimtex or Vim-LaTeX, not to mention the other
Latex packages I haven't tried. This article is certainly not a
substitute for the excellent documentation these packages have.

I have written 100,000 lines of Latex over the last four years using
this setup. I hope this sets you on your way to writing Latex in vim.

