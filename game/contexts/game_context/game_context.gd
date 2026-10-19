class_name GameContext
extends Control


signal return_to_menu_requested


## Bölüm haritası `chapter_id` ([member GameState.current_chapter]) ile bağlam başlarken
## [code]load()[/code] edilir, preload edilmez (ADR-0001, TR-map-002). Yol kuralı C-62'de
## (Scene flow & chapter loading ADR) kesinleşir.
const CHAPTER_MAP_PATH_FORMAT: String = "res://features/grid/data/chapter_%d_map.tres"
const COMBAT_CONFIG: CombatConfig = preload("res://features/combat/data/combat_config.tres")
const SPIRIT_CONFIG: SpiritConfig = preload("res://features/bozkurt/data/spirit_config.tres")
const ECONOMY_CONFIG: EconomyConfig = preload("res://features/resources/data/economy_config.tres")
## Lütuf kataloğu küçük bir içerik kaynağıdır; bağlamla birlikte ağaçtan çıkar.
const BOON_CATALOG: BoonCatalog = preload("res://features/bozkurt/data/boon_catalog.tres")

@onready var _background: ColorRect = %Background
@onready var _chapter_label: Label = %ChapterLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _turn_label: Label = %TurnLabel
@onready var _spirit_label: Label = %SpiritLabel
@onready var _kok_bori_button: Button = %KokBoriButton
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _menu_button: Button = %MenuButton

var _game_state: GameState
var _accessibility: AccessibilitySettings
var _audio: AudioController = null
var _save: SaveController = null
var _map_def: ChapterMapDefinition
var _map_controller: MapController
var _army_controller: ArmyController
var _resource_controller: ResourceController
var _combat_resolver: CombatResolver
var _spirit_rules: SpiritRules
var _spirit: SpiritController
var _modifiers: ModifierController
var _modal_queue: ModalQueue
## Sahne sonu zorunlu lütuf dizisinde yapılan seçim sayısı (üst sınır `victory_pick_cap`).
var _victory_picks: int = 0
var _campaign_map: CampaignMap
var _info_panel: RegionInfoPanel
var _awaiting_target: bool = false
var _send_from_id: StringName = &""


## [param audio] isteğe bağlıdır (null → sessiz; testler ve sessiz başlatma için).
## [param save] verilirse her tur sonunda kampanya otomatik kaydedilir (ADR-0007).
func bind_services(
	game_state: GameState,
	accessibility: AccessibilitySettings,
	audio: AudioController = null,
	save: SaveController = null,
) -> void:
	_game_state = game_state
	_accessibility = accessibility
	_audio = audio
	_save = save


func _ready() -> void:
	# Area2D bölge tıklamalarının çalışması için 2D fiziksel nesne seçimini aç.
	get_viewport().physics_object_picking = true
	_setup_controllers()
	_setup_map_visuals()
	_connect_signals()
	_refresh_views()
	FocusReveal.focus_quietly(_end_turn_button)


