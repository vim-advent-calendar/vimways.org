---
title: "Personal Notetaking in Vim"
publishDate: 2019-12-01
draft: true
description: "TODO"
author:
  email: "samuel@swalladge.net"
  github: "swalladge"
  homepage: "https://swalladge.net/"
  freenode: "swalladge"
  name: "Samuel Walladge"
  picture: "https://www.swalladge.net/assets/images/logo.jpg"
  twitter: "@srwalladge"
  dotfiles: https://github.com/swalladge/dotfiles
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

"quote"



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
- [Standardnotes][standardnote]
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

## Warning about code

I'm going to share a bunch of code snippets copied almost verbatim from my
config.  They are not fully fit for public consumption; they work for me with
my particular setup and workflow, but will likely need modifying before it will
work with someone else's. Copy code snippets with care!


## Zettelkasten

Zettelkasten (German for "card index") is a method for personal knowledge
management in which one uses many small atomic notes, linked to other such
notes. The idea is that it forms a huge interconnected network of notes one can
traverse and interact with. I came across this a little while back and love the
idea. I haven't yet spent the time to learn how to use it effectively, but I've
started to use some of the ideas, including linking between notes and
facilitating easy creation of notes.

### The system

If you're interested to know more about Zettelkasten as a system, see [zettelkasten.de][zettelkasten] and/or web search for it. There are many good resources.


### The tools

The features required include:

- search and tagging
- easy creation of new notes
- linking between notes

#### Creating new notes

Obviously I'll be editing a new note in Vim. There are two main places from
where I want to be able to create a note: the shell and Vim itself. It must be
as frictionless as possible to create new notes; any friction will dissuade me
from bothering to take a note.

So, from inside Vim, I have a command to create a timestamped file in my notes
directory:

```vim
" .vim/plugin/local.vim
command! -nargs=* Zet call local#zettel#edit(<f-args>)
```

```vim
" .vim/autoload/local/zettel.vim
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

This enables calling `:Zet a new note` to edit for example: `~/wiki/2019-12-21-0945-a-new-note.md`.

For the shell I have the following alias to call the above Vim command directly:

```bash
zet() {
  nvim "+Zet $*"
}
```

So, `$ zet a new note` will produce the same result as the example above from
in Vim.


### Linking notes

To link between notes, I make use of [ultisnips][ultisnips] for inserting the
syntax and [deoplete][deoplete] to complete filenames. This is a lot easier to
show than to explain, so here's a screencast:

{{< asciicast 290330 >}}


And the code - this is the snippet to insert my custom syntax for marking cross
links:

```snippet
" .vim/UltiSnips/markdown.snippets
snippet h "hyperlink"
[[$1]]$0
endsnippet
```

And this is the deoplete source plugin to list all files in my notes directory.
Note that it strips the file extension for cleanliness. I can still use Vim's
built in `gf` (goto file) mapping to follow the link - see `:h 'suffixesadd'`.

```python
# .vim/rplugin/python3/deoplete/sources/wiki_files.py
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


### Search

Search is core to being able to effectively *consume* notes (as opposed to
*creating* notes, as the previous points have been about). For me, there are 3
entry points to search and 3 types of search.

By "entry points", I mean where I want to start a search from. These are:

1. the desktop (ie. anywhere)
2. the shell
2. Vim itself

Types of search:

1. fuzzy find by title
2. grep file contents
3. search-engine-style search


Ok, so fuzzy find by title is done from the window manager with

```i3
# ~/.config/i3/config
bindsym Mod4+w exec --no-startup-id open-wiki-page
```

And the corresponding script that launches a graphical fuzzy finder which is
used to select a wiki file to open in a new terminal window:

```bash
~/bin/open-wiki-page
cd "$HOME/wiki"

if [ -n "$WAYLAND_DISPLAY" ]; then
  file=$(rg --files --follow | bemenu --fn 'Hack 11' -p "wiki:" -i -l 20)
else
  file=$(rg --files --follow | rofi -dmenu -no-custom  -i -p "wiki")
fi

[[ -n "$file" ]] || exit

exec termite -e "nvim \"$file\""
```

Fuzzy find from inside Vim is done using [fzf][fzf] and a mapping:

```vim
" ~/.vim/after/plugin/local.vim
map <silent> <leader>ww :FZF ~/wiki<cr>
```

Grepping contents of wiki files is done using Vim's builtin `:grep` command
(I've set `grepprg` to [rg][rg] for speed).

A proper search engine-esque search with stemming, ranking by relevance, etc.
is done using the excellent [Tantivy][tantivy] search engine, plumbed together
with [searchr][searchr], a cli program I wrote for this purpose.


```toml
# ~/.config/searchr/config.toml
[indexes.wiki]
language = "English"
index_path = "/home/swalladge/.searchr/wiki"
files = [
  '/home/swalladge/wiki/**/*.md',
]
require_literal_leading_dot = true
```


```vim
" ~/.vim/plugin/local.vim
command! -nargs=* Searchr call local#searchr#search(<f-args>)
```


```vim
" ~/.vim/autoload/local/searchr.vim
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














---


```bash
alias wi='nvim ~/wiki/index.md'
alias d='nvim + ~/wiki/diary.md'

# edit today's journal entry
today() {
  nvim + "$HOME/wiki/diary.md"
}
```


```vim
`.vim/filetype.vim`
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


[deoplete]: https://github.com/Shougo/deoplete.nvim
[fzf]: https://github.com/junegunn/fzf
[gollum]: https://github.com/gollum/gollum
[gtd]: https://hamberg.no/gtd/
[rg]: https://github.com/BurntSushi/ripgrep/
[searchr]: https://github.com/swalladge/searchr
[simplenote]: https://simplenote.com/
[sncli]: https://github.com/insanum/sncli
[standardnote]: https://standardnotes.org/
[tantivy]: https://github.com/tantivy-search/tantivy
[taskwarrior]: https://taskwarrior.org/
[ultisnips]: https://github.com/SirVer/ultisnips/
[vimwiki]: https://github.com/vimwiki/vimwiki
[zettelkasten]: https://zettelkasten.de/
