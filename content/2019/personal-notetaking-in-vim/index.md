---
title: "Personal Notetaking in Vim"
publishDate: 2019-12-01
draft: true
description: "Working with several working directories in Vim"
author:
  email: "samuel@swalladge.net"
  github: "swalladge"
  homepage: "https://swalladge.net/"
  irc: "swalladge"
  name: "Samuel Walladge"
  picture: "https://www.swalladge.net/assets/images/logo.jpg"
  twitter: "@srwalladge"
---

outline / points to cover:

- categories
  - tasks (gtd)
  - notes
  - wiki
  - zettelkasten
  - diary
- journey
  - vimwiki
  - vimwiki with markdown
  - markdown plugins
  - taskwarrior plugin
- my requirements / workflow
  - create and consume in vim
  - lightweight/fast (vimwiki was slow startup)
  - open/close many
  - search (fuzzy title + full text)
- current setup
  - methodology: zettelkasten + arbitrary
  - wiki bindings (gf, deoplete, zet)
  - scripts / aliases
  - diary
  - taskwarrior
  - search
  - folds
  - multiple locations via symlinks (implications for file searches)
- cool things
  - cool things that seem cool at the time but are never used afterwards
  - cool things that are slightly offtopic for this article
  - syncing? nextcloud + git. mobile? nextcloud and symlinks
- future
  - wishlist for features, bindings, etc.




## Context

Out of a computer based personal knowledge management system, I needed:

- a diary or journal to record events
- notes system for anything I wanted to track or remember in the future
- task management so I don't forget things to do

This is going to cover "notetaking" as a broad topic. Perhaps a better title
would be "personal knowledge management".


## Brief history

A long time ago, I rarely took notes. I forgot many things. I realized maybe I
should start taking notes. I was terrible at first, but over the years I've
been gradually researching note taking and optimizing my processes. I haven't
yet settled on a certain system, but have taken inspiration from several
defined systems over the years.

### Timeline

So a brief progression would look something like this:

- bad notetaking: adhoc and rare
- some notetaking experimenting with various software (long time ago; can't
  remember details)
- [Simplenote][simplenote]: official client on mobile plus [sncli][sncli] for desktop
  (editing files in Vim)
- [Standardnote][standardnote]
- others?
- Vimwiki with Vimwiki syntax
- Vimwiki with markdown + [Gollum][gollum] for viewing wiki on mobile
- Vimwiki with Vimwiki syntax
- experimenting with other Vim wiki plugins
- rolled own Vim configuration to manage what I have now
- continue tweaking configuration and writing scripts around it

So basically, there were the dark ages before I discovered Vim was perfect for
notetaking, then the playing with large Vim plugins, and finally rolling my
own.

### Create + Consume in Vim

It should be noted that I was using Vim as my main editor long before I
switched to using Vim to take notes. The reason why is that for a time I knew I
wanted to create and edit notes using Vim, but I wanted to be able to read
those notes in other ways, such as rich text from rendered markdown
(Simplenote), or a wiki that was navigable in a browser. The times I used Vim
to edit was frustrating, because I needed to fit with a workflow that required
rebuilding a wiki after editing, or opening one file at a time for something
like Simplenote.

Finally, I realized that I didn't actually need to read rich text or navigate
hyperlinks with a mouse in a browser. I could create *and consume* in Vim!
Granted, it's not as pretty for viewing sometimes, but now creating, editing,
searching, and reading notes are all the same thing. Efficiency.



## Current system

My current system is a directory tree full of markdown files, with a supporting
framework of scripts and Vim config. They roughly function as an interconnected
whole, and have various roles including:

- small time-stamped file, Zettelkasten style, for a scoped note like a tip or
  code snippet
- some files serving as a central place for linking these small note files
- file containing a list of some sort, updated regularly, like shopping lists,
  various logs, etc.
- "inbox" files to dump things to be sorted later
- diary

I also use [Taskwarrior][taskwarrior] for task management. Though I use this as
a standalone tool most of the time, I will discuss it here because it links
closely with my notetaking and at one time I used Vim plugins to link it more
closely.

## TODO


---

snippets to cover

zshrc (or bashrc):

```bash
alias wi='nvim ~/wiki/index.md'
alias d='nvim + ~/wiki/diary.md'

# edit today's journal entry
today() {
  nvim + "$HOME/wiki/diary.md"
}

# open quick note with title
zet() {
  nvim "+Zet $*"
}
```

i3/sway config

```i3
bindsym Mod4+Shift+Return exec termite --directory "$HOME/wiki/" -e "nvim $HOME/wiki/index.md"
bindsym Mod4+Ctrl+Return exec termite --directory "$HOME/wiki/" -e "nvim + $HOME/wiki/diary.md"
bindsym Mod4+w exec --no-startup-id open-wiki-page

```


