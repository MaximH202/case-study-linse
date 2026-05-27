#Nutzung von LLM zur Bestimmung von Hauptproteinquelle und Anteil

# Analyse der bereits klassifizierten Mahlzeiten via LLM

reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

user_prompt_template_2 <- "
## Aufgabe

Für den folgenden Mensa-Eintrag sollst du zuerst entscheiden, ob es sich tatsächlich um eine Speise handelt. Dies ist ein Sonderfall, *kein* default-Fallback!

Beispiele für Nicht-Speisen:
- 'Wir machen Urlaub'
- 'Mensa geschlossen'
- 'Feiertag'
- 'Aktionswoche'
- 'Heute kein Betrieb'

#### Sollte der Eintrag nur aus einzelnen Lebensmitteln bestehen, handelt es sich um eine Speise. In diesem Fall sollst du *nicht* ist_speise auf false setzen.

Falls es keine Speise ist:
- setze 'ist_speise' auf false
- gib keine Lebensmittelklassen zurück
- setze 'hauptprotein' auf 'keine_eindeutige_proteinquelle'
- setze 'gruppe_ebene1' auf 'nicht_speise'

Falls es eine Speise ist:
1. schätze den qualitativen Anteil jeder Klasse die dir zu der Speise gegeben wird,
2. bestimme die Hauptproteinquelle.

Berücksichtige sowohl explizit genannte Zutaten als auch typische Hauptbestandteile des Gerichts.

---

## Lebensmittelklassen

{matched_classes_str}

---

## Anteilskategorien

- dominant
  = Hauptbestandteil der Speise

- mittel
  = deutlicher Bestandteil oder relevante Beilage

- gering
  = kleiner, aber noch relevanter Bestandteil der Hauptrezeptur

---

## Hauptproteinquelle

Mögliche Werte:

- {matched_classes_str}
- keine_eindeutige_proteinquelle

---

## Wichtige Regeln

- Konzentriere dich ausschließlich auf Hauptzutaten und wesentliche Rezeptbestandteile.
- Ignoriere Gewürze, Kräuter, kleine Garnituren und technisch notwendige Kleinstmengen.
- Leite implizite Hauptzutaten aus typischen Rezepten ab.

Speise:
{text}
"

schema_2 <- '{
  "type": "object",

  "properties": {

    "ist_speise": {
      "type": "boolean"
    },

    "klassen": {
      "type": "array",
      "description": "Nur relevante, bestätigte Lebensmittelklassen. Kann leer sein bei Nicht-Speisen.",

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

        "required": ["klasse", "anteil"],
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
    "klassen",
    "hauptprotein"
  ],

  "additionalProperties": false
}'

#Daten die durch das Regelwerk nicht klassifiziert werden konnten
batch_menus_classified_2 <- classified_short |> 
  slice_sample(n = 40) |> 
  select(text = menu_clean, klassen)

# LLM 
results <- process_with_llm_openai_multiple_workers(
  data = batch_menus_classified_2,
  model = "gpt-5-nano",
  system_prompt = "You are a food classification assistant for German university cafeterias. 
                   You have extensive knowledge of German and international cuisine.",
  user_prompt_template = user_prompt_template,
  schema = schema_2,
  log_fn = log_to_r,
  max_workers = 5
)

# results in Tibble umwandeln
results_tbl_2 <- as_tibble(results)

# Ergebnis mit nur Hauptlebensmittel
safe_parse <- possibly(fromJSON, otherwise = NA)
llm_classified_2 <- results_tbl_2 |>
  select(-klassen) |>
  mutate(parsed = map(llm_result, safe_parse)) |>
  unnest_wider(parsed) |>
  select(text, hauptprotein)

# Ergebnis parsen Version mit einzelnen Lebensmitteln
llm_classified_2 <- results_tbl_2 |>
  mutate(parsed = map(llm_result, safe_parse)) |>
  unnest_wider(parsed) |>
  unnest_longer(klassen) |>
  unnest_wider(klassen) |>
  select(text, klasse, anteil, hauptprotein)

