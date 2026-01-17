extends Node2D

# 游戏核心控制类

# 波比配置类
class BoppieConfiguration:
	var group
	var min_count
	var scene
	var fittest: Array = []
	var new_dna_chance = 0.2
	func _init(group: String, min_count: int, scene: PackedScene):
		self.group = group
		self.min_count = min_count
		self.scene = scene
		
export var min_count_config = {
	"Owlie": 10,
	"Kloppie": 0,
	"Trap": 5,
}

func get_min_count(type):
	return min_count_config[type] if type in min_count_config else 0
		
onready var boppie_configurations = [
	BoppieConfiguration.new("Owlie", get_min_count("Owlie"), preload("res://Entities/Boppie/Types/Owlie.tscn")),
	BoppieConfiguration.new("Kloppie", get_min_count("Kloppie"), preload("res://Entities/Boppie/Types/Kloppie.tscn")),
	BoppieConfiguration.new("Trap", get_min_count("Trap"), preload("res://Entities/Trap/Trap.tscn")),
]
var lookup_boppie_type_to_config = {}

# Simulation settings
export var max_food_count = 150
export var food_per_500ms = 7
export var spawn_food_on_death = true # 死亡后生成食物
export var keep_n_fittest_boppies = 30
export var kloppies_cannibals = false # 同类相食
export var number_of_lakes = 1

# Game size
export var total_width = 4000
export var total_height = 3000
export var empty_zone_size = 20
onready var total_size = Vector2(total_width, total_height)
onready var world_zone_start = Vector2(empty_zone_size, empty_zone_size)
onready var world_zone_end = total_size - world_zone_start 
var unused_food_stack = []
var unused_food_stack_index = 0
var follow_fittest_boppie = false setget set_follow_fittest_boppie
var difficulty_level = 1
var last_difficulty_level_change_time = 0
var mouse_is_pressed = false
var control_newest_boppie = false

export var background_color = Color("#6d6d6d")

# Boppies
var food_scene = preload("res://Entities/Food/Food.tscn")
var lake_scene = preload("res://Entities/World/Water/Lake.tscn")
var controlled_boppie: Boppie = null
var player_ai = Player.new()
var rand_ai = RandomAI.new()
var smart_ai = SmartAI.new()



signal FollowFittestBoppie(new_value)
signal EngineTimeScaleChange(factor)
signal BoppieControlChanged(boppie)
signal BoppieInvincibilityChanged(boppie, is_invincible)
signal SpawnNewBoppie(at, dna)

func random_coordinate():
	return Vector2(Globals.rng.randf(), Globals.rng.randf())

func random_world_coordinate(): # 返回随机的世界坐标
	return random_coordinate() * (world_zone_end - world_zone_start) + world_zone_start
	
# 在2D世界中找到一个随机的空白位置，即没有其他对象与之重叠的位置
func random_empty_world_coordinate():
	for i in range(10): # 尝试10次找到空白的坐标
		var coordinate = random_world_coordinate()
		var space_state = get_world_2d().get_direct_space_state() # 获取2D世界的直接空间状态，这允许查询世界中对象之间的空间关系。
		var result = space_state.intersect_point(coordinate, 1, [], 0x7FFFFFFF, true, true) # 检查指定的 coordinate 是否与任何其他对象相交。1 表示检查的半径大小，[] 表示碰撞层，0x7FFFFFFF 是一个很大的数字，表示碰撞掩码，true, true 分别表示是否检测碰撞体和是否检测区域碰撞
		if not result or i == 9:
			return coordinate

	
func random_game_coordinate():
	return random_coordinate() * total_size

func is_within_game(pos: Vector2): # 是否在游戏界面中
	return (world_zone_start.x <= pos.x and pos.x <= world_zone_end.x
			and world_zone_start.y <= pos.y and pos.y <= world_zone_end.y)
	
# 确保生物不会移出地图范围
func make_within_game(pos: Vector2): # 基于地图进行位置调整，如果从底部移动出去，则重新从顶部进入，从右侧移动出去，则重新从左侧进入
	return Vector2(fposmod(pos.x, total_width), fposmod(pos.y, total_height))
	
func get_mouse_world_coords():
	var pos = get_global_mouse_position()
	return pos
	
