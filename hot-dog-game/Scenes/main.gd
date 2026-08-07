extends Node2D
## HOT DOG CANNON v8.0 — lose number is FIXED (does not keep changing)
## WASD/Arrows = you + hot dog + bullets
## Space=shoot  R=restart  Enter=achs

const VERSION := "v8.0 - Godot / MakeCode speeds"
const SCREEN := Vector2(960, 540)
const SCALE_X := 6.0
const SCALE_Y := 4.5
const PLAYER_SPEED := Vector2(30.0 * SCALE_X, 30.0 * SCALE_Y)
const DOG_SPEED := Vector2(60.0 * SCALE_X, 100.0 * SCALE_Y)
const BULLET_SPEED := Vector2(100.0 * SCALE_X, 100.0 * SCALE_Y)
const ENEMY_STEP := 1.0 * SCALE_X
const ENEMY_STEP_TIME := 8.0 / 60.0

var player: CharacterBody2D = null
var hotdog: CharacterBody2D = null
var enemy: CharacterBody2D = null
var cannon: Area2D = null
var bullets_root: Node2D = null
var bonus_root: Node2D = null
var score_lbl: Label
var msg_lbl: Label
var hint_lbl: Label

var busy := false
var game_over := false
var starting := true
var start_grace := 1.5
var can_shoot := true
var cannon_alive := true
var cannon_messy := false
var hotdog_plain := false
var shoot_cd := 0.0
var chase_t := 0.0
var yeet_cd := 0.0
var storm_cd := 0.0
var storm_time := 0.0
var bonus_eaten := 0
var enemy_404_lock := false
var event_cd := 8.0
var _404_t := 0.0

var ach := {
	"ate": false, "snipe": false, "yeet": false, "storm": false,
	"plain": false, "nogun": false, "gunbroke": false, "ouch": false,
	"oops": false, "stolen": false, "sticky": false, "all": false
}

func _ready() -> void:
	randomize()
	set_physics_process(false)
	_build_ui()
	await _start_game()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	score_lbl = Label.new()
	score_lbl.position = Vector2(12, 8)
	layer.add_child(score_lbl)
	hint_lbl = Label.new()
	hint_lbl.position = Vector2(12, 510)
	hint_lbl.text = "WASD/Arrows=YOU+DOG+BULLET  Space=Shoot  R=Restart  Enter=Achs"
	layer.add_child(hint_lbl)
	msg_lbl = Label.new()
	msg_lbl.position = Vector2(220, 210)
	msg_lbl.add_theme_font_size_override("font_size", 28)
	layer.add_child(msg_lbl)

func _alive(n: Object) -> bool:
	return n != null and is_instance_valid(n)

func _actors_ready() -> bool:
	return _alive(player) and _alive(hotdog) and _alive(enemy) and _alive(cannon)

func _clear_world() -> void:
	for c in get_children():
		if c is CanvasLayer:
			continue
		c.queue_free()

func _start_game() -> void:
	starting = true
	set_physics_process(false)
	player = null
	hotdog = null
	enemy = null
	cannon = null
	bullets_root = null
	bonus_root = null
	_clear_world()
	await get_tree().process_frame
	await get_tree().process_frame

	busy = false
	game_over = false
	start_grace = 1.5
	can_shoot = true
	cannon_alive = true
	cannon_messy = false
	hotdog_plain = false
	shoot_cd = 0.0
	chase_t = 0.0
	yeet_cd = 0.0
	storm_cd = 0.0
	storm_time = 0.0
	bonus_eaten = 0
	enemy_404_lock = false
	event_cd = randf_range(8.0, 14.0)
	_404_t = 0.0
	if _alive(msg_lbl):
		msg_lbl.text = ""
		msg_lbl.modulate = Color.WHITE

	bullets_root = Node2D.new()
	add_child(bullets_root)
	bonus_root = Node2D.new()
	add_child(bonus_root)

	player = _body(Vector2(32, 32), Vector2(40 * SCALE_X, 90 * SCALE_Y), "player", _tex_player())
	hotdog = _body(Vector2(48, 24), Vector2(40 * SCALE_X, 30 * SCALE_Y), "hotdog", _tex_hotdog(false))
	cannon = _area(Vector2(40, 40), Vector2(120 * SCALE_X, 80 * SCALE_Y), "cannon", _tex_cannon(false))
	enemy = _body(Vector2(32, 32), Vector2(randf_range(0, 160) * SCALE_X, randf_range(0, 120) * SCALE_Y), "enemy", _tex_enemy())

	starting = false
	set_physics_process(true)
	_say(player, "Go!")
	_say(cannon, "READY!")
	_hud()
	msg_lbl.text = VERSION
	get_tree().create_timer(1.2).timeout.connect(func ():
		if not game_over and _alive(msg_lbl) and msg_lbl.text == VERSION:
			msg_lbl.text = ""
	)

