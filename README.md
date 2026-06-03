## Solution Documentation

### Task 1: Datenaufbereitung

#### Gefilterte Daten:

Wir haben uns dazu entschieden, uns hauptsächlich auf Hauptgerichte zu konzentrieren. Daher haben wir in verschiedenen classify_schritten versucht, Beilagen und Einträge, bei denen es sich nicht um Speisen handelte, herauszufiltern.

### Task 2: Classification of Menu Items

Wir haben die Klassifizierung der Daten in zwei Schritten durchgeführt. Zunächst haben wir eine key_word suche über die product_names und menu_text Spalten laufen lassen, und die Ergebnisse
zussamengeführt (siehe classify_step_2). Danach haben wir diese Klassen dem LLM übergeben und ihm dabei zwei Aufgaben erteilt:
1. Das Ergänzen von fehlenden Klassen
2. Das Abschätzen der Anteile der einzelnen Klassen am gesamten Gericht (gering, mittel dominant). Dabei lag der Fokus auf Hauptkomponenten eines Gerichts.

Diese Ergebnisse haben wir dann genutzt, um zwei Tabellen zu bauen.
1. *llm_classified_long* listet alle Gerichte mit ihren einzelnen Komponenten und deren Anteil auf
2. *llm_classified_short* listet alle Gerichte mit ihrer Ernährungsform und dem Hauptprotein auf

Ernährungsform und Hauptprotein wurden nicht durch ein LLM, sondern feste Regeln bestimmt.
##### Ernährungsform

Die Ernährungsform wird durch ein hierarchisches System bestimmt. Ganz oben steht die Wort-Suche nach vegetarisch oder vegan in den Daten (eindeutig).
Danach wird stufenweise anhand der Lebensmittelklassen bestimmt (siehe classify_step_5). Diese Art der Ermittlung beugt Halluzinationen des LLMs vor. Jedoch ist das Ergebnis eng gebunden an der Qualität des Outputs des LLM.
#### Hauptprotein

Das Hauptprotein wird durch eine mathematische Formel bestimmt. Den einzelnen Lebensmittelklassen werden dabei Werte zugeordnet und dann mit dem Anteil am Gericht verrechnet um so das 
Hauptprotein zu bestimmen (siehe classify_step_6). Diese Art der Ermittlung beugt Halluzinationen des LLMs vor. Jedoch ist das Ergebnis eng gebunden an der Qualität des Outputs des LLM.

#### Qualität des LLM

Um die Verlässlichkeit des LLM zu prüfen, haben wir uns als Stichprobe 100 klassifizierte Gerichte angeschaut und manuell geprüft. Dabei kamen wir auf eine Trefferquote von >85% (zuverlässigkeit_llm_sample_test.xlsx)

### Task 3: Exporatory Analysis

Für die Darstellung haben wir uns hauptsächlich auf Ernährungsformen, Hauptproteinquellen und deren Beliebtheit konzentriert. Ein besonderer Fokus lag dabei auf den Hülsenfrüchten. Gerichte, bei denen nur eine Lebensmittelklasse ohne nennenswerten Proteingehalt (Gemüse, Kartoffeln oder Nudeln) angeboten wurden, haben wir bei der Analyse ausgeschlossen.
