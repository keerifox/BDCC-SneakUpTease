extends PawnInteractionBase

const DOM_FLIRT_COOLDOWN_TURNS:int = 3
const DOM_SPECIAL_ACTION_COOLDOWN_TURNS:int = 3

const SUB_SNARK_COOLDOWN_TURNS:int = 3
const SUB_STAMINA_COST_BREAK_FREE:int = 40
const SUB_MAX_RESISTING_TURNS_WHEN_STANDING:int = 10
const SUB_MAX_RESISTING_TURNS_TOTAL:int = 20
const SUB_MAX_WAITING_ON_DOM_TURNS:int = 12

var subResistedTimes:int = 0
var subResistedWhileNotWaitingOrHesitatingTimes:int = 0
var subSoftenedTimes:int = 0
var subSoftenedWhileWaitingTimes:int = 0
var subRubbedAgainstDomTimes:int = 0
var subSnarkCooldown:int = 0
var subSnarkUsedTimes:int = 0
var subBrattinessRatio:float = 0.5
var subAdditionalLustFromSpecials:float = 0.0
var subStaminaRecovered:int = 0
var subConsentedToUndressing:bool = false
var subConsentedToAnalSexReceiving:bool = false
var subConsentedToAnalSexGiving:bool = false
var subIsTooFrightenedToEscape:bool = false
var subWasHypnotizedIntoKneeling:bool = false
var subWasHypnotizedIntoStandingStill:bool = false
var subEscapeUponEaseGripProbability:float = 0.0
var subIntendsToKneel:bool = false
var subIntendsToStandStill:bool = false
var subWasPinnedToTheGround:bool = false
var subWasUndressed:bool = false

var domHasUsedFlirtLineByAlias:Dictionary = {}
var domFlirtCooldown:int = 0
var domRefusedUndressingRequestTimes:int = 0
var domRefusedPenetrationRequestTimes:int = 0
var domHasBittenSubTimes:int = 0
var domRefusedAnalSexReceiving:bool = false
var domSpecialActionCooldown:int = 0
var domSpecialActionKeyLastUsed:String = "none"
var domSpecialActionParamStrength:float = 0.0
var domSpecialActionParamBodyPart:String = "none"
var domEasedGripOnce:bool = false
var domAttemptedToHypnotizeSubUponEaseGrip:bool = false
var domWasUndressed:bool = false
var domWasCaptivatedBySubPenis:bool = false

func _init():
	id = "SneakUpTease"

func start(_pawns:Dictionary, _args:Dictionary):
	doInvolvePawn("dom", _pawns["dom"])
	doInvolvePawn("sub", _pawns["sub"])
	setState("", "sub")

	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	if( dom.getLustLevel() < 0.5 ):
		dom.addLust( int( ceil( 0.05 * dom.lustThreshold() ) ) )

	if( !sub.isPlayer() ):
		var NPC_STAMINA_RATIO_DESIRED_MINIMUM = 0.6
		var interactionStartSubStaminaIncrease = int( ceil( ( NPC_STAMINA_RATIO_DESIRED_MINIMUM * sub.getMaxStamina() ) - sub.getStamina() ) )
		if(interactionStartSubStaminaIncrease >= 1):
			sub.addStamina(interactionStartSubStaminaIncrease)

		var NPC_PAIN_RATIO_DESIRED_MAXIMUM = 0.4
		var interactionStartSubPainReduction = int( ceil( sub.getPain() - ( NPC_PAIN_RATIO_DESIRED_MAXIMUM * sub.painThreshold() ) ) )
		if(interactionStartSubPainReduction >= 1):
			sub.addPain(-interactionStartSubPainReduction)

	if( dom.isFullyNaked() && sub.isFullyNaked() ):
		# Skip undressing interactions if there is nothing to undress
		subConsentedToUndressing = true
		domWasUndressed = true
		subWasUndressed = true

	var subPersonalityBratRatio = ( subPawn.scorePersonalityMax({ PersonalityStat.Brat: 1.0 }) + 1.0 ) / 2.0
	subBrattinessRatio = clamp( ( subPersonalityBratRatio + RNG.randf_range(-0.4, 0.4) ), 0.0, 1.0 )

func init_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var possible = []

	var subResistedOrSoftenedTimes = subResistedTimes + subSoftenedTimes

	if(domSpecialActionKeyLastUsed == "none"):
		var isIntro = (subResistedOrSoftenedTimes < 1)

		if(isIntro):
			possible.append_array([
				"{dom.You} tightly {dom.youVerb('grip')} both of {sub.your} wrists as they're pinned behind {sub.yourHis} back. {dom.YourHis} breath cascades against {sub.yourHis} neck, making {sub.youHim} feel intimated in {dom.yourHis} presence.",
				"{dom.You} firmly {dom.youVerb('grip')} {sub.your} arms as they're held together behind {sub.yourHis} spine. {dom.YouHe} {dom.youVerb('lean')} forward, forcing {sub.youHim} to bend over, even if just a little.",
			])
		else:
			var domHasExposedPenis = dom.hasBodypart(BodypartSlot.Penis) && !dom.isBodypartCovered(BodypartSlot.Penis)
			var domFrontBodypart = "crotch" if(!domHasExposedPenis) else ( "{dom.penisDesc} "+ RNG.pick(["cock", "dick", "member"]) )
			
			var isRubbingBetweenButtcheeks = (
					subConsentedToUndressing
				&& !dom.isBodypartCovered(BodypartSlot.Penis)
				&& !sub.isBodypartCovered(BodypartSlot.Anus)
			)

			if(isRubbingBetweenButtcheeks):
				var subRearBodypart = ( RNG.pick(["bare", "charming", "exposed"]) + " buttcheeks" )

				possible.append_array([
					"{dom.You} {dom.youVerb('rub')} {dom.yourHis} "+ domFrontBodypart +" between {sub.your} "+ subRearBodypart +".",
				])
			else:
				var subRearBodypart = "clothed butt" if(sub.isBodypartCovered(BodypartSlot.Anus)) else ( RNG.pick(["bare", "charming", "exposed"]) + " butt" )

				possible.append_array([
					"{dom.You} {dom.youVerb('rub')} {dom.yourHis} "+ domFrontBodypart +" against {sub.your} "+ subRearBodypart +".",
				])

		saynn(RNG.pick(possible))
	else:
		if(domSpecialActionKeyLastUsed == "bite"):
			incl_post_dom_special_bite_text()

		domSpecialActionKeyLastUsed = "none"
	
	if(domFlirtCooldown == DOM_FLIRT_COOLDOWN_TURNS):
		incl_post_dom_flirt_text()

	if(subResistedTimes == 0):
		var breakFreeStrengthStatRequirement = max( 5, ceil( 0.40 * dom.getStat(Stat.Strength) ) )
		var subHasStrengthStatToBreakFree = ( sub.getStat(Stat.Strength) >= breakFreeStrengthStatRequirement )
		var subHasUnboundArmsAndUnblockedHands = ( !sub.hasBoundArms() && !sub.hasBlockedHands() )
		var subHasStaminaToBreakFree = ( sub.getStamina() >= SUB_STAMINA_COST_BREAK_FREE )

		var ACTION_NAME_BREAK_FREE = "Break free"
		var ACTION_DESC_PREFIX_BREAK_FREE = "[Strength "+ str(breakFreeStrengthStatRequirement) +"+] "
		if(subHasStrengthStatToBreakFree && subHasUnboundArmsAndUnblockedHands && subHasStaminaToBreakFree):
			addAction("immediately_break_free", ACTION_NAME_BREAK_FREE, ACTION_DESC_PREFIX_BREAK_FREE+ "You're more than capable of freeing yourself. Uses " + str(SUB_STAMINA_COST_BREAK_FREE) + " stamina.", "default", -0.01, 60, {})
		elif(!subHasStrengthStatToBreakFree):
			addDisabledAction(ACTION_NAME_BREAK_FREE, ACTION_DESC_PREFIX_BREAK_FREE+ "You lack strength to easily free yourself from their hold.")
		elif(!subHasUnboundArmsAndUnblockedHands):
			addDisabledAction(ACTION_NAME_BREAK_FREE, ACTION_DESC_PREFIX_BREAK_FREE+ "Restraints on your arms prevent you from breaking free.")
		else:
			addDisabledAction(ACTION_NAME_BREAK_FREE, ACTION_DESC_PREFIX_BREAK_FREE+ "You need " + str(SUB_STAMINA_COST_BREAK_FREE) + " stamina to be able to break free.")

	var subLustRatio = getSubLustRatio()
	var subResistProbability = 4.0 - min(subLustRatio * 5.0, 3.5)

	var staminaUseInformation = " Uses 5 stamina." if(!subWasPinnedToTheGround) else ""
	addAction("resist", "Resist", ("Try to resist." + staminaUseInformation), "default", subResistProbability, 60, {})

	if(subResistedTimes >= 1):
		if(!subWasPinnedToTheGround):
			addAction("remain_still", "Stand still", "Try to replenish some stamina.", "default", 1.0, 60, {})
		else:
			addAction("remain_still", "Lay still", "Remain helplessly pinned down.", "default", 1.0, 60, {})

	if(subResistedOrSoftenedTimes >= 3):
		var wasClothingRemoved = (subWasUndressed || domWasUndressed)
		var isAbleToRubInReturn = !subWasPinnedToTheGround
		var haveRubbedDomButIntentWasUnclear = (subRubbedAgainstDomTimes == 1)

		var subInterestInAnalSexGiving:float = subPawn.scoreFetishMax({ Fetish.AnalSexGiving: 1.0 })
		var subDislikesAnalSexGiving:bool = subInterestInAnalSexGiving <= -0.5

		if(!subConsentedToUndressing):
			var subRemoveClothesBegProbability = max( ( 1.0 * ( getSubLustRatio() - 0.50 ) ), -0.01 ) if(!haveRubbedDomButIntentWasUnclear || !isAbleToRubInReturn) else -0.01

			if(domRefusedUndressingRequestTimes > 0):
				subRemoveClothesBegProbability = 2.0

			addAction("beg_for_clothes_removal", "Beg: Feel them", "Beg them to get clothes out of the way.", "default", subRemoveClothesBegProbability, 60, {})
		elif(wasClothingRemoved):
			var subAnalSexReceivingBegProbability = max( ( 1.0 * ( getSubLustRatio() - 0.80 ) ), -0.01 )
			var subAnalSexGivingBegProbability = -0.01 if( getSubAnalSexReceivingPossible() ) else subAnalSexReceivingBegProbability

			if(domRefusedPenetrationRequestTimes > 0):
				subAnalSexReceivingBegProbability = 2.0

			if(domWasCaptivatedBySubPenis && !subDislikesAnalSexGiving):
				subAnalSexGivingBegProbability = subAnalSexReceivingBegProbability
				subAnalSexReceivingBegProbability = 0.2 * subAnalSexReceivingBegProbability

			if( getSubAnalSexReceivingPossible() ):
				addAction("beg_for_anal_sex_receiving", "Beg: Fuck me", "Beg them to penetrate your anal ring.", "default", subAnalSexReceivingBegProbability, 60, {})
			else:
				addDisabledAction("Beg: Fuck me", "This interaction doesn't seem to be possible.")

			if( !domRefusedAnalSexReceiving && getSubAnalSexGivingPossible() ):
				addAction("beg_for_anal_sex_giving", "Ask: Ride me", "Beg them to ride your cock.", "default", subAnalSexGivingBegProbability, 60, {})
			elif(!domRefusedAnalSexReceiving):
				addDisabledAction("Ask: Ride me", "This interaction doesn't seem to be possible.")
			else:
				addDisabledAction("Ask: Ride me", "They are not interested.")

			if( !getSubAnalSexReceivingPossible() && !getSubAnalSexGivingPossible() ):
				var subSurrenderProbability = max( ( 1.0 * ( getSubLustRatio() - 0.80 ) ), -0.01 )
				addAction("surrender", "Surrender", "They cannot fuck or ride you, but you don't mind having some fun.", "default", subSurrenderProbability, 60, {})

		if(isAbleToRubInReturn):
			if( !subConsentedToUndressing || wasClothingRemoved ):
				var subRubAgainstDomProbability = max( ( 1.0 * ( getSubLustRatio() - ( 0.80 if(subConsentedToUndressing) else 0.50 ) ) ), -0.01 )

				if(haveRubbedDomButIntentWasUnclear):
					subRubAgainstDomProbability = 2.0

				if(domWasCaptivatedBySubPenis && !subDislikesAnalSexGiving):
					subRubAgainstDomProbability = 0.2 * subRubAgainstDomProbability

				addAction("rub_against_dom", "Rub in return", "Use body language to encourage them to be more greedy with you.", "default", subRubAgainstDomProbability, 60, {})

	if( (subResistedTimes == 0) && sub.isPlayer() ):
		var spacerActionsCount = 4 - actionBuffer.size()
		for n in spacerActionsCount:
			addDisabledAction( "", getSpacerText() if((n + 1) == spacerActionsCount) else "" )

		addAction("mod_settings", "Mod Settings", "Configure SneakUpTease mod.", "default", -0.01, 60, {})

