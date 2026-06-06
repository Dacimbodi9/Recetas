class AppLocalization {
  static final AppLocalization instance = AppLocalization._internal();
  AppLocalization._internal();

  String currentLanguage = 'es'; // default

  void setLanguage(String lang) {
    currentLanguage = lang;
  }

  String translate(String input) {
    if (currentLanguage == 'es') return spanishOverrides[input] ?? input;
    return translations[input] ?? input;
  }

  static const Map<String, String> translations = {
    "+1000 Recetas": "+1000 Recipes",
    "Aceites y Grasas": "Oils & Fats",
    "Activa el tema oscuro.": "Enable dark theme.",
    "Actualizar": "Update",
    "Ajustes": "Settings",
    "Aplicar": "Apply",
    "Aplicar plantilla": "Apply template",
    "Aplicar a recetas predeterminadas": "Apply to default recipes",
    "Atrás": "Back",
    "Añade los ingredientes necesarios": "Add necessary ingredients",
    "Añade recetas para explorar sus ingredientes":
        "Add recipes to explore their ingredients",
    "Añade tus propias recetas para verlas aquí":
        "Add your own recipes to see them here",
    "Añade y organiza tus creaciones culinarias en un solo lugar.":
        "Add and organize your culinary creations in one place.",
    "Añadir": "Add",
    "Añadir etiqueta": "Add tag",
    "Añadir foto": "Add photo",
    "Añadir a": "Add to",
    "Añadir ingrediente": "Add ingredient",
    "Añadir paso": "Add step",
    "Almuerzo": "Lunch",
    "Bebidas": "Beverages",
    "Bienvenido a Recetas": "Welcome to Recetas",
    "Borrar TODOS los datos": "Delete ALL data",
    "Borrar todo": "Delete all",
    "Borrar todos los datos": "Delete all data",
    "Busca recetas en Google desde la aplicación.":
        "Search for recipes on Google from the app.",
    "Buscador": "Search engine",
    "Buscar": "Search",
    "Buscar en Internet": "Search on the Internet",
    "Buscar en guardados...": "Search saved...",
    "Buscar en @fld...": "Search in @fld...",
    "Buscar ingredientes...": "Search ingredients...",
    "Buscar recetas por nombre...": "Search recipes by name...",
    "Buscar recetas en @cat...": "Search recipes in @cat...",
    "Búsqueda Inteligente": "Smart Search",
    "Búsqueda en Internet": "Internet search",
    "Búsqueda por ingredientes...": "Search by ingredients...",
    "CALENDARIO": "CALENDAR",
    "CATEGORÍA": "CATEGORY",
    "Calendario": "Calendar",
    "Cambiar": "Swap",
    "Cena": "Dinner",
    "Crear plantilla": "Create template",
    "Califica las recetas y organiza tus guardados.":
        "Rate recipes and organize your saved recipes.",
    "Cancelar": "Cancel",
    "Cantidad (ej: 100g)": "Amount (e.g., 100g)",
    "Carga nuestras +1000 recetas iniciales.":
        "Load our +1000 initial recipes.",
    "Categoría (Opcional)": "Category (Optional)",
    "Cerrar": "Close",
    "Comenzar a cocinar": "Start cooking",
    "Cámara": "Camera",
    "Condimentos y Especias": "Condiments & Spices",
    "Desayuno": "Breakfast",
    "comidas": "meals",
    "días": "days",
    "Conservas y Varios": "Canned & Various",
    "Copia de seguridad compartida": "Backup shared",
    "Crear": "Create",
    "Crear carpeta": "Create folder",
    "Crear etiqueta": "Create tag",
    "Crear ingrediente": "Create ingredient",
    "Crea una plantilla primero": "Create a template first",
    "DATOS": "DATA",
    "DIETA": "DIET",
    "Datos eliminados correctamente": "Data deleted successfully",
    "Describe el paso de la receta": "Describe the recipe step",
    "Describe el paso...": "Describe the step...",
    "Duplicar": "Duplicate",
    "EDITAR RECETA": "EDIT RECIPE",
    "ETIQUETAS PERSONALIZADAS": "CUSTOM TAGS",
    "Editar": "Edit",
    "Editar carpeta": "Edit folder",
    "Editar plantilla": "Edit template",
    "Editar paso": "Edit step",
    "Ej: 200g": "Ex: 200g",
    "Ej: 30 min": "Ex: 30 min",
    "Ej: Keto, Low Carb...": "Ex: Keto, Low Carb...",
    "Ej: Postres": "Ex: Desserts",
    "Elegir pantalla predeterminada": "Choose default screen",
    "Eliminar": "Delete",
    "Eliminar carpeta": "Delete folder",
    "Eliminar paso": "Delete step",
    "Eliminar receta": "Delete recipe",
    "Encuentra recetas según los ingredientes que ya tengas en tu nevera.":
        "Find recipes based on the ingredients you already have in your fridge.",
    "Ensaladas": "Salads",
    "Entrantes": "Appetizers",
    "Escribe un nombre para la plantilla": "Enter a name for the template",
    "Esta semana": "This week",
    "Error al guardar": "Error saving",
    "Error al guardar la receta": "Error saving recipe",
    "Esta acción eliminará todas tus recetas personalizadas y carpetas. No se puede deshacer. ¿Estás seguro?":
        "This will delete all your custom recipes and folders. It cannot be undone. Are you sure?",
    "Etiquetas personalizadas:": "Custom tags:",
    "Excluir siempre recetas incompatibles":
        "Always exclude incompatible recipes",
    "Excluye recetas incompatibles. Elige las que coincidan con tu dieta.":
        "Exclude incompatible recipes. Choose those that match your diet.",
    "Escanear receta desde foto (Beta)": "Scan recipe from photo (Beta)",
    "Exportar recetas": "Export recipes",
    "Guardados": "Saved",
    "Filtros Dietéticos": "Dietary Filters",
    "Filtros dietéticos": "Dietary filters",
    "Filtros dietéticos permanentes": "Permanent dietary filters",
    "Finalizar Receta": "Finish Recipe",
    "Frescos Vegetales": "Fresh Vegetables",
    "Galería": "Gallery",
    "GENERAL": "GENERAL",
    "Granos y Pastas": "Grains & Pastas",
    "Guardar": "Save",
    "Guardar Cambios": "Save Changes",
    "Guardar cambios": "Save changes",
    "Guardar como nueva": "Save as new",
    "Guardar en dispositivo": "Save to device",
    "Guarniciones": "Side dishes",
    "Has modificado la receta. ¿Deseas actualizar la actual o guardar como una nueva?":
        "You've modified the recipe. Update the current one or save as new?",
    "HOY": "TODAY",
    "Haz copias de seguridad de tus recetas y compártelas.":
        "Backup your recipes and share them.",
    "Hoy": "Today",
    "INFORMACIÓN": "INFORMATION",
    "INGREDIENTES": "INGREDIENTS",
    "Imagen actualizada": "Image updated",
    "Importar recetas": "Import recipes",
    "Importar/Exportar": "Import/Export",
    "Info": "Info",
    "Información Nutricional": "Nutritional Information",
    "Información nutricional": "Nutritional information",
    "Ingredientes": "Ingredients",
    "Instrucciones": "Instructions",
    "Inicio": "Home",
    "Intenta con otra búsqueda": "Try another search",
    "Legal": "Legal",
    "Limpiar filtros": "Clear filters",
    "Lácteos y Huevos": "Dairy & Eggs",
    "Mantener pantalla encendida": "Keep screen on",
    "Mejor valoradas": "Top rated",
    "Mis Recetas": "My Recipes",
    "Modo Oscuro": "Dark Mode",
    "Mostrar Recetas Predeterminadas": "Show Default Recipes",
    "Mostrar indicador rojo también en recetas incluidas en la app":
        "Show red indicator also on default recipes",
    "Mover a carpeta": "Move to folder",
    "Mover abajo": "Move down",
    "Mover arriba": "Move up",
    "Más recientes": "Most recent",
    "NOMBRE": "NAME",
    "NUEVA RECETA": "NEW RECIPE",
    "NUTRICIÓN (OPCIONAL)": "NUTRITION (OPTIONAL)",
    "No contiene carne": "Does not contain meat",
    "No contiene productos animales": "Does not contain animal products",
    "No existen recetas": "No recipes exist",
    "No hay ingredientes": "No ingredients",
    "No hay ingredientes disponibles en esta categoría":
        "No ingredients available in this category",
    "No hay pasos disponibles para esta receta.":
        "No steps available for this recipe.",
    "No hay recetas": "No recipes",
    "No hay recetas disponibles": "No recipes available",
    "No hay recetas para exportar": "No recipes to export",
    "No mostrar recetas que no cumplan con los filtros":
        "Do not show recipes that do not meet the filters",
    "No hay comidas planificadas": "No meals planned",
    "No hay plantillas": "No templates",
    "No se encontraron recetas": "No recipes found",
    "Nombre de la plantilla": "Template name",
    "Nueva plantilla": "New template",
    "No se pudo abrir el navegador": "Could not open browser",
    "No tienes guardados": "No saved recipes",
    "Nombre": "Name",
    "Nombre de la carpeta": "Folder name",
    "Nombre de la receta": "Recipe name",
    "Nombre del ingrediente": "Ingredient name",
    "OPCIONES": "OPTIONS",
    "Ocultar recetas incompatibles": "Hide incompatible recipes",
    "Organiza tus comidas de la semana": "Organize your weekly meals",
    "Otros": "Others",
    "PASOS A SEGUIR": "STEPS TO FOLLOW",
    "PREPARACIÓN": "PREPARATION",
    "Pantalla predeterminada": "Default screen",
    "Peor valoradas": "Worst rated",
    "Personaliza tu experiencia": "Customize your experience",
    "Planificar hoy": "Plan today",
    "Planificador de comidas": "Meal Planner",
    "Plantilla aplicada a esta semana": "Template applied to this week",
    "Plantilla aplicada a la próxima semana": "Template applied to next week",
    "Plantilla aplicada": "Template applied",
    "PLANTILLAS": "TEMPLATES",
    "Platos Principales": "Main Dishes",
    "Política de Privacidad y Términos": "Privacy Policy and Terms",
    "Por favor ingresa un nombre para la carpeta": "Please enter a folder name",
    "Por favor, escribe un nombre para la receta": "Please write a recipe name",
    "Postres y Dulces": "Desserts & Sweets",
    "Proteína Animal": "Animal Protein",
    "Próxima semana": "Next week",
    "Quitar de guardados": "Remove from saved",
    "RECETAS": "RECIPES",
    "RESTRICCIONES": "RESTRICTIONS",
    "recetas": "recipes",
    "receta": "recipe",
    "Receta Aleatoria": "Random Recipe",
    "Receta guardada como nueva": "Recipe saved as new",
    "Receta duplicada": "Recipe duplicated",
    "Receta": "Recipe",
    "Recetas": "Recipes",
    "Recetas Predeterminadas": "Default Recipes",
    "Predeterminada": "Default",
    "Recetas guardadas exitosamente": "Recipes saved successfully",
    "Repostería y Harinas": "Baking & Flours",
    "Restricciones dietéticas": "Dietary restrictions",
    "Restricciones estándar:": "Standard restrictions:",
    "Selecciona las restricciones que coincidan con tus preferencias (ej: si eres vegetariano, selecciona \"vegetariano\"). Añadirá un indicador rojo a las recetas que no cumplen con estas restricciones.":
        "Select the restrictions that match your preferences (e.g., if you are vegetarian, select \"vegetarian\"). This will add a red indicator to recipes that do not meet these restrictions.",
    "Seleccionados": "Selected",
    "Seleccionar icono": "Select icon",
    "Seleccionar plantilla": "Select template",
    "Siguiente": "Next",
    "Semana": "Week",
    "Salir": "Exit",
    "Sin carpeta": "No folder",
    "Sin frutos secos": "Nut-free",
    "Sin gluten": "Gluten-free",
    "Sin lactosa": "Lactose-free",
    "Sin comidas": "No meals",
    "Sin mariscos": "Seafood-free",
    "Sin resultados": "No results",
    "Sin valoraciones": "No ratings",
    "Sin planificar": "Not planned",
    "Sin valorar": "Not rated",
    "Snack": "Snack",
    "Sopas y Cremas": "Soups & Creams",
    "Sugerencias": "Suggestions",
    "TIEMPO ESTIMADO": "ESTIMATED TIME",
    "Tienes cambios sin guardar. Si sales, los perderás.":
        "You have unsaved changes. If you exit, you will lose them.",
    "Toca para añadir foto": "Tap to add photo",
    "Toca una estrella para valorar:": "Tap a star to rate:",
    "Tu valoración": "Your rating",
    "Tus Propias Recetas": "Your Own Recipes",
    "Tus recetas guardadas aparecerán aquí":
        "Your saved recipes will appear here",
    "Una base de datos inmensa de recetas creativas y deliciosas.":
        "A huge database of creative and delicious recipes.",
    "Una interfaz elegante que cuida tus ojos.":
        "An elegant interface that takes care of your eyes.",
    "Valora recetas para verlas aquí": "Rate recipes to see them here",
    "Valoraciones": "Ratings",
    "Valoración": "Rating",
    "Valorar receta": "Rate recipe",
    "Vegano": "Vegan",
    "Vegetariano": "Vegetarian",
    "Vegetariano, vegano, sin gluten... Filtra según tus necesidades.":
        "Vegetarian, vegan, gluten-free... Filter according to your needs.",
    "¿Cómo se prepara?": "How is it prepared?",
    "¿Indeciso? Deja que el azar decida qué cocinar hoy.":
        "Undecided? Let chance decide what to cook today.",
    "¿Salir sin guardar?": "Exit without saving?",
    "¿A qué semana quieres aplicar esta plantilla? Se reemplazarán las comidas existentes.":
        "Which week do you want to apply this template to? Existing meals will be replaced.",
    "API Endpoint": "API Endpoint",
    "API Key": "API Key",
    "Analizando imagen con IA... Espera un momento.":
        "Analyzing image with AI... Please wait.",
    "Configura tu API Key (ej. OpenAI, Gemini) para extraer automáticamente recetas desde imágenes.":
        "Configure your API Key (e.g., OpenAI, Gemini) to automatically extract recipes from images.",
    "Configurar API Key": "Configure API Key",
    "Hubo un error con la IA": "There was an error with the AI",
    "IA API Key": "AI API Key",
    "INTELIGENCIA ARTIFICIAL": "ARTIFICIAL INTELLIGENCE",
    "Por favor configura un API Key de IA en Configuración primero.":
        "Please configure an AI API Key in Settings first.",
    "Usar IA para extraer recetas de imágenes":
        "Use AI to extract recipes from images.",
    "¡Listo! Revisa los ingredientes y los pasos.":
        "Done! Review the ingredients and steps.",
    "Compartir próximamente...": "Share coming soon...",
    "APARIENCIA Y NAVEGACIÓN": "APPEARANCE & NAVIGATION",
    "MIS DATOS": "MY DATA",
    "ACERCA DE": "ABOUT",
    "Configuración de IA": "AI Configuration",
    "Escaneo de Recetas Inteligente": "Smart Recipe Scanning",
    "Para que la aplicación pueda leer fotos de recetas y convertirlas automáticamente en texto, necesitas conectar un servicio de Inteligencia Artificial.":
        "For the app to read recipe photos and convert them automatically into text, you need to connect an Artificial Intelligence service.",
    "1. Elige tu proveedor de IA": "1. Choose your AI provider",
    "Google Gemini (Recomendado, Gratis)": "Google Gemini (Recommended, Free)",
    "OpenAI / Otros compatibles": "OpenAI / Other compatibles",
    "2. Consigue tu Clave (API Key)": "2. Get your API Key",
    "Gemini ofrece una clave gratuita y es muy fácil de obtener. Solo entra a Google AI Studio pulsando el botón de abajo, inicia sesión con tu cuenta de Google, y pulsa en \"Get API key\" o \"Crear clave de API\".":
        "Gemini offers a free key and it is very easy to obtain. Just go to Google AI Studio by pressing the button below, sign in with your Google account, and click on \"Get API key\".",
    "Obtener clave de Gemini": "Get Gemini key",
    "Para usar OpenAI (ChatGPT) necesitas una cuenta de desarrollador de pago con saldo en platform.openai.com. También puedes usar servicios compatibles como OpenRouter editando el Endpoint.":
        "To use OpenAI (ChatGPT) you need a paid developer account with balance at platform.openai.com. You can also use compatible services like OpenRouter by editing the Endpoint.",
    "Obtener clave de OpenAI": "Get OpenAI key",
    "3. Pega tu API Key aquí": "3. Paste your API Key here",
    "Clave de API (API Key)": "API Key (API Key)",
    "Opciones Avanzadas": "Advanced Options",
    "API Endpoint Url (Opcional)": "API Endpoint Url (Optional)",
    "Guardar Configuración": "Save Configuration",
    "No se pudo abrir el enlace": "Could not open link",
    "Configuración guardada correctamente": "Configuration saved successfully",
    "Compartir receta": "Share recipe",
    "Compartir enlace": "Share link",
    "Envía un enlace con los datos de la receta":
        "Send a link with recipe data",
    "Mostrar código QR": "Show QR code",
    "Muestra un QR para que otros lo escaneen": "Show a QR for others to scan",
    "¡Mira esta receta de": "Check out this recipe for",
    "Código QR": "QR Code",
    "Otros pueden escanear este código para añadir la receta a su aplicación":
        "Others can scan this code to add the recipe to their app",
    "Listo": "Done",
    "Escanear código QR": "Scan QR code",
    "Importar una receta escaneando un código QR":
        "Import a recipe by scanning a QR code",
    "Receta detectada": "Recipe detected",
    "¿Quieres importar la receta": "Do you want to import the recipe",
    "Nota: Ya tienes una receta con este nombre.":
        "Note: You already have a recipe with this name.",
    "Receta importada correctamente": "Recipe imported successfully",
    "Apunta al código QR de la receta": "Point at the recipe QR code",
    "Importar": "Import",
    "Receta compartida detectada": "Shared recipe detected",
    "(Necesitas tener instalada la app Recetas)":
        "(You need to have the Recipes app installed)",
    "Compartir archivo": "Share file",
    "Envía un archivo .receta por WhatsApp, Telegram...":
        "Send a .receta file via WhatsApp, Telegram...",
    "Importar archivo .receta": "Import .receta file",
    "Selecciona un archivo .receta para importar la receta":
        "Select a .receta file to import the recipe",
    "Archivo no válido o corrupto": "Invalid or corrupted file",
    "Error al compartir archivo": "Error sharing file",
    "Error al importar archivo": "Error importing file",
    "Error al compartir": "Error sharing",
    "Perfil": "Profile",
    "Chef": "Chef",
    "Nombre de usuario": "Username",
    "Editar perfil": "Edit Profile",
    "Guardar perfil": "Save Profile",
    "Foto de perfil": "Profile Photo",
    "Toca para cambiar": "Tap to change",
    "Escribe tu nombre": "Type your name",
    "Mostrar estadísticas": "Show statistics",
    "Recetas y guardados en tu tarjeta": "Recipes and saved items in your card",
    "Calorías": "Calories",
    "Proteínas": "Proteins",
    "Carbohidratos": "Carbs",
    "Grasas": "Fats",
    "Mes": "Month",
    "Año": "Year",
    "Menú principal": "Main Menu",
    "Personalizar botones inferiores": "Customize bottom buttons",
    "Elige qué funciones quieres tener a mano en la barra inferior (máx 4). Las que no selecciones aparecerán en la pantalla de inicio.":
        "Choose which features you want handy in the bottom bar (max 4). Those not selected will appear on the home screen.",
    "Solo puedes seleccionar hasta 4 accesos directos":
        "You can only select up to 4 shortcuts",
    "Búsqueda": "Search",
    "Busca recetas e ingredientes": "Search for recipes and ingredients",
    "Planificador": "Planner",
    "Compra": "Shopping",
    "Lista de Compra": "Shopping List",
    "Lista de compra automática": "Automatic shopping list",
    "Gestión de despensa e ingredientes": "Pantry and ingredients management",
    "Lista y Despensa": "List & Pantry",
    "Despensa": "Pantry",
    "Añadir a despensa...": "Add to pantry...",
    "NUEVA PLANTILLA": "NEW TEMPLATE",
    "EDITAR PLANTILLA": "EDIT TEMPLATE",
    "Generar lista desde el planificador": "Generate list from planner",
    "Nada por aquí": "Nothing here",
    "Añadir a lista...": "Add to list...",
    "Añadido Manualmente": "Added Manually",
    "Añadidos Manualmente": "Added Manually",
    "Del Planificador": "From Planner",
    "Cantidad para": "Amount for",
    "Ej: 200g, 1 un, al gusto...": "e.g., 200g, 1 unit, to taste...",
    "Añadir artículo": "Add item",
    "No hay ingredientes para comprar": "No ingredients to buy",
    "Planifica comidas primero para generar tu lista de compra":
        "Plan meals first to generate your shopping list",
    "Sincronizado con el planificador": "Synced with planner",
    "comprados": "purchased",
    "Marcar todo": "Check all",
    "Desmarcar todo": "Uncheck all",
    "Añadir otra receta": "Add another recipe",
    "Pérdida de Peso Equilibrada": "Balanced Weight Loss",
    "Ganancia Muscular": "Muscle Gain",
    "Vegetariano Completo": "Complete Vegetarian",
    "Rápido y Fácil": "Quick & Easy",
    "Plantilla predeterminada": "Default template",
    "Avena Nocturna Proteica con Frutos Rojos": "Protein Overnight Oats with Berries",
    "Ensalada de Quinoa, Garbanzos y Aguacate": "Quinoa, Chickpea & Avocado Salad",
    "Salmón al Horno con Espárragos y Boniato": "Baked Salmon with Asparagus and Sweet Potato",
    "Wrap de Pollo y Hummus": "Chicken & Hummus Wrap",
    "Batido Verde Detox": "Green Detox Smoothie",
    "Copia": "Copy",
    "Comidas de hoy": "Today's meals",
    "Limpiar semana": "Clear week",
    "Semana limpiada": "Week cleared",
    "Estadísticas": "Statistics",
    "Tus estadísticas nutricionales": "Your nutritional statistics",
    "Consulta tus datos de nutrición": "Check your nutrition data",
    "Consumo de hoy": "Today's intake",
    "Meta diaria": "Daily goal",
    "Distribución de macros": "Macro distribution",
    "Racha": "Streak",
    "Recetas más consumidas": "Most consumed recipes",
    "Distribución por categoría": "Category distribution",
    "Perfil corporal": "Body profile",
    "Peso (kg)": "Weight (kg)",
    "Altura (cm)": "Height (cm)",
    "Edad": "Age",
    "Sexo": "Sex",
    "Masculino": "Male",
    "Femenino": "Female",
    "IMC": "BMI",
    "Tasa Metabólica Basal": "Basal Metabolic Rate",
    "Gasto Energético Diario": "Daily Energy Expenditure",
    "kcal consumidas": "kcal consumed",
    "Completa comidas del planificador para ver tus estadísticas":
        "Complete meals from the planner to see your statistics",
    "días de racha": "streak days",
    "veces": "times",
    "Ver estadísticas": "View statistics",
    "Tu información corporal": "Your body information",
    "Estos datos se usan para calcular recomendaciones nutricionales personalizadas":
        "This data is used to calculate personalized nutritional recommendations",
    "Normal": "Normal",
    "Bajo peso": "Underweight",
    "Sobrepeso": "Overweight",
    "Obesidad": "Obesity",
    "Introduce tus datos físicos": "Enter your physical data",
    "Estos datos son opcionales y se guardan solo en tu dispositivo":
        "This data is optional and stored only on your device",
    "años": "years",
    "Sin datos nutricionales": "No nutritional data",
    "Tabla nutricional": "Nutrition table",
    "Comida": "Meal",
    "Total del día": "Day total",
    "Hoy no hay comidas completadas": "No completed meals today",
    "consumidas": "consumed",
    "objetivo": "goal",
    "Resumen nutricional": "Nutritional summary",
    "No hay datos suficientes": "Not enough data",
    "Peso": "Weight",
    "Altura": "Height",
    "Sin meta configurada": "No goal configured",
    "Configura tu perfil corporal en ajustes para ver tu meta calórica":
        "Set up your body profile in settings to see your calorie goal",
    "RESUMEN": "SUMMARY",
    "GRÁFICO": "CHART",
    "MACROS": "MACROS",
    "CONSISTENCIA": "CONSISTENCY",
    "TOP RECETAS": "TOP RECIPES",
    "CATEGORÍAS": "CATEGORIES",
    "DETALLE": "DETAIL",
    "PERFIL CORPORAL": "BODY PROFILE",
    "¡Sigue así!": "Keep it up!",
    "Planifica y completa comidas para iniciar tu racha":
        "Plan and complete meals to start your streak",
    "No hay recetas consumidas aún": "No recipes consumed yet",
    "Completa comidas para ver las más consumidas":
        "Complete meals to see the most consumed",
    "Sin categorías aún": "No categories yet",
    "Gráfico nutricional": "Nutrition chart",
    "Perfil Físico": "Body Profile",
    "Editar perfil corporal": "Edit body profile",
    "Añadir comida extra": "Add extra meal",
    "Receta eliminada": "Recipe deleted",
    "Califica las recetas y organiza tus favoritas.": "Rate recipes and organize your favorites.",
    "Idioma / Language": "Language / Idioma",
    "Tus recetas guardadas y favoritas": "Your saved and favorite recipes",
    "Analizando Receta...": "Analyzing Recipe...",
    "¡Importación completada con éxito!": "Import completed successfully!",
    "Crear nuevo": "Create new",
    "Error al eliminar la receta": "Error deleting recipe",
    "Comidas de hoy en Inicio": "Today's meals on Home",
    "Mostrar resumen en vez de en planificador": "Show summary instead of in planner",
    "Configura tus datos de salud para recomendaciones": "Configure your health data for recommendations",
    "Español": "Spanish",
    "English": "English",
    "Nivel de Actividad": "Activity Level",
    "Sedentario: Trabajo de oficina, poco o ningún ejercicio.": "Sedentary: Office work, little or no exercise.",
    "Ligeramente activo: Ejercicio ligero 1-3 días a la semana.": "Lightly active: Light exercise 1-3 days a week.",
    "Moderadamente activo: Ejercicio 3-5 días a la semana.": "Moderately active: Exercise 3-5 days a week.",
    "Muy activo: Ejercicio fuerte 6-7 días a la semana.": "Very active: Hard exercise 6-7 days a week.",
    "Extremadamente activo: Trabajo físico duro o entrenamiento doble.": "Extremely active: Hard physical work or double training.",
    "Sedentario (Poco/ningún ejercicio)": "Sedentary (Little/no exercise)",
    "Ligero (1-3 días/sem)": "Light (1-3 days/week)",
    "Moderado (3-5 días/sem)": "Moderate (3-5 days/week)",
    "Muy activo (6-7 días/sem)": "Very active (6-7 days/week)",
    "Extremo (Trabajo físico/Atleta)": "Extreme (Physical work/Athlete)",
    "Compartir": "Share",
    "Crea carpetas o guarda recetas para verlas aquí": "Create folders or save recipes to see them here",
    "Cantidad de": "Amount of",
    "Cantidades de": "Amounts of",
    "Calorías (kcal)": "Calories (kcal)",
    "Proteína (g)": "Protein (g)",
    "Carbohidratos (g)": "Carbohydrates (g)",
    "Grasas (g)": "Fats (g)",
    "Paso": "Step",
    "Categoría": "Category",
    "Ingrediente": "Ingredient",
    "Cantidad": "Amount",
    "día": "day",
    "Borrador encontrado": "Draft found",
    "Comida eliminada": "Meal removed",
    "Deshacer": "Undo",
    "Receta actualizada": "Recipe updated",
    "Receta creada": "Recipe created",
    "Restaurar": "Restore",
    "Receta movida fuera de carpetas": "Recipe moved out of folders",
    "Receta movida a carpeta": "Recipe moved to folder",
    "Se intentó con": "Tried with",
    "¿Estás seguro de que quieres eliminar": "Are you sure you want to delete",
    "Esto también eliminará todas las subcarpetas.": "This will also delete all subfolders.",
    "Error al seleccionar imagen": "Error selecting image",
    "Error al exportar": "Error exporting",
    "Error al importar": "Error importing",
    "eliminada": "deleted",
    "legal_privacy": """PRIVACY POLICY
Effective Date: June 6, 2026

1. Introduction
Welcome to Recetas. Your privacy is critically important to us. This Privacy Policy explains how your information is collected, used, and protected when you use the Recetas mobile application ("the App").

2. Offline-First Architecture and Data Storage
Recetas is designed with a privacy-centric, "offline-first" philosophy. All your core data—including recipes, meal plans, ingredient lists, dietary preferences, and user profile information—is stored locally on your device using local databases (SQLite) and local storage. We do not require you to create an account, nor do we transmit, store, or process your personal culinary data on our own servers. 

3. Camera and Photo Library Access
To provide core functionalities such as scanning physical cookbooks, handwritten notes, uploading custom recipe imagery, and reading QR codes, Recetas requires access to your device's camera and photo library. The App will only access images that you explicitly choose to capture or import. 

4. AI-Powered Recipe Extraction and Third-Party Services
If you choose to use our intelligent recipe extraction feature (Vision AI/OCR), the specific images or photos you submit for extraction will be securely transmitted to third-party AI service providers (such as Google Gemini, OpenAI, or custom configured endpoints). 
- These providers process the image solely to extract text, ingredients, and instructions.
- By using this feature, you acknowledge and consent to this temporary data transmission.
- We do not control and are not responsible for the privacy practices of these third-party AI providers. We encourage you to review their respective privacy policies.

5. Data Sharing
Because your data is stored locally, we do not sell, trade, or otherwise transfer your personally identifiable information to outside parties. You may voluntarily share your recipes with others using our generated QR codes, deep links, or encoded .receta files.

6. Changes to this Privacy Policy
We may update our Privacy Policy periodically to reflect changes in our practices or for other operational, legal, or regulatory reasons.""",
    "legal_tos": """TERMS OF USE
Effective Date: June 6, 2026

1. Acceptance of Terms
By downloading, installing, or using the Recetas application, you agree to be bound by these Terms of Use. If you do not agree with any part of these terms, please do not use the App.

2. Use of the Application
Recetas grants you a personal, non-exclusive, non-transferable, limited license to use the App on compatible devices for personal, non-commercial culinary organization and meal planning.

3. AI Accuracy and Disclaimer
Recetas utilizes advanced Artificial Intelligence (OCR and LLMs) to extract recipes from images. While we strive for accuracy, AI interpretations are not infallible. You acknowledge that extracted ingredients, quantities, and instructions may contain errors. It is your sole responsibility to review, verify, and edit all AI-extracted recipes before relying on them for cooking or dietary compliance. 

4. Health and Dietary Information
The dietary safeguards (such as real-time visual indicators for restrictions) and nutritional tracking features are provided for informational and organizational purposes only. They do not constitute medical or professional nutritional advice. Always consult a healthcare professional regarding severe food allergies, intolerances, or specific medical diets.

5. User-Generated Content
You are solely responsible for the recipes, images, and content you create, store, or share using Recetas. You agree not to use the App to distribute illegal, offensive, or copyrighted material without permission.

6. Limitation of Liability
To the maximum extent permitted by applicable law, Recetas, its developers, and affiliates shall not be liable for any indirect, incidental, special, or consequential damages resulting from the use or inability to use the App, including but not limited to ruined meals, allergic reactions resulting from unverified recipes, or data loss.

7. Modifications to the App
We reserve the right to modify, suspend, or discontinue any feature of the App at any time without prior notice."""
  };

  static const Map<String, String> spanishOverrides = {
    "legal_privacy": """POLÍTICA DE PRIVACIDAD
Fecha de entrada en vigor: 6 de junio de 2026

1. Introducción
Bienvenido a Recetas. Su privacidad es de vital importancia para nosotros. Esta Política de Privacidad explica cómo se recopila, utiliza y protege su información cuando utiliza la aplicación móvil Recetas ("la Aplicación").

2. Arquitectura "Offline-First" y Almacenamiento de Datos
Recetas está diseñada con una filosofía centrada en la privacidad y el funcionamiento sin conexión ("offline-first"). Todos sus datos principales, incluyendo recetas, planes de comidas, listas de ingredientes, preferencias dietéticas e información de perfil de usuario, se almacenan localmente en su dispositivo mediante bases de datos locales (SQLite). No le pedimos que cree una cuenta, ni transmitimos, almacenamos o procesamos sus datos culinarios personales en nuestros propios servidores.

3. Acceso a la Cámara y a la Galería de Fotos
Para ofrecer funcionalidades clave como escanear libros de cocina físicos, notas escritas a mano, subir imágenes personalizadas de recetas y leer códigos QR, Recetas requiere acceso a la cámara y a la galería de fotos de su dispositivo. La Aplicación solo accederá a las imágenes que usted elija explícitamente capturar o importar.

4. Extracción de Recetas con Inteligencia Artificial y Servicios de Terceros
Si elige utilizar nuestra función de extracción inteligente de recetas (Visión IA/OCR), las imágenes o fotos específicas que envíe para su extracción se transmitirán de forma segura a proveedores de servicios de IA de terceros (como Google Gemini, OpenAI o puntos de enlace configurados a medida).
- Estos proveedores procesan la imagen únicamente para extraer texto, ingredientes e instrucciones.
- Al utilizar esta función, usted reconoce y acepta esta transmisión temporal de datos.
- No controlamos ni somos responsables de las prácticas de privacidad de estos proveedores de IA de terceros. Le recomendamos que revise sus respectivas políticas de privacidad.

5. Compartir Datos
Debido a que sus datos se almacenan localmente, no vendemos, comercializamos ni transferimos de ninguna otra manera su información personal identificable a terceros. Usted puede compartir voluntariamente sus recetas con otros utilizando nuestros códigos QR generados, enlaces profundos (deep links) o archivos codificados .receta.

6. Cambios en esta Política de Privacidad
Podemos actualizar nuestra Política de Privacidad periódicamente para reflejar cambios en nuestras prácticas o por otros motivos operativos, legales o normativos.""",
    "legal_tos": """TÉRMINOS DE USO
Fecha de entrada en vigor: 6 de junio de 2026

1. Aceptación de los Términos
Al descargar, instalar o utilizar la aplicación Recetas, usted acepta estar sujeto a estos Términos de Uso. Si no está de acuerdo con alguna parte de estos términos, por favor no utilice la Aplicación.

2. Uso de la Aplicación
Recetas le otorga una licencia personal, no exclusiva, intransferible y limitada para utilizar la Aplicación en dispositivos compatibles para la organización culinaria personal y no comercial y la planificación de comidas.

3. Precisión de la IA y Descargo de Responsabilidad
Recetas utiliza Inteligencia Artificial avanzada (OCR y LLM) para extraer recetas a partir de imágenes. Aunque nos esforzamos por lograr la máxima precisión, las interpretaciones de la IA no son infalibles. Usted reconoce que los ingredientes extraídos, las cantidades y las instrucciones pueden contener errores. Es su entera responsabilidad revisar, verificar y editar todas las recetas extraídas por la IA antes de confiar en ellas para cocinar o para el cumplimiento dietético.

4. Información de Salud y Dieta
Las salvaguardas dietéticas (como los indicadores visuales en tiempo real para restricciones) y las funciones de seguimiento nutricional se proporcionan únicamente con fines informativos y organizativos. No constituyen asesoramiento médico o nutricional profesional. Consulte siempre a un profesional de la salud en caso de alergias alimentarias graves, intolerancias o dietas médicas específicas.

5. Contenido Generado por el Usuario
Usted es el único responsable de las recetas, imágenes y contenido que cree, almacene o comparta utilizando Recetas. Usted acepta no utilizar la Aplicación para distribuir material ilegal, ofensivo o protegido por derechos de autor sin permiso.

6. Limitación de Responsabilidad
En la medida máxima permitida por la ley aplicable, Recetas, sus desarrolladores y afiliados no serán responsables de ningún daño indirecto, incidental, especial o consecuente que resulte del uso o la incapacidad de usar la Aplicación, incluyendo, pero no limitado a, comidas arruinadas, reacciones alérgicas resultantes de recetas no verificadas o pérdida de datos.

7. Modificaciones a la Aplicación
Nos reservamos el derecho de modificar, suspender o interrumpir cualquier función de la Aplicación en cualquier momento sin previo aviso."""
  };
}

extension StringLocalization on String {
  String get tr {
    return AppLocalization.instance.translate(this);
  }
}
