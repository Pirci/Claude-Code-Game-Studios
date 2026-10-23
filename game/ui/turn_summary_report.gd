class_name TurnSummaryReport
extends ReportModal
## Gece özeti (ux/battle-report.md §4.3, ADR-0011 `show_turn`): oyuncuya yapılan düşman saldırıları
## (olay sırasıyla, en çok [constant MAX_ATTACKS]) → Erlik yayılımı → Erlik'in Gölgesi uyarısı.
## Pasif görünüm: gösterilecek bir şey yoksa [method has_events] false döner ve çağıran modalı açmaz.
## Düşmanın nötr/kendi bölgesine hamlesi özette yer almaz (K8); gelir ve takviye de (Q6).


## Q7: en çok 3 saldırı bloğu garanti (Perde 1'de `enemy_actions_per_turn` = 1).
const MAX_ATTACKS: int = 3
const ALERT_ICON: Texture2D = preload("res://assets/art/ui/theme/icon_alert.png")
## Bloklar arası ek boşluk (VBox ayrımı 4'ün üstüne) — saldırı / yayılım ayrı okunsun.
const BLOCK_GAP: int = 4

var _event_count: int = 0


## [param region_names] bölge kimliği → `name_key`; [param shadow_warning] tur sonunda
## `erlik_power == eşik − 1` (yalnız yayılım olan gecede gösterilir).
func _init(
	outcomes: Array[MoveOutcome],
	spread: ErlikSpreadController.SpreadDecision,
	region_names: Dictionary,
	shadow_warning: bool,
	guard_s: float = 0.0,
) -> void:
	super(guard_s)
	name = "TurnSummaryReport"
	_add_heading(tr("TURN_SUMMARY_HEADING"))
	var attacks: Array[MoveOutcome] = attacks_on_player(outcomes)
	for i: int in mini(attacks.size(), MAX_ATTACKS):
		_add_attack(i, attacks[i], region_names.get(attacks[i].to_id, &"") as StringName)
	var spread_shown: bool = spread != null and spread.is_spread_turn and spread.target_id != &""
	if spread_shown:
		var key: String = "TURN_SUMMARY_SPREAD" if spread.level_before == 0 else "TURN_SUMMARY_DEEPENED"
		var place: String = tr(String(region_names.get(spread.target_id, spread.target_id) as StringName))
		_add_gap()
		_add_verse(tr(key) % place, "Spread")
		_event_count += 1
	if spread_shown and shadow_warning:
		_add_shadow_warning()


## Gösterilecek olay var mı (saldırı ya da yayılım) — yoksa modal açılmaz (Q5).
func has_events() -> bool:
	return _event_count > 0


## Özete giren düşman hamleleri: hedefin önceki sahibi oyuncu ve savaş çözülmüş (G2).
static func attacks_on_player(outcomes: Array[MoveOutcome]) -> Array[MoveOutcome]:
	var attacks: Array[MoveOutcome] = []
	for outcome: MoveOutcome in outcomes:
		if outcome.mover == RegionData.Owner.ENEMY and outcome.branch == MoveOutcome.Branch.COMBAT \
				and outcome.target_owner_before == RegionData.Owner.PLAYER and outcome.combat != null:
			attacks.append(outcome)
	return attacks


## Saldırı bloğu: dize (BOTH_FELL → LOST_DEFENSE → HELD), bölge adı, sayılar. Oyuncu savunandır.
func _add_attack(index: int, outcome: MoveOutcome, region_key: StringName) -> void:
	var prefix: String = "Attack%d" % index
	_add_gap()
	var combat: CombatResolver.CombatResult = outcome.combat
	var both_fell: bool = combat.attacker_remaining == 0 and combat.defender_remaining == 0
	var key: String = "BATTLE_BOTH_FELL" if both_fell \
		else "BATTLE_LOST_DEFENSE" if combat.attacker_won else "BATTLE_HELD_DEFENSE"
	_add_verse(tr(key), prefix + "Verse")
	_add_region_name(region_key, prefix + "Region")
	# İki sayı tek satırda, ayrı Label'lar (BiDi: tek Label'da karıştırılmaz — §7); 3 blok + yayılım +
	# uyarı ≈ 281 px yüksekliğe sığsın diye (Q7).
	var row: HBoxContainer = HBoxContainer.new()
	row.name = prefix + "Numbers"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 12)
	row.add_child(_number_label(prefix + "OurFallen", "REPORT_OUR_FALLEN", combat.defender_losses, -1))
	if both_fell or not combat.attacker_won:
		row.add_child(_number_label(prefix + "TheirFallen", "REPORT_THEIR_FALLEN", combat.attacker_losses))
	else:
		row.add_child(_number_label(prefix + "TheirStanding", "REPORT_THEIR_STANDING", combat.attacker_remaining))
	_vbox.add_child(row)
	_event_count += 1


## İlk bloktan önce boşluk yok (başlık zaten ayırır).
func _add_gap() -> void:
	if _event_count == 0:
		return
	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0, BLOCK_GAP)
	_vbox.add_child(gap)


## Blok C: 7×7 kırmızı `!` ikonu + metin (renk tek başına anlam taşımaz).
func _add_shadow_warning() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "ShadowWarning"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 4)
	var icon: TextureRect = TextureRect.new()
	icon.texture = ALERT_ICON
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(icon)
	var label: Label = Label.new()
	label.name = "Text"
	label.text = tr("ERLIK_SHADOW_WARNING")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(LINE_WIDTH - 11, 0)
	label.add_theme_color_override(&"font_color", ValueFeedback.COLOR_LOSS)
	row.add_child(label)
	_vbox.add_child(row)