func init_do(_id:String, _args:Dictionary, _context:Dictionary):
	var sub = getRoleChar("sub")

	if(subSnarkCooldown > 0):
		subSnarkCooldown -= 1

	if(domFlirtCooldown > 0):
		domFlirtCooldown -= 1

	if(domSpecialActionCooldown > 0):
		domSpecialActionCooldown -= 1

	if(_id == "immediately_break_free"):
		sub.addStamina(-SUB_STAMINA_COST_BREAK_FREE)
		affectAffection("dom", "sub", -0.1)
		setState("immediately_broke_free", "sub")
	elif(_id == "resist"):
		if(!subWasPinnedToTheGround):
			sub.addStamina(-5)

		subResistedTimes += 1

		if( !isSubWaitingOnDom() && !isSubHesitating() ):
			subResistedWhileNotWaitingOrHesitatingTimes += 1

		var subShouldMakeSnarkyComment = (
				(subBrattinessRatio > 0.8)
			&& ( getSubLustRatio() < 0.5 )
			&& !subConsentedToUndressing
			&& (subResistedTimes >= 2)
			&& (subSnarkUsedTimes < 3)
			&& (subSnarkCooldown == 0)
			&& RNG.chance(40)
		)

		if(subShouldMakeSnarkyComment):
			subSnarkUsedTimes += 1
			subSnarkCooldown = SUB_SNARK_COOLDOWN_TURNS

		var hasSubRanOutOfStamina = ( sub.getStamina() < 1 )

		if(hasSubRanOutOfStamina && !subWasPinnedToTheGround):
			setState("ran_out_of_stamina", "sub")
		else:
			setState("after_sub_resisted", "dom")
	elif(_id == "remain_still"):
		recoverSubStamina()

		subSoftenedTimes += 1

		if( isSubWaitingOnDom() ):
			subSoftenedWhileWaitingTimes += 1

		var hasSubRanOutOfPatienceWaitingOnDom = (subSoftenedWhileWaitingTimes >= SUB_MAX_WAITING_ON_DOM_TURNS)

		if(hasSubRanOutOfPatienceWaitingOnDom):
			setState("ran_out_of_patience", "sub")
		else:
			setState("after_sub_softened", "dom")
	elif(_id == "beg_for_clothes_removal"):
		var hasDomRefusedRequest = false

		if(domRefusedUndressingRequestTimes == 0):
			hasDomRefusedRequest = ( sub.isGagged() || RNG.chance(20) )
		elif(domRefusedUndressingRequestTimes == 1):
			hasDomRefusedRequest = RNG.chance(10)

		if(hasDomRefusedRequest):
			domRefusedUndressingRequestTimes += 1
		else:
			domRefusedUndressingRequestTimes = -1
			subConsentedToUndressing = true

		setState("begged_for_clothes_removal", "dom")
	elif(_id == "beg_for_anal_sex_receiving"):
		var hasDomRefusedRequest = false

		if(domRefusedPenetrationRequestTimes == 0):
			hasDomRefusedRequest = ( sub.isGagged() || RNG.chance(20) )
		elif(domRefusedPenetrationRequestTimes == 1):
			hasDomRefusedRequest = RNG.chance(10)

		if(hasDomRefusedRequest):
			domRefusedPenetrationRequestTimes += 1
		else:
			domRefusedPenetrationRequestTimes = -1
			subConsentedToAnalSexReceiving = true

		setState("begged_for_anal_sex_receiving", "dom")
	elif(_id == "beg_for_anal_sex_giving"):
		domRefusedPenetrationRequestTimes = -1
		setState("asked_for_something_else", "dom")
	elif(_id == "surrender"):
		domRefusedPenetrationRequestTimes = -1
		setState("asked_for_something_else", "dom")
	elif(_id == "rub_against_dom"):
		var isSubAnalSexReceivingPossible = getSubAnalSexReceivingPossible()

		subRubbedAgainstDomTimes += 1

		if(!subConsentedToUndressing):
			# Attempting to consent to undressing

			var haveRubbedDomButIntentWasUnclear = (subRubbedAgainstDomTimes >= 2)

			if( haveRubbedDomButIntentWasUnclear || RNG.chance(50) ):
				domRefusedUndressingRequestTimes = -1
				subConsentedToUndressing = true
		else:
			# Consenting to penetration, or initiating a request for something else

			domRefusedPenetrationRequestTimes = -1

			if(isSubAnalSexReceivingPossible):
				subConsentedToAnalSexReceiving = true

		setState("rubbed_against_dom", "dom")
	elif(_id == "mod_settings"):
		setState("mod_settings", "sub")


func after_sub_resisted_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	var both_youThem = "you" if( isPlayerInvolved() ) else "them"
	var both_You_reThey_re = "You're" if( isPlayerInvolved() ) else "They're"
	var dom_youHave = "have" if dom.isPlayer() else "{dom.has}"
	var sub_you_reHe_s = "you're" if sub.isPlayer() else ( "they're" if ( sub.heShe() == "they" ) else "{sub.he}'s" )

	var possible = []
	
	var isFirstNonSkippableResist = (subResistedTimes <= 1)

	if(isFirstNonSkippableResist):
		possible.append_array([
			"{sub.You} {sub.youVerb('try', 'tries')} to struggle out of {dom.your} grip, but it's no use. {dom.You} {dom.youVerb('hold')} {sub.youHim} tight, like an animal that has just caught its prey.",
			"{sub.You} {sub.youVerb('attempt')} to wiggle {sub.yourHis} way out, but {sub.youVerb('end')} up rubbing {sub.yourHis} soft butt all over {dom.your} crotch, which makes {dom.youHim} grip {sub.youHim} even tighter.",
		])
	elif(!subWasPinnedToTheGround):
		# Standing

		if( !dom.isGagged() && !dom.isMuzzled() ):
			# Uses tongue
			possible.append_array([
				"{sub.You} {sub.youVerb('keep')} struggling, hoping to catch an opportune moment to break free. {dom.You} only {dom.youVerb('pull')} {sub.youHim} closer in, and {dom.youVerb('proceed')} to give {sub.yourHis} neck a prolonged lick.",
			])

		if( !dom.isGagged() ):
			# Grins
			possible.append_array([
				"{sub.You} {sub.youVerb('try', 'tries')} to shove {dom.you} away, but with hands behind {sub.yourHis} back it proves to be difficult. There's a momentary grin on {dom.yourHis} face, but {sub.youHe} could only guess the emotions that run through it.",
			])

		possible.append_array([
			"{sub.You} {sub.youVerb('gather')} some energy to pull away in one swift motion, but {dom.you} {dom.youVerb('notice')} {sub.youHim} lean in anticipation, and immediately {dom.youVerb('pull')} {sub.youHim} back in.",
			"{sub.You} {sub.youVerb('shuffle')} from one side to the other, but {dom.you} still {dom.youVerb('hold')} {sub.youHim} dearly, like {dom.yourHis} most prized possession.",
			"{sub.You} furiously {sub.youVerb('step')} on {dom.your} "+RNG.pick(["left", "right"])+" foot. {dom.YouHe} {dom.youVerb('find')} it kind of cute.",
			"{sub.You} {sub.youVerb('nudge')} {sub.yourHis} whole body to the "+RNG.pick(["left", "right"])+", causing both of "+ both_youThem +" to turn slightly. "+ both_You_reThey_re +" now facing towards a different direction, but "+ ( (sub_you_reHe_s + " ") if( !sub.isPlayer() ) else "" ) +"being held just as firm.",
		])
	else:
		# Pinned to the ground

		possible.append_array([
			"{sub.You} {sub.youVerb('try', 'tries')} to get {dom.you} off {sub.youHim}, but {dom.youHe} "+ dom_youHave +" {sub.youHim} pinned really tight and intimate.",
			"{sub.You} {sub.youVerb('try', 'tries')} to shake {dom.you} off, but {dom.youHe} {dom.youAre} laying above {sub.youHim} with all of {dom.yourHis} weight.",
		])

	saynn(RNG.pick(possible))
	
	if(subSnarkCooldown == SUB_SNARK_COOLDOWN_TURNS):
		incl_post_sub_snark_text()
	
	if(!subWasPinnedToTheGround):
		if(subResistedWhileNotWaitingOrHesitatingTimes > SUB_MAX_RESISTING_TURNS_WHEN_STANDING):
			saynn( RNG.pick([
				"Seems this isn't getting anywhere..",
				"Seems this isn't going as planned..",
			]) )

		if( sub.isPlayer() ):
			addMessage("{sub.You} used 5 stamina.")

	incl_after_sub_resisted_or_softened_text()

func after_sub_resisted_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func after_sub_softened_text():
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	var sub_youHave = "have" if sub.isPlayer() else "{sub.has}"
	var sub_youHaven_t = "haven't" if ( sub.isPlayer() || ( sub.hasHave() == "have" ) ) else "hasn't"
	var sub_you_reHe_s = "you're" if sub.isPlayer() else ( "they're" if ( sub.heShe() == "they" ) else "{sub.he}'s" )
	var sub_yourselfThemselves = "yourself" if sub.isPlayer() else "themselves"
	var sub_stand_OR_lay = "stand" if(!subWasPinnedToTheGround) else "lay"
	var sub_youVerb_stand_OR_lay = "{sub.youVerb('stand')}" if(!subWasPinnedToTheGround) else "{sub.youVerb('lay')}"

	var subLustRatio = getSubLustRatio()

	var possible = []

	if(subLustRatio < 0.25):
		if(!subWasPinnedToTheGround):
			possible.append_array([
				"{sub.Your} knees tremble a little bit, but {sub.youHe} {sub.youVerb('remain')} still.",
			])
		else:
			possible.append_array([
				"A shiver runs through {sub.your} body, but {sub.youHe} {sub.youVerb('remain')} laying still.",
			])

		possible.append_array([
			"{sub.You} "+ sub_youVerb_stand_OR_lay +" obediently still, or at least {sub.youVerb('make')} an impression of doing so.",
			"{sub.You} briefly {sub.youVerb('remain')} in {sub.yourHis} current pose, still fueled with resistance, but not yet acting on it.",
			"{sub.You} {sub.youVerb('spend')} some time to consider the options that are available to {sub.youHim}.",
		])
	elif(subLustRatio < 0.50):
		if(!subWasPinnedToTheGround):
			possible.append_array([
				"{sub.You} {sub.youVerb('stand')} still, lightly panting, hoping to recover some stamina for another attempt to free " +sub_yourselfThemselves+ ".",
			])

		possible.append_array([
			"{sub.You} {sub.youVerb('try', 'tries')} to focus on finding a way out of this situation, but it's starting to become.. difficult..",
		])
	else:
		if(!subWasPinnedToTheGround):
			if( sub.getStamina() >= 25 ):
				# Has stamina left to spare
				possible.append_array([
					"{sub.You} still "+ sub_youHave +" stamina left to spare, but "+ sub_you_reHe_s +" beginning to question whether it's better to just.. give in.",
				])

		possible.append_array([
			"{sub.You} {sub.youVerb('get')} lost in the thought, forgetting to struggle for a moment. Whatever's on {sub.yourHis} mind must have been rather.. tempting.",
			"{dom.You} {dom.youVerb('notice')} that {sub.you} "+ sub_youHaven_t +" been resisting as much anymore. {sub.YouHe} still {sub.youVerb('nudge')} away on occasion, but from {sub.yourHis} movements {sub.youHe} {sub.youVerb('seem')}.. rather aroused.",
			"{sub.Your} heart rate grows high as "+ sub_you_reHe_s +" going through all possibilities, but {sub.yourHis} mind fixates imagining every outcome where {sub.youHe} [i]{sub.youVerb('fail')}[/i] to break free..",
			"{sub.Your} mind spirals throughout all kinds of corrupted thoughts, as {sub.youHe} "+ sub_youVerb_stand_OR_lay +" still for a little bit, taking no action to break out.",
			"{sub.Your} will is bordering on a state of disarray, leaving {sub.youHim} to "+ sub_stand_OR_lay +" helpless, even when presented with an opportune moment to break free.",
		])

	saynn(RNG.pick(possible))

	if( subSoftenedWhileWaitingTimes > ceil(0.6 * SUB_MAX_WAITING_ON_DOM_TURNS) ):
		possible = []

		if(subIsMean):
			possible.append_array([
				"{sub.You} {sub.youAre} gradually getting more and more annoyed."
			])
		else:
			possible.append_array([
				"{sub.You} {sub.youAre} slowly starting to lose patience."
			])

		saynn(RNG.pick(possible))

		if( RNG.chance(10) ):
			possible = [
				"Hnn.. Don't keep me waiting now..",
			]

			if(subIsMean):
				possible.append_array([
					"Are we going to do something or what?",
					"Are you just going to stare at me?",
					"You're such a bitch.",
					"I'm waiting!..",
					"I'm letting you have your way, what's the fucking hold up?",
				])
			else:
				possible.append_array([
					"You can do more than just stare..",
					"I'm trying to be patient, but.. y'know..",
				])

			saynn("[say=sub]"+RNG.pick(possible)+"[/say]")
	else:
		var subShouldStammerFromLust = (
				(subLustRatio > 0.5)
			&& RNG.chance(15)
		)

		if(subShouldStammerFromLust):
			possible = [
				"A- Ahh fuck..",
				"F- Fuck..",
				"H- How..",
				"I- I need..",
				"I- I shouldn't..",
				"I- I will not..",
				"W- What have you..",
				"Y- You're..",
			]

			saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	if( sub.isPlayer() && (subStaminaRecovered > 0) ):
		addMessage("{sub.You} recovered " + str(subStaminaRecovered) + " stamina.")

	incl_after_sub_resisted_or_softened_text()

func after_sub_softened_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func incl_after_sub_resisted_or_softened_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domIsMean = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4

	var subResistedOrSoftenedTimes = subResistedTimes + subSoftenedTimes
	var subResistedTimesMax = SUB_MAX_RESISTING_TURNS_WHEN_STANDING if(!subWasPinnedToTheGround) else SUB_MAX_RESISTING_TURNS_TOTAL
	var canRubAgainstSub = (subResistedWhileNotWaitingOrHesitatingTimes <= subResistedTimesMax)

	var canAdvanceToFinale = (
			subConsentedToAnalSexReceiving
		|| subConsentedToAnalSexReceiving
		|| (!canRubAgainstSub && subWasPinnedToTheGround)
	)

	if(canAdvanceToFinale):
		addAction("advance_to_finale", "Advance", "Time for some fun..", "default", 1.0, 60, {})
		return

	if(subConsentedToUndressing):
		if(!subWasUndressed && !domWasUndressed && !sub.isFullyNaked() && !dom.isFullyNaked()):
			addAction("undress_both", "Undress both", "Take off all clothes from both you and the sub.", "default", 100.0, 120, {})
		elif(!subWasUndressed && !sub.isFullyNaked()):
			addAction("undress_sub", "Undress sub", "Take off all their clothes.", "default", 100.0, 60, {})
		elif(!domWasUndressed && !dom.isFullyNaked()):
			addAction("undress_self", "Undress self", "Take off all your clothes.", "default", 100.0, 60, {})

	if(canRubAgainstSub):
		addAction("rub", "Keep rubbing", "Continue rubbing them~", "default", 1.0, 60, {})

		if(!subWasPinnedToTheGround):
			if(subResistedOrSoftenedTimes >= 3 && domSpecialActionCooldown == 0):
				if( !dom.isBitingBlocked() ):
					addAction("special_bite", "Special: Bite", "Chomp on one of their body parts.", "default", 0.7, 60, {})
				else:
					addDisabledAction("Special: Bite", "Restraints on your snout prevent you from doing this.")
	elif(!subWasPinnedToTheGround):
		addAction("pin_down", "Pin down", "Pin them into the ground.", "default", 1.0, 60, {})

	if(!subWasPinnedToTheGround):
		if(!domEasedGripOnce && !subConsentedToUndressing):
			var domEaseGripProbability = 0.1 if ( !domIsMean && (subResistedOrSoftenedTimes >= 2) && (subResistedTimes <= 6) && RNG.chance(20) ) else -0.01
			addAction("ease_grip", "Ease your grip", "Allow them to break free.", "default", domEaseGripProbability, 60, {})
	else:
		addAction("just_leave", "Leave", "You don't feel like doing anything with them.", "default", -0.01, 60, {})

	if( (subResistedOrSoftenedTimes == 1) && dom.isPlayer() ):
		var spacerActionsCount = 4 - actionBuffer.size()
		for n in spacerActionsCount:
			addDisabledAction( "", getSpacerText() if((n + 1) == spacerActionsCount) else "" )

		addAction("mod_settings", "Mod Settings", "Configure SneakUpTease mod.", "default", -0.01, 60, {})

