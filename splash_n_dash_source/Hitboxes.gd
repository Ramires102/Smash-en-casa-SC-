extends Area2D

var hitSprite = preload("res://ASSETS/Effects/Hit.tscn")
var slashSprite = preload("res://ASSETS/Effects/Slash.tscn")
var explodeSprite = preload("res://ASSETS/Effects/Explosion.tscn")

var parent = get_parent()
export var width = 300
export var height = 400
export var damage = 50
export var angle = 90
export var base_kb = 100
export var kb_scaling = 2
export var duration = 1500
export var hitlag_modifier = 1
export var type = "normal"
export var angle_flipper = 0
onready var hitbox = get_node("Hitbox_Shape")
onready var timer = get_node("Timer")
onready var path = Path2D.new().get_curve()
onready var parentState = get_parent().selfState
var knockbackVal
var framez = 0.0
var player_list = []
var points = []


func set_parameters(w, h, d, a, b_kb, kb_s, dur, t, p, af, hit, parent = get_parent()):
	self.position = Vector2(0, 0)
	player_list.append(parent)
	player_list.append(self)
	width = w
	height = h
	damage = d
	angle = a
	base_kb = b_kb
	kb_scaling = kb_s
	duration = dur
	type = t
	self.position = p
	hitlag_modifier = hit
	angle_flipper = af
	update_extents()
	if type == "Flip":
		connect("area_entered", self, "Flipbox_Collide")
	else:
		connect("area_entered", self, "Hitbox_Collide")
	set_physics_process(true)

func Hitbox_Collide(body):
	body = body.get_parent()
	if not (body in player_list):
		var charstate
		charstate = body.get_node("StateMachine")
		weight = body.weight
		body.percentage += damage
		knockbackVal = knockback(body.percentage, damage, weight, kb_scaling, base_kb, 1)
		s_angle(body)
		effect(type)
		angle_flipper(body)
		body.knockback = knockbackVal
		body.hitstun = getHitstun(knockbackVal / 0.3)
		get_parent().connected = true
		body.frame()
		charstate.state = charstate.states.HITSTUN
		Engine.time_scale = hitlag_modifier
		yield(get_tree().create_timer(((hitlag(damage, hitlag_modifier)) / 60) * hitlag_modifier), "timeout")
		print("freeeeeze")
		Engine.time_scale = 1


func Flipbox_Collide(body):
	body = body.get_parent()
	if not (body in player_list):
		var charstate
		charstate = body.get_node("StateMachine")
		weight = body.weight
		body.percentage += damage
		if body.direction() == 1:
			body.turn(true)
		else:
			body.turn(false)
		body.velocity.x = body.velocity.x * - 1

func _ready():
	hitbox.shape = RectangleShape2D.new()
	set_physics_process(false)
	pass

func hitlag(d, hit):
	damage = d
	hitlag_modifier = hit
	return floor((((floor(d) * 0.65) + 6) / hit))

func update_extents():
	hitbox.shape.extents = Vector2(width, height)
	
const angleConversion = PI / 180
func getHitstun(knockback):
	return floor(knockback * 0.4);

func getHorizontalHitStun(knockback):
	return knockback * 0.4

func getVerticalHitStun(knockback):
	return knockback * 0.03

func getHorizontalDecay(angle):
	var decay = 0.051 * cos(angle * angleConversion)
	decay = round(decay * 100000) / 100000
	decay = decay * 1000
	return decay

func getVerticalDecay(angle):
	var decay = 0.051 * sin(angle * angleConversion)
	decay = round(decay * 100000) / 100000
	decay = decay * 1000
	return abs(decay)

func getHorizontalVelocity(knockback, angle):
	
	
	var initialVelocity = knockback * 30;
	var horizontalAngle = cos(angle * angleConversion);
	var horizontalVelocity = initialVelocity * horizontalAngle;
	horizontalVelocity = round(horizontalVelocity * 100000) / 100000;
	return horizontalVelocity;

func getVerticalVelocity(knockback, angle):
	
	
	var initialVelocity = knockback * 30;
	var verticalAngle = sin(angle * angleConversion);
	var verticalVelocity = initialVelocity * verticalAngle;
	verticalVelocity = round(verticalVelocity * 100000) / 100000;
	return verticalVelocity


func _physics_process(delta):
	if framez < duration:
		framez += 1
	elif framez == duration:
	
		Engine.time_scale = 1
		queue_free()
		return
	if get_parent().selfState != parentState:
		Engine.time_scale = 1
		queue_free()
		return

export var percentage = 0
export var weight = 100
export var base_knockback = 40
export var ratio = 1

func effect(type):
	match type:
		"normal":
			var normal_1 = hitSprite.instance()
			normal_1.number = 3
			
			get_tree().current_scene.add_child(normal_1)
			normal_1.global_position = self.global_position
		"slash":
			var normal_1 = slashSprite.instance()
			normal_1.number = 2
			
			get_tree().current_scene.add_child(normal_1)
			normal_1.global_position = self.global_position
		"explode":
			var normal_1 = explodeSprite.instance()
			normal_1.number = 1
			
			get_tree().current_scene.add_child(normal_1)
			normal_1.global_position = self.global_position

func knockback(p, d, w, ks, bk, r):
	percentage = p
	damage = d
	weight = w
	kb_scaling = ks
	base_kb = bk
	ratio = r
	
	
	
	return ((kb_scaling / 100) * ((((14 * (percentage + damage) * (damage + 2))) / weight + 100) + 18) + base_kb) / 10

func s_angle(body):
		if angle == 361:
			if knockbackVal > 28:
				if body.in_air == true:
					angle = 40
				else:
					angle = 38
			else:
				if body.in_air == true:
					angle = 40
				else:
					angle = 25
		elif angle == - 181:
			if knockbackVal > 28:
				if body.in_air == true:
					angle = ( - 40) + 180
				else:
					angle = ( - 38) + 180
			else:
				if body.in_air == true:
					angle = ( - 40) + 180
				else:
					angle = ( - 25) + 180

func destroy():
	queue_free()

func angle_flipper(body):
	var xangle
	if get_parent().direction() == - 1:
		xangle = ( - (((body.global_position.angle_to_point(get_parent().global_position)) * 180) / PI))
	else:
		xangle = (((body.global_position.angle_to_point(get_parent().global_position)) * 180) / PI)
	match angle_flipper:
		0:
			body.velocity.x = (getHorizontalVelocity(knockbackVal, - angle))
			body.velocity.y = (getVerticalVelocity(knockbackVal, - angle))
			body.hdecay = (getHorizontalDecay( - angle))
			body.vdecay = (getVerticalDecay(angle))
		1:
			if get_parent().direction() == - 1:
				xangle = - (((self.global_position.angle_to_point(body.get_parent().global_position)) * 180) / PI)
			else:
				xangle = (((self.global_position.angle_to_point(body.get_parent().global_position)) * 180) / PI)
			body.velocity.x = ((getHorizontalVelocity(knockbackVal, xangle + 180)))
			body.velocity.y = ((getVerticalVelocity(knockbackVal, - xangle)))
			body.hdecay = (getHorizontalDecay(angle + 180))
			body.vdecay = (getVerticalDecay(xangle))
			
			
		2:
			if get_parent().direction() == - 1:
				xangle = - (((body.get_parent().global_position.angle_to_point(self.global_position)) * 180) / PI)
			else:
				xangle = (((body.get_parent().global_position.angle_to_point(self.global_position)) * 180) / PI)
			body.velocity.x = ((getHorizontalVelocity(knockbackVal, - xangle + 180)))
			body.velocity.y = ((getVerticalVelocity(knockbackVal, - xangle)))
			body.hdecay = (getHorizontalDecay(xangle + 180))
			body.vdecay = (getVerticalDecay(xangle))
			
			
		3:
			if get_parent().direction() == - 1:
				xangle = ( - (((body.global_position.angle_to_point(self.global_position)) * 180) / PI)) + 180
			else:
				xangle = (((body.global_position.angle_to_point(self.global_position)) * 180) / PI)
			body.velocity.x = (getHorizontalVelocity(knockbackVal, xangle))
			body.velocity.y = (getVerticalVelocity(knockbackVal, - angle))
			body.hdecay = (getHorizontalDecay(xangle))
			body.vdecay = (getVerticalDecay(angle))
		4:
			if get_parent().direction() == - 1:
				xangle = - (((body.global_position.angle_to_point(self.global_position)) * 180) / PI) + 180
			else:
				xangle = (((body.global_position.angle_to_point(self.global_position)) * 180) / PI)
			body.velocity.x = (getHorizontalVelocity(knockbackVal, - xangle * 180))
			body.velocity.y = (getVerticalVelocity(knockbackVal, - angle))
			body.hdecay = (getHorizontalDecay(angle))
			body.vdecay = (getVerticalDecay(angle))
		5:
			body.velocity.x = (getHorizontalVelocity(knockbackVal, angle + 180))
			body.velocity.y = (getVerticalVelocity(knockbackVal, - angle))
			body.hdecay = (getHorizontalDecay(angle + 180))
			body.vdecay = (getVerticalDecay(angle))
		6:
			body.velocity.x = (getHorizontalVelocity((knockbackVal), xangle))
			body.velocity.y = (getVerticalVelocity(knockbackVal, - angle))
			body.hdecay = (getHorizontalDecay(xangle))
			body.vdecay = (getVerticalDecay(angle))
			
		7:
			body.velocity.x = (getHorizontalVelocity(knockbackVal, - xangle + 180))
			body.velocity.y = (getVerticalVelocity(knockbackVal, - angle))
			body.hdecay = (getHorizontalDecay(angle))
			body.vdecay = (getVerticalDecay(angle))
			

	

	

	

	

	

	

	

	

	

	
