---
title: "On Mappings - Basics"
date: 2018-10-14T11:11:59+02:00
publishDate: 2018-12-07
draft: true
description: "mappings basics"
slug: "on-mappings-basics"
author:
  name: "Markzen"
  email: "gh nick at proton mail"
  github: "fcpg"
---

## On The Genealogy of Modality

What makes Vim so different from other editors is, arguably, its rich set of
motion commands. Once you can move around with precision, you not only gain
time, as you do not need to reach for the mouse, but you can also turn pretty
much every modification into tiny "programs", either to accomplish ad hoc tasks
via recorded macros, or to address more general cases, thanks to commands,
functions--and mappings.

A mapping is the binding of a key or a sequence of keys, called the *left-hand
side (LHS)*, to a series of keystrokes, the *right-hand side (RHS)*. The RHS is
similar to a macro recorded with [`q`][q]; contrary to some other tools or
editors, mappings do not reach for some 'core' functions or commands, like
hypothetical `next-word` or `delete-char`, that the default bindings would just
call. In Vim, motions and modification commands are so central that it would not
make much sense to decouple them from their standard keys, since they are the
building blocks of what we could call the "Vim editing programming language".
For instance, `dw` is like a program statement that deletes chars from cursor to
the beginning of next word; it's a piece of code every Vim user will understand,
like an 'if' statement in C or in another programming language. Thus, in Vim the
media (the key) is definitely the message (the function to execute).

Obviously, since alphanumeric keys are used to write "editing programs", there is
a need to separate "programming mode" where the user hits `dw` to delete a word,
from "insertion mode", where the user just wants to type text and not execute
programs. That is why Vim is a *modal editor*, contrary to, say, Emacs. Once you
go the modal road, it makes sense to define [extra modes][em] for things like
visual selection or the command-line. Again, mappings make it possible to
automate tasks for each of these modes.

So, if Vim is programming, custom mappings are no less than its user-defined
functions.

## Maps. Very dangerous... You Go First

The general syntax to create mappings is:

```
{map-cmd} [modifiers] {lhs} {rhs}
```

'{map-cmd}' is one of the several mapping-defining Ex commands we will examine
shortly. '[modifiers]' is an optional list of modifiers. '{lhs}' is the key
sequence that will trigger the mapping: if it contains a literal blank (space,
tab or linefeed), it must be escaped. '{rhs}' is the key sequence that will be
triggered, as though the user typed these keys directly (for the most
part--there are a few differences).

### Mad Maps Beyond Thousand Modes

Each Vim mode has its own [mapping-defining commands][mc]:

* `nmap` for normal mode
* `imap` for insert mode
* `vmap` for visual mode and select mode
* `xmap` for visual mode only
* `cmap` for command-line mode
* `omap` for operator-pending mode
* `tmap` for terminal mode

Most are self-explanatory. `vmap` defines mappings both for visual mode and
select mode; if you do not know what [select mode][sm] is, it is similar to
visual mode, but hitting a printable key like alphanumerics will replace the
visual selection with that key and switch to insert mode. Select mode is not
often used, so many Vim users do as though it did not exist and use `vmap` to
define visual mode mappings. However, some plugins can take advantage of it, for
instance snippet plugins that expand shortcuts into text or code with parts that
the user may want to change, like some default variable name. Selecting the
variable in select mode enables the user to type the new name "over" the visual
selection, or to hit some control char (eg. `<Tab>`) to go to the next
occurrence. Unfortunately, if the user made some mappings with `vmap`, this can
interfere with that process, if there are mappings starting with a printable
char like `<Space>` or `,`. Thus, it is best to use `xmap` to define mappings
for visual mode (and `smap` for select mode if you ever need it).

`omap` is for [operator-pending mode][om], ie. the mode where extra key(s) are
expected, typically to define the selection where the current command will
operate. This is the mode you get when you hit `y`, `c` or `d` and Vim waits for
the user to define what will be yanked, changed or deleted. This command
enables the user to create custom text objects of sorts.

`tmap` lets users define mappings for the new [_terminal mode_][te] of Vim,
available inside a buffer containing a terminal. This requires Vim 8 or the
backported patches.

