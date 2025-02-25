extends Resource
class_name Asset

enum asset_type {
	IMAGE,
	NOTE,
	AUDIO
}

@export_global_file() var path:String
@export var type:asset_type
@export var preview:CompressedTexture2D
@export_group("Image")
@export var image:Image
@export_range(10,512,0.1) var gridsize:float
