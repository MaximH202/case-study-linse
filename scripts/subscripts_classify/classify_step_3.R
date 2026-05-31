# 3. Hauptprotein und Anteile per LLM schätzen lassen

# Einbindung des Python-Skripts für die OpenAI API-Kommunikation
reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

# Prompt für das LLM
user_prompt_template <- '
INPUT PRIORITY:
- Use "gericht_name" to identify the core dish (it is the clean, main name).
- Use "menu_text" to find additional details, side dishes, sauces, or ingredients.

Follow this logical chain of reasoning strictly:

STEP 1: MAIN DISH FILTER (ist_speise)
Identify if the dish is a savory main course.
ist_speise = true if the dish contains a substantial main component, including vegetarian or vegan dishes.
Examples:
- Hirsepuffer mit Gemüse
- Falafel mit Salat
- Gemüselasagne
- Burger
- Curry mit Reis
- Großer Salatteller

ist_speise = false only for:
- desserts
- pure side dishes (plain fries, plain rice, small side salad)
- non-meals (e.g., information about open opening times)

STEP 2: RECONSTRUCT ALL CLASSES (alle_klassen)
Deconstruct the dish into its ingredients and list all constituent classes with their portion size:
- "dominant" (main base/protein), "mittel" (side dish/heavy sauce), "gering" (garnish/seasoning/breading).

CORE RULES:
1. START with the classes from "vorhandene_klassen" (must be strictly kept).
2. ADD missing implicit ingredients (e.g., breaded dishes -> add "getreide"; pizza -> add "milchprodukte" + "getreide"; lasagna -> add "getreide" + "milchprodukte").
3. HACKFLEISCH/BURGER RULE: Default to "rotes_fleisch" unless specified otherwise (e.g., "chicken burger" -> "gefluegel", "vegan burger" -> non-animal class).
4. VEG/VEGAN OVERRIDE: If "veg", "vegetarisch", or "vegan" is detected, do NOT assign animal classes ("rotes_fleisch", "gefluegel", "fisch", "ei", "milchprodukte" if vegan). Replace with plant-based equivalents. (This overrides all other rules).

STEP 3: DETERMINE MAIN PROTEIN (hauptprotein)
Select the primary protein from the classes in Step 2. Use ONLY a class present in your "alle_klassen" list.

To make the decision, categorize your classes from Step 2 into two groups:
- PRIMARY PROTEINS: "rotes_fleisch", "gefluegel", "fisch", "huelsenfruechte", "milchprodukte", "ei", "nuesse", "samen"
- SECONDARY PROTEINS: "getreide", "knollen"

LOGIC:
1. Choose a PRIMARY protein if it is present in a "dominant" or "mittel" portion (e.g., beef in lasagna, cheese on a pizza, tofu in a curry).
2. Choose a SECONDARY protein (Grains or Tubers) if no substantial primary protein is present, or if the primary protein is only a "gering" garnish (e.g., pasta with just a light sprinkle of cheese, or potatoes with just a few bacon bits).
3. Choose "keine_eindeutige_proteinquelle" only if the dish contains no substantial ingredients from either group (e.g., a plain vegetable dish or green salad).

---

INTERNAL VERIFICATION LOOP (MANDATORY)
Before finishing the JSON, verify mentally:
[ ] Is my chosen "hauptprotein" physically listed inside the "alle_klassen" array? 
[ ] Did I copy all classes from "vorhandene_klassen" into "alle_klassen"?

PROJECT EXAMPLES FOR ORIENTATION:

Beispiel 1: 
menu_text: "Kalbsschnitzel mit Kartoffeln und Champignonrahmsauce", vorhandene_klassen: ["rotes_fleisch"]
JSON-Output: 
{{"ist_speise": true, "hauptprotein": "rotes_fleisch", "alle_klassen": [{{"klasse": "rotes_fleisch", "anteil": "dominant"}}, {{"klasse": "knollen", "anteil": "mittel"}}, {{"klasse": "getreide", "anteil": "gering"}}, {{"klasse": "gemuese", "anteil": "gering"}}, {{"klasse": "milchprodukte", "anteil": "gering"}}]}}

