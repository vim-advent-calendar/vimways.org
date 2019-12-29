---
title: "A Test to Attest To"
publishDate: 2020-01-01
draft: true
description: "Testing complex Vim plugins without using Vim plugins"
author:
  dotfiles: "https://github.com/puremourning/.vim-mac"
  github: "puremourning"
  gitlab: "puremourning"
  freenode: "puremouring"
  name: "Ben Jackson"
  picture: "https://s.gravatar.com/avatar/a16c0086b4646b1ac0bf6002134a6965?s=80"
  twitter: "@puremouron"
---

> "Regression testing"? What's that? If it compiles, it is good; if it boots up,
> it is perfect.
>
> – Linus Torvalds, [linux-kernel mailing list, April 1998][linus-quote]

## System under test

First, let's get this out of the way: this is not an article about testing. I'm
not going to tell you why you should or should not test things (hint: you
should) or how you should do it (hint: integration testing is always better than
unit testing), what you should test (hint: everything) or what colour socks you
should wear when you install the JavaScript testing framework that was just
released on the latest social network (hint: _purple_ ***always purple***).

No, this article is about Vim and Vim scripting. Arguably, it's about advanced
Vim scripting, but ultimately it's about Vim.

We're going to talk about how you can use Vim to test your Vim plugins without
using other Vim plugins. In particular, we're going to focus on one of the
things that's _difficult_ to test: insert-mode completion. I've picked this for
a few reasons:

1. It's something that, as far as I know, no existing Vim testing "framework"
   makes easy.
2. As the maintainer of a popular autocompletion plugin, this is an area with
   which I have [some experience][ycm-tests].
3. It's interesting. At least, it's interesting to people like me. Make of that
   what you will.

While I will talk about the vim [`assert_*()` functions][h-test-functions] and
other built-in testing primitives, I'm not going to repeat what you can read in
[`:help testing.txt`][h-testing].

Hopefully the details (or if I may be so bold, lessons) presented here will
provide some insight into somewhat advanced Vim usage and scripting.

### Should you read this

Probably not. But if you've got this far, you're probably one of the following:

* An existing Vim aficionado, looking to pick holes in my article (thanks!)
* A plugin author looking to find out how to use core Vim functions to test your
  own plugin(s).
* An intermediate or advanced Vim user who is curious about different Vim script
  use cases
* A beginner Vim user who would like to take a look at "how the sausages are
  made"

You're probably not:

* A regular Vim user who doesn't care too much about fiddly details
* Looking for a new cool plugin for a new cool JavaScript framework
* Looking for some new mappings to paste in your `vimrc`

## Apparatus

So, to get started, let's review what we need to start testing our plugin. A lot
of you will probably google `vim testing framework` at this point, and you might
find something that works. I didn't, so I asked myself one question "What does
Vim use to test Vim?".

And the answer, simply, is Vim.

In order to test our Vim plugin (and indeed, Vim itself), we need the following:

* Vim
* Something to test

I'm assuming you have the former, and I've put together a [very simple
completion plugin][test-plugin] which we'll be testing. The test plugin just
implements the 'months completion' example from [`:help
complete-functions`][h-complete-functions] in 2 ways:

* Synchronously: `attest#CompleteSimple` performs a simple insert-mode
  completion and returns the results
* Asynchronously: `attest#CompleteAsync` does the same, but after a delay (using
  a timer)

If you'd like to follow along and play with the examples, you can check out the
example code in any directory you like:

```
$ cd /some/path
$ git clone https://github.com/puremourning/a-test-to-attest-to.git
```

### Environment

I'm sorry but all the examples here assume you're running on Unix-like OS
(Linux, macOS, etc.). While everything here applies equally to Windows, and any
other OS that Vim runs on, the examples of running tests will assume a
Bourne-like shell. You can adapt this to your operating system of choice at your
own leisure.

## Testing our plugin manually

First things first, we need to work out what we need to do to test this plugin.
Naively, we might just:

* Sync the plugin to our [`pack/attest/start/attest`][h-packages] directory
* Run `vim test_file`
* Set the [`completefunc`][h-completefunc] for [user-defined
  completion][h-compl-function]
* Type something, and trigger completion with [`<C-x><C-u>`][h-compl-function]
* Check that the correct months are returned
* Repeat for both `completefunc=attest#CompleteSimple` and
  `attest#CompleteAsync`.

## Isolation

But there's a problem: our test is not _isolated_. It's actually being affected
by a number of things, but most importantly any _existing_ `vimrc` or other Vim
configuration in your user account, system, distribution, etc.

