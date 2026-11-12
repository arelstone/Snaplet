# Snaplet app icon

Created with the built-in image generation tool, followed by one targeted edit. The selected PNG preserves the generated alpha channel. `scripts/build-icon.sh` packages standard macOS icon sizes using sips and iconutil.

## Generation prompt

Use case: logo-brand. Asset type: production macOS app icon for Snaplet, a native menu bar utility that snaps, arranges and remembers application windows. Create one original, polished, square app icon, 1024 by 1024 pixels. A bold, simple emblem made from three softly rounded window panes snapping together into a precise asymmetric layout: one tall pane and two stacked panes, clear negative-space gutters. Use the app's existing cool blue accent character, with luminous pearl-white window shapes and restrained blue glass depth. Give the panes a subtle sense of clicking into position through one small offset edge, while the overall silhouette stays calm and balanced. Native macOS aesthetic, softly rounded square body, refined shallow bevels, soft studio lighting, crisp controlled gradients, exceptionally legible at small Dock sizes. Straight-on view, centered icon body filling about 88 percent of the square canvas. Genuinely transparent corners and space outside the rounded square. Only the icon itself; no presentation sheet, no device mockup, no app screenshot, no letters, no words, no watermark, no busy decoration. The delivered image must be a finished icon ready for app-icon packaging.

## Targeted edit prompt

Use case: precise-object-edit. This image is a finished macOS app icon for Snaplet. Preserve the blue rounded-square body, its position and size, the three pearl-white window panes, the lighting, colors and all details INSIDE the icon body. Change ONLY the transparent area outside the blue rounded-square silhouette: remove every detached cyan or blue speck, stray fragment, particle and colored pixel, especially above the top edge, under the bottom edge and to the left. The outside must be perfectly clean genuine alpha transparency, with a smooth anti-aliased icon contour. No surrounding glow cloud or new shadow, no text, no new elements, no white background. Keep the existing composition unchanged.

## Files

- `Packaging/AppIcon.png`: selected generated master, 1254 × 1254 RGBA.
- `Packaging/Snaplet.icns`: macOS icon bundle, including 16-point through 512-point sizes at 1× and 2×.
