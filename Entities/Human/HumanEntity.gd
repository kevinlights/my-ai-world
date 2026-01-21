extends KinematicBody2D

class_name HumanEntity

# Properties
var type = "HumanEntity"
var radius := 25.0  # Slightly larger than Boppie to distinguish visually
var can_die := true

# ------------------------
# Basic survival needs (Physiological)
# ------------------------
var hunger = 100.0  # Hunger level (0-100), decreases over time
var max_hunger = 100.0
var hunger_rate = 0.5  # How fast hunger decreases per second (reduced from 5.0)

var thirst = 100.0  # Thirst level (0-100), decreases over time
var max_thirst = 100.0
var thirst_rate = 0.7  # How fast thirst decreases per second (reduced from 7.0)

var fatigue = 0.0  # Fatigue level (0-100), increases over time
var max_fatigue = 100.0
var fatigue_rate = 0.3  # How fast fatigue increases per second (reduced from 3.0)
var fatigue_recovery_rate = 10.0  # How fast fatigue recovers when resting

var health = 100.0  # Health level (0-100), affected by hunger, thirst, and fatigue
var max_health = 100.0
var health_recovery_rate = 0.5  # How fast health recovers when needs are met

var energy = 100.0  # Energy level for actions
var max_energy = 100.0
var energy_consumption_base = 1.0  # Base energy consumption rate

# ------------------------
# Psychological needs
# ------------------------
var safety = 100.0  # Safety level (0-100)
var max_safety = 100.0
var safety_decay_rate = 1.0  # How fast safety decreases when in dangerous situations

var belonging = 100.0  # Belonging level (0-100)
var max_belonging = 100.0
var belonging_decay_rate = 2.0  # How fast belonging decreases when alone

var self_esteem = 100.0  # Self-esteem level (0-100)
var max_self_esteem = 100.0
var self_esteem_decay_rate = 1.5  # How fast self-esteem decreases when rejected

# ------------------------
# Social properties
# ------------------------
var age = 18 + rand_range(0, 60)  # Random age between 18 and 78
var max_age = 100.0
var gender = randf() > 0.5  # True for female, False for male

# Skills (0-100)
var skills = {
	"gathering": randf() * 50,  # Gathering resources
	"hunting": randf() * 30,     # Hunting
	"building": randf() * 40,    # Building structures
	"cooking": randf() * 35,     # Cooking food
	"social": randf() * 50,      # Social interaction
	"leadership": randf() * 20    # Leadership skills
}

# Personality traits (0-100)
var personality = {
	"extroversion": randf() * 100,   # Extroversion vs Introversion
	"agreeableness": randf() * 100,  # Agreeableness vs Antagonism
	"conscientiousness": randf() * 100,  # Conscientiousness vs Impulsivity
	"neuroticism": randf() * 100,    # Neuroticism vs Emotional Stability
	"openness": randf() * 100        # Openness vs Conservatism
}

var reputation = 0.0  # Reputation among other humans (-100 to 100)
var max_reputation = 100.0

# ------------------------
# Emotional system
# ------------------------
var emotions = {
	"happiness": 50.0,  # 0-100
	"anger": 0.0,       # 0-100
	"fear": 0.0,        # 0-100
	"empathy": 50.0,     # 0-100
	"jealousy": 0.0      # 0-100
}

# ------------------------
# Cognitive abilities
# ------------------------
var memory = []  # List of memories
var max_memories = 100  # Maximum number of memories to retain

# ------------------------
# Movement properties
# ------------------------
var move_speed := 60.0
var turn_speed := 1.5
var rotation_direction = 0.0
var resting = false  # Whether the entity is resting

# ------------------------
# Resource collection
# ------------------------
var carrying_capacity = 10  # Max resources this entity can carry
var current_resources = 0   # Currently carried resources
var resource_types = ["food", "water", "material"]  # Types of resources that can be carried
var resources = {}

# ------------------------
# Terrain perception and navigation
# ------------------------
var terrain_awareness = {}  # Awareness of surrounding terrain
var navigation_path = []  # Current navigation path
var target_position = null  # Target position to move towards
var world_generator = null  # Reference to the world generator
var terrain_movement_costs = {}  # Movement costs for different terrain types
var terrain_suitability = {}  # Suitability for different activities
var terrain_risk = {}  # Risk levels for different terrain types
var current_terrain_type = 1  # Current terrain type (default to grass)
var perception_range = 5  # Number of tiles to perceive in each direction
var pathfinding_grid = []  # Grid for pathfinding
var movement_speed_multiplier = 1.0  # Movement speed multiplier based on terrain

