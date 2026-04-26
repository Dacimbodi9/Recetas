# Recetas - Complete App Overview

**Recetas** is a premium Flutter application designed for modern home cooks who value both functionality and aesthetic beauty. It transitions the traditional recipe box into a digital, AI-enhanced experience while maintaining a warm, organic feel.

---

## 🌟 Vision & Purpose
Recetas is born from the idea that cooking should be an inviting, tactile experience, even when digitized. The app focuses on **offline-first reliability**, **privacy-centric data management**, and a **premium visual language** that feels more like a physical cookbook than a utility app.

### Target Audience
- **Home Chefs:** Individuals looking for a beautiful way to organize their culinary repertoire.
- **Meal Planners:** Users who need to manage their weekly nutrition efficiently.
- **Diet-Conscious Users:** People with specific dietary restrictions (Gluten-Free, Vegan, etc.) who need a smart system to filter content.
- **Tech-Savvy Cooks:** Users who enjoy AI-assisted recipe generation and modern sharing methods like QR codes and deep links.

---

## 🍳 Focus & Key Features

### 1. Intelligent Recipe Management
- **Smart Ingredient Matching:** Highlights which ingredients the user already has and identifies what's missing.
- **Dietary Safeguards:** Real-time visual indicators (red dots) for recipes that don't match the user's dietary profile.
- **Multi-Level Organization:** A sophisticated folder and sub-folder system with custom icons for professional-grade categorization.
- **Rich Content Editing:** Full control over steps, detailed ingredient quantities, nutrition facts, and custom imagery.

### 2. Sophisticated Meal Planning
- **Interactive Calendar:** A seamless weekly view for assigning meals.
- **Meal Templates:** Design "Weekly Staples" (e.g., a standard healthy week) and apply them to any calendar range with one tap.
- **Categorized Planning:** Specific slots for Breakfast, Lunch, Dinner, and Snacks.
- **Progressive Disclosure:** Simple tap-to-complete actions to keep track of daily goals.

### 3. Data Sovereignty & Sharing
- **Offline-First:** All data lives on the device; no cloud account is required for core functionality.
- **Compressed Sharing:** Uses Gzip + Base64 encoding to share full recipes through tiny strings, QR codes, or custom `.receta` files.
- **Smart Import:** Detects conflicts during import and allows for merging or skipping duplicates.

### 4. AI Culinary Assistant
- **Cross-Provider Support:** Integrated with both **Google Gemini** and **OpenAI**.
- **Context-Aware:** Generates recipes that automatically adopt the app's visual style and formatting.

---

## 🎨 Design System ("The Artisan Look")
*Recetas uses a curated design language to evoke a warm, organic kitchen environment.*

### Core Philosophy
- **Light Mode: "Artisan Bakery"** — Toasted parchment, rich creams, and earthy natural tones.
- **Dark Mode: "Rustic Organic Kitchen"** — Deep woods, truffle tones, and herbal sage accents.

### Color Palette
| Token | Light (Bakery) | Dark (Kitchen) | Usage |
| :--- | :--- | :--- | :--- |
| **Background** | `#EBE6DD` (Parchment) | `#141513` (Truffle) | Main scaffold |
| **Surface** | `#F6F3EC` (Cream) | `#222420` (Olive Wood) | Cards & Dialogs |
| **Primary** | `#6B8738` (Olive) | `#8BA85D` (Sage) | Actions & Branding |
| **Secondary** | `#B54921` (Terracotta) | - | Accents |
| **Text** | `#2E2A27` (Mocha) | `#F2EFE9` (Flour) | Typography |

### Typography
- **Headlines:** `Playfair Display` — Elegant, traditional, premium serif for recipe names and titles.
- **Interface:** `Nunito` — Rounded, friendly, and highly legible for instructions and lists.

### Visual Principles
- **Organic Geometry:** Generous `18px` corner radiuses for a soft feel.
- **Flat Depth:** Depth is achieved through subtle 1px borders (5-10% opacity) and surface contrast rather than heavy Material shadows.
- **Tactile Transitions:** Uses `OpenContainer` (Material Motion) to expand cards smoothly when tapped.

---

## 🏗 Technical Architecture

### Tech Stack
- **Framework:** Flutter (Material 3)
- **State:** `ValueNotifier` & `ValueListenableBuilder`
- **Storage:** `SharedPreferences` (Settings/State) & `sqflite` (Structured Data)
- **Integrations:** `dio` (Networking), `qr_flutter` (Sharing), `intl` (Localization).

### 📂 Directory Structure
```text
lib/
├── main.dart          # Entry point & Theme Engine
├── models/            # Recipe, PlannedMeal, FavoriteFolder
├── services/          # SettingsManager, RecipeManager, MealPlanManager
├── screens/           # UI logic (Monolithic screens.dart for performance)
├── widgets/           # Custom UI components (Cards, Buttons)
└── l10n.dart          # Localization & Translation Engine
```

---

## 🔄 Data Flow

```mermaid
graph TD
    UI[UI Components] -->|Action| VM[Managers/Services]
    VM -->|Persist| SP[Shared Preferences]
    VM -->|Query| DB[SQLite DB]
    Assets[recipes.json] -->|Default Load| VM
    VM -->|Notify| UI
```

---

## 🚀 CI/CD & Deployment
- **Pipeline:** Custom `.yml` workflow for automated builds and scanning.
- **Deployment:** Integrated with Fastlane for store metadata and screenshot management.
- **Compatibility:** Optimized for iOS and Android with custom splash screens and adaptive icons.

---

*Last Updated: 2026-04-26*
