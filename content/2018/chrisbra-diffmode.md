---
title: "The power of diff"
publishDate: 2018-12-01
date: 2018-12-01
draft: false
description: "Making Vim's diff mode more powerful and more flexible."
slug: "the-power-of-diff"
author:
  name: "Christian Brabandt"
  email: "cb@256bit.org"
  github: "chrisbra"
  picture: "https://i.imgur.com/HjSMLD9.png"
---

Lots of people use vimdiff to understand and handle diffs in console
mode. While there exist more specialized tools for comparing files,
vimdiff has always worked good enough for me.

## The inefficiency of the external diff

However, Vim's diff mode was seriously lacking. This was basically
because it needed to write down temporary files, shell out and run a
manual diff command and parse the result back and as one can imagine,
this could be slow and was seriously inefficient.

Additionally, this required to have a diff binary available that was
able to create [ed like style diffs][0], so one could not even fall-back
to using git-diff (which is considered to have one of the best tested
diff libraries and allows to select different algorithms) for creating
those diffs. This lead to the creation of vimscript [plugins][1], that
would internally translate a unified diff back into an ed-like diff. Of
course this would add an extra performance penalty.

In Windows land, this was also a pain, since Vim had to be distributed with
an extra diff binary, since Windows does not come with it out of the box
and one would notice the expansive diff call by an ugly command line
window flashing by whenever the diff needed to be updated.

Also, since the whole generation of diffs was so ugly, Vim would not
always refresh the diff on each and every modification to not slow down
too much, causing inaccurate diffs every once in a while.

And finally, before shelling out for the external diff command, Vim
would check **every time** that a diff is actually available by running
a hard coded diff against "line1" and "line2" buffer.

## Bundling an internal diff library with Vim

This problem was well known and can still be found in the well known
`todo.txt` file (`:h todo.txt`, search for diff). One problem why it
wasn't done earlier, was that there did not exist a good documented and
simple to use C library that could be used by Vim.

So I started working on how to improve this [situation][2] and decided
to go with the xdiff library which the git developers finally settled to
use. They basically had the same problem when the git vcs system was
developed by Linus Torvalds. Back in around 2006 they decided
to ship git with the [libxdiff][3] library, which over time got heavily
modified to fit better the needs of git.

The advantage of using the same library for Vim is that, for one, the
library has been tested and proven to be working well over the last
12 years. In addition, is has been tweaked and several new diff
algorithms have been added, like the [patience diff algorithm][4] and
[histogram diff algorithm][5] and the [indent-heuristics][6].

So with [Patch 8.1.360][7] the xdiff code from git has been finally
merged into Vim and allows for a much smoother and more efficient diff
experience in Vim. In addition, the internal diff algorithm has been
made the default, but one can still switch to the old external
algorithm, using:

```vim
:set diffopt-=internal
```

Also, Vim can now read and understand the [unified diff format][8]
(which seems to be the standard format nowadays), so even when the
bundled the diff library does not work well enough, one does not need to
translate the output back into a ed like diff format anymore.

## Some examples

By default, the diff library uses the myers algorithm (also known as
[longest common subsequence problem][9]). However, in certain
circumstances, one might want to use a different algorithm. One famous
example is for the patience algorithm.

### The patience algorithm

Say you have the following file1:

```c
#include <stdio.h>

// Frobs foo heartily
int frobnitz(int foo)
{
    int i;
    for(i = 0; i < 10; i++)
    {
        printf("Your answer is: ");
        printf("%d\n", foo);
    }
}

int fact(int n)
{
    if(n > 1)
    {
        return fact(n-1) * n;
    }
    return 1;
}

int main(int argc, char **argv)
{
    frobnitz(fact(10));
}
```

In addition you have the following changed file2 (e.g. from a later revision):

```c
#include <stdio.h>

int fib(int n)
{
    if(n > 2)
    {
        return fib(n-1) + fib(n-2);
    }
    return 1;
}

// Frobs foo heartily
int frobnitz(int foo)
{
    int i;
    for(i = 0; i < 10; i++)
    {
        printf("%d\n", foo);
    }
}

int main(int argc, char **argv)
{
    frobnitz(fib(10));
}
```

The default diff, running `$ vimdiff file1 file2` would then look like this:

![default diff](../chrisbra-diffmode/default_diff.png)

However, now you can simply do `:set diffopt+=algorithm:patience` and the
diff will change to the following:

![patience diff](../chrisbra-diffmode/histogram_diff.png)

Pretty nice, isn't it?

Here is an asciicast:

<script id="asciicast-YL035raOlEbadoWNLpj5cBXan" src="https://asciinema.org/a/YL035raOlEbadoWNLpj5cBXan.js" data-size="1.3vw" async></script>

### The indent heuristics

Here is an example where the indent heuristics might come handy. Say you have the following file:

```ruby
  def finalize(values)

    values.each do |v|
      v.finalize
    end
```

And later the file has been changed to the following:

```ruby
  def finalize(values)

    values.each do |v|
      v.prepare
    end

    values.each do |v|
      v.finalize
    end
```

The default diff, running `$ vimdiff file1.rb file2.rb` would then look like this:

![default ruby diff](../chrisbra-diffmode/ruby_default.png)

Now, type `:set diffopt+=indent-heuristic` and see how the diff changes to the following:

![indent-heuristic diff](../chrisbra-diffmode/ruby_indent_heuristics.png)

Now one can clearly see what part has been added.

That is pretty neat.

This is also available as an asciiast:

<script id="asciicast-QyIhLUUmwMdpzIjRhkdcPdUyx" src="https://asciinema.org/a/QyIhLUUmwMdpzIjRhkdcPdUyx.js" data-size="1.3vw" async></script>

## What is next

Having included the xdiff library this does not mean improving the diff
mode stops. There have been additional patches that fixed small bugs as
well as improved the diff mode further. For example the `DiffUpdate`
autocommand has been included in [Patch 8.1.397][10] which allows to run
commands once the diff mode has been updated.

In addition, there are already requests to provide a VimScript API for
creating diffs or update the diff more often. It should also be possible
to create better inline diffs.

That hasn't been done yet, but I am sure some of those improvements will
be developed in the future.


[0]: https://en.wikipedia.org/wiki/Diff#Edit_script
[1]: https://github.com/chrisbra/vim-diff-enhanced
[2]: https://github.com/vim/vim/pull/2732
[3]: http://www.xmailserver.org/xdiff-lib.html
[4]: https://bramcohen.livejournal.com/73318.html
[5]: https://stackoverflow.com/a/32367597/789222
[6]: https://hackernoon.com/whats-new-in-git-2-11-64860aea6c4f#892c
[7]: https://github.com/vim/vim/commit/e828b7621cf9065a3582be0c4dd1e0e846e335bf
[8]: https://en.wikipedia.org/wiki/Diff#Unified_format
[9]: https://en.wikipedia.org/wiki/Longest_common_subsequence_problem
[10]: https://github.com/vim/vim/releases/tag/v8.1.0397
