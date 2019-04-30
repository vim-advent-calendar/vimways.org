---
title: "Death by a thousand files"
publishDate: 2018-12-13
draft: false
description: "Free yourself from the tyranny of file explorers"
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

Moving around a buffer or project without aim, mainly in search of something "interesting", is not something easy to optimize as "interesting" is pretty much undefined until you find it. On the other hand, jumping to a specific point of interest is something Vim is very good at and that talent is an important part of its appeal. Unfortunately, normal mode commands take all the sunlight and the popularity of fuzzy finders and alternative file explorers tends to distract new and seasoned vimmers from Vim's most useful navigation features by systematically optimizing the wrong things and reinforcing bad habits.

In this article I will try to show how we can leverage some of Vim's not-so-advanced features to smooth out an essential part of our experience: navigation.

## Nobody move, nobody gets edited

Before examining *how* Vim can facilitate what I call "symbol-based navigation", let's put together a list of motivations for navigating away from the current view. What is the nature of the *next step*?

### The next step involves an *unknown* resource

This is certainly a valid motivation but not one we will be able to optimize much. We are basically left with a single technique: *exploring*, and a single category of boring but reasonably efficient tools: *file explorers*.

Vim happens to ship with a default hierarchical file explorer called [Netrw][doc-netrw] and also provides different levels of [command-line completion][doc-cmdline-completion] to Ex commands like [`:edit`][cmd-edit] or [`:vsplit`][cmd-vsplit] if you like it shell-like.

Those tools may seem rudimentary at first, maybe even clunky, but they can offer a great experience through a wealth of sub-features and sheer customizability. It is my opinion that one should learn how to use and extend that class of basic features before jumping on the plugins bandwagon.

### The next step involves a *known* resource that's not present in, or accessible from, the current view

Since we know at least *something* about that resource we can finally try some optimizations!

**If it's a file**, combining shortcuts (`../`, `%`, `#`), globs (`*`, `**`), and command-line completion ([`'wildmenu'`][opt-wildmenu] anyone?) with the aforementioned `:edit`--and similar commands--goes a long way, especially with rudimentary mappings like:

```vim
set wildcharm=<C-z>
nnoremap ,e :e **/*<C-z><S-Tab>
```
<script id="asciicast-217090" src="https://asciinema.org/a/217090.js" data-size="1.3vw" async></script>

And if that's too limited, there's the versatile [`:find`][cmd-find] that does what `:edit` does but can also be trained to search for files in specific places, thus leveraging whatever naming conventions are enforced by our language/framework/project. This is how it looks, with another simple mapping and a topical `'path'`:

```vim
set path-=/usr/include
nnoremap ,f :find **/*<C-z><S-Tab>
```

<script id="asciicast-217092" src="https://asciinema.org/a/217092.js" data-size="1.3vw" async></script>

Both `:edit` and `:find` depend on *many* options like [`'suffixesadd'`][opt-suffixesadd], [`'wildmode'`][opt-wildmode] or, for `:find` only, the super-powerful `'path'` that we will explore in depth later.

**If it's a symbol**, [tag search][post-tags] might be our best option as it's generic enough to not require much context *and* specific enough to not shower us with completely irrelevant results.

### The next step involves a *known* resource that's present in, or accessible from, the current view

Of the three situations, this is the most common: we are looking at a unit of code, trying to figure out what gets in, what gets out, and if applicable, what it uses from the outside to work with what gets in. This situation is also the most interesting because it will allow us to explore powerful but sadly overlooked features.

From now on, our not-so-crazy assumption will be that everything that is used in this file is either named in this file or in another file directly accessible from this file.

## Started From The Bottom

### Off The Beaten Path

We mentioned [`'path'`][opt-path] in relation with `:find` but that option is honored by (and instrumental in the good working of) many of the features we will see in this section.

The value of that option is a comma-separated list of directories--or globs that can be expanded to directories. If we take a look at the default value on UNIX-like systems:

```vim
:set path?
  .,/usr/include,,
```

we see that, when using a `'path'`-aware command, Vim is going to search for files in:

1. the directory of the current file, `.`,

2. `/usr/include` (Vim has a serious history with C),

3. the working directory, `,,`.

Locations #1 and #3 cover the basics but the real magic is implied by #2: we can add and remove whatever directory we want.

Suppose our project has many internal directories that are of zero interest to us and a few "interesting" directories. We could change `'path'` to a helpful *and highly contextual* value:

```vim
set path=.,dirA,path/to/dirB,path/to/dirB/and/then/dirC
```

