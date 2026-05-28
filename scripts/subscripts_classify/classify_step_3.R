#Nutzung von LLM zur Bestimmung von Hauptproteinquelle und Anteil

#Klassifizierung der restlichen Mahlzeiten via LLM
reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

user_prompt_template <- "

Du bist ein präziser Assistent zur Analyse von Mensa-Speiseplänen. 
Deine Aufgabe ist es, Gerichte zu analysieren, Lebensmittelklassen zu vervollständigen, für ALLE Klassen den Anteil zu bestimmen und die Hauptproteinquelle zu finden.

Gehe strikt nach diesen 4 Schritten vor:

SCHRITT 1: IST ES EINE SPEISE?
Prüfe den Text. Ist es ein echtes Gericht oder eine Info (z.B. 'Feiertag', 'Mensa geschlossen', 'Aktionswoche')?
-> Wenn keine Speise: Setze 'ist_speise' auf false, 'llm_klassen' bleibt leer [], 'hauptprotein' ist 'keine_eindeutige_proteinquelle'.

SCHRITT 2: ALLE KLASSEN SAMMELN (Vorgegebene + Neue)
Schau dir das Gericht und die bereits erkannten 'vorhandene_klassen' an.
- Übernimm die 'vorhandene_klassen', denn sie sind definitiv im Gericht enthalten.
- Überlege: Welche Hauptzutaten fehlen noch (auch implizit durch Rezeptwissen)? Ergänze diese.
-> Ignoriere Gewürze, Kräuter und Kleinstmengen.
-> Nudeln, Reis, Brot, Teig = 'getreide'. Kartoffeln = 'knollen'. Sahne/Käse = 'milchprodukte'.

SCHRITT 3: ANTEIL FÜR ALLE KLASSEN BESTIMMEN
Bestimme nun für JEDE Klasse aus Schritt 2 (sowohl die vorgegebenen als auch die neu ergänzten) den Anteil am Gericht. Gib alle zusammen in 'llm_klassen' aus:
- 'dominant' = Hauptbestandteil (z.B. Nudeln in einem Pastagericht, großes Stück Fleisch)
- 'mittel' = deutliche Beilage oder normaler Bestandteil (z.B. Kartoffeln, Soße mit viel Einlage)
- 'gering' = kleiner, aber relevanter Teil (z.B. Käse-Topping, Speckwürfel)

SCHRITT 4: HAUPTPROTEIN BESTIMMEN
Was ist die wichtigste Eiweißquelle des gesamten Gerichts?

---
ERLAUBTE WERTE (Nutze exakt diese Strings):

Lebensmittelklassen:
rotes_fleisch, gefluegel, fisch, milchprodukte, ei, huelsenfruechte, getreide, knollen, gemuese, nuesse, samen

Hauptprotein:
rotes_fleisch, gefluegel, fisch, milchprodukte, ei, huelsenfruechte, nuesse, samen, keine_eindeutige_proteinquelle

## Eingabe

menu_text:
{text}

vorhandene_klassen:
{klassen}

"

schema <- '{
  "type": "object",

  "properties": {

    "ist_speise": {
      "type": "boolean"
    },

    "llm_klassen": {
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
    }
  },

  "required": [
    "ist_speise",
    "llm_klassen",
    "hauptprotein"
  ],

  "additionalProperties": false
}'

#Daten die durch das Regelwerk nicht klassifiziert werden konnten
batch_menus <- classified_new |> 
  slice_sample(n = 40) |> 
  select(gericht_name=name_clean, text = menu_clean, klassen) 

# LLM 
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
results_tbl <- as_tibble(results)

safe_parse <- possibly(fromJSON, otherwise = list())

llm_classified_short <- results_tbl |>
  mutate(
    text = map_chr(text, ~ as.character(.x[[1]])),
    klassen      = map_chr(klassen, ~ paste(.x, collapse = ", ")),
    parsed       = map(llm_result, safe_parse),
    llm_klassen  = map_chr(parsed, ~ paste(.x$llm_klassen$klasse, collapse = ", ")),
    hauptprotein = map_chr(parsed, ~ .x$hauptprotein),
    klasse       = map2_chr(klassen, llm_klassen, ~ paste(unique(strsplit(paste(.x, .y, sep = ", "), ", ")[[1]]), collapse = ", "))
  ) |>
  select(gericht_name, text, klasse, hauptprotein)

joined_df <- classified_new %>%
  distinct(name_clean, .keep_all = TRUE) |> 
  right_join(llm_classified_short, by = c("name_clean" = "gericht_name"))