func incl_after_sub_resisted_or_softened_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	if( sub.isPlayer() ):
		# Clear stamina messages for PC sub, since they aren't cleared when choosing the default "Continue" action
		GM.main.clearMessages()

	subStaminaRecovered = 0

	if( _id in ["rub", "special_bite"] ):
		if( dom.getLustLevel() < 0.7 ):
			dom.addLust( int( ceil( 0.05 * dom.lustThreshold() ) ) )
		else:
			dom.addLust(1)

		var subLustRatio = getSubLustRatio()

		if( sub.getLustLevel() < subLustRatio ):
			sub.addLust( int( ceil( subLustRatio * sub.lustThreshold() ) ) - sub.getLust() )

	if(_id == "advance_to_finale"):
		var subPetNames = getPetNames({ species = sub.getSpecies(), heSheThey = sub.heShe() })

		startInteraction("SneakUpFinale", {dom=getRoleID("dom"), sub=getRoleID("sub")}, {
			subConsentedToAnalSexReceiving = subConsentedToAnalSexReceiving,
			subConsentedToAnalSexGiving = subConsentedToAnalSexGiving,
			subWasPinnedToTheGround = subWasPinnedToTheGround,
			subWasUndressed = subWasUndressed,
			subPetNames = subPetNames,
		})
	elif(_id == "undress_both"):
		dom.lustStateFullyUndress()
		domWasUndressed = true
		sub.lustStateFullyUndress()
		subWasUndressed = true
		subSoftenedWhileWaitingTimes = 0
		incl_after_anyone_undressed_do()
		setState("undressed_both", "dom")
	elif(_id == "undress_sub"):
		sub.lustStateFullyUndress()
		subWasUndressed = true
		subSoftenedWhileWaitingTimes = 0
		incl_after_anyone_undressed_do()
		setState("undressed_sub", "dom")
	elif(_id == "undress_self"):
		dom.lustStateFullyUndress()
		domWasUndressed = true
		subSoftenedWhileWaitingTimes = 0
		incl_after_anyone_undressed_do()
		setState("undressed_self", "dom")
	elif(_id == "pin_down"):
		subWasPinnedToTheGround = true
		setState("pinned_after_resisting_too_much", "dom")
	elif(_id == "rub"):
		var subResistedOrSoftenedTimes = subResistedTimes + subSoftenedTimes

		var domShouldFlirt = (
				(subResistedOrSoftenedTimes >= 2)
			&& (domFlirtCooldown == 0)
			&& RNG.chance(40)
		)

		if(domShouldFlirt):
			domFlirtCooldown = DOM_FLIRT_COOLDOWN_TURNS

		setState("", "sub")
	elif(_id == "special_bite"):
		incl_dom_special_bite_do()
	elif(_id == "ease_grip"):
		domEasedGripOnce = true

		subEscapeUponEaseGripProbability = max( ( 1.0 - 2.0 * getSubLustRatio() ), -0.01 )
		var subEscapeUponEaseGripProbabilityInverse:float = 1 - max(subEscapeUponEaseGripProbability, 0.0)

		var subChanceToBeTooFrightenedToEscape:float = (
				100.0
			* (
					subPawn.scorePersonalityMax({ PersonalityStat.Coward: 0.4 })
				+ domPawn.scorePersonalityMax({ PersonalityStat.Mean: 0.2 })
			)
		)

		subIsTooFrightenedToEscape = RNG.chance(subChanceToBeTooFrightenedToEscape)

		var subForcedObedienceRatio:float = clamp( sub.getForcedObedienceLevel(), 0.0, 1.0 )

		if(subForcedObedienceRatio > 0.25):
			domAttemptedToHypnotizeSubUponEaseGrip = true

			if(subIsTooFrightenedToEscape):
				subWasHypnotizedIntoKneeling = RNG.chance(60 * subForcedObedienceRatio)

				if( !subWasHypnotizedIntoKneeling && !sub.isPlayer() ):
					subIntendsToKneel = RNG.chance(subEscapeUponEaseGripProbabilityInverse * 100.0)
			else:
				subWasHypnotizedIntoStandingStill = RNG.chance(80 * subForcedObedienceRatio)

				if( !subWasHypnotizedIntoStandingStill && !sub.isPlayer() ):
					subIntendsToStandStill = RNG.chance(subEscapeUponEaseGripProbabilityInverse * 100.0)

		setState("eased_grip", "sub")
	elif(_id == "just_leave"):
		setState("left_laying_down", "sub")
	elif(_id == "mod_settings"):
		setState("mod_settings", "dom")


func undressed_both_text():
	var creature_stands_OR_lays = "stands" if(!subWasPinnedToTheGround) else "lays"
	var creature_behind_OR_above = "behind" if(!subWasPinnedToTheGround) else "above"
	var sub_youVerb_stand_OR_lay = "{sub.youVerb('stand')}" if(!subWasPinnedToTheGround) else "{sub.youVerb('lay')}"
	var both_yourTheir = "your" if( isPlayerInvolved() ) else "their"

	var possible = [
		"{sub.You} "+ sub_youVerb_stand_OR_lay +" obediently still as {dom.you} {dom.youVerb('begin')} to remove all {dom.yourHis} clothes. {dom.YourHis} paws then proceed to roam all over {sub.your} body, stripping {sub.youHim} of {sub.yourHis} clothing too. Each bit that covered "+ both_yourTheir +" secluded parts is now either messily scattered on the floor, or alluringly hanging around one's ankles.",
		"{sub.You} "+ sub_youVerb_stand_OR_lay +" eagerly still as {dom.you} assertively {dom.youVerb('strip')} {sub.youHim} of {sub.yourHis} clothes. Before {sub.you} {sub.youVerb('manage')} to shake the lust off, {sub.youHe} {sub.youVerb('notice')} that all of {dom.your} clothes are now also scattered on the ground. Positioned "+ creature_behind_OR_above +" {sub.you} "+ creature_stands_OR_lays +" a hot, naked creature.",
	]

	saynn(RNG.pick(possible))

	incl_after_anyone_undressed_text()
	incl_after_sub_resisted_or_softened_text()

func undressed_both_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func undressed_sub_text():
	var dom = getRoleChar("dom")

	var dom_youWere = "were" if ( dom.isPlayer() || ( dom.hasHave() == "have" ) ) else "was"
	var dom_standing_OR_laying = "standing" if(!subWasPinnedToTheGround) else "laying"
	var dom_behind_OR_above = "behind" if(!subWasPinnedToTheGround) else "above"
	var sub_youVerb_stand_OR_lay = "{sub.youVerb('stand')}" if(!subWasPinnedToTheGround) else "{sub.youVerb('lay')}"

	var possible = [
		"{sub.You} "+ sub_youVerb_stand_OR_lay +" obediently still, panting, as {dom.you} {dom.youVerb('remove')} all {sub.yourHis} clothes. {sub.YouHe} {sub.youVerb('struggle')} not to be aroused, as when you press together, {sub.youHe} {sub.youVerb('realize')} that from the very beginning {dom.you} "+ dom_youWere + " "+ dom_standing_OR_laying +" "+ dom_behind_OR_above +" {sub.youHim} fully naked.",
		"{sub.You} {sub.youVerb('do', 'does')} not resist as {dom.you} meticulously {dom.youVerb('remove')} every piece of clothing covering {sub.yourHis} body. {sub.YouHe} {sub.youVerb('notice')} that {dom.you} never had any clothing on {dom.youHim}, and that realization leaves {sub.youHim} a little pent up.",
	]

	saynn(RNG.pick(possible))

	incl_after_anyone_undressed_text()
	incl_after_sub_resisted_or_softened_text()

func undressed_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func undressed_self_text():
	var dom = getRoleChar("dom")

	var dom_You_veHe_s = "You've" if dom.isPlayer() else ( "They've" if ( dom.heShe() == "they" ) else "{dom.He}'s" )
	var sub_youVerb_stand_OR_lay = "{sub.youVerb('stand')}" if(!subWasPinnedToTheGround) else "{sub.youVerb('lay')}"

	var possible = [
		"{dom.You} quickly {dom.youVerb('remove')} {dom.yourHis} clothes as {sub.you} "+ sub_youVerb_stand_OR_lay +" eagerly still. "+ dom_You_veHe_s +" been glaring at {sub.yourHis} exposed body for a very long time, mind drifting in the thought of all the things {dom.youHe}'d want to do to {sub.youHim}.",
	]

	saynn(RNG.pick(possible))

	incl_after_anyone_undressed_text()
	incl_after_sub_resisted_or_softened_text()

func undressed_self_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func incl_after_anyone_undressed_do():
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	if( !getSubAnalSexGivingPossible() || sub.isBodypartCovered(BodypartSlot.Penis) ):
		return

	var domInterestInAnalSexReceiving = domPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })
	var domLikesAnalSexReceiving = domInterestInAnalSexReceiving >= 0.5

	if(!domLikesAnalSexReceiving):
		return

	var domInterestInAnalSexGiving = domPawn.scoreFetishMax({ Fetish.AnalSexGiving: 1.0 })
	var chanceToBeCaptivatedBySubPenis:float = 40.0 + clamp( (-domInterestInAnalSexGiving * 40.0), 0.0, 30.0 )

	if( !RNG.chance(chanceToBeCaptivatedBySubPenis) ):
		return

	domWasCaptivatedBySubPenis = true

func incl_after_anyone_undressed_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	if(!domWasCaptivatedBySubPenis):
		return

	var dom_you_veHe_s = "you've" if dom.isPlayer() else ( "they've" if ( dom.heShe() == "they" ) else "{dom.he}'s" )
	var sub_penis = "{sub.penisDesc} "+ RNG.pick(["cock", "dick", "member"])

	var subIsFullyNaked:bool = isCharFullyNaked(sub)

	var possible = [
		"{dom.You} teasingly {dom.youVerb('brush', 'brushes')} the tip of {sub.your} "+ sub_penis +", before returning to {sub.yourHis} wrists.",
	]

	if(subWasUndressed):
		if( !dom.isBlindfolded() ):
			possible.append_array([
				"After getting {sub.you} "+( "fully naked" if(subIsFullyNaked) else "to reveal more of {sub.yourHis} naked body" )+", {dom.you} {dom.youVerb('take')} a moment to admire {sub.yourHis} "+ sub_penis +".",
				"With clothes out of the way, {dom.you} {dom.youVerb('catch', 'catches')} sight of {sub.your} aroused "+ sub_penis +" swaying in the light.",
			])
	else:
		if( !dom.isBlindfolded() ):
			possible.append_array([
				"{sub.You} {sub.youVerb('notice')} {dom.your} eyes briefly fixating on {sub.yourHis} "+ sub_penis +", before {dom.youHe} {dom.youVerb('look')} away, conscious of the fact "+ dom_you_veHe_s +" been staring far longer than {dom.youHe} thought.",
			])

	saynn(RNG.pick(possible))


func begged_for_clothes_removal_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	var subPersonalitySubbyScore = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var subIsSubby = subPersonalitySubbyScore > 0.4

	var clothing_theYourHis = "the"
	var clothing_theYourMy = "the"

	if( !subWasUndressed && !domWasUndressed && !sub.isFullyNaked() && !dom.isFullyNaked() ):
		clothing_theYourHis = "the"
		clothing_theYourMy = "the"
	elif( !subWasUndressed && !sub.isFullyNaked() ):
		clothing_theYourHis = "{sub.yourHis}"
		clothing_theYourMy = "my"
	elif( !domWasUndressed && !dom.isFullyNaked() ):
		clothing_theYourHis = "{dom.your}"
		clothing_theYourMy = "your"

	var possible = [
		"{sub.You} {sub.youVerb('pant')}, craving intimate touch, but needing "+ clothing_theYourHis +" clothing to be out of the way first.",
	]
	
	if(subIsSubby):
		possible.append_array([
			"{sub.You} {sub.youVerb('whine')}, lusting for a more intimate contact, unobstructed by "+ clothing_theYourHis +" clothing.",
		])

	saynn(RNG.pick(possible))

	var hasDomRefusedRequest = !subConsentedToUndressing
	var speechComprehensibility = "bad" if( hasDomRefusedRequest && sub.isGagged() ) else "good"

	possible = [
		"F- Fuck.. I need to feel you.",
		"F- Fuck.. Get rid of "+ clothing_theYourMy +" clothes already.",
		"Go ahead, take "+ clothing_theYourMy +" clothes off.",
	]

	if(subIsMean):
		possible.append_array([
			"Hnnf.. Take "+ clothing_theYourMy +" fucking clothes off.",
			"Hh.. Take "+ clothing_theYourMy +" clothes off before I lose my temper.",
		])

		if(clothing_theYourMy == "your"):
			possible.append_array([
				"Why the fuck are you still dressed?",
				"Strip for me, service slut.",
				"You better not be wearing any underwear when I get a good look at you.",
			])
	else:
		var compositeEnding = ""

		if(clothing_theYourMy == "the"):
			compositeEnding = RNG.pick([
				"Let's lose the clothes, please..",
				"I want our bodies pressed together, with nothing between us but fur..",
			])
		elif(clothing_theYourMy == "my"):
			compositeEnding = RNG.pick([
				"Help me lose my clothes..",
				"Could you strip me fully, please..",
			])
		elif(clothing_theYourMy == "your"):
			compositeEnding = RNG.pick([
				"Would you undress for me?",
				"Strip for me, would you?..",
			])
			
		possible.append_array([
			"I w- want to feel every inch of your body.. "+ compositeEnding,
			"F- Fuck, you're making me crave more of you.. "+ compositeEnding,
			"Would you take "+ clothing_theYourMy +" clothes off, please..",
			"Want to take a closer look?",
		])

		if(!subIsSubby):
			possible.append_array([
				"I- I did not expect to be so much into this.. Would you care to get "+ clothing_theYourMy +" clothes out of the way?",
			])

	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	if(hasDomRefusedRequest):
		incl_dom_refuse_request_text({ speechComprehensibility = speechComprehensibility })

	incl_after_sub_resisted_or_softened_text()

