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
