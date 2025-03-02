extends Module
class_name SneakUpTeaseModule

func getFlags():
	return {
		"SneakUpEncounterChanceMillionth": flag(FlagType.Number),
	}

func _init():
	id = "SneakUpTeaseModule"
	author = "keerifox"
	
	scenes = []
	characters = []
	items = []
	events = [
		"res://Modules/SneakUpTeaseModule/Events/SneakUpEncounterStartEvent.gd",
	]
	quests = []
	worldEdits = []
	computers = []
