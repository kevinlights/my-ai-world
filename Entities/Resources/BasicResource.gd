extends Area2D

class_name BasicResource

# Properties
var resource_type = "basic"
var value = 5  # Amount of resources this item provides
var consumed = false

# Visual properties
var color = Color(0.8, 0.6, 0.2)  # Brownish color for basic resources

func _ready():
	# Visual appearance is handled by the _draw function
	
	self.modulate = color
	
	# Connect to body enter signal to handle collection
	self.connect("body_entered", self, "_on_BodyEntered")
	
	# Trigger initial draw
	self.update()

func _on_BodyEntered(body):
	if body is SimpleHumanEntity and not consumed:
		body.consume_resources(value)  # Pass the resource value to the human entity
		consumed = true
		queue_free()

# Draw method for fallback if no sprite is available
func _draw():
	# Draw a simple square representing the resource
	var size = 10
	draw_rect(Rect2(-size/2, -size/2, size, size), color)
