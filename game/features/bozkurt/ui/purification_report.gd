class_name PurificationReport
extends ReportModal
## Oyuncu arındırma raporu (ux/battle-report.md §4.2): başarıda kazanılan Ruh, düşen ve yerleşen;
## başarısızlıkta karanlığa giden kuvvet ve öğrenme satırı (direnç S). Hedef sahnenin Erlik odağıysa
## dize (başarıda başlık da) sahnenin ritüel anahtarlarından gelir ([SceneDefinition], boşsa `PURIFY_*`).


## [param ritual] sahnenin odak anahtarları — boş anahtar düz `PURIFY_*` metnine düşer.
func _init(outcome: MoveOutcome, region_name_key: StringName, ritual: SceneDefinition = null, guard_s: float = 0.0) -> void:
	super(guard_s)
	name = "PurificationReport"
	# Ritüel başlığı zafer ilanıdır — başarısız avda düz başlık kalır.
	var heading_key: StringName = ritual.focus_heading_key if ritual and outcome.purified else &""
	_add_heading(tr(_key(heading_key, &"PURIFY_REPORT_HEADING")))
	_add_region_name(region_name_key)
	if outcome.purified:
		_add_verse(tr(_key(ritual.focus_success_key if ritual else &"", &"PURIFY_SUCCESS")))
		_add_number("SpiritGained", "PURIFY_SPIRIT_GAINED", outcome.ruh_gain, 1)
		_add_number("OurFallen", "REPORT_OUR_FALLEN", outcome.combat.attacker_losses, -1)
		_add_number("Settled", "PURIFY_SETTLED", outcome.combat.attacker_remaining)
	else:
		_add_verse(tr(_key(ritual.focus_failed_key if ritual else &"", &"PURIFY_FAILED")))
		_add_number("Lost", "PURIFY_LOST", outcome.moving, -1)
		var hint: Label = Label.new()
		hint.name = "FailedHint"
		hint.text = tr("PURIFY_FAILED_HINT") % NumberFormatter.ltr(NumberFormatter.format_int(outcome.corruption_strength))
		hint.theme_type_variation = &"SecondaryLabel"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(LINE_WIDTH, 0)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_vbox.add_child(hint)


static func _key(preferred: StringName, fallback: StringName) -> String:
	return String(preferred if preferred != &"" else fallback)
