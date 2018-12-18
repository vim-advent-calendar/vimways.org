---
title: "Vim's social life"
publishDate: 2018-12-15
draft: true
description: "A story of flags and POSIX compatibility"
slug: "vims-social-life"
author:
    name: Justin M. Keyes
    email: justinkz@gmail.com
    github: justinmk
    twitter: justinmk
    site: http://justinmk.github.io/
---

Vim is a shell command, and its fast startup supports that use-case: shell
tasks, whether ad-hoc (interactive) or orchestrated (pipeline, script), are
cheap and thus frequent.

Yet Vim's startup story is relatively unpolished. Shell tools are expected to
consume standard input ("stdin") and emit to standard output ("stdout")—but
Vim supports this awkwardly, at best. The endeavor is never mentioned in Vim
tutorials (including the "Unix as IDE"
[hymnals](https://news.ycombinator.com/item?id=12653028)), and puzzled out of
Vim's documentation only by careful inspection.

Vim is positioned as a script host (VimL, `if_python`, …) , but not as
a participant. Yet Vim is a terminal tool, and terminal users expect their
tools to compose. Like this:

```bash
# Does not work!
$ printf 'a\nb\nc\nb\n' | vim +'g/b/norm gUUixx' +2 +'norm yy2p' | tr x z
```

Why doesn't that work? What can we do instead?


Let's talk about -s-ex
----------------------

The goal is to penetrate Vim with input, manipulate it non-interactively, and
produce output consumable by other shell tools.

Sending text input to Vim requires the explicit `-` file.

```bash
$ echo foo | vim -
```

Working non-interactively is less obvious. Vim's
[testsuite](https://github.com/vim/vim/tree/e751a5f531c1ceb58dacc7c280fdaae0df2c71c7/src/testdir)
does something like this:

```bash
$ vim -es -u NONE -U NONE -i NONE --noplugin -c ... -c "qall!"
```

But what is `-es`? Not merely the combination of `-e` and `-s`, it is a special
"silent mode" described at `:help -s-ex`:

```txt
Switches off most prompts.
...
The output of these commands is displayed (to stdout):
    :print
...
Initializations are skipped.
```

So `-es` does not draw the UI, and we can emit text to stdout using `:print`.

```bash
$ echo foo | vim - -es +'%p' +'qa!'
Vim: Reading from stdin...
foo
```

`:%p` prints the entire buffer and `:qa!` ensures that Vim quits. In Vim
version 8, that "Vim: Reading from stdin..." message can be avoided with
`--not-a-term`.

Note that `-es` and `-se` are not equivalent, the Vim
[parser](https://github.com/vim/vim/blob/d47d52232bf21036c5c89081458be7eaf2630d24/src/main.c#L2156)
quite literally expects `-e` to precede `-s`:

```bash
$ echo foo | vim - -se +'%p' +'qa!'
Garbage after option argument: "-se"
```

A similar order-sensitivity befalls the `-` file argument: `vim - -es` behaves
differently than `vim -es -`!  The former consumes stdin as text, while the
latter activates stdin as Ex commands.

If you run into trouble, use `-V1` to reveal why `-e` isn't working:

```bash
$ printf 'foo\n' | vim -es
# No output. Non-zero error code.
echo $?
1
```

```bash
$ printf 'foo\n' | vim -es -V1
Entering Ex mode.  Type "visual" to go to Normal mode.
:foo
E492: Not an editor command: foo
```

So now we can light up our tinsel:

```bash
$ printf 'a\nb\nc\nb\n' | vim - -es --not-a-term +'g/b/norm gUUixx' +2 +'norm yy2p' '+%p' '+qa!' | tr x z
a
zzB
zzB
zzB
c
zzB
```

Yay! We did it. Wait, you're going home already...?


Ugly sweater party
------------------

Apparently Vim thought this was an ugly sweater party. Vim's sweater has `-`
and `Reading from stdin...` and forty-four `--help` options. Let's learn more
about Vim before seating it next to Grandpa vi.

Input at startup can take these forms:

- user ("keyboard") input
- Ex commands
- text

By default, even in non-interactive mode (`-es`) Vim treats input as
"commands". That's a tradition from Grandpa vi. Note that "commands" in vi
parlance means general _user-input_ (starting from Normal-mode).

With `-e` (and `-es`) Vim treats input as Ex commands: those entered at the `:`
prompt, or "statements" in Vim script.

```bash
$ printf "put ='foo'\n%%s/o/X\n%%print\n" | vim -es

fXo
```

Finally the `-` file tells Vim to slurp input as plain text into a buffer. Then
commands can be given with `-c` or `--cmd`.

There's another thing I want to announce at the dinner table: if you specify
the `-` file, then other _file arguments_ are not allowed. `:help vim-arguments`
characterizes these independent "editing ways":

> Exactly one out of the following five items may be used to choose how to start editing:

Should you try to invoke multiple "editing ways", Vim will leave the table. For
example, asking Vim to read both `-` and `a.txt` is asking too much:

```bash
$ echo foo | vim - -es --not-a-term '+%p' a.txt
Too many edit arguments: "a.txt"
```


Santa POS is coming to town
---------------------------

Gathering from the
[POSIX vi specification](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/vi.html)
we find these directives regarding non-interactive ("not a terminal") cases:

> Historically, vi exited immediately if the standard input was **not a terminal**. ...
>
> If standard input is **not a terminal** device, the results are undefined. The
> standard input consists of a series of commands and input text, ...
>
> If a read from the standard input returns an error, or if the editor detects
> an end-of-file condition from the standard input, it shall be equivalent to
> a SIGHUP

- Input is always interpreted as user input, even if non-interactive.

- When stdout is not a terminal, Vim may behave as it likes ("undefined").

- EOF (that is, closed input stream) means quit.

POSIX conspicuously omits the `-e` and `-s` startup options (and `-es`,
which is not merely the composition of the two!).
[Traditional vi](http://ex-vi.sourceforge.net/vi.html) lacks `-e`, but
[nvi](https://www.freebsd.org/cgi/man.cgi?query=nvi) implements both and calls
out POSIX's incongruence with "historical ex/vi practice".

We've uncovered the origin of Vim's eagerness to consume stdin as something
live (commands) instead of something inert (text): 'twas always done that way.

```bash
$ echo foo | vim
Vim: Warning: Input is not from a terminal
Vim: Error reading input, exiting...
Vim: Finished.
```

Vim must warn about stdin-as-commands because (1) it's potentially destructive
and (2) it's almost always accidental (does anyone actually use this feature?).

Vim exits after stdin EOF, as prescribed by POSIX. (Party trick: convince it to
keep running by sending the input to `-s`: `vim -s <(echo ifoo)`.)

POSIX does not mention `-E`, a variant of `-e` ignored by Vim's own testsuite.
`-e` invokes
[getexmodeline](https://github.com/vim/vim/blob/d47d52232bf21036c5c89081458be7eaf2630d24/src/ex_getln.c#L2731)
whereas `-E` invokes
[getexline](https://github.com/vim/vim/blob/d47d52232bf21036c5c89081458be7eaf2630d24/src/ex_getln.c#L2713).
The distinction is not useful, and in Nvim they both invoke `getexline`.


## Under the tree: Neovim

[Neovim](https://neovim.io/) version 0.3.1 features some
[improvements](https://github.com/neovim/neovim/pull/7679) to the workflow
described above. The [documentation](https://neovim.io/doc/user/starting.html#-es)
and manpage were rewritten.

Nvim now treats non-terminal stdin as plain text _by default_ (the explicit `-`
file is not needed):

```bash
$ echo foo | nvim
```

That means Nvim never pauses for two seconds to display a warning (because
stdin is not executed). Nvim also allows multiple "editing ways":

```bash
$ echo foo | nvim file1.txt file2.txt
```

It also works with `-Es` (but not `-es`), and it exits automatically (no
`+'qa!'` needed):

```bash
$ echo foo | nvim -Es +"%p"
```

If you ever _want_ to execute stdin-as-commands, use `-s -`:

```bash
$ echo ifoo | nvim -s -
```

With these improvements it's now possible to use `nvim -es` as one might use
`python -c` or `perl -e`. For example, I use it in my `.bashrc` to configure
the shell depending on the Nvim version:

```bash
if nvim -es +'if has("nvim-0.3.2")|0cq|else|1cq|endif' ; then
  ...
fi
```


## Eggnog

The mechanisms and ergonomics for delivering data to Vim at invocation-time are
essentially unchanged from vi—owing, yes, to deference to
[POSIX vi](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/vi.html)
and our old friend backwards compatibility—but perhaps primarly to intertia.

It turns out that very few people actually care about the traditional behavior:
the precise behavior of `-es`, for example, was broken in Nvim for years but no
one complained. And Vim's own codebase (including testsuite) does not use `-E`.
If no one uses a feature, it might be ok to change it.

Merry Textmas! This holiday, when you're with your loved ones, think of Vim.
