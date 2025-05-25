extends TabContainer

func _ready() -> void:
	get_tab_bar().set_tab_disabled(1,true)
	get_tab_bar().set_tab_tooltip(1,"Coming soon!")
