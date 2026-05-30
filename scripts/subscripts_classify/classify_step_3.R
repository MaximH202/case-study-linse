#Nutzung von LLM zur Bestimmung von Hauptproteinquelle und Anteil

#Klassifizierung der restlichen Mahlzeiten via LLM
reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

#Der Prompt für das LLM
user_prompt_template <- '
Follow this logical chain of reasoning strictly:

STEP 1: MAIN DISH FILTER (ist_speise)
Check whether the dish is a savory main course.
Set "ist_speise" to false, "hauptprotein" to "keine_eindeutige_proteinquelle", and "alle_klassen" to [] if it is any of the following:
- Desserts and sweet dishes (e.g., pudding, cake, ice cream, yogurt).
- Pure side dishes (e.g., "kleiner Beilagensalat", "Portion Pommes", "nur Reis").
- Not a meal (holiday, closed, info text).

IMPORTANT: If a side dish is served as a standalone main course (e.g., "Großer Pommesteller", "Großer Salatteller mit Ei/Käse"), it counts as a main course (set "ist_speise" to true)!

STEP 2: FIND MAIN PROTEIN (hauptprotein)
Identify the PRIMARY source of protein in the dish. Evaluate the actual quantity and relevance! 
WARNING: A tiny garnish (e.g., a few bacon bits on fried potatoes, a small sprinkle of parmesan) does NOT determine the main protein. Look for the main component.

Choose the most substantial protein source based on this priority list:
1. Substantial Meat or Fish? -> "rotes_fleisch", "gefluegel", or "fisch"
2. Legumes (lentils, beans, tofu, soy)? -> "huelsenfruechte"
3. Substantial Dairy or Egg (e.g., cheese filling, large omelet, cream sauce)? -> "milchprodukte" or "ei"
4. Nuts or Seeds? -> "nuesse" or "samen"
5. Grains or Tubers (e.g., a plate of pasta, a potato dish without meat)? -> "getreide" or "knollen"

Select "keine_eindeutige_proteinquelle" ONLY if the dish consists entirely of ingredients with practically no protein (e.g., a simple plain green salad).

STEP 3: MERGE ALL CLASSES (alle_klassen)
Collect ALL components of the dish (main component, side dishes, sauces).
RULE 1: The input from "vorhandene_klassen" MUST be strictly included in your list!
RULE 2: The "hauptprotein" selected in Step 2 MUST be strictly included as a class in the list!
RULE 3: Add starchy side dishes (potatoes = "knollen", pasta/rice = "getreide") and sauce ingredients (cream/cheese = "milchprodukte").

Determine the qualitative portion for each class:
- "dominant" = Main component (e.g., piece of meat, patty)
- "mittel" = Filling side dish or relevant sauce (e.g., pasta, cream sauce)
- "gering" = Small addition, garnish

PROJECT EXAMPLES FOR ORIENTATION:

Beispiel 1: 
menu_text: "Kalbsschnitzel mit Kartoffeln und Champignonrahmsauce", vorhandene_klassen: ["rotes_fleisch"]
JSON-Output: 
{{"ist_speise": true, "hauptprotein": "rotes_fleisch", "alle_klassen": [{{"klasse": "rotes_fleisch", "anteil": "dominant"}}, {{"klasse": "knollen", "anteil": "mittel"}}, {{"klasse": "getreide", "anteil": "gering"}}, {{"klasse": "gemuese", "anteil": "gering"}}, {{"klasse": "milchprodukte", "anteil": "gering"}}]}}

Beispiel 2:
menu_text: "Großer Pommesteller mit Ketchup", vorhandene_klassen: []
JSON-Output: 
{{"ist_speise": true, "hauptprotein": "keine_eindeutige_proteinquelle", "alle_klassen": [{{"klasse": "knollen", "anteil": "dominant"}}]}}

INPUT:
gericht_name: {gericht_name}
menu_text: {text}
vorhandene_klassen: {klassen}
'

# Das Schema für den Output des LLM
schema <- '{
  "type": "object",
  "properties": {
    "ist_speise": {
      "type": "boolean"
    },
    "hauptprotein": {
      "type": "string",
      "enum": [
        "rotes_fleisch",
        "gefluegel",
        "fisch",
        "milchprodukte",
        "ei",
        "huelsenfruechte",
        "nuesse",
        "samen",
        "keine_eindeutige_proteinquelle"
      ]
    },
    "alle_klassen": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "klasse": {
            "type": "string",
            "enum": [
              "rotes_fleisch",
              "gefluegel",
              "fisch",
              "milchprodukte",
              "ei",
              "huelsenfruechte",
              "getreide",
              "knollen",
              "gemuese",
              "nuesse",
              "samen"
            ]
          },
          "anteil": {
            "type": "string",
            "enum": [
              "dominant",
              "mittel",
              "gering"
            ]
          }
        },
        "required": [
          "klasse",
          "anteil"
        ],
        "additionalProperties": false
      }
    }
  },
  "required": [
    "ist_speise",
    "hauptprotein",
    "alle_klassen"
  ],
  "additionalProperties": false
}'

# Slice der gesamten Daten, der dem LLM gegeben wird (gericht_name, menu_text und klassen die durch die str suche gefunden wurden)
batch_menus <- unique_dishes |> 
  slice_sample(n = 20) |> 
  select(gericht_name=product_name, text = menu_text, klassen) 

# Aufrufen des LLM und speichern der Ergebnisse in results
results <- process_with_llm_openai_multiple_workers(
  data = batch_menus,
  model = "gpt-5-nano",
  system_prompt = "You are a food classification assistant for German university cafeterias. 
                   You have extensive knowledge of German and international cuisine.",
  user_prompt_template = user_prompt_template,
  schema = schema,
  log_fn = log_to_r,
  max_workers = 2
)

# results in Tibble umwandeln
results <- as_tibble(results)

# Funktion zum parsen
safe_parse <- possibly(fromJSON, otherwise = list())

# parsen des Ergebnis
llm_classified_short <- results |>
  mutate(
    text = map_chr(text, ~ as.character(.x[[1]])),
    parsed = map(llm_result, safe_parse),
    
    klassen_llm = map_chr(parsed, ~ {
      if (is.null(.x$alle_klassen) || length(.x$alle_klassen) == 0) {
        return("")
      } else {
        return(paste(.x$alle_klassen$klasse, collapse = ", "))
      }
    }),
    
    hauptprotein = map_chr(parsed, ~ {
      if (is.null(.x$hauptprotein)) "" else .x$hauptprotein
    })
  ) |>
  select(gericht_name, klassen_llm, hauptprotein) 


# Der Join ist danach super kurz und sauber, ganz ohne "suffix" oder select(-klassen.y):
llm_classified_short <- unique_dishes %>%
  distinct(product_name, .keep_all = TRUE) |> 
  select(-klassen) |> 
  right_join(llm_classified_short, by = c("product_name" = "gericht_name")) |> 
  mutate(klassen = klassen_llm) |> 
  select(-klassen_llm)