Finally, `map` is the original mapping command from vi, and in Vim it
simultaneously defines a mapping for normal, visual and operator-pending mode.
`map!` (also from vi) defines a mapping for insert and command-line mode. The
mode-specific versions (`nmap`, `imap` etc.) are generally preferred in Vim.

### GG no RE

Say you want to extend the `<Return>` key in normal mode, so that in addition to
its standard function (going to the first non-blank of the next line), it also
temporarily turns off search highlighting. You come up with the following
command:

    nmap <Return> :nohls<Return><Return>

It calls the [`nohls`][nh] Ex command on the command-line, runs it, and then
finally sends a `<Return>` to go to the next line. You execute this nmap
command, hit `<Return>`, and... Vim seems to hang (hit `<C-c>` to interrupt).
What gives?

The `:nohls<Return>` part runs just fine, but the issue is the last `<Return>`:
remember, the RHS of a mapping runs as though the user typed it. So, when you
hit `<Return>` to run the mapping, the mapping will also "hit" `<Return>` at the
end--and you get an infinite recursion!

    nmap <Return> :nohls<Return><Return>
    "       ^                      |
    "       `---[recursive call]---'

What you meant, of course, was to execute the core function of the unmapped
`<Return>`, not to run the mapping again. In other words, you do not want
mappings to apply in the RHS. That is exactly what the [_noremap_][nr] version
of mapping-defining commands do. Try:

    nnoremap <Return> :nohls<Return><Return>
    "                                  ^ [Built-in <Return>]

Bingo, everything works as intended.

Each mapping-creating command has its noremap version:

* nnoremap
* inoremap
* xnoremap
* cnoremap
* onoremap
* etc.

As a rule of thumb, use the noremap versions unless you actually need to run
mappings in the RHS.

### Modifiers: The Bestiary

A few modifiers are available to tweak the created mapping; they all have the
form `<modifier>`, between angle brackets. Here are the main ones; consult the
[documentation][ma] for the whole list.

#### Silence, RHSling

[`<silent>`][si] is one of the most used modifiers. As its name suggests, it
turns off echo area visual feedback for the duration of the mapping execution.
This is especially useful if you run Ex commands in the RHS that you do not want
to expose to the user. For instance:

    xnoremap <silent> p p:if v:register == '"'<Bar>let @@=@0<Bar>endif<cr>

This extends `p` in visual mode (note the _noremap_), so that if you paste from
the unnamed (ie. default) register, that register content is not replaced by
the visual selection you just pasted over--which is the default behavior. This
enables the user to yank some text and paste it over several places in a row,
without using a named register (eg. `"ay`, `"ap` etc.).

In the previous mapping, it would be annoying to see the `:if v:register...`
command-line each time you pasted in visual mode; thus, the `<silent>` modifier
was added, and nothing is displayed when the mapping runs. As for the rest of
the mapping, the `v:register` special variable contains the name of the
register, if any, that was specified for the current mapping when the user typed
something like `"ap`. The statement `let @@=@0` re-assigns the value of the `@0`
register, which contains the last yanked text, to the unnamed register (`@@`)
once the paste is done. `<Bar>` stands for the `|` character that separates Ex
commands on the command-line, and `<cr>` is another way to get a carriage
return, along with `<Enter>` or `<Return>`.

#### Don't Map For Me Next Door Neighbor

[`<buffer>`][bu] makes the new mapping buffer-local, ie. it will be defined only
for the buffer that was current when the mapping was created. It is useful in
filetype-specific settings, eg. in `/.vim/after/ftplugin/help.vim`:

    nnoremap <silent><buffer> zl
     \ :call search('<Bar>[^ <Bar>]\+<Bar>\<Bar>''[A-Za-z0-9_-]\{2,}''')<cr>

A buffer-local mapping on `zl` is created on buffers with the `help` filetype,
ie. help buffers created with `:help`. The mapping jumps to the next tag in the
current buffer. Obviously, this only makes sense in help buffers, so we should
not make this mapping global. Again, note the `<silent>` modifier, since we
do not want to show this RHS on the command-line each time we use the mapping.

Here is the backward-jumping version of the mapping:

    nnoremap <silent><buffer> zh
     \ :call search('<Bar>[^ <Bar>]\+<Bar>\<Bar>''[A-Za-z0-9_-]\{2,}''','b')<cr>

#### Unique: Is This Seat Taken?