func _setup_controllers() -> void:
	var map_path: String = CHAPTER_MAP_PATH_FORMAT % _game_state.current_chapter
	var map_def: ChapterMapDefinition = load(map_path) as ChapterMapDefinition
	assert(map_def != null, "Bölüm haritası yüklenemedi: %s" % map_path)
	_map_def = map_def
	# Yüklenen kayıt bu bölümün haritasını taşıyorsa onunla devam edilir (ADR-0007);
	# yoksa bölüm içerikten başlar.
	var loaded: MapState = _game_state.map_state
	if loaded == null or loaded.chapter_id != map_def.chapter_id:
		_game_state.map_state = map_def.create_map_state()
		_game_state.gold = map_def.starting_gold

	_spirit_rules = SpiritRules.new()
	_spirit_rules.bind_config(SPIRIT_CONFIG)
	_army_controller = ArmyController.new()
	_resource_controller = ResourceController.new()
	_resource_controller.bind_services(_spirit_rules, ECONOMY_CONFIG)
	_combat_resolver = CombatResolver.new()
	_combat_resolver.bind_config(COMBAT_CONFIG)
	var move_resolver: MoveResolver = MoveResolver.new()
	move_resolver.bind_services(_combat_resolver, _spirit_rules)
	_spirit = SpiritController.new()
	_spirit.bind_services(_game_state, _spirit_rules)
	_modifiers = ModifierController.new()
	_modifiers.bind_services(_game_state)
	# Lütuf kayıtları türetilmiş durumdur: kayıttaki seçimlerden yeniden kurulur (ADR-0006/0007).
	_spirit.bind_boons(BOON_CATALOG, _modifiers)
	_spirit.rebuild_boon_modifiers()
	_map_controller = MapController.new()
	_map_controller.bind_services(
		_game_state.map_state,
		_game_state,
		_army_controller,
		_resource_controller,
		_combat_resolver,
		map_def.win_condition,
		EnemyAIController.new(),
		move_resolver,
	)
	_map_controller.bind_erlik_layer(_spirit, ErlikSpreadController.new(), _modifiers)


func _setup_map_visuals() -> void:
	_background.color = _map_def.ground_color
	_campaign_map = CampaignMap.new()
	_campaign_map.set_line_color(_map_def.adjacency_line_color)
	add_child(_campaign_map)
	move_child(_campaign_map, 1)
	_campaign_map.build_map(_game_state.map_state)
	_campaign_map.apply_accessibility(_accessibility)

	_info_panel = RegionInfoPanel.new()
	_info_panel.layout_mode = 1
	_info_panel.anchors_preset = 3
	_info_panel.anchor_left = 1.0
	_info_panel.anchor_top = 1.0
	_info_panel.anchor_right = 1.0
	_info_panel.anchor_bottom = 1.0
	# Harita x ≤ 491'de biter; panel sağ kenarda, alt barın üstünde yukarı doğru büyür.
	# Alt bar 27px → panel ile arasında sağ kenardaki gibi 4px boşluk.
	_info_panel.offset_left = -140.0
	_info_panel.offset_top = -131.0
	_info_panel.offset_right = -4.0
	_info_panel.offset_bottom = -31.0
	_info_panel.grow_horizontal = 0
	_info_panel.grow_vertical = 0
	add_child(_info_panel)

	# Modallar haritanın ve HUD'un üstündeki katmanda, tek sıra (ADR-0011 karar 5).
	var overlay: CanvasLayer = CanvasLayer.new()
	overlay.name = "ModalLayer"
	overlay.layer = 10
	add_child(overlay)
	_modal_queue = ModalQueue.new()
	_modal_queue.name = "ModalQueue"
	overlay.add_child(_modal_queue)


func _connect_signals() -> void:
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_kok_bori_button.pressed.connect(_on_kok_bori_pressed)
	_campaign_map.region_clicked.connect(_on_region_clicked)
	_info_panel.send_army_pressed.connect(_on_send_army_pressed)
	_info_panel.recruit_pressed.connect(_on_recruit_pressed)
	_map_controller.region_selected.connect(_on_controller_region_selected)
	_map_controller.region_deselected.connect(_on_controller_region_deselected)
	_map_controller.turn_ended.connect(_on_turn_ended)
	_map_controller.income_collected.connect(_on_income_collected)
	_map_controller.combat_occurred.connect(_on_combat_occurred)
	_map_controller.purification_resolved.connect(_on_purification_resolved)
	_map_controller.army_moved.connect(_on_army_moved)
	_map_controller.game_won.connect(_on_game_won)
	_map_controller.game_lost.connect(_on_game_lost)


