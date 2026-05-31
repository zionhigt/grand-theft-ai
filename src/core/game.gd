class_name Game
extends Node

var version_label: String = ""

var _ready_called: bool = false

func _ready() -> void:
	if _ready_called:
		return
	_ready_called = true
	version_label = VersionInfo.get_full_label()

func is_bootstrapped() -> bool:
	return _ready_called
