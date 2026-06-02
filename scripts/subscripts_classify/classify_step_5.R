# 5. Ernährungsformen klassifizieren (Level 1)
# Hier bestimmen wir für jedes Gericht die übergreifende Ernährungsform: 
# Ist es omnivor (mit Fleisch), pescetarisch (mit Fisch), vegetarisch oder vegan?
# Die Zuordnung erfolgt hierarchisch: Sobald Fleisch drin ist, ist es omnivor, egal wie viel Gemüse dabei ist.

# Wir schreiben eine Hilfsfunktion, die diese Zuordnung übernimmt.
assign_level1 <- function(klassen_str= " ", menu_text = " ") {
  
  # Sicherheits-Checks: Wenn keine Daten da sind, füllen wir mit Leerzeichen auf, 
  # damit die Funktion nicht abbricht.
  if (is.na(menu_text)) menu_text <- " "
  if (is.na(klassen_str) || klassen_str == " ") return(NA_character_)
  
  # DIREKTER TEXT-CHECK: 
  # Manchmal benennen Mensen ihre Gerichte explizit als "vegan" oder "vegetarisch".
  # Diesem Namen vertrauen wir mehr als der Einzelteilanalyse, daher prüfen wir das zuerst.
  if (grepl("vegan", menu_text, ignore.case = TRUE)) return("vegan")
  if (grepl("vegetarisch", menu_text, ignore.case = TRUE)) return("vegetarisch")
  
  # Wenn der Name nichts Eindeutiges verrät, schauen wir uns die vom LLM gefundenen Klassen an.
  # Dazu schneiden wir unseren Komma-String ("rotes_fleisch, knollen") wieder in Einzelteile.
  klassen_vector <- trimws(strsplit(klassen_str, ",")[[1]])
  
  # HIERARCHISCHE ZUORDNUNG (von oben nach unten):
  # 1. Ist Fleisch dabei? -> omnivor
  if (any(c("rotes_fleisch", "gefluegel") %in% klassen_vector)) return("omnivor")
  # 2. Kein Fleisch, aber Fisch? -> pescetarisch
  if ("fisch" %in% klassen_vector) return("pescetarisch")
  # 3. Kein Fleisch/Fisch, aber Milch oder Ei? -> vegetarisch
  if (any(c("milchprodukte", "ei") %in% klassen_vector)) return("vegetarisch")
  # 4. Keins von alledem, aber es GIBT Zutaten? -> vegan
  if (length(klassen_vector) > 0) return("vegan")
  
  # Falls gar nichts zutrifft
  return(NA_character_)
}

# anwenden der Funktion
llm_classified_short <- llm_classified_short |>
  mutate(
    # geht Zeile für Zeile durch und übergibt die Zutaten ("group_level_2") 
    # und den Originaltext ("menu_text") an unsere Funktion.
    group_level_1 = map2_chr(
      group_level_2,
      menu_text,
      ~ assign_level1(klassen_str = .x, menu_text = .y)
    )
  )
