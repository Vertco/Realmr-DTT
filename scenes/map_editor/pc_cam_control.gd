extends Control

const margin:Dictionary = {
	"top": 5.0,
	"right": 5.0,
	"bottom": 5.0,
	"left": 5.0
}
const seperation:float = 5
const preview_size:Vector2 = Vector2(256,35)

var dragging:bool
var offscreen:bool
var show_preview:bool = true
var header_mouse_offset:Vector2
var pc_desk := Vector2(0,0)
@onready var pc_view_desk_style := StyleBoxFlat.new()
@onready var pc_desk_style := StyleBoxFlat.new()


func _ready() -> void:
	# Load preferences
	pc_desk = Vector2(Preferences.pc_desk_size_left,Preferences.pc_desk_size_right)
	
	# Setup Pc View Desk style
	pc_view_desk_style.draw_center = false
	pc_view_desk_style.bg_color = Preferences.pc_desk_color
	pc_view_desk_style.border_width_left = 2
	pc_view_desk_style.border_width_right = 2
	pc_view_desk_style.border_color = Preferences.pc_desk_color
	pc_view_desk_style.corner_radius_top_left = 4
	pc_view_desk_style.corner_radius_top_right = 4
	pc_view_desk_style.corner_radius_bottom_left = 4
	pc_view_desk_style.corner_radius_bottom_right = 4
	
	# Setup PC Desk style
	pc_desk_style.draw_center = false
	pc_desk_style.bg_color = Preferences.pc_desk_color
	pc_desk_style.border_color = Preferences.pc_desk_color
	
	# Apply styles
	%PcViewDesk.add_theme_stylebox_override("panel", pc_view_desk_style)
	%PcDesk.add_theme_stylebox_override("panel", pc_desk_style)
	
	# Setup Pc Desk Color
	%PcDeskColor.color = Preferences.pc_desk_color
	%PcDeskColor.get_picker().can_add_swatches = false
	%PcDeskColor.get_picker().presets_visible = false
	
	# Update Player's desk
	update_desk()


func update() -> void:
	# Hide PcDeskControls
	%PcDeskControls.visible = false
	
	# Calculate scaled size and position
	var pc_size:Vector2 = Vector2(%PcWindow.get_visible_rect().size)
	var rect_pos:Vector2 = (%PcCamera.get_offset()*%GmCamera.zoom)+((Vector2(%GmViewport.get_size()) / 2) - ((pc_size/%PcCamera.zoom / 2) * %GmCamera.zoom)) - %GmCamera.get_offset() * %GmCamera.zoom
	var rect_size:Vector2 = pc_size/%PcCamera.zoom * %GmCamera.zoom
	
	# Set view rect
	%PcView.set_position(rect_pos)
	%PcView.set_size(rect_size)
	
	# Set initial header position
	%PcViewHeader.set_position(rect_pos)
	var header_width:float = get_on_screen_size(%PcView).x-(margin.left+margin.right)
	%PcViewHeader.set_size(Vector2(header_width,%PcViewHeader.size.y))
	
	# Set initial preview position
	%PcPreview.set_position(rect_pos)
	
	# Calculate and apply header offset
	var header_offset:Vector2 = Vector2(rect_size.x/2-%PcViewHeader.size.x/2,-%PcViewHeader.size.y-seperation)
	var offset_pos:Vector2
	%PcPreview.set_size(Vector2(preview_size.x,preview_size.x/pc_size.aspect()))
	if %PcPreview.visible:
		offset_pos = (rect_pos + header_offset).clamp(Vector2(margin.left,margin.top), Vector2(%GmViewport.get_size())-(Vector2(margin.right,clamp(%PcPreview.size.y+seperation+margin.bottom,0,%GmViewport.get_size().y-seperation-%PcViewHeader.size.y))+%PcViewHeader.size))
	else:
		offset_pos = (rect_pos + header_offset).clamp(Vector2(margin.left,margin.top), Vector2(%GmViewport.get_size())-(Vector2(margin.right,margin.bottom)+%PcViewHeader.size))
	%PcViewHeader.set_position(offset_pos)
	
	# Calculate and apply preview offset
	var preview_offset:Vector2 = Vector2(rect_size.x/2-%PcPreview.size.x/2,0)
	var preview_offset_pos:Vector2 = (rect_pos + preview_offset).clamp(Vector2(seperation,margin.top+margin.bottom+%PcViewHeader.size.y), Vector2(%GmViewport.get_size())-(Vector2(5,5)+%PcPreview.size))
	%PcPreview.set_position(preview_offset_pos)
	
	# Show or hide the preview depending on if the view is offscreen
	if offscreen && %PcWindow.visible && show_preview:
		%PcPreview.show()
	else:
		%PcPreview.hide()
	
	# Update scaling
	%PcSettings.update_pc_zoom(Vector2(Preferences.pc_view_size_x,Preferences.pc_view_size_y))
	
	# Update Player's desk
	update_desk()


