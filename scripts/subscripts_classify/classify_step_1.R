#Bereinigung der Daten

#Wörter die in der Kategorie product_name und product_type herausgefiltert werden
exclude_pattern_name <- str_c(
  "pudding", "buffet", "kuchen", "obst", "dessert", "^eis$", "joghurt", "getränk", "imbiss", "personal", "catering", "schokolade"
  ,sep = "|")

exclude_pattern_type <- str_c(
  "dessert", "pudding", "kuchen", "eis", "joghurt",
  "obst", "beilage", "getränk", "buffet", "pudding", "salat", "imbiss", "personal", "gemüse", "catering"
  ,sep = "|"
)

# Unique Dishes filtern & bereinigen

unique_dishes <- menus |>
  mutate(
    #name und typ in lowercase
    product_name = str_to_lower(product_name),
    prod_type = str_to_lower(prod_type),
    # Geht alle Wörter durch, herausgefilterte werden in einer Liste gespeichert
    is_side_type = str_detect(prod_type, exclude_pattern_type),
    is_side_name = str_detect(product_name, exclude_pattern_name),
    is_side = is_side_type | is_side_name
  ) |>
  #eigentlicher Filter
  filter(!is_side) |>
  # distinct um jedes product_name nur einmal zu haben
  distinct(product_name, .keep_all = TRUE) |>
  select(-is_side_type, -is_side_name, -is_side) |> 
  # Umlaute und kleinbuchstaben für product_name und menu_clean
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
  ) 

