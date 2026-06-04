# Recetas Design System

## Core Philosophy
The design of **Recetas** is built around the concept of a warm, inviting, and organic kitchen environment. It transitions between two primary aesthetic themes:
- **Light Mode: "Artisan Bakery"** — Evoking the feeling of a sunlit bakery with toasted parchment, rich creams, and earthy natural tones.
- **Dark Mode: "Rustic Organic Kitchen"** — Inspired by a deep forest at twilight, with dark woods, truffle tones, and herbal sage accents.

---

## Color Palette

### Light Mode (Artisan Bakery)
| Token | Hex | Name | Usage |
| :--- | :--- | :--- | :--- |
| **Background** | `#EBE6DD` | Toasted Baking Paper | Main scaffold background |
| **Surface** | `#F6F3EC` | Pastry Cream | Cards, dialogs, and elevated surfaces |
| **Primary** | `#6B8738` | Olive Leaf | Action buttons, active states, branding |
| **Secondary** | `#B54921` | Brick Terracotta | Accents, warnings, secondary actions |
| **Text** | `#2E2A27` | Dark Mocha | Primary headings and body text |

### Dark Mode (Rustic Organic Kitchen)
| Token | Hex | Name | Usage |
| :--- | :--- | :--- | :--- |
| **Background** | `#141513` | Black Truffle | Deep background layer |
| **Surface** | `#222420` | Dark Olive Wood | Card surfaces and overlays |
| **Primary** | `#8BA85D` | Sage Rosemary | Primary buttons and icons |
| **Text** | `#F2EFE9` | Warm Cream | High-readability light text |

---

## Typography
The app uses a premium font pairing to balance artisan charm with modern readability.

- **Headlines: Playfair Display**
  - *Usage:* Page titles, recipe names, card headings.
  - *Vibe:* Elegant, traditional, premium serif.
- **Body & Interface: Nunito**
  - *Usage:* Instructions, ingredient lists, navigation labels, inputs.
  - *Vibe:* Rounded, friendly, high legibility.

---

## Key Design Principles

### 1. Organic Geometry
- **Cards & Dialogs:** Use a generous `18px` corner radius to maintain a soft, approachable feel.
- **Chips & Small Elements:** Use a `12px` radius.
- **Inputs:** Use a `16px` radius.

### 2. Flat Depth
Instead of heavy Material Design shadows, depth is achieved through:
- **Subtle Borders:** `1px` borders with low opacity (`5-10%` alpha).
- **Surface Color Contrasts:** Using the distinct difference between Background and Surface colors.
- **Zero Elevation:** Cards and AppBars typically have `elevation: 0`.

### 3. Tactile Feedback
- **OpenContainer Transitions:** Smooth, material-style expansion when opening recipes.
- **Subtle Micro-interactions:** Animated checkmarks, scale transitions on buttons, and tonal feedback on tap.

### 4. Semantic Indicators
- **Dietary Alerts:** Small red dots on recipe cards indicate incompatibility with the user's dietary filters.
- **Matched Ingredients:** Bold text and highlighted chips indicate ingredients the user already has.

---

## Component Specifications

### Cards
- **Background:** `theme.cardColor`
- **Border:** `1px` solid, `Colors.black.withOpacity(0.05)` (Light) / `Colors.white.withOpacity(0.1)` (Dark).
- **Padding:** Standard `14px` internal padding for consistency.

### Buttons
- **Primary:** Filled with primary color, white text.
- **Tonal:** Uses primary color with `10-20%` alpha for a softer, integrated look.
- **Action Icons:** Encapsulated in containers with `10%` alpha primary background and `10px` radius.

### Navigation
- **NavigationBar:** Transparent or matching background color.
- **Indicator:** Primary color with low opacity pill shape.
