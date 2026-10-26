extends GdUnitTestSuite
## Anlatı sesi denetimleri (C-76; narrative-voice.md §6–§7): AC-V1 "kuru hesap yok" yasak sözcükleri,
## `DEFEAT_REASON_ERLIK` sahneden bağımsız (Prolog bozkırı ve Perde 1 doğu ormanı için de doğru).


const CSV_PATH: String = "res://assets/locale/translations.csv"
## AC-V1 kapsamı: rapor ve ritüel anahtarları.
const VOICE_PREFIXES: Array[String] = ["BATTLE_", "REPORT_", "PURIFY_", "TURN_SUMMARY_"]
const VOICE_PATTERNS: Array[String] = ["^CHAPTER_\\d+_HUNT_", "^CHAPTER_\\d+_SLAIN_"]
const FORBIDDEN: Dictionary = {
	"en": ["Attacker", "Defender", "Losses", "Remaining", "Casualties", "Units"],
	"tr": ["Saldıran", "Savunan", "Kayıp", "Kayıplar", "Birlik"],
}
## Sahneye bağlı yer sözcükleri: Erlik yenilgisi her sahnede okunabilmeli (Q11, seviye §13 #5).
const SCENE_BOUND_WORDS: Dictionary = {
	"en": ["homeland", "steppe", "forest"],
	"tr": ["ata yurdu", "bozkır", "orman"],
}

## Ad sözlüğü (narrative-voice §6.7): Cürcet'in ÇJK karşılıkları.
const JURCHEN_NAMES: Dictionary = {"zh": "女真", "ja": "女真", "ko": "여진"}


## Anahtar → { dil → metin } (CSV içerik verisi).
func _rows() -> Dictionary:
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	var header: PackedStringArray = file.get_csv_line()
	var rows: Dictionary = {}
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < header.size() or row[0].is_empty():
			continue
		var texts: Dictionary = {}
		for i: int in range(1, header.size()):
			texts[header[i]] = row[i]
		rows[row[0]] = texts
	return rows


func _in_scope(key: String) -> bool:
	for prefix: String in VOICE_PREFIXES:
		if key.begins_with(prefix):
			return true
	for pattern: String in VOICE_PATTERNS:
		var regex: RegEx = RegEx.create_from_string(pattern)
		if regex.search(key) != null:
			return true
	return false


func _has_word(text: String, word: String) -> bool:
	var regex: RegEx = RegEx.create_from_string("(?i)(?<![\\p{L}])" + word + "(?![\\p{L}])")
	return regex.search(text) != null


func test_narrative_voice_reports_avoid_dry_ledger_words() -> void:
	var rows: Dictionary = _rows()
	var checked: int = 0
	var problems: Array[String] = []
	for key: String in rows:
		if not _in_scope(key):
			continue
		checked += 1
		for locale: String in FORBIDDEN:
			for word: String in FORBIDDEN[locale]:
				if _has_word(rows[key][locale] as String, word):
					problems.append("%s/%s: %s" % [key, locale, word])
	assert_int(checked).is_greater(30)
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()


func test_narrative_voice_detects_forbidden_word_as_whole_word_only() -> void:
	assert_bool(_has_word("Losses: 3", "Losses")).is_true()
	assert_bool(_has_word("Kayıplar: 3", "Kayıp")).is_false()  # bütün sözcük
	assert_bool(_has_word("Birlikte döndük", "Birlik")).is_false()


func test_defeat_reason_erlik_is_scene_independent_in_every_locale() -> void:
	var texts: Dictionary = _rows()["DEFEAT_REASON_ERLIK"]
	assert_int(texts.size()).is_equal(11)
	for locale: String in texts:
		assert_str(texts[locale] as String).override_failure_message("boş: %s" % locale).is_not_empty()
	for locale: String in SCENE_BOUND_WORDS:
		for word: String in SCENE_BOUND_WORDS[locale]:
			assert_bool(_has_word(texts[locale] as String, word)).override_failure_message(
				"%s: %s" % [locale, word]).is_false()


# Ad sözlüğü (narrative-voice §6.7, C-91): "Cürcet" yalnız Türkçede; tr metni Cürcet diyorsa zh/ja 女真, ko 여진.
func test_narrative_voice_jurchen_glossary() -> void:
	var rows: Dictionary = _rows()
	var problems: Array[String] = []
	var checked: int = 0
	for key: String in rows:
		var texts: Dictionary = rows[key]
		if not (texts["tr"] as String).contains("Cürcet"):
			continue
		checked += 1
		for locale: String in texts:
			if locale != "tr" and (texts[locale] as String).contains("Cürcet"):
				problems.append("%s/%s: Cürcet" % [key, locale])
		for locale: String in JURCHEN_NAMES:
			if not (texts[locale] as String).contains(JURCHEN_NAMES[locale]):
				problems.append("%s/%s: %s yok" % [key, locale, JURCHEN_NAMES[locale]])
		if not (texts["en"] as String).contains("Jurchen"):
			problems.append("%s/en: Jurchen yok" % key)
	assert_int(checked).is_greater_equal(8)
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()