Beispiel 2:
menu_text: "Großer Pommesteller mit Ketchup", vorhandene_klassen: []
JSON-Output: 
{{"ist_speise": true, "hauptprotein": "knollen", "alle_klassen": [{{"klasse": "knollen", "anteil": "dominant"}}]}}

INPUT:
gericht_name: {gericht_name}
menu_text: {text}
vorhandene_klassen: {klassen}
'

# JSON-Schema für strukturierte LLM-Antwort
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
        "getreide",
        "knollen",
        "keine_eindeutige_proteinquelle"
      ]
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
  "required": ["ist_speise", "hauptprotein", "alle_klassen"],
  "additionalProperties": false
}'

# Testlauf: Zufällige Stichprobe (30 Gerichte) für das LLM ziehen
batch_menus <- unique_dishes |> 
  slice_sample(n = 30) |> 
  select(gericht_name=product_name, text = menu_text, klassen) 

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

# Ergebnisse in ein R-Datenformat (Tibble) konvertieren
results <- as_tibble(results)

# Fehlerresistentes Parsen mit purrr::possibly (verhindert Abbruch bei fehlerhaftem JSON)
safe_parse <- possibly(fromJSON, otherwise = list())

# JSON extrahieren und in strukturierte Spalten überführen
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
    
    # Typische Fehler des LLM korrigieren die uns aufgefallen sind 
    hauptprotein = map_chr(parsed, ~ {
      hp <- if (is.null(.x$hauptprotein)) "" else .x$hauptprotein
      df <- .x$alle_klassen
      
      if (!is.null(df) && is.data.frame(df) && nrow(df) > 0) {
        
        # ABSICHERUNG 1: Widerspruchs-Schutz (LLM übersieht Protein)
        if (hp == "keine_eindeutige_proteinquelle") {
          prim_proteine <- c("rotes_fleisch", "gefluegel", "fisch", "huelsenfruechte", "milchprodukte", "ei", "nuesse", "samen")
          # Gibt es ein primäres Protein, das dominant oder mittel ist?
          starke_proteine <- df$klasse[df$klasse %in% prim_proteine & df$anteil %in% c("dominant", "mittel")]
          
          if (length(starke_proteine) > 0) {
            hp <- starke_proteine[1] # Überschreibe mit dem gefundenen Protein
          }
        }

        # ABSICHERUNG 2: Getreide- UND Knollen-Fallback
        # Suche nach dominantem/mittlerem Getreide ODER Knollen
        kohlenhydrat_klasse <- df$klasse[df$klasse %in% c("getreide", "knollen") & df$anteil %in% c("dominant", "mittel")]
        
        if (length(kohlenhydrat_klasse) > 0) {
          # Nimm das erste (entweder getreide oder knollen)
          target_klasse <- kohlenhydrat_klasse[1] 
          
          others <- df[df$klasse != target_klasse & df$klasse != "gemuese", ]
          invalid_others <- others[!(others$klasse == "milchprodukte" & others$anteil == "gering"), ]
          
          # Wenn keine blockierenden Zutaten da sind -> überschreibe mit Getreide/Knollen
          if (nrow(invalid_others) == 0) {
            hp <- target_klasse
          }
        }
      }
      return(hp)
    }),
    
    # Boolean-Wert für Hauptgerichte extrahieren
    ist_speise = map_lgl(parsed, ~ {
      if (is.null(.x$ist_speise)) NA else as.logical(.x$ist_speise)
    })
  ) |>
  select(gericht_name, klassen_llm, hauptprotein, ist_speise) |> 
  
  # Plausibilitätsfilter: Das ermittelte Hauptprotein muss physisch in den Zutaten vorkommen
  filter(
    hauptprotein %in% c("keine_eindeutige_proteinquelle", "", NA) | 
    str_detect(klassen_llm, paste0("\\b", hauptprotein, "\\b"))
  )


# Ergebnisse mit dem ursprünglichen unique_dishes-Datensatz zusammenführen
llm_classified_short <- unique_dishes %>%
  distinct(product_name, .keep_all = TRUE) |> 
  select(-klassen) |> 
  right_join(llm_classified_short, by = c("product_name" = "gericht_name")) |> 
  mutate(klassen = klassen_llm) |> 
  select(-klassen_llm)
