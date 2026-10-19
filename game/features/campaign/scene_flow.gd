class_name SceneFlow
extends RefCounted
## Kampanya akış durum makinesi (scene-flow.md §3.3, ADR-0012 karar 1) — saf: durum + olay +
## olgular → [FlowStep] (sonraki durum + sıralı eylem kimlikleri). Tüm koşullar burada;
## RootContext yalnızca eylemleri uygular ve bağlam değiştirir. Tabloda olmayan (durum, olay)
## çifti durumu değiştirmez ve günlüğe yazılır.


enum State {
	MAIN_MENU, CHAPTER_SELECT, INTRO_NARRATIVE, KOK_BORI_MARK_PAGES, KOK_BORI_MARK_PANEL,
	PLAYING, VICTORY_BEAT, BOON_PICKS, OUTRO_NARRATIVE, DEFEAT, CAMPAIGN_END, STORY_REPLAY,
}

# --- Olaylar ---
const EVENT_NEW_CAMPAIGN: StringName = &"new_campaign_requested"
const EVENT_NEW_CAMPAIGN_CONFIRMED: StringName = &"new_campaign_confirmed"
const EVENT_CONTINUE: StringName = &"continue_requested"
const EVENT_START: StringName = &"start_requested"
const EVENT_READ: StringName = &"read_requested"
const EVENT_MENU: StringName = &"menu_requested"
## Anlatı ekranı: son sayfa geçildi, [Atla] ya da Esc (bulunulan durumun kalanı atlanır).
const EVENT_PAGES_FINISHED: StringName = &"pages_finished"
const EVENT_OBJECTIVE_DISMISSED: StringName = &"objective_dismissed"
const EVENT_GAME_WON: StringName = &"game_won"
const EVENT_GAME_LOST: StringName = &"game_lost"
const EVENT_LEAVE_CONFIRMED: StringName = &"leave_confirmed"
const EVENT_VICTORY_ACKNOWLEDGED: StringName = &"victory_acknowledged"
const EVENT_BOON_PICKS_FINISHED: StringName = &"boon_picks_finished"
const EVENT_RETRY: StringName = &"retry_requested"

# --- Eylemler (RootContext sırayla uygular) ---
const ACTION_CONFIRM_NEW_CAMPAIGN: StringName = &"confirm_new_campaign"
const ACTION_NEW_STATE: StringName = &"new_state"
const ACTION_ADOPT_STATE: StringName = &"adopt_state"
const ACTION_SHOW_LOAD_ERROR: StringName = &"show_load_error"
const ACTION_BUILD_MAP: StringName = &"build_map"
const ACTION_REBUILD_MODIFIERS: StringName = &"rebuild_modifiers"
const ACTION_CAPTURE_ENTRY: StringName = &"capture_entry"
const ACTION_SAVE_ENTRY: StringName = &"save_entry"
const ACTION_CONFIRM_LEAVE: StringName = &"confirm_leave"
const ACTION_START_BOON_PICKS: StringName = &"start_boon_picks"
const ACTION_COMMIT_SCENE: StringName = &"commit_scene"
const ACTION_SAVE_COMPLETED: StringName = &"save_completed"
const ACTION_RESTORE_ENTRY: StringName = &"restore_entry"

# --- Olgular (facts) anahtarları ---
const FACT_HAS_SAVE: StringName = &"has_save"
const FACT_LOAD_OK: StringName = &"load_ok"
const FACT_MAP_PRESENT: StringName = &"map_present"
const FACT_CHAPTER_ID: StringName = &"chapter_id"
const FACT_CHAPTER_STATE: StringName = &"chapter_state"
const FACT_HAS_KOK_BORI_PAGES: StringName = &"has_kok_bori_pages"
const FACT_CONFIRM_LEAVE: StringName = &"confirm_leave"
const FACT_PICKS_PENDING: StringName = &"picks_pending"
const FACT_IS_LAST_SCENE: StringName = &"is_last_scene"


## Geçiş sonucu: sonraki durum, sahne kimliği ve sıralı eylemler.
class FlowStep:
	extends RefCounted
	var next_state: State
	var chapter_id: int
	var actions: Array[StringName] = []
	## Tabloda karşılığı olmayan çift (durum değişmez).
	var ignored: bool = false


