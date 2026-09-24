extends Control

@onready var dice = $DiceSprite
@onready var state = $GameState

@onready var die_label = $DieLabel
@onready var game_log = $GameLog
@onready var turn_label = $TurnLabel
@onready var roll_value_label = $RollValueLabel
@onready var winner_label = $WinnerLabel
@onready var roll_button = $RollButton
@onready var reset_button = $ResetButton
@onready var roll_sprite: Sprite2D = $RollButtonSprite
@onready var you_lose = $LoseSound
@onready var you_win = $VictorySound
@onready var winner_works = $WinnerSprite
@onready var loser_skull = $LoserSkull
@onready var coop_box = $UI/Coop/CoopContainer
@onready var session_label = $UI/SessionInfoVBox/SessionNotification
@onready var session_box = $UI/SessionInfoVBox
@onready var host_button = $UI/Coop/CoopContainer/Host
@onready var join_code = $UI/JoinCodeNode/VBoxContainer/JoinCode
@onready var join_text = $UI/JoinCodeNode/VBoxContainer/JoinBox

var rolling_visual := false
var displayed_roll := 0

## Co-op Multiplayer variable
var peer = null
var _current_code: String = ""
const CODE_ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const MAX_PLAYERS  := 2

const BUTTON_TOTAL_FRAMES := 24
const BUTTON_FPS := 15.0

const FIREWORK_TOTAL_FRAMES := 30    # 6 x 5 sprite sheet
const FIREWORK_FPS := 20.0

var firework_timer := 0.0
var fireworks_playing := false

var button_frame_timer := 0.0
var button_animating := true

func _ready():

	randomize()

	dice.roll_finished.connect(_on_roll_finished)
	roll_button.pressed.connect(_on_roll_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	reset_button.hide()
	winner_label.hide()
	winner_works.hide()
	loser_skull.hide()
	coop_box.show()
	join_text.hide()
	
	update_turn()


func _on_roll_pressed():

	if state.game_over:
		return

	roll_button.disabled = true
	set_roll_button_enabled(false)
	rolling_visual = true
	coop_box.visible = false
	session_box.hide()

	dice.roll()
	
func set_roll_button_enabled(enabled: bool) -> void:
	roll_button.disabled = !enabled

	var target_color := Color.WHITE if enabled else Color(0.45, 0.45, 0.45, 1.0)

	create_tween().tween_property(
		roll_sprite,
		"modulate",
		target_color,
		0.15
	)
	
	
func _on_roll_finished():

	rolling_visual = false

	var die_used = state.current_max
	var roll = randi_range(1, die_used)

	roll_value_label.text = str(roll)

	state.history.append(
		"Player %d rolled %d on d%d"
		% [state.current_player, roll, die_used]
	)
	while state.history.size() > 7:
		state.history.remove_at(0)

	game_log.text = "\n".join(state.history)

	if roll == 1:

		var lose_time = float(you_lose.stream.get_length())

		you_lose.play()

	# Start flashing the skull while the sound plays.
		flash_loser_skull(lose_time)

	# Wait for the sound to finish.
		await get_tree().create_timer(lose_time + 0.25).timeout

		loser_skull.hide()

	# Start fireworks.
		winner_works.show()
		fireworks_playing = true

		you_win.play()

		state.game_over = true

		var winner = 2 if state.current_player == 1 else 1

		winner_label.text = "%s Wins!" % state.get_player_name(winner)
		winner_label.modulate = state.get_player_color(winner)
		
		game_log.text = "\n".join(state.history)

		winner_label.show()
		reset_button.show()
		roll_button.hide()
		roll_sprite.hide()

		return

	state.current_max = roll

	state.swap_player()

	update_turn()

	roll_button.disabled = false
	set_roll_button_enabled(true)
	roll_sprite.visible = true
	
	
func update_turn():
	turn_label.text = state.get_player_name(state.current_player)
	turn_label.modulate = state.get_player_color(state.current_player)
	die_label.text = "d%d" % state.current_max

func _on_reset_pressed():

	state.reset()

	roll_value_label.text = ""
	
	winner_label.hide()
	reset_button.hide()
	roll_button.show()
	session_box.show()
	coop_box.show()
	
	roll_sprite.visible = true
	loser_skull.hide()

	fireworks_playing = false
	winner_works.hide()
	winner_works.frame = 0

	firework_timer = 0.0
	roll_button.disabled = false

	
	update_turn()
	
	game_log.text = ""
	die_label.text = "d1000"
	
	
func flash_loser_skull(duration: float) -> void:

	loser_skull.show()

	var elapsed := 0.0

	while elapsed < duration:

		await get_tree().create_timer(0.5).timeout

		loser_skull.visible = !loser_skull.visible

		elapsed += 0.5

	loser_skull.hide()

func _process(delta):
	if rolling_visual:
		displayed_roll = randi_range(1, state.current_max)
		roll_value_label.text = str(displayed_roll)

	if button_animating:
		button_frame_timer += delta

		if button_frame_timer >= 1.0 / BUTTON_FPS:
			button_frame_timer -= 1.0 / BUTTON_FPS

			roll_sprite.frame += 1

			if roll_sprite.frame >= BUTTON_TOTAL_FRAMES:
				roll_sprite.frame = 0
	if fireworks_playing:

		firework_timer += delta

	if firework_timer >= 1.0 / FIREWORK_FPS:

		firework_timer -= 1.0 / FIREWORK_FPS

		winner_works.frame = (winner_works.frame + 1) % FIREWORK_TOTAL_FRAMES

# MULTIPLAYER - COOP SERVER HOST/JOIN
	## Host a server
func _on_host_pressed() -> void:
	
	multiplayer.multiplayer_peer = peer 

	multiplayer.peer_connected.connect(
		func(pid):
			print(str(pid) + " has joined the game")
	)
	multiplayer.peer_disconnected.connect(
		func(pid):
			print(str(pid) + " has left the game")
	)
	## function to hide co-op vbox unless there is an error
	var error = peer.create_server(55112)
	
	if error == OK:
		multiplayer.multiplayer_peer = peer
		# Hide the VBoxContainer when server is created successfully
		coop_box.hide()
		session_box.show()
		generate_random_code()
		join_code.show()
pass
#Generate code on host
func generate_random_code(code_len: int = 6) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := ""
	for i in range(code_len):
		s += CODE_ALPHABET[rng.randi_range(0, CODE_ALPHABET.length() - 1)]
	return s
pass
func begin_random_lobby(code_len: int = 6) -> String:
	# call this *after* host_lobby() succeeds
	_current_code = generate_random_code(code_len)
	emit_signal("code_generated", _current_code)
	return _current_code
pass
func get_current_code() -> String:
	return _current_code

## Join a server
func _on_join_pressed() -> void:
	peer.create_client("localhost", 55112)
	multiplayer.multiplayer_peer = peer
	var res = peer.create_client("localhost", 55112)
	
	if host_button.visible == true:
		host_button.hide()
		
	else:
		join_text.show()
		

	if res == OK:
		print("Connected")
	else:
		print("Failed: ", res)
		
		multiplayer.multiplayer_peer = peer
		
	pass
