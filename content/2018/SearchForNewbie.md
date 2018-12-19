# Newbie search usage in VIM
Now that we've seen moving across files I think it is time to get back to the
current buffer and see what is possible there as well. 

One thing that is consistent when you want to move from beginning newbie to
not-so-much newbie is when you start to realize that hjkl is not the most
efficient way to move around, holding w/b is not the most efficient way either.
Personally I don't think counting the number of words to get to the correct
place is any efficient either. To take an example where I use ^ as indicator
for the cursor position.

```
String result = new String(anotherString + "hello");
^
```

What count do you need to for w to get to hello? The answer might surprise
someone who haven't thought about it before. Go ahead, I'll wait.

Ok, so we have all come to the conclusion of 9w to get to hello? Vim has the
interestingly chosen that =, ()  + and " is a start of a new word. Adding 4 
more to our count. Which makes it hard to get correctly and there isn't a do
again command for [count]w. Also what about when you have this 
⬇️ and you want to move to apply.

```
var oldUnload = window.onbeforeunload;
^
window.onbeforeunload = function() {
    saveCoverage();
    if (oldUnload) {
        return oldUnload.apply(this, arguments);
    }
};
```

should you count/use relativenumbers to get down 4 lines, then 4w to get to
apply? There is a better way and it is simply to search it. You look at where
you want to go, press / and start typing the word. To make this more
userfriendly, we want to see where we would end up if we pressed enter now.
So we put in :set incsearch and try our previous example. /ap<cr>, 4 keypresses
and we knew at the 3 keypress that we had hit the correct spot. This is the
closest I've come to point and click, and it is super fast. I'm sorry for all
you scandinavians and germans out there that has the / at the shift+7. Most other keyboard
layouts this is right next to the right shift key. Obviously there is also the
dvorak programmer masterrace *cough cough* that has the / right next to the
right pinkie (normal 'Å').

Sorry back to Vim. 

#/ is one of the supreme features (IMHO)
Imagine that you have
```
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
Obviously you don't need result2 - 8. So one easy way to do it is to just hold
the d and after a while it will all be deleted. But as vimmers we should try to
do most things in 1 go, since it is easier to undo or put somewhere.
One fun and intuitive way is to use the visual mode. V/8<cr> and you have marked
all the lines that you want to delete and you can press x knowing that this is
exactly what you wanted. A more direct approach could be to do d/8<cr>dd, but
this is not removing everything at once. Luckily we can just search again in
the same query! So d/8/;/;/e<cr> and you have done exactly what you want. Let's
break that one down

- **d** accepts a motion and luckily / is a motion 
- **/8** normal search for 8
- **/** the / shows that it should put in an offset here 
- **;** shows that the next part is a new search
- **/;** searches for the next ;
- **/e** instead of being at the start of the match, be at the end

Another fun thing to illustrate a point, rather than being a good vimmer, is that
you can do d/result/;//;//;//;//;//;//;/;/e at that spot and you will delete
the same. 

For more information checkout help /. And especially checkout the offset.

# Repeat last search
Something else that is fun with / is that you can repeat the last search with
//. Now this is probably completely useless right? I can just press n or N do
the exact search again. True, but you can do it in other commands! So imagine
that we have the text as above. Result might not be the best name for it so we
want to change it to something else. We do /result<cr>, to see that we're
hitting the correct things. (if you haven't done it, do :set hlsearch and
you'll see exactly the words we hit). That looks fine, so we substitute out the
meaningless name. :%s//shouldBeArray/<cr> and suddenly we've renamed it to 
something that that conveys more meaning. 

# Ranges
Now you might be thinking "That last command is nice and all, but what happens
if that is in the middle of a 5000 lines of code? I can't be held accountable
for what happens with the other 4992 lines of code!". Well luckily you wont
have to, you can use search to choose the range of lines that you want to hit!
:/result1/,/result8/s/<ctrl+r>//shouldBeArray/<cr> and your done. The ctrl+r
/ adds the last search into your command. But what happens if your code has
multiple result1 or result8? Basically the same as when you do a normal search.
So from where your cursor currently is until you hit the first result1 and then
until you hit the first result8 after result1. An interesting behaviour I found
here is that if your doing the same command again a second time and you have
1 result1 above your current cursor it will still find your result1 and do the
substitute and if for some reason result8 is before result1 it will ask you if
you want to switch the backward range.

# Obvious(?) other uses of search and some tips
Obviously we can use regex in the search, which is nice and all, but regexes
ain't really a part of what I want to highlight. Regexes deserve their own
article. 

You can use :g/<search here>/d to delete all lines that contain pattern or you
can use :v/<search here>/d to delete all lines that don't contain pattern. You
can also use ranges on those 2 command and the ranges can use search. And don't
get me started on what can come after v/.../ or g/.../ because I don't know
that much about and would like someone to do an article or send me a message on
irc to plitter in #vim explaining it in detail for me :)

After doing the d/<search>, you can repeat it with dot. 

After doing the c/<search>, you can repeat it with dot.

I think you can begin to see a pattern where if the command changes text and
accepts a motion you can repeat it with dot. A cheap substitute for
:%s/foo/bar/gc is actually to do /foo<cr>cwbar then n to get to the next match
and dot to repeat the change. 

\* and # searches the current word forwards and backwards respectively and you
can use that as a substitute in :s//<something>/, :g//<something fancy>, c//, 
and d//. 

# Checkout the following manuals
- :help /
- :help c_CTRL-R
- :help :g
- :help :s
- :help search-offset
- :help cmdline-ranges
