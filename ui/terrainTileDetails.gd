extends Panel

@onready var terrainImage : TextureRect = get_node("TerrainTypeImage")
@onready var terrainTypeLabel : Label = get_node("TerrainTypeLabel")
@onready var foodLabel : Label = get_node("FoodLabel")
@onready var productionLabel : Label = get_node("ProductionLabel")
@onready var resources : PanelContainer = get_node("ResourceContainer")
@onready var resources_list : ItemList = resources.get_node("ResourcesList")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# Set the terrain details for the terrain tile.
func set_terrain_details(hex : Dictionary):
	_clean_data()
	terrainImage.texture = load("res://textures/terrain/" + hex.terrain_type_string + ".jpg")
	terrainTypeLabel.text = hex.terrain_type_string.capitalize()
	foodLabel.text = "Food: " + str(hex.food)
	productionLabel.text = "Production: " + str(hex.production)
	for i in range(hex.resources.size()):
		# print('Hex has resource: ' + hex.resources_strings[i])
		var resource : String = hex.resources_strings[i]
		var resource_image : Texture2D = load("res://textures/resources/" + resource + ".png")
		resources_list.add_item(resource.capitalize(), resource_image, false)

func _clean_data():
	terrainImage.texture = null
	terrainTypeLabel.text = "Terrain:"
	foodLabel.text = "Food:"
	productionLabel.text = "Production:"
	resources_list.clear()