## HUD [HudModel]'den çizilir (ADR-0011 karar 3): oyun bitince başlık sonucu gösterir ve
## Tur Bitir kapanır (§3.7); altın yanında oyun sürerken bu turun gelir tahmini (+Y, F2 —
## resource §10); Ruh ve sunum bekliyorsa Kök Böri düğmesi (spirit §3.4).
func _render_hud(model: HudModel) -> void:
	var ongoing: bool = model.game_result == MapState.GameResult.ONGOING
	match model.game_result:
		MapState.GameResult.WON:
			_chapter_label.text = tr("VICTORY")
		MapState.GameResult.LOST:
			_chapter_label.text = tr("DEFEAT")
		_:
			_chapter_label.text = tr("CHAPTER_1_TITLE")
	_gold_label.text = "%s: %s" % [tr("GOLD"), NumberFormatter.format_int(model.gold)]
	if ongoing:
		_gold_label.text += " " + tr("INCOME_PER_TURN") % NumberFormatter.format_int(model.income_forecast)
	_spirit_label.text = "%s: %s" % [tr("SPIRIT"), NumberFormatter.format_int(model.ruh)]
	_turn_label.text = "%s: %s" % [tr("TURN"), NumberFormatter.format_int(model.turn)]
	_end_turn_button.disabled = not ongoing
	_kok_bori_button.visible = model.boon_offer_available


## Her işlenmiş değişiklikten sonra tam yenileme (ADR-0011 karar 2): harita, HUD ve seçili
## bölge varsa bilgi paneli (üretim sayaçları, altın, sahiplik) güncel durumdan çizilir.
func _refresh_views() -> void:
	_campaign_map.refresh(_game_state.map_state)
	var selected: RegionData = _game_state.map_state.get_region(_game_state.map_state.selected_region_id)
	if selected != null:
		_show_region_info(selected)
	_render_hud(HudPresenter.build(_game_state, _resource_controller, _spirit, _modifiers.get_modifiers()))
	_update_focus_chain()


## Dinamik Ordu Gönder butonunu odak zincirine bağlar (art bible §7): görünürken
## Tur Bitir ↑ Ordu Gönder ↓ Tur Bitir; gizliyken bağ kaldırılır.
func _update_focus_chain() -> void:
	var send: Control = _info_panel.get_focus_target()
	if send == null:
		_end_turn_button.focus_neighbor_top = NodePath()
		return
	_end_turn_button.focus_neighbor_top = _end_turn_button.get_path_to(send)
	send.focus_neighbor_bottom = send.get_path_to(_end_turn_button)


func _on_region_clicked(region_id: StringName) -> void:
	# Modal açıkken harita girdisi kilitli (ADR-0011 karar 5).
	if _modal_queue.is_open():
		return
	if _awaiting_target:
		if _map_controller.attempt_move(region_id):
			_awaiting_target = false
			_send_from_id = &""
			_refresh_views()
		return
	_map_controller.select_region(region_id)


func _on_send_army_pressed(from_id: StringName) -> void:
	_awaiting_target = true
	_send_from_id = from_id


func _on_controller_region_selected(region_id: StringName) -> void:
	if _audio:
		_audio.play_sfx(AudioController.SFX_REGION_SELECT)
	_campaign_map.set_selected(region_id)
	_refresh_views()


## Bilgi paneline bölge + Erlik bilgisi (direnç, seviye sınırı, cezalı gelir) — değerler
## oyunun saf kurallarından (SpiritRules, IncomeRules); panel yalnızca gösterir (ADR-0011).
func _show_region_info(data: RegionData) -> void:
	var level: int = data.corruption_level
	_info_panel.show_region(
		data,
		_spirit_rules.corruption_strength(level),
		_spirit_rules.max_corruption_level(),
		IncomeRules.region_income(data, _spirit_rules.production_multiplier(level)),
	)
	match data.owner:
		RegionData.Owner.PLAYER:
			if _game_state.map_state.game_result == MapState.GameResult.ONGOING:
				var cost: int = _resource_controller.recruit_cost()
				_info_panel.show_recruit(
					data.recruited_this_turn,
					_resource_controller.recruit_cap(data),
					_resource_controller.max_recruit(_game_state, data),
					cost,
					maxi(0, cost - _game_state.gold),
				)
		RegionData.Owner.ENEMY:
			if _game_state.map_state.enemy_reinforcement_per_turn > 0:
				_info_panel.show_reinforcement(_game_state.map_state.enemy_reinforcement_per_turn)


