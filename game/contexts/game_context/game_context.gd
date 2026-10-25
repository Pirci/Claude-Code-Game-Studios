class_name GameContext
extends Control


## Sahne akışına yukarı sinyaller (ADR-0012 karar 3) — geçişi RootContext'in SceneFlow'u verir.
signal menu_requested
signal leave_confirmed
signal objective_dismissed
signal scene_won
signal scene_lost
signal victory_acknowledged
signal boon_picks_finished
signal retry_requested


## Kampanya içeriği: sahne verilmezse buradan `current_chapter` sahnesi bulunur. Bölüm
## haritası sahnenin `map_path`'inden bağlam başlarken `load()` edilir (ADR-0001, ADR-0012).
const CAMPAIGN_PATH: String = "res://features/campaign/data/campaign.tres"
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
@onready var _top_bar: Control = %TopBarPanel
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _shadow_label: Label = %ShadowLabel
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _menu_button: Button = %MenuButton

var _game_state: GameState
var _accessibility: AccessibilitySettings
var _audio: AudioController = null
var _save: SaveController = null
var _scene: SceneDefinition = null
var _flow_config: SceneFlowConfig = SceneFlowConfig.new()
## Görülen öğretici ipuçları (RootContext enjekte eder; null → öğretici kapalı).
var _tutorial: TutorialProgress = null
var _hint_bubble: HintBubble = null
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
## Gece tamponu (ADR-0010 eki G4): oyuncu turu bitirince temizlenir; `end_turn()` sırasında düşman
## savaş/arındırma sonuçları ve yayılım kararı birikir; şafakta tur özeti bunu okur (C-73).
var _night_outcomes: Array[MoveOutcome] = []
var _night_spread: ErlikSpreadController.SpreadDecision = null
## HUD altın değişimi (resource §9): gelir yeşil `↑+X`, harcama kırmızı `↓-X`.
var _gold_feedback: ValueFeedback = ValueFeedback.new()
var _gold_feedback_generation: int = 0
var _gold_text: String = ""
var _income_text: String = ""


## [param audio] isteğe bağlıdır (null → sessiz; testler ve sessiz başlatma için).
## [param save] verilirse her tur sonunda kampanya otomatik kaydedilir (ADR-0007, S1).
## [param scene] verilmezse kampanyadan `current_chapter` sahnesi kullanılır.
func bind_services(
	game_state: GameState,
	accessibility: AccessibilitySettings,
	audio: AudioController = null,
	save: SaveController = null,
	scene: SceneDefinition = null,
	flow_config: SceneFlowConfig = null,
	tutorial: TutorialProgress = null,
) -> void:
	_game_state = game_state
	_accessibility = accessibility
	_audio = audio
	_save = save
	_scene = scene
	if flow_config != null:
		_flow_config = flow_config
	_tutorial = tutorial


func _ready() -> void:
	# Area2D bölge tıklamalarının çalışması için 2D fiziksel nesne seçimini aç.
	get_viewport().physics_object_picking = true
	_gold_feedback.reduce_motion = _accessibility != null and _accessibility.reduce_motion
	_setup_controllers()
	_setup_map_visuals()
	_connect_signals()
	_refresh_views()
	FocusReveal.focus_quietly(_end_turn_button)
	# Hedef paneli (RootContext) senkron açılır; panel yoksa (Devam Et) 1. tur ipucu hemen.
	_check_start_hint.call_deferred()


func _setup_controllers() -> void:
	if _scene == null:
		_scene = (load(CAMPAIGN_PATH) as CampaignDefinition).scene(_game_state.current_chapter)
	assert(_scene != null, "Sahne tanımı yok: %d" % _game_state.current_chapter)
	var map_def: ChapterMapDefinition = _scene.load_map_definition()
	assert(map_def != null, "Bölüm haritası yüklenemedi: %s" % _scene.map_path)
	_map_def = map_def
	# Harita normalde sahne akışında kurulur (ADR-0012 T11/T22) ya da kayıttan gelir;
	# yoksa (testler, eski çağrılar) bölüm içerikten başlar.
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
	_spirit.bind_boons(BOON_CATALOG, _modifiers, _scene.boon_pool_ids)
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
	_modal_queue.drained.connect(_check_start_hint)