# ------------------------
# State properties
# ------------------------
var dead = false
var selected = false setget set_selected
var hovered = false setget set_hovered

# ------------------------
# Visual properties
# ------------------------
var color = Color(randf(), randf(), randf())  # Random color for each entity
var gender_color = Color(0.9, 0.7, 0.8) if gender else Color(0.7, 0.8, 0.9)  # Pink for female, blue for male

# ------------------------
# Signals
# ------------------------
signal HumanEntityClicked(entity)
signal HumanEntityDied(entity)
signal HumanEntityCollectedResource(entity, resource_type, amount)
signal HumanEntityEmotionChanged(entity, emotion_type, value)
signal HumanEntityNeedsChanged(entity, need_type, value)

# ------------------------
# Constructor
# ------------------------
func _init():
	# Initialize resources dictionary
	for resource_type in resource_types:
		resources[resource_type] = 0

# ------------------------
# Called when the node enters the scene tree for the first time.
# ------------------------
func _ready():
	# Set initial color based on gender
	self.modulate = gender_color
	
	# Start the resource collection timer
	var collect_timer = Timer.new()
	collect_timer.name = "CollectTimer"
	collect_timer.wait_time = 2.0  # Collect resources every 2 seconds
	collect_timer.connect("timeout", self, "_on_CollectTimer_timeout")
	add_child(collect_timer)
	collect_timer.start()
	
	# Find the world generator
	find_world_generator()
	
	# Initialize terrain properties from world generator
	initialize_terrain_properties()
	
	# Trigger initial draw
	self.update()

# ------------------------
# Physics processing - called at fixed intervals
# ------------------------
func _physics_process(delta):
	if not dead:
		# Update all needs
		update_needs(delta)
		
		# Update emotions based on needs and situation
		update_emotions(delta)
		
		# Update social properties
		update_social_properties(delta)
		
		# Check if entity should die
		if health <= 0 or hunger <= 0 or thirst <= 0 or age >= max_age:
			die()
		
		# Simple movement (random wandering)
		simple_move(delta)
		
		# Update terrain awareness
		update_terrain_awareness()

# ------------------------
# Update all needs systems
# ------------------------
func update_needs(delta):
	# ------------------------
	# Physiological needs
	# ------------------------
	if not resting:
		# Decrease hunger over time
		hunger = max(0, hunger - hunger_rate * delta)
		
		# Decrease thirst over time
		thirst = max(0, thirst - thirst_rate * delta)
		
		# Increase fatigue over time
		fatigue = min(max_fatigue, fatigue + fatigue_rate * delta)
	else:
		# Recover fatigue when resting
		fatigue = max(0, fatigue - fatigue_recovery_rate * delta)
		
		# Recover energy when resting
		energy = min(max_energy, energy + energy_consumption_base * 2 * delta)
	
	# Update health based on needs
	if hunger < 20 or thirst < 20 or fatigue > 80:
		# Decrease health if needs are not met
		health = max(0, health - delta * 2)
	else:
		# Recover health if needs are met
		health = min(max_health, health + health_recovery_rate * delta)
	
	# ------------------------
	# Psychological needs
	# ------------------------
	# Simple decay for psychological needs
	safety = max(0, safety - safety_decay_rate * delta)
	belonging = max(0, belonging - belonging_decay_rate * delta)
	self_esteem = max(0, self_esteem - self_esteem_decay_rate * delta)
	
	# ------------------------
	# Energy consumption
	# ------------------------
	var energy_consumption = energy_consumption_base
	if not resting:
		energy_consumption += abs(rotation_direction) + 0.5
	
	energy = max(0, energy - energy_consumption * delta)
	
	# Emit signals for need changes
	emit_signal("HumanEntityNeedsChanged", self, "hunger", hunger)
	emit_signal("HumanEntityNeedsChanged", self, "thirst", thirst)
	emit_signal("HumanEntityNeedsChanged", self, "fatigue", fatigue)
	emit_signal("HumanEntityNeedsChanged", self, "health", health)

