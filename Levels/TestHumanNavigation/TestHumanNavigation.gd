extends Node2D

# Test script for HumanEntity navigation and terrain awareness

var human_entities = []
var test_human_count = 3  # Reduced from 5 for better visibility
var world_generator = null
var camera_node = null
var camera_speed = 200.0
var zoom_speed = 0.1

func _ready():
	print("Human Navigation and Terrain Awareness test scene loaded successfully")
	
	# Setup camera
	setup_camera()
	
	# Load and initialize world generator
	load_world_generator()
	
	# Wait a frame to ensure world generator is ready
	yield(get_tree(), "idle_frame")
	
	# Spawn test humans
	spawn_test_humans()
	
	print("Human Navigation test initialized")
	print("Created ", test_human_count, " HumanEntity instances with world generator")
	print("Controls:")
	print("- Click on human entity to set random navigation target")
	print("- Press G to set random navigation target for random human")
	print("- Press H to spawn more humans")
	print("- Use WASD to move camera")
	print("- Use mouse wheel to zoom camera")

func setup_camera():
	# Create a Camera2D node
	camera_node = Camera2D.new()
	camera_node.current = true
	camera_node.zoom = Vector2(0.5, 0.5)  # Start with zoomed out view
	add_child(camera_node)

func load_world_generator():
	# Load the world generator scene
	var world_scene = preload("res://Entities/World/WorldGenerator.tscn")
	
	# Create an instance
	world_generator = world_scene.instance()
	
	# Optimize world generator for testing
	world_generator.world_size = Vector2(600, 600)  # Smaller world size for better visibility
	world_generator.tile_size = 32.0
	
	# Add to scene
	add_child(world_generator)
	
	print("World generator loaded successfully")

func spawn_test_humans():
	# Load the human entity scene
	var human_scene = preload("res://Entities/Human/HumanEntity.tscn")
	
	# Spawn humans at random positions
	for i in range(test_human_count):
		# Create a new instance
		var human = human_scene.instance()
		
		# Set random position within a reasonable range
		var random_x = rand_range(-200, 200)
		var random_y = rand_range(-200, 200)
		human.position = Vector2(random_x, random_y)
		
		# Add to scene and list
		add_child(human)
		human_entities.append(human)
		
		# Connect signals for testing
		human.connect("HumanEntityClicked", self, "_on_human_clicked")
		human.connect("HumanEntityDied", self, "_on_human_died")
		human.connect("HumanEntityCollectedResource", self, "_on_resource_collected")
		human.connect("HumanEntityEmotionChanged", self, "_on_emotion_changed")
		human.connect("HumanEntityNeedsChanged", self, "_on_needs_changed")

# Handle input events
func _input(event):
	# Camera controls
	if camera_node:
		# Mouse wheel for zoom
		if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_WHEEL_UP:
			camera_node.zoom *= Vector2(0.9, 0.9)
		elif event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_WHEEL_DOWN:
			camera_node.zoom *= Vector2(1.1, 1.1)
	
	if event is InputEventKey and event.pressed:
		# Press H to spawn more humans
		if event.scancode == KEY_H:
			spawn_test_humans()
			print("Spawned additional humans")
		# Press G to set a random navigation target for a human
		elif event.scancode == KEY_G:
			if human_entities.size() > 0:
				var random_human = human_entities[randi() % human_entities.size()]
				var random_x = rand_range(-300, 300)
				var random_y = rand_range(-300, 300)
				random_human.set_navigation_target(Vector2(random_x, random_y))
				print("Set navigation target for human")



# Human entity clicked
func _on_human_clicked(entity):
	print("Human entity clicked: ", entity.name)
	print("- Age: ", round(entity.age), " years")
	print("- Gender: ", "Female" if entity.gender else "Male")
	print("- Health: ", round(entity.health), "/", entity.max_health)
	print("- Hunger: ", round(entity.hunger), "/", entity.max_hunger)
	print("- Thirst: ", round(entity.thirst), "/", entity.max_thirst)
	print("- Fatigue: ", round(entity.fatigue), "/", entity.max_fatigue)
	print("- Happiness: ", round(entity.emotions["happiness"]))
	print("- Current terrain: ", world_generator.get_terrain_name(entity.current_terrain_type))
	print("- Movement speed multiplier: ", entity.movement_speed_multiplier)
	
	# Set a random navigation target when clicked
	var random_x = rand_range(-400, 400)
	var random_y = rand_range(-400, 400)
	entity.set_navigation_target(Vector2(random_x, random_y))
	print("Set navigation target for clicked human")

# Human entity died
func _on_human_died(entity):
	print("Human entity died: ", entity.name)
	if entity in human_entities:
		human_entities.erase(entity)

# Resource collected
func _on_resource_collected(entity, resource_type, amount):
	print("Human entity collected resource: ", entity.name, ", Type: ", resource_type, ", Amount: ", amount)

# Emotion changed
func _on_emotion_changed(entity, emotion_type, value):
	# Only print significant changes
	if abs(value - 50) > 20:  # Only print if emotion is significantly high or low
		print("Human emotion changed: ", entity.name, ", ", emotion_type, ": ", round(value))

# Needs changed
func _on_needs_changed(entity, need_type, value):
	# Only print critical needs changes
	if need_type in ["hunger", "thirst", "health"] and value < 30:  # Only print if need is critical
		print("Human needs critical: ", entity.name, ", ", need_type, ": ", round(value))

# Update function to monitor human entities and handle camera movement
func _process(delta):
	# Camera movement with WASD
	if camera_node:
		var camera_velocity = Vector2()
		if Input.is_action_pressed("ui_up"):
			camera_velocity.y -= 1
		if Input.is_action_pressed("ui_down"):
			camera_velocity.y += 1
		if Input.is_action_pressed("ui_left"):
			camera_velocity.x -= 1
		if Input.is_action_pressed("ui_right"):
			camera_velocity.x += 1
		
		# Normalize and apply speed
		if camera_velocity.length() > 0:
			camera_velocity = camera_velocity.normalized() * camera_speed * delta
			camera_node.position += camera_velocity
	
	# Monitor human entities
	if human_entities.size() == 0:
		print("All humans have died, respawning...")
		spawn_test_humans()

# Draw debug information
func _draw():
	# Draw world generator boundaries
	if world_generator:
		var world_size = world_generator.world_size
		draw_rect(Rect2(-world_size/2, -world_size/2, world_size.x, world_size.y), Color(1, 0, 0, 0.1), false, 2)
