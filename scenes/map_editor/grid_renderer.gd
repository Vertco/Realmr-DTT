extends Node2D

var cell_size:int = 100  # Size of each cell in the grid

func _draw():
	# Get the visible area of the viewport
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Get the viewport size
		var viewport_size = get_viewport().get_size()
		
		# Calculate the visible area based on the camera's position and the viewport size
		var camera_pos = camera.offset
		var zoom = camera.zoom
		
		# Calculate the visible rectangle
		var visible_rect = Rect2(
			camera_pos.x - (viewport_size.x / 2) / zoom.x,
			camera_pos.y - (viewport_size.y / 2) / zoom.y,
			viewport_size.x / zoom.x,
			viewport_size.y / zoom.y
		)
		
		# Calculate the dash size based on the zoom level
		var dash_size:float
		if zoom.x > 0.3:
			dash_size = 5 / zoom.x
		
		# Calculate the range of lines to draw
		var start_x := int(visible_rect.position.x / cell_size) - 1
		var end_x := int((visible_rect.position.x + visible_rect.size.x) / cell_size) + 1
		var start_y := int(visible_rect.position.y / cell_size) - 1
		var end_y := int((visible_rect.position.y + visible_rect.size.y) / cell_size) + 1
		
		# Draw horizontal lines
		for y in range(start_y, end_y + 1):
			var start_h := Vector2(start_x * cell_size, y * cell_size)
			var end_h := Vector2(end_x * cell_size, y * cell_size)
			if dash_size:
				draw_dashed_line(start_h, end_h, Preferences.grid_color, -1, dash_size)
			else:
				draw_line(start_h, end_h, Preferences.grid_color, -1)
		
		# Draw vertical lines
		for x in range(start_x, end_x + 1):
			var start_v := Vector2(x * cell_size, start_y * cell_size)
			var end_v := Vector2(x * cell_size, end_y * cell_size)
			if dash_size:
				draw_dashed_line(start_v, end_v, Preferences.grid_color, -1, dash_size)
			else:
				draw_line(start_v, end_v, Preferences.grid_color, -1)
