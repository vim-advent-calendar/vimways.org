---
title: "Opening Non-Vim File Formats"
publishDate: 2018-12-16
draft: false
description: "How to open images, spreadsheets, and whatever else using vim"
slug: "opening-non-vim-file-formats"
author:
   name: "Conner McDaniel"
   email: "connermcd@gmail.com"
   github: "connermcd"
   picture: "https://en.gravatar.com/userimage/14315884/59ba71fd2c2286907838b5afd0b77bef?size=400"
   twitter: "@connermcd"
   irc: "connermcd"
   homepage: "http://connermcd.github.io/"
---

> The mechanic that would perfect his work must first sharpen his tools.
> - Confucius

Once your vim gills grow in, trying to operate outside of your new command line haven can feel akin to being a fish out of water. Two excellent posts regarding [using vim with splits][1] and [ditching excess file explorers][2] have already demonstrated how easy it is to navigate vim without using external programs or plugins. However, we all encounter filetypes that aren't suitable for editing within vim, such as viewing images, movies, audio, PDF files, and yes, even spreadsheets. Unfortunately we've thus far been unsuccessful in converting all humans to plain text formats and must still suffer the treachery of `.docx` and `.pptx` formats. If you're facing this scenario and have completed your obligatory corner crying, read on. There is hope for editing non-vim file formats right at your finger tips.

## Making use of ftdetect

If you're still attached to a command-line based file explorer like `ranger` or `vifm` then this post is not here to shame you. You can easily type or map `:vert term ranger` and be on your merry way. This option of course has features that aren't supplied by vanilla vim; however, they may not be present on every system you utilize. You also might find yourself wanting to open a file with your standard vim key bindings. Luckily, vim has built-in structures for filetype detection and execution. You can bolster vim's filetype detection with your own customized extensions using the `~/.vim/ftdetect` directory. As specified in `:h ftdetect` simple create a directory in `~/.vim/ftdetect` that corresponds to a nominal filetype. This directory name can be whatever you want it to be. For instance:

    :!mkdir -p ~/.vim/ftdetect/text.vim

Then edit that file and place the following:

    au BufRead,BufNewFile *.txt,*.md,*.mkd,*.markdown,*.mdwn set filetype=text

Now whenever vim reads a buffer or new file with the extensions `*.txt, et al.` it will automatically assign the filetype of `text` to the buffer. Note that the `ftdetect` files are only meant for filetype detection and not for multiple lines of complex commands.

## Carrying out actions on a given filetype

When vim recognizes that a buffer belongs to a particular `filetype` it executes a corresponding `ftplugin` (if one exists). You can view several of these `ftplugin` files within vim's runtime directory.

    :e $VIMRUNTIME/ftplugin/

You can find information for writing your own `ftplugin` files at `:h write-filetype-plugin`, or just read on. As specified in the help file, an `ftplugin` should start with the following:

    if exists("b:did_ftplugin")
      finish
    endif
    let b:did_ftplugin = 1

to prevent the `ftplugin` from running multiple times on the same buffer. You can then specify commands to be executed on the filetype in question when detected. If you find this a bit cumbersome, you're not alone. You can bypass the need for such a guard by instead using the `~/.vim/after/ftplugin` directory, which executes after the default `ftplugin` runs (if there is one).

## Putting it all together

Coming back to our opening statements, how do we make this work for external formats? For starters, make your `ftdetect` file

    :!mkdir -p ~/.vim/ftdetect/video.vim

and edit it with extension detection parameters

    au BufRead,BufNewFile *.avi,*.mp4,*.mkv,*.mov,*.mpg set filetype=video

then create your `ftplugin` file

    :!mkdir -p ~/.vim/after/ftplugin/video.vim

and edit it appropriately:

    sil exe "!mplayer " . shellescape(expand("%:p")) . " &>/dev/null &" | b# | bd# | redraw! | syn on

In this example we're using the PDF reader `mplayer` to open the PDF file, but you could just as easily use any PDF viewer. This silently executes an `!external-program` on the current buffer and places it in the background (`&`), discarding any output or errors to `/dev/null`. The `|`s could easily be separated onto multiple lines and act as a list of sequential commands to switch back to the previous buffer (`b#`), delete the PDF buffer (`bd#`), and then ensure that the screen was not garbled in the process by redrawing and ensuring syntax highlighting is on.

You can simply repeat this process for any other filetypes you'd like to open with vim. For example:

    :!mkdir -p ~/.vim/ftdetect/audio.vim
    au BufRead,BufNewFile *.mp3,*.flac,*.wav,*.ogg set filetype=audio
    :!mkdir -p ~/.vim/after/ftplugin/audio.vim
    sil exe "!mplayer " . shellescape(expand("%:p")) . " &>/dev/null &" | b# | bd# | redraw! | syn on

Here's an example of opening a video with vim:

![MPlayer](opening-other-file-formats/example.gif)\ 

   [1]: /2018/one-vim/
   [2]: /2018/death-by-a-thousand-files/