func get_on_screen_size(node:Node) -> Vector2:
	# Get the global rectangle of the node
	var global_rect = node.get_global_rect()
	var viewport_size = %GmViewport.get_visible_rect()
	
	# Calculate the intersection of the node's rectangle and the viewport rectangle
	var intersection = global_rect.intersection(viewport_size)
	
	if intersection.size == Vector2(0,0):
		offscreen = true
	else:
		offscreen = false
		show_preview = true
	
	# Return the size of the intersection rectangle
	return intersection.size


func update_left_desk_value(percent:float) -> void:
	pc_desk = Vector2(percent,pc_desk.y)
	update_desk()
	Preferences.update_preferences({pc_desk_size_left = percent})


func update_right_desk_value(percent:float) -> void:
	pc_desk = Vector2(pc_desk.x,percent)
	update_desk()
	Preferences.update_preferences({pc_desk_size_right = percent})


func update_desk_value(percent:float) -> void:
	update_left_desk_value(percent)
	update_right_desk_value(percent)


func update_desk() -> void:
	if pc_desk == Vector2(100,100):
		# Update Pc View Desk style
		pc_view_desk_style.draw_center = true
		pc_view_desk_style.border_width_left = 0
		pc_view_desk_style.border_width_right = 0
		
		# Update Pc Desk style
		pc_desk_style.draw_center = true
		pc_desk_style.border_width_left = 0
		pc_desk_style.border_width_right = 0
	else:
		# Update Pc View Desk style
		var view_factor = %PcViewDesk.size.x/200
		pc_view_desk_style.draw_center = false
		pc_view_desk_style.border_width_left = view_factor*pc_desk.x
		pc_view_desk_style.border_width_right = view_factor*pc_desk.y
		
		# Update Pc Desk style
		var factor = %PcDesk.size.x/200
		pc_desk_style.draw_center = false
		pc_desk_style.border_width_left = factor*pc_desk.x
		pc_desk_style.border_width_right = factor*pc_desk.y
	
	pc_desk_style.bg_color = Preferences.pc_desk_color
	pc_desk_style.border_color = Preferences.pc_desk_color
	pc_view_desk_style.bg_color = Preferences.pc_desk_color
	pc_view_desk_style.border_color = Preferences.pc_desk_color
	
	# Apply updated styles
	%PcViewDesk.remove_theme_stylebox_override("panel")
	%PcDesk.remove_theme_stylebox_override("panel")
	%PcViewDesk.add_theme_stylebox_override("panel", pc_view_desk_style)
	%PcDesk.add_theme_stylebox_override("panel", pc_desk_style)


func _on_pc_view_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if event.pressed:
				dragging = true
				header_mouse_offset = %PcViewHeader.get_local_mouse_position()
			else:
				dragging = false
				Input.warp_mouse(%PcViewHeader.position+header_mouse_offset+Vector2(0,30))
			if event.double_click:
				var tween := get_tree().create_tween()
				tween.tween_property(%GmCamera,"offset",%PcCamera.offset-Vector2(0,55),0.5).set_trans(Tween.TRANS_CUBIC)
				tween.tween_callback(%GmGridRenderer.queue_redraw)
				tween.tween_callback(update)
	elif event is InputEventMouseMotion:
		if dragging:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			%PcCamera.set_offset(%PcCamera.offset+(event.relative/%GmCamera.zoom))
			update()
			%PcGridRenderer.queue_redraw()


func _on_hide_preview_btn_pressed() -> void:
	show_preview = false
	%PcPreview.hide()
	update()


func _on_pc_view_btn_pressed() -> void:
	%PcOverlay.visible = !%PcOverlay.visible
	%PcDesk.visible = !%PcOverlay.visible
	if %PcOverlay.visible:
		%PcViewBTN.icon = preload("uid://bu3egx1d0j1ok") # pc_view
		%PcViewBTN.tooltip_text = "Reveal"
	else:
		%PcViewBTN.icon = preload("uid://djc5tqouae65q") # pc_view_hidden
		%PcViewBTN.tooltip_text = "Cover"


func _on_pc_settings_btn_pressed() -> void:
	%PcSettings.popup_centered()


func _on_pc_desk_btn_pressed() -> void:
	%PcDeskControls.visible = !%PcDeskControls.visible
	%PcDeskColor.color = Preferences.pc_desk_color


func _on_pc_overlay_visibility_changed() -> void:
	%PcCamControlOverlay.visible = %PcOverlay.visible


func _on_pc_desk_left_value_changed(value: float) -> void:
	if %PcDeskLinked.button_pressed:
		update_desk_value(value)
	else:
		update_left_desk_value(value)


func _on_pc_desk_right_value_changed(value: float) -> void:
	if %PcDeskLinked.button_pressed:
		update_desk_value(value*-1+100)
	else:
		update_right_desk_value(value*-1+100)


func _on_pc_desk_color_color_changed(color: Color) -> void:
	Preferences.update_preferences({"pc_desk_color": color})
	update_desk()
