# 1. Daten-Cleaning

# Stopwords für Filterung definieren (Desserts, Beilagen etc.)
exclude_pattern_name <- str_c(
  "pudding", "buffet", "kuchen", "obst", "dessert", "^eis$", "joghurt", "getränk", "imbiss", "personal", "catering", "schokolade"
  ,sep = "|")

exclude_pattern_type <- str_c(
  "dessert", "pudding", "kuchen", "eis", "joghurt",
  "obst", "beilage", "getränk", "buffet", "pudding", "salat", "imbiss", "personal", "gemüse", "catering"
  ,sep = "|"
)

# Hauptgerichte filtern & normieren
# unique_dishes enthält jedes Gericht genau einmal für eine kostengünstigere LLM-Klassifizierung

unique_dishes <- menus |>
  mutate(
    # Erstmal alles in Kleinbuchstaben umwandeln
    product_name = str_to_lower(product_name),
    prod_type = str_to_lower(prod_type),
    # Prüfen, ob das Gericht eine Beilage oder ein Dessert ist
    is_side_type = str_detect(prod_type, exclude_pattern_type),
    is_side_name = str_detect(product_name, exclude_pattern_name),
    is_side = is_side_type | is_side_name
  ) |>
  # Beilagen und Desserts herausfiltern
  filter(!is_side) |>
  # Duplikate entfernen, um jedes Gericht nur einmal zu behalten
  distinct(product_name, .keep_all = TRUE) |>
  select(-is_side_type, -is_side_name, -is_side) |> 
  # Umlaute ersetzen und Sonderzeichen bereinigen (str_squish entfernt doppelte Leerzeichen)
  mutate(
    product_name = product_name |>
      str_to_lower() |>
      str_replace_all(c(
        "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss",
        "\\." = " ", ","  = " "
      )) |>
      str_squish()
  ) |> 
    mutate(
    menu_text = menu_text |>
      str_to_lower() |>
      str_replace_all(c(
        "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss",
        "\\." = " ", ","  = " "
      )) |> 
      str_squish()
  ) |> 
  # Manche Mensen fügen 2 Gerichte in einer Zeile ein. Diese können kaum sinnvoll ausgewertet werden und verwirren das LLM.
  # Diese werden oft durch "oder"/ "or" getrennt. Daher harter Filter, alle Einträge in denen oder/or alleine stehen rausfiltert.
  filter(!str_detect(menu_text, "\\boder\\b|\\bor\\b")) |>
  mutate(id = as.integer(id))

# Dieselbe Bereinigung auf den Original-Datensatz (menus) anwenden für den späteren Join
menus <- menus |>
  mutate(
    # Spalten in Kleinbuchstaben umwandeln
    prod_type = str_to_lower(prod_type),
  ) |>
  # Umlaute und Sonderzeichen auch in den Rohdaten bereinigen
  mutate(
    product_name = product_name |>
      str_to_lower() |>
      str_replace_all(c(
        "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss",
        "\\." = " ", ","  = " "
      )) |>
      str_squish()
  ) |> 
    mutate(
    menu_text = menu_text |>
      str_to_lower() |>
      str_replace_all(c(
        "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss",
        "\\." = " ", ","  = " "
      )) |> 
      str_squish()
  ) |> 
  mutate(id = as.integer(id))
