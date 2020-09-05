extends Node2D


func _ready():
	pass


func _on_DustEffect8_tree_exited():
	queue_free()