# ------------------------
# Update emotions based on needs and situation
# ------------------------
func update_emotions(delta):
	# Base happiness on overall needs satisfaction
	var needs_satisfaction = (hunger + thirst + health + (max_fatigue - fatigue)) / (max_hunger + max_thirst + max_health + max_fatigue)
	var base_happiness = needs_satisfaction * 100
	
	# Adjust happiness based on safety, belonging, and self-esteem
	var social_happiness = (safety + belonging + self_esteem) / (max_safety + max_belonging + max_self_esteem) * 50
	
	# Update emotions
	emotions["happiness"] = lerp(emotions["happiness"], base_happiness + social_happiness, 0.1 * delta)
	emotions["anger"] = lerp(emotions["anger"], (100 - base_happiness) * 0.5, 0.1 * delta)
	emotions["fear"] = lerp(emotions["fear"], (100 - safety) * 0.8, 0.1 * delta)
	
	# Clamp emotions to 0-100 range
	for emotion_type in emotions.keys():
		emotions[emotion_type] = clamp(emotions[emotion_type], 0, 100)
		emit_signal("HumanEntityEmotionChanged", self, emotion_type, emotions[emotion_type])

# ------------------------
# Update social properties
# ------------------------
func update_social_properties(delta):
	# Age increases over time
	age += delta / (365 * 24 * 60 * 60)  # Convert seconds to years
	
	# Adjust personality based on experiences (simplified)
	for trait in personality.keys():
		personality[trait] = clamp(personality[trait] + rand_range(-0.1, 0.1) * delta, 0, 100)

# ------------------------
# Find the world generator node in the scene tree
# ------------------------
func find_world_generator():
	print("HumanEntity: Finding world generator...")
	
	# Look for world generator in the entire scene tree using SceneTree
	var nodes = get_tree().get_nodes_in_group("world_generator")
	
	if nodes.size() > 0:
		world_generator = nodes[0]
		print("HumanEntity: Found world generator in group")
		return
	
	# Last resort: check siblings and children
	print("HumanEntity: Checking siblings and children...")
	var parent = get_parent()
	if parent:
		# Check parent's children (siblings)
		for child in parent.get_children():
			if child != self and child.has_method("get_terrain_at_position"):
				world_generator = child
				print("HumanEntity: Found world generator in siblings")
				return
		
		# Check parent itself
		if parent.has_method("get_terrain_at_position"):
			world_generator = parent
			print("HumanEntity: Found world generator in parent")
			return
	
	print("HumanEntity: Warning - World generator not found!")

# ------------------------
# Initialize terrain properties from world generator
# ------------------------
func initialize_terrain_properties():
	if world_generator:
		# Get terrain movement costs from world generator
		var terrain_types = [0, 1, 2, 3]  # Water, Grass, Desert, Mountain
		for terrain_type in terrain_types:
			terrain_movement_costs[terrain_type] = world_generator.get_terrain_movement_cost(terrain_type)
			terrain_suitability[terrain_type] = {}
			terrain_suitability[terrain_type]["gathering"] = world_generator.get_terrain_suitability(terrain_type, "gathering")
			terrain_suitability[terrain_type]["hunting"] = world_generator.get_terrain_suitability(terrain_type, "hunting")
			terrain_suitability[terrain_type]["building"] = world_generator.get_terrain_suitability(terrain_type, "building")
			terrain_suitability[terrain_type]["resting"] = world_generator.get_terrain_suitability(terrain_type, "resting")
			terrain_risk[terrain_type] = world_generator.get_terrain_risk(terrain_type)

# ------------------------
# Update terrain awareness
# ------------------------
func update_terrain_awareness():
	if not world_generator:
		return
	
	# Clear previous terrain awareness
	terrain_awareness.clear()
	
	# Get current position in world coordinates
	var world_pos = global_position
	
	# Update current terrain type
	current_terrain_type = world_generator.get_terrain_at_position(world_pos)
	
	# Calculate movement speed multiplier based on terrain
	movement_speed_multiplier = 1.0 / (terrain_movement_costs.get(current_terrain_type, 1.0) if terrain_movement_costs.has(current_terrain_type) else 1.0)
	
	# Check surrounding tiles for terrain awareness
	var tile_size = 32.0  # Match the world generator's tile size
	var tile_pos = Vector2(int(world_pos.x / tile_size), int(world_pos.y / tile_size))
	
	for y_offset in range(-perception_range, perception_range + 1):
		for x_offset in range(-perception_range, perception_range + 1):
			var check_tile_pos = tile_pos + Vector2(x_offset, y_offset)
			var terrain_type = world_generator.get_terrain_by_tile(check_tile_pos.x, check_tile_pos.y)
			var world_check_pos = Vector2(check_tile_pos.x * tile_size, check_tile_pos.y * tile_size)
			
			# Add to terrain awareness map
			terrain_awareness[str(check_tile_pos)] = {
				"position": world_check_pos,
				"terrain_type": terrain_type,
				"movement_cost": terrain_movement_costs.get(terrain_type, 1.0),
				"risk": terrain_risk.get(terrain_type, 0.5),
				"distance": world_check_pos.distance_to(world_pos)
			}

