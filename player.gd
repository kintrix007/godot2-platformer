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
var time_since_on_wall = 999.0
var wall_direction = 0
var is_hitting_wall = false
var time_airborne = 999.0
var prev_jump_key = true

func _ready():
	get_node("Timer").connect("timeout", self, "_timeout")

func _timeout():
	set_process(true)

func _process(delta):
	var dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	var is_grounded = time_airborne <= 0.1
	var is_on_wall = time_since_on_wall <= 0.5 and abs(vel.x) <= 20.0
	if not is_on_wall:
		wall_direction = 0
		time_since_on_wall = 999
	
	var jump_key = Input.is_action_pressed("jump")
	if is_grounded and jump_key and not prev_jump_key:
		vel.y = -jump_strength
		time_airborne = 999
	
	if is_on_wall and not is_grounded and jump_key and not prev_jump_key:
		vel.y = -jump_strength * 0.6
		vel.x = -wall_direction * 700
	
	var friction
	if is_grounded:
		vel.x += dir * ground_speed * delta
		friction = ground_friction
		if sign(vel.x) != sign(dir):
			vel.x *= pow(friction, delta)
	else:
		if abs(vel.x) <= abs(max_speed):
			vel.x += dir * air_speed * delta
			vel.x = clamp(vel.x, -max_speed, max_speed)
		friction = air_friction
	
	vel.x *= pow(friction, delta)
	vel += gravity * delta
	
	if is_grounded:
		vel.x = clamp(vel.x, -max_speed, max_speed)
	if is_on_wall:
		vel.y = min(vel.y, 100) 
	
	var attempted_move = vel * delta
	var remaining = self.move(attempted_move)
	var actual_move = attempted_move - remaining
	
#	print("rem: ", remaining)
	is_hitting_ground = false
	is_hitting_wall = false
	var i = 0
	while self.is_colliding() and remaining.length_squared() >= 0.1 and i < 5:
		var normal = self.get_collision_normal()
		
		is_hitting_ground = is_hitting_ground or normal.dot(Vector2(0, -1)) >= 0.7
		if wall_direction == 0 and normal.dot(Vector2(-1, 0)) >= 0.7:
			wall_direction = 1
			is_hitting_wall = true
		elif wall_direction == 0 and normal.dot(Vector2(1, 0)) >= 0.7:
			wall_direction = -1
			is_hitting_wall = true
		
		var tangent = normal.tangent() # It does not matter which tangent
		remaining = tangent * remaining.dot(tangent)
		# For some reason it still thinks there is a collision,
		# even if it is parallel...
		var new_remaining = self.move(remaining)
		actual_move += remaining - new_remaining
		remaining = new_remaining
		i += 1
	
#	print("vel: ", vel, ",\tactual move: ", actual_move)
	vel = actual_move / delta
	
	prev_jump_key = jump_key
	if is_hitting_ground:
		time_airborne = 0.0
	else:
		time_airborne += delta
	if is_hitting_wall:
		time_since_on_wall = 0.0
	else:
		time_since_on_wall += delta