script `open-wiki-page`

```bash
cd "$HOME/wiki"

if [ -n "$WAYLAND_DISPLAY" ]; then
  file=$(rg --files --follow | bemenu --fn 'Hack 11' -p "wiki:" -i -l 20)
else
  file=$(rg --files --follow | rofi -dmenu -no-custom  -i -p "wiki")
fi

[[ -n "$file" ]] || exit

exec termite -e "nvim \"$file\""
```

vimrc

```vim
" cool thing slightly off topic
nnoremap <silent> <leader>K :silent ! $BROWSER https://en.wiktionary.org/wiki/<cword><cr>
```

`.vim/rplugin/python3/deoplete/sources/wiki_files.py`

```python
import os
import re
from os.path import relpath, dirname
import glob

from deoplete.source.base import Base
from deoplete.util import expand


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.vim = vim
        self.name = 'wiki_files'
        self.mark = '[WL]' # WikiLink
        self.min_pattern_length = 0
        self.rank = 450
        self.filetypes = ['privwiki']

    def get_complete_position(self, context):
        pos = context['input'].rfind('[[')
        return pos if pos < 0 else pos + 2

    def gather_candidates(self, context):
        contents = []
        path = '/home/swalladge/wiki/'
        len_path = len(path)

        cur_file_dir = dirname(self.vim.buffers[context['bufnr']].name)

        for fname in glob.iglob(path + '**/*', recursive=True):
            fname = relpath(fname, cur_file_dir)

            if fname.endswith('.md'):
                fname = fname[:-3]

            contents.append(fname)

        return contents
```

`.vim/filetype.vim`

```vim
if exists("did_load_filetypes")
  finish
endif
augroup filetypedetect
  " taking advantage of dotted filetypes for wiki-specific config
  au! BufNewFile,BufRead /home/swalladge/wiki/*.md    setf privwiki.markdown
augroup END

```

`.vim/after/ftplugin/privwiki.vim`

```vim
nnoremap <buffer> <space>gf :e %:h/<cfile>.md<cr>
setlocal foldmethod=marker
```


searchr config

```toml
[main]
default_index = "wiki"


[indexes.wiki]
language = "English"
index_path = "/home/swalladge/.searchr/wiki"
files = [
  '/home/swalladge/wiki/**/*.md',
  '/home/swalladge/proj/swalladge/swalladge.net/**/*.md',
  '/home/swalladge/proj/swalladge/swalladge.net/**/*.markdown',
]
require_literal_leading_dot = true
```

`.vim/plugin/local.vim`

```vim
command! -nargs=* Zet call local#zettel#edit(<f-args>)
command! -nargs=* Searchr call local#searchr#search(<f-args>)
```

`.vim/autoload/local/searchr.vim`

```vim
function! local#searchr#search(index, ...)
  let l:query = join(a:000, ' ')
  if a:index == "all"
    let l:which_index = '-a'
  else
    let l:which_index = '-i ' . a:index
  endif
  let l:cmd = 'searchr ' . l:which_index . " search -l 15 " . l:query . ""
  let l:files = split(system(l:cmd), "\n")
  let l:qffiles = []
  for f in l:files
    call add(l:qffiles, {'filename': f})
  endfor
  call setqflist(l:qffiles)
  copen
  cc
endfunction
```

`.vim/autoload/local/zettel.vim`

```vim
func! local#zettel#edit(...)
  let l:sep = ''
  if len(a:000) > 0
    let l:sep = '-'
  endif

  let l:fname = expand('~/wiki/') . strftime("%F-%H%M") . l:sep . join(a:000, '-') . '.md'

  exec "e " . l:fname
  if len(a:000) > 0
    exec "normal Go\<c-u>datetime\<c-space> " . join(a:000) . "\<cr>\<cr>\<esc>"
  else
    exec "normal Go\<c-u>datetime\<c-space>\<cr>\<cr>\<esc>"
  endif
endfunc
```

`.vim/UltiSnips/markdown.snippets`

```snippet
snippet h "hyperlink"
[[$1]]$0
endsnippet
```

`.vim/after/syntax/markdown.vim`

```vim
" highlight jrnl style headers (timestamp)
" I use these to timestamp sections in my private wiki
syn match markdownTimestamp /\d\d\d\d-\d\d-\d\d\( \d\d:\d\d\)\?\|\d\d:\d\d/
hi def link markdownTimestamp Todo
```

---

_This article is licensed under the [Creative Common Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/). You are free to share and adapt this
article provided you give appropriate credits. Enjoy!_


[taskwarrior]: TODO
[gtd]: TODO
[vimwiki]: TODO
[zettelkasten]: TODO