func begged_for_clothes_removal_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func begged_for_anal_sex_receiving_text():
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4
	var subIsKind = subPersonalityMeanScore < -0.4

	var subPersonalitySubbyScore = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var subIsSubby = subPersonalitySubbyScore > 0.4

	var possible = [
		"{sub.You} {sub.youVerb('pant')} heavily, unable to resist giving in to the lustful desire.",
		"{sub.You} {sub.youVerb('pant')} heavily, visibly helpless against the lustful thoughts permeating {sub.yourHis} mind.",
	]

	if(subIsSubby):
		possible.append_array([
			"{sub.Your} "+ ( "legs tremble" if(!subWasPinnedToTheGround) else "body trembles" ) +" as {sub.youHe} {sub.youVerb('start')} to find it futile to resist the temptation.",
		])

	saynn(RNG.pick(possible))
	
	var hasDomRefusedRequest = !subConsentedToAnalSexReceiving
	var speechComprehensibility = ( "awful" if( RNG.chance(5) ) else "bad" ) if( hasDomRefusedRequest && sub.isGagged() ) else "good"

	possible = []

	if(speechComprehensibility == "awful"):
		if(subIsMean):
			possible.append_array([
				"Start penetrating my ring already, I have no interest in wasting personal leisure time for the likes of you.",
				"What the fuck are you waiting for, the perfect time to insert your member was a good thirty minutes ago.",
			])
		else:
			possible.append_array([
				"Still hesitating? How about we get to the thirsty part where you send your little slut whining?",
				"Let's carry this a step further, I'd really like to spend the next hour exhausted, whimpering for you alone."
			])
	elif(speechComprehensibility == "bad"):
		if(subIsMean):
			possible.append_array([
				"I'm not your personal slut to wait on you all day, go on..",
				"I've had enough of rubbing for the rest of the week, how about we proceed to the real deal.",
			])
		else:
			possible.append_array([
				"Now you've made me really needy.. There's only so much I can resist your alluring figure.",
			])

		if(subIsKind):
			possible.append_array([
				"You are more than welcome to nudge it in, sweetheart.",
			])
	else:
		if(subIsMean):
			possible.append_array([
				"Fuck me already.",
			])
		else:
			possible.append_array([
				"Please f- fuck me.",
				"I need you in me..",
				"Please go ahead..",
			])
		
		if(subIsSubby):
			possible.append_array([
				"I- I need you in me so bad..",
				"P- Please make me your personal fucktoy..",
			])

		if( !hasDomRefusedRequest && domHasUsedFlirtLineByAlias.has("glazed_donut") ):
			possible.append_array([
				"What was that about a glazed donut?~"
			])

	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	if(hasDomRefusedRequest):
		incl_dom_refuse_request_text({ speechComprehensibility = speechComprehensibility })

	incl_after_sub_resisted_or_softened_text()

func begged_for_anal_sex_receiving_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func rubbed_against_dom_text():
	var sub = getRoleChar("sub")
	#var subPawn = getRolePawn("sub")

	var sub_youHave = "have" if sub.isPlayer() else "{sub.has}"

	#var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	#var subIsMean = subPersonalityMeanScore > 0.4
	#var subIsKind = subPersonalityMeanScore < -0.4

	#var subPersonalitySubbyScore = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	#var subIsSubby = subPersonalitySubbyScore > 0.4
	#var subIsDommy = subPersonalitySubbyScore < -0.4

	var possible = []

	var isConsentingToUndress = (domRefusedPenetrationRequestTimes != -1)
	var isConsentingToUndressButIntentUnclear = ( isConsentingToUndress && !subConsentedToUndressing )
	var isConsentingToUndressWhichWasUnclearLastTime = ( isConsentingToUndress && (subRubbedAgainstDomTimes == 2) )
	var isConsentingToToAnalSexReceiving = subConsentedToAnalSexReceiving

	if(isConsentingToUndressButIntentUnclear):
		possible.append_array([
			"{dom.You} {dom.youVerb('feel')} like {sub.you} "+ sub_youHave +" just rubbed {dom.youHim} in return, though it might have been wishful thinking, so {dom.youHe} {dom.youVerb('do', 'does')} not assign much value to that.",
			"{dom.You} {dom.youVerb('get')} an impression that {sub.you} {sub.youAre} impulsively brushing {sub.yourHis} buttcheeks against {dom.yourHis} crotch. There's a good chance that it was a mere coincidence.. {dom.You} {dom.youVerb('decide')} to leave it at that, for now.",
		])
	elif(isConsentingToUndressWhichWasUnclearLastTime):
		possible.append_array([
			"{dom.You} {dom.youVerb('notice')} {sub.you} [color="+ getSensationColor("comfort") +"]rubbing {sub.youHis} buttchecks against {dom.youHim}[/color] again, this time it's evident how much {sub.you} {sub.youVerb('want')} {dom.youHim} to strip all the clothes.",
		])
	elif(isConsentingToUndress):
		possible.append_array([
			"{dom.You} {dom.youVerb('catch', 'catches')} {sub.you} [color="+ getSensationColor("comfort") +"]rubbing {sub.youHis} buttchecks against {dom.youHim}[/color], assuredly expressing {sub.yourHis} desire to drop the clothing and allow the duo to feel each other more intimately.",
		])
	elif(isConsentingToToAnalSexReceiving):
		possible.append_array([
			"{sub.You} [color="+ getSensationColor("comfort") +"]needily {sub.youVerb('rub')} {sub.yourHis} buttchecks against {dom.you}[/color], begging {dom.youHim} to enter {sub.youHim}. {sub.YouHe} {sub.youVerb('do', 'does')} not let any words leave {sub.yourHis} mouth, delegating everything to the body language. Even so, {sub.yourHis} intent and desires are clear.",
			"{sub.You} [color="+ getSensationColor("comfort") +"]cravingly {sub.youVerb('brush', 'brushes')} {sub.yourHis} buttchecks against {dom.you}[/color], imploring {dom.youHim} to penetrate {sub.yourHis} hole. Despite no words having been exchanged, {sub.yourHis} motivation was conveyed well, leaving {dom.you} a little pent up in excitement.",
		])
	else:
		possible.append_array([
			"{sub.You} [color="+ getSensationColor("comfort") +"]needily {sub.youVerb('rub')} against {dom.you}[/color], wondering if {dom.youHe} would be open to something else.",
		])

	if( possible.size() > 0 ):
		saynn(RNG.pick(possible))

	if(isConsentingToUndress || isConsentingToToAnalSexReceiving):
		incl_after_sub_resisted_or_softened_text()
	else:
		addAction("ask_for_something_else", "Continue", "See what happens next..", "default", 1.0, 60, {})

func rubbed_against_dom_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "ask_for_something_else"):
		domRefusedPenetrationRequestTimes = -1
		setState("asked_for_something_else", "dom")
		return

	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func asked_for_something_else_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	var subInterestInAnalSexGiving:float = subPawn.scoreFetishMax({ Fetish.AnalSexGiving: 1.0 })
	var subDislikesAnalSexGiving:bool = !sub.isPlayer() && (subInterestInAnalSexGiving <= -0.5)
	var subOfferingToRideThem:bool = ( getSubAnalSexGivingPossible() && !subDislikesAnalSexGiving )

	var reasonSubUnableToAnalSexReceive = getReasonCharCannotPartakeInAnalSexReceiving(sub, "sub")
	var reasonDomUnableToAnalSexGive = getReasonCharCannotPartakeInAnalSexGiving(dom, "dom")

	var possible = []

	if( domWasCaptivatedBySubPenis && subOfferingToRideThem && (reasonSubUnableToAnalSexReceive == null) ):
		var sub_penis = RNG.pick(["cock", "dick", "member"])
		var sub_canine_penis = "{sub.penisDesc} "+ sub_penis

		possible.append_array([
			"Mmmh, my cock has certainly caught your interest.. Want to get more intimate with it?",
			"You've been rubbing my butt quite a lot, but you can't hide just how much you're craving to be stuffed~",
		])

		if(subIsMean):
			if( !sub.isBlindfolded() && !dom.isBlindfolded() ):
				possible.append_array([
					"Can't get your eyes off my "+ sub_penis +", huh? A slut like you should do more than just stare.",
				])

			possible.append_array([
				"You can pretend you want to fill me up, but it's really you who wants to be dripping for hours on end. Admit it, whore, and maybe I'll consider making it your reality.",
			])
		else:
			if( !sub.isBlindfolded() && !dom.isBlindfolded() ):
				possible.append_array([
					"I've seen you staring~.. I'd love to watch your hips tremble as you're riding me.. If that's what you want, of course.",
				])

			if( !sub.isBlindfolded() ):
				possible.append_array([
					"You look like you're just craving to be filled.. I wouldn't say no to that~",
				])

			possible.append_array([
				"You seem quite interested in my "+ sub_penis +", teehee. Want to take it in?~",
				"I couldn't help but notice how much attention you've been paying to my "+ sub_canine_penis +".. Want to have it all to yourself?",
				"You seem to be liking my "+ sub_canine_penis +" quite a bit.. Want to take it for a ride?~",
			])
	else:
		var sexIncompatibilities = ""

		if(reasonSubUnableToAnalSexReceive != null):
			sexIncompatibilities += (reasonSubUnableToAnalSexReceive + " ")
		
		if(reasonDomUnableToAnalSexGive != null):
			sexIncompatibilities += (reasonDomUnableToAnalSexGive + " ")

		if(sexIncompatibilities == ""):
			if(subIsMean):
				sexIncompatibilities += RNG.pick([
					"Tell you what, slut..",
					"I have something better in mind for a bitch like you..",
				]) + " "
			else:
				sexIncompatibilities += RNG.pick([
					"You're really hot, but I was hoping for something else..",
					"Hnn.. I love feeling you like this, but I would like to try something different..",
				]) + " "

		if(subOfferingToRideThem):
			possible.append_array([
				sexIncompatibilities +"Would you like to ride my "+ RNG.pick(["cock", "dick", "member"]) +" instead?",
			])
		else:
			possible.append_array([
				sexIncompatibilities +"Would you like to have some fun with me instead?",
			])

	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	if(subOfferingToRideThem):
		var domInterestInAnalSexReceiving = domPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })
		
		var probabilityToAgreeToAnalSexReceiving = 1.0
		
		if(domInterestInAnalSexReceiving <= -0.5):
			probabilityToAgreeToAnalSexReceiving = -0.01
		elif(domInterestInAnalSexReceiving <= 0.0):
			probabilityToAgreeToAnalSexReceiving = 2.0
		elif(domInterestInAnalSexReceiving <= 0.5):
			probabilityToAgreeToAnalSexReceiving = 50.0
		else:
			probabilityToAgreeToAnalSexReceiving = 1000.0

		addAction("agree_to_ride_sub", "Agree", "You would like to ride their cock.", "default", probabilityToAgreeToAnalSexReceiving, 60, {})
		addAction("refuse_to_ride_sub", "Refuse", "You're not interested in riding their cock.", "default", 1.0, 60, {})
	else:
		addAction("agree_to_play_with_sub", "Agree", "At the very least, you would like to play with them.", "default", 1.0, 60, {})
		addDisabledAction("Refuse", "You kept them waiting for so long, don't leave now..")

func asked_for_something_else_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "agree_to_ride_sub"):
		subConsentedToAnalSexGiving = true
		setState("agreed_to_something_else", "dom")
	elif(_id == "refuse_to_ride_sub"):
		domRefusedAnalSexReceiving = true
		setState("refused_something_else", "dom")
	elif(_id == "agree_to_play_with_sub"):
		setState("agreed_to_something_else", "dom")


func agreed_to_something_else_text():
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4
	var domIsKind = domPersonalityMeanScore < -0.4

	var possible = [
		"{dom.You} {dom.youVerb('nod')}."
	]

	saynn(RNG.pick(possible))

	var hasDomAgreedToAnalSexReceiving = subConsentedToAnalSexGiving

	if( RNG.chance(50) ):
		possible = [
			"Sure.",
			"I couldn't pass an opportunity like that.",
			"Sounds gay, I'm in.",
			"I'm already excited about what that entails..",
			"Would you be surprised if I said yes?",
		]

		if(hasDomAgreedToAnalSexReceiving):
			if(domIsMean):
				possible.append_array([
					"You think you can satisfy me?",
				])
			elif(domIsKind):
				possible.append_array([
					"Not quite what I expected.. But I couldn't say no to a cutie like you.",
				])
		else:
			possible.append_array([
				"That's what I'm here for.",
			])

		saynn("[say=dom]"+RNG.pick(possible)+"[/say]")

	addAction("advance_to_finale", "Advance", "Time for some fun..", "default", 1.0, 10, {})

func agreed_to_something_else_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func refused_something_else_text():
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4
	#var domIsKind = domPersonalityMeanScore < -0.4

	var possible = [
		"{dom.You} {dom.youVerb('shake')} head."
	]

	saynn(RNG.pick(possible))

	if( RNG.chance(50) ):
		var domInterestInAnalSexReceiving = domPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })
		var domDislikesAnalSexReceiving = domInterestInAnalSexReceiving < -0.5

		possible = []

		if(domIsMean):
			possible.append_array([
				"I'm going to pass on that.",
				"That's not going to work with me.",
				"I'm good, thanks.",
			])
		else:
			possible.append_array([
				"Not quite what I'm looking for, sorry..",
				"Sorry, that wasn't what I had in mind."
			])

			if(domDislikesAnalSexReceiving):
				possible.append_array([
					"I'm not really into that, sorry..",
					"Not really my thing, sorry.."
				])
			else:
				possible.append_array([
					"Not in the right mood for that, sorry..",
					"Sorry, perhaps some other time.."
				])

		saynn("[say=dom]"+RNG.pick(possible)+"[/say]")

	var haveExhaustedAllPossibleOptions = !getSubAnalSexReceivingPossible()

	if(haveExhaustedAllPossibleOptions):
		addAction("advance_to_finale", "Advance", "Time for some fun..", "default", 1.0, 10, {})
	else:
		incl_after_sub_resisted_or_softened_text()

func refused_something_else_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func ran_out_of_patience_text():
	var sub = getRoleChar("sub")

	var sub_youHave = "have" if sub.isPlayer() else "{sub.has}"

	var possible = [
		"{sub.You} "+ sub_youHave +" ran out of patience.",
	]

	saynn(RNG.pick(possible))

	addAction("break_free", "Break free", "Your discontent revealed the strength to free yourself.", "default", 1, 60, {})

func ran_out_of_patience_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "break_free"):
		setState("broke_free_after_running_out_of_patience", "sub")


func broke_free_after_running_out_of_patience_text():
	var dom = getRoleChar("dom")
	var subPawn = getRolePawn("sub")

	var subIsMean = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4

	var dom_youHave = "have" if dom.isPlayer() else "{dom.has}"

	var possible = []

	if(subIsMean):
		possible.append_array([
			"Fuck off.",
			"I've had enough of you wasting my time.",
			"What a waste of time.",
		])
	else:
		possible.append_array([
			"Sorry, I can only wait on you for so long..",
		])

	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	possible = []

	if(subWasPinnedToTheGround):
		possible.append_array([
			"{sub.You} {sub.youVerb('sigh')}, amassing all {sub.yourHis} strength to roll {dom.you} off {sub.yourHis} back and underneath {sub.yourself}.",
		])
	else:
		possible.append_array([
			"{sub.You} {sub.youVerb('manage')} to find the strength to buck into {dom.you} with {sub.yourHis} sturdy spine.",
		])

	saynn(RNG.pick(possible))

	possible = []

	if(subWasPinnedToTheGround):
		possible.append_array([
			"{dom.You} "+ dom_youHave +" lost {dom.yourHis} advantage.",
		])
	else:
		possible.append_array([
			"{dom.You} {dom.youVerb('lose')} balance, sprawling to the floor.",
		])

	saynn(RNG.pick(possible))

	addAction("leave", "Leave", "Leave them be.", "default", 1.0, 0, {})

