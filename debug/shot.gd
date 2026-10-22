extends Node
## Renders the game from fixed camera poses to PNG files, for checking the look without playing.
##   godot --path . --resolution 1280x720 res://debug/shot.tscn -- --out=/tmp/hotf [--poses=res://debug/shot_poses.json]
##     [--align=-1] [--help-ui] [--debug-ui] [--sun=0.76] [--ambient=0.4] [--prefix=godot]
## --sun and --ambient override the light energies, for calibrating against the pilot one light at a time.

const MAIN_SCENE := preload("res://main.tscn")
const DEFAULT_POSES := "res://debug/shot_poses.json"
## Frames to wait after placing the camera, so shadows and the sky's ambient light settle.
const SETTLE_FRAMES := 12


func _ready() -> void:
	var args := _user_args()
	var out_dir: String = args.get("out", OS.get_user_data_dir().path_join("shots"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var poses: Array = Tuning.load_json(str(args.get("poses", DEFAULT_POSES)))["poses"]

	var main: Node3D = MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	var hud: Hud = main.get("hud")
	hud.set_help_visible(args.has("help-ui"))
	hud.set_debug_visible(args.has("debug-ui"))
	var look: WorldLook = main.get("world_look")
	if args.has("align"):
		look.show_alignment(float(args["align"]))
	if args.has("sun"):
		look.sun.light_energy = float(args["sun"])
	if args.has("ambient"):
		look.set_ambient_energy(float(args["ambient"]))
	var prefix: String = args.get("prefix", "godot")

	var rig: CameraRig = main.get("camera_rig")
	for p: Dictionary in poses:
		rig.set_pose(p["x"], p["z"], p["yaw"], p["pitch"], p["distance"])
		for _i in SETTLE_FRAMES:
			await get_tree().process_frame
		var path := out_dir.path_join("%s_%s.png" % [prefix, p["name"]])
		get_viewport().get_texture().get_image().save_png(path)
		print("shot ", path)
	get_tree().quit()


## Arguments after "--" as a dictionary: --key=value, or --flag with an empty value.
func _user_args() -> Dictionary:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else ""
	return args
