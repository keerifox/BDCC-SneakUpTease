extends PawnInteractionBase

var subConsentedToAnalSexReceiving:bool = false
var subConsentedToAnalSexGiving:bool = false
var subWasPinnedToTheGround:bool = false
var subWasUndressed:bool = false
var subWasCuffed:bool = false
var subMightEndSexEarly:bool = false
var subPetNames:Array = ["creature"]

var domIsBottoming:bool = false
var domHasImmediatelyLeftConsentingSub:bool = false
var domToggleableMouthPlayMightPerform:bool = false
var domToggleableMouthPlayState:String = "none"
var domToggleableMouthPlayActiveTurns:int = 0
var domCuddlesLastedTurns:int = 0
var domMessyKissingLastedTurns:int = 0
var domLeashedWalkOnAllFours:bool = false
var domLeashedWalkHelpedSubStand:bool = false
var domLeashedWalkStoodStill:bool = false
var domLeashedWalkReachedTargetLoc:bool = false
var domLeashedWalkTraversedCellsCount:int = 0
var domLeashedWalkTargetLoc:String = ""

var topPenisWasOutsidePreviousTurn:bool = true
var topCameInsidePreviousTurn:bool = false
var topCameInsideThisTurn:bool = false
var topCameOutsideThisTurn:bool = false
var topCameTimes:int = 0

var bottomCameThisTurn:bool = false
var bottomCameTimes:int = 0

var currentSexPoseId:String = "none"
var currentTurnTopOrBottom:String = "nobody"
var hasSexEndedEarly:bool = false
var tfResultText:String = ""

const ANAL_SEX_RECEIVING_POSE_MATING_PRESS = {
	id = "mating_press",
	name = "Mating press",
	stageScene = StageScene.SexMatingPress,
	tags = [
		"bottomBelowTop", "bottomFacingTop",
	],
}
const ANAL_SEX_RECEIVING_POSE_MISSIONARY = {
	id = "missionary",
	name = "Missionary",
	stageScene = StageScene.SexMissionary,
	tags = [
		"bottomBelowTop", "bottomFacingTop", "unboundHandholding",
	],
}
const ANAL_SEX_RECEIVING_POSE_RAISED_LEG = {
	id = "raised_leg",
	name = "Raised leg",
	stageScene = StageScene.SexPawLick,
	tags = [
		"topLickingBottomHindPawbs", "bottomFacingTop", "bottomCumsOverSelf", "unboundHandholding",
	],
}

const ANAL_SEX_RECEIVING_STANDING_POSES = [
	{
		id = "standing",
		name = "Standing",
		stageScene = StageScene.SexFreeStanding,
		fastAnimationMinArousal = 0.90,
		tags = [
			"toggleableMouthPlay",
		],
	},
	{
		id = "full_nelson",
		name = "Full nelson",
		stageScene = StageScene.SexFullNelson,
		tags = [
			"toggleableMouthPlay",
		],
	},
	ANAL_SEX_RECEIVING_POSE_MATING_PRESS,
	ANAL_SEX_RECEIVING_POSE_MISSIONARY,
	ANAL_SEX_RECEIVING_POSE_RAISED_LEG,
	{
		id = "against_a_wall",
		name = "Against a wall",
		stageScene = StageScene.SexStanding,
		fastAnimationMinArousal = 0.90,
		requirements = {
			wallsNearby = true,
		},
		tags = [
			"toggleableMouthPlay",
		],
	},
	{
		id = "pinned_into_wall",
		name = "Pinned into wall",
		stageScene = StageScene.SexPinnedBehind,
		fastAnimationMinArousal = 0.80,
		requirements = {
			wallsNearby = true,
		},
		tags = [
			"bottomUnboundArmsGraspingAtWall", "toggleableMouthPlay",
		],
	},
]

const ANAL_SEX_RECEIVING_PINNED_POSES = [
	{
		id = "prone_bone",
		name = "Prone bone",
		stageScene = StageScene.SexBehind,
		oddsScore = 3.0,
		tags = [
			"bottomBelowTop",
		],
	},
	{
		id = "all_fours",
		name = "All fours",
		stageScene = StageScene.SexAllFours,
		oddsScore = 3.0,
		tags = [
			"bottomUnboundArmsSupportingChest",
		],
	},
	ANAL_SEX_RECEIVING_POSE_MATING_PRESS,
	ANAL_SEX_RECEIVING_POSE_MISSIONARY,
	ANAL_SEX_RECEIVING_POSE_RAISED_LEG,
]

const ANAL_SEX_GIVING_POSES = [
	{
		id = "cowgirl",
		name = "Cowgirl",
		stageScene = StageScene.SexCowgirl,
		tags = [
			"bottomFacingTop",
		],
	},
	{
		id = "cowgirl_alt",
		name = "Reclined",
		stageScene = StageScene.SexCowgirlAlt,
		tags = [
			"bottomFacingTop",
		],
	},
	{
		id = "cowgirl_reverse",
		name = "Reverse",
		stageScene = StageScene.SexReverseCowgirl,
		tags = [
			
		],
	},
	{
		id = "lotus",
		name = "Lotus",
		stageScene = StageScene.SexLotus,
		stageSceneSwapCharacters = true,
		tags = [
			"bottomFacingTop",
		],
	},
]

var SEX_POSE_ARRAYS = [
	ANAL_SEX_RECEIVING_STANDING_POSES,
	ANAL_SEX_RECEIVING_PINNED_POSES,
	ANAL_SEX_GIVING_POSES,
]

func _init():
	id = "SneakUpFinale"

func start(_pawns:Dictionary, _args:Dictionary):
	doInvolvePawn("dom", _pawns["dom"])
	doInvolvePawn("sub", _pawns["sub"])

	if( _args.has("subConsentedToAnalSexReceiving") && _args["subConsentedToAnalSexReceiving"] ):
		subConsentedToAnalSexReceiving = true
	if( _args.has("subConsentedToAnalSexGiving") && _args["subConsentedToAnalSexGiving"] ):
		subConsentedToAnalSexGiving = true
	if( _args.has("subWasPinnedToTheGround") && _args["subWasPinnedToTheGround"] ):
		subWasPinnedToTheGround = true
	if( _args.has("subWasUndressed") && _args["subWasUndressed"] ):
		subWasUndressed = true
	if( _args.has("subPetNames") ):
		subPetNames = _args["subPetNames"]

	if(subConsentedToAnalSexReceiving || subConsentedToAnalSexGiving):
		getRoleChar("dom").lustStateFullyUndress()
		getRoleChar("sub").lustStateFullyUndress()

		getRoleChar("dom").setArousal(0.0)
		getRoleChar("sub").setArousal(0.0)

	domToggleableMouthPlayMightPerform = RNG.chance(50)
	subMightEndSexEarly = RNG.chance(1)

	setState("", "dom")

func init_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	var both_youThem = "you" if( isPlayerInvolved() ) else "them"
	var dom_you_veHe_s = "you've" if dom.isPlayer() else ( "they've" if ( dom.heShe() == "they" ) else "{dom.he}'s" )
	var sub_youDon_t = "don't" if ( sub.isPlayer() || ( sub.hasHave() == "have" ) ) else "doesn't"

	var possible = []

	if(subConsentedToAnalSexReceiving || subConsentedToAnalSexGiving):
		possible.append_array([
			"{sub.You} {sub.youAre} fully lost in the thought, eagerly awaiting for {dom.you} to have {dom.yourHis} way with {sub.youHim}.",
		])
	else:
		possible.append_array([
			"{sub.You} "+ sub_youDon_t +" seem interested in a sexual intercourse with {dom.you}. If there's anything else that {dom.youHe} {dom.youVerb('have', 'has')} on offer, there's a good chance {sub.youHe} might indulge.",
			"{sub.You} {sub.youAre}n't exactly warm to the idea of {dom.you} fucking {sub.youHim}, so that's off the table. {dom.YouHe} can still mess with {sub.youHim} a little, before {dom.youHe} {dom.youVerb('leave')}.",
			"{sub.You} may not want {dom.you} fucking {sub.youHim}, but "+ dom_you_veHe_s + " showered {sub.youHim} with enough attention, for {sub.youHim} to be open to a brief play session before "+ both_youThem +" part ways.",
			"Seems {dom.you} {dom.youVerb('were', 'was')} rather off the mark on what {sub.you} would be interested in doing with {dom.youHim}. However, {sub.youHe} did find {dom.yourHis} determination rather impressive, and likely wouldn't oppose a small parting gift of sorts.",
		])

	saynn(RNG.pick(possible))

	if(subConsentedToAnalSexReceiving):
		addAction("dom_anal_sex_giving_pose_select", "Fuck: Anal", "Proceed to pose selection for a sexual act in which you are fucking their butt~", "default", 1.0, 60, {})

	if(subConsentedToAnalSexGiving):
		addAction("dom_anal_sex_receiving_pose_select", "Ride: Anal", "Proceed to pose selection for a sexual act in which you are riding their cock~", "default", 1.0, 60, {})

	var domProbabilityToStartPlaySession = -0.01 if(subConsentedToAnalSexReceiving || subConsentedToAnalSexGiving) else 1.0
	addAction("dom_parting_action_select", "Play session", "Proceed to parting action selection.", "default", domProbabilityToStartPlaySession, 60, {})

	addAction("leave", "Leave", "You don't feel like doing anything with them.", "default", -0.01, 60, {})

func init_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "dom_anal_sex_giving_pose_select"):
		domIsBottoming = false
		setState("dom_choosing_sex_pose", "dom")
	elif(_id == "dom_anal_sex_receiving_pose_select"):
		domIsBottoming = true
		setState("dom_choosing_sex_pose", "dom")
	elif(_id == "dom_parting_action_select"):
		setState("dom_choosing_parting_action", "dom")
	elif(_id == "leave"):
		if(subConsentedToAnalSexReceiving || subConsentedToAnalSexGiving):
			domHasImmediatelyLeftConsentingSub = true
			affectAffection("sub", "dom", -0.10)

		setState("dom_left_sub_alone", "dom")


func dom_choosing_sex_pose_text():
	var possible = []
	
	if(domIsBottoming):
		possible.append_array([
			"{dom.You} {dom.youVerb('reach', 'reaches')} around, cravingly teasing {sub.your} "+ getTopPenisDesc() +" while deciding on a pose to take {sub.youHim} in.",
		])
	else:
		possible.append_array([
			"{dom.You} playfully {dom.youVerb('run')} a digit between {sub.your} buttcheeks, thinking about which pose {dom.youHe} {dom.youVerb('want')} {sub.youHim} the most in.",
		])

	saynn(RNG.pick(possible))

	addAction("select_sex_pose_random", "Random", "Let your subconsiousness choose a pose.", "default", 2.0, 60, {})

	for sexPose in getRelevantSexPoses():
		var unmetRequirements:Array = getSexPoseUnmetRequirements(sexPose)

		if( unmetRequirements.size() == 0 ):
			var domProbabilityToSelectPose = sexPose.oddsScore if( sexPose.has("oddsScore") ) else 1.0
			addAction( ("select_sex_pose_" + sexPose.id), sexPose.name, "Picture this pose to decide if this is what you want.", "default", domProbabilityToSelectPose, 60, {} )
		else:
			addDisabledAction(sexPose.name, Util.join(unmetRequirements))

	addAction("cancel", "Cancel", "Leave the pose selection.", "default", -0.01, 0, {})

func dom_choosing_sex_pose_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")

	if(_id == "cancel"):
		setState("", "dom")
		return

	var availablePoses = []

	for sexPose in getRelevantSexPoses():
		var unmetRequirements:Array = getSexPoseUnmetRequirements(sexPose)

		if( unmetRequirements.size() == 0 ):
			availablePoses.append(sexPose)

	var stateIdSuffix = "_preview" if dom.isPlayer() else "_done"

	if(_id == "select_sex_pose_random"):
		var randomlySelectedPose = RNG.pick(availablePoses)
		currentSexPoseId = randomlySelectedPose.id
	else:
		for availablePose in availablePoses:
			if( _id == ("select_sex_pose_" + availablePose.id) ):
				currentSexPoseId = availablePose.id

	setState( ("dom_choosing_sex_pose" + stateIdSuffix), "dom" )


func dom_choosing_sex_pose_preview_text():
	var defaultSexPoseId = "standing" if(!subWasPinnedToTheGround) else "prone_bone"

	var possible = []
	
	if(currentSexPoseId == defaultSexPoseId):
		possible.append_array([
			"Normally, {dom.youHe}'d picture the pose in {dom.yourHis} mind, but for this specific pose there's no need to imagine. Still, {dom.your} mind drifts to depict considerably hornier views of {sub.your} body, which happen to help {dom.youHim} weigh on whether this is {dom.yourHis} most desired pose.",
		])
	else:
		possible.append_array([
			"{dom.You} {dom.youVerb('imagine')} {dom.yourself} about to "+ ( "ride" if(domIsBottoming) else "fuck" ) +" {sub.you} " + getPoseDescForCurrentSexPose() + ".",
		])

	saynn(RNG.pick(possible))

	saynn("Is this what {dom.you} {dom.youVerb('want')}?")

	var yes_id = "yes_skip_return_to_reality" if(currentSexPoseId == defaultSexPoseId) else "yes_return_to_reality"

	addAction(yes_id, "Yes", "Proceed with this pose for the rest of the interaction.", "default", 1.0, 60, {})
	addAction("no", "No", "Return to pose selection.", "default", 1.0, 60, {})

func dom_choosing_sex_pose_preview_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "yes_return_to_reality"):
		setState("dom_choosing_sex_pose_return_to_reality", "dom")
	elif(_id == "yes_skip_return_to_reality"):
		setState("dom_choosing_sex_pose_done", "dom")
	elif(_id == "no"):
		currentSexPoseId = "none"
		setState("dom_choosing_sex_pose", "dom")


func dom_choosing_sex_pose_return_to_reality_text():
	saynn( RNG.pick([
		"{dom.You} reluctantly {dom.youVerb('quit')} imagining {sub.name} in a captivating pose, returning to focus on reality in which {sub.youHe} {sub.youAre} still "+ ( "standing in front of {dom.youHim}" if(!subWasPinnedToTheGround) else "pinned underneath {dom.youHim}" ) + ", eagerly waiting on {dom.youHim} to act.",
		"{dom.You} hesitantly {dom.youVerb('stop')} picturing {sub.name} in an enticing pose, snapping back to reality in which {sub.youHe} {sub.youAre} still "+ ( "standing in front of {dom.youHim}" if(!subWasPinnedToTheGround) else "pinned underneath {dom.youHim}" ) + ", patiently waiting on {dom.youHim} to begin.",
	]) )

	addAction("enter_pose", "Enter pose", "Get both of you into the desired pose.", "default", 1.0, 60, {})

func dom_choosing_sex_pose_return_to_reality_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "enter_pose"):
		setState("dom_choosing_sex_pose_done", "dom")


func dom_choosing_sex_pose_done_text():
	var eventLines = getEventLinesForCurrentSexPose_gettingIntoPose()

	saynn(RNG.pick(eventLines))

	addAction("fuck", "Fuck", "Start the fucking.", "default", 1.0, 60, {})

func dom_choosing_sex_pose_done_do(_id:String, _args:Dictionary, _context:Dictionary):
	var top = getTopChar()
	var bottom = getBottomChar()

	if(_id == "fuck"):
		var nextTurnTopOrBottom = "top" if(domIsBottoming) else "bottom"

		increaseArousal({ nextTurnTopOrBottom = nextTurnTopOrBottom, })
		bottom.gotOrificeStretchedBy( BodypartSlot.Anus, top.getID(), true, 0.2 )

		currentTurnTopOrBottom = nextTurnTopOrBottom
		setState("sex_"+ nextTurnTopOrBottom +"_turn", "sub")


func sex_bottom_turn_text():
	var priorityRandomness = getPriorityRandomness()

	var baseLines = getBaseLinesForCurrentSexPose_priority(priorityRandomness)

	if( baseLines.size() < 1 ):
		baseLines = getBaseLinesForCurrentSexPose_beingFucked()

	var eventLine = RNG.pick(baseLines)

	var flavorLines = getFlavorLinesForCurrentSexPose_priority(priorityRandomness)

	if( flavorLines.size() < 1 ):
		flavorLines = getFlavorLinesForCurrentSexPose_beingFucked()

		if( RNG.chance( 100 - 10 * flavorLines.size() ) ):
			flavorLines = []

	if( ( flavorLines.size() > 0 ) && ( flavorLines[0] != "[no flavor allowed]" ) ):
		eventLine += ( " "+ RNG.pick(flavorLines) )

	eventLine = postProcessEventLine(eventLine)
	saynn(eventLine)

	incl_sex_turn_text()

func sex_bottom_turn_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_sex_turn_do_preTick(_id)

	incl_sex_turn_do(_id, _args, _context)


