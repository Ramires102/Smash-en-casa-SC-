class_name GachaMenu
extends Control

# ── Rareza ────────────────────────────────────────────────────
enum Rarity { COMMON, RARE, SUPER_RARE, EPIC, LEGENDARY }

const RARITY_NAMES := {
	Rarity.COMMON:     "COMÚN",
	Rarity.RARE:       "RARO",
	Rarity.SUPER_RARE: "SUPER RARO",
	Rarity.EPIC:       "ÉPICO",
	Rarity.LEGENDARY:  "LEGENDARIO",
}
const RARITY_COLORS := {
	Rarity.COMMON:     Color(0.55, 0.55, 0.55),
	Rarity.RARE:       Color(0.10, 0.80, 0.20),
	Rarity.SUPER_RARE: Color(0.10, 0.40, 1.00),
	Rarity.EPIC:       Color(0.60, 0.10, 0.90),
	Rarity.LEGENDARY:  Color(1.00, 0.75, 0.00),
}
const RARITY_INNER := {
	Rarity.COMMON:     Color(0.80, 0.80, 0.80),
	Rarity.RARE:       Color(0.50, 1.00, 0.60),
	Rarity.SUPER_RARE: Color(0.50, 0.80, 1.00),
	Rarity.EPIC:       Color(0.85, 0.50, 1.00),
	Rarity.LEGENDARY:  Color(1.00, 0.95, 0.50),
}
# Rangos de polvo por rareza [min, max]
const RARITY_DUST := {
	Rarity.COMMON:     [15,  15],
	Rarity.RARE:       [20,  35],
	Rarity.SUPER_RARE: [40,  60],
	Rarity.EPIC:       [75,  95],
	Rarity.LEGENDARY:  [100, 160],
}
# Pesos acumulados (50 / 75 / 90 / 97 / 100)
const RARITY_WEIGHTS := [50, 75, 90, 97, 100]

# ── Nodos ─────────────────────────────────────────────────────
@onready var victory_label: Label         = $MainVBox/DustRow/VictoryBox/VictoryLabel
@onready var defeat_label: Label          = $MainVBox/DustRow/DefeatBox/DefeatLabel
@onready var victory_circles: Control      = $MainVBox/DustRow/VictoryBox/VictoryCircles
@onready var defeat_circles: Control       = $MainVBox/DustRow/DefeatBox/DefeatCircles
@onready var tesseract: TesseractDisplay   = $MainVBox/TesseractArea/Tesseract
@onready var status_label: Label          = $MainVBox/StatusLabel
@onready var skip_btn: Button             = $MainVBox/SkipBtn
@onready var pull_victory_btn: Button     = $MainVBox/ButtonRow/PullVictoryBtn
@onready var pull_victory_10_btn: Button  = $MainVBox/ButtonRow/PullVictory10Btn
@onready var pull_defeat_btn: Button      = $MainVBox/ButtonRow2/PullDefeatBtn
@onready var pull_defeat_10_btn: Button   = $MainVBox/ButtonRow2/PullDefeat10Btn
@onready var result_panel: PanelContainer = $MainVBox/ResultPanel
@onready var rarity_label: Label          = $MainVBox/ResultPanel/ResultVBox/RarityLabel
@onready var reward_label: Label          = $MainVBox/ResultPanel/ResultVBox/RewardLabel
@onready var item_grid: GridContainer     = $MainVBox/ResultPanel/ResultVBox/ItemGrid
@onready var collect_btn: Button          = $MainVBox/ResultPanel/ResultVBox/CollectBtn
@onready var back_btn: Button             = $MainVBox/BackButton

# ── Estado ────────────────────────────────────────────────────
enum State { IDLE, ANIMATING, REWARD }
var _state := State.IDLE
var _pending_dust: int = 0
var _pending_rarity: Rarity = Rarity.COMMON
var _pull_count: int = 1
var _pending_items: Array[Dictionary] = []

func _ready() -> void:
	_refresh_counters()
	result_panel.hide()
	status_label.text = ""
	tesseract.animation_finished.connect(_on_tesseract_done)
	tesseract.lock_in_triggered.connect(_on_lock_in_triggered)
	tesseract.luck_bonus_applied.connect(_on_luck_bonus)
	ProfileManager.dust_changed.connect(_on_dust_changed)
	_update_buttons()
	if pull_victory_btn:
		pull_victory_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _state == State.IDLE:
		_on_back_button_pressed()

func _process(_delta: float) -> void:
	if _state == State.ANIMATING:
		status_label.text = tesseract.status_msg
	elif _state == State.IDLE:
		status_label.text = "¡PRESIONÁ TIRAR PARA INICIAR EL TESERACTO!"

func _refresh_counters() -> void:
	victory_label.text = str(ProfileManager.get_victory_dust())
	defeat_label.text  = str(ProfileManager.get_defeat_dust())
	if victory_circles: victory_circles.queue_redraw()
	if defeat_circles:  defeat_circles.queue_redraw()

