#Zuweisung zu Lebensmittelklassen und Ernährungsformen

# Erstellung einer Liste mit den Lebensmittelklassen und typischen Wörtern die dazugehören
keywords <- list(
  rotes_fleisch = c(
    "rind", "rinder", "rinderhack", "rindfleisch", "rindergeschnetzel",
    "kalb", "kalbs", "schwein", "schweine", "schweinefleisch",
    "schweineschnitzel", "schweinenacken", "spanferkel", "kotelett",
    "lamm", "lammfleisch", "lammhack", "lammkeule", "schaf", "schaffleisch",
    "reh", "rehgulasch", "rehbraten", "hirsch", "hirschgulasch",
    "wild", "wildragout", "wildgulasch", "cevapcici", "pork", "kassler", 
    "salami", "hamburger", "^schaschlik$", "ungarische gulaschsuppe", "spare ribs"
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
    "sahne", "schmand", "creme fraiche", "sauerrahm", "rahm", "!leberkaese"
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
#Funktion zur Textformatierung
make_pattern <- function(kws) {
  kws |>
    str_replace_all("\\*", "") |>
    str_c(collapse = "|")
}
#Funktion zum mapen der Keywords auf eine Liste von Namen
classify_row <- function(name_clean) {
  matches <- keywords |>
    imap_lgl(~ str_detect(name_clean, make_pattern(.x)))
  names(matches)[matches]
}

#4 Kerne für mehr Effizienz
plan(multisession, workers = 4)

# Mapen der Keywords auf die Produkt_namen und menu_text, Ergebnisse werden zusammengelegt
unique_dishes <- unique_dishes |>
  mutate(
    classes_name = future_map(product_name, classify_row),
    classes_text = future_map(menu_text, classify_row),
    
    # Beide Listen vereinen, Duplikate entfernen
    matched_classes = map2(classes_name, classes_text, ~ unique(c(.x, .y)))
  ) |>
  #entfernt überflüssige Spalten
  select(-classes_name, -classes_text)


# Klassen werden von Vektor-Format in leserliches (, getrenntes) Format gebracht
unique_dishes <- unique_dishes |>
  mutate(klassen = map_chr(matched_classes, ~ paste(.x, collapse = ", "))) |> 
  select(-matched_classes)