While I promised to not preach about how to test, this point is important: tests
should be isolated, idempotent and minimal. They should not rely on any external
environmental configuration (unless that's part of the test suite) and should
leave the system clean after they have run.

So how do we isolate our test? Well, fortunately Vim has a command line option
to start in a `clean` way. By clean, we mean with it's default configuration:

```
$ vim --clean
```

We'll be using this, but for the record, there's and _even cleaner_ way to start
Vim, with _no_ configuration or initialisation scripts:

```
$ vim -Nu NONE
```

So, there we have it:

* Sync the plugin to our [`pack/attest/start/attest`][h-packages] directory
* Run `vim --clean test_file`
* Set the [`completefunc`][h-completefunc] for [user-defined
  completion][h-compl-function]
* Type something, and trigger completion with [`<C-x><C-u>`][h-compl-function]
* Check that the correct months are returned
* Repeat for both `completefunc=attest#CompleteSimple` and
  `attest#CompleteAsync`.

## Repeatability

There's another problem. You probably worked this one out. The test is too
manual. Even if we ignore the manual entering, triggering and checking, we're
doing a bunch of setup code manually. We should really have the setup code done
automatically, so that our isolation can be used to ensure consistency and
simplicity of our test runs.

A nice way to do this is to provide a `vimrc`-like script to set up the test
environment. Recall that we need to set:

* The package path (or runtime path)
* The `completefunc`, which needs to differ according to which mode we're
  testing

A very simple way to do this is to create 2 simple files:

* [A setup script for simple testing][setup-simple]
* [A setup script for async testing][setup-async]

Here's the meat of the simple one (the async one is almost identical):

```vim
let &rtp .= ',' .expand( "<sfile>:p:h:h:h" )
set completefunc=atest#CompleteSimple
```

This adds the root path of the plugin (the parent of the parent of the parent of
the path to the script!) to the [`runtimepath`][h-rtp], then sets `completefunc`
to our simple function.

So how to use this? Well, enter more Vim command line options. The [`-S`
option][h-minus-S] tells Vim to source the argument after all initialisation has
completed. Neat.

This small change allows us to drastically simplify our test instructions.

* Sync the plugin to any directory you like
* Run `vim --clean -S support/test/test_simple.vim test_file`
* Type something, and trigger completion with [`<C-x><C-u>`][h-compl-function]
* Check that the correct months are returned
* Repeat for both `test/support/test_simple.vim` and
  `test/support/test_async.vim`.

But we're not done. Not by a long way.

## Formalisation

Now that we've got the boilerplate setup out of the way, let's have a think
about how our actual test can be automated. This is, of course, the meat and
vegetables of testing in practice; "frameworks" such as the above initialisation
scripts are written once and only changed when needed, whereas most time is
spent writing actual tests that actually validate quality and correctness.

So what did we do manually? Well we just sort of typed some stuff and checked it
was right. We can't automate _that_ (yet?), so we need to formalise our test
cases.

But first, let's take a look at what the plugin does so our test cases make
sense. For those not familiar, [insert mode completion][h-complete-functions]
is done in two stages:

1. **FindStart:** Vim asks you to find the start column for the completion.
   Usually this is the start of the current word, but might be anything
   depending on the file type.  (examples: after `attest#` for Vim, after
   `astruct.` for C, etc.)
2. **Complete:** Then, it calls you again passing the 'query' (the bit between
   the start column and the cursor) and asking you to return the matching
   completion items (examples: `Compl` in `attest#Compl` for Vim, `memb` in
   `astruct.memb` for C, etc.)

The entire test plugin completion code, split into the 2 stages, is as follows:

```vim
function! s:FindStart() abort
  " locate the start of the word (stage 1)
  let line = getline('.')
  let start = col('.') - 1
  while start > 0 && line[start - 1] =~ '\a'
    let start -= 1
  endwhile
  return start
endfunction

function! s:CompleteMonth( base ) abort
  " find months matching with "a:base" (stage 2)
  let res = []
  for m in split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec")
    if m =~ '^' . a:base
      call add(res, m)
    endif
  endfor
  return res
endfunction
```

In stage 1, we just look backwards from the cursor for the first
non-alphabetical character and return that as our start column. In stage 2 we
attempt to match the 'query' (`a:base`) against the months of the Gregorian
calendar. This example code is from Vim help; don't shoot the messenger.

We'll talk about the asynchronous completion later, but for the synchronous
version, the actual `completefunc` is trivial:

```vim
" See :help complete-functions
function! attest#CompleteSimple( findstart, base ) abort
  if a:findstart
    return s:FindStart()
  else
    return s:CompleteMonth( a:base )
  endif
endfunction
```

So we can formulate some simple test cases:

* When the word before the cursor is empty, all months are presented in the
  popup menu, and `Jan` is inserted (the first month).
* When the word before the cursor is `F`, `Feb` is inserted and there is no
  popup menu.
* When the word before the cursor is `M`, months `Mar` and `May` are
  presented, and `Mar` is inserted.

Therefore we can formalise our test "script" as follows:

* Sync the plugin to any directory you like
* Run `vim --clean -S support/test/test_simple.vim`
* Type `i<C-x><C-u>`. Expect the buffer to contain `Jan` and a popup menu with
  the following contents:
    * "Jan"
    * "Feb"
    * "Mar"
    * ... etc. you get the point
* Type `<Esc>:%bwipe!<CR>` to clear out the buffer
* Type `iF<C-x><C-u>`. Expect the buffer to contain `Feb`
* Type `<Esc>:%bwipe!<CR>` to clear out the buffer
* Type `iM<C-x><C-u>`. Expect the buffer to contain `Mar` and a popup menu with
  the following contents:
    * "Mar"
    * "May"
* Repeat for both `test/support/test_simple.vim` and
  `test/support/test_async.vim`.

Of course there are tons more cases to test, but this should do for now.

At this point, if you're following along at home, satisfy yourself that the
completion plugin works by following those test instructions. Next we'll need
to automate them, so it makes sense to be familiar with what will happen.

## Automation

Finally, this is the part where we answer the question "How can I test my Vim
plugin with pure Vim?". Yes, the question you were told you asked at the
beginning of the article.

Of course this is not a straightforward answer. Let's take it bit-by bit.

## Automating typing with feedkeys

It may not be obvious, but the best way to test the user typing some commands is
to actually tell Vim to pretend that's exacty what happened. 

There are ways to _actually_ enter text by running Vim in another terminal and
sending keypresses to that terminal, but we're not going to cover that here.
We're going to be using [`feedkeys()`][h-feedkeys].

Taking a look at the help for `feedkeys()` can be a little overwhelming, but
fear not, I've read it enough times to have a vague understanding of it. I've
also [stepped through the Vim code with Vimspector][vimspector-vim]
to understand exactly what's going on.

### How Vim works

As a terminal application, Vim is essentially a main loop a bit like this
pseudocode:

```c
extern char *input_buffer;
int input_len = 0;
while (!finished) {
  input_buffer[ input_len++ ] = read_character_from_standard_input();
  expand_mappings_in_buffer( &input_buffer, &input_len )
  if ( have_command_in_buffer( input_buffer ) ) {
    handle_command_in_buffer( &input_buffer, &input_len );
  }
}
```

That is, read characters into a buffer until you know what to do, then do it.
(Disclaimer: It's a tad more complex than that, but suffice to say
there is a buffer of characters to be processed, which can contain commands made
up of sequences of characters and that some sequences of characters can be
expanded into some _other_ sequence of characters).

### How feedkeys works

Intuitively, `feedkeys()` pushes characters into the input buffer. This
effectively tells Vim to execute as if the pushed characters were entered. But
there are a few things you need to know:

* To enter special characters, like `<C-x>`, you must use double quotes `"` and
  a backslash `\` before the `<`, as in `feedkeys( "\<C-x>" )`
* By default, `feedkeys()` treats characters like the _rhs_ of a mapping
* By default, `feedkeys()` just puts things in the queue, but doesn't actually
  execute them
* By default, if you wait for keys to be executed, `feedkeys()` ends insert mode
  (if it is active) when it returns, as if the command ended with `<Esc>`.
* By default, `feedkeys()` expands mappings in the input (like `:map` rather
  than `:noremap`)

### How feedkeys can work for us

Less intuitively perhaps, characters pushed by `feedkeys()` are treated by
default as if they come from a mapping, _not_ as if they were entered _by the
user_. What does this mean? Well if you've ever written a Vim _mapping_ it might
make sense to you. A mapping is a sequence of characters in the input buffer
(the _lhs_) which is _replaced by_ the characters on the other side (the _rhs_)
of the mapping. What the user typed was the _lhs_ of the _mapping_, but what
actually executes is the _rhs_.  Importantly, things like undo, folding,
etc. are treated according to the _lhs_ not the _rhs_.

We're interested in testing _what the user types_, so we want to change that.
That's easy; we pass the `t` flag in the second argument to `feedkeys()`. This
leads to the First Rule of Testing With `feedkeys`:

> When testing, we (almost) always pass the `t` flag to
> `feedkeys()` to make it as if the _user_ entered the keys themselves.

More surprisingly, and less usefully for testing, `feedkeys()` returns after
having put the characters in the buffer, but _before_ the input buffer has
actually been read and executed. This means that if you use it for testing, your
test will finish, but it won't have actually done anything yet. Doh! Again,
there's a simple Rule:

> When testing, we (almost) always pass the `x` flag to
> `feedkeys()` to make Vim keep executing until the input buffer is empty.

We'll look at this more later, but it's also important to realise that if
`feedkeys( '...', 'x' )` would leave Vim in insert mode, it acts as if the
command were `feedkeys( "...\<Esc>", 'x' )`. Again this is easily avoided, but
has some serious implications for the test:

> When testing insert-mode functionality, we _sometimes_ need to tell Vim to
> stay in insert mode after `feedkeys`. We pass the `!` flag to `feedkeys` for
> this, and **we always use `feedkeys( "\<Esc>" )` in another callback** to
> ensure we actually quit insert mode.

And finally, as we usually want to test what happens when the _user typed
something_ we almost _always_ want mappings in the input string to be expanded.
This is the default, but it pays to reiterate:

> When testing user typed commands, we _never_ pass the `n` flag to `feedkeys()`
> so that mappings are applied to the input buffer.

Phew. That was a lot of detail about `feedkeys`.  But trust me, **this is the
number 1 thing to understand**. If you take nothing else from this article, this
is the section to try and retain; if you can successfully wield `feedkeys()`,
you can write tests that behave the way your users will actually experience.

Let's put this to use, going all the way back to our very first test case. For
now, while we learn the ropes, let's ignore testing the popup menu, and just
check the buffer contents. This actually lets us test a large amount of our
plugin functionality.

So, our test case is:

* Type `i<C-x><C-u><Esc>`. Expect the buffer to contain `Jan`.

We need to translate that to some vimscript. Based on what we know now about
`feedkeys()`, it's a piece of cake:

```vim
call feedkeys( "i\<C-x>\<C-u>", 'xt' )
```

Due to the `x` flag, this call will:

* Enter insert mode: `i`
* Trigger user-defined completion: `<C-x><C-u>`
* Exit insert-mode (implicitly due to use of `x` flag without `!` flag)

Tada! You just automated typing. Now, let's check if it did what we expect.

## Validating results 

After all that detail, the following sections are going to feel very light and
breezy. That's good; it means you've pretty much done all the mental heavy
lifting required in this article and you're now on the downhill section towards
a well-deserved cup of java.

Recall that we're trying to implement the following minimal test case:

* Type `i<C-x><C-u><Esc>`. Expect the buffer to contain `Jan`.

We've covered the first part, and we now need to deal with the second part. This
involves:

* Getting the current buffer contents (line contents, whatever)
* Asserting that they match what we expect

The first is super easy: [`getline( 1 )`][h-getline] does the trick. There are
tons of other ways to inspect buffer contents in vimscript, and I won't list
them. The more interesting part for the purposes of this article are how to
assert matching values.

By now you've probably worked out that there's
[`assert_equal()`][h-assert-equal] which is what we want:

```vim
call feedkeys( "i\<C-x>\<C-u>", 'xt' )
call assert_equal( 'Jan', getline( 1 ) )
```

But that's not all we need. Let's take a minute to talk about how the `assert_`
functions work in Vim and what that means for testing.

### Assertions and v:errors

The way assertions work in Vim is a little unusual and might not be immediately
intuitive to people familiar with other testing tools. First and foremost, the
`assert_*()` functions **do NOT throw an error if the assertion fails**. That
means that even if an assertion fails, your script will continue executing. 

So what do the `assert_*` functions do when they fail? Well, they return `0` and
add reports to the special `v:errors` list.

That is:

> A test is considered to have failed if `v:errors` is a non-empty list.

Let's explore the other sources of "failure" too.

### Exceptions and tracebacks

Errors and exceptions do occur, and they can be trapped with `:try` etc. For
reasons that will become clearer when we wrap this all up into a neat little
"framework", it is not considered good practice to "fail" a test by throwing or
triggering an uncaught error/exception. It's best to use the assert functions,
or add things to `v:errors` with `call add( v:errors, ... )`.

However, an exception might be thrown due to a bug in our code! We should catch
these uncaught exceptions and mark our test as failed if there are any:

> A test is considered to have failed if an exception is thrown and not caught
> within the test.

```vim
try
  " do the test
catch
  call assert_report( "Uncaught exception in test: "
                    \ . v:exception 
                    \ . " at " 
                    \ . v:throwpoint )
endtry
```

### Early exit

While it probably goes without saying, it's not a good idea for the test to
cause Vim to exit. So, we want to trap that and report it as a
failure. For that we can use [`VimLeavePre`][h-vimleavepre] autocommand:

```vim
au VimLeavePre * call s:EarlyExit()
try
  " do the test
catch
  " Handle uncaught
finally
  au! VimLeavePre
endtry
```

The `s:EarlyExit()` function will be defined later, but you can guess that it
adds something to `v:errors` and then quits with an error code.

## Reporting results

After running your test, you need to know if it was successful, and if not, why
not. The former is fairly easy: we can make Vim exit with a nonzero exit code on
failure. For this, there is [`:quit!`][h-quit] for success and
[`:cquit!`][h-cquit] for failure:

```vim
if len( v:errors ) > 0
  cquit!
else
  quit!
endif
```

Unfortunately, getting the _reason_ for failure is not so straightforward. Due
to Vim being a terminal-mode application itself, the obvious choice 
(print something to stdout/stderr) isn't really available. `:echom` and suchlike
will all be lost when Vim exits. So what we normally do is to write all the
messages reported to a file (called `<file>.failed.log`, why not) and have a
wrapper script detect the failure and print them out.

```vim
" Append errors to test failure log
let logfile = expand( "<sfile>:p:t" ) . ".failed.log"
call writefile( v:errors, logfile, 'as' )
```

## Putting it all together

So, recalling that the test we want to run is:

```vim
call feedkeys( "i\<C-x>\<C-u>", 'xt' )
call assert_equal( 'Jan', getline( 1 ) )
```

We can create [a script to automate this for CompleteSimple][script-simple],
encompassing all of the above, as follows:

```vim
let init_script = expand( '<sfile>:p:h' ) . '/../support/test_simple.vim'
execute 'source ' . init_script

function! s:EarlyExit()
  call add( v:errors, "Test caused Vim to quit!" )
  call s:Done()
endfunction

function! s:Done()
  if len( v:errors ) > 0
    " Append errors to test failure log
    let logfile = expand( "<sfile>:p:t" ) . ".failed.log"
    call writefile( v:errors, logfile, 'as' )

    " Quit with an error code
    cquit!
  else
    quit!
  endif
endfunction

" * Type `i<C-x><C-u>`. Expect the buffer to contain `Jan`

let v:errors = []
au VimLeavePre * call s:EarlyExit()
try
  call feedkeys( "i\<C-x>\<C-u>", 'xt' )
  call assert_equal( 'Jan', getline( 1 ) )
catch
  call add( v:errors,
        \   "Uncaught exception in test: "
        \ . v:exception
        \ . " at "
        \ . v:throwpoint )
finally
  au! VimLeavePre
endtry

call s:Done()
```

Go on, try it! You can clone the test repo and run:

```
$ vim --clean -S test/scripts/test_simple.vim
$ echo $?
0
```

And to confirm that it works, if we change the check to `getline( 2 )`, we get
this:

```
$ vim --clean -S test/scripts/test_simple.vim
$ echo $?
1
$ cat test/scripts/test_simple.vim.failed.log
/Users/ben/Development/vimways/a-test-to-attest-to/test/scripts/test_simple.vim line 30: Expected 'Jan' but got ''
```

Done! You now know everything you need to to use Vim's built in testing
functionality to test Vim with Vim.

## A test "framework"

But that's a lot of boilerplate to write for _every_ script. The ratio of
boilerplate to test lines is about 20:1, which is obviously terrible. So to make
this into a workable "framework", we pull out all of the stuff that doesn't
differ between individual tests. That is:

* General setup
* Running the test and catching exceptions, Vim exit, etc.
* Reporting results

The way we do this is to pull all of that into a single script `run_test.vim`
and always source _that_ file. 

But how does it find what tests there are to run ? Well, there are a few ways we
could do this, including:

* Scanning a directory for files called `*.test.vim` and sourcing them in turn
* Sourcing a specified file and scanning for functions named `Test_*`

On reflection, we could of course do both.  But we're just going to use the
later because that's what Vim's tests do and what my own setup uses. It also
makes global setup and teardown functions simpler to reason about. But you're
free to do whatever works for you (hint: checkout [`glob()`][h-glob]). By
writing this all yourself, you can make it work best for you.

### Test discovery from functions

If we define each individual test case as a Vim function, then we can just
source the test script and search for functions that are defined (globally)
matching a particular pattern. Therefore, our approach will be:

* Source the test script containing the test cases (functions)
* Find the list of functions matching and any setup/teardown functions
* Run each test function in a "clean" environment

We put this logic into `run_tests.vim`. The process to run a test is going to be
this:

```
$ vim --clean -S run_test.vim /path/to/the/test/script
```

That is, we're going to open a test script in the editor, then `source
run_test.vim`. While `run_test.vim` is executing, the 'test script' is the
buffer identified by `%` (i.e. the current buffer), so we can source the test
script containing the functions with:

```vim
" Sources /path/to/the/test/script in our example above
source %
" Unloads /path/to/the/test/script in our example above
bwipe!
```

We can then find all the functions we need to run by inspecting the output of
the [`:function`][h-function] command, passing a filter argument. Sadly there's
no vimscript function to get this, so we capture the output using
[`execute()`][h-execute-func] and parse the result:

```vim
" Extract the list of functions matching ^Test_
let s:tests = split( substitute( execute( 'function /^Test_' ),
                               \ 'function \(\k*()\)',
                               \ '\1',
                               \ 'g' ) )

```

In order to allow scripts to run in different configurations, we actually defer
the global setup to the scripts, by looking for `SetUp` and `TearDown`
functions. This leads to the following "main" test loop:

```vim
if exists("*SetUp")
    call SetUp()
endif

" ... run all of the Test_* functions
for test_function in s:tests
  %bwipe!

  let v:errors = []
  au VimLeavePre * call s:EarlyExit()
  try
    execute 'call ' . test_function
  catch
    call add( v:errors,
          \   "Uncaught exception in test: "
          \ . v:exception
          \ . " at "
          \ . v:throwpoint )
  finally
    au! VimLeavePre
  endtry
endfor

if exists( "*TearDown" )
    call TearDown()
endif
```

Then we can write our actual test script:

```vim
function SetUp()
  let init_script = g:test_path . '/../support/' . g:test_name
  execute 'source ' . init_script
endfunction

function Test_Simple_Empty()
  call feedkeys( "i\<C-x>\<C-u>", 'xt' )
  call assert_equal( 'Jan', getline( 1 ) )
  %bwipe!
endfunction

function Test_Simple_February()
  call feedkeys( "iF\<C-x>\<C-u>", 'xt' )
  call assert_equal( 'Feb', getline( 1 ) )
  %bwipe!
endfunction

function Test_Simple_March()
  call feedkeys( "iM\<C-x>\<C-u>", 'xt' )
  call assert_equal( 'Mar', getline( 1 ) )
  %bwipe!
endfunction

function Test_Simple_May()
  " Use C-n to prove that the second option is May
  call feedkeys( "iM\<C-x>\<C-u>\<C-n>", 'xt' )
  call assert_equal( 'Mar', getline( 1 ) )
  %bwipe!
endfunction
```

We run this with:

```
$ vim --clean -S test/run_test.vim test/tests/test_simple.vim
$ echo $?
0
```

And that really is it, you now have a framework on which to build Vim tests
using about 70 LOCs of Vimscript.

## Bonus material - insert mode completion

As I mentioned earlier, I want to tackle specifically insert-mode completion
testing. So far we've actually just touched the surface and put together a
little framework for writing tests (and arguably nothing that clever);
now comes the (optional) interesting part.

So let's think about how we can check the popup menu. First, let's explore what
facilities Vim provides to even look at the current contents of the popup menu:

* `pumvisible()`
* `complete_info()`
* `pum_getpos()` (in very recent Vim builds)

Of course, all of these things are only useful during insert-mode. Recall that
by default `feedkeys()` leaves insert mode on return, so in order to actually
verify the popup menu in insert mode, we have to be a little clever. There are
actually a few ways to do this, one of which involves using the ["expression
register"][h-i_ctrl-r] to run a function. 

For anyone not familiar, the expression register is a neat tool, which
allows us to run an arbitrary vimscript expression _without
leaving insert mode_ and insert the result in the buffer. For our purposes, we
don't really want to insert the result, we just use a side-effect of running
the expression to validate the current buffer contents.

Here's an example (from `test/tests/test_simple_insert_mode.vim`), which
triggers user defined completion, then immediately calls the check function via
the expression register. The function itself returns `''` so as not to affect
the buffer:

```vim
function Test_Popup_Menu_Expression_Register()
  function TestPopupContents()
    let items = complete_info().items
    call map( items, {index, value -> value.word} )
    call assert_equal( [ 'Mar', 'May' ], items )
    return ''
  endfunction

  call feedkeys( "iM\<C-x>\<C-u>\<C-r>=TestPopupContents()", "xt" )

  delfunc! TestPopupContents
  %bwipe!
endfunction
```

This works well for this case, but won't work for all cases. In particular, this
won't work when we try to test the async version.

### Testing the async version

So far we have looked exclusively at testing the synchronous version of our
completion engine. But we are interested also in testing our asynchronous
version. So how do we do that? Well, we could try running our synchronous
(simple) tests against the async version of our completer.

Let's see what happens if we just take the above example, and source the async
setup script...

```
$ vim --clean -S test/run_test.vim test/tests/test_async_using_simple_approach.vim
$ echo $?
1
```

Blerg. It failed? Let's see why:

```
$ cat test/tests/test_async_using_simple_approach.vim.failed.log
function Test_Async_February line 2: Expected 'Feb' but got 'F'
function Test_Popup_Menu_Expression_Register[8]..TestPopupContents line 3: Expected ['Mar', 'May'] but got []
function Test_Async_Empty line 2: Expected 'Jan' but got ''
function Test_Async_May line 2: Expected 'May' but got 'M'
function Test_Async_March line 2: Expected 'Mar' but got 'M'
```

Oh, that's sad... it looks like our async completion plugin doesn't work! But
wait! When we tested it manually, it worked fine. So what's happening?

Well, let's take a look at the test plugin code for our `completefunc`,
`attest#CompleteAsync`:

```vim
" See :help complete-functions
function! attest#CompleteAsync( findstart, base ) abort
  if a:findstart
    " We will work out the start position later
    return s:FindStart()
  endif

  " Kill any existing request
  call s:KillTimer()

  " Kill the timer when leaving insert mode
  augroup ATestClear
    au InsertLeave * ++once call <SID>KillTimer()
  augroup END

  " Do something complicated that takes time. Pass the current column (actually
  " the start column) and the 'query' (a:base) to the callback using a partial.
  let s:complete_timer =  timer_start( 200,
                                     \ function( "s:DoAsyncCompletion",
                                               \ [ col( '.' ), a:base ] ) )

  return v:none
endfunction
```

To summarise:

* In phase 1, just return the start column synchronously
* In phase 2, start a timer to fire in 200ms time, and return `v:none` (this
  magic return value tells Vim we're going to trigger the popup manually using
  [`complete()`][h-complete])

The timer callback actually populates the completion menu:

```vim
function! s:DoAsyncCompletion( start_col, base, id ) abort
  call complete( a:start_col, s:CompleteMonth( a:base ) )
endfunction
```

For anyone not familiar with the syntax used above, the following creates a
partial (a `Funcref` with some predefined arguments), and sets it as the
callback for the timer. The predefined arguments are the completion start
column, which is always the cursor column, `col( '.' )`, in "phase 2" of
completion, and the 'query', `a:base`:

```vim
  let s:complete_timer =  timer_start( 200,
                                     \ function( "s:DoAsyncCompletion",
                                               \ [ col( '.' ), a:base ] ) )
```

The predefined arguments are combined with the signature of the required timer
callback (just a timer ID argument) in the signature or our actual callback:

```vim
function! s:DoAsyncCompletion( start_col, base, id ) abort
```

### Staying in insert mode

Recall that our tests are simple Vim functions. They themselves execute
_synchronously_, but our completion system won't return the results (and thus
display the popup menu) until at least 200ms _after_ we triggered completion.

