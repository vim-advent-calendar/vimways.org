---
title: "Make your setup truly cross-platform"
date: 2018-10-14T11:11:59+02:00
publishDate: 2018-12-02
draft: true
description: An article on this or that.
---

Make your setup truly cross-platform
===============================================================================
Once you have taken the time to setup Vim exactly the way you want, you might
still encounter configuration issues. My whole `~/.vim` folder is under version
control so I can just clone it on any computer I want my familiar Vim
experience.

But I use Windows computers and Linux computers. Even within the same
environment, I might have different dependencies installed for the plugins I
try to import. Also, from time to time I like to use Neovim too, to try out a
few unique features.

All the tips in this article gravitate around being able to use if statements in
your startup scripts.


Environment specific settings
-------------------------------------------------------------------------------
To make environment specific settings we need to know the environment we are
running on.
We can ask vim directly if it was compiled for Windows, otherwise a system call
to `uname` will give the running environment. The function below returns a string
containing the value of the running environment.

```vim
function! whichEnv() abort
    if has('win64') || has('win32') || has('win16')
        return 'WINDOWS'
    else
       return toupper(substitute(system('uname'), '\n', '', ''))
    endif
endfunction

"""""""""""""""""""""""""""""
" Later use in another file "
"""""""""""""""""""""""""""""
if (whichEnv() =~# 'WINDOWS')
    " Enable Windows specific settings/plugins
else if (whichEnv() =~# 'LINUX')
    " Enable Linux specific settings/plugins
else if (whichEnv() =~# 'DARWIN')
    " Enable MacOS specific settings/plugins
else
    " Other cases I can't think of like MINGW
endif
```

