extends Node

#region session constants
const imageCursor = preload("res://media/icons/image.svg")
const noteCursor = preload("res://media/icons/note.svg")
#endregion

#region signals
@warning_ignore("unused_signal")
signal focusGmCam(position:Vector2)
@warning_ignore("unused_signal")
signal togglePlayersView(display:int)
@warning_ignore("unused_signal")
signal togglePlayersViewVis()
@warning_ignore("unused_signal")
signal updateOutliner(nodes:Array)
@warning_ignore("unused_signal")
signal updateOutlinerItem(index:int)
@warning_ignore("unused_signal")
signal layerChanged()
@warning_ignore("unused_signal")
signal loadSession()
#endregion

#region session variables
var gmZoom:float
var session:String:
	set(value):
		session = value
		path = "user://sessions/"+session
		assetsRoot = "user://sessions/"+session+"/assets"
		filePath = "user://sessions/"+session+"/"+session+".rrmap"
var path:String
var assetsRoot:String
var filePath:String
var activeLayer:int = 4:
	set(value):
		activeLayer = value
		emit_signal("layerChanged")
var newAsset:Node:
	set(value):
		newAsset = value
		if newAsset:
			match newAsset.metadata.type:
				"image":
					Input.set_custom_mouse_cursor(imageCursor,Input.CURSOR_ARROW,Vector2(12,12))
				"note":
					Input.set_custom_mouse_cursor(noteCursor,Input.CURSOR_ARROW,Vector2(12,12))
		else:
			Input.set_custom_mouse_cursor(null)
#endregion

#region session functions
func save() -> void:
	var file := FileAccess.open(filePath, FileAccess.WRITE)
	var saveData := {
		"version": ProjectSettings.get_setting("application/config/version"),
		"nodes": []  # Initialize an empty array for nodes
	}
	var saveNodes := get_tree().get_nodes_in_group("saveWithSession")
	for node in saveNodes:
		if node.scene_file_path.is_empty():
			print("Savable node " + node.name + " is not an instanced scene, skipped")
			continue
		if !node.has_method("save"):
			print("Savable node " + node.name + " is missing a saveData() function, skipped saving")
			continue
		var nodeData = node.call("save")
		saveData["nodes"].append(nodeData)  # Append node data to the nodes array in saveData
	var metaString = JSON.stringify(saveData)
	file.store_line(metaString)
	file.close()  # Close the file after writing
#endregion
