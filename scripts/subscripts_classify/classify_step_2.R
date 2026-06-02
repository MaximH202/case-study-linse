# 2. Zuordnung zu Lebensmittelklassen

# Keywords für die einzelnen Klassen definieren
keywords <- list(
rotes_fleisch = c(
  "rind", "rinder", "rinderhack", "rindfleisch", "rindergeschnetzel",
  "kalb", "kalbs", "kalbfleisch", "kalbsschnitzel",
  "schwein", "schweine", "schweinefleisch", "schweinebraten",
  "schweineschnitzel", "schweinenacken", "schweinefilet",
  "spanferkel", "kotelett", "kassler",
  "lamm", "lammfleisch", "lammhack", "lammkeule", "lammkotelett",
  "schaf", "schaffleisch", "hacksteak", "pulled beef",
  "reh", "rehgulasch", "rehbraten", "rehkeule",
  "hirsch", "hirschgulasch", "hirschbraten",
  "wild", "wildragout", "wildgulasch", "wildschwein",
  "cevapcici", "pork", "salami", "hamburger",
  "gulasch", "spare ribs", "leberkaes",
  "mett", "hackbraten", "roulade", "beef", "pastrami", "corned beef"
),

gefluegel = c(
  "huhn", "haehnchen", "huehnchen", "huehner", "haehnchenbrust",
  "huhnbrust", "huhnfilet", "chicken", "gefluegel",
  "truthahn", "pute", "puten", "putenfleisch", "putenbrust",
  "putensteak", "putenhack", "putenschnitzel",
  "ente", "entenbrust", "entenkeule", "entenfleisch",
  "gans", "gaensekeule", "gaensebraten",
  "pollo", "maishaehnchen", "hendl",
  "coq", "perlhuhn"
),

fisch = c(
  "fisch", "fischfilet", "lachs", "seelachs", "kabeljau", "backfisch",
  "thunfisch", "forelle", "petersfisch", "st pierre", "dorade",
  "matjes", "hering", "makrele", "zander", "barsch",
  "scholle", "heilbutt", "rotbarsch", "seezunge",
  "meeresfrueecht", "meeresfruecht", "meeresfrucht",
  "muschel", "miesmuschel", "jakobsmuschel",
  "garnele", "shrimp", "scampi", "krabbe",
  "calamares", "tintenfisch", "oktopus",
  "fish", "seeteufel", "sardine", "anchovis", "aal", "aalfilet", "butt", "steinbutt", "flunder",
  "sprotte", "kieler sprotte", "stint",
  "felchen", "renke", "maraene", "saibling", "seesaibling", "bachsaibling", "karpfen", "wels", "welsfilet", "hecht",
  "lachsforelle", "wildlachs", "silberlachs",
  "atlantiklachs", "pazifiklachs","seehecht","pollack", "pollak", "koehler","schellfisch", "dorsch", "skrei","wolfsbarsch", "seebarsch",
  "steinbeisser", "steinbeißer","tilapia", "pangasius", "pangasiusfilet",
  "victoriabarsch", "victoriaseebarsch","red snapper", "snapper","sardelle", "ansjovis", "anchovy",
  "aalrauch", "raeucheraal","fischfrikadelle", "fischfrikadellen",
  "fischstaebchen", "fischstäbchen","fischburger","fischragout", "fischpfanne",
  "fischcurry", "fischgulasch","riesengarnele", "riesengarnelen", "prawn", "king prawn",
  "flusskrebs", "flusskrebse", "hummer", "languste", "langustine",
  "kaisergranat", "krustentier", "krustentiere",
  "auster", "austern", "venusmuschel", "vongole", "vongole veraci"
),

milchprodukte = c(
  "grillkaese", "hirtenkaese", "fetakaese", "schafskaese", "schafkaese", "ziegenkaese",
  "camembert", "brie", "mozzarella", "halloumi",
  "parmesan", "gouda", "emmentaler", "bergkaese",
  "frischkaese", "ricotta", "mascarpone",
  "joghurt", "jogurt", "quark", "milch", "buttermilch", "schmand", "creme fraiche", "sauerrahm", "rahm",
  "kefir", "molke", "skyr", "auflauf"
),

ei = c(
  "ruehrei", "spiegelei", "wachtelei", "pochiertem ei",
  "gekochtem ei", "eiergericht", "^ei$",
  "omelett", "omelette", "eierspeise",
  "eiersalat", "eiweiss", "eigelb"
),

huelsenfruechte = c(
  "linse", "linsen", "rote linse", "braune linse", "gruene linse", "belugalinse",
  "kichererbse", "kichererbs", "kichererbsenmehl", "kichererbsen",
  "hummus", "humus", "falafel",
  "soja", "sojabohn", "sojabohne", "sojabohnen",
  "sojafleisch", "sojaschnetzel", "sojagranulat", "sojamedaillons",
  "tofu", "raeuchertofu", "seidentofu", "tempeh", "edamame",
  "bohn", "bohnen", "kidney", "kidneybohne", "black bean", "schwarze bohne",
  "weisse bohne", "rote bohne", "braune bohne", "dicke bohne",
  "mungbohne", "mung", "ackerbohne", "lupin", "lupinen",
  "erbsen", "erbse", "grüne erbsen", "spalterbse",
  "adukibohne", "azukibohne", "butterbohne",
  "borlotti", "borlottibohnen", "chili sin carne",
  "cannellini", "cannellinibohnen"
),

getreide = c(
  "weizen", "vollkorn", "vollkornweizen", "dinkel", "gerste", "roggen",
  "reis", "basmati", "jasmine reis", "sushireis",
  "hafer", "haferflock", "haferflocken",
  "mais", "maiskorn", "polenta",
  "quinoa", "amaranth", "buchweizen",
  "hirse", "bulgur", "couscous",
  "nudel", "nudeln", "pasta", "spaghetti", "tagliatelle",
  "bandnudel", "bandnudeln", "rigatoni", "farfalle", "penne",
  "fusilli", "fussili", "maccaroni", "macaroni",
  "tortelloni", "tortellini", "spaetzle", "spätzle", "eierknoepfle",
  "risotto", "gries", "griess", "grieß",
  "brot", "baguette", "broetchen", "brötchen", "toast", "ciabatta",
  "fladenbrot", "wrap", "lavash", "tortilla",
  "pizza", "lasagne", "ravioli",
  "pfannkuchen", "kaiserschmarrn", "crepe", "crêpe",
  "haferbrei", "porridge"
),

knollen = c(
  "kartoffel", "kartoffeln", "kartoffelpuffer", "kartoffelgratin",
  "kartoffelstampf", "bratkartoffel", "bratkartoffeln",
  "salzkartoffel", "salzkartoffeln",
  "pueree", "puerree", "kartoffelpueree", "kartoffelpüree",
  "suesskartoffel", "süsskartoffel", "sweet potato",
  "pastinake", "maniok", "cassava",
  "pommes", "pommes frites", "fritten", "fries",
  "roesti", "rösti",
  "gnocchi", "wedges", "kroketten", "krokette"
),

gemuese = c(
  "spinat", "gruenkohl", "wirsing", "mangold",
  "brokkoli", "broccoli", "pak choi", "chinakohl",
  "karott", "moehre", "kuerbis", "paprika",
  "tomat", "rote bete", "chili", "kohl",
  "lauch", "porree", "zwiebel", "sellerie",
  "gurk", "zucchini", "aubergine", "fenchel",
  "spargel", "pilz", "champignon", "olive",
  "gemuese", "blumenkohl", "rosenkohl",
  "kohlrabi", "artischocke", "radies",
  "rettich", "rotebeete", "avocado",
  "bohnenkraut", "sauerkraut", "champignon"
),

nuesse = c(
  "mandel", "walnuss", "haselnuss", "cashew",
  "pistazie", "pinienkern", "kastanie",
  "marone", "kokos", "erdnuss",
  "macadamia", "pecannuss", "pekannuss",
  "paranuss"
),

samen = c(
  "sonnenblumenkern", "kuerbiskern",
  "sesam", "leinsamen", "chia",
  "hanfsamen", "mohn",
  "flohsamen", "nigella"
)
)
# Erstellt ein reguläres RegExp-Pattern aus der Keyword-Liste (trennt Wörter mit OR |)
make_pattern <- function(kws) {
  kws |>
    str_replace_all("\\*", "") |>
    str_c(collapse = "|")
}

# Prüft, welche Lebensmittelklassen auf ein Gericht zutreffen (liefert Namen der zutreffenden Klassen zurück)
classify_row <- function(name_clean) {
  matches <- keywords |>
    imap_lgl(~ str_detect(name_clean, make_pattern(.x)))
  names(matches)[matches]
}

# Parallelisierung (Kerne je nach CPU wählen, 4 sollten bei den meisten gehen)
plan(multisession, workers = 8)

# Keywords auf Produktname und Beschreibung matchen, zusammenführen und als String formatieren
unique_dishes <- unique_dishes |>
  mutate(
    classes_name = future_map(product_name, classify_row),
    classes_text = future_map(menu_text, classify_row),
    
    # Ergebnisse aus Produktname und Beschreibung zusammenführen und Duplikate entfernen
    matched_classes = map2(classes_name, classes_text, ~ unique(c(.x, .y))),
    
    # Die gematchten Klassen als Komma-getrennten String speichern für bessere Lesbarkeit
    klassen = map_chr(matched_classes, ~ paste(.x, collapse = ", "))
  ) |>
  # Hilfsspalten wieder löschen
  select(-classes_name, -classes_text, -matched_classes)
