#Nutzung von LLM zur Bestimmung von Hauptproteinquelle und Anteil

#Klassifizierung der restlichen Mahlzeiten via LLM
reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

user_prompt_template <- '
Du bist ein präziser Assistent zur Analyse von Mensa-Speiseplänen im Rahmen des "Projekt Linse". 
Deine Aufgabe ist es, Gerichte strukturiert zu analysieren, alle enthaltenen Lebensmittelklassen zu vervollständigen, deren Anteile zu bestimmen und die Hauptproteinquelle zu finden.

Gehe bei der Analyse strikt nach dieser logischen Kette vor:

SCHRITT 1: IST ES EINE SPEISE? (Dessert-Filter)
Prüfe, ob es sich um ein herzhaftes Hauptgericht handelt.
- Setze "ist_speise" auf false, "llm_klassen" auf [] und "hauptprotein" auf "keine_eindeutige_proteinquelle", wenn es sich um Folgendes handelt:
  * Keine Speise (Feiertag, geschlossen, Info...)
  * Desserts und süße Nachspeisen (z.B. Grießbrei, Pudding, Joghurt, Kompott, Eis, Kuchen).

SCHRITT 2: ALLE KOMPONENTEN ERFASSEN (Inklusive Beilagen & Soßen)
Zerlege das Gericht im Geist in alle seine Bestandteile (Hauptkomponente, Beilagen, Soßen).
- Erfasse JEDE relevante Lebensmittelklasse, auch wenn sie nicht explizit im Text steht, sondern rezepttypisch impliziert ist.
- WICHTIG (Projekt-Vorgabe): Klassifiziere auch stärkehaltige Beilagen (z.B. Kartoffeln/Pommes = knollen; Reis/Nudeln = getreide) und Soßenbestandteile (z.B. Champignons = gemuese; Rahm/Käse = milchprodukte).
- Die "vorhandene_klassen" ({klassen}) müssen zwingend übernommen werden.

SCHRITT 3: ANTEILE BESTIMMEN
Bestimme für jede ermittelte Klasse (auch "vorhandene_klassen" aus {klassen}) den qualitativen Anteil am Gesamtgericht:
- "dominant" = Hauptakteur des Tellers (z.B. das Fleisch, das vegetarische Patty)
- "mittel" = Sättigungsbeilage oder relevante Soße (z.B. Pommes, Rahmsoße)
- "gering" = Kleine Beigabe, Garnitur, Käse-Topping

SCHRITT 4: HAUPTPROTEIN-ENTSCHEIDUNG (Prioritäten-Entscheidungsbaum)
Finde die wichtigste Proteinquelle des Gerichts. Sei nicht zu zögerlich! Jedes Gericht mit einer proteinreichen Zutat hat ein Hauptprotein, auch wenn es sich um ein vegetarisches Gericht handelt.

Gehe diesen Entscheidungsbaum von oben nach unten durch. Wähle den ERSTEN Punkt, der auf das Gericht zutrifft:

1. Fleisch im Gericht? -> Wähle "rotes_fleisch" oder "gefluegel".
2. Fisch im Gericht? -> Wähle "fisch".
3. Hülsenfrüchte im Gericht? (Linsen, Bohnen, Kichererbsen, Falafel, Hummus, Tofu, Soja) -> Wähle "huelsenfruechte".
4. Milchprodukte relevant im Gericht? (Käse-Topping, Käsefüllung, Sahnesoße, Schmand, Joghurt-Dip) -> Wähle "milchprodukte" (z.B. bei Käsespätzle, Pizza, Gratins, Rahmsoßen).
5. Ei relevant im Gericht? (Eierspeisen, Pfannkuchen, Ei-Garnitur) -> Wähle "ei".
6. Nüsse oder Samen im Gericht? (Pesto, Erdnusssoße, Sesam-Topping) -> Wähle "nuesse" oder "samen".

NUR WENN KEINER der obigen 6 Punkte zutrifft (reines Gemüse, Kartoffelgerichte ohne Käse/Fleisch, Nudeln mit reiner Tomatensoße), wählst du "keine_eindeutige_proteinquelle".

*STRIKTE KONSISTENZ-REGEL:* Das hier gewählte "hauptprotein" MUSS zwingend auch als Klasse in "llm_klassen" oder in "vorhandene_klassen" aufgeführt sein!

---
ERLAUBTE WERTE (Hinweis: Gleiche diese mit dem Projekt-Schema ab):

Lebensmittelklassen:
rotes_fleisch, gefluegel, fisch, milchprodukte, ei, huelsenfruechte, getreide, knollen, gemuese, nuesse, samen

Hauptprotein:
rotes_fleisch, gefluegel, fisch, milchprodukte, ei, huelsenfruechte, nuesse, samen, keine_eindeutige_proteinquelle

---
PROJEKT-BEISPIELE ALS ORIENTIERUNG:

Beispiel 1 (Komplexe Speise mit Beilagen und Soße):
menu_text: "Kalbsschnitzel mit Kartoffeln und Champignonrahmsauce"
vorhandene_klassen: ["rotes_fleisch"]
- Analyse: Schnitzel (rotes_fleisch, getreide für Panade), Kartoffeln (knollen), Pilze (gemuese), Rahm (milchprodukte).
JSON-Output: {{"ist_speise": true, "llm_klassen": [{{"klasse": "rotes_fleisch", "anteil": "dominant"}}, {{"klasse": "getreide", "anteil": "gering"}}, {{"klasse": "knollen", "anteil": "mittel"}}, {{"klasse": "gemuese", "anteil": "gering"}}, {{"klasse": "milchprodukte", "anteil": "gering"}}], "hauptprotein": "rotes_fleisch"}}

Beispiel 2 (Implizite Zutaten):
menu_text: "Flammkuchen Griechischer Art"
vorhandene_klassen: []
- Analyse: Teig (getreide), Schafskäse (milchprodukte), Tomaten/Zwiebeln (gemuese).
JSON-Output: {{"ist_speise": true, "llm_klassen": [{{"klasse": "getreide", "anteil": "dominant"}}, {{"klasse": "milchprodukte", "anteil": "mittel"}}, {{"klasse": "gemuese", "anteil": "gering"}}], "hauptprotein": "milchprodukte"}}

Beispiel 3 (Beilage ist das Hauptgericht):
menu_text: "Großer Pommesteller mit Ketchup"
vorhandene_klassen: []
- Analyse: Hier sind Pommes das Hauptgericht. "knollen" wird klassifiziert. Kein Protein aus den Top 6 vorhanden.
JSON-Output: {{"ist_speise": true, "llm_klassen": [{{"klasse": "knollen", "anteil": "dominant"}}], "hauptprotein": "keine_eindeutige_proteinquelle"}}

---

EINGABE:

gericht_name:
{gericht_name}

menu_text:
{text}

vorhandene_klassen:
{klassen}
'

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
  right_join(llm_classified_short, by = c("name_clean" = "gericht_name")) |> 
  select(-text, -klassen)
