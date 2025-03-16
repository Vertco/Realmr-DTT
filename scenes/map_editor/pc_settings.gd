extends ConfirmationDialog

@warning_ignore("unused_signal")
signal pc_zoom_updated

var pref_backup:Dictionary

func _ready() -> void:
	# Configure window
	var accept:Button = get_ok_button()
	var cancel:Button = get_cancel_button()
	accept.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Configure color picker
	var picker:ColorPicker = %PcDeskColor.get_picker()
	picker.presets_visible = false
	picker.deferred_mode = true
	if Preferences.pc_view_size_x != 0 && Preferences.pc_view_size_y != 0:
		update_pc_zoom(Vector2(Preferences.pc_view_size_x,Preferences.pc_view_size_y))


func update_pc_zoom(pc_size:Vector2) -> void:
	if pc_size != Vector2(0,0):
		%PcCamera.zoom = Vector2((%PcWindow.get_visible_rect().size*0.0254)/pc_size)
	emit_signal("pc_zoom_updated")


func _on_about_to_popup() -> void:
	pref_backup = {
		pc_view_size_x = Preferences.pc_view_size_x,
		pc_view_size_y = Preferences.pc_view_size_y
	}
	%PcViewWidth.value = Preferences.pc_view_size_x
	%PcViewHeight.value = Preferences.pc_view_size_y


func _on_pc_desk_enabled_toggled(toggled_on: bool) -> void:
	Preferences.update_preferences({pc_desk_enabled = toggled_on})
	%PcDeskSettings.visible = Preferences.pc_desk_enabled


func _on_canceled() -> void:
	Preferences.update_preferences(pref_backup)


func _on_confirmed() -> void:
	var pc_view_size:Vector2
	if %PcViewWidth.value == 0 && %PcViewHeight.value == 0:
		%PcCamera.zoom = Vector2(1,1)
		pc_view_size = Vector2(0,0)
	else:
		pc_view_size = Vector2(%PcViewWidth.value,%PcViewHeight.value)
	var new_prefs:Dictionary = {
		pc_view_size_x = pc_view_size.x,
		pc_view_size_y = pc_view_size.y
	}
	Preferences.update_preferences(new_prefs)
	update_pc_zoom(Vector2(Preferences.pc_view_size_x,Preferences.pc_view_size_y))
	%PcGridRenderer.queue_redraw()


func _on_reset_size_btn_pressed() -> void:
	Preferences.update_preferences({pc_view_size_x = 1.0,pc_view_size_y = 1.0})
	%PcViewWidth.value = 0
	%PcViewHeight.value = 0
