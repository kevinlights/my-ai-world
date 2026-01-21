extends Node2D

# Test script for world generation system

var world_generator = null
var human_entities = []
var test_human_count = 5

func _ready():
	print("World Generation test scene loaded")
	
	# Get reference to world generator
	world_generator = get_node("WorldGenerator")
	
	# Spawn test humans
	spawn_test_humans()
	
	print("World Generation test initialized")
	print("Created world generator and spawned ", test_human_count, " human entities")

func spawn_test_humans():
	# Load the human entity scene
	var human_scene = preload("res://Entities/Human/SimpleHumanEntity.tscn")
	
	# Spawn humans at random positions
	for i in range(test_human_count):
		# Create a new instance
		var human = human_scene.instance()
		
		# Set random position within the world bounds
		var random_x = rand_range(-world_generator.world_size.x/4, world_generator.world_size.x/4)
		var random_y = rand_range(-world_generator.world_size.y/4, world_generator.world_size.y/4)
		human.position = Vector2(random_x, random_y)
		
		# Add to scene and list
		add_child(human)
		human_entities.append(human)
		
		# Connect signals for testing
		human.connect("SimpleHumanEntityClicked", self, "_on_human_clicked")
		human.connect("SimpleHumanEntityDied", self, "_on_human_died")

# Regenerate world with a new seed
func _input(event):
	if event is InputEventKey and event.pressed:
		# Press R to regenerate world
		if event.scancode == KEY_R:
			print("Regenerating world with new seed...")
			world_generator.regenerate_world()
			print("World regenerated")
		
		# Press H to spawn more humans
		if event.scancode == KEY_H:
			spawn_test_humans()
			print("Spawned additional humans")

# Human entity clicked
func _on_human_clicked(entity):
	print("Human entity clicked: ", entity.name)
	
	# Get terrain type at human position
	var terrain_type = world_generator.get_terrain_at_position(entity.position)
	var terrain_name = get_terrain_name(terrain_type)
	print("Human is on ", terrain_name, " terrain")

# Human entity died
func _on_human_died(entity):
	print("Human entity died: ", entity.name)
	if entity in human_entities:
		human_entities.erase(entity)

# Helper function to get terrain name from numeric type
func get_terrain_name(terrain_type):
	match terrain_type:
		0: return "Water"
		1: return "Grass"
		2: return "Desert"
		3: return "Mountain"
	return "Unknown"

# Update function to monitor human entities
func _process(delta):
	if human_entities.size() == 0:
		print("All humans have died")
		
		# Respawn humans after a delay
		yield(get_tree().create_timer(2.0), "timeout")
		spawn_test_humans()
		print("Respawned humans")
