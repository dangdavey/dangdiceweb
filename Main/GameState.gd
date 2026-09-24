extends Node

var current_max := 1000
var current_player := 1
var game_over := false
var displayed_roll := 0
var rolling_visual = false
var history: Array[String] = []
var oneColor = Color(0.8,0.6,0.1) # Player One
var twoColor = Color(0.3,0.6,.6) # Player Two

const PLAYER_NAMES := [
	"Player One",
	"Player Two"
]

const PLAYER_COLORS := [
	Color(0.8,0.6,0.1), # Player One
	Color(0.3,0.6,.6)  # Player Two
]

func get_player_name(player: int) -> String:
	return PLAYER_NAMES[player - 1]

func get_player_color(player: int) -> Color:
	match player:
		1:
			return oneColor
		2:
			return twoColor
		_:
			return Color.WHITE

func reset():
	current_max = 1000
	current_player = 1
	game_over = false
	history.clear()

func swap_player():
	current_player = 2 if current_player == 1 else 1
