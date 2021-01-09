extends Node2D

# max possible length of words is 6
const MAX_LENGTH = 6

var Enemy = preload("res://Scenes/enemy.tscn")

onready var enemies = $enemies
onready var r_spawn_points = $enemy_right_spawns
onready var l_spawn_points = $enemy_left_spawns
onready var spawn_timer = $spawn_timer
onready var buffer_label = $archer/buffer as RichTextLabel

var typed_buffer = ""
var active_words = []
var alpha_regex = RegEx.new()

export (int) var current_wave = 1
var current_wave_size = 10
var min_word_length = 3
var max_word_length = 4 # has to be at LEAST min_word_length + 1
var enemy_speed = 1.5
var total_enemies_killed = 0
var enemies_killed = 0
var spawn_time = 3 # starts at 5 seconds

func _ready() -> void:
	randomize()
	alpha_regex.compile("[a-z]")
	spawn_enemy()
	start_wave()

func start_wave():
	print("Starting wave ",current_wave)
	spawn_timer.start()

func stop_wave():
	print("wave ", current_wave, " has been cleared!")
	spawn_timer.stop()
	
	# wait 5 seconds
	var t = Timer.new()
	t.set_wait_time(5)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	t.queue_free()
	
	# increment current wave
	current_wave += 1
	
	# increase the difficulty for the next wave
	increase_difficulty()
	
	# start the next wave
	start_wave()

func increase_difficulty():
	
	if current_wave % 2 == 0:
		if spawn_timer.wait_time > .5:
			print("before ",spawn_timer.wait_time)
			spawn_timer.wait_time = (spawn_time - (0.2 * current_wave))
			print("after ",spawn_timer.wait_time)
		
	if current_wave % 3 == 0:
		enemy_speed += 0.35
	
	if current_wave % 6 == 0: 
		if max_word_length < MAX_LENGTH + 1:
			max_word_length += 1
	
	if current_wave % 10 == 0:
		if min_word_length < max_word_length - 1:
			min_word_length += 1
		current_wave_size += 15
	
	
func check_words():
	for enemy in enemies.get_children():
		var prompt = enemy.get_prompt()
		if prompt == typed_buffer:
			enemy.queue_free()
			typed_buffer = ""
			buffer_label.text = typed_buffer
			enemies_killed += 1
			if enemies_killed >= current_wave_size:
				stop_wave()
				total_enemies_killed += enemies_killed
				enemies_killed = 0
			break

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_pressed():
		var type_event = event as InputEventKey
		if type_event.scancode == KEY_SPACE:
			typed_buffer = ""
			buffer_label.text = typed_buffer
		elif type_event.scancode == KEY_BACKSPACE:
			typed_buffer = typed_buffer.substr(0, typed_buffer.length() - 1)
			buffer_label.text = typed_buffer
		else:
			var typed_char = char(type_event.scancode).to_lower()
			if alpha_regex.search(typed_char):
				typed_buffer += typed_char
				buffer_label.text = typed_buffer
				check_words()
			

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()

func spawn_enemy():
	var enemy_instance = Enemy.instance()
	var randInt = randi()
	var spawns = r_spawn_points.get_children()
	var direction = -1
	
	if randInt % 2 == 0:
		# insert into left
		spawns = l_spawn_points.get_children()
		direction = 1
		
	var index = randInt % spawns.size()

	enemy_instance.init(direction, enemy_speed, min_word_length, max_word_length)
	enemies.add_child(enemy_instance)
	enemy_instance.global_position = spawns[index].global_position
