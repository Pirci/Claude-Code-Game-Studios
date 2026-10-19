class_name TutorialRules
extends RefCounted
## Prolog öğretici ipuçlarının saf kuralları (design/ux/prolog-tutorial.md): hangi durumda
## hangi ipucu. Görülmüşlük [TutorialProgress]'te, gösterim GameContext'te — burada durum yok.


const HINT_RECRUIT: StringName = &"recruit"
const HINT_SEND_ARMY: StringName = &"send_army"
const HINT_NEUTRAL: StringName = &"neutral"
const HINT_CORRUPTED: StringName = &"corrupted"
const HINT_SPREAD: StringName = &"spread"
const HINT_SPIRIT: StringName = &"spirit"

## Tanımlı tüm ipuçları (kayıttaki bilinmeyen kimlikler atılır).
const ALL: Array[StringName] = [
	HINT_RECRUIT, HINT_SEND_ARMY, HINT_NEUTRAL, HINT_CORRUPTED, HINT_SPREAD, HINT_SPIRIT,
]


## İpucu metninin çeviri anahtarı: `HINT_<ID>`.
static func text_key(hint_id: StringName) -> String:
	return "HINT_%s" % String(hint_id).to_upper()


## 1. turun başında altın en az bir birliğe yetiyorsa "önce üret" (C-49 notu).
static func hint_at_turn_start(turn: int, gold: int, recruit_cost: int) -> StringName:
	return HINT_RECRUIT if turn == 1 and gold >= recruit_cost else &""


## Bölge seçilince: bozuk → arındırma, nötr → fetih, ordulu oyuncu bölgesi → Ordu Gönder.
static func hint_for_selection(region: RegionData) -> StringName:
	if region == null:
		return &""
	if region.corruption_level >= 1:
		return HINT_CORRUPTED
	if region.owner == RegionData.Owner.NEUTRAL:
		return HINT_NEUTRAL
	if region.owner == RegionData.Owner.PLAYER and region.army_count > 1:
		return HINT_SEND_ARMY
	return &""
