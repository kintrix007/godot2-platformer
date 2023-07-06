extends KinematicBody2D

var gravity = Vector2(0, 1500)
var jump_strength = 600
var max_speed = 300
var ground_speed = 2000
var ground_friction = 0.01
var air_speed = 1200
var air_friction = 0.2

var vel = Vector2(0, 0)
var is_hitting_ground = false
var hitting_wall = 0
var time_airborne = 0.0
var prev_jump_key = true

func _ready():
	get_node("Timer").connect("timeout", self, "_timeout")

func _timeout():
	set_process(true)

func _process(delta):
	var dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	var is_grounded = time_airborne <= 0.1
	
	var jump_key = Input.is_action_pressed("jump")
	if is_grounded and jump_key and not prev_jump_key:
		vel.y = -jump_strength
	prev_jump_key = jump_key
	
	var friction
	if is_grounded:
		vel.x += dir * ground_speed * delta
		friction = ground_friction
		if sign(vel.x) != sign(dir):
			vel.x *= pow(friction, delta)
	else:
		vel.x += dir * air_speed * delta
		friction = air_friction
	
	vel.x *= pow(friction, delta)
	vel.x = clamp(vel.x, -max_speed, max_speed)
	vel += gravity * delta
	
	var attempted_move = vel * delta
	var remaining = self.move(attempted_move)
	var actual_move = attempted_move - remaining
	
#	print("rem: ", remaining)
	is_hitting_ground = false
	hitting_wall = 0
	var i = 0
	while self.is_colliding() and remaining.length_squared() >= 0.1 and i < 5:
		var normal = self.get_collision_normal()
		
		is_hitting_ground = is_hitting_ground or normal.dot(Vector2(0, -1)) >= 0.7
		if normal.dot(Vector2(-1, 0)) >= 0.7:
			hitting_wall = 1
		if normal.dot(Vector2(1, 0)) >= 0.7:
			hitting_wall = -1
		
		var tangent = -normal.tangent() # Get the tangent 90 degrees clockwise
		remaining = tangent * remaining.dot(tangent)
		var new_remaining = self.move(remaining)
		actual_move += remaining - new_remaining
		remaining = new_remaining
		i += 1
	
#	print("vel: ", vel, ",\tactual move: ", actual_move)
	vel = actual_move / delta
	
	if is_hitting_ground:
		time_airborne = 0.0
	else:
		time_airborne += delta
