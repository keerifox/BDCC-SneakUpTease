extends EventBase

# If the chance is increased by 100 (0.01%) per cell traveled, the
# initial value being set to -25000 (-2.5%) means the encounter chance
# will remain negative until (25000 / 100) = 250 cells have been traveled
const CHANCE_MILLIONTH_INITIAL_VALUE = -25000

func _init():
	id = "SneakUpEncounterStartEvent"

func registerTriggers(es):
	es.addTrigger(self, Trigger.EnteringRoom)
	es.addTrigger(self, Trigger.PCLookingForTrouble)

func react(_triggerID, _args):
	var isLookingForTrouble = (_triggerID == Trigger.PCLookingForTrouble)

	if(!(WorldPopulation.Inmates in GM.pc.getLocationPopulation())):
		return false

	var chanceAdditiveIncrementMillionth = GM.main.getFlag("SneakUpTeaseModule.SneakUpEncounterChanceIncrementMillionth", 100)

	if( chanceAdditiveIncrementMillionth <= ( -1 if(isLookingForTrouble) else 0 ) ):
		return false

	var chanceAdditiveMillionth = GM.main.getFlag("SneakUpTeaseModule.SneakUpEncounterChanceMillionth", CHANCE_MILLIONTH_INITIAL_VALUE)
	chanceAdditiveMillionth += chanceAdditiveIncrementMillionth
	GM.main.setFlag("SneakUpTeaseModule.SneakUpEncounterChanceMillionth", chanceAdditiveMillionth)

	var chanceToStartInteraction:float = chanceAdditiveMillionth / 10000.0
	chanceToStartInteraction *= GM.pc.getEncounterChanceModifierInmates()

	if(!isLookingForTrouble):
		if(!RNG.chance(chanceToStartInteraction)):
			return false

		GM.main.setFlag("SneakUpTeaseModule.SneakUpEncounterChanceMillionth", 1000000)

	var encounterLevel = RNG.randi_range(0, Util.maxi(0, GM.pc.getLevel() + RNG.randi_range(-1, 1)))
	encounterLevel = Util.maxi(encounterLevel, 0)
	encounterLevel = Util.mini(encounterLevel, 15+RNG.randi_range(-1, 1))

	var idToUse = grabNpcIDFromPoolOrGenerate(CharacterPool.Inmates, [], InmateGenerator.new(), {NpcGen.Level: encounterLevel})

	if(idToUse == null || idToUse == ""):
		return false

	if(GM.ES.triggerReact(Trigger.TalkingToDynamicNPC, [idToUse])):
		return true

	var dom = getCharacter(idToUse)

	if(dom == null):
		return false

	if(dom.hasBoundArms() || dom.hasBlockedHands()):
		return false

	var domPawn:CharacterPawn = GM.main.IS.spawnPawnIfNeeded(idToUse)

	if(domPawn == null):
		return false

	GM.main.setFlag("SneakUpTeaseModule.SneakUpEncounterChanceMillionth", CHANCE_MILLIONTH_INITIAL_VALUE)

	# Really don't want them breaking the suspense to comment on our tallymarks
	GM.main.IS.reactCooldowns[idToUse] = 1200

	domPawn.setLocation(GM.pc.getLocation())
	GM.main.IS.startInteraction("SneakUpOnInmate", {dom=idToUse, sub="pc"})

	return true

func getPriority():
	return 1