func transition(state: State, event: StringName, facts: Dictionary = {}) -> FlowStep:
	var chapter_id: int = int(facts.get(FACT_CHAPTER_ID, 1))
	match state:
		State.MAIN_MENU:
			match event:
				EVENT_NEW_CAMPAIGN:
					if facts.get(FACT_HAS_SAVE, false):
						return _step(State.MAIN_MENU, chapter_id, [ACTION_CONFIRM_NEW_CAMPAIGN])  # T2
					return _step(State.INTRO_NARRATIVE, 1, [ACTION_NEW_STATE])  # T1
				EVENT_NEW_CAMPAIGN_CONFIRMED:
					return _step(State.INTRO_NARRATIVE, 1, [ACTION_NEW_STATE])  # T2 → T1
				EVENT_CONTINUE:
					if not facts.get(FACT_LOAD_OK, false):
						return _step(State.MAIN_MENU, chapter_id, [ACTION_SHOW_LOAD_ERROR])  # T5
					if facts.get(FACT_MAP_PRESENT, false):
						return _step(State.PLAYING, chapter_id, [ACTION_ADOPT_STATE, ACTION_REBUILD_MODIFIERS])  # T3
					return _step(State.CHAPTER_SELECT, chapter_id, [ACTION_ADOPT_STATE])  # T4
		State.CHAPTER_SELECT:
			match event:
				EVENT_START:
					if facts.get(FACT_CHAPTER_STATE, -1) == CampaignRules.ChapterState.AVAILABLE:
						return _step(State.INTRO_NARRATIVE, chapter_id, [])  # T6
				EVENT_READ:
					if facts.get(FACT_CHAPTER_STATE, -1) == CampaignRules.ChapterState.COMPLETED:
						return _step(State.STORY_REPLAY, chapter_id, [])  # T7
				EVENT_MENU:
					return _step(State.MAIN_MENU, chapter_id, [])  # T8
		State.STORY_REPLAY:
			if event == EVENT_PAGES_FINISHED:
				return _step(State.CHAPTER_SELECT, chapter_id, [])  # T9
		State.INTRO_NARRATIVE:
			if event == EVENT_PAGES_FINISHED:
				if facts.get(FACT_HAS_KOK_BORI_PAGES, false):
					return _step(State.KOK_BORI_MARK_PAGES, chapter_id, [])  # T10
				return _step(State.KOK_BORI_MARK_PANEL, chapter_id, _enter_scene_actions())  # T10 (A boş) + T11
		State.KOK_BORI_MARK_PAGES:
			if event == EVENT_PAGES_FINISHED:
				return _step(State.KOK_BORI_MARK_PANEL, chapter_id, _enter_scene_actions())  # T11
		State.KOK_BORI_MARK_PANEL:
			if event == EVENT_OBJECTIVE_DISMISSED:
				return _step(State.PLAYING, chapter_id, [ACTION_SAVE_ENTRY])  # T12 (S2)
		State.PLAYING:
			match event:
				EVENT_GAME_WON:
					return _step(State.VICTORY_BEAT, chapter_id, [])  # T13
				EVENT_GAME_LOST:
					return _step(State.DEFEAT, chapter_id, [])  # T14 — kayıt yok
				EVENT_MENU:
					if facts.get(FACT_CONFIRM_LEAVE, true):
						return _step(State.PLAYING, chapter_id, [ACTION_CONFIRM_LEAVE])  # T15 onay
					return _step(State.MAIN_MENU, chapter_id, [])  # T15 (onaysız)
				EVENT_LEAVE_CONFIRMED:
					return _step(State.MAIN_MENU, chapter_id, [])  # T15 Evet — kayıt yok
		State.VICTORY_BEAT:
			if event == EVENT_VICTORY_ACKNOWLEDGED:
				if facts.get(FACT_PICKS_PENDING, false):
					return _step(State.BOON_PICKS, chapter_id, [ACTION_START_BOON_PICKS])  # T16 (k > 0)
				return _commit_step(chapter_id)  # T16 (k = 0) → T18
		State.BOON_PICKS:
			if event == EVENT_BOON_PICKS_FINISHED:
				return _commit_step(chapter_id)  # T17 bitti → T18
		State.OUTRO_NARRATIVE:
			if event == EVENT_PAGES_FINISHED:
				if facts.get(FACT_IS_LAST_SCENE, false):
					return _step(State.CAMPAIGN_END, chapter_id, [])  # T20
				return _step(State.CHAPTER_SELECT, chapter_id, [])  # T19
		State.CAMPAIGN_END:
			if event == EVENT_PAGES_FINISHED:
				return _step(State.MAIN_MENU, chapter_id, [])  # T21
		State.DEFEAT:
			match event:
				EVENT_RETRY:
					return _step(State.KOK_BORI_MARK_PANEL, chapter_id,
						[ACTION_RESTORE_ENTRY, ACTION_BUILD_MAP, ACTION_REBUILD_MODIFIERS])  # T22
				EVENT_MENU:
					return _step(State.MAIN_MENU, chapter_id, [])  # T23 — kayıt yok
	print("scene_flow: ignored %s in %s" % [event, State.keys()[state]])
	var ignored: FlowStep = _step(state, chapter_id, [])
	ignored.ignored = true
	return ignored


## T11: haritayı kur, değiştiricileri yeniden kur, sahne girişi anlık görüntüsünü yakala.
func _enter_scene_actions() -> Array[StringName]:
	return [ACTION_BUILD_MAP, ACTION_REBUILD_MODIFIERS, ACTION_CAPTURE_ENTRY]


## T18 COMMIT (F7) + S3, ardından çıkış anlatısı.
func _commit_step(chapter_id: int) -> FlowStep:
	return _step(State.OUTRO_NARRATIVE, chapter_id, [ACTION_COMMIT_SCENE, ACTION_SAVE_COMPLETED])


func _step(next_state: State, chapter_id: int, actions: Array[StringName]) -> FlowStep:
	var step: FlowStep = FlowStep.new()
	step.next_state = next_state
	step.chapter_id = chapter_id
	step.actions = actions
	return step
