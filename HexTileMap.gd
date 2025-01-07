extends Node2D

enum terrain_type { PLAINS, OCEAN, DESERT, HILLS, FROZEN_HILLS, FROZEN_MOUNTAIN, MOUNTAIN, SNOW, COAST, FOREST, FROZEN_FOREST, BEACH, LIGHT_FOREST, SWAMP, ICE }
enum special_resource_type { ALUMINUM, APPLES, CATTLE, CLAY, COAL, COLORS, COTTON, DEER, FISH, WHEAT, GRAPES, HORSE, LAPIS_LAZULI, MARBLE, OIL_RAW, OLIVES, ORE_COPPER, ORE_GOLD, ORE_IRON, ORE_SILVER, RICE, SALT, SHEEP, SUGAR_CANE, VEGETABLES, WHALES }

var current_selected_cell: Vector2 = Vector2(-1, -1)

@export var width: int = 100
@export var height: int = 100
@export var seed: int = 0

@onready var root : Node = get_tree().get_root()
@onready var base_layer : Node2D = get_node("BaseLayer")
@onready var overlay_layer : Node2D = get_node("SelectionOverlayLayer")
@onready var territory_layer : Node2D = get_node("TerritoryLayer")
@onready var ui_manager: Node2D = get_node("%UIManager")

@onready var city_scene: PackedScene = load("res://City.tscn")

var hex_tile_size: int
var map_data: Dictionary = {}
var click_counter: int = 0
var cities : Dictionary = {}
var civilizations : Array = []
# TEST
var player_civ: Civilization

# Set terrain textures from the TileSet for each terrain type. There are four different textures for each terrain type,
# so the textures are stored in an array. At terrain creation time, a random texture is chosen.
var terrain_textures: Dictionary = {
	terrain_type.PLAINS: [Vector2(4, 4), Vector2(5, 4), Vector2(6, 4), Vector2(7, 4)],
	terrain_type.OCEAN: [Vector2(0, 4), Vector2(1, 4), Vector2(2, 4), Vector2(3, 4)],
	terrain_type.DESERT: [Vector2(4, 0), Vector2(5, 0), Vector2(6, 0), Vector2(7, 0)],
	terrain_type.HILLS: [Vector2(0, 2), Vector2(1, 2), Vector2(2, 2), Vector2(3, 2)],
	terrain_type.FROZEN_HILLS: [Vector2(0, 8), Vector2(1, 8), Vector2(2, 8), Vector2(3, 8)],
	terrain_type.MOUNTAIN: [Vector2(4, 3), Vector2(5, 3), Vector2(6, 3), Vector2(7, 3)],
	terrain_type.FROZEN_MOUNTAIN: [Vector2(5, 7), Vector2(6, 7), Vector2(7, 7), Vector2(8, 7)],
	terrain_type.BEACH: [Vector2(7, 5), Vector2(8, 5), Vector2(0, 6), Vector2(1, 6)],
	terrain_type.COAST: [Vector2(8, 4), Vector2(0, 5), Vector2(1, 5), Vector2(2, 5)],
	terrain_type.FOREST: [Vector2(4, 1), Vector2(5, 1), Vector2(6, 1), Vector2(7, 1)],
	terrain_type.FROZEN_FOREST: [Vector2(1, 7), Vector2(2, 7), Vector2(3, 7), Vector2(4, 7)],
	terrain_type.SNOW: [Vector2(2, 6), Vector2(3, 6), Vector2(4, 6), Vector2(5, 6)],
	terrain_type.ICE: [Vector2(6, 6), Vector2(7, 6), Vector2(8, 6), Vector2(0, 7)],
	terrain_type.LIGHT_FOREST: [Vector2(3,5), Vector2(4,5), Vector2(5,5), Vector2(6,5)],
	terrain_type.SWAMP: [Vector2(0, 3), Vector2(1, 3), Vector2(2, 3), Vector2(3, 3)]
}