In fact, `feedkeys()` exits insert mode after triggering user-defined completion,
so  we actually cancel our timer and never even run the `s:DoAsyncCompletion`
method. So what do we do?

Our options are limited, but we need to stay in insert mode after triggering
user-defined completion, and we also need to return to the Vim 'event loop' so
that the timer can fire and trigger completion popup to be displayed.

The first is easy; we can pass the `!` flag to `feedkeys()`, which as we
discussed earlier will leave us in insert mode and hand over responsibility to
us to return to normal mode programmatically.

### Timers to the rescue

The latter is a little more tricky. A naive, but effective approach is to start
_our own timer_ in the tests which fires _after_ the completion results are in.
This can then check the popup menu, and return to normal mode by running
`feedkeys( "\<Esc>" )`. It would look something like this:

```vim
function Test_Async_Empty()
  function CheckPopupContents( id )
    let items = complete_info().items
    call map( items, {index, value -> value.word} )
    call assert_equal( [ 'Mar', 'May' ], items )
    call feedkeys( "\<Esc>" )
  endfunction

  call timer_start( 400, function( "CheckPopupContents" ) )
  call feedkeys( "iM\<C-x>\<C-u>", "xt!" )
  call assert_equal( "Mar", getline( 1 ) )

  delfunc! CheckPopupContents
  %bwipe!
endfunction
```
You can try this out, and it will probably work, but ultimately this can lead to
flaky tests. I include this because in some scenarios, it's the only choice.