func sex_top_turn_text():
	var dom = getRoleChar("dom")
	var top = getTopChar()

	var topIsAboutToCum = top.getArousal() >= 1.0
	var priorityRandomness = getPriorityRandomness()

	var baseLines = getBaseLinesForCurrentSexPose_priority(priorityRandomness)

	if( baseLines.size() < 1 ):
		baseLines = getBaseLinesForCurrentSexPose_fucking()

	var eventLine = RNG.pick(baseLines)

	var flavorLines = getFlavorLinesForCurrentSexPose_priority(priorityRandomness)

	if( flavorLines.size() < 1 ):
		flavorLines = getFlavorLinesForCurrentSexPose_fucking()

		if( RNG.chance( 100 - 10 * flavorLines.size() ) ):
			flavorLines = []

	if( ( flavorLines.size() > 0 ) && ( flavorLines[0] != "[no flavor allowed]" ) ):
		eventLine += ( " "+ RNG.pick(flavorLines) )

	eventLine = postProcessEventLine(eventLine)
	saynn(eventLine)

	if(topIsAboutToCum):
		var domLustInterests:LustInterests = dom.getLustInterests()
		var domLustInterestInStuffedAss = domLustInterests.getInterestValue(InterestTopic.StuffedAss)
		var domLustInterestInCoveredInCum = domLustInterests.getInterestValue(InterestTopic.CoveredInCum)

		var domProbabilityToPickStuffedAss = 0.5 + domLustInterestInStuffedAss
		var domProbabilityToPickPullingOut = 0.5 + domLustInterestInCoveredInCum
		var domProbabilityMax = max(domProbabilityToPickStuffedAss, domProbabilityToPickPullingOut)

		while(domProbabilityMax < 0.5):
			domProbabilityToPickStuffedAss += 0.1
			domProbabilityToPickPullingOut += 0.1
			domProbabilityMax = max(domProbabilityToPickStuffedAss, domProbabilityToPickPullingOut)

		if(domIsBottoming):
			addAction("cum_inside", "Get cummed in", "Allow the cum to fill you up.", "default", domProbabilityToPickStuffedAss, 60, {})
			addAction("cum_outside", "Pull out", "Pull out before they can cum into you.", "default", domProbabilityToPickPullingOut, 60, {})
		else:
			addAction("cum_inside", "Cum: Inside", "Finish inside of them.", "default", domProbabilityToPickStuffedAss, 60, {})
			addAction("cum_outside", "Cum: Outside", "Finish after pulling out.", "default", domProbabilityToPickPullingOut, 60, {})
	else:
		incl_sex_turn_text()

func sex_top_turn_do(_id:String, _args:Dictionary, _context:Dictionary):
	var top = getTopChar()
	var bottom = getBottomChar()

	incl_sex_turn_do_preTick(_id)

	if( _id in ["cum_inside", "cum_outside"] ):
		topCameTimes += 1

		bottom.gotAnusFuckedBy( top.getID() )

		top.addLust( -int( top.getLust() * 0.5 ) )
		top.setArousal(0.0)

		if(_id == "cum_inside"):
			topCameInsideThisTurn = true

			if( !bottom.hasWombIn(BodypartSlot.Anus) || RNG.chance( OPTIONS.getSandboxOffscreenBreedingMult() * 100.0 ) ):
				bottom.cummedInAnusBy( top.getID() )

			bottom.addArousal(0.2)
		else:
			topCameOutsideThisTurn = true
			bottom.cummedOnBy( top.getID() )
			bottom.gotOrificeStretchedBy( BodypartSlot.Anus, top.getID(), true, 0.1 )

		if(domIsBottoming):
			currentTurnTopOrBottom = "bottom"
		else:
			currentTurnTopOrBottom = "top"

		setState("sex_"+ currentTurnTopOrBottom +"_turn", "dom")
	else:
		incl_sex_turn_do(_id, _args, _context)

	if( bottom.getArousal() >= 1.0 ):
		bottomCameThisTurn = true
		bottomCameTimes += 1

		bottom.addLust( -int( bottom.getLust() * 0.5 ) )
		bottom.setArousal(0.0)


func confirming_whether_to_end_sex_text():
	var character = getCurrentPawn().getCharacter()
	var characterRole = "dom" if( getRoleChar("dom") == character ) else "sub"

	var character_you_veHe_s = "you've" if character.isPlayer() else ( "they've" if ( character.heShe() == "they" ) else ("{"+ characterRole + ".he}'s") )

	if(hasSexEndedEarly):
		saynn("{"+ characterRole + ".YouAre} {"+ characterRole + ".you} sure {"+ characterRole + ".youHe} {"+ characterRole + ".youVerb('want')} to stop here?")
	else:
		saynn("{"+ characterRole + ".YouAre} {"+ characterRole + ".you} sure "+ character_you_veHe_s +" had enough?")

	addAction("confirm_end_sex", "End sex", ( "You want it to stop." if(hasSexEndedEarly) else "You've really had enough." ), "default", 1.0, 60, {})
	addAction("cancel", "Cancel", "You did not really mean to press that..", "default", 0.1, 0, {})

func confirming_whether_to_end_sex_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "confirm_end_sex"):
		if(hasSexEndedEarly):
			var partnerDomOrSubString = getBottomRole() if(currentTurnTopOrBottom == "top") else getTopRole()
			setState("ended_sex_early", partnerDomOrSubString)
		else:
			setState("dom_after_sex", "dom")
	elif(_id == "cancel"):
		var domOrSubString = getTopRole() if(currentTurnTopOrBottom == "top") else getBottomRole()
		setState("sex_"+ currentTurnTopOrBottom + "_turn", domOrSubString)


func ended_sex_early_text():
	var partner = getCurrentPawn().getCharacter()
	var partnerRole = "dom" if( getRoleChar("dom") == partner ) else "sub"
	var partnerPawn = getRolePawn(partnerRole)
	var characterRole = "sub" if(partnerRole == "dom") else "dom"
	var character = getRoleChar(characterRole)
	var characterTopOrBottom = "top" if( characterRole == getTopRole() ) else "bottom"

	var partnerPersonalityMeanRatio = ( partnerPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) + 1.0 ) / 2.0

	var possible = []

	if(tfResultText != ""):
		var impossibleToContinueWhat:String = (
				( "using" if(characterTopOrBottom == "bottom") else "being used by" )
			if(domIsBottoming)
			else ( "pounding" if(characterTopOrBottom == "top") else "being pounded by" )
		)

		saynn( RNG.pick([
			"As waves of pleasure rock over {"+characterRole+".youHim}, {"+characterRole+".you} {"+characterRole+".youVerb('begin')} to notice certain changes in {"+characterRole+".yourHis} body that make it impossible to continue "+ impossibleToContinueWhat +" {"+partnerRole+".you}.",
		]) )

		possible = getDialogueLines_endedSexEarlyDueToTransformation(character, characterRole)
		if( possible.size() > 0 ):
			saynn("[say="+characterRole+"]"+ RNG.pick(possible) +"[/say]")

		possible = getDialogueLines_endedSexEarlyDueToTransformationReaction(partner, partnerRole)
		if( possible.size() > 0 ):
			saynn("[say="+partnerRole+"]"+ RNG.pick(possible) +"[/say]")
	elif(characterRole == "dom"):
		var dom = character
		var sub = partner

		if(domIsBottoming):
			possible.append_array([
				"{dom.You} {dom.youVerb('quit')} riding {sub.you} up and down, carefully ascending.",
			])
		else:
			possible.append_array([
				"{dom.You} {dom.youVerb('reduce')} the speed of {dom.yourHis} thrusts to a halt, carefully pulling out.",
			])

		saynn(RNG.pick(possible))

		possible = getDialogueLines_endedSexEarly(dom, "dom")
		saynn("[say=dom]"+ RNG.pick(possible) +"[/say]")

		possible = getDialogueLines_endedSexEarlyReaction(sub, "sub")
		saynn("[say=sub]"+ RNG.pick(possible) +"[/say]")
	else:
		var sub = character
		var dom = partner

		if( sub.hasBoundArms() || sub.hasBlockedHands() ):
			possible.append_array([
				"{sub.You} {sub.youVerb('call')} out to {dom.you}, simultaneously using the movement of {sub.yourHis} body to [color="+ getSensationColor("attention") +"]indicate that {sub.youHe} {sub.youVerb('need')} {dom.youHim} to stop[/color].",
			])
		else:
			possible.append_array([
				"{sub.You} {sub.youVerb('raise')} {sub.yourHis} paw, digits spread out, waving it to {dom.you}, [color="+ getSensationColor("attention") +"]signaling that {sub.youHe} {sub.youVerb('need')} {dom.youHim} to stop[/color].",
			])

		saynn(RNG.pick(possible))

		possible = []

		if(domIsBottoming):
			possible.append_array([
				"{dom.You} {dom.youVerb('quit')} riding {sub.you} up and down, carefully ascending to pay close attention to {sub.youHim}.",
			])
		else:
			possible.append_array([
				"{dom.You} {dom.youVerb('reduce')} the speed of {dom.yourHis} thrusts to a halt, carefully pulling out, and leaning forward to check on {sub.you}.",
			])

		saynn(RNG.pick(possible))

		possible = getDialogueLines_endedSexEarly(sub, "sub")
		saynn("[say=sub]"+ RNG.pick(possible) +"[/say]")

		possible = getDialogueLines_endedSexEarlyReaction(dom, "dom")
		saynn("[say=dom]"+ RNG.pick(possible) +"[/say]")

	var partnerOfferCuddlesProbability = 1.0 - 1.4 * partnerPersonalityMeanRatio
	var partnerLetThemLeaveProbability = 1.0 - max(partnerOfferCuddlesProbability, 0.0)
	addAction("offer_cuddles", "Offer cuddles", "Offer them cuddles.", "default", partnerOfferCuddlesProbability, 60, {})
	addAction("let_them_leave", "Let them leave", "Don't offer any cuddles.", "default", partnerLetThemLeaveProbability, 60, {})

func ended_sex_early_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "offer_cuddles"):
		var partner = getCurrentPawn().getCharacter()
		var characterRole = "dom" if( getRoleChar("sub") == partner ) else "sub"
		setState("offered_cuddles", characterRole)
	elif(_id == "let_them_leave"):
		afterSexEnded()
		affectAffection("sub", "dom", 0.05)
		resetLustState()
		setState("dom_left_sub_alone", "dom")


func offered_cuddles_text():
	var character = getCurrentPawn().getCharacter()
	var characterRole = "dom" if( getRoleChar("dom") == character ) else "sub"
	var partnerRole = "sub" if(characterRole == "dom") else "dom"
	var partner = getRoleChar(partnerRole)

	var dialogueLines = getDialogueLines_offerCuddles(partner, partnerRole)
	saynn("[say="+ partnerRole +"]"+ RNG.pick(dialogueLines) +"[/say]")

	addAction("yes", "Yes", "Agree to cuddle.", "default", 1.0, 60, {})
	addAction("no", "No", "You don't want to cuddle.", "default", 0.2, 60, {})

func offered_cuddles_do(_id:String, _args:Dictionary, _context:Dictionary):
	var character = getCurrentPawn().getCharacter()
	var partnerRole = "dom" if( getRoleChar("sub") == character ) else "sub"

	if(_id == "yes"):
		setState("agreed_to_cuddles", partnerRole)
	elif(_id == "no"):
		setState("refused_cuddles", partnerRole)


func agreed_to_cuddles_text():
	var partner = getCurrentPawn().getCharacter()
	var partnerRole = "dom" if( getRoleChar("dom") == partner ) else "sub"
	var characterRole = "sub" if(partnerRole == "dom") else "dom"
	#var character = getRoleChar(characterRole)

	var possible = [
		"{"+ characterRole +".You} {"+ characterRole +".youVerb('nod')}."
	]

	saynn(RNG.pick(possible))

	addAction("cuddles", "Cuddles", "Envelop them in a hug.", "default", 1.0, 60, {})

func agreed_to_cuddles_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "cuddles"):
		afterSexEnded()
		setState("dom_cuddling_sub", "dom")


func refused_cuddles_text():
	var partner = getCurrentPawn().getCharacter()
	var partnerRole = "dom" if( getRoleChar("dom") == partner ) else "sub"
	var characterRole = "sub" if(partnerRole == "dom") else "dom"
	#var character = getRoleChar(characterRole)

	var possible = [
		"{"+ characterRole +".You} {"+ characterRole +".youVerb('shake')} head."
	]

	saynn(RNG.pick(possible))

	addAction("leave", "Leave", "Leave them here.", "default", 1.0, 60, {})

func refused_cuddles_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		afterSexEnded()
		affectAffection("sub", "dom", 0.10)
		resetLustState()
		setState("dom_left_sub_alone", "dom")


func dom_after_sex_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	var eventLines = getEventLinesForCurrentSexPose_afterSex()

	saynn(RNG.pick(eventLines))

	var domDialogueChance = 10 if( isPlayerInvolved() ) else 50

	if( sub.isPlayer() ):
		domDialogueChance = 100 - domDialogueChance

	var dialogueLines = []

	if( RNG.chance(domDialogueChance) ):
		dialogueLines = getDialogueLines_afterSex(dom, "dom")
		saynn("[say=dom]"+ RNG.pick(dialogueLines) +"[/say]")
	else:
		var subSeekingAffirmationChance = 0 if(subIsMean) else 20

		if( RNG.chance(subSeekingAffirmationChance) ):
			dialogueLines = getDialogueLines_afterSexSubSeekingAffirmation(sub)
			saynn("[say=sub]"+ RNG.pick(dialogueLines) +"[/say]")

			if( RNG.chance(60) ):
				dialogueLines = getDialogueLines_afterSexSubSeekingAffirmationReaction(dom)
				saynn("[say=dom]"+ RNG.pick(dialogueLines) +"[/say]")
			else:
				saynn( RNG.pick([
					"{dom.You} {dom.youVerb('reach', 'reaches')} towards {sub.your} hair, petting it softly, without a word leaving {dom.yourHis} mouth.",
				]) )
		else:
			dialogueLines = getDialogueLines_afterSex(sub, "sub")
			saynn("[say=sub]"+ RNG.pick(dialogueLines) +"[/say]")

	addAction("leave", "Leave", "Leave them here.", "default", 1.0, 60, {})

func dom_after_sex_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		afterSexEnded()
		resetLustState()
		setState("dom_left_sub_alone", "dom")


func dom_choosing_parting_action_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanRatio = ( domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) + 1.0 ) / 2.0

	var possible = []
	
	if(subWasPinnedToTheGround):
		possible.append_array([
			"{dom.You} {dom.youVerb('hold')} {sub.you} pressed to the ground, deciding what to do with {sub.youHim}.",
		])
	else:
		possible.append_array([
			"{dom.You} {dom.youVerb('keep')} a tight grip on {sub.your} wrists, while thinking what to do with {sub.youHim}.",
		])

	saynn(RNG.pick(possible))

	var isAtLeastOneActionAvailable = false

	var domCuddlesProbability = max( (1.0 - 2.0 * domPersonalityMeanRatio), ( -0.01 if( !dom.isMuzzled() && !sub.isMuzzled() ) else 0.20 ) )
	var domMessyKissesProbability = 1.0 - max(domCuddlesProbability, 0.0)
	addAction("cuddles", "Cuddles", "Envelop them in a hug, before leaving.", "default", domCuddlesProbability, 60, {})
	isAtLeastOneActionAvailable = true

	var ACTION_NAME_MESSY_KISSES = "Messy kisses"
	if( !dom.isMuzzled() && !sub.isMuzzled() ):
		addAction("messy_kisses", ACTION_NAME_MESSY_KISSES, "Kiss them sloppily, before leaving.", "default", domMessyKissesProbability, 60, {})
		isAtLeastOneActionAvailable = true
	elif( dom.isMuzzled() && sub.isMuzzled() ):
		addDisabledAction(ACTION_NAME_MESSY_KISSES, "Unable to do this when both of you are muzzled.")
	elif( sub.isMuzzled() ):
		addDisabledAction(ACTION_NAME_MESSY_KISSES, "Unable to do this when they are muzzled.")
	else:
		addDisabledAction(ACTION_NAME_MESSY_KISSES, "Unable to do this when you are muzzled.")

	var ACTION_NAME_RESTRAIN = "Restrain them"
	if( sub.isGuard() && !sub.hasBoundArms() ):
		addAction("cuff_sub", ACTION_NAME_RESTRAIN, "Put them in their own restraints and leave.", "default", 1.0, 60, {})
		isAtLeastOneActionAvailable = true
	elif( !sub.isGuard() ):
		addDisabledAction(ACTION_NAME_RESTRAIN, "They're not a guard.")
	else:
		addDisabledAction(ACTION_NAME_RESTRAIN, "They already have restraints on their arms.")

	if( sub.getInventory().hasEquippedItemWithTag(ItemTag.AllowsEnslaving) || dom.isPlayer() ):
		var leashedWalkTime = ( 60 if( sub.getInventory().hasEquippedItemWithTag(ItemTag.AllowsEnslaving) ) else 0 )
		addAction("leash_walk_sub", "Leashed walk", "Walk them around the area on a leash, before leaving.", "default", 1.0, leashedWalkTime, {})
		isAtLeastOneActionAvailable = true

	var domJustLeaveProbability = -0.01 if(isAtLeastOneActionAvailable) else 1.00
	addAction("cancel", "Cancel", "Leave the parting action selection.", "default", domJustLeaveProbability, 0, {})

func dom_choosing_parting_action_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	if(_id == "cuddles"):
		setState("dom_cuddling_sub", "dom")
	elif(_id == "messy_kisses"):
		setState("dom_messy_kissing_sub", "dom")
	elif(_id == "cuff_sub"):
		var subInventory = sub.getInventory()

		if( !sub.hasBoundArms() ):
			subInventory.forceEquipStoreOther( GlobalRegistry.createItem("inmatewristcuffs") )

		if( !sub.hasBoundLegs() ):
			subInventory.forceEquipStoreOther( GlobalRegistry.createItem("inmateanklecuffs") )

		if( dom.isPlayer() ):
			dom.addSkillExperience(Skill.BDSM, 5)

		var subInterestInBondage = subPawn.scoreFetishMax({ Fetish.Bondage: 1.0 })
		var affectionIncrease:float = clamp( (-0.2 + 0.1 * subInterestInBondage), -0.2, -0.1 )
		affectAffection("sub", "dom", affectionIncrease)

		subWasCuffed = true

		setState("dom_cuffed_guard_sub", "dom")
	elif(_id == "leash_walk_sub"):
		if( sub.getInventory().hasEquippedItemWithTag(ItemTag.AllowsEnslaving) ):
			setState("dom_choosing_leash_walking_variant", "dom")
		else:
			setState("dom_confirming_whether_to_collar_sub", "dom")
	elif(_id == "cancel"):
		setState("", "dom")


