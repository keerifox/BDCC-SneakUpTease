extends PawnInteractionBase

func _init():
	id = "SneakUpOnInmate"

func start(_pawns:Dictionary, _args:Dictionary):
	doInvolvePawn("dom", _pawns["dom"])
	doInvolvePawn("sub", _pawns["sub"])
	setState("", "dom")

func init_text():
	var sub = getRoleChar("sub")

	var possible:Array = [
		"{sub.You} {sub.youVerb('hear')} the faint sound of footsteps.",
		"For a moment, {sub.you} {sub.youVerb('zone')} out, no longer paying attention to {sub.yourHis} surroundings.",
		"As the ambient sounds blend together, a certain thud-like noise stands out from the chaotic harmony, becoming more and more apparent. Footsteps! Behind y-",
		"{sub.Your} senses sharpen as {sub.youHe} {sub.youHeVerb('notice')} certain sounds quickly form a worrying pattern. Jagged noises are becoming louder and louder. Footsteps. On your six-",
	]

	if( !sub.isBlindfolded() ):
		# Uses sight
		possible.append_array([
			"From the corner of {sub.your} eye, {sub.youHe} {sub.youHeVerb('notice')} someone's shadow creeping about.",
		])

	saynn( RNG.pick(possible) )

	addAction("sneak_up_on", "Sneak up!", "Sneak up on them and grab them in a hold!", "default", 1.0, 60, {})

func init_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "sneak_up_on"):
		setState("sneaked_up_on", "dom")


