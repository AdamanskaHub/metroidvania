extends KinematicBody2D

const Dust = preload("res://Effects/DustEffect.tscn")
const WallSlideEffect = preload("res://Effects/WallSlideEffect.tscn")
const PlayerBullet = preload("res://Player/PlayerBullet.tscn")
const JumpEffect = preload("res://Effects/JumpEffect.tscn")

var PlayerStats = ResourceLoader.PlayerStats
var MainInstances = ResourceLoader.MainInstances
# ce qui a accès à maininstance à aussi accès au player

export (int) var ACCELERATION = 512
export (int) var MAX_SPEED = 64
export (float) var FRICTION = 0.25

export (int) var GRAVITY = 200
export (int) var JUMP_FORCE = 128
export (int) var MAX_SLOPE_ANGLE = 46
export (int) var SLIDE_SPEED = 48
export (int) var MAX_SLIDE_SPEED = 128
export (int) var BULLET_SPEED = 250

enum{
	MOVE, WALL_SLIDE
}

var state = MOVE

var invincible = false setget set_invincible
var motion = Vector2.ZERO

var snapVector = Vector2.ZERO
var just_jumped = false
var dbl_jump = true


onready var sprite = $Sprite
onready var spriteAnimator = $SpriteAnimator
onready var coyote = $Coyote
onready var muzzle = $Sprite/PlayerGun/Sprite/Muzzle
onready var gun = $Sprite/PlayerGun
onready var fireBulletTimer = $FireBullet
onready var blinkAnimator= $BlinkAnimator

func set_invincible(value):
	invincible = value
	
func _ready():
	PlayerStats.connect("player_died", self, "_on_died")
	MainInstances.Player = self
	
func _exit_tree():
	MainInstances.Player = null

###### MOUVEMENT ########

func _physics_process(delta):
	just_jumped = false
	
	match state:
		MOVE:
			# PRENDS LA DIRECTION
			var input_vector = get_input_vector()
			
			apply_horizontal_force(input_vector, delta)
			apply_friction(input_vector)
			update_snap_vector()
			apply_gravity(delta)
			jump_check()
			update_animation(input_vector)
			move()
			
			#transition to the wall slide
			wall_slide_check()
		WALL_SLIDE:
			spriteAnimator.play("Slide")
			var wall_axis = get_wall_axis()
			if wall_axis != 0:
				sprite.scale.x = wall_axis
			wall_slide_jump_check(wall_axis)
			wall_slide_fast_slide_check(delta)
			move() # pour motion.x et y
			wall_detach_check(delta, wall_axis)
		
	if Input.is_action_pressed("Fire") and fireBulletTimer.time_left == 0:
		fire_bullet()
	
func fire_bullet():
	var bullet = Utils.instance_scene_on_main(PlayerBullet, muzzle.global_position)
	bullet.velocity = Vector2.RIGHT.rotated(gun.rotation)*BULLET_SPEED
	bullet.velocity.x *= sprite.scale.x # donc * 1 ou -1
	bullet.rotation = bullet.velocity.angle()
	fireBulletTimer.start()
	
func get_input_vector():
	# Get vector input QUELLE TOUCHE
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	# input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	return input_vector

func apply_horizontal_force(input_vector, delta):
	# QUELLE VITESSE
	if input_vector.x != 0:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)
		
func apply_friction(input_vector):
	if input_vector.x == 0 and is_on_floor():
		motion.x = lerp(motion.x, 0, FRICTION)
		
func update_snap_vector():
	if is_on_floor():
		snapVector = Vector2.DOWN
		
func jump_check():
	if is_on_floor() or coyote.time_left >0:
		if Input.is_action_just_pressed("ui_up"):
			Utils.instance_scene_on_main(JumpEffect, global_position)
			motion.y = -JUMP_FORCE
			just_jumped = true
			snapVector= Vector2.ZERO
	else:
#		print("not on floor")
		if Input.is_action_just_released("ui_up") and motion.y < - JUMP_FORCE/2:
			motion.y = -JUMP_FORCE/2
			
		if Input.is_action_just_pressed("ui_up") and dbl_jump==true:
			jump(JUMP_FORCE*.75)
			dbl_jump = false
			
func jump(force):
	Utils.instance_scene_on_main(JumpEffect, global_position)
	motion.y = -force
	snapVector= Vector2.ZERO
	
		
func apply_gravity(delta):
	if not is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE)
		

func move():
	var was_in_air = not is_on_floor()
	var last_motion = motion
	var was_on_floor = is_on_floor()
	
	# move
	motion = move_and_slide_with_snap(motion, snapVector*4, Vector2.UP, true, 4, deg2rad(MAX_SLOPE_ANGLE))
	# comme pas top down, on explique en deuxième où est le plafond
	
	# landing
	if was_in_air and is_on_floor():
		motion.x = last_motion.x	
		Utils.instance_scene_on_main(JumpEffect, global_position)
		dbl_jump = true
	# just left ground
	if was_on_floor and not is_on_floor() and not just_jumped:
		motion.y = 0
		coyote.start()
	

			
func update_animation(input_vector):
	sprite.scale.x = sign(get_local_mouse_position().x)
	if input_vector.x != 0:
		spriteAnimator.play("Run")
		spriteAnimator.playback_speed = input_vector.x * sprite.scale.x
	else:
		spriteAnimator.play("Idle")
		
	if not is_on_floor():
		spriteAnimator.play("Jump")



func create_dust_effect():
	var dust_pos = global_position
	dust_pos.x += rand_range(-4,4)
	Utils.instance_scene_on_main(Dust, dust_pos)
#	var dust = Dust.instance()
#	get_tree().current_scene.add_child(dust)
#	dust.global_position = dust_pos


func _on_HurtBox_hit(damage):
	if not invincible:
		PlayerStats.health -= damage
		blinkAnimator.play("Blink")

func _on_died():
	queue_free()
	
func wall_slide_check():
	if not is_on_floor() and is_on_wall():
		state = WALL_SLIDE
		dbl_jump = true
		create_dust_effect()
		
func get_wall_axis():
	var is_right_wall = test_move(transform, Vector2.RIGHT)
	# true si collision
	var is_left_wall= test_move(transform, Vector2.LEFT)
	return int(is_left_wall) - int(is_right_wall)
	#-1 si mur à gauche, +1 à droite
	
func wall_slide_jump_check(wall_axis):
	if Input.is_action_just_pressed("ui_up"):
		motion.x = wall_axis * MAX_SPEED
		motion.y = -JUMP_FORCE/1.25
		state = MOVE
		Utils.instance_scene_on_main(WallSlideEffect, global_position+ Vector2(0,4))
	
	
func wall_slide_fast_slide_check(delta):
	var max_slide_speed = SLIDE_SPEED
	if Input.is_action_pressed("ui_down"):
		max_slide_speed = MAX_SLIDE_SPEED
	motion.y = min (motion.y + GRAVITY * delta, max_slide_speed)

func wall_detach_check(delta, wall_axis):
	if Input.is_action_just_pressed("ui_right"):
		motion.x = ACCELERATION * delta
		# delta non obligatoire
		state = MOVE
	if Input.is_action_just_pressed("ui_left"):
		motion.x = -ACCELERATION * delta
		state = MOVE
		
	if wall_axis == 0 or is_on_floor():
		state = MOVE




	
	
	
	
	
