import json
import time
import os
from deep_translator import GoogleTranslator

translator = GoogleTranslator(source='es', target='en')

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

# Collect all unique strings
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
print(f"Still need to translate: {len(still_to_translate)}")

# Batch in chunks of max 4000 characters
chunks = []
current_chunk = []
current_len = 0

for s in still_to_translate:
    # Google translation limit is 5000, we aim for safe 4000
    if current_len + len(s) + 6 > 4000:
        chunks.append(current_chunk)
        current_chunk = [s]
        current_len = len(s) + 6
    else:
        current_chunk.append(s)
        current_len += len(s) + 6
        
if current_chunk:
    chunks.append(current_chunk)

print(f"Translating {len(chunks)} chunks.")

for idx, chunk in enumerate(chunks):
    success = False
    for _ in range(3):
        try:
            joined_text = " <br> ".join(chunk)
            translated_text = translator.translate(joined_text)
            translated_parts = translated_text.split(" <br> ")
            
            # Note: Sometimes translator deletes <br> or messes up spaces
            # Clean up the parts
            translated_parts = [p.replace("<br>", "").strip() for p in translated_parts]
            
            if len(translated_parts) == len(chunk):
                for original, trans in zip(chunk, translated_parts):
                    translation_cache[original] = trans
                success = True
                break
            else:
                print(f"Mismatch in chunk {idx}: expected {len(chunk)}, got {len(translated_parts)}")
                # Try fallback, translate one by one
                print("Falling back to 1-by-1 for this chunk")
                for item in chunk:
                    try:
                        translation_cache[item] = translator.translate(item)
                    except:
                        translation_cache[item] = item
                success = True
                break
        except Exception as e:
            print(f"Error on chunk {idx}: {e}")
            time.sleep(2)
            
    if not success:
        print(f"Failed chunk {idx}")
        # fallback to identity
        for item in chunk:
            translation_cache[item] = item
            
    # save
    with open(cache_file, 'w', encoding='utf-8') as f:
        json.dump(translation_cache, f, indent=2, ensure_ascii=False)
        
    print(f"Done chunk {idx+1}/{len(chunks)}")
    time.sleep(1)

# Apply Translations
for r in data:
    if 'title' in r and isinstance(r['title'], str):
        # capitalize titles correctly
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
