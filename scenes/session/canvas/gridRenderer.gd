extends Node2D

var cell_size = 100  # Size of each cell in the grid
var grid_size = 500  # Number of cells in the grid
var lines := []

func _ready():
	# Initialize the lines array
	var gridColor := Color.html(root.settings.get("gridColor"))
	for i in range(-grid_size, grid_size + 1):
		var start := Vector2(-grid_size * cell_size, i * cell_size)
		var end := Vector2(grid_size * cell_size, i * cell_size)
		lines.append({"start": start, "end": end, "color": gridColor})
		
		start = Vector2(i * cell_size, -grid_size * cell_size)
		end = Vector2(i * cell_size, grid_size * cell_size)
		lines.append({"start": start, "end": end, "color": gridColor})

func _draw():
	# Draw all the lines
	for line in lines:
		draw_line(line["start"], line["end"], line["color"])

func updateGrid():
	var gridColor := Color.html(root.settings.get("gridColor"))
	for line in lines:
		line["color"] = gridColor
	queue_redraw()
