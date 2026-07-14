class_name GameContext
extends Control


signal return_to_menu_requested


const CHAPTER_1_MAP: ChapterMapDefinition = preload("res://features/grid/data/chapter_1_map.tres")

@onready var _chapter_label: Label = %ChapterLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _turn_label: Label = %TurnLabel
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _menu_button: Button = %MenuButton

var _game_state: GameState
var _map_controller: MapController
var _army_controller: ArmyController
var _resource_controller: ResourceController
var _combat_resolver: CombatResolver
var _campaign_map: CampaignMap
var _info_panel: RegionInfoPanel
var _awaiting_target: bool = false
var _send_from_id: StringName = &""


func bind_services(game_state: GameState) -> void:
	_game_state = game_state


func _ready() -> void:
	_setup_controllers()
	_setup_map_visuals()
	_connect_signals()
	_update_ui()


func _setup_controllers() -> void:
	var map_def: ChapterMapDefinition = CHAPTER_1_MAP
	_game_state.map_state = map_def.create_map_state()
	_game_state.gold = 100

	_army_controller = ArmyController.new()
	_resource_controller = ResourceController.new()
	_combat_resolver = CombatResolver.new()
	_map_controller = MapController.new()
	_map_controller.bind_services(
		_game_state.map_state,
		_game_state,
		_army_controller,
		_resource_controller,
		_combat_resolver,
		map_def.win_condition,
	)


func _setup_map_visuals() -> void:
	_campaign_map = CampaignMap.new()
	add_child(_campaign_map)
	move_child(_campaign_map, 1)
	_campaign_map.build_map(_game_state.map_state)

	_info_panel = RegionInfoPanel.new()
	_info_panel.layout_mode = 1
	_info_panel.anchors_preset = 3
	_info_panel.anchor_left = 1.0
	_info_panel.anchor_top = 1.0
	_info_panel.anchor_right = 1.0
	_info_panel.anchor_bottom = 1.0
	_info_panel.offset_left = -300.0
	_info_panel.offset_top = -270.0
	_info_panel.offset_right = -16.0
	_info_panel.offset_bottom = -64.0
	_info_panel.grow_horizontal = 0
	_info_panel.grow_vertical = 0
	add_child(_info_panel)


func _connect_signals() -> void:
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_campaign_map.region_clicked.connect(_on_region_clicked)
	_info_panel.send_army_pressed.connect(_on_send_army_pressed)
	_map_controller.region_selected.connect(_on_controller_region_selected)
	_map_controller.region_deselected.connect(_on_controller_region_deselected)
	_map_controller.turn_ended.connect(_on_turn_ended)
	_map_controller.income_collected.connect(_on_income_collected)
	_map_controller.combat_occurred.connect(_on_combat_occurred)
	_map_controller.army_moved.connect(_on_army_moved)
	_map_controller.game_won.connect(_on_game_won)
	_map_controller.game_lost.connect(_on_game_lost)


func _update_ui() -> void:
	_chapter_label.text = tr("CHAPTER_1_TITLE")
	_gold_label.text = "%s: %d" % [tr("GOLD"), _game_state.gold]
	_turn_label.text = "%s: %d" % [tr("TURN"), _game_state.map_state.current_turn]
	_end_turn_button.disabled = false


func _refresh_map() -> void:
	_campaign_map.refresh(_game_state.map_state)
	_update_ui()


func _on_region_clicked(region_id: StringName) -> void:
	if _awaiting_target:
		if _map_controller.attempt_move(region_id):
			_awaiting_target = false
			_send_from_id = &""
			_refresh_map()
		return
	_map_controller.select_region(region_id)


func _on_send_army_pressed(from_id: StringName) -> void:
	_awaiting_target = true
	_send_from_id = from_id


func _on_controller_region_selected(region_id: StringName) -> void:
	_campaign_map.set_selected(region_id)
	var data: RegionData = _game_state.map_state.get_region(region_id)
	if data:
		_info_panel.show_region(data)
	_refresh_map()


func _on_controller_region_deselected() -> void:
	_campaign_map.clear_selection()
	_info_panel.hide_panel()
	_refresh_map()


func _on_end_turn_pressed() -> void:
	_awaiting_target = false
	_send_from_id = &""
	_map_controller.end_turn()


func _on_turn_ended(_new_turn: int) -> void:
	_refresh_map()


func _on_income_collected(_amount: int) -> void:
	_update_ui()


func _on_combat_occurred(
	_from_id: StringName,
	_to_id: StringName,
	_result: CombatResolver.CombatResult,
) -> void:
	_refresh_map()


func _on_army_moved(
	_from_id: StringName,
	_to_id: StringName,
	_army_count: int,
) -> void:
	_refresh_map()


func _on_game_won() -> void:
	_end_turn_button.disabled = true
	_chapter_label.text = tr("VICTORY")


func _on_game_lost() -> void:
	_end_turn_button.disabled = true
	_chapter_label.text = tr("DEFEAT")


func _on_menu_pressed() -> void:
	return_to_menu_requested.emit()
