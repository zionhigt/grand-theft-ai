class_name VersionInfo
extends RefCounted

const GAME_NAME := "Grand Theft AI"
const GAME_VERSION := "0.1.0-bootstrap"

static func get_full_label() -> String:
	return "%s %s" % [GAME_NAME, GAME_VERSION]