# ------------------------
# Simple pathfinding algorithm (A*)
# ------------------------
func calculate_path(start_pos, target_pos):
	if not world_generator:
		return []
	
	var tile_size = 32.0
	var start_tile = Vector2(int(start_pos.x / tile_size), int(start_pos.y / tile_size))
	var target_tile = Vector2(int(target_pos.x / tile_size), int(target_pos.y / tile_size))
	
	# Check if start and target are the same
	if start_tile == target_tile:
		return [target_pos]
	
	# Open and closed sets for A*
	var open_set = [start_tile]
	var closed_set = []
	
	# Dictionaries to track came from, g score, and f score
	var came_from = {}
	var g_score = {}
	var f_score = {}
	
	# Initialize scores
	g_score[str(start_tile)] = 0.0
	f_score[str(start_tile)] = start_tile.distance_to(target_tile)
	
	while open_set.size() > 0:
		# Find the tile with the lowest f score
		var current = null
		var lowest_f = INF
		for tile in open_set:
			var f = f_score.get(str(tile), INF)
			if f < lowest_f:
				lowest_f = f
				current = tile
		
		# Check if we've reached the target
		if current == target_tile:
			return reconstruct_path(came_from, current, tile_size)
		
		# Remove current from open set and add to closed set
		open_set.erase(current)
		closed_set.append(current)
		
		# Check neighbors
		var neighbors = [
			Vector2(current.x + 1, current.y),
			Vector2(current.x - 1, current.y),
			Vector2(current.x, current.y + 1),
			Vector2(current.x, current.y - 1)
		]
		
		for neighbor in neighbors:
			# Skip if in closed set
			if neighbor in closed_set:
				continue
			
			# Get terrain type for neighbor
			var terrain_type = world_generator.get_terrain_by_tile(neighbor.x, neighbor.y)
			
			# Skip water tiles (not traversable)
			if terrain_type == 0:  # WATER
				continue
			
			# Calculate tentative g score
			var movement_cost = terrain_movement_costs.get(terrain_type, 1.0)
			var tentative_g_score = g_score.get(str(current), INF) + movement_cost
			
			# Add to open set if not already there
			if not neighbor in open_set:
				open_set.append(neighbor)
			# Skip if this path is not better
			elif tentative_g_score >= g_score.get(str(neighbor), INF):
				continue
			
			# This is a better path
			came_from[str(neighbor)] = current
			g_score[str(neighbor)] = tentative_g_score
			f_score[str(neighbor)] = tentative_g_score + neighbor.distance_to(target_tile)
	
	# If no path found, return empty array
	return []

# ------------------------
# Reconstruct path from came_from dictionary
# ------------------------
func reconstruct_path(came_from, current, tile_size):
	var path = []
	path.append(Vector2(current.x * tile_size + tile_size/2, current.y * tile_size + tile_size/2))
	
	while str(current) in came_from:
		current = came_from[str(current)]
		path.append(Vector2(current.x * tile_size + tile_size/2, current.y * tile_size + tile_size/2))
	
	# Reverse the path to get from start to target
	path.invert()
	return path

# ------------------------
# Follow a generated path
# ------------------------
func follow_path(delta):
	if navigation_path.size() == 0:
		return false
	
	# Get the next waypoint
	var next_waypoint = navigation_path[0]
	var direction = (next_waypoint - global_position).normalized()
	
	# Move towards the waypoint
	var adjusted_speed = move_speed * movement_speed_multiplier
	var velocity = direction * adjusted_speed * delta
	move_and_slide(velocity, Vector2.UP)
	
	# Check if we've reached the waypoint
	if global_position.distance_to(next_waypoint) < 10:
		navigation_path.remove(0)
		# If this was the last waypoint, return true
		if navigation_path.size() == 0:
			target_position = null
			return true
	
	return false

# ------------------------
# Set a new navigation target
# ------------------------
func set_navigation_target(target_pos):
	target_position = target_pos
	if world_generator:
		navigation_path = calculate_path(global_position, target_pos)

