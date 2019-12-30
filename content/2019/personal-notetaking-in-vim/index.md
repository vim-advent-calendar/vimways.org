---
title: "Personal Notetaking in Vim"
publishDate: 2019-12-01
draft: true
description: "Implementing a notetaking methodology in Vim"
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

> It pays you not to blink sometimes. It gives you a heck of a fright.
>
> – My grandmother, on rapid change


## Intro

Part of Vim's power is how it can integrate with its environment. It can
interact with external programs, external scripts can interact with Vim, and
Vim is of course scriptable. Here, I'm going to detail an example of weaving
Vim with other applications and the environment to implement a notetaking
methodology that I personally use.

My notetaking has changed a lot over the years, from little to no notetaking (I
don't recommend!), to experimenting with off-the-shelf tools
([Simplenote][simplenote], [Standardnotes][standardnote], [Vimwiki][vimwiki]),
to experimenting with various knowledge management methodologies, to rolling my
own framework for [Zettelkasten][zettelkasten] in Vim. I haven't yet reached
the ideal setup, but it's feeling close, and it's reached a point where I can
comfortably.


### Sidenote: Create + Consume in Vim

Yes, you did see non-Vim tools in my list of previously used tools for notes...
It should be noted that I was using Vim as my main editor long before I
switched to using Vim to take notes. The reason why is that for a time I knew I
wanted to create and edit notes using Vim, but I wanted to be able to read
those notes in other ways, such as rich text from rendered markdown
(Simplenote), or a wiki that was navigable in a browser (Vimwiki). The times I
used Vim to edit was frustrating, because I needed to fit with a workflow that
required rebuilding a wiki after editing, or opening one file at a time for
something like Simplenote.

Finally, I realized that I didn't actually need to read rich text or navigate
hyperlinks with a mouse in a browser. I could create *and consume* in Vim!
Granted, it's not as pretty for viewing sometimes, but now creating, editing,
searching, and reading notes are all the same thing. Efficiency.


### Zettelkasten

One more thing to discuss before we dive in - what is Zettelkasten?.
Zettelkasten (German for "card index") is a method for personal knowledge
management in which one uses many small atomic notes, linked to other such
notes. The idea is that it forms a huge interconnected network of notes one can
traverse and interact with. I came across this methodology a little while back
and love the idea. I haven't yet spent the time to really learn how to use it
effectively, but I've started to use some of the ideas, including linking
between notes and facilitating easy creation of notes.

If you're interested to know more about Zettelkasten as a system, see
[zettelkasten.de][zettelkasten] and/or web search for it. There are many good
resources. What I described above is a horrendous simplification.


## Let's get started!

Ok, so now we have a methodology and Vim without any specific notes/wiki
plugins. What do we do now? Let's work out the workflows involved. So we want:

- Easy creation of new notes. It should be frictionless to create and start
  editing a new note at any time. More friction equals less motivation to write
  up a note.
- Powerful options for search. Zettelkasten eschews hierarchy and taxonomy in
  favour of flexible search and...
- linking between notes. We need to be able to create a network of small notes,
  where we can search to find an entry point, and then traverse notes to
  discover related ideas.

### Creating notes

Obviously I'll be editing a new note in Vim. There are two main places from
where I want to be able to create a note: the shell and Vim itself. It must be
as frictionless as possible to create new notes; any friction will dissuade me
from taking a note at once, and thoughts are fleeting.

So, from inside Vim, I have a command and function to create a timestamped file
in my notes directory:

```vim
" .vim/plugin/local.vim
command! -nargs=* Zet call local#zettel#edit(<f-args>)
```

```vim
" .vim/autoload/local/zettel.vim
func! local#zettel#edit(...)

  " build the file name
  let l:sep = ''
  if len(a:000) > 0
    let l:sep = '-'
  endif
  let l:fname = expand('~/wiki/') . strftime("%F-%H%M") . l:sep . join(a:000, '-') . '.md'

  " edit the new file
  exec "e " . l:fname

  " enter the title and timestamp (using ultisnips) in the new file
  if len(a:000) > 0
    exec "normal Go\<c-u>datetime\<c-space> " . join(a:000) . "\<cr>\<cr>\<esc>"
  else
    exec "normal Go\<c-u>datetime\<c-space>\<cr>\<cr>\<esc>"
  endif
endfunc
```

Now we can create a new titled, timestamped note directly in Vim: `:Zet a new
note` to edit (for example) `~/wiki/2019-12-21-0945-a-new-note.md`.

It's possible to instruct Vim to execute a command on launch, so we can write a
shell function with the same api as the `:Zet` command:

```bash
zet() {
  nvim "+Zet $*"
}
```

So, `$ zet a new note` will produce the same result as the example above from
in Vim.

It would be just as easy to develop entry points to creating notes from
elsewhere in the environment, but since I spend a lot of time either in Vim or
have multiple shell sessions open, most of the time a neat new note is only a
few keystrokes away.


### Linking notes

Now we have some notes, we need to link them together.

Here, I stray from vanilla Vim, and lean on a couple of popular plugins:
[Ultisnips][ultisnips] to shortcut inserting custom syntax and
[Deoplete][deoplete] to auto-complete paths to other notes.

Before we go into the code, let's see what the end result looks like:

{{< asciicast 290330 >}}

Now the code! I use a syntax similar to Vimwiki to denote internal links, which
are simply paths to other note files in the notes directory, with the extension
removed for readability.

```snippet
" .vim/UltiSnips/markdown.snippets
snippet h "hyperlink"
[[$1]]$0
endsnippet
```

With this snippet, and the Deoplete configuration that comes next, The
keysequence `h<snippet-trigger>` enters the syntax and opens a fuzzy
autocomplete for other notes. Two key strokes is my definition of low friction.
:)

