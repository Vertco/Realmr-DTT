extends CanvasLayer

@export var playersWindow:bool

func _ready() -> void:
	%header.playersWindow = playersWindow


func _on_playersViewPopup_confirmed() -> void:
	session.emit_signal("togglePlayersView", %displaySelector.selectedDisplay)
	%header.playersWindow = true
