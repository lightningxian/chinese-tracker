# Easy Study brand assets

Official logo files extracted from `Logo EasyStudy HD.zip`.

## Files

| File | Use |
|------|-----|
| `logo_primary.png` | Full horizontal logo — 易华文教中心 + EASY STUDY (dark background artwork) |
| `logo_with_tagline.png` | Same + white tagline: Mandarin Education Center & China Education Consultant |
| `mascot_pencil.png` | Pencil mascot with graduation cap and 易华 |
| `mascot_board.png` | Board graphic (brand element) |
| `mascot_writing.png` | Calligraphy / writing graphic (brand element) |

## In the app

- **Login:** `AppLogo` widget — `lib/core/widgets/app_logo.dart`
- **Web favicon / PWA icons:** generated from `mascot_pencil.png` in `web/icons/`

## Brand colors (from logo artwork)

| Token | Hex | Usage |
|-------|-----|--------|
| Brand yellow | `#F5B800` | EASY STUDY pill, pencil body |
| Brand green | `#00A651` | Chinese calligraphy 易华文教中心 |
| Brand teal | `#006B54` | EASY STUDY lettering, pencil tip |
| Brand black | `#000000` | Logo background, graduation cap |

App UI chrome still uses navy/teal (`lib/core/theme/app_theme.dart`) until a full visual rebrand.

## Figma

See [FIGMA_AI_SPEC.md](../design/FIGMA_AI_SPEC.md) for prompts and typography.
