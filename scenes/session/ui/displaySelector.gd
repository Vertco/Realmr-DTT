extends Control

var selectedDisplay:int

@onready var displays := DisplayServer.get_screen_count()
@onready var displaysRect:Rect2

func _ready() -> void:
	get_tree().get_root().size_changed.connect(update)
	update()

func openWindow(display:int) -> void:
	selectedDisplay = display
	mainMenu.playersWindowDisplay = display

func updateDisplays() -> void:
	displaysRect = Rect2()
	var displayScale
	var displayButtons := get_tree().get_nodes_in_group("displayButtons")
	for button in displayButtons:
		button.queue_free()
	for display in displays:
		var buttonRect:Rect2 = Rect2(DisplayServer.screen_get_position(display), DisplayServer.screen_get_size(display))
		if displaysRect == Rect2():
			displaysRect = buttonRect
		else:
			displaysRect = displaysRect.merge(buttonRect)
		var displaysScaled = displaysRect.size.clamp(Vector2(),Vector2(414, 181))
		var scaleVector = displaysRect.size/displaysScaled
		displayScale = max(scaleVector.x, scaleVector.y)
	for display in displays:
		var displayButton:Button = Button.new()
		displayButton.position = Vector2(DisplayServer.screen_get_position(display))/displayScale
		displayButton.size = Vector2(DisplayServer.screen_get_size(display))/displayScale
		displayButton.text = str(display)
		displayButton.pressed.connect(openWindow.bind(display))
		displayButton.set_name("displayButton" + str(display))
		displayButton.add_to_group("displayButtons")
		displayButton.mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND
		add_child(displayButton)

func updateCurrentDisplay() -> void:
	displays = DisplayServer.get_screen_count()
	var current = DisplayServer.window_get_current_screen()
	var displayButtons := get_tree().get_nodes_in_group("displayButtons")
	for button in displayButtons:
		if button.text == str(current):
			button.disabled = true
			button.mouse_default_cursor_shape = CursorShape.CURSOR_ARROW
		else:
			button.disabled = false
			button.mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND

func update() -> void:
	updateDisplays()
	updateCurrentDisplay()
