# 1. Daten-Cleaning

# Stopwords für Filterung definieren (Desserts, Beilagen etc.)
exclude_pattern_name <- "pudding|buffet|kuchen|obst|dessert|^eis$|joghurt|getränk|imbiss|personal|catering|schokolade"
exclude_pattern_type <- "dessert|pudding|kuchen|eis|joghurt|obst|beilage|getränk|buffet|pudding|salat|imbiss|personal|gemüse|catering"

# Hilfsfunktion zur Textbereinigung (Umlaute ersetzen, Sonderzeichen entfernen, etc.)
clean_text <- function(text_column) {
  text_column |>
    str_to_lower() |>
    str_replace_all(c(
      "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss",
      "\\." = " ", ","  = " "
    )) |>
    str_squish()
}

# Hauptgerichte filtern & normieren
# unique_dishes enthält jedes Gericht genau einmal für eine kostengünstigere LLM-Klassifizierung
unique_dishes <- menus |>
  mutate(
    product_name = str_to_lower(product_name),
    prod_type = str_to_lower(prod_type),
    is_side = str_detect(prod_type, exclude_pattern_type) | str_detect(product_name, exclude_pattern_name)
  ) |>
  # Beilagen und Desserts herausfiltern
  filter(!is_side) |>
  # Textbereinigung auf die verbleibenden Einträge anwenden
  mutate(
    product_name = clean_text(product_name),
    menu_text = clean_text(menu_text),
    id = as.integer(id)
  ) |> 
  # Duplikate entfernen, um jedes Gericht nur einmal zu behalten
  distinct(product_name, .keep_all = TRUE) |>
  select(-is_side) |> 
  # Manche Mensen fügen 2 Gerichte in einer Zeile ein ("oder"/"or"). Daher harter Filter:
  filter(!str_detect(menu_text, "\\boder\\b|\\bor\\b"))

# Dieselbe Bereinigung auf den Original-Datensatz (menus) anwenden für den späteren Join
menus <- menus |>
  mutate(
    prod_type = str_to_lower(prod_type),
    product_name = clean_text(product_name),
    menu_text = clean_text(menu_text),
    id = as.integer(id)
  )
