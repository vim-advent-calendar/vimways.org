---
title: "Formatting lists with Vim"
publishDate: 2018-12-06
date: 2018-12-06
draft: false
description: "Understanding how Vim understands lists"
slug: "formatting-lists-with-vim"
author:
  name: "George Brown"
  email: "321.george@gmail.com"
  github: "george-b"
---

## Use of formatoptions and the fo-table

We tell Vim how formatting should be carried out by setting `'formatoptions'`. This is set to a string of characters whose meaning is described in `:help fo-table`. Rather than repeating what's in the help it's sufficient to say the default is `formatoptions=tcq`, which may lead users to think that invoking Vim's formatting with `gw` from normal mode simply wraps text at whatever `'textwidth'` is set to. But we can actually do a lot more.

The focus of this article is how we can alter the formatting behaviour when we have the `n` value present in `'formatoptions'`. This allows formatting operations to recognize lists, thereby avoiding joining distinct items as if they were a single paragraph.

## Understanding formatlistpat

Succinctly described in the documentation.

```text
The default recognizes a number, followed by an optional punctuation
character and white space.
```

This translates as the regex string of `^\s*\d\+[\]:.)}\t ]\s*`.

Atom | Description
---|---
`^`         | From the start of line
`\s*`       | Zero or more whitespace characters
`\d\+`      | One or more digits
`[`         | Start a class
`\]:.)}\t`  | A closing bracket, colon, full stop, closing parenthesis, closing curly brace, tab, or space
`]`         | End a class
`\s*`       | Zero or more whitespace characters

Here is an example of a list that can be formatted when passing over it when executing `gwip`.

```text
1. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
2. Donec feugiat a quam id faucibus.
3. Sed maximus efficitur commodo.
4. Sed et euismod ex.
5. Sed at libero placerat, pretium sem sit amet, mattis dolor.
```

However something like the following won't be recognized.

```text
a. Lorem ipsum dolor sit amet, consectetur adipiscing elit.
b. Donec feugiat a quam id faucibus.
c. Sed maximus efficitur commodo.
d. Sed et euismod ex.
e. Sed at libero placerat, pretium sem sit amet, mattis dolor.
```

## Expanding formatlistpat

An item of particular importance when setting `'formatlistpat'`, though not exclusively so, is that we will need to enter more backslashes than you may expect. This is because when setting string options in Vim backslashes need to be escaped (covered in `:help option-backslash`). As an example let's see how we would set `formatlistpat` to its default value of `^\s*\d\+[\]:.)}\t ]\s*`.

```vim
set formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
```

Now to use the example of the alphabetical listing used earlier how may we change `'formatlistpat'` to recognise this as a list? Changing the matching of a digit to a group matching a digit or an alphabetic character seems like a simple solution. We could so so with the following (note the three backslashes that precede the pipe).

```vim
set formatlistpat=^\\s*\\(\\d\\\|\\a\\)\\+[\\]:.)}\\t\ ]\\s*
```

However this will end up matching too many structures of text. The punctuation after digits or alphabetic characters also includes a space. So this will match prose-like paragraphs. We could remove the space in the class like so to avoid this like so.

```vim
set formatlistpat=^\\s*\\(\\d\\\|\\a\\)\\+[\\]:.)}\\t\]\\s*
```

Though as one may expect by removing something from the default setting we've broken the matching of lists that are prefixed by numbers alone. Rather than continuing example by example I'll stop here, an example of what I consider to be comprehensive for my personal needs will follow in the final section.

## Some filetypes will set formatlistpat

It is interesting to note that Vim will set `'formatlistpat'` for some filetypes. At the time of writing this consists of the following:

```vim
runtime/ftplugin/rmd.vim:      setlocal formatlistpat=^\\s*\\d\\+\\.\\s\\+\\\|^\\s*[-*+]\\s\\+
runtime/ftplugin/rrst.vim:     setlocal formatlistpat=^\\s*\\d\\+\\.\\s\\+\\\|^\\s*[-*+]\\s\\+
runtime/ftplugin/markdown.vim: setlocal formatlistpat=^\\s*\\d\\+\\.\\s\\+\\\|^[-*+]\\s\\+\\\|^\\[^\\ze[^\\]]\\+\\]:
```

This is just something to bear in mind if you find `'formatlistpat'` set to something unexpected or if you had been wondering how formatting of lists in your markdown files had "just worked" for example.

# Other settings that can interfere with formatlistpat

Vim has a notion of comments which can lead to formatting not working as you may expect. For example if we were to open a file named `list.txt` with the following content.

