extends Control

@warning_ignore("unused_signal")
signal pc_overlay_visibility_changed

@export var max_gm_zoom:float = 0.05
@export var min_gm_zoom:float = 4.0
@export var gm_zoom_incr:float = 0.05
@export var gm_zoom:float = 1.0
var gm_cam_drag:bool = false
var initiated:bool = false

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	get_tree().set_auto_accept_quit(false)
	get_window().set_canvas_cull_mask_bit(19, false)
	%PcWindow.world_2d = get_world_2d()
	%PcWindow.size_changed.connect(%PcCamControl.update)
	get_window().size_changed.connect(%PcCamControl.update)
	%PcCamera.item_rect_changed.connect(%PcCamControl.update)
	%PcCamControl.update()
	if App.map_path:
		load_map(App.map_path)
	initiated = true


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		App.confirm("Do you want to quit Realmr?", "Quit Realmr?")
		var confirm = await App.confirmation
		if confirm:
			%PcWindow.size_changed.disconnect(%PcCamControl.update)
			get_window().size_changed.disconnect(%PcCamControl.update)
			%PcCamera.item_rect_changed.disconnect(%PcCamControl.update)
			get_tree().quit()
		else:
			pass


func _unhandled_input(event: InputEvent) -> void:
	# Handle camera controls
	if event.is_action_pressed("cam_drag"):
		gm_cam_drag = true
	elif event.is_action_released("cam_drag"):
		gm_cam_drag = false
	elif event.is_action("cam_zoom_in"):
		update_gm_zoom(gm_zoom_incr)
		%GmGridRenderer.queue_redraw()
		%PcCamControl.update()
	elif event.is_action("cam_zoom_out"):
		update_gm_zoom(-gm_zoom_incr)
		%GmGridRenderer.queue_redraw()
		%PcCamControl.update()
	elif event is InputEventMouseMotion && gm_cam_drag:
		var new_offset = %GmCamera.get_offset() - event.relative/gm_zoom
		new_offset.x = new_offset.x
		new_offset.y = new_offset.y
		%GmCamera.set_offset(new_offset)
		%GmGridRenderer.queue_redraw()
		%PcCamControl.update()


func load_map(path:String) -> void:
	print("Opening map "+path)
 

func update_gm_zoom(incr:float) -> void:
	var old_zoom = gm_zoom
	var new_incr = incr * gm_zoom
	gm_zoom += new_incr
	if gm_zoom < max_gm_zoom:
		gm_zoom = max_gm_zoom
	elif gm_zoom > min_gm_zoom:
		gm_zoom = min_gm_zoom
	if old_zoom == gm_zoom:
		return
	var new_zoom = Vector2(gm_zoom, gm_zoom)
	%GmCamera.set_zoom(new_zoom)


func _on_pc_overlay_visibility_changed() -> void:
	emit_signal("pc_overlay_visibility_changed")
