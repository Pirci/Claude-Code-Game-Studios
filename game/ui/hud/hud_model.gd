class_name HudModel
extends RefCounted
## HUD görünüm modeli — yalnızca veri (ADR-0011 karar 3). [HudPresenter] oyunun saf
## kurallarından kurar; HUD yalnızca gösterir.


var gold: int = 0
## Bu turun gelir tahmini (F2) — ekonomi adımıyla aynı hesap (TR-resource-006).
var income_forecast: int = 0
var turn: int = 1
var ruh: int = 0
var game_result: MapState.GameResult = MapState.GameResult.ONGOING
## Kök Böri düğmesi: sunum bekliyor ve oyun sürüyor (spirit §3.4).
var boon_offer_available: bool = false
## Kalıcı "Hedef" satırı (scene-flow §10): kazanma koşulunun metni ve ilerlemesi.
var objective_key: StringName = &""
var neutral_conquered: int = 0
var neutral_required: int = 0
var foci_cleansed: int = 0
var foci_total: int = 0
## Erlik'in Gölgesi (spirit §4.7): `erlik_power / eşik`; eşik 0 = kapalı.
var erlik_power: int = 0
var erlik_threshold: int = 0
## `erlik_power = eşik − 1`: bir sonraki yayılımda kayıp (spirit AC24).
var erlik_warning: bool = false

## Kalıcı HUD'da aynı anda en çok bir kırmızı uyarı (hud H8): öncelik Erlik kaybı > Odak tehlikede > Yayılım N = 0.
enum Warning { NONE, ERLIK_LOSS, FOCUS_AT_RISK, SPREAD_NOW }

## "Yayılım: N tur" (hud §5.1, H1): yalnız Gölge görünürken (`erlik_threshold > 0`, H2).
var spread_visible: bool = false
var spread_turns_left: int = 0
## "Şu an olsa" yayılım hedefi (boş = yayılacak yer yok).
var spread_target_id: StringName = &""
## `N = 0` ve hedef bir Erlik odağı (hud §5.2, H3); Yayılım segmentinin yerini alır (H10).
var focus_at_risk: bool = false
## Düşman bölgesi sayacı (hud §5.5, H9): yalnız `must_defeat_all_enemies` ve sahne başında düşman varken.
var enemy_counter_visible: bool = false
var enemy_regions_taken: int = 0
var enemy_regions_initial: int = 0
## Gösterilecek tek kırmızı uyarı (oyun bitince NONE).
var red_warning: Warning = Warning.NONE