```text
* Lorem ipsum dolor sit amet, consectetur adipiscing elit.
* Donec feugiat a quam id faucibus.
* Sed maximus efficitur commodo.
* Sed et euismod ex.
* Sed at libero placerat, pretium sem sit amet, mattis dolor.
```

Executing `gwip` does *not* join the lines. As we have already covered the default value for `'formatlistpat'` expects list items to at least be denoted with a digit, so what's happening here? From the previous section about filetypes it wouldn't seem that `'formatlistpat'` is being modified for this example. We can check this and see that sure enough it's the default value.

```vim
:set formatlistpat?
  formatlistpat=^\s*\d\+[\]:.)}\t ]\s*
```

So why do we have this behaviour? Is Vim recognising this as a list by some other means? Yes, sort of. Vim's understanding of a comment also extends to lists and is not defined by `'formatlistpat'`. Specifically in this example of a file with the "text" `'filetype'` we have the following.

```vim
:verbose set comments?
  comments=fb:-,fb:*
        Last set from /usr/local/Cellar/vim/8.1.0450/share/vim/vim81/ftplugin/text.vim line 16
```

The various setting for `'comments'` is of course covered in Vim's help (see `:help format-comments`) but let's breakdown the value above:

Part | Description
---|---
`f`  | Flag denoting only the first line has this string
`b`  | Flag denoting whitespace is required after the string
`:`  | Delimiter denoting the end of flags
`-`  | The string literal `-`
`,`  | Delimiter denoting ending of a setting
`f`  | Flag denoting only the first line has this string
`b`  | Flag denoting whitespace is required after the string
`:`  | Delimiter denoting the end of flags
`*`  | String literal `*`

The usage of the `f` flag may seem slightly confusing given the prior example. But becomes clearer if we try and format a line that exceeds `'textwidth'`, here we are again in a buffer with the `'filetype'` of "text".

```text
* Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec feugiat a quam id faucibus.
```

Executing `gwip` will yield the following.

```text
* Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec feugiat a quam
  id faucibus.
```

Here we see the second line is not prefixed with an asterisk, this action is in line with the description of the `f` flag in `'comments'`. So, going back to our earlier example, Vim is not re-flowing the paragraph as it treats each line as an individual list item under the notion of being a "comment".

## My personal customizations for notes

I often open Vim to write up emails and replies for ticketing systems. In such instances Vim has no `'filetype'` set. As such in order to associate various setting with such a buffer I give it a pseudo filetype.

```vim
function! EmptyBuffer()
  if @% == ""
    setfiletype txt
  endif
endfunction
```

I simply call the function above upon entering Vim with an autocommand.

```vim
autocmd vimrc BufEnter * call EmptyBuffer()
```

I also set this pseudo filetype for any "blank" buffers I pull up, here the autocommand is making use of `:setfiletype` to only set the filetype if it has not otherwise been set.

```vim
autocmd vimrc BufRead,BufNewFile * setfiletype txt
```

I then have a function which I call when the pseudo filetype of "txt" has been set, the below is a truncated version as to only illustrate formatting settings.

```vim
function! PlainText()
  setlocal comments=
endfunction

autocmd vimrc FileType txt call PlainText()
```

Why am I setting `'comments'` to an empty value? Well as described in the help it assumes, like many other things in Vim, that you are working with something resembling C code. As such this can cause issues if we match lists that use asterisks in `'formatlistpat'`.

As a note for the more savvy reader, you may be thinking why not make this "pseudo filetype" a fully fledged filetype with its own files somewhere in my `'runtimepath'`, with its own "after" directory for this? This is simply a personal preference, I prefer a more monolithic organization of my config.

And finally my `'formatlistpat'`.

```vim
set formatlistpat=^\\s*                     " Optional leading whitespace
set formatlistpat+=[                        " Start class
set formatlistpat+=\\[({]\\?                " |  Optionally match opening punctuation
set formatlistpat+=\\(                      " |  Start group
set formatlistpat+=[0-9]\\+                 " |  |  Numbers
set formatlistpat+=\\\|                     " |  |  or
set formatlistpat+=[a-zA-Z]\\+              " |  |  Letters
set formatlistpat+=\\)                      " |  End group
set formatlistpat+=[\\]:.)}                 " |  Closing punctuation
set formatlistpat+=]                        " End class
set formatlistpat+=\\s\\+                   " One or more spaces
set formatlistpat+=\\\|                     " or
set formatlistpat+=^\\s*[-–+o*•]\\s\\+      " Bullet points
```

This handles a broader range of lists.

```text
1.  Typical item the default handles
a.  An item with an alphabetic character and punctuation
(2) An item with punctuation preceding and following it
•   An item consisting of leading punctuation
```

I hope this has shown how to extend Vim's `'formatlistpat'` and how other settings interplay with it.
