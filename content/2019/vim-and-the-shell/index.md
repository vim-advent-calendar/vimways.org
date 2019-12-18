---
title: "Vim Filters, External Commands, And The Shell"
publishDate: 2019-12-01
draft: true
description: "Vim is not an isolated tool. It is designed to work with external programs."
author:
  email: "pabloariasal@gmail.com"
  github: "pabloariasal"
  homepage: "https://pabloariasal.github.io"
  irc: "username"
  name: "Pablo Arias"
  picture: "https://example.com/username.jpg"
  twitter: "@pabloariasal"
---

> Don't love me, flaco. Love your mom. I just play football.
>
> – Juan Roman Riquelme

There is a day in the life of a man when he realizes that the traditional way of using a computer is flawed, that graphical interfaces were a bad idea, that the mouse is an absurd invention, that a life away from the home row is not a life worth living.

The UNIX philosophy becomes a religion when you are hit with the realization that best solutions are not provided by gigantic almighty monoliths, but are the joint effort of several minimal, highly specialized components. Each solves one part of the problem, just one, but solves it well.

In this post I'll explore the idea that Vim is not meant to be a universal answer to all problems, but rather just another member of the toolbox, perfectly integrated with other programs and the underlying shell. Vim's built-in interaction capabilities with external commands allow for very interesting synergies. Interplays that become particularly powerful in conjunction with advanced text processing utilities and filters.

# Command Line Text Processing

```text
$ cat fruits.txt
oranges 5
apples 7
blueberries 15
bananas 4
ananas 6
```

There are endless possibilities when it comes to fruit lists. For example, you can format them as a table:

```text
$ cat fruits.txt | column -t
oranges      5
apples       7
blueberries  15
bananas      4
ananas       6
```

sort them by quantity:

```text
$ cat fruits.txt | column -t | sort -nrk 2
blueberries  15
apples       7
ananas       6
oranges      5
bananas      4
```

or, print how many fruits there are in total:

```text
$ cat fruits.txt | awk '{sum += $2} END { print sum }'
37
```

