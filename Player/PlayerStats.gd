extends Resource

class_name PlayerStats

var max_health = 4
var health = max_health setget set_health

signal player_died
signal health_changed

func set_health(value):
	if value < health: #donc on prend des dégâts
		Events.emit_signal("add_screenshake", 0.25,0.5)
	health = clamp(value, 0, max_health)
	emit_signal("health_changed", health)
	if health == 0:
		emit_signal("player_died")
