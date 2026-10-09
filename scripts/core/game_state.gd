extends Node
## Autoload: minimal persistent state for the vertical slice.

signal message(text: String)

var player_name := "Player"
var current_location := "pine_town"
var debug_visible := false

func notify(text: String) -> void:
	message.emit(text)
