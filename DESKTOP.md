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

- *Compose from the source.* The composition that finally pleased the
  eye was the picture's own: the artwork centered, the field extending
  its edge colors, and a small logo in the corner cropped from the
  artwork itself — same source, same colors, so the elements match by
  construction. Invented arrangements (the artwork tucked into a
  corner, a generated mosaic field around it) were all rejected in
  favor of what the picture already was.

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
theme only if the wallpaper is not enough. And sometimes the stock
themes are the answer: our final desktop runs the stock Pharo Dark
theme — the custom theme we built was an education, not a need.

**Even visuals can be test-first.** Our generator is deterministic
(fixed seed), so the generated image is unit-testable: the test suite
asserts the layout (center square, artwork position), the palette
membership of every sampled pixel, and reproducibility. Test-first is
not just for logic; anything deterministic can be tested.

## Aesthetics, learned the hard way

- *Screenshots are lossy.* A chat screenshot compresses badly: colors
  wash into murky gray and pixel-art edges smear. Every generator
  trick — snapping colors to a palette, recovering the pixel grid and
  re-rendering crisp cells — fights the symptom; the cause is the
  source. Ask for the original asset before rebuilding art from a
  screenshot.
- *Bounding boxes lie.* To locate a region by color, flood-fill the
  largest connected region, not the bounding box of all matching
  pixels. Our corner logo once cropped out the entire checkered frame
  of the picture, because the frame contains a few small blocks of the
  same color as the target square, and the bounding box happily
  spanned them.
- *Keep a restore path.* The layout lives in a handful of constants
  (size fractions, anchors, margins). When an experiment makes things
  worse, reverting is one edit away — and the human will say
  "restore" sooner than you think. Reverting is not failure; it is
  the loop working.

## State: defaults, toggles, and rescues

- *Record the accepted state as the default, in code.* When a look is
  approved, encode it: a `restoreDefaultDesktop` message re-applies
  the recorded theme, the theme's world color, and clears the
  wallpaper. "Take me back" is then one message, never a
  reconstruction from memory.
- *Toggle, don't stack.* A one-message toggle between the custom look
  and the recorded default keeps both states first-class. The
  off-state is a full restore, not a partial undo of the picture.
- *Do not delete what you did not create.* During debugging we removed
  a morph on the user's world as a presumed leftover; it was the
  user's. Live memory is forgiving — a deleted morph survives until
  garbage collection, and
  `ImageMorph allInstances select: [ :m | m owner isNil ]` finds the
  orphan for re-adding — but the real lesson is to ask first.
- *Back up UI assets to files.* Forms live in memory; a PNG on disk
  survives garbage collection, image loss, and rebuilds. Anything on
  the world that matters gets written to a file the moment it is
  discovered.

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
