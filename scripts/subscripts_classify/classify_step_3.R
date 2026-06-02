# 3. Hauptprotein und Anteile per LLM schätzen lassen
# Jetzt kommt das Herzstück: Wir nutzen ein LLM, hier über OpenAI,
# um für jedes Gericht die genauen Zutaten und deren Mengenverhältnisse (dominant, mittel, gering) zu schätzen.
# Das LLM kann auch "versteckte" Zutaten erkennen, wie z.B. Weizen in Nudeln oder Ei in Panade.

reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

# Das ist der Bauplan (Prompt) für das LLM. Hier erklären wir ihm ganz genau, 
# wie es arbeiten soll, welche Klassen erlaubt sind und wie die Ausgabe aussehen muss.
# Durch klare Regeln (z.B. die "Burger Rule" oder "Vegan Override") verhindern wir Halluzinationen. Gleichzeitig überlassen wir ihm genug Freiraum um sich auf die Hauptaufgabe
# zu fokussieren.
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

2. CLASSES & INGREDIENT LOGIC (alle_klassen):
   List ALL constituent classes from the ALLOWED FOOD CLASSES list and assign a portion size ("dominant" = main component/base, "mittel" = heavy side/sauce, "gering" = garnish/breading). Apply these strict rules:
   - KEEP PROVIDED: You MUST include all classes from "vorhandene_klassen".
   - ADD IMPLICIT: Use culinary knowledge for hidden ingredients (e.g., "paniert"/pasta -> "getreide"; potatoes/fries -> "knollen"; pizza -> "getreide" + "milchprodukte").
   - BURGER RULE: "Hackfleisch" or "Burger" default to "rotes_fleisch" unless specified otherwise (e.g., "Chickenburger").
   - VEG/VEGAN OVERRIDE: If "veg", "vegetarisch", or "vegan" is in the text, output NO meat/fish. If "vegan", also NO "ei" or "milchprodukte".
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

# Dieses JSON-Schema zwingt das LLM, uns strukturierte Daten statt Fließtext zurückzugeben.
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

# Wir bereiten die Gerichte für das LLM vor, indem wir nur die nötigsten Infos mitnehmen.
batch_menus <- unique_dishes |> 
  #slice_head(n = 20) |> 
  select(id, product_name, menu_text, klassen) 

# wir haben eine neue classify_with_llm funktion gebaut und lassen bis zu 8 Abfragen gleichzeitig laufen, um Zeit zu sparen.
results <- process_with_llm_openai_multiple_workers(
  data = batch_menus,
  model = "gpt-5-nano",
  system_prompt = "You are a food classification assistant for German university cafeterias. 
                   You have extensive knowledge of German and international cuisine.",
  user_prompt_template = user_prompt_template,
  schema = schema,
  log_fn = log_to_r,
  max_workers = 8
)

# Das Ergebnis ist ein JSON-String. Wir wandeln ihn in eine R-Liste um.
# Wenn das JSON fehlerhaft ist, gibt safe_parse einfach eine leere Liste zurück
safe_parse <- possibly(fromJSON, otherwise = list())

results <- as_tibble(results) |>
  mutate(parsed = map(llm_result, safe_parse))

# Jetzt holen wir die klassifizierten Daten aus der JSON
# 1. Wir legen noch einmal unsere Projekt-Klassen fest, falls das LLM doch halluziniert hat.
erlaubte_klassen <- c("rotes_fleisch", "gefluegel", "fisch", "milchprodukte", 
                      "ei", "huelsenfruechte", "getreide", "knollen", 
                      "gemuese", "nuesse", "samen")

llm_classified_short <- results |>
  select(-klassen) |> 
  mutate(
    # Wir iterieren über jede LLM-Antwort und holen uns die Klassen-Namen.
    klassen = map_chr(parsed, ~ {
      if (is.null(.x$alle_klassen) || length(.x$alle_klassen) == 0) {
        return("")
      } else {
        # Alle vom LLM erkannten Klassen extrahieren
        erkannte_klassen <- .x$alle_klassen$klasse
        
        # FILTER: Nur die Klassen behalten, die in unserer erlaubten Liste stehen
        gueltige_klassen <- erkannte_klassen[erkannte_klassen %in% erlaubte_klassen]
        
        # Zu einem Komma-String
        return(paste(gueltige_klassen, collapse = ", "))
      }
    }),
    # Boolean-Wert extrahieren: Ist es wirklich ein Hauptgericht? (ist_speise = true)
    ist_speise = map_lgl(parsed, ~ {
      if (is.null(.x$ist_speise)) NA else as.logical(.x$ist_speise)
    })
  ) |> 
  # alles wegwerfen, was das LLM als "Keine Hauptspeise" erkannt hat.
  filter(ist_speise != FALSE) |> 
  select(id, product_name, menu_text, klassen, ist_speise) |> 
  rename(group_level_2 = klassen) |> 
  # Wir filtern Gerichte heraus, die AUSSCHLIESSLICH aus einer Basis-Beilage bestehen 
  # und somit keine vollwertige Mahlzeit darstellen. Außerdem erkennt das LLM nicht immer alle relevanten Klassen. Diese Gerichte zu
  # behalten würde die Auswertung verfälschen.
  filter(
    !(
      group_level_2 %in% c("getreide", "knollen", "gemuese")
    )
  )
