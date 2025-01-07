extends Object

class_name Civilization

var id: int = 0
var cities: Array = []
var color: Color = Color()
var name: String = ""
var player_civ: bool = false
var hextilemap = null

func _init():
    cities = []
    color = Color(randi()%255, randi()%255, randi()%255, 1)

func initialize(id, cities, color, name, player_civ, map):
    self.hextilemap = map
    self.id = id
    self.cities = cities
    self.color = color
    self.name = name
    self.player_civ = player_civ

func update_civ_territory_map():
    var territories_to_merge = {}
    var merged_territories = []
    # For each city and each hex, identify the territory group
    for city in cities:
        var processed_hexes = []
        for hex in city.territory:
            var neighbors = hextilemap.get_surrounding_cells(hex.coordinates)
            for neighbor in neighbors:
                if processed_hexes.has(neighbor):
                    continue
                neighbor = hextilemap.get_hex(neighbor)
                # if neighbor is not owned by the city but by a city owned by the same civilization
                if neighbor.ownerCity != null and neighbor.ownerCity.coordinates != city.coordinates and neighbor.ownerCity.get_civilization() == city.civilization:
                    # create dynamic array name
                    var array_name = "%s_mergeWith_%s" % [str(city.get_instance_id()), str(neighbor.ownerCity.get_instance_id())]
                    for key in territories_to_merge.keys():
                        print("Checking if %s or %s is in %s." % [str(city.get_instance_id()), str(neighbor.ownerCity.get_instance_id()), key])
                        print("'str(city.get_instance_id()) in key' returns: "+str(str(city.get_instance_id()) in key))
                        print("'str(neighbor.ownerCity.get_instance_id()) in key' returns: "+str(str(neighbor.ownerCity.get_instance_id()) in key))
                        print("key is of type "+type_string(typeof(key)))
                        if str(city.get_instance_id()) in key or str(neighbor.ownerCity.get_instance_id()) in key:
                            array_name = key
                            break
                    if !territories_to_merge.has(array_name):
                        territories_to_merge[array_name] = []
                    
                    # add hex and neighbor to the array
                    if hex not in territories_to_merge[array_name]:
                        territories_to_merge[array_name].append(hex)
                    if neighbor not in territories_to_merge[array_name]:
                        territories_to_merge[array_name].append(neighbor)
                processed_hexes.append(neighbor.coordinates)
    

    # Shader-Input oder andere Verarbeitung vorbereiten
    for key in territories_to_merge.keys():
        var territory_group = []
        # Get cities instances from keys
        var city_ids = key.split("_mergeWith_")
        var city1 = instance_from_id(int(city_ids[0]))
        var city2 = instance_from_id(int(city_ids[1]))
        # merge the two territories, avoid duplicates
        territory_group = city1.territory
        for hex in city2.territory:
            if hex not in territory_group:
                territory_group.append(hex)
        
        if territory_group.size() > 0:
            merged_territories.append(territory_group)
            print("Merged 2 territories together:"+str(territory_group))
        process_merged_territories(merged_territories)

func process_merged_territories(territories: Array):
    # Hier könntest du z. B. Grenzen oder Shader-Daten vorbereiten
    # Dummy-Logik, um alle Koordinaten zu sammeln
    var coordinates = []
    for territory in territories:
        for hex in territory:
            coordinates.append(hex.coordinates)
    print("Processed territory group with coordinates:", coordinates)
