---
title: "The Mapping Business"
publishDate: 2018-12-09
draft: false
description: "Tools of the mapping trade"
slug: "the-mapping-business"
author:
  name: "Markzen"
  email: "gh nick at proton mail"
  github: "fcpg"
---

## Time For More Cookin'

In [first part][fp], we went through the basics of mappings, and how they fit
into the big picture of Vim design and use.

We are now going to see a few common recipes to write slightly more advanced
mappings.

### Follow The Yellow Power Cord

In a nutshell, [`<Plug>`][pg] is a Vim notation for some special key sequence
_that the user cannot type_. What use is it?

Imagine you are a plugin author and you have a complicated mapping whose LHS
must be customizable by the user. The first option is to instruct them in the
documentation to copy that complicated mapping in their vimrc and just change
the LHS to their liking. This will work, but the user will have to deal with the
internals of your plugin, which is not ideal. And if you want to change the RHS
in a later version, your users will have to update their own version of the
mapping.

The second option is to make an indirection: create a mapping to your
internal RHS from a simple, intermediate LHS, and expose that LHS in your
documentation. The user will then be able to map his own LHS to your simple LHS,
and your implementation details will not be exposed. An example will make this
clear:

```vim
" ]&MyPluginIndentLine is an intermediate, "pivot" LHS/RHS
nnoremap <silent> ]&MyPluginIndentLine ...internal RHS...
nmap <silent> <LocalLeader>f ]&MyPluginIndentLine
```

Now, if the user want to change the default mapping from `<LocalLeader>f` to
something else, say, `<Leader><Tab>`, they will just need to add this in their
vimrc:

```vim
nmap <Leader><Tab> ]&MyPluginIndentLine
```

Then, if you later modify the internal RHS part, your users will not have to
change anything. Note that all mappings except the one to the internal RHS are
_not_ of the noremap family, since we do want all mappings to chain together;
`:nnoremap` in any of those would break the chain.

This setting would work, but there is a flaw: the intermediate LHS, namely
`]&MyPluginIndentLine`, interfers with normal usage. We paid attention to use a
leading sequence of `]&` that is not mapped by default, but the user might well
have created a mapping on that very sequence--and now, each time they will hit
`]&`, there will be a slight delay while Vim waits for the duration of the
timeout to see if it should run `]&` or `]&MyPluginIndentLine`.

That is where `<Plug>` comes in handy: since it is not a sequence made from
normal keys, it gets totally out of the way of other mappings that do not use
`<Plug>` themselves. To use it, just replace the arbitrary `]&` prefix above
with `<Plug>`:

```vim
nnoremap <silent> <Plug>MyPluginIndentLine ...internal RHS...
nmap <silent> <LocalLeader>f <Plug>MyPluginIndentLine
```

And in the user's vimrc:

```vim
nmap <Leader><Tab> <Plug>MyPluginIndentLine
```

Note that the RHS comprises, firstly, the expansion of `<Plug>` (we do not need
to know what it is exactly, though you can get an idea with `:echo "\<Plug>"`),
followed by all the individual letters of "MyPluginIndentLine". This is not some
special command-line or function-invoking mode! Therefore, conflicts could
theoretically arise. Suppose we write a snippet plugin with these two mappings:

```vim
nnoremap <silent> <Plug>MyPluginFor ...internal RHS 1...
nnoremap <silent> <Plug>MyPluginFori ...internal RHS 2...
```

The first mapping might insert some for-loop snippet, and the second one could
insert a for-loop variant that uses a variable called 'i'.

So far so good, but now a user finds it convenient to go into insert mode right
after inserting the first for-loop variant, and they want to make a mapping for
it:

```vim
" Intent: call <Plug>MyPluginFor and hit 'i' to go into insert mode
nmap <Leader>i <Plug>MyPluginFori
```

You see the problem: the mapping will inadvertently call the wrong mapping from
our snippet plugin!

Even though those cases are rare, it is common practice to avoid them altogether
by surrounding the part after `<Plug>` in braces:

```vim
nmap <silent> <LocalLeader>f <Plug>(MyPluginFor)
nmap <Leader><Tab> <Plug>(MyPluginFori)
```

In user's vimrc:

```vim
" Intent: call <Plug>(MyPluginFor) and hit 'i' to go into insert mode
nmap <Leader>i <Plug>(MyPluginFor)i
```

Problem solved.

### Never Give Up Control-R -- W.W.

[`<C-r>`][cr] inserts the content of a register from insert and command-line
mode. It is notably useful in visual mode, when the mapping needs to work with
the selection eg.:

```vim
xnoremap <silent> <Leader>gf y:pedit <C-r><C-r>"<cr>
```

This will open the filename expected in the visual selection into the preview
window. Doubling the `<C-r>` inserts the content literally, in case there were
some control characters in the filename that might be interpreted by Vim.

The expression register can also be used, opening some interesting
possibilities:

```vim
inoremap <C-g><C-t> [<C-r>=strftime("%d/%b/%y %H:%M")<cr>]
```

That mapping will insert the current date an time between brackets.

Another example, from command-line mode:

```vim
cnoremap <C-x>_ <C-r>=split(histget('cmd', -1))[-1]<cr>
```

This will insert the last space-separated word from the last command-line, as 
`<M-_>` in Bash.

`<C-r>` can also insert text present under the current cursor position, when
followed by some control characters. Here is an example with `<C-r><C-f>`, which
inserts the filename under the cursor:

```vim
nnoremap <silent> <Leader>gf :pedit <C-r><C-f><cr>
```

This is the normal mode version of the preview mapping we saw above (the
filename recognition will depend on the [`'isfname'`][if] option). Note that on
the command-line, for a command where a filename is expected (like `:e`), you
can also use a few special Vim notations to similar effects, eg. `<cfile>` will
insert on the command-line the filename under the cursor, and `<cword>` will
insert the current word. If a filename is not expected, you can always use
[`expand()`][ed] like this:

```vim
nnoremap <silent> c<Tab> :let @/=expand('<cword>')<cr>cgn
```

This mapping sets the last search pattern to the word under the cursor, and
changes it with the `cgn` sequence--making the whole thing conveniently
repeatable with `.` to apply the same replacement to some following occurrences.

### The Mushroom Register: @=

The [`@`][at] key executes the content of a register, and once again the
expression register offers a good deal of flexibility. As an example, consider
the [`<C-a>`][ca] normal mode command, that increases the number under the
cursor or the closest number on its right, on the same line, if any. A common
annoyance is words like `file-1.txt`: hitting `<C-a>` will turn it to
`file0.txt`, to the surprise of many users, as Vim assumes the next number is
'-1', not '1'. Let's write a mapping to change this behavior.

```vim
function! Increment() abort
  call search('\d\@<!\d\+\%#\d', 'b')
  call search('\d', 'c')
  norm! v
  call search('\d\+', 'ce')
  exe "norm!" "\<C-a>"
  return ''
endfun
```

The `Increment()` function finds the sequence of digits under the cursor or
following it, then selects it in visual mode, and finally runs `<C-a>` on it.
The visual mode version of `<C-a>` is a relatively recent addition, so Vim 8 or
a late Vim 7 version is required. Now, let's remap the normal mode `<C-a>` to
our function:

```vim
nnoremap <silent> <C-a> @=Increment()<cr>
```

The effect is to execute the `Increment()` function in the expression register,
which as we saw increases the next number ignoring leading minuses and returns
the empty string--leaving nothing to do for the `@` command, since the job is
already done.

At first glance, this might just look like a fancy alternative to `:call
Increment()<cr>`. There is a nice bonus to it, though: our mapping now accepts a
_count_, so that we can type `3<C-a>` to add three to the next number. This is
not something we could do with the `:call` version, at least not without adding
more code to deal with the count.

### Feeding Frenzy

The built-in [`feedkeys()`][fk] function inserts keys into the internal Vim
buffer containing all keys left to execute, either typed by the user or coming
from mappings. This can sound somewhat low-level, but it is a very useful tool.

```vim
nnoremap <silent> <C-g> :call feedkeys(nr2char(getchar()),'nt')<cr>
```

This mapping waits for a key after hitting `<C-g>` and executes it, ignoring any
mapping for that key -- a kind of "just-once-noremap". `getchar()` is first
executed: it waits for the user to hit a key, and returns its keycode.
`nr2char()` converts that keycode into a character, and `feedkeys()` puts that
key into the Vim internal buffer; the 'nt' options says not to use mappings, and
to process the key as though the user typed it. Even though it remaps the useful
`<C-g>` built-in, it instantly makes it available again on `<C-g><C-g>`.

Here's a longer example (inspired from igemnace on #vim):

```vim
function! QuickBuffer(pattern) abort
  if empty(a:pattern)
    call feedkeys(":B \<C-d>")
    return
  elseif a:pattern is '*'
    call feedkeys(":ls!\<cr>:B ")
    return
  elseif a:pattern =~ '^\d\+$'
    execute 'buffer' a:pattern
    return
  endif
  let l:globbed = '*' . join(split(a:pattern, ' '), '*') . '*'
  try
    execute 'buffer' l:globbed
  catch
    call feedkeys(':B ' . l:globbed . "\<C-d>\<C-u>B " . a:pattern)
  endtry
endfun

command! -nargs=* -complete=buffer B call QuickBuffer(<q-args>)

nnoremap <Leader>b :B<cr>
```

Hitting `<Leader>b` will run the user-defined Ex command `B`, which will in turn
call the `QuickBuffer()` function. When the latter is called without argument,
it will run `feedkeys(":B \<C-d>")`, with the effect of listing the completion
options of the `B` command -- that is, showing the list of buffers, thanks to
the `-complete=buffer` option of `B`. The `:B` is still on the command-line, so
now the user can pick its choice by entering a part of the wanted buffer
filename. All the conditionals of the `QuickBuffer()` function will be skipped,
and the [`buffer`][bf] Ex command inside the try block will be run on the
argument with leading and trailing wildcards automatically added. If there is a
single match, the buffer will be displayed and the function ends. If there is no
match or more than one match, the choices will be shown and the `:B` will be put
back on the commnd-line (in the 'catch' block).

The first `elseif` allows for `:B *` to show a full `:ls!` listing, with hidden
buffers. The second `elseif` lets the user select a buffer by number, eg.
`:B 2`, skipping all wildcards addition.

## Lazy And Gentlemen, Let's Jump To The Conclusion

While a few mappings into your vimrc are quick to process, a larger amount of
them can take its toll on the overall startup time. Quite often, a group of
related mappings share a common prefix, eg. `<Leader>x`; these mappings can deal
with some specific task, tool or plugin -- something that you might not use
every time you run Vim. In other words, they stand out as prime candidates for
_lazy loading_, and that is what we will do in this final example.

[vim-flattery](https://github.com/fcpg/vim-flattery) is a plugin of mine
(shameless `<Plug>`!) that overrides the `f` key so as to provide new targets on
the alpha characters: for instance, `fu` will jump to the next uppercase letter
on the current line, instead of jumping to the next 'u' letter. Not all letters
are overridden though, and the user can also choose which ones they want; for
the others, the key falls back to the default `f` built-in.

The design choice was to create a `<Plug>` mapping for each new target provided
by the plugin. This makes things easy to customize for the user, but it also
means creating quite a few mappings, all duplicated for `f` and `t`.
Lazy-loading them could definitely save some time during startup.

The initialization goes like this:

```vim
" in plugin/flattery.vim
if get(g:, 'flattery_autoload', 1)
  for op in [s:flattery_f_map, s:flattery_t_map]
    for cmd in ['nm', 'xm', 'om']
      exe cmd '<silent><expr>' op
            \ 'FlatteryLoad("'.op.'")'
      exe cmd '<silent>' '<Plug>(flattery)'.op
            \ op
    endfor
  endfor
else
  call flattery#SetPlugMaps()
  call flattery#SetUserMaps()
endif
```

If the `g:flattery_autoload` variable is true or does not exist, this code will
create a mapping on `s:flattery_f_map` and `s:flattery_t_map` (script-local
variables containing `"f"` and `"t"` by default) to some `FlatteryLoad()`
function. This is similar to this:

```vim
nmap <silent><expr> f FlatteryLoad("f")
nmap <silent><expr> t FlatteryLoad("t")

nmap <silent> <Plug>(flattery)f f
nmap <silent> <Plug>(flattery)t t
```

This is done for normal, visual and operator-pending mode. The `<Plug>` mappings
make it possible for the user to map them to what they want without setting
variables, and still benefit from lazy loading if needed.

Here is the `FlatteryLoad()` function:

```vim
" in plugin/flattery.vim
function! FlatteryLoad(o) abort
  call flattery#SetPlugMaps()
  call flattery#SetUserMaps()
  for op in [s:flattery_f_map, s:flattery_t_map]
    for cmd in ['nun', 'xu', 'ou']
      exe cmd op
    endfor
  endfor
  return "\<Plug>(flattery)".a:o
endfun
```

It calls the autoloaded `flattery#SetPlugMaps()` and `flattery#SetUserMaps()`
functions, which sets all the plugin mappings starting with `f` and `t` eg.
`fa`, `fb`, `fu` etc. Then, it unmaps the initial "lazy-loader" mappings (those
who called this very function) for all modes, as the loading has just been done.
Finally, it returns a string containing a `<Plug>` mapping that will be
processed as an RHS, since the mapping that called the `FlatteryLoad()` function
had the `<expr>` modifier. Consequently, the intended mapping will be executed.

With some effort, that mechanism can be made generic, and it can also load
plugins on demand, for instance with the Vim 8 package management. That is how
my current setting works, and it might be the topic of a following article.

Until then, merry xmaps to all!

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

[fp]: https://vimways.org/2018/for-mappings-and-a-tutorial/
[pg]: http://vimhelp.appspot.com/map.txt.html#%3CPlug%3E
[cr]: http://vimhelp.appspot.com/cmdline.txt.html#c_%3CC-R%3E
[if]: http://vimhelp.appspot.com/options.txt.html#%27isf%27
[ed]: http://vimhelp.appspot.com/eval.txt.html#expand%28%29
[at]: http://vimhelp.appspot.com/repeat.txt.html#%40
[ca]: http://vimhelp.appspot.com/change.txt.html#CTRL-A
[fk]: http://vimhelp.appspot.com/eval.txt.html#feedkeys%28%29
[bf]: http://vimhelp.appspot.com/windows.txt.html#%3Abuffer

