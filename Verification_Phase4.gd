# Verification script for Phase 4: Terrain Perception and Navigation
# This script tests all components of the terrain perception and navigation system

extends Node2D

var test_results = []
var total_tests = 0
var passed_tests = 0
var world_generator = null
var test_human = null

func _ready():
	print("\n=== Phase 4: Terrain Perception and Navigation Verification ===")
	
	# Load and initialize world generator
	load_world_generator()
	
	# Wait for world generator to be ready
	yield(get_tree(), "idle_frame")
	
	# Create a test human entity
	create_test_human()
	
	# Wait for human entity to initialize
	yield(get_tree(), "idle_frame")
	
	# Run all tests
	run_all_tests()
	
	# Print final results
	print_results()
	
	# Quit after 2 seconds
	yield(get_tree().create_timer(2.0), "timeout")
	get_tree().quit()

func load_world_generator():
	# Load the world generator scene
	var world_scene = preload("res://Entities/World/WorldGenerator.tscn")
	
	# Create an instance
	world_generator = world_scene.instance()
	
	# Add to scene
	add_child(world_generator)
	
	log_test("World generator loaded", true)

func create_test_human():
	# Load the human entity scene
	var human_scene = preload("res://Entities/Human/HumanEntity.tscn")
	
	# Create a new instance
	test_human = human_scene.instance()
	
	# Set position at center of the world
	test_human.position = Vector2(0, 0)
	
	# Add to scene
	add_child(test_human)
	
	log_test("Human entity created", true)

func run_all_tests():
	print("\n--- Running all tests ---")
	
	# Test 1: World generator connection
	test_world_generator_connection()
	
	# Test 2: Terrain property initialization
	test_terrain_property_initialization()
	
	# Test 3: Terrain awareness update
	test_terrain_awareness_update()
	
	# Test 4: Movement speed multiplier
	test_movement_speed_multiplier()
	
	# Test 5: Path calculation
	test_path_calculation()
	
	# Test 6: Better terrain detection
	test_better_terrain_detection()
	
	print("\n--- All tests completed ---")

func test_world_generator_connection():
	total_tests += 1
	var test_name = "World generator connection"
	
	if test_human.world_generator != null:
		log_test(test_name, true)
	else:
		log_test(test_name, false, "Human entity failed to connect to world generator")

func test_terrain_property_initialization():
	total_tests += 1
	var test_name = "Terrain property initialization"
	
	var success = true
	var error_message = ""
	
	if test_human.terrain_movement_costs.size() == 0:
		success = false
		error_message = "Terrain movement costs not initialized"
	elif test_human.terrain_suitability.size() == 0:
		success = false
		error_message = "Terrain suitability not initialized"
	elif test_human.terrain_risk.size() == 0:
		success = false
		error_message = "Terrain risk not initialized"
	
	log_test(test_name, success, error_message)

func test_terrain_awareness_update():
	total_tests += 1
	var test_name = "Terrain awareness update"
	
	# Clear previous terrain awareness
	test_human.terrain_awareness.clear()
	
	# Force update terrain awareness
	test_human.update_terrain_awareness()
	
	if test_human.terrain_awareness.size() > 0:
		log_test(test_name, true, "Detected " + str(test_human.terrain_awareness.size()) + " terrain tiles")
	else:
		log_test(test_name, false, "No terrain tiles detected")

func test_movement_speed_multiplier():
	total_tests += 1
	var test_name = "Movement speed multiplier"
	
	# Test on different terrain types by moving human to different positions
	var test_positions = [
		Vector2(0, 0),         # Center - likely grass
		Vector2(200, 200),     # Some other terrain
		Vector2(-200, -200),   # Another area
		Vector2(300, -300)     # Edge area
	]
	
	var multipliers = []
	
	for pos in test_positions:
		test_human.position = pos
		test_human.update_terrain_awareness()
		multipliers.append(test_human.movement_speed_multiplier)
	
	# Check if we got different multipliers (indicating terrain influence)
	var has_variation = false
	for i in range(1, multipliers.size()):
		if abs(multipliers[i] - multipliers[0]) > 0.1:
			has_variation = true
			break
	
	if has_variation:
		log_test(test_name, true, "Movement speed varies with terrain: " + str(multipliers))
	else:
		log_test(test_name, false, "Movement speed did not vary with terrain: " + str(multipliers))

func test_path_calculation():
	total_tests += 1
	var test_name = "Path calculation"
	
	# Test path calculation from center to a nearby point
	var start_pos = Vector2(0, 0)
	var end_pos = Vector2(100, 100)
	
	test_human.position = start_pos
	test_human.set_navigation_target(end_pos)
	
	# Ensure navigation_path is initialized
	if test_human.navigation_path == null:
		log_test(test_name, false, "Navigation path not initialized")
		return
	
	if test_human.navigation_path.size() > 0:
		log_test(test_name, true, "Path calculated with " + str(test_human.navigation_path.size()) + " waypoints")
	else:
		log_test(test_name, false, "No path calculated")

func test_better_terrain_detection():
	total_tests += 1
	var test_name = "Better terrain detection"
	
	# Clear any existing path
	if test_human.navigation_path != null:
		test_human.navigation_path.clear()
	test_human.target_position = null
	
	# Force terrain awareness update
	test_human.update_terrain_awareness()
	
	# Check for better terrain
	test_human.check_for_better_terrain()
	
	if test_human.target_position != null:
		log_test(test_name, true, "Found better terrain at " + str(test_human.target_position))
	else:
		log_test(test_name, false, "No better terrain detected")

func log_test(test_name, passed, details = ""):
	total_tests += 0  # Already incremented in test functions
	if passed:
		passed_tests += 1
		var result = "✓ PASS: " + test_name
		if details != "":
			result += " - " + details
		test_results.append(result)
		print(result)
	else:
		var result = "✗ FAIL: " + test_name
		if details != "":
			result += " - " + details
		test_results.append(result)
		print(result)

func print_results():
	print("\n=== Verification Results ===")
	for result in test_results:
		print(result)
	
	var pass_rate = float(passed_tests) / total_tests * 100
	print("\n=== Summary ===")
	print("Total tests: " + str(total_tests))
	print("Passed: " + str(passed_tests))
	print("Failed: " + str(total_tests - passed_tests))
	print("Pass rate: " + str(pass_rate) + "%")
	
	if pass_rate >= 80:
		print("\n🎉 Phase 4 verification PASSED!")
	else:
		print("\n❌ Phase 4 verification FAILED!")
	
	print("=== Verification Complete ===")