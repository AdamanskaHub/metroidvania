extends "res://Projectile.gd"


const BRICK_LAYER = 4
const EnemyDeathEffect = preload("res://Effects/ExplosionEffect.tscn")

func _on_HitBox_body_entered(body):
	print("COLLIDED")
	if body.get_collision_layer_bit(BRICK_LAYER):
		body.queue_free()
		Utils.instance_scene_on_main(EnemyDeathEffect, body.global_position+Vector2(2,2))
	._on_HitBox_body_entered(body) # il fait le check pour brick 
	#puis est rappelé pour faire son taf original dans le truc d'où il est extended
