extends Control

var PlayerStats = ResourceLoader.PlayerStats

onready var full = $Full

func _ready():
	PlayerStats.connect("health_changed", self, "_on_health_changed")
	
func _on_health_changed(value):
	full.rect_size.x = value * 5 +1
