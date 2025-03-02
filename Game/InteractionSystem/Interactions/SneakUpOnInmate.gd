extends PawnInteractionBase

func _init():
	id = "SneakUpOnInmate"

func start(_pawns:Dictionary, _args:Dictionary):
	doInvolvePawn("dom", _pawns["dom"])
	doInvolvePawn("sub", _pawns["sub"])
	setState("", "dom")

func init_text():
	var sub = getRoleChar("sub")

	var possible = [
		"{sub.You} {sub.youVerb('hear')} the faint sound of footsteps.",
		"For a moment, {sub.you} {sub.youVerb('zone')} out, no longer paying attention to {sub.yourHis} surroundings.",
		"As the ambient sounds blend together, a certain thud-like noise stands out from the chaotic harmony, becoming more and more apparent. Footsteps! Behind y-",
	]

	if( !sub.isBlindfolded() ):
		# Uses sight
		possible.append_array([
			"From the corner of {sub.your} eye, {sub.youHe} {sub.youVerb('notice')} someone's shadow creeping about.",
		])

	saynn(RNG.pick(possible))

	addAction("sneak_up_on", "Sneak up!", "Sneak up on them and grab them in a hold!", "default", 1.0, 60, {})

func init_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "sneak_up_on"):
		setState("sneaked_up_on", "dom")