func dom_cuddling_sub_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	var affectionValue:float = domPawn.getAffection(subPawn)

	var dom_you_reHe_s = "you're" if dom.isPlayer() else ( "they're" if ( dom.heShe() == "they" ) else "{dom.he}'s" )
	var dom_you_veHe_s = "you've" if dom.isPlayer() else ( "they've" if ( dom.heShe() == "they" ) else "{dom.he}'s" )

	var possible = []

	if( hasSexEndedEarly && (domCuddlesLastedTurns == 0) ):
		possible.append_array([
			"{dom.You} {dom.youVerb('sit')} on {dom.yourHis} butt, opening {dom.yourHis} arms wide for {sub.you}. {sub.YouHe} {sub.youVerb('rest')} nearby, letting {dom.youHim} envelop {sub.youHim} in a hug.",
		])

		saynn( RNG.pick(possible) )
	elif( !hasSexEndedEarly && (domCuddlesLastedTurns == 0) ):
		if(subWasPinnedToTheGround):
			possible.append_array([
				"{dom.Your} weight shifted off of {sub.you}, as {dom.youHe} sat nearby, dragging {sub.youHim} on {sub.yourHis} butt, before enveloping {sub.youHim} in a hug.",
			])
		else:
			possible.append_array([
				"{dom.You} forcefully {dom.youVerb('drag')} {sub.you} on {sub.yourHis} butt, then sit right behind, enveloping {sub.youHim} in a hug.",
			])

		saynn( RNG.pick(possible) )

		possible = []

		if(subIsMean):
			possible.append_array([
				"{sub.You} {sub.youVerb('were', 'was')} about to pull away while throwing some mean words at {dom.you}, but {sub.youHe} didn't. {sub.YouHe} sat still, not putting up a rude expression, not fighting {dom.your} embrace, and not calling {dom.youHim} a slut"+ ( (" ("+ dom_you_reHe_s +" still one, however)") if( dom.isPlayer() && hasRepLevelPC("dom", RepStat.Whore, 2) ) else "" ) +". One would say it was rather out of character, "+ ( ("but "+ dom_you_veHe_s +" known {sub.youHim} enough to know there's more to {sub.yourHis} personality than the thorns on display.") if(affectionValue > 0.8) else ("but "+ dom_you_veHe_s +" never really figured out which side would be {sub.yourHis} genuine self. Perhaps, it's not as naive as that, and it's both beings that comprise {sub.youHim} for who {sub.youHe} {sub.youAre}. Perhaps, it goes beyond two.") ),
			])
		else:
			possible.append_array([
				"{sub.You} welcomed {dom.your} embrace, calmly spending this moment with {dom.youHim}.",
			])

		saynn( RNG.pick(possible) )
	else:
		possible.append_array([
			"{dom.You} {dom.youVerb('cuddle')} {sub.you} for a little longer.",
			"{dom.You} {dom.youVerb('decide')} to stay with {sub.you} for a little longer.",
			"{dom.You} {dom.youVerb('keep')} {sub.you} in {dom.yourHis} embrace for a little longer.",
		])

		saynn( RNG.pick(possible) )

		if(domCuddlesLastedTurns == 20):
			saynn("[say=sub]"+ RNG.pick([
				"That bad, huh?..",
			]) +"[/say]")
		elif( (domCuddlesLastedTurns > 5) && RNG.chance(10) ):
			possible = [
				"I guess I can stay a little longer..",
				"You've really caught me, huh..",
			]

			if( sub.isGuard() ):
				possible.append_array([
					"I'm kind of supposed to be on patrol..",
				])
			elif( sub.isStaff() ):
				possible.append_array([
					"You're going to make me run out of believable excuses for skipping work..",
				])

			if(subIsMean):
				possible.append_array([
					"I'm not your plushie, y'know?.. *sigh*",
				])
			else:
				possible.append_array([
					"I'm here for you.",
					"This feels comforting.",
				])

			saynn("[say=sub]"+ RNG.pick(possible) +"[/say]")

	addAction("stay", "Stay a while", "Make it last just a little longer.", "default", 1.0, 60, {})
	var domLeaveProbability:float = -0.3 + 0.2 * domCuddlesLastedTurns
	addAction("leave", "Leave", "Leave them here.", "default", domLeaveProbability, 60, {})

func dom_cuddling_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "stay"):
		domCuddlesLastedTurns += 1
	elif(_id == "leave"):
		var affectionIncrease = min( (0.075 + 0.025 * domCuddlesLastedTurns), 0.15 )
		affectAffection("sub", "dom", affectionIncrease)
		setState("dom_left_sub_alone", "dom")


func dom_messy_kissing_sub_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	var both_youThem = "you" if( isPlayerInvolved() ) else "them"
	var sub_yours = "yours" if sub.isPlayer() else "{sub.nameS}"
	var sub_yoursHis = "yours" if sub.isPlayer() else ( "theirs" if ( sub.heShe() == "they" ) else "{sub.his}" )

	var possible = []

	if(domMessyKissingLastedTurns == 0):
		if(subWasPinnedToTheGround):
			possible.append_array([
				(
						"{dom.You} {dom.youVerb('turn')} {sub.you} on {sub.yourHis} spine, moving closer in to force a lustful, messy kiss onto {sub.yourHis} lips. {dom.YouHe} {dom.youVerb('hold')} back every now and then, "
					+ (
							"to keep {sub.youHim} begging for more, as {dom.youHe} {dom.youVerb('leave')} trails"
						if( dom.isBlindfolded() || sub.isBlindfolded() )
						else "leaving trails"
					)
					+ " of saliva between "+ both_youThem +"."
					+ (
							""
						if( dom.isBlindfolded() || sub.isBlindfolded() )
						else " {dom.YourHis} eyes remain insatiable."
					)
				),
			])
		else:
			possible.append_array([
				"{dom.You} {dom.youVerb('surge')} forward, pinning {sub.you} underneath and pressing {dom.yourHis} lips close to "+ sub_yoursHis +", to deliver a sloppy, passionate kiss. A plentiful of saliva is forced into {sub.yourHis} mouth, as {dom.your} paws roam all over, leaving {sub.youHim} no room to fight back.",
			])

		saynn( RNG.pick(possible) )
	else:
		possible.append_array([
			"{dom.You} {dom.youVerb('make')} out with {sub.you} for a little longer.",
			"{dom.You} {dom.youVerb('roll')} {dom.yourHis} tongue with "+ sub_yours +" for a little longer.",
			"{dom.You} {dom.youAre} unable to stop, continuing kissing {sub.you} for a little longer.",
			"{dom.You} {dom.youVerb('continue')} forcing saliva into {sub.your} mouth for a little longer.",
			"{dom.You} briefly {dom.youVerb('focus', 'focuses')} on {sub.your} "+ RNG.pick(["upper", "lower"]) +" lip, kissing {sub.youHim} for a little longer.",
		])

		saynn( RNG.pick(possible) )

		if( (domMessyKissingLastedTurns > 3) && RNG.chance(20) ):
			var soundsLen = RNG.randi_range(3, 6)
			var sounds = "M"

			for n in soundsLen:
				sounds += RNG.pick(["f", "h", "m"])

			sounds += ".."

			saynn("[say=sub]"+ sounds +"[/say]")

	addAction("keep_kissing", "Keep kissing", "Make it last just a little longer.", "default", 1.0, 60, {})
	var domLeaveProbability:float = -0.3 + 0.2 * domMessyKissingLastedTurns
	addAction("leave", "Leave", "Leave them here.", "default", domLeaveProbability, 60, {})

func dom_messy_kissing_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "keep_kissing"):
		domMessyKissingLastedTurns += 1
	elif(_id == "leave"):
		setState("dom_stopped_messy_kissing_sub", "dom")


func dom_stopped_messy_kissing_sub_text():
	saynn( RNG.pick([
		"{dom.You} {dom.youVerb('break')} the kiss, leaving {sub.you} stunned for a short moment."
	]) )

	addAction("continue", "Continue", "Just continue doing what you're doing.", "default", 1.0, 60, {})

func dom_stopped_messy_kissing_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		var affectionIncrease = min( (0.0500 + 0.0125 * domMessyKissingLastedTurns), 0.10 )
		var lustIncrease = min( (0.1000 + 0.0250 * domMessyKissingLastedTurns), 0.20 )

		affectAffection("sub", "dom", affectionIncrease)
		affectLust("sub", "dom", lustIncrease)

		setState("dom_left_sub_alone", "dom")


func dom_cuffed_guard_sub_text():
	var subPawn = getRolePawn("sub")

	var subIsCoward = subPawn.scorePersonalityMax({ PersonalityStat.Coward: 1.0 }) > 0.4

	saynn( RNG.pick([
		"{dom.You} {dom.youVerb('rummage')} through {sub.your} belongings, hoping to find a particular type of gear, favored by the guards to exercise authority upon others.",
	]) )

	saynn( RNG.pick([
		"The chances are in {dom.yourHis} favor, and {dom.youHe} {dom.youVerb('manage')} to acquire a set of metal cuffs.",
	]) )

	var possible = []

	if(subIsCoward):
		possible.append_array([
			"H- Hey, what are you.. Those are mine!",
			"Y- You put those b- back!! N- Now!!",
		])
	else:
		possible.append_array([
			"They're all accounted for, you better put them back or you're in trouble.",
			"Those are not yours to utilize, put them back. Immediately."
		])

	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	saynn( RNG.pick([
		"{dom.You} promptly {dom.youVerb('make')} use of the cuffs to disempower the pawn upholding an unjust system.",
	]) )
	
	possible = []

	possible.append_array([
		"Should have picked a better line of work~",
		"You've made your choice when you put on that uniform.",
		"Oh, so you don't like it when it's you the rules are applied to?",
	])

	saynn("[say=dom]"+RNG.pick(possible)+"[/say]")

	addAction("leave", "Leave", "Leave them here.", "default", 1.0, 60, {})

func dom_cuffed_guard_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		setState("dom_left_sub_alone", "dom")


func dom_confirming_whether_to_collar_sub_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	saynn( RNG.pick([
		"{sub.You} {sub.youVerb('do', 'does')} not have a collar on {sub.yourHis} neck. If {dom.youHe} {dom.youVerb('have', 'has')} a spare slave collar, would {dom.youHe} like to make {sub.youHim} wear it? It will stay with {sub.youHim} for a long time.",
	]) )

	var domHasSlaveCollar = dom.getInventory().hasItemsWithTag(ItemTag.AllowsEnslaving)
	var subHasNeckSlotEquipped = sub.getInventory().hasSlotEquipped(InventorySlot.Neck)

	if(domHasSlaveCollar && !subHasNeckSlotEquipped):
		addAction("yes", "Yes", "Use a slave collar from your inventory to force it on them.", "default", 1.0, 60, {})
	elif(subHasNeckSlotEquipped):
		addDisabledAction("Yes", "They are already wearing something on their neck.")
	else:
		addDisabledAction("Yes", "You do not have a slave collar.")

	addAction("no", "No", "You don't want to put a slave collar on them.", "default", 1.0, 0, {})

func dom_confirming_whether_to_collar_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	if(_id == "yes"):
		var slaveCollarItems = dom.getInventory().getItemsWithTag(ItemTag.AllowsEnslaving)

		if( slaveCollarItems.size() > 0 ):
			dom.getInventory().removeItem( slaveCollarItems[0] )
			sub.getInventory().forceEquipRemoveOther( slaveCollarItems[0] )
			setState("dom_forced_collar_on_sub", "dom")
	elif(_id == "no"):
		setState("dom_choosing_parting_action", "dom")


func dom_forced_collar_on_sub_text():
	saynn( RNG.pick([
		"{dom.You} {dom.youVerb('force')} a slave collar on {sub.your} neck.",
	]) )

	addAction("continue", "Leashed walk", "You may now walk them on a leash.", "default", 1.0, 60, {})

func dom_forced_collar_on_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("dom_choosing_leash_walking_variant", "dom")


func dom_choosing_leash_walking_variant_text():
	var sub = getRoleChar("sub")

	saynn( RNG.pick([
		"{dom.You} {dom.youVerb('prepare')} the leash, briefly fidgeting its clip around {dom.yourHis} digits while deliberating on the details.",
	]) )

	var subWasUndressedOrIsNaked = ( subWasUndressed || sub.isFullyNaked() )

	var ACTION_NAME_ON_ALL_FOURS = "On all fours"
	if( subWasUndressedOrIsNaked && !sub.hasBoundArms() ):
		addAction("all_fours", ACTION_NAME_ON_ALL_FOURS, "Make them crawl on all fours like a good pet.", "default", 0.6, 60, {})
	elif(!subWasUndressedOrIsNaked):
		addDisabledAction(ACTION_NAME_ON_ALL_FOURS, "They must be naked to make them crawl on all fours.")
	else:
		addDisabledAction(ACTION_NAME_ON_ALL_FOURS, "Restraints on their arms are preventing them from crawling on all fours.")

	addAction("on_two_feet", "On two feet", "Walk them on their two feet.", "default", 0.4, 60, {})

func dom_choosing_leash_walking_variant_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "all_fours"):
		domLeashedWalkOnAllFours = true
		setState("dom_leash_walking_sub", "dom")
	elif(_id == "on_two_feet"):
		domLeashedWalkOnAllFours = false
		setState("dom_leash_walking_sub", "dom")


func dom_leash_walking_sub_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	var subPersonalitySubbyScore = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var subIsSubby = subPersonalitySubbyScore > 0.4
	var subIsDommy = subPersonalitySubbyScore < -0.4

	var subPersonalityImpatientScore = subPawn.scorePersonalityMax({ PersonalityStat.Impatient: 1.0 })
	var subIsImpatient = subPersonalityImpatientScore > 0.4

	var sub_obediently = RNG.pick(["obediently", "willingly"]) if(subIsSubby) else RNG.pick(["readily"]) if(!subIsDommy) else RNG.pick(["reluctantly"])

	var domRoomID:String = domPawn.getLocation()
	# var domRoom = GM.world.getRoomByID(domRoomID)

	var possible = []

	if(domLeashedWalkTraversedCellsCount == 0):
		if(domLeashedWalkHelpedSubStand):
			saynn( RNG.pick([
				"{dom.You} {dom.youVerb('grab')} {sub.you} by the collar and {dom.youVerb('heave')} {sub.youHim} to {sub.yourHis} feet.",
			]) )
		elif(subWasPinnedToTheGround):
			saynn( RNG.pick([
				"As {sub.you} {sub.youVerb('lay')} helplessly, {dom.you} {dom.youVerb('attach', 'attaches')} a leash to your collar.",
			]) )

			possible = getDialogueLines_attachedLeashForWalk(dom)
			saynn("[say=dom]"+ RNG.pick(possible) +"[/say]")
		else:
			saynn( RNG.pick([
				"{dom.You} {dom.youVerb('lean')} forward and {dom.youVerb('attach', 'attaches')} a leash to {sub.your} collar.",
			]) )

			if(domLeashedWalkOnAllFours):
				possible = getDialogueLines_commandOnAllFoursForLeashedWalk(dom)
				saynn("[say=dom]"+ RNG.pick(possible) +"[/say]")

				saynn( RNG.pick([
					"{sub.You} "+ sub_obediently +" {sub.youVerb('get')} on {sub.yourHis} knees, then on {sub.yourHis} four paws, awaiting what comes next.",
					"{sub.You} {sub.youVerb('lower')} {sub.yourself} to {sub.yourHis} knees, "+ sub_obediently +" bending forward and getting on all fours.",
				]) )
			else:
				possible = getDialogueLines_attachedLeashForWalk(dom)
				saynn("[say=dom]"+ RNG.pick(possible) +"[/say]")
	elif(domLeashedWalkReachedTargetLoc):
		saynn( RNG.pick([
			"{dom.You} {dom.youVerb('make')} a brief stop, still holding {sub.you} on a leash.",
		]) )
	elif(domLeashedWalkStoodStill):
		var sub_patiently = "patiently" if(!subIsImpatient) else "impatiently"

		saynn( RNG.pick([
			"{sub.You} "+ ( "{sub.youVerb('remain')} standing on all fours" if(domLeashedWalkOnAllFours) else "{sub.youVerb('stand')} still" ) +" as {dom.you} {dom.youVerb('hold')} {sub.youHim} on a leash.",
			"{sub.You} "+ ( "{sub.youVerb('endure')} standing on all fours" if(domLeashedWalkOnAllFours) else ( "{sub.youVerb('wait')} "+ sub_patiently ) ) +" as {dom.you} {dom.youVerb('keep')} hold of {sub.yourHis} leash.",
		]) )
	elif(domLeashedWalkOnAllFours):
		possible.append_array([
			"{sub.You} {sub.youAre} being pulled around, crawling on all fours as {dom.you} {dom.youVerb('hold')} power over {sub.youHim}.",
			"{sub.You} {sub.youAre} forced to traverse the area, crawling on all fours right next to {dom.your} hind paws.",
			"{sub.You} {sub.youVerb('have', 'has')} no choice but to crawl behind {dom.you} on all fours, as {dom.youHe} {dom.youVerb('pull')} {sub.yourHis} leash forward.",
		])

		if( RNG.chance(5) ):
			possible.append_array([
				"{sub.Your} "+ RNG.pick(["arms", "knees"]) +" feel a little exhausted, and {sub.youHe} {sub.youVerb('struggle')} to keep up with the pace. A pull of {sub.yourHis} leash urges {sub.youHim} to catch up.",
			])

		saynn( RNG.pick(possible) )

		if( RNG.chance(10) ):
			possible = getDialogueLines_walkingLeashedOnAllFours(sub)
			saynn("[say=sub]"+ RNG.pick(possible) +"[/say]")
	elif(!domLeashedWalkOnAllFours):
		possible.append_array([
			"{sub.You} {sub.youAre} being pulled around by {dom.you} as {dom.youHe} {dom.youVerb('hold')} {sub.youHim} on a leash.",
			"{sub.You} {sub.youAre} forced to traverse the area while {dom.you} {dom.youVerb('have', 'has')} {sub.youHim} on the leash.",
			"{sub.You} {sub.youVerb('have', 'has')} no choice but to follow, as {dom.you} {dom.youVerb('pull')} {sub.yourHis} leash forward.",
		])

		if( RNG.chance(5) ):
			possible.append_array([
				"{sub.You} {sub.youVerb('stumble')} lightly. {dom.You} {dom.youVerb('pull')} on {sub.yourHis} leash, urging {sub.youHim} to catch up.",
			])

		saynn( RNG.pick(possible) )

	# Proved to be a little distracting

	# var shouldDescribeCurrentRoomAsPlayerCharacterPerceivesIt = (
	# 		(domLeashedWalkReachedTargetLoc || domLeashedWalkStoodStill)
	# 	&& (domLeashedWalkTargetLoc == "")
	# 	&& (domRoom != null)
	# 	&& isPlayerInvolved()
	# )

	# if(shouldDescribeCurrentRoomAsPlayerCharacterPerceivesIt):
	# 	if( GM.pc.isBlindfolded() && !GM.pc.canHandleBlindness() ):
	# 		saynn( domRoom.getBlindDescription() )
	# 	else:
	# 		saynn( domRoom.getDescription() )

	if(!domLeashedWalkStoodStill):
		if(domRoomID == "hall_checkpoint"):
			saynn("[say=cp_guard]"+ RNG.pick([
				"Mm, that's bold.",
			]) +"[/say]")
		elif( (domRoomID == "yard_novaspot") && (GM.ES != null) && !GM.ES.eventCheck("NovaBusy") ):
			saynn("[say=nova]"+ RNG.pick([
				"I see you've got a pet of your own, you little rascal~.",
			]) +"[/say]")

			if( !subIsMean && RNG.chance(50) ):
				saynn("[say=sub]I- I'm not-..[/say]")
		elif( domRoomID in ["main_dressing1", "main_dressing2"] ):
			if( subIsSubby && RNG.chance(20) ):
				saynn("[say=sub]O- Oh, lockers..[/say]")
			else:
				saynn("[say=dom]"+ RNG.pick([
					"What, thought I'm getting you to shower? You're better off as a total mess.",
					"Oh, don't misunderstand, you don't get to take a shower today.",
				]) +"[/say]")

			if( !subIsMean && RNG.chance(20) ):
				saynn("{sub.You} {sub.youVerb('whine')}.")

	if(subWasPinnedToTheGround && !domLeashedWalkOnAllFours):
		addAction("help_stand", "Help them up", "Get them to stand.", "default", 1.0, 60, {})
	else:
		if(domLeashedWalkTraversedCellsCount == 0):
			addAction("walk", "Walk them", "Pull them around the place.", "default", 1.0, 60, {})
		else:
			if(!domLeashedWalkReachedTargetLoc):
				addAction("walk", "Keep walking", "Keep pulling them around.", "default", 1.0, 60, {})

			for n in ( 2 if(domLeashedWalkReachedTargetLoc) else 1 ):
				addAction("stay", "Stay a while", "Stand here for a little bit.", "default", ( 1.0 if(n == 2) else -0.01 ), 60, {})

		if(domLeashedWalkTraversedCellsCount > 10):
			var domProbabilityToStop = ( 0.02 * (domLeashedWalkTraversedCellsCount - 30) ) if(domLeashedWalkTargetLoc == "") else -0.01
			addAction("stop", "That's enough", "You've had enough walking them around.", "default", domProbabilityToStop, 60, {})

