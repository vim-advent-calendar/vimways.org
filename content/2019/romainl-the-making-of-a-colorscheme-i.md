---
title: "The Making of a Colorscheme — Part 1: Design"
publishDate: 2019-12-24
draft: true
description: "foo bar baz"
slug: "the-making-of-a-colorscheme-part-1-design"
author:
  name: "Romain Lafourcade"
  github: "romainl"
  sourcehut: "~romainl"
  gitlab: "romainl"
  bitbucket: "romainl"
---

* Theory
	* colorschemes in general
		* color theory
		* harmonies
	* colorschemes for text
	* light background or dark background?
	* color blindness
* Practice

The purpose of this two-parts article is to demystify the process of creating what Vim calls a "colorscheme", a script used to assign specific visual properties to specific parts of your favorite text editor.

This part will focus on the theory, physical constraints, techniques, and thought processes typically involved in putting together an organized list of colors. This is the first step of designing a "colorscheme".

The second part will focus on how to implement and distribute colorschemes, turning the palette we built in part 1 into a proper Vim colorscheme.

## The purpose of syntax highlighting

In text editors, the whole point of syntax highlighting is to make it easier for the user to *see* important things in the text they are working with. The basic idea is to highlight every token belonging to a class with the same color, and do so for every class potentially present in our text, so that our eyes can scan the document efficiently and our brain can understand structure and spot interesting things.

This can't be properly achieved by using random colors that change every time you look at the same document, or by using colors that are too similar, or by using jarring colors (remember we are trying to help people, not make their eyes bleed), or by using too few or too many colors, or by depending too much on the physical properties of the user's device… so we will need:

* a solid understanding of how color works,
* a systematic approach.

## A primer on color

The apple is not red. Its surface is made of tiny particles that, under certain circumstances, reflect certain wavelengths of the electromagnetic spectrum that, after being processed in our eyes, are associated by our brain with the concept of "red". Or not. The light our apple receives may not be perfectly white to begin with (think highway tunnels), or we may watch it through a colored window, or we may have slightly dysfunctional photoreceptors that can't process those specific wavelengths, or our culture may only have one word for "not green", etc.

Color is, more than anything, a combination of phenomenons happening in the outside world, in our own body, and in our mind, all of them subject to *many* factors.

### Vocabulary

With such a fuzzy nature, color is not really an easy topic to discuss so we invented a number of terms to communicate some of its aspects in a hopefully objective way. Some of those terms are "abstract", meaning that they are used to discuss color among non-specialists and may or may not refer to measurable properties, while others are "concrete", more technical and science-y than their friends but not necessarily more objective.

Making a colorscheme generally requires juggling with abstract and concrete terms and concepts: on one hand we want it to be eye-pleasing or evoke certain feelings (subjective, abstract) but we also want it to work correctly under different conditions or our colors to have some sort of logical distribution (objective, concrete). So let's get acquainted with the most useful terms.

Aspect | Description | Example
---|---|---
Hue | The name of the color | Blue, orange
Value | How lighter or darker a color is when white or black is added | dsdsd
Tint | Value obtained by adding white to a hue | sdsds
Shade | Value obtained by adding black to a hue | sdsdfsg
Tone | Value obtained by adding grey to a hue | sdsdsd

#### Hue

Experts aren't exactly unanimous about *why*, but they agree that it is possible to tell how much a given color diverges from four "pure hues": "red", "green", "blue", and "yellow".

It may be difficult to find the exact word to describe the color of our apple but it is relatively easy to decide in which of the largest color buckets—"red", "green", "blue", and "yellow"—we shall put it. Those are "primary" or "unique" hues.

But the apples in our "red" bucket are not all the same red. Some of them are decidedly more "red" than "yellow" but it's not clear cut so we put them in a "red-yellow" bucket and we do the same with the slightly red-ish apples from the "yellow" bucket and put them in a "yellow-red" bucket. At that point, we may find that some of the apples from the "red-yellow" and "yellow-red" bucket look so similar that we could in fact put them in their own bucket and invent a name for it: "orange".

The hue of a color expresses how much it diverges from so-called "pure colors": red, green, blue, and yellow. Because it relates to broad categories it is the most immediately identifiable property of a color.

Saturation

Luminance

## Contrast

## Harmony

## Cohesiveness

## Environmental influence

### proportions des surfaces
#### fond
##### foncé
##### clair
#### texte




## Artistic constraints
### High or low contrast
### Seasons
### Hot or cold
### Monochrom
### Documentary source

## Sight deficiencies
### color blindness
## Vim constraints

At a high level, the way it works is the same everywhere: there is a mechanism that divides your text in tokens according to some syntactic rules and another system that assigns styling to those tokens.

## Best practices
## Hands-on
		construire une palette
			choisir des couleurs de base
			couleurs secondaires
			rhythme





[//]: # ( Vim: set spell spelllang=en: )
