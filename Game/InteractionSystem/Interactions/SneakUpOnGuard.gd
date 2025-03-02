extends PawnInteractionBase

func _init():
	id = "SneakUpOnGuard"

func start(_pawns:Dictionary, _args:Dictionary):
	doInvolvePawn("guard", _pawns["guard"])
	doInvolvePawn("inmate", _pawns["inmate"])
	setState("", "inmate")

func init_text():
	var possible = [
		"{guard.You} {guard.youAre} facing the other way, not noticing {inmate.name} in an off-limits area.",
		"{guard.You} {guard.youVerb('seem')} distracted. {inmate.You} might avoid being seen in an off-limits area if {inmate.youHe} {inmate.youVerb('keep')} quiet.",
	]
	
	if( isInmateWearingStaffUniform() ):
		possible.append_array([
			"{guard.You} {guard.youVerb('pass', 'passes')} {inmate.you} by, not noticing the inmate collar on {inmate.yourHis} neck."
		])

	saynn(RNG.pick(possible))

	var inmate = getRoleChar("inmate")

	if( inmate.hasBoundArms() || inmate.hasBlockedHands() ):
		addDisabledAction("Sneak up!", "Restraints on your arms prevent you from doing this.")
	else:
		addAction("sneak_up_on", "Sneak up!", "Sneak up on them and grab them in a hold!", "sexUse", 1.0, 60, {})

	addAction("try_avoid_detection", "Stay hidden", "Try to avoid being detected.", "default", 1.0, 30, {})
	addAction("draw_attention", "Draw attention", "You really want to be noticed in an off-limits area.", "default", 0.2, 30, {})

func init_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "sneak_up_on"):
		setState("sneaked_up_on", "inmate")
	elif(_id == "try_avoid_detection"):
		setState("tried_to_avoid_detection", "inmate")
	elif(_id == "draw_attention"):
		setState("drew_attention", "inmate")