func broke_free_after_running_out_of_patience_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		var domPawn = getRolePawn("dom")
		domPawn.afterLostFight()
		resetLustState()
		stopMe()


func ran_out_of_stamina_text():
	var sub = getRoleChar("sub")

	var possible = [
		"{sub.Your} spirit is still strong, but {sub.yourHis} body cannot sustain standing like this. {sub.YourHis} knees give in, causing {sub.youHim} to kneel.",
		"With no stamina left in {sub.you} to stand still, all {sub.youHe} can do is watch {sub.yourself} sink down on {sub.yourHis} weakened knees.",
		"Unable to endure standing on {sub.yourHis} feet any longer, {sub.you} {sub.youVerb('succumb')} to exhaustion, falling to {sub.yourHis} knees.",
	]

	saynn(RNG.pick(possible))

	if(sub.isPlayer()):
		addMessage("{sub.You} used up all of your remaining stamina.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func ran_out_of_stamina_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		subWasPinnedToTheGround = true
		setState("pinned_after_kneeling_or_running_out_of_stamina", "dom")


func pinned_after_kneeling_or_running_out_of_stamina_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	var dom_yourselfHimself = "yourself" if dom.isPlayer() else "{dom.himself}"
	var sub_yoursHis = "yours" if sub.isPlayer() else ( "theirs" if ( sub.heShe() == "they" ) else "{sub.his}" )

	var possible = [
		"Seeing {sub.you} so vulnerable, {dom.your} eyes glimmer, and {dom.youHe} ravenously {dom.youVerb('push', 'pushes')} {sub.you} forward, pinning {sub.youHim} down underneath.",
		"{dom.You} readily {dom.youVerb('shove')} {sub.you} forward, positioning "+ dom_yourselfHimself +" tightly pinned above {sub.youHim}.",
		"{dom.You} playfully {dom.youVerb('drag')} {sub.you} even further down into the ground, pressing {dom.yourHis} entire body above "+ sub_yoursHis +".",
	]

	saynn(RNG.pick(possible))

	incl_after_sub_resisted_or_softened_text()

func pinned_after_kneeling_or_running_out_of_stamina_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func pinned_after_resisting_too_much_text():
	var dom = getRoleChar("dom")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4
	var domIsKind = domPersonalityMeanScore < -0.4

	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4

	var dom_youHave = "have" if dom.isPlayer() else "{dom.has}"

	var possible = [
		"{dom.You} "+ dom_youHave +" gotten rather impatient from {sub.your} stubbornness. {dom.YouHe} hastily {dom.youVerb('shove')} {sub.youHim} forward, causing {sub.youHim} to lose balance and fall down on {sub.yourHis} chest. {dom.YouHe} then {dom.youVerb('pounce')} at {sub.you}, pinning {sub.youHim} down helpless.",
		"Seeing that {sub.you} {sub.youVerb('keep')} resisting to no end, {dom.you} {dom.youVerb('conclude')} that {dom.youHe}'d allowed {sub.youHim} more power than {sub.youHe} truly {sub.youVerb('deserve')}. {dom.YouHe} then {dom.youVerb('lunge')} forward at {sub.youHim}. For a brief moment, {sub.you} {sub.youVerb('lose')} track of {sub.yourHis} surroundings. When {sub.youHe} {sub.youVerb('regain')} senses, {sub.youHe} {sub.youVerb('notice')} {sub.yourself} down on {sub.yourHis} belly, with {dom.you} hungrily pinning {sub.youHim} down.",
	]

	saynn(RNG.pick(possible))
	
	possible = []
	
	if(subIsMean):
		possible.append_array([
			"*grunts* Fuck you.",
		])
	else:
		possible.append_array([
			"Eek!",
			"Aah!",
		])

	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")
	
	possible = []
	
	if(domIsMean):
		possible.append_array([
			"What a helpless bitch.",
			"Next time you see me approach, bend over in advance.",
			"Come on brat, let me have a little fun with you.",
			"I don't have all day, you know what I'm here for.",
		])
	else:
		possible.append_array([
			"I'd love to play with you a little longer..",
			"There's still so many things I'd love to do to you..",
			"You're loving this aren't you..",
			"I really like seeing you so powerless..",
		])
	
	if(domIsKind):
		possible.append_array([
			"Heheh sorry, you were too tempting..",
			"I hope you don't mind if I'm a little rough with you.."
		])

	saynn("[say=dom]"+RNG.pick(possible)+"[/say]")

	incl_after_sub_resisted_or_softened_text()

func pinned_after_resisting_too_much_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func eased_grip_text():
	var sub = getRoleChar("sub")

	var subStandInFearProbability = 1.0
	var subKneelScoreType = "agreeSexAsSub"
	var subKneelProbability = 1.0

	var subEscapeProbability = subEscapeUponEaseGripProbability
	var subEscapeProbabilityInverse:float = 1 - max(subEscapeProbability, 0.0)

	var possible = []

	saynn("{dom.You} {dom.youVerb('ease')} {dom.yourHis} grip on {sub.your} wrists, now just barely touching them in a playful manner. There's no longer anything that prevents {sub.you} from escaping.")

	if(domAttemptedToHypnotizeSubUponEaseGrip):
		if(subIsTooFrightenedToEscape):
			possible = [
				"Submit to me.",
				"Surrender yourself to me.",
			]

			saynn("[say=dom]"+RNG.pick(possible)+"[/say]")

			if(subWasHypnotizedIntoKneeling):
				possible = [
					"I will submit..",
					"Y- Yes.. I will get on my knees..",
					"I'll do what you want..",
					"The spirals.. are so mesmerizing.. I'm.. all yours..",
					"Everything.. is overflowing with colors.. I- I'm.. a fucktoy?..",
				]

				if( RNG.chance(5) ):
					possible.append_array([
						"Hah, good try. Wait.. W- What is- Knees, hello??",
					])

				saynn("[say=sub]"+RNG.pick(possible)+"[/say]")
			elif( !sub.isPlayer() ):
				if(subIntendsToKneel):
					subKneelScoreType = "default"
					subKneelProbability = 1.0
					subStandInFearProbability = -0.01

					possible = [
						"You don't have to cast your spells on me, I.. was already going to submit..",
						"F- Fuck, hearing you say that.. makes me want to obey out of my own will.. what's left of it..",
						"I can still.. resist your influence, but.. that offer sounds hot..",
					]

					saynn("[say=sub]"+RNG.pick(possible)+"[/say]")
				else:
					subStandInFearProbability = 1.0
					subKneelScoreType = "default"
					subKneelProbability = -0.01

					possible = [
						"I.. will not..",
						"Not.. to the likes.. of you..",
						"Not.. even going to look into my eyes?",
					]

					saynn("[say=sub]"+RNG.pick(possible)+"[/say]")
		else:
			possible = [
				"Stay.",
			]

			saynn("[say=dom]"+RNG.pick(possible)+"[/say]")

			if(subWasHypnotizedIntoStandingStill):
				possible = [
					"I.. will stay..",
					"I.. shouldn't leave..",
					"This.. won't magically make me want to stay.. H- Huh.. Stay.. That sounds.. comfortable..",
					"I.. cannot refuse..",
				]

				saynn("[say=sub]"+RNG.pick(possible)+"[/say]")
			elif( !sub.isPlayer() ):
				if(subIntendsToStandStill):
					subEscapeProbabilityInverse = 1.00
					subEscapeProbability = -0.01

					possible = [
						"Somehow, that.. doesn't have an effect on me. But I wasn't planning on leaving~",
						"I.. don't have to listen to you. But.. I'm curious, what is it that you have in store for me..",
						"I can still.. ward off your influence, but.. there's something about you..",
					]

					saynn("[say=sub]"+RNG.pick(possible)+"[/say]")
				else:
					subEscapeProbability = 1.00
					subEscapeProbabilityInverse = -0.01

					possible = [
						"I don't.. serve you..",
						"You have no power.. over me..",
					]

					saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	if(subIsTooFrightenedToEscape):
		if(subWasHypnotizedIntoKneeling):
			addAction("immediately_kneel", "OBEY", "You have lost control of your body..", "default", 1.0, 30, {})
		else:
			addDisabledAction("Escape", "You are too frightened to move.")
			addAction("stand_frightened", "Stand in fear", "That's about all you can do..", "default", subStandInFearProbability, 60, {})
			addAction( ( "immediately_kneel" if(subIntendsToKneel) else "eventually_kneel" ), "Kneel", "Set your fear aside and get on your knees.", subKneelScoreType, subKneelProbability, 30, {} )
	else:
		if(subWasHypnotizedIntoStandingStill):
			addAction("refuse_to_escape", "OBEY", "You have lost control of your body..", "default", 1.0, 60, {})
		else:
			addAction("escape", "Escape", "This is what you want.", "default", subEscapeProbability, 60, {})
			addAction("refuse_to_escape", "Stand still", "This is what you want.", "default", subEscapeProbabilityInverse, 60, {})

func eased_grip_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "escape"):
		setState("escaped", "sub")
	elif(_id == "stand_frightened"):
		setState("stood_frightened", "dom")
	elif(_id == "immediately_kneel"):
		setState("kneeled", "dom")
	elif(_id == "eventually_kneel"):
		setState("stood_before_kneeling", "sub")
	elif(_id == "refuse_to_escape"):
		recoverSubStamina()
		domRefusedUndressingRequestTimes = -1
		subConsentedToUndressing = true
		subResistedWhileNotWaitingOrHesitatingTimes -= 2
		setState("refused_to_escape", "dom")


func escaped_text():
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domIsMean = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4
	var affectionRatio:float = ( subPawn.getAffection(domPawn) + 1.0 ) / 2.0

	saynn("{sub.You} {sub.youVerb('pull')} forward, breaking away from {dom.your} nudging, turning around in the motion.")

	var possible = []

	if(domIsMean):
		possible.append_array([
			{ dialogue = "What a bitch. Fine, leave. Before I change my mind.", offerDenyChance = 0.0 },
			{ dialogue = "Hmph, picky slut. Next time I won't be so easy on you.", offerDenyChance = 0.0 },
		])
	else:
		possible.append_array([
			{ dialogue = "Aww, I was hoping to play with you..", offerDenyChance = (60.0 - 80.0 * affectionRatio) },
			{ dialogue = "It was fun playing with you, hope we meet again soon~", offerDenyChance = (60.0 - 80.0 * affectionRatio) },
		])

	var possibleRandomPick = RNG.pick(possible)
	saynn("[say=dom]"+ possibleRandomPick.dialogue +"[/say]")

	if( (possibleRandomPick.offerDenyChance > 0.0) && RNG.chance(possibleRandomPick.offerDenyChance) ):
		sayLine("sub", "TalkSexOfferDeny", {main="sub", target="dom"})

	addAction("leave", "Leave", "Leave them be.", "default", 1.0, 0, {})

func escaped_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		resetLustState()
		stopMe()


func stood_frightened_text():
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanRatio = ( domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) + 1.0 ) / 2.0

	saynn( RNG.pick([
		"{sub.You} {sub.youAre} given an opportunity to escape, but {sub.youHe} {sub.youVerb('seem')} too frightened to move, almost vibrating in place.",
		"{dom.You} carefully {dom.youVerb('observe')} {sub.your} movements with all senses available to {dom.youHim}. {sub.YouHe} {sub.youVerb('remain')} standing in place, albeit visibly distressed. Perhaps {sub.youHe} {sub.youVerb('see')} this as a test, or {sub.youAre} too shaken up to move..",
	]) )

	var domGrabSubAgainProbability = -0.4 + (1.0 * domPersonalityMeanRatio)
	addAction("tighten_grip", "Tighten grip", "Firmly hold them by their wrists again.", "punish", domGrabSubAgainProbability, 60, {})
	addAction("leave", "Leave", "Perhaps it's better to leave them alone.", "default", 1.0, 60, {})

func stood_frightened_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "tighten_grip"):
		setState("tightened_grip", "sub")
	elif(_id == "leave"):
		setState("left_standing", "sub")


func tightened_grip_text():
	saynn( RNG.pick([
		"{dom.You} {dom.youVerb('tighten')} {dom.yourHis} paws around {sub.your} wrists, possessively comforting {sub.youHim}.",
	]) )

	incl_after_sub_resisted_or_softened_text()

func tightened_grip_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func kneeled_text():
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	if(subWasHypnotizedIntoKneeling || subIntendsToKneel):
		saynn( RNG.pick([
			"{sub.You} {sub.youVerb('kneel')} submissively in front of {dom.you}.",
		]) )
	else:
		saynn( RNG.pick([
			"Eventually, {sub.you} {sub.youVerb('manage')} to set {sub.youHis} fears aside.. submissively kneeling in front of {dom.you}.",
		]) )

	var domSexScoreType:String = "sexDom"
	var domSexProbability:float = 1.0

	var domPinDownScoreType:String = "punish"
	var domPinDownProbability:float = 1.0

	if( subWasHypnotizedIntoKneeling && sub.isPlayer() ):
		var subInterestInUnconSex = subPawn.scoreFetishMax({ Fetish.UnconsciousSex: 1.0 })
		var subLikesUnconSex = subInterestInUnconSex >= 0.5

		if(!subLikesUnconSex):
			domSexScoreType = "default"
			domSexProbability = -0.01

			domPinDownScoreType = "default"
			domPinDownProbability = 1.0

	addAction("sex", "Sex", "Just have some fun with them!", domSexScoreType, domSexProbability, 60, {})
	addAction("pin_down", "Pin down", "Pin them into the ground.", domPinDownScoreType, domPinDownProbability, 60, {})
	addAction("leave", "Leave", "You don't feel like doing anything with them.", "justleave", 1.0, 60, {})

func kneeled_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "sex"):
		setState("about_to_sex", "dom")
	elif(_id == "pin_down"):
		subWasPinnedToTheGround = true
		setState("pinned_after_kneeling_or_running_out_of_stamina", "dom")
	elif(_id == "leave"):
		setState("left_standing", "sub")


func stood_before_kneeling_text():
	saynn( RNG.pick([
		"{sub.You} {sub.youAre} allowed to freely leave, but {sub.youHe} {sub.youAre} visibly intimated by {dom.your} presence, not being able to move for about "+ RNG.pick(["ten", "twenty", "thirty"]) +" seconds.",
	]) )

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 0, {})

func stood_before_kneeling_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("kneeled", "dom")


