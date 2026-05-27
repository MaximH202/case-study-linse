#Zuweisung zu Lebensmittelklassen und Ernährungsformen


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
    "mais", "polenta", "quinoa", "amaranth", "buchweizen", "couscous", "hirse",
    "bulgur", "nudel", "pasta", "spaghetti", "tagliatelle", "bandnudel", "rigatoni",
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
  ) |>
  select(-classes_name, -classes_text, -is_side, -is_side_name, -is_side_type, -menu_text, -prod_type, -product_name, -name_lc)

  
# classified_long <- classified
classified_short <-classified


#  8. Abdeckung prüfen, aktuell können 95% der Gerichte einer Lebensmittelklasse zugeordnet werden
# classified_long |>
#   mutate(n_classes = map_int(matched_classes, length)) |>
#   summarise(
#     total               = n(),
#     klassifiziert       = sum(n_classes > 0),
#     nicht_klassifiziert = sum(n_classes == 0),
#     abdeckung           = scales::percent(mean(n_classes > 0))
#   )

# nicht klassifizierte
not_classified <- classified |>
  filter(map_int(matched_classes, length) == 0) |> 
  select(-matched_classes)

# Klassifizierte
classified_short <- classified_short |>
  filter(!is.na(matched_classes)) |>
  filter(map_int(matched_classes, length) > 0) |>
  mutate(Klassifizierungsart = "regel") |>
  mutate(klassen = map_chr(matched_classes, ~ paste(.x, collapse = ", "))) |> 
  select(-matched_classes)

# classified_long <- classified_short |>
#   mutate(
#     klassen = str_split(klassen, ",\\s*")
#   ) |>
#   unnest_longer(klassen)
