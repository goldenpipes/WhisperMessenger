# Icon art scripts

The scripts that drew this branch's logo, rings and bubble glyphs. Each writes a PNG with
System.Drawing (Windows PowerShell 5.1); run them with `&` from PowerShell, passing an output path.

| Script | Draws | Used as |
|---|---|---|
| `make_logo.ps1 -Out <png> [-Size 256] [-NoRim]` | The addon logo: steel rim, gold ring, navy disc, blue and white chat bubbles. `-NoRim` leaves only the disc and bubbles. | `Media/icon.png`, `Media/icon_rimless.png` |
| `make_ring.ps1 -Out <png> -Style classic\|modern [-Size 256]` | A centred ring, canvas radius 22 units around an outer edge of 16. | `Media/icon_ring_classic.png` (512, saved grayscale), `Media/icon_ring_modern.png` (256, grayscale) |
| `make_glyph.ps1 -Out <png> [-Size 256] [-Part both\|back\|front]` | The two chat bubbles, white so the game can tint them. | `Media/chat_glyph_front.png`, `Media/chat_glyph_back.png` (EllesmereUI preset) |
| `make_glyph_outline.ps1 -Out <png>` | A thin outline around both bubbles. | `Media/chat_glyph_outline.png` |
| `make_bubble_glow.ps1 -Out <png> [-Size 512] [-Spread 14] [-Blur 16]` | A soft halo following the bubbles' outline. | `Media/chat_glyph_glow.png` |
| `blp2png.py <in.blp> <out.png>` | Converts a game texture (BLP2: palette, DXT1/3/5, raw) to PNG, mip 0. | Reading Blizzard's art for reference |

## Where the ring shapes come from

- **Classic** is a copy of Classic Era's minimap border, `Interface\Minimap\UI-Minimap-Border`
  (file 136468): its proportions (gold 65.5-67.5, gunmetal 67.5-72.5 of an outer 72.5) and its
  brightness every 45 degrees around the ring, lit from the top left.
- **Modern** in game is the gold portrait ring of the retail target frame, cut out of the
  game's own atlas `ui-hud-unitframe-target-portraiton-2x` (file 4642466) at runtime by
  `UI/Shared/IconRing.lua`. The `modern` style of `make_ring.ps1` is the fallback for clients
  without that art, modelled on retail's `MiniMap-TrackingBorder` (file 136430).
- Game textures were downloaded from wago.tools (`https://wago.tools/api/casc/<fileID>?download&branch=wow`
  or `branch=wow_classic_era`) for measuring only; none are shipped.

The rings are saved in grayscale (luminance) so the preset's `toggle_icon_ring` color tints them.