### Autocommands to the rescue

As it happens, we can do better, based on the observation that the
[`CompleteChanged`][h-completechanged] autocommand is triggered when we call
[`complete()`][h-complete] and provide the completions. This is due us using the
default configuration of Vim which is that `completeopt` does not contain
`noselect`.

Therefore a fully robust solution looks like this:

```vim
function Test_Async_Empty()
  function CheckPopupContents()
    let items = complete_info().items
    call map( items, {index, value -> value.word} )
    call assert_equal( [ 'Mar', 'May' ], items )
    call feedkeys( "\<Esc>" )
  endfunction

  augroup Test_Async_Empty
    au CompleteChanged * call CheckPopupContents()
  augroup END

  call feedkeys( "iM\<C-x>\<C-u>", "xt!" )
  call assert_equal( "Mar", getline( 1 ) )

  augroup Test_Async_Empty
    au!
  augroup END
  delfunc! CheckPopupContents
  %bwipe!

endfunction
```

For the completion tests where only a single result is returned, no completion
menu is shown (in the default Vim configuration, `menuone` is not set
in `completeopt`). So how do we test that? Well in that case we don't need to
check the popup contents, but simply wait for the completion to be inserted
automatically. This automatic insertion triggers the
[`CompleteDone`][h-completedone] autocommand, so we can use that instead:

