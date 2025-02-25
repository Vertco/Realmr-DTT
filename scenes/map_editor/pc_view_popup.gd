extends ConfirmationDialog

var selected:int

func _ready() -> void:
	get_tree().get_root().size_changed.connect(update)
	get_ok_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	get_cancel_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	update()


func openWindow(display:int) -> void:
	var display_buttons:Array[Node] = get_tree().get_nodes_in_group("display_buttons")
	for button in display_buttons:
		if button.text == str(display):
			selected = display
			var theme_override:StyleBox = button.get_theme_stylebox("normal").duplicate()
			theme_override.bg_color = Color("#303030")
			button.add_theme_stylebox_override("normal", theme_override)
		else:
			button.remove_theme_stylebox_override("normal")


func update_displays() -> void:
	var displays:int = DisplayServer.get_screen_count()
	var displays_rect:Rect2 = Rect2()
	var display_scale:int
	var display_buttons := get_tree().get_nodes_in_group("display_buttons")
	for button in display_buttons:
		button.queue_free()
	for display in displays:
		var button_rect:Rect2 = Rect2(DisplayServer.screen_get_position(display), DisplayServer.screen_get_size(display))
		if displays_rect == Rect2():
			displays_rect = button_rect
		else:
			displays_rect = displays_rect.merge(button_rect)
		var displays_scaled:Vector2 = displays_rect.size.clamp(Vector2(),Vector2(414, 181))
		var scale_vector:Vector2 = displays_rect.size/displays_scaled
		display_scale = max(scale_vector.x, scale_vector.y)
	for display in displays:
		var display_button:Button = Button.new()
		display_button.position = Vector2(DisplayServer.screen_get_position(display))/display_scale
		display_button.size = Vector2(DisplayServer.screen_get_size(display))/display_scale
		display_button.text = str(display)
		display_button.pressed.connect(openWindow.bind(display))
		display_button.add_to_group("display_buttons")
		display_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		%DisplaySelector.add_child(display_button)


func update_current() -> void:
	var current:int = DisplayServer.window_get_current_screen()
	var display_buttons:Array[Node] = get_tree().get_nodes_in_group("display_buttons")
	for button in display_buttons:
		if button.text == str(current):
			button.disabled = true
			button.tooltip_text = "Can't select active display"
			button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		else:
			button.disabled = false
			button.tooltip_text = ""
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func update() -> void:
	update_displays()
	update_current()


func _on_visibility_changed() -> void:
	update()


func _on_confirmed() -> void:
	if selected != null:
		#var windows_pos = DisplayServer.screen_get_size(selected)/2
		var global_pos = DisplayServer.screen_get_position(selected)
		%PcWindow.set_position(global_pos)
		%PcWindow.visible = true
		%PcOverlay.visible = true
		%PcGridRenderer.queue_redraw()
		%PcCamControl.update()
