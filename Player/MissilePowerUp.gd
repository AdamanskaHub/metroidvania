extends PowerUp


func _pickup():
	PlayerStats.missile_unlocked = true
	queue_free()