func add_lakes():
	for i in range(number_of_lakes):
		var lake = lake_scene.instance()
		add_child(lake)
		lake.rotation = PI * 2 * Globals.rng.randf()
		var offset = lake.radius * 2
		var allowed_width = total_width - offset * 2
		var allowed_height = total_height - offset * 2
		lake.position.x = offset + allowed_width * Globals.rng.randf()
		lake.position.y = offset + allowed_height * Globals.rng.randf()
		
	
func _draw():
	var offset = Vector2(14, 14)
	draw_rect(Rect2(-offset, total_size+offset), background_color)

func _ready():
	add_lakes()
	Globals.kloppies_cannibals = kloppies_cannibals
	for boppie in get_tree().get_nodes_in_group("Boppie"):
		handle_boppie(boppie) # 对当前环境中的波比进行事件绑定
	$Camera.position = total_size / 2 # 摄像机位于界面中心
	if food_per_500ms > 0:
		$FoodTimer.connect("timeout", self, "_reset_food_timer")
	for config in boppie_configurations:
		lookup_boppie_type_to_config[config.group] = config
	connect("SpawnNewBoppie", self, "_on_SpawnNewBoppie")
		
func _reset_food_timer(): # 生成食物
	spawn_food(food_per_500ms * 2)
#	print(unused_food_stack_index)
#	var new_index = max(0, unused_food_stack_index - food_per_100ms)
#	for i in range(unused_food_stack_index, new_index, -1):
#		unused_food_stack[i].global_position = random_world_coordinate()
#		unused_food_stack[i].reset()
#	unused_food_stack_index = new_index
		

# 波比的事件绑定	
func handle_boppie(boppie):
	for signal_name in ["Clicked", "Died", "Offspring"]:
		boppie.connect("Boppie" + signal_name, self, "_on_Boppie" + signal_name)
	boppie.update()
		
func _on_SpawnNewBoppie(at, dna): # 添加新波比 或陷阱
	add_boppie(at, boppie_configurations[0].scene, dna)

# 生成个体的核心方法
func add_boppie(at: Vector2, scene: PackedScene, dna=null, dna2=null):
	var instance = scene.instance() # 场景的实例化
	if instance is Boppie:
		if dna != null:
			instance.set_dna(dna, 1, dna2) # 对波比设置 DNA
		handle_boppie(instance) # 绑定事件
	instance.rotation = Globals.rng.randf() * 2 * PI # 随机朝向
	add_child(instance)
	instance.set_owner(self)
	instance.global_position = at # 设置位置
	# Globals.debugMsg("add boppie")
	# Globals.debugMsg(at.x)
	# Globals.debugMsg(at.y)
	if control_newest_boppie:
		control_newest_boppie = false
		take_control_of_boppie(instance) # 控制最新波比
	return instance


func add_random_boppies(count: int, config: BoppieConfiguration): # 添加随机波比
	for _i in range(count):
		var dna1 = null
		var dna2 = null
		if config.fittest.size() >= 10 and Globals.rng.randf() > config.new_dna_chance:
			var fittest_len = len(config.fittest)
			var dna1_index = Globals.rng.randi() % fittest_len # e.g. 9%10=9
			var dna2_index = (dna1_index + (fittest_len - 1)) % fittest_len # e.g. (9+9)%10=8
			dna1 = config.fittest[dna1_index][1]
			dna2 = config.fittest[dna2_index][1]
		# var boppie = add_boppie(random_empty_world_coordinate(), config.scene, dna1, dna2)
		add_boppie(random_empty_world_coordinate(), config.scene, dna1, dna2)
		
func add_food(at: Vector2): # 在指定位置生成食物
	var food = food_scene.instance() # 实例化时会向 globals 记录食物数量
	add_child(food)
	food.global_position = at
	# food.connect("FoodEaten", self, "_on_FoodEaten")
	return food
	
func _on_FoodEaten(food): # 废弃方法
	unused_food_stack[unused_food_stack_index] = food
	unused_food_stack_index += 1


func spawn_food(count=max_food_count): # 生成指定数量食物，不超过最大数量
	var target_food_count = min(max_food_count, Globals.food_counts[Data.FoodType.PLANT] + count)
	while Globals.food_counts[Data.FoodType.PLANT] < target_food_count:
		add_food(random_empty_world_coordinate())

