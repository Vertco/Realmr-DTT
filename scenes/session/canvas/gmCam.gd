extends Camera2D

@export var maxZoom = 0.05
@export var minZoom = 4.0
@export var zoomIncrement = 0.05
@export var currentZoom = 1

@warning_ignore("unused_signal")
signal zoomChanged()

var _drag = false

const maxOffset = Vector2(40000, 40000)
const minOffset = Vector2(-40000, -40000)

func _unhandled_input(event) -> void:
	if event.is_action_pressed("cam_drag"):
		_drag = true
	elif event.is_action_released("cam_drag"):
		_drag = false
	elif event is InputEventMouseMotion && _drag:
		var new_offset = get_offset() - event.relative/currentZoom
		new_offset.x = clamp(new_offset.x, minOffset.x, maxOffset.x)
		new_offset.y = clamp(new_offset.y, minOffset.y, maxOffset.y)
		set_offset(new_offset)
	elif event.is_action("cam_zoomIn"):
		_update_zoom(zoomIncrement)
	elif event.is_action("cam_zoomOut"):
		_update_zoom(-zoomIncrement)

func _update_zoom(incr) -> void:
	var old_zoom = currentZoom
	var new_incr = incr * currentZoom
	currentZoom += new_incr
	session.gmZoom = currentZoom
	if currentZoom < maxZoom:
		currentZoom = maxZoom
	elif currentZoom > minZoom:
		currentZoom = minZoom
	if old_zoom == currentZoom:
		return
	emit_signal("zoomChanged")
	var newZoom = Vector2(currentZoom, currentZoom)
	set_zoom(newZoom)
