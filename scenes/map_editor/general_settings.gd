extends ConfirmationDialog

var pref_backup:Dictionary

func _ready() -> void:
	# Configure window
	var accept:Button = get_ok_button()
	var cancel:Button = get_cancel_button()
	accept.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	%GridColor.get_picker().can_add_swatches = false
	%GridColor.get_picker().presets_visible = false


func _on_about_to_popup() -> void:
	pref_backup = {
		grid_enabled = Preferences.grid_enabled,
		grid_color = Preferences.grid_color
	}
	%GridEnabled.button_pressed = pref_backup.grid_enabled
	if pref_backup.grid_enabled:
		%GridSettings.visible = true
		%GridColor.color = pref_backup.grid_color
	else:
		%GridSettings.visible = false


func _on_grid_enabled_toggled(toggled_on: bool) -> void:
	%GridSettings.visible = toggled_on


func _on_canceled() -> void:
	Preferences.update_preferences(pref_backup)


func _on_confirmed() -> void:
	var new_prefs:Dictionary = {
		grid_enabled = %GridEnabled.button_pressed,
		grid_color = %GridColor.color
	}
	Preferences.update_preferences(new_prefs)
	%PcGridRenderer.queue_redraw()
	%GmGridRenderer.queue_redraw()
