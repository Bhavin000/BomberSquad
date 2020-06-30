extends KinematicBody2D

export var PLAYER_NAME = "player"

onready var bomb = preload("res://scenes/gameScenes/character/characterAssets/bomb.tscn")

puppet var move = Vector2()
puppet var pos = Vector2()

var healthbar
const max_health = 100

const GRAVITY = 30
const JUMP = 600
var move_speed = 150
var motion = Vector2()
const boolet_speed = 1000
var boolet_throw = true
const boolet_offset = 48
var boolet_idx = 0
var gun_dps

var hit_anim = false

puppet var m_dir = ""
var dir = ""

var _gun_name
var crnt_gun
var boolet_dmg

var jumppad = false

func _ready():
	healthbar = max_health
	_gun_name = "pistol"
	crnt_gun = Globals._gun_info[_gun_name]["frame"]
	boolet_dmg = Globals._gun_info[_gun_name]["dmg"]
	gun_dps = Globals._gun_info[_gun_name]["fire_rate"]
	pos = position
	
sync func boolet_hit(poss, by_who, bomb_name, _dir):
	var b = bomb.instance()
	b.set_name(bomb_name)
	b.set_linear_velocity(_dir * boolet_speed)
	b.position = poss
	b.from_player = by_who
	b.value = boolet_dmg
	hand_anim(b, _dir)

func hand_anim(b,_dir):
	if _dir == Vector2.RIGHT and motion.x >= 0:
		$hand.frame = crnt_gun[0]
		$hand.rotation_degrees = 0
		get_parent().add_child(b)
	elif _dir == Vector2.LEFT and motion.x <= 0:
		$hand.frame = crnt_gun[1]
		$hand.rotation_degrees = 0
		get_parent().add_child(b)
	elif _dir == Vector2.UP:
		if dir == "right":
			$hand.frame = crnt_gun[0]
			$hand.offset.x = 3.5
			$hand.position.x = -5
			$hand.rotation_degrees = -90
		elif dir == "left":
			$hand.frame = crnt_gun[1]
			$hand.offset.x = -3.5
			$hand.position.x = 5
			$hand.rotation_degrees = 90
		get_parent().add_child(b)
	elif _dir == Vector2.DOWN:
		if dir == "right":
			$hand.frame = crnt_gun[0]
			$hand.offset.x = 3.5
			$hand.position.x = -5
			$hand.rotation_degrees = 90
		elif dir == "left":
			$hand.frame = crnt_gun[1]
			$hand.offset.x = -3.5
			$hand.position.x = 5
			$hand.rotation_degrees = -90
		get_parent().add_child(b)

sync func steady_hand_anim():
	if dir == "right":
		$hand.frame = crnt_gun[0]
		$hand.rotation_degrees = 0
	elif dir == "left":
		$hand.frame = crnt_gun[1]
		$hand.rotation_degrees = 0

func _physics_process(delta):
	_move()
	_anim()

func _move():
	if not is_on_floor():
		motion.y += GRAVITY
	motion.x = 0
	
	if is_network_master():
		if Input.is_action_just_pressed("jump") and is_on_floor():
			motion.y = -JUMP
		
		motion.x = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * move_speed
		
		if jumppad:
			motion.y = -JUMP * 1.8
		
		_action()
		rset("m_dir", dir)
		
		rset("move", motion)
		rset_unreliable("pos", position)
	else:
		motion = move
		position = pos
		dir = m_dir
	
	if not is_network_master():
		pos = position
	
	motion = move_and_slide(motion,Vector2.UP)