func _connect_signals() -> void:
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_kok_bori_button.pressed.connect(_on_kok_bori_pressed)
	_campaign_map.region_clicked.connect(_on_region_clicked)
	_campaign_map.region_accepted.connect(_on_region_accepted)
	_info_panel.send_army_pressed.connect(_on_send_army_pressed)
	_info_panel.recruit_pressed.connect(_on_recruit_pressed)
	_map_controller.region_selected.connect(_on_controller_region_selected)
	_map_controller.region_deselected.connect(_on_controller_region_deselected)
	_map_controller.turn_ended.connect(_on_turn_ended)
	_map_controller.income_collected.connect(_on_income_collected)
	_map_controller.combat_occurred.connect(_on_combat_occurred)
	_map_controller.purification_resolved.connect(_on_purification_resolved)
	_map_controller.army_moved.connect(_on_army_moved)
	_map_controller.corruption_spread.connect(_on_corruption_spread)
	_spirit.ruh_changed.connect(_on_ruh_changed)
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
			_chapter_label.text = tr(String(_scene.title_key))
	_gold_text = "%s: %s" % [tr("GOLD"), NumberFormatter.format_int(model.gold)]
	_income_text = NumberFormatter.ltr(tr("INCOME_PER_TURN") % NumberFormatter.format_int(model.income_forecast)) \
		if ongoing else ""
	if _gold_feedback.observe(model.gold) and is_inside_tree():
		_gold_feedback_generation += 1
		get_tree().create_timer(ValueFeedback.FLASH_SEC).timeout.connect(
			_on_gold_flash_expired.bind(_gold_feedback_generation))
		get_tree().create_timer(ValueFeedback.DELTA_HOLD_SEC).timeout.connect(
			_on_gold_delta_expired.bind(_gold_feedback_generation))
	_render_gold()
	_spirit_label.text = "%s: %s" % [tr("SPIRIT"), NumberFormatter.format_int(model.ruh)]
	_render_objective(model)
	_turn_label.text = "%s: %s" % [tr("TURN"), NumberFormatter.format_int(model.turn)]
	_end_turn_button.disabled = not ongoing
	_kok_bori_button.visible = model.boon_offer_available


## Altın + değişim farkı (`Altın: 25 ↑+5 (+5 / tur)`) ve 2 karelik renk vurgusu.
func _render_gold() -> void:
	var parts: PackedStringArray = [_gold_text]
	for part: String in [_gold_feedback.delta_text(), _income_text]:
		if not part.is_empty():
			parts.append(part)
	_gold_label.text = " ".join(parts)
	if _gold_feedback.is_flashing():
		_gold_label.add_theme_color_override(&"font_color", _gold_feedback.flash_color(Color.WHITE))
	else:
		_gold_label.remove_theme_color_override(&"font_color")


func _on_gold_flash_expired(generation: int) -> void:
	if generation == _gold_feedback_generation:
		_gold_feedback.expire_flash()
		_render_gold()


func _on_gold_delta_expired(generation: int) -> void:
	if generation == _gold_feedback_generation:
		_gold_feedback.expire_delta()
		_render_gold()


## Testler için: HUD altın geri bildirimi.
func get_gold_feedback() -> ValueFeedback:
	return _gold_feedback


## Üst HUD çubuğunun yüksekliği (2 satır; dile göre font boyu değişir).
func _top_bar_height() -> float:
	return _top_bar.get_combined_minimum_size().y


