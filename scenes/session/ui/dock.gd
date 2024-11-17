extends Control

# Preload scenes and icons used in the UI
const fileItem:PackedScene = preload("res://scenes/session/ui/fileItem.tscn")
const newFileItem:PackedScene = preload("res://scenes/session/ui/newFileItem.tscn")
const folder:Texture2D = preload("res://media/icons/folder.svg")

# Stores the currently selected path
var currentPath:String

#region functions
func _ready() -> void:
	session.connect("loadSession", updateTree)
	# Setup the vertical scroll bar for asset container
	var scrollBar:VScrollBar = %assetContainer.get_v_scroll_bar()
	scrollBar.set_visibility_layer_bit(0, false)
	scrollBar.set_visibility_layer_bit(10, true)
	# Adjust the scroll bar for the session tree
	scrollBar = %sessionTree.get_child(3, true)
	scrollBar.set_visibility_layer_bit(0, false)
	scrollBar.set_visibility_layer_bit(10, true)
	# Populate the session tree with the directory structure
	updateTree()

func updateTree() -> void:
	# Clears and resets the session tree, adding a root item
	%sessionTree.clear()
	var treeRoot:TreeItem = %sessionTree.create_item()
	treeRoot.set_text(0, "assets")
	treeRoot.set_icon(0, folder)

	# Recursively list directories and assets
	listDirs(session.assetsRoot, treeRoot)
	listAssets(treeRoot)

func listDirs(path:String, parent:TreeItem) -> void:
	# Lists directories within the specified path
	var dir = DirAccess.open(path)
	if dir == null:
		print("Error opening directory: "+path)
		return
	dir.list_dir_begin()
	var dirName = dir.get_next()
	while dirName != "":
		# For each directory, create a tree item and recurse
		if dir.current_is_dir():
			var dirItem:TreeItem = %sessionTree.create_item(parent)
			dirItem.set_text(0, dirName)
			dirItem.set_icon(0, folder)
			listDirs(path + "/" + dirName, dirItem)
		dirName = dir.get_next()
	dir.list_dir_end()

func get_selectedPath(selected_item:TreeItem) -> String:
	# Constructs the path from the selected item in the tree
	var path:String = "user://sessions/" + session.session
	var stack = []
	while selected_item != null:
		# Build path stack from parent to child nodes
		stack.push_back(selected_item.get_text(0))
		selected_item = selected_item.get_parent()
	while stack.size() > 0:
		path += "/" + stack.pop_back()
	# Set the current path and return it
	currentPath = path
	return path

func listAssets(selected_item:TreeItem) -> void:
	# List assets in the specified selected item
	var activeAssets = %assetGrid.get_children()
	for asset in activeAssets:
		if asset.get_name() != "uploadFile":
			# Remove all assets except the upload button
			asset.queue_free()

	var selectedPath:String = get_selectedPath(selected_item)
	var assets:PackedStringArray = DirAccess.get_files_at(selectedPath)
	var regex = RegEx.new()
	regex.compile("@\\d{2,3}pps")

	for asset in assets:
		# Skip certain files based on extension
		if asset.get_extension() == "import" or asset.get_extension() == "preview" or asset.get_extension() == "rrmap":
			continue
		# Instantiate file item and populate metadata
		var instance = fileItem.instantiate()
		var metadataPath = selectedPath + "/" + asset.get_basename() + ".import"
		var previewPath = selectedPath + "/" + asset.get_basename() + ".preview"
		var metadata:Dictionary = {type = "", preview = false, gridsize = 100}
		# Check if metadata file exists and parse it
		if FileAccess.file_exists(metadataPath):
			var importFile = FileAccess.open(metadataPath, FileAccess.READ)
			while importFile.get_position() < importFile.get_length():
				var jsonString = importFile.get_line()
				var json = JSON.new()
				var parseResult = json.parse(jsonString)
				if not parseResult == OK:
					print("JSON Parse Error: ", json.get_error_message(), " in ", jsonString, " at line ", json.get_error_line())
					continue
				metadata = json.get_data()
			importFile.close()
		else:
			# Create a new metadata file if not found
			var importFile = FileAccess.open(metadataPath, FileAccess.WRITE)
			if asset.get_extension() in ["png", "jpg", "jpeg", "webp"]:
				metadata.type = "image"
				var image = Image.new()
				image.load(selectedPath + "/" + asset)
				# Generate a preview image if required
				if image.get_width() > 512 or image.get_height() > 512 and !FileAccess.file_exists(previewPath):
					var aspect:float = float(image.get_size().x) / float(image.get_size().y)
					var previewImage := Image.new()
					previewImage.copy_from(image)
					previewImage.resize(512, int(512/aspect))
					var previewPacked = previewImage.save_webp_to_buffer()
					var file = FileAccess.open(previewPath, FileAccess.WRITE_READ)
					file.store_buffer(previewPacked)
					file.close()
					metadata.preview = true
				# Extract gridsize from asset name if present
				var PPS = regex.search(asset)
				if PPS:
					metadata.gridsize = PPS.get_string().to_int()
			elif asset.get_extension() in ["mp3", "wav"]:
				metadata.type = "audio"
			elif asset.get_extension() in ["md", "txt"]:
				metadata.type = "note"
			else:
				continue
			var jsonString = JSON.stringify(metadata)
			importFile.store_line(jsonString)
		instance.metadata = metadata
		instance.filePath = selectedPath + "/" + asset
		instance.connect("deleteFile", deleteFile)
		%assetGrid.add_child(instance)
	# Add upload button at the end of asset grid
	var uploadButton = newFileItem.instantiate()
	uploadButton.connect("gui_input", _on_newFile_gui_input)
	%assetGrid.add_child(uploadButton)

func uploadFiles(paths:PackedStringArray) -> void:
	# Process uploaded files and save them as compressed images
	for path in paths:
		if path.get_extension() in ["png", "jpg", "jpeg", "webp"]:
			var img := Image.new()
			img.load(path)
			var newImg := Image.new()
			newImg.copy_from(img)
			var newImgPacked := newImg.save_webp_to_buffer()
			var newImgPath:String = currentPath + "/" + path.get_file().get_basename() + ".webp"
			var file = FileAccess.open(newImgPath, FileAccess.WRITE_READ)
			file.store_buffer(newImgPacked)
			file.close()
		elif path.get_extension() in ["md", "txt"]:
			var file := FileAccess.open(path, FileAccess.READ)
			var content := file.get_as_text()
			var newPath:String = currentPath + "/" + path.get_file()
			var newFile := FileAccess.open(newPath, FileAccess.WRITE)
			newFile.store_line(content)
		else:
			continue
	# Refresh asset list after upload
	listAssets(%sessionTree.get_selected())

func deleteFile(file:String) -> void:
	# Delete a file and associated metadata
	var path:String = currentPath + "/" + file
	var metadataPath = currentPath + "/" + file.get_basename() + ".import"
	var previewPath = currentPath + "/" + file.get_basename() + ".preview"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(metadataPath))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(previewPath))
	# Refresh asset list after deletion
	listAssets(%sessionTree.get_selected())

func _on_newFile_gui_input(event: InputEvent) -> void:
	# Trigger file dialog on left mouse button click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		%fileDialog.popup_centered()

func _on_assetContainer_resized() -> void:
	# Adjust asset grid columns based on container size
	%assetGrid.columns = clamp(%assetContainer.size.x / (10+%assetContainer.get_child_count()*100)/%assetContainer.get_child_count(), 2, 100)

func _on_sessionTree_item_selected() -> void:
	# Update asset list when a tree item is selected
	listAssets(%sessionTree.get_selected())
#endregion
