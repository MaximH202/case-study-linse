#Nutzung von LLM zur Bestimmung von Hauptproteinquelle und Anteil

#Klassifizierung der restlichen Mahlzeiten via LLM
reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

user_prompt_template <- "
## Aufgabe

Für den folgenden Mensa-Eintrag sollst du zuerst entscheiden, ob es sich tatsächlich um eine Speise handelt.

Beispiele für Nicht-Speisen:
- 'Wir machen Urlaub'
- 'Mensa geschlossen'
- 'Feiertag'
- 'Aktionswoche'
- 'Heute kein Betrieb'

Falls es keine Speise ist:
- setze 'ist_speise' auf false
- gib keine Lebensmittelklassen zurück
- setze 'hauptprotein' auf 'keine_eindeutige_proteinquelle'

Falls es eine Speise ist:
1. bestimme, welche Lebensmittelklassen anhand der Hauptzutaten enthalten sind,
2. ergänze typische implizite Hauptzutaten aus Standardrezepten,
3. schätze den qualitativen Anteil jeder Klasse,
4. bestimme die Hauptproteinquelle.

Berücksichtige sowohl explizit genannte Zutaten als auch typische Hauptbestandteile des Gerichts.

---

## Lebensmittelklassen mit 

keywords <- list(
  rotes_fleisch = c(
    'rind', 'rinder', 'rinderhack', 'rindfleisch', 'rindergeschnetzel',
    'kalb', 'kalbs', 'schwein', 'schweine', 'schweinefleisch',
    'schweineschnitzel', 'schweinenacken', 'spanferkel', 'kotelett',
    'lamm', 'lammfleisch', 'lammhack', 'lammkeule', 'schaf', 'schaffleisch',
    'reh', 'rehgulasch', 'rehbraten', 'hirsch', 'hirschgulasch',
    'wild', 'wildragout', 'wildgulasch', 'cevapcici', 'pork', 'kassler', 
    'salami', 'schinken', 'hamburger', '^schaschlik$', 'ungarische gulaschsuppe', 'spare ribs'
  ),
  gefluegel = c(
    'huhn', 'haehnchen', 'huehnchen', 'huehner', 'haehnchenbrust',
    'huhnbrust', 'chicken', 'gefluegel', 'truthahn',
    'pute', 'puten', 'putenfleisch', 'putenbrust', 'putensteak', 'putenhack',
    'ente', 'entenbrust', 'entenkeule', 'entenfleisch',
    'gans', 'gaensekeule', 'gaensebraten', 'chicken', 'pollo'
  ),
  fisch = c(
    'fisch', 'fischfilet', 'lachs', 'seelachs', 'kabeljau', 'backfisch',
    'thunfisch', 'forelle', 'petersfisch', 'st pierre', 'dorade',
    'meeresfrueecht', 'meeresfruecht', 'meeresfrucht', 'muschel',
    'miesmuschel', 'garnele', 'shrimp', 'scampi', 'krabbe', 'calamares',
    'tintenfisch', 'scholle', 'hering', 'makrele', 'zander', 'barsch', 'fish'
  ),
  milchprodukte = c(
    'kaese', 'grillkaese', 'hirtenkaese', 'fetakaese', 'camembert',
    'mozzarella', 'halloumi', 'kaiserschmarrn',
    'joghurt', 'jogurt', 'quark', 'milch', 'buttermilch',
    'sahne', 'schmand', 'creme fraiche', 'sauerrahm', 'rahm'
  ),
  ei = c(
    'ruehrei', 'spiegelei', 'wachtelei', 'pochiertem ei',
    'gekochtem ei', 'eiergericht', '^ei$'
  ),
  huelsenfruechte = c(
    'linse', 'linsen', 'kichererbse', 'kichererbs', 'hummus', 'humus',
    'falafel', 'bohn', 'kidney', 'black bean', 'erbse', 'erbsen',
    'lupin', 'lupinen', 'soja', 'sojafleisch', 'sojaschnetzel',
    'sojabohn', 'tofu', 'raeuuchertofu', 'tempeh', 'edamame'
  ),
  getreide = c(
    'weizen', 'vollkorn', 'reis', 'basmati', 'hafer', 'haferflock', 'kaiserschmarrn', 'pfannkuchen',
    'mais', 'polenta', 'quinoa', 'amaranth', 'buchweizen', 'couscous',
    'bulgur', 'nudel', 'pasta', 'spaghetti', 'tagliatelle', 'bandnudel', 'rigatoni',
    'farfalle', 'penne', 'fusilli', 'fussili', 'maccaroni', 'tortelloni', 'tortellini', 'spaetzle', 'gebaeck', 
    'pizza', 'grieß', 'brot'
  ),
  knollen = c(
    'kartoffel', 'kartoffelpuffer', 'kartoffelgratin', 'kartoffelstampf',
    'bratkartoffel', 'salzkartoffel', 'puerree', 'pueree',
    'suesskartoffel', 'pastinake', 'maniok', 'pommes', 'roesti', 'gnocchi', 'wedges'
  ),
  gemuese = c(
    'spinat', 'gruenkohl', 'wirsing', 'mangold', 'brokkoli', 'broccoli',
    'pak choi', 'chinakohl', 'karott', 'moehre', 'kuerbis', 'paprika',
    'tomat', 'rote bete', 'chili', 'kohl', 'lauch', 'porree', 'zwiebel',
    'sellerie', 'gurk', 'zucchini', 'aubergine', 'fenchel', 'spargel',
    'pilz', 'champignon', 'olive', 'gemuese'
  ),
  nuesse = c(
    'mandel', 'walnuss', 'haselnuss', 'cashew', 'pistazie',
    'pinienkern', 'kastanie', 'marone', 'kokos', 'erdnuss'
  ),
  samen = c(
    'sonnenblumenkern', 'kuerbiskern', 'sesam', 'leinsamen',
    'chia', 'hanfsamen', 'mohn'
  )
)

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