## Kalıcı "Hedef" satırı + ilerleme + Erlik'in Gölgesi (scene-flow §10, spirit AC24); eşik
## kapalıysa (0) gölge gizlenir. `erlik_power = eşik − 1` iken hedef metninin yerini aynı satırda
## kırmızı "bir sonraki yayılımda kayıp" uyarısı alır (üst çubuk büyümez, harita örtülmez).
func _render_objective(model: HudModel) -> void:
	var ongoing: bool = model.game_result == MapState.GameResult.ONGOING
	var warning: bool = model.erlik_warning and ongoing
	_objective_label.text = tr("ERLIK_SHADOW_WARNING") if warning \
		else "%s: %s" % [tr("OBJECTIVE_LABEL"), tr(String(model.objective_key))]
	_objective_label.add_theme_color_override(&"font_color", RegionInfoPanel.COLOR_LOSS) if warning \
		else _objective_label.remove_theme_color_override(&"font_color")
	var parts: PackedStringArray = []
	if model.neutral_required > 0:
		parts.append(tr("OBJECTIVE_TRIBES") % NumberFormatter.fraction(model.neutral_conquered, model.neutral_required))
	if model.foci_total > 0:
		parts.append(tr("OBJECTIVE_FOCI") % NumberFormatter.fraction(model.foci_cleansed, model.foci_total))
	_progress_label.text = "  ".join(parts)
	_progress_label.visible = not warning  # uyarı tam okunsun diye aynı satırda yer açılır
	_shadow_label.visible = model.erlik_threshold > 0
	_shadow_label.text = tr("ERLIK_SHADOW_VALUE") % NumberFormatter.fraction(model.erlik_power, model.erlik_threshold)
	_shadow_label.add_theme_color_override(&"font_color", RegionInfoPanel.COLOR_LOSS if model.erlik_warning \
		else RegionInfoPanel.COLOR_ERLIK_INFO)


## Her işlenmiş değişiklikten sonra tam yenileme (ADR-0011 karar 2): harita, HUD ve seçili
## bölge varsa bilgi paneli (üretim sayaçları, altın, sahiplik) güncel durumdan çizilir.
func _refresh_views() -> void:
	_campaign_map.refresh(_game_state.map_state)
	var selected: RegionData = _game_state.map_state.get_region(_game_state.map_state.selected_region_id)
	if selected != null:
		_show_region_info(selected)
	_render_hud(HudPresenter.build(_game_state, _resource_controller, _spirit, _modifiers.get_modifiers(),
		_map_def.win_condition))
	_campaign_map.set_objective_markers(
		CampaignRules.objective_markers(_game_state.map_state, _map_def.win_condition, _scene))
	_update_focus_chain()


## Dinamik Ordu Gönder butonunu odak zincirine bağlar (art bible §7): görünürken
## Tur Bitir ↑ Ordu Gönder ↓ Tur Bitir; gizliyken bağ kaldırılır.
func _update_focus_chain() -> void:
	_link_map_tab_order()
	var send: Control = _info_panel.get_focus_target()
	if send == null:
		_end_turn_button.focus_neighbor_top = NodePath()
		return
	_end_turn_button.focus_neighbor_top = _end_turn_button.get_path_to(send)
	send.focus_neighbor_bottom = send.get_path_to(_end_turn_button)


## Tab: Tur Bitir → harita bölgeleri (okuma sırası) → Tur Bitir'in olağan sonrakisi (K4, A-7).
## Olağan sonraki, HUD görünürlüğü değiştikçe değişir; her yenilemede yeniden hesaplanır.
func _link_map_tab_order() -> void:
	var order: Array[Control] = _campaign_map.focus_order()
	if order.is_empty():
		return
	_end_turn_button.focus_next = NodePath()
	var after: Control = _end_turn_button.find_next_valid_focus()
	_end_turn_button.focus_next = _end_turn_button.get_path_to(order[0])
	order[0].focus_previous = order[0].get_path_to(_end_turn_button)
	var last: Control = order[order.size() - 1]
	if after != null and after != _end_turn_button:
		last.focus_next = last.get_path_to(after)
	else:
		last.focus_next = last.get_path_to(_end_turn_button)


func _on_region_clicked(region_id: StringName) -> void:
	# Modal açıkken harita girdisi kilitli (ADR-0011 karar 5).
	if _modal_queue.is_open():
		return
	if _awaiting_target:
		if _map_controller.attempt_move(region_id):
			_set_target_mode(false)
			_refresh_views()
		return
	_map_controller.select_region(region_id)


## Klavyeyle seçim (K4): hedef modunda hamle; değilse seçim + odak panelin ilk etkin düğmesine
## (görünür). Panelde düğme yoksa odak bölgede kalır.
func _on_region_accepted(region_id: StringName) -> void:
	if _modal_queue.is_open():
		return
	if _awaiting_target:
		_on_region_clicked(region_id)
		return
	_on_region_clicked(region_id)
	var first: Control = _info_panel.get_first_focus()
	if first != null:
		first.grab_focus()