func dom_leash_walking_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	var domPawn = getRolePawn("dom")

	if(_id == "help_stand"):
		subWasPinnedToTheGround = false
		domLeashedWalkHelpedSubStand = true
	elif(_id == "stay"):
		domLeashedWalkStoodStill = true
		domLeashedWalkReachedTargetLoc = false
	elif(_id == "walk"):
		if(domLeashedWalkTargetLoc == ""):
			var domFloorID:String = "none"
			var domRoomID:String = domPawn.getLocation()
			var domRoom = GM.world.getRoomByID(domRoomID)
			if(domRoom != null):
				domFloorID = domRoom.getFloorID()

			var possibleSafeLocs = []
			var possibleUnsafeLocs = []

			var connectedLocs:Array = GM.world.getConnectedRoomsNear(domRoomID, 8)
			var PROHIBITED_LOCS = ["hall_elevator", "main_shower1", "main_shower2"]

			for connectedRoomID in connectedLocs:
				var connectedRoom = GM.world.getRoomByID(connectedRoomID)

				var isLocEligible = (
						(connectedRoom != null)
					&& ( connectedRoom.getFloorID() == domFloorID )
					&& ( GM.world.simpleDistance(connectedRoomID, domRoomID) > 2.0 )
					&& !(connectedRoomID in PROHIBITED_LOCS)
				)

				if(isLocEligible):
					if( GM.world.isLocSafe(connectedRoomID) ):
						possibleSafeLocs.append(connectedRoomID)
					else:
						possibleUnsafeLocs.append(connectedRoomID)

			if( possibleSafeLocs.size() > 0 ):
				domLeashedWalkTargetLoc = RNG.pick(possibleSafeLocs)
			elif( possibleUnsafeLocs.size() > 0 ):
				domLeashedWalkTargetLoc = RNG.pick(possibleUnsafeLocs)

		if(domLeashedWalkTargetLoc == ""):
			domLeashedWalkStoodStill = true
			domLeashedWalkTraversedCellsCount += 100
		else:
			goTowards(domLeashedWalkTargetLoc)

			domLeashedWalkStoodStill = false
			domLeashedWalkTraversedCellsCount += 1

			if( domPawn.getLocation() == domLeashedWalkTargetLoc ):
				domLeashedWalkReachedTargetLoc = true
				domLeashedWalkTargetLoc = ""
	elif(_id == "stop"):
		domLeashedWalkStoodStill = true
		setState("dom_stopped_leash_walking_sub", "dom")


func dom_stopped_leash_walking_sub_text():
	var dom = getRoleChar("dom")

	var dom_you_veHe_s = "you've" if dom.isPlayer() else ( "they've" if ( dom.heShe() == "they" ) else "{dom.he}'s" )

	saynn("{dom.You} {dom.youVerb('feel')} like "+ dom_you_veHe_s +" had enough fun walking {sub.you} around. {dom.YouHe} {dom.youVerb('approach', 'approaches')} {sub.youHim}, detaching the leash from {sub.yourHis} collar.")

	addAction("continue", "Continue", "Just continue doing what you're doing.", "default", 1.0, 60, {})

func dom_stopped_leash_walking_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	var subPawn = getRolePawn("sub")

	if(_id == "continue"):
		var subInterestInBondage = subPawn.scoreFetishMax({ Fetish.Bondage: 1.0 })

		var affectionIncrease:float = clamp(0.0025 * domLeashedWalkTraversedCellsCount * subInterestInBondage, -0.05, 0.10)
		var lustIncrease:float = clamp(0.0025 * domLeashedWalkTraversedCellsCount * subInterestInBondage, 0.00, 0.10)

		affectAffection("sub", "dom", affectionIncrease)
		affectLust("sub", "dom", lustIncrease)

		setState("dom_left_sub_alone", "dom")


func dom_left_sub_alone_text():
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	saynn("{dom.You} {dom.youVerb('leave')} {sub.you} alone..")

	if(domHasImmediatelyLeftConsentingSub):
		var possible = []
		
		if(subIsMean):
			possible.append_array([
				"Bitch, of all the times you could leave me alone, you pick now? Fuck you..",
			])
		else:
			possible.append_array([
				"I thought we were about to do something..",
			])

		saynn("[say=sub]"+ RNG.pick(possible) +"[/say]")

	addAction("leave", "Leave", "Time to go.", "default", 1.0, 30, {})

func dom_left_sub_alone_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		resetLustState()
		stopMe()


func incl_sex_turn_text():
	var domTopOrBottomString = "bottom" if(domIsBottoming) else "top"
	var isDomTurn = (currentTurnTopOrBottom == domTopOrBottomString)
	var topCameThisTurn = topCameInsideThisTurn || topCameOutsideThisTurn

	incl_toggleable_mouth_play_text()

	if(tfResultText != ""):
		saynn(tfResultText)
	else:
		incl_sex_turn_dialogue_text()

	if(isDomTurn && topCameThisTurn):
		addAction("continue", "Keep going", "Just continue doing what you're doing.", "default", 1.0, 60, {})

		var endSexProbability = max( ( -0.75 + ( 0.35 * topCameTimes ) ), 0.0 )
		addAction("had_enough_sex", "End sex", "Enough fun for now.", "default", endSexProbability, 0, {})
	else:
		addAction("continue", "Continue", "Just continue doing what you're doing.", "default", 1.0, 60, {})

		incl_toggleable_mouth_play_actions()

		var endSexEarlyProbability = 1.0 if( !isDomTurn && subMightEndSexEarly && RNG.chance(1) ) else -0.01
		addAction("end_sex_early", "End sex", "You no longer want this to continue.", "default", endSexEarlyProbability, 0, {})

func incl_sex_turn_dialogue_text():
	var top = getTopChar()

	var topDialogueLines = []

	if( !domIsBottoming && topPenisWasOutsidePreviousTurn && RNG.chance(20) ):
		topDialogueLines = getDialogueLines_emphasizeTightness(top)

	if( topDialogueLines.size() > 0 ):
		saynn("[say=dom]"+ RNG.pick(topDialogueLines) +"[/say]")

func incl_sex_turn_do_preTick(_id:String):
	var dom = getRoleChar("dom")

	if( ( _id in ["had_enough_sex", "end_sex_early"] ) && dom.isPlayer() ):
		return

	topCameInsidePreviousTurn = topCameInsideThisTurn
	topPenisWasOutsidePreviousTurn = topCameOutsideThisTurn

	bottomCameThisTurn = false
	topCameInsideThisTurn = false
	topCameOutsideThisTurn = false

func incl_sex_turn_do(_id:String, _args:Dictionary, _context:Dictionary):
	var top = getTopChar()
	var bottom = getBottomChar()

	var nextTurnTopOrBottom = ( "top" if(currentTurnTopOrBottom == "bottom") else "bottom" )
	
	var tfRequiresEndingInteraction:bool = handleTransformation({ nextTurnTopOrBottom = nextTurnTopOrBottom, })

	if(tfRequiresEndingInteraction == true):
		hasSexEndedEarly = true

		var partnerDomOrSubString = getBottomRole() if(currentTurnTopOrBottom == "bottom") else getTopRole()
		setState("ended_sex_early", partnerDomOrSubString)
		return

	incl_toggleable_mouth_play_do(_id, _args, _context)

	if(_id == "had_enough_sex"):
		var dom = getRoleChar("dom")

		if( dom.isPlayer() ):
			hasSexEndedEarly = false
			setState("confirming_whether_to_end_sex", "dom")
		else:
			setState("dom_after_sex", "dom")
	elif(_id == "end_sex_early"):
		var character = getCurrentPawn().getCharacter()
		var characterRole = "dom" if( getRoleChar("dom") == character ) else "sub"

		hasSexEndedEarly = true

		if( character.isPlayer() ):
			setState("confirming_whether_to_end_sex", characterRole)
		else:
			var partnerDomOrSubString = "dom" if(characterRole == "sub") else "sub"
			setState("ended_sex_early", partnerDomOrSubString)
	else:
		increaseArousal({ nextTurnTopOrBottom = nextTurnTopOrBottom, })

		if(topPenisWasOutsidePreviousTurn):
			bottom.gotOrificeStretchedBy( BodypartSlot.Anus, top.getID(), true, 0.2 )
		elif( RNG.chance(20) ):
			bottom.gotOrificeStretchedBy( BodypartSlot.Anus, top.getID(), true, 0.1 )

		currentTurnTopOrBottom = nextTurnTopOrBottom

		if(nextTurnTopOrBottom == "top"):
			var topIsAboutToCum = top.getArousal() >= 1.0

			if(domIsBottoming && topIsAboutToCum):
				# Bottom dom takes over the top sub's turn
				setState( "sex_top_turn", getBottomRole() )
			else:
				setState( "sex_top_turn", getTopRole() )
		else:
			setState( "sex_bottom_turn", getBottomRole() )


func incl_toggleable_mouth_play_text():
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domTopOrBottomString = "bottom" if(domIsBottoming) else "top"
	var isDomTurn = (currentTurnTopOrBottom == domTopOrBottomString)

	var affectionValue:float = domPawn.getAffection(subPawn)

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	var baseLines = []

	if(domToggleableMouthPlayState == "started"):
		baseLines = [
			"{dom.You} {dom.youVerb('reach', 'reaches')} over, opening {dom.yourHis} paw and shoving "+ RNG.pick(["two", "three"]) +" digits into {sub.your} maw.",
			"{dom.You} {dom.youVerb('lean')} forward, pressing {dom.yourHis} paw on {sub.your} lips before cravingly sliding "+ RNG.pick(["two", "three"]) +" digits past them.",
		]

		saynn( RNG.pick(baseLines) )
		return

	if(domToggleableMouthPlayState == "active"):
		var topCameThisTurn = topCameInsideThisTurn || topCameOutsideThisTurn

		if(topCameThisTurn):
			return

		if(isDomTurn):
			baseLines = [
				"{sub.You} {sub.youVerb('feel')} {dom.your} digits persistently slide past {sub.yourHis} lips, in and out.",
				"{sub.You} {sub.youAre} further aroused by {dom.your} paw fish hooking {sub.yourHis} cheek.",
				"{sub.Your} lips are forced to suck on {dom.your} digits as they slip back and forth.",
			]
		else:
			baseLines = [
				"{dom.Your} "+ RNG.pick(["two", "three"]) +" digits are shoved into {sub.your} maw, noticeably contributing to {sub.yourHis} arousal.",
				"{dom.Your} paw is reaching into {sub.your} mouth, further corrupting {sub.yourHis} thoughts.",
				"{dom.You} {dom.youAre} forcing {sub.you} to suck on {dom.yourHis} digits, squeezing them across the surface of {sub.yourHis} tongue.",
			]

		saynn( RNG.pick(baseLines) )
		return

	if(domToggleableMouthPlayState == "stopped"):
		baseLines = [
			"Having played enough with {sub.your} mouth, {dom.you} {dom.youVerb('pull')} the paw away from it.",
		]

		saynn( RNG.pick(baseLines) )
		return

	if(domToggleableMouthPlayState == "interrupted"):
		baseLines = []

		var isBitePainful = subIsMean

		if(isBitePainful):
			baseLines.append_array([
				"{sub.You} [color="+ getSensationColor("pain_severe") +"]{sub.youVerb('bite')} the digits[/color] in {sub.yourHis} mouth, causing {dom.you} to recoil from pain.",
			])
		else:
			baseLines.append_array([
				"{sub.You} [color="+ getSensationColor("pain_moderate") +"]lightly {sub.youVerb('chomp')}[/color] on {dom.your} paw. It doesn't hurt much, but it was a little unexpected.",
			])

		saynn( RNG.pick(baseLines) )

		baseLines = []

		if(isBitePainful):
			baseLines = [
				"Ow, fuck! I cannot tell if you're simply being a brat.. But I'll take a clue and not do that again. Either way, you're really missing out.",
			]

			if(domIsMean):
				baseLines.append_array([
					"Oww, now why the flying fuck would you do that!..",
				])
			else:
				baseLines.append_array([
					"Oww.. Fair fair, I should have asked if you're into that..",
					"Ow! I was sure you'd be into that.. Oh well.",
				])
		else:
			baseLines = []

			if(domIsMean):
				baseLines.append_array([
					"You could just tell me you don't like it, you know?",
					"What an untrained bitch. Fine, it's only you who's missing out.",
				])
			else:
				if(affectionValue > 0.40):
					baseLines.append_array([
						"I swear I remember you being into that.. Hmh..",
					])

				baseLines.append_array([
					"Ah! I think I get what you're biting..",
					"Aw, no more paws for you.",
				])

		saynn( "[say=dom]"+ RNG.pick(baseLines) +"[/say]" )

		baseLines = [
			"{dom.You} reluctantly {dom.youVerb('pull')} {dom.yourHis} paw out of {sub.your} mouth.",
		]

		saynn( RNG.pick(baseLines) )
		return

func incl_toggleable_mouth_play_actions():
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var domTopOrBottomString = "bottom" if(domIsBottoming) else "top"
	var isDomTurn = (currentTurnTopOrBottom == domTopOrBottomString)

	var currentSexPose = getCurrentSexPose()

	if(currentSexPose == null):
		return

	if( !("toggleableMouthPlay" in currentSexPose.tags) ):
		return

	var domIsPerformingMouthPlay = domToggleableMouthPlayActiveTurns > 0

	if(domToggleableMouthPlayActiveTurns != 0):
		domToggleableMouthPlayActiveTurns += 1

	if(isDomTurn):
		var ACTION_NAME_MOUTH_PLAY = "Mouth play"

		if(!domIsPerformingMouthPlay):
			var startMouthPlayProbability:float = 0.2 if( domToggleableMouthPlayMightPerform && (domToggleableMouthPlayActiveTurns == 0) ) else -0.01

			if( (domToggleableMouthPlayState != "unavailable") && !sub.isOralBlocked() ):
				addAction("toggleable_mouth_play_start", "+ "+ ACTION_NAME_MOUTH_PLAY, "Use your paw to play with their mouth.", "default", startMouthPlayProbability, 60, {})
			elif(domToggleableMouthPlayState == "unavailable"):
				addDisabledAction("+ "+ ACTION_NAME_MOUTH_PLAY, "They don't seem to be into that.")
			else:
				addDisabledAction("+ "+ ACTION_NAME_MOUTH_PLAY, "Unable to reach into their mouth due to their restraints.")
		else:
			var endMouthPlayProbability:float = -0.6 + 0.1 * domToggleableMouthPlayActiveTurns
			addAction("toggleable_mouth_play_stop", "- "+ ACTION_NAME_MOUTH_PLAY, "Stop playing with their mouth.", "default", endMouthPlayProbability, 60, {})
	else:
		if(domIsPerformingMouthPlay):
			var subInterestInMouthPlay:float = subPawn.scoreFetishMax({ Fetish.Masochism: 1.0 })
			var interruptMouthPlayProbability:float = -subInterestInMouthPlay
			addAction("toggleable_mouth_play_interrupt", "Bite paw", "You don't want them sticking digits in your mouth.", "default", interruptMouthPlayProbability, 60, {})

