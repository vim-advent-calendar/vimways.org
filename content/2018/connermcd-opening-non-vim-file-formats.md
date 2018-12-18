---
title: "Opening Non-Vim File Formats"
publishDate: 2018-12-14
draft: true
description: "How to open images, spreadsheets, and whatever else using Vim"
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
>
> -- Confucius

Once your Vim gills grow in, trying to operate outside of your new command line haven can feel akin to being a fish out of water. Two excellent posts regarding [using Vim with splits][1] and [ditching excess file explorers][2] have already demonstrated how easy it is to navigate Vim without using external programs or plugins. However, we all encounter filetypes that aren't suitable for editing within Vim, such as viewing images, movies, audio, PDF files, and yes, even spreadsheets. Unfortunately we've thus far been unsuccessful in converting all humans to plain text formats and must still suffer the treachery of `.docx` and `.pptx` formats. If you're facing this scenario and have completed your obligatory corner crying, read on. There is hope for editing non-Vim file formats right at your finger tips.

## Making use of ftdetect

If you're still attached to a command-line based file explorer like [`ranger`][program-ranger] or [`vifm`][program-vifm] then this post is not here to shame you. You can easily type or map `:vert term ranger` and be on your merry way. This option of course depends on features that may not be available in your version of Vim or tools that may not be present on every system you utilize. You also might find yourself wanting to open a file with your standard Vim key bindings. Luckily, Vim has a built-in structure for filetype detection and execution. You can bolster Vim's filetype detection with your own customized extensions using the `~/.vim/ftdetect` directory. As specified in [`:help 'ftdetect'`][help-ftdetect], you simply have to create a file `~/.vim/ftdetect` that corresponds to a nominal filetype. This name of this file can be whatever you want (e.g. text). For instance:

```vim
:!mkdir -p ~/.vim/ftdetect/text.vim
```

Then edit that file and place the following:

```vim
autocommand BufRead,BufNewFile *.txt,*.md,*.mkd,*.markdown,*.mdwn set filetype=text
```

Now whenever Vim reads a buffer or new file with the extensions `*.txt, et al.` it will automatically assign the filetype of `text` to the buffer. Note that the `ftdetect` files are only meant for filetype detection and not for multiple lines of complex commands.

## Carrying out actions on a given filetype

When Vim recognizes that a buffer belongs to a particular `filetype` it executes a corresponding `ftplugin` (if one exists). You can [`:view`][cmd-view] several of these `ftplugin` files within Vim's runtime directory:

```vim
:view $VIMRUNTIME/ftplugin/
```

You can find information for writing your own `ftplugin` files at [`:help write-filetype-plugin`][help-write-filetype-plugin], or just read on. As specified in the help file, an `ftplugin` should start with the following:

```vim
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1
```

to prevent the `ftplugin` from running multiple times on the same buffer. You can then specify commands to be executed on the filetype in question when detected. If you find this a bit cumbersome, you're not alone. You can bypass the need for such a guard by instead using the `~/.vim/after/ftplugin` directory, which executes after the default `ftplugin` runs (if there is one).

## Putting it all together

Coming back to our opening statements, how do we make this work for external formats? For starters, make your `ftdetect` file:

```vim
:!mkdir -p ~/.vim/ftdetect/video.vim
```

and edit it with extension detection parameters:

```vim
au BufRead,BufNewFile *.avi,*.mp4,*.mkv,*.mov,*.mpg set filetype=video
```

then create your `ftplugin` file:

```vim
:!mkdir -p ~/.vim/after/ftplugin/video.vim
```

and edit it appropriately:

```vim
silent execute "!mplayer " . shellescape(expand("%:p")) . " &>/dev/null &" | buffer# | bdelete# | redraw! | syntax on
```

In this example we're using `mplayer` to open the video file, but you could just as easily use any other video player. This silently executes an `!external-program` on the current buffer and places it in the background (`&`), discarding any output or errors to `/dev/null`. The `|`s could easily be separated onto multiple lines and act as a list of sequential commands to switch back to the previous buffer (`buffer#`), delete the buffer containing the binary file (`bdelete#`), and then ensure that the screen was not garbled in the process by redrawing and ensuring syntax highlighting is on.

You could also consider using a [`system()`][func-system] call with [`xdg-open`][program-xdg-open], [`open`][program-open], or [`explorer`][program-explorer], depending on what is available on your system. The previous example is not fully cross-platform, but with a few tweaks you can make this work on any system. For instance, consider this function:

```vim
" What command to use
function! s:Cmd() abort
    " Linux/BSD
    if executable("xdg-open")
        return "xdg-open"
    endif
    " MacOS
    if executable("open")
        return "open"
    endif
    " Windows
    return "explorer"
endfunction
```

You could then use this function in conjunction with a `system()` call to make cross-platform a reality.

```vim
:!mkdir -p ~/.vim/ftdetect/audio.vim
au BufRead,BufNewFile *.mp3,*.flac,*.wav,*.ogg set filetype=audio

:!mkdir -p ~/.vim/after/ftplugin/audio.vim
" insert or source Cmd() function here
call system(<SID>Cmd() . " " . expand("%:p")) | buffer# | bdelete# | redraw! | syntax on
```

You can see how the `ftdetect` and `ftplugin` directories can be your friend. Here's an example of opening a video with Vim:

<video controls width="100%" poster="../connermcd-opening-non-vim-file-formats/cut.png">
<source src="../connermcd-opening-non-vim-file-formats/cut.mp4" type="video/mp4">
<source src="../connermcd-opening-non-vim-file-formats/cut.webm" type="video/webm">
<source src="../connermcd-opening-non-vim-file-formats/cut.ogv" type="video/ogg">
Sorry, your browser doesn't support embedded videos, but <a href="../connermcd-opening-non-vim-file-formats/cut.mp4">you can download it</a>.
</video>


[1]: /2018/one-vim/
[2]: /2018/death-by-a-thousand-files/
[cmd-view]: http://vimdoc.sourceforge.net/htmldoc/editing.html#:view
[func-system]: http://vimdoc.sourceforge.net/htmldoc/eval.html#system()
[help-ftdetect]: http://vimdoc.sourceforge.net/htmldoc/filetype.html#ftdetect
[help-write-filetype-plugin]: http://vimdoc.sourceforge.net/htmldoc/usr_41.html#write-filetype-plugin
[program-explorer]: https://ss64.com/nt/explorer.html
[program-open]: https://ss64.com/osx/open.html
[program-ranger]: https://ranger.github.io/
[program-vifm]: https://vifm.info/
[program-xdg-open]: https://ss64.com/bash/xdg-open.html
