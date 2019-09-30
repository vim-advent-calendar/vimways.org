---
title: "{{ replace .Name "-" " " | title }}"
publishDate: {{ dateFormat "2006" .Date }}-12-01
draft: true
description: "Tweet-sized description of your post"
author:
  email: "username@example.com"
  github: "username"
  gitlab: "username"
  bitbucket: "username"
  sourcehut: "~username"
  homepage: "https://example.com/"
  name: "Firstname Lastname"
  picture: "https://example.com/username.jpg"
  twitter: "@username"
---

> You don't have to open your post with a citation and if you want to, that
> citation can be from anyone, real or imaginary, and be as relevant or
> irrelevant to the subject of your post as you want.
>
> – romainl

## Heading level 2
### Heading level 3
#### Heading level 4
##### Heading level 5
###### Heading level 6

## Front matter

You don't have to provide any personal information under `author` beyond a name.

## Body

We prefer [reference links][vim-site] to [inline links](https://www.vim.org/) but you are free to use any style as long as it works.

To mark *emphasis*, wrap your text with single `*`. Use two `**` to make text **strong**. Alternatively, you can use _single_ `_` and __double__ `__`. Use `` ` `` to wrap inline code like `:set autoindent` and filenames like `after/ftplugin/go.vim`.

Here is an unordered list:

* item
* item
* item

Here is an ordered list:

1. item
2. item
3. item

And here is a silly list of lists:

1. Unordered list:

   * item
   * item
   * item

2. Ordered list:

   1. item
   2. item

3. More lists:

   * ordered:
   
     1. item
     2. item
   
   * unorderd:
   
     * item
     * item
     * item

Here is a table:

Column 1 | Column 2 | Column 3
---|---|---
Foo | `foo` | 1234
Bar | `bar` | 1234

Refer to [this document][md-ref] and [this one][md-ext] if your Markdown-fu is rusty.

## Code blocks

Vim-highlighted code block:

```vim
if !exists('g:env')
    if has('win64') || has('win32') || has('win16')
        let g:env = 'WINDOWS'
    else
        let g:env = toupper(substitute(system('uname'), '\n', '', ''))
    endif
endif
```

Plain code block:

```text
Hello, World!
```

## Embeds

[Asciinema][asciinema] is our preferred way to show moving examples. To embed an asciicast, use this shortcode:

    {{< asciicast 217094 >}}

If you have recorded your own videos, consider uploading them to either [Youtube][youtube] or [Vimeo][vimeo] instead of embedding them directly as they will handle them way better than we could. To embed videos uploaded to those sites, use the shortcodes below:

* Youtube

      {{< youtube icr8rdUM-RM >}}

* Vimeo

      {{< vimeo 17007435 >}}

## Images

* Images are displayed within a 666px-wide column so you should make sure your screenshots and diagrams are readable at that size.

* Avoid unnecessary visual pollution. If you are showing the effect of a custom refactoring macro, for example, your colorscheme, your terminal multiplexer, your fancy statusline, and all your plugins are irrelevant so make sure they don't distract from the subject.

* Be considerate of your readers' bandwidth, optimize your images for use on the web.

This is a remote image:

![Placeholder 666x349][remote-placeholder]

This is a local image:

![Placeholder 666x349][local-placeholder]

---

_License notice_


[vim-site]: https://www.vim.org/
[remote-placeholder]: https://via.placeholder.com/666x349
[local-placeholder]: assets/666x349.jpg
[youtube]: https://youtube.com/
[vimeo]: https://vimeo.com/
[asciinema]: https://asciinema.org/
[md-ref]: https://commonmark.org/
[md-ext]: https://github.com/russross/blackfriday/wiki/Extensions


[//]: # ( Vim: set spell spelllang=en: )