## Ordu Topla aksiyon harcamaz (resource R4); sonuç panel ve HUD yenilenince görünür.
func _on_recruit_pressed(region_id: StringName, count: int) -> void:
	if _map_controller.recruit(region_id, count):
		_refresh_views()


func _on_controller_region_deselected() -> void:
	_campaign_map.clear_selection()
	_info_panel.hide_panel()
	_refresh_views()


func _on_end_turn_pressed() -> void:
	_awaiting_target = false
	_send_from_id = &""
	_map_controller.end_turn()


## `turn_ended` yalnızca oyun sürerken ve tur sonu kontrolünden sonra gelir — kayıt anı (ADR-0007).
func _on_turn_ended(_new_turn: int) -> void:
	if _save:
		_save.save_campaign(_game_state)
	_refresh_views()
	# Şafak (spirit §3.4): tur başına en çok 1 kendiliğinden sunum; ertelenebilir.
	_push_boon_offer(false)


func _on_income_collected(_amount: int) -> void:
	_refresh_views()


func _on_combat_occurred(
	_from_id: StringName,
	_to_id: StringName,
	_result: CombatResolver.CombatResult,
) -> void:
	_refresh_views()


func _on_purification_resolved(_outcome: MoveOutcome) -> void:
	_refresh_views()


func _on_army_moved(
	_from_id: StringName,
	_to_id: StringName,
	_army_count: int,
) -> void:
	_refresh_views()


## Zafer: bekleyen sunumlar outro'dan önce sırayla ve zorunlu (spirit §3.4, ADR-0011 C-35
## ek kararı); outro bağlantısı C-40'ta (ModalQueue.drained).
func _on_game_won() -> void:
	_refresh_views()
	_victory_picks = 0
	_push_boon_offer(true)


func _on_game_lost() -> void:
	_refresh_views()


## HUD Kök Böri düğmesi: oyuncu kendi turunda bekleyen sunumu istediği an açar.
func _on_kok_bori_pressed() -> void:
	if _game_state.map_state.game_result == MapState.GameResult.ONGOING:
		_push_boon_offer(false)


## Sunum bekliyorsa (ve başka modal yoksa) lütuf modalını sıraya koyar. [param mandatory]
## sahne sonu dizisidir: ertelenemez, `victory_pick_cap` ile sınırlıdır.
func _push_boon_offer(mandatory: bool) -> void:
	if _modal_queue.is_open() and not mandatory:
		return
	if mandatory and _victory_picks >= _spirit_rules.victory_pick_cap():
		return
	var offer: Array[BoonDefinition] = _spirit.current_offer(_game_state.map_state.chapter_id)
	if offer.is_empty():
		return
	var modal: BoonOfferModal = BoonOfferModal.new()
	modal.show_offer(offer, _game_state.ruh, _spirit.next_boon_cost(), mandatory)
	modal.boon_picked.connect(_on_boon_picked.bind(mandatory))
	_modal_queue.push(modal)


## Seçim SpiritController'da uygulanır (Ruh düşer, etki hemen başlar). Sahne sonunda koşul
## hâlâ sağlanıyorsa bir sonraki zorunlu sunum hemen sıraya girer; tur içinde ise HUD
## düğmesi açık kalır (kendiliğinden ikinci modal yok — §3.4).
func _on_boon_picked(boon_id: StringName, mandatory: bool) -> void:
	if not _spirit.pick_boon(_game_state.map_state.chapter_id, boon_id):
		return
	_refresh_views()
	if mandatory:
		_victory_picks += 1
		_push_boon_offer(true)


func _on_menu_pressed() -> void:
	return_to_menu_requested.emit()