func sneaked_up_on_text():
	var guardPawn = getRolePawn("guard")

	var guardIsMean = guardPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4
	var guardIsSubby = guardPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) > 0.4
	var guardIsNaive = guardPawn.scorePersonalityMax({ PersonalityStat.Naive: 1.0 }) > 0.4
	var guardIsCowardly = guardPawn.scorePersonalityMax({ PersonalityStat.Coward: 1.0 }) > 0.4

	var guardIsGuard = guardPawn.isGuard() # I know, I know
	var guardIsEngineer = guardPawn.isEngineer()
	var guardIsNurse = guardPawn.isNurse()

	saynn("{inmate.You} {inmate.youVerb('sneak')} up on {guard.name} and {inmate.youVerb('grab')} {guard.him} in a hold.")

	var possible = [
		"Inmate, stop that immediately!",
		"You will regret this, stop right now!",
		"Get your fucking hands off me.",
		"You have absolutely no clue who you're messing with.",
		"I guess you want to be one of those who'll find out the hard way..",
		"You can still let me go, [i]before[/i] I make an example out of you.",
		"This area is off-limits for you, and so is my body."
	]

	if(guardIsMean):
		possible.append_array([
			"You think you can handle me? Think again, hoe.",
		])

	if(guardIsSubby):
		possible.append_array([
			"H- Huh?? Hey!",
			"W- Who ar- Hey!!",
			"Hey!! S- Stop that.. I mean..",
			"Y- You will.. regret! Ah.."
		])
		
		if(guardIsCowardly):
			possible.append_array([
				"Couldn't you h- have at least picked a more secluded spot, everyone is staring!!",
			])

	if(guardIsNaive):
		var guards_OR_other_guards = "guards" if(!guardIsGuard) else "other guards"

		possible.append_array([
			"Ooh, you're going to be in big trouble when the "+ guards_OR_other_guards +" see you..",
			"You have no idea how patrolled this area is, do you? I almost feel bad for your butt after they notice you here.",
		])

	if(guardIsCowardly):
		possible.append_array([
			"*squeak* W- Why me??",
			"I- I don't want any trouble..",
			"Waah! Don't scare me like that..",
			"Y- You shouldn't b- be here..",
		])
		
	if(guardIsGuard):
		if(guardIsNaive):
			possible.append_array([
				"N- Not when I'm on duty!..",
			])

	if(guardIsEngineer):
		if(!guardIsMean):
			possible.append_array([
				"Eek! I know I've been saying 'Fuck me..' for the past fifty minutes, but it really wasn't literal!",
			])

		possible.append_array([
			"You have a strong grip. However, with that thing on your neck, you're only one codeword away from being incapacitated. I have a stronger grip on you. Remember that.",
			"You're directly in the view of the security camera I've just finished fixing. There are a lot of eyes on you right now, so you may [i]really[/i] want to reconsider.",
			"I've seen you approach on the proximity scanner, so I'm sorry to break it to you – you're not catching me by surprise. It indicated you as a pink dot though, either this prototype needs further tweaking, or you must be pretty handful for a complete slut.",
			"I'm honestly unsure if I'm more upset about the proximity sensor not going off, or that I have to deal with direct consequences of that.",
			"For the millionth time, there are no games on my datapad.",
			"I could fix you~",
		])

	if(guardIsNurse):
		if(guardIsMean):
			possible.append_array([
				"You seem healthy enough to have the guts to sneak up on me, the fuck you want, creep.",
			])
		else:
			if(!guardIsNaive):
				# Perceptive
				possible.append_array([
					"You have an elevated heart rate. You can still ease your grip, I promise not to be too harsh.",
				])

			possible.append_array([
				"You need an appointment for that, dear~",
				"Whoa, those experimental drugs make it feel so real..",
				"Wah! You overdosed on heat pills or something?",
				"H- Hey! My handwriting wasn't that bad..",
				"Starving for attention? I'm sorry, but there aren't any pills we can prescribe for that.",
			])

		possible.append_array([
			"I keep telling them to reduce the dosage..",
		])

	if( RNG.chance(10) ):
		possible.append_array([
			"Don't you miss how simple things used to be? I'd call you mean words, and you'd either have to fight to have it your way, or surrender.",
		])

	saynn("[say=guard]"+RNG.pick(possible)+"[/say]")

	addAction("tease", "Tease", "Tease them by rubbing against their butt.", "sexUse", 1.0, 60, {})
		
	addAction("let_go", "Let go", "You changed your mind.", "default", 1.0, 60, {})

func sneaked_up_on_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "tease"):
		startInteraction("SneakUpTease", {dom=getRoleID("inmate"), sub=getRoleID("guard")})
	elif(_id == "let_go"):
		setState("stopped_holding_guard", "inmate")


func stopped_holding_guard_text():
	saynn("{inmate.You} {inmate.youVerb('change')} {inmate.yourHis} mind, loosening the grip on {guard.nameS} wrists.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func stopped_holding_guard_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startInteraction("CaughtOffLimits", {guard=getRoleID("guard"), inmate=getRoleID("inmate")})


func tried_to_avoid_detection_text():
	var guardPawn = getRolePawn("guard")

	var guardPerceptionScore = guardPawn.scorePersonalityMax({ PersonalityStat.Naive: -1.0 })
	var guardIsPerceptive = guardPerceptionScore > 0.4

	saynn("{inmate.You} {inmate.youVerb('try', 'tries')} to tread lightly as not to attract {guard.your} attention.")

	var inmateWasDetectedChance = 40 + 20 * guardPerceptionScore
	var inmateWasDetected = RNG.chance(inmateWasDetectedChance)

	var possible = []

	if(inmateWasDetected):
		if(guardIsPerceptive):
			possible.append_array([
				"You know I can hear you.",
				"If only your shadow was as sneaky as you are.",
				"I've seen you approach, don't try to hide now.",
			])
		else:
			possible.append_array([
				"Huh.. Who's there?",
			])
	else:
		if(!guardIsPerceptive):
			possible.append_array([
				"W- what was that..",
				"Must be hearing things..",
			])

	if( possible.size() > 0 ):
		saynn("[say=guard]"+RNG.pick(possible)+"[/say]")

	if(!inmateWasDetected):
		saynn("{inmate.You} {inmate.youVerb('manage')} to avoid being detected.")

	if(inmateWasDetected):
		addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})
	else:
		addAction("leave", "Leave", "Pass without trace.", "default", 1.0, 0, {})