```vim
function Test_Async_February()
  function ExitInsertMode()
    call feedkeys( "\<Esc>" )
  endfunction

  augroup Test_Async
    au CompleteDone * call ExitInsertMode()
  augroup END

  call feedkeys( "iF\<C-x>\<C-u>", 'xt!' )
  call assert_equal( 'Feb', getline( 1 ) )

  augroup Test_Async
    au!
  augroup END

  delfunc! ExitInsertMode
  %bwipe!
endfunction
```

## Wrapping up

And there you have it. A reliable way to test asynchronous insert-mode
completion plugins, and any other type of plugin.

You can view the completed tests here:

* [Test "framework"][run-test]
* [Basic test for simple version][test-simple]
* [Popup test for simple version][test-simple-insert-mode]
* [Full test for async version][test-async]

Hopefully the ideas and techniques here show some insight into the process of
writing robust vimscript layer tests. Of course, there's so much more to talk
about and so much more to testing, but I like to think that this approach (or
your own personally adapted version) can go a long way to both improving the
quality of your plugins and your confidence in changing them.

Maybe it can even improve your knowledge and understanding of Vimternals.

Or perhaps it was even mildly entertaining.

## Appendix: Further reading

`:help testing.txt` is a great guide and includes a lot more detail about
assertion functions, running Vim in a terminal, etc.

