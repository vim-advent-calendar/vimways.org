---
title: "Transactions Pending"
publishDate: 2018-12-14
draft: true
description: "Take control of your text objects"
slug: "operator-pending"
author:
  name: "Dylan McClure"
---

> Literature adds to reality, it does not simply describe it. It enriches the
> necessary competencies that daily life requires and provides; and in this
> respect, it irrigates the deserts that our lives have already become.
>
> – C. S. Lewis

## What are Text Objects?

Even if you are a newcomer to vim, you're likely familiar with the concept of a
text object. In vimtutor, this concept is introduced pretty early on. Text
objects are "commands that can only be used while in Visual mode or after an
operator", as is explained in [:help text-objects][help-text-objects].
Essentially, text objects are descriptors that tell an operator what to operate
on. If you think about an operator as a verb, then metaphorically, a text object
is like a direct object, or what the verb is operating on. They do this by
creating a visual selection that the operator then operates on.

One of the most commonly-used examples is `iw`, which is short for or
**inner-word**. If you type `diw`, for instance, this will delete the word under
the cursor. `d` is the operator: **delete**; `iw` is the text object:
**inner-word**. We could easily change the operator to `c` for **change**, or we
could even use [tpope's vim-surround plugin][vim-surround] in order to gain
access to the `ys` operator and do something like `ysiw"` to surround the
**inner-word** with double-quotes. We could also change the text object to
something like `aw` (short for **around-word**), which includes the
**inner-word** as well as any surrounding whitespace.

In the same way that "literature adds to reality", text objects add to vim's
ability to describe transformations on text. There are a handful of very useful
built-in text objects--which you can read about at [:help
text-objects][help-text-objects]--but we can make our own that add to this in
order to both increase our productivity and sometimes save those extra couple of
keystrokes. I use my own text objects quite frequently, and the rest of this
article is concerned with creating text objects. Hopefully, it will be of use to
you.


## Simple Text Object Example

In order to make a new text object, you should map both the **visual-mode**
mapping as well as the **operator-pending** mapping. Respectively, this can be
achieved using the commands `:xnoremap` and `:onoremap`.

### Text Object *inner-line*

Here is a very simple example that creates the text object `il` for
**inner-line**:

```vim
" "in line" (entire line sans white-space; cursor at beginning--ie, ^)
xnoremap <silent> il :<c-u>normal! g_v^<cr>
onoremap <silent> il :<c-u>normal! g_v^<cr>
```

In order to fully understand the mappings, it might be useful to review
[Markzen's pun-filled article, "For Mappings And A Tutorial"][markzen-vimways].
However, I'll briefly describe each component and its function below and then
how each of these components work together to achieve our goal: a new text
object.

Both of these commands--`xnoremap` and `onoremap`--take a left-hand-side (*LHS*)
and a right-hand side (*RHS*) and bind the *LHS* to the *RHS*. The *LHS* is just
a sequence of keys. In our example, the *LHS* is `il`. When the *LHS* is typed
in the correct mode--for example in visual-mode when `xnoremap` is used--then
the *RHS* will be executed. In our example, the *RHS* is `:<c-u>normal!
g_v^<cr>`. This means that when we type `il` in either visual-mode or when vim
is expecting an operator (we used both `xnoremap` and `onoremap` to bind both of
these respective modes), then vim will execute the *RHS*.

#### *inner-line* LHS: `il`

The `<silent>` simply means that when the *RHS* is being executed, vim should
not display any output in the command-line. If we were to not use `<silent>`,
then we would see `:normal! g_v^` in the command-line every time we pressed `il`
in visual-mode or when there is a pending operator, and that could get fairly
annoying.

Of course, the *LHS* is `il`, which is what we must press in visual-mode or when
there is a pending operator in order to execute the *RHS* and fulfil our text
object's purpose. This can be anything we want, but I find that `il` for
**inner-line** makes the most sense. You can even use special-keys, such as
`<F12>` or `<c-bslash>`, to map special keys. However, note that there are very
limited options and vim maps quite a few of them already in visual mode.

#### *inner-line* RHS: `:<c-u>normal! g_v^<cr>`

The `:` begins command-line mode, and it operates as if you, the user, had typed
`:` yourself. However, there is a gotcha. When `:` is pressed in visual mode,
vim automatically puts the range, `'<,'>`, in the command-line because it
assumes that you want to use the range for the command you're about to type.
This leaves us with `:'<,'>` in total. Since the range, `'<,'>`, will interfere
with our mapping, we can use `<c-u>` ([:help c_CTRL-U][help-c_ctrl-u]) to clear
the command-line and restore it from `:'<,'>` to just `:`.

Then, we start the actual command we want to execute: `:normal! g_v^`.
Essentially, this command moves to the last non-whitespace character on the line
with `g_`, then enters visual mode with `v`, and finally moves to the first
non-whitespace character on the line with `^`. To read more about `:normal`,
check out [:help :normal][help-normal], and of course, if you're not familiar
with the motions or visual mode check out [:help g\_][help-g-under], [:help
^][help-hat], and [:help visual-mode][help-visual-mode].

#### All Together

What have we achieved? We have created a simple mapping such that when we press
`il` in visual mode or after an operator, vim will visually select or operate on
(respectively) the **inner line**. For example, `vil` will select from the first
non-whitespace character until the last non-whitespace character. Also, `cil`
will *change* what the visual selection would have selected. As a final example,
`yil` will yank the **inner line**.


### More Text Object Examples

Now that we have covered in depth how to create a simple text object, let's
cover a few more simple example before we dive into some more complex ones.

#### Text Object *around-line*

Since we have created a text object that selects the inner line (the whole line
sans any trailing whitespace), lets make one for **around-line** that selects
the entire line with the exception of the newline at the end.

```vim
" "around line" (entire line sans trailing newline; cursor at beginning--ie, 0)
xnoremap <silent> al :<c-u>normal! $v0<cr>
onoremap <silent> al :<c-u>normal! $v0<cr>
```

Well, that was easy. We simply needed to replace `g_` with `$` (instead of going
to the last non-whitespace character, we simply want to go to the last
character) as well as replace `^` with `0` (instead of going to the soft start
of the line, go to the beginning of the line). The relevant motions are [:help
$][help-dollar] and [:help 0][help-0].

Now we can do things like `"+yal` to yank the line (without the newline at the
end) into the system clipboard. Or we can use `val` to select the current line
sans the newline at the end.

#### Text Object *inner-document*

Suppose we wanted to make a text object that selected the entire document we're
currently working in, since it might be annoying to have to use something like
`ggcG`--or, [more philosophically, `ggVGc`][ggvgc]. Well, we know that we can
describe this operator with a text object and give it a name, so let's do just
that for `id`, or **inner-document**.

How do we achieve this? We know that we will need to move to the end of the
document, start visual mode, and finally move to the beginning of the document.
If you've been using vim, you might easily recognize that the two motions we
need are [:help G][help-G] and [:help gg][help-gg]. Let's piece it all together
based on what we've learned:

```vim
" "in document" (from first line to last; cursor at top--ie, gg)
xnoremap <silent> id :<c-u>normal! G$Vgg0<cr>
onoremap <silent> id :<c-u>normal! GVgg<cr>
```

Now, we can be as philosophical as we like (for example, with `vidc` rather than
`cid`) but we can save one character. While This isn't an amazing feat, we can
do even better since the *RHS* can be as arbitrarily complex as we want it to
be--within reason.


## Complex Text Object Examples

The above text objects were simply for saving one or two key strokes. However,
text objects can quickly become unwieldy. In such cases it is useful to map a
text object to a function, or to illustrate it with pseudocode:  `[xo]noremap
{LHS} :<c-u>call MyTextObjectFunc()<cr>`. The commands in the function will
achieve the same thing that the simple `:normal!` command achieved above--that
is to visually select the proper region of text.

### Text Objects *in-number* and *around-number*

Suppose we want to make a text object to select a number, which can be a binary,
a hex, or a decimal number. It would not be easy to put this in a one-line
command, but it is certainly possible to make a function that will do just that.
That's exactly what the two functions below do. The first function will only
select the number with `in`, while the second function will select the number
and any surrounding whitespace with `an`.

* **in-number**

```vim
" regular expressions that match numbers (order matters .. keep '\d' last!)
" note: \+ will be appended to the end of each
let s:regNums = [ '0b[01]', '0x\x', '\d' ]

function! s:inNumber()
	" select the next number on the line
	" this can handle the following three formats (so long as s:regNums is
	" defined as it should be above this function):
	"   1. binary  (eg: "0b1010", "0b0000", etc)
	"   2. hex     (eg: "0xffff", "0x0000", "0x10af", etc)
	"   3. decimal (eg: "0", "0000", "10", "01", etc)
	" NOTE: if there is no number on the rest of the line starting at the
	"       current cursor position, then visual selection mode is ended (if
	"       called via an omap) or nothing is selected (if called via xmap)

	" need magic for this to work properly
	let l:magic = &magic
	set magic

	let l:lineNr = line('.')

	" create regex pattern matching any binary, hex, decimal number
	let l:pat = join(s:regNums, '\+\|') . '\+'

	" move cursor to end of number
	if (!search(l:pat, 'ce', l:lineNr))
		" if it fails, there was not match on the line, so return prematurely
		return
	endif

	" start visually selecting from end of number
	normal! v

	" move cursor to beginning of number
	call search(l:pat, 'cb', l:lineNr)

	" restore magic
	let &magic = l:magic
endfunction

" "in number" (next number after cursor on current line)
xnoremap <silent> in :<c-u>call <sid>inNumber()<cr>
onoremap <silent> in :<c-u>call <sid>inNumber()<cr>
```

* **around-number**

```vim

function! s:aroundNumber()
	" select the next number on the line and any surrounding white-space;
	" this can handle the following three formats (so long as s:regNums is
	" defined as it should be above these functions):
	"   1. binary  (eg: "0b1010", "0b0000", etc)
	"   2. hex     (eg: "0xffff", "0x0000", "0x10af", etc)
	"   3. decimal (eg: "0", "0000", "10", "01", etc)
	" NOTE: if there is no number on the rest of the line starting at the
	"       current cursor position, then visual selection mode is ended (if
	"       called via an omap) or nothing is selected (if called via xmap);
	"       this is true even if on the space following a number

	" need magic for this to work properly
	let l:magic = &magic
	set magic

	let l:lineNr = line('.')

	" create regex pattern matching any binary, hex, decimal number
	let l:pat = join(s:regNums, '\+\|') . '\+'

	" move cursor to end of number
	if (!search(l:pat, 'ce', l:lineNr))
		" if it fails, there was not match on the line, so return prematurely
		return
	endif

	" move cursor to end of any trailing white-space (if there is any)
	call search('\%'.(virtcol('.')+1).'v\s*', 'ce', l:lineNr)

	" start visually selecting from end of number + potential trailing whitspace
	normal! v

	" move cursor to beginning of number
	call search(l:pat, 'cb', l:lineNr)

	" move cursor to beginning of any white-space preceding number (if any)
	call search('\s*\%'.virtcol('.').'v', 'b', l:lineNr)

	" restore magic
	let &magic = l:magic
endfunction

" "around number" (next number on line and possible surrounding white-space)
xnoremap <silent> an :<c-u>call <sid>aroundNumber()<cr>
onoremap <silent> an :<c-u>call <sid>aroundNumber()<cr>
```

#### Brief analysis of **in-number** and **around-number**

These text objects have served me very well when editing code. When it comes to
editing css, in particular, which has a lot of things like `left: 10px;`, it can
be useful to change the next number on the line. I must use `cin` at least a
handful of times each day, but I probably use it closer to hundreds of times.

I won't go too in-depth, but essentially the function figures out if there is a
number on the line that matches a binary, hex, or decimal regex, and if there is
a match, then it visually selects the number (**around-number** also selects
surrounding whitespace). `let l:lineNr = line('.')` gets the current line
number and `let l:pat = join(s:regNums, '\+\|')` builds the regex for a valid
number based on the list, `s:regNums`. Next, `if (!search(l:pat, 'ce',
l:lineNr))` attempts to search until the end of the number; if this fails, then
we will return without visually selecting anything, since `search()` will fail
if it does not match anything but will move the cursor to the end of the match
if it succeeds. Finally, we call `normal! v` to begin the visual selection and
then move to the beginning of the same match. The most important thing to become
acquainted with here is [:help search()][help-search].


### Text Objects *in-indentation* and *around-indentation*

The last two text objects that I'll cover are quite useful for python code and
coders who meticulously keep their code indented properly (as most of us do).
They select (and quickly might I add) an entire region of indentation! The first
one, **in-indentation** (`ii`), selects only the indentation without any
surrounding empty lines, and the second one, **around-indentation** (`ai`),
selects the current indentation level in addition to any surround empty lines.
Cool!

* **in-indentation**

```vim
function! s:inIndentation()
	" select all text in current indentation level excluding any empty lines
	" that precede or follow the current indentationt level;
	"
	" the current implementation is pretty fast, even for many lines since it
	" uses "search()" with "\%v" to find the unindented levels
	"
	" NOTE: if the current level of indentation is 1 (ie in virtual column 1),
	"       then the entire buffer will be selected
	"
	" WARNING: python devs have been known to become addicted to this

	" magic is needed for this
	let l:magic = &magic
	set magic

	" move to beginning of line and get virtcol (current indentation level)
	" BRAM: there is no searchpairvirtpos() ;)
	normal! ^
	let l:vCol = virtcol(getline('.') =~# '^\s*$' ? '$' : '.')

	" pattern matching anything except empty lines and lines with recorded
	" indentation level
	let l:pat = '^\(\s*\%'.l:vCol.'v\|^$\)\@!'

	" find first match (backwards & don't wrap or move cursor)
	let l:start = search(l:pat, 'bWn') + 1

	" next, find first match (forwards & don't wrap or move cursor)
	let l:end = search(l:pat, 'Wn')

	if (l:end !=# 0)
		" if search succeeded, it went too far, so subtract 1
		let l:end -= 1
	endif

	" go to start (this includes empty lines) and--importantly--column 0
	execute 'normal! '.l:start.'G0'

	" skip empty lines (unless already on one .. need to be in column 0)
	call search('^[^\n\r]', 'Wc')

	" go to end (this includes empty lines)
	execute 'normal! Vo'.l:end.'G'

	" skip backwards to last selected non-empty line
	call search('^[^\n\r]', 'bWc')

	" go to end-of-line 'cause why not
	normal! $o

	" restore magic
	let &magic = l:magic
endfunction

" "in indentation" (indentation level sans any surrounding empty lines)
xnoremap <silent> ii :<c-u>call <sid>inIndentation()<cr>
onoremap <silent> ii :<c-u>call <sid>inIndentation()<cr>
```

* **around-indentation**

```vim
function! s:aroundIndentation()
	" select all text in the current indentation level including any emtpy
	" lines that precede or follow the current indentation level;
	"
	" the current implementation is pretty fast, even for many lines since it
	" uses "search()" with "\%v" to find the unindented levels
	"
	" NOTE: if the current level of indentation is 1 (ie in virtual column 1),
	"       then the entire buffer will be selected
	"
	" WARNING: python devs have been known to become addicted to this

	" magic is needed for this (/\v doesn't seem work)
	let l:magic = &magic
	set magic

	" move to beginning of line and get virtcol (current indentation level)
	" BRAM: there is no searchpairvirtpos() ;)
	normal! ^
	let l:vCol = virtcol(getline('.') =~# '^\s*$' ? '$' : '.')

	" pattern matching anything except empty lines and lines with recorded
	" indentation level
	let l:pat = '^\(\s*\%'.l:vCol.'v\|^$\)\@!'

	" find first match (backwards & don't wrap or move cursor)
	let l:start = search(l:pat, 'bWn') + 1

	" NOTE: if l:start is 0, then search() failed; otherwise search() succeeded
	"       and l:start does not equal line('.')
	" FORMER: l:start is 0; so, if we add 1 to l:start, then it will match
	"         everything from beginning of the buffer (if you don't like
	"         this, then you can modify the code) since this will be the
	"         equivalent of "norm! 1G" below
	" LATTER: l:start is not 0 but is also not equal to line('.'); therefore,
	"         we want to add one to l:start since it will always match one
	"         line too high if search() succeeds

	" next, find first match (forwards & don't wrap or move cursor)
	let l:end = search(l:pat, 'Wn')

	" NOTE: if l:end is 0, then search() failed; otherwise, if l:end is not
	"       equal to line('.'), then the search succeeded.
	" FORMER: l:end is 0; we want this to match until the end-of-buffer if it
	"         fails to find a match for same reason as mentioned above;
	"         again, modify code if you do not like this); therefore, keep
	"         0--see "NOTE:" below inside the if block comment
	" LATTER: l:end is not 0, so the search() must have succeeded, which means
	"         that l:end will match a different line than line('.')

	if (l:end !=# 0)
		" if l:end is 0, then the search() failed; if we subtract 1, then it
		" will effectively do "norm! -1G" which is definitely not what is
		" desired for probably every circumstance; therefore, only subtract one
		" if the search() succeeded since this means that it will match at least
		" one line too far down
		" NOTE: exec "norm! 0G" still goes to end-of-buffer just like "norm! G",
		"       so it's ok if l:end is kept as 0. As mentioned above, this means
		"       that it will match until end of buffer, but that is what I want
		"       anyway (change code if you don't want)
		let l:end -= 1
	endif

	" finally, select from l:start to l:end
	execute 'normal! '.l:start.'G0V'.l:end.'G$o'

	" restore magic
	let &magic = l:magic
endfunction

" "around indentation" (indentation level and any surrounding empty lines)
xnoremap <silent> ai :<c-u>call <sid>aroundIndentation()<cr>
onoremap <silent> ai :<c-u>call <sid>aroundIndentation()<cr>
```

#### Brief analysis of **in-indentation** and **around-indentation**

I will keep this one very brief, but I will say that I worked pretty hard to
make this as fast as possible. It uses [`/\%v`][help-search-virtual] after
noting the current level of indentation in order to quickly match the current
indentation level. It is a vast improvement over its predecessor that used regex
on each line in a for loop to find the indentation region. Hopefully, the
comments are helpful.

## Conclusion

If you find yourself typing a motion followed by an operator and another motion,
then maybe you want to create a quick text object. It might be valuable to
create such text objects that can save some time, such as selecting a number or
an indentation level. It's simply so neat that vim is able to provide such an
intricate and powerful way to describe how to manipulate text. Indeed, that is
its primary objective, and it does a damn good job at it.

Also, if you want, you are welcome to copy the code snippets above--there is no
license on them. Good luck vimming. Try to stay productive but also curious and
remember to explore vim and other software, places, cultures, and ideas when you
get the opportunity.

[help-text-objects]: http://vimhelp.appspot.com/motion.txt.html#text-objects
[vim-surround]: https://github.com/tpope/vim-surround
[help-c_ctrl-u]: http://vimhelp.appspot.com/cmdline.txt.html#c_CTRL-U
[markzen-vimways]: https://vimways.org/2018/for-mappings-and-a-tutorial/
[help-normal]: http://vimhelp.appspot.com/various.txt.html#%3Anormal
[help-g-under]: http://vimhelp.appspot.com/motion.txt.html#g\_
[help-hat]: http://vimhelp.appspot.com/motion.txt.html#%5E
[help-visual-mode]: http://vimhelp.appspot.com/visual.txt.html#visual-mode
[help-dollar]: http://vimhelp.appspot.com/motion.txt.html#%24
[help-0]: http://vimhelp.appspot.com/motion.txt.html#0
[ggvgc]: http://www.ggvgc.com/
[help-G]: http://vimhelp.appspot.com/motion.txt.html#G
[help-gg]: http://vimhelp.appspot.com/motion.txt.html#gg
[help-search]: http://vimhelp.appspot.com/eval.txt.html#search%28%29
[help-search-virtual]: http://vimhelp.appspot.com/pattern.txt.html#%2F%5C%25v


[//]: # ( Vim: set spell spelllang=en: )