func about_to_sex_text():
	saynn("{dom.You} {dom.youVerb('grab')} {sub.you}..")
	sayLine("dom", "PunishSex", {punisher="dom", target="sub"})

	addAction("sex", "Sex", "Start the sex.", "default", 1.0, 300, { start_sex=["dom", "sub"], })

func about_to_sex_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "sex"):
		var _result = getSexResult(_args, true)
		setState("after_sex", "dom")


func after_sex_text():
	saynn("After sex, {dom.you} {dom.youVerb('leave')} {sub.you} alone..")

	addAction("leave", "Leave", "Time to go.", "default", 1.0, 30, {})

func after_sex_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		resetLustState()
		stopMe()


func refused_to_escape_text():
	var sub = getRoleChar("sub")

	saynn("{sub.You} can now freely leave, but.. {sub.YouHe} {sub.youVerb('remain')} standing there, slightly bent over, as {dom.you} {dom.youVerb('remain')} tightly pressed against {sub.youHim}.")

	if( sub.isPlayer() && (subStaminaRecovered > 0) ):
		addMessage("{sub.You} recovered " + str(subStaminaRecovered) + " stamina.")

	incl_after_sub_resisted_or_softened_text()

func refused_to_escape_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func immediately_broke_free_text():
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")
	var subIsMean = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4
	
	var possible = [
		"Not a chance.",
		"In your dreams.",
	]

	if(subIsMean):
		possible.append_array([
			"Fuck off.",
			"You crossed the wrong creature, fucker.",
			"Next time use your fucking mouth to ask.",
			"Find yourself some other hoe.",
		])
	else:
		possible.append_array([
			"Sorry, you're not my type~",
			"Sorry, not making it that easy for you~",
		])

	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	saynn("{sub.You} {sub.youVerb('strike')} {dom.you} into {dom.yourHis} left ankle, then {sub.youVerb('deliver')} a successive swing of {sub.yourHis} elbow directly into {dom.yourHis} side.")
	saynn("{dom.You} {dom.youVerb('lose')} balance.")

	if(sub.isPlayer()):
		addMessage("{sub.You} used " + str(SUB_STAMINA_COST_BREAK_FREE) + " stamina.")

	addAction("leave", "Leave", "Leave them be.", "default", 1.0, 0, {})

func immediately_broke_free_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		var domPawn = getRolePawn("dom")
		domPawn.afterLostFight()
		resetLustState()
		stopMe()


func left_standing_text():
	var subPawn = getRolePawn("sub")
	var subIsKind = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) < -0.4

	var possible = [
		"{dom.You} {dom.youVerb('decide')} it's best to leave {sub.you} alone and allow {sub.youHim} time to recover.",
		"{dom.You} {dom.youVerb('choose')} to leave {sub.you} alone.",
	]

	var eventLine = RNG.pick(possible)

	if(subIsKind):
		eventLine += " " + RNG.pick([
			"Before parting ways, {dom.you} {dom.youVerb('leave')} {sub.youHim} with a brief, gentle hug.",
		])

	saynn(eventLine)

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 0, {})

func left_standing_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		resetLustState()
		stopMe()


func left_laying_down_text():
	var dom = getRoleChar("dom")

	var dom_you_veHe_s = "you've" if dom.isPlayer() else ( "they've" if ( dom.heShe() == "they" ) else "{dom.he}'s" )

	var possible = [
		"{dom.You} {dom.youVerb('stand')} up, deciding to leave {sub.you} laying on the ground.",
		"{dom.You} {dom.youVerb('get')} up, feeling like "+ dom_you_veHe_s +" had enough playing with {sub.you}.",
	]

	saynn(RNG.pick(possible))

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 0, {})

func left_laying_down_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		resetLustState()
		stopMe()


func in_pain_text():
	if(domSpecialActionKeyLastUsed == "bite"):
		incl_post_dom_special_bite_text()

	domSpecialActionKeyLastUsed = "none"

	saynn("{sub.You} {sub.youAre} in too much pain to continue.")

	addAction("leave", "Leave", "Leave them be.", "default", 1.0, 0, {})

func in_pain_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		var sub = getRoleChar("sub")

		var PAIN_RATIO_DESIRED_MAXIMUM = 0.6
		var postInteractionSubPainReduction = int( ceil( sub.getPain() - ( PAIN_RATIO_DESIRED_MAXIMUM * sub.painThreshold() ) ) )
		if(postInteractionSubPainReduction >= 1):
			sub.addPain(-postInteractionSubPainReduction)

		resetLustState()
		stopMe()


func mod_settings_text():
	incl_mod_setting_value_encounter_chance_text()

	addAction("setting_encounter_chance", "Encounter %", "Change how often you wish to be sneaked up on.", "default", -0.01, 0, {})
	addAction("return", "Return", "Return to the interaction.", "default", 1.0, 0, {})
	
func mod_settings_do(_id:String, _args:Dictionary, _context:Dictionary):
	var character = getCurrentPawn().getCharacter()
	var characterRole = "dom" if( getRoleChar("dom") == character ) else "sub"

	if(_id == "setting_encounter_chance"):
		setState("mod_setting_encounter_chance", characterRole)
	elif(_id == "return"):
		if(characterRole == "dom"):
			setState("after_sub_resisted", "dom")
		else:
			setState("", "sub")


func mod_setting_encounter_chance_text():
	incl_mod_setting_value_encounter_chance_text()

	saynn("\n"+ "Determines how often will other inmates sneak up on you.")

	saynn("Default: Balanced (+0.010% / cell)" +"\n")

	var encounterChanceIncrementMillionth = GM.main.getFlag("SneakUpTeaseModule.SneakUpEncounterChanceIncrementMillionth", 100)

	if(encounterChanceIncrementMillionth > -1):
		addAction("decrease_chance_2", "-0.002%", "Decrease the chance of being sneaked up on.", "default", -0.01, 0, {})
		addAction("decrease_chance_1", "-0.001%", "Decrease the chance of being sneaked up on.", "default", -0.01, 0, {})
	else:
		addDisabledAction("-0.002%", "Cannot decrease the chance any further.")
		addDisabledAction("-0.001%", "Cannot decrease the chance any further.")

	addAction("return", "Done", "Return to the list of settings.", "default", 1.0, 0, {})

	if(encounterChanceIncrementMillionth < 500):
		addAction("increase_chance_1", "+0.001%", "Increase the chance of being sneaked up on.", "default", -0.01, 0, {})
		addAction("increase_chance_2", "+0.002%", "Increase the chance of being sneaked up on.", "default", -0.01, 0, {})
	else:
		addDisabledAction("+0.001%", "Cannot increase the chance any further.")
		addDisabledAction("+0.002%", "Cannot increase the chance any further.")

func mod_setting_encounter_chance_do(_id:String, _args:Dictionary, _context:Dictionary):
	var encounterChanceIncrementMillionth = GM.main.getFlag("SneakUpTeaseModule.SneakUpEncounterChanceIncrementMillionth", 100)

	var valueMin:int = -1 if(encounterChanceIncrementMillionth == 0) else 0
	var valueMax:int = 0 if(encounterChanceIncrementMillionth <= -1) else 500

	if(_id == "decrease_chance_1"):
		encounterChanceIncrementMillionth -= 10
	elif(_id == "decrease_chance_2"):
		encounterChanceIncrementMillionth -= 20
	elif(_id == "increase_chance_1"):
		encounterChanceIncrementMillionth += 10
	elif(_id == "increase_chance_2"):
		encounterChanceIncrementMillionth += 20

	if(encounterChanceIncrementMillionth < valueMin):
		encounterChanceIncrementMillionth = valueMin
	elif(encounterChanceIncrementMillionth > valueMax):
		encounterChanceIncrementMillionth = valueMax

	if(_id != "return"):
		GM.main.setFlag("SneakUpTeaseModule.SneakUpEncounterChanceIncrementMillionth", encounterChanceIncrementMillionth)
	else:
		var character = getCurrentPawn().getCharacter()
		var characterRole = "dom" if( getRoleChar("dom") == character ) else "sub"
		setState("mod_settings", characterRole)

func incl_mod_setting_value_encounter_chance_text():
	var encounterChanceIncrementMillionth = GM.main.getFlag("SneakUpTeaseModule.SneakUpEncounterChanceIncrementMillionth", 100)

	var encounterChanceDesc = ""

	if(encounterChanceIncrementMillionth <= -1):
		encounterChanceDesc = "Never, not even when looking for trouble."
	elif(encounterChanceIncrementMillionth == 0):
		encounterChanceDesc = "Only when looking for trouble."
	elif(encounterChanceIncrementMillionth <= 30):
		encounterChanceDesc = "Unlikely"
	elif(encounterChanceIncrementMillionth <= 70):
		encounterChanceDesc = "Very rare"
	elif(encounterChanceIncrementMillionth <= 120):
		encounterChanceDesc = "[color="+ getSensationColor("comfort") +"]Balanced[/color]"
	elif(encounterChanceIncrementMillionth <= 170):
		encounterChanceDesc = "Common"
	elif(encounterChanceIncrementMillionth <= 250):
		encounterChanceDesc = "[color="+ getSensationColor("pain_moderate") +"]Very common[/color]"
	else:
		encounterChanceDesc = "[color="+ getSensationColor("pain_severe") +"]Might get repetitive really quick[/color]"

	saynn(
			"Encounter chance: "
		+ encounterChanceDesc
		+ (
				(
						" (+"
					+ ( "%.3f" % (encounterChanceIncrementMillionth / 10000.0) )
					+ "% / cell)"
				)
			if (encounterChanceIncrementMillionth > 0)
			else ""
		)
	)


func incl_post_dom_flirt_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domIsMean = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4
	var domIsSubby = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) > 0.4
	var domInterestInAnalSexReceiving = domPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })
	var subIsMean = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4
	var subSpecies = sub.getSpecies()
	var subIsInmate = subPawn.isInmate()
	var subHasBeenHighlyObedient = ( (subResistedTimes <= 1) && (subSoftenedTimes >= 6) )
	var sub_handsome = "charming" if ( sub.heShe() == "they" ) else ( "pretty" if ( sub.heShe() == "she" ) else "handsome" )
	var affectionValue:float = domPawn.getAffection(subPawn)
	var lustValue:float = domPawn.getLust(subPawn)
	var subLustRatio = getSubLustRatio()

	var DIALOGUE_I_DONT_BITE = "Don't worry, I don't bite~"
	var DIALOGUE_GLAZED_DONUT = "We're not done until your cute butt looks like a glazed donut."

	var possible = [
		"I'm not letting anyone else have you.",
		"Nobody else can have you.. You're mine.",
	]

	if( !domHasUsedFlirtLineByAlias.has("glazed_donut") ):
		possible.append(DIALOGUE_GLAZED_DONUT)

	if( !domHasUsedFlirtLineByAlias.has("i_dont_bite") ):
		if(domHasBittenSubTimes == 0):
			possible.append(DIALOGUE_I_DONT_BITE)
		else:
			possible.append("Don't worry, I don't bite- Oh.. I suppose I do, actually~")

	if( subIsInmate && RNG.chance(10) ):
		possible.append_array([
			"If I knew there's hotties like you imprisoned in the middle of nowhere, maybe I would have gotten myself caught much sooner..",
			"It should be illegal to be this hot.. Wait, don't tell me-",
		])

	if( (affectionValue < -0.4) && (lustValue > 0.6) ):
		possible.append_array([
			"I'm mad about you.",
		])

	if(lustValue > 0.8):
		possible.append_array([
			"I've yet to spend a day in here without deeply craving you..",
			"You've been on my mind all day.. Your thighs..",
		])

	if( subWasUndressed || sub.isFullyNaked() ):
		possible.append_array([
			"Fuck, your curves make me want to go completely feral..",
		])

	if(subWasUndressed):
		possible.append_array([
			"I almost want to put the clothes back on you, just to experience sliding them down one more time.",
		])

	if(domIsMean):
		if( sub.isPlayer() ):
			if( hasRepLevelPC("sub", RepStat.Whore, 8) ):
				possible.append_array([
					"Everyone keeps talking about how good of a fuck you are. Don't disappoint me now.",
				])
			elif( hasRepLevelPC("sub", RepStat.Whore, 4) ):
				possible.append_array([
					"If you're at least half as good as your reputation, you might actually be worth my time.",
				])

		if(affectionValue < -0.4):
			possible.append_array([
				"Told you that you shouldn't have crossed me.",
				"You get what you give, bitch.",
			])
		elif(affectionValue > 0.4):
			possible.append_array([
				"You're a bitch, but you've been fair to me. I appreciate it.",
			])
	else:
		if( sub.isPlayer() ):
			if( hasRepLevelPC("sub", RepStat.Whore, 8) ):
				possible.append_array([
					"You're all everyone talks about.. Can't help but crave a taste..",
				])
			elif( hasRepLevelPC("sub", RepStat.Whore, 4) ):
				possible.append_array([
					"I've been hearing good things about you..",
				])

			if( ( subWasUndressed || sub.isFullyNaked() ) && ( sub.getStat(Stat.Sexiness) >= 60 ) && RNG.chance(5) ):
				possible.append_array([
					"Gosh, just how many points did you invest in sexiness..",
				])

		if( abs(affectionValue) < 0.05 ):
			possible.append_array([
				"Wish I had met you earlier..",
			])
		elif( abs(affectionValue) < 0.10 ):
			possible.append_array([
				"I would like to get to know you more.. Like, really get to know you..",
			])
		elif(affectionValue < -0.4):
			possible.append_array([
				"I'm still a little upset over what you did to me that time..",
			])
		elif(affectionValue > 0.8):
			possible.append_array([
				"Sorry, I've got a little attached to you lately.. I mean.. metaphorically..",
			])

		if(subLustRatio > 0.5):
			possible.append_array([
				"You seem a little pent up~",
			])

		if( !dom.isBlindfolded() ):
			if(affectionValue > 0.8):
				possible.append_array([
					"I'm always happy to see you.. Hope you're also happy to, um.. feel me, hehehe.",
					"Sorry.. I'm just so happy to see you..",
				])

			if( subWasUndressed || sub.isFullyNaked() ):
				possible.append_array([
					"I absolutely adore this view.",
				])

			if( RNG.chance(5) ):
				if( sub.getInventory().hasEquippedItemWithTag(ItemTag.SexualDeviantInmateUniform) && sub.isBodypartCovered(BodypartSlot.Body) ):
					possible.append_array([
						"You know, not all animals are good at discerning colors.. They should have made lilac uniform come with a skirt.. For accessibility..",
					])

			possible.append_array([
				"You're so "+ sub_handsome +"..",
				"I could stare at you all day..",
				"You look stunning, darling."
			])

		possible.append_array([
			"Glad I managed to get my paws on you, "+ sub_handsome +".",
			"I can't seem to get enough of you..",
			"I promise I have my reasons..",
			"You're all I'm thinking about..",
		])

	if(subResistedTimes < 4):
		# Haven't resisted much yet

		if(subHasBeenHighlyObedient):
			if(domIsMean):
				possible.append_array([
					"Someone here actually knows their place, color me surprised.",
					"You must be really desperate to not even put up a fight.",
					"Good little slut.",
					"You're the perfect fucktoy.",
					"That's right. I own you.",
				])
			else:
				possible.append_array([
					"What a good pet you are~",
					"Aren't you an obedient little pet~",
					"What a well-behaved "+ RNG.pick( getPetNames({ species = subSpecies, heSheThey = sub.heShe() }) ) + ".",
				])

				if( subSpecies.has(Species.Canine) ):
					var sub_boy = "puppy" if ( sub.heShe() == "they" ) else ( "girl" if ( sub.heShe() == "she" ) else "boy" )

					possible.append_array([
						"Such a good "+ sub_boy + ".",
						"You must be really craving for a bone..",
					])

		if(domIsMean):
			if(!subWasPinnedToTheGround):
				possible.append_array([
					"Keep bending over, bitch. You're much hotter this way.",
				])
		else:
			possible.append_array([
				"I really want you right now..",
				"You're such a snack, you know..",
			])
	elif( !isSubWaitingOnDom() ):
		# Resisted quite a few times by now, and isn't waiting on dom to act

		if(affectionValue < -0.4):
			possible.append_array([
				"Don't worry, I'm not here for revenge. You might've been a bitch to me, but I want you to get something good out of this too.",
			])

		if( domIsSubby && (domInterestInAnalSexReceiving > 0.4) ):
			possible.append_array([
				"Oh I wish I were in your place, we're about to get to my favorite part~",
				"I wouldn't resist if I were you. I don't mean that as a threat, it's just I'd [i]really[/i] want to be buttfucked.",
			])

		if(domIsMean):
			possible.append_array([
				"Quit being such a brat, we both know how bad you want it.",
				"You won't be resisting much longer, I'll remind you who's bitch you really are.",
				"Did you forget who you belong to? Stop being such a brat."
			])
		else:
			possible.append_array([
				( "I love watching you struggle~" if( !dom.isBlindfolded() ) else "I love it when you struggle~" ),
				"No need to resist that much hun, I promise I'll be gentle~",
				"I'll take good care of you, so you won't have to struggle much longer~",
				"No need to make this difficult, I know you want it too~",
				"I'll make it worth your time..",
				"I really want you to stay..",
				"I won't mistreat a cutie like you..",
			])

	var possibleRandomPick = RNG.pick(possible)

	if(possibleRandomPick == DIALOGUE_GLAZED_DONUT):
		domHasUsedFlirtLineByAlias["glazed_donut"] = true
	elif(possibleRandomPick == DIALOGUE_I_DONT_BITE):
		domHasUsedFlirtLineByAlias["i_dont_bite"] = true

	saynn("[say=dom]"+possibleRandomPick+"[/say]")

	var flirtResponseSubLustRatioMin = 0.25 if(subIsMean) else 0.50
	var shouldSubRespondToFlirt = ( (subLustRatio >= flirtResponseSubLustRatioMin) && RNG.chance(2) )

	if(shouldSubRespondToFlirt):
		sayLine("sub", "TalkFlirtAccept", {main="sub", target="dom"})
	elif( !subIsMean && (subLustRatio > 0.3) && RNG.chance(2) ):
		saynn("{sub.You} {sub.youVerb('blush', 'blushes')}.")


