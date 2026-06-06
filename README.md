# Recetas 🍳

A beautiful, privacy-focused recipe management and meal planning application built with Flutter. **Recetas** helps you organize your culinary life, track your nutrition, and automate your shopping without compromising your data privacy.

## 🚀 Getting Started

This project is not yet available for download in Google Play Store or Apple App Store. However, you can download the APK file and install it on your Android device from my [website](https://recetasinfo.netlify.app/) or from this [github repository](https://github.com/dacimbdi/recetas/blob/main/app-release.apk).

## ✨ Features

### 📅 Weekly Meal Planner & Templates
*   **Drag & Drop Planning:** Visually plan your entire week's meals.
*   **Meal Limits:** Track whether you are skipping meals or exceeding your daily meal limits.
*   **Weekly Templates:** Create routine templates (e.g., "Healthy Week") and instantly populate an upcoming week in seconds.

### 🛒 Automated Shopping List
*   **Auto-Generated:** Your shopping list builds itself based on the meals you've planned in the Meal Planner.
*   **Smart Grouping:** Ingredients are neatly categorized (Vegetables, Meats, Dairy, etc.).
*   **Manual Adjustments:** Add one-off items to the list or cross them off interactively as you walk down the supermarket aisles.

### 📊 Nutritional Dashboard
*   **Macro Tracking:** Keep an eye on your daily intake of Calories, Proteins, Carbohydrates, and Fats.
*   **Visual Charts:** Beautiful, interactive circular progress charts showing your current macro distribution compared to your goals.
*   **Automatic Calculation:** Nutrition info automatically propagates from your recipes.

### 🤖 AI Recipe Import
*   **From Photo to Recipe:** Snap a picture of a physical cookbook or screenshot a recipe online. 
*   **BYO Key:** Bring your own API key (Gemini, OpenAI, etc.) and let AI intelligently parse the image and extract the ingredients, steps, and macros directly into the app.

### 🧑‍🍳 Recipe Management & Smart Search
*   **Custom Recipes:** Create, edit, and personalize your recipes with custom photos, detailed steps, and tags.
*   **Search by Ingredient:** "What can I cook with this?" Select ingredients from your pantry to find matching recipes.
*   **Dietary Compliance:** Set permanent dietary filters (Vegan, Gluten-Free, Keto, etc.). The app highlights incompatible recipes and warns you automatically.
*   **Organization:** Group your favorite recipes into custom folders (e.g., "Weekly Dinner," "Christmas," "Desserts").
*   **Undo System:** Accidentally deleted a recipe or meal? Instantly restore it using the undo snackbar!

### 📱 Premium UX & Privacy
*   **Offline-First:** All your data stays on your device. No analytics, no tracking, no external servers. 
*   **Data Portability:** Full JSON Export/Import support to back up or transfer your data locally.
*   **Bilingual Support:** Fully translated in both English and Spanish (Dynamic switching based on system language).
*   **Premium Aesthetics:** Features an elegant layout with dynamic empty states, skeleton loading screens, and a soothing dark mode designed to reduce eye strain.

## 🛠️ Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/) (3.x+)
*   **Language:** [Dart](https://dart.dev/)
*   **Architecture:** Clean, modularized architecture with active state management.
*   **Persistence:** `sqflite` (SQLite) & Shared Preferences for fast, local storage.
*   **Design System:** Custom theme engine with WCAG AA compliant contrast ratios.

## 🔒 Privacy Policy

**Recetas** is designed with **Privacy by Design**.
*   We do not collect usage data.
*   We do not upload your photos.
*   All backups are local files entirely under your control.
*   Your API keys are stored securely using `flutter_secure_storage`.

## 📄 Credits

Developed by **Daniel Cimbollek Díaz**.

*   *Icons powered by Cupertino Icons & Material Design.*
