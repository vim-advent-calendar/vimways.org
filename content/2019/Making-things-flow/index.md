---
title: "Making Things Flow"
publishDate: 2019-12-01
draft: true
description: "Making the behaviour of Vim flow"
author:
  github: "george-b"
  name: "George Brown"
---

# Making things flow

Changing the behaviour of one's editor is a common subject, but what if the desired behaviour can't be achieved by configuring a setting offered by your editor? Thankfully Vim is an editor which allows powerful scripting by its users.

## Look Ma, no mappings!

There's nothing wrong with mappings. The purpose of this article is to explore more generalised methods whereas mappings generally have a more singular focus. Or to put is another way this article will focus more on the behaviour and response of the editor rather than defining singular imperative actions.

## An example from defaults.vim

Let us begin with an example that can be found in [Vim as-is these days][defaults.vim].

```vim
" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid, when inside an event handler
" (happens when dropping a file on gvim) and for a commit message (it's
" likely a different one than last time).
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | end
```

The comment explains the what's being done in the `autocmd` so I won't talk about that. But it's interesting to think about the fact that this is something Vim now ships with. It's been possible and indeed used by others in their configuration before appearing in mainline Vim. I consider this interesting for two reasons, firstly Vim scripting allows us to do this quite easily and secondly the scripting was added to Vim rather than code for an option that would allow users to `set` such behaviour.

## Getting into the groove

Whilst having been a Vim user for some time my first real exposure to the idea of curving Vim's behaviour in a transparent way was this excellent [gist][CCR]. I thoroughly recommend reading through it then coming back here. I actually even made my own [variant][Autoreply].

In any case the effect is the same. Vim's behaviour is altered not because of a setting but because we've scripted a flow. It's something we can use a great deal but we've only ever had to think about it once, when we wrote the script. To contrast we don't have to think "Oh I have a mapping that will show me X and prompt for Y", instead we ask Vim for X as usual it now prompts for Y.

Continuing with a another "call and response" type example we can have the quickfix window open when it contains results.

Here's a [gist][instant-grep] that showcases this. This is also behaviour is also available in [vim-qf][vim-qf].

This method is very useful as there are many ways the quickfix list may be populated and yet we are able to create a behaviour that is consistent with a self contained implementation.

## Don't disrupt my flow

Disabling `hlsearch` is a common operation for users that have `set hlsearch` as after performing the search and finding the desired result the highlighting becomes superfluous. To ease this many Vim users have a mapping to deal with this. But that's an extra step that the user has to think about. Instead we can alter the behaviour of Vim to intelligently disable and re-enable `hlsearch` as done with [vim-cool][vim-cool].

As noted in the README this plugin really became "cool" with [this][vim-cool_purpleP]. It doesn't change the intention of the plugin but it achieves it in a far robust and elegant way.

## Don't break my flow

Another example is the movement of the cursor when dealing with operators. Vim has moves the cursor after invoking operators and I'd prefer it didn't always do so. Here we wish to prevent a behaviour default to Vim rather than craft a complementary one.

Avoiding this in the case of operator mappings can be particularly ugly. A common method is to drop a mark or save a view in the mapping. However the mapping must end with `g@` so Vim will wait for the operator, meaning the mapping itself can't invoke the cursor movement back to its original location. As such the movement would have to be placed inside the function that `operatorfunc` has been set to. Note that dropping a mark or saving a view inside the `operatorfunc` function is not an option as the cursor has already been moved by the time this is invoked.

Functions should not require such a priori knowledge about the mappings that are calling them.

A solution to this is to save a view whenever `operatorfunc` is set. Then whenever the cursor is moved check if `operatorfunc` is set, if so restore the view, dispose of the temporary variable containing said view, and unset `operatorfunc` with autocmd's disabled as to avoid a loop.

```vim
function! OpfuncSteady()
  if !empty(&operatorfunc)
    call winrestview(w:opfuncview)
    unlet w:opfuncview
    noautocmd set operatorfunc=
  endif
endfunction

augroup OpfuncSteady
  autocmd!
  autocmd OptionSet operatorfunc let w:opfuncview = winsaveview()
  autocmd CursorMoved * call OpfuncSteady()
augroup END
```

Again it's the transparency that makes this neat. With this snippet neither the user or even the rest of their configuration have to think about this. The behaviour of the editor has simply been altered.

## Conclusion

I hope this has showcased some interesting ideas about scripting Vim's behaviour. I've placed and emphasis on "flow" as the examples shown aim to have little to zero cognitive impact.

---

_License notice_

[defaults.vim]: https://github.com/vim/vim/blob/eaf35241197fc6b9ee9af993095bf5e6f35c8f1a/runtime/defaults.vim#L108-L117
[CCR]: https://gist.github.com/romainl/047aca21e338df7ccf771f96858edb86
[autoreply]: https://gist.github.com/george-b/2f842efaf2141cb935a81f6174b6401f
[instant-grep]: https://gist.github.com/romainl/56f0c28ef953ffc157f36cc495947ab3
[vim-qf]: https://github.com/romainl/vim-qf
[vim-cool]: https://github.com/romainl/vim-cool
[vim-cool_purpleP]: https://github.com/romainl/vim-cool/issues/9

[//]: # ( Vim: set spell spelllang=en: )
