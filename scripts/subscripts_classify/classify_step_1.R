#Bereinigung der Daten


exclude_pattern_name <- str_c(
  "pudding", "buffet", "kuchen", "obst", "dessert", "^eis$", "joghurt", "getränk", "imbiss", "personal", "catering", "schokolade"
  ,sep = "|")

exclude_pattern_type <- str_c(
  "dessert", "pudding", "kuchen", "eis", "joghurt",
  "obst", "beilage", "getränk", "buffet", "pudding", "salat", "imbiss", "personal", "gemüse", "catering"
  ,sep = "|"
)
#  3. Unique Dishes filtern & bereinigen

unique_dishes <- menus |>
  mutate(
    name_lc = str_to_lower(product_name),
    type_lc = str_to_lower(prod_type),
    is_side_type = str_detect(type_lc, exclude_pattern_type),
    is_side_name = str_detect(name_lc, exclude_pattern_name),
    is_side = is_side_type | is_side_name
  ) |>
  filter(!is_side) |>
  distinct(product_name, .keep_all = TRUE) |>
  mutate(
    name_clean = product_name |>
      str_to_lower() |>
      str_replace_all(c(
        "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss",
        "\\." = " ", ","  = " "
      )) |>
      str_squish()
  ) |> 
    mutate(
    menu_clean = menu_text |>
      str_to_lower() |>
      str_replace_all(c(
        "ä" = "ae", "ö" = "oe", "ü" = "ue", "ß" = "ss",
        "\\." = " ", ","  = " "
      )) |>
      str_squish()
  ) 

