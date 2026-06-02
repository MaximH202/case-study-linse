# 3. Hauptprotein und Anteile per LLM schätzen lassen

# Einbindung des Python-Skripts für die OpenAI API-Kommunikation
reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

# Prompt für das LLM
user_prompt_template <- '
ALLOWED FOOD CLASSES (Use ONLY these exact strings):
"rotes_fleisch", "gefluegel", "fisch", "milchprodukte", "ei", "huelsenfruechte", "getreide", "knollen", "gemuese", "nuesse", "samen"

INPUT PRIORITY:
- Use "product_name" to identify the core dish (it is the clean, main name).
- Use "menu_text" to find additional details, side dishes, sauces, or implicit ingredients.

RULES:
1. MAIN DISH FILTER (ist_speise):
   - TRUE: Savory main courses (including veggie plates, large fries-plates, casseroles, stews).
   - FALSE: Desserts/sweet dishes (pudding, sweet rice, cakes), plain separate side dishes (plain rice, small side salad), or non-meals (info texts, "closed").

2. CLASSES & PORTIONS (alle_klassen):
   - List ALL constituent classes from the ALLOWED FOOD CLASSES list.
   - Assign a portion size to each:
     * "dominant" = Main component / base of the dish (e.g., the meat, the pasta, the burger patty).
     * "mittel" = Sättigungsbeilage (heavy side dishes like fries/potatoes) or substantial sauces (e.g., cheese sauce).
     * "gering" = Garnish, breading (Panade), light toppings, small vegetable bits.

3. INGREDIENT LOGIC:
   - KEEP PROVIDED: You MUST include all classes listed in "vorhandene_klassen".
   - ADD IMPLICIT: Add hidden ingredients based on culinary knowledge (e.g., "paniert"/breaded -> add "getreide"; "Pizza" -> add "getreide" + "milchprodukte"; Pasta/Noodles/Bread -> "getreide"; Potatoes/Fries -> "knollen").
   - BURGER/MINCE RULE: "Hackfleisch", "Burger", or "Meatballs" default to "rotes_fleisch" unless specified otherwise (e.g., "Chickenburger" -> "gefluegel").
   - VEG/VEGAN OVERRIDE: If "veg", "vegetarisch", or "vegan" appears in the text, absolutely NO meat/fish classes ("rotes_fleisch", "gefluegel", "fisch"). If "vegan", also NO "ei" or "milchprodukte".

---
PROJECT EXAMPLES:

Beispiel 1 (Implicit ingredients & portions): 
product_name: "Kalbsschnitzel"
menu_text: "Kalbsschnitzel mit Kartoffeln und Champignonrahmsauce"
vorhandene_klassen: ["rotes_fleisch"]
JSON-Output: {{"ist_speise": true, "alle_klassen": [{{"klasse": "rotes_fleisch", "anteil": "dominant"}}, {{"klasse": "knollen", "anteil": "mittel"}}, {{"klasse": "getreide", "anteil": "gering"}}, {{"klasse": "gemuese", "anteil": "gering"}}, {{"klasse": "milchprodukte", "anteil": "gering"}}]}}

Beispiel 2 (Standalone side dish):
product_name: "Großer Pommesteller"
menu_text: "Großer Pommesteller mit Ketchup"
vorhandene_klassen: []
JSON-Output: {{"ist_speise": true, "alle_klassen": [{{"klasse": "knollen", "anteil": "dominant"}}]}}

Beispiel 3 (Vegan Override & Burger Rule):
product_name: "Veganer Burger"
menu_text: "Veganer Burger mit Pommes"
vorhandene_klassen: []
JSON-Output: {{"ist_speise": true, "alle_klassen": [{{"klasse": "getreide", "anteil": "dominant"}}, {{"klasse": "gemuese", "anteil": "dominant"}}, {{"klasse": "knollen", "anteil": "mittel"}}]}}

---
INPUT:
product_name: {product_name}
menu_text: {menu_text}
vorhandene_klassen: {klassen}

'

# JSON-Schema für strukturierte LLM-Antwort
schema <- '{
  "type": "object",
  "properties": {
    "ist_speise": {
      "type": "boolean"
    },
    "alle_klassen": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "klasse": {
            "type": "string"
          },
          "anteil": {
            "type": "string"
          }
        },
        "required": ["klasse", "anteil"],
        "additionalProperties": false
      }
    }
  },
  "required": ["ist_speise", "alle_klassen"],
  "additionalProperties": false
}'

# Testlauf: Zufällige Stichprobe (30 Gerichte) für das LLM ziehen
batch_menus <- unique_dishes |> 
  slice_sample(n = 20) |> 
  select(id, product_name, menu_text, klassen) 

# OpenAI API aufrufen und Ergebnisse über mehrere Worker parallel abfragen
results <- process_with_llm_openai_multiple_workers(
  data = batch_menus,
  model = "gpt-5-nano",
  system_prompt = "You are a food classification assistant for German university cafeterias. 
                   You have extensive knowledge of German and international cuisine.",
  user_prompt_template = user_prompt_template,
  schema = schema,
  log_fn = log_to_r,
  max_workers = 4
)

# Ergebnisse in ein R-Datenformat (Tibble) konvertieren und direkt parsen
safe_parse <- possibly(fromJSON, otherwise = list())

results <- as_tibble(results) |>
  mutate(parsed = map(llm_result, safe_parse))

# JSON extrahieren und in strukturierte Spalten überführen
llm_classified_short <- results |>
  select(-klassen) |> 
  mutate(
    klassen = map_chr(parsed, ~ {
      if (is.null(.x$alle_klassen) || length(.x$alle_klassen) == 0) {
        return("")
      } else {
        return(paste(.x$alle_klassen$klasse, collapse = ", "))
      }
    }),  
    # Boolean-Wert für Hauptgerichte extrahieren
    ist_speise = map_lgl(parsed, ~ {
      if (is.null(.x$ist_speise)) NA else as.logical(.x$ist_speise)
    })
  ) |> 
  select(id, product_name, menu_text, klassen, ist_speise) |> 
  rename(group_level_2 = klassen)
