extends Sprite

export var item_ob = "HP"
export var value = 50

signal item_picked(pos)

func _ready():
	pass

func _on_check_body_entered(body):
	queue_free()
	if is_network_master():
		if body.has_method("get_item"):
			emit_signal("item_picked", position)
			body.rpc("get_item", item_ob, value)