func incl_toggleable_mouth_play_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	if(domToggleableMouthPlayState == "started"):
		domToggleableMouthPlayState = "active"
	elif(domToggleableMouthPlayState == "stopped"):
		domToggleableMouthPlayState = "none"
	elif(domToggleableMouthPlayState == "interrupted"):
		domToggleableMouthPlayState = "unavailable"

	if(_id == "toggleable_mouth_play_start"):
		domToggleableMouthPlayState = "started"
		domToggleableMouthPlayActiveTurns = 1
	elif(_id == "toggleable_mouth_play_stop"):
		domToggleableMouthPlayState = "stopped"
		domToggleableMouthPlayActiveTurns = RNG.randi_range(-24, -16)
	elif(_id == "toggleable_mouth_play_interrupt"):
		domToggleableMouthPlayState = "interrupted"
		domToggleableMouthPlayActiveTurns = -10000

		var painInflictedFromBite = 6 if(subIsMean) else 2
		dom.addPain(painInflictedFromBite)


func getAnimData() -> Array:
	if( getState() == "dom_left_sub_alone" ):
		if(subWasCuffed):
			if(subWasPinnedToTheGround):
				return [StageScene.GivingBirth, "idle", { pc="sub" }]
			else:
				return [StageScene.Solo, "kneel", { pc="sub" }]

		return [StageScene.Duo, "stand", { pc="dom", npc="sub" }]

	if( getState() == "dom_cuddling_sub" ):
		return [StageScene.Cuddling, "idle", { pc="dom", npc="sub" }]

	if( getState() == "dom_messy_kissing_sub" ):
		return [StageScene.SexMatingPress, "tease", { pc="dom", npc="sub" }]

	if(subWasCuffed):
		if(subWasPinnedToTheGround):
			return [StageScene.SexBehind, "tease", { pc="dom", npc="sub" }]
		else:
			return [StageScene.Duo, "stand", { pc="dom", npc="sub", npcAction="kneel", flipNPC=true }]

	if( getState() == "dom_stopped_messy_kissing_sub" ):
		return [StageScene.GivingBirth, "idle", { pc="sub" }]

	if( getState() == "dom_stopped_leash_walking_sub" ):
		return [StageScene.Duo, "stand", { pc="dom", npc="sub" }]

	if( getState() == "dom_choosing_leash_walking_variant" ):
		if(subWasPinnedToTheGround):
			return [StageScene.SexBehind, "tease", { pc="dom", npc="sub" }]
		else:
			return [StageScene.Duo, "stand", { pc="sub", npc="dom" }]

	if( getState() == "dom_leash_walking_sub" ):
		if(domLeashedWalkTraversedCellsCount == 0):
			if(subWasPinnedToTheGround):
				return [StageScene.SexBehind, "tease", { pc="dom", npc="sub", npcBodyState={ leashedBy="dom" } }]
			else:
				return [StageScene.Duo, ( "allfours" if(domLeashedWalkOnAllFours) else "stand" ), { pc="sub", npc="dom", bodyState={ leashedBy="dom" } }]
		elif(domLeashedWalkStoodStill):
			return [StageScene.Duo, ( "allfours" if(domLeashedWalkOnAllFours) else "stand" ), { pc="sub", npc="dom", flipNPC=true, bodyState={ leashedBy="dom" } }]
		else:
			return [StageScene.Duo, ( "crawl" if(domLeashedWalkOnAllFours) else "walk" ), { pc="sub", npc="dom", npcAction="walk", flipNPC=true, bodyState={ leashedBy="dom" } }]

	var currentSexPose = getCurrentSexPose()

	if(currentSexPose != null):
		var pc:String
		var npc:String
		var pcCum:bool
		var npcCum:bool
		var pcBodyState:Dictionary
		var npcBodyState:Dictionary

		var topCameLastTurn = topCameInsideThisTurn || topCameOutsideThisTurn

		if( currentSexPose.has("stageSceneSwapCharacters") && currentSexPose.stageSceneSwapCharacters ):
			pc = getBottomRole()
			npc = getTopRole()
			pcCum = bottomCameThisTurn
			npcCum = topCameLastTurn
			pcBodyState = { hard=true, }
			npcBodyState = { hard=true, }
		else:
			pc = getTopRole()
			npc = getBottomRole()
			pcCum = topCameLastTurn
			npcCum = bottomCameThisTurn
			pcBodyState = { hard=true, }
			npcBodyState = { hard=true, }

		var TEASE_STATES = [
			"dom_choosing_sex_pose_done",
			"dom_choosing_sex_pose_preview",
			"ended_sex_early",
			"offered_cuddles",
			"agreed_to_cuddles",
			"refused_cuddles",
			"dom_after_sex"
		]

		if( getState() in TEASE_STATES ):
			return [currentSexPose.stageScene, "tease", { pc=pc, npc=npc, bodyState=pcBodyState, npcBodyState=npcBodyState }]

		if( getState() in ["sex_bottom_turn", "sex_top_turn", "confirming_whether_to_end_sex"] ):
			var top = getTopChar()

			var fastAnimationMinArousal = currentSexPose.fastAnimationMinArousal if( currentSexPose.has("fastAnimationMinArousal") ) else 0.70
			var animationName = "fast" if( top.getArousal() >= fastAnimationMinArousal ) else "sex"

			if(topCameInsideThisTurn):
				animationName = "inside"
			elif(topCameOutsideThisTurn):
				animationName = "tease"

			return [currentSexPose.stageScene, animationName, { pc=pc, npc=npc, pcCum=pcCum, npcCum=npcCum, bodyState=pcBodyState, npcBodyState=npcBodyState }]

	if(subWasPinnedToTheGround):
		return [StageScene.SexBehind, "tease", { pc="dom", npc="sub" }]

	return [StageScene.SexFreeStanding, "tease", { pc="dom", npc="sub" }]

func getActivityIconForRole(_role:String):
	if( ( getState() in ["dom_stopped_messy_kissing_sub"] ) && (_role == "sub") ):
		return RoomStuff.PawnActivity.Down

	if( ( getState() in ["dom_leash_walking_sub"] ) && (_role == "sub") ):
		return RoomStuff.PawnActivity.Struggle

	if( subWasCuffed && (_role == "sub") ):
		return RoomStuff.PawnActivity.Struggle

	if( getState() in ["dom_left_sub_alone", "dom_stopped_messy_kissing_sub", "dom_cuffed_guard_sub", "dom_leash_walking_sub", "dom_stopped_leash_walking_sub"] ):
		return RoomStuff.PawnActivity.None

	return RoomStuff.PawnActivity.Sex

func getPreviewLineForRole(_role:String) -> String:
	var isAssumingSexImminent = (
			(subConsentedToAnalSexReceiving || subConsentedToAnalSexGiving)
		&& ( getState() == "" )
	)

	if( isAssumingSexImminent || ( getState() in ["dom_choosing_sex_pose_done", "dom_choosing_sex_pose_preview", "dom_after_sex"] ) ):
		if(_role == "dom"):
			return "{dom.name} {dom.is} about to fuck {sub.name}."
		elif(_role == "sub"):
			return "{sub.name} {sub.is} is about to be fucked by {dom.name}."

	if( getState() in ["sex_bottom_turn", "sex_top_turn", "confirming_whether_to_end_sex"] ):
		if(_role == "dom"):
			return "{dom.name} {dom.is} fucking {sub.name}."
		elif(_role == "sub"):
			return "{sub.name} {sub.is} being fucked by {dom.name}."

	if( getState() == "dom_cuddling_sub" ):
		if(_role == "dom"):
			return "{dom.name} {dom.is} cuddling with {sub.name}."
		elif(_role == "sub"):
			return "{sub.name} {sub.is} being cuddled by {dom.name}."

	if( getState() == "dom_messy_kissing_sub" ):
		if(_role == "dom"):
			return "{dom.name} {dom.is} messily kissing {sub.name}."
		elif(_role == "sub"):
			return "{sub.name} {sub.is} being messily kissed by {dom.name}."

	if( getState() == "dom_leash_walking_sub" ):
		if(_role == "dom"):
			return "{dom.name} {dom.is} walking {sub.name} on a leash."
		elif(_role == "sub"):
			return "{sub.name} {sub.is} held on a leash by {dom.name}."

	if(_role == "dom"):
		return "{dom.name} {dom.is} having some fun with {sub.name}."
	elif(_role == "sub"):
		return "{sub.name} {sub.is} at the whim of {dom.name}."

	return .getPreviewLineForRole(_role)

func isPawnBeingFucked(pawn) -> bool:
	return (
			( getRoleForPawn(pawn) == "sub" )
		&& ( getState() in ["sex_bottom_turn", "sex_top_turn"] )
	)

func isPawnFuckingSomeone(pawn) -> bool:
	return (
			( getRoleForPawn(pawn) == "dom" )
		&& ( getState() in ["sex_bottom_turn", "sex_top_turn"] )
	)

func isRoleOnALeash(_role:String) -> bool:
	return ( (_role == "sub") && getState() in ["dom_leash_walking_sub"] )
	
func isRoleLeashing(_role:String) -> bool:
	return ( (_role == "dom") && getState() in ["dom_leash_walking_sub"] )

func saveData():
	var data = .saveData()

	data["subConsentedToAnalSexReceiving"] = subConsentedToAnalSexReceiving
	data["subConsentedToAnalSexGiving"] = subConsentedToAnalSexGiving
	data["subWasPinnedToTheGround"] = subWasPinnedToTheGround
	data["subWasUndressed"] = subWasUndressed
	data["subWasCuffed"] = subWasCuffed
	data["subMightEndSexEarly"] = subMightEndSexEarly
	data["subPetNames"] = subPetNames

	data["domIsBottoming"] = domIsBottoming
	data["domHasImmediatelyLeftConsentingSub"] = domHasImmediatelyLeftConsentingSub
	data["domToggleableMouthPlayMightPerform"] = domToggleableMouthPlayMightPerform
	data["domToggleableMouthPlayState"] = domToggleableMouthPlayState
	data["domToggleableMouthPlayActiveTurns"] = domToggleableMouthPlayActiveTurns
	data["domCuddlesLastedTurns"] = domCuddlesLastedTurns
	data["domMessyKissingLastedTurns"] = domMessyKissingLastedTurns
	data["domLeashedWalkOnAllFours"] = domLeashedWalkOnAllFours
	data["domLeashedWalkHelpedSubStand"] = domLeashedWalkHelpedSubStand
	data["domLeashedWalkStoodStill"] = domLeashedWalkStoodStill
	data["domLeashedWalkReachedTargetLoc"] = domLeashedWalkReachedTargetLoc
	data["domLeashedWalkTraversedCellsCount"] = domLeashedWalkTraversedCellsCount
	data["domLeashedWalkTargetLoc"] = domLeashedWalkTargetLoc

	data["currentSexPoseId"] = currentSexPoseId
	data["currentTurnTopOrBottom"] = currentTurnTopOrBottom
	data["hasSexEndedEarly"] = hasSexEndedEarly
	data["tfResultText"] = tfResultText

	data["topCameInsideThisTurn"] = topCameInsideThisTurn
	data["topCameInsidePreviousTurn"] = topCameInsidePreviousTurn
	data["topCameOutsideThisTurn"] = topCameOutsideThisTurn
	data["topPenisWasOutsidePreviousTurn"] = topPenisWasOutsidePreviousTurn
	data["topCameTimes"] = topCameTimes

	data["bottomCameTimes"] = bottomCameTimes

	return data

func loadData(_data):
	.loadData(_data)

	subConsentedToAnalSexReceiving = SAVE.loadVar(_data, "subConsentedToAnalSexReceiving", false)
	subConsentedToAnalSexGiving = SAVE.loadVar(_data, "subConsentedToAnalSexGiving", false)
	subWasPinnedToTheGround = SAVE.loadVar(_data, "subWasPinnedToTheGround", false)
	subWasUndressed = SAVE.loadVar(_data, "subWasUndressed", false)
	subMightEndSexEarly = SAVE.loadVar(_data, "subMightEndSexEarly", false)
	subPetNames = SAVE.loadVar(_data, "subPetNames", ["creature"])

	domIsBottoming = SAVE.loadVar(_data, "domIsBottoming", false)
	domHasImmediatelyLeftConsentingSub = SAVE.loadVar(_data, "domHasImmediatelyLeftConsentingSub", false)
	domToggleableMouthPlayMightPerform = SAVE.loadVar(_data, "domToggleableMouthPlayMightPerform", false)
	domToggleableMouthPlayState = SAVE.loadVar(_data, "domToggleableMouthPlayState", "none")
	domToggleableMouthPlayActiveTurns = SAVE.loadVar(_data, "domToggleableMouthPlayActiveTurns", 0)
	domCuddlesLastedTurns = SAVE.loadVar(_data, "domCuddlesLastedTurns", 0)
	domMessyKissingLastedTurns = SAVE.loadVar(_data, "domMessyKissingLastedTurns", 0)
	domLeashedWalkOnAllFours = SAVE.loadVar(_data, "domLeashedWalkOnAllFours", false)
	domLeashedWalkHelpedSubStand = SAVE.loadVar(_data, "domLeashedWalkHelpedSubStand", false)
	domLeashedWalkStoodStill = SAVE.loadVar(_data, "domLeashedWalkStoodStill", false)
	domLeashedWalkReachedTargetLoc = SAVE.loadVar(_data, "domLeashedWalkReachedTargetLoc", false)
	domLeashedWalkTraversedCellsCount = SAVE.loadVar(_data, "domLeashedWalkTraversedCellsCount", 0)
	domLeashedWalkTargetLoc = SAVE.loadVar(_data, "domLeashedWalkTargetLoc", "")

	currentSexPoseId = SAVE.loadVar(_data, "currentSexPoseId", "none")
	currentTurnTopOrBottom = SAVE.loadVar(_data, "currentTurnTopOrBottom", "nobody")
	hasSexEndedEarly = SAVE.loadVar(_data, "hasSexEndedEarly", false)
	tfResultText = SAVE.loadVar(_data, "tfResultText", "")

	topCameInsideThisTurn = SAVE.loadVar(_data, "topCameInsideThisTurn", false)
	topCameInsidePreviousTurn = SAVE.loadVar(_data, "topCameInsidePreviousTurn", false)
	topCameOutsideThisTurn = SAVE.loadVar(_data, "topCameOutsideThisTurn", false)
	topPenisWasOutsidePreviousTurn = SAVE.loadVar(_data, "topPenisWasOutsidePreviousTurn", true)
	topCameTimes = SAVE.loadVar(_data, "topCameTimes", 0)

	bottomCameThisTurn = SAVE.loadVar(_data, "bottomCameThisTurn", false)
	bottomCameTimes = SAVE.loadVar(_data, "bottomCameTimes", 0)

func getTopRole():
	return ( "sub" if(domIsBottoming) else "dom" )
func getBottomRole():
	return ( "dom" if(domIsBottoming) else "sub" )
func getTopChar():
	return getRoleChar( getTopRole() )
func getBottomChar():
	return getRoleChar( getBottomRole() )
func getTopPawn():
	return getRolePawn( getTopRole() )
func getBottomPawn():
	return getRolePawn( getBottomRole() )

func getSensationColor(_type:String) -> String:
	if(_type == "pain_severe"):
		return "#FFBBBB"

	if(_type == "pain_moderate"):
		return "#FFDDBB"

	if(_type == "comfort"):
		return "#DDFFCC"

	if(_type == "attention"):
		return "#EFBBEF"

	return "#666"

func applyOrgasmSensationToLines(lines:Array) -> Array:
	for idx in lines.size():
		lines[idx] = (
				"[rainbow freq=0.05 sat=0.25 val=1.0]"
			+ lines[idx]
			+ "[/rainbow]"
		)

	return lines

func increaseArousal(_info:Dictionary):
	var nextTurnTopOrBottom = _info.nextTurnTopOrBottom

	var top = getTopChar()
	var bottom = getBottomChar()
	var topPawn = getTopPawn()
	var bottomPawn = getBottomPawn()

	var topInterestInAnalSexGiving = topPawn.scoreFetishMax({ Fetish.AnalSexGiving: 1.0 })
	var bottomInterestInAnalSexReceiving = bottomPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })

	var topArousalIncrease = RNG.randf_range(0.03, 0.07) + 0.08 * max(topInterestInAnalSexGiving, 0)
	var bottomArousalIncrease = RNG.randf_range(0.01, 0.03) + 0.07 * max(bottomInterestInAnalSexReceiving, 0)

	top.addLust( ceil( topArousalIncrease * top.lustThreshold() ) )
	bottom.addLust( ceil( bottomArousalIncrease * bottom.lustThreshold() ) )

	var topArousalBeforeIncrease = top.getArousal()
	var bottomArousalBeforeIncrease = bottom.getArousal()

	top.addArousal(topArousalIncrease)
	bottom.addArousal(bottomArousalIncrease)

	# Arousal of both characters can only max out during the top's turn
	if(nextTurnTopOrBottom == "bottom"):
		if( top.getArousal() >= 1.0 ):
			top.setArousal( min( lerp(topArousalBeforeIncrease, 1.0, 0.5), 0.994 ) )
	elif(nextTurnTopOrBottom == "top"):
		if( bottom.getArousal() >= 1.0 ):
			bottom.setArousal( min( lerp(bottomArousalBeforeIncrease, 1.0, 0.5), 0.994 ) )

