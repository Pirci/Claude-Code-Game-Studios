class_name NarrativePage
extends Resource
## Tam ekran anlatı sayfası (scene-flow.md §3.8, §3.10). İçerik — asla kaydedilmez.


## İllüstrasyon yolu; boş = önceki sayfanınki korunur (ilk sayfada boş olamaz — L4).
@export var illustration_path: String = ""
@export var text_key: StringName = &""
## İsteğe bağlı 24px başlık kartı (sahne adı, Kağan ilanı).
@export var title_key: StringName = &""
@export var sfx_id: StringName = &""
