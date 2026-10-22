extends Node3D
## Builds the prototype: the island from data/island.json, its sky and light, the camera rig and the HUD.

const ISLAND_PATH := "res://data/island.json"

var layout: IslandLayout
var world_look: WorldLook
var island: Island
var camera_rig: CameraRig
var hud: Hud


func _ready() -> void:
	layout = IslandLayout.from_file(ISLAND_PATH)

	world_look = WorldLook.new()
	world_look.name = "WorldLook"
	add_child(world_look)

	island = Island.new()
	island.name = "Island"
	island.layout = layout
	add_child(island)

	camera_rig = CameraRig.new()
	camera_rig.name = "CameraRig"
	camera_rig.layout = layout
	add_child(camera_rig)

	hud = Hud.new()
	hud.name = "Hud"
	hud.camera_rig = camera_rig
	hud.world_look = world_look
	add_child(hud)
