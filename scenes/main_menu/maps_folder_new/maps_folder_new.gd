extends Control

@warning_ignore("unused_signal")
signal created(name:String)
@warning_ignore("unused_signal")
signal empty()

@export_global_dir() var path:String
var selected:bool:
	set(value):
		selected = value
		if selected:
			set_self_modulate(Color(1,1,1))
		else:
			if hover:
				set_self_modulate(Color(1,1,1,0.5))
			else:
				set_self_modulate(Color(1,1,1,0))
var hover:bool = false

func _ready() -> void:
	%Name.grab_focus()


func submit() -> void:
	if %Name.text == "":
		emit_signal("empty")
	else:
		emit_signal("created",%Name.text)


func _on_name_text_submitted(_new_text: String) -> void:
	submit()
