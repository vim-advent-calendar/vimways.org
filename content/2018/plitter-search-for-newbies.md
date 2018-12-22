---
title: "Search for us, newbies"
publishDate: 2018-12-19
draft: true
description: "Supercharge your movement through the buffer"
slug: "searches-for-us-newbies"
author:
  name: "plitter"
  github: "plitter"
---

## Search in Vim for newbies

Now that we've seen [moving across files][moving-across-files] I think it is time to get back to the current buffer and see what is possible here as well.

One thing that seems to happen consistently on the way from beginning newbie to not-so-much newbie is that moment when you realize that mashing `hjkl` or holding `w`/`b` is not the most efficient way to move around. Personally, I don't think counting words is any efficient either. To take an example (where I use `^` as indicator for the cursor position):

```vim
String result = new String(anotherString + "hello");
^
```

What count do you need for `w` to get to `hello`? The answer might surprise you. Go ahead, I'll wait.

OK, so we all came to the conclusion of `9w` to get to `hello`? Vim has the interestingly decided that `=`, `(`, `)`, `+`, and `"` started words so we had to add 4 to our initial count, which makes it hard count correctly and, if we were wrong, there isn't a "repeat" command for `[count]w`.

There is another line-wise search in vim that is slightly more efficient, even if slightly less precise. Consider our former example, but this time we want to get to the `e` of `hello`: we can type `fe` and repeat the search with `;`. Since this is a line-wise search and `e` happens to be the last `e` you could just hold down `;` and you will hit the correct spot. That's not nearly as precise, but I don't have to count the `e`'s to get to where I want to go. This, in my counting deficient brain, is a plus as holding `w` will certainly overshoot the target. But what happens when you have something like the following and you want to move to `apply`?

```vim
var oldUnload = window.onbeforeunload;
^
window.onbeforeunload = function() {
    saveCoverage();
    if (oldUnload) {
        return oldUnload.apply(this, arguments);
    }
};
```

Should you count to get down 4 lines, then `4w` to get to `apply`? Or use relative numbers to move down and then `fa;`?

There is a better way and it is simply to search. You look at where you want to go, press `/` and start typing the word. To make this more user-friendly, we want to see where we would end up if we pressed enter now.  So we enable incremental search with `:set incsearch` and  we try again, with our previous example:

<script id="asciicast-218011" src="https://asciinema.org/a/218011.js" async></script>

Four keystrokes and we knew at the third keystrokes that we had hit the correct spot. This is the closest I've come to point and click, and it is super fast.

### Addendum for previous motions

So, I covered `f`, `w` and `/`, and I think it is worth mentioning some opposites, additions, and silly mnemonics.

#### Opposites and additions

So `f` searches forward on the line, but how should you move back? Well, there is `F<char>` which allows you to search backwards but that might be more work than we're willing to do if we simply overshot our target. So if we are at the `e` in `hello` and we really wanted the `e` in `anotherString`, we can simply press `,` to repeat the last move in the opposite direction.

Another complementary search for `f` is `t` which searches *until* the character, and its opposite `F` which moves backward.

`w` is another story, though. `w` moves you to the start of the next word and we might expect `W` to move to the previous word. Instead, it does... the exact same thing as `w`, at first glance. I'll leave the specifics up to [the manual][the-manual] (which you should read), but an easy example of the difference is this:

```vim
public void importantFunction(Type1 t1);
            ^
```

`W` will not care about the `(` or `)` and jump straight to `t1`.

`/something` will search forward for the first `something` that it finds. To find the next `something`, press `n`. To find the previous `something`, press `N`. Just like `F` for `f` there's `?` for `/` which searches backward, with `n` moving to the previous `something` and `N` moving to the next. Remember that all of these motions can be preceded with a count.

#### Mnemonic

Here are the mnemonic tricks I use to remember what those motions do:

Command | Mnemonic
---|---
`f` | forward search (see [:help f][:help-f])
`t` | 'til, as in until (see [:help t][:help-t])
`w` | word (see [:help w][:help-w])
`/` | forward search, if you draw the slash from bottom then the slash goes from left to right (see [:help /][:help-/])
`?` | backward search, if you draw the question mark from the bottom it points backward (see [:help /][:help-/])

I hope you weren't expecting anything fancy...

## `/` is one of the supreme features (IMHO)

Imagine that you have:

```vim
String result1 = new String(anotherString + "hello");
String result2 = new String(anotherString + "hello");
^
String result3 = new String(anotherString + "hello");
String result4 = new String(anotherString + "hello");
String result5 = new String(anotherString + "hello");
String result6 = new String(anotherString + "hello");
String result7 = new String(anotherString + "hello");
String result8 = new String(anotherString + "hello");
```

Say you don't need `result2-8`. One easy way to remove those lines is to just hold `d` and after a while it will all be deleted. But as vimmers we should try to do most things in one go, since it is easier to undo or put somewhere. One fun and intuitive way is to use visual mode:

