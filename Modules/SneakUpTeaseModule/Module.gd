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

func onSneakUpEncounterEarlyExit(_info:Dictionary):
	var cooldownMultiplier:float = _info.cooldownMultiplier
	multiplySneakUpEncounterCooldownByRatio(cooldownMultiplier)

func multiplySneakUpEncounterCooldownByRatio(cooldownMultiplier:float):
	var chanceAdditiveMillionth = GM.main.getFlag("SneakUpTeaseModule.SneakUpEncounterChanceMillionth", 0)

	if(chanceAdditiveMillionth > 0):
		return

	chanceAdditiveMillionth = int(cooldownMultiplier * chanceAdditiveMillionth)
	GM.main.setFlag("SneakUpTeaseModule.SneakUpEncounterChanceMillionth", chanceAdditiveMillionth)
