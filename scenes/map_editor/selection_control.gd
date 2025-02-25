extends Control

const margin:Dictionary = {
	"top": 40.0,
	"right": 5.0,
	"bottom": 40.0,
	"left": 5.0
}
const seperation:float = 5

var dragging:bool
var drag_accum:Vector2 = Vector2.ONE
var header_mouse_offset:Vector2
var selected_rect:Rect2
var prev_rect:Rect2
var none_selected:bool

func _process(_delta: float) -> void:
	# Calculate scaled size and position
	selected_rect = Rect2()
	var first:bool = true
	
	if get_tree().get_nodes_in_group("selected").is_empty():
		if !none_selected:
			set_visible(false)
			queue_redraw()
			none_selected = true
	else:
		none_selected = false
		set_visible(true)
		
		# Get lock and visibility avarage
		var avg_lock:int = 0
		var avg_vis:int = 0
		for node in get_tree().get_nodes_in_group("selected"):
			if node.locked:
				avg_lock = avg_lock+1
			else:
				avg_lock = avg_lock-1
			if node.pc_vis:
				avg_vis = avg_vis+1
			else:
				avg_vis = avg_vis-1
		
		# Set lock icon
		if avg_lock >= 0:
			%SelectionLock.icon = preload("uid://dlspyivnh08k6")
		else:
			%SelectionLock.icon = preload("uid://bme838l035yws")
		
		# Set visibility icon
		if avg_vis >= 0:
			%SelectionVis.icon = preload("uid://bkb5bvkic3wn5")
		else:
			%SelectionVis.icon = preload("uid://cwjoo48cxfep7")
		
		# Generate selection outline
		for n in get_tree().get_nodes_in_group("selected"):
			var rect:Rect2
			rect.position = (n.position*%GmCamera.zoom)+((Vector2(%GmViewport.get_size()) / 2)) - %GmCamera.get_offset() * %GmCamera.zoom
			rect.size = n.get_full_rect().size*%GmCamera.zoom
			rect.position = rect.position - (rect.size / 2)
			if first:
				selected_rect = rect
			else:
				selected_rect = selected_rect.merge(rect)
			first = false
		
		# Redraw selection outline if different to previous
		if selected_rect != prev_rect:
			queue_redraw()
		prev_rect = selected_rect
		
		# Set move gizmo position
		%SelectionMove.position = selected_rect.position+((selected_rect.size/2)-(%SelectionMove.size/2))
		
		# Set initial header position
		%SelectionHeader.set_position(selected_rect.position)
		%SelectionHeader.set_size(Vector2(%SelectionHeader.size.x,%SelectionHeader.size.y))
		
		# Calculate and apply header offset
		var header_offset:Vector2 = Vector2(selected_rect.size.x/2-%SelectionHeader.size.x/2,-%SelectionHeader.size.y-seperation)
		var offset_pos:Vector2
		offset_pos = (selected_rect.position + header_offset).clamp(Vector2(margin.left,margin.top), Vector2(%GmViewport.get_size())-(Vector2(margin.right,margin.bottom)+%SelectionHeader.size))
		%SelectionHeader.set_position(offset_pos)


func _draw() -> void:
	draw_dashed_line(selected_rect.position, selected_rect.position + Vector2(selected_rect.size.x, 0), Color.WHITE, 2, 4)
	draw_dashed_line(selected_rect.position + Vector2(selected_rect.size.x, 0), selected_rect.position + Vector2(selected_rect.size.x, selected_rect.size.y), Color.WHITE, 2, 4)
	draw_dashed_line(selected_rect.position + Vector2(selected_rect.size.x, selected_rect.size.y), selected_rect.position + Vector2(0, selected_rect.size.y), Color.WHITE, 2, 4)
	draw_dashed_line(selected_rect.position + Vector2(0, selected_rect.size.y), selected_rect.position, Color.WHITE, 2, 4)


func snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / 50) * 50,
		round(pos.y / 50) * 50
	)


func _on_selection_lock_pressed() -> void:
	var avg_lock:int = 0
	for node in get_tree().get_nodes_in_group("selected"):
		if node.locked:
			avg_lock = avg_lock+1
		else:
			avg_lock = avg_lock-1
	if avg_lock <= 0:
		for node in get_tree().get_nodes_in_group("selected"):
			if node.has_method("set_locked"):
				node.set_locked(true)
	else:
		for node in get_tree().get_nodes_in_group("selected"):
			if node.has_method("set_locked"):
				node.set_locked(false)


func _on_selection_vis_pressed() -> void:
	var avg_vis:int = 0
	for node in get_tree().get_nodes_in_group("selected"):
		if node.pc_vis:
			avg_vis = avg_vis+1
		else:
			avg_vis = avg_vis-1
	if avg_vis <= 0:
		for node in get_tree().get_nodes_in_group("selected"):
			if node.has_method("set_pc_vis"):
				node.set_pc_vis(true)
		%SelectionVis.icon = preload("uid://bkb5bvkic3wn5")
	else:
		for node in get_tree().get_nodes_in_group("selected"):
			if node.has_method("set_pc_vis"):
				node.set_pc_vis(false)
		%SelectionVis.icon = preload("uid://cwjoo48cxfep7")


func _on_selection_move_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if event.pressed:
				dragging = true
				header_mouse_offset = %SelectionHeader.get_local_mouse_position()
			else:
				dragging = false
				Input.warp_mouse(%SelectionHeader.position+header_mouse_offset+Vector2(0,30))
	elif event is InputEventMouseMotion:
		if dragging:
			drag_accum += event.relative
			if Input.is_key_pressed(KEY_CTRL):
				if drag_accum.length() >= 50 * %GmCamera.zoom.x:
					for node in get_tree().get_nodes_in_group("selected"):
						node.position = snap_to_grid(node.position + (drag_accum / %GmCamera.zoom))
					drag_accum = Vector2.ZERO
			else:
				drag_accum = Vector2.ZERO
				for node in get_tree().get_nodes_in_group("selected"):
					node.position = node.position + (event.relative / %GmCamera.zoom)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
