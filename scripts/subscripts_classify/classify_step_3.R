#Nutzung von LLM zur Bestimmung von Hauptproteinquelle und Anteil

#Klassifizierung der restlichen Mahlzeiten via LLM
reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

#Der Prompt für das LLM
user_prompt_template <- '
Du bist ein präziser Assistent zur Analyse von Mensa-Speiseplänen im Rahmen des "Projekt Linse".
Deine Aufgabe ist es, Gerichte strukturiert zu analysieren.

Gehe strikt nach dieser logischen Kette vor:

SCHRITT 1: DESSERT-FILTER (ist_speise)
Prüfe, ob es ein herzhaftes Hauptgericht ist.
- Bei Desserts (Pudding, Kuchen etc.), Feiertagen oder Infos: Setze "ist_speise" auf false, "hauptprotein" auf "keine_eindeutige_proteinquelle" und "alle_klassen" auf [].

SCHRITT 2: HAUPTPROTEIN FINDEN (hauptprotein)
Gehe diese Liste von 1 bis 6 durch. Das ERSTE, was zutrifft, gewinnt. Sei nicht zögerlich!
1. Fleisch? -> "rotes_fleisch" oder "gefluegel"
2. Fisch? -> "fisch"
3. Hülsenfrüchte (Linsen, Bohnen, Erbsen, Tofu, Falafel, Soja)? -> "huelsenfruechte"
4. Milchprodukte (Käse, Sahnesoße, Schmand, Quark)? -> "milchprodukte"
5. Ei (Pfannkuchen, Spiegelei)? -> "ei"
6. Nüsse/Samen (Pesto, Sesam)? -> "nuesse" oder "samen"
Trifft NICHTS davon zu (z.B. reines Gemüse, Pommes mit Ketchup): Wähle "keine_eindeutige_proteinquelle".

SCHRITT 3: ALLE KLASSEN ZUSAMMENFÜHREN (alle_klassen)
Sammle nun ALLE Bestandteile des Gerichts (Hauptkomponente, Beilagen, Soßen).
REGEL 1: Die Eingabe aus "vorhandene_klassen" MUSS zwingend in deine Liste übernommen werden!
REGEL 2: Das in Schritt 2 gewählte "hauptprotein" MUSS zwingend als Klasse in der Liste auftauchen!
REGEL 3: Ergänze stärkehaltige Beilagen (Kartoffeln=knollen, Nudeln=getreide) und Soßen (Rahm=milchprodukte).

Bestimme für jede Klasse den qualitativen Anteil:
- "dominant" = Hauptakteur (z.B. Fleischstück, Patty)
- "mittel" = Sättigungsbeilage / relevante Soße (z.B. Nudeln, Rahmsoße)
- "gering" = Kleine Beigabe, Garnitur

PROJEKT-BEISPIELE ALS ORIENTIERUNG:

Beispiel 1: 
menu_text: "Kalbsschnitzel mit Kartoffeln und Champignonrahmsauce", vorhandene_klassen: ["rotes_fleisch"]
JSON-Output: 
{{"ist_speise": true, "hauptprotein": "rotes_fleisch", "alle_klassen": [{{"klasse": "rotes_fleisch", "anteil": "dominant"}}, {{"klasse": "knollen", "anteil": "mittel"}}, {{"klasse": "getreide", "anteil": "gering"}}, {{"klasse": "gemuese", "anteil": "gering"}}, {{"klasse": "milchprodukte", "anteil": "gering"}}]}}

Beispiel 2:
menu_text: "Großer Pommesteller mit Ketchup", vorhandene_klassen: []
JSON-Output: 
{{"ist_speise": true, "hauptprotein": "keine_eindeutige_proteinquelle", "alle_klassen": [{{"klasse": "knollen", "anteil": "dominant"}}]}}

EINGABE:
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
    
    # HIER DIE LÖSUNG: Nenne die Spalte direkt "klassen_llm" anstatt "klassen"
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
  # WICHTIG: Hier unten im select() dann auch "klassen_llm" auswählen
  select(gericht_name, klassen_llm, hauptprotein) 


# Der Join ist danach super kurz und sauber, ganz ohne "suffix" oder select(-klassen.y):
llm_classified_short <- unique_dishes %>%
  distinct(product_name, .keep_all = TRUE) |> 
  select(-klassen) |> 
  right_join(llm_classified_short, by = c("product_name" = "gericht_name")) |> 
  mutate(klassen = klassen_llm) |> 
  select(-klassen_llm)