## [Ordu Gönder]: hedef seçim modu (A5). Mod açıkken tekrar basmak iptal eder. Klavyeyle
## basıldıysa odak kaynak bölgeye geçer (oklarla hedef seçilir); fareyle gizli kalır.
func _on_send_army_pressed(from_id: StringName) -> void:
	if _awaiting_target:
		_cancel_target_mode()
		return
	var keyboard: bool = _info_panel.get_send_button().has_focus(true)
	_set_target_mode(true, from_id)
	var source: Control = _campaign_map.focus_target(from_id)
	if source != null:
		source.grab_focus(not keyboard)


## Hedef modu iptal (Esc / tekrar basış): odak [Ordu Gönder]'e, klavye odağı görünürse görünür.
func _cancel_target_mode() -> void:
	var owner: Control = get_viewport().gui_get_focus_owner()
	var keyboard: bool = owner != null and owner.has_focus(true)
	_set_target_mode(false)
	var send: Button = _info_panel.get_send_button()
	if send.is_visible_in_tree():
		send.grab_focus(not keyboard)


func _set_target_mode(awaiting: bool, from_id: StringName = &"") -> void:
	_awaiting_target = awaiting
	_send_from_id = from_id if awaiting else &""
	_info_panel.set_awaiting_target(awaiting)


## Esc (hud §10.3 kural 7): hedef modu iptal; panel odaktaysa seçili bölgeye dön. Modal
## açıkken modal kendisi karar verir.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel") or _modal_queue.is_open():
		return
	if _awaiting_target:
		get_viewport().set_input_as_handled()
		_cancel_target_mode()
		return
	var owner: Control = get_viewport().gui_get_focus_owner()
	var selected: StringName = _game_state.map_state.selected_region_id
	if owner != null and _info_panel.is_ancestor_of(owner) and selected != &"":
		var region: Control = _campaign_map.focus_target(selected)
		if region != null:
			get_viewport().set_input_as_handled()
			region.grab_focus(not owner.has_focus(true))


func _on_controller_region_selected(region_id: StringName) -> void:
	if _audio:
		_audio.play_sfx(AudioController.SFX_REGION_SELECT)
	_campaign_map.set_selected(region_id)
	_refresh_views()
	_offer_hint(TutorialRules.hint_for_selection(_game_state.map_state.get_region(region_id)))


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


# --- Öğretici ipuçları (design/ux/prolog-tutorial.md) ---

## 1. turda altın yetiyorsa "önce üret" — modal açıkken bekler, kapanınca (`drained`) gelir.
## Bu gece yayılım olduysa yayılım ipucu önce (Q9: tur özeti kapanana dek ertelenir).
func _check_start_hint() -> void:
	if _game_state.map_state == null or _modal_queue.is_open() \
			or _game_state.map_state.game_result != MapState.GameResult.ONGOING:
		return
	if _night_spread != null:
		_offer_hint(TutorialRules.HINT_SPREAD)
	_offer_hint(TutorialRules.hint_at_turn_start(
		_game_state.map_state.current_turn, _game_state.gold, _resource_controller.recruit_cost()))


func _on_corruption_spread(decision: ErlikSpreadController.SpreadDecision) -> void:
	_night_spread = decision  # ipucu özet kapanınca (`drained` → `_check_start_hint`)


func _on_ruh_changed(ruh: int) -> void:
	if ruh > 0:
		_offer_hint(TutorialRules.HINT_SPIRIT)


## İpucunu gösterir: görülmediyse, başka balon/modal yoksa ve oyun sürüyorsa. Görülmüş sayılması
## balon kapanınca olur; meşgulken kaçan ipucu bir sonraki tetikte yeniden denenir.
func _offer_hint(hint_id: StringName) -> void:
	if _tutorial == null or hint_id == &"" or _tutorial.has_seen(hint_id):
		return
	if _hint_bubble != null or _modal_queue.is_open():
		return
	# Sahne tamamlanınca (COMMIT) harita durumu null olur; o zaman ipucu yok.
	if _game_state.map_state == null or _game_state.map_state.game_result != MapState.GameResult.ONGOING:
		return
	_hint_bubble = HintBubble.new(hint_id)
	_hint_bubble.dismissed.connect(_on_hint_dismissed)
	add_child(_hint_bubble)
	# Sol üst tercih (alt-sol Bereket Vadisi'ni örter); işaret örtülürse sağ üst, sonra sol alt.
	var size: Vector2 = _hint_bubble.get_combined_minimum_size()
	var top: float = _top_bar_height() + 4.0
	var bottom: float = self.size.y - 31.0 - size.y
	var corners: Array[Vector2] = [Vector2(4.0, top), Vector2(self.size.x - 4.0 - size.x, top), Vector2(4.0, bottom)]
	var rects: Array[Rect2] = []
	for corner: Vector2 in corners:
		rects.append(Rect2(corner, size))
	_hint_bubble.position = corners[PanelPlacement.choose(rects, _campaign_map.objective_marker_rects())]


