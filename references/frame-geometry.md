# Frame geometry

`sections/navigation.el` owns this configuration's frame sizing. On graphical
Emacs exit it saves the selected frame's native pixel width and height to
`.frame-geometry` in the user's Doom data directory. On startup it reads those values and
converts them to `text-pixels` frame parameters, subtracting the current
frame's non-text area. Invalid or absent saved data falls back to defaults
chosen by display width. Terminal exits do not save geometry.

Native frame pixels and text-area pixels are different: the native size can
include internal frame elements such as fringes. It does not necessarily
include window-manager borders. A window manager or toolkit may constrain the
restored size, so treat exact dimensions as environment-dependent.

Do not divide saved pixels by character dimensions during config loading:
Doom applies the configured font later, so those dimensions can change before
the frame is displayed. See the [research record](frame-geometry-research.md)
for the observed failure and verification. The installed Emacs documentation
for `frame-pixel-width`, `frame-text-width`, and `initial-frame-alist` and
[GNU's size parameters reference](https://www.gnu.org/software/emacs/manual/html_node/elisp/Size-Parameters.html)
describe the underlying units.

## Verify changes

Run `check-parens`, `doom sync`, and `doom doctor` as required by `AGENTS.md`.
Then verify the graphical behavior after a real restart: resize a frame, exit
normally, restart, and compare sizes. For isolated tests, use a temporary
geometry file and a separate graphical display; do not overwrite the user's
saved geometry. Test existing saved native-pixel records as well as a new
save-and-restart cycle. A reload alone does not exercise startup sizing.
