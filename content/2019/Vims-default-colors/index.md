---
title: "Vim's default colors"
publishDate: 2019-12-29
draft: false
description: "The ins and outs of how Vim sets colors"
author:
  github: "george-b"
  name: "George Brown"
---

> Either the well was very deep, or she fell very slowly, for she had plenty of
> time as she went down to look about her and to wonder what was going to happen
> next.
>
> - Lewis Carol, Alice's Adventures in Wonderland

## Colorschemes

One day I thought I'd set about creating a minimal colorscheme for Vim. The idea of having minimal highlighting to force a fuller reading and comprehension of code intrigued me and I wanted to try it for myself. Plus, working with a minimal set of highlights ought to make this a simple endeavour, or so I thought. And lo I found myself in another one of Vim's idiosyncratic rabbit holes, something I seem to have an unfortunate knack for.

To be very clear this is not an article about recommending minimal colorschemes or how to write colorschemes. This is simply a journey I went on and sharing what I learnt about Vim along the way.

## Vim's default colors

The first thing to know is that when creating a colorscheme you never actually start from a clean slate. Even if I weren't creating a minimal colorscheme I'd still find this annoying. One would think if we're telling Vim what colors to use we wouldn't have to override things.

Anyway let's take a look at that default colorscheme, it'll be in `colors/default.vim` in our `runtimepath` right? Let's open it up with `vim -c 'edit $VIMRUNTIME/colors/default.vim'`:

``` vim
" Vim color file
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last Change:	2001 Jul 23

" This is the default color scheme.  It doesn't define the Normal
" highlighting, it uses whatever the colors used to be.

" Set 'background' back to the default.  The value can't always be estimated
" and is then guessed.
hi clear Normal
set bg&

" Remove all existing highlighting and set the defaults.
hi clear

" Load the syntax highlighting defaults, if it's enabled.
if exists("syntax_on")
  syntax reset
endif

let colors_name = "default"

" vim: sw=2
```

Erm... Where are the highlight groups? Let's try to dig a little deeper: `:verbose highlight` reveals `syntax/syncolor.vim` in `$VIMRUNTIME` is the source of *some* of the default colors. Said file contains a rather succinct comment:

```vim
" This file sets up the default methods for highlighting.
" It is loaded from "synload.vim" and from Vim for ":syntax reset".
" Also used from init_highlight().
```

So what about the others? The fact that even with `:verbose` we don't get a file from the runtime is somewhat telling. Well it turns out these are [hardcoded into Vim itself][hardcoded].

So it is perhaps more accurate to say Vim "sets default colors" rather than "has a default colorscheme". At the very least the default colorscheme is not equal to other colorschemes.

## Clearing highlights

So let's just say we want to clear everything to get that blank slate to start from. We consult the `:help` to find out how we may achieve this.

```vim
:hi[ghlight] clear	Reset all highlighting to the defaults.  Removes all
			highlighting for groups added by the user!
			Uses the current value of 'background' to decide which
			default colors to use.

:hi[ghlight] clear {group-name}
:hi[ghlight] {group-name} NONE
			Disable the highlighting for one highlight group.  It
			is _not_ set back to the default colors.
```

So `:highlight clear` "clears" things in the sense of reverting to its default colors. It seems we would want `:highlight NONE`, but that `{group-name}` isn't optional. There's no way to unset all highlight groups with a single command.

Crap.

## Let's get structured

So I touched on the fact that I find overriding a set of highlight groups ugly but it seems we're going to have to anyway. We could do something like the following for a list of highlight groups:

```vim
highlight SpecialKey NONE
...
```

But that's still very arbitrary and doesn't work well if things change (more on that later). A more robust approach would be to probe Vim for highlight groups and operate on what is returned meaning we can avoid assumed knowledge.

A list of highlight groups would be sufficient for my desire to clear things. But I wanted to have a full representation of all the highlights in a single data structure. This allows for working with highlights in a far more functional manner.