and do `:find *foo<Tab>` to find a file with `foo` in its name in the locations above. Even using the otherwise expensive `**` would not be *that* heavy-ended in this case because we are searching through a much smaller set of directories and files than before.

If we do C or C++, the default value could be *extended* (and not replaced) with paths to company-specific headers:

```vim
set path+=path/to/include
```

If we do JavaScript, we could set it up to only look into the directory of the current file and the `front/src/js/` directory:

```vim
set path=.,front/src/js/
```

Setting the *right* `'path'` is key to a smooth and useful navigation, symbol-based or not, but there are many other options that alter the behavior of some or all of the `'path'`-aware commands. We will try to cover them as they come into play.

### Go to File

`gf` is another `'path'`-aware command that lets us jump to the file whose name is under the cursor. It is very useful, even with the default settings, but it will crap out on things that *we* know are filenames but are not really filenames, like:

```javascript
import foo from './path/to/fileNameWithoutExtension';
```

Luckily, we can set `'suffixesadd'` so that Vim mentally adds the right extension before looking up for the file:

```vim
" in after/ftplugin/javascript.vim
setlocal suffixesadd+=.js
```

`gf` has a lesser known sibling, `gF` that does everything `gf` does while also jumping to the given line number, if any:

```javascript
// TODO: investigate why path/to/file:12 was added
```

Here is how `gf` can be used to inspect related files:

<script id="asciicast-217093" src="https://asciinema.org/a/217093.js" data-size="1.3vw" async></script>

### Include file search

#### In theory

The whole ["include file search"][doc-include-search] feature is a collection of commands designed around two options: [`'include'`][opt-include] and [`'define'`][opt-define].

**The first option**, `'include'`, is used to tell Vim how an "include", essentially a link to another resource, looks. That information is then used to follow *each* include found in the current file and every included file, in order to create a tree usable by the many commands related to include file search. The default value is once again a C classic but it can be changed to whatever works for your language/framework/library. Here is a simplistic but working value for EcmaScript 6:

```vim
" in after/ftplugin/javascript.vim
setlocal include=from
```

and here is a more serious value, still for ES6, with triple backslashes and all:

```vim
" in after/ftplugin/javascript.vim
setlocal include=^\\s*[^\/]\\+\\(from\\\|require(['\"]\\)
```

Sometimes, language designers get sloppy and you end up with too many legal syntaxes. Or they get fancy and you end up with a syntax too far removed from the actual directory structure and filenames. In such cases, plain `'include'` may still be used to spot an include but Vim will be incapable of mapping that weird syntax to an actual filename. This is where [`'includeexpr'`][opt-includeexpr] comes handy.

The value of `'includeexpr'` is a function that will be used by Vim every time `gf` and include file search commands find themselves incapable of finding the file. The example found in the documentation shows how the dot notation in:

```java
import org.springframework.context.ApplicationContext;
```

can be transformed into the much more useful:

```text
org/springframework/context/ApplicationContext
```

which, when combined with the suffixes in `'suffixesadd'`, will hopefully point to a proper Java file.

When working with `'include'` and `'includeexpr'` we might want to check how our latest hack works against a real world case. This can be done with [`:checkpath!`][cmd-checkpath].

**The second option**, `'define'`, is used to tell Vim how a macro definition (C again, and the default value is also for C) looks. In language without macros, this option can be (ab)used to describe what a function signature looks like, or a class, or even a constant if that's your speed.

Here is a minimalist example that shows how to convince Vim that a JavaScript function should be considered as a macro:

```vim
" in after/ftplugin/javascript.vim
setlocal define=^\\s*function
```

Now, include file search support is definitely spotty across the built-in ftplugins so we may or may not have to set it all up, an action that may or may not be trivial. FWIW, my custom `'includeexpr'` function for JavaScript is 107 LOC long. Right now, it covers edge cases that presented themselves at work as well as Webpack/VSCode's aliases but it started small and messy, like everything big and beautiful.

#### In practice

Our sandbox will be [the "vanilla-es6" version][site-vanilla] of the infamous [TodoMVC][site-todomvc] project. The project is small and vanilla so we won't have to deal with weird stuff.

If you want to follow at home, put this ultra-minimal configuration in a file:

```vim
" in /tmp/vimrc
set include=from
set incsearch
set ignorecase
set suffixesadd=.js
syntax on  " irrelevant to the topic at hand but nice for the eyes
```

and clone the project:

```bash
$ cd /tmp
$ git clone https://github.com/tastejs/todomvc.git
$ cd todomvc/examples/vanilla-es6
$ vim -Nu /tmp/vimrc src/app.js
```

So, we have opened the entry point of our project and we are treated with this view:

```javascript
import Controller from './controller';
import {$on} from './helpers';
import Template from './template';
import Store from './store';
import View from './view';

const store = new Store('todos-vanilla-es6');

const template = new Template();
const view = new View(template);

/**
 * @type {Controller}
 */
const controller = new Controller(store, view);

const setView = () => controller.setView(document.location.hash);
$on(window, 'load', setView);
$on(window, 'hashchange', setView);
```

Suppose we would like to see how the project's templating works. We could jump to the file containing the `Template` class:

```vim
/Tem<C-g><CR>    " search for 'Tem', move cursor on second match without leaving search mode
gf               " jump to file
```

or we could jump to that class from its first reference:

```vim
/Tem<CR>         " move the cursor on first 'Tem'
[<C-i>           " jump to first match of current word in includes
```

or we could do it even more *directly*:


```vim
:ijump Template  " jump to first match of 'Template' in includes
```

or more lazily:


```vim
:ij /Tem         " jump to first match of pattern 'Tem' in includes
```

*That* is what "symbol-based navigation" is all about: we see a reference to `Template`, we get curious about it, and we jump to its definition. No intermediary step. No filename involved. No waste. *We moved with intent.*

Anyway, we are now greeted with this view:

```javascript
import {ItemList} from './item';

import {escapeForHTML} from './helpers';

export default class Template {
	/**
	 * Format the contents of a todo list.
	 *
	 * @param {ItemList} items Object containing keys you want to find in the template to replace.
	 * @returns {!string} Contents for a todo list
	 *
	 * @example
	 * view.show({
	 *	id: 1,
	 *	title: "Hello World",
	 *	completed: false,
	 * })
	 */
	itemList(items) {
		return items.reduce((a, item) => a + `
<li data-id="${item.id}"${item.completed ? ' class="completed"' : ''}>
	<div class="view">
		<input class="toggle" type="checkbox" ${item.completed ? 'checked' : ''}>
		<label>${escapeForHTML(item.title)}</label>
		<button class="destroy"></button>
	</div>
</li>`, '');
	}

	/**
	 * Format the contents of an "items left" indicator.
	 *
	 * @param {number} activeTodos Number of active todos
	 *
	 * @returns {!string} Contents for an "items left" indicator
	 */
	itemCounter(activeTodos) {
		return `${activeTodos} item${activeTodos !== 1 ? 's' : ''} left`;
	}
}
```

Nice! This is pretty clear and readable but what does that `escapeForHTML()` do, *exactly*? Let's find out:

```vim
:isearch /esca<CR>
  export const escapeForHTML = s => s.replace(/[&<]/g, c => c === '&' ? '&amp;' : '&lt;');
```

or `[i` if we happen to have the cursor on `escapeForHTML`.

There. Another useful and productive action performed without waste. Fast and accurate code navigation without dependencies? Sign me up!

`'define'` commands have the same syntax as their `'include'` counterparts. You just have to replace `i` with `d`:

Include | Define
---|---
`:ijump`   | `:djump`
`:isearch` | `:dsearch`
`:ilist`   | `:dlist`
`[<C-i>`   | `[<C-d>`
`[I`       | `[D`
`]i`       | `]d`

They are different, though, in that `'include'` commands search for *text*, which is not very precise, whereas `'define'` commands search for text matching `'define'` *plus* the argument, which is a hell of a lot more precise. `'include'` commands do the job, here, because the project is small and squeaky-clean but real life projects are typically larger and more messy. That's where a carefully set `'define'` comes handy.

But `'define'` is still the default value so we can't make use of it. Let's change that sorry state of affairs with a minimalist value meant to match classes:

```vim
:set define=class\\s
```

and go back to our starting point:


```vim
:bfirst
```

where we can use regex search:


```vim
:dj /Tem
```

to jump directly to our class definition while saving some typing.

What makes include file search amazing is that it only concerns itself with resources that are accessible from the current context so that *we* don't have to concern ourselves with irrelevant stuff.

There is another command worth knowing, `:ilist` (and its mirror [`:dlist'`][cmd-dlist]), that can be used to list every match of the given text or pattern. This can be useful to get a feel for the structure of a large document, find local references, or find the right symbol in case there are too many potential candidates.


