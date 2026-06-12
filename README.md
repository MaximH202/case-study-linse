![Poster]("C:\Users\Maxim\Desktop\Linse Poster.png")
## Solution Documentation

### Task 1: Datenaufbereitung

#### Gefilterte Daten

Wir haben uns dazu entschieden, uns hauptsächlich auf Hauptgerichte zu konzentrieren. Daher haben wir in verschiedenen classify-Schritten versucht, Beilagen und Einträge, bei denen es sich nicht um Speisen handelte, herauszufiltern. Konkret wird dabei zweistufig vorgegangen:

1. **Regelbasierter Vorfilter (classify_step_1):** Über Keyword-Listen auf `prod_type` und `product_name` werden typische Desserts, Beilagen und Nicht-Speise-Einträge (z.B. „Buffet", „Personal", „Kita", „Pastabar") ausgeschlossen.
2. **LLM-basierter Nachfilter (classify_step_3 & classify_step_4):** Das LLM bewertet jeden Eintrag zusätzlich mit einem `ist_speise`-Flag. Gerichte, die das LLM als Nicht-Hauptspeise einstuft, werden ebenfalls entfernt. Außerdem werden Gerichte aussortiert, bei denen ausschließlich eine einzelne reine Sättigungsbeilage (Getreide, Knollen, Gemüse, Nüsse oder Samen) erkannt wurde und somit kein vollwertiges Hauptgericht vorliegt.

#### Textnormalisierung

