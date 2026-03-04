import json
import time
import os
from deep_translator import GoogleTranslator

# setup translator
translator = GoogleTranslator(source='es', target='en')

# cat and diet map
cat_map = {
    'Bebidas': 'Beverages',
    'Ensaladas': 'Salads',
    'Entrantes': 'Appetizers',
    'Guarniciones': 'Side Dishes',
    'Otros': 'Others',
    'Platos Principales': 'Main Dishes',
    'Postres y Dulces': 'Desserts & Sweets',
    'Sopas y Cremas': 'Soups & Creams'
}

diet_map = {
    'sin frutos secos': 'nut-free',
    'vegetariano': 'vegetarian',
    'vegano': 'vegan',
    'sin lactosa': 'dairy-free',
    'sin gluten': 'gluten-free',
    'sin mariscos': 'seafood-free'
}

with open(r'c:\Users\danie\Apps\Recetas\assets\data\recipes.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Collect all unique strings to translate
strings_to_translate = set()

for r in data:
    if 'title' in r and isinstance(r['title'], str): strings_to_translate.add(r['title'])
    if 'prepTime' in r and r['prepTime'] and isinstance(r['prepTime'], str):
        strings_to_translate.add(r['prepTime'])
    for ing in r.get('ingredients', []):
        if isinstance(ing, str): strings_to_translate.add(ing)
    for step in r.get('steps', []):
        if isinstance(step, str): strings_to_translate.add(step)
    for fact in r.get('nutritionFacts', []):
        if 'label' in fact and isinstance(fact['label'], str): strings_to_translate.add(fact['label'])
    for d_ing in r.get('detailedIngredients', []):
        if 'name' in d_ing and isinstance(d_ing['name'], str): strings_to_translate.add(d_ing['name'])
        if 'quantity' in d_ing and isinstance(d_ing['quantity'], str): strings_to_translate.add(d_ing['quantity'])

strings_to_translate.discard('')
strings_list = list(strings_to_translate)
print(f"Total unique strings to translate: {len(strings_list)}")

cache_file = 'translation_cache.json'
translation_cache = {}

if os.path.exists(cache_file):
    with open(cache_file, 'r', encoding='utf-8') as f:
        translation_cache = json.load(f)

still_to_translate = [s for s in strings_list if s not in translation_cache]
print(f"Still need to translate {len(still_to_translate)}")

batch_size = 40
retries = 3

for i in range(0, len(still_to_translate), batch_size):
    batch = still_to_translate[i:i+batch_size]
    success = False
    
    for _ in range(retries):
        try:
            translated_batch = translator.translate_batch(batch)
            for original, translated in zip(batch, translated_batch):
                translation_cache[original] = translated
            success = True
            break
        except Exception as e:
            print(f"Error at batch {i}: {e}. Retrying in 2 seconds...")
            time.sleep(2)
            
    if not success:
        print(f"Failed to translate batch {i}. Translating one by one.")
        for item in batch:
            try:
                translation_cache[item] = translator.translate(item)
            except Exception as e2:
                print(f"Error on {item}: {e2}")
                translation_cache[item] = item # fallback to original
            time.sleep(0.5)

    # Save cache periodically
    with open(cache_file, 'w', encoding='utf-8') as f:
        json.dump(translation_cache, f, indent=2, ensure_ascii=False)
        
    if i % 200 == 0:
        print(f"Progress: {i}/{len(still_to_translate)}")

for r in data:
    if 'title' in r and isinstance(r['title'], str):
        r['title'] = translation_cache.get(r['title'], r['title']).title()
    if 'prepTime' in r and r['prepTime'] and isinstance(r['prepTime'], str):
        r['prepTime'] = translation_cache.get(r['prepTime'], r['prepTime'])
    if 'ingredients' in r:
        r['ingredients'] = [translation_cache.get(i, i) for i in r['ingredients']]
    if 'steps' in r:
        r['steps'] = [translation_cache.get(s, s) for s in r['steps']]
    if 'nutritionFacts' in r:
        for f in r['nutritionFacts']:
            if 'label' in f:
                f['label'] = translation_cache.get(f['label'], f['label'])
    if 'detailedIngredients' in r:
        for f in r['detailedIngredients']:
            if 'name' in f:
                f['name'] = translation_cache.get(f['name'], f['name'])
            if 'quantity' in f:
                f['quantity'] = translation_cache.get(f['quantity'], f['quantity'])
            
    if 'categories' in r:
        r['categories'] = [cat_map.get(c, c) for c in r['categories']]
    if 'dietaryRestrictions' in r:
        r['dietaryRestrictions'] = [diet_map.get(d, d) for d in r['dietaryRestrictions']]

with open(r'c:\Users\danie\Apps\Recetas\assets\data\recipes_en.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Translation completed and saved to recipes_en.json")