func _on_hint_dismissed(hint_id: StringName) -> void:
	_tutorial.mark_seen(hint_id)
	remove_child(_hint_bubble)
	_hint_bubble.queue_free()
	_hint_bubble = null


## Ordu Topla aksiyon harcamaz (resource R4); sonuç panel ve HUD yenilenince görünür.
func _on_recruit_pressed(region_id: StringName, count: int) -> void:
	if _map_controller.recruit(region_id, count):
		if _audio:
			_audio.play_sfx(AudioController.SFX_RECRUIT)
		_refresh_views()


func _on_controller_region_deselected() -> void:
	_set_target_mode(false)
	_campaign_map.clear_selection()
	_info_panel.hide_panel()
	_refresh_views()


func _on_end_turn_pressed() -> void:
	_set_target_mode(false)
	_clear_night()
	_map_controller.end_turn()


## Testler ve tur özeti (C-73) için: bu gecenin düşman sonuçları ve yayılım kararı (salt okunur).
func night_outcomes() -> Array[MoveOutcome]:
	return _night_outcomes


func night_spread() -> ErlikSpreadController.SpreadDecision:
	return _night_spread


func _clear_night() -> void:
	_night_outcomes.clear()
	_night_spread = null


## Düşman sonucu geceye yazılır; oyuncu hamlesi tamponlanmaz (raporu hamleden hemen sonra açılır).
func _record_night(outcome: MoveOutcome) -> void:
	if outcome.mover == RegionData.Owner.ENEMY:
		_night_outcomes.append(outcome)


## `turn_ended` yalnızca oyun sürerken ve tur sonu kontrolünden sonra gelir — kayıt anı (ADR-0007).
func _on_turn_ended(_new_turn: int) -> void:
	if _save:
		_save.save_campaign(_game_state)
	_refresh_views()
	# Sıra (ADR-0011 K5): gece özeti → şafak lütfu (spirit §3.4: en çok 1, ertelenebilir).
	var summary_open: bool = _push_turn_summary()
	_push_boon_offer(false, summary_open)


## Bu gecenin özeti; olaysız gecede modal açılmaz (battle-report Q5). Açıldıysa true.
func _push_turn_summary() -> bool:
	var map_state: MapState = _game_state.map_state
	var names: Dictionary = {}
	for region_id: StringName in map_state.regions:
		names[region_id] = _region_name_key(region_id)
	var win: WinCondition = _map_def.win_condition
	var warning: bool = win != null and win.erlik_loss_threshold > 0 \
		and WinCondition.erlik_power(map_state) == win.erlik_loss_threshold - 1
	var summary: TurnSummaryReport = TurnSummaryReport.new(_night_outcomes, _night_spread, names, warning,
		_flow_config.screen_input_guard_s)
	if not summary.has_events():
		summary.free()
		return false
	_modal_queue.top_margin = _top_bar_height() + 4.0
	_modal_queue.push(summary)
	return true


func _on_income_collected(amount: int) -> void:
	if _audio and amount > 0:
		_audio.play_sfx(AudioController.SFX_INCOME)
	_refresh_views()


func _on_combat_occurred(outcome: MoveOutcome) -> void:
	_record_night(outcome)
	_refresh_views()
	if outcome.mover == RegionData.Owner.PLAYER and _report_data_ok(outcome):
		_push_report(BattleReport.new(outcome, _region_name_key(outcome.to_id), _flow_config.screen_input_guard_s),
			outcome.to_id)