```vim
:dlist /
  /private/tmp/todomvc/examples/vanilla-es6/src/././store.js
    1:    3 export default class Store {
  /private/tmp/todomvc/examples/vanilla-es6/src/./././template.js
    2:    5 export default class Template {
  /private/tmp/todomvc/examples/vanilla-es6/src/././view.js
    3:    9 export default class View {
  /private/tmp/todomvc/examples/vanilla-es6/src/./controller.js
    4:    5 export default class Controller {
  [...]
```

The flip-side of `:[di]list`, though, is one it shares with many similar list-like commands: what to do next is not always obvious and sometimes cumbersome. In this case, the list contains several items from several files so how do we get to the fourth item?

The answer is `:[di]jump 4 /` but it's neither practical nor familiar and, even if it becomes familiar, it will never be practical. `:ilist` and `:dlist` are the ideal candidate for the kind of improvement I like: one that smoothes out rough edges without changing anything fundamental. How about a command-line mode mapping that auto-populates the prompt with the right command, the right second argument, and the cursor at the right place for typing the desired number?

```vim
function! CCR()
    let cmdline = getcmdline()
    if cmdline =~ '\v\C^(dli|il)'
        return "\<CR>:" . cmdline[0] . "j  " . split(cmdline, " ")[1] . "\<S-Left>\<Left>"
    else
        return "\<CR>"
    endif
endfunction
cnoremap <expr> <CR> CCR()
```

If you like the idea, I have described it in detail--and generalized--in [this gist][gist-limits].

<script id="asciicast-217094" src="https://asciinema.org/a/217094.js" loop="loop" data-size="1.3vw" async></script>

## So that's it?

Well yes, that's it.

Simply put, "symbol-based navigation" is the art of jumping to a specific symbol with as few intermediary steps as possible.

Truth be told, the whole concept is neither new nor specific to Vim. In fact, every IDE or programming-oriented editor under the sun does symbol-based navigation in one way or another so… nope, definitely not new or particularly ground-breaking. It's just *one* approach of a common problem. But, in a typical Vim way, an approach that allows us to move as we think, and to think as we move, without the burden that are files and directories. An approach and tools that are *built into the core of our favorite editor*.

---

_This work is licensed under a [Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License][license].
Permissions beyond the scope of this license may be available by
contacting the author._



[cmd-checkpath]: http://vimdoc.sourceforge.net/htmldoc/tagsrch.html#:checkpath
[cmd-dlist]: http://vimdoc.sourceforge.net/htmldoc/tagsrch.html#:dlist
[cmd-edit]: http://vimdoc.sourceforge.net/htmldoc/editing.html#:edit_f
[cmd-find]: http://vimdoc.sourceforge.net/htmldoc/editing.html#:find
[cmd-global]: http://vimdoc.sourceforge.net/htmldoc/repeat.html#:g
[cmd-ilist]: http://vimdoc.sourceforge.net/htmldoc/tagsrch.html#:ilist
[cmd-vsplit]: http://vimdoc.sourceforge.net/htmldoc/windows.html#:vsplit
[doc-cmdline-completion]: http://vimdoc.sourceforge.net/htmldoc/cmdline.html#cmdline-completion
[doc-include-search]: http://vimdoc.sourceforge.net/htmldoc/tagsrch.html#include-search
[doc-netrw]: http://vimdoc.sourceforge.net/htmldoc/pi_netrw.html
[gist-limits]: https://gist.github.com/romainl/047aca21e338df7ccf771f96858edb86
[opt-define]: http://vimdoc.sourceforge.net/htmldoc/options.html#'define'
[opt-include]: http://vimdoc.sourceforge.net/htmldoc/options.html#'include'
[opt-includeexpr]: http://vimdoc.sourceforge.net/htmldoc/options.html#'includeexpr'
[opt-path]: http://vimdoc.sourceforge.net/htmldoc/options.html#'path'
[opt-suffixesadd]: http://vimdoc.sourceforge.net/htmldoc/options.html#'suffixesadd'
[opt-wildmenu]: http://vimdoc.sourceforge.net/htmldoc/options.html#'wildmenu'
[opt-wildmode]: http://vimdoc.sourceforge.net/htmldoc/options.html#'wildmode'
[post-tags]: /2018/you-should-be-using-tags-in-vim/
[site-todomvc]: https://github.com/tastejs/todomvc
[site-vanilla]: https://github.com/tastejs/todomvc/tree/master/examples/vanilla-es6/src
[license]: https://creativecommons.org/licenses/by-nc-sa/4.0/


[//]: # ( Vim: set spell spelllang=en: )