[`<unique>`][un] prevents the clobbering of an existing mapping on the same LHS.
This can be useful for plugin authors, who want to offer default mappings but
are still careful not to override the users' own mappings:

    nnoremap <unique><silent> <LocalLeader>a :call ThisPluginFunction()<cr>

If there already is a mapping on `<LocalLeader>a`, then the `nnoremap` above
will fail (the error can be silenced with `silent! nnoremap <unique> ...`).
`<LocalLeader>` is expanded to some user-defined key, and is typically used for
buffer-local settings.

#### Expr-esso: What Else To Eval

[`<expr>`][ex] changes the meaning of the RHS: it is no longer a sequence of
keys to run like a macro, but an _expression_ that will be evaluated each time
the mapping is triggered, and the result of that evaluation will be a string
containing the key sequence to run. So this is a level of indirection to make
things more dynamic; typically, it contains some conditional to either run one
sequence or the other. Here is an example:

    inoremap <expr> jk pumvisible() ? "<C-e>" : "<Esc>"

This is the "classic" `jk` to exit insert mode, with a twist: if the pop-up menu
is visible (this is the menu showing completion candidates), then it will close
it with [`<C-e>`][pe] instead of exiting insert mode with `<Esc>`. The whole RHS
is a single expression, here, a ternary conditional, and when you hit `jk`, the
expression is evaluated. The [`pumvisible()`][pv] function is called, returning
true or false depending on whether the pop-up menu is visible, and if it is then
the expression evaluates to `<C-e>`, otherwise it evaluates to `<Esc>`. The
result of that evaluation becomes the final RHS. 

Here is another example:

    onoremap <expr> il ':<C-u>norm! `['.strpart(getregtype(), 0, 1).'`]<cr>'

This is an operator-pending mapping, that selects the last piece of changed text
(most often, some pasted text), in the same visual mode (char, line or block) as
that of the used register. It can be used to indent some pasted lines, with
`>il`. The `<expr>` modifier is necessary to evaluate the `strpart(...)` part of
the RHS; it is then concatenated to the leading and trailing literal strings, to
form the final RHS.

As for the rest of the mapping: the `<C-u>` clears the command-line, since in
some circumstances Vim can fill it automatically with a line range, for instance
if `:` is hit from visual mode, or if a count is given to it (either directly,
or from a mapping, eg. if we hit something like `3il`). [`norm`][no] will
execute normal mode commands, and the `!` says not to use mappings in those,
like `noremap`. The [`[` and `]`][bk] marks are automatically set on both ends
of the last changed text, so the first backtick goes to one end, then the right
visual mode is set by the `strpart(...)` part, and the second backtick goes to
the other end of the changed text. Making a visual selection from an
operator-pending mapping defines the object of the current command, eg. `y`, `c`
or `d`.

### Escaping and Notation

#### Better Get Used To These Bars, Kid

Mapping-defining commands are standard Ex commands, so they can be separated by
the [`|`][ba] character. What do you think the following command will do?

    nnoremap <F7> :echo "foo"|echo "bar"

This command actually contains two parts: first, the `nnoremap` Ex command, then
the `echo "bar"` one. So, it will map `<F7>` to `:echo "foo"`, _then_ it will
run `echo "bar"` just once, when the `<F7>` mapping is defined. This is probably
not what the user intended!

In order to map `<F7>` to `echo "foo"|echo "bar"`, the `|` character must be
escaped, either with `\|` or with the Vim notation `<Bar>` (in five characters).
The following two commands do the same thing:

    " same thing
    nnoremap <F7> :echo "foo"\|echo "bar"
    nnoremap <F7> :echo "foo"<Bar>echo "bar"

Pick your favorite method. Also, do not forget to add a trailing `<cr>` to those
mappings if you want to run the command-line when calling the mappings;
otherwise, they will stay there on the command-line, for the user to modify, run
or cancel.

#### We Don't Need No True Control

You can use literal control chars in your mappings, by hitting [`<C-v>`][cv]
followed by the control char in insert or command-line mode. For instance,
pressing `<C-v>` then the tab key will insert a literal tab char (you can use
`:set list` to show them). However, it is not very convenient to work with
literal control chars: the graphic representation can be confusing (eg. `^[` for
the Escape key), and it can insert a terminal-dependent sequence, like `^[OP`,
instead of the generic character (here, the F1 key).

