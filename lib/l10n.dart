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
    "legal_privacy": """PRIVACY POLICY
Last updated: January 10, 2026

1. Introduction
This Privacy Policy describes how Recetas ("we", "our", or "us"), developed by Daniel Cimbollek Díaz, handles your information.

We are committed to protecting your privacy. The core principle of "Recetas" is privacy by design: we do not collect, transmit, or store your personal data on any external servers. The application functions entirely offline, and all data you input remains locally on your device.

2. Data Collection and Usage
We do not collect any personal information, usage statistics, or analytics.

User Data (Recipes & Preferences): All recipes, ingredients, dietary settings, and saved recipes created within the app are stored locally on your device's internal memory using SharedPreferences and local file storage. This data is never transmitted to us or any third party.

Voluntary Backups: If you choose to use the "Export" or "Backup" feature, a JSON file is generated. You control where this file is stored or shared. We do not have access to these files.

3. Device Permissions
To provide specific features, the app may request access to certain system permissions. These permissions are used solely for the functionality described below:

Camera & Photo Gallery: Used strictly to allow you to take or select photos to attach to your custom recipes. These images are stored locally on your device. We do not view, process, or upload your photos.

Storage (Files/Media): Used to save recipe backups (JSON files) and to read files you explicitly select for importing recipes.

4. Third-Party Services
This application does not contain third-party advertising (e.g., AdMob), analytics (e.g., Google Analytics), or tracking SDKs. It does not require an internet connection to function.

5. Children's Privacy
Our application is safe for general audiences, including children. We do not knowingly collect personally identifiable information from children under 13 (or any age), as we do not collect data at all.

6. Your Rights (GDPR)
Since we do not store your data on our servers, we cannot "delete" or "export" your account data for you because we do not have it. You retain full ownership and control of your data. You can delete your data at any time by:

Using the "Clear Data" (Borrar todo) option within the app settings.

Uninstalling the application, which will remove all local data.

7. Links to Other Sites
Our Service may contain links to other sites that are not operated by us (e.g., when using the "Search on Internet" button). If you click on a third-party link, you will be directed to that third party's site. We strongly advise you to review the Privacy Policy of every site you visit. We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services.

8. Contact Us
If you have any questions about this Privacy Policy, please contact us at:

Email: recetasaplicacion@gmail.com

Developer: Daniel Cimbollek Díaz""",
    "legal_tos": """TERMS OF SERVICE
Last updated: January 10, 2026

1. Acceptance of Terms
By downloading or using the Recetas application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the application.

2. License to Use
Daniel Cimbollek Díaz grants you a personal, non-exclusive, non-transferable, and revocable license to use the "Recetas" application for personal and non-commercial purposes.

3. User Content
Ownership: You retain all rights and ownership of the recipes, photos, and texts ("Content") that you create or store within the application.

Responsibility: You are solely responsible for the Content you create. Since the application works offline, you are responsible for backing up your own data using the provided export features. We are not responsible for any data loss caused by device failure, app uninstallation, or file corruption.

4. Content Disclaimer (AI)
Recipe Origins: You acknowledge that the default recipes provided within the application were generated with the assistance of Artificial Intelligence.

Accuracy: While we strive to provide quality content, AI-generated text may occasionally contain errors, inaccuracies, or "hallucinations" regarding ingredients, amounts, or cooking instructions.

User Responsibility: You agree to use your own judgment and common sense when following these recipes. It is your responsibility to ensure food safety, verify cooking times/temperatures, and check for potential allergens. Recetas and Daniel Cimbollek Díaz are not responsible for any illness, injury, or culinary failure resulting from the use of these recipes.

5. External Links
The application may contain links to third-party websites or services (such as Google search results) that are not owned or controlled by Recetas. Daniel Cimbollek Díaz has no control over and assumes no responsibility for the content, privacy policies, or practices of any third-party websites or services. You acknowledge and agree that Recetas shall not be responsible or liable, directly or indirectly, for any damage or loss caused by the use of any such content, goods, or services available on or through any such web sites.

6. Disclaimer of Warranties
The application is provided "AS IS" and "AS AVAILABLE", without warranty of any kind, express or implied. We do not warrant that the application will be error-free or that access to it will be continuous or uninterrupted.

7. Intellectual Property
The source code, design, and "Recetas" brand are the intellectual property of Daniel Cimbollek Díaz.

8. Governing Law
These terms shall be governed and construed in accordance with the laws of Spain, without regard to its conflict of law provisions.

9. Changes to Terms
We reserve the right to modify these terms at any time. We will notify you of any changes by updating the "Last updated" date at the top of this document. Continued use of the application constitutes acceptance of those changes.

10. Contact Us
For any questions regarding these Terms, please contact: recetasaplicacion@gmail.com"""
  };

  static const Map<String, String> spanishOverrides = {
    "legal_privacy": """POLÍTICA DE PRIVACIDAD
Última actualización: 10 de enero de 2026

1. Introducción
Esta Política de Privacidad describe cómo Recetas ("nosotros", "nuestro" o "la aplicación"), desarrollada por Daniel Cimbollek Díaz, trata su información.

Estamos comprometidos con la protección de su privacidad. El principio fundamental de "Recetas" es la privacidad desde el diseño: no recopilamos, transmitimos ni almacenamos sus datos personales en servidores externos. La aplicación funciona completamente sin conexión (offline) y todos los datos que usted introduce permanecen localmente en su dispositivo.

2. Recopilación y Uso de Datos
No recopilamos información personal, estadísticas de uso ni datos analíticos.

Datos del Usuario (Recetas y Preferencias): Todas las recetas, ingredientes, configuraciones dietéticas y guardados creados dentro de la aplicación se almacenan localmente en la memoria interna de su dispositivo (utilizando SharedPreferences y almacenamiento de archivos local). Estos datos nunca se transmiten a nosotros ni a terceros.

Copias de Seguridad Voluntarias: Si decide utilizar la función de "Exportar" o "Copia de seguridad", se generará un archivo JSON. Usted tiene el control total sobre dónde almacenar o con quién compartir este archivo. Nosotros no tenemos acceso a estos archivos.

3. Permisos del Dispositivo
Para proporcionar funcionalidades específicas, la aplicación puede solicitar acceso a ciertos permisos del sistema. Estos permisos se utilizan únicamente para la funcionalidad descrita a continuación:

Cámara y Galería de Fotos: Se utiliza estrictamente para permitirle tomar o seleccionar fotos para adjuntarlas a sus recetas personalizadas. Estas imágenes se guardan localmente en su dispositivo. No visualizamos, procesamos ni subimos sus fotos.

Almacenamiento (Archivos/Medios): Se utiliza para guardar copias de seguridad de recetas (archivos JSON) y para leer archivos que usted seleccione explícitamente para importar recetas.

4. Servicios de Terceros
Esta aplicación no contiene publicidad de terceros (por ejemplo, AdMob), analíticas (por ejemplo, Google Analytics) ni SDKs de rastreo. No requiere conexión a Internet para funcionar.

5. Privacidad del Menor
Nuestra aplicación es segura para el público general, incluidos los niños. No recopilamos a sabiendas información de identificación personal de niños menores de 13 años (ni de ninguna edad), ya que no recopilamos datos en absoluto.

6. Sus Derechos (RGPD / LOPD)
Dado que no almacenamos sus datos en nuestros servidores, no podemos "eliminar" o "exportar" los datos de su cuenta por usted, ya que no tenemos acceso a ellos. Usted conserva la propiedad y el control total de sus datos. Puede eliminar sus datos en cualquier momento mediante:

El uso de la opción "Borrar todo" dentro de la configuración de la aplicación.

La desinstalación de la aplicación, lo cual eliminarará todos los datos locales.

7. Enlaces a Otros Sitios
Nuestra aplicación puede contener enlaces a sitios externos que no son operados por nosotros (por ejemplo, al utilizar el botón de "Buscar en Internet"). Si hace clic en un enlace de terceros, será dirigido al sitio de ese tercero. Le recomendamos encarecidamente que revise la Política de Privacidad de cada sitio que visite. No tenemos control ni asumimos responsabilidad por el contenido, las políticas de privacidad o las prácticas de sitios o servicios de terceros.

8. Contacto
Si tiene alguna pregunta sobre esta Política de Privacidad, por favor contáctenos en:

Correo electrónico: recetasaplicacion@gmail.com

Desarrollador: Daniel Cimbollek Díaz""",
    "legal_tos": """TÉRMINOS Y CONDICIONES DE USO
Última actualización: 10 de enero de 2026

1. Aceptación de los Términos
Al descargar o utilizar la aplicación Recetas, usted acepta estar vinculado por estos Términos y Condiciones. Si no está de acuerdo con estos términos, por favor no utilice la aplicación.

2. Licencia de Uso
Daniel Cimbollek Díaz le otorga una licencia personal, no exclusiva, intransferible y revocable para utilizar la aplicación "Recetas" con fines personales y no comerciales.

3. Contenido del Usuario
Propiedad: Usted conserva todos los derechos y la propiedad de las recetas, fotos y textos ("Contenido") que cree o almacene dentro de la aplicación.

Responsabilidad: Usted es el único responsable del Contenido que crea. Dado que la aplicación funciona sin conexión, usted es responsable de realizar copias de seguridad de sus propios datos utilizando las funciones de exportación proporcionadas. No nos hacemos responsables de ninguna pérdida de datos causada por fallos del dispositivo, desinstalación de la aplicación o corrupción de archivos.

4. Renuncia de Responsabilidad sobre el Contenido (IA)
Origen de las Recetas: Usted reconoce que las recetas predeterminadas proporcionadas dentro de la aplicación fueron generadas con la asistencia de Inteligencia Artificial.

Exactitud: Aunque nos esforzamos por ofrecer contenido de calidad, el texto generado por IA puede contener ocasionalmente errores, inexactitudes o "alucinaciones" con respecto a ingredientes, cantidades o instrucciones de cocción.

Responsabilidad del Usuario: Usted acepta utilizar su propio juicio y sentido común al seguir estas recetas. Es su responsabilidad garantizar la seguridad alimentaria, verificar los tiempos/temperaturas de cocción y comprobar posibles alérgenos. Recetas y Daniel Cimbollek Díaz no se hacen responsables de ninguna enfermedad, lesión o fallo culinario resultante del uso de estas recetas.

5. Enlaces Externos
La aplicación puede contener enlaces a sitios web o servicios de terceros (como resultados de búsqueda de Google) que no son propiedad ni están controlados por Recetas. Daniel Cimbollek Díaz no tiene control ni asume responsabilidad por el contenido, las políticas de privacidad o las prácticas de los sitios web o servicios de terceros. Usted reconoce y acepta que Recetas no será responsable, directa o indirectamente, de cualquier daño o pérdida causada por el uso de dicho contenido, bienes o servicios disponibles a través de dichos sitios web.

6. Exención de Garantías
La aplicación se proporciona "TAL CUAL" y "SEGÚN DISPONIBILIDAD", sin garantía de ningún tipo, expresa o implícita. No garantizamos que la aplicación esté libre de errores o que el acceso a la misma sea continuo o ininterrumpido.

7. Propiedad Intelectual
El código fuente, el diseño y la marca "Recetas" son propiedad intelectual de Daniel Cimbollek Díaz.

8. Ley Aplicable
Estos términos se regirán e interpretarán de acuerdo con las leyes de España, sin tener en cuenta sus disposiciones sobre conflictos de leyes.

9. Cambios en los Términos
Nos reservamos el derecho de modificar estos términos en cualquier momento. Le notificaremos cualquier cambio actualizando la fecha de "Última actualización" en la parte superior de este documento. El uso continuado de la aplicación constituye la aceptación de dichos cambios.

10. Contacto
Para cualquier pregunta relacionada con estos Términos, por favor contacte a: recetasaplicacion@gmail.com"""
  };
}

extension StringLocalization on String {
  String get tr {
    return AppLocalization.instance.translate(this);
  }
}
