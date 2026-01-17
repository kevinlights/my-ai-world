extends KinematicBody2D

class_name SimpleHumanEntity

# Properties
var type = "SimpleHumanEntity"
var radius := 25.0  # Slightly larger than Boppie to distinguish visually
var can_die := true

# Basic survival needs
var hunger = 100.0  # Hunger level (0-100), decreases over time
var max_hunger = 100.0
var hunger_rate = 5.0  # How fast hunger decreases per second

var health = 100.0  # Health level (0-100), affected by hunger
var max_health = 100.0

var energy = 100.0  # Energy level for actions
var max_energy = 100.0
var energy_consumption_base = 1.0  # Base energy consumption rate

# Movement properties
var move_speed := 60.0
var turn_speed := 1.5
var rotation_direction = 0.0

# Resource collection
var carrying_capacity = 10  # Max resources this entity can carry
var current_resources = 0   # Currently carried resources

# State properties
var dead = false
var selected = false setget set_selected
var hovered = false setget set_hovered

# Visual properties
var color = Color(randf(), randf(), randf())  # Random color for each entity

# Signals
signal SimpleHumanEntityClicked(entity)
signal SimpleHumanEntityDied(entity)
signal SimpleHumanEntityCollectedResource(entity, amount)

# Constructor
func _init():
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set initial random color
	self.modulate = color
	
	# Start the resource collection timer
	var collect_timer = Timer.new()
	collect_timer.name = "CollectTimer"
	collect_timer.wait_time = 2.0  # Collect resources every 2 seconds
	collect_timer.connect("timeout", self, "_on_CollectTimer_timeout")
	add_child(collect_timer)
	collect_timer.start()
	
	# Trigger initial draw
	self.update()

# Physics processing - called at fixed intervals
func _physics_process(delta):
	if not dead:
		# Update basic needs
		update_needs(delta)
		
		# Check if entity should die
		if health <= 0 or hunger <= 0:
			die()
		
		# Simple movement (random wandering)
		simple_move(delta)

# Update survival needs
func update_needs(delta):
	# Decrease hunger over time
	hunger = max(0, hunger - hunger_rate * delta)
	
	# If hunger is too low, health decreases
	if hunger <= 20:
		health = max(0, health - 2 * delta)
	else:
		health = min(max_health, health + 0.5 * delta)  # Health recovers slowly when fed
	
	# Consume energy based on movement and existence
	energy = max(0, energy - (energy_consumption_base + abs(rotation_direction) + 0.5) * delta)

# Simple movement behavior (random wandering)
func simple_move(delta):
	# Randomly change direction occasionally
	if randf() < 0.02:  # 2% chance each frame to change direction
		rotation_direction = randf() * 2 - 1  # -1 to 1
	
	# Apply rotation
	self.rotation += rotation_direction * turn_speed * delta
	
	# Move forward
	var velocity = Vector2(cos(rotation), sin(rotation)) * move_speed * delta
	self.move_and_slide(velocity, Vector2.UP)

# Collect resources when timer fires
func _on_CollectTimer_timeout():
	if not dead and hunger > 10:  # Only collect if not starving
		# Simulate collecting resources
		var collected = min(carrying_capacity - current_resources, 2)
		current_resources += collected
		
		if collected > 0:
			# Increase hunger when eating
			hunger = min(max_hunger, hunger + collected * 5)
			emit_signal("SimpleHumanEntityCollectedResource", self, collected)

# Eat collected resources to restore hunger
func consume_resources(amount):
	if current_resources >= amount:
		current_resources -= amount
		hunger = min(max_hunger, hunger + amount * 8)  # Eating restores hunger significantly

# Die method
func die():
	if can_die:
		dead = true
		emit_signal("SimpleHumanEntityDied", self)
		queue_free()

# Handle mouse clicks
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("SimpleHumanEntityClicked", self)

# Set selected state
func set_selected(select):
	selected = select
	self.update()

# Set hovered state
func set_hovered(new_value):
	if hovered != new_value:
		hovered = new_value
		# Change appearance when hovered
		if hovered:
			self.modulate = color.lightened(0.3)
		else:
			self.modulate = color

# Draw method for visual representation
func _draw():
	# Draw a circle representing the entity
	draw_circle(Vector2.ZERO, radius, color)
	
	# Draw health bar above the entity
	var bar_width = radius * 2
	var bar_height = 4
	var bar_pos = Vector2(-bar_width/2, -radius - 10)
	
	# Background of health bar
	draw_rect(Rect2(bar_pos.x, bar_pos.y, bar_width, bar_height), Color.red)
	
	# Health portion of the bar
	var health_width = bar_width * (health / max_health)
	draw_rect(Rect2(bar_pos.x, bar_pos.y, health_width, bar_height), Color.green)
	
	# Draw hunger bar below the entity
	var hunger_bar_pos = Vector2(-bar_width/2, radius + 6)
	draw_rect(Rect2(hunger_bar_pos.x, hunger_bar_pos.y, bar_width, bar_height), Color(0.3, 0.3, 0.3))
	var hunger_width = bar_width * (hunger / max_hunger)
	draw_rect(Rect2(hunger_bar_pos.x, hunger_bar_pos.y, hunger_width, bar_height), Color.yellow)

# Method to get fitness/score of the entity
func fitness():
	return (hunger + health + energy) / 3  # Simple average of all stats