func _body(size: Vector2, pos: Vector2, group: String, tex: Texture2D) -> CharacterBody2D:
	var b := CharacterBody2D.new()
	b.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	b.position = pos
	b.add_to_group(group)
	add_child(b)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(3, 3)
	b.add_child(spr)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var lab := Label.new()
	lab.name = "Say"
	lab.position = Vector2(-48, -52)
	b.add_child(lab)
	return b

func _area(size: Vector2, pos: Vector2, group: String, tex: Texture2D) -> Area2D:
	var a := Area2D.new()
	a.position = pos
	a.add_to_group(group)
	add_child(a)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(3, 3)
	a.add_child(spr)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	a.add_child(cs)
	var lab := Label.new()
	lab.name = "Say"
	lab.position = Vector2(-48, -52)
	a.add_child(lab)
	a.body_entered.connect(_on_cannon_body)
	return a

func _on_cannon_body(body: Node) -> void:
	if starting or not _ok() or not cannon_alive or not _actors_ready():
		return
	if body.is_in_group("player") and yeet_cd <= 0.0:
		yeet_cd = 0.6
		player.global_position = Vector2(20 * SCALE_X, 80 * SCALE_Y)
		_say(player, "WHOA!!!")
		_say(cannon, "YEET!")
		_unlock("yeet")
	elif body.is_in_group("hotdog") and storm_cd <= 0.0:
		storm_cd = 1.0
		_hotdog_hits_cannon()
	elif body.is_in_group("enemy"):
		_break_cannon("SMASH!")

func _physics_process(delta: float) -> void:
	if starting:
		return
	# FREEZE after lose/win — number never updates here
	if game_over:
		return
	if not _actors_ready():
		return

	if start_grace > 0.0:
		start_grace -= delta
	if shoot_cd > 0.0:
		shoot_cd -= delta
	if yeet_cd > 0.0:
		yeet_cd -= delta
	if storm_cd > 0.0:
		storm_cd -= delta
	if storm_time > 0.0:
		storm_time -= delta
		if storm_time <= 0.0:
			_end_storm()

	_move_player()
	_move_hotdog()
	_move_enemy(delta)
	_move_bullets(delta)
	if _alive(player):
		_wrap(player)
	if _alive(hotdog):
		_wrap(hotdog)
	if _alive(enemy):
		_wrap(enemy)
	_check_touches()
	_events(delta)
	_try_404(delta)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_R:
				_start_game()
			KEY_SPACE:
				_shoot()
			KEY_ENTER:
				_show_achs()

func _get_move_vector() -> Vector2:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var w := Vector2(
		(1.0 if Input.is_physical_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_physical_key_pressed(KEY_A) else 0.0),
		(1.0 if Input.is_physical_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_physical_key_pressed(KEY_W) else 0.0)
	)
	if w != Vector2.ZERO:
		v = w
	return v.normalized() if v != Vector2.ZERO else Vector2.ZERO