Take a look at Vim's
[`src/testdir/Makefile`](https://github.com/vim/vim/blob/master/src/testdir/Makefile)
for how Vim runs its own tests. Also you can take a look at the tests in
[`src/testdir/`](https://github.com/vim/vim/tree/master/src/testdir) for
inspiration on testing particular aspects of Vim functionality.

You can take a look at the full [README][ycm-tests] for the YouCompleteMe test
suite and at the (significantly more complex) [`run_tests.vim`][ycm-run-tests]
used there. There's also a [script used to run them][ycm-run_vim_tests] and the
[CI configuration][ycm-ci]. The CI also supports coverage testing using
covimerage.

### Credit

This article is based on work I did to support vim-layer testing for 2 complex
plugins:

* [YouCompleteMe][]
* [Vimspector][]

Most, if not _all_ of the actual content of this test "framework" is lifted and
reverse-engineered from Vim's source tree in the `src/testdir` directory. I have
simplified and minimised it for demonstrative purposes, but very little of it is
strictly original work. The article, test plugin and its tests are original
work.

### What's not covered

There are plenty of other things we could/should do in practice which are left
out for brevity, including:

* Allowing per-test SetUp and TearDown functions.
* Allowing tests to be skipped by throwing 'Skip: <something>', catching that in
  this loop.
* Catching and handling errors/exceptions in set up and tear down functions.
* Implementing a per-test global timeout to catch tests stuck in insert mode.
* `WaitForAssert`, `RunVimInTerminal`, etc. utility methods.
* Avoiding the `E325: ATTENTION` errors if you have the test file open (hint:
  `vim  --clean -S run_test.vim --cmd 'au SwapExists * let v:swapchoice = "e"' test_script.vim` )

As I said, this is not an article about testing. But it's also not an article
about making Vim plugins (the right way). So I have left out things like:

* Running the tests from make, or any other build system
* Building and testing in Vim in docker
* Continuous integration
* Installation testing and linting
* Code coverage testing
* Debugging
* etc.

All of those are covered in the aforementioned plugin codebases, so please
check the [further reading](#further-reading) section if you're interested in
any of those things.

### About the author

Ben Jackson is a software architect working in high performance/low latency
financial trading systems software. He is the primary maintainer of
[YouCompleteMe][], an all-language code completion and comprehension tool for
Vim (and all time #vim whipping boy). Ben is also the author and maintainer of
[Vimspector][], an (the only?) all-language graphical debugger for Vim.

If you want to contact him, you can find him in YCM's Gitter channel and
occasionally in #vim on Freenode.

Ben's OSS work is not in any way associated with his employer nor do his views
or opinions in any way represent those of his employer, his family or any of his
alter egos.

---

_License notice_


[linus-quote]: http://lkml.iu.edu/hypermail/linux/kernel/9804.1/0149.html
[ycm-tests]: https://github.com/ycm-core/YouCompleteMe/tree/master/test#quick-start

[YouCompleteMe]: https://ycm-core.github.io/YouCompleteMe
[Vimspector]: https://puremourning.github.io/vimspector-web/
[ycm-run-tests]: https://github.com/ycm-core/YouCompleteMe/blob/master/test/lib/run_test.vim
[ycm-run_vim_tests]: https://github.com/ycm-core/YouCompleteMe/blob/master/test/run_vim_tests
[ycm-ci]: https://github.com/ycm-core/YouCompleteMe/blob/master/azure-pipelines.yml#L44
[vimspector-vim]: https://puremourning.github.io/vimspector-web/demo-setup.html
[test-plugin]: https://github.com/puremourning/a-test-to-attest-to
[setup-simple]: https://github.com/puremourning/a-test-to-attest-to/blob/master/test/support/test_simple.vim
[setup-async]: https://github.com/puremourning/a-test-to-attest-to/blob/master/test/support/test_async.vim
[script-simple]: https://github.com/puremourning/a-test-to-attest-to/blob/master/test/scripts/test_simple.vim
[test-simple]: https://github.com/puremourning/a-test-to-attest-to/blob/master/test/tests/test_simple.vim
[test-simple-insert-mode]: https://github.com/puremourning/a-test-to-attest-to/blob/master/test/tests/test_simple_insert_mode.vim
[test-async]: https://github.com/puremourning/a-test-to-attest-to/blob/master/test/tests/test_async.vim
[run-test]: https://github.com/puremourning/a-test-to-attest-to/blob/master/test/run_test.vim

[h-testing]: https://vimhelp.org/testing.txt.html
[h-test-functions]: https://vimhelp.org/testing.txt.html#assert-functions-details
[h-packages]: https://vimhelp.org/repeat.txt.html#packages
[h-completefunc]: https://vimhelp.org/options.txt.html#%27completefunc%27
[h-compl-function]: https://vimhelp.org/insert.txt.html#compl-function
[h-complete]: http://vimhelp.appspot.com/eval.txt.html#complete%28%29
[h-rtp]: https://vimhelp.org/options.txt.html#%27runtimepath%27
[h-minus-S]: https://vimhelp.org/starting.txt.html#-S
[h-feedkeys]: https://vimhelp.org/eval.txt.html#feedkeys%28%29
[h-getline]: https://vimhelp.org/eval.txt.html#getline%28%29
[h-assert-equal]: https://vimhelp.org/testing.txt.html#assert_equal%28%29
[h-i_ctrl-r]: https://vimhelp.org/insert.txt.html#i_CTRL-R
[h-vimleavepre]: https://vimhelp.org/autocmd.txt.html#VimLeavePre
[h-quit]: https://vimhelp.org/editing.txt.html#%3Aquit
[h-cquit]: https://vimhelp.org/quickfix.txt.html#%3Acquit
[h-function]: http://vimhelp.appspot.com/eval.txt.html#%3Afunction
[h-execute-func]: http://vimhelp.appspot.com/eval.txt.html#execute%28%29
[h-completechanged]: https://vimhelp.org/autocmd.txt.html#CompleteChanged
[h-completedone]: http://vimhelp.appspot.com/autocmd.txt.html#CompleteDone
[h-complete-functions]: http://vimhelp.appspot.com/insert.txt.html#complete-functions
[h-glob]: http://vimhelp.appspot.com/eval.txt.html#glob%28%29

[//]: # ( Vim: set spell spelllang=en: )