func tried_to_avoid_detection_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startInteraction("CaughtOffLimits", {guard=getRoleID("guard"), inmate=getRoleID("inmate")})
	elif(_id == "leave"):
		stopMe()


func drew_attention_text():
	var inmate = getRoleChar("inmate")
	var inmatePawn = getRolePawn("inmate")

	var inmatePersonalityMeanScore = inmatePawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var inmateIsMean = inmatePersonalityMeanScore > 0.4
	var inmateIsKind = inmatePersonalityMeanScore < -0.4

	var inmatePersonalityNaiveScore = inmatePawn.scorePersonalityMax({ PersonalityStat.Naive: 1.0 })
	var inmateIsNaive = inmatePersonalityNaiveScore > 0.4

	var possible = [
		"{inmate.You} purposely {inmate.youVerb('bump')} into {guard.you}.",
	]

	if(!inmate.isGagged()):
		# Grins or howls

		if(!inmate.hasBoundArms()):
			# Uses hands
			possible.append_array([
				"{inmate.You} {inmate.youVerb('sneak')} up on {guard.you} and {inmate.youVerb('pat')} {guard.youHim} twice on the shoulder, grinning widely.",
			])

		possible.append_array([
			"{inmate.You} {inmate.youVerb('howl')} at {guard.you} to get {guard.yourHis} attention.",
		])
	
	saynn(RNG.pick(possible))
	
	possible = [
		"Missed me?",
	]

	if(inmateIsMean):
		# Mean
		possible.append_array([
			"Keep your eyes on me, bitch.",
			"Looking for trouble? I'm right here.",
		])
	elif(!inmateIsKind):
		# Neutral
		possible.append_array([
			"Aren't you supposed to patrol this area?",
		])
	else:
		# Kind
		possible.append_array([
			"Awrr, surely there's nothing on your mind more important than me?~",
			"Hey hun, slacking off again?",
			"Um, excuse me..",
			"I think I got lost.."
		])
		
	if(inmateIsNaive):
		possible.append_array([
			"Hey, you there! I was told I can find some hotties around here..",
		])

	saynn("[say=inmate]"+RNG.pick(possible)+"[/say]")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func drew_attention_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startInteraction("CaughtOffLimits", {guard=getRoleID("guard"), inmate=getRoleID("inmate")})


func getAnimData() -> Array:
	if( getState() == "sneaked_up_on" ):
		return [StageScene.SexFreeStanding, "tease", { pc="inmate", npc="guard" }]

	if( getState() in ["stopped_holding_guard", "drew_attention"] ):
		return [StageScene.Duo, "stand", { pc="inmate", npc="guard", flipNPC=true, npcAction="stand" }]

	return [StageScene.Duo, "stand", { pc="inmate", npc="guard", flipNPC=true, npcAction="stand", further=true }]

func getActivityIconForRole(_role:String):
	if( getState() == "drew_attention" ):
		return RoomStuff.PawnActivity.Chat

	return RoomStuff.PawnActivity.None
	
func getPreviewLineForRole(_role:String) -> String:
	if( getState() == "drew_attention" ):
		if(_role == "guard"):
			return "{guard.name} had their attention drawn by {inmate.name}."
		elif(_role == "inmate"):
			return "{inmate.name} decided to draw {guard.nameS} attention."

	if(_role == "guard"):
		return "{guard.name} {guard.is} patroling the off-limits area, but does not spot {inmate.name}."
	elif(_role == "inmate"):
		return "{inmate.name} avoided being seen by {guard.name}."

	return .getPreviewLineForRole(_role)


func isInmateWearingStaffUniform():
	var inmateInventory = getRoleChar("inmate").getInventory()

	if( !inmateInventory.hasSlotEquipped(InventorySlot.Body) ):
		return false

	var item = inmateInventory.getEquippedItem(InventorySlot.Body)

	return(
			item.hasTag(ItemTag.GuardUniform)
		|| item.hasTag(ItemTag.EngineerUniform)
		|| item.hasTag(ItemTag.NurseUniform)
	)
