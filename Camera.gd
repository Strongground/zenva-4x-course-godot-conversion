extends Camera2D

@onready var map: Node2D = get_node('/root/Game/HexTileMap')
@onready var ui_manager: Node2D = get_node('/root/Game/CanvasLayer/UIManager')

@export var velocity: float = 15.0
@export var zoom_speed: float = 0.05
@export var max_zoom: float = 3.0
@export var min_zoom: float = 0.5
@export var x_boundary_margin: float = 50.0
@export var y_boundary_margin: float = 100.0

var mouse_wheel_scrolling_up: bool = false
var mouse_wheel_scrolling_down: bool = false
var left_bound: float
var right_bound: float
var top_bound: float
var bottom_bound: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    left_bound = to_global(map.map_to_local(Vector2(0, 0))).x + x_boundary_margin
    right_bound = to_global(map.map_to_local(Vector2(map.width, 0))).x - x_boundary_margin
    top_bound = to_global(map.map_to_local(Vector2(0, 0))).y + y_boundary_margin
    bottom_bound = to_global(map.map_to_local(Vector2(0, map.height))).y - y_boundary_margin

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass

func _physics_process(_delta: float) -> void:
    # Camera Controls
    if Input.is_action_pressed("camera_move_right"):
        if position.x + (velocity / zoom.x) < right_bound:
            position.x += velocity / zoom.x
    if Input.is_action_pressed("camera_move_left"):
        if position.x - (velocity / zoom.x) > left_bound:
            position.x -= velocity / zoom.x
    if Input.is_action_pressed("camera_move_up"):
        if position.y - (velocity / zoom.y) > top_bound:
            position.y -= velocity / zoom.y
    if Input.is_action_pressed("camera_move_down"):
        if position.y + (velocity / zoom.y) < bottom_bound:
            position.y += velocity / zoom.y

    # Zoom Controls
    if Input.is_action_pressed("camera_zoom_in") or mouse_wheel_scrolling_up:
        if zoom.x < max_zoom:
            zoom.x += zoom_speed
            zoom.y += zoom_speed
    if Input.is_action_pressed("camera_zoom_out") or mouse_wheel_scrolling_down:
        if zoom.x > min_zoom:
            zoom.x -= zoom_speed
            zoom.y -= zoom_speed

    # Mouse Wheel Scrolling
    if Input.is_action_just_released("mouse_zoom_in"):
        mouse_wheel_scrolling_up = true
    if not Input.is_action_just_released("mouse_zoom_in"):
        mouse_wheel_scrolling_up = false

    if Input.is_action_just_released("mouse_zoom_out"):
        mouse_wheel_scrolling_down = true
    if not Input.is_action_just_released("mouse_zoom_out"):
        mouse_wheel_scrolling_down = false