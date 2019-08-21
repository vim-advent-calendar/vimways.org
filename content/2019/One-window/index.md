---
title: "One window"
publishDate: 2019-12-01
draft: true
description: "Limiting myself to a single window and what I learnt"
author:
  github: "george-b"
  name: "George Brown"
---

> To do two things at once is to do neither
>
> - Publilius Syrus

# Preamble

In an effort to consolidate my focus in Vim I wondered what it would be like if I limited myself to a single window. This notion came about because I knew I wasn't utilizing buffers and things like the quickfix list as effectively could be done. I wanted to break the anti-pattern of "navigating" by moving to a window that had the buffer I wanted loaded. I needed to rewire my thought process and not [die by a thousand files][death-by-a-thousand-files].

## Windows

I would note I've never been keen on the idea of setting up lots of windows with different files in each. Having two windows vertically split would be a far more common case for me, and rarely a third window split wherever.

It's important to remember that no configuration is a substitute for discipline when learning to change. This is simply a journey I went on and sharing what I learnt about Vim along the way.

## Splits I don't like anyway

Vim splits some things by default which I'm not too keen on. As I'm sure everyone is aware, by default `:help` opens up another window that is split horizontally. Given the portrait orientation of most displays I consider lines to be a more precious commodity than columns. Traditionally I've configured Vim to open help in a vertical split.

```vim
augroup Help
  autocmd!
  autocmd FileType help wincmd L
augroup END
```

The quickfix window is another item Vim defaults to opening in a split. Whilst this was something I didn't love I didn't hate it either and just lived with it,
but we'll come to this later.

## A simple config

Preventing Vim or ourselves creating split windows is pretty easy, when we enter a window ensure it is the only one displayed.

```vim
augroup OneWindow
  autocmd!
  autocmd WinEnter * only
augroup END
```

Whilst simple this took me a little while to think of. This method essentially takes a "corrective" approach allowing for split windows and then ensuring the window we are in is the only one displayed.

This is actually the only viable method because as mentioned in the beginning, Vim simply defaults to splitting windows for some things and can't be `set` to do otherwise.

## Splits I do like

Now that being said I do value using Vim as a diff tool so let's make an exception.

```vim
augroup OneWindow
  autocmd!
  autocmd WinEnter * if &diff ==# 'nodiff' | only | endif
augroup END
```

## The quickfix window is special

One thing I noticed is that with the above `autocmd` the quickfix window wasn't displaying correctly. It would become the only window but it would not take up all the available lines. So as always let's make check the `:help` as our first step.

```help
:cope[n] [height]       Open a window to show the current list of errors.

                        When [height] is given, the window becomes that high
                        (if there is room).  When [height] is omitted the
                        window is made ten lines high.
```

Sure enough I was getting a quickfix window only ten lines high. As we cannot define the default value for this via a setting again we need to consider a "corrective" approach.

```vim
augroup OneWindow
  autocmd!
  autocmd WinEnter * if &diff ==# 'nodiff' | only | endif
  autocmd BufReadPost quickfix resize
augroup END
```

Now whilst I was going over height related settings in the help I also came across `winfixheight` which is set for the quickfix window. Sadly I can't recall exactly how I came across this, likely `:helpgrep`. So a slightly more complete snippet would be.

```vim
augroup OneWindow
  autocmd!
  autocmd WinEnter * if &diff ==# 'nodiff' | only | endif
  autocmd BufReadPost quickfix setlocal nowinfixheight | resize
augroup END
```

## Finding a bug

Surprisingly in this adventure I managed to make Vim crash when opening the location list. I [reported this][bug] with a minimal reproducer and it was quickly fixed.

## Living with a single window

Using a single window I've leaned heavily on Vim's alternate file feature. This essentially substitutes my previous usage of two windows. The following two mappings are something I use frequently, though they're just as applicable regardless of how many windows you use.

```vim
nnoremap <BS> <C-^>
nnoremap gb :ls<CR>:buffer<Space>
```

I won't go into other mappings as it's been [well covered][death-by-a-thousand-files].

## Conclusion

Whilst I initially embarked on this method as effectively imposing training wheels on myself I've actually come to quite like a no split workflow in Vim. I don't reach for things like `:vsplit` but I do like having help pages and the quickfix window be my only window when I open them.

---

_License notice_

[death-by-a-thousand-files]: https://vimways.org/2018/death-by-a-thousand-files/
[bug]: https://github.com/vim/vim/issues/3906

[//]: # ( Vim: set spell spelllang=en: )