You can filter and transform text in virtually any way using the command line, you can remove duplicate lines with the absolute poetry of a command `awk '!visited[$0]++'` [(for the curious)](https://opensource.com/article/19/10/remove-duplicate-lines-files-awk), change curly braces to parenthesizes with `tr '{}' '()'`, or delete the first three characters in each line with `cut -c3-`.

The point is, command line text processing is *powerful*. It's hard to describe the beauty of executing a chain of commands and watching it, pipe after pipe, transform your text like a perfect symphony of streams; the magic of doing so much work with so little keystrokes. The fact, however, that you are a Vim user makes me believe that you know this feeling very well.

Talking about Vim, wouldn't it be awesome if you could use advanced text processing tools, like `awk`, `tr`, `jq`, `bc`, as you edit your Vim buffer?
It probably doesn't come as a surprise to you when I tell you that that in fact, you can.

## The Big Bang

Vim integrates smoothly with external programs, the underlying shell, and the system. Specifically, you can execute commands from Vim, read the standard output of a command into your buffer, and use your buffer (or parts of it) as standard input to a shell program.

In Vim, the bang (`!`) symbol is used to interact with external commands.

### Executing External Programs from Vim

For example, you can run a shell program directly from Vim's command line with:

```vim
:!{cmd}
```
This will show the standard output of __cmd__ in the command line, at the bottom of the Vim window ([`:h !:cmd`][bang]).

But boy, we are just getting started. You can use the bang in conjunction with the `:read` and `:write` commands to read from and write to external shell program executions.

### Reading the Output of a Command Into Your Buffer

For example, using 

```vim
:read !{cmd}
```

will execute __cmd__ and insert its standard output into your buffer below the cursor. You can also specify a range to indicate where the output of __cmd__ should be inserted:

```vim
:3read !curl --silent ifconfig.me
```

Will insert your public IP address at line 3 ([`:h read!`][read]).

### Using Your Buffer as Input to a Command

The other way works, too, you can execute a program with contents of your buffer as input:

```vim
:[range]write !{cmd}
```

will use the lines specified by __range__ (or the whole buffer if not provided) as standard input to __cmd__ and display its standard output below your Vim window.
[`:h w_c`][write]

For example, if you want to execute the selected lines with the python interpreter you can do:

```vim
:'<,'>write !python
```

# Filters

Using the bang with `read` and `write` is handy, but what if you want to do both things: use a range as input to a command and _replace_ it with the command's standard output?
This works too! This is called a *filter* and builds the basis of command line text processing: input some text, transform it (format, sort, etc.) and output the transformed version.

Filters have the following standard form:

```vim
:{range}!{filter}
```

The above call will take the lines specified by __range__ and replace them with the output of __filter__ ([`:h :!`][filter]).

While editing our fruit inventory, we could do the following directly from Vim's command line:

```text
oranges 5
apples 7
blueberries 15
bananas 4
ananas 6

:%! sort -nrk 2 | column -t
```

This replaces the entire buffer with a sorted [^1] and formatted version of it:

```text
blueberries  15
apples       7
ananas       6
oranges      5
bananas      4
```
### Normal Mode Bindings

Vim filters are so useful that there is a normal mode binding for filtering lines through external programs, you guessed it, the bang!

```vim
!{motion}
```

Typing `!` in normal mode, followed by a motion (like `!4j`) will populate Vim's command line with a range corresponding to the given motion:
([`:h !`][bang_normal])

```vim
:.,.+4!{filter}
```

Following a common pattern among Vim commands, `!!` will filter the current line:

```vim
:.! {filter}
```
You can then type a filter command like `cowsay`, which will filter the specified range and replace it with:

```
 ________________________________________ 
/ I'd just like to interject for a       \
| moment. What you're referring to as    |
| Linux, is in fact, GNU/Linux, or as    |
| I've recently taken to calling it, GNU |
| plus Linux. Linux is not an operating  |
| system unto itself, but rather another |
| free component of a fully functioning  |
| GNU system made useful by the GNU      |
| corelibs, shell utilities and vital    |
| system components comprising a full OS |
\ as defined by POSIX.                   /
 ---------------------------------------- 
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

or create fancy ascii art with `figlet`

```
  ____ _______        __  ___                       _             _     
 | __ )_   _\ \      / / |_ _|  _   _ ___  ___     / \   _ __ ___| |__  
 |  _ \ | |  \ \ /\ / /   | |  | | | / __|/ _ \   / _ \ | '__/ __| '_ \ 
 | |_) || |   \ V  V /    | |  | |_| \__ \  __/  / ___ \| | | (__| | | |
 |____/ |_|    \_/\_/    |___|  \__,_|___/\___| /_/   \_\_|  \___|_| |_|
                                                                        
                                                
```

## That's All Folks

Even when Vim is the superstar striker of your team, you shouldn't play him as a goalkeeper. Your computer is an ecosystem of powerful tools that are designed to work with each other. Each does one thing, and does it well.

Your compiler, debugger, linker, editor, formatter, version control system, they all play together as a unit, as a family, as a team. Your team. Learn your players and most importantly find effective ways of combining their strengths. Use your editor for what it is best for: edit text.

Some ask themselves how people like me can code without an IDE, missing on all those awesome features. Little do they know we use the most powerful IDE there is: the system.

[^1]: for sorting structured text, take a look at Vim's built-in sorting ([`:h sorting`][sorting])

[bang]: http://vimdoc.sourceforge.net/htmldoc/various.html#:!cmd
[read]: http://vimdoc.sourceforge.net/htmldoc/insert.html#:read!
[write]: http://vimdoc.sourceforge.net/htmldoc/editing.html#:w_c
[filter]: http://vimdoc.sourceforge.net/htmldoc/change.html#!
[bang_normal]: http://vimdoc.sourceforge.net/htmldoc/change.html#!
[sorting]: http://vimdoc.sourceforge.net/htmldoc/change.html#sorting