func _on_dust_changed(_v: int, _d: int) -> void:
	_refresh_counters()
	_update_buttons()

func _update_buttons() -> void:
	var can_act := _state == State.IDLE
	pull_victory_btn.disabled    = not ProfileManager.current_profile.can_pull_victory() or not can_act
	pull_victory_10_btn.disabled = not ProfileManager.current_profile.can_pull_victory_10() or not can_act
	pull_defeat_btn.disabled     = not ProfileManager.current_profile.can_pull_defeat() or not can_act
	pull_defeat_10_btn.disabled  = not ProfileManager.current_profile.can_pull_defeat_10() or not can_act
	skip_btn.visible             = _state == State.ANIMATING

# ── Tirada (1x o 10x independientes) ──────────────────────────
func _start_pull(pull_count: int = 1) -> void:
	_pull_count = pull_count
	_state = State.ANIMATING
	result_panel.hide()
	_update_buttons()

	_pending_items.clear()
	_pending_rarity = Rarity.COMMON
	_pending_dust   = 0

	# Tiradas 100% independientes
	for i in range(_pull_count):
		var r := _roll_rarity()
		var d := randi_range(RARITY_DUST[r][0], RARITY_DUST[r][1])
		_pending_items.append({ "rarity": r, "dust": d })
		if r > _pending_rarity:
			_pending_rarity = r
		_pending_dust += d

	# El color del tesseracto muestra la mayor rareza obtenida en el conjunto
	tesseract.start(RARITY_COLORS[_pending_rarity], RARITY_INNER[_pending_rarity])

func _roll_rarity() -> Rarity:
	var roll: int = randi_range(1, 100)
	for i in range(RARITY_WEIGHTS.size()):
		if roll <= RARITY_WEIGHTS[i]:
			return i as Rarity
	return Rarity.COMMON

func _on_lock_in_triggered() -> void:
	Events.camera_shake_requested.emit(8.0)

func _on_luck_bonus(bonus_tiers: int) -> void:
	# El bonus de los minijuegos sube +1 nivel de rareza a CADA uno de los items del pull
	_pending_rarity = Rarity.COMMON
	_pending_dust   = 0

	for item in _pending_items:
		var new_r: Rarity = mini(item["rarity"] + bonus_tiers, Rarity.LEGENDARY) as Rarity
		item["rarity"] = new_r
		item["dust"]   = randi_range(RARITY_DUST[new_r][0], RARITY_DUST[new_r][1])
		if new_r > _pending_rarity:
			_pending_rarity = new_r
		_pending_dust += item["dust"]

	tesseract.target_outer_color = RARITY_COLORS[_pending_rarity]
	tesseract.target_inner_color = RARITY_INNER[_pending_rarity]

func _on_tesseract_done() -> void:
	_state = State.REWARD
	status_label.text = "¡RECOMPENSA REVELADA!"
	
	# Limpiar grid anterior
	for c in item_grid.get_children():
		c.queue_free()

	if _pull_count > 1:
		rarity_label.text = "¡10 TIRADAS INDEPENDIENTES!"
		rarity_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		reward_label.text = "+%d ✦ Polvo de Victoria Total" % _pending_dust
		
		# Mostrar el desglose individual de cada item
		for idx in range(_pending_items.size()):
			var item: Dictionary = _pending_items[idx]
			var lbl := Label.new()
			lbl.text = "#%d: %s (+%d ✦)" % [idx + 1, RARITY_NAMES[item["rarity"]], item["dust"]]
			lbl.add_theme_color_override("font_color", RARITY_COLORS[item["rarity"]])
			lbl.add_theme_font_size_override("font_size", 13)
			item_grid.add_child(lbl)
		item_grid.show()
	else:
		item_grid.hide()
		rarity_label.text = RARITY_NAMES[_pending_rarity]
		rarity_label.add_theme_color_override("font_color", RARITY_COLORS[_pending_rarity])
		reward_label.text = "+%d ✦ Polvo de Victoria" % _pending_dust

	result_panel.show()
	_update_buttons()
	if collect_btn:
		collect_btn.grab_focus()

# ── Handlers de Botones ───────────────────────────────────────
func _on_pull_victory_btn_pressed() -> void:
	if ProfileManager.try_pull_victory():
		_start_pull(1)

func _on_pull_victory_10_btn_pressed() -> void:
	if ProfileManager.try_pull_victory_10():
		_start_pull(10)

func _on_pull_defeat_btn_pressed() -> void:
	if ProfileManager.try_pull_defeat():
		_start_pull(1)

func _on_pull_defeat_10_btn_pressed() -> void:
	if ProfileManager.try_pull_defeat_10():
		_start_pull(10)

func _on_skip_btn_pressed() -> void:
	tesseract.skip_to_final()

func _on_collect_btn_pressed() -> void:
	ProfileManager.add_victory_dust(_pending_dust)
	tesseract.stop()
	result_panel.hide()
	_state = State.IDLE
	_update_buttons()
	if pull_victory_btn:
		pull_victory_btn.grab_focus()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
