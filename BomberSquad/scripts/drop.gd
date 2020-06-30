extends RigidBody2D

export var item_ob = "HP"
export var value = 50

var gun_name

signal item_picked(pos)

func _ready():
	$drop.visible = true
	$gun.visible = false

sync func drop_open():
	$shape.queue_free()
	$drop.visible = false
	$gun.visible = true
	$gun.frame = Globals._gun_info[gun_name]["frame"][0]

func _on_check_body_entered(body):
	if body.has_method("get_item"):
		queue_free()
	if is_network_master():
		if body.has_method("get_item"):
			emit_signal("item_picked", position)
			body.rpc("get_item", gun_name)
