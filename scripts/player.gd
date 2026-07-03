# player.gd
# Side-view player character for the dinner-room exploration scene.
extends CharacterBody2D

@export var speed: float = 250.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1200.0

var _active: bool = true

func _ready():
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not _active:
		velocity = Vector2.ZERO
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Walk
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		# Flip the whole character visual so left/right is readable
		var new_scale_x = sign(direction) * abs(scale.x)
		if new_scale_x != 0:
			scale.x = new_scale_x
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

func set_active(active: bool):
	_active = active
	if not active:
		velocity = Vector2.ZERO

func is_active() -> bool:
	return _active
