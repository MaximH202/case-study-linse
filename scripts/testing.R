
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

# 4. Keywords

keywords <- list(
  rotes_fleisch = c(
    "rind", "rinder", "rinderhack", "rindfleisch", "rindergeschnetzel",
    "kalb", "kalbs", "schwein", "schweine", "schweinefleisch",
    "schweineschnitzel", "schweinenacken", "spanferkel", "kotelett",
    "lamm", "lammfleisch", "lammhack", "lammkeule", "schaf", "schaffleisch",
    "reh", "rehgulasch", "rehbraten", "hirsch", "hirschgulasch",
    "wild", "wildragout", "wildgulasch", "cevapcici", "pork", "kassler", 
    "salami", "schinken", "hamburger", "^schaschlik$", "ungarische gulaschsuppe", "spare ribs"
  ),
  gefluegel = c(
    "huhn", "haehnchen", "huehnchen", "huehner", "haehnchenbrust",
    "huhnbrust", "chicken", "gefluegel", "truthahn",
    "pute", "puten", "putenfleisch", "putenbrust", "putensteak", "putenhack",
    "ente", "entenbrust", "entenkeule", "entenfleisch",
    "gans", "gaensekeule", "gaensebraten", "chicken", "pollo"
  ),
  fisch = c(
    "fisch", "fischfilet", "lachs", "seelachs", "kabeljau", "backfisch",
    "thunfisch", "forelle", "petersfisch", "st pierre", "dorade",
    "meeresfrueecht", "meeresfruecht", "meeresfrucht", "muschel",
    "miesmuschel", "garnele", "shrimp", "scampi", "krabbe", "calamares",
    "tintenfisch", "scholle", "hering", "makrele", "zander", "barsch", "fish"
  ),
  milchprodukte = c(
    "kaese", "grillkaese", "hirtenkaese", "fetakaese", "camembert",
    "mozzarella", "halloumi", "kaiserschmarrn",
    "joghurt", "jogurt", "quark", "milch", "buttermilch",
    "sahne", "schmand", "creme fraiche", "sauerrahm", "rahm"
  ),
  ei = c(
    "ruehrei", "spiegelei", "wachtelei", "pochiertem ei",
    "gekochtem ei", "eiergericht", "^ei$"
  ),
  huelsenfruechte = c(
    "linse", "linsen", "kichererbse", "kichererbs", "hummus", "humus",
    "falafel", "bohn", "kidney", "black bean", "erbse", "erbsen",
    "lupin", "lupinen", "soja", "sojafleisch", "sojaschnetzel",
    "sojabohn", "tofu", "raeuuchertofu", "tempeh", "edamame"
  ),
  getreide = c(
    "weizen", "vollkorn", "reis", "basmati", "hafer", "haferflock", "kaiserschmarrn", "pfannkuchen",
    "mais", "polenta", "quinoa", "amaranth", "buchweizen", "couscous",
    "bulgur", "nudel", "pasta", "spaghetti", "tagliatelle", "bandnudel",
    "farfalle", "penne", "fusilli", "fussili", "maccaroni", "tortelloni", "tortellini", "spaetzle", "gebaeck", 
    "pizza", "grieß", "brot"
  ),
  knollen = c(
    "kartoffel", "kartoffelpuffer", "kartoffelgratin", "kartoffelstampf",
    "bratkartoffel", "salzkartoffel", "puerree", "pueree",
    "suesskartoffel", "pastinake", "maniok", "pommes", "roesti", "gnocchi", "wedges"
  ),
  gemuese = c(
    "spinat", "gruenkohl", "wirsing", "mangold", "brokkoli", "broccoli",
    "pak choi", "chinakohl", "karott", "moehre", "kuerbis", "paprika",
    "tomat", "rote bete", "chili", "kohl", "lauch", "porree", "zwiebel",
    "sellerie", "gurk", "zucchini", "aubergine", "fenchel", "spargel",
    "pilz", "champignon", "olive", "gemuese"
  ),
  nuesse = c(
    "mandel", "walnuss", "haselnuss", "cashew", "pistazie",
    "pinienkern", "kastanie", "marone", "kokos", "erdnuss"
  ),
  samen = c(
    "sonnenblumenkern", "kuerbiskern", "sesam", "leinsamen",
    "chia", "hanfsamen", "mohn"
  )
)

# 5. Klassifikations-Funktionen

make_pattern <- function(kws) {
  kws |>
    str_replace_all("\\*", "") |>
    str_c(collapse = "|")
}

classify_row <- function(name_clean) {
  matches <- keywords |>
    imap_lgl(~ str_detect(name_clean, make_pattern(.x)))
  names(matches)[matches]
}

#  7. Auf alle Gerichte anwenden (name und menu_text)

classified <- unique_dishes |>
  mutate(
    classes_name = map(name_clean, classify_row),
    classes_text = map(menu_clean, classify_row),
    
    # Beide Listen vereinen, Duplikate entfernen
    matched_classes = map2(classes_name, classes_text, ~ unique(c(.x, .y)))
  )

#  8. Abdeckung prüfen, aktuell können 95% der Gerichte einer Lebensmittelklasse zugeordnet werden
classified |>
  mutate(n_classes = map_int(matched_classes, length)) |>
  summarise(
    total               = n(),
    klassifiziert       = sum(n_classes > 0),
    nicht_klassifiziert = sum(n_classes == 0),
    abdeckung           = scales::percent(mean(n_classes > 0))
  )

# Stichprobe der nicht klassifizierten
not_classified <- classified |>
  filter(map_int(matched_classes, length) == 0)

