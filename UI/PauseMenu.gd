extends ColorRect

var paused = false setget set_paused

func set_paused(value):
	paused= value
	get_tree().paused = paused 
	#get tree paused est un truc du système
	visible = paused 
	#rends le canvas de pause (pause menu) visible ou pas, paused est true ou false
	
# warning-ignore:unused_argument
func _process(delta):
	if Input.is_action_just_pressed("pause"):
		self.paused = !paused

func _on_Resume_pressed():
	self.paused = false


func _on_Quit_pressed():
	get_tree().quit()
