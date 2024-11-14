extends Control

@export var playersWindow:Window
@export var playersDesk:StyleBoxFlat = StyleBoxFlat.new()

var _dragging:bool = false
var initiated:bool = false

func _ready():
	%header.connect("gui_input", Callable(self, "on_header_input"))
	playersWindow.connect("size_changed", Callable(self, "on_playersCam_changed"))
	%playersCam.connect("item_rect_changed", Callable(self, "on_playersCam_changed"))
	var picker:ColorPicker = %picker.get_picker()
	picker.can_add_swatches = false
	picker.presets_visible = false
	_on_picker_color_changed(Color.html(root.settings.passepartoutColor))
	%picker.color = Color.html(root.settings.passepartoutColor)
	%xScale.value = root.settings.playersView_x
	%yScale.value = root.settings.playersView_y
	on_playersCam_changed()
	initiated = true

func updatePassepartoutWidth(value:float) -> void:
	var widthIncrement = %playersDesk.size.x/200
	var width = widthIncrement*value
	%passepartoutLeft.value = value
	%passepartoutRight.value = value
	%playersDesk.remove_theme_stylebox_override("panel")
	playersDesk.border_width_left = width
	playersDesk.border_width_right = width
	%playersDesk.add_theme_stylebox_override("panel", playersDesk)

func hideControls() -> void:
	%yScale.visible = false
	%xScale.visible = false
	%passepartoutSliderL.visible = false
	%passepartoutSliderR.visible = false
	%picker.visible = false

func on_header_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
	elif event is InputEventMouseMotion:
		if _dragging:
			global_position += event.relative
			%playersCam.global_position += event.relative
			hideControls()

func on_playersCam_changed():
	size = Vector2(playersWindow.get_visible_rect().size) / %playersCam.zoom
	var positionOffset := Vector2(size.x/2,size.y/2)
	position = %playersCam.position - positionOffset
	updatePassepartoutWidth(root.settings.passepartout)

func _on_editButton_pressed() -> void:
	if %yScale.visible == true && %xScale.visible == true:
		%yScale.visible = false
		%xScale.visible = false
		%passepartoutSliderL.visible = false
		%passepartoutSliderR.visible = false
		%picker.visible = false
	else:
		%xScale.value = %playersCam.zoom.x
		%yScale.value = %playersCam.zoom.y
		%yScale.visible = true
		%xScale.visible = true
		%passepartoutSliderL.visible = true
		%passepartoutSliderR.visible = true
		%picker.visible = true

func _on_scale_value_changed(value: float) -> void:
	if initiated:
		%playersCam.zoom = Vector2(%xScale.value, %yScale.value)
		root.saveSettings({playersView_x = %playersCam.zoom.x, playersView_y = %playersCam.zoom.y})
		on_playersCam_changed()

func _on_passepartoutSliderL_value_changed(value: float) -> void:
	updatePassepartoutWidth(value)

func _on_passepartoutSliderR_value_changed(value: float) -> void:
	updatePassepartoutWidth(value*-1+100)

func _on_passepartoutSlider_drag_ended(_value_changed: bool) -> void:
	if _value_changed:
		root.saveSettings({passepartout = %passepartoutLeft.value})

func _on_picker_color_changed(color: Color) -> void:
	%passepartoutLeft.remove_theme_stylebox_override("fill")
	%passepartoutRight.remove_theme_stylebox_override("fill")
	@warning_ignore("shadowed_variable_base_class")
	var theme:StyleBoxFlat = StyleBoxFlat.new()
	theme.bg_color = color
	%passepartoutLeft.add_theme_stylebox_override("fill", theme)
	%passepartoutRight.add_theme_stylebox_override("fill", theme)
	%playersDesk.remove_theme_stylebox_override("panel")
	playersDesk.draw_center = false
	playersDesk.border_color = color
	%playersDesk.add_theme_stylebox_override("panel", playersDesk)

func _on_picker_popup_closed() -> void:
	root.saveSettings({passepartoutColor = %picker.color.to_html()})