var resource_values: Dictionary = {
	special_resource_type.APPLES: {'food': 1, 'production': 0},
	special_resource_type.CATTLE: {'food': 2, 'production': 0},
	special_resource_type.WHEAT: {'food': 2, 'production': 0},
	special_resource_type.VEGETABLES: {'food': 1, 'production': 0},
	special_resource_type.FISH: {'food': 1, 'production': 0},
	special_resource_type.WHALES: {'food': 0, 'production': 1},
	special_resource_type.SALT: {'food': 1, 'production': 1},
	special_resource_type.OIL_RAW: {'food': 0, 'production': 1},
	special_resource_type.CLAY: {'food': 0, 'production': 1},
	special_resource_type.ORE_COPPER: {'food': 0, 'production': 2},
	special_resource_type.ORE_IRON: {'food': 0, 'production': 3},
	special_resource_type.COAL: {'food': 0, 'production': 3},
	special_resource_type.MARBLE: {'food': 0, 'production': 1},
	special_resource_type.ORE_SILVER: {'food': 0, 'production': 2},
	special_resource_type.ORE_GOLD: {'food': 0, 'production': 2},
	special_resource_type.DEER: {'food': 2, 'production': 0},
	special_resource_type.OLIVES: {'food': 1, 'production': 0},
	special_resource_type.COLORS: {'food': 0, 'production': 1},
	special_resource_type.SUGAR_CANE: {'food': 1, 'production': 1},
	special_resource_type.RICE: {'food': 2, 'production': 0}
}