func handleTransformation(_info:Dictionary):
	var tfRequiresEndingInteraction:bool = false

	var nextTurnTopOrBottom = _info.nextTurnTopOrBottom
	var character = getBottomChar() if(nextTurnTopOrBottom == "bottom") else getTopChar()
	var characterRole = "dom" if( getRoleChar("dom") == character ) else "sub"

	tfResultText = ""

	var dialogueLines = []

	var tfHolder:TFHolder = character.getTFHolder()

	if( (tfHolder != null) && tfHolder.hasPendingTransformations() ):
		var tfResult:Dictionary = tfHolder.doFirstPendingTransformation({}, true)

		if( tfResult.has("text") && ( tfResult["text"] != "" ) ):
			if(tfResultText != ""):
				tfResultText += "\n\n"

			tfResultText += (
					"{"+characterRole+".Your} body is suddenly [b]changing[/b]! "
				+ tfResult["text"]
			)

			if( tfResult.has("say") && ( tfResult["say"] != "" ) ):
				dialogueLines.append( tfResult["say"] )

	if( dialogueLines.size() > 0 ):
		tfResultText += (
				"\n\n"
			+ "[say="+characterRole+"]"
			+ RNG.pick(dialogueLines)
			+ "[/say]"
		)

	tfRequiresEndingInteraction = (
			(nextTurnTopOrBottom == "top")
		&& ( getTopChar().hasReachablePenis() == false )
	)

	return tfRequiresEndingInteraction

func getRelevantSexPoses():
	if(domIsBottoming):
		return ANAL_SEX_GIVING_POSES.duplicate()

	if(subWasPinnedToTheGround):
		return ANAL_SEX_RECEIVING_PINNED_POSES.duplicate()

	return ANAL_SEX_RECEIVING_STANDING_POSES.duplicate()

func getCurrentSexPose():
	for posesArray in SEX_POSE_ARRAYS:
		for availablePose in posesArray:
			if(availablePose.id == currentSexPoseId):
				return availablePose

	return null

func getSexPoseUnmetRequirements(pose) -> Array:
	var unmetRequirements = []

	if( !pose.has("requirements") ):
		return unmetRequirements

	if "wallsNearby" in pose.requirements:
		if( !hasWallsNearby() ):
			unmetRequirements.append("There are no walls nearby.")

	return unmetRequirements

func getPenisNoun():
	return RNG.pick(["cock", "dick", "member"])
func getPenisNounPlural():
	return getPenisNoun() + "s"

func getPenisDesc(_role:String):
	return "{"+ _role +".penisDesc} "+ getPenisNoun()
func getTopPenisDesc():
	return getPenisDesc( getTopRole() )
func getBottomPenisDesc():
	return getPenisDesc( getBottomRole() )
func getBothPenisesDesc():
	var sharedPenisDesc = ""

	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	
	if( !dom.hasBodypart(BodypartSlot.Penis) || !sub.hasBodypart(BodypartSlot.Penis) ):
		sharedPenisDesc = ""
		return sharedPenisDesc

	var domBodypartPenis = dom.getBodypart(BodypartSlot.Penis)
	var subBodypartPenis = sub.getBodypart(BodypartSlot.Penis)

	var domPenisDescriptions = []
	var subPenisDescriptions = []

	for n in 20:
		var domPenisRandomDesc = domBodypartPenis.getLewdAdjective()

		if( !domPenisDescriptions.has(domPenisRandomDesc) ):
			domPenisDescriptions.append(domPenisRandomDesc)

		var subPenisRandomDesc = subBodypartPenis.getLewdAdjective()

		if( !subPenisDescriptions.has(subPenisRandomDesc) ):
			subPenisDescriptions.append(subPenisRandomDesc)

	var sharedPenisDescriptions = []

	for domPenisDesc in domPenisDescriptions:
		if subPenisDescriptions.has(domPenisDesc):
			sharedPenisDescriptions.append(domPenisDesc)

	if( sharedPenisDescriptions.size() < 1 ):
		sharedPenisDesc = ""
		return sharedPenisDesc

	return ( RNG.pick(sharedPenisDescriptions) + " " + getPenisNounPlural() )

func getAnusAdjective():
	return RNG.pick(["needy", "awaiting", "drippy", "inviting", "wet", "slick", "aroused"])

func getAnusDesc(_role:String):
	return RNG.pick(["anus", "tailhole", "backdoor", "star", "anal ring"])
func getTopAnusDesc():
	return getAnusDesc( getTopRole() )
func getBottomAnusDesc():
	return getAnusDesc( getBottomRole() )

func getAnusDescWithStretch(_role:String):
	return "{"+ _role +".anusStretch} "+ getBottomAnusDesc()
func getTopAnusDescWithStretch():
	return getAnusDescWithStretch( getTopRole() )
func getBottomAnusDescWithStretch():
	return getAnusDescWithStretch( getBottomRole() )

func getPoseDescForCurrentSexPose():
	var currentSexPose = getCurrentSexPose()

	if(currentSexPose == null):
		return "[color=red]NO POSE ACTIVE[/color]"

	if(currentSexPose.id == "standing"):
		return "standing"
	if(currentSexPose.id == "full_nelson"):
		return "in a full nelson pose"
	if(currentSexPose.id == "mating_press"):
		return "in a mating press"
	if(currentSexPose.id == "missionary"):
		return "in a missionary pose"
	if(currentSexPose.id == "raised_leg"):
		return "with one leg raised"
	if(currentSexPose.id == "against_a_wall"):
		return "against a wall"
	if(currentSexPose.id == "pinned_into_wall"):
		return "pinned against a wall"
	if(currentSexPose.id == "prone_bone"):
		return "in a prone bone pose"
	if(currentSexPose.id == "all_fours"):
		return "on all fours"
	if(currentSexPose.id == "cowgirl"):
		return "in a cowgirl position"
	if(currentSexPose.id == "cowgirl_alt"):
		return "in a reclined cowgirl position"
	if(currentSexPose.id == "cowgirl_reverse"):
		return "in a reverse cowgirl position"
	if(currentSexPose.id == "lotus"):
		return "in a lotus position"

	return "[color=red]FIX DESCRIPTOR[/color]"

func postProcessEventLine(eventLine:String) -> String:
	return eventLine.replace("{top.", "{"+ getTopRole() +".").replace("{bottom.", "{"+ getBottomRole() +".")

