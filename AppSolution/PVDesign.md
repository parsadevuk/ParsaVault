# PVDesign.md — Parsa Vault Design System

> This file covers every design rule for Parsa Vault. It applies to the iOS app first, and will scale to macOS and web later. No code lives here — only principles, decisions, and specs.

---

## 1. Design Philosophy

Parsa Vault sits at the intersection of two worlds that rarely meet: premium finance and casual learning. The design must hold both at once.

**The core feeling:** Walking into a high-end bank but finding out it is actually fun inside.

**Three pillars that guide every decision:**

1. **Trust first** — everything must feel stable, clean, and credible. Users are learning about money. The app must never feel cheap or rushed.
2. **Progress always visible** — XP, levels, balance changes, and rankings should always be one glance away. The sense of growing matters.
3. **Nothing is scary** — no overwhelming charts, no dense data walls. Every screen earns the user's attention by being easy to read and rewarding to look at.

---

## 2. Brand Identity

### App Name
**Parsa Vault**

### Tagline
**Secure your wealth. Master the markets.**

### Brand Personality
Premium but human. Confident but welcoming. Think of a knowledgeable friend who works in finance — they know their stuff, but they talk like a real person.

### Inspiration References
| Source | What We Borrow |
|--------|---------------|
| Robinhood | Clean layout, confident numbers, financial data without intimidation |
| Duolingo | XP bars, levels, streaks, the joy of small progress |
| Revolut | Premium card aesthetic, bold numbers, gold and gradient trust signals |

### Design Differentiator
The gold accent is the single strongest visual signature in the app. It appears on every interactive and active element. It signals action, quality, and reward. Everything else steps back to let gold do its work.

---

## 3. Logo

### Mark Description
A gold letter **P** in serif style with a vault combination lock dial integrated into the counter (the enclosed circular space inside the P). The dial has fine tick marks around its edge and a small central knob — mechanical, precise, and premium.

### Logo Variants
| Variant | Use Case |
|---------|----------|
| Gold P on black | App store assets, dark launch screens, splash backgrounds |
| Gold P on white | Documents, App Store listing, light contexts |
| Gold P on transparent | Inside the app — top of screens, profile, onboarding |

### Logo Sizing
| Context | Size |
|---------|------|
| Splash screen | 120×120pt |
| Onboarding and Auth screens | 60×60pt |
| Navigation or top bar | 32×32pt |

### Logo Rules
- Never stretch or distort the mark
- Never add a drop shadow to the logo itself
- Never place on a busy background without a solid backing
- Minimum clear space around the mark equals the height of the letter P

---

## 4. Colour System

### Core Palette
| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Primary Background | White | `#FFFFFF` | All screen backgrounds |
| Secondary Background | Light Grey | `#F5F5F5` | Page sub-sections, tab backgrounds |
| Card Background | Soft White | `#FAFAFA` | All card surfaces |
| Gold Accent | Warm Gold | `#D4A843` | Active elements, CTAs, progress, icons |
| Dark Gold | Deep Gold | `#B8860B` | Gold pressed/hover states |
| Primary Text | Near Black | `#1A1A1A` | All primary text |
| Secondary Text | Medium Grey | `#757575` | Captions, placeholders, inactive states |
| Border / Divider | Light Grey | `#E0E0E0` | Input borders, dividers, nav top border |
| Success Green | Market Up | `#2E7D32` | Price increases, profits only |
| Danger Red | Market Down | `#C62828` | Price drops, losses, destructive actions |
| Overlay | Scrim | `rgba(0,0,0,0.40)` | Modals and confirmation dialogues |
| Gold Glow | Ambient | `rgba(212,168,67,0.15)` | Hover/active glow on cards and badges |

### Colour Rules

**Gold (#D4A843)** is the brand's most important colour. It must:
- Appear on every active or selected state
- Be the fill of all primary buttons
- Form the active tab indicator
- Highlight the XP progress bar
- Mark level badges
- Fill focused input borders

**Green and Red** are reserved exclusively for financial data — price changes, gains, and losses. They must never be used for any other purpose in the app. A red confirmation button is the only exception (Reset Portfolio / Reset Progress).

**White** dominates backgrounds. The app breathes. Whitespace is deliberate and generous.

**Grey** handles all secondary and supporting information. It never competes with gold.

### Extended Palette for Future Platforms
As the app expands to macOS and web, a dark mode palette will be introduced:
| Role | Dark Equivalent |
|------|----------------|
| Background | `#121212` |
| Card Background | `#1E1E1E` |
| Surface | `#252525` |
| Gold Accent | `#D4A843` (unchanged) |
| Primary Text | `#F5F5F5` |
| Secondary Text | `#9E9E9E` |
| Border | `#2E2E2E` |
| Success Green | `#4CAF50` |
| Danger Red | `#EF5350` |

---

## 5. Typography

### Type Scale
| Role | Font | Weight | Size | Line Height |
|------|------|--------|------|-------------|
| Display headline | Playfair Display | Bold | 32–36pt | 1.2 |
| Screen title | Playfair Display | Bold | 24–28pt | 1.25 |
| Section heading | Playfair Display | Semi-bold | 18–20pt | 1.3 |
| Body text | Inter | Regular | 14–16pt | 1.5 |
| Subheading / label | Inter | Medium | 14pt | 1.4 |
| Caption / small text | Inter | Regular | 12pt | 1.4 |
| Numbers / prices | Inter | Bold | varies | 1.2 |
| Button text | Inter | Medium | 16pt | 1.0 |
| Error / status text | Inter | Regular | 12pt | 1.4 |

### Typography Rules

**Playfair Display** is the editorial voice of the brand. It is used only for display headlines, screen titles, and section headings. It carries the premium, premium feel that sets Parsa Vault apart.

**Inter** handles everything functional — labels, body copy, numbers, buttons, captions, and all UI text. It is clean, legible, and neutral so the numbers always stand out.

**Numbers and prices** always use Inter Bold. Give financial figures visual weight. Users need to read them instantly.

**Mixing rule:** Never place Playfair Display and Inter on the same line. Playfair sets the headline, Inter follows below it.

**Letter spacing:**
- Tagline and captions: +0.05em (slightly wider for an elevated feel)
- Headlines: default or slightly tighter (-0.01em)
- Buttons: default
- Prices: default or slightly tighter for density

**Colour on text:**
- Primary text: `#1A1A1A` always
- Secondary/supporting: `#757575`
- Gold text: used for links, active labels, and the Skip button in onboarding
- Never place white text on light backgrounds — maintain contrast at all times

**Accessibility rule:** All text at 14pt and above must pass WCAG AA contrast (4.5:1). All text at 12pt must still meet minimum legibility thresholds.

---

## 6. Spacing and Grid System

### Base Unit
All spacing is built on a base unit of **4pt**. Every spacing value is a multiple of 4.

### Named Spacing Values
| Name | Value | Use |
|------|-------|-----|
| Screen padding | 24pt | Left/right padding on all screens |
| Section gap | 24pt | Between major sections on a screen |
| Card inner padding | 16pt | Inside all card components |
| Element spacing | 12pt | Between items in a list or form |
| Small gap | 8pt | Between label and input, icon and text |
| Tiny gap | 4pt | Between caption and content |

### Grid (Mobile — iOS)
- Screen width: 390pt (iPhone 14 base reference)
- Safe area insets respected at top (status bar) and bottom (home indicator)
- Content area width: 342pt (390 minus 48pt total horizontal padding)
- Two-column grid: each column is 159pt with 24pt gutter

### Grid (macOS — future)
- Sidebar navigation: 240pt fixed width
- Content area: remaining width
- Maximum content width: 900pt, centred
- Minimum window size: 1024×680pt

### Grid (Web — future)
- 12-column grid
- Max content width: 1200px
- Column gutter: 24px
- Outer margin: 40px on desktop, 24px on mobile web

---

## 7. Component Library

### 7.1 Buttons

**Primary Button (Gold Filled)**
- Background: `#D4A843`
- Text: White, Inter Medium 16pt
- Border radius: 12pt
- Height: 52pt
- Width: full width within screen padding
- Shadow: `0 4px 12px rgba(212, 168, 67, 0.3)`
- Pressed state: background `#B8860B`, scale 0.97
- Disabled state: background `#E0E0E0`, text `#9E9E9E`, no shadow

**Secondary Button (Gold Outline)**
- Background: transparent
- Border: 1.5px solid `#D4A843`
- Text: `#D4A843`, Inter Medium 16pt
- Border radius: 12pt
- Height: 52pt
- Pressed state: background `rgba(212,168,67,0.08)`, scale 0.97

**Destructive Button (Red Outline)**
- Background: transparent
- Border: 1.5px solid `#C62828`
- Text: `#C62828`, Inter Medium 16pt
- Border radius: 12pt
- Height: 52pt
- Used only for Reset Portfolio and Reset Progress
- Pressed state: background `rgba(198,40,40,0.06)`, scale 0.97

**Text Link Button**
- No background, no border
- Text: `#D4A843`, Inter Medium 14pt
- Underline on focus (accessibility)
- Used for "Forgot password?", "Log in", "Register"

**Button Spacing Rule:** Primary and secondary buttons always sit at the bottom of a screen or section, with 24pt from screen edge. Multiple buttons stack with 12pt gap between them.

---

### 7.2 Input Fields

**Default State**
- Background: `#FFFFFF`
- Border: 1px solid `#E0E0E0`
- Border radius: 12pt
- Height: 52pt
- Horizontal padding: 16pt
- Label above field: Inter Medium 14pt `#1A1A1A`, 8pt gap to input
- Placeholder text: Inter Regular 14pt `#9E9E9E`
- Input text: Inter Regular 16pt `#1A1A1A`

**Focus State**
- Border: 1.5px solid `#D4A843`
- No glow or shadow change — just the border upgrade

**Error State**
- Border: 1.5px solid `#C62828`
- Error message below field: Inter Regular 12pt `#C62828`, 4pt gap
- Error messages are always actionable (see Content file)

**Filled / Valid State**
- Border: 1px solid `#E0E0E0`
- Input text remains `#1A1A1A`

**Password Field Addition**
- Eye icon on the right (24pt) to toggle visibility
- Icon colour: `#757575`, changes to `#D4A843` when active

**Numeric Input (Trade Screen)**
- Large display: Inter Bold 28pt, centred
- Soft animated cursor on focus
- Prefix/suffix labels: "USD" or "shares" in Inter Regular 14pt `#757575`

---

### 7.3 Cards

**Standard Card**
- Background: `#FAFAFA`
- Border radius: 12pt
- Shadow: `0 2px 8px rgba(0, 0, 0, 0.06)`
- Inner padding: 16pt
- No border (shadow provides separation)

**Accent Card (Portfolio Value)**
- Same as standard card
- Left border accent: 4px solid `#D4A843`
- Used exclusively for the main portfolio value display on Home

**Asset List Row (Markets / Holdings)**
- White background
- Padding: 12pt vertical, 0pt horizontal (full width with divider)
- Left: asset logo placeholder (36×36pt circle) + name and symbol stacked
- Right: current price (Inter Bold 16pt) + percentage change (Inter Medium 13pt, green/red)
- Divider: `#E0E0E0`, 0.5pt, inset left by 60pt (aligned past the icon)

**Leaderboard Row**
- Padding: 12pt vertical
- Rank number: Inter Bold 16pt `#1A1A1A` — 32pt fixed width column
- Username and level badge stacked left
- XP total: Inter Bold 16pt right-aligned
- Top 3: gold (#D4A843), silver (#9E9E9E), bronze (#CD7F32) rank numbers
- Current user row: background `rgba(212,168,67,0.08)` — a very faint gold wash

**Transaction Row**
- Left accent border: 3px — green for buy, red for sell
- Asset name: Inter Medium 14pt
- Details row: type + shares + price in Inter Regular 12pt `#757575`
- Total and date right-aligned
- Padding: 12pt vertical, 16pt horizontal

---

### 7.4 Progress Bar (XP)

- Track: `#F0F0F0`, height 8pt, fully rounded ends
- Fill: `#D4A843`, animates on load from 0 to current value (0.6s ease-out)
- Level label left of bar: "Level 4" Inter Medium 13pt `#1A1A1A`
- XP label right of bar: "320 / 600 XP" Inter Regular 12pt `#757575`
- On level up: brief gold pulse animation on the level badge, bar fills to 100% then resets to 0

---

### 7.5 Bottom Navigation Bar

- Background: `#FFFFFF`
- Top border: 1px solid `#E0E0E0`
- No elevation shadow
- Height: 83pt (including safe area padding on iPhone)
- Five tabs: Home, Markets, Trade (centre), History, Profile
- Icon size: 24pt
- Label: Inter Regular 11pt
- Active state: icon + label in `#D4A843`
- Inactive state: icon + label in `#757575`
- Trade tab (centre): gold filled circle 52pt diameter as the container, white icon inside — elevated above the bar slightly to signal it is the primary action
- Tab change: icon scales from 1.0 to 1.12 briefly, label fades in

---

### 7.6 Level Badges

- Shape: rounded rectangle or pill
- Background: `#D4A843`
- Text: white, Inter Bold 11pt
- Text content: "LVL 4" or the level title (e.g. "Analyst")
- Size: 48×22pt approximately
- Used on: Profile screen, Leaderboard rows, Home screen XP section

### Level Titles (for badge and profile display)
| Level | XP Required | Title |
|-------|-------------|-------|
| 1 | 0 | Apprentice |
| 2 | 100 | Trader |
| 3 | 300 | Investor |
| 4 | 600 | Analyst |
| 5 | 1,000 | Strategist |
| 6 | 1,500 | Portfolio Manager |
| 7 | 2,500 | Fund Manager |
| 8 | 4,000 | Market Expert |
| 9 | 6,000 | Wall Street Pro |
| 10 | 9,000 | Vault Master |

---

### 7.7 Charts

**Price Chart (Trade Screen)**
- Line chart only — no bars, no candles for now
- Line colour: `#D4A843`
- Line weight: 2pt
- Area fill below line: gradient from `rgba(212,168,67,0.2)` to `rgba(212,168,67,0.0)`
- Background: white
- No grid lines — keeps it clean
- Time axis labels: Inter Regular 11pt `#757575` — show 6 time points
- Price axis: hidden, price shown as large label above the chart
- Touch/tap interaction: vertical hairline cursor in `#D4A843`, price tooltip above
- Loading state: shimmer animation on the chart area

---

### 7.8 Profile Avatar

- Shape: circle, 80×80pt on Profile screen
- Background: `#D4A843`
- Initials: Inter Bold 28pt white — up to 2 letters (first name initial + last name initial)
- If no name: use first letter of username
- Border: 3pt solid white with `0 2px 8px rgba(0,0,0,0.12)` shadow

---

### 7.9 Modals and Confirmation Dialogues

- Full screen overlay: `rgba(0,0,0,0.40)` scrim
- Card centred: background white, border radius 16pt, padding 24pt
- Title: Playfair Display Bold 20pt
- Body: Inter Regular 15pt `#757575`
- Two buttons stacked: primary action on top, dismiss below
- Animation: card slides up from bottom, scrim fades in

---

### 7.10 Empty States

- Centred illustration or icon (gold outline style, 80×80pt)
- Heading: Playfair Display Bold 20pt
- Subtext: Inter Regular 14pt `#757575`, centred
- CTA button if action is available

---

### 7.11 Loading States

- Spinner: gold circular spinner, 24pt
- Skeleton / shimmer: `#F0F0F0` to `#E0E0E0` animated sweep, matches the shape of the content it replaces
- Full screen loading: logo centred, gold progress bar at the bottom (Splash only)

---

### 7.12 Toast / Snackbar Notifications

- Bottom of screen, 24pt from bottom edge (above navigation bar)
- Background: `#1A1A1A`
- Text: white, Inter Regular 14pt
- Border radius: 10pt
- Auto-dismiss: 3 seconds
- XP earned variant: left icon of gold star, text includes "+25 XP" in gold
- Error variant: red left accent border

---

### 7.13 Buy/Sell Toggle

- Pill-shaped container, full width
- Two options: "Buy" and "Sell"
- Active side: gold background, white text
- Inactive side: transparent, `#757575` text
- Transition: smooth slide of the gold pill between states

---

## 8. Screen Design Specifications

### 8.1 Splash Screen

- Background: white
- Logo centred vertically (slightly above centre — 45% from top)
- App name below logo: Playfair Display Bold 32pt `#1A1A1A`
- Tagline below name: Inter Regular 14pt `#757575`, letter spacing +0.05em
- Gold progress bar: 4pt tall, full width, pinned to bottom of screen above safe area
- Animation sequence: logo fades in at 0ms → name at 400ms → tagline at 800ms → bar starts at 1000ms
- Bar fills left to right over 3 seconds

---

### 8.2 Onboarding Slides

- White background
- Full-height scroll/pager with horizontal swipe
- Illustration area: top 55% of screen — gold line illustrations or abstract shapes relevant to each slide
- Text block: bottom 45%, padded 24pt
- Slide headline: Playfair Display Bold 26pt
- Body copy: Inter Regular 15pt `#757575`, line height 1.5
- Gold dot page indicator: centred, below text block
- Skip button: top right, Inter Medium 14pt `#D4A843`
- Next / Get Started button: gold filled primary button at the bottom

---

### 8.3 Register Screen

- White background, screen padding 24pt
- Logo 60×60pt top, 48pt from top of content area
- "Create Account" — Playfair Display Bold 28pt, 24pt below logo
- Subtitle — Inter Regular 14pt `#757575`, 8pt below title
- Form fields stacked with 12pt gap: Full Name, Username, Email, Website (optional tag in label), Password, Confirm Password
- Password fields show strength indicator below (weak/good/strong in grey/gold/green)
- Primary gold button: "Create Account", 32pt below last field
- Log in link: centred, Inter Regular 14pt with gold "Log in" text

---

### 8.4 Login Screen

- Same structure as Register but shorter
- "Welcome Back" — Playfair Display Bold 28pt
- Subtitle: "Log in to your vault."
- Two fields: Email or Username, Password
- "Forgot password?" — right-aligned gold text link, 8pt below password field
- Primary gold button: "Log In"
- Register link below

---

### 8.5 Home Screen

- Top bar: greeting left-aligned, notification bell icon right (24pt, `#1A1A1A`)
- Greeting: "Good morning, [name]" — Inter Medium 16pt
- Portfolio Value Card (accent card with gold left border): "Total Portfolio Value" label, large Inter Bold 28pt number, percentage change since last session in green or red
- Two equal cards side by side: "Cash" and "Holdings" — Inter Medium 13pt label, Inter Bold 20pt value
- XP Section: level badge + progress bar + XP text — 24pt section gap from above
- "My Holdings" section heading: Playfair Display Semi-bold 18pt
- Holdings list: asset rows with live prices
- Empty state if no holdings

---

### 8.6 Markets Screen

- Search bar at top: full width, 52pt height, `#F5F5F5` background, border radius 12pt
- Search icon left-inside, `#9E9E9E`
- Tabs row: "Stocks" and "Crypto" — gold underline indicator on active tab
- Asset list below: scrollable
- Pull-to-refresh with gold spinner
- Each row: 60pt height minimum

---

### 8.7 Trade Screen

- Back arrow top left
- Asset name: Playfair Display Bold 22pt
- Asset symbol: Inter Regular 14pt `#757575`
- Current price: Inter Bold 32pt `#1A1A1A` — centred, with green/red percentage change beside it
- Chart: 200pt height, gold line chart with 24hr data, with time selector tabs (1D, 1W, 1M, 3M)
- Buy / Sell toggle below chart
- Input section: "Shares" or "Amount" toggle, large number input
- Summary row: "Estimated Total" label left, calculated value right
- Available cash / shares note below: Inter Regular 12pt `#757575`
- Confirm button pinned to bottom: "Confirm Buy" or "Confirm Sell"

---

### 8.8 History Screen

- Title: "Transaction History" — Playfair Display Bold 24pt
- Filter row: "All", "Buys", "Sells" pill buttons in gold/outline style
- Transaction list, reverse chronological
- Date section headers (Today, Yesterday, specific date) in Inter Medium 12pt `#757575`
- Transaction rows as defined in Card section

---

### 8.9 Profile Screen

- Top section: avatar circle centred, username below (Inter Bold 18pt), email below (Inter Regular 13pt `#757575`), website as tappable gold link
- Level badge below username (inline or below)
- XP progress bar full width, 24pt padding
- Two equal stat cards: "Cash Balance" and "Net Worth"
- Action buttons section: Deposit Cash (secondary), Withdraw Cash (secondary)
- Change Password (secondary, smaller)
- Divider
- Destructive section: Reset Portfolio and Reset Progress — red outline buttons with a warning subtext below each

---

### 8.10 Leaderboard Screen

- Title: "Leaderboard" — Playfair Display Bold 24pt
- Three tabs: "All Time", "This Week", "Today"
- Top three rows: slightly elevated treatment — gold, silver, bronze rank numbers with respective colours
- Standard rows below with rank, avatar initials, username, level, XP
- Current user row always highlighted in faint gold wash
- Sticky bottom bar: user's current rank and XP if they are not visible in the viewport

---

## 9. Animation and Motion

All animations in Parsa Vault are subtle, fast, and purposeful. Nothing should feel flashy or drag on longer than needed.

| Element | Animation | Duration | Easing |
|---------|-----------|----------|--------|
| Splash screen elements | Staggered fade in (0ms, 400ms, 800ms, 1000ms) | 400ms each | ease-out |
| Onboarding slides | Horizontal page slide | 300ms | ease-in-out |
| Screen transitions | Fade or slide right | 250ms | ease-in-out |
| XP progress bar fill | Smooth fill from 0 to current on load | 600ms | ease-out |
| Level up event | Gold pulse on badge (scale 1.0 → 1.15 → 1.0) | 400ms | spring |
| Level up bar | Fill to 100% then reset to 0 with new level | 800ms | ease-in-out |
| Price change (live) | Green or red flash then back to black | 600ms | ease-out |
| Button press | Scale 0.97 | 100ms | ease-in |
| Buy/Sell toggle | Gold pill slides between states | 200ms | ease-in-out |
| Card entrance (lists) | Fade + slight translate up (8pt) | 200ms staggered | ease-out |
| Modal appear | Slide up + scrim fade | 280ms | ease-out |
| Toast notification | Slide up from bottom | 220ms | spring |
| Chart line draw | Path draws from left to right on load | 500ms | ease-out |

**Motion rules:**
- No looping animations except loading spinners and skeleton shimmer
- No bouncing or elastic effects except level-up celebration
- All durations under 600ms for interactions, under 800ms for transitions
- Respect user's reduce-motion accessibility setting — fall back to instant or fade-only

---

## 10. Iconography

### Icon Style
- Line icons, not filled (except the active state in the bottom nav)
- Stroke weight: 1.5pt
- Rounded corners and line caps
- Size: 24pt standard, 20pt compact, 28pt for emphasis

### Active State
- Bottom nav active icons: filled version of the same icon in gold

### Icon Set Reference
Use a consistent set throughout — avoid mixing icon families. Recommended source: a single unified set with both outline and filled variants.

### Key Icons Used
| Screen / Element | Icon |
|-----------------|------|
| Home tab | house / vault door |
| Markets tab | chart line up |
| Trade tab (centre) | swap / exchange arrows |
| History tab | clock / receipt |
| Profile tab | person / user |
| Search | magnifying glass |
| Notification | bell |
| Password visibility | eye / eye-off |
| Deposit | arrow down into tray |
| Withdraw | arrow up from tray |
| Settings | gear |
| Back | chevron left |
| Rank 1 | gold medal or crown |
| Asset price up | triangle up (green) |
| Asset price down | triangle down (red) |

---

## 11. Accessibility

- Minimum touch target: 44×44pt for all tappable elements
- Colour contrast: all text meets WCAG AA (4.5:1 for normal text, 3:1 for large text)
- Do not use colour alone to convey meaning — pair green/red with a label or icon
- All form fields have visible labels (not just placeholders)
- Focus states visible on all interactive elements (for web and macOS keyboard navigation)
- Screen reader labels on all icon-only buttons
- Reduce motion: respect system preference and fall back to instant/fade transitions

---

## 12. Platform Adaptation Notes

### iOS (Primary)
- Follow Apple Human Interface Guidelines where they do not conflict with the Parsa Vault design system
- Use native iOS navigation patterns (back swipe, modal cards)
- Bottom navigation bar sits above home indicator safe area
- Haptic feedback on: button taps, trade confirms, level-up events, error states

### macOS (Future)
- Side navigation panel (240pt) replaces bottom tab bar
- Larger content area — use multi-column layouts where appropriate
- Mouse hover states on all interactive elements (subtle gold tint on card hover)
- Menu bar integration with app name and key shortcuts
- Keyboard shortcuts for primary actions (Cmd+T for Trade, Cmd+M for Markets, etc.)
- Window chrome follows macOS conventions (traffic lights, title bar)

### Web (Future)
- Responsive breakpoints: 375px (mobile), 768px (tablet), 1024px (desktop), 1280px (wide)
- Sticky top navigation bar on desktop replaces bottom tab bar
- Hover states on all interactive elements
- Keyboard navigation fully supported
- Max content width 1200px, centred
- Web-specific: loading skeleton on all data-fetching areas

---

## 13. Design Anti-Patterns to Avoid

The following choices are explicitly off-limits:

- No purple gradients or generic "fintech" blue gradients
- No dense data tables visible on load — always start with a summary
- No more than two font families ever
- No green or red used anywhere except financial data
- No full-screen pop-up ads or interstitials of any kind
- No dark patterns — confirmation dialogues are clear and honest
- No hiding the "go back" option or trapping users in flows
- No animated GIFs or stock-photo style illustrations
- No icon inconsistency — one icon set throughout
- No text smaller than 11pt anywhere in the UI
- No placeholder text that disappears without a visible label
- No buttons without pressed/disabled states defined

---

## 14. Design Review Checklist

Before any screen is considered complete, it must pass:

- [ ] Gold appears on at least one active or interactive element
- [ ] Spacing follows the 4pt grid system
- [ ] Typography uses only Playfair Display and Inter in defined weights
- [ ] Green and red appear only on financial data
- [ ] All touch targets are minimum 44×44pt
- [ ] Empty state is defined for any list or data screen
- [ ] Loading state is defined for any screen with async data
- [ ] Animations are defined and within the duration limits
- [ ] Screen works with placeholder/no data, partial data, and full data
- [ ] Screen is visually consistent with all other screens in the app