# Percentages of likelihood for a special resource to appear in each terrain type
var special_resources_distribution: Dictionary = {
	terrain_type.PLAINS: {
		special_resource_type.APPLES: 0.3,
		special_resource_type.OIL_RAW: 0.1,
		special_resource_type.CATTLE: 0.2,
		special_resource_type.WHEAT: 0.3,
		special_resource_type.VEGETABLES: 0.2
	},
	terrain_type.OCEAN: {
		special_resource_type.FISH: 0.4,
		special_resource_type.WHALES: 0.05,
		special_resource_type.SALT: 0.1,
	},
	terrain_type.DESERT: {
		special_resource_type.OIL_RAW: 0.3,
		special_resource_type.SALT: 0.2,
		special_resource_type.CLAY: 0.15
	},
	terrain_type.HILLS: {
		special_resource_type.ORE_COPPER: 0.3,
		special_resource_type.ORE_IRON: 0.25,
		special_resource_type.COAL: 0.2,
		special_resource_type.MARBLE: 0.15
	},
	terrain_type.FROZEN_HILLS: {
		special_resource_type.ORE_IRON: 0.25,
		special_resource_type.COAL: 0.3,
		special_resource_type.ORE_SILVER: 0.15
	},
	terrain_type.FROZEN_MOUNTAIN: {
		special_resource_type.ORE_SILVER: 0.2,
		special_resource_type.ORE_GOLD: 0.1,
		special_resource_type.COAL: 0.3
	},
	terrain_type.MOUNTAIN: {
		special_resource_type.ORE_GOLD: 0.15,
		special_resource_type.ORE_COPPER: 0.3,
		special_resource_type.ORE_IRON: 0.25,
		special_resource_type.COAL: 0.2
	},
	terrain_type.SNOW: {
		special_resource_type.DEER: 0.2
	},
	terrain_type.COAST: {
		special_resource_type.FISH: 0.35,
		special_resource_type.SALT: 0.15,
		special_resource_type.OLIVES: 0.2
	},
	terrain_type.FOREST: {
		special_resource_type.DEER: 0.3,
		special_resource_type.APPLES: 0.25,
		special_resource_type.VEGETABLES: 0.15
	},
	terrain_type.FROZEN_FOREST: {
		special_resource_type.DEER: 0.4
	},
	terrain_type.BEACH: {
		special_resource_type.SALT: 0.2,
		special_resource_type.COLORS: 0.1,
		special_resource_type.SUGAR_CANE: 0.15
	},
	terrain_type.LIGHT_FOREST: {
		special_resource_type.CATTLE: 0.2,
		special_resource_type.APPLES: 0.3,
		special_resource_type.RICE: 0.1
	},
	terrain_type.SWAMP: {
		special_resource_type.RICE: 0.3,
		special_resource_type.SALT: 0.15,
		special_resource_type.COLORS: 0.2
	}
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hex_tile_size = base_layer.get_tile_set().get_tile_size().x
	generate_terrain()
	generate_resources()

	player_civ = Civilization.new()
	player_civ.initialize(0, [], Color(0, 0, 255, 1), "Afghans", true, self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	# If tile clicked
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var map_coordinates: Vector2 = base_layer.local_to_map(to_local(get_global_mouse_position()))
			if map_coordinates.x >= 0 and map_coordinates.x < width and map_coordinates.y >= 0 and map_coordinates.y < height:
				
				if click_counter == 0:
					click_counter += 1
				else:
					click_counter = 0

				if click_counter == 0:
					# TEST
					create_city(player_civ, map_coordinates, "Kabul")
				
				# if tile clicked is not the same as the current selected tile, hide the previous overlay
				if Vector2(map_coordinates) != current_selected_cell:
					# Show new cell overlay	
					overlay_layer.set_cell(Vector2(map_coordinates.x, map_coordinates.y), 0, Vector2(0, 1))
					ui_manager.show_terrain_tile_details(map_data[map_coordinates])
				else:
					# Hide terrain details panel and cell overlay if the same tile is clicked
					ui_manager.hide_terrain_tile_details()
				# hide current/last cell overlay
				overlay_layer.set_cell(Vector2(current_selected_cell.x, current_selected_cell.y), -1)
				# Finally save new cell as current selected cell
				current_selected_cell = Vector2(map_coordinates)


# Return a random texture from terrain type.
# @param terrain_type terr_type: The terrain type to get a random texture from.
# @return Vector2: A random texture coordinate (referencing a TileSet location).
func get_random_texture(terr_type: int) -> Vector2:
	var textures: Array = terrain_textures[terr_type]
	var random_index: int = randi() % textures.size()
	return textures[random_index]

func register_city(city: Node2D) -> void:
	cities[city.coordinates] = city

# Generate the terrain for the map.
func generate_terrain() -> void:
	# Create 2D arrays for the noise maps
	var continents_map: Array = []
	var forest_map: Array = []
	var desert_map: Array = []
	var light_forest_map: Array = []
	var swamp_map: Array = []

	for x in range(width):
		continents_map.append([])
		forest_map.append([])
		desert_map.append([])
		light_forest_map.append([])
		swamp_map.append([])

		# fill the 2D arrays with float values
		for y in range(height):
			continents_map[x].append(0.0)
			forest_map[x].append(0.0)
			desert_map[x].append(0.0)
			light_forest_map[x].append(0.0)
			swamp_map[x].append(0.0)

	if seed == 0:
		seed = randi() % 100000

	# BASE CONTINENTS (OCEAN, Beaches, Plains, Mountains)
	var base_noise: FastNoiseLite = FastNoiseLite.new()
	var base_noise_max: float = 0.0
	base_noise.seed = seed
	base_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	base_noise.frequency = 0.0123
	base_noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_FBM

	# FOREST
	var forest_noise: FastNoiseLite = FastNoiseLite.new()
	var forest_noise_max: float = 0.0
	forest_noise.seed = seed
	forest_noise.noise_type = FastNoiseLite.NoiseType.TYPE_CELLULAR
	forest_noise.frequency = 0.0276
	forest_noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_FBM
	forest_noise.cellular_distance_function = FastNoiseLite.CellularDistanceFunction.DISTANCE_EUCLIDEAN

	# DESERT
	var desert_noise: FastNoiseLite = FastNoiseLite.new()
	var desert_noise_max: float = 0.0
	desert_noise.seed = seed
	desert_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	desert_noise.frequency = 0.068
	desert_noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_FBM

	# LIGHT FOREST
	var light_forest_noise: FastNoiseLite = FastNoiseLite.new()
	var light_forest_noise_max: float = 0.0
	light_forest_noise.seed = seed
	light_forest_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	light_forest_noise.frequency = 0.114
	light_forest_noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_FBM

	# SWAMP
	var swamp_noise: FastNoiseLite = FastNoiseLite.new()
	var swamp_noise_max: float = 0.0
	swamp_noise.seed = seed	
	swamp_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	swamp_noise.frequency = 0.088
	swamp_noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_FBM

	# Generate noise map
	for x in range(width):
		for y in range(height):
			# Continents
			continents_map[x][y] = abs(base_noise.get_noise_2d(x, y))
			if continents_map[x][y] > base_noise_max:
				base_noise_max = continents_map[x][y]
			
			# Forest
			forest_map[x][y] = abs(forest_noise.get_noise_2d(x, y))
			if forest_map[x][y] > forest_noise_max:
				forest_noise_max = forest_map[x][y]

			# Desert
			desert_map[x][y] = abs(desert_noise.get_noise_2d(x, y))
			if desert_map[x][y] > desert_noise_max:
				desert_noise_max = desert_map[x][y]

			# Light Forest
			light_forest_map[x][y] = abs(light_forest_noise.get_noise_2d(x, y))
			if light_forest_map[x][y] > light_forest_noise_max:
				light_forest_noise_max = light_forest_map[x][y]
			
	# Ratios of base terrain
	var terrain_gen_values: Array = [
		{'min': 0, 'max': base_noise_max/10 * 2.5, 'type': terrain_type.OCEAN},
		{'min': base_noise_max/10 * 2.5, 'max': base_noise_max/10 * 4, 'type': terrain_type.COAST},
		{'min': base_noise_max/10 * 4, 'max': base_noise_max/10 * 4.5, 'type': terrain_type.BEACH},
		{'min': base_noise_max/10 * 4.5, 'max': base_noise_max/10 * 7, 'type': terrain_type.PLAINS},
		{'min': base_noise_max/10 * 7, 'max': base_noise_max/10 * 7.5, 'type': terrain_type.HILLS},
		{'min': base_noise_max/10 * 7.5, 'max': base_noise_max + 0.05, 'type': terrain_type.MOUNTAIN}
	]

	# Forest values (yes or no)
	var forest_gen_values: Vector2 = Vector2(forest_noise_max/10 * 6, forest_noise_max + 0.05)

	# Desert values (yes or no)
	var desert_gen_values: Vector2 = Vector2(desert_noise_max/10 * 5, desert_noise_max + 0.05)

	# Light Forest values (yes or no)
	var light_forest_gen_values: Vector2 = Vector2(light_forest_noise_max/10 * 5, light_forest_noise_max + 0.05)

	# Swamp values (yes or no)
	var swamp_gen_values: Vector2 = Vector2(swamp_noise_max/10 * 5, swamp_noise_max + 0.05)

	# Set tiles
	for x in range(width):
		for y in range(height):
			# Hex data structure - this is used in a lot of places!
			var h: Dictionary = {
				'coordinates': Vector2i(x, y),
				'food': 0,
				'production': 0,
				'terrain_type_string': '',
				'resources_strings': [],
				'resources': [],
				'ownerCity': null, # node reference to the city that owns this tile or null
				'isCityCenter': false,
			}
			var noise_value: float = continents_map[x][y]

			# Find terrain type
			for range_val in terrain_gen_values:
				if noise_value >= range_val['min'] and noise_value < range_val['max']:
					h.terrain_type = range_val['type']
					break

			# Assign hex object to map data
			map_data[Vector2(x, y)] = h

			# Set desert tiles
			if desert_map[x][y] >= desert_gen_values.x and desert_map[x][y] < desert_gen_values.y and h.terrain_type == terrain_type.PLAINS:
				h.terrain_type = terrain_type.DESERT

			# Set forest tiles
			if forest_map[x][y] >= forest_gen_values.x and forest_map[x][y] < forest_gen_values.y and h.terrain_type == terrain_type.PLAINS:
				h.terrain_type = terrain_type.FOREST

			# Set light forest tiles
			if light_forest_map[x][y] >= light_forest_gen_values.x and light_forest_map[x][y] < light_forest_gen_values.y and h.terrain_type == terrain_type.PLAINS:
				h.terrain_type = terrain_type.LIGHT_FOREST
				
			# # Set swamp tiles
			# if swamp_map[x][y] >= swamp_gen_values.x and swamp_map[x][y] < swamp_gen_values.y and h.terrain_type == terrain_type.PLAINS:
			# 	h.terrain_type = terrain_type.SWAMP

			# Also add string representation of terrain type for UI
			h = set_string_terrain_type(h)

			# Actually set the cells to display the terrain
			base_layer.set_cell(Vector2(x, y), 1, get_random_texture(h.terrain_type))
	
	# Cold poles region
	var max_pole_region_width: int = int(width / 10 * 0.75)
	var is_pole_region: bool = false

	for x in range(width):
		for y in range(height):

			var random_pole_region_factor: int = randi_range(0, 3)
			randomize()
			
			if y < (max_pole_region_width + random_pole_region_factor) or y > (height - max_pole_region_width + random_pole_region_factor):
				is_pole_region = true
			else:
				is_pole_region = false

			var h: Dictionary = map_data[Vector2(x, y)]
			if is_pole_region:
				if h.terrain_type == terrain_type.HILLS:
					h.terrain_type = terrain_type.FROZEN_HILLS

				if h.terrain_type in [terrain_type.PLAINS, terrain_type.BEACH, terrain_type.DESERT, terrain_type.HILLS, terrain_type.SWAMP, terrain_type.LIGHT_FOREST]:
					h.terrain_type = terrain_type.SNOW

				if h.terrain_type == terrain_type.COAST:
					h.terrain_type = terrain_type.ICE

				if h.terrain_type == terrain_type.FOREST:
					h.terrain_type = terrain_type.FROZEN_FOREST
				
				if h.terrain_type == terrain_type.MOUNTAIN:
					h.terrain_type = terrain_type.FROZEN_MOUNTAIN

			
			# Also add string representation of terrain type for UI
			h = set_string_terrain_type(h)

			# Actually set the cells to display the terrain
			base_layer.set_cell(Vector2(x, y), 1, get_random_texture(h.terrain_type))

func generate_resources():
	for x in range(width):
		for y in range(height):

			# Generate basic resources
			var h: Dictionary = map_data[Vector2(x, y)]
			if h.terrain_type == terrain_type.OCEAN or h.terrain_type == terrain_type.COAST or h.terrain_type == terrain_type.SNOW or h.terrain_type == terrain_type.ICE:
				h.food = 1
				h.production = 0
			if h.terrain_type == terrain_type.PLAINS:
				h.food = 2
				h.production = 0
			if h.terrain_type == terrain_type.HILLS or h.terrain_type == terrain_type.FROZEN_HILLS:
				h.food = 0
				h.production = 2
			if h.terrain_type == terrain_type.MOUNTAIN or h.terrain_type == terrain_type.FROZEN_MOUNTAIN:
				h.food = 0
				h.production = 5
			if h.terrain_type == terrain_type.FOREST or h.terrain_type == terrain_type.FROZEN_FOREST:
				h.food = 2
				h.production = 2
			if h.terrain_type == terrain_type.LIGHT_FOREST:
				h.food = 1
				h.production = 1

			# Generate special resources
			if h.terrain_type in special_resources_distribution.keys():
				var special_resources: Dictionary = special_resources_distribution[h.terrain_type]
				for resource in special_resources.keys():
					if randf() < special_resources[resource]:
						h['resources'].append(resource)
				h = set_string_resource(h)

			# For each special resource, add the amount of food or production it can give the tile to the existing value
			for resource in h.resources:
				h.food += resource_values[resource]['food']
				h.production += resource_values[resource]['production']

			map_data[Vector2(x, y)] = h

# Get the dimensions of the map.
func get_map_dimensions() -> Vector2:
	return Vector2(width, height)

# Get the hex at the given position.
func get_hex(coordinates: Vector2) -> Dictionary:
	return map_data[coordinates]

# Save hex data to the map.
# CAUTION! This alters map data irreversibly.
func set_hex(coordinates: Vector2, hex: Dictionary) -> void:
	map_data[hex.coordinates] = hex

# Change a hexes parameter
# @param Vector2 coordinates: The coordinates of the hex to change.
# @param String parameter: The parameter to change.
# @param value: The new value of the parameter.
# @param ignore_null: If true, the function will not error if the parameter value is null. This is
# useful for having default value of null for parameters as it is easier to check than for object types.
func change_hex_parameter(coordinates: Vector2, parameter, value, ignore_null=false) -> void:
	var hex: Dictionary = get_hex(coordinates)
	if hex.has(parameter):
		if typeof(hex[parameter]) == typeof(value) || ignore_null && hex[parameter] == null:
			hex[parameter] = value
			set_hex(coordinates, hex)
		else:
			print("Error: Parameter %s is of type %s, but value is of type %s." % [parameter, type_string(typeof(hex[parameter])), type_string(typeof(value))])
	else:
		print("Error: Parameter %s not found." % parameter)

# Get the size of the hexes.
func get_global_hex_size() -> int:
	return hex_tile_size

# Convert tilemap coordinates to local coordinates.
func map_to_local(coordinates: Vector2) -> Vector2:
	return base_layer.map_to_local(coordinates)

# Set the string representation of the terrain type for the UI.
func set_string_terrain_type(hex: Dictionary) -> Dictionary:
	hex.terrain_type_string = terrain_type.keys()[hex.terrain_type].to_lower()
	return hex

# Set the string representation of the resources for the UI.
func set_string_resource(hex: Dictionary) -> Dictionary:
	for resource in hex.resources:
		hex['resources_strings'].append(special_resource_type.keys()[resource].to_lower())
	return hex

func create_city(civilization: Civilization, coordinates: Vector2, city_name: String) -> void:
	var city: Node2D = city_scene.instantiate()
	add_child(city)
	city.init(civilization, coordinates, city_name, self)
	# Add city center
	city.add_territory([coordinates])
	change_hex_parameter(coordinates, 'isCityCenter', true)
	# Add surrounding tiles (if un-owned)
	for tile_coordinates in get_surrounding_cells(coordinates):
		if get_hex(tile_coordinates).ownerCity == null:
			city.add_territory([tile_coordinates])
	civilization.update_civ_territory_map()
	# Temporary fix to see territory until shader is implemented
	for hex in city.territory:
		territory_layer.set_cell(hex.coordinates, 2, Vector2(0, 1))
	# city.add_territory(base_layer.get_surrounding_cells(coordinates))
	# @TODO
	# Set the color of the city’s icon to reflect the color of the civilization.

# Define neighboring hexes here for convenience
var neighbor_offsets = [
    Vector2(1, 0),  # Rechts
    Vector2(0, 1),  # Unten rechts
    Vector2(-1, 1), # Unten links
    Vector2(-1, 0), # Links
    Vector2(0, -1), # Oben links
    Vector2(1, -1)  # Oben rechts
]

# Get all hex edges that are adjacent to the given hex
func get_border_edges(hex_group: Array) -> Array:
	var edges = []
	var visited = {} # Verhindert doppelte Edges
	for hex in hex_group:
		for offset in neighbor_offsets:
			var neighbor = hex + offset
			if not hex_group.has(neighbor):
				var edge = [hex, neighbor]
				var reverse_edge = [neighbor, hex]
				# Nur eine Richtung speichern
				if not visited.has(reverse_edge):
					edges.append(edge)
					visited[edge] = true
	return edges

func get_border_polygon(edges: Array) -> Array:
	var polygon = []
	# Starte mit einer Kante
	var current_edge = edges.pop_front()
	polygon.append(current_edge[0])
	polygon.append(current_edge[1])

	# Verbinde alle Kanten
	while edges.size() > 0:
		for i in range(edges.size()):
			var edge = edges[i]
			if edge[0] == polygon[-1]:
				polygon.append(edge[1])
				edges.erase(edge)
				break
			elif edge[1] == polygon[-1]:
				polygon.append(edge[0])
				edges.erase(edge)
				break
	return polygon

# Helper function to expose the get_surrounding_cells function from the base_layer to other scripts.
func get_surrounding_cells(coordinates: Vector2) -> Array:
	var result : Array = []
	for cell in base_layer.get_surrounding_cells(coordinates):
		if hex_in_bounds(cell):
			result.append(cell)
	return result

# Helper function to check if a given set of coordinates is within the bounds of the map.
func hex_in_bounds(coordinates: Vector2) -> bool:
	return coordinates.x >= 0 and coordinates.x < width and coordinates.y >= 0 and coordinates.y < height