func sneaked_up_on_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var someone_you = "you" if dom.isPlayer() else "someone"
	var someone_YouThey = "You" if dom.isPlayer() else "They"
	var someone_youThey = "you" if dom.isPlayer() else "they"
	var someone_YouIt = "You" if dom.isPlayer() else "It"
	var someone_youIt = "you" if dom.isPlayer() else "it"
	var someone_youThem = "you" if dom.isPlayer() else "them"
	var someone_yourTheir = "your" if dom.isPlayer() else "their"
	var someone_You_veThey_ve = "You've" if dom.isPlayer() else "They've"
	var someone_youVerb_grab = "grab" if dom.isPlayer() else "grabs"
	var someone_youVerb_swipe = "swipe" if dom.isPlayer() else "swipes"

	var sub_youHave = "have" if sub.isPlayer() else "{sub.has}"
	var sub_youWere = "were" if ( sub.isPlayer() || ( sub.hasHave() == "have" ) ) else "was"
	var sub_youVerb_don_t = "don't" if ( sub.isPlayer() || ( sub.hasHave() == "have" ) ) else "doesn't"
	var sub_You_veThey_ve = "You've" if sub.isPlayer() else "They've"
	var sub_you_reHe_s = "you're" if sub.isPlayer() else ( "they're" if ( sub.heShe() == "they" ) else "{sub.he}'s" )

	var possible = [
		"Before {sub.youHe} {sub.youVerb('know')} it, "+ someone_you +" "+ someone_youVerb_grab +" {sub.youHim} from behind, strongly gripping {sub.yourHis} wrists.",
		"Before {sub.youHe} {sub.youVerb('get')} a chance to react, {sub.youHe} {sub.youAre} grabbed from behind.",
		"Before {sub.youHe} "+ sub_youHave +" a chance to react, "+ someone_you +" "+ someone_youVerb_swipe +" at you, grabbing both of {sub.yourHis} wrists.",
		"{sub.You} "+ sub_youWere +" about to turn around, but "+ someone_you +" immediately {dom.youVerb('shove')} into {sub.youHim}, grabbing both of {sub.yourHis} wrists.",
	]

	saynn(RNG.pick(possible))

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4
	var domIsKind = domPersonalityMeanScore < -0.4
	var dom_feline_canine_hybrid = dom.getSpeciesFullName().to_lower()
	var dom_feline_MAYBE = getIncompleteSpeciesFullName( dom.getSpecies() ).to_lower()
	var subIsNaive = subPawn.scorePersonalityMax({ PersonalityStat.Naive: 1.0 }) > 0.4
	var affectionValue:float = subPawn.getAffection(domPawn)
	var chanceToIdentifyDom = 40.0 + 40.0 * abs(affectionValue)
	
	var genericUnclearIntentionsEnding = RNG.pick([
		"What is it that "+ someone_youThey +" want from {sub.youHim}?",
		"What are "+ someone_yourTheir + " intentions with {sub.youHim}?",
		"{sub.youVerb('Have', 'Has')} {sub.youHe} done something to upset "+ someone_youThem +"?",
		"What has gotten into "+ someone_youThem +"?",
	])

	possible = []

	if( abs(affectionValue) < 0.10 ):
		possible.append_array([
			"The scent "+ someone_youThey +" carry seems unfamiliar to {sub.you}. It could be anyone from around here. "+ genericUnclearIntentionsEnding,
			"{sub.You} {sub.youVerb('do', 'does')} not recall this scent. A part of it seems.. "+ dom_feline_MAYBE +"? "+ genericUnclearIntentionsEnding,
		])
	elif( abs(affectionValue) < 0.30 ):
		possible.append_array([
			someone_YouThey +" carry a familiar "+ dom_feline_canine_hybrid +" scent, but "+ sub_you_reHe_s +" unable to discern who it belongs to ."+ genericUnclearIntentionsEnding,
			"{sub.You} {sub.youVerb('pick')} up on a familiar "+ dom_feline_canine_hybrid +" scent, but {sub.youVerb('fall')} short of inferring the identity behind it. "+ genericUnclearIntentionsEnding,
		])
	elif( !RNG.chance(chanceToIdentifyDom) ):
		possible.append_array([
			"A very familiar "+ dom_feline_canine_hybrid +" scent fills the air, but {sub.you} {sub.youVerb('exert')} {sub.yourself} trying to remember the scent's owner. {dom.youVerb('Were', 'Was')} "+ someone_youIt +" an ally? A traitor? {sub.YouHe} {sub.youAre} unable to tell.",
			"{sub.You} {sub.youVerb('hope')} to determine the assailant's identity from only their scent, but it proves to be difficult. There is a trace of.. "+ dom_feline_MAYBE +" smell in it? The associations it evokes in {sub.you} are "+ ( ( "positive, at least. But {sub.youHe} cannot trust "+ someone_yourTheir +" intentions." ) if(affectionValue > 0) else "somewhat negative. {sub.YouHe} {sub.youVerb('swallow')}." ),
		])
	elif( affectionValue < -0.60 ):
		var optionalEnding = ""

		if( RNG.chance(50) ):
			optionalEnding = " " + RNG.pick([
				"Undoubtedly, the creature standing behind {sub.youHim} is none other than {dom.name}.",
			])

		possible.append_array([
			someone_YouThey +" carry a familiar scent, but {sub.your} mind immediately flags it as a threat, causing {sub.youHim} to feel even more alerted."+ optionalEnding,
		])
	elif( affectionValue < 0 ):
		var optionalEnding = ""

		if( RNG.chance(50) ):
			optionalEnding = " " + RNG.pick([
				"{sub.You} {sub.youVerb('try', 'tries')} to remember "+ someone_yourTheir +" name, and {sub.youVerb('figure')} it might've been {dom.name}.",
			])

		possible.append_array([
			"The scent "+ someone_youThey +" carry seems familiar, but it fills the air with this feeling of.. uneasiness. {sub.You} {sub.youVerb('reckon')} it might belong to that one "+ dom_feline_canine_hybrid +" that {sub.youHe} didn't get along very well with."+ optionalEnding,
		])
	elif( affectionValue < 0.60 ):
		var dom_friendlyPeculiarStern = "friendly" if(domIsKind) else ( "stern" if(domIsMean) else "peculiar" )

		var necessaryEnding = RNG.pick([
			"that {sub.youHe} unfortunately "+ sub_youVerb_don_t +" remember the name of.",
		])

		if( RNG.chance(50) ):
			necessaryEnding = RNG.pick([
				"which went by the name of {dom.name}.",
			])

		possible.append_array([
			"{sub.You} {sub.youVerb('hope')} to ascertain who "+ someone_youThey +" are, from just "+ someone_yourTheir +" scent and touch. "+ sub_You_veThey_ve +" definitely had run-ins with "+ someone_youThem +" in the past. "+ someone_YouIt +" {dom.youVerb('were', 'was')} a "+ dom_friendlyPeculiarStern +" "+ dom_feline_canine_hybrid +" "+ necessaryEnding,
		])
	else:
		var necessaryEnding = ""

		if(!subIsNaive):
			necessaryEnding = "You've been on good terms so far, but not even the most dependable inmates have earned {sub.your} absolute trust, so {sub.youHe} {sub.youVerb('opt')} to remain careful."
		else:
			necessaryEnding = someone_You_veThey_ve +" always had {sub.yourHis} back in the past, so why worry if "+ someone_youThey +" have {sub.yourHis} back now?"

		var domTouch_gentle = RNG.pick(["gentle", "tender", "delicate", "soft", "warm"]) if(domIsKind) else ( RNG.pick(["soft", "warm", "chilly", "gritty", "sensuous", "greedy"]) if(!domIsMean) else RNG.pick(["greedy", "selfish", "mean", "rough", "harsh"]) )

		possible.append_array([
			"{sub.You} quickly {sub.youVerb('recognize')} the "+ domTouch_gentle +" touch and a rather familiar "+ dom_feline_canine_hybrid +" scent. The creature standing behind {sub.youHim} is {dom.name}. "+ necessaryEnding,
		])

	saynn(RNG.pick(possible))

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
		return "{dom.name} {dom.has} caught {sub.name} off guard."
	if(_role == "sub"):
		return "{sub.name} {sub.has} been caught off guard by {dom.name}."

	return .getPreviewLineForRole(_role)
	
func getIncompleteSpeciesFullName(species: Array):
	if( species.size() == 0 ):
		return "Creature"

	var specie = GlobalRegistry.getSpecies( RNG.pick(species) )

	if(specie == null):
		return "Creature"

	return specie.getVisibleName()