# ------------------------
# Simple movement behavior with terrain awareness and path following
# ------------------------
func simple_move(delta):
	# Ensure navigation_path is initialized
	if navigation_path == null:
		navigation_path = []
	
	# Follow path if one exists
	if navigation_path.size() > 0:
		follow_path(delta)
		return
	
	# Randomly change direction occasionally
	if randf() < 0.02:  # 2% chance each frame to change direction
		rotation_direction = randf() * 2 - 1  # -1 to 1
	
	# Randomly decide to rest based on fatigue
	if fatigue > 70 and randf() < 0.01:
		resting = true
	elif fatigue < 30 and resting:
		resting = false
	
	if not resting:
		# Calculate movement direction without rotating the entity
		var movement_angle = rotation_direction * PI  # Convert to radians (-PI to PI)
		
		# Adjust movement speed based on terrain
		var adjusted_speed = move_speed * movement_speed_multiplier
		
		# Move in the calculated direction
		var velocity = Vector2(cos(movement_angle), sin(movement_angle)) * adjusted_speed * delta
		move_and_slide(velocity, Vector2.UP)
		
		# Add terrain-aware behavior: prefer suitable terrain for gathering
		if randf() < 0.01:  # 1% chance to check for better terrain
			check_for_better_terrain()

# ------------------------
# Check for better terrain nearby for gathering
# ------------------------
func check_for_better_terrain():
	if terrain_awareness.size() == 0:
		return
	
	var best_terrain_score = 0.0
	var best_terrain_pos = null
	
	# Evaluate surrounding terrain for gathering suitability
	for tile_str in terrain_awareness.keys():
		var terrain_info = terrain_awareness[tile_str]
		var terrain_type = terrain_info["terrain_type"]
		var distance = terrain_info["distance"]
		
		# Skip water tiles
		if terrain_type == 0:  # WATER
			continue
		
		# Calculate terrain score: higher suitability * inverse distance
		var gathering_suitability = terrain_suitability.get(terrain_type, {}).get("gathering", 0.5)
		var risk_factor = 1.0 - terrain_risk.get(terrain_type, 0.5) / 2.0  # Lower risk is better
		var score = gathering_suitability * risk_factor / (distance + 1.0)  # Add 1 to avoid division by zero
		
		if score > best_terrain_score:
			best_terrain_score = score
			best_terrain_pos = terrain_info["position"]
	
	# If found a better terrain, set it as target
	if best_terrain_pos and best_terrain_score > 0.2:
		set_navigation_target(best_terrain_pos)

# ------------------------
# Resource collection and consumption
# ------------------------
func _on_CollectTimer_timeout():
	if not dead:
		# Simulate collecting resources based on skills
		var gathering_efficiency = 1 + skills["gathering"] / 100
		var collected = min(carrying_capacity - current_resources, 3 * gathering_efficiency)  # Increased collection amount
		current_resources += collected
		
		if collected > 0:
			# Determine resource type based on current needs (prioritize the most urgent need)
			var resource_type = "food"
			if thirst < hunger:
				resource_type = "water"
			resources[resource_type] += collected
			
			# Increase hunger/thirst when collecting resources
			if resource_type == "food":
				hunger = min(max_hunger, hunger + collected * 10)  # Increased hunger gain
			elif resource_type == "water":
				thirst = min(max_thirst, thirst + collected * 15)  # Increased thirst gain
			
			emit_signal("HumanEntityCollectedResource", self, resource_type, collected)

# ------------------------
# Consume resources
# ------------------------
func consume_resources(resource_type, amount):
	if resource_type in resources and resources[resource_type] >= amount:
		resources[resource_type] -= amount
		current_resources -= amount
		
		if resource_type == "food":
			hunger = min(max_hunger, hunger + amount * 8)
		elif resource_type == "water":
			thirst = min(max_thirst, thirst + amount * 10)

# ------------------------
# Memory management
# ------------------------
func add_memory(event):
	# Add memory to the list
	memory.append({
		"event": event,
		"timestamp": Globals.elapsed_time,
		"position": Vector2(position.x, position.y)  # Create a copy of the position vector
	})
	
	# Limit the number of memories
	if memory.size() > max_memories:
		memory.remove(0)

# ------------------------
# Die method
# ------------------------
func die():
	if can_die:
		dead = true
		emit_signal("HumanEntityDied", self)
		queue_free()

# ------------------------
# Handle mouse clicks
# ------------------------
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("HumanEntityClicked", self)

# ------------------------
# Set selected state
# ------------------------
func set_selected(select):
	selected = select
	self.update()

