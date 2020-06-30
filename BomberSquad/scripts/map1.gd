extends Node

onready var drop_items = {0:preload("res://scenes/gameScenes/maps/mapAsset/drop_items/drop.tscn")}
var i
var idx
var time = 0
var GAME_TIME = 120

var gun_name = ["pistol","akm","awp"]

func _ready():
	Engine.time_scale = 1
	$timers/drop1.wait_time = 5
	$timers/drop1.start()
	$timers/drop2.wait_time = 5
	$timers/drop2.start()
	$timers/game_time.wait_time = GAME_TIME
	$timers/game_time.start()
	if get_tree().is_network_server():
		rpc("start_sec_timer")
	randomize()

sync func drop1(I, IDX):
	var x = drop_items[I].instance()
	get_node("drop_position").add_child(x)
	x.connect("item_picked", self, "_on_item_picked")
	x.gun_name = gun_name[IDX]
	x.position = $drop_position/pos1.position

sync func drop2(I, IDX):
	var x = drop_items[I].instance()
	get_node("drop_position").add_child(x)
	x.connect("item_picked", self, "_on_item_picked")
	x.gun_name = gun_name[IDX]
	x.position = $drop_position/pos2.position

func _on_item_picked(pos):
	if pos == $drop_position/pos1.position:
		$timers/drop1.wait_time = 10
		$timers/drop1.start()
	if pos == $drop_position/pos2.position:
		$timers/drop2.wait_time = 10
		$timers/drop2.start()

sync func show_lobby():
	Engine.time_scale = 0.1
	$timers/game_time.stop()
	$Control.show()

func _on_lobby_pressed():
	get_tree().get_root().get_node("lobby").show()
	if get_tree().is_network_server():
		get_tree().get_root().get_node("lobby/players/start").disabled = false
	else:
		get_tree().get_root().get_node("lobby/players/ready").disabled = false
	queue_free()

func _on_drop1_timeout():
	if is_network_master():
		i = 0
		idx = randi()%3
		rpc("drop1", i, idx)
	$timers/drop1.stop()

func _on_drop2_timeout():
	if is_network_master():
		i = 0
		idx = randi()%3
		rpc("drop2", i, idx)
	$timers/drop2.stop()

sync func start_sec_timer():
	$timers/secTime.start()
	$global_time/Label.text = str(time)

func _on_secTime_timeout():
	time += 1
	$global_time/Label.text = str(time)

sync func stop_sec_timer():
	time = GAME_TIME
	$global_time/Label.text = str(time)
	$timers/secTime.stop()

func _on_game_time_timeout():
	if get_tree().is_network_server():
		rpc("show_lobby")
		rpc("stop_sec_timer")
