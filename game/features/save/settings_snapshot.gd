class_name SettingsSnapshot
extends RefCounted
## Kalıcı oyuncu ayarları — yalnızca veri (ADR-0007 "Settings persistence"; C-65).
## Kampanyadan ayrı belge (`settings` yuvası), kendi şema sürümüyle.


var color_blind_mode: bool = false
var reduce_motion: bool = false
var show_region_names: bool = true
var fullscreen: bool = false
## Dil kodu (ör. "tr"); [constant SettingsSerializer.SUPPORTED_LOCALES] içinden.
var locale: String = "en"
## Bus sesleri, doğrusal 0–1 (ayarlar ekranı kaydırıcılarıyla aynı ölçek).
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
## Görülen öğretici ipuçları ([TutorialProgress]); yeni oyuncuda boş.
var seen_hints: Array[StringName] = []