func _on_purification_resolved(outcome: MoveOutcome) -> void:
	_record_night(outcome)
	_refresh_views()
	if outcome.mover == RegionData.Owner.PLAYER and _report_data_ok(outcome):
		var is_focus: bool = _map_def.win_condition != null and outcome.to_id in _map_def.win_condition.erlik_foci
		_push_report(PurificationReport.new(outcome, _region_name_key(outcome.to_id), _scene if is_focus else null,
			_flow_config.screen_input_guard_s), outcome.to_id)


## Oyuncu hamlesi raporu hamleden hemen sonra açılır; hedef bölgeyi örtmeyen yere yerleşir
## (ux/battle-report.md §2–§3). Kazandıran hamlede rapor zafer kartından önce gelir (kuyruk sırası).
func _push_report(report: ReportModal, target_id: StringName) -> void:
	_modal_queue.top_margin = _top_bar_height() + 4.0
	_modal_queue.push_avoiding(report, [_campaign_map.region_rect(target_id)] as Array[Rect2])


## Eksik veride rapor açılmaz, uyarı günlüğe yazılır (ux/battle-report.md §9). Başarısız arındırmada
## savaş sonucu tasarım gereği yoktur (bütün kuvvet dağılır) — o rapor yalnız `moving` ve `S` okur.
func _report_data_ok(outcome: MoveOutcome) -> bool:
	var needs_combat: bool = outcome.branch == MoveOutcome.Branch.COMBAT or outcome.purified
	if needs_combat and outcome.combat == null:
		push_warning("GameContext: savaş sonucu olmayan outcome için rapor atlandı (%s → %s)" % [outcome.from_id, outcome.to_id])
		return false
	return true


func _region_name_key(region_id: StringName) -> StringName:
	var region: RegionData = _game_state.map_state.get_region(region_id)
	return region.display_name_key if region != null else &""


func _on_army_moved(
	_from_id: StringName,
	_to_id: StringName,
	_army_count: int,
) -> void:
	_refresh_views()


## Zafer/yenilgi sahne akışına bildirilir (T13/T14); sonuç kartı ve yenilgi ekranını
## RootContext ister ([method show_victory] / [method show_defeat]).
func _on_game_won() -> void:
	_clear_night()  # zafer kartı anlatır; özet açılmaz (ADR-0010 eki G4)
	_refresh_views()
	scene_won.emit()


func _on_game_lost() -> void:
	_clear_night()  # yenilgi ekranı anlatır (battle-report Q3)
	_refresh_views()
	scene_lost.emit()


# --- Sahne akışı modalları (ADR-0012 karar 3; RootContext çağırır) ---

## `KOK_BORI_MARK` B: Kök Böri sözü + kazanma koşulundan hedef metni; [Başla] → S2.
func show_objective() -> void:
	var panel: ObjectivePanel = ObjectivePanel.new(_scene.kok_bori_line_key,
		_map_def.win_condition.description_key if _map_def.win_condition != null else &"",
		_flow_config.screen_input_guard_s)
	panel.dismissed.connect(objective_dismissed.emit)
	# Önce alt-orta; işaret örtülürse üst-orta, ikisi de örterse en az örten (scene-flow §3.5).
	_modal_queue.top_margin = _top_bar_height() + 4.0
	_modal_queue.push(panel, ModalQueue.Placement.BOTTOM)
	var options: Array[ModalQueue.Placement] = [ModalQueue.Placement.BOTTOM, ModalQueue.Placement.TOP]
	var rects: Array[Rect2] = []
	for option: ModalQueue.Placement in options:
		rects.append(_modal_queue.rect_for(panel, option))
	_modal_queue.place(panel, options[PanelPlacement.choose(rects, _campaign_map.objective_marker_rects())])


## T15: harita sırasında Ana Menü onayı (kayıt yazılmaz).
func show_leave_confirm() -> void:
	var dialog: ConfirmDialog = ConfirmDialog.new("CONFIRM_LEAVE_SCENE", _flow_config.screen_input_guard_s)
	dialog.confirmed.connect(leave_confirmed.emit)
	_modal_queue.push(dialog)