As a quick recap the output of `:highlight` returns output like the following:

```vim
SpecialKey     xxx term=bold ctermfg=4 guifg=Blue
```

So we first have have the group name `SpecialKey`, then `xxx` which is highlighted as syntax matching that group would be, and then a list of key value pairs denoting the appearance in terms of colors and attributes.

Groups may also link to other groups.

```vim
EndOfBuffer    xxx links to NonText
```

We can represent the output of `:highlight` as a nested dictionary.

* At the top level we have a dictionary of "highlights" whose keys are the various highlight groups
* Each highlight group contains a dictionaries of attributes and their values

A pseudo example.

```vim
highlights {
              'SpecialKey' : {
                               'term'    : 'bold',
                               'ctermfg' : '4',
                               'guifg'   : 'Blue',
              },
              'EndOfBuffer' : {
                                'links' : 'NoneText'
              },
              ...
```

The final level of having attributes and their values may seem suitable for a list but the having this as a dictionary means we can do things like look up the `ctermfg` value of the `SpecialKey` group directly for example. Also attributes are not necessarily limited to a single value, `term` for instance may specify `bold` *and* `underlined`.

I won't go into the code or parsing this here but you can find it
[here][GetColors].

## The dumbest thing I've ever seen Vim do

This is a slight tangent in that I'm writing up this journey chronologically as I traveled it. This however is not something I found until others pointed it out to me.

In my parsing of the output of `:highlight` I had made the assumption of there being one highlight group per line. Now if the window is not wide enough to fit this on one line Vim will hard wrap this onto another line. However this happens **even if the output is not interactive!** By which I mean captured in a `redir` or `execute()`. I find this deeply perverse. Why alter the output to be more visually accommodating when it's not actually outputted to a human?

It's all the more flabbergasting when one has been accustomed to tooling with intuitive output. Take for example the humble `ls`, its output can vary depending on the size of the terminal window. However if we were to pipe its output it would actually contain one entry per line. This is because it knows when its output is a terminal, when it's not you're probably scripting something and one entry per line is easy and consistent to deal with.

I found this out late in the evening and initially had trouble fixing this. That [issue][issue] turned out to be my own error likely due to tiredness and frustration and was [fixed][fixed] the next day.

Anyway that's my rant within a rant, back to the topic at hand.

## Redefining the situation

So whilst Vim has various colors set by default, clearing those doesn't actually ensure you have a clean slate. Why? Because syntax files can set colors. One may think they would only set links but that is not the case.

```sh
grep -RE 'hi |highlgiht ' /usr/local/share/vim/vim81/syntax/ | grep -cv link
315
```

So let's redefine how we are going to achieve a clean slate. Rather than just clearing things at start up we want to clear any colors Vim sets *implicitly*. This is where having parsed the output of `:highlight` fully is going to pay off. If we define what we want our colorscheme to be in terms of a dictionary like the one we've generated from parsing the output of `:highlight`, we can compare the two to find out if they are different. If they are different simply clear whatever has been set and then set the colors that we defined.

Again I'm not going to go into the implementation but you can find it [here][ClearUndefinedColors].

## Conclusion

* Vim's default colors are not set in the same way as other colorschemes
* Syntax files may set their own colors
* Asserting total control over colors in Vim requires scripting

---

_License notice_

[hardcoded]: https://github.com/vim/vim/blob/c799fe206e61f2e2c1231bc46cbe4bb354f3da69/src/syntax.c#L6815-L7150
[GetColors]: https://github.com/george-b/zenchrome/blob/1.0/autoload/zenchrome.vim#L1-L24
[issue]: https://github.com/george-b/zenchrome/issues/1
[fixed]: https://github.com/george-b/zenchrome/commit/a0ab9b9a64dfec4cae46a0f1b2cd5669994fd3df
[ClearUndefinedColors]: https://github.com/george-b/zenchrome/blob/1.0/autoload/zenchrome.vim#L37-L43

[//]: # ( Vim: set spell spelllang=en: )