func _move_player() -> void:
	if not _alive(player):
		return
	var v := _get_move_vector()
	player.velocity = Vector2(v.x * PLAYER_SPEED.x, v.y * PLAYER_SPEED.y)
	player.move_and_slide()

func _move_hotdog() -> void:
	if not _alive(hotdog):
		return
	var v := _get_move_vector()
	hotdog.velocity = Vector2(v.x * DOG_SPEED.x, v.y * DOG_SPEED.y)
	hotdog.move_and_slide()

func _move_bullets(delta: float) -> void:
	if not _alive(bullets_root):
		return
	var v := _get_move_vector()
	var speed := Vector2(v.x * BULLET_SPEED.x, v.y * BULLET_SPEED.y)
	for b in bullets_root.get_children():
		if b is Area2D and is_instance_valid(b):
			b.global_position += speed * delta
			_wrap(b)

func _move_enemy(delta: float) -> void:
	if busy or start_grace > 0.0 or not _alive(enemy) or not enemy.visible:
		return
	if not _alive(player) or not _alive(hotdog):
		return
	chase_t += delta
	if chase_t < ENEMY_STEP_TIME:
		return
	chase_t = 0.0
	var t := hotdog.global_position
	if player.global_position.distance_squared_to(enemy.global_position) <= hotdog.global_position.distance_squared_to(enemy.global_position):
		t = player.global_position
	if enemy.global_position.x < t.x:
		enemy.global_position.x += ENEMY_STEP
	elif enemy.global_position.x > t.x:
		enemy.global_position.x -= ENEMY_STEP
	if enemy.global_position.y < t.y:
		enemy.global_position.y += ENEMY_STEP
	elif enemy.global_position.y > t.y:
		enemy.global_position.y -= ENEMY_STEP

func _wrap(n: Node2D) -> void:
	if not _alive(n):
		return
	var p := n.global_position
	if p.x < 0.0:
		p.x = SCREEN.x
	elif p.x > SCREEN.x:
		p.x = 0.0
	if p.y < 0.0:
		p.y = SCREEN.y
	elif p.y > SCREEN.y:
		p.y = 0.0
	n.global_position = p

func _shoot() -> void:
	if starting or not _ok() or not _actors_ready():
		return
	if not cannon_alive or not can_shoot:
		_say(player, "No cannon... can't shoot!")
		return
	if shoot_cd > 0.0:
		_say(cannon, "sticky...")
		return
	if cannon_messy and randf() < 0.28:
		_say(cannon, "ACHOO!")
		shoot_cd = 0.5
		return
	_say(cannon, "KEPLEUY!!!!" if randi() % 2 == 0 else "PEW!")
	var b := Area2D.new()
	b.add_to_group("bullet")
	var spr := Sprite2D.new()
	spr.texture = _tex_bullet()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(2, 2)
	b.add_child(spr)
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 8.0
	cs.shape = sh
	b.add_child(cs)
	bullets_root.add_child(b)
	b.global_position = Vector2(20 * SCALE_X, 80 * SCALE_Y)
	b.body_entered.connect(func(body: Node) -> void:
		if not _ok():
			return
		if body.is_in_group("enemy"):
			_win_snipe(b)
		elif body.is_in_group("player"):
			_lose_self(b)
		elif body.is_in_group("hotdog"):
			_lose_lunch(b)
	)
	b.area_entered.connect(func(a: Area2D) -> void:
		if not _ok():
			return
		if a.is_in_group("cannon"):
			if is_instance_valid(b):
				b.global_position = Vector2(20 * SCALE_X, 80 * SCALE_Y)
			_break_cannon("HIT!")
	)
	shoot_cd = 0.45 if cannon_messy else 0.12
	if cannon_messy:
		_unlock("sticky")

func _check_touches() -> void:
	if not _ok() or not _actors_ready():
		return
	if player.global_position.distance_to(hotdog.global_position) < 42.0:
		_win_eat()
		return
	if player.global_position.distance_to(enemy.global_position) < 40.0:
		_lose_touch()
		return
	if hotdog.global_position.distance_to(enemy.global_position) < 40.0:
		_lose_stolen()
		return
	if _alive(bonus_root):
		for d in bonus_root.get_children():
			if d is Node2D and is_instance_valid(d) and player.global_position.distance_to(d.global_position) < 36.0:
				d.queue_free()
				bonus_eaten += 1
				_say(player, "nom" if bonus_eaten % 3 != 0 else "%d dogs!!" % bonus_eaten)

func _hotdog_hits_cannon() -> void:
	_say(hotdog, "STORM TIME!!!")
	_say(cannon, "MORE DOGS!!!")
	if not hotdog_plain:
		hotdog_plain = true
		_set_sprite(hotdog, _tex_hotdog(true))
		_say(hotdog, "My toppings!!!!")
	if not cannon_messy:
		cannon_messy = true
		_set_sprite(cannon, _tex_cannon(true))
		_say(cannon, "EWW KETCHUP")
	_start_storm()

func _start_storm() -> void:
	if storm_time > 0.0 or not _alive(bonus_root):
		return
	storm_time = 7.777
	bonus_eaten = 0
	_unlock("storm")
	_say(player, "HOT DOG STORM!!!")
	for i in range(randi_range(16, 26)):
		var d := Node2D.new()
		var spr := Sprite2D.new()
		spr.texture = _tex_hotdog(false)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.scale = Vector2(2, 2)
		d.add_child(spr)
		bonus_root.add_child(d)
		d.global_position = Vector2(randf_range(40, 920), randf_range(40, 500))

func _end_storm() -> void:
	if _alive(bonus_root):
		for c in bonus_root.get_children():
			c.queue_free()
	if _alive(player):
		_say(player, "%d bonus dogs!!" % bonus_eaten if bonus_eaten > 0 else "I missed the storm...")

func _events(delta: float) -> void:
	if not _ok() or not _actors_ready():
		return
	event_cd -= delta
	if event_cd > 0.0:
		return
	event_cd = randf_range(10.0, 18.0)
	var r := randi() % 100
	if r < 25:
		_say(player, ["MY LUNCH!", "THIS IS FINE.", "I'M STARVING!"][randi() % 3])
	elif r < 45:
		_say(enemy, ["FOOD DETECTED.", "NOM NOM NOM.", ":)"][randi() % 3])
	elif r < 60:
		_say(hotdog, ["Protect me!", "HELP!", "WHY ME?"][randi() % 3])
	elif r < 75 and cannon_alive:
		_say(cannon, ["READY!", "I LIKE HOT DOGS", "DON'T TOUCH ME"][randi() % 3])
	elif r < 85:
		_start_storm()

func _try_404(delta: float) -> void:
	if not _ok() or enemy_404_lock or not _actors_ready():
		return
	_404_t += delta
	if _404_t < 1.0:
		return
	_404_t = 0.0
	if randi_range(1, 10000) > 9:
		return
	enemy_404_lock = true
	busy = true
	_say(enemy, "404 Error: Food not dected")
	await get_tree().create_timer(0.9).timeout
	if _alive(enemy):
		_say(enemy, "404: Cannot turn off")
	await get_tree().create_timer(0.9).timeout
	if _alive(enemy):
		enemy.visible = false
	if _alive(player):
		_say(player, "free win???")
	await get_tree().create_timer(0.6).timeout
	_unlock("snipe")
	_end(true)

func _win_eat() -> void:
	busy = true
	_say(player, "Yummy Yummy Yummy Hot dog" if not hotdog_plain else "Yummy... dry hot dog")
	_unlock("ate")
	if hotdog_plain:
		_unlock("plain")
	if not cannon_alive:
		_unlock("nogun")
	await get_tree().create_timer(0.85).timeout
	_end(true)