# ------------------------
# Set hovered state
# ------------------------
func set_hovered(new_value):
	if hovered != new_value:
		hovered = new_value
		# Change appearance when hovered
		if hovered:
			self.modulate = gender_color.lightened(0.3)
		else:
			self.modulate = gender_color

# ------------------------
# Draw method for visual representation
# ------------------------
func _draw():
	# Draw simple humanoid shape
	
	# Head (circle)
	var head_radius = radius * 0.4
	var head_pos = Vector2(0, -radius * 0.3)
	draw_circle(head_pos, head_radius, gender_color)
	
	# Body (rectangle)
	var body_width = radius * 0.6
	var body_height = radius * 0.8
	var body_pos = Vector2(-body_width/2, head_pos.y + head_radius)
	draw_rect(Rect2(body_pos.x, body_pos.y, body_width, body_height), gender_color)
	
	# Arms (rectangles)
	var arm_width = radius * 0.2
	var arm_height = radius * 0.6
	var arm_y = body_pos.y + body_height * 0.3
	
	# Left arm
	var left_arm_pos = Vector2(body_pos.x - arm_width, arm_y)
	draw_rect(Rect2(left_arm_pos.x, left_arm_pos.y, arm_width, arm_height), gender_color)
	
	# Right arm
	var right_arm_pos = Vector2(body_pos.x + body_width, arm_y)
	draw_rect(Rect2(right_arm_pos.x, right_arm_pos.y, arm_width, arm_height), gender_color)
	
	# Legs (rectangles)
	var leg_width = radius * 0.2
	var leg_height = radius * 0.7
	var leg_y = body_pos.y + body_height
	
	# Left leg
	var left_leg_pos = Vector2(body_pos.x + body_width * 0.2, leg_y)
	draw_rect(Rect2(left_leg_pos.x, left_leg_pos.y, leg_width, leg_height), gender_color)
	
	# Right leg
	var right_leg_pos = Vector2(body_pos.x + body_width * 0.6, leg_y)
	draw_rect(Rect2(right_leg_pos.x, right_leg_pos.y, leg_width, leg_height), gender_color)
	
	# Draw status bars above the head
	var bar_width = radius * 1.5
	var bar_height = 3
	var bar_spacing = 4
	var top_pos = Vector2(-bar_width/2, -radius - 10)
	
	# Health bar (green)
	var health_background_pos = top_pos
	draw_rect(Rect2(health_background_pos.x, health_background_pos.y, bar_width, bar_height), Color(0.3, 0.3, 0.3))
	var health_width = bar_width * (health / max_health)
	draw_rect(Rect2(health_background_pos.x, health_background_pos.y, health_width, bar_height), Color(0.2, 0.8, 0.2))
	
	# Hunger bar (brown), positioned below health bar
	var hunger_background_pos = Vector2(top_pos.x, top_pos.y + bar_height + bar_spacing)
	draw_rect(Rect2(hunger_background_pos.x, hunger_background_pos.y, bar_width, bar_height), Color(0.3, 0.3, 0.3))
	var hunger_width = bar_width * (hunger / max_hunger)
	draw_rect(Rect2(hunger_background_pos.x, hunger_background_pos.y, hunger_width, bar_height), Color(0.5, 0.35, 0.0))
	
	# Thirst bar (blue), positioned below hunger bar
	var thirst_background_pos = Vector2(top_pos.x, hunger_background_pos.y + bar_height + bar_spacing)
	draw_rect(Rect2(thirst_background_pos.x, thirst_background_pos.y, bar_width, bar_height), Color(0.3, 0.3, 0.3))
	var thirst_width = bar_width * (thirst / max_thirst)
	draw_rect(Rect2(thirst_background_pos.x, thirst_background_pos.y, thirst_width, bar_height), Color(0.2, 0.4, 0.8))
	
	# Fatigue bar (purple), positioned below thirst bar
	var fatigue_background_pos = Vector2(top_pos.x, thirst_background_pos.y + bar_height + bar_spacing)
	draw_rect(Rect2(fatigue_background_pos.x, fatigue_background_pos.y, bar_width, bar_height), Color(0.3, 0.3, 0.3))
	var fatigue_width = bar_width * (fatigue / max_fatigue)
	draw_rect(Rect2(fatigue_background_pos.x, fatigue_background_pos.y, fatigue_width, bar_height), Color(0.6, 0.2, 0.8))

# ------------------------
# Method to get fitness/score of the entity
# ------------------------
func fitness():
	return (hunger + thirst + health + (max_fatigue - fatigue) + energy) / 5  # Simple average of all physical stats