The best practice is to use the Vim notation like we did so far, eg. `<C-x>`, in
five chars (`<` + `C` + `-` + `x` + `>`), for Control+x. All keys have a
notation, eg. `<Tab>`, `<Return>` or `<Esc>`; check out the [documentation][vn]
for the complete list.

Vim will expand Vim notation in mappings commands as long as the `<` flag does
not appear in [`'cpoptions'`][cp] (it does not by default). You can also include
the Vim notation in strings by prepending the notation with a backslash, eg.
`"\<Tab>"` is a string that will contain a single literal tab when the code is
evaluated.

#### And All The Keys That Lead You There Were Mappings

As a convenience, Vim provides two customizable Vim notation expansions that you
can use in your mappings: [`<Leader>`][le] and [`<LocalLeader>`][ll]. You can
set their value via the `mapleader` and `maplocalleader` global variables, eg.:

    let mapleader = "\<Space>"
    let maplocalleader = "&"

You can then use it like this:

    nnoremap <silent> <Leader>w :w<cr>

Now hitting `<Space>w` will save the current buffer.

It is called "leader" as it is generally the first key of a group of mappings. A
common setting is to undefine the original behavior of that key, so that it does
not interfer or trigger inadvertently:

    nnoremap <Space> <Nop>

Leader and LocalLeader let the user change several mappings at one fell swoop
just by changing the value of the `mapleader` and `maplocalleader` variables,
but this is not something that occurs very often. Also, note that the mechanism
is a mere convenience: `<Leader>` is expanded in mapping commands, but not
elsewhere. This does *NOT* echo a space:

    " No expansion: echoes `<Leader>` in eight chars
    :echo "\<Leader>"

And if you show a mapping containing Leader, you will see its expansion (the
`<Space>` character):

    :nmap <Leader>w

So all in all, there is not a whole lot to gain with Leader and LocalLeader,
but they at least show intent, and it can make it easier to search through your
Vim files for mappings.

## Come Out To Part II, We'll Get Together, Have A Few Laughs

In this first part, we went through a whirlwind tour of the mappings concepts
and syntax; hopefully this should get you started if you never wrote mappings
before, or it might have given you some ideas for your future mappings.

In part two, we will present a few mapping-related tools and tricks to help you
unleash the madman<C-w> power user in you. 

That's all for now, vimfolks!

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

[q]:  http://vimhelp.appspot.com/repeat.txt.html#q
[em]: http://vimhelp.appspot.com/intro.txt.html#vim-modes
[mc]: http://vimhelp.appspot.com/map.txt.html#%3Amap-commands
[sm]: http://vimhelp.appspot.com/visual.txt.html#Select-mode
[om]: http://vimhelp.appspot.com/intro.txt.html#Operator-pending
[te]: http://vimhelp.appspot.com/terminal.txt.html#terminal
[nh]: http://vimhelp.appspot.com/pattern.txt.html#%3Anohlsearch
[nr]: http://vimhelp.appspot.com/map.txt.html#%3Anore
[ma]: http://vimhelp.appspot.com/map.txt.html#%3Amap-arguments
[si]: http://vimhelp.appspot.com/map.txt.html#%3Amap-silent
[bu]: http://vimhelp.appspot.com/map.txt.html#%3Amap-local
[un]: http://vimhelp.appspot.com/map.txt.html#%3Amap-%3Cunique%3E
[ex]: http://vimhelp.appspot.com/map.txt.html#%3Amap-expression
[pe]: http://vimhelp.appspot.com/map.txt.html#popupmenu-keys
[pv]: http://vimhelp.appspot.com/eval.txt.html#pumvisible%28%29
[no]: http://vimhelp.appspot.com/various.txt.html#%3Anorm
[bk]: http://vimhelp.appspot.com/motion.txt.html#%27%5B
[ba]: http://vimhelp.appspot.com/cmdline.txt.html#%3Abar
[cv]: http://vimhelp.appspot.com/insert.txt.html#i_CTRL-V
[vn]: http://vimhelp.appspot.com/intro.txt.html#key-notation
[cp]: http://vimhelp.appspot.com/options.txt.html#%27cpo%27
[le]: http://vimhelp.appspot.com/map.txt.html#mapleader
[ll]: http://vimhelp.appspot.com/map.txt.html#maplocalleader

