extends Node2D

# Enhanced world generation script with biomes, smooth transitions and resource distribution

# Basic properties
var world_size = Vector2(800, 800)  # Smaller default world size
var tile_size = 32.0
var noise_scale = 0.01
var biome_noise_scale = 0.005
var resource_noise_scale = 0.02

# Biome types
var BIOME_TROPICAL = 0
var BIOME_TEMPERATE = 1
var BIOME_ARID = 2
var BIOME_TUNDRA = 3

# Biome thresholds
var biome_thresholds = {
	BIOME_TROPICAL: 0.25,
	BIOME_TEMPERATE: 0.5,
	BIOME_ARID: 0.75,
	BIOME_TUNDRA: 1.0
}

# Terrain types
var TERRAIN_WATER = 0
var TERRAIN_GRASS = 1
var TERRAIN_DESERT = 2
var TERRAIN_MOUNTAIN = 3

# Internal variables
var noise = null
var biome_noise = null
var resource_noise = null
var world_data = []
var terrain_tiles = []
var resource_tiles = []

func _ready():
	# Initialize noises
	noise = OpenSimplexNoise.new()
	noise.seed = 12345
	noise.octaves = 4
	noise.persistence = 0.5
	noise.lacunarity = 2.0
	
	# Biome noise for biome generation
	biome_noise = OpenSimplexNoise.new()
	biome_noise.seed = noise.seed + 1
	biome_noise.octaves = 3
	biome_noise.persistence = 0.4
	biome_noise.lacunarity = 2.5
	
	# Resource noise for resource distribution
	resource_noise = OpenSimplexNoise.new()
	resource_noise.seed = noise.seed + 2
	resource_noise.octaves = 5
	resource_noise.persistence = 0.6
	resource_noise.lacunarity = 2.0
	
	# Generate world
	generate_world()
	
	# Smooth terrain transitions
	smooth_terrain_transitions()
	
	# Draw terrain
	draw_terrain()
	
	# Generate resources
	generate_resources()

func generate_world():
	var width = int(world_size.x / tile_size)
	var height = int(world_size.y / tile_size)
	
	world_data = []
	
	for y in range(height):
		var row = []
		for x in range(width):
			# Generate noise values
			var noise_value = noise.get_noise_2d(x * noise_scale, y * noise_scale)
			var normalized_noise = (noise_value + 1.0) / 2.0
			
			# Get biome type
			var biome_value = biome_noise.get_noise_2d(x * biome_noise_scale, y * biome_noise_scale)
			var normalized_biome = (biome_value + 1.0) / 2.0
			var biome_type = get_biome_type(normalized_biome)
			
			# Determine terrain type based on noise and biome
			var terrain_type = get_terrain_type(normalized_noise, biome_type)
			
			row.append(terrain_type)
		world_data.append(row)

# Get biome type based on noise value
func get_biome_type(normalized_biome):
	if normalized_biome < biome_thresholds[BIOME_TROPICAL]:
		return BIOME_TROPICAL
	elif normalized_biome < biome_thresholds[BIOME_TEMPERATE]:
		return BIOME_TEMPERATE
	elif normalized_biome < biome_thresholds[BIOME_ARID]:
		return BIOME_ARID
	else:
		return BIOME_TUNDRA

# Get terrain type based on noise value and biome
func get_terrain_type(normalized_noise, biome_type):
	# Base terrain mapping
	var terrain_type = TERRAIN_WATER
	
	match biome_type:
		BIOME_TROPICAL:
			# Tropical biome: more water and grass
			if normalized_noise > 0.25:
				terrain_type = TERRAIN_GRASS
			if normalized_noise > 0.8:
				terrain_type = TERRAIN_MOUNTAIN
			
		BIOME_TEMPERATE:
			# Temperate biome: balanced terrain
			if normalized_noise > 0.3:
				terrain_type = TERRAIN_GRASS
			if normalized_noise > 0.7:
				terrain_type = TERRAIN_MOUNTAIN
			
		BIOME_ARID:
			# Arid biome: more desert
			if normalized_noise > 0.2:
				terrain_type = TERRAIN_DESERT
			if normalized_noise > 0.6:
				terrain_type = TERRAIN_MOUNTAIN
			
		BIOME_TUNDRA:
			# Tundra biome: more grass and mountains
			if normalized_noise > 0.35:
				terrain_type = TERRAIN_GRASS
			if normalized_noise > 0.75:
				terrain_type = TERRAIN_MOUNTAIN
	
	return terrain_type