Bevor Gerichte ans LLM oder die Keyword-Suche übergeben werden, normalisiert `clean_text` alle Texte: Umlaute werden in Ersatzschreibweisen umgewandelt (z.B. „ä" → „ae"), alles wird kleingeschrieben und überflüssige Leerzeichen entfernt. Zusätzlich werden Klammern mit Inhalten (typischerweise Zusatzstoffnummern wie „(1, 2, A)") aus dem `menu_text` entfernt — außer wenn darin explizit „vegan" oder „vegetarisch" steht, da diese Hinweise für die spätere Klassifikation relevant sind.

#### Deduplizierung

Um Kosten und Laufzeit beim LLM-Aufruf zu minimieren, wird jedes einzigartige Gericht nur einmal klassifiziert. Als Eindeutigkeitsmerkmal wird dabei der vollständige `menu_text` (nach Normalisierung) genutzt, nicht allein der `product_name`. Das ist entscheidend, da viele generische Namen (z.B. „Pizza", „Tagesteller") für inhaltlich völlig unterschiedliche Gerichte stehen können. Nur über den konkreten Beschreibungstext lässt sich das jeweilige Gericht eindeutig identifizieren.

---

### Task 2: Classification of Menu Items

Wir haben die Klassifizierung der Daten in zwei Schritten durchgeführt. Zunächst haben wir eine Keyword-Suche über die `product_name`- und `menu_text`-Spalten laufen lassen und die Ergebnisse zusammengeführt (siehe classify_step_2). Danach haben wir diese vorläufigen Klassen dem LLM übergeben und ihm dabei zwei Aufgaben erteilt:

1. Das Ergänzen von fehlenden oder impliziten Klassen (z.B. „getreide" bei panierten Gerichten oder Pasta-Beilagen)
2. Das Abschätzen der Anteile der einzelnen Klassen am gesamten Gericht (gering, mittel, dominant). Dabei lag der Fokus auf den Hauptkomponenten eines Gerichts.

Diese Ergebnisse haben wir dann genutzt, um zwei Tabellen zu bauen:

1. *menu_components* (Long-Format) listet alle Gerichte mit ihren einzelnen Komponenten und deren Anteil auf. Jede Komponente hat eine eigene Zeile.
2. *menus_classified* (Short-Format) listet alle Gerichte mit ihrer Ernährungsform (`group_level_1`) und dem Hauptprotein (`code_main_protein`) auf — eine Zeile pro Gericht.

Ernährungsform und Hauptprotein wurden nicht durch das LLM, sondern durch feste Regeln bestimmt.

#### Ernährungsform (group_level_1)

Die Ernährungsform wird durch ein hierarchisches System bestimmt (classify_step_5). Ganz oben steht die direkte Wortsuche nach den Tags „vegan" oder „vegetarisch" im `menu_text` — dieser expliziten Kennzeichnung der Mensen vertrauen wir am meisten. Dies kann jedoch im Wiederspruch mit den vom LLM erkannten Klassen stehen, wenn dieses die Tags bei der Klassifizierung nicht berücksichtigt hat.
Danach wird stufenweise anhand der vom LLM erkannten Lebensmittelklassen entschieden: Fleisch → omnivor, Fisch (ohne Fleisch) → pescetarisch, Milch/Ei (ohne Fleisch/Fisch) → vegetarisch, alles andere → vegan. Diese regelbasierte Ermittlung beugt Halluzinationen vor, ist aber eng an die Qualität des LLM-Outputs gebunden.

#### Hauptprotein (code_main_protein)

Das Hauptprotein wird durch eine gewichtete Punktformel bestimmt (classify_step_6). Jeder Lebensmittelklasse wird ein Basiswert zugeordnet (Fleisch/Fisch = 100, Hülsenfrüchte = 90, Milch/Ei = 80 usw.), der dann mit dem vom LLM geschätzten Anteil multipliziert wird (dominant × 3, mittel × 2, gering × 1). Die Klasse mit dem höchsten Gesamtscore gilt als Hauptprotein. Ist der maximale Score sehr gering (≤ 20), wird „keine_eindeutige_proteinquelle" vergeben.

#### Proteincode (proteincode)

Jede Komponente in der Long-Tabelle erhält zusätzlich einen `proteincode`, der den ungefähren Proteingehalt der Lebensmittelklasse widerspiegelt:

| Lebensmittelklasse | Proteincode |
|---|---|
| milchprodukte, ei | very_high |
| rotes_fleisch, gefluegel, fisch | high |
| huelsenfruechte | medium |
| getreide, samen, nuesse | low |
| gemuese | very_low |

#### Rückführung auf den Gesamtdatensatz (classify_step_7)

Die klassifizierten Ergebnisse liegen zunächst nur für die eindeutigen Gerichte vor. In Schritt 7 werden sie über einen `inner_join` auf `menu_text` wieder an den vollständigen Originaldatensatz zurückgespielt. So erhält jede einzelne Ausgabe einer Mensa, auch Duplikate über verschiedene Standorte und Tage hinweg, ihre Klassifikation. Der `inner_join` stellt dabei sicher, dass nur Gerichte im finalen Datensatz verbleiben, die erfolgreich klassifiziert wurden.

#### Qualität des LLM

Um die Verlässlichkeit des LLM zu prüfen, haben wir uns als Stichprobe 100 klassifizierte Gerichte angeschaut und manuell geprüft. Dabei kamen wir auf eine Trefferquote von >85% (`zuverlässigkeit_llm_sample_test.xlsx`).

#### Annahmen und Einschränkungen

- `menu_text` wird als primäres Eindeutigkeitsmerkmal für die Deduplizierung und den abschließenden Join genutzt, da generische `product_name`-Einträge häufig für mehrere inhaltlich verschiedene Gerichte stehen
- Das LLM bestimmt nur grob die Lebensmittelklassen
- Kleinere Komponenten (z.B. eine Ei-Panade) werden oft nicht erkannt, was besonders die Differenzierung zwischen vegan und vegetarisch ungenau macht
- Gerichte, die explizit als „oder"-Auswahl angegeben sind (z.B. „Pizza oder Pasta"), werden vollständig ausgeschlossen, da sie nicht eindeutig klassifizierbar sind
---

### Task 3: Exploratory Analysis

Für die Darstellung haben wir uns hauptsächlich auf Ernährungsformen, Hauptproteinquellen und deren Beliebtheit konzentriert. Ein besonderer Fokus lag dabei auf den Hülsenfrüchten als pflanzliche Proteinquelle. Gerichte, bei denen ausschließlich eine Lebensmittelklasse ohne nennenswerten Proteingehalt erkannt wurde (Gemüse, Kartoffeln oder Nudeln ohne Beilage), wurden bei der Analyse ausgeschlossen. Alle Anteile werden jahresweise normalisiert, damit Zeiträume mit unterschiedlicher Datendichte trotzdem fair verglichen werden können.

Die neun Analyse-Skripte sind thematisch aufgebaut und bauen auf den zwei klassifizierten Ausgabetabellen (`menus_classified` und `menu_components`) auf:

#### 01 – Entwicklung der Ernährungsformen (diet_yearly)
100%-gestapeltes Balkendiagramm, das zeigt, wie sich der Anteil von veganen, vegetarischen, pescetarischen und omnivoren Gerichten am Gesamtangebot Jahr für Jahr verändert hat. Zusätzlich werden die `actual_output`-Mengen vorbereitet, um auch die Nachfrageseite analysieren zu können.

#### 02 – Ernährungsformen nach Studierendenwerk (diet_by_student_service)
Horizontales 100%-gestapeltes Balkendiagramm, das die Studierendenwerke nach ihrem kombinierten Vegan-/Vegetarisch-Anteil sortiert auflistet. So werden regionale Unterschiede im Angebot auf einen Blick sichtbar.

#### 03 – Hülsenfrüchte-Anteil im Zeitverlauf (legumes_share_over_time)
Liniendiagramm mit linearen Trendgeraden, das drei Rollen von Hülsenfrüchten unterscheidet: als dominante Hauptzutat, als Nebenkomponente (mittel/gering) und als das klassifizierte Hauptprotein eines Gerichts. So lässt sich beurteilen, ob Hülsenfrüchte zunehmend als vollwertiger Fleischersatz eingesetzt werden oder weiterhin eine Nebenrolle spielen.

#### 04 – Hülsenfrüchte-Anteil nach Mensa (legumes_share_by_cafeteria)
Boxplot, bei dem jeder Punkt eine einzelne Mensa repräsentiert, gruppiert in Vierjahreszeiträume. Der Plot zeigt, ob der Anstieg des Hülsenfrüchte-Anteils ein breites Phänomen ist, das über alle Standorte hinweg passiert, oder ob er von einzelnen Vorreitern getrieben wird.

#### 05 – Beliebtheit der Top-6-Proteinquellen im Zeitverlauf (beliebtheit)
Heatmap auf Basis der tatsächlichen Ausgabemengen (`actual_output`) über alle Jahre. Dadurch wird sichtbar, welche Proteinquellen von den Studierenden tatsächlich nachgefragt werden, unabhängig davon, wie häufig sie auf der Karte stehen.

#### 06 – Hauptproteinquellen im Zeitverlauf (protein_trend)
Heatmap der sechs wichtigsten Proteinquellen (Rotes Fleisch, Geflügel, Fisch, Milchprodukte, Hülsenfrüchte, Getreide) über alle Jahre. Seltene Kategorien wie `ei`, `samen` und `keine_eindeutige_proteinquelle` werden ausgeschlossen, um den Fokus auf die relevanten Verschiebungen zu halten.


#### 07 – Wochentags-Analyse: Veggie-Tag-Effekt? (weekday_analysis)
Gruppiertes Balkendiagramm, das die durchschnittlich verkauften Portionen pro angebotenem Gericht nach Wochentag und Kategorie (pflanzlich vs. fleischhaltig) zeigt. Durch die Normalisierung auf "pro angebotenem Gericht" werden Tage mit mehr oder weniger Auswahl fair verglichen. Die Analyse ist auf Montag bis Freitag beschränkt.