# DESKTOP.md — Building a Custom Pharo Desktop, Agentic Process Notes

This is a learning note about the *process*: how a human and a coding agent
together turned the stock Pharo 13 desktop into a personalized one —
custom wallpaper and a custom color theme — working live against the
running image, with the human watching every step.

The specific desktop we built (the Mistral cat wallpaper and color
theme) is **not published** in this repository: it is derived from
third-party copyright material, so the artwork, the generator and the
theme classes stay private on the author's machine (see AGENTS.md,
"Private Mistral material"). Everything documented here is the *method*,
and you are free to use it to construct your own setup with your own
artwork.

## The shape of the process

1. **Share the live world.** Run the Pharo desktop (GUI mode) while the
   agent talks to the same image through the SIS bridge (port 8086).
   Every eval the agent sends lands on the screen the human is looking
   at. The human is the acceptance test; screenshots and the world-morph
   structure (`/read-screen`) are the agent's own eyes.
2. **Explore before you build.** Do not guess APIs — interrogate the
   running image. We found Pharo's entire theming architecture by
   reading live sources: `UITheme` delegates colors to a
   `colorConfiguratorClass`, `PasteUpMorph >> backgroundMorph:` carries
   a background, `UITheme >> desktopImageFor:` revealed that Pharo has a
   *native* wallpaper mechanism. The best solution was already in the
   image; we only had to find it.
3. **Iterate in small, reversible steps.** One eval changes one thing.
   Apply, look, judge, adjust. Every step is re-runnable and the image
   can be snapshotted (`snapshot.cmd`) before risky changes.
4. **Finish durably.** When the look is accepted: compile the final
   version into classes, export them as Tonel to `src/`, save the image
   (`Smalltalk snapshot: true andQuit: false`), commit. Cosmetic work
   deserves the same durability discipline as code.

## The technical method, distilled

**Wallpaper.** Three layers, learned the hard way:

- *Prepare the art.* Content-crop your source picture (bounding box of
  non-background pixels — never hardcode crop coordinates), and denoise
  the border: a handful of compression-noise pixels on the artwork's
  edge will propagate into huge wrong-colored regions if your generator
  extends edge colors outward. Sample extension colors a few pixels
  inside the border.
- *Generate per screen, not once.* Query the live world for its extent
  (`World extent`) and generate the image at exactly that size. A
  fixed-size bitmap cannot adapt; a parameterized generator can. Rerun
  it after the world is resized.
- *Install through Pharo's own mechanism.* One line does it right:

  ```smalltalk
  World backgroundImage: aForm layout: #scaled
  ```

  This installs a **locked, scaled `AlphaImageMorph`** as the world's
  background morph. The `lock` matters: an ordinary `ImageMorph` used
  as a background is an interactive object — plain clicks drag it
  around and it appears to "multiply". A week of Morphic wisdom in one
  selector.

**Theme.** Pharo 13 makes a custom theme a two-class job:

- Subclass `PharoDarkTheme` (or `PharoLightTheme`). Class-side
  `themeName ^ 'Your Name'` and `isAbstract ^ false` register it; it
  then appears in Settings → Appearance → Theme, and
  `YourTheme beCurrent` applies it.
- Colors come from a configurator: override class-side
  `colorConfiguratorClass` to answer a subclass of
  `DarkThemeColorConfigurator` that overrides `backgroundColor`,
  `selectionColor`, `caretColor`, `highlightTextColor`, and friends.
  Nothing else is needed — the theme machinery picks everything up.

One honest lesson from our run: applying a *theme* changes every
window, menu, and caret at once — a heavy visual step to accept or
reject. A wallpaper is the gentler instrument: it personalizes the
desktop without touching any widget. Start with the wallpaper; adopt a
theme only if the wallpaper is not enough.

**Even visuals can be test-first.** Our generator is deterministic
(fixed seed), so the generated image is unit-testable: the test suite
asserts the layout (center square, artwork position), the palette
membership of every sampled pixel, and reproducibility. Test-first is
not just for logic; anything deterministic can be tested.

## Building your own setup

With your own artwork, the whole thing is:

1. Write a generator (Python or Smalltalk) that crops and denoises
   your art and renders a desktop-sized image. Parameterize it by the
   world extent.
2. Install it with the one-liner above, or wrap it in a class-side
   `installWallpaper` method so it is a single message.
3. Optionally, build a theme with the two classes above.
4. Save the image to make it persist; keep the generator and sources
   under version control; re-run the generator after a world resize.

The Pharo image already contains everything else you need — the theme
hierarchy, the color configurators, the icon assets (look at
`Smalltalk ui icons`), and the desktop-image machinery. The method is
just: find it, use it, and lock what should not move.
