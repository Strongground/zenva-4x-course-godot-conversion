extends Node2D

@onready var root : Node = get_tree().get_root()
@onready var canvas_layer : CanvasLayer = get_parent() 
@onready var terrain_tile_details : Panel = canvas_layer.get_node("TerrainTileDetails")
@onready var hex_tile_map : Node2D = get_node("/root/Game/HexTileMap")
@onready var tile_production_overlay : Node2D = get_node("/root/Game/HexTileMap/TileProductionOverlay")

var basic_resources_overlay : PackedScene = load("res://BasicResourcesOverlay.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#_create_tile_production_overlay()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func get_tile_production_overlay_visibility() -> bool:
	return tile_production_overlay.is_visible()

func _unhandled_input(event) -> void :
	# Show basic tile production values as overlay
	# @TODO to speed up significantly, only show overlay for tiles that are currently visible
	# Also only generate once and hide on second press, instead of delete.
	if event.is_action_pressed('show_base_resources_overlay'):
		if !tile_production_overlay.is_visible():
			_show_tile_production_overlay()
		elif tile_production_overlay.is_visible():
			_hide_tile_production_overlay()

func show_terrain_tile_details(hex : Dictionary) -> void:
	if !terrain_tile_details.is_visible():
		terrain_tile_details.set_visible(true)
	terrain_tile_details.set_terrain_details(hex)

func hide_terrain_tile_details() -> void:
	if terrain_tile_details.is_visible():
		terrain_tile_details.set_visible(false)

# For all cells that are currently within the viewport, create a basic resources overlay
func _show_tile_production_overlay() -> void:
	# @TODO to speed up significantly, only show overlay for tiles that are currently visible
	# The basics of the code is here and works

	# var width = hex_tile_map.get_map_dimensions().x
	# var height = hex_tile_map.get_map_dimensions().y
	# var camera = get_node("/root/Game/Camera")
	# for x in range(width):
	# 	for y in range(height):
	# 		# find out if the hex is currently inside the camera viewport, if yes show overlay
	# 		var hex = hex_tile_map.get_hex(Vector2(x, y))
	# 		var global_hex_coordinates = to_global(hex_tile_map.map_to_local(hex.coordinates))
	# 		var viewport_size = camera.get_viewport_rect().size
	# 		var global_camera_boundaries = Rect2(camera.get_global_position()-viewport_size/2, viewport_size)
	# 		if !global_camera_boundaries.has_point(global_hex_coordinates):
	# 			continue
	#		# show overlay for this hex
	tile_production_overlay.set_visible(true)

func _create_tile_production_overlay() -> void:
	# create overlay
	var width = hex_tile_map.get_map_dimensions().x
	var height = hex_tile_map.get_map_dimensions().y
	for x in range(width):
		for y in range(height):
			var hex = hex_tile_map.get_hex(Vector2(x, y))
			var overlay = basic_resources_overlay.instantiate()
			tile_production_overlay.add_child(overlay)
			var overlay_label = overlay.get_node('./Label')
			var quarter_tile = hex_tile_map.get_global_hex_size() / 4
			overlay.set_position(overlay.to_global(hex_tile_map.map_to_local(Vector2(x, y)))-Vector2(0, quarter_tile))
			overlay_label.append_text('[outline_size=10][outline_color=#FFFFFF][font_size=30][b][color="#7d9800"]' + str(hex.food) + '[/color]\n[color="#ff7f00"]' + str(hex.production) + '[/color][/b][/font_size][/outline_color][/outline_size]')
			# print('Created overlay for hex at: ' + str(x) + ', ' + str(y))

func _hide_tile_production_overlay() -> void:
	tile_production_overlay.set_visible(false)
