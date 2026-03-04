import os

metadata = {
    "es-ES": {
        "title.txt": "Recetas",
        "short_description.txt": "Gestor de recetas offline enfocado en privacidad con búsqueda por ingredientes y dieta.",
        "full_description.txt": (
            "Recetas es una aplicación gratuita para gestionar tus recetas con privacidad por diseño.\n\n"
            "✨ Características\n\n"
            "*  **Offline y Privado:** Todos tus datos se guardan en el dispositivo, sin analíticas ni rastreo.\n"
            "*  **Búsqueda Inteligente:** Búsqueda rápida por nombre o por ingredientes para saber qué cocinar con lo que tienes.\n"
            "*  **Dietas:** Filtros personalizados vegano, vegetariano, sin gluten, sin lactosa, etc con avisos de incompatibilidad.\n"
            "*  **Organización:** Carpetas, valoraciones y favoritos.\n"
            "*  **Experiencia Premium:** Interfaz minimalista y personalizable centrada en el modo oscuro.\n\n"
            "Descubre más de 1000 recetas que vienen integradas y compártelas de forma rápida sin comprometer tu información personal."
        )
    },
    "en-US": {
        "title.txt": "Recetas",
        "short_description.txt": "Offline, privacy-focused recipe manager with ingredient and diet search.",
        "full_description.txt": (
            "Recetas is a free, beautifully designed app to manage your recipes with privacy in mind.\n\n"
            "✨ Features\n\n"
            "*  **Offline & Private:** All your data stays on your device. No tracking, no servers.\n"
            "*  **Smart Search:** Fast fuzzy search by name, or select ingredients you have in your fridge to find matching recipes.\n"
            "*  **Dietary Compliance:** Permanent dietary filters (Vegan, Gluten-Free, Keto, etc.) with incompatible recipe warnings.\n"
            "*  **Organization:** Create folders, rate your recipes, and manage your favorites.\n"
            "*  **Premium Experience:** Beautiful dark mode aesthetics and highly customizable settings.\n\n"
            "Discover over 1,000 built-in recipes, create your own, and fully control your data."
        )
    }
}

base_path = r"c:\Users\danie\Apps\Recetas\fastlane\metadata\android"

for lang, files in metadata.items():
    folder_path = os.path.join(base_path, lang)
    os.makedirs(folder_path, exist_ok=True)
    
    for filename, content in files.items():
        with open(os.path.join(folder_path, filename), "w", encoding="utf-8") as file:
            file.write(content)

print("Fastlane metadata generated successfully.")
