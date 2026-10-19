class_name CampaignDefinition
extends Resource
## Kampanya içeriği (scene-flow.md §3.1, §3.10): sahneler `chapter_id` 1…K sırasıyla ve
## kampanya sonu sayfaları. RootContext açılışta bir kez `load()` eder (küçük kaynak).


@export var scenes: Array[SceneDefinition] = []
## `CAMPAIGN_END` sayfaları (M1: demo sonu).
@export var end_pages: Array[NarrativePage] = []


## `chapter_id` ile sahne; 1…K dışında null.
func scene(chapter_id: int) -> SceneDefinition:
	for definition: SceneDefinition in scenes:
		if definition.chapter_id == chapter_id:
			return definition
	return null


## Kampanya uzunluğu `K`.
func scene_count() -> int:
	return scenes.size()
