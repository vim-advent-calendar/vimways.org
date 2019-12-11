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
- future
  - wishlist for features, bindings, etc.


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
