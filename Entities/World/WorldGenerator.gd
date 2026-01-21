extends Node2D

# Minimal world generation script

# Basic properties
var world_size = Vector2(2000, 2000)
var tile_size = 32.0
var noise_scale = 0.01

# Internal variables
var noise = null
var world_data = []
var terrain_tiles = []

func _ready():
	# Initialize noise
	noise = OpenSimplexNoise.new()
	noise.seed = 12345
	noise.octaves = 4
	noise.persistence = 0.5
	noise.lacunarity = 2.0
	
	# Generate world
	generate_world()
	
	# Draw terrain
	draw_terrain()

func generate_world():
	var width = int(world_size.x / tile_size)
	var height = int(world_size.y / tile_size)
	
	world_data = []
	
	for y in range(height):
		var row = []
		for x in range(width):
			var noise_value = noise.get_noise_2d(x * noise_scale, y * noise_scale)
			var normalized_noise = (noise_value + 1.0) / 2.0
			
			# Simple terrain mapping using numbers instead of enum
			var terrain_type = 0  # WATER
			if normalized_noise > 0.3:
				terrain_type = 1  # GRASS
			if normalized_noise > 0.5:
				terrain_type = 2  # DESERT
			if normalized_noise > 0.7:
				terrain_type = 3  # MOUNTAIN
			
			row.append(terrain_type)
		world_data.append(row)

func draw_terrain():
	var terrain_colors = [
		Color(0.2, 0.4, 0.8),  # WATER
		Color(0.3, 0.6, 0.2),  # GRASS
		Color(0.9, 0.8, 0.5),  # DESERT
		Color(0.5, 0.5, 0.5)   # MOUNTAIN
	]
	
	var width = world_data.size()
	if width == 0:
		return
	
	var height = world_data[0].size()
	
	for y in range(height):
		for x in range(width):
			var terrain_type = world_data[x][y]
			var tile_position = Vector2(x * tile_size, y * tile_size) - world_size / 2
			
			# Create a simple tile
			var tile = ColorRect.new()
			tile.rect_size = Vector2(tile_size, tile_size)
			tile.rect_position = tile_position
			tile.color = terrain_colors[terrain_type]
			
			# Add collision shape
			var collision_shape = CollisionShape2D.new()
			var rectangle_shape = RectangleShape2D.new()
			rectangle_shape.extents = Vector2(tile_size / 2, tile_size / 2)
			collision_shape.shape = rectangle_shape
			tile.add_child(collision_shape)
			
			add_child(tile)
			terrain_tiles.append(tile)

func get_terrain_at_position(position):
	var tile_x = int((position.x + world_size.x / 2) / tile_size)
	var tile_y = int((position.y + world_size.y / 2) / tile_size)
	
	if tile_x >= 0 and tile_x < world_data.size() and tile_y >= 0 and tile_y < world_data[0].size():
		return world_data[tile_x][tile_y]
	else:
		return 0  # Default to water