func incl_post_sub_snark_text():
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subIsDommy = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) < -0.4

	var possible = [
		"Think you're getting anywhere with me? Good luck.",
		"If you think this gets you anywhere, you're funny.",
		"You're silly if you think you can make me "+ ( "hard" if( sub.hasBodypart(BodypartSlot.Penis) ) else "wet" ) +" with that.",
		"Don't you get it? I'm not someone you play to get what you want.",
		"What are you even trying to achieve here?",
		"Are you genuinely expecting this to work on me?",
	]

	if(subSnarkUsedTimes > 1):
		possible.append_array([
			"Didn't you hear what I just said?",
			"How many times do I need to spell it out for you?",
			"Did I not make myself clear enough?",
		])

	if(subIsDommy):
		possible.append_array([
			"The only way you're getting anything is if you submit to me.",
		])

	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")


func incl_dom_refuse_request_text(_info:Dictionary):
	var speechComprehensibility = _info.speechComprehensibility

	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4

	if( (speechComprehensibility != "awful") && RNG.chance(10) ):
		saynn( RNG.pick([
			"{dom.Your} ears lightly twitched.",
		]) )

	var possible = []

	if(speechComprehensibility == "awful"):
		possible.append_array([
			"Like what the fuck are you even saying..",
		])
	elif(speechComprehensibility == "bad"):
		if(domIsMean):
			possible.append_array([
				"Stop muttering and say it in the way I can understand.",
				"You'll have to stop mumbling if you expect me to comprehend your speech.",
				"Was that even in an actual language? Bitch, stop messing with me.",
			])
		else:
			possible.append_array([
				"Hm.. Say it again?",
				"Hehe, it's.. difficult to make out what you're saying.. Say it again?",
				"I can't quite make out what you're saying.. Could you rephrase?",
				"Um.. I cannot make heads or tails of what you just said.. Could you rephrase?",
				"Huh? I didn't quite understand that, sorry.",
			])
	else:
		if(domIsMean):
			possible.append_array([
				"Keep begging for it, slut.",
				"You'll have to try harder than that.",
				"I decide when that happens, not you.",
				"I need to hear how desperate you really are.",
			])
		else:
			possible.append_array([
				"Mmm.. I want to hear you say it again~",
				"Sorry, I didn't quite catch that~",
				"I love hearing those words.. I want to hear some more begging out of your lips~",
				"..Sorry, I was distracted by your charming butt. Could you repeat?",
				"That was a little too quiet for me, say it again?",
			])

	saynn("[say=dom]"+RNG.pick(possible)+"[/say]")


func incl_dom_special_bite_do():
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanRatio = ( domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) + 1.0 ) / 2.0
	var subInterestInBeingBitten = subPawn.scoreFetishMax({ Fetish.Masochism: 1.0 })

	domSpecialActionCooldown = DOM_SPECIAL_ACTION_COOLDOWN_TURNS
	domSpecialActionKeyLastUsed = "bite"
	domSpecialActionParamBodyPart = RNG.pick(["neck", "shoulder", "arm"])
	domSpecialActionParamStrength = clamp( ( domPersonalityMeanRatio + RNG.randf_range(-0.40, 0.40) ), 0.01, 1.00 )

	if( domHasUsedFlirtLineByAlias.has("i_dont_bite") && !domHasUsedFlirtLineByAlias.has("i_dont_bite_<reacted>") ):
		domSpecialActionParamStrength = max(domSpecialActionParamStrength, 0.35)

	var painBaseValue = 12 if(domSpecialActionParamBodyPart == "neck") else 6
	var painInflictedFromBite = ceil(painBaseValue * domSpecialActionParamStrength)

	# Ensures nibbles never fully fill out the pain meter (unless it is already)
	var isBiteGentle = (domSpecialActionParamStrength <= 0.3)
	var painMaxAllowed = max( sub.getPain(), sub.painThreshold() - 1 ) if(isBiteGentle) else sub.painThreshold()
	painInflictedFromBite = min(painInflictedFromBite, painMaxAllowed - sub.getPain())

	if(!isBiteGentle):
		domHasBittenSubTimes += 1

	if(painInflictedFromBite >= 1):
		sub.addPain(painInflictedFromBite)

	subAdditionalLustFromSpecials = max(
		(
				subAdditionalLustFromSpecials
			+ (0.10 * subInterestInBeingBitten)
		),
		0.0
	)

	if( sub.getPain() >= sub.painThreshold() ):
		setState("in_pain", "dom")
	else:
		setState("", "sub")

func incl_post_dom_special_bite_text():
	var bittenBodyPart = domSpecialActionParamBodyPart

	var biteType = ""
	var possible = []

	if(domSpecialActionParamStrength > 0.7):
		biteType = "painful"

		possible.append_array([
			"{dom.You} {dom.youVerb('lean')} forward and [color="+ getSensationColor("pain_severe") +"]strongly {dom.youVerb('bite')}[/color] {sub.you} in the "+ bittenBodyPart +".",
			"{dom.You} {dom.youVerb('lean')} forward and [color="+ getSensationColor("pain_severe") +"]painfully {dom.youVerb('chomp')}[/color] {sub.your} "+ bittenBodyPart +".",
			"{dom.You} {dom.youVerb('lean')} forward and [color="+ getSensationColor("pain_severe") +"]{dom.youVerb('leave')} a deep bite mark[/color] in {sub.your} "+ bittenBodyPart +".",
		])
	elif(domSpecialActionParamStrength > 0.3):
		biteType = "regular"

		possible.append_array([
			"{dom.You} {dom.youVerb('lean')} forward and [color="+ getSensationColor("pain_moderate") +"]{dom.youVerb('bite')}[/color] {sub.you} in the "+ bittenBodyPart +".",
			"{dom.You} {dom.youVerb('lean')} forward and [color="+ getSensationColor("pain_moderate") +"]{dom.youVerb('mark')}[/color] {sub.your} "+ bittenBodyPart +" with {dom.yourHis} teeth.",
		])
	else:
		biteType = "gentle"

		possible.append_array([
			"{dom.You} {dom.youVerb('lean')} forward and [color="+ getSensationColor("comfort") +"]lightly {dom.youVerb('nibble')}[/color] {sub.your} "+ bittenBodyPart +".",
			"{dom.You} {dom.youVerb('lean')} forward and [color="+ getSensationColor("comfort") +"]delicately {dom.youVerb('mark')}[/color] {sub.your} "+ bittenBodyPart +" with {dom.yourHis} teeth.",
		])

	saynn(RNG.pick(possible))

	possible = []

	var domReactEvents = []

	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var subIsInPain = ( sub.getPain() >= sub.painThreshold() )
	var subLustRatio = getSubLustRatio()
	var domPersonalityMeanScore = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean = domPersonalityMeanScore > 0.4
	var subPersonalityMeanScore = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean = subPersonalityMeanScore > 0.4
	var subIsKind = subPersonalityMeanScore < -0.4
	var subInterestInBeingBitten = subPawn.scoreFetishMax({ Fetish.Masochism: 1.0 })
	var subLikesBeingBitten = subInterestInBeingBitten >= 0.5
	var subDislikesBeingBitten = subInterestInBeingBitten <= -0.5
	var subFakesIndifferenceToBites = (subLustRatio < 0.50)

	if(subIsInPain):
		possible.append_array([
			"Watch where you put those teeth! Fuck!",
			"Oww.. I'm not a fucking chew toy!"
		])

		if(subDislikesBeingBitten || subIsMean):
			possible.append_array([
				"Oww! Fuck off now, will you?",
				"Fuck.. Leave me the fuck alone.",
				"Bitch.. Leave me alone or you'll be next..",
				"Bitch.. Get the fuck away from me.",
			])
		else:
			possible.append_array([
				"Fuck, that was too much..",
				"Oww, fuck! It hurts..",
				"Oww.. Heck, I need to lay down..",
			])
	elif( domHasUsedFlirtLineByAlias.has("i_dont_bite") && !domHasUsedFlirtLineByAlias.has("i_dont_bite_<reacted>") && (biteType != "gentle") ):
		domHasUsedFlirtLineByAlias["i_dont_bite_<reacted>"] = true

		if(subIsMean):
			possible.append_array([
				"See that's why I don't trust you.",
			])
		else:
			possible.append_array([
				"B- But you said..",
			])

		domReactEvents.append_array([
			"{dom.You} {dom.youVerb(" + ( "'snicker'" if(domIsMean) else "'giggle'" ) + ")}.",
		])
	elif(subLikesBeingBitten && !subFakesIndifferenceToBites):
		if( (biteType == "painful") && !subIsMean ):
			possible.append_array([
				"Owch!.. Oh wow..",
			])

		if(biteType != "gentle"):
			possible.append_array([
				"F-fuck yeah..",
			])

		possible.append_array([
			"Mmm, got fangs in you I see.",
			"You really want a bite of me, huh..",
			"Ooh, I love that..",
			"..Why'd you stop?",
		])
	elif(!subDislikesBeingBitten):
		if(biteType == "painful"):
			possible.append_array([
				"Oww, fuck!",
			])

		if(biteType != "gentle"):
			possible.append_array([
				"Oww..",
			])

			if(!subIsMean):
				possible.append_array([
					"Hey, that hurts..",
				])

		if(subIsKind):
			possible.append_array([
				"Stop t- that..",
			])

		possible.append_array([
			"..I don't know how to feel about this.",
			"Ow. Hmph..",
		])
	else:
		if(biteType == "painful"):
			possible.append_array([
				"Ow, what the fuck!",
			])

			if(subIsMean):
				possible.append_array([
					"The fuck is wrong with you??",
				])

		if( (biteType != "gentle") && subIsMean ):
			possible.append_array([
				"Bitch, next time I see your unlucky ass, you're getting the same treatment.",
			])

		possible.append_array([
			"What do you think you're doing??",
			"What did you do that for..",
		])
	
	saynn("[say=sub]"+RNG.pick(possible)+"[/say]")

	if( domReactEvents.size() > 0 ):
		saynn( RNG.pick(domReactEvents) )


func getAnimData() -> Array:
	if( getState() == "immediately_broke_free" ):
		return [StageScene.GivingBirth, "idle", { pc="dom" }]

	if( getState() == "broke_free_after_running_out_of_patience" ):
		if(subWasPinnedToTheGround):
			return [StageScene.SexBehind, "tease", { pc="sub", npc="dom" }]

		return [StageScene.GivingBirth, "idle", { pc="dom" }]

	if( getState() == "escaped" ):
		return [StageScene.Duo, "stand", { pc="dom", npc="sub", npcAction="stand", further=true} ]

	if( getState() == "left_standing" ):
		return [StageScene.Duo, "stand", { pc="dom", npc="sub", npcAction="stand", flipNPC=true} ]

	if( getState() in ["in_pain", "left_laying_down"] ):
		return [StageScene.GivingBirth, "idle", { pc="sub" }]

	if( getState() in ["ran_out_of_stamina", "kneeled"] ):
		return [StageScene.Duo, "stand", { pc="dom", npc="sub", npcAction="kneel", flipNPC=true }]

	if( getState() == "about_to_sex" ):
		return [StageScene.SexStart, "start", { pc="dom", npc="sub" }]

	if( getState() == "after_sex" ):
		return [StageScene.Duo, "stand", { pc="dom", npc="sub" }]

	if(subWasPinnedToTheGround):
		return [StageScene.SexBehind, "tease", { pc="dom", npc="sub" }]

	return [StageScene.SexFreeStanding, "tease", { pc="dom", npc="sub" }]