# Smooth terrain transitions by averaging with neighbors
func smooth_terrain_transitions():
	var actual_height = world_data.size()
	if actual_height == 0:
		return
	
	var actual_width = world_data[0].size()
	var new_world_data = []
	
	# Create a copy of the current world data
	for y in range(actual_height):
		new_world_data.append(world_data[y].duplicate())
	
	# Smooth each tile by considering its neighbors
	for y in range(actual_height):
		for x in range(actual_width):
			# Skip edge tiles for simplicity
			if x == 0 or x == actual_width - 1 or y == 0 or y == actual_height - 1:
				continue
			
			# Get neighbors
			var neighbors = [
				world_data[y-1][x-1], world_data[y-1][x], world_data[y-1][x+1],
				world_data[y][x-1],                      world_data[y][x+1],
				world_data[y+1][x-1], world_data[y+1][x], world_data[y+1][x+1]
			]
			
			# Count terrain types in neighbors
			var terrain_counts = {}
			for neighbor in neighbors:
				if neighbor in terrain_counts:
					terrain_counts[neighbor] += 1
				else:
					terrain_counts[neighbor] = 1
			
			# Find the most common terrain type among neighbors
			var most_common_terrain = world_data[y][x]
			var max_count = 0
			for terrain in terrain_counts.keys():
				if terrain_counts[terrain] > max_count:
					max_count = terrain_counts[terrain]
					most_common_terrain = terrain
			
			# Only smooth if at least 5 neighbors have the same terrain type
			if max_count >= 5:
				new_world_data[y][x] = most_common_terrain
	
	# Update world data with smoothed version
	world_data = new_world_data

func draw_terrain():
	var terrain_colors = [
		Color(0.2, 0.4, 0.8),  # WATER
		Color(0.3, 0.6, 0.2),  # GRASS
		Color(0.9, 0.8, 0.5),  # DESERT
		Color(0.5, 0.5, 0.5)   # MOUNTAIN
	]
	
	var height = world_data.size()
	if height == 0:
		return
	
	var width = world_data[0].size()
	
	for y in range(height):
		for x in range(width):
			var terrain_type = world_data[y][x]  # Fixed: use y,x instead of x,y
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

# Generate resources based on terrain type and resource noise
func generate_resources():
	var height = world_data.size()
	if height == 0:
		return
	
	var width = world_data[0].size()
	var resource_colors = [
		Color(1.0, 0.2, 0.2),  # Food resource (red)
		Color(0.2, 0.2, 1.0),  # Water resource (blue)
		Color(0.8, 0.6, 0.2),  # Material resource (orange)
		Color(0.6, 0.2, 0.8)   # Special resource (purple)
	]
	
	for y in range(height):
		for x in range(width):
			var terrain_type = world_data[y][x]  # Fixed: use y,x instead of x,y
			
			# Skip water tiles for resource generation
			if terrain_type == TERRAIN_WATER:
				continue
			
			# Generate resource noise value
			var resource_value = resource_noise.get_noise_2d(x * resource_noise_scale, y * resource_noise_scale)
			var normalized_resource = abs(resource_value)
			
			# Generate resources based on terrain type and noise
			if normalized_resource > 0.85:
				# Determine resource type based on terrain
				var resource_type = 0  # Default to food
				match terrain_type:
					TERRAIN_GRASS:
						resource_type = 0  # Food resource
					TERRAIN_DESERT:
						resource_type = 1  # Water resource
					TERRAIN_MOUNTAIN:
						resource_type = 2  # Material resource
				
				# Create resource tile
				var tile_position = Vector2(x * tile_size, y * tile_size) - world_size / 2
				var resource_radius = tile_size * 0.3
				
				var resource = ColorRect.new()
				resource.rect_size = Vector2(resource_radius * 2, resource_radius * 2)
				resource.rect_position = tile_position + Vector2(tile_size / 2 - resource_radius, tile_size / 2 - resource_radius)
				resource.color = resource_colors[resource_type]
				resource.name = "Resource_" + str(x) + "_" + str(y)
				
				# Add collision shape
				var collision_shape = CollisionShape2D.new()
				var circle_shape = CircleShape2D.new()
				circle_shape.radius = resource_radius
				collision_shape.shape = circle_shape
				resource.add_child(collision_shape)
				
				add_child(resource)
				resource_tiles.append(resource)

func get_terrain_at_position(position):
	var tile_x = int((position.x + world_size.x / 2) / tile_size)
	var tile_y = int((position.y + world_size.y / 2) / tile_size)
	
	var height = world_data.size()
	var width = world_data[0].size() if height > 0 else 0
	
	# Check if tile coordinates are within bounds
	if tile_y >= 0 and tile_y < height and tile_x >= 0 and tile_x < width:
		return world_data[tile_y][tile_x]  # Fixed: use tile_y, tile_x instead of tile_x, tile_y
	else:
		return 0  # Default to water