## `VICTORY_BEAT` sonuç kartı: tur, tutulan bölge / toplam, sahnede kazanılan Ruh (F3).
func show_victory(ruh_gained: int) -> void:
	var map_state: MapState = _game_state.map_state
	var card: VictoryCard = VictoryCard.new(map_state.current_turn, map_state.get_player_regions().size(),
		map_state.regions.size(), ruh_gained, _flow_config.screen_input_guard_s)
	card.acknowledged.connect(victory_acknowledged.emit)
	_modal_queue.push(card)


## `BOON_PICKS` (T16/T17): zorunlu lütuf zinciri; bitince `boon_picks_finished`.
func start_boon_picks() -> void:
	_victory_picks = 0
	if not _push_boon_offer(true):
		boon_picks_finished.emit.call_deferred()


## Sahne sonunda zorunlu seçim bekliyor mu (F2 `k > 0`)?
func has_pending_offer() -> bool:
	return _spirit.is_offer_pending()


## "Devam Et" yüklemesi tur başı sayılır (scene-flow §3.4): bekleyen sunum bir kez açılır.
func offer_pending_boon() -> void:
	_push_boon_offer(false)


## `DEFEAT`: neden metni, Erlik kaybında `erlik_power / eşik`; [Yeniden Dene] / [Ana Menü].
func show_defeat() -> void:
	var map_state: MapState = _game_state.map_state
	var win: WinCondition = _map_def.win_condition
	var erlik: bool = map_state.loss_reason == MapState.LossReason.ERLIK and win != null
	var screen: DefeatScreen = DefeatScreen.new(CampaignRules.defeat_text_key(_scene, map_state.loss_reason),
		WinCondition.erlik_power(map_state) if erlik else 0, win.erlik_loss_threshold if erlik else 0,
		_flow_config.screen_input_guard_s)
	screen.retry_requested.connect(retry_requested.emit)
	screen.menu_requested.connect(menu_requested.emit)
	_modal_queue.push(screen)


## HUD Kök Böri düğmesi: oyuncu kendi turunda bekleyen sunumu istediği an açar.
func _on_kok_bori_pressed() -> void:
	if _game_state.map_state.game_result == MapState.GameResult.ONGOING:
		_push_boon_offer(false)


## Sunum bekliyorsa (ve başka modal yoksa) lütuf modalını sıraya koyar. [param mandatory]
## sahne sonu dizisidir: ertelenemez, `victory_pick_cap` ile sınırlıdır.
## [param after_summary]: şafak sunumu bu gecenin özetinin arkasına girer (açık tek modal odur).
## Sıraya girdiyse true.
func _push_boon_offer(mandatory: bool, after_summary: bool = false) -> bool:
	if _modal_queue.is_open() and not mandatory and not after_summary:
		return false
	if mandatory and _victory_picks >= _spirit_rules.victory_pick_cap():
		return false
	var offer: Array[BoonDefinition] = _spirit.current_offer(_game_state.map_state.chapter_id)
	if offer.is_empty():
		return false
	var modal: BoonOfferModal = BoonOfferModal.new(_flow_config.screen_input_guard_s)
	var stacks: Dictionary = {}
	for boon: BoonDefinition in offer:
		if boon.modifier_source != null:
			stacks[boon.boon_id] = _modifiers.stacks_of(boon.modifier_source.source_id)
	modal.show_offer(offer, _game_state.ruh, _spirit.next_boon_cost(), mandatory, stacks)
	modal.boon_picked.connect(_on_boon_picked.bind(mandatory))
	_modal_queue.push(modal)
	return true


## Seçim SpiritController'da uygulanır (Ruh düşer, etki hemen başlar). Sahne sonunda koşul
## hâlâ sağlanıyorsa bir sonraki zorunlu sunum hemen sıraya girer; tur içinde ise HUD
## düğmesi açık kalır (kendiliğinden ikinci modal yok — §3.4).
func _on_boon_picked(boon_id: StringName, mandatory: bool) -> void:
	if not _spirit.pick_boon(_game_state.map_state.chapter_id, boon_id):
		return
	_refresh_views()
	if mandatory:
		_victory_picks += 1
		if not _push_boon_offer(true):
			# Modal `closed`'ı yayıp kuyruktan çıktıktan sonra akış ilerlesin (bağlam değişimi).
			boon_picks_finished.emit.call_deferred()


## T15: onay sahne akışından gelir ([method show_leave_confirm]).
func _on_menu_pressed() -> void:
	menu_requested.emit()