func _win_snipe(b: Node) -> void:
	busy = true
	if is_instance_valid(b):
		b.queue_free()
	_say(enemy, "OWWIE!!!")
	_say(player, ":)")
	_unlock("snipe")
	if not cannon_alive:
		_unlock("nogun")
	await get_tree().create_timer(0.9).timeout
	_end(true)

func _lose_touch() -> void:
	busy = true
	_say(enemy, "I MUST KILL YOU!")
	_say(player, "DON'T!!!!!")
	await get_tree().create_timer(0.8).timeout
	_end(false)

func _lose_stolen() -> void:
	busy = true
	_say(player, "HEY!!! My Hot dog!!")
	_say(enemy, "Yummy Yummy Yummy")
	_unlock("stolen")
	await get_tree().create_timer(1.0).timeout
	_say(enemy, "I LOVED that hot dog!!!")
	_say(player, "I am DYING of Hunger!!!")
	await get_tree().create_timer(0.8).timeout
	_end(false)

func _lose_self(b: Node) -> void:
	busy = true
	if is_instance_valid(b):
		b.queue_free()
	_say(player, "OWWIE!!!")
	_unlock("ouch")
	await get_tree().create_timer(0.7).timeout
	_end(false)

func _lose_lunch(b: Node) -> void:
	busy = true
	if is_instance_valid(b):
		b.queue_free()
	_say(player, "WHY DID YOU SHOOT THE FOOD?!")
	_unlock("oops")
	await get_tree().create_timer(0.8).timeout
	_end(false)

func _break_cannon(reason: String) -> void:
	if not cannon_alive or not _alive(cannon):
		return
	_say(cannon, reason)
	if randi() % 2 == 0:
		_say(cannon, "I WAS ONLY 3 DAYS FROM RETIREMENT...")
	cannon_alive = false
	can_shoot = false
	cannon.visible = false
	if _alive(player):
		_say(player, "The cannon is gone!!!")
	_unlock("gunbroke")

func _end(win: bool) -> void:
	game_over = true
	busy = true
	if not _alive(msg_lbl):
		return
	if win:
		msg_lbl.modulate = Color(0.4, 1.0, 0.5)
		msg_lbl.text = "YOU WIN!!"
	else:
		msg_lbl.modulate = Color.WHITE
		# ONE number only — never updated again after this line
		msg_lbl.text = "GAME OVER\n%s" % str(randi_range(0, randi_range(10, randi_range(100, 999))))
	_hud()

func _ok() -> bool:
	return not starting and not game_over and not busy and start_grace <= 0.0

func _say(who: Node, text: String) -> void:
	if not _alive(who):
		return
	var lab := who.get_node_or_null("Say") as Label
	if lab == null:
		return
	lab.text = text
	get_tree().create_timer(1.15).timeout.connect(func () -> void:
		if is_instance_valid(lab) and lab.text == text:
			lab.text = ""
	)

func _set_sprite(who: Node, tex: Texture2D) -> void:
	if not _alive(who):
		return
	for c in who.get_children():
		if c is Sprite2D:
			c.texture = tex
			return

func _unlock(id: String) -> void:
	if not ach.has(id) or ach[id]:
		return
	ach[id] = true
	_hud()
	var names := {
		"ate": "Ate It", "snipe": "Shot Em", "yeet": "Yeeted", "storm": "Storm",
		"plain": "Plain Win", "nogun": "No Gun Win", "gunbroke": "Gun Broke",
		"ouch": "Ouch", "oops": "Oops Lunch", "stolen": "Stolen", "sticky": "Sticky", "all": "All Done"
	}
	if _alive(msg_lbl) and not game_over:
		msg_lbl.modulate = Color(0.3, 1.0, 0.4)
		msg_lbl.text = "ACH: %s" % names.get(id, id)
		get_tree().create_timer(1.0).timeout.connect(func () -> void:
			if not game_over and _alive(msg_lbl):
				msg_lbl.text = ""
				msg_lbl.modulate = Color.WHITE
		)
	var all := true
	for k in ach.keys():
		if k == "all":
			continue
		if not ach[k]:
			all = false
			break
	if all:
		_unlock("all")