Note that vim also has so-called *features* (the arguments in the `has`
function) for checking respectively `'osx'` and '`osx_darwin`', but after having
spoken with a MacOS user (I don't use it personnally), there seems to be cases
where using these flags for MacOS detection is not working as
[one would guess](https://github.com/vim-advent-calendar/ideas/pull/12#issuecomment-435005197).

Intermission : external shell calls optimizations
-------------------------------------------------------------------------------
External shell calls are costly, mostly because of the context switching they
require. They are not very long, but one of the big advantages of vim is the
very quick startup time, and having too many external calls in your startup
will definitely have consequences on your experience.

To illustrate this, let's compare the startup time of Vim with a one-liner
vimrc, where :
- one case has `let g:dummy_string = 'dummy string'` (no external shell call),
- the other case has `let g:dummy_string = system('date')` (one external shell
  call)

The command I used to compare the startup times was `vim --noplugin -u
one_liner_vimrc --startuptime startup.txt`, and here is the final result :
- no external call : `002.369  000.003: --- VIM STARTED ---`
- external call : `093.497  000.002: --- VIM STARTED ---`

The 90 ms difference in startup time is entirely due to the external system call
(see `:h startuptime` for help on the syntax) :
```
# No external call
001.246  000.021  000.021: sourcing no_externalcall_vimrc

# External call
092.540  088.869  088.869: sourcing externalcall_vimrc
```

Caching the results from any external system call as
much as possible is important when crafting flexible `.vim/` startup scripts.
Here is the final function I use (and call in my other scripts) to know my
environment. The result of `system` is stored in a global variable and used
in all scripts.

```vim
"""""""""""""""""""""""""""""
"        vimrc              "
"""""""""""""""""""""""""""""

" The function needs to be near the top since it has to be known for later use

" Sets only once the value of g:env to the running environment
" from romainl
" https://gist.github.com/romainl/4df4cde3498fada91032858d7af213c2
function! Config_setEnv() abort
    if exists('g:env')
        return
    endif
    if has('win64') || has('win32') || has('win16')
        let g:env = 'WINDOWS'
    else
       let g:env = toupper(substitute(system('uname'), '\n', '', ''))
    endif
endfunction

"""""""""""""""""""""""""""""
" Later use in another file "
"""""""""""""""""""""""""""""

" I can call this function before every environment specific block with the
" early return branch.
call Config_setEnv()
if (g:Env =~# 'WINDOWS')
    " Enable Windows specific settings/plugins
else if (g:Env =~# 'LINUX')
    " Enable Linux specific settings/plugins
else if (g:Env =~# 'DARWIN')
    " Enable MacOS specific settings/plugins
else
    " Other cases I can't think of like MINGW
endif
```

Host specific settings
-------------------------------------------------------------------------------
We can use exactly the same method for host specific settings.
Linux provides [hostname](https://linux.die.net/man/1/hostname) so we can use
the same function as before, replacing only the `toupper...` line with
`system('hostname')`, and storing it in another `g:` variable like `g:Hostname`.

This method should also work on Windows, since it also provides
[hostname](https://ss64.com/nt/hostname.html), but I have not tested it yet.

In order to show
how this can be useful I will have to present a little my work environment.
I am currently a PhD student in computational mechanics, which
is one heavy user of High Performance Computing
([HPC](https://en.wikipedia.org/w/index.php?title=High-performance_computing&redirect=no)
: the laboratory has a Linux-powered
[cluster](https://en.wikipedia.org/wiki/Computer_cluster) on which all the heavy
simulations are run. The software we use is written in C++ and we built a DSL to
communicate input parameters through plain-text files to the software.

This means I need to edit text from multiple places on
multiple machines for my work :

- I might want to edit files directly on my office Windows machine. This machine
    is a little beefy and I can use it to test locally developments which need
    more computational power to be run.
- I might want to edit files stored on the cluster from my office Windows
    machine (with ssh). This is useful to work on the code and/or launch tests
    directly in the correct environment.
- I might want to edit files stored on the cluster from my laptop running Linux
    (with ssh). This is useful when I want to change quickly simulation
    parameters.
- I might want to edit files directly on my laptop. This is where I work on
    code the most.

Therefore, I use Vim to edit text in 2 Linux environments (my laptop and the
front node of the cluster), but I do have specific issues related to the way I
access the files (either "natively" or through ssh using a Windows client are
the two extremes). So in the following snippet, I use the "host specific" method
to disable X server connection when working on the cluster (Putty used to try to
connect and wait for a timeout, leading to startup times of 3-5 *seconds*), and
to add the [FZF](https://github.com/junegunn/fzf#as-vim-plugin) directory to the
runtimepath, since I had to install fzf in my `$HOME` directory on this machine.

```vim
"""""""""""""""""""""""""""""
"        vimrc              "
"""""""""""""""""""""""""""""
" Sets only once the value of g:host to the output of hostname
function! Config_setHost() abort
    if exists('g:Hostname')
        return
    endif
       let g:host = system('hostname')
endfunction

call Config_setHost()
if g:Hostname =~? 'front'
    set clipboard=exclude:.*
    set runtimepath+=~/.fzf
endif
```

Host specific settings are good when you know you're only cloning your `~/.vim`
directory in a few computers on which you know what is installed. Using this to
differentiate between 50 hosts means you will need very long if statements which
get quickly hard to read.

I still find this useful for clipboard handling or other purely host-specific
settings.

**Security note** : as you can see in the last snippet, you have to put the
hostname in your configuration in order to make these specific settings. This
information will then be available to anyone who can see your configuration
files on the internet. If this is an issue (especially regarding version
control on online git repositories), I think the best thing to do is to :
- keep these if statements in separate `.vim` files,
- Move these `.vim` files in a specific folder under `~/.vim` like
    `host_settings`
- `runtime` the settings in the version controlled file.

Eventually the configuration looks like this :
```vim
""""""""""""""""""""""""""""""
" vimrc (version-controlled) "
""""""""""""""""""""""""""""""
" Sets only once the value of g:host to the output of hostname
function! Config_setHost() abort
    if exists('g:Hostname')
        return
    endif
       let g:host = system('hostname')
endfunction

call Config_setHost()
runtime host_settings/34.vim

"""""""""""""""""""""""""""""
"       .gitignore          "
"""""""""""""""""""""""""""""
# Ignore the host_settings folder in version control
host_settings/

" All files below are now private
"""""""""""""""""""""""""""""
"   host_settings/34.vim    "
"""""""""""""""""""""""""""""
if g:Hostname =~? 'front'
    set clipboard=exclude:.*
    set runtimepath+=~/.fzf
endif


```

If all snippets can be run at the same location, you can even use globs to hide
even file names :
```vim
""""""""""""""""""""""""""""""
" vimrc (version-controlled) "
""""""""""""""""""""""""""""""
" Sets only once the value of g:host to the output of hostname
function! Config_setHost() abort
    if exists('g:Hostname')
        return
    endif
       let g:host = system('hostname')
endfunction

call Config_setHost()
runtime! host_settings/*.vim " Beware of the '!', it is necessary

"""""""""""""""""""""""""""""
"       .gitignore          "
"""""""""""""""""""""""""""""
# Ignore the host_settings folder in version control
host_settings/

" All files below are now private
""""""""""""""""""""""""""""""""""""""""
" host_settings/clipboard_settings.vim "
""""""""""""""""""""""""""""""""""""""""
if g:Hostname =~? 'front'
    set clipboard=exclude:.*
endif

""""""""""""""""""""""""""""""""""
" host_settings/fzf_settings.vim "
""""""""""""""""""""""""""""""""""
if g:Hostname =~? 'front'
    set runtimepath+=~/.fzf
endif

```

Dependencies specific settings
-------------------------------------------------------------------------------
Even on the same environment, dependencies might not be fulfilled on all the
target machines. These dependencies can be separated into 2 categories, Vim's
*features* and external *dependencies*. The difference I make between these 2
is that *features* are defined at compilation time in Vim and that
*dependencies* are external to Vim's compilation.

Vim keeps track of its own feature set, defined at compile time. Therefore you
can directly use vimscript to know if Vim has a feature or not, using the
`has()` function.
See `:h has()` for all the features you can test for
directly within vim.
```vim
if has('cscope')
" Enable all the plugins or change settings to use cscope support
endif
```

For external dependencies (like the linters you might want to set as `makeprg`
or the LSP servers you want to start for a project), using `executable()`
instead of using a call to [which](https://linux.die.net/man/1/which) is very
important, as it is way faster than `system`. I ran the same test case as
before with a vimrc which only include an `executable()` call :
```vim
if executable('rg')
    let g:string_date = 'dummy string'
    " usually the line here is set grepprg=rg\ --vimgrep
endif
```

and the results are almost the same as the *no external call* case :
```
# Important lines only
001.991  000.136  000.136: sourcing exec_vimrc
003.383  000.005: --- VIM STARTED ---
```


Bonus round : Vim 8+ and Neovim compatibility
-------------------------------------------------------------------------------
Vim 8+ is important because I make heavy usage of the package feature for this
adaptation.

First step is to symlink the folders of course. We only want one copy of the
`.vim` folder on the system, Vim does not care about `init.vim` and Neovim does
not care about `vimrc`

After a few updates I made in my plugins and/or colorschemes, I noticed I
always had 2 files to change : `init.vim` and `vimrc`. I still want to keep the
files different because there are a few settings which are actually specific to
one software, but duplicating changes is a code smell.

My solution is to use
`runtime` heavily and externalize all the common parts of my old `vimrc`.
`runtime` will look for files to source with the given name in your
`runtimepath` and will source the first one it finds. Choosing a "unique"
folder for the sourced files (like `settings`) allows to store them all with
any name as long as they are in the `runtimepath`. I choose to leave them
directly in the `~/.vim` folder to have them under version control of course :
```
$ ls ~/.vim
... some files
init.vim
vimrc
settings/
... other folders

$ ls ~/.vim/settings
colors.vim
ale.vim
... other files

```

```vim
" In vimrc
set autoindent " 'vim-specific' setting
runtime settings/fold_fillchars.vim

```


`if has('nvim')` is exactly what you want to separate the 2 cases in your
scripts. For example, to load plugins only for Vim or only for Neovim, you can
put your optional plugins in `~/.vim/pack/vim_or_neovim/opt` and then use this
kind of snippets :

```vim
if has('nvim')
    " Load Neovim specific plugins
    packadd LanguageClient-neovim " This plugin is not Neovim specific anymore,
                                  " just here for the example
else
    " Load Vim specific plugins
    packadd traces.vim
endif
```


Results
-------------------------------------------------------------------------------
You can see a few of those principles applied on my [current
repo](https://framagit.org/gagbo/vim-setup). Be warned that it is still a little
bit messy, because tidying all the files and plugins is very low priority on my
TODO list. And also because writing this post made me verify and learn new
things about how to further smooth my truly cross platform setup.


Gerry

This article is licensed under
[Creative Commons v4.0](https://creativecommons.org/licenses/by/4.0/)
