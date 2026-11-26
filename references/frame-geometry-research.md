# Frame geometry research

Checked 2026-11-26 against the installed Emacs 30.2 and Doom configuration.
This is a historical record of the sizing investigation; current behavior and
verification guidance are in [frame geometry](frame-geometry.md).

## Findings

- Emacs frame `width` and `height` integers describe character columns and
  text lines. `(text-pixels . N)` specifies text-area pixels instead. See
  [GNU's size parameters reference](https://www.gnu.org/software/emacs/manual/html_node/elisp/Size-Parameters.html)
  and the installed `make-frame` documentation.
- Native frame and text-area pixel dimensions differ. In the isolated graphical
  test, the native width exceeded the text width by 16 pixels. The installed
  `frame-pixel-width` and `frame-text-width` documentation defines the distinction.
- Doom initializes its configured font on `after-init-hook`. A conversion from
  pixels to character units during configuration loading can therefore use
  different font metrics from those used when the frame is displayed. The
  installed Doom `lisp/doom-ui.el` is the source for the initialization order.

## Observed behavior

With a saved native size of 1920 by 2075 pixels, the earlier character-based
conversion produced a 3856 by 4270 frame in a fresh Doom session under Xvfb.
Using text-pixel parameters and allowing for the non-text area restored the
same record to 1920 by 2075. In a separate isolated test, a new 1520 by 1400
frame was saved to a temporary geometry file and restored at the same size in
the next session. The second session injected that temporary file's geometry
into its initial frame parameters before those settings were applied; it did
not replace the user's saved file or test an unmodified startup path. The tests
used Emacs 30.2, a virtual X display, and no window
manager; other toolkits and window managers may constrain sizes differently.

The character conversion was rejected because it depended on font metrics
before Doom applied the configured font. The accepted approach retains the
existing native-pixel record format and uses Emacs's text-pixel parameters.
It does not establish pixel-exact behavior for every display environment.
