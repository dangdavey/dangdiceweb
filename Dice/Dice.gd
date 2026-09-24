extends Sprite2D

signal roll_finished

const TOTAL_FRAMES := 45
const ANIMATION_FPS := 70.0
const ROLL_DURATION := 2.0

var rolling := false
var frame_timer := 0.0

const SPIN_SPEED := TAU * 1.5

func _process(delta):
	if !rolling:
		return

	frame_timer += delta

	if frame_timer >= 1.0 / ANIMATION_FPS:
		frame_timer -= 1.0 / ANIMATION_FPS
		frame = (frame + 1) % TOTAL_FRAMES


func roll():

	frame = randi() % TOTAL_FRAMES

	if rolling:
		return

	rolling = true
	frame = 0
	frame_timer = 0.0

	await get_tree().create_timer(ROLL_DURATION).timeout

	rolling = false
	frame = 3

	roll_finished.emit()