- rotes_fleisch
- gefluegel
- fisch
- milchprodukte
- ei
- huelsenfruechte
- nuesse
- samen
- keine_eindeutige_proteinquelle

---

## Wichtige Regeln

- Konzentriere dich ausschließlich auf Hauptzutaten und wesentliche Rezeptbestandteile.
- Ignoriere Gewürze, Kräuter, kleine Garnituren und technisch notwendige Kleinstmengen.
- Zutaten sollen nur dann klassifiziert werden, wenn sie einen relevanten Anteil an der Speise haben.
- Leite implizite Hauptzutaten aus typischen Rezepten ab.
- Gib nur Lebensmittelklassen aus, die plausibel und relevant enthalten sind.
- Mehrere Klassen können gleichzeitig vorkommen.
- Pilze zählen zu 'gemuese'.
- Teige, Nudeln, Reis etc. zählen zu 'getreide'.
- Sahne- oder Käsesaucen zählen zu 'milchprodukte', wenn sie ein relevanter Bestandteil der Speise sind.

Speise:
{text}
"

schema <- '{
  "type": "object",

  "properties": {

    "ist_speise": {
      "type": "boolean"
    },

    "klassen": {
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
    "klassen",
    "hauptprotein"
  ],

  "additionalProperties": false
}'

#Daten die durch das Regelwerk nicht klassifiziert werden konnten
batch_menus_not_classified <- not_classified |> 
  slice_sample(n = 40) |> 
  select(text = menu_clean) 

# LLM 
results <- process_with_llm_openai_multiple_workers(
  data = batch_menus_not_classified,
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

# Ergebnis parsen
safe_parse <- possibly(fromJSON, otherwise = NA)

# Klassen in mehreren Zeilen
# llm_classified_long<- results_tbl |>
#   mutate(parsed = map(llm_result, safe_parse)) |>
#   unnest_wider(parsed) |>
#   unnest_longer(klassen) |>
#   unnest_wider(klassen) |>
#   select(text, klasse, anteil, hauptprotein) |> 
#   mutate(Klassifizierungsart = "llm")

# Klassen in einer Zeile, Datensätze bei denen keine Lebensmittelklasse erkannt wurde wird gelöscht 
llm_classified_short <- results_tbl |>
  mutate(parsed = map(llm_result, safe_parse)) |>
  unnest_wider(parsed) |>
  unnest_longer(klassen) |>
  unnest_wider(klassen) |>
  group_by(text) |>
  summarise(
    klasse = paste(klasse, collapse = ", "),
    hauptprotein = first(hauptprotein),
    .groups = "drop"
  ) |> 
  select(text, klasse, hauptprotein)

# Nur Hauptprotein
# llm_classified_mainprotein <- results_tbl |>
#   mutate(parsed = map(llm_result, safe_parse)) |>
#   unnest_wider(parsed) |>
#   select(text, hauptprotein)

#join der Klassen vom llm und regelbasiert
# llm_classified_join <- not_classified %>%
#   right_join(
#     llm_classified_short,
#     by = c("menu_clean" = "text")
#   ) |>
#   distinct(menu_clean, .keep_all = TRUE)