func _anim():
	if motion.x > 0:
		dir = "right"
		$hand.frame = crnt_gun[0]
		if is_on_floor():
			$AnimationPlayer.play("right_idle")
		else:
			if motion.y <= 0:
				$AnimationPlayer.play("right_jump")
			elif motion.y > 0:
				$AnimationPlayer.play("right_down")
	elif motion.x < 0:
		dir = "left"
		$hand.frame = crnt_gun[1]
		if is_on_floor():
			$AnimationPlayer.play("left_idle")
		else:
			if motion.y <= 0:
				$AnimationPlayer.play("left_jump")
			elif motion.y > 0:
				$AnimationPlayer.play("left_down")
	else:
		if is_on_floor():
			if dir == "right":
				$AnimationPlayer.play("right_idle")
			elif dir == "left":
				$AnimationPlayer.play("left_idle")
		else:
			if dir == "right":
				if motion.y <= 0:
					$AnimationPlayer.play("right_jump")
				elif motion.y > 0:
					$AnimationPlayer.play("right_down")
			elif dir == "left":
				if motion.y <= 0:
					$AnimationPlayer.play("left_jump")
				elif motion.y > 0:
					$AnimationPlayer.play("left_down")

func _action():
	if boolet_throw:
		if Input.is_action_pressed("right"):
			dir = "right"
			var boolet_name = get_name() + str(boolet_idx)
			boolet_idx += 1
			var boolet_pos = position + Vector2(32,0)
			var _dir = Vector2(1, 0)
			rpc("boolet_hit",boolet_pos, get_tree().get_network_unique_id(), boolet_name, _dir)
			boolet_throw = false
			$Timer.wait_time = gun_dps
			$Timer.start()
		elif Input.is_action_pressed("left"):
			dir = "left"
			var boolet_name = get_name() + str(boolet_idx)
			boolet_idx += 1
			var boolet_pos = position + Vector2(-32,0)
			var _dir = Vector2(-1, 0)
			rpc("boolet_hit",boolet_pos, get_tree().get_network_unique_id(), boolet_name, _dir)
			boolet_throw = false
			$Timer.wait_time = gun_dps
			$Timer.start()
		elif Input.is_action_pressed("up"):
			var boolet_name = get_name() + str(boolet_idx)
			boolet_idx += 1
			var boolet_pos = position + Vector2(0, -32)
			var _dir = Vector2(0, -1)
			rpc("boolet_hit",boolet_pos, get_tree().get_network_unique_id(), boolet_name, _dir)
			boolet_throw = false
			$Timer.wait_time = gun_dps
			$Timer.start()
		elif Input.is_action_pressed("down"):
			var boolet_name = get_name() + str(boolet_idx)
			boolet_idx += 1
			var boolet_pos = position + Vector2(0, 32)
			var _dir = Vector2(0, 1)
			rpc("boolet_hit",boolet_pos, get_tree().get_network_unique_id(), boolet_name, _dir)
			boolet_throw = false
			$Timer.wait_time = gun_dps
			$Timer.start()
		else:
			if $hand.rotation_degrees != 0:
				rpc("steady_hand_anim")

func _on_Timer_timeout():
	boolet_throw = true
	$Timer.stop()

sync func dmg_taken(from, dmg):
	healthbar -= dmg
	get_parent().get_parent().get_node("players_info/"+get_name()+"/health_bar").value = healthbar
	if healthbar <= 0:
		var x = int(get_parent().get_parent().get_node("players_info/"+str(from)+"/score").text)
		x += 1
		get_parent().get_parent().get_node("players_info/"+str(from)+"/score").text = str(x)
		self.position = get_parent().get_parent().get_node("position/"+get_name()).position
		healthbar = max_health
		get_parent().get_parent().get_node("players_info/"+get_name()+"/health_bar").value = healthbar

sync func get_item(gun_name):
	_gun_name = gun_name
	crnt_gun = Globals._gun_info[_gun_name]["frame"]
	boolet_dmg = Globals._gun_info[_gun_name]["dmg"]
	gun_dps = Globals._gun_info[_gun_name]["fire_rate"]
	if $hand.rotation_degrees != 0:
		rpc("steady_hand_anim")
	match gun_name:
		"pistol":print(gun_name)
		

func set_player_name(new_name):
	$name.text = new_name

func _on_detector_area_entered(area):
	if area.name == "jumper":
		jumppad = true

func _on_detector_area_exited(area):
	if area.name == "jumper":
		jumppad = false