func take_control_of_boppie(boppie):
	if controlled_boppie != null:
		controlled_boppie.set_selected(false)
		controlled_boppie.draw_senses = false
		if controlled_boppie.temp_ai == player_ai:
			controlled_boppie.pop_temp_ai()
	controlled_boppie = boppie
	emit_signal("BoppieControlChanged", controlled_boppie) # 主要用来改变 UI
	var invincibility = false if controlled_boppie == null else not controlled_boppie.can_die
	emit_signal("BoppieInvincibilityChanged", controlled_boppie, invincibility) # 主要用来改变 UI
	if controlled_boppie != null:
		controlled_boppie.draw_senses = Globals.draw_current_senses
		controlled_boppie.set_selected(true)


func _process(_delta):
	check_boppies()
	if controlled_boppie != null: # 如果有控制的波比，将镜头移动到相应的位置
		$Camera.global_position = controlled_boppie.global_position
	else:
		$Camera.global_position -= Utils.input_vectors() * 7

# 输入处理方法	
func _unhandled_input(event):
	if event.is_action_pressed("cancel"): # 取消控制波比
		take_control_of_boppie(null)
	if event.is_action_pressed("add_energy_to_focused_boppie"): # 手动给波比增加能量
		if controlled_boppie:
			controlled_boppie.update_energy(5)
			controlled_boppie.update_water(5)
	if event.is_action_pressed("toggle_vision_rays_of_focused_boppie"): # 显示射线
		Globals.draw_current_senses = !Globals.draw_current_senses
		if controlled_boppie != null:
			controlled_boppie.draw_senses = Globals.draw_current_senses
	if event.is_action_pressed("set_time_factor_to_2^(number-1)"): # 加快时间
		var new_time_scale = 1 << (event.scancode - KEY_1)
		change_time_scale(new_time_scale / Engine.time_scale)
	if event.is_action_pressed("save_simulation"): # 保存
		$SaveDialog.show_save_dialog(true)
	if event.is_action_pressed("load_simulation"): # 加载
		$SaveDialog.show_save_dialog(false)
	if event.is_action_pressed("follow_fittest_boppie_after_death"):
		set_follow_fittest_boppie(!follow_fittest_boppie)
	if event.is_action_pressed("follow_fittest_owlie"): # 跟随适应度最高的波比，
		take_control_of_fittest_boppie_in_group("Owlie")
	if event.is_action_pressed("follow_fittest_kloppie"):
		take_control_of_fittest_boppie_in_group("Kloppie")
	if event is InputEventMouseButton:
		mouse_is_pressed = event.pressed
	elif event is InputEventMouseMotion and mouse_is_pressed:
		$Camera.position -= event.relative * $Camera._zoom_level
		
func produce_and_focus_offspring():
	if controlled_boppie: # 产生下一代同时控制最新的个体
		controlled_boppie.produce_offspring()
		control_newest_boppie = true
		
# 无敌模式下生物不会死亡
func toggle_controlled_boppie_invincibility(new_value=null):
	var is_invincible = false
	if controlled_boppie != null:
		if new_value == null:
			controlled_boppie.can_die = !controlled_boppie.can_die
			
		else:
			controlled_boppie.can_die = new_value
		is_invincible = !controlled_boppie.can_die
	emit_signal("BoppieInvincibilityChanged", controlled_boppie, is_invincible)
		
func take_control_of_focused_boppie() -> bool:
	if controlled_boppie != null:
		if controlled_boppie.temp_ai != player_ai: # 将 player ai 设置成当前控制的个体的临时 ai
			controlled_boppie.add_temp_ai(player_ai)
			return true
		# if controlled_boppie.temp_ai != rand_ai: # 将 player ai 设置成当前控制的个体的临时 ai
		# 	Globals.debugMsg("add rand_ai")
		# 	controlled_boppie.add_temp_ai(rand_ai)
		# 	return true
		else:
			# Globals.debugMsg("pop temp ai")
			controlled_boppie.pop_temp_ai() # 取消临时 ai 
			return false
	return false

func toggle_simulation_pause():
	get_tree().paused = !get_tree().paused
	emit_signal("EngineTimeScaleChange", int(!get_tree().paused))

				