func getActivityIconForRole(_role:String):
	var STATES_WITH_NO_ICON = [
		"immediately_broke_free",
		"broke_free_after_running_out_of_patience",
		"eased_grip",
		"escaped",
		"stood_frightened",
		"stood_before_kneeling",
		"kneeled",
		"left_standing",
		"left_laying_down",
		"in_pain",
		"after_sex",
	]

	if( getState() in STATES_WITH_NO_ICON ):
		return RoomStuff.PawnActivity.None

	return RoomStuff.PawnActivity.Sex
	
func getPreviewLineForRole(_role:String) -> String:
	if(_role == "dom"):
		return "{dom.name} {dom.is} teasing {sub.name}."
	if(_role == "sub"):
		return "{sub.name} {sub.is} being teased by {dom.name}."

	return .getPreviewLineForRole(_role)

func stopMe():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		var state = getState()

		var cooldownMultiplier = 0.80
		if( state in ["escaped"] ):
			cooldownMultiplier = 0.60
		elif( state in ["immediately_broke_free"] ):
			cooldownMultiplier = 0.40

		GlobalRegistry.getModule("SneakUpTeaseModule").onSneakUpEncounterEarlyExit({
			cooldownMultiplier = cooldownMultiplier,
		})

	return .stopMe()

func saveData():
	var data = .saveData()

	data["subResistedTimes"] = subResistedTimes
	data["subResistedWhileNotWaitingOrHesitatingTimes"] = subResistedWhileNotWaitingOrHesitatingTimes
	data["subSoftenedTimes"] = subSoftenedTimes
	data["subSoftenedWhileWaitingTimes"] = subSoftenedWhileWaitingTimes
	data["subRubbedAgainstDomTimes"] = subRubbedAgainstDomTimes
	data["subSnarkCooldown"] = subSnarkCooldown
	data["subSnarkUsedTimes"] = subSnarkUsedTimes
	data["subBrattinessRatio"] = subBrattinessRatio
	data["subAdditionalLustFromSpecials"] = subAdditionalLustFromSpecials
	data["subStaminaRecovered"] = subStaminaRecovered
	data["subConsentedToUndressing"] = subConsentedToUndressing
	data["subConsentedToAnalSexReceiving"] = subConsentedToAnalSexReceiving
	data["subConsentedToAnalSexGiving"] = subConsentedToAnalSexGiving
	data["subIsTooFrightenedToEscape"] = subIsTooFrightenedToEscape
	data["subWasHypnotizedIntoKneeling"] = subWasHypnotizedIntoKneeling
	data["subWasHypnotizedIntoStandingStill"] = subWasHypnotizedIntoStandingStill
	data["subEscapeUponEaseGripProbability"] = subEscapeUponEaseGripProbability
	data["subIntendsToKneel"] = subIntendsToKneel
	data["subIntendsToStandStill"] = subIntendsToStandStill
	data["subWasPinnedToTheGround"] = subWasPinnedToTheGround
	data["subWasUndressed"] = subWasUndressed

	data["domHasUsedFlirtLineByAlias"] = domHasUsedFlirtLineByAlias
	data["domFlirtCooldown"] = domFlirtCooldown
	data["domRefusedUndressingRequestTimes"] = domRefusedUndressingRequestTimes
	data["domRefusedPenetrationRequestTimes"] = domRefusedPenetrationRequestTimes
	data["domHasBittenSubTimes"] = domHasBittenSubTimes
	data["domRefusedAnalSexReceiving"] = domRefusedAnalSexReceiving
	data["domSpecialActionCooldown"] = domSpecialActionCooldown
	data["domSpecialActionKeyLastUsed"] = domSpecialActionKeyLastUsed
	data["domSpecialActionParamStrength"] = domSpecialActionParamStrength
	data["domSpecialActionParamBodyPart"] = domSpecialActionParamBodyPart
	data["domEasedGripOnce"] = domEasedGripOnce
	data["domAttemptedToHypnotizeSubUponEaseGrip"] = domAttemptedToHypnotizeSubUponEaseGrip
	data["domWasUndressed"] = domWasUndressed
	data["domWasCaptivatedBySubPenis"] = domWasCaptivatedBySubPenis

	return data

func loadData(_data):
	.loadData(_data)

	subResistedTimes = SAVE.loadVar(_data, "subResistedTimes", 0)
	subResistedWhileNotWaitingOrHesitatingTimes = SAVE.loadVar(_data, "subResistedWhileNotWaitingOrHesitatingTimes", 0)
	subSoftenedTimes = SAVE.loadVar(_data, "subSoftenedTimes", 0)
	subSoftenedWhileWaitingTimes = SAVE.loadVar(_data, "subSoftenedWhileWaitingTimes", 0)
	subRubbedAgainstDomTimes = SAVE.loadVar(_data, "subRubbedAgainstDomTimes", 0)
	subSnarkCooldown = SAVE.loadVar(_data, "subSnarkCooldown", 0)
	subSnarkUsedTimes = SAVE.loadVar(_data, "subSnarkUsedTimes", 0)
	subBrattinessRatio = SAVE.loadVar(_data, "subBrattinessRatio", 0.5)
	subAdditionalLustFromSpecials = SAVE.loadVar(_data, "subAdditionalLustFromSpecials", 0.0)
	subStaminaRecovered = SAVE.loadVar(_data, "subStaminaRecovered", 0)
	subConsentedToUndressing = SAVE.loadVar(_data, "subConsentedToUndressing", false)
	subConsentedToAnalSexReceiving = SAVE.loadVar(_data, "subConsentedToAnalSexReceiving", false)
	subConsentedToAnalSexGiving = SAVE.loadVar(_data, "subConsentedToAnalSexGiving", false)
	subIsTooFrightenedToEscape = SAVE.loadVar(_data, "subIsTooFrightenedToEscape", false)
	subWasHypnotizedIntoKneeling = SAVE.loadVar(_data, "subWasHypnotizedIntoKneeling", false)
	subWasHypnotizedIntoStandingStill = SAVE.loadVar(_data, "subWasHypnotizedIntoStandingStill", false)
	subEscapeUponEaseGripProbability = SAVE.loadVar(_data, "subEscapeUponEaseGripProbability", 0.0)
	subIntendsToKneel = SAVE.loadVar(_data, "subIntendsToKneel", false)
	subIntendsToStandStill = SAVE.loadVar(_data, "subIntendsToStandStill", false)
	subWasPinnedToTheGround = SAVE.loadVar(_data, "subWasPinnedToTheGround", false)
	subWasUndressed = SAVE.loadVar(_data, "subWasUndressed", false)

	domHasUsedFlirtLineByAlias = SAVE.loadVar(_data, "domHasUsedFlirtLineByAlias", {})
	domFlirtCooldown = SAVE.loadVar(_data, "domFlirtCooldown", 0)
	domRefusedUndressingRequestTimes = SAVE.loadVar(_data, "domRefusedUndressingRequestTimes", 0)
	domRefusedPenetrationRequestTimes = SAVE.loadVar(_data, "domRefusedPenetrationRequestTimes", 0)
	domHasBittenSubTimes = SAVE.loadVar(_data, "domHasBittenSubTimes", 0)
	domRefusedAnalSexReceiving = SAVE.loadVar(_data, "domRefusedAnalSexReceiving", 0)
	domSpecialActionCooldown = SAVE.loadVar(_data, "domSpecialActionCooldown", 0)
	domSpecialActionKeyLastUsed = SAVE.loadVar(_data, "domSpecialActionKeyLastUsed", "none")
	domSpecialActionParamStrength = SAVE.loadVar(_data, "domSpecialActionParamStrength", 0.0)
	domSpecialActionParamBodyPart = SAVE.loadVar(_data, "domSpecialActionParamBodyPart", "none")
	domEasedGripOnce = SAVE.loadVar(_data, "domEasedGripOnce", false)
	domAttemptedToHypnotizeSubUponEaseGrip = SAVE.loadVar(_data, "domAttemptedToHypnotizeSubUponEaseGrip", false)
	domWasUndressed = SAVE.loadVar(_data, "domWasUndressed", false)
	domWasCaptivatedBySubPenis = SAVE.loadVar(_data, "domWasCaptivatedBySubPenis", false)


func getSensationColor(_type:String) -> String:
	if(_type == "pain_severe"):
		return "#FFBBBB"

	if(_type == "pain_moderate"):
		return "#FFDDBB"

	if(_type == "comfort"):
		return "#DDFFCC"

	return "#666"

func getPetNames(_petInfo:Dictionary) -> Array:
	var species:Array = _petInfo.species
	var heSheThey:String = _petInfo.heSheThey

	var possiblePetNames = []

	if( species.has(Species.Canine) ):
		possiblePetNames.append_array(["doggy", "puppy"])

		if( species.has(Species.Human) ):
			if(heSheThey == "she"):
				possiblePetNames.append_array(["puppygirl"])
			elif(heSheThey == "he"):
				possiblePetNames.append_array(["puppyboy"])
	
	if( species.has(Species.Demon) ):
		possiblePetNames.append_array(["fiend"])
	
	if( species.has(Species.Dragon) ):
		possiblePetNames.append_array(["derg"])

	if( species.has(Species.Equine) ):
		if(heSheThey == "she"):
			possiblePetNames.append_array(["mare"])
		elif(heSheThey == "he"):
			possiblePetNames.append_array(["stallion", "stud"])
		else:
			possiblePetNames.append_array(["stud"])

	if( species.has(Species.Feline) ):
		possiblePetNames.append_array(["kitten", "kitty"])

		if( species.has(Species.Human) ):
			if(heSheThey == "she"):
				possiblePetNames.append_array(["catgirl"])
			elif(heSheThey == "he"):
				possiblePetNames.append_array(["catboy"])

	if( possiblePetNames.size() < 1 ):
		possiblePetNames.append_array(["creature", "pet"])

	return possiblePetNames

func getSpacerText() -> String:
	if( RNG.chance(90) ):
		return ""

	return RNG.pick([
		"Space space wanna go to space yes please space.",
		"Space space going to space can't wait.",
		"Oh oh this is space. We're in space.",
		"Don't like space, don't like space.",
	])

func isCharFullyNaked(character:BaseCharacter) -> bool:
	# char.isFullyNaked() doesn't seem to account for lustState

	var isFullyNaked:bool = false

	for bodypartSlot in BodypartSlot.getAll():
		if character.isBodypartCovered(bodypartSlot):
			isFullyNaked = false
			return isFullyNaked

	isFullyNaked = true
	return isFullyNaked

func isSubWaitingOnDom() -> bool:
	var wasClothingRemoved = (subWasUndressed || domWasUndressed)

	var isSubWaitingOnDom = (
		(subConsentedToUndressing && !wasClothingRemoved)
	)

	return isSubWaitingOnDom

func isSubHesitating() -> bool:
	var isSubHesitating = (
			(domRefusedUndressingRequestTimes > 0) # \ are set to -1 after dom obliges
		|| (domRefusedPenetrationRequestTimes > 0) # /
	)

	return isSubHesitating

func getReasonCharCannotPartakeInAnalSexReceiving(_char:BaseCharacter, _role:String):
	if( !_char.hasAnus() ):
		return RNG.pick([
			"I have no anus.",
			"I do not have a rear hole.",
			"My donut is without a hole in it.",
		])

	if( _char.isWearingPortalPanties() ):
		return RNG.pick([
			"I cannot take the portal panties off.",
		])

	if( !_char.hasReachableAnus() ):
		return RNG.pick([
			"My rear hole is not currently up for it.",
			"My anus is currently off-limits."
		])

	if( (_role == "dom") && _char.hasBoundArms() ):
		return RNG.pick([
			"My arms are tied.",
		])

	if( (_role == "dom") && _char.hasBlockedHands() ):
		return RNG.pick([
			"I have restraints on my paws.",
		])

	return null

func getReasonCharCannotPartakeInAnalSexGiving(_char:BaseCharacter, _role:String):
	if( !_char.hasPenis() ):
		return RNG.pick([
			"Seems it's not going to work.",
		])

	if( _char.isWearingChastityCage() ):
		return RNG.pick([
			"You're a caged animal.",
			"The cage prevents you from fucking me.",
			"You cannot fuck me in that cage.",
		])

	if( _char.isWearingPortalPanties() ):
		return RNG.pick([
			"You're stuck with portal panties on you.",
		])

	if( !_char.hasReachablePenis() ):
		return RNG.pick([
			"The access to your penis is obstructed.",
		])

	if( (_role == "dom") && _char.hasBoundArms() ):
		return RNG.pick([
			"Your arms are tied.",
		])

	if( (_role == "dom") && _char.hasBlockedHands() ):
		return RNG.pick([
			"You have restraints on your paws.",
		])

	return null

func getSubAnalSexReceivingPossible() -> bool:
	return (
			( getReasonCharCannotPartakeInAnalSexGiving( getRoleChar("dom"), "dom" ) == null )
		&& ( getReasonCharCannotPartakeInAnalSexReceiving( getRoleChar("sub"), "sub" ) == null )
	)

func getSubAnalSexGivingPossible() -> bool:
	return (
			( getReasonCharCannotPartakeInAnalSexGiving( getRoleChar("sub"), "sub" ) == null )
		&& ( getReasonCharCannotPartakeInAnalSexReceiving( getRoleChar("dom"), "dom" ) == null )
	)

func recoverSubStamina() -> void:
	var sub = getRoleChar("sub")

	if( sub.getStamina() >= 20 ):
		return

	subStaminaRecovered = int( ceil( min( 20 - sub.getStamina(), 5 ) ) )
	sub.addStamina(subStaminaRecovered)

func getSubLustRatio() -> float:
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var forcedObedienceRatio = clamp( sub.getForcedObedienceLevel(), 0.0, 1.0 )
	var subPersonalitySubbyRatio = ( subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) + 1.0 ) / 2.0
	var interestInAnalSexReceiving = subPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })

	var lustRatioFromSubbinessRatio = subPersonalitySubbyRatio
	var lustRatioFromBrattinessRatio = 1.0 - (0.6 * subBrattinessRatio)
	var lustRatioFromInterestInAnalSexReceiving = clamp(interestInAnalSexReceiving + 1.0, 0.0, 1.0)

	var lustRatioCombined = lerp(
		(
				lustRatioFromSubbinessRatio
			* lustRatioFromBrattinessRatio
			* lustRatioFromInterestInAnalSexReceiving
		),
		1,
		(0.3 * forcedObedienceRatio)
	)

	var subLustRatio:float = clamp(
		(
				subAdditionalLustFromSpecials
			+ (
					(0.30 * lustRatioCombined)
				* (subResistedTimes + subSoftenedTimes)
			)
		),
		0.0,
		1.0
	)
	
	return subLustRatio

func resetLustState() -> void:
	for role in ["dom", "sub"]:
		var character = getRoleChar(role)
		var items = character.getInventory().getAllEquippedItems()
		for itemSlot in items:
			var item = items[itemSlot]
			item.resetLustState()
		character.updateAppearance()
