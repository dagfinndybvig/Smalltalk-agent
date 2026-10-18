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
  favor of what the picture already was. And when even that was too
  much, the accepted desktop was the simplest composition of all: one
  uniform color — measured as the dominant color of the artwork's own
  light square — with only the corner logo on it. Derive everything
  from the source; invent nothing.

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
theme — the custom theme we built was an education, not a need. We
even re-imported and re-applied that custom theme a second time before
reverting again: the user wanted *stock* chrome with orange accents,
not a restyled chrome. The refined rule: **personalize the chrome, keep
the theme stock**. Two surgical patches on stock methods deliver the
accents — window border color/width in the theme's border
configuration, and the title-bar stripe accents (which, it turns out,
Pharo never recolors at all: the stock stripes are `Morph`'s default
blue, untouched by any theme).

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
- *Theme-instance settings do not survive `beCurrent`.* Making a theme
  current builds a fresh instance; anything set on the old instance
  (our window shadows, for example) is gone. Bake such settings into
  the restore/toggle method so every state transition re-applies them.
- *State can vanish silently — read it, don't assume it.* After a
  stretch of theme churn, the wallpaper morph was simply gone and the
  desktop was "all gray"; nothing had errored. After any churn, read
  the world's actual structure (background morph present? theme?
  colors?) instead of trusting the intended sequence of steps.
- *`git checkout <branch> -- <path>` stages what it restores.* Deleting
  the file from disk later does not unstage it, and a subsequent
  commit can sweep in material that was never meant to be published.
  Before pushing anything that touched private files, read the commit:
  `git show --stat HEAD` — the stat line is the last line of defense.

## Building your own setup

With your own artwork — and this recipe is the whole method, in order:

1. **Get a clean source.** The original asset, not a screenshot; if you
   must work from a screenshot, expect washed colors and smeared edges
   (see "Aesthetics, learned the hard way").
2. **Write a generator** (Python, Smalltalk, anything) that:
   - content-crops the art (bounding box of non-background pixels —
     never hardcode crop coordinates),
   - denoises the border and samples colors a little inside it,
   - locates regions by flood-filling the largest *connected*
     component, never by a bounding box of matching colors,
   - renders at the size reported by the live image
     (`World extent`), never a fixed size.
3. **Install through the native mechanism:**

   ```smalltalk
   World backgroundImage: aForm layout: #scaled
   ```

   Wrap it in one class-side `installWallpaper` message. But note:
   `#scaled` *stretches to the bounds* — a bitmap wallpaper distorts
   whenever the window's aspect ratio changes. If your desktop is one
   uniform color, skip the bitmap entirely: a solid world color plus a
   fixed-size, locked logo morph is aspect-proof under any resize.
4. **Keep the theme stock; accent the chrome if you want more.**
   Window border color and width in `configureWindowBorderFor:`, and
   the title-bar stripe accents in `setStripeColorsFrom:` (stock Pharo
   never recolors the stripes — they are `Morph`'s default blue).
   Small patches, big effect, fully reversible.
5. **Record your states in code.** An `install` message for the custom
   look, a `restoreDefault` message for the stock one, and a
   one-message toggle between them. Re-apply any theme-instance
   settings inside the restore — they do not survive `beCurrent`.
6. **Persist.** Save the image (`Smalltalk snapshot: true andQuit:
   false`), keep the generator and classes under version control,
   re-run the generator after a world resize — and if your art is
   someone else's copyright, keep it out of the published repository.

### If something goes wrong

Every failure mode below happened to us at least once:

| Symptom | Cause | Fix |
|---|---|---|
| Clicks drag or "multiply" the background | The background morph is not locked | Install via `backgroundImage:layout:`, which locks it |
| Huge white or gray bands across the field | Border noise or a washed-out source, propagated by edge extension | Denoise the border, sample colors inside it, get a cleaner source |
| A logo crops out far more than its subject | A bounding box of matching colors swallowed same-colored neighbors | Flood-fill the largest connected region instead |
| Desktop goes "all gray" after theme work | The background morph vanished silently — nothing errored | Reinstall, and read the world's actual structure after any churn |
| Custom settings lost after a theme switch | `beCurrent` builds a fresh theme instance | Re-apply instance settings in the restore/toggle method |
| The picture squishes or stretches when the window is resized | `backgroundImage:layout: #scaled` stretches the bitmap to the new bounds — non-uniformly | For a uniform-color desktop, don't use a bitmap: solid world color + a fixed-size locked logo morph. Otherwise regenerate per extent |
| Private material about to be published | `git checkout <branch> -- <path>` stages files; deleting from disk does not unstage | Read `git show --stat HEAD` before pushing |

The Pharo image already contains everything else you need — the theme
hierarchy, the color configurators, the icon assets (look at
`Smalltalk ui icons`), and the desktop-image machinery. The method is
just: find it, use it, and lock what should not move.