func find_fittest_in_group(group):
	var fittest = null
	for boppie in get_tree().get_nodes_in_group(group):
		if not boppie.dead and (fittest == null or boppie.spawn_time < fittest.spawn_time):
			fittest = boppie
	return fittest
	
func set_follow_fittest_boppie(value):
	follow_fittest_boppie = value
	emit_signal("FollowFittestBoppie", follow_fittest_boppie)
	
func take_control_of_fittest_boppie_in_group(group):
	# Use this function so it can be deferred
	set_follow_fittest_boppie(true)
	take_control_of_boppie(find_fittest_in_group(group))

# 使用引擎来更改游戏运行速度
func change_time_scale(factor):
	var new_time_scale = Engine.time_scale * factor
	if .5 <= new_time_scale and new_time_scale <= 256 and new_time_scale != Engine.time_scale:
		Engine.time_scale = new_time_scale
		Engine.iterations_per_second = 60 * max(1, pow(2, log(Engine.time_scale)))
		if new_time_scale >= 64:
			Globals.performance_mode = true
		emit_signal("EngineTimeScaleChange", factor)

# 检查生物，如位置，困难度，随机补充生物数量到最小数量		
func check_boppies():
	for config in boppie_configurations:
		var boppies = get_tree().get_nodes_in_group(config.group)
		if Globals.elapsed_time - last_difficulty_level_change_time > 1200:
			if difficulty_level <= 20 and boppies.size() > 40:
				# lookup_boppie_type_to_config["Kloppie"].min_count = 3
				difficulty_level += 1
				last_difficulty_level_change_time = Globals.elapsed_time
				Globals.difficulty += .01
				config.new_dna_chance = 1 - ((1 - config.new_dna_chance) * .9)
		for boppie in boppies:
			if not is_within_game(boppie.global_position):
				boppie.global_position = make_within_game(boppie.global_position)
		var diff = config.min_count - boppies.size()
		if diff > 0:
			Globals.boppies_spawned += diff
			add_random_boppies(diff, config)
			
func possibly_replace_weakest_boppie(boppie):
	if boppie.offspring_count == 0:
		return
	var fittest_boppies = lookup_boppie_type_to_config[boppie.type].fittest
	var tuple = [boppie.fitness(), boppie.dna.duplicate(true)]
	if fittest_boppies.size() < keep_n_fittest_boppies:
		fittest_boppies.append(tuple)
		return
	var weakest_index = 0
	for index in range(fittest_boppies.size()):
		if fittest_boppies[weakest_index][0] > fittest_boppies[index][0]:
			weakest_index = index
	if fittest_boppies[weakest_index][0] < tuple[0]:
		fittest_boppies[weakest_index] = tuple

func _on_BoppieClicked(boppie):
	take_control_of_boppie(boppie)
	
func _on_BoppieDied(boppie):
	Globals.boppies_died += 1
	# possibly_replace_weakest_boppie(boppie)
	if boppie == controlled_boppie:
		if follow_fittest_boppie: # 如果设置了跟随适应最好的个体，则控制它
			take_control_of_fittest_boppie_in_group(boppie.type)
		else:
			take_control_of_boppie(null) # 否则不控制任何个体
	if spawn_food_on_death: # 如果死亡后产生食物
		var food = food_scene.instance()
		food.food_type = Data.FoodType.MEAT # 食物类型为肉食种类
		food.global_position = boppie.global_position
		# food.modulate = food.modulate.darkened(.3)
		add_child(food)
	
func _on_BoppieOffspring(boppie): # 废弃方法
	Globals.boppies_born += 1
	var offspring_position = boppie.global_position - boppie.rotation_vector() * boppie.radius * 2.7
	var scene
	for config in boppie_configurations:
		if boppie.type == config.group:
			scene = config.scene
			break
	call_deferred("add_boppie", offspring_position, scene, boppie.dna)


func _on_TrackFittestTimer_timeout() -> void:
	if not get_tree().paused:
		for config in boppie_configurations:
			if config.group == "Trap":
				continue
			var boppie = find_fittest_in_group(config.group)
			if boppie != null and boppie.offspring_count > 0:
				config.fittest.push_front([boppie.fitness(), boppie.dna.duplicate(true)])
				if len(config.fittest) > keep_n_fittest_boppies:
					config.fittest.pop_back()