```vim
V/8<cr>
```

and you have marked all the lines that you want to delete and you can press `d` knowing that this is exactly what you wanted. A more direct approach could be to do:

```vim
d/8<cr>dd
```

but this is not removing everything at once. Luckily we can just search again in the same query:

```vim
d/8/;/;/e<cr>
```

and you have done exactly what you wanted. Let's break that one down

- `d` accepts a motion and luckily `/` is a motion
- `/8` is a normal search for `8`
- `/` marks the end of the pattern
- `;` shows that the next part is a new search
- `/;` searches for the next `;`
- `/e` leaves the cursor at the end of the match

For fun, and to illustrate our point rather than be a good vimmer, you can do something like:

```vim
d/result/;//;//;//;//;//;//;/;/e
```

to obtain the exact same result.

For more information checkout [:help /][:help-/], especially the section on offset.

Still for fun, but this time to be a good vimmer, one could use visual-line mode to cast whatever motion follows to a linewise motion:

```vim
dV/8<CR>
```
<<<< STOPPED HERE >>>>
Another thing that makes / very easy to use is that you have history which you can access with the up and down button when you have the / on the commandline. So d/ and you can go through your previous searches. Which is nice if you have a search with a lot of regex.

## Repeat last search

Something else that is fun with / is that you can repeat the last search with //. Now this is probably completely useless right? I can just press n or N do the exact search again. True, but you can do it in other commands! So imagine that we have the text as above. Result might not be the best name for it so we want to change it to something else. We do /result<cr>, to see that we're hitting the correct things. (if you haven't done it, do :set hlsearch and you'll see exactly the words we hit). That looks fine, so we substitute out the meaningless name. :%s//shouldBeArray/<cr> and suddenly we've renamed it to something that that conveys more meaning.

## Ranges

Now you might be thinking "That last command is nice and all, but what happens if that is in the middle of a 5000 lines of code? I can't be held accountable for what happens with the other 4992 lines of code!". Well luckily you wont have to, you can use search to choose the range of lines that you want to hit!  :/result1/,/result8/s/<ctrl+r>//shouldBeArray/<cr> and your done. The ctrl+r / adds the last search into your command. But what happens if your code has multiple result1 or result8? Basically the same as when you do a normal search.  So from where your cursor currently is until you hit the first result1 and then until you hit the first result8 after result1. An interesting behaviour I found here is that if your doing the same command again a second time and you have 1 result1 above your current cursor it will still find your result1 and do the substitute and if for some reason result8 is before result1 it will ask you if you want to switch the backward range.

## Obvious(?) other uses of search and some tips

I mentioned briefly (very briefly) that / allows regexes. Regexes should be allowed its own article. But quick example would be to search for result1-8 in 1 go instead of just result. /result\d, /re.ult\d, /res\wlt\d f.ex. Read the manual and also checkout bash regexes, their super useful and remember that you can call shellcommands inside vim.

You can use :g/<search here>/d to delete all lines that contain pattern or you can use :v/<search here>/d to delete all lines that don't contain pattern. You can also use ranges on those 2 command and the ranges can use search. And don't get me started on what can come after v/.../ or g/.../ because I don't know that much about and would like someone to do an article or send me a message on irc to plitter in #vim explaining it in detail for me :)

After doing d/<search>, you can repeat it with dot.

After doing c/<search>, you can repeat it with dot.

I think you can begin to see a pattern where if the command changes text and accepts a motion you can repeat it with `.`. For example, a cheap substitute for:

```vim
:%s/foo/bar/gc
```

could actually be to do:

```vim
/foo<cr>cgnbar<Esc>
```

then `n` to get to the next match and `.` to repeat the change. See [`:help gn`][`:help-gn`].

\* and # searches the current word forwards and backwards respectively and you can use that as a substitute in :s//<something>/, :g//<something fancy>, c//, and d//.

I like to use `/` to move around or visually selecting. But when I've gotten to where I want to work I'll go to insert mode to insert text, change text with `ct;` (I usually come to where I want to assign a variable and remove the text from: `<text to remove>;`), or when I change a function signature I'll let my [quickfix list][quickfix-list] get populated with the problematic method calls, go to those locations, do `/something` to get to the offending parameter and follow up with any of the following:

* `df,x`,
* `d2w`,
* `dw.`,
* `d/<the next parameter>` to remove the parameter,
* `ct`,
* `c/<the next parameter>` to change the parameter,
* etc.

### Checkout the following manuals

- :help /
- :help c_CTRL-R
- :help :g
- :help :s
- :help search-offset
- :help cmdline-ranges


[:help-f]: #
[:help-t]: #
[:help-w]: #
[:help-/]: #
[:help-/]: #
[:help-/]: #

[//]: # ( Vim: set spell spelllang=en: )
[`:help-gn`]: #
[quickfix-list]: #
[moving-across-files]: #
[the-manual]: #
