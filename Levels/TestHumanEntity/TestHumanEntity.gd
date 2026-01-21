extends Node2D

# Test script for HumanEntity implementation

var human_entities = []
var test_human_count = 5

func _ready():
	print("HumanEntity test scene loaded successfully")
	
	# Spawn test humans
	spawn_test_humans()
	
	print("HumanEntity test initialized")
	print("Created ", test_human_count, " HumanEntity instances")

func spawn_test_humans():
	# Load the human entity scene
	var human_scene = preload("res://Entities/Human/HumanEntity.tscn")
	
	# Spawn humans at random positions
	for i in range(test_human_count):
		# Create a new instance
		var human = human_scene.instance()
		
		# Set random position within a reasonable range
		var random_x = rand_range(-400, 400)
		var random_y = rand_range(-400, 400)
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

# Regenerate world with a new seed
func _input(event):
	if event is InputEventKey and event.pressed:
		# Press H to spawn more humans
		if event.scancode == KEY_H:
			spawn_test_humans()
			print("Spawned additional humans")

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

# Update function to monitor human entities
func _process(delta):
	if human_entities.size() == 0:
		print("All humans have died, respawning...")
		spawn_test_humans()
