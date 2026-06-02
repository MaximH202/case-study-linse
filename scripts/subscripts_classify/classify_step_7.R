# 7. Zusammenführen (Join) und Speichern der Daten
# Wir haben jetzt unsere Klassifizierungen in isolierten Datensätzen (unique_dishes).
# Nun müssen wir diese Ergebnisse wieder an unseren großen Original-Datensatz 
# ("menus") mit allen Duplikaten und Standorten anheften.

# Zuerst holen wir das berechnete Hauptprotein aus der "Long"-Version in unsere "Short"-Version.
# Da die ID in beiden Datensätzen gleich ist, geht das ganz einfach per left_join.
llm_classified_short <- llm_classified_short |> 
  left_join(llm_classified_long |> distinct(id, code_main_protein), by = "id")

# Jetzt kleben wir die Short-Ergebnisse an den Hauptdatensatz (menus).
# Wir joinen über den "product_name"
menus_short <- menus |> 
  select(-menu_text) |> # Vermeidung der durch den Join entstandenen ID-Doppelungen
  inner_join(llm_classified_short, by = "product_name") |> 
  rename(id = id.x) |> # Bereinigung der durch den Join entstandenen ID-Doppelungen
  select(-id.y)

# Das Gleiche machen wir für die "Long"-Version (wo jede Zutat eine eigene Zeile hat).
menus_long <- menus |> 
  select(-menu_text) |> 
  inner_join(llm_classified_long, by = "product_name") |> 
  rename(id= id.x) |> 
  select(-id.y)

# Wir sortieren die Spalten in eine logische und gut lesbare Reihenfolge
menus_long <- menus_long |> 
  select(
    id,
    student_service,
    cafeteria,
    source_file,
    date,
    prod_type,
    production_location,
    actual_output,
    product_name,
    menu_text,
    group_level_2,    
    anteil,            
    code_main_protein,  
    proteincode         
  )

menus_short <- menus_short |> 
  select(
    id,
    student_service,
    cafeteria,
    source_file,
    date,
    prod_type,
    production_location,
    actual_output,
    product_name,
    menu_text,
    group_level_2,     
    code_main_protein,  
    group_level_1       
  )

# abspeichern als CSV-Dateien
write_csv(menus_short, "data/menus_classified.csv")
write_csv(menus_long, "data/menu_components.csv")