func sneaked_up_on_text():
	var dom = getRoleChar("dom")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var someone_you:String = "you" if( dom.isPlayer() ) else "someone"
	var someone_YouThey:String = "You" if( dom.isPlayer() ) else "They"
	var someone_youThey:String = "you" if( dom.isPlayer() ) else "they"
	var someone_YouIt:String = "You" if( dom.isPlayer() ) else "It"
	var someone_youIt:String = "you" if( dom.isPlayer() ) else "it"
	var someone_youThem:String = "you" if( dom.isPlayer() ) else "them"
	var someone_yourTheir:String = "your" if( dom.isPlayer() ) else "their"
	var someone_youVerb_grab:String = "grab" if( dom.isPlayer() ) else "grabs"
	var someone_youVerb_swipe:String = "swipe" if( dom.isPlayer() ) else "swipes"

	var both_You_veThey_ve:String = "You've" if( isPlayerInvolved() ) else "They've"
	var both_youThese:String = "you" if( isPlayerInvolved() ) else "these"

	var possible:Array = [
		"Before {sub.youHe} {sub.youHeVerb('know')} it, "+ someone_you +" "+ someone_youVerb_grab +" {sub.youHim} from behind, strongly gripping {sub.yourHis} wrists.",
		"Before {sub.youHe} {sub.youHeVerb('get')} a chance to react, {sub.youHe} {sub.youAreHeIs} grabbed from behind.",
		"Before {sub.youHe} {sub.youHaveHeHas} a chance to react, "+ someone_you +" "+ someone_youVerb_swipe +" at you, grabbing both of {sub.yourHis} wrists.",
		"{sub.You} {sub.youWere} about to turn around, but "+ someone_you +" immediately {dom.youVerb('shove')} into {sub.youHim}, grabbing both of {sub.yourHis} wrists.",
	]

	saynn( RNG.pick(possible) )

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domIsKind:bool = domPersonalityMeanScore < -0.4
	var dom_feline_canine_hybrid:String = dom.getSpeciesFullName().to_lower()
	var dom_feline_MAYBE:String = getIncompleteSpeciesFullName( dom.getSpecies() ).to_lower()
	var subIsNaive:bool = subPawn.scorePersonalityMax({ PersonalityStat.Naive: 1.0 }) > 0.4
	var subPersonalitySubbyScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var subIsSubby:bool = subPersonalitySubbyScore > 0.4
	var subIsDommy:bool = subPersonalitySubbyScore < -0.4
	var affectionValue:float = subPawn.getAffection(domPawn)
	var chanceToIdentifyDom:float = 40.0 + 40.0 * abs(affectionValue)

	var genericUnclearIntentionsEnding = RNG.pick([
		( "What is it that "+ someone_youThey +" want from {sub.youHim}?" ),
		( "What are "+ someone_yourTheir +" intentions with {sub.youHim}?" ),
		( "{sub.YouHaveHeHas} {sub.youHe} done something to upset "+ someone_youThem +"?" ),
		( "What has gotten into "+ someone_youThem +"?" ),
	])

	possible = []

	if( abs(affectionValue) < 0.10 ):
		possible.append_array([
			( "The scent "+ someone_youThey +" carry seems unfamiliar to {sub.you}. It could be anyone from around here. "+ genericUnclearIntentionsEnding ),
			( "{sub.You} {sub.youVerb('do', 'does')} not recall this scent. A part of it seems.. "+ dom_feline_MAYBE +"? "+ genericUnclearIntentionsEnding ),
		])
	elif( abs(affectionValue) < 0.30 ):
		possible.append_array([
			( someone_YouThey +" carry a familiar "+ dom_feline_canine_hybrid +" scent, but {sub.youreTheyre} unable to discern who it belongs to. "+ genericUnclearIntentionsEnding ),
			( "{sub.You} {sub.youVerb('pick')} up on a familiar "+ dom_feline_canine_hybrid +" scent, but {sub.youVerb('fall')} short of inferring the identity behind it. "+ genericUnclearIntentionsEnding ),
		])
	elif( !RNG.chance(chanceToIdentifyDom) ):
		possible.append_array([
			(
					"A very familiar "
				+ dom_feline_canine_hybrid
				+ " scent fills the air, but {sub.you} {sub.youVerb('exert')} {sub.yourselfThemself} trying to remember the scent's owner. {dom.youVerb('Were', 'Was')} "
				+ someone_youIt
				+ " "
				+ RNG.pick([
					"an ally",
					"a follower",
					"a friend",
					"a lilac",
					"a lover",
				])
				+ "? "
				+ RNG.pick([
					"A bully",
					"A guard",
					"A traitor",
				])
				+ "? {sub.YouHe} {sub.youAreHeIs} unable to tell."
			),
			(
					"{sub.You} {sub.youVerb('hope')} to determine the assailant's identity from only their scent, but it proves to be difficult. There is a trace of.. "
				+ dom_feline_MAYBE
				+ " smell in it? The associations it evokes in {sub.you} are"
				+ (
						RNG.pick([
							" a little mixed, but.. recently more comforting than not..",
							( " positive, at least. But {sub.youHe} still cannot trust "+ someone_yourTheir +" intentions." ),
							".. unusually comforting.. given what one would commonly expect when they first hear about this station.",
						])
					if(affectionValue > 0)
					else " somewhat negative. {sub.YouHe} {sub.youHeVerb('swallow')}."
				)
			),
		])
	elif( affectionValue < -0.60 ):
		var optionalEnding:String = ""

		if( RNG.chance(50) ):
			optionalEnding = " " + RNG.pick([
				"Fuck.. No doubt, it has to be {dom.name}.",
				"Undoubtedly, the creature standing behind {sub.youHim} is none other than {dom.name}.",
			])

		possible.append_array([
			( someone_YouThey +" carry a familiar scent, but {sub.your} mind immediately flags it as a threat, causing {sub.youHim} to feel even more alerted."+ optionalEnding ),
		])
	elif( affectionValue < 0 ):
		var optionalEnding:String = ""

		if( RNG.chance(50) ):
			optionalEnding = " " + RNG.pick([
				( "{sub.You} {sub.youVerb('try', 'tries')} to remember "+ someone_yourTheir +" name, and {sub.youVerb('figure')} it might've been {dom.name}." ),
			])

		possible.append_array([
			( "The scent "+ someone_youThey +" carry seems familiar, but it fills the air with this feeling of.. uneasiness. {sub.You} {sub.youVerb('reckon')} it might belong to that one "+ dom_feline_canine_hybrid +" that {sub.youHe} didn't get along very well with."+ optionalEnding ),
		])
	elif( affectionValue < 0.60 ):
		var dom_friendlyPeculiarStern:String = "friendly" if(domIsKind) else ( "peculiar" if(!domIsMean) else "stern" )

		var necessaryEnding:String = RNG.pick([
			" that {sub.youHe} unfortunately {sub.youDontHeDoesnt} remember the name of.",
			" whose name unfortunately seems to have slipped {sub.yourHis} mind..",
			". Sadly, you can't seem to remember {dom.yourHis} name..",
		])

		if( RNG.chance(50) ):
			necessaryEnding = RNG.pick([
				" which was quite happy with {dom.yourHis} preferred name! {dom.name}.",
				" which went by the name of {dom.name}.",
				". What was {dom.yourHis} name again? Ooh.. {dom.name}..",
			])

		possible.append_array([
			( "{sub.You} {sub.youVerb('hope')} to ascertain who "+ someone_youThey +" are, from just "+ someone_yourTheir +" scent and touch. {sub.YouveTheyve} definitely had run-ins with "+ someone_youThem +" in the past. "+ someone_YouIt +" {dom.youVerb('were', 'was')} a "+ dom_friendlyPeculiarStern +" "+ dom_feline_canine_hybrid + necessaryEnding ),
		])
	else:
		var necessaryEnding_variants:Array = []

		if( dom.isPlayerOwner() ):
			necessaryEnding_variants.append_array([
				"{dom.YoureTheyre} {sub.yourHis} owner..",
			])
		else:
			necessaryEnding_variants.append_array([
				( "It hasn't been that long since "+ both_youThese +" two interacted, but it seems that {dom.youHe} {dom.youHeVerb('miss', 'misses')} {sub.youHim} already.." ),
				( "Slight anxiety rushes through {sub.you}. "+ both_You_veThey_ve +" had many good memories together, and wouldn't want this encounter to be any different." ),
			])

			if( ( dom.getThickness() >= 0.70 ) || dom.isVisiblyPregnant() ):
				necessaryEnding_variants.append_array([
					( "{dom.YourHis} large "+( "impregnated " if( dom.isVisiblyPregnant() ) else "" )+"belly presses softly into {sub.you}, washing away any stress {sub.youHe} had left." ),
				])

			if(!subIsDommy):
				necessaryEnding_variants.append_array([
					(
							"{sub.You} might've subtly hinted earlier that it's something {sub.youHe}'d wish happened to {sub.youHim}.."
						+ (
								" It wasn't exactly subtle."
							if( RNG.chance(10) )
							else ""
						)
					),
				])

			if(!domIsMean):
				necessaryEnding_variants.append_array([
					(
							"Many critters here learn about your kinks much sooner than your name, even if most often that information goes straight into the mental trashbin. {dom.You} might actually make good use of that knowledge"
						+ (
								(
										". And {sub.you}."
									if(subIsSubby)
									else ", even at {dom.yourHis} own expense."
								)
							if( RNG.chance(10) )
							else "."
						)
					),
					"{sub.You} instinctively {sub.youVerb('relax', 'relaxes')} {sub.yourHis} arms. Being held by {dom.youHim} is cozy..",
				])

			if(subIsNaive):
				if( RNG.chance(10) ):
					necessaryEnding_variants.append_array([
						"{dom.YouveTheyve} always had {sub.yourHis} back in the past, so why worry if {dom.youHe} {dom.youHaveHeHas} {sub.yourHis} back now?",
					])
			else:
				necessaryEnding_variants.append_array([
					( both_You_veThey_ve +" been on good terms so far, but not even the most dependable inmates have earned {sub.your} absolute trust, so {sub.youHe} {sub.youHeVerb('opt')} to remain careful." ),
				])

		var necessaryEnding:String = RNG.pick(necessaryEnding_variants)

		var domTouch_gentle = RNG.pick(["gentle", "tender", "delicate", "soft", "warm"]) if(domIsKind) else ( RNG.pick(["soft", "warm", "chilly", "gritty", "sensuous", "greedy"]) if(!domIsMean) else RNG.pick(["greedy", "selfish", "mean", "rough", "harsh"]) )

		possible.append_array([
			( "{sub.You} quickly {sub.youVerb('recognize')} the "+ domTouch_gentle +" touch and a rather familiar "+ dom_feline_canine_hybrid +" scent. The creature standing behind {sub.youHim} is {dom.name}. "+ necessaryEnding ),
		])

	saynn( RNG.pick(possible) )

	addAction("tease", "Tease", "Tease them by rubbing against their butt.", "default", 1.0, 60, {})

func sneaked_up_on_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "tease"):
		startInteraction("SneakUpTease", {dom=getRoleID("dom"), sub=getRoleID("sub")})


func getAnimData() -> Array:
	if( getState() == "sneaked_up_on" ):
		return [StageScene.SexFreeStanding, "tease", { pc="dom", npc="sub" }]

	return [StageScene.Solo, "stand", { pc="sub", flipNPC=true }]

func getActivityIconForRole(_role:String):
	return RoomStuff.PawnActivity.None
	
func getPreviewLineForRole(_role:String) -> String:
	if(_role == "dom"):
		return "{dom.name} has caught {sub.name} off guard."
	if(_role == "sub"):
		return "{sub.name} has been caught off guard by {dom.name}."

	return .getPreviewLineForRole(_role)

func shouldHideRelativeActionChances() -> bool:
	return true


func getIncompleteSpeciesFullName(species: Array):
	if( species.size() == 0 ):
		return "Wild"

	var specie = GlobalRegistry.getSpecies( RNG.pick(species) )

	if(specie == null):
		return "Wild"

	return specie.getVisibleName()
