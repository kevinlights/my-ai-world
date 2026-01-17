extends Node2D

# Test script for SimpleHumanEntity implementation

func _ready():
	print("SimpleHumanEntity test scene loaded successfully")
	
	# Get references to the entities
	var human1 = get_node("SimpleHumanEntity")
	var human2 = get_node("SimpleHumanEntity2")
	var resource = get_node("BasicResource")
	
	# Connect to signals to verify functionality if nodes exist and are of correct type
	if human1 and "connect" in human1:
		human1.connect("SimpleHumanEntityClicked", self, "_on_human_clicked")
		human1.connect("SimpleHumanEntityDied", self, "_on_human_died")
		human1.connect("SimpleHumanEntityCollectedResource", self, "_on_resource_collected")
	
	if human2 and "connect" in human2:
		human2.connect("SimpleHumanEntityClicked", self, "_on_human_clicked")
		human2.connect("SimpleHumanEntityDied", self, "_on_human_died")
		human2.connect("SimpleHumanEntityCollectedResource", self, "_on_resource_collected")
	
	print("SimpleHumanEntity test initialized")
	print("Created 2 SimpleHumanEntity instances and 1 BasicResource")
	print("Signals connected for testing")

func _on_human_clicked(entity):
	print("SimpleHumanEntity clicked: ", entity.name)

func _on_human_died(entity):
	print("SimpleHumanEntity died: ", entity.name)

func _on_resource_collected(entity, amount):
	print("SimpleHumanEntity collected resource: ", entity.name, " amount: ", amount)

func _process(delta):
	# Display some basic stats periodically
	if int(OS.get_ticks_msec() / 5000) % 2 == 0:  # Every 5 seconds
		var human1 = get_node("SimpleHumanEntity")
		if human1 and "dead" in human1 and not human1.dead:
			print("Human1 - Hunger: ", human1.hunger, " Health: ", human1.health, " Energy: ", human1.energy)
