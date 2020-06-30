extends RigidBody2D

var from_player
var value = 1

func _on_bombHit_body_entered(body):
	queue_free()
	if is_network_master():
		if body.has_method("dmg_taken"):
			body.rpc("dmg_taken", from_player, value)
		elif body.has_method("drop_open"):
			body.rpc("drop_open")
	#print(body.name)
