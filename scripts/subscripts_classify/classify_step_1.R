# 1. Daten-Cleaning: Vorbereitung der Speiseplandaten
# In diesem Schritt bereinigen wir die Texte, vereinheitlichen Schreibweisen und 
# sortieren irrelevante Einträge (wie reine Beilagen oder Desserts) aus.

# Wir definieren zunächst Schlüsselwörter (Stopwords), mit denen wir typische 
# Beilagen, Desserts und nicht-Speise-Einträge (z.B. "Personal", "Buffet") erkennen.
exclude_pattern_name <- "pudding|buffet|kuchen|obst|dessert|^eis$|joghurt|getränk|imbiss|personal|catering|schokolade"
exclude_pattern_type <- "dessert|pudding|kuchen|eis|joghurt|obst|beilage|getränk|buffet|pudding|salat|imbiss|personal|gemüse|catering"

# Eine Hilfsfunktion, um Texte zu "säubern". 
# Sie wandelt alles in Kleinbuchstaben um, ersetzt Umlaute durch ihre 
# Ersatzschreibweisen (z.B. "ä" wird "ae") und entfernt Satzzeichen wie Punkte und Kommata.
# str_squish entfernt überflüssige Leerzeichen.
clean_text <- function(text_column) {
  text_column |>
    str_to_lower() |>
    str_replace_all(c(
      "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss",
      "\\." = " ", ","  = " "
    )) |>
    str_squish()
}

# Wir filtern die Hauptgerichte heraus und normieren sie.
# Ziel ist es, in "unique_dishes" jedes einzigartige Gericht genau einmal zu haben.
# Das spart  Zeit und Geld, wenn wir die Daten später an das LLM schicken.
unique_dishes <- menus |>
  mutate(
    # Wir wandeln Namen und Typen zur Sicherheit in Kleinbuchstaben um,
    # damit unsere Keywords (exclude_pattern) verlässlich greifen.
    product_name = str_to_lower(product_name),
    prod_type = str_to_lower(prod_type),
    
    # Prüfen, ob Name oder Kategorie auf ein Dessert/Beilage hindeuten
    is_side = str_detect(prod_type, exclude_pattern_type) | str_detect(product_name, exclude_pattern_name)
  ) |>
  # Wir werfen alles raus, was als Beilage/Dessert erkannt wurde
  filter(!is_side) |>
  
  # Nun machen wir die Texte mit clean_text einheitlich
  mutate(
    product_name = clean_text(product_name),
    menu_text = clean_text(menu_text),
    id = as.integer(id)
  ) |> 
  
  # entfernen der Duplikate
  distinct(product_name, .keep_all = TRUE) |>
  
  # Die Hilfsspalte "is_side" brauchen wir nicht mehr.
  select(-is_side) |> 
  
  # Manche Mensen schreiben zwei Gerichte in eine Zeile (z.B. "Pizza oder Pasta").
  # Solche uneindeutigen Fälle filtern wir komplett aus, da sie die Klassifikation stören würden.
  filter(!str_detect(menu_text, "\\boder\\b|\\bor\\b"))

# Damit wir später die klassifizierten Ergebnisse (unique_dishes) wieder 
# an den ursprünglichen, vollen Datensatz joinen können, müssen wir "menus" auf die 
# gleiche Weise bereinigen.
menus <- menus |>
  mutate(
    prod_type = str_to_lower(prod_type),
    product_name = clean_text(product_name),
    menu_text = clean_text(menu_text),
    id = as.integer(id)
  )