And this is the (abridged) Deoplete source plugin to list all files in my notes directory.

```python
# .vim/rplugin/python3/deoplete/sources/wiki_files.py
class Source(Base):
    def __init__(self, vim):
        self.name = 'wiki_files'
        self.mark = '[WL]' # WikiLink
        self.min_pattern_length = 0
        self.rank = 450
        # only activate for files in my notes directory
        self.filetypes = ['privwiki']

    def get_complete_position(self, context):
        # trigger completion if we're currently in the [[link]] syntax
        pos = context['input'].rfind('[[')
        return pos if pos < 0 else pos + 2

    def gather_candidates(self, context):
        contents = []
        path = '/home/swalladge/wiki/'
        # now gather all note files, and return paths relative to the current
        # note's directory.
        cur_file_dir = dirname(self.vim.buffers[context['bufnr']].name)
        for fname in glob.iglob(path + '**/*', recursive=True):
            fname = relpath(fname, cur_file_dir)
            if fname.endswith('.md'):
                fname = fname[:-3]
            contents.append(fname)
        return contents
```

Note that we can still use Vim's built in `gf` (goto file) mapping to follow
the link - see [:h 'suffixesadd'][suffixesadd]. The more we can do in Vim
builtins, the better - it's familiar, portable, maintained.


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

Now I also have some special files that I need to access frequently. From the
shell:

```bash
alias wi='nvim ~/wiki/index.md'
alias d='nvim + ~/wiki/diary.md'
```

```i3
bindsym Mod4+Shift+Return exec termite --directory "$HOME/wiki/" -e "nvim $HOME/wiki/index.md"
bindsym Mod4+Ctrl+Return exec termite --directory "$HOME/wiki/" -e "nvim + $HOME/wiki/diary.md"
```



---

_This article is licensed under the [Creative Common Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/). You are free to share and adapt this
article provided you give appropriate credits. Enjoy!_


[deoplete]: https://github.com/Shougo/deoplete.nvim
[fzf]: https://github.com/junegunn/fzf
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
[suffixesadd]: https://vimhelp.org/options.txt.html#%27suffixesadd%27
