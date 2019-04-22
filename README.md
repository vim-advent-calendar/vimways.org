# vimways.org

This is the main repository for [vimways.org](https://vimways.org), a project by [@romainl](https://github.com/romainl) and [@robertmeta](https://github.com/robertmeta).

[Vimways.org](https://vimways.org) is largely inspired by [24ways.org](https://24ways.org/) but, instead of covering such broad subjects as web design and web development, our focus will *exclusively* be on delivering high quality articles about [Vim](https://www.vim.org/) and its thriving ecosystem.

## Requirements

Vimways is a static website built with [Hugo](). Currently, we are using the *extended* variant of [version 0.55](https://github.com/gohugoio/hugo/releases/tag/v0.55) because it includes SASS compilation.

## Local usage

Clone the project on your machine, move into it, and run the command below:

    $ hugo server

* The site should be accessible at this address: [http://localhost:1313/](http://localhost:1313), with [LiveReload](https://chrome.google.com/webstore/detail/livereload/jnihajbhpnppcggbcgedagnkighmdlei?hl=fr) enabled.
* Hugo should watch a number of subdirectories for changes and rebuild the site accordingly.

If you want to see draft pages and pages scheduled for future publication, use the `-D` and `-F` flags respectively:

    $ hugo server -DF

## Articles

The articles are in `content/YYYY/`: `content/2018/`, `content/2019/`, etc.

They are written in Markdown, with the addition of a front matter specific to Hugo.

## Meta pages

The *About* and *Authors* pages are in `content/`.

## Theme

The theme is completely custom.


[//]: # ( Vim: set spell spelllang=en: )
