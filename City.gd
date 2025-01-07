extends Node2D

@onready var ui_manager: Node2D = get_node('/root/Game/CanvasLayer/UIManager')
@onready var city_label: Label = get_node('Label')
@onready var city_sprite: Sprite2D = get_node('Sprite')

var map: Node2D
var territory: Array = []
var potential_territory: Array = []
var city_name: String = "City Name"
var coordinates: Vector2 = Vector2(-1, -1)
var civilization: Civilization = null
var world_position: Vector2 = Vector2(-1, -1)

func _ready():
	pass

func init(given_civilization: Civilization, given_coordinates: Vector2, given_city_name: String, hextilemap: Node2D) -> void:
	map = hextilemap
	set_civilization(given_civilization)
	set_coordinates(given_coordinates)
	set_city_name(given_city_name)
	set_world_position(given_coordinates)
	map.register_city(self)

# Generic setter for civilization
func set_civilization(given_civilization: Civilization) -> void:
	civilization = given_civilization
	civilization.cities.append(self)

# Generic setter for coordinates
func set_coordinates(given_coordinates: Vector2) -> void:
	coordinates = given_coordinates

# Generic setter for world position
func set_world_position(given_coordinates: Vector2) -> void:
	world_position = map.map_to_local(given_coordinates)
	self.global_position = world_position

# Generic setter for city name
func set_city_name(given_city_name: String) -> void:
	city_label.text = given_city_name
	city_name = given_city_name

# Generic getter for civilization
func get_civilization() -> Civilization:
	return civilization

# Generic getter for coordinates
func get_coordinates() -> Vector2:
	return coordinates

# Generic getter for world position
func get_world_position() -> Vector2:
	return world_position

# Generic getter for city name
func get_city_name() -> String:
	return city_name

# Add 1 to n tiles to the city’s territory. The Array this
# function expects, must contain the coordinates of the tiles to add.
func add_territory(territoryToAdd: Array) -> void:
	for tile_coordinates in territoryToAdd:
		map.change_hex_parameter(tile_coordinates, 'ownerCity', self, true)
		territory.append(map.get_hex(tile_coordinates))