extends CharacterBody2D

#variables
var input_vector : Vector2
var dive_direction : float
@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0
@onready var c_timer = $Timers/CoyoteTimer
@onready var d_timer = $Timers/DiveTimer

#exported variables
@export var standing_speed : float
@export var crouching_speed : float
@export var airborne_speed : float
@export var jump_height : float
@export var jump_time_to_peak : float
@export var jump_time_to_descent : float
@export var dive_force : float
@export var wall_descent_speed : float

enum states {
	standing,
	crouching,
	jumping,
	airborne,
	diving,
	wall_sliding,
	wall_jumping
}

#state variables
var current_state : int
var is_crouching : bool
var has_dive_dir : bool
var is_diving : bool
var on_left_wall : bool
var on_right_wall : bool
var wall_jump_dir : int
var is_wall_jumping : bool
var can_jump : bool
var can_dive : bool
var is_facing_right : bool = true

func _process(delta):
	#movement direction
	input_vector = Vector2(
		Input.get_action_raw_strength("Right") - Input.get_action_raw_strength("Left"),
		input_vector.y)

	#inputs
	if is_on_floor():
		is_diving = false
		has_dive_dir = false
		c_timer.start()
		if Input.is_action_just_released("Act"): is_crouching = false
		if Input.is_action_pressed("Act"): is_crouching = true
		if is_crouching == false: current_state = states.standing
		else: current_state = states.crouching
	else:
		if !is_diving:
			current_state = states.airborne
		if Input.is_action_just_pressed("Act") and can_dive:
			current_state = states.diving
			is_diving = true
	if c_timer.time_left <= 0:
		can_jump = false
	else:
		can_jump = true
	if can_jump:
		if Input.is_action_pressed("Jump") and current_state != states.crouching:
			current_state = states.jumping

	if d_timer.is_stopped() and Input.is_action_just_pressed("Act") and !is_on_floor():
		d_timer.start()
	if d_timer.time_left <= 0:
		can_dive = true
	else:
		can_dive = false

	if is_on_wall_only():
		current_state = states.wall_sliding
	if is_on_wall_only() and Input.is_action_just_pressed("Jump"):
		current_state = states.wall_jumping

	ChangeDirection()

	#state logic
	match current_state:
		states.standing:
			is_wall_jumping = false
			input_vector.x = input_vector.x * standing_speed
			input_vector.y = 0
			$StateLabel.text = "standing" #debug

		states.crouching:
			is_wall_jumping = false
			input_vector.x = input_vector.x * crouching_speed
			input_vector.y = 0
			$StateLabel.text = "crouching" #debug

		states.jumping:
			is_wall_jumping = false
			input_vector.x = input_vector.x * standing_speed
			input_vector.y = jump_velocity
			await get_tree().create_timer(0.05).timeout
			current_state = states.airborne

		states.airborne:
			if is_wall_jumping:
				input_vector.x = wall_jump_dir * airborne_speed
			else:
				input_vector.x = input_vector.x * airborne_speed
			input_vector.y += get_gravity() * delta
			$StateLabel.text = "airborne" #debug

		states.diving:
			if not has_dive_dir:
				get_dive_dir()
			input_vector.x = dive_direction * dive_force
			input_vector.y += get_gravity() * delta
			$StateLabel.text = "diving" #debug

		states.wall_sliding:
			is_diving = false
			is_crouching = false
			is_wall_jumping = false
			input_vector.y = wall_descent_speed
			input_vector.x = 0
			$StateLabel.text = "wall sliding" #debug

		states.wall_jumping:
			is_wall_jumping = true
			has_dive_dir = false
			if on_left_wall:
				wall_jump_dir = -1
			if on_right_wall:
				wall_jump_dir = 1
			input_vector.y = jump_velocity
			input_vector.x = wall_jump_dir * airborne_speed 

func get_dive_dir():
	if is_facing_right:
		dive_direction = 1
	else:
		dive_direction = -1
	has_dive_dir = true
func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity
func _physics_process(delta):
	velocity = input_vector
	move_and_slide()

func ChangeDirection():
	if input_vector.x > 0 and is_facing_right == false:
		$Sprite.set_flip_h( false )
		is_facing_right = true
	elif input_vector.x < 0 and is_facing_right == true:
		$Sprite.set_flip_h( true )
		is_facing_right = false


func _on_left_body_entered(body):
	on_right_wall = true
func _on_right_body_entered(body):
	on_left_wall = true

func _on_left_body_exited(body):
	on_right_wall = false
func _on_right_body_exited(body):
	on_left_wall = false
