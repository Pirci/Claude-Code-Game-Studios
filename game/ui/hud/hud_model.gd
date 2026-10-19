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