func getEventLinesForCurrentSexPose_gettingIntoPose() -> Array:
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4
	var domIsKind = domPersonalityMeanScore < -0.4

	var subPersonalitySubbyScore = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var subIsSubby = subPersonalitySubbyScore > 0.4
	var subIsDommy = subPersonalitySubbyScore < -0.4

	var top_penis = getTopPenisDesc()
	var bottom_penis = getBottomPenisDesc()
	var both_penises = getBothPenisesDesc()

	var bottom_drippy_anus = getAnusAdjective() + " " + getBottomAnusDesc()
	var bottom_drippy_stretched_wide_anus = getAnusAdjective() + ", " + getBottomAnusDescWithStretch()

	var both_youThem = "you" if( isPlayerInvolved() ) else "them"
	var both_yourTheir = "your" if( isPlayerInvolved() ) else "their"
	var both_YourTheir = "Your" if( isPlayerInvolved() ) else "Their"

	var dom_gently = RNG.pick(["gently", "delicately", "playfully"]) if(domIsKind) else RNG.pick(["playfully", "assertively", "greedily"]) if(!domIsMean) else RNG.pick(["greedily", "roughly", "harshly", "ruthlessly"])
	var dom_you_reHe_s = "you're" if dom.isPlayer() else ( "they're" if ( dom.heShe() == "they" ) else "{dom.he}'s" )
	var dom_yoursHis = "yours" if dom.isPlayer() else ( "theirs" if ( dom.heShe() == "they" ) else "{dom.his}" )

	var sub_obediently = RNG.pick(["obediently", "willingly"]) if(subIsSubby) else RNG.pick(["readily"]) if(!subIsDommy) else RNG.pick(["reluctantly"])
	var sub_willingly = "willingly" if(sub_obediently == "obediently") else sub_obediently
	var sub_you_reHe_s = "you're" if sub.isPlayer() else ( "they're" if ( sub.heShe() == "they" ) else "{sub.he}'s" )
	var sub_yoursHis = "yours" if sub.isPlayer() else ( "theirs" if ( sub.heShe() == "they" ) else "{sub.his}" )

	var currentSexPose = getCurrentSexPose()

	if(currentSexPose == null):
		return [
			"[color=red]NO POSE ACTIVE[/color]",
		]

	var eventLines = []
	var dialogueLines = getDialogueLines_commandIntoPose(dom)
	var domCommandingToGetIntoPose = ( "[say=dom]"+ RNG.pick(dialogueLines) + "[/say]\n\n" ) if( dialogueLines.size() > 0 ) else ""

	if(currentSexPose.id == "full_nelson"):
		return [
			"{dom.You} {dom.youVerb('wrap')} {dom.yourHis} arms under {sub.your} legs, "+ dom_gently +" raising {sub.youHim} above the floor and locking {sub.yourHis} arms in a full nelson hold. {dom.YourHis} "+ top_penis +" is pressed against {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +"."
		]

	if(currentSexPose.id == "mating_press"):
		if(subWasPinnedToTheGround):
			return [
				"{dom.You} {dom.youVerb('roll')} {sub.you} on {sub.yourHis} back, "+ dom_gently +" folding {sub.yourHis} legs up toward {sub.yourHis} shoulders, pressing {dom.yourself} close, and positioning {dom.yourHis} "+ top_penis +" next to {sub.yourHis} exposed, "+ bottom_drippy_anus +"."
			]
		else:
			return [
				"{dom.You} {dom.youVerb('turn')} {sub.you} around, "+ dom_gently +" forcing {sub.youHim} down on {sub.yourHis} spine, firmly pressed against the floor in a mating press position. {dom.YouHe} then {dom.youVerb('press', 'presses')} {dom.yourself} close, aligning {dom.yourHis} "+ top_penis +" against {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +"."
			]

	if(currentSexPose.id == "missionary"):
		if(subWasPinnedToTheGround):
			return [
				"{dom.You} {dom.youVerb('turn')} {sub.you} onto {sub.yourHis} back, approaching closer and "+ dom_gently +" pushing {dom.yourHis} thighs into {sub.yourHis}, until "+ sub_you_reHe_s +" pinned by {dom.youHim} in a missionary pose, tip of {dom.yourHis} "+ top_penis +" touching the edges of {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +".",
				( domCommandingToGetIntoPose + "{sub.You} "+ sub_willingly +" {sub.youVerb('give')} in, lying flat on {sub.yourHis} spine. {dom.You} "+ dom_gently +" {dom.youVerb('pin')} {sub.youHim} against the floor, before taking a missionary pose, and positioning {dom.yourHis} "+ top_penis +" right next to {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +"." ),
			]
		else:
			return [
				"{dom.You} "+ dom_gently +" {dom.youVerb('pin')} {sub.your} body against the floor, placing {dom.yourself} between {sub.yourHis} legs, and aligning {dom.yourHis} "+ top_penis +" against {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +"."
			]

	if(currentSexPose.id == "raised_leg"):
		if(subWasPinnedToTheGround):
			return [
				"{dom.You} {dom.youVerb('turn')} {sub.you} on {sub.yourHis} back, "+ dom_gently +" getting hold of {sub.yourHis} "+ RNG.pick(["left", "right"]) +" leg and lifting it to dangle near {dom.yourHis} face, as {dom.youHe} {dom.youVerb('rub')} {dom.yourHis} "+ top_penis +" close to {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +"."
			]
		else:
			return [
				"With a circular motion of {dom.yourHis} paw, {dom.you} {dom.youVerb('command')} {sub.you} to turn around. {sub.YouHe} "+ sub_obediently +" {sub.youVerb('oblige')}, and {dom.youHe} {dom.youVerb('push', 'pushes')} {sub.youHim} on {sub.yourHis} spine, "+ dom_gently +" lifting one of {sub.yourHis} legs. As {sub.yourHis} hind paw sways intimately close to {dom.yourHis} snout, {dom.you} {dom.youVerb('press', 'presses')} {dom.yourself} close, brushing {dom.yourHis} "+ top_penis +" against {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +"."
			]

	if(currentSexPose.id == "against_a_wall"):
		return [
			"{dom.You} "+ dom_gently +" {dom.youVerb('press', 'presses')} {sub.you} against the nearby wall, forcing {sub.youHim} to rely on own arms to keep {sub.yourHis} balance. The tip of {dom.yourHis} "+ top_penis +" brushes over {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +", eager to enter."
		]

	if(currentSexPose.id == "pinned_into_wall"):
		return [
			"{dom.You} {dom.youVerb('grab')} {sub.your} "+ RNG.pick(["left", "right"]) +" hind paw, "+ dom_gently +" shoving {sub.youHim} into the nearest wall. As {sub.youHe} hastily {sub.youVerb('raise')} {sub.yourHis} arms in hopes to soften the impact, {dom.you} readily {dom.youVerb('pin')} {sub.youHim} against the wall, pressing {dom.yourHis} "+ top_penis +" against {sub.yourHis} vulnerable, "+ bottom_drippy_anus +".",
		]

	if(currentSexPose.id == "all_fours"):
		eventLines.append_array([
			"{dom.You} {dom.youVerb('lift')} {dom.yourHis} weight off {sub.you} and {dom.youVerb('grab')} both of {sub.yourHis} thighs, slightly rising them above the ground, before folding {sub.your} legs to force {sub.youHim} to use {sub.yourHis} knees for support. {sub.YouHe} instinctively uses {sub.yourHis} arms to support {sub.yourHis} chest, as {dom.youHe} {dom.youVerb('align')} {dom.yourHis} "+ top_penis +" against {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +".",
			( domCommandingToGetIntoPose + "{sub.You} "+ sub_willingly +" {sub.youVerb('obey')}, getting on all fours, as {dom.you} {dom.youVerb('position')} {dom.yourself} behind {sub.yourHis} butt, pressing {dom.yourHis} "+ top_penis +" against {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +"." ),
		])

		if( sub.hasTail() ):
			eventLines.append_array([
				( domCommandingToGetIntoPose + "{sub.You} "+ sub_obediently +" {sub.youVerb('get')} on all fours, lifting {sub.yourHis} tail, and welcoming {dom.you} to press {dom.yourHis} "+ top_penis +" against {sub.yourHis} "+ bottom_drippy_stretched_wide_anus +"." ),
			])

		return eventLines

	if(currentSexPose.id == "cowgirl"):
		return [
			(
					( "{sub.You} {sub.youVerb('lay')} on {sub.yourHis} spine, expecting {dom.you}. Without hesitation, {dom.youHe} {dom.youVerb('pounce')} at {sub.youHim}, "+ dom_gently +" stradling, " )
				+ (
						( "and playfully frotting "+ both_yourTheir +" "+ ( both_penises if(both_penises != "") else getPenisNounPlural() ) +" together until "+ dom_you_reHe_s +" ready to ride {sub.yourHis}." )
					if( dom.hasBodypart(BodypartSlot.Penis) && RNG.chance(50) )
					else ( "and rubbing {dom.yourHis} "+ bottom_drippy_stretched_wide_anus +" against {sub.yourHis} "+ top_penis +"." )
				)
			),
			(
					( domCommandingToGetIntoPose + "{sub.You} {sub.youVerb('nod')}, "+ sub_willingly +" positioning {sub.yourself} on the ground in an ideal pose for {dom.you} to ride {sub.youHim}. {dom.YouHe} "+ dom_gently +" {dom.youVerb('stradle')} {sub.youHim}, " )
				+ (
						( "rubbing "+ both_yourTheir +" "+ ( both_penises if(both_penises != "") else getPenisNounPlural() ) +" together for a brief moment." )
					if( dom.hasBodypart(BodypartSlot.Penis) && RNG.chance(50) )
					else ( "rubbing {dom.yourHis} "+ bottom_drippy_stretched_wide_anus +" against {sub.yourHis} "+ top_penis +"." )
				)
			),
		]

	if(currentSexPose.id == "cowgirl_alt"):
		return [
			(
					"{sub.You} {sub.youVerb('lay')} on {sub.yourHis} back, "
				+ (
						"playfully swaying {sub.yourHis} hips for {dom.you}"
					if ( dom.isBlindfolded() || sub.isBlindfolded() || RNG.chance(30) )
					else "winking at {dom.you}"
				)
				+ ( ". "+ RNG.pick(["Soon after", "Not long after"]) +", {dom.youHe} {dom.youVerb('climb')} on and "+ dom_gently +" {dom.youVerb('stradle')} {sub.youHim}, with {dom.yourHis} body tilted back, and {dom.yourHis} "+ bottom_drippy_stretched_wide_anus +" brushing against the tip of {sub.yourHis} "+ top_penis +"." )
			),
			( domCommandingToGetIntoPose + "{sub.You} "+ sub_willingly +" {sub.youVerb('follow')} {dom.your} command, slowly positioning {sub.yourself} on the ground, ready for {dom.youHim} to use {sub.youHim} for {dom.yourHis} pleasure. {dom.YouHe} nicely {dom.youVerb('position')} {dom.yourHis} thighs above "+ sub_yoursHis +", tilting {dom.yourHis} relaxed body backwards. {sub.You} can feel the edges of {dom.yourHis} "+ bottom_drippy_stretched_wide_anus +" touch the tip of {sub.yourHis} "+ top_penis +"." ),
		]

	if(currentSexPose.id == "cowgirl_reverse"):
		return [
			(
					"{sub.You} {sub.youVerb('position')} {sub.yourself} on the ground, ready for {dom.you} to ride {sub.youHim} in a reverse cowgirl position. {dom.YouHe} "+ dom_gently +" {dom.youVerb('stradle')} {sub.youHim}, "
				+ (
						(		( "briefly frotting "+ both_yourTheir +" "+ both_penises +" together" )
							if(both_penises != "")
							else ( "briefly frotting {sub.yourHis} "+ top_penis +" with "+ dom_yoursHis )
						)
					if( dom.hasBodypart(BodypartSlot.Penis) && RNG.chance(50) )
					else "briefly rubbing {dom.yourself} against {sub.yourHis} "+ top_penis
				)
				+ ", to "+ RNG.pick(["tease", "entice"]) +" {sub.youHim} even more."
			),
			( domCommandingToGetIntoPose + "Before {sub.you} {sub.youVerb('have', 'has')} a chance to process what's being asked of {sub.youHim}, {sub.yourHis} body has already assumed the position on the ground, allowing {dom.you} to "+ dom_gently +" {dom.youVerb('stradle')} {sub.youHim}, and rub {dom.yourself} all over." ),
		]

	if(currentSexPose.id == "lotus"):
		return [
			(
					( "{sub.You} {sub.youVerb('rest')} {sub.yourHis} butt on the ground, and {dom.you} promptly {dom.youVerb('sink')} into {sub.yourHis} lap, wrapping {dom.yourHis} legs around {sub.yourHis} waist, and resting {dom.yourHis} paws on {sub.yourHis} shoulders, as both of "+ both_youThem +" are pressed together in an intimate embrace. " )
				+ (
						( both_YourTheir +" "+ both_penises +" "+ RNG.pick(["touch", "throb"]) + " together." )
					if( both_penises != "" )
					else ( "{dom.Your} "+ bottom_penis +" lightly "+ RNG.pick(["brushes", "nudges"]) +" against {sub.yourHis} "+ top_penis +"." )
				)
			),
			(
					( domCommandingToGetIntoPose + "{sub.You} instinctively {sub.youVerb('obey')}, perhaps trained for this. {dom.You} {dom.youVerb('position')} {dom.yourself} in {sub.yourHis} lap, wrapping {dom.yourHis} legs around {sub.youHim}, and pressing close in an intimate embrace. " )
				+ (
						( both_YourTheir +" "+ both_penises +" are eagerly "+ RNG.pick(["touching", "throbbing"]) + " together." )
					if( both_penises != "" )
					else ( "{dom.Your} "+ bottom_penis +" eagerly "+ RNG.pick(["brushes", "nudges"]) +" against {sub.yourHis} "+ top_penis +"." )
				)
			),
		]

	return [
		"{dom.You} {dom.youVerb('position')} {dom.yourHis} "+ top_penis +" intimately close to {sub.your} "+ bottom_drippy_stretched_wide_anus +"."
	]

func getPriorityRandomness() -> Dictionary:
	var priorityRandomness:Dictionary = {}

	priorityRandomness.shouldBelittleBottom = !domIsBottoming && RNG.chance(50)

	return priorityRandomness

func getBaseLinesForCurrentSexPose_priority(_priorityRandomness:Dictionary) -> Array:
	var topCameThisTurn = topCameInsideThisTurn || topCameOutsideThisTurn

	if( topCameThisTurn && bottomCameThisTurn && !_priorityRandomness.shouldBelittleBottom ):
		return applyOrgasmSensationToLines( getBaseLinesForCurrentSexPose_bothCame() )

	if(topCameInsideThisTurn):
		return applyOrgasmSensationToLines( getBaseLinesForCurrentSexPose_topCameInside() )

	if(topCameOutsideThisTurn):
		var baseLines = getBaseLinesForCurrentSexPose_topCameOutside()

		if( getTopChar().isPlayer() ):
			baseLines = applyOrgasmSensationToLines(baseLines)

		return baseLines

	if(topPenisWasOutsidePreviousTurn):
		if(domIsBottoming):
			return getBaseLinesForCurrentSexPose_envelopingPenis()
		else:
			return getBaseLinesForCurrentSexPose_enteringHole()

	if(topCameInsidePreviousTurn):
		if(domIsBottoming):
			return getBaseLinesForCurrentSexPose_resumingRiding()
		else:
			return getBaseLinesForCurrentSexPose_resumingFucking()

	return []

func getFlavorLinesForCurrentSexPose_priority(_priorityRandomness:Dictionary) -> Array:
	var top = getTopChar()
	var bottom = getBottomChar()

	var topCameThisTurn = topCameInsideThisTurn || topCameOutsideThisTurn

	if( topCameThisTurn && bottomCameThisTurn && _priorityRandomness.shouldBelittleBottom ):
		var flavorLines = getFlavorLinesForCurrentSexPose_bottomAlsoCame()

		if( getBottomChar().isPlayer() ):
			flavorLines = applyOrgasmSensationToLines(flavorLines)

		return flavorLines

	if(topCameInsideThisTurn):
		# "[no flavor allowed]"
		return getFlavorLinesForCurrentSexPose_topCameInside()

	if(topCameOutsideThisTurn):
		# "[no flavor allowed]"
		return getFlavorLinesForCurrentSexPose_topCameOutside()

	if(bottomCameThisTurn):
		var flavorLines = getFlavorLinesForCurrentSexPose_bottomCame()

		if( getBottomChar().isPlayer() ):
			flavorLines = applyOrgasmSensationToLines(flavorLines)

		return flavorLines

	if( top.getArousal() >= 1.0 ):
		return getFlavorLinesForCurrentSexPose_topAboutToCum()

	if( top.getArousal() >= 0.9 ):
		return getFlavorLinesForCurrentSexPose_topGettingClose()

	if( bottom.getArousal() >= 0.9 ):
		return getFlavorLinesForCurrentSexPose_bottomGettingClose()

	return []

func getBaseLinesForCurrentSexPose_enteringHole() -> Array:
	var top_penis = getTopPenisDesc()

	var bottom_anus = getBottomAnusDesc()
	var bottom_drippy_stretched_wide_anus = getAnusAdjective() + ", " + getBottomAnusDescWithStretch()

	if(topCameTimes == 0):
		# _gettingIntoPose already accented on it, keep the description brief
		bottom_drippy_stretched_wide_anus = bottom_anus

	return [
		"{top.You} {top.youVerb('slide')} {top.yourHis} "+ top_penis +" "+ ( "back " if(topCameTimes > 0) else "" ) +"into {bottom.your} "+ bottom_drippy_stretched_wide_anus +", beginning to gracefully pound it.",
		"{top.You} "+ ( "once again " if(topCameTimes > 0) else "" ) +"{top.youVerb('squeeze')} {top.yourHis} "+ top_penis +" between {bottom.your} exposed buttcheeks, and {top.youVerb('start')} to thrust into {bottom.yourHis} "+ bottom_drippy_stretched_wide_anus +".",
	]

func getBaseLinesForCurrentSexPose_envelopingPenis() -> Array:
	var top_penis = getTopPenisDesc()

	#var bottom_anus = getBottomAnusDesc()
	var bottom_drippy_stretched_wide_anus = getAnusAdjective() + ", " + getBottomAnusDescWithStretch()

	return [
		"{bottom.You} "+ ( "re-" if(topCameTimes > 0) else "" ) +"{bottom.youVerb('align')} {bottom.yourHis} "+ bottom_drippy_stretched_wide_anus +", letting it envelop {top.your} "+ top_penis +". {bottom.You} then "+ ( "{bottom.youVerb('resume')} wielding it" if(topCameTimes > 0) else "{bottom.youVerb('begin')} to wield it" ) +" for {bottom.yourHis} pleasure.",
	]

func getBaseLinesForCurrentSexPose_resumingFucking() -> Array:
	#var top_penis = getTopPenisDesc()

	#var bottom_anus = getBottomAnusDesc()
	var bottom_drippy_stretched_wide_anus = getAnusAdjective() + ", " + getBottomAnusDescWithStretch()

	return [
		"{top.You} {top.youVerb('wish', 'wishes')} to keep going, again starting to thrust into {bottom.your} "+ bottom_drippy_stretched_wide_anus +".",
	]

func getBaseLinesForCurrentSexPose_resumingRiding() -> Array:
	var top_penis = getTopPenisDesc()

	#var bottom_anus = getBottomAnusDesc()
	#var bottom_drippy_stretched_wide_anus = getAnusAdjective() + ", " + getBottomAnusDescWithStretch()

	return [
		"{bottom.You} {bottom.youVerb('choose')} to keep riding {top.your} "+ top_penis +".",
	]

func getBaseLinesForCurrentSexPose_fucking() -> Array:
	var sexPoseDesc = getPoseDescForCurrentSexPose()

	if(domIsBottoming):
		return [
			"{bottom.You} {bottom.youAre} riding {top.you} "+ sexPoseDesc +"."
		]

	var verb_fucking = RNG.pick(["fucking", "pounding"])

	return [
		"{top.You} {top.youAre} "+ verb_fucking +" {bottom.you} "+ sexPoseDesc +"."
	]

func getBaseLinesForCurrentSexPose_beingFucked() -> Array:
	var top_penis = getTopPenisDesc()
	#var bottom_anus = getBottomAnusDesc()

	if(domIsBottoming):
		return [
			"{top.Your} "+ top_penis +" is being used by {bottom.you}."
		]

	return [
		"{bottom.You} {bottom.youAre} taking {top.your} "+ top_penis +".",
		"{bottom.You} {bottom.youAre} letting {top.your} "+ top_penis +" penetrate {bottom.youHim}.",
	]

func getBaseLinesForCurrentSexPose_topCameInside() -> Array:
	var top_cum = RNG.pick(["sticky seed", "cum"])
	var bottom_anus = getBottomAnusDesc()

	if(domIsBottoming):
		return [
			"{bottom.You} {bottom.youVerb('let')} {bottom.yourHis} "+ bottom_anus + " get filled with every bit of {top.your} "+ top_cum + "."
		]

	return [
		"{top.You} {top.youVerb('fill')} {bottom.your} "+ bottom_anus + " full of {top.yourHis} "+ top_cum + "."
	]

func getBaseLinesForCurrentSexPose_bothCame() -> Array:
	var baseLines = []

	var both_youThem = "you" if( isPlayerInvolved() ) else "them"
	var bottom_anus = getBottomAnusDesc()

	var baseSentence = RNG.pick([
		"Both of "+ both_youThem +" finish in unison!",
		"Both of "+ both_youThem +" cum at the same time!",
	]) + " "

	if(topCameInsideThisTurn):
		baseLines.append_array([
			baseSentence + "{top.You} {top.youVerb('have', 'has')} {bottom.your} "+ bottom_anus +" filled to the brim, while {bottom.yourHis} cum spreads everywhere.",
		])
	elif(topCameOutsideThisTurn):
		baseLines.append_array([
			baseSentence + "{top.You} managed to pull out of {bottom.your} "+ bottom_anus +" just in time.",
		])

	return baseLines

func getBaseLinesForCurrentSexPose_topCameOutside() -> Array:
	var top_penis = getTopPenisDesc()
	#var bottom_anus = getBottomAnusDesc()

	var currentSexPose = getCurrentSexPose()

	if(currentSexPose == null):
		return []

	if(domIsBottoming):
		return [
			"{bottom.You} {bottom.youVerb('pull')} away from {top.your} "+ top_penis + " just before {top.youHe} {top.youVerb('finish', 'finishes')}, letting all of {top.yourHis} cum go to waste."
		]

	var painted_bodyparts = "belly and thighs" if("bottomFacingTop" in currentSexPose.tags) else "neck and spine"

	return [
		"{bottom.You} {bottom.youVerb('feel')} {top.your} "+ top_penis + " slide out mere moments before it paints cum all over {bottom.yourHis} "+ painted_bodyparts + "."
	]

func getEventLinesForCurrentSexPose_afterSex() -> Array:
	var dom = getRoleChar("dom")

	var dom_you_veHe_s = "you've" if dom.isPlayer() else ( "they've" if ( dom.heShe() == "they" ) else "{dom.he}'s" )

	return [
		"{dom.You} {dom.youVerb('feel')} like "+ dom_you_veHe_s +" had enough fucking {sub.you}.",
	]

func getFlavorLinesForCurrentSexPose_fucking() -> Array:
	var flavorLines = []

	#var top = getTopChar()
	var bottom = getBottomChar()

	var currentSexPose = getCurrentSexPose()

	if(currentSexPose == null):
		return flavorLines

	if( !bottom.hasBoundArms() ):
		if "bottomUnboundArmsGraspingAtWall" in currentSexPose.tags:
			flavorLines.append_array([
				"{bottom.YourHis} arms grasp at any irregularity in the wall just to retain balance.",
				"{bottom.YouHe} {bottom.youVerb('struggle')} to maintain balance as {bottom.yourHis} arms tremble from pleasure.",
			])

		if "bottomUnboundArmsSupportingChest" in currentSexPose.tags:
			flavorLines.append_array([
				"{bottom.YourHis} whole body trembles with each thrust, arms weakened from the need to support {bottom.yourHis} chest.",
			])

	if "bottomBelowTop" in currentSexPose.tags:
		flavorLines.append_array([
			"{bottom.YouHe} {bottom.youVerb('quiver')} below {top.youHim}.",
		])

	return flavorLines

func getFlavorLinesForCurrentSexPose_beingFucked() -> Array:
	var flavorLines = []

	var top = getTopChar()
	var bottom = getBottomChar()

	var domIsPerformingMouthPlay = domToggleableMouthPlayActiveTurns > 0
	var isBottomMouthClosed = ( !domIsPerformingMouthPlay && !bottom.isGagged() )

	var bottom_yoursHis = "yours" if bottom.isPlayer() else ( "theirs" if ( bottom.heShe() == "they" ) else "{bottom.his}" )

	var currentSexPose = getCurrentSexPose()

	if(currentSexPose == null):
		return flavorLines

	if(isBottomMouthClosed):
		flavorLines.append_array([
			"{bottom.YouHe} {bottom.youVerb('moan')} into {bottom.yourHis} closed mouth.",
		])

	if "unboundHandholding" in currentSexPose.tags:
		if( !top.hasBoundArms() && !bottom.hasBoundArms() && !top.hasBlockedHands() && !bottom.hasBlockedHands() ):
			flavorLines.append_array([
				"{bottom.YouHe} {bottom.youVerb('feel')} the heat of {top.yourHis} paw against "+ bottom_yoursHis +".",
			])

	return flavorLines

func getFlavorLinesForCurrentSexPose_topGettingClose() -> Array:
	var flavorLines = [
		"{top.YouHe} {top.youVerb('feel')} very close.",
		"{top.YouHe} {top.youAre} on the very edge.",
		"{top.YouHe} {top.youAre} nearing {top.yourHis} orgasm.",
	]

	return flavorLines

func getFlavorLinesForCurrentSexPose_topAboutToCum() -> Array:
	var flavorLines = [
		"{top.YouHe} {top.youAre} about to cum!",
	]

	return flavorLines

func getFlavorLinesForCurrentSexPose_bottomGettingClose() -> Array:
	var flavorLines = [
		"{bottom.YouHe} {bottom.youAre} approaching a point where it's very difficult to prevent {bottom.yourself} from cumming.",
		"{bottom.YouHe} {bottom.youVerb('look')} like {bottom.youHe} wouldn't be able to hold off finishing for much longer.",
	]

	return flavorLines

func getFlavorLinesForCurrentSexPose_bottomAlsoCame() -> Array:
	var flavorLines = [
		"On a less important note, {bottom.you} also {bottom.youVerb('finish', 'finishes')}.",
		"Less importantly, {bottom.you} also {bottom.youVerb('cum')}.",
	]

	return flavorLines

func getFlavorLinesForCurrentSexPose_topCameInside() -> Array:
	var flavorLines = ["[no flavor allowed]"]
	return flavorLines

func getFlavorLinesForCurrentSexPose_topCameOutside() -> Array:
	var flavorLines = ["[no flavor allowed]"]
	return flavorLines

func getFlavorLinesForCurrentSexPose_bottomCame() -> Array:
	var flavorLines = []

	var currentSexPose = getCurrentSexPose()

	if(currentSexPose == null):
		return flavorLines

	var cumming_where = "everywhere"

	if("bottomCumsOverSelf" in currentSexPose.tags):
		cumming_where = "all over {bottom.yourself}"
	elif("bottomFacingTop" in currentSexPose.tags):
		cumming_where = "all over {top.you}"

	flavorLines.append_array([
		"{bottom.YouHe} {bottom.youAre} unable to hold it any longer, cumming "+ cumming_where + ".",
		"{bottom.YouHe} cannot stop {bottom.yourself} from cumming "+ cumming_where + ".",
	])

	return flavorLines

func getDialogueLines_commandIntoPose(_dom:BaseCharacter) -> Array:
	var dialogueLines = []

	var currentSexPose = getCurrentSexPose()

	if(currentSexPose == null):
		return dialogueLines

	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsKind = domPersonalityMeanScore < -0.4

	var domPersonalitySubbyScore = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var domIsSubby = domPersonalitySubbyScore > 0.4

	if(currentSexPose.id == "missionary"):
		if(subWasPinnedToTheGround):
			dialogueLines.append_array([
				"Turn around, "+ RNG.pick(subPetNames) +".",
			])

			if(!domIsSubby):
				dialogueLines.append_array([
					"On your back.",
				])

			if(domIsKind):
				dialogueLines.append_array([
					"Roll over on your back, hun.",
				])
	elif(currentSexPose.id == "all_fours"):
		dialogueLines.append_array([
			"Be a good "+ RNG.pick(subPetNames) +" and get on all fours.",
		])

		if(domIsSubby):
			dialogueLines.append_array([
				"Why don't you get on all fours for me~",
			])
		else:
			dialogueLines.append_array([
				"On all fours, now.",
			])
	elif( currentSexPose.id in ["cowgirl", "cowgirl_alt", "cowgirl_reverse"] ):
		dialogueLines.append_array([
			"Get yourself ready for me.",
			"Good "+ RNG.pick(subPetNames) +". Now lay on your back.",
		])

		if(!domIsSubby):
			dialogueLines.append_array([
				"On your back.",
			])
	elif(currentSexPose.id == "lotus"):
		dialogueLines.append_array([
			"Sit, like a good "+ RNG.pick(subPetNames) +" you are.",
		])

		if(domIsSubby):
			dialogueLines.append_array([
				"Prepare your lap for me, won't you? Sit.",
			])
		else:
			dialogueLines.append_array([
				"Sit!",
			])

	return dialogueLines

func getDialogueLines_emphasizeTightness(_character:BaseCharacter) -> Array:
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var dialogueLines = []

	var subBodypartAnus:BodypartAnus = sub.getBodypart(BodypartSlot.Anus)

	if(subBodypartAnus == null):
		dialogueLines = []
		return dialogueLines

	var subOrificeAnus:Orifice = subBodypartAnus.getOrifice()

	if(subOrificeAnus == null):
		dialogueLines = []
		return dialogueLines

	var subAnusLooseness:float = subOrificeAnus.getLooseness()

	if(subAnusLooseness > 0.5):
		dialogueLines = []
		return dialogueLines

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4

	dialogueLines.append_array([
		"You're so tight..",
	])

	if(!domIsMean):
		dialogueLines.append_array([
			"Didn't expect you to be so tight~"
		])

	return dialogueLines

func getDialogueLines_endedSexEarlyDueToTransformation(_character:BaseCharacter, _characterRole:String) -> Array:
	var characterPawn = getRolePawn(_characterRole)

	var characterPersonalityMeanScore = characterPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var characterIsMean = characterPersonalityMeanScore > 0.4

	var characterInterestInTFReceiving = characterPawn.scoreFetishMax({ Fetish.TFReceiving: 1.0 })
	var characterLikesTFReceiving = characterInterestInTFReceiving >= 0.5
	var characterDislikesTFReceiving = characterInterestInTFReceiving <= -0.5

	# Used by both doms and subs

	var dialogueLines = []

	if(characterLikesTFReceiving):
		if(characterIsMean):
			dialogueLines.append_array([
				"About the fucking time they kicked in. Meet the new me.",
				"That's all you're getting, whore. You don't deserve my new shape.",
			])
		else:
			dialogueLines.append_array([
				"Oooh, I have transformed!",
				"Ohh, I've been waiting for this to happen! Sorry about the timing though~",
				"I wasn't ready for this to happen now.. But f-fuckk, I love changing..",
				"I can never predict when this happens.. But that's also what makes it so exciting~",
			])
	elif(!characterDislikesTFReceiving):
		if(!characterIsMean):
			dialogueLines.append_array([
				"Oh.. I think.. something about my body has changed..",
				"Awhh, I thought I still had time..",
				"That drug.. it kicked in so fast..",
			])

		dialogueLines.append_array([
			"Huh.. My body feels.. different..",
			"This is.. a little unexpected.. Hmph.",
		])
	else:
		if(characterIsMean):
			dialogueLines.append_array([
				"W- What the fuck?",
				"I fucking hate everything about this.",
			])
		else:
			dialogueLines.append_array([
				"Nooo, why does it have to happen now??",
				"Arghh, I never asked for this to happen..",
				"Why now.. Why does it have to happen to me at all, f-fuck..",
				"I really regret some of my decisions lately..",
			])

	return dialogueLines

func getDialogueLines_endedSexEarlyDueToTransformationReaction(_character:BaseCharacter, _characterRole:String) -> Array:
	var characterPawn = getRolePawn(_characterRole)
	var characterIsTop = ( _character == getTopChar() )

	var characterPersonalityMeanScore = characterPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var characterIsMean = characterPersonalityMeanScore > 0.4

	#var partnerCharacter = getBottomChar() if(characterIsTop) else getTopChar()
	var partnerPawn = getBottomPawn() if(characterIsTop) else getTopPawn()

	var partnerInterestInTFReceiving = partnerPawn.scoreFetishMax({ Fetish.TFReceiving: 1.0 })
	var partnerLikesTFReceiving = partnerInterestInTFReceiving >= 0.5
	var partnerDislikesTFReceiving = partnerInterestInTFReceiving <= -0.5

	# Used by both doms and subs

	var dialogueLines = []

	if(characterIsMean):
		dialogueLines.append_array([
			"I couldn't care less how you look like.",
			"You still look like a whore.",
		])

	if(partnerLikesTFReceiving || !partnerDislikesTFReceiving):
		if(!characterIsMean):
			dialogueLines.append_array([
				( ( "You look" if( !_character.isBlindfolded() ) else "Your touch is" ) +" just as charming, darling." ),
			])

	if(partnerLikesTFReceiving):
		if(characterIsMean):
			dialogueLines.append_array([
				"Why the fuck are you so pent up about it?",
			])
		else:
			dialogueLines.append_array([
				"I love how pent up you are about it~",
			])
	elif(!partnerDislikesTFReceiving):
		if(!characterIsMean):
			dialogueLines.append_array([
				"I'm sure you'll love this form of yours~",
			])
	else:
		if(!characterIsMean):
			dialogueLines.append_array([
				( "Hehee, I'm sure there are still plenty of ways to "+( "use" if(_characterRole == "dom") else "serve" )+" you~" ),
				"You're fine~. Whether you get used to it, or find a way to shift back, I'd still be eager to explore your body~",
			])

	return dialogueLines

func getDialogueLines_endedSexEarly(_character:BaseCharacter, _characterRole:String) -> Array:
	# Used by both doms and subs

	var dialogueLines = []

	if(topCameTimes >= 2):
		dialogueLines.append_array([
			"F- Fuck.. I cannot endure it for much longer. That was hot though..",
			"I.. really need a break. But don't get me wrong, that was amazing.",
		])
	else:
		dialogueLines.append_array([
			"I thought I'd be up for it, but I'm really not feeling it right now.. Sorry.",
		])

	return dialogueLines

func getDialogueLines_endedSexEarlyReaction(_character:BaseCharacter, _characterRole:String) -> Array:
	var characterPawn = getRolePawn(_characterRole)

	var characterPersonalityMeanScore = characterPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var characterIsMean = characterPersonalityMeanScore > 0.4

	# Used by both doms and subs

	var dialogueLines = [
		"Alright. There's always another time.",
	]

	if(characterIsMean):
		if( ( _character == getTopChar() ) && (topCameTimes < 1) ):
			dialogueLines.append_array([
				"Uhh, now?? I didn't even finish once.. But I understand. I'll catch your ass another time."
			])
	else:
		dialogueLines.append_array([
			"Oh.. No worries.",
		])

	return dialogueLines

func getDialogueLines_offerCuddles(_character:BaseCharacter, _characterRole:String) -> Array:
	var dialogueLines = [
		"Do you want some snuggles?",
		"Do you want to snuggle with me?",
		"Wanna snuggle together?",
	]

	if(_characterRole == "dom"):
		dialogueLines.append_array([
			"Would you like me to snuggle you for a little bit?",
		])
	elif(_characterRole == "sub"):
		dialogueLines.append_array([
			"Would you like to hold me close for a little while?",
		])

	return dialogueLines

func getDialogueLines_afterSex(_character:BaseCharacter, _characterRole:String) -> Array:
	var characterPawn = getRolePawn(_characterRole)
	var characterIsTop = ( _character == getTopChar() )

	var partnerCharacter = getBottomChar() if(characterIsTop) else getTopChar()
	var partnerPawn = getBottomPawn() if(characterIsTop) else getTopPawn()

	var characterPersonalityMeanScore = characterPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var characterIsMean = characterPersonalityMeanScore > 0.4

	var characterPersonalitySubbyScore = characterPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var characterIsSubby = characterPersonalitySubbyScore > 0.4
	var characterIsDommy = characterPersonalitySubbyScore < -0.4

	var characterLustInterests:LustInterests = _character.getLustInterests()
	var characterLustInterestInStuffedAss = characterLustInterests.getInterestValue(InterestTopic.StuffedAss)
	var characterLustInterestInCoveredInCum = characterLustInterests.getInterestValue(InterestTopic.CoveredInCum)

	var affectionValue:float = characterPawn.getAffection(partnerPawn)

	var dialogueLines = []

	if(!characterIsMean):
		if( ( characterIsSubby && (_characterRole == "dom") ) || ( characterIsDommy && (_characterRole == "sub") ) ):
			dialogueLines.append_array([
				"I don't take on this role often, so you must be quite the lucky creature~",
			])

	if(_characterRole == "dom"):
		if(characterIsMean):
			if( ( partnerCharacter.getArousal() >= 0.70 ) && partnerCharacter.hasReachablePenis() ):
				dialogueLines.append_array([
					"Hm, still got your boner? Too bad, slut, it seems that you're keeping it.",
					"Good fucktoy~. Go find someone to take care of that bone of yours.",
				])

		if(topCameTimes >= 5):
			dialogueLines.append_array([
				"I can still keep going~. But I'll catch you later, when you least expect it.",
			])

			if(characterIsTop):
				dialogueLines.append_array([
					"Each time you feel weak in the knees I want you to think of me.",
				])

			if(characterIsMean):
				dialogueLines.append_array([
					"That's more than you deserve, now get lost.",
				])

				if(characterIsTop):
					if(characterLustInterestInStuffedAss >= 0.5):
						dialogueLines.append_array([
							"Heard you're a cum dump, but now you actually look like one.",
						])

					if(characterLustInterestInCoveredInCum >= 0.5):
						dialogueLines.append_array([
							"Hope you enjoy being covered in thick ropes, because you don't get to clean for the rest of the day.",
						])
			else:
				dialogueLines.append_array([
					"Huff.. You're quite charming, always tempting me to keep going..",
					"Hope I surpassed your expectations, hun~",
				])
		elif(topCameTimes >= 2):
			dialogueLines.append_array([
				"Might wanna get yourself ready for another round. Even if you slip past my paws, someone is about to make good use of you~",
				"If you're ever lusting for more, you know where to find me. Though next time I won't let you leave so easily~",
			])

			if( abs(affectionValue) < 0.20 ):
				dialogueLines.append_array([
					"The name's {dom.name}. You better remember it.",
				])

			if( RNG.chance(5) ):
				if(characterIsTop):
					dialogueLines.append_array([
						"Enjoy your filler content.",
					])

			if(characterIsDommy):
				dialogueLines.append_array([
					"I'm letting you go, but you still belong to me. Know your place and kneel when you see me.",
				])

			if(characterIsMean):
				dialogueLines.append_array([
					"You ain't getting any more of me, now get the fuck out of my sight.",
					"I've had my share of fun. I don't care if you did, get lost.",
				])

				if(!characterIsTop):
					dialogueLines.append_array([
						"Good service slut.",
					])
			else:
				dialogueLines.append_array([
					"Fuck, that felt good..",
					"You're the best dessert~",
					"You've earned yourself some rest, "+ RNG.pick(subPetNames) +".",
				])

				if(characterIsTop):
					dialogueLines.append_array([
						"Huff.. I've got more treats for you, next time we meet.",
					])
		else:
			if(characterIsMean):
				dialogueLines.append_array([
					"That's all you're getting this time. I want to see you crawl over the place craving for more.",
				])
			else:
				dialogueLines.append_array([
					"Hope you enjoyed the quickie~",
				])
	else:
		if(topCameTimes >= 8):
			if(characterIsMean):
				dialogueLines.append_array([
					"F- Fuck, I'm surprised you know how to stop.",
				])
			else:
				dialogueLines.append_array([
					"F- Fuck, my whole body feels so weak..",
					"Everything hurts.. but.. in a good way..",
				])

				if(!characterIsTop):
					dialogueLines.append_array([
						"Hhhjff.. I- I think I'm going to feel phantom fucked for the rest of the week after this..",
					])
		elif(topCameTimes >= 5):
			if(characterIsMean):
				dialogueLines.append_array([
					"Huff.. Is that all you've got?",
					"Bitch.. You're full of surprises, huh?",
				])
			else:
				dialogueLines.append_array([
					"Oh.. Wow..",
					"Ahh.. F- Fuck, that was great..",
				])

				if(characterIsTop):
					dialogueLines.append_array([
						"F- Fuck.. Ride me any day..",
					])
		elif(topCameTimes >= 2):
			if(characterIsMean):
				dialogueLines.append_array([
					"That was mediocre at best.",
					"For a slut, that wasn't half bad..",
				])

				if(characterIsDommy):
					if(!characterIsTop):
						dialogueLines.append_array([
							"Bah. Next time your ass is stuck in the stocks I'll show you how it's done.",
						])
			else:
				dialogueLines.append_array([
					"We haven't parted ways yet, but I'm already imagining meeting you again..",
					"Mmhh, I really needed that..",
					"H- How does this keep happening to me..",
					"Huff.. I loved the pose.",
				])

				if(affectionValue >= 0.60):
					dialogueLines.append_array([
						"Huff.. You always know how to give me a good time~",
					])
		else:
			if(characterIsMean):
				dialogueLines.append_array([
					"That wasn't worth the time. Whatever.",
					"Ahh- Wait, whore, is that all?",
					"I haven't paid you any credits but I still feel scammed.",
				])
			else:
				dialogueLines.append_array([
					"Mhff, that left me very needy..",
				])

	return dialogueLines

func getDialogueLines_afterSexSubSeekingAffirmation(_character:BaseCharacter) -> Array:
	var dialogueLines = []

	if(topCameTimes >= 8):
		dialogueLines.append_array([
			"I- I can't feel half of my b- body.. I h- hope I did well..",
		])
	elif(topCameTimes >= 5):
		dialogueLines.append_array([
			"H- Huff.. Did I do a good job? Please tell me I did..",
		])
	elif(topCameTimes >= 2):
		dialogueLines.append_array([
			"P- Please tell me I did well.",
			"P- Please tell me I was a good "+ RNG.pick(subPetNames) +"..",
		])
	else:
		dialogueLines.append_array([
			"D- Did I do something wrong? That was rather brief..",
			"W- Was I.. not good enough? I expected us to have some m- more fun..",
		])

	return dialogueLines

func getDialogueLines_afterSexSubSeekingAffirmationReaction(_character:BaseCharacter) -> Array:
	var characterPawn = getRolePawn("dom")

	var characterPersonalityMeanScore = characterPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var characterIsMean = characterPersonalityMeanScore > 0.4

	var affectionValue:float = characterPawn.getAffection( getRolePawn("sub") )

	var dialogueLines = []

	if(characterIsMean):
		dialogueLines.append_array([
			"You were just another whore. But I would use you again.",
			"You hardly pleased me. Now scram. Keep getting yourself in hapless situations, and maybe I'll consider making a proper fucktoy out of you.",
		])
	else:
		dialogueLines.append_array([
			"You did "+ RNG.pick(["good", "great", "well"]) +", "+ RNG.pick(subPetNames) +".",
		])

		if(affectionValue >= 0.20):
			dialogueLines.append_array([
				"You're a pleasure, {sub.name}.",
			])

	return dialogueLines

func getDialogueLines_commandOnAllFoursForLeashedWalk(_character:BaseCharacter) -> Array:
	var dialogueLines = [
		"On all fours.",
	]

	return dialogueLines

func getDialogueLines_attachedLeashForWalk(_character:BaseCharacter) -> Array:
	var characterPawn = getRolePawn("dom")

	var characterPersonalityMeanScore = characterPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var characterIsMean = characterPersonalityMeanScore > 0.4

	var dialogueLines = [
		"You'll keep me company, pet.",
	]

	if(characterIsMean):
		dialogueLines.append_array([
			"What an obedient slut.",
		])
	else:
		dialogueLines.append_array([
			"You're mine now~",
			"Everyone needs to see how good of a pet you are~",
		])

	return dialogueLines

func getDialogueLines_walkingLeashedOnAllFours(_character:BaseCharacter) -> Array:
	var sub = getRoleChar("sub")

	var subSpecies = sub.getSpecies()

	var dialogueLines = [
		"I'm.. a pet..",
		"*"+ RNG.pick(subPetNames) +" noises*",
	]

	if( subSpecies.has(Species.Canine) ):
		dialogueLines.append_array([
			"Woof!",
			"Bark!",
		])

	if( subSpecies.has(Species.Feline) ):
		dialogueLines.append_array([
			"Mmhh.. Meow?",
			"Mrow..",
		])

	return dialogueLines

func hasWallsNearby() -> bool:
	var locToCheck:String = ""
	if( isPlayerInvolved() ):
		locToCheck = GM.pc.getLocation()
	else:
		var domPawn = getRolePawn("dom")
		locToCheck = domPawn.getLocation()

	if(locToCheck == ""):
		return true

	if(GM.world == null):
		return true

	return GM.world.hasWallsNearby(locToCheck)

func afterSexEnded() -> void:
	for topOrBottom in ["top", "bottom"]:
		var domOrSubString = getTopRole() if(topOrBottom == "top") else getBottomRole()
		var character = getTopChar() if(topOrBottom == "top") else getBottomChar()
		var characterCameTimes = topCameTimes if(topOrBottom == "top") else bottomCameTimes
		var partnerCameTimes = bottomCameTimes if(topOrBottom == "top") else topCameTimes

		if(characterCameTimes > 0):
			character.addLust(-character.getLust())

			if( character.isPlayer() ):
				character.addStamina( character.getBuffsHolder().getCustom(BuffAttribute.StaminaRecoverAfterSex) )
				character.addSkillExperience(Skill.SexSlave, 30)

		if( !character.isPlayer() ):
			character.addLust(-character.getLust())
			character.addPain(-character.getPain())
			character.addStamina(character.getMaxStamina())

		character.setArousal(0.0)

		if(!hasSexEndedEarly):
			if(domOrSubString == "dom"):
				addRepScore( "dom", RepStat.Alpha, min(0.10 * partnerCameTimes, 0.40) )
			elif(domOrSubString == "sub"):
				var affectionIncrease:float = min(0.0125 * partnerCameTimes, 0.05) + min(0.05 * characterCameTimes, 0.05)
				var lustIncrease:float = min(0.05 * partnerCameTimes, 0.20)

				affectAffection("sub", "dom", affectionIncrease)
				affectLust("sub", "dom", lustIncrease)

				addRepScore( "sub", RepStat.Whore, min(0.10 * partnerCameTimes, 0.40) )

func resetLustState() -> void:
	for role in ["dom", "sub"]:
		var character = getRoleChar(role)
		var items = character.getInventory().getAllEquippedItems()
		for itemSlot in items:
			var item = items[itemSlot]
			item.resetLustState()
		character.updateAppearance()
