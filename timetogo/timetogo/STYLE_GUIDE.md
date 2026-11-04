# Style Guide Reference

## Typography Styles

Text styles come from the Figma file (Timetogo, "Final/…" styles) and live in `TextStyles.swift`.

### Usage in Views

```swift
Text("Where do you leave?")
    .typography(.title)

Text("Home station")
    .typography(.main)
```

For a one-off size with no Figma style, use `scaledFont` instead of `.font(.system(size:))`:

```swift
Text("8:02 AM")
    .scaledFont(size: 56, weight: .bold)
```

### Text size (Dynamic Type)

Every size below is the design size at the default text size. `typography` and `scaledFont`
grow and shrink it with Settings → Display → Text Size. The app caps text at the largest
standard size (`xxxLarge`) in `timetogoApp.swift`. Don't use `.font(.system(size:))` directly:
it ignores the setting.

### Style Specifications

| Style | Figma | Weight | Size | Tracking | Line height | Used for |
|-------|-------|--------|------|----------|-------------|----------|
| `.display` | Old/H1 | Bold | 40 | -2 | auto | "Settings" page title |
| `.h1` | Final/H1 | Bold | 28 | -0.5 | auto | Onboarding step titles, Back home intro |
| `.h2` | Final/H2 | Bold | 24 | -0.5 | auto | Journey and group titles, success title, destination cards |
| `.h3` | Final/H3 | Bold | 18 | -0.5 | auto | Card titles, field values, "Next commute" |
| `.h4` | Final/H4 | Semibold | 16 | 0 | auto | Step counter, station names |
| `.h5` | H5 | Semibold | 15 | 0 | auto | Button labels, line badges |
| `.large` | Final/Large | Medium | 16 | -0.5 | 140% | Body copy, settings rows, departures |
| `.main` | Final/Main | Medium | 14 | -0.5 | auto | Field labels, day chips |
| `.small` | Final/Small | Regular | 13 | 0 | auto | Line status, minutes chips |
| `.footnote` | Final/Footnote | Regular | 11 | 0 | auto | Secondary lines ("Northern", "Powered by TfL") |

Figma sets Final/H4, H5, Final/Small and Final/Footnote in Inter; the app uses SF Pro throughout.

## Color Palette

### Usage

```swift
.foregroundColor(.white)
.foregroundColor(.grey10)
.foregroundColor(.grey30)
.foregroundColor(.grey50)
.foregroundColor(.black)

.background(.white)
.fill(.grey10)
```

### Color Values

| Name | Hex Code |
|------|----------|
| White | #FFFFFF |
| Grey 10 | #EBEBEB |
| Grey 29 | #CDCDCD |
| Grey 30 | #949494 |
| Grey 40 | #686868 |
| Grey 50 | #3E3E3E |
| Black | #000000 |
| Bright bg | #FFF8EF |
| Bright green | #3FEB00 |


## Radius and spacing

The Figma variables live in `Layout.swift`. Use them instead of numbers.

| Token | Value | Figma variable | Used for |
|-------|-------|----------------|----------|
| `Radius.extraSmall` | 8 | Extra small | Journey page: line badge, delay pill |
| `Radius.smallElement` | 14 | Small element | Leave-time card's line-status pill (padding 12 × 6), success page's next-commute block |
| `Radius.element` | 18 | Element | Buttons, fields, day chips, destination cards, minutes chip, journey page's train cards |
| `Radius.smallBlock` | 22 | Small block | Leave-time card, departures card, Settings cards |
| `Radius.medium` | 12 | Corner/Medium | Not in use at the moment |
| `Radius.card` | 36 | none yet | Large white cards: intro, setup, success, Back home |
| `Radius.sheet` | 38 | none yet | Journey sheet top corners |
| `Spacing.padding` | 20 | Padding | Screen edges to the large cards (sides and bottom) |
| `Spacing.paddingInside` | 24 | Padding inside | Inside the large cards |

## Setup step template

Build every setup step with `SetupStepLayout` (`Components/SetupStepLayout.swift`), from Figma "Setup - Step 1":

- Bright bg screen, step counter and H1 title 29pt from the sides.
- Illustration in a 402×263 frame, 20pt under the title, resting on the card. Export the artwork at exactly that frame (1206×789 @3x); it fills the width and only shrinks on short phones.
- White card: `Spacing.padding` from the sides and the screen bottom, `Radius.card` corners, `Spacing.paddingInside` inside, shadow 8% black. It takes the remaining height.
- Fields at the top of the card, 24pt apart and outlined (Grey 29). The button sits at the bottom.
- Step 3 puts the arrival time first and the day row 48pt under it (`fieldSpacing: 48`).
