class_name SceneDefinition
extends Resource
## Bir sahnenin sunum verisi (scene-flow.md §3.10). Mekanik veri [ChapterMapDefinition]'da;
## harita yalnızca sahne kurulurken [member map_path]'ten `load()` edilir (ADR-0012 karar 4).


## Kök Böri pozları (art bible §5): profil varsayılan, Prolog iniş, Final cephe.
enum Pose { PROFILE, DESCENT, FRONT }

@export var chapter_id: int = 1
## Sahne adı; [member ChapterMapDefinition.chapter_name_key] ile aynı olmalı (L2).
@export var title_key: StringName = &""
@export var map_path: String = ""
@export var intro_pages: Array[NarrativePage] = []
@export var kok_bori_pose: Pose = Pose.PROFILE
## Kök Böri anlatı sayfaları (A); boş olabilir. Yeniden Dene'de gösterilmez.
@export var kok_bori_pages: Array[NarrativePage] = []
## Hedef panelindeki (B) 1–2 satırlık Kök Böri sözü.
@export var kok_bori_line_key: StringName = &""
## Kazanma koşulunda geçmeyen ek hedef bölgeler (F7 `M`'ye eklenir).
@export var objective_region_ids: Array[StringName] = []
@export var outro_pages: Array[NarrativePage] = []
## Bu sahne tamamlanınca açılan sahnenin sefer haritasındaki ipucu.
@export var teaser_key: StringName = &""
## İsteğe bağlı sahneye özel yenilgi metni (boş → `DEFEAT_REASON_*`).
@export var defeat_text_key: StringName = &""
## Erlik odağı arındırma raporunun ritüel metinleri (ux/battle-report.md §4.2; boş → `PURIFY_*`):
## başlık, başarı dizesi, başarısızlık dizesi. Prolog `CHAPTER_1_SLAIN_*` / `HUNT_FAILED`.
@export var focus_heading_key: StringName = &""
@export var focus_success_key: StringName = &""
@export var focus_failed_key: StringName = &""


func load_map_definition() -> ChapterMapDefinition:
	if map_path.is_empty() or not ResourceLoader.exists(map_path):
		return null
	return load(map_path) as ChapterMapDefinition