func _show_achs() -> void:
	var t := "ACHIEVEMENTS\n"
	var keys := ["ate", "snipe", "yeet", "storm", "plain", "nogun", "gunbroke", "ouch", "oops", "stolen", "sticky", "all"]
	var nice := ["Ate It", "Shot Em", "Yeeted", "Storm", "Plain Win", "No Gun Win", "Gun Broke", "Ouch", "Oops Lunch", "Stolen", "Sticky", "All Done"]
	for i in keys.size():
		t += "%s %s\n" % [("[x]" if ach[keys[i]] else "[ ]"), nice[i]]
	if _alive(msg_lbl):
		msg_lbl.modulate = Color.WHITE
		msg_lbl.text = t

func _hud() -> void:
	var n := 0
	for k in ach.keys():
		if ach[k]:
			n += 1
	if _alive(score_lbl):
		score_lbl.text = "Achs: %d/12 | v8.0" % n

func _tex_player() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_rect(img, 11, 4, 10, 10, Color("ffb07a"))
	_rect(img, 13, 7, 2, 2, Color("1a1a1a"))
	_rect(img, 18, 7, 2, 2, Color("1a1a1a"))
	_rect(img, 14, 11, 5, 1, Color("1a1a1a"))
	_rect(img, 10, 14, 12, 12, Color("3d7eff"))
	_rect(img, 6, 15, 4, 3, Color("3d7eff"))
	_rect(img, 22, 15, 4, 3, Color("3d7eff"))
	_rect(img, 11, 26, 4, 5, Color("2a4f9e"))
	_rect(img, 17, 26, 4, 5, Color("2a4f9e"))
	return ImageTexture.create_from_image(img)

func _tex_hotdog(plain: bool) -> ImageTexture:
	var img := Image.create(48, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_rect(img, 4, 14, 40, 6, Color("e0a040"))
	_rect(img, 6, 8, 36, 8, Color("c45c2a"))
	_rect(img, 4, 4, 40, 6, Color("f0b050"))
	if not plain:
		for p in [[10, 9], [14, 10], [18, 9], [22, 10], [26, 9], [30, 10], [34, 9], [11, 15], [23, 15], [35, 15]]:
			_rect(img, p[0], p[1], 2, 2, Color("e22222"))
		for p in [[12, 12], [16, 11], [20, 12], [24, 11], [28, 12], [32, 11], [17, 16], [29, 16]]:
			_rect(img, p[0], p[1], 2, 2, Color("ffd000"))
	return ImageTexture.create_from_image(img)

func _tex_enemy() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_rect(img, 8, 8, 16, 16, Color("33e0f0"))
	_rect(img, 11, 12, 3, 3, Color("111111"))
	_rect(img, 18, 12, 3, 3, Color("111111"))
	_rect(img, 12, 20, 8, 2, Color("111111"))
	return ImageTexture.create_from_image(img)

func _tex_cannon(messy: bool) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_rect(img, 10, 6, 8, 18, Color("ff66cc"))
	_rect(img, 12, 2, 4, 6, Color("ff99dd"))
	_rect(img, 8, 22, 12, 6, Color("cc44aa"))
	if messy:
		_rect(img, 7, 8, 3, 3, Color("e22222"))
		_rect(img, 18, 12, 3, 3, Color("ffd000"))
		_rect(img, 9, 18, 3, 3, Color("e22222"))
		_rect(img, 16, 20, 3, 3, Color("ffd000"))
	return ImageTexture.create_from_image(img)

func _tex_bullet() -> ImageTexture:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_rect(img, 3, 3, 6, 6, Color("ffe066"))
	_rect(img, 5, 1, 2, 10, Color("ffaa00"))
	return ImageTexture.create_from_image(img)

func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
				img.set_pixel(xx, yy, c)
				
