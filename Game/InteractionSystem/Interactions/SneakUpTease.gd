extends PawnInteractionBase

const DOM_FLIRT_COOLDOWN_TURNS:int = 3
const DOM_SPECIAL_ACTION_COOLDOWN_TURNS:int = 3

const SUB_SNARK_COOLDOWN_TURNS:int = 3
const SUB_STAMINA_COST_BREAK_FREE:int = 40
const SUB_STAMINA_COST_POWER_REVERSAL_ATTEMPT:int = 20
const SUB_MAX_RESISTING_TURNS_WHEN_STANDING:int = 10
const SUB_MAX_RESISTING_TURNS_TOTAL:int = 20
const SUB_MAX_WAITING_ON_DOM_TURNS:int = 12

var subResistedTimes:int = 0
var subResistedWhileNotWaitingOrHesitatingTimes:int = 0
var subResistedWithAttentionDivertAttemptTimes:int = 0
var subSoftenedTimes:int = 0
var subSoftenedWhileWaitingTimes:int = 0
var subResistOrSoftenEventText:String = ""
var subRubbedAgainstDomTimes:int = 0
var subSnarkCooldown:int = 0
var subSnarkUsedTimes:int = 0
var subBrattinessRatio:float = 0.5
var subMayBegToBeFreelyUsed:bool = false
var subMayAttemptAttentionDivert:bool = false
var subMayAttemptPowerReversal:bool = false
var subPowerReversalUnequippedRestraints:Array = []
var subPowerReversalObtainedRestraints:Array = []
var subPowerReversalPersistentDict:Dictionary = {}
var subAdditionalLustFromSpecials:float = 0.0
var subStaminaRecovered:int = 0
var subConsentedToUndressing:bool = false
var subConsentedToAnalSexReceiving:bool = false
var subConsentedToAnalSexGiving:bool = false
var subConsentedToFreeUse:bool = false
var subIsTooFrightenedToEscape:bool = false
var subWasHypnotizedIntoKneeling:bool = false
var subWasHypnotizedIntoStandingStill:bool = false
var subEscapeUponEaseGripProbability:float = 0.0
var subKneeledAtInteractionStart:bool = false
var subIntendsToKneel:bool = false
var subIntendsToStandStill:bool = false
var subAttemptedPowerReversal:bool = false
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

	if( _args.has("subKneeled") && _args["subKneeled"] ):
		subKneeledAtInteractionStart = true
		subResistedTimes = 1
		subResistedWhileNotWaitingOrHesitatingTimes = 1
		subConsentedToFreeUse = true
		subConsentedToUndressing = true
		subConsentedToAnalSexReceiving = true
		subConsentedToAnalSexGiving = true
		setState("kneeled", "dom")
	else:
		setState("", "sub")

	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
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

	var subPersonalityBratRatio:float = ( subPawn.scorePersonalityMax({ PersonalityStat.Brat: 1.0 }) + 1.0 ) / 2.0
	subBrattinessRatio = clamp( ( subPersonalityBratRatio + RNG.randf_range(-0.4, 0.4) ), 0.0, 1.0 )

	subMayAttemptAttentionDivert = RNG.chance(10)

	if(!subKneeledAtInteractionStart):
		var subPersonalitySubbyRatio:float = ( subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) + 1.0 ) / 2.0
		var subPersonalityImpatientRatio:float = ( subPawn.scorePersonalityMax({ PersonalityStat.Impatient: 1.0 }) + 1.0 ) / 2.0
		subMayBegToBeFreelyUsed = RNG.chance( 5.0 * subPersonalitySubbyRatio + 5.0 * subPersonalityImpatientRatio )

		if(!subMayBegToBeFreelyUsed):
			var successChance_usingStrength:float = getSubPowerReversalSuccessChance(Stat.Strength)
			var successChance_usingAgility:float = getSubPowerReversalSuccessChance(Stat.Agility)
			var powerReversalMaySucceed:bool = max(successChance_usingStrength, successChance_usingAgility) > 30.0
			var domPersonalitySubbyRatio:float = ( domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) + 1.0 ) / 2.0
			# If the sub is too subby they won't attempt this, but whether they are is checked every turn
			var chanceToAttemptPowerReversal:float = 5.0 + 20.0 * domPersonalitySubbyRatio
			subMayAttemptPowerReversal = powerReversalMaySucceed && RNG.chance(chanceToAttemptPowerReversal)


func init_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domPersonalitySubbyScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var domIsDommy:bool = domPersonalitySubbyScore < -0.4

	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4

	var domInterestInLactation:float = domPawn.scoreFetishMax({ Fetish.Lactation: 1.0 })
	var domLikesLactation:bool = domInterestInLactation >= 0.5

	var possible:Array = []

	var subResistedOrSoftenedTimes:int = subResistedTimes + subSoftenedTimes
	var hasDomFlirtedThisTurn:bool = (domFlirtCooldown == DOM_FLIRT_COOLDOWN_TURNS)
	var subLustRatio:float = getSubLustRatio()
	var domForcedObedienceRatio:float = clamp( dom.getForcedObedienceLevel(), 0.0, 1.0 )
	var affectionValue:float = domPawn.getAffection(subPawn)
	var doesSubHaveBreastsDomIsInterestedIn:bool = ( domLikesLactation && sub.hasNonFlatBreasts() )

	if(domSpecialActionKeyLastUsed == "none"):
		var isIntro = (subResistedOrSoftenedTimes < 1)

		if(isIntro):
			possible.append_array([
				"{dom.You} tightly {dom.youVerb('grip')} both of {sub.your} wrists as they're pinned behind {sub.yourHis} back. {dom.YourHis} breath cascades against {sub.yourHis} neck, making {sub.youHim} feel intimated in {dom.yourHis} presence.",
				"{dom.You} firmly {dom.youVerb('grip')} {sub.your} arms as they're held together behind {sub.yourHis} spine. {dom.YouHe} {dom.youHeVerb('lean')} forward, forcing {sub.youHim} to bend over, even if just a little.",
			])
		else:
			var domHasExposedPenis:bool = dom.hasBodypart(BodypartSlot.Penis) && !dom.isBodypartCovered(BodypartSlot.Penis)
			var domFrontBodypart:String = "crotch" if(!domHasExposedPenis) else ( "{dom.penisDesc} "+ RNG.pick(["cock", "dick", "member"]) )

			var rub_needily_variants:Array = ["alluringly", "casually", "cravingly", "desperately", "eagerly", "helplessly", "indecently", "involuntarily", "lustfully", "naughtily", "needily", "playfully", "possessively", "self-indulgently", "slowly", "suggestively", "teasingly", "thoroughly"]

			if(subConsentedToUndressing):
				rub_needily_variants.append_array(["excitedly", "immodestly", "insatiably", "intimately", "lasciviously", "messily", "passionately", "shamelessly", "sloppily"])

			if(domForcedObedienceRatio > 0.4):
				rub_needily_variants.append_array(["blissfully", "impulsively", "instinctively"])
			if(domForcedObedienceRatio > 0.8):
				rub_needily_variants.append_array(["enchantedly", "mindlessly"])

			if(!domIsMean):
				rub_needily_variants.append_array(["softly", "warmly"])

				if(affectionValue > 0.7):
					rub_needily_variants.append_array(["affectionately", "lovingly"])

				if(!subConsentedToUndressing):
					rub_needily_variants.append_array(["carefully", "delicately", "gently", "sweetly"])

			if(domIsDommy):
				rub_needily_variants.append_array(["assertively"])

			var rub_needily:String = RNG.pick(rub_needily_variants)
			var tease_needily:String = RNG.pick(["consciously", "intently"]) if( rub_needily in ["involuntarily", "teasingly"] ) else rub_needily

			var shape_sexy:String = RNG.pick(["alluring", "arousing", "captivating", "charming", "delightful", "exquisite", "fuckable", "inviting", "irresistible", "luscious", "pleasurable", "provocative", "sexy"])

			possible.append_array([
				( "{dom.You} "+ ( "intimately " if(subConsentedToUndressing) else "" ) +"{dom.youVerb('brush', 'brushes')} {dom.yourHis} whole body against {sub.yours}, "+ RNG.pick(["huffing quietly", "panting softly"]) +".." ),
				(
						"{dom.You} {dom.youVerb('tease')} {sub.you} by "
					+ tease_needily
					+" brushing "
					+ (
							(
									"both of {dom.yourHis} thighs against the outer sides of {sub.yoursHis}.."
								+ (
										" F- Fuck.. That's hot.."
									if( sub.isPlayer() && RNG.chance(10) )
									else ""
								)
							)
						if(subConsentedToUndressing && subWasPinnedToTheGround)
						else ( "one of {dom.yourHis} thighs against the inner side of {sub.yourHis} "+ RNG.pick(["left", "right"]) +" thigh.." )
					)
				),
			])

			var dom_doesWhat_part1_variants:Array = [
				"{dom.youVerb('make')} an effort to draw out more needy squirms out of {sub.you}",
				"{dom.youVerb('perform')} another attempt at enticing {sub.you}",
				"{dom.youVerb('seek')} to evoke more lustful feelings within {sub.you}",
				"{dom.youVerb('strive')} to arouse {sub.you} with a hint of intimacy",
				"{dom.youVerb('use')} {dom.yourHis} charm on {sub.you}",
			]

			var dom_doesWhat_part2_variants:Array = [
				".. {dom.YouHe} {dom.youAreHeIs} particularly good at it..",
				".. It is difficult for {sub.youHim} to ignore..",
				( ", reaching for {sub.yourHis} "+ RNG.pick(["left", "right"]) +" ear, fondling and gently squeezing it.." ),
				", getting one of {dom.yourHis} paws in {sub.yourHis} face, and indecently running it through {sub.yourHis} face cheeks..",
				( ", "+ RNG.pick(["lustfully", "possessively", "teasingly"]) +" grabbing onto {sub.yourHis} neck from its front side.." ),
				(
						( ", gently pressing {dom.yourHis} digits at the tip of {sub.yourHis} "+ shape_sexy +" breasts.." )
					if( doesSubHaveBreastsDomIsInterestedIn && RNG.chance(80) )
					else ", gently running {dom.yourHis} digits through {sub.yourHis} curvy spine.."
				),
				( ", reaching around and "+ rub_needily +" brushing {dom.yourHis} "+ RNG.pick(["left", "right"]) +" paw across {sub.yourHis} "+( "impregnated" if( sub.isVisiblyPregnant() ) else "soft" )+" belly.." ),
			]

			for n in 3:
				if( ( dom_doesWhat_part1_variants.size() >= 1 ) && ( dom_doesWhat_part2_variants.size() >= 1 ) ):
					possible.append_array([
						(
								"{dom.You} "
							+ RNG.grab(dom_doesWhat_part1_variants)
							+ RNG.grab(dom_doesWhat_part2_variants)
						),
					])

			var isAbleToRubBetweenButtcheeks:bool = (
					subConsentedToUndressing
				&& !dom.isBodypartCovered(BodypartSlot.Penis)
				&& !sub.isBodypartCovered(BodypartSlot.Anus)
			)

			if(isAbleToRubBetweenButtcheeks):
				var subRearBodypart:String = ( RNG.pick(["bare", "charming", "exposed"]) + " buttcheeks" )

				possible.append_array([
					( "{dom.You} "+ rub_needily +" {dom.youVerb('rub')} {dom.yourHis} "+ domFrontBodypart +" between {sub.your} "+ subRearBodypart +"." ),
				])
			else:
				var subRearBodypart:String = "clothed butt" if( sub.isBodypartCovered(BodypartSlot.Anus) ) else ( RNG.pick(["bare", "charming", "exposed"]) + " butt" )

				possible.append_array([
					( "{dom.You} "+ rub_needily +" {dom.youVerb('rub')} {dom.yourHis} "+ domFrontBodypart +" against {sub.your} "+ subRearBodypart +"." ),
				])

			var isAbleToRubBetweenThighs:bool = (
					subConsentedToUndressing
				&& !dom.isBodypartCovered(BodypartSlot.Penis)
			)

			if(isAbleToRubBetweenThighs):
				var subThighsBodypart:String = ( RNG.pick(["bare", "charming", "exposed"]) + " thighs" )

				possible.append_array([
					"{dom.You} "+ rub_needily +" {dom.youVerb('brush', 'brushes')} {dom.yourHis} "+ domFrontBodypart +" between {sub.your} "+ subThighsBodypart +".",
				])

			if( !hasDomFlirtedThisTurn && !dom.isBitingBlocked() ):
				possible.append_array([
					(
							"{dom.You} quietly {dom.youVerb('whisper')} something into {sub.your} ear. "
						+ (
								(
										( "{sub.YouHe} "+ RNG.pick(["{sub.youHeVerb('react')}", "{sub.youHeVerb('respond')}"]) +" by "+ RNG.pick(["pushing", "shoving"]) +" {dom.youHim} away with {sub.yourHis} shoulder." )
									if( (subResistedTimes >= 5) && (subLustRatio < 0.5) )
									else "{sub.YouHe} {sub.youHeVerb('conceal')} {sub.yourHis} reaction well, but there definitely was one.."
								)
							if(subIsMean)
							else RNG.pick([
								"It makes {sub.youHim} incredibly flustered..",
								"{sub.YourHis} face cheeks turn red in an instant..",
								( "H- Huff.." if( sub.isPlayer() ) else "It made {sub.youHim} huff.." ),
							])
						)
					),
				])

			if( !dom.isBlindfolded() ):
				possible.append_array([
					(
							"{dom.You} "
						+ RNG.pick([
							"cannot keep {dom.yourHis} eyes away from",
							"can't help but stare at",
							"{dom.youVerb('find')} {dom.yourselfThemself} deeply fixating on",
						])
						+ " {sub.your} "
						+ RNG.pick([
							(shape_sexy +" body"),
							(
									( RNG.pick(["plump", "round"]) +" breasts" )
								if(doesSubHaveBreastsDomIsInterestedIn)
								else "curvy spine"
							),
							(shape_sexy +" curves")
						])
						+ ".." ),
				])

			if(!domIsMean):
				var nuzzle_playfully_variants:Array = ["gently", "playfully", "softly", "sweetly", "warmly"]

				if(affectionValue > 0.7):
					nuzzle_playfully_variants.append_array(["affectionately", "lovingly"])

				var nuzzle_playfully:String = RNG.pick(nuzzle_playfully_variants)

				possible.append_array([
					( "{dom.You} {dom.youVerb('nuzzle')} "+ nuzzle_playfully +" into {sub.your} spine, still keeping hold of {sub.yourHis} wrists" + ( " with one paw, while the other strays a little further away, indecently exploring {sub.yourHis} "+ RNG.pick(["left", "right"]) +" thigh" if(subConsentedToUndressing) else "" ) +".." ),
				])

		saynn( RNG.pick(possible) )
	else:
		if(domSpecialActionKeyLastUsed == "bite"):
			incl_post_dom_special_bite_text()

		domSpecialActionKeyLastUsed = "none"

	if(hasDomFlirtedThisTurn):
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

	var subResistProbability:float = 4.0 - min( (subLustRatio * 5.0), 3.5 )

	var staminaUseInformation:String = " Uses 5 stamina." if(!subWasPinnedToTheGround) else ""
	addAction("resist", "Resist", ("Try to resist." + staminaUseInformation), "default", subResistProbability, 60, {})

	if(subResistedTimes >= 1):
		if(!subWasPinnedToTheGround):
			addAction("remain_still", "Stand still", "Try to replenish some stamina.", "default", 1.0, 60, {})
		else:
			addAction("remain_still", "Lay still", "Remain helplessly pinned down.", "default", 1.0, 60, {})

	if(subResistedOrSoftenedTimes >= 5):
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
	elif(subResistedOrSoftenedTimes >= 3):
		if(!subConsentedToFreeUse):
			var subPersonalityImpatientRatio:float = ( subPawn.scorePersonalityMax({ PersonalityStat.Impatient: 1.0 }) + 1.0 ) / 2.0
			var subResistedOrSoftenedTimesMustMatch:int = 3 if(subPersonalityImpatientRatio > 0.5) else 4
			var subShouldBegToBeFreelyUsed:bool = ( subMayBegToBeFreelyUsed && (subResistedOrSoftenedTimes == subResistedOrSoftenedTimesMustMatch) )
			addAction("beg_to_be_freely_used", "Beg: Use me", "Beg them to use you however they please.", "default", 100.0 if(subShouldBegToBeFreelyUsed) else -0.01, 60, {})

	if( !subWasPinnedToTheGround && (subResistedTimes >= 1) ):
		var subHasStaminaToAttemptPowerReversal:bool = ( sub.getStamina() >= SUB_STAMINA_COST_POWER_REVERSAL_ATTEMPT )
		var ACTION_NAME_POWER_REVERSAL:String = "Reverse roles..."

		if(!subAttemptedPowerReversal && subHasStaminaToAttemptPowerReversal):
			var subIsSubby:bool = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) > 0.4
			var powerReversalProbability:float = ( 1.40 + 0.20 * subResistedTimes ) if(!subIsSubby && subMayAttemptPowerReversal) else -0.01

			addAction("power_reversal_choices", ACTION_NAME_POWER_REVERSAL, ( "View power reversal options.\nChoosing one of the options will consume "+ str(SUB_STAMINA_COST_POWER_REVERSAL_ATTEMPT)+ " stamina." ), "default", powerReversalProbability, 0, {})
		elif(subAttemptedPowerReversal):
			addDisabledAction(ACTION_NAME_POWER_REVERSAL, "This hasn't gone well for you the last time, you're not willing to try it again.")
		else:
			addDisabledAction(ACTION_NAME_POWER_REVERSAL, "You need "+ str(SUB_STAMINA_COST_POWER_REVERSAL_ATTEMPT) + " stamina to attempt power reversal.")

	if( (subResistedTimes == 0) && sub.isPlayer() ):
		var spacerActionsCount = 4 - actionBuffer.size()
		for n in spacerActionsCount:
			addDisabledAction( "", getSpacerText() if((n + 1) == spacerActionsCount) else "" )

		addAction("mod_settings", "Mod Settings", "Configure SneakUpTease mod.", "default", -0.01, 60, {})

func init_do(_id:String, _args:Dictionary, _context:Dictionary):
	var sub = getRoleChar("sub")

	incl_sub_do()

	if(_id == "immediately_break_free"):
		sub.addStamina(-SUB_STAMINA_COST_BREAK_FREE)
		affectAffection("dom", "sub", -0.1)
		setState("immediately_broke_free", "sub")
	elif(_id == "resist"):
		incl_sub_resist_do()
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
	elif(_id == "beg_to_be_freely_used"):
		subConsentedToFreeUse = true
		subConsentedToUndressing = true
		subConsentedToAnalSexReceiving = true
		subConsentedToAnalSexGiving = true
		setState("kneeled", "dom")
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
	elif(_id == "power_reversal_choices"):
		setState("choosing_power_reversal_option", "sub")
	elif(_id == "mod_settings"):
		setState("mod_settings", "sub")


func after_sub_resisted_text():
	var sub = getRoleChar("sub")

	incl_after_sub_resisted_text()

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

	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4

	var sub_in_front_of_OR_beneath:String = "in front of" if(!subWasPinnedToTheGround) else "beneath"
	var sub_stand_OR_lay:String = "stand" if(!subWasPinnedToTheGround) else "lay"
	var sub_youVerb_stand_OR_lay:String = "{sub.youVerb('stand')}" if(!subWasPinnedToTheGround) else "{sub.youVerb('lay')}"
	var sub_youHeVerb_stand_OR_lay:String = "{sub.youHeVerb('stand')}" if(!subWasPinnedToTheGround) else "{sub.youHeVerb('lay')}"

	var subLustRatio:float = getSubLustRatio()

	var possible:Array = []

	if(subLustRatio < 0.25):
		if(!subWasPinnedToTheGround):
			possible.append_array([
				"{sub.Your} knees tremble a little bit, but {sub.youHe} {sub.youHeVerb('remain')} still.",
			])
		else:
			possible.append_array([
				"A shiver runs through {sub.your} body, but {sub.youHe} {sub.youHeVerb('remain')} laying still.",
			])

		if(subResistedTimes >= 2):
			possible.append_array([
				"{sub.You} briefly {sub.youVerb('remain')} in {sub.yourHis} current pose, still fueled with resistance, but not yet acting on it.",
				"{sub.You} {sub.youVerb('spend')} some time to consider the options that are available to {sub.youHim}.",
				( "{sub.You} "+ sub_youVerb_stand_OR_lay +" still for a little while, saving stamina as {sub.youHe} {sub.youHeVerb('try', 'tries')} to come up with a better plan to break out." ),
			])

		possible.append_array([
			( "{sub.You} "+ sub_youVerb_stand_OR_lay +" obediently still, or at least {sub.youVerb('make')} an impression of doing so." ),
		])
	elif(subLustRatio < 0.50):
		if(!subWasPinnedToTheGround):
			possible.append_array([
				"{sub.You} {sub.youVerb('stand')} still, lightly panting, hoping to recover some stamina for another attempt to free {sub.yourselfThemself}.",
			])

		possible.append_array([
			"{sub.You} {sub.youVerb('try', 'tries')} to focus on finding a way out of this situation, but it's starting to become.. difficult..",
			"For a brief while, {sub.you} {sub.youDoHeDoes} not seem to oppose {dom.you} much. {dom.YouHe} {dom.youHeVerb('wonder')} if {sub.youreTheyre} slowly warming up to {dom.youHim}, or merely trying to catch {sub.yourHis} breath.",
		])
	else:
		if(!subWasPinnedToTheGround):
			if( sub.getStamina() >= 25 ):
				# Has stamina left to spare
				possible.append_array([
					"{sub.You} still {sub.youHave} stamina left to spare, but {sub.youreTheyre} beginning to question whether it's better to just.. give in.",
				])

		possible.append_array([
			"{sub.You} {sub.youVerb('get')} lost in the thought, forgetting to struggle for a moment. Whatever's on {sub.yourHis} mind must have been rather.. tempting.",
			"{dom.You} {dom.youVerb('notice')} that {sub.you} {sub.youHavent} been resisting as much anymore. {sub.YouHe} still {sub.youHeVerb('nudge')} away on occasion, but from {sub.yourHis} movements {sub.youHe} {sub.youHeVerb('seem')}.. rather aroused.",
			"{sub.Your} heart rate grows high as {sub.youreTheyre} going through all possibilities, but {sub.yourHis} mind fixates imagining every outcome where {sub.youHe} *{sub.youHeVerb('fail')}* to break free..",
			( "{sub.Your} mind spirals throughout all kinds of corrupted thoughts, as {sub.youHe} "+ sub_youHeVerb_stand_OR_lay +" still for a little bit, taking no action to break out." ),
			( "{sub.Your} will is bordering on a state of disarray, leaving {sub.youHim} to "+ sub_stand_OR_lay +" helpless, even when presented with an opportune moment to break free." ),
			"{sub.You} {sub.youVerb('cling')} to the temptation that {sub.youHe} found {sub.yourselfThemself} in, refusing to spare any effort to resist..",
			( "{sub.You} "+ RNG.pick(["{sub.youVerb('huff')}", "{sub.youVerb('pant')}"]) +" profusely as {sub.youHe} "+ sub_youHeVerb_stand_OR_lay +" "+ sub_in_front_of_OR_beneath +" {dom.you}, basking in self-reflection over numerous uncertainties that absorb {sub.yourHis} mind." ),
			( "{sub.You} {sub.youVerb('ruminate')} on what is it that {sub.youHe} truly {sub.youHeVerb('want')} from {dom.you}. The answers that come to {sub.yourHis} mind seem to be rather unlike what they used to be mere minutes ago. This realization "+ ( "fusses" if(subIsMean) else "flusters" ) +" {sub.youHim} quite a bit.." ),
		])

	saynn( RNG.pick(possible) )

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

		saynn( RNG.pick(possible) )

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

			saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )
	else:
		var subShouldStammerFromLust:bool = (
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

			saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

	if( sub.isPlayer() && (subStaminaRecovered > 0) ):
		addMessage( "{sub.You} recovered "+ str(subStaminaRecovered) +" stamina." )

	incl_after_sub_resisted_or_softened_text()

func after_sub_softened_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func incl_after_sub_resisted_text():
	if(subResistOrSoftenEventText != ""):
		saynn(subResistOrSoftenEventText)

	if(subSnarkCooldown == SUB_SNARK_COOLDOWN_TURNS):
		incl_post_sub_snark_text()

func incl_after_sub_resisted_or_softened_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	var subResistedOrSoftenedTimes = subResistedTimes + subSoftenedTimes
	var subResistedTimesMax = SUB_MAX_RESISTING_TURNS_WHEN_STANDING if(!subWasPinnedToTheGround) else SUB_MAX_RESISTING_TURNS_TOTAL
	var canRubAgainstSub = (subResistedWhileNotWaitingOrHesitatingTimes <= subResistedTimesMax)

	var canSubBeUndressed:bool = false
	if(subConsentedToUndressing):
		if( !subWasUndressed && !domWasUndressed && !sub.isFullyNaked() && !dom.isFullyNaked() ):
			canSubBeUndressed = true
			addAction("undress_both", "Undress both", "Take off all clothes from both you and the sub.", "default", 100.0, 120, {})
		elif( !subWasUndressed && !sub.isFullyNaked() ):
			canSubBeUndressed = true
			addAction("undress_sub", "Undress sub", "Take off all their clothes.", "default", 100.0, 60, {})
		elif( !domWasUndressed && !dom.isFullyNaked() ):
			canSubBeUndressed = true
			addAction("undress_self", "Undress self", "Take off all your clothes.", "default", 100.0, 60, {})

	if(subConsentedToFreeUse && canSubBeUndressed):
		return

	var canAdvanceToFinale = (
			subConsentedToFreeUse
		|| subConsentedToAnalSexReceiving
		|| subConsentedToAnalSexGiving
		|| (!canRubAgainstSub && subWasPinnedToTheGround)
	)

	if(canAdvanceToFinale):
		addAction("advance_to_finale", "Advance", "Time for some fun..", "default", 1.0, 60, {})
		return

	if(canRubAgainstSub):
		addAction("rub", "Keep rubbing", "Continue rubbing them~", "default", 1.0, 60, {})

		if(!subWasPinnedToTheGround):
			if( (subResistedOrSoftenedTimes >= 3) && (domSpecialActionCooldown == 0) ):
				if( !dom.isBitingBlocked() ):
					addAction("special_bite", "Special: Bite", "Chomp on one of their body parts.", "default", 0.7, 60, {})
				else:
					addDisabledAction("Special: Bite", "Restraints on your muzzle prevent you from doing this.")
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

	clearMessagesForChar(sub)

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
			domWasUninterestedInSexEngineAction = ( false if( dom.isPlayer() ) else subConsentedToFreeUse ),
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
		"{sub.You} "+ sub_youVerb_stand_OR_lay +" eagerly still as {dom.you} assertively {dom.youVerb('strip')} {sub.youHim} of {sub.yourHis} clothes. Before {sub.you} {sub.youVerb('manage')} to shake the lust off, {sub.youHe} {sub.youHeVerb('notice')} that all of {dom.your} clothes are now also scattered on the ground. Positioned "+ creature_behind_OR_above +" {sub.you} "+ creature_stands_OR_lays +" a hot, naked creature.",
	]

	saynn( RNG.pick(possible) )

	incl_after_anyone_undressed_text()
	incl_after_sub_resisted_or_softened_text()

func undressed_both_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func undressed_sub_text():
	var dom_standing_OR_laying = "standing" if(!subWasPinnedToTheGround) else "laying"
	var dom_behind_OR_above = "behind" if(!subWasPinnedToTheGround) else "above"
	var sub_youVerb_stand_OR_lay = "{sub.youVerb('stand')}" if(!subWasPinnedToTheGround) else "{sub.youVerb('lay')}"

	var possible = [
		"{sub.You} "+ sub_youVerb_stand_OR_lay +" obediently still, panting, as {dom.you} {dom.youVerb('remove')} all {sub.yourHis} clothes. {sub.YouHe} {sub.youHeVerb('struggle')} not to be aroused, as when you press together, {sub.youHe} {sub.youHeVerb('realize')} that from the very beginning {dom.you} {dom.youWere} "+ dom_standing_OR_laying +" "+ dom_behind_OR_above +" {sub.youHim} fully naked.",
		"{sub.You} {sub.youDo} not resist as {dom.you} meticulously {dom.youVerb('remove')} every piece of clothing covering {sub.yourHis} body. {sub.YouHe} {sub.youHeVerb('notice')} that {dom.you} never had any clothing on {dom.youHim}, and that realization leaves {sub.youHim} a little pent up.",
	]

	saynn( RNG.pick(possible) )

	incl_after_anyone_undressed_text()
	incl_after_sub_resisted_or_softened_text()

func undressed_sub_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func undressed_self_text():
	var sub_youVerb_stand_OR_lay = "{sub.youVerb('stand')}" if(!subWasPinnedToTheGround) else "{sub.youVerb('lay')}"

	var possible = [
		"{dom.You} quickly {dom.youVerb('remove')} {dom.yourHis} clothes as {sub.you} "+ sub_youVerb_stand_OR_lay +" eagerly still. {dom.YouveTheyve} been glaring at {sub.yourHis} exposed body for a very long time, mind drifting in the thought of all the things {dom.youHe}'d want to do to {sub.youHim}.",
	]

	saynn( RNG.pick(possible) )

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
				"{sub.You} {sub.youVerb('notice')} {dom.your} eyes briefly fixating on {sub.yourHis} "+ sub_penis +", before {dom.youHe} {dom.youVerb('look')} away, conscious of the fact {dom.youveTheyve} been staring far longer than {dom.youHe} thought.",
			])

	saynn( RNG.pick(possible) )


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

	saynn( RNG.pick(possible) )

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

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

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
			"{sub.Your} "+ ( "legs tremble" if(!subWasPinnedToTheGround) else "body trembles" ) +" as {sub.youHe} {sub.youHeVerb('start')} to find it futile to resist the temptation.",
		])

	saynn( RNG.pick(possible) )
	
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

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

	if(hasDomRefusedRequest):
		incl_dom_refuse_request_text({ speechComprehensibility = speechComprehensibility })

	incl_after_sub_resisted_or_softened_text()

func begged_for_anal_sex_receiving_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func rubbed_against_dom_text():
	var possible = []

	var isConsentingToUndress = (domRefusedPenetrationRequestTimes != -1)
	var isConsentingToUndressButIntentUnclear = ( isConsentingToUndress && !subConsentedToUndressing )
	var isConsentingToUndressWhichWasUnclearLastTime = ( isConsentingToUndress && (subRubbedAgainstDomTimes == 2) )
	var isConsentingToToAnalSexReceiving = subConsentedToAnalSexReceiving

	if(isConsentingToUndressButIntentUnclear):
		possible.append_array([
			"{dom.You} {dom.youVerb('feel')} like {sub.you} {sub.youHave} just rubbed {dom.youHim} in return, though it might have been wishful thinking, so {dom.youHe} {dom.youDoHeDoes} not assign much value to that.",
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
			"{sub.You} [color="+ getSensationColor("comfort") +"]needily {sub.youVerb('rub')} {sub.yourHis} buttchecks against {dom.you}[/color], begging {dom.youHim} to enter {sub.youHim}. {sub.YouHe} {sub.youDoHeDoes} not let any words leave {sub.yourHis} mouth, delegating everything to the body language. Even so, {sub.yourHis} intent and desires are clear.",
			"{sub.You} [color="+ getSensationColor("comfort") +"]cravingly {sub.youVerb('brush', 'brushes')} {sub.yourHis} buttchecks against {dom.you}[/color], imploring {dom.youHim} to penetrate {sub.yourHis} hole. Despite no words having been exchanged, {sub.yourHis} motivation was conveyed well, leaving {dom.you} a little pent up in excitement.",
		])
	else:
		possible.append_array([
			"{sub.You} [color="+ getSensationColor("comfort") +"]needily {sub.youVerb('rub')} against {dom.you}[/color], wondering if {dom.youHe} would be open to something else.",
		])

	if( possible.size() > 0 ):
		saynn( RNG.pick(possible) )

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

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

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

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domIsKind:bool = domPersonalityMeanScore < -0.4

	var possible:Array = [
		"{dom.You} {dom.youVerb('nod')}."
	]

	saynn( RNG.pick(possible) )

	var hasDomAgreedToAnalSexReceiving:bool = subConsentedToAnalSexGiving

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

		saynn( "[say=dom]"+ RNG.pick(possible) +"[/say]" )

	addAction("advance_to_finale", "Advance", "Time for some fun..", "default", 1.0, 10, {})

func agreed_to_something_else_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func refused_something_else_text():
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	#var domIsKind:bool = domPersonalityMeanScore < -0.4

	var possible:Array = [
		"{dom.You} {dom.youVerb('shake')} head."
	]

	saynn( RNG.pick(possible) )

	if( RNG.chance(50) ):
		var domInterestInAnalSexReceiving:float = domPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })
		var domDislikesAnalSexReceiving:bool = domInterestInAnalSexReceiving < -0.5

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

		saynn( "[say=dom]"+ RNG.pick(possible) +"[/say]" )

	var haveExhaustedAllPossibleOptions = !getSubAnalSexReceivingPossible()

	if(haveExhaustedAllPossibleOptions):
		addAction("advance_to_finale", "Advance", "Time for some fun..", "default", 1.0, 10, {})
	else:
		incl_after_sub_resisted_or_softened_text()

func refused_something_else_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func ran_out_of_patience_text():
	var possible:Array = [
		"{sub.You} {sub.youHave} ran out of patience.",
	]

	saynn( RNG.pick(possible) )

	addAction("break_free", "Break free", "Your discontent revealed the strength to free yourself.", "default", 1, 60, {})

func ran_out_of_patience_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "break_free"):
		setState("broke_free_after_running_out_of_patience", "sub")


func broke_free_after_running_out_of_patience_text():
	var subPawn = getRolePawn("sub")

	var subIsMean:bool = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4

	var possible:Array = []

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

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

	possible = []

	if(subWasPinnedToTheGround):
		possible.append_array([
			"{sub.You} {sub.youVerb('sigh')}, amassing all {sub.yourHis} strength to roll {dom.you} off {sub.yourHis} back and underneath {sub.yourselfThemself}.",
		])
	else:
		possible.append_array([
			"{sub.You} {sub.youVerb('manage')} to find the strength to buck into {dom.you} with {sub.yourHis} sturdy spine.",
		])

	saynn( RNG.pick(possible) )

	possible = []

	if(subWasPinnedToTheGround):
		possible.append_array([
			"{dom.You} {dom.youHave} lost {dom.yourHis} advantage.",
		])
	else:
		possible.append_array([
			"{dom.You} {dom.youVerb('lose')} balance, sprawling to the floor.",
		])

	saynn( RNG.pick(possible) )

	addAction("leave", "Leave", "Leave them be.", "default", 1.0, 0, {})

func broke_free_after_running_out_of_patience_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "leave"):
		var domPawn = getRolePawn("dom")
		domPawn.afterLostFight()
		resetLustState()
		stopMe()


func ran_out_of_stamina_text():
	var sub = getRoleChar("sub")

	var possible:Array = [
		"{sub.Your} spirit is still strong, but {sub.yourHis} body cannot sustain standing like this. {sub.YourHis} knees give in, causing {sub.youHim} to kneel.",
		"With no stamina left in {sub.you} to stand still, all {sub.youHe} can do is watch {sub.yourselfThemself} sink down on {sub.yourHis} weakened knees.",
		"Unable to endure standing on {sub.yourHis} feet any longer, {sub.you} {sub.youVerb('succumb')} to exhaustion, falling to {sub.yourHis} knees.",
	]

	saynn( RNG.pick(possible) )

	if( sub.isPlayer() ):
		addMessage("{sub.You} used up all of your remaining stamina.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func ran_out_of_stamina_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		subWasPinnedToTheGround = true
		setState("pinned_after_kneeling_or_running_out_of_stamina", "dom")


func pinned_after_kneeling_or_running_out_of_stamina_text():
	var possible:Array = [
		"Seeing {sub.you} so vulnerable, {dom.your} eyes glimmer, and {dom.youHe} ravenously {dom.youHeVerb('push', 'pushes')} {sub.you} forward, pinning {sub.youHim} down underneath.",
		"{dom.You} readily {dom.youVerb('shove')} {sub.you} forward, positioning {dom.yourselfThemself} tightly pinned above {sub.youHim}.",
		"{dom.You} playfully {dom.youVerb('drag')} {sub.you} even further down into the ground, pressing {dom.yourHis} entire body above {sub.yoursHis}.",
	]

	saynn( RNG.pick(possible) )

	incl_after_sub_resisted_or_softened_text()

func pinned_after_kneeling_or_running_out_of_stamina_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func pinned_after_resisting_too_much_text():
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domIsKind:bool = domPersonalityMeanScore < -0.4

	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4

	var possible:Array = [
		"{dom.You} {dom.youHave} gotten rather impatient from {sub.your} stubbornness. {dom.YouHe} hastily {dom.youHeVerb('shove')} {sub.youHim} forward, causing {sub.youHim} to lose balance and fall down on {sub.yourHis} chest. {dom.YouHe} then {dom.youVerb('pounce')} at {sub.you}, pinning {sub.youHim} down helpless.",
		"Seeing that {sub.you} {sub.youVerb('keep')} resisting to no end, {dom.you} {dom.youVerb('conclude')} that {dom.youHe}'d allowed {sub.youHim} more power than {sub.youHe} truly {sub.youHeVerb('deserve')}. {dom.YouHe} then {dom.youHeVerb('lunge')} forward at {sub.youHim}. For a brief moment, {sub.you} {sub.youVerb('lose')} track of {sub.yourHis} surroundings. When {sub.youHe} {sub.youHeVerb('regain')} senses, {sub.youHe} {sub.youHeVerb('notice')} {sub.yourselfThemself} down on {sub.yourHis} belly, with {dom.you} hungrily pinning {sub.youHim} down.",
	]

	saynn( RNG.pick(possible) )
	
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

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

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

	saynn( "[say=dom]"+ RNG.pick(possible) +"[/say]" )

	incl_after_sub_resisted_or_softened_text()

func pinned_after_resisting_too_much_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_after_sub_resisted_or_softened_do(_id, _args, _context)


func eased_grip_text():
	var sub = getRoleChar("sub")

	var subStandInFearProbability:float = 1.0
	var subKneelScoreType:String = "agreeSexAsSub"
	var subKneelProbability:float = 1.0

	var subEscapeProbability:float = subEscapeUponEaseGripProbability
	var subEscapeProbabilityInverse:float = 1 - max(subEscapeProbability, 0.0)

	var possible:Array = []

	saynn("{dom.You} {dom.youVerb('ease')} {dom.yourHis} grip on {sub.your} wrists, now just barely touching them in a playful manner. There's no longer anything that prevents {sub.you} from escaping.")

	if(domAttemptedToHypnotizeSubUponEaseGrip):
		if(subIsTooFrightenedToEscape):
			possible = [
				"Submit to me.",
				"Surrender yourself to me.",
			]

			saynn( "[say=dom]"+ RNG.pick(possible) +"[/say]" )

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

				saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )
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

					saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )
				else:
					subStandInFearProbability = 1.0
					subKneelScoreType = "default"
					subKneelProbability = -0.01

					possible = [
						"I.. will not..",
						"Not.. to the likes.. of you..",
						"Not.. even going to look into my eyes?",
					]

					saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )
		else:
			possible = [
				"Stay.",
			]

			saynn( "[say=dom]"+ RNG.pick(possible) +"[/say]" )

			if(subWasHypnotizedIntoStandingStill):
				possible = [
					"I.. will stay..",
					"I.. shouldn't leave..",
					"This.. won't magically make me want to stay.. H- Huh.. Stay.. That sounds.. comfortable..",
					"I.. cannot refuse..",
				]

				saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )
			elif( !sub.isPlayer() ):
				if(subIntendsToStandStill):
					subEscapeProbabilityInverse = 1.00
					subEscapeProbability = -0.01

					possible = [
						"Somehow, that.. doesn't have an effect on me. But I wasn't planning on leaving~",
						"I.. don't have to listen to you. But.. I'm curious, what is it that you have in store for me..",
						"I can still.. ward off your influence, but.. there's something about you..",
					]

					saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )
				else:
					subEscapeProbability = 1.00
					subEscapeProbabilityInverse = -0.01

					possible = [
						"I don't.. serve you..",
						"You have no power.. over me..",
					]

					saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

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
	saynn( "[say=dom]"+ possibleRandomPick.dialogue +"[/say]" )

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
		"{sub.You} {sub.youAre} given an opportunity to escape, but {sub.youHe} {sub.youHeVerb('seem')} too frightened to move, almost vibrating in place.",
		"{dom.You} carefully {dom.youVerb('observe')} {sub.your} movements with all senses available to {dom.youHim}. {sub.YouHe} {sub.youHeVerb('remain')} standing in place, albeit visibly distressed. Perhaps {sub.youHe} {sub.youHeVerb('see')} this as a test, or {sub.youAreHeIs} too shaken up to move..",
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

	if(subKneeledAtInteractionStart):
		saynn( RNG.pick([
			"{sub.You} {sub.youHave} kneeled submissively in front of {dom.you}.",
		]) )
	elif(subConsentedToFreeUse || subWasHypnotizedIntoKneeling || subIntendsToKneel):
		saynn( RNG.pick([
			"{sub.You} {sub.youVerb('kneel')} submissively in front of {dom.you}.",
		]) )
	else:
		saynn( RNG.pick([
			"Eventually, {sub.you} {sub.youVerb('manage')} to set {sub.youHis} fears aside.. submissively kneeling in front of {dom.you}.",
		]) )

	if(!subKneeledAtInteractionStart && subConsentedToFreeUse):
		incl_free_use_beg_text()

	var domSexScoreType:String = "sexDom"
	var domSexProbability:float = 1.0

	var domPinDownScoreType:String = "punish"
	var domPinDownProbability:float = 1.0

	if( subWasHypnotizedIntoKneeling && sub.isPlayer() ):
		var subInterestInUnconSex:float = subPawn.scoreFetishMax({ Fetish.UnconsciousSex: 1.0 })
		var subLikesUnconSex:bool = subInterestInUnconSex >= 0.5

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
		"{sub.You} {sub.youAre} allowed to freely leave, but {sub.youHe} {sub.youAreHeIs} visibly intimated by {dom.your} presence, not being able to move for about "+ RNG.pick(["ten", "twenty", "thirty"]) +" seconds.",
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

	saynn("{sub.You} can now freely leave, but.. {sub.YouHe} {sub.youHeVerb('remain')} standing there, slightly bent over, as {dom.you} {dom.youVerb('remain')} tightly pressed against {sub.youHim}.")

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

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

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
	var possible = [
		"{dom.You} {dom.youVerb('stand')} up, deciding to leave {sub.you} laying on the ground.",
		"{dom.You} {dom.youVerb('get')} up, feeling like {dom.youveTheyve} had enough playing with {sub.you}.",
	]

	saynn( RNG.pick(possible) )

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


func choosing_power_reversal_option_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	incl_sub_resist_pick_random_event_line()
	incl_after_sub_resisted_text()

	if( sub.isPlayer() ):
		saynn("Which power reversal option would you like to try?")

	var successChance_usingStrength:float = getSubPowerReversalSuccessChance(Stat.Strength)
	var successChance_usingAgility:float = getSubPowerReversalSuccessChance(Stat.Agility)

	var useStrengthProbability:float = 1.0 if(successChance_usingStrength > successChance_usingAgility) else -0.01
	var useAgilityProbability:float = 1.0 if(successChance_usingStrength < successChance_usingAgility) else -0.01
	if(successChance_usingStrength == successChance_usingAgility):
		useStrengthProbability = 0.5
		useAgilityProbability = 0.5

	var ACTION_NAME_OVERPOWER:String = "Overpower"
	var ACTION_NAME_TRICK:String = "Trick"

	if(successChance_usingStrength > 0.0):
		addAction("use_strength", ACTION_NAME_OVERPOWER, ( "Use your strength to swap positions with "+ dom.getName() +".\n[i]Success chance: "+ str(Util.roundF(successChance_usingStrength, 1)) +"%[/i]" ), "default", useStrengthProbability, 60, {})
	else:
		addDisabledAction(ACTION_NAME_OVERPOWER, "No chance this would work..")

	if(successChance_usingAgility > 0.0):
		addAction("use_agility", ACTION_NAME_TRICK, ( "Use your agility to swap positions with "+ dom.getName() +".\n[i]Success chance: "+ str(Util.roundF(successChance_usingAgility, 1)) +"%[/i]" ), "default", useAgilityProbability, 60, {})
	else:
		addDisabledAction(ACTION_NAME_TRICK, "No chance this would work..")

	var spacerActionsCount:int = 4 - actionBuffer.size()
	for n in spacerActionsCount:
		addDisabledAction( "", getSpacerText() if((n + 1) == spacerActionsCount) else "" )

	addAction("cancel", "Cancel", "You changed your mind.", "default", -0.01, 60, {})

func choosing_power_reversal_option_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var subIsDommy:bool = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) < -0.4

	var domInterestInOralSexGiving:float = domPawn.scoreFetishMax({ Fetish.OralSexGiving: 1.0 })
	var domLikesOralSexGiving:bool = (domInterestInOralSexGiving >= 0.5)

	var stat:String = ""
	var statPrefix:String = ""

	if(_id == "use_strength"):
		stat = Stat.Strength
		statPrefix = "strength"
	elif(_id == "use_agility"):
		stat = Stat.Agility
		statPrefix = "agility"

	var possibleScenarios:Array = []
	var wasSuccessful:bool = false

	if( _id in ["use_strength", "use_agility"] ):
		wasSuccessful = RNG.chance( getSubPowerReversalSuccessChance(stat) )

	if(_id == "use_strength"):
		if(wasSuccessful):
			possibleScenarios.append({
				id = "wall_bash",
				sub_unequip_some_restraints = true,
				dom_pain_gain_ratio = 1.5,
			})

			possibleScenarios.append({
				id = "martial_arts",
				reacting_character_dom_or_sub_string = "sub",
				generate_associative_sequence = true,
			})
		else:
			possibleScenarios.append({
				id = "elbow_strike",
				sub_obtain_a_restraint = true,
				dom_pain_gain_ratio = 1.0,
				sub_pain_gain_ratio = 1.0,
			})

			if(!subIsDommy):
				possibleScenarios.append({
					id = "unpersuasive",
					reacting_character_dom_or_sub_string = "dom",
				})
	elif(_id == "use_agility"):
		if(wasSuccessful):
			possibleScenarios.append({
				id = "suddenly_free",
				sub_unequip_some_restraints = true,
			})

			if( domLikesOralSexGiving && !dom.isBitingBlocked() ):
				possibleScenarios.append({
					id = "squishy_bone",
				})

			if( !dom.isBlindfolded() && !dom.isBitingBlocked() && ( sub.hasNonFlatBreasts() || !sub.hasBlockedHands() ) ):
				possibleScenarios.append({
					id = "holocard",
				})
		else:
			possibleScenarios.append({
				id = "dream_of_slime",
			})

			if( dom.getInventory().hasEquippedItemWithTag(ItemTag.AllowsEnslaving) && !sub.hasBlockedHands() ):
				possibleScenarios.append({
					id = "shock_remote",
				})

	if( _id in ["use_strength", "use_agility"] ):
		if( possibleScenarios.size() == 0 ):
			print("[SneakUpTease] Error: Could not find a suitable power reversal scenario.")
			incl_sub_do()
			incl_sub_resist_do()
			return

		var selectedScenario:Dictionary = RNG.pick(possibleScenarios)
		var reactingCharacterDomOrSubString:String = "dom" if(wasSuccessful) else "sub"

		if( selectedScenario.has("sub_unequip_some_restraints") ):
			unequipSubRestraintsPreventingPowerReversal()
		if( selectedScenario.has("sub_obtain_a_restraint") ):
			addSubRestraintUponFailingPowerReversal()
		if( selectedScenario.has("dom_pain_gain_ratio") ):
			dom.addPain( int( selectedScenario.dom_pain_gain_ratio * RNG.randi_range(8, 15) ) )
		if( selectedScenario.has("sub_pain_gain_ratio") ):
			sub.addPain( int( selectedScenario.sub_pain_gain_ratio * RNG.randi_range(8, 15) ) )
		if( selectedScenario.has("reacting_character_dom_or_sub_string") ):
			reactingCharacterDomOrSubString = selectedScenario.reacting_character_dom_or_sub_string
		if( selectedScenario.has("generate_associative_sequence") ):
			subPowerReversalPersistentDict = generateAssociativeSequenceParamsForChar(sub)

		subAttemptedPowerReversal = true
		sub.addStamina(-SUB_STAMINA_COST_POWER_REVERSAL_ATTEMPT)

		var stateName:String = statPrefix +"_power_reversal__"+ ("success" if(wasSuccessful) else "failure") +"__"+ selectedScenario.id +"__1"
		setState(stateName, reactingCharacterDomOrSubString)

	if(_id == "cancel"):
		incl_sub_do()
		incl_sub_resist_do()


func strength_power_reversal__success__wall_bash__1_text():
	var dom = getRoleChar("dom")

	saynn( "{sub.You} {sub.youVerb('use')} {sub.yourHis} raw strength to [color="+ getSensationColor("pain_severe") +"]bash {dom.your} spine into a wall[/color]. Ouch, that must have hurt bad. As {dom.you} desperately {dom.youVerb('try', 'tries')} to maintain grip, or even.. remnants of composure.. {dom.YouHe} {dom.youHeVerb('feel')} {dom.yourHis} chest [color="+ getSensationColor("pain_severe") +"]getting slammed into concrete[/color], and {sub.your} figure is tightly pinning {dom.youHim} against it." )

	var dialogueLines:Array = getDialogueLines_reactToSuccessfulPowerReversal()

	if( dialogueLines.size() > 0 ):
		saynn( "[say=dom]"+ RNG.pick(dialogueLines) +"[/say]" )

	if( subPowerReversalUnequippedRestraints.size() >= 1 ):
		saynn("Didn't {sub.youHe} have restraints on {sub.yourHis} arms?")

		if( dom.isBlindfolded() ):
			saynn("{dom.You} would look for them if it wasn't for this damn blindfold. Well, doesn't matter now, does it.")
		else:
			var lockDesc:String = getLockDescForMostSecureUnequippedRestraint()
			saynn( "{dom.You} {dom.youVerb('rush', 'rushes')} eyes around, only to find what held {sub.youHim} in obedience scattered on the floor."+ ( (" "+ lockDesc +" restraint my ass.") if( dom.isPlayer() && !( lockDesc in ["Level 1", "Level 2"] ) ) else "" ) )

	incl_power_reversal_stamina_cost()
	addAction("continue", "Fuck..", "That hurts..", "default", 1.0, 60, {})

func strength_power_reversal__success__wall_bash__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startPowerReversedInteraction()


func strength_power_reversal__success__martial_arts__1_text():
	var sub = getRoleChar("sub")

	var initialHintIdx:int = subPowerReversalPersistentDict.initialHintIdx

	var initialHintColorString:String = (
			"[color="+ getSensationColor("pain_severe") +"]"
		+ subPowerReversalPersistentDict.sequence[initialHintIdx]
		+ "[/color]"
	)

	if( RNG.chance(50) ):
		var INITIAL_HINT_TEXTS_BY_IDX:Array = [
			"{sub.YouHe} {sub.youHeVerb('remember')} the fragment it started with.. \"<FRAGMENT>\"..",
			"The second fragment was.. \"<FRAGMENT>\".",
			"The third fragment was.. \"<FRAGMENT>\".",
			"\"<FRAGMENT>\" was the final fragment.",
		]

		var initial_hint:String = INITIAL_HINT_TEXTS_BY_IDX[initialHintIdx].replace(
			"<FRAGMENT>",
			initialHintColorString
		)

		saynn("{sub.You} faintly {sub.youVerb('recall')} a martial arts move that could turn the odds in {sub.yourHis} favor. While {sub.your} strength offers great benefit, successfully executing the maneuver would require technique. Reign over the flow of {sub.yourHis} very essence. A state of equilibrium.")

		saynn("For {sub.you}, all it would take is to visualize every moment of it, from start to finish. The massive barrier between reality and fiction would not lay its presence for that split second of opportunity that {sub.youHe} {sub.youHeVerb('crave')}, and solace that {sub.youHe} {sub.youHeVerb('harbor')}.")

		saynn(
				"The animation, in its entirety, is already ahead of {sub.youHim}. Within a mental folder. {sub.YouHe} {sub.youHeVerb('reach', 'reaches')} out to access it, yet its barred beyond what's seemingly an associative sequence. {sub.YouHaveHeHas} {sub.youHe} really password locked a folder in {sub.yourHis} mind?"
			+ (
					" ..In {sub.your} defense, the persecutory delusions were only slightly off the mark."
				if( sub.isInmate() )
				else ""
			)
		)

		saynn( "{sub.YouHe} {sub.youHeVerb('focus', 'focuses')}. "+ initial_hint +" The rest of the sequence is within reach, too. {sub.YourHis} arms hurt. The possibilities are all laid out, awaiting {sub.yourHis} input." )

	else:
		saynn("{sub.Youre} certain there's a way to free {sub.yourselfThemself} out of the hold. Perhaps even exploit {sub.yourHis} temporary freedom for something more.. {sub.YourHis} thoughts are a little murky, yet.. that's {sub.yourHis} *only* obstacle.")

		saynn("Are these words trying to tell a story, or is it a mere glimpse into the chaotic constellations of {sub.your} memories, fears and obsessions?")

		saynn( "There's no way to tidy this up, is there? {sub.YoureTheyre} unsure what even constitutes a solution. Navigating through slivers upon slivers of information, some seem to resonate more than the others. It's faint, but that might be {sub.yourHis} only tell." )

		saynn( "The word \""+ initialHintColorString +"\" slots into the "+ ["first", "second", "third", "fourth"][initialHintIdx] +" position. Or perhaps it had been there from the start? A wave of discomfort passes through {sub.your} sore arms. {sub.YouHe}'ll have to take chances to piece the rest of the sequence." )

	incl_power_reversal_stamina_cost()
	incl_power_reversal__success__martial_arts__list_actions()

func strength_power_reversal__success__martial_arts__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_power_reversal__success__martial_arts__on_action_select(_id)


func strength_power_reversal__success__martial_arts__list_text():
	var currentActionStageIdx:int = getCurrentPowerReversalStageIdx()
	var stageActionList:Array = getCurrentPowerReversalActionList()

	if(currentActionStageIdx == 1):
		var initialHintIdx:int = subPowerReversalPersistentDict.initialHintIdx

		var initialHintColorString:String = (
				"[color="+ getSensationColor("pain_severe") +"]"
			+ subPowerReversalPersistentDict.sequence[initialHintIdx]
			+ "[/color]"
		)

		saynn( "The "+ ["first", "second", "third", "fourth"][initialHintIdx] +" fragment is \""+ initialHintColorString +"\"." )
	else:
		incl_power_reversal__success__martial_arts__say_chosen_sequence()

	var actionIdx:int = 0
	for actionInfo in stageActionList:
		saynn(
				"[b][color=#FFE2BA]Option "+str(actionIdx + 1)+ "[/color][/b]\n"
			+ actionInfo.sequence[0] + ".\n"
			+ actionInfo.sequence[1] + ".\n"
			+ actionInfo.sequence[2] + ".\n"
			+ actionInfo.sequence[3] + "."
		)
		actionIdx += 1

	incl_power_reversal__success__martial_arts__list_actions()

func strength_power_reversal__success__martial_arts__list_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_power_reversal__success__martial_arts__on_action_select(_id)


func strength_power_reversal__success__martial_arts__2correct1_text():
	incl_power_reversal__success__martial_arts__say_chosen_sequence()

	var misplacedFragmentIdx:int = subPowerReversalPersistentDict.chosenSequenceMisplacedFragmentIdx
	var misplacedFragmentValue:String = subPowerReversalPersistentDict.chosenSequence[misplacedFragmentIdx]
	var misplacedFragmentIdxAsString:String = [ "first", "second", "third", RNG.pick(["fourth", "last"]) ][misplacedFragmentIdx]

	var misplacedFragmentColorString:String = (
			"[color="+ getSensationColor("pain_severe") +"]"
		+ misplacedFragmentValue
		+ "[/color]"
	)

	saynn( RNG.pick([
		( "{sub.You} {sub.youVerb('seem')} to be on the right path. \"" + misplacedFragmentColorString + "\" was certainly one of the fragments, just perhaps.. not the "+ misplacedFragmentIdxAsString + " one?" ),
		( "Ooh. \""+ misplacedFragmentColorString +"\".. That word evokes strong emotions within {sub.you}. It's certainly part of the sequence, although not the "+ misplacedFragmentIdxAsString +" entry." )
	]) )

	incl_power_reversal__success__martial_arts__list_actions()

func strength_power_reversal__success__martial_arts__2correct1_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_power_reversal__success__martial_arts__on_action_select(_id)


func strength_power_reversal__success__martial_arts__3correct1_text():
	var sub = getRoleChar("sub")

	incl_power_reversal__success__martial_arts__say_chosen_sequence()

	saynn( RNG.pick([
		"{sub.You} {sub.youHave} almost figured it out. All the noise seems to be filtered out, but.. something is still not quite right..",
		(
				"{sub.You} {sub.youVerb('seem')} incredibly close to piecing this together."
			+ ( " Just.. try not to blow it, okay?.." if( sub.isPlayer() ) else "" )
		),
	]) )

	incl_power_reversal__success__martial_arts__list_actions()

func strength_power_reversal__success__martial_arts__3correct1_do(_id:String, _args:Dictionary, _context:Dictionary):
	incl_power_reversal__success__martial_arts__on_action_select(_id)


func strength_power_reversal__success__martial_arts__4correct1_text():
	var sub = getRoleChar("sub")

	incl_power_reversal__success__martial_arts__say_chosen_sequence()

	saynn(
			"{sub.You} {sub.youVerb('remember')}. "
		+ (
				"Focus. Inhale. Let it play out. "
			if( sub.isPlayer() )
			else "{sub.YouHe} {sub.youHeVerb('focus', 'focuses')}, {sub.youHeVerb('take')} a deep breath, allowing the instinct to play it all out. "
		)
		+ "In an instant, {dom.your} silhouette is tossed upwards. As {sub.yourHis} whole figure revolves beyond surpassing constraints of feral verticality, {sub.yourHis} ankle pivots {dom.youHim} over {sub.yourselfThemself} in an arc, pounding {dom.youHim} into the ground."
	)

	if( subPowerReversalUnequippedRestraints.size() >= 1 ):
		saynn("Arm restraints, no matter how sturdy, were simply not schematized to withstand anything remotely indiscernible from what had just occurred.")

	saynn("{sub.You} forcefully {sub.youVerb('lift')} {dom.you} up, quite synonymous to the pose from brief moments ago, though not quite to the play that {dom.youHe} had set {sub.youHim} up for.")

	var dialogueLines:Array = getDialogueLines_reactToSuccessfulPowerReversal()

	if( dialogueLines.size() > 0 ):
		saynn( "[say=dom]"+ RNG.pick(dialogueLines) +"[/say]" )

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func strength_power_reversal__success__martial_arts__4correct1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startPowerReversedInteraction()


func strength_power_reversal__success__martial_arts__4inattentive1_text():
	incl_power_reversal__success__martial_arts__say_chosen_sequence()

	var currentActionStageIdx:int = getCurrentPowerReversalStageIdx()

	if(currentActionStageIdx == 1):
		saynn( RNG.pick([
			"{sub.Youve} tried to listen to {sub.yourHis} own instructions, to no avail. Incompatible signals overwhelm {sub.yourHis} ability to discern genuine memories from white noise.",
		]) )
	elif(currentActionStageIdx == 2):
		var isEveryChosenSequenceFragmentInSolution:bool = true
		for fragment in subPowerReversalPersistentDict.chosenSequence:
			if(fragment in subPowerReversalPersistentDict.sequence):
				continue

			isEveryChosenSequenceFragmentInSolution = false
			break

		if(isEveryChosenSequenceFragmentInSolution):
			saynn( RNG.pick([
				"Hey, this can still be salvaged! Or.. {sub.youHe}'d think so, but the satellite of thought had already been knocked off-orbit. Thrashed away. Pummeled.",
				"{sub.You} {sub.youVerb('feel')} one mere step away from solving this, yet.. {sub.youHe} had actually taken one step back. It has thrown {sub.youHim} off course to an unrecoverable extent.",
			]) )
		else:
			saynn( RNG.pick([
				"Hm.. No, that doesn't seem right.. Focus doesn't always come easy. It was worth a try.",
			]) )
	elif(currentActionStageIdx == 3):
		saynn( RNG.pick([
			"A door shuts itself in front, shielding {sub.you} from visions of the transpired events. Its trimmed with holographic labels, sliding illuminated text in opposing directions. \"Out of order\".",
			"A single mistake washes away the picture in front of {sub.you}, like it would a tower of sand. It's tempting to shift back the chronostream, only this time {sub.youreTheyre} aware that continuing onward is how {sub.youHe} {sub.youHeVerb('make')} reach towards dreams that {sub.youHe} never had thought to conceptualize.",
		]) )

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func strength_power_reversal__success__martial_arts__4inattentive1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func strength_power_reversal__success__martial_arts__4nonsense1_text():
	var sequenceEndingWithNonsenseFragment:Array = []
	var sequenceBeforeReachingNonsenseFragment:Array = []
	var chosenNonsenseFragment:String = "Fwioup"
	var knownNonsenseFragments:Array = getNonsenseFragmentsForAssociativeSequence()

	for fragment in subPowerReversalPersistentDict.chosenSequence:
		sequenceEndingWithNonsenseFragment.append(fragment)

		if fragment in knownNonsenseFragments:
			chosenNonsenseFragment = fragment
			break

		sequenceBeforeReachingNonsenseFragment.append(fragment)

	var nonsenseFragmentColorString:String = (
			"[color="+ getSensationColor("pain_severe") +"]"
		+ chosenNonsenseFragment
		+ "[/color]"
	)

	saynn("{sub.You} {sub.youVerb('start')} to recite the sequence in {sub.yourHis} head..")

	if(chosenNonsenseFragment == "Xnopyt"):
		if( sequenceBeforeReachingNonsenseFragment.size() >= 1 ):
			saynn( Util.join(sequenceBeforeReachingNonsenseFragment, ".\n") +"." )
		saynn("Wh- What do you mean, \""+ nonsenseFragmentColorString +"\"??-")
		saynn("Abruptly, {sub.your} inner voice disintegrates.")
	else:
		saynn( Util.join(sequenceEndingWithNonsenseFragment, ".\n") + "." )
		saynn( RNG.pick([
			("Wait.. \""+ nonsenseFragmentColorString +"\"? That makes no dog damn sense."),
			("Umm.. \""+ nonsenseFragmentColorString +"\"? {sub.YouAreHeIs} {sub.youHe} being serious right now?"),
			("Err.. \""+ nonsenseFragmentColorString +"\"? Is that genuinely the best {sub.youHe} could come up with?"),
		]) )
		saynn("...")
		saynn( RNG.pick([
			"At this point {sub.you} forgot what {sub.youHe} {sub.youWereHeWas} trying to achieve here.",
			"{sub.Your} mind feels blank now.",
		]) )

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func strength_power_reversal__success__martial_arts__4nonsense1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func incl_power_reversal__success__martial_arts__list_actions():
	var stageActionList:Array = getCurrentPowerReversalActionList()

	var actionIdx:int = 0
	for actionInfo in stageActionList:
		var ACTION_ID:String = ( actionInfo.result+ "-idx"+ str(actionIdx) )
		var ACTION_NAME:String = ( "Option "+str(actionIdx + 1) )
		var ACTION_DESC:String = actionInfo.sequence[0] + ".\n" + actionInfo.sequence[1] + ".\n" + actionInfo.sequence[2] + ".\n" + actionInfo.sequence[3] + "."
		var ACTION_SCORE:float = 1.0 if(actionInfo.result == "correct") else ( 1.0 if( RNG.chance(1) ) else -0.01 )
		addAction(ACTION_ID, ACTION_NAME, ACTION_DESC, "default", ACTION_SCORE, 60, {})
		actionIdx += 1

	var ACTION_LIST_NAME:String = "List"
	if( getState() != "strength_power_reversal__success__martial_arts__list" ):
		addAction("list", ACTION_LIST_NAME, "Print out all available options, useful when the tooltips such as this one are inaccessible or inconvenient.", "default", -0.01, 60, {})
	else:
		addDisabledAction(ACTION_LIST_NAME, "Available options have been listed.")

func incl_power_reversal__success__martial_arts__on_action_select(_id:String):
	if(_id == "list"):
		setState("strength_power_reversal__success__martial_arts__list", "sub")
		return

	var nextActionStageIdx:int = getCurrentPowerReversalStageIdx() + 1
	var stageActionList:Array = getCurrentPowerReversalActionList()

	var chosenActionIdx:int = int( _id[ _id.length() - 1 ] )
	subPowerReversalPersistentDict.chosenSequence = stageActionList[chosenActionIdx].sequence

	if("correct-idx" in _id):
		if(nextActionStageIdx == 4):
			unequipSubRestraintsPreventingPowerReversal()
		else:
			subPowerReversalPersistentDict.currentActionStageIdx = nextActionStageIdx
			generateAssociativeSequenceParamsForActionStageIdx(nextActionStageIdx)

		setState("strength_power_reversal__success__martial_arts__"+ str(nextActionStageIdx) +"correct1", "sub")
	elif("inattentive-idx" in _id):
		setState("strength_power_reversal__success__martial_arts__4inattentive1", "sub")
	elif("nonsense-idx" in _id):
		setState("strength_power_reversal__success__martial_arts__4nonsense1", "sub")

func incl_power_reversal__success__martial_arts__say_chosen_sequence():
	var sequenceSay:String = ""

	for fragmentIdx in 4:
		var prefix:String = ""
		var suffix:String = ".."
		if( subPowerReversalPersistentDict.chosenSequence[fragmentIdx] == subPowerReversalPersistentDict.sequence[fragmentIdx] ):
			prefix = "[b][color="+ getSensationColor("comfort") +"]"
			suffix = ".[/color][/b]"
		elif( subPowerReversalPersistentDict.chosenSequence[fragmentIdx] in subPowerReversalPersistentDict.sequence ):
			prefix = "[color=#FFE2BA]"
			suffix = "?[/color]"
		sequenceSay += ( prefix + subPowerReversalPersistentDict.chosenSequence[fragmentIdx] + suffix )
		if(fragmentIdx != 3):
			sequenceSay += "\n"

	saynn(sequenceSay)


func strength_power_reversal__failure__elbow_strike__1_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	saynn(
			"{sub.You} {sub.youVerb('manage')} to free one arm out of the firm grasp, immediately following up with a hit of the elbow, aimed [color="+ getSensationColor("pain_severe") +"]directly at {dom.your} jaw[/color]. Now's the time to keep the pressure up, but {sub.your} arm is quickly caught at the worst possible time. With a thud, {sub.youreTheyre} [color="+ getSensationColor("pain_severe") +"]painfully pinned into the floor[/color]. When {sub.youreTheyre} lifted back on {sub.yourHis} feet, "
		+ (
				(
						"{sub.you} {sub.youVerb('notice')} a restraint {sub.youHe} {sub.youWereHeWas} not wearing before"
					+ (
							(", "+ subPowerReversalObtainedRestraints[0].a_name)
						if( !subPowerReversalObtainedRestraints[0].nameIsPlaceholder )
						else ""
					)
					+ "."
				)
			if( subPowerReversalObtainedRestraints.size() >= 1 )
			else "{sub.you} {sub.youVerb('notice')} {sub.yourselfThemself} standing there just as helpless."
		)
	)

	if( subPowerReversalObtainedRestraints.size() >= 1 ):
		if( RNG.chance(50) ):
			saynn("[say=sub]Hey, what the hell??[/say]")
			saynn("[say=dom]Seems fair, doesn't it? Can't have you this violent, you'll damage all the goods.[/say]")
			saynn( "{dom.YouHe} then {dom.youHeVerb('point')} at {sub.you}"+ ( "" if( dom.isBlindfolded() ) else " and {dom.youHeVerb('wink')}" ) +"." )
			saynn("H- Huh?")
		else:
			saynn("[say=sub]This is un-fucking-fair.[/say]")
			saynn("[say=dom]Yeah, maybe. I get kicked in the jaw, and you get a nice little gift. Wanna make it up to me?[/say]")
			saynn("[say=sub]F- Fuck off..[/say]")

			saynn(
					"It does feel kind of comfy though. {sub.You} immediately {sub.youVerb('try', 'tries')} to shake away the thoughts of being thoroughly used while standing this vulnerable in the open.."
				+ (
						" Why did {sub.you} physically shake from one side to the other? {dom.You} {dom.youVerb('look')} at {sub.youHim} puzzled."
					if( sub.isPlayer() )
					else ""
				)
			)
	else:
		var dialogueLines:Array = getDialogueLines_reactToFailedPowerReversal()

		if( dialogueLines.size() > 0 ):
			saynn( "[say=dom]"+ RNG.pick(dialogueLines) +"[/say]" )

	incl_power_reversal_stamina_cost()
	addAction("continue", "Worth a try..", "You did what you could..", "default", 1.0, 60, {})

func strength_power_reversal__failure__elbow_strike__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func strength_power_reversal__failure__unpersuasive__1_text():
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domIsKind:bool = domPersonalityMeanScore < -0.4
	var subPersonalitySubbyScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })

	saynn("[say=sub]I will make y- you my plaything. Think I don't h- have what it takes? Y- You will be begging to be in m- my place.[/say]")
	saynn("[say=dom]Wha-[/say]")
	saynn("[say=sub]I'm about to watch you *willingly* b- bend over for me, fitting an obedient w- whore like you. And then, you will be squirming f- for days, while s- someone smaller than you uses you as their personal t- toy.[/say]")

	var dialogueLines:Array = [
		"That's enough fumbling, how about we skip to the part where *you're* squirming for days.",
	]

	if(domIsKind):
		dialogueLines.append_array([
			"I'm sorry, that was just horrible.. Does anyone actually fall for something like that?",
		])
	else:
		dialogueLines.append_array([
			"You forgot your persuasion in a dryer or something?",
			"You're about to watch me stuff your mouth with a sock, is what you're about to watch.",
		])

	if(domIsMean):
		dialogueLines.append_array([
			"Why the fuck would I listen to you, small fry?",
		])

	saynn( "[say=dom]"+ RNG.pick(dialogueLines) +"[/say]" )

	incl_power_reversal_stamina_cost()
	var obeyIdx:int = RNG.randi_range(10, 14)
	var subObeyProbability:float = 0.2 * subPersonalitySubbyScore

	for n in 15:
		if(n == obeyIdx):
			addAction("obey", "Obey?", "Seriously? I m- mean, if that's what you want..", "default", subObeyProbability, 60, {})
		else:
			addAction( "ignore", "Ignore", "What a silly animal..", "default", ( 1.0 if(n == 0) else -0.01 ), 60, {} )

func strength_power_reversal__failure__unpersuasive__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	var sub = getRoleChar("sub")

	clearMessagesForChar(sub)

	if(_id == "ignore"):
		addSubRestraintUponFailingPowerReversal()
		setState("strength_power_reversal__failure__unpersuasive__2ignore1", "sub")
	elif(_id == "obey"):
		unequipSubRestraintsPreventingPowerReversal()
		setState("strength_power_reversal__failure__unpersuasive__2obey1", "sub")


func strength_power_reversal__failure__unpersuasive__2ignore1_text():
	if( subPowerReversalObtainedRestraints.size() >= 1 ):
		saynn("[say=dom]Let's give you something to remind you of your role here.[/say]")

		saynn( "{sub.You} {sub.youVerb('nudge')} from side to side, which makes it a little harder for {dom.you} to put "+ subPowerReversalObtainedRestraints[0].a_name +" on {sub.youHim}, but helpless wiggling only accentuates how cutehot {sub.youHe} {sub.youHeVerb('look')}." )
	else:
		saynn("{dom.You} lightly {dom.youVerb('brush', 'brushes')} {dom.yourHis} paw digits over rings and edges of various bondage gear adoring {sub.your} body.")

		saynn("[say=dom]I was planning to restrain you with something, but you're just so helpless already~[/say]")

	addAction("continue", "But..", "You were brimming with aura of dominance..", "default", 1.0, 60, {})

func strength_power_reversal__failure__unpersuasive__2ignore1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func strength_power_reversal__failure__unpersuasive__2obey1_text():
	var sub = getRoleChar("sub")

	var thingsPool:Array = []
	var narratorFetishHolder:FetishHolder = GM.pc.getFetishHolder()

	if( ( narratorFetishHolder.scoreFetishMax({ Fetish.Lactation: 1.0 }) >= 0.5 ) && !sub.hasBigBreasts() ):
		thingsPool.append("a pair of large intimidating milkers")
	if( ( narratorFetishHolder.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0, Fetish.VaginalSexReceiving: 1.0, Fetish.OralSexGiving: 1.0 }) >= 0.5 ) && ( !sub.hasBodypart(BodypartSlot.Penis) || sub.isBodypartCovered(BodypartSlot.Penis) ) ):
		thingsPool.append( RNG.pick(["a flaunted", "a paraded"]) +" throbbing cock that one cannot keep their stare away from" )
	if( ( narratorFetishHolder.scoreFetishMax({ Fetish.Tribadism: 1.0, Fetish.VaginalSexGiving: 1.0 }) >= 0.5 ) && ( !sub.hasBodypart(BodypartSlot.Vagina) || sub.isBodypartCovered(BodypartSlot.Vagina) ) ):
		thingsPool.append( RNG.pick(["an exposed", "a flaunted"]) +" pussy that one cannot resist yielding to" )

	if( thingsPool.size() == 0 ):
		thingsPool.append("some ten percent luck")

	var the_third_thing:String = RNG.pick(thingsPool)

	saynn(
			"Compelling someone to obey with words alone demands a strong aura of dominance, an advantage in size, "+ the_third_thing +". "
		+ (
				"A muzzle that isn't stuffed, for crying out loud. "
			if( sub.isGagged() )
			else ""
		)
		+ "{sub.You} {sub.youVerb('possess', 'possesses')} none of that. As {sub.youHe} {sub.youHeVerb('remain')} standing firm, the grip on {sub.yourHis} arms is suddenly eased. "
		+ (
				"And not just from the grasp of {dom.your} paws.\n\n{sub.YouHe} {sub.youHeVerb('stretch', 'stretches')}, no longer having {sub.yourHis} arms restrained with gear. "
			if( subPowerReversalUnequippedRestraints.size() >= 1 )
			else ""	
		)
		+ "{dom.You} slowly {dom.youVerb('walk')} in front of {sub.youHim}, then, in complete submission, {dom.youVerb('get')} on {dom.yourHis} knees."
	)

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func strength_power_reversal__failure__unpersuasive__2obey1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startInteraction("SneakUpTease", {dom=getRoleID("sub"), sub=getRoleID("dom")}, {subKneeled=true})


func agility_power_reversal__success__suddenly_free__1_text():
	saynn(
			"{sub.You} cheerfully {sub.youVerb('wave')} at {dom.you}, as {sub.youHe} {sub.youHeVerb('stand')} in front, grinning with eyes closed. H- Huh? {dom.YouWerentHeWasnt} {dom.youHe} just holding {sub.youHim} with an incredibly tight grip?"
		+ (
				(
						" And {sub.youWerentHeWasnt} {sub.youHe} wearing "
					+ subPowerReversalUnequippedRestraints[0].a_name
					+"?"
				)
			if( subPowerReversalUnequippedRestraints.size() >= 1 )
			else ""
		)
		+ (
				(
						" And "
					+ subPowerReversalUnequippedRestraints[1].a_name
					+"? What the fuck?"
				)
			if( subPowerReversalUnequippedRestraints.size() >= 2 )
			else ""
		)
	)

	incl_power_reversal_stamina_cost()
	addAction("continue", "What..", "Is someone going to explain this..", "default", 1.0, 60, {})

func agility_power_reversal__success__suddenly_free__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	var sub = getRoleChar("sub")

	if(_id == "continue"):
		clearMessagesForChar(sub)
		setState("agility_power_reversal__success__suddenly_free__2", "dom")


func agility_power_reversal__success__suddenly_free__2_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalitySubbyScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var domIsSubby:bool = domPersonalitySubbyScore > 0.4
	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsKind:bool = subPersonalityMeanScore < -0.4

	saynn(
			"What *was* that? {sub.You} {sub.youVerb('lean')} over to "
		+ (
				"feel {dom.your} breath"
			if( sub.isBlindfolded() )
			else "look at {dom.you}"
		)
		+ ", then "
		+ (
				"gently"
			if(subIsKind)
			else "possessively"
		)
		+ " {sub.youVerb('run')} {sub.yourHis} digit from {dom.yourHis} neck, through chest, down across the soft surface of {dom.yourHis} "
		+ (
				"impregnated "
			if( dom.isVisiblyPregnant() )
			else ""
		)
		+ "belly. {dom.YouHe} instinctively {dom.youHeVerb('place')} {dom.yourHis} arms in a way that allows {sub.youHim} to easily grab {dom.youHim} like {sub.yourHis} personal pet."
		+ (
				" Why {dom.youDoHeDoes} {dom.youHe} have instincts like that?"
			if( !domIsSubby && dom.isPlayer() )
			else ""
		)
	)

	addAction("continue", "Huff..", "Seems they have you now..", "default", 1.0, 60, {})

func agility_power_reversal__success__suddenly_free__2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startPowerReversedInteraction()


func agility_power_reversal__success__squishy_bone__1_text():
	saynn("{dom.You} {dom.youVerb('notice')} that someone had placed a squishy bone in {dom.yourHis} mouth. H- Huh? It feels rather.. nice... Both of its ends stick out from the sides of {dom.yourHis} muzzle, as {dom.youHe} {dom.youHeVerb('bite')} softly into it.")

	incl_power_reversal_stamina_cost()
	addAction("continue", "Huh..", "What is this thing..", "default", 1.0, 60, {})


func agility_power_reversal__success__squishy_bone__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	var sub = getRoleChar("sub")

	clearMessagesForChar(sub)

	if(_id == "continue"):
		setState("agility_power_reversal__success__squishy_bone__2", "sub")


func agility_power_reversal__success__squishy_bone__2_text():
	var sub = getRoleChar("sub")

	saynn("{dom.You} {dom.youVerb('take')} it out of {dom.yourHis} mouth, initially planning to inspect it, but {dom.yourHis} paws move one of its ends back into {dom.yourHis} mouth. {dom.YouHe} {dom.youHeVerb('crave')} it so much, that {dom.youHe} {dom.youHeVerb('begin')} to suckle on it, taking it deeper and deeper..")

	var ACTION_NAME_JUST_WATCH:String = "Just watch"
	var ACTION_NAME_OFFER_YOURS:String = "Offer yours"

	addAction("just_watch", ACTION_NAME_JUST_WATCH, "Watch them have some fun.. attentively..", "justleave", 1.0, 60, {})

	if( getReasonCharCannotPartakeInAnalSexGiving(sub, "sub") == null ):
		addAction("offer_yours", ACTION_NAME_OFFER_YOURS, "Tell them they can suck you off instead.. I- If they want to..", "agreeSexAsDom", 1.0, 60, {})
	else:
		addDisabledAction(ACTION_NAME_OFFER_YOURS, "This interaction doesn't seem to be possible.")

func agility_power_reversal__success__squishy_bone__2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "offer_yours"):
		subPowerReversalPersistentDict.hasSubOfferedBone = true

	if( _id in ["just_watch", "offer_yours"] ):
		setState("agility_power_reversal__success__squishy_bone__3", "dom")


func agility_power_reversal__success__squishy_bone__3_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4

	saynn("{dom.You} {dom.youVerb('continue')} toying with the squishy bone, stuffing {dom.yourHis} own mouth with it, licking through its whole length..")

	if( subPowerReversalPersistentDict.has("hasSubOfferedBone") && subPowerReversalPersistentDict.hasSubOfferedBone ):
		saynn(
				"[say=sub]"
			+ RNG.pick([
				"Wanna have a taste of the real thing?~",
				"Mine's tastier, y'know~",
			])
			+ "[/say]"
		)

		saynn(
				"{sub.You} "
			+ (
				(
						"teasingly {sub.youVerb('slide')} down some of {sub.yourHis} lower clothing, causing {sub.yourHis} tasty member to spring up right next to {dom.your} "
					+ (
							"silly"
						if( subIsMean or RNG.chance(25) )
						else "flustered"
					)
					+ " face."
				)
				if( sub.isBodypartCovered(BodypartSlot.Penis) )
				else "{sub.youVerb('flaunt')} {sub.yourHis} erect member next to {dom.your} face."
			)
			+ " It's so incredibly tempting"
			+ (
					""
				if( dom.isPlayer() )
				else " to {dom.youHim}"
			)
			+ ",, {dom.YouHe} {dom.youHeVerb('glance')} at the squishy bone, then back at {sub.your} \"bone\", deciding which one {dom.youHe} {dom.youHeVerb('crave')} more.."
		)

	addAction("refuse_offer", "Squishy bone", "This is all you want..", "justleave", 1.0, 180, {})

	if( subPowerReversalPersistentDict.has("hasSubOfferedBone") && subPowerReversalPersistentDict.hasSubOfferedBone ):
		addAction( "agree_offer", ( sub.getName() +"'s" ), ( "Suck on "+ ( sub.getName() +"'s" ) +" cock instead.." ), "agreeSexAsSub", 1.0, 60, {} )

func agility_power_reversal__success__squishy_bone__3_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "refuse_offer"):
		setState("agility_power_reversal__success__squishy_bone__4squishy1", "dom")
	elif(_id == "agree_offer"):
		setState("agility_power_reversal__success__squishy_bone__4subs1", "dom")


func agility_power_reversal__success__squishy_bone__4squishy1_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	if( subPowerReversalPersistentDict.has("hasSubOfferedBone") && subPowerReversalPersistentDict.hasSubOfferedBone ):
		var sub_paw_leftOrRight:String = RNG.pick(["left", "right"])

		saynn("{dom.Your} mind is too focused on the irresistible squishy bone in {dom.yourHis} paws. {dom.YouHe} couldn't possibly ask for anything more..")

		saynn("[say=dom]I'mh fhinne, fhanks,,[/say]")

		saynn(
				"{sub.You} still {sub.youVerb('take')} pleasure "
			+ (
					"in the sounds {dom.youHe} {dom.youHeVerb('emit')} while insatiably working {dom.yourHis} tongue around the toy"
				if( sub.isBlindfolded() )
				else "watching {dom.youHim} squirm as {dom.youHe} insatiably {dom.youHeVerb('work')} {dom.yourHis} tongue throughout the squishy bone's texture"
			)
			+ ". "
			+ (
					(
							"If {sub.yourHis} arms were free, {sub.youHe}'d definitely play with {sub.yourselfThemself} while closely "
						+ (
								"listening to"
							if( sub.isBlindfolded() )
							else "watching"
						)
						+ " {dom.youHim},,"
					)
				if( sub.hasBoundArms() || sub.hasBlockedHands() )
				else (
						"{sub.YouHe} slowly {sub.youHeVerb('move')} {sub.yourHis} "+ sub_paw_leftOrRight +" paw downwards, brushing it past {sub.yourHis} own belly and {sub.yourHis} "+ sub_paw_leftOrRight +" thigh, involuntarily reaching for {sub.yourHis} member to touch {sub.yourselfThemself}, as {sub.yourHis} mind drifts to imagine "
					+ (
							"your tongue's touch"
						if( dom.isPlayer() )
						else "the touch of {dom.your} tongue"
					)
					+ ".."
				)
			)
		)
	else:
		saynn("{dom.Youre} having immense amounts of fun with the squishy bone.. Sliding it across {dom.yourHis} tongue.. giving it kisses.. nuzzling into it..")

	addAction("continue", "Huff..", "It's so good..", "default", 1.0, 180, {})

func agility_power_reversal__success__squishy_bone__4squishy1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__success__squishy_bone__4squishy2", "dom")


func agility_power_reversal__success__squishy_bone__4squishy2_text():
	saynn( "The squishy bone throbs in {dom.your} mouth. {dom.YouHe} {dom.youHeVerb('add')} tilting movements to pleasure it as much as {dom.youHe} can, and {dom.youHe} {dom.youHeVerb('love')} every second of it. As {dom.youHe} {dom.youHeVerb('continue')} making out with it more and more, "+ applyOrgasmSensationToLine("sensations overwhelm {dom.youHim} immensely, sending {dom.youHim} over the edge") +"." )

	addAction("continue", "Mmfh..", "Thank you squishy bone..", "default", 1.0, 60, {})

func agility_power_reversal__success__squishy_bone__4squishy2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		unequipSubRestraintsPreventingPowerReversal()
		setState("agility_power_reversal__success__squishy_bone__5", "dom")


func agility_power_reversal__success__squishy_bone__4subs1_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	var dom_boy:String = getBoyBoun("dom")
	var dom_boy_or_puppy:String = (
			dom_boy
		if( RNG.chance(65) )
		else RNG.pick( getPetNames({ species = dom.getSpecies(), heSheThey = dom.heShe() }) )
	)

	if( RNG.chance(50) ):
		saynn("{dom.You} {dom.youVerb('nod')} needily, as both ends of the squishy bone once again stick out from the sides of {dom.yourHis} muzzle. {sub.You} {sub.youVerb('approach', 'approaches')} {dom.youHim} from the side, teasingly rubbing the tip of {sub.yourHis} member against {dom.yourHis} face cheek. {sub.YouHe} then carefully {sub.youHeVerb('push', 'pushes')} the toy bone out with {sub.yourHis} own cock, keeping it there as a worthy substitute. It being sideways makes {dom.you} particularly drooly..")
	else:
		saynn("{dom.You} begrudgingly {dom.youVerb('place')} the squishy bone on the ground, moving {dom.yourHis} muzz close to {sub.your} member, and proceeding to tongue through it with just as much lust,,")

	saynn(
			"[say=sub]"
		+ RNG.pick([
			( "Huffhh.. That's it, good "+ dom_boy_or_puppy + ".." ),
			( "Mmhhf.. Such an obedient "+ dom_boy_or_puppy + ".." ),
		])
		+ "[/say]"
	)

	addAction( "continue", "Fuck..", ( sub.getName() +"'s bone is so fucking good.. Sorry, squishy bone.." ), "default", 1.0, 360, {} )

func agility_power_reversal__success__squishy_bone__4subs1_do(_id:String, _args:Dictionary, _context:Dictionary):
	var sub = getRoleChar("sub")

	if(_id == "continue"):
		var playerDomOrSubString = "sub" if( sub.isPlayer() ) else "dom"
		setState("agility_power_reversal__success__squishy_bone__4subs2", playerDomOrSubString)


func agility_power_reversal__success__squishy_bone__4subs2_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	if( sub.isPlayer() ):
		saynn(
				"{dom.Your} tongue feels really good.. {sub.You} can tell {dom.youHe} {dom.youHaventHeHasnt} gone all out on {sub.youHim}, prolonging "
			+ (
					"{dom.yourHis}"
				if(domIsMean)
				else "{sub.yourHis}"
			)
			+ " pleasure for as much as possible. However, {sub.youHe} still {sub.youHaveHeHas} to withstand the sensation of {dom.yourHis} lips sliding across {sub.yourHis} shaft, as {dom.youHe} slowly {dom.youHeVerb('tilt')} {dom.yourHis} head to the left, then right, then left again.. {dom.YouHe} {dom.youHeVerb('take')} {sub.youHim} rather deep too, all while making such "
			+ (
					"fussy"
				if(domIsMean)
				else "cute"
			)
			+ " noises of quiet slurping and muffled squirming.. {sub.Youre} already weak for all of the mentioned aspects, but when this continues for such a long time, {sub.youHe} just can't help but shove {sub.yourHis} whole length, with a push so needy it temporarily deforms the shape of {dom.your} muzzle, "
			+ applyOrgasmSensationToLine("filling {dom.yourHis} maw full of {sub.yourHis} warm cum")
			+ "."
		)
	else:
		var subPenisBodypart = sub.getBodypart(BodypartSlot.Penis)
		var subPenis_barbed:String = subPenisBodypart.getLewdAdjective() if(subPenisBodypart != null) else "phantom"

		saynn( "{dom.You} {dom.youVerb('continue')} delicately tonguing through {sub.your} "+ subPenis_barbed +" cock, absolutely in love with its texture. Each time an imprecise motion causes it to brush across {dom.yourHis} maw's inner walls, it only furthers just how much {dom.youHe} {dom.youHeVerb('crave')} it." )

		saynn(
				"{dom.You} {dom.youVerb('wish', 'wishes')} to prolong "
			+ (
					"{dom.yourHis}"
				if(domIsMean)
				else "both {dom.yoursHis} and {sub.your}"
			)
			+ " pleasure for as much as possible, opting for a slower, more steady pace. That desire is however at odds with the amount of pure arousal that {dom.youHe} {dom.youHeVerb('get')} from a mere "
			+ (
					"lick through"
				if( dom.isBlindfolded() )
				else "glance at"
			)
			+ " {sub.yourHis} delicious bone."
		)

		saynn("To make matters worse, a noticeable amount of pre leaks out of it onto {dom.your} tongue,, At this point, {dom.yourHis} mind can hardly formulate any thoughts. What's left to comprise {dom.youHim} is an animalistic desire to suck on {sub.your} member, craving it deep inside {dom.yourHis} mouth, making out with its tip ever so often..")

		saynn(
				"Eventually, {dom.yourHis} mouthwork causes {sub.you} to feel so irresistibly needy.. {sub.YouHe} "
			+ (
					"{sub.youHeVerb('grab')} onto {dom.yourHis} head with both paws, and "
				if( !sub.hasBoundArms() && !sub.hasBlockedHands() )
				else ""
			)
			+ "{sub.youHeVerb('shove')} {sub.yourHis} entire length deep into {dom.yourHis} throat, filling it full of {sub.yourHis} warm cum,,"
		)

	saynn("[say=dom]Mmfh-![/say]")

	addAction("continue", "Huff..", "That felt so fucking nice..", "default", 1.0, 60, {})

func agility_power_reversal__success__squishy_bone__4subs2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__success__squishy_bone__4subs3", "dom")


func agility_power_reversal__success__squishy_bone__4subs3_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	if( sub.isPlayer() ):
		saynn("Still huffing, {sub.you} {sub.youVerb('slide')} {sub.yourHis} member out, painting {dom.your} face, seed still spilling out from {sub.yourHis} member as if {sub.youHe}'d only just came..")
	else:
		var affectionValue:float = subPawn.getAffection(domPawn)
		var domCharacterTypeName = CharacterType.getName( dom.getCharacterType() )
		var dom_Callname:String = ""

		if(affectionValue >= 0.4):
			dom_Callname = dom.getName()
		elif( dom.isLilac() ):
			dom_Callname = "Lilac"
		elif( domCharacterTypeName in ["Inmate", "Guard", "Nurse", "Engineer"] ):
			dom_Callname = domCharacterTypeName
		else:
			dom_Callname = Util.capitalizeFirstLetter( getBoyBoun("dom") )

		saynn(
				"{sub.Your} bone continues throbbing inside {dom.your} maw, releasing even more cum for almost a minute, until {sub.youHe} finally {sub.youHeVerb('pull')} out, painting half of {dom.yourHis} "
			+ (
					"fussy"
				if(domIsMean)
				else "adorable"
			)
			+ " face with a new release of {sub.yourHis} warm seed.."
		)

		saynn( "[say=sub]"+ dom_Callname +"-.. Fuckhhfh,,[/say]" )

	addAction("continue", "Gosh..", "It keeps leaking..", "default", 1.0, 60, {})

func agility_power_reversal__success__squishy_bone__4subs3_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		unequipSubRestraintsPreventingPowerReversal()
		setState("agility_power_reversal__success__squishy_bone__5", "dom")


func agility_power_reversal__success__squishy_bone__5_text():
	var dom = getRoleChar("dom")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalitySubbyScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var domIsSubby:bool = domPersonalitySubbyScore > 0.4
	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4

	var hasSubHadAnyRestraintsUnequipped:bool = ( subPowerReversalUnequippedRestraints.size() >= 1 )

	if(hasSubHadAnyRestraintsUnequipped):
		var dom_boy:String = getBoyBoun("dom")
		var dom_boy_or_puppy:String = (
				dom_boy
			if( RNG.chance(65) )
			else RNG.pick( getPetNames({ species = dom.getSpecies(), heSheThey = dom.heShe() }) )
		)

		var hasDomRefusedRequest:bool = RNG.chance( domPawn.scorePersonalityMax({ PersonalityStat.Subby: -40.0, PersonalityStat.Brat: 40.0 }) )

		saynn(
				"As {dom.you} still haplessly {dom.youVerb('try', 'tries')} to recover, {sub.you} {sub.youVerb('approach', 'approaches')} {dom.youHim} with an unanticipated "
			+ (
					"demand"
				if(subIsMean)
				else "request"
			)
			+ "."
		)

		saynn(
				"[say=sub]"
			+ RNG.pick([
				( "Be a good "+ dom_boy_or_puppy + " and take care of these arm restraints for me." ),
				( "You're a very obedient "+ dom_boy_or_puppy + ", aren't you? Help me out with these restraints." ),
			])
			+ "[/say]"
		)

		if(hasDomRefusedRequest):
			var possibleRefusalLines:Array = [
				"Make me-",
				"And why would I do that-?"
			]

			if(domIsMean):
				possibleRefusalLines.append_array([
					"Bitch, who do you think you are-",
				])

			saynn( "[say=dom]"+ RNG.pick(possibleRefusalLines) + "[/say]" )

			saynn(
					"{dom.You} {dom.youVerb('bite')} into an unanticipated squishy bone as {dom.youHe} {dom.youHeVerb('try', 'tries')} to finish that last word. The way the bone toy fits into {dom.yourHis} muzzle "
				+ (
						"feels"
					if( dom.isPlayer() )
					else "makes {dom.youHim} feel"
				)
				+ " really nice.. Everything else now seems unimportant"
				+ (
						""
					if( dom.isPlayer() )
					else " to {dom.youHim}"
				)
				+ ", somehow.."
			)

		saynn(
				"{dom.YouHe} "
			+ (
					"then "
				if(hasDomRefusedRequest)
				else ""
			)
			+ (
					"{dom.youHeVerb('obey')}"
				if(subIsMean)
				else "{dom.youHeVerb('fulfill')}"
			)
			+ " {sub.yourHis} "
			+ (
					"command"
				if(subIsMean)
				else "request"
			)
			+ " without question, "
			+ (
					"first "
				if( subPowerReversalUnequippedRestraints.size() >= 2 )
				else ""
			)
			+ (
					(
							"freeing {sub.youHim} of {sub.yourHis} "
						+ subPowerReversalUnequippedRestraints[0].a_name
					)
				if( subPowerReversalUnequippedRestraints[0].nameIsPlural )
				else (
						"taking care of "
					+ subPowerReversalUnequippedRestraints[0].a_name
				)
			)
			+ (
					(
							(
									", then {sub.yourHis} "
								+ subPowerReversalUnequippedRestraints[1].a_name
							)
						if( subPowerReversalUnequippedRestraints[1].nameIsPlural )
						else (
								". "
							+ subPowerReversalUnequippedRestraints[1].A_name
							+ " is soon unlocked for {sub.youHim}, too"
						)
					)
				if( subPowerReversalUnequippedRestraints.size() >= 2 )
				else ""
			)
			+ "."
			+ (
					(
							" So eager to serve, aren't you?"
						if(domIsSubby)
						else (
								""
							if(hasDomRefusedRequest)
							else " {sub.YouHe} {sub.youHaveHeHas} a way with words that really make you want to serve {sub.youHim}, {sub.youDontHeDoesnt} {sub.youHe}.."
						)
					)
				if( dom.isPlayer() )
				else ""
			)
		)

	saynn(
			(
					"{sub.You} then {sub.youVerb('command')} {dom.youHim} to place {dom.yourselfThemself} in a vulnerable pose."
				if(hasSubHadAnyRestraintsUnequipped)
				else "{dom.You} {dom.youVerb('notice')} a silhouette commanding {dom.youHim} to place {dom.yourselfThemself} in a vulnerable pose."
			)
		+ " {dom.YouHe} {dom.youDoHeDoes} so with great amount of obedience. "
		+ (
				(
						"{sub.You} {sub.youVerb('position')} {sub.yourselfThemself} behind {dom.youHim}, just as {dom.youHe} had {sub.youHim} a few minutes ago, only this time it doesn't look like it'd take much time until the creature in front is down on its knees, raising its "
					+ (
							"tail"
						if( dom.hasTail() )
						else "rear"
					)
					+ " for its captor.."
				)
			if(domIsSubby)
			else "When clarity comes, it is a little late. {dom.YourHis} arms now tremble under {sub.your} tight grasp."
		)
	)

	addAction("continue", "Damn..", "Their bone was really tasty..", "default", 1.0, 60, {})

func agility_power_reversal__success__squishy_bone__5_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startPowerReversedInteraction()


func agility_power_reversal__success__holocard__1_text():
	var sub = getRoleChar("sub")

	saynn( "[say=sub]There's a playing card "+( "between my breasts" if( sub.hasNonFlatBreasts() ) else "in my paws" )+ ".[/say]" )
	saynn("[say=dom]Yeah I ain't falling for that.[/say]")
	saynn("[say=sub]No I mean it.[/say]")

	saynn( "{dom.Youre} not even curious. {dom.YouHe} carefully {dom.youHeVerb('inspect')} {sub.your} "+( "breasts" if( sub.hasNonFlatBreasts() ) else "paws" )+ " for any weapons or dangerous tech that {dom.youHe} might have missed. But it is there. The card. How did {sub.youHe}.." )

	incl_power_reversal_stamina_cost()
	addAction("continue", "Ignore it", "A card is a card..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	var sub = getRoleChar("sub")

	if(_id == "continue"):
		clearMessagesForChar(sub)

		if( sub.hasNonFlatBreasts() ):
			setState("agility_power_reversal__success__holocard__2breasts1", "dom")
		else:
			setState("agility_power_reversal__success__holocard__2paws1", "dom")


func agility_power_reversal__success__holocard__2paws1_text():
	saynn("It is an Envoy card, of the Submission suit. {dom.You} {dom.youVerb('decide')} not to give it any more attention than {dom.youHe} already {dom.youHaveHeHas}. The illustration is rather hot, but {dom.youHe} {dom.youDontHeDoesnt} get much from simply looking at it.")

	saynn("{dom.YouHe} {dom.youHeVerb('feel')} like {dom.youHe} would need to lick it, for the sensations to run through {dom.youHim}. That.. doesn't really make much sense. It is a holocard, so {dom.yourHis} tongue would only..")

	addAction("continue", "It would what?", "What are you even thinking..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__2paws1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__success__holocard__2paws2", "dom")


func agility_power_reversal__success__holocard__2paws2_text():
	var dom = getRoleChar("dom")

	var dom_feline_MAYBE:String = getIncompleteSpeciesFullName( dom.getSpecies() ).to_lower()

	saynn( "{dom.You} {dom.youVerb('kneel')} in front of the card as it's held in {sub.your} paws. The Envoy, previously on its knees, now had its thighs spread wide, and was obediently leaning backwards in wait. {dom.You} reached closer, {dom.yourHis} tongue pressing through the card until it reached {sub.your} pawpads. This seemed rather disappointing"+( " to {dom.youHim}" if( !dom.isPlayer() ) else "" )+", but {dom.you} still felt obliged to please the Envoy, making an offering by indulgently running {dom.yourHis} tongue through "+ dom_feline_MAYBE +" paws." )

	saynn("The card was really cute, bending and squirming, but there was something else. Its pleasure seemed to almost.. course through {dom.you}. Making out with the paw and kissing upon the digits "+ applyOrgasmSensationToLine("brought {dom.youHim} immense waves of euphoria") +", and any act of submission delivered praise, unrivaled to any emotion {dom.youHe} {dom.youHaveHeHas} had before.")

	addAction("continue", "Huff..", "This is really nice..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__2paws2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		unequipSubRestraintsPreventingPowerReversal()

		if( subPowerReversalUnequippedRestraints.size() >= 1 ):
			setState("agility_power_reversal__success__holocard__2paws3", "dom")
		else:
			setState("agility_power_reversal__success__holocard__2paws4", "dom")


func agility_power_reversal__success__holocard__2paws3_text():
	var dom = getRoleChar("dom")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsKind:bool = subPersonalityMeanScore < -0.4

	saynn( "{sub.You} "+( "kindly asked for help with {sub.yourHis} restraints. {dom.You} {dom.youWere}" if(subIsKind) else "ordered {dom.you} to remove {sub.yourHis} restraints. {dom.YouHe} {dom.youWereHeWas}" )+" eager to serve, helping {sub.youHim} unlock gear on {sub.yourHis} arms." )

	if(subIsKind):
		saynn("[say=sub]Good thing~[/say]")

		if( dom.isPlayer() ):
			saynn("That almost made {dom.you} cum..")

	addAction("continue", "Huff..", "What is going on..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__2paws3_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")

	if(_id == "continue"):
		if( GM.pc.dynamicPersonality || !dom.isPlayer() ):
			dom.getPersonality().addStat( PersonalityStat.Subby, RNG.randf_range(0.05, 0.1) )

		setState("agility_power_reversal__success__holocard__2paws4", "dom")


func agility_power_reversal__success__holocard__2paws4_text():
	var dom = getRoleChar("dom")

	saynn("{sub.You} then commanded {dom.you} to get into the same pose {dom.youHe} initially held {sub.youHim} in. {dom.YouHe} obeyed, still obsessed about the effect it would leave on the Envoy, yet this time there was no immediate response. Puzzled, {dom.youHe} quickly started to regain clarity, but any advantage {dom.youHe} had over {sub.you} has already been lost.")

	saynn("There is one more thing of note – this interaction might have had some lasting effects on {dom.youHim}..")

	if( GM.pc.dynamicPersonality || !dom.isPlayer() ):
		addMessage("{dom.name} became slightly more subby because of the holocard.")

	addAction("continue", "This isn't..", "What just happened..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__2paws4_do(_id:String, _args:Dictionary, _context:Dictionary):
	var sub = getRoleChar("sub")

	if(_id == "continue"):
		clearMessagesForChar(sub)
		startPowerReversedInteraction()


func agility_power_reversal__success__holocard__2breasts1_text():
	var dom = getRoleChar("dom")
	var domPawn = getRolePawn("dom")

	var domInterestInLactation:float = domPawn.scoreFetishMax({ Fetish.Lactation: 1.0 })

	var symbolPairs:Array = [
		["an amphora of sorts", "a wineglass"],
		["a shard of celestine", "Ouroboros"],
		["the starchart designation for Calypso", "Fenrir"],
	]
	var randomSymbolPair:Array = RNG.pick(symbolPairs)

	var symbolDescription:String = RNG.pick([
		( randomSymbolPair[0] +"? Or was that "+ randomSymbolPair[1] +".." ),
		( randomSymbolPair[0] +"? No, wait.. "+ randomSymbolPair[1] +"?" ),
	])

	saynn( "{dom.You} {dom.youVerb('choose')} not to risk interacting with underground tech, beyond momentarily inspecting the character in an attempt to identify its rank and suit. But before {dom.youHe} {dom.youHeVerb('manage')} to do so, the holocard display fades, only allowing {dom.youHim} to catch a glimpse of the symbol – "+ symbolDescription )

	saynn(
			"{dom.You} {dom.youVerb('feel')} observed, somehow without the usual associated discomfort. "
		+ (
				"Its"
			if( dom.isPlayer() )
			else "The entity's"
		)
		+ " gaze is curious, awaiting {dom.your} move. {dom.YouHe}'d really like to see it in a more playful mood, but also worried that whichever motion {dom.youHe} might attempt will only startle it. A comforting paw slowly touches upon {dom.yourHis} spine, gently pressing {dom.youHim} forwards into {sub.your} chest."
	)

	addAction("embrace", "Embrace", "Hug around their belly..", "default", 0.2, 180, {})
	var domLickBreastsProbability:float = domInterestInLactation
	addAction("lick_breasts", "Lick breasts", "Lick their breasts.. if- if they don't mind..", "default", domLickBreastsProbability, 60, {})

func agility_power_reversal__success__holocard__2breasts1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "embrace"):
		setState("agility_power_reversal__success__holocard__2breasts5embrace1", "dom")
	elif(_id == "lick_breasts"):
		subPowerReversalPersistentDict.wasDomInterestedInLickingBreasts = true
		setState("agility_power_reversal__success__holocard__2breasts2lick1", "sub")


func agility_power_reversal__success__holocard__2breasts2lick1_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subInterestInLactation:float = subPawn.scoreFetishMax({ Fetish.Lactation: 1.0 })

	saynn(
			"{dom.You} slowly {dom.youVerb('stick')} out {dom.yourHis} tongue right next to {sub.your} breasts, tilting {dom.yourHis} head back to "
		+ (
				"face {sub.you}"
			if( dom.isBlindfolded() || sub.isBlindfolded() )
			else "look into {sub.your} eyes"
		)
		+ ". This seems to be what the entity is expecting {dom.youHim} to do, but {dom.youHe} still {dom.youHeVerb('need')} permission."
	)

	addAction("refuse", "Refuse", "Don't allow them to lick your breasts.", "justleave", 1.0, 60, {})
	var subAllowLickBreastsProbability:float = subInterestInLactation
	addAction("allow", "Allow", "You don't mind them licking your breasts.", "default", subAllowLickBreastsProbability, 60, {})

func agility_power_reversal__success__holocard__2breasts2lick1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "refuse"):
		setState("agility_power_reversal__success__holocard__2breasts5embrace1", "dom")
	elif(_id == "allow"):
		setState("agility_power_reversal__success__holocard__2breasts3lick1", "sub")


func agility_power_reversal__success__holocard__2breasts3lick1_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4

	var possible = [
		"Don't be shy~",
		"Show me how much you crave them~",
	]

	if(subIsMean):
		possible.append_array([
			"Don't keep me waiting.",
			"Start working your tongue, brat.",
		])
	else:
		possible.append_array([
			"Go right ahead, dear~",
			"Are you waiting for my input? That's adorable. Go on, then~",
		])

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

	if( sub.hasBoundArms() || sub.hasBlockedHands() ):
		saynn(
				"{sub.YouHe} {sub.youHeVerb('wiggle')} lightly"
			+ (
					""
				if( sub.isBlindfolded() )
				else ", looking at {sub.yourHis} covered breasts, then back at {dom.you}"
			)
			+ ", feeling a little restricted in {sub.yourHis} clothing."
		)

		saynn(
				"[say=sub]"
			+ RNG.pick([
				"Don't let what I'm wearing get in the way~",
				"Loosen up my clothing to get to them, yeah?~",
			])
			+ "[/say]"
		)

		saynn(
				"{dom.You} {dom.youVerb('nod')}, carefully unbuttoning, lifting up, or otherwise lessening the coverage {sub.your} clothes provide, particularly to {sub.yourHis} tits.. When they're finally out in the open, {dom.youHe} cannot help but "
			+ (
					"nuzzle into their round shape"
				if( dom.isBlindfolded() || RNG.chance(50) )
				else "stare at how plump they are"
			)
			+ ",,"
		)
	else:
		saynn(
				"{sub.YouHe} {sub.youHeVerb('ensure')} none of {sub.yourHis} clothing is in the way, teasingly revealing {sub.yourHis} round breasts right next to {dom.your} "
			+ (
					"devious"
				if(domIsMean)
				else "flustered"
			)
			+ " face."
		)

	saynn("A distorted giggle passes through {dom.your} ears. It doesn't seem to be at {dom.yourHis} expense, but {dom.yourHis} mind drifts for a short while, imagining what other, needier sounds the entity could produce. Perhaps, to hear those glitchy, squirming noises, {dom.youHe} wouldn't need to do anything {dom.youHe} {dom.youWerentHeWasnt} already planning, which is.. fully submitting to {dom.yourHis} own desires..")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 240, {})

func agility_power_reversal__success__holocard__2breasts3lick1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		if( RNG.chance(50) ):
			subPowerReversalPersistentDict.hasEntityOfferedBreasts = true

		setState("agility_power_reversal__success__holocard__2breasts3lick2", "dom")


func agility_power_reversal__success__holocard__2breasts3lick2_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	var both_youThem:String = "you" if( isPlayerInvolved() ) else "them"

	var hasEntityOfferedBreasts:bool = ( subPowerReversalPersistentDict.has("hasEntityOfferedBreasts") && subPowerReversalPersistentDict.hasEntityOfferedBreasts )

	saynn("{dom.You} {dom.youVerb('lean')} closer, pressing {dom.yourHis} tongue at one of {sub.your} breasts, insatiably and sloppily making out with it, before switching to the other, and giving it the same self-indulgent treatment.")

	saynn( "No matter how many times {dom.youve} done this throughout the months, the sensations arouse {dom.youHim} within mere seconds, immensely pleasing {dom.youHim} with each prolonged wet kiss, each squeeze and fondle of {dom.yourHis} "+ ("depraved" if(domIsMean) else "craving") +" paws, each muffled moan or squirm that {dom.youHe} purposely evoked within {sub.youHim}." )

	if(hasEntityOfferedBreasts):
		saynn("The illusory creature leans at {sub.your} side, inviting {dom.you} to take pleasure from its breasts too. It's content with letting {dom.youHim} refuse, but unable to help but closely observe both {dom.yourHis} initial reaction, and the emotions that rush through {dom.youHim} during a brief moment that {dom.youHe} {dom.youHeVerb('spend')} deliberating.")

		addAction( "refuse_entity_breasts", "Refuse offer", ( "Keep your full attention on "+ sub.getName() +".." ), "default", 0.5, 180, {} )
		addAction("lick_entity_breasts", "Lick breasts", "Lick the en-titties..", "default", 0.5, 180, {})
	else:
		saynn( "This time, the two of "+ both_youThem +" are joined by a daimon presence. It dedicates most of its attention to {dom.you}, tenderly petting {dom.yourHis} "+ ( "hair" if( dom.hasHair() ) else "face cheeks" ) +", which {dom.youHe} {dom.youHeVerb('find')} immensely comforting but also unexpectedly arousing. From time to time, it would also brush its paw around the curves of {sub.your} breasts, as it quietly emitted lustful, distorted huffs." )

		addAction("done", "Continue", "See what happens next..", "default", 1.0, 300, {})

func agility_power_reversal__success__holocard__2breasts3lick2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "refuse_entity_breasts"):
		setState("agility_power_reversal__success__holocard__2breasts4refuse1", "dom")
	elif(_id == "lick_entity_breasts"):
		setState("agility_power_reversal__success__holocard__2breasts4lick1", "dom")
	elif(_id == "done"):
		unequipSubRestraintsPreventingPowerReversal()
		setState("agility_power_reversal__success__holocard__2breasts6", "dom")


func agility_power_reversal__success__holocard__2breasts4refuse1_text():
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	saynn( "{dom.You} {dom.youVerb('choose')} to focus on pleasuring {sub.your} breasts, "+ ( "ignoring" if(domIsMean) else "politely refusing" ) +" the entity's offer. Its not upset with {dom.youHim} at all, though possibly a little curious whether {dom.youreTheyre} simply not interested, or if this is {dom.yourHis} way of teasing it.. As {dom.youHe} needily {dom.youHeVerb('grab')} onto {sub.you} while working {dom.yourHis} tongue, the spectral being seems much more out of focus, though however distorted, there's still semblance of a creature pleasuring itself, around where it could be clearly seen leaning on earlier." )

	addAction("continue", "Huff..", "You absolutely loved sucking on them..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__2breasts4refuse1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		unequipSubRestraintsPreventingPowerReversal()
		setState("agility_power_reversal__success__holocard__2breasts6", "dom")


func agility_power_reversal__success__holocard__2breasts4lick1_text():
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	saynn( "{dom.You} avidly {dom.youVerb('welcome')} the entity's offer, from that point on dedicating roughly half of {dom.yourHis} time to pleasure "+ ( "" if(domIsMean) else "and share love with ") +"its breasts. The surreal, half-glitched squirms, that {dom.youHe} {dom.youWereHeWas} so hoping to hear, echo sweetly into {dom.yourHis} ears. They are even better than the ones {dom.youHe} imagined earlier.." )

	addAction("continue", "Huff..", "You absolutely loved sucking on them..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__2breasts4lick1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		unequipSubRestraintsPreventingPowerReversal()
		setState("agility_power_reversal__success__holocard__2breasts6", "dom")


func agility_power_reversal__success__holocard__2breasts5embrace1_text():
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4

	var both_youThem:String = "you" if( isPlayerInvolved() ) else "them"
	var both_yourTheir:String = "your" if( isPlayerInvolved() ) else "their"

	var wasDomInterestedInLickingBreasts:bool = ( subPowerReversalPersistentDict.has("wasDomInterestedInLickingBreasts") && subPowerReversalPersistentDict.wasDomInterestedInLickingBreasts )

	if(wasDomInterestedInLickingBreasts):
		saynn("{sub.You} {sub.youVerb('shake')} head.")

		var possible = []

		if(subIsMean):
			possible.append_array([
				"You're not getting them this easily.",
				"Hey, these are mine, get your own.."
			])
		else:
			possible.append_array([
				"Sorry but you can't have them~",
				"Not now, pet. But perhaps you'll be able to convince me later~",
			])

		saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )
	else:
		saynn(
				"{dom.You} {dom.youVerb('shake')} head, hoping to indicate {dom.youHe}'d prefer something else."
			+ (
					" {sub.You} {sub.youAre} unable to see {dom.youHim} do that, but the entity kindly shares {dom.your} intentions by sweetly whispering into {sub.your} ear."
				if( sub.isBlindfolded() )
				else ""
			)
		)

	saynn(
			(
					"{sub.You} {sub.youVerb('gesture')} towards {sub.yourHis} own belly, and {dom.you} obediently {dom.youVerb('press', 'presses')} {dom.yourHis} head into it, then {dom.youVerb('hug')} around {sub.your} back."
				if( sub.hasBoundArms() )
				else (
						( "{sub.You} {sub.youVerb('pull')} {dom.you} close, pressing {dom.yourHis} head into {sub.yourHis} "+( "impregnated " if( sub.isVisiblyPregnant() ) else "" )+"belly, then wrapping arms around the back of it, " )
					+ (
							"greedily holding onto {dom.youHim}, occasionally squeezing at {dom.yourHis} ears"
						if(subIsMean)
						else (
								"holding tightly but tender, occasionally caressing {dom.yourHis} ears and "
							+ (
									"hair"
								if( sub.hasHair() && RNG.chance(80) )
								else "face cheeks"
							)
						)
					)
				)
			)
		+ "."
	)

	saynn( RNG.pick([
		( "The holocard's beast closely observes "+ both_yourTheir +" embrace, with "+ RNG.pick(["fervency", "fondness", "sappiness"]) +", lingering between varied viewpoints." ),
		( "The phantom being causes a flicker, appearing by {dom.your} "+ RNG.pick(["left", "right"]) +" side, slow enough as not to startle. {dom.You} {dom.youVerb('begin')} to feel its gentle touch, as it joins the two of "+ both_youThem +" in a soothing embrace." )
	]) )

	addAction("continue", "Mmh..", "Their belly is so soft..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__2breasts5embrace1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		unequipSubRestraintsPreventingPowerReversal()
		setState("agility_power_reversal__success__holocard__2breasts6", "dom")


func agility_power_reversal__success__holocard__2breasts6_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	var both_youreTheyre:String = "you're" if( isPlayerInvolved() ) else "they're"
	var both_youThem:String = "you" if( isPlayerInvolved() ) else "them"
	var both_youThey:String = "you" if( isPlayerInvolved() ) else "they"

	var hasSubHadAnyRestraintsUnequipped:bool = ( subPowerReversalUnequippedRestraints.size() >= 1 )

	var hasEntityDisappeared:bool = (
			hasSubHadAnyRestraintsUnequipped
		&& RNG.chance(50)
	)

	if(hasSubHadAnyRestraintsUnequipped):
		saynn(
				"{sub.You} "
			+ (
					"{sub.youVerb('stretch', 'stretches')} as much as {sub.yourHis} arm restraints allow {sub.youHim} to"
				if( sub.isBlindfolded() )
				else "{sub.youVerb('glance')} at {sub.yourHis} arm restraints"
			)
			+ ". Sooner or later, {sub.youHe}'ll have to think of a way to deal with their lock mechanisms.. {sub.YouHe} {sub.youWereHeWas} about to make it {dom.your} problem, when a chimeric echo gently paused {sub.youHim} in {sub.yourHis} tracks, with a touch of its paw."
		)

		if(hasEntityDisappeared):
			saynn(
					"It reached out towards "
				+ (
						(
								"{sub.yourHis} "
							+ subPowerReversalUnequippedRestraints[0].a_name
						)
					if( subPowerReversalUnequippedRestraints[0].nameIsPlural )
					else (
							subPowerReversalUnequippedRestraints[0].a_name
						+ " that {sub.youHe} had been wearing"
					)
				)
				+ ", pressing its paw against the restraint. A mere few seconds passed, and the same visual distortions that engulfed the entity's figure could be observed on the restraint. "
				+ (
						(
								"It had done the same to "
							+ (
									(
											"{sub.yourHis} "
										+ subPowerReversalUnequippedRestraints[1].a_name
									)
								if( subPowerReversalUnequippedRestraints[1].nameIsPlural )
								else (
										subPowerReversalUnequippedRestraints[1].a_name
									+ " that was troubling {sub.youHim}"
								)
							)
							+ ". "
						)
					if( subPowerReversalUnequippedRestraints.size() >= 2 )
					else ""
				)
				+ "The chimeric being shared a kiss on {sub.your} face cheek, before phasing away, along with the restraint"
				+ (
						"s"
					if( subPowerReversalUnequippedRestraints.size() >= 2 )
					else ""
				)
				+ " it had touched."
			)
		else:
			saynn(
					"It blinked a meter back, extending its paw towards {sub.you}, and performing a gesture that seemed like it was attempting to crush something. Before {sub.youHe} had a chance to feel concerned for {sub.yourHis} safety, {sub.youHe} could hear a distinct -click- from the direction of "
				+ (
						(
								"{sub.yourHis} "
							+ subPowerReversalUnequippedRestraints[0].a_name
						)
					if( subPowerReversalUnequippedRestraints[0].nameIsPlural )
					else (
							subPowerReversalUnequippedRestraints[0].a_name
						+ " {sub.youHe} had been wearing"
					)
				)
				+ (
						(
								". Then another, from "
							+ (
									(
											"{sub.yourHis} "
										+ subPowerReversalUnequippedRestraints[1].a_name
									)
								if( subPowerReversalUnequippedRestraints[1].nameIsPlural )
								else subPowerReversalUnequippedRestraints[1].a_name
							)
							+ ". "
						)
					if( subPowerReversalUnequippedRestraints.size() >= 2 )
					else "."
				)
			)

		var possible:Array = [
			"Hey, you can't just-",
			"What the actual-",
			"How is any of this even-",
			"Am I dreaming? This has to be a dream, right?..",
			"I- Huh??!",
			"Ain't no way..",
		]

		if(hasEntityDisappeared):
			possible.append_array([
				"..Can I have one of these?",
				"W- Who are you??"
			])

		if( dom.isStaff() ):
			possible.append_array([
				"This.. this has to be illegal, right?..",
			])

		if(domIsMean):
			possible.append_array([
				"Does this fucking station even adhere to the laws of physics? What the fuck??",
				"Shut the fuck up, this isn't happening??",
			])

		saynn( "[say=dom]"+ RNG.pick(possible) +"[/say]" )
		saynn( "[say=sub]Shush~[/say]" )

	if(hasEntityDisappeared):
		saynn( "{dom.You} {dom.youWereHeWas} completely bewildered, which allowed {sub.you} to get into a position that's very advantageous over {dom.youHim}, without any meaningful resistance. For both of "+ both_youThem +", the memories of the card would still surface occasionally, and while the entity would love the fact that "+ both_youThey +" can't help but think about it, "+ both_youreTheyre +" confident that if "+ both_youThey +" could still hear it, it would use its earliest opportunity to command "+ both_youThem +" to instead give full attention to one another." )
	else:
		saynn( "The illusory critter then appeared by {dom.your} "+ ( "" if(hasSubHadAnyRestraintsUnequipped) else "other " ) +"side, slowly and lustfully teasing {dom.youHim} for minutes.. The entity eventually welcomed {sub.you} to share the same space with it, and the both of "+ ( "you" if( sub.isPlayer() ) else "them" ) +" would merge in place, the hold over {dom.your} wrists now passed onto {sub.youHim}. The merge effect is, of course, purely visual.. unless.. it's {sub.your} clear intent to give up some of control?~" )

	addAction("continue", "Waow", "That sure was something..", "default", 1.0, 60, {})

func agility_power_reversal__success__holocard__2breasts6_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		startPowerReversedInteraction()


func agility_power_reversal__failure__dream_of_slime__1_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		saynn("{sub.You} {sub.youVerb('ponder')} how to use {sub.yourHis} unrivaled agility to break out of {dom.your} hold.. Even {sub.yourHis} most basic thoughts refuse to surface through this heat. {sub.You} {sub.youVerb('feel')} as if {sub.youreTheyre} going to melt.")
	else:
		saynn("{sub.You} {sub.youVerb('zone')} out for a while. {dom.You} {dom.youVerb('pay')} it no attention, continuing to play with {sub.yourHis} body.")

	incl_power_reversal_stamina_cost()
	addAction("melt", "Melt", "Perhaps that's exactly what you need..", "default", 1.0, 60, {})
	addAction("resist", "Resist", "You're happy with your solid form.", "default", -0.01, 60, {})

func agility_power_reversal__failure__dream_of_slime__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	clearMessagesForChar(dom)

	if(_id == "melt"):
		var slimeColorName:String = "red"
		var subChatColor:String = sub.getChatColor()
		if( subChatColor in ["#C3E8BE", "#77D86C"] ):
			slimeColorName = "green"
		elif( subChatColor in ["#DABFFF", "#BA82FF"] ):
			slimeColorName = "purple"
		elif( subChatColor in ["#FFB7B2", "#FF837A"] ):
			slimeColorName = "pink"
		elif( subChatColor in ["#92B3DD", "#5696EA"] ):
			slimeColorName = "blue"
		subPowerReversalPersistentDict.slimeColorName = slimeColorName
		setState("agility_power_reversal__failure__dream_of_slime__2melt1", "sub")
	elif(_id == "resist"):
		setState("agility_power_reversal__failure__dream_of_slime__2resist1", "sub")


func agility_power_reversal__failure__dream_of_slime__2resist1_text():
	saynn("{sub.You} swiftly {sub.youVerb('regain')} {sub.yourHis} senses.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__2resist1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func agility_power_reversal__failure__dream_of_slime__2melt1_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domIsKind:bool = domPersonalityMeanScore < -0.4
	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4
	var subIsKind:bool = subPersonalityMeanScore < -0.4

	var subInterestInBeingPenetrated:float = subPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0, Fetish.VaginalSexReceiving: 1.0 })
	var subLikesBeingPenetrated:bool = subInterestInBeingPenetrated >= 0.5
	var subInterestInPenetratingOthers:float = subPawn.scoreFetishMax({ Fetish.AnalSexGiving: 1.0, Fetish.VaginalSexGiving: 1.0 })
	var subLikesPenetratingOthers:bool = subInterestInPenetratingOthers >= 0.5

	if( sub.isPlayer() ):
		var slimeColorName:String = subPowerReversalPersistentDict.slimeColorName if( subPowerReversalPersistentDict.has("slimeColorName") ) else "red"

		saynn(
				"{sub.Your} colors, {sub.yourHis} patterns, all slowly begin to drip down. There is nothing for {dom.you} to grip onto anymore, with goo-like substance now filling the former shape of {sub.yourHis} arms. Eventually, that shape also drips downwards, merging to form a single-color substance, "
			+ (
					"so pure that one can see clearly through it."
				if(subIsKind)
				else (
						"muddy enough but one can still make out most of the objects behind it"
					if(subIsMean)
					else "partly opaque but one can see clearly through it"
				)
			)
		)

		saynn( "{sub.You} {sub.youVerb('retain')} most of what made {sub.youHim}, {sub.youHim}. But {sub.yourHis} appearance? No denying it, {sub.youreTheyre} a "+ slimeColorName +" slime. Almost as tall as {sub.yourHis} former captor." )
	else:
		saynn(
				"{sub.YouHe} {sub.youHeVerb('seem')} to be zoned out for longer than usual. "
			+ (
					"{dom.You} {dom.youVerb('ensure')} {sub.youreTheyre} okay, and make {sub.youHim} feel safe in {dom.yourHis} grasp."
				if(domIsKind)
				else (
						"{dom.You} {dom.youVerb('wonder')} what {dom.youHe} could do to {sub.youHim} in this state, but {dom.youVerb('figure')} there would be no fun in that."
					if(domIsMean)
					else "It makes {dom.you} a little worried at first, but {sub.youHe} {sub.youHeVerb('seem')} to be doing fine, just.. daydreaming."
				)
			)
		)

	var ACTION_NAME_PLAY:String = "Play"
	var ACTION_NAME_BOTTOM:String = "Bottom"
	var ACTION_NAME_TOP:String = "Top"

	addAction( "play", ACTION_NAME_PLAY, "Play around with them..", "default", ( 0.4 if(subLikesBeingPenetrated || subLikesPenetratingOthers) else 1.0 ), 60, {} )

	if( getReasonCharCannotPartakeInAnalSexGiving(dom, "dom") == null ):
		addAction( "bottom", ACTION_NAME_BOTTOM, "You've just got this new form, but already can't stop thinking about being penetrated..", "default", ( 1.0 if(subLikesBeingPenetrated) else -0.01 ), 60, {} )
	else:
		addDisabledAction(ACTION_NAME_BOTTOM, "They do not have the means to penetrate you.")

	if( getReasonCharCannotPartakeInAnalSexReceiving(dom, "dom") == null ):
		addAction( "top", ACTION_NAME_TOP, "You wish to use your new form to penetrate them..", "default", ( 1.0 if(subLikesPenetratingOthers) else -0.01 ), 60, {} )
	else:
		addDisabledAction(ACTION_NAME_TOP, "They do not have the means to be penetrated by you.")

func agility_power_reversal__failure__dream_of_slime__2melt1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "play"):
		var possibleScenarioSuffixes:Array = ["cuddle", "fondling", "gravity", "warp"]
		var randomScenario_suffix:String = RNG.pick(possibleScenarioSuffixes)
		setState( ("agility_power_reversal__failure__dream_of_slime__3play1"+ randomScenario_suffix +"1" ), "sub" )
	elif(_id == "bottom"):
		setState("agility_power_reversal__failure__dream_of_slime__3bottom1", "sub")
	elif(_id == "top"):
		setState("agility_power_reversal__failure__dream_of_slime__3top1", "sub")


func agility_power_reversal__failure__dream_of_slime__3play1cuddle1_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		var both_youThem:String = "you" if( isPlayerInvolved() ) else "them"
		var slimeColorName:String = subPowerReversalPersistentDict.slimeColorName if( subPowerReversalPersistentDict.has("slimeColorName") ) else "red"

		saynn("{dom.You} {dom.youVerb('inspect')} {sub.you} with caution, but also mild curiosity. {sub.YouHe} {sub.youHeVerb('wobble')} in response, opting not to move too much to avoid frightening {dom.youHim}.")

		saynn("{sub.You} {sub.youVerb('watch', 'watches')} as {dom.you} {dom.youVerb('lay')} down on {dom.yourHis} back, next to {sub.youHim}. {dom.YouHe} then {dom.youHeVerb('gesture')} something towards {sub.youHim}.")

		saynn("[say=dom]Humm. You seem harmless.. Would you like to lay on top? I imagine it'd be comfy.[/say]")

		saynn( "{sub.You} {sub.youVerb('decide')} to give it a try. It ends up being a very unusual sensation for {dom.you}. Like having a weighted blanket, in the form of a large "+ slimeColorName +" slime. But also not exactly like having a weighted blanket. The pose is comforting and quite cuddly. Both of "+ both_youThem +" rest like this for a little while." )
	else:
		saynn("{sub.You} {sub.youVerb('nuzzle')} {sub.yourHis} back against {dom.you} as {sub.youHe} {sub.youHeVerb('daydream')}.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3play1cuddle1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3play2", "sub")


func agility_power_reversal__failure__dream_of_slime__3play1fondling1_text():
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	if( sub.isPlayer() ):
		var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
		var domIsMean:bool = domPersonalityMeanScore > 0.4

		saynn("{dom.You} {dom.youVerb('tilt')} {dom.yourHis} head, unable to make heads or tails of what {sub.you} {sub.youAre}. {dom.YouHe} slowly {dom.youHeVerb('extend')} {dom.yourHis} arm and cautiously {dom.youHeVerb('poke')} {sub.youHim}. {sub.YouHe}'d like to react with an upwards bounce, but only {sub.youHeVerb('manage')} to spring up a few inches.")

		saynn(
				"{sub.YourHis} movement is met with another headtilt, now angled towards the opposite side. "
			+ (
					"{dom.You} {dom.youVerb('decide')} to play {sub.youHim} like a bongo."
				if(domIsMean)
				else "Still excessively careful, {dom.you} {dom.youVerb('try', 'tries')} to pet {sub.youHim}. {dom.YouHe} {dom.youHeVerb('start')} with a few strokes, but soon {dom.youHeVerb('feel')} confident to continue, as {sub.youre} clearly pleased by it."
			)
			+ " After a while, {sub.yourHis} reactions only encourage {dom.yourHis} touches to become more self-indulgent. {dom.You} {dom.youVerb('squeeze')} and {dom.youVerb('fondle')} through {sub.yourHis} iridescent surface, momentarily reshaping {sub.youHim}. It continuously fills {sub.youHim} with waves of pleasure, for what feels like a very long time."
		)
	else:
		saynn("{sub.You} needily {sub.youVerb('rub')} {sub.yourHis} arms against {dom.you} as {sub.youHe} {sub.youHeVerb('daydream')}.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3play1fondling1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3play2", "sub")


func agility_power_reversal__failure__dream_of_slime__3play1gravity1_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		var slimeColorName:String = subPowerReversalPersistentDict.slimeColorName if( subPowerReversalPersistentDict.has("slimeColorName") ) else "red"
		var both_youThem:String = "you" if( isPlayerInvolved() ) else "them"

		saynn("{dom.You} cautiously {dom.youVerb('touch', 'touches')} {sub.you}, taking one step back. {sub.YouHe} {sub.youDoHeDoes} {sub.yourHis} best to appear harmless, but against {sub.yourHis} persuasiveness, {dom.yourHis} touch results in something unusual. {sub.YouHe} {sub.youHaveHeHas} no way of conveying this has nothing to do with {sub.youHim}. {dom.YourHis} feet gradually lose touch with the ground, as {dom.yourHis} figure slowly gains altitude, revolving slightly along multiple axiis.")

		saynn("A loud automated speech is emitted by the announcement system, largely indecipherable aside from one word that {sub.you} {sub.youWere} able to make out. \"Gravity\". Not long after {dom.you}, {sub.youHe} too {sub.youHeVerb('begin')} to slowly float upwards, both reaching some kind of ceiling. Even in places that previously had none, there seems to be a solid barrier, its faint glow only revealing itself within a short distance.")

		saynn("{sub.You} {sub.youVerb('feel')} some kind of rumbling coming down from underneath, causing minor vibrations within the walls. In need of angular velocity to be able to check what's up, or rather, what's *down*, {sub.youHe} {sub.youDoHeDoes} a wobbly spin, overdoing it by one extra rotato, but eventually slowing down at a downwards-facing angle. From the edges of {sub.yourHis} slime vision, hundreds of assorted color spheres roll in, filling the ground space.")

		saynn( "Another indistinct announcement echoes past, and both of "+ both_youThem +" immediately plunge down. After a brief moment of laying inside the station-wide ball pit with just about one third of {sub.you} unobscured, one of the small spheres harmlessly bludgeons at {sub.yourHis} "+ slimeColorName +" slime shell. {sub.YouHe} {sub.youHeVerb('look')} upon the direction it was hurled from, spotting {dom.you} with a silly expression on {dom.yourHis} face. Both of "+ both_youThem +" remain like this for some time." )
	else:
		saynn("As {sub.you} {sub.youVerb('daydream')}, {sub.yourHis} perception of balance seems to be a little off, needing {dom.you} to support {sub.youHim}, in order to prevent any fall damage.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3play1gravity1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3play2", "sub")


func agility_power_reversal__failure__dream_of_slime__3play1warp1_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		saynn("{sub.Your} new form gives {dom.you} much more of a scare than one would expect. Under complete lack of composure, and in a hurry, {dom.youHe} {dom.youHeVerb('scour')} and {dom.youHeVerb('scramble')} through {dom.yourHis} own belongings, pulling out a shock remote, and in haste, pressing on the button, with the hopes that the shock collar is still somewhere inside of {sub.you}, and that it remains capable of calming {sub.youHim} down, albeit with force applied.")

		saynn("Instead, it seems to have.. *translocated* {sub.you} towards a rather unusual place. As {sub.youHe} {sub.youHeVerb('look')} around, {sub.yourHis} initial awe quickly shifts to a rather displeased state. It's an opulent residence, to a nonsensical degree. Each piece of furniture, the interior decorations, the electronics, machinery, all of them are state-of-the-art, but in the millions-of-creatures-were-exploited-to-procure-all-of-this sense. {sub.YourHis} immediate surroundings seem to be covered in spilled wine. {sub.YouHe} {sub.youHeVerb('manage')} to explore a few rooms, unable to spot any living beings, or anything of, not purely financial, value. Not long after, in a single gleaming flicker, {sub.youreTheyre} brought back to the prison, right next to the rather anxiously looking {dom.name}, who seems to have just pressed the button a second time.")

		saynn("{dom.YouHe}'d be glad to be rid of {sub.you}, but {dom.yourHis} dread of filling the paperwork is seemingly even greater than having to face a containment subject in a one-on-one scenario. {dom.YourHis} other paw now holds a magnetic net at the ready, and that thing is getting thrown at {sub.you}. Unavoidable.")
	else:
		saynn("{sub.You} {sub.youVerb('sway')} anxiously from side to side as {sub.youHe} {sub.youHeVerb('daydream')}.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3play1warp1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3play1warp2", "sub")


func agility_power_reversal__failure__dream_of_slime__3play1warp2_text():
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	if( sub.isPlayer() ):
		var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
		var domIsMean:bool = domPersonalityMeanScore > 0.4

		saynn( "Upon noticing an improbable opening that would only require immense reflexes, {sub.you} {sub.youVerb('get')} a rush of adrenaline. It appeared to have been strong enough to.. wake {sub.youHim} up? As {sub.yourHis} senses stabilize, and {sub.youHe} {sub.youHeVerb('inspect')} {sub.yourHis} surroundings, {sub.youHe} no longer {sub.youHeVerb('seem')} to be a slime, and nothing is being thrown {sub.yourHis} way aside from "+ ( "insults" if(domIsMean) else "flirtatious callouts" )+ " from {dom.name}, who holds {sub.you} by {sub.yourHis} wrists like {dom.youHe}'d be before. {sub.Youre} quite upset that none of that was real." )

		saynn("Later, upon walking past the television set that nobody valuing their time and mental health could really afford to pay attention to, {sub.youHe}'d see a strangely familiar environment with the tragic news about someone's passing. Was it not spilled wine? More importantly.. huh?")
	else:
		saynn("{sub.You} slowly {sub.youVerb('come')} back to {sub.yourHis} senses.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3play1warp2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func agility_power_reversal__failure__dream_of_slime__3play2_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		saynn("The colors begin to fade away. Eventually, {sub.your} senses tell {sub.youHim} that {sub.youHe} {sub.youAreHeIs} back to {sub.yourHis} previous form, and {dom.you} {dom.youAre} again tightly holding onto {sub.yourHis} wrists. Did any of that happen, or was it all in {sub.yourHis} mind? {dom.You} might have an idea, but {sub.youHe} {sub.youDontHeDoesnt} exactly feel like asking.")
	else:
		saynn("{sub.You} slowly {sub.youVerb('come')} back to {sub.yourHis} senses.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3play2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func agility_power_reversal__failure__dream_of_slime__3bottom1_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		saynn( "{sub.You} {sub.youVerb('approach', 'approaches')} closer, leaving {dom.you} no room to back away. {dom.YoureTheyre} visibly intimidated by a large volume of colorful slime pressing against {dom.yourHis} fur. {dom.YouHe} {dom.youHeVerb('dash', 'dashes')} to the "+ RNG.pick(["left", "right"]) +" side, but that only causes one of {dom.yourHis} legs to become trapped within {sub.you}. Hapless struggling drags {dom.youHim} into a deeper peril, with {sub.yourHis} slime form now enveloping everything up to {dom.yourHis} waist level." )

		saynn("Most creatures in fact do not wish for their legs to disintegrate. Understandably, that unavoidable fate brought {dom.you} to a state of panic. But after a minute of {dom.yourHis} heart setting new lap records, no permanent damage could be observed. {sub.You} wobbled, which ran a slow wave through {dom.your} lower half.")

		saynn("It took another minute for {dom.youHim} to calm down, only to remain highly irritated and noticeably alerted by other dangers {sub.you} may pose. Slowly, {dom.youHe} reached out with {dom.yourHis} paw, carefully pressing onto {sub.yourHis} surface. It held firm, preventing {dom.yourHis} arm from being swallowed within.")
	else:
		saynn("{sub.You} quietly {sub.youVerb('squirm')} for a little bit. Makes {dom.you} wonder what {sub.youreTheyre} dreaming about..")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3bottom1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3bottom2", "sub")


func agility_power_reversal__failure__dream_of_slime__3bottom2_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		saynn(
				"{sub.You} {sub.youWereHeWas} still getting used to this form, however {sub.youWereHeWas} already able to control it. It's highly limited in what it can do, with not a lot to learn. Besides adjusting firmness of {sub.yourHis} outer shell, {sub.youHe} seemed to be able to control the flow within {sub.youHim}. Trying it out merely tickled {dom.your} fur."
			+ (
					""
				if( domWasUndressed || dom.isFullyNaked() )
				else " With focus, {sub.youHe} {sub.youWereHeWas} eventually able to pull on {dom.yourHis} clothes, fully undressing {dom.youHim}."
			)
		)

		saynn("{dom.You} began to struggle more. At some point, {dom.youHe} tripped over, which caused {dom.yourHis} upper body to fall on top of {sub.you} – {sub.youHe} made sure it would remain on the outside. {dom.YourHis} arms still ended up partially enveloped, but that wasn't {sub.yourHis} intention, and it was something a swift nudge could easily resolve. {dom.You} however continued to rely primarily on {dom.yourHis} legs.")

		saynn( "As {dom.youHe} "+ ( "nudged around, {dom.youHe} felt" if( dom.isBlindfolded() ) else "looked down, {dom.youHe} saw" ) +" {dom.yourHis} member slowly get more and more aroused, as {dom.yourHis} hips struggled against the slime. That made {dom.youHim} pause. At this point, the emotions running through {dom.yourHis} mind were all too conflicting. {dom.YouHe} took a deep breath, discarding every thought in at attempt to find some clarity." )

		saynn("{dom.You} needed to take a step back, and {sub.you} let {dom.youHim}, perhaps literal too. {dom.YouHe} {dom.youWereHeWas} now fully on the outside, still leaning over. As {sub.youHe} gently rubbed {sub.yourHis} slime shape against {dom.yourHis} sensitive bits, they either throbbed or got stiff, sometimes both.. It was clear that {dom.youHe}, despite {dom.yourHis} worries about the unknown, did not want to use {dom.yourHis} provided opportunity to flee.")
	else:
		saynn("{dom.Your} curiousity is quite high, but {dom.youHe} {dom.youHeVerb('choose')} not to disturb {sub.you} just yet..")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3bottom2_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3bottom3", "sub")


func agility_power_reversal__failure__dream_of_slime__3bottom3_text():
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	if( sub.isPlayer() ):
		saynn( "{dom.YouHe} "+ ( "huffed" if(domIsMean) else "whined" ) + ", rubbing more and more against {sub.your} easily deformable shape. {dom.Your} member partially submerged past the outer surface, as it was insistingly brushing up and down. {sub.YouHe} {sub.youHeVerb('notice')} {dom.yourHis} paws grabbing onto {sub.youHim}, as {dom.youHe} {dom.youHeVerb('move')} {dom.yourHis} thighs backwards. {dom.YouHe} then {dom.youHeVerb('thrust')} into {sub.youHim} with such immense force, that {dom.yourHis} member becomes fully engulfed within {sub.you}, and {sub.yourHis} slime eyes each shift into an outline of a heart symbol." )

		saynn("{sub.You} can barely catch a break before {dom.you} {dom.youVerb('pull')} out and thrusts back in again. An attempt to draw a strength comparison fails entirely, as {sub.yourHis} whole slime being and mushy mind are occupied withstanding powerful thrusts, one after another, and another, and another..")
	else:
		saynn("{sub.You} {sub.youVerb('huff')} as {sub.youHe} {sub.youHeVerb('rub')} {sub.yourHis} butt against {dom.your} thighs. {sub.YoureTheyre} still too unconscious for it to signal any consent, but it gives {dom.youHim} a hint about what {sub.youHe} {sub.youHeVerb('like')}.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3bottom3_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3bottom4", "sub")


func agility_power_reversal__failure__dream_of_slime__3bottom4_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		saynn("{dom.You} {dom.youVerb('fuck')} {sub.you} silly for minutes and minutes, until eventually {dom.yourHis} knees give in, and {dom.youHe} {dom.youHeVerb('fill')} nearly all of {sub.yourHis} volume with {dom.yourHis} cum.")
	else:
		saynn("{sub.You} {sub.youVerb('emit')} a needy moan, almost waking {sub.yourselfHimself} up by doing that. {dom.You} {dom.youHave} a feeling that {sub.youreTheyre} rather close to waking up regardless.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3bottom4_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		subPowerReversalPersistentDict.hasAvoidedPunishment = RNG.chance(5)
		if(!subPowerReversalPersistentDict.hasAvoidedPunishment):
			addSubRestraintUponFailingPowerReversal()
		setState("agility_power_reversal__failure__dream_of_slime__3bottom5", "sub")


func agility_power_reversal__failure__dream_of_slime__3bottom5_text():
	var sub = getRoleChar("sub")

	var hasAvoidedPunishment:bool = subPowerReversalPersistentDict.hasAvoidedPunishment if( subPowerReversalPersistentDict.has("hasAvoidedPunishment") && subPowerReversalPersistentDict.hasAvoidedPunishment ) else false

	if( sub.isPlayer() ):
		saynn("{sub.You} {sub.youVerb('look')} around to witness the whole environment beginning to flood with cum. As it washes over {sub.youHim}, {sub.youHe} {sub.youHeVerb('happen')} to wake up in {sub.yourHis} previous form, with {dom.you} tightly holding {sub.youHim} by {sub.yourHis} wrists. Was any of that real? {sub.YouHe} {sub.youHeVerb('decide')} that to {sub.youHim}, it was.")

		saynn("{sub.YoureTheyre} not yet sure if that includes the cum flooding part.")
	else:
		saynn("{sub.You} slowly {sub.youVerb('come')} back to {sub.yourHis} senses.")

	if(hasAvoidedPunishment):
		saynn("[say=sub]Would you fuck me if I was a slime?[/say]")
		saynn("[say=dom]What.[/say]")
		saynn("[say=sub]What.[/say]")
	else:
		if( subPowerReversalObtainedRestraints.size() >= 1 ):
			saynn(
					"[say=dom]You've been making a lot of noise for someone not paying any attention. "
				+ (
						(
								"These "
							+ subPowerReversalObtainedRestraints[0].a_name
						)
					if( subPowerReversalObtainedRestraints[0].nameIsPlural )
					else (
							"Perhaps "
						+ subPowerReversalObtainedRestraints[0].a_name
					)
				)
				+ " will remind you how to behave.[/say]"
			)

			saynn("A distinct -snap- sound makes {sub.you} realize that {sub.youreTheyre} now wearing a new restraint.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3bottom5_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func agility_power_reversal__failure__dream_of_slime__3top1_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subPawn = getRolePawn("sub")

	var subInterestInOralSexReceiving:float = subPawn.scoreFetishMax({ Fetish.OralSexReceiving: 1.0 })
	var subLikesOralSexReceiving:bool = (subInterestInOralSexReceiving >= 0.5)

	if( sub.isPlayer() ):
		saynn("{sub.Your} form is adorable, but it'd be way more advantageous if-.. Hmhh.. {sub.You} {sub.youVerb('close')} {sub.yourHis} slime eyes to focus, attempting to control the flow of essence that comprises {sub.youHim}, channeling {sub.yourHis} emotions and lust. {sub.YoureTheyre} set on shifting into a shape that's greatly intimidating to even the most fearless inmates, while simultaneously being a shape that fills {sub.yourHis} mind with comfort and dozens of unshakeable horny thoughts, after one mere glance at {sub.yourHis} own body. At times, it still resembles the substance of a slime, but more often it's entirely up to the form {sub.youHe} {sub.youVerb('choose', 'chose')}, with a sprinkle of raw intimidation.")
	else:
		saynn("{sub.You} quietly {sub.youVerb('huff')}. Makes {dom.you} wonder what {sub.youreTheyre} dreaming about..")

	var ACTION_NAME_ORAL:String = "Oral"
	var ACTION_NAME_SKIP_ORAL:String = "Skip oral"

	if( !dom.isOralBlocked() ):
		addAction( "oral", ACTION_NAME_ORAL, "Make them choke on your sizeable member.", "default", ( 1.0 if(subLikesOralSexReceiving) else -0.01 ), 60, {} )
	else:
		addDisabledAction(ACTION_NAME_ORAL, "They cannot suck you off.")

	addAction( "skip_oral", ACTION_NAME_SKIP_ORAL, "Skip shoving your member into their mouth.", "justleave", 1.0, 60, {} )

func agility_power_reversal__failure__dream_of_slime__3top1_do(_id:String, _args:Dictionary, _context:Dictionary):
	var potentialTargetSnippets:Array = []
	var dynamicGuardIDs:Array = GM.main.getDynamicCharacterIDsFromPool(CharacterPool.Guards)

	if( dynamicGuardIDs.size() >= 1 ):
		for dynamicGuardID in dynamicGuardIDs:
			var someGuardPawnMayBeNull:CharacterPawn = getPawn(dynamicGuardID)

			if( (someGuardPawnMayBeNull != null) && isPawnInvolved(someGuardPawnMayBeNull) ):
				continue

			var someGuardChar:BaseCharacter = GlobalRegistry.getCharacter(dynamicGuardID)

			if(someGuardChar == null):
				continue

			var someGuardSnippet:Dictionary = {
				name = someGuardChar.getName(),
				formatted_dialogue_line = "",
			}

			var someGuardLikesAnalSexReceiving:bool = someGuardChar.getFetishHolder().scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 }) >= 0.5

			var dialogueLines:Array = [
				"God I wish that was me.",
			]

			someGuardSnippet.formatted_dialogue_line = "[b]"+ someGuardSnippet.name +"[/b]: "+ someGuardChar.formatSay( RNG.pick(dialogueLines) )

			if(someGuardLikesAnalSexReceiving):
				potentialTargetSnippets.append(someGuardSnippet)

	if( potentialTargetSnippets.size() >= 1 ):
		var targetSnippet:Dictionary = RNG.pick(potentialTargetSnippets)

		subPowerReversalPersistentDict = {
			target_name = targetSnippet.name,
			target_formatted_dialogue_line = targetSnippet.formatted_dialogue_line,
		}

	if(_id == "oral"):
		setState("agility_power_reversal__failure__dream_of_slime__3top2oral1", "sub")
	elif(_id == "skip_oral"):
		subPowerReversalPersistentDict.skippedOral = true
		setState("agility_power_reversal__failure__dream_of_slime__3top3", "sub")


func agility_power_reversal__failure__dream_of_slime__3top2oral1_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		saynn("{dom.You} {dom.youVerb('take')} a few uneasy steps back, as {sub.you} {sub.youVerb('stand')} in front of {dom.youHim}, now significantly way taller, and even more so, threatening. As {sub.youHe} {sub.youHeVerb('narrow')} through that distance, the shaft of {sub.yourHis} erect cock stands within one hindpaw from {dom.your} face.")

		saynn("{dom.YouHe} {dom.youVerb('gulp')} from its mere presence, slowly moving {dom.yourHis} head closer to carefully kiss through {sub.yourHis} overwhelmingly sized member. {dom.YouHe} had hoped that as a result, {sub.youHe}'d handle {dom.youHim} at least a hint more sparing. While it did please {sub.you} quite a bit, it only made {sub.youHim} relish in {sub.yourHis} dominance.")

		saynn("{sub.You} {sub.youVerb('slap')} through {dom.your} face with {sub.yourHis} giant member, its weight greatly helping {sub.youHim} toy with {dom.youHim}. As {dom.youHe} {dom.youHeVerb('attempt')} to recover, {sub.youHe} {sub.youHeVerb('handle')} {dom.youHim} rather greedily, grabbing {dom.yourHis} muzzle, and forcing {dom.yourHis} maw open, to shove {sub.yourHis} eager member inside. At first only its tip manages to fit in, but with enough effort {sub.youHe} {sub.youHeVerb('manage')} to squeeze in most of {sub.yourHis} length.")

		saynn("[say=dom]Hhhfghh-[/say]")

		saynn("{dom.YouHe} {dom.youHeVerb('struggle')} greatly, barely able to take {sub.yourHis} member in {dom.yourHis} mouth. As lust flows through {sub.youHim}, it pushes {sub.youHim} to use {dom.your} body even more. {sub.You} {sub.youVerb('grab')} {dom.yourHis} wrists, thrusting {sub.yourHis} thighs with tremendous force, reaching deep into {dom.yourHis} throat. While moving {sub.yourHis} thighs back, {sub.youHe} sometimes {sub.youHeVerb('pull')} out without meaning to, only to immediately shove {sub.yourHis} member back in, eagerly fucking {dom.yourHis} mouth again and again..")
	else:
		saynn("{sub.Youre} now panting more and more, still seemingly unconscious.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3top2oral1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3top3", "sub")


func agility_power_reversal__failure__dream_of_slime__3top3_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		if( subPowerReversalPersistentDict.has("skippedOral") && subPowerReversalPersistentDict.skippedOral ):
			saynn("{dom.You} {dom.youVerb('take')} a few uneasy steps back, as {sub.you} {sub.youVerb('stand')} in front of {dom.youHim}, now significantly way taller, and even more so, threatening. Being able to easily lift {dom.youHim} in the air with just one of {sub.yourHis} arms is a good example of the extent of power that {sub.youHe} {sub.youHaveHeHas} over {dom.youHim}.")
		else:
			saynn("Having felt that {sub.youHe} toyed enough with {dom.yourHis} maw, {sub.you} {sub.youVerb('make')} sure to play with the rest of {dom.yourHis} body too, and being able to easily lift {dom.youHim} in the air with just one of {sub.yourHis} arms is a good example of the extent of power that {sub.youHe} {sub.youHaveHeHas} over {dom.youHim}.")

		saynn("{sub.You} greedily {sub.youVerb('fondle')} through {dom.your} curves, covering {dom.youHim} in a layer of saliva as {sub.youHe} {sub.youHeVerb('make')} out and needily {sub.youHeVerb('rub')} {sub.yourselfThemself} against {dom.youHim}. Soon after, {sub.youre} pounding {dom.yourHis} hole while {dom.yourHis} legs helplessly wiggle in the air, muffled moans leave {dom.yourHis} mouth, and {dom.yourHis} sensitive bits struggle to hide {dom.yourHis} pleasure.")

		if( subPowerReversalPersistentDict.has("target_formatted_dialogue_line") && RNG.chance(10) ):
			var target_name:String = subPowerReversalPersistentDict.target_name if( subPowerReversalPersistentDict.has("target_name") ) else "Guard"
			var both_youThem:String = "you" if( isPlayerInvolved() ) else "them"
			var both_yourTheir:String = "your" if( isPlayerInvolved() ) else "their"

			saynn( target_name +" walks past the two of "+ both_youThem +", eyeing "+ both_yourTheir +" passionate interaction with great attention to detail.." )

			saynn(subPowerReversalPersistentDict.target_formatted_dialogue_line)
	else:
		saynn("{sub.You} can be seen thrusting against the space in front of {sub.youHim}. {dom.You} can now somewhat guess what {sub.youreTheyre} dreaming of.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3top3_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		setState("agility_power_reversal__failure__dream_of_slime__3top4", "sub")


func agility_power_reversal__failure__dream_of_slime__3top4_text():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		saynn("{sub.You} {sub.youVerb('continue')} using {dom.you}, {sub.yourHis} movements and grabs possessive and animalistic. The tone of {dom.yourHis} destitute squirms and the sensation of {dom.yourHis} luscious thighs push {sub.youHim} over the limit, and {sub.youHe} {sub.youHeVerb('fill')} {dom.yourHis} hole to the brim,, To {sub.you} however, that limit is a mere suggestion. As large quantities of cum keep dripping out of {dom.yourHis} hole, {sub.youHe} {sub.youHeVerb('keep')} pounding {dom.youHim} more and more, needily stuffing {dom.youHim}, only to switch up the pose and resume with even more lust..")
	else:
		saynn("{sub.You} {sub.youVerb('huff')} profusely, no longer moving as much. {dom.You} {dom.youHave} a feeling that {sub.youHe} will soon wake up.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3top4_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		addSubRestraintUponFailingPowerReversal()
		setState("agility_power_reversal__failure__dream_of_slime__3top5", "sub")


func agility_power_reversal__failure__dream_of_slime__3top5_text():
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domPersonalitySubbyScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var domIsSubby:bool = domPersonalitySubbyScore > 0.4

	if( sub.isPlayer() ):
		saynn("This continues on and on, for.. who knows how long? {sub.Youve} lost track of time a long while ago. {sub.Your} senses fade completely. Once they return, {sub.youHe} {sub.youHeVerb('seem')} to be in {sub.yourHis} usual form, and {dom.you} {dom.youAre} tightly holding {sub.yourHis} wrists again. Was all of that only a dream? It felt so.. real.. {sub.You} {sub.youVerb('take')} a bit to process all of this, clearly disappointed. Eventually, {sub.youHe} {sub.youHeVerb('decide')} that to {sub.youHim}, it was real.")
	else:
		saynn("{sub.You} slowly {sub.youVerb('come')} back to {sub.yourHis} senses.")

	var dialogueSequenceVariants:Array = []

	if(domIsMean):
		dialogueSequenceVariants.append_array([
			[
				"Hey, whore. Were you just daydreaming about fucking someone?",
				"Daydreaming about fucking *me*? I-..",
			]
		])
	else:
		dialogueSequenceVariants.append_array([
			[
				"You seemed like you had a rather wet daydream~. Wanna tell me who was it you were domming?",
				"You were dreaming of domming *me*? W- Wow..",
			]
		])

	var randomDialogueSequence:Array = RNG.pick(dialogueSequenceVariants)

	saynn( "[say=dom]"+ randomDialogueSequence[0] +"[/say]" )

	saynn( RNG.pick([
		"{sub.You} {sub.youVerb('lower')} {sub.yourHis} head with a bit of guilt on {sub.yourHis} face.",
		"{sub.You} {sub.youVerb('keep')} silent, dodging the question, which tells {dom.you} more than enough.",
	]) )

	saynn(
			"[say=dom]"
		+ randomDialogueSequence[1]
		+ " "
		+ (
				"Uh.. Uhm... Mmhh.. "
			if( domIsSubby && RNG.chance(50) )
			else ""
		)
		+ (
				(
						(
								"Y- You are getting "
							+ (
									(
											"these "
										+ subPowerReversalObtainedRestraints[0].a_name
									)
								if( subPowerReversalObtainedRestraints[0].nameIsPlural )
								else subPowerReversalObtainedRestraints[0].a_name
							)
							+ " for d- doing that, you h- hear me!,,"
						)
					if(domIsSubby)
					else (
							"Let's get you "
						+ (
								(
										"some "
									+ subPowerReversalObtainedRestraints[0].a_name
								)
							if( subPowerReversalObtainedRestraints[0].nameIsPlural )
							else subPowerReversalObtainedRestraints[0].a_name
						)
						+ " to remind you of your place here."
					)
				)
			if( subPowerReversalObtainedRestraints.size() >= 1 )
			else (
					"Y- You're all covered in r- restraints and you're s- still thinking about b- being the dom?,, Huff.."
				if(domIsSubby)
				else "With the amount of restraints you're wearing, I'm really surprised you still imagine yourself as anything but a playtoy for others to use."
			)
		)
		+ "[/say]"
	)

	if( subPowerReversalObtainedRestraints.size() >= 1 ):
		saynn("A new restraint adorns {sub.your} body.")

	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__dream_of_slime__3top5_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


func agility_power_reversal__failure__shock_remote__1_text():
	saynn("One swift movement of {sub.your} paws, and {sub.youreTheyre} holding a shock remote that {sub.youHe}'d stash a cycle or two prior. Fetching one round the cellblock wasn't easy, but a remote tailored specifically to match {dom.nameS} collar? It's really not often these get pawned here. Recalling what {sub.you} had to agree to, in exchange for the favor, makes {sub.youHim} uncomfortably swallow. But {sub.youHe} {sub.youHaveHeHas} it now, so {sub.youHe} {sub.youHeVerb('press', 'presses')} the button with a lightly drooly grin.")

	incl_power_reversal_stamina_cost()
	addAction("continue", "Continue", "See what happens next..", "default", 1.0, 60, {})

func agility_power_reversal__failure__shock_remote__1_do(_id:String, _args:Dictionary, _context:Dictionary):
	var dom = getRoleChar("dom")

	clearMessagesForChar(dom)

	if(_id == "continue"):
		var dynamicInmateIDs:Array = GM.main.getDynamicCharacterIDsFromPool(CharacterPool.Inmates)

		if( dynamicInmateIDs.empty() ):
			setState("agility_power_reversal__failure__shock_remote__2nothing1", "sub")
			return

		var potentialTargetSnippets_veryMean:Array = []
		var potentialTargetSnippets_masochistic:Array = []

		for dynamicInmateID in dynamicInmateIDs:
			var someInmatePawnMayBeNull:CharacterPawn = getPawn(dynamicInmateID)

			if( (someInmatePawnMayBeNull != null) && isPawnInvolved(someInmatePawnMayBeNull) ):
				continue

			var someInmateChar:BaseCharacter = GlobalRegistry.getCharacter(dynamicInmateID)

			if(someInmateChar == null):
				continue

			var someInmateSnippet:Dictionary = {
				name = someInmateChar.getName(),
				them = someInmateChar.himHer(),
				their = someInmateChar.hisHer(),
				they = someInmateChar.heShe(),
				theyve = someInmateChar.theyve(),
				formatted_dialogue_line = "",
			}

			var someInmateIsVeryMean:bool = someInmateChar.getPersonality().personalityScoreMax({ PersonalityStat.Mean: 1.0 }) > 0.7
			var someInmateIsMasochistic:bool = someInmateChar.getFetishHolder().scoreFetishMax({ Fetish.Masochism: 1.0 }) >= 0.5

			var dialogueLines:Array = []

			if(someInmateIsMasochistic):
				dialogueLines.append_array([
					"O- Ooh, f-ffuckhh y- yesss..",
					"G- Guhhhffh~..",
				])

				if( RNG.chance(10) ):
					dialogueLines.append_array([
						"T- Thunderstruck, yeah!!",
					])
			else:
				dialogueLines.append_array([
					"What the fuck did I do- aaaaARH-",
					"Guards, whYYYYY AAAAAHH-",
					"No no no not agai- rrAAAAH-",
				])

			someInmateSnippet.formatted_dialogue_line = "[b]"+ someInmateSnippet.name +"[/b]: "+ someInmateChar.formatSay( RNG.pick(dialogueLines) )

			if(someInmateIsVeryMean):
				potentialTargetSnippets_veryMean.append(someInmateSnippet)

			if(someInmateIsMasochistic):
				potentialTargetSnippets_masochistic.append(someInmateSnippet)

		var targetCriteria:String = "someone_very_mean" if( ( potentialTargetSnippets_veryMean.size() >= 1 ) && RNG.chance(50) ) else "someone_masochistic"
		var potentialTargetSnippets:Array = potentialTargetSnippets_veryMean if(targetCriteria == "someone_very_mean") else potentialTargetSnippets_masochistic

		if( potentialTargetSnippets.size() == 0 ):
			subPowerReversalPersistentDict = {}
			setState("agility_power_reversal__failure__shock_remote__2nothing1", "sub")
			return

		var targetSnippet:Dictionary = RNG.pick(potentialTargetSnippets)

		subPowerReversalPersistentDict = {
			target_criteria = targetCriteria,
			target_name = targetSnippet.name,
			target_them = targetSnippet.them,
			target_their = targetSnippet.their,
			target_they = targetSnippet.they,
			target_theyve = targetSnippet.theyve,
			target_formatted_dialogue_line = targetSnippet.formatted_dialogue_line,
		}

		setState("agility_power_reversal__failure__shock_remote__2targeted1", "sub")


func agility_power_reversal__failure__shock_remote__2nothing1_text():
	saynn("..Nothing happens. At all..")

	addAction("continue", "Fuck..", "Useless piece of hardware.. It would be a good idea to get rid of it now, but that's not something you planned for..", "default", 1.0, 60, {})

func agility_power_reversal__failure__shock_remote__2nothing1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		addSubRestraintUponFailingPowerReversal()
		setState("agility_power_reversal__failure__shock_remote__4", "sub")


func agility_power_reversal__failure__shock_remote__2targeted1_text():
	saynn("..Nothing seems to have happened. This tenses {sub.you} up a little, and {sub.youHe} {sub.youHeVerb('try', 'tries')} it once more. A sound that {sub.yourHis} ears reflexively nullified the first time, has echoed louder.")

	if( subPowerReversalPersistentDict.has("target_formatted_dialogue_line") ):
		saynn(subPowerReversalPersistentDict.target_formatted_dialogue_line)

	saynn("...{sub.You} {sub.youVerb('feel')} as if it was {sub.yourHis} own collar that's been shocked. This was {sub.yourHis} way out, and the only option at that..")

	addAction("oops", "Oops", "This was not supposed to happen..", "default", 1.0, 60, {})

	var ACTION_DESC_PRESS_AGAIN:String = "Screw that creature in particular." if( !subPowerReversalPersistentDict.has("target_criteria") || (subPowerReversalPersistentDict.target_criteria == "someone_very_mean") ) else "Let them have their share of fun."
	addAction("press_again", "Press again", ACTION_DESC_PRESS_AGAIN, "default", 1.0, 60, {})

func agility_power_reversal__failure__shock_remote__2targeted1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "oops"):
		setState("agility_power_reversal__failure__shock_remote__3oops1", "sub")
	elif(_id == "press_again"):
		setState("agility_power_reversal__failure__shock_remote__3repeat1", "sub")


func agility_power_reversal__failure__shock_remote__3oops1_text():
	var target_name:String = subPowerReversalPersistentDict.target_name if( subPowerReversalPersistentDict.has("target_name") ) else "the poor inmate"
	var target_them:String = subPowerReversalPersistentDict.target_them if( subPowerReversalPersistentDict.has("target_them") ) else "them"

	if( !subPowerReversalPersistentDict.has("target_criteria") || (subPowerReversalPersistentDict.target_criteria == "someone_very_mean") ):
		saynn( "{sub.You} {sub.youVerb('feel')} {sub.youHe}'ll have to make it up to "+ target_name +" later. Walk up to "+ target_them +" looking all guilty, offer to please "+ target_them +" every dusk and dawn of the year. No suspicion will be raised that day, nuh-uh." )
	else:
		saynn("{sub.You} {sub.youAre} fortunate that the creature on the receiving end was into it. Guilt is not something {sub.youHe} {sub.youHaveHeHas} to deal with right now.. Hiding the remote is.")

	addAction("continue", "Hide remote", "Uh, fuck.. How did you even get it out in the first place..", "default", 1.0, 60, {})

func agility_power_reversal__failure__shock_remote__3oops1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		addSubRestraintUponFailingPowerReversal()
		setState("agility_power_reversal__failure__shock_remote__4", "sub")


func agility_power_reversal__failure__shock_remote__3repeat1_text():
	var sub = getRoleChar("sub")

	var target_name:String = subPowerReversalPersistentDict.target_name if( subPowerReversalPersistentDict.has("target_name") ) else "the inmate"
	var target_them:String = subPowerReversalPersistentDict.target_them if( subPowerReversalPersistentDict.has("target_them") ) else "them"
	var target_their:String = subPowerReversalPersistentDict.target_their if( subPowerReversalPersistentDict.has("target_their") ) else "their"
	var target_they:String = subPowerReversalPersistentDict.target_they if( subPowerReversalPersistentDict.has("target_they") ) else "they"
	var target_theyve:String = subPowerReversalPersistentDict.target_theyve if( subPowerReversalPersistentDict.has("target_theyve") ) else "they've"

	if( !subPowerReversalPersistentDict.has("target_criteria") || (subPowerReversalPersistentDict.target_criteria == "someone_very_mean") ):
		saynn( "{sub.Youre} angry at this whole situation, but honestly? {sub.YouHe} {sub.youHeVerb('press', 'presses')} the button again. Not as much out of frustration. {sub.YouHe} can distinctly recognize "+ target_name +"'s voice, and for all the time {sub.youve} known "+ target_them +", "+ target_theyve +" only been fucking mean to {sub.you}. To everyone merely trying to get by. If anyone here deserves to be fried until they kneel over and can take a no, that has to be "+ target_them +"." )

		saynn("{sub.You} {sub.youVerb('avert')} {sub.yourHis} ears from the consequences of {sub.yourHis} actions.")
	else:
		saynn("{sub.You} {sub.youAre} quite unhappy with the predicament that {sub.youHe} found {sub.yourselfThemself} in. {sub.YouHe} {sub.youHeVerb('shrug')}, figuring that at least someone here deserves a pleasing ending, and {sub.youHeVerb('press', 'presses')} the button of a shocker remote one more time.")

		saynn(
				( target_name +" "+ RNG.pick(["moans", "squeals", "squirms"]) +" somewhere in the distance." )
			+ (
					( " {sub.You} {sub.youVerb('imagine')} that if "+ ( target_they if( sub.isPlayer() ) else target_name ) +" didn't have "+ target_their +" arms bound, "+ target_they +" would do a thumbs up gesture saying \"I'm okay,,\"." )
				if( RNG.chance(10) )
				else ""
			)
		)

	addAction("continue", "Hide remote", "Uhm.. Is this even something you can do?", "default", 1.0, 60, {})

func agility_power_reversal__failure__shock_remote__3repeat1_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		addSubRestraintUponFailingPowerReversal()
		setState("agility_power_reversal__failure__shock_remote__4", "sub")


func agility_power_reversal__failure__shock_remote__4_text():
	var sub = getRoleChar("sub")

	saynn("{dom.You} {dom.youVerb('notice')} the remote rather quickly, snatching it out of {sub.your} paws, and swiping it at the nearest wall at what felt like two parsecs per year.")

	if( subPowerReversalPersistentDict.has("target_name") ):
		var sub_them:String = sub.himHer()
		var target_them:String = subPowerReversalPersistentDict.target_them if( subPowerReversalPersistentDict.has("target_them") ) else "them"

		var subAndTarget_you_two:String = "you two"
		if( (sub_them == "it") and (target_them == "it") ):
			subAndTarget_you_two = "you things"
		elif( (sub_them == "her") and (target_them == "her") ):
			subAndTarget_you_two = "you girlthings"
		elif( (sub_them == "him") and (target_them == "him") ):
			subAndTarget_you_two = "you boythings"

		saynn(
				"[say=dom]"
			+ "I don't care what kinky stuff "
			+ subAndTarget_you_two
			+ " are up to, I'm the only one you should be paying your full attention."
			+ (
					" Perhaps this will help you remember that."
				if( subPowerReversalObtainedRestraints.size() >= 1 )
				else ""
			)
			+ "[/say]"
		)
	else:
		saynn("[say=dom]I've got more than enough toys for you, we wouldn't need any of yours.[/say]")

	if( subPowerReversalObtainedRestraints.size() >= 1 ):
		saynn(
				"{sub.You} could hardly blink before "
			+ subPowerReversalObtainedRestraints[0].a_name
			+ " "
			+ (
					"were"
				if( subPowerReversalObtainedRestraints[0].nameIsPlural )
				else "was"
			)
			+ " firmly "
			+ RNG.pick(["placed", "put"])
			+ " onto {sub.youHim}."
		)

	addAction("continue", "Damn remote..", "Can't trust a single bark in the underground..", "default", 1.0, 60, {})

func agility_power_reversal__failure__shock_remote__4_do(_id:String, _args:Dictionary, _context:Dictionary):
	if(_id == "continue"):
		incl_sub_resist_do()


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


func incl_sub_do():
	if(subSnarkCooldown > 0):
		subSnarkCooldown -= 1

	if(domFlirtCooldown > 0):
		domFlirtCooldown -= 1

	if(domSpecialActionCooldown > 0):
		domSpecialActionCooldown -= 1

func incl_sub_resist_pick_random_event_line():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domPersonalityNaiveScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Naive: 1.0 })
	var domIsNaive:bool = domPersonalityNaiveScore > 0.4

	var subSpecies = sub.getSpecies()

	var both_youThem:String = "you" if( isPlayerInvolved() ) else "them"
	var both_You_reThey_re:String = "You're" if( isPlayerInvolved() ) else "They're"

	var eventLines:Array = []
	var attentionDivertEventLine:String = ""

	var isFirstNonSkippableResist:bool = (subResistedTimes <= 1)

	if(isFirstNonSkippableResist):
		eventLines.append_array([
			"{sub.You} {sub.youVerb('try', 'tries')} to struggle out of {dom.your} grip, but it's no use. {dom.You} {dom.youVerb('hold')} {sub.youHim} tight, like an animal that has just caught its prey.",
			"{sub.You} {sub.youVerb('attempt')} to wiggle {sub.yourHis} way out, but {sub.youVerb('end')} up rubbing {sub.yourHis} soft butt all over {dom.your} crotch, which makes {dom.youHim} grip {sub.youHim} even tighter.",
		])
	else:
		# Standing or pinned down

		eventLines.append_array([
			"{sub.You} {sub.youVerb('put')} up quite a fight.. As one could expect, it only amplified {dom.your} desire to see {sub.youHim} in a state where {sub.youHe} really {sub.youHeVerb('want')} this..",
			"{sub.You} {sub.youVerb('make')} it clear, through very mild violence, that {dom.you} cannot have {dom.yourHis} way with {sub.youHim}. At the very least, not yet..",
			"{sub.You} {sub.youVerb('fuss', 'fusses')} about, while repeatedly failing to tackle {dom.you}. It is inexplicit how much of {sub.yourHis} discontent is genuine.",
			"{sub.You} {sub.youVerb('attempt')} to resist {dom.your} influence, wishing for external factors to provide {sub.youHim} with an opportunity to break out.",
		])

		if( sub.bodypartHasTrait(BodypartSlot.Tail, PartTrait.TailFlexible) ):
			eventLines.append_array([
				( "{sub.You} {sub.youVerb('put')} {dom.you} off {dom.yourHis} stride by "+ RNG.pick(["relentlessly", "ruthlessly", "wrathfully"]) +" "+ RNG.pick(["swinging", "swishing", "whipping"]) +" {sub.yourHis} tail right over {dom.yourHis} face." ),
			])

		if( sub.isStaff() ):
			eventLines.append_array([
				"{sub.You} {sub.youVerb('hope')} to catch attention of nearby personnel or security cameras. Even when {sub.youHe} {sub.youDoHeDoes} succeed, staff tends to pretend it doesn't concern them. On the rare occassion someone does care, they end up lovingly watching {sub.youHim} be played with..",
			])

		if( RNG.chance(40) ):
			var imaginationEventLineEndingVariants:Array = [
				" where {sub.youHe} {sub.youHeVerb('drop')} a cartoon anvil onto {dom.youHim}.",
				" where {sub.youHe} {sub.youHeVerb('stretch', 'stretches')} {dom.youHim} silly.",
				" where {sub.youHe} {sub.youHeVerb('launch', 'launches')} a thousand trouts towards {dom.youHim} at maximum velocity.",
				" where {sub.youHe} power {sub.youHeVerb('wash', 'washes')} {dom.youHim} with a hose.",
			]

			if( RNG.chance(20) ):
				imaginationEventLineEndingVariants.append_array([
					" where {dom.youHe} {dom.youAreHeIs} put in a horny jai- Oh right..",
				])

			if( subSpecies.has(Species.Feline) ):
				imaginationEventLineEndingVariants.append_array([
					" where {sub.youHe} {sub.youHeVerb('humiliate')} {dom.youHim} with a laser pointer that {dom.youHe} can't resist chasing after.",
				])

			if( sub.isPlayer() ):
				imaginationEventLineEndingVariants.append_array([
					" and.. and what.. {dom.YouHe} {dom.youHeVerb('look')} so hot.. {sub.YouHe} forgot what {sub.youHe} {sub.youWereHeWas} going to do to {dom.youHim}..",
				])

				if( RNG.chance(10) ):
					imaginationEventLineEndingVariants.append_array([
						" where you Zoltraak {dom.yourHis} ass.",
					])

			var randomImaginationEventLineEnding:String = RNG.pick(imaginationEventLineEndingVariants)

			eventLines.append_array([
				( "{sub.Youre} unsure how to resist {sub.yourHis} way out of this. {sub.YouHe} {sub.youHeVerb('picture')} {dom.you} in {sub.yourHis} mind" + randomImaginationEventLineEnding ),
			])

		var hasExhaustedAllAttentionDivertEventLines:bool = ( subResistedWithAttentionDivertAttemptTimes >= ( 2 if( dom.isBitingBlocked() ) else 3 ) )

		if( subMayAttemptAttentionDivert && !hasExhaustedAllAttentionDivertEventLines && !dom.isBlindfolded() && !sub.isBlindfolded() ):
			attentionDivertEventLine = ( "{sub.You} {sub.youVerb('stare')} "+ RNG.pick(["at something", "off somewhere"]) +" with "+ RNG.pick(["evident", "noticeable"]) +" "+ RNG.pick(["anxiety", "distress", "unease"]) +", hoping to get {dom.you} to divert {dom.yourHis} attention. " )

			if( (subResistedWithAttentionDivertAttemptTimes >= 2) && !dom.isBitingBlocked() ):
				attentionDivertEventLine += "[color="+ getSensationColor("pain_moderate") +"]{dom.YouHe} {dom.youHeVerb('bite')} {sub.youHim}, {dom.youHe} {dom.youHeVerb('bite')} {sub.youHim}, {dom.youHe} {dom.youHeVerb('bite')} {sub.youHim}..[/color]"
			elif(subResistedWithAttentionDivertAttemptTimes >= 1):
				attentionDivertEventLine += "{dom.YouveTheyve} witnessed this trick way too many times, so {dom.youHe} simply {dom.youHeVerb('ignore')} {sub.youHim}."
			else:
				if(domIsNaive):
					attentionDivertEventLine += "{sub.YourHis} face expression makes {dom.youHim} quite alert. {dom.YouHe} {dom.youHeVerb('inspect')} the direction towards which {sub.you} {sub.youWere} looking, but find nothing except the plain usual environment."
				else:
					attentionDivertEventLine += "{dom.YouHe} reluctantly {dom.youHeVerb('turn')} around along with {sub.youHim}, checking that there is indeed nothing there."

			for n in 3:
				eventLines.append(attentionDivertEventLine)

		if(!subWasPinnedToTheGround):
			# Standing

			if( !dom.isGagged() && !dom.isMuzzled() ):
				# Uses tongue
				eventLines.append_array([
					"{sub.You} {sub.youVerb('keep')} struggling, hoping to catch an opportune moment to break free. {dom.You} only {dom.youVerb('pull')} {sub.youHim} closer in, and {dom.youVerb('proceed')} to give {sub.yourHis} neck a prolonged lick.",
				])

			if( !dom.isGagged() ):
				# Grins or smiles
				eventLines.append_array([
					( "{sub.You} {sub.youVerb('try', 'tries')} to shove {dom.you} away, but with hands behind {sub.yourHis} back it proves to be difficult. There's a momentary "+ ( "grin" if(domIsMean) else "smile" ) +" on {dom.yourHis} face, but {sub.youHe} could only guess the emotions that run through it." ),
				])

			if( !sub.hasBlockedHands() ):
				eventLines.append_array([
					( "{sub.You} {sub.youAre} unable to freely swing {sub.yourHis} arms around, but {sub.youHe} still {sub.youHeVerb('try', 'tries')} to swipe at {dom.your} belly with {sub.yourHis} sharp claws. {dom.YouHe} {dom.youHeVerb('manage')} to gain enough distance in time to avoid the attack."+ ( " Scratch that." if( dom.isPlayer() && RNG.chance(10) ) else "" ) ),
				])

			eventLines.append_array([
				"{sub.You} {sub.youVerb('gather')} some energy to pull away in one swift motion, but {dom.you} {dom.youVerb('notice')} {sub.youHim} lean in anticipation, and immediately {dom.youVerb('pull')} {sub.youHim} back in.",
				( "{sub.You} {sub.youVerb('shuffle')} from one side to the other, but {dom.you} still {dom.youVerb('hold')} {sub.youHim} "+ ( "greedily" if( domIsMean || RNG.chance(20) ) else "dearly" ) +", like {dom.yourHis} most "+ RNG.pick(["cherished", "important", "prized"]) +" "+ RNG.pick(["catch", "possession"]) +"." ),
				( "{sub.You} "+ RNG.pick(["fiercely", "furiously"]) +" {sub.youVerb('step')} on {dom.your} "+ RNG.pick(["left", "right"]) +" foot. {dom.YouHe} {dom.youHeVerb('find')} it kind of cute." ),
				( "{sub.You} {sub.youVerb('nudge')} {sub.yourHis} whole body to the "+ RNG.pick(["left", "right"]) +", causing both of "+ both_youThem +" to turn slightly. "+ both_You_reThey_re +" now facing towards a different direction, but "+ ( "{sub.youreTheyre} " if( !sub.isPlayer() ) else "" ) +"being held just as firm." ),
			])
		else:
			# Pinned to the ground

			eventLines.append_array([
				"{sub.You} {sub.youVerb('try', 'tries')} to get {dom.you} off {sub.youHim}, but {dom.youHe} {dom.youHaveHeHas} {sub.youHim} pinned really tight and intimate.",
				"{sub.You} {sub.youVerb('try', 'tries')} to shake {dom.you} off, but {dom.youreTheyre} laying above {sub.youHim} with all of {dom.yourHis} weight, with no sign of wanting to let {sub.youHim} go..",
				"{sub.You} {sub.youVerb('attempt')} to free {sub.yourselfThemself} again. With {dom.you} laying heavily above, it appears to be quite difficult. Not to mention how possessively {dom.youHe} {dom.youHeVerb('cling')} onto {sub.youHim}..",
				"{sub.You} {sub.youVerb('shuffle')} on the ground, seemingly trying to crawl out of the snare, however {sub.yourHis} efforts yield no success. {dom.You} really {dom.youDont} want {sub.youHim} to leave just yet..",
			])

	subResistOrSoftenEventText = RNG.pick(eventLines)

	if(subResistOrSoftenEventText == attentionDivertEventLine):
		subResistedWithAttentionDivertAttemptTimes += 1

		if("Verb('bite')" in attentionDivertEventLine):
			sub.addPain( RNG.randi_range(8, 14) )
			domSpecialActionCooldown = int( max(1, domSpecialActionCooldown) )
			domHasUsedFlirtLineByAlias["i_dont_bite"] = true
			domHasUsedFlirtLineByAlias["i_dont_bite_<reacted>"] = true

func incl_sub_resist_do():
	var sub = getRoleChar("sub")

	incl_sub_resist_pick_random_event_line()

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


func incl_post_dom_flirt_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domIsMean:bool = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4
	var domIsSubby:bool = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) > 0.4
	var domInterestInAnalSexReceiving:float = domPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })
	var subIsMean:bool = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 }) > 0.4
	var subSpecies = sub.getSpecies()
	var subIsInmate:bool = subPawn.isInmate()
	var subHasBeenHighlyObedient = ( !subAttemptedPowerReversal && (subResistedTimes <= 1) && (subSoftenedTimes >= 6) )
	var sub_handsome = "charming" if ( sub.heShe() == "they" ) else ( "pretty" if ( sub.heShe() == "she" ) else "handsome" )
	var affectionValue:float = domPawn.getAffection(subPawn)
	var lustValue:float = domPawn.getLust(subPawn)
	var subLustRatio:float = getSubLustRatio()

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

		if( domIsSubby && (domInterestInAnalSexReceiving >= 0.5) ):
			possible.append_array([
				"I wish I were in your place.. We're about to get to my favorite part~",
				"I wouldn't resist if I were you. I don't mean that as a threat, it's just I'd *really* want to be buttfucked.",
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

	saynn( "[say=dom]"+ possibleRandomPick +"[/say]" )

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

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )


func incl_free_use_beg_text():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4
	var subPersonalityImpatientScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Impatient: 1.0 })
	var subIsImpatient:bool = subPersonalityImpatientScore > 0.4

	var domInterestInOralSexGiving:float = domPawn.scoreFetishMax({ Fetish.OralSexGiving: 1.0 })
	var domLikesOralSexGiving:bool = (domInterestInOralSexGiving >= 0.5)
	var domInterestInBeingBred:float = domPawn.scoreFetishMax({ Fetish.BeingBred: 1.0 })
	var domLikesBeingBred:bool = (domInterestInBeingBred >= 0.5)
	var domIsVisiblyPregnant:bool = dom.isVisiblyPregnant()

	var subInterestInPaws:float = subPawn.scoreFetishMax({ Fetish.FeetplayReceiving: 1.0 })
	var subLikesPaws:bool = subInterestInPaws >= 0.5
	var subInterestInAnalOrVaginalSexReceiving:float = subPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0, Fetish.VaginalSexReceiving: 1.0 })
	var subLikesAnalOrVaginalSexReceiving:bool = (subInterestInAnalOrVaginalSexReceiving >= 0.5)
	var subInterestInAnalOrVaginalSexGiving:float = subPawn.scoreFetishMax({ Fetish.AnalSexGiving: 1.0, Fetish.VaginalSexGiving: 1.0 })
	var subLikesAnalOrVaginalSexGiving:bool = (subInterestInAnalOrVaginalSexGiving >= 0.5)
	var subInterestInOralSexReceiving:float = subPawn.scoreFetishMax({ Fetish.OralSexReceiving: 1.0 })
	var subLikesOralSexReceiving:bool = (subInterestInOralSexReceiving >= 0.5)
	var subInterestInBreedingOthers:float = subPawn.scoreFetishMax({ Fetish.Breeding: 1.0 })
	var subLikesBreedingOthers:bool = (subInterestInBreedingOthers >= 0.5)
	var subInterestInBondage:float = subPawn.scoreFetishMax({ Fetish.Bondage: 1.0 })
	var subLikesBondage:bool = (subInterestInBondage >= 0.5)

	var reasonSubUnableToAnalSexGive = getReasonCharCannotPartakeInAnalSexGiving(sub, "sub")
	var subHasPenisTheyCanUse:bool = (reasonSubUnableToAnalSexGive == null)

	var dom_thoseAssets_thatAsset__array:Array = []
	if(subLikesPaws):
		dom_thoseAssets_thatAsset__array.append_array(["those paws"])
		if( dom.bodypartHasTrait(BodypartSlot.Legs, PartTrait.LegsDigi) ):
			dom_thoseAssets_thatAsset__array.append_array(["those hindpaws"])
	if(subLikesOralSexReceiving):
		dom_thoseAssets_thatAsset__array.append_array(["that mouth", "those lips"])
	if(subLikesAnalOrVaginalSexGiving):
		dom_thoseAssets_thatAsset__array.append_array(["those thighs"])

	var sub_playtoy__array:Array = ["playtoy", "whorething"]
	if(subLikesAnalOrVaginalSexReceiving):
		sub_playtoy__array.append_array(["cockslut"])

	var sub_I_changed_my_mind:String = (
			(
					RNG.pick(
							[
								"Forget what I said"+ ( " earlier" if( RNG.chance(50) ) else "" ) +".",
								"Nevermind what I said"+ ( " earlier" if( RNG.chance(50) ) else "" ) +".",
							]
						if(subIsMean)
						else [
							"..I changed my mind.",
							( "Uhm.. Nevermind what I said earlier. You're rather "+ RNG.pick(["charming", "tempting"]) +".." ),
							"Err.. I might've spoke too harsh. You know what..",
							"Uhmm.. I take back what I said..",
							"Gosh you're quite good at pushing my buttons..",
						]
					)
				+ " "
			)
		if(subSnarkUsedTimes >= 1)
		else ""
	)

	var possible:Array = [
		( sub_I_changed_my_mind +"Use me "+ RNG.pick(["however", "in any way"]) +" you "+ RNG.pick(["please", "want", "wish"]) +"~" ),
		( sub_I_changed_my_mind +RNG.pick(["You can", "You're free to"]) +" do "+ RNG.pick(["anything", "whatever"]) +" you want "+ RNG.pick(["to", "with"]) +" me~" ),
		"You know what.. I'm curious what you'd do if I let you have your way..",
		( sub_I_changed_my_mind +"I'm all yours~" ),
		( sub_I_changed_my_mind +"My body is all yours to play with~" ),
	]

	if(subLikesBreedingOthers && domLikesBeingBred && !domIsVisiblyPregnant):
		possible.append_array([
			( sub_I_changed_my_mind +"You should use me for your all of your naughty desires~. I bet you'd look even prettier with a pregnant belly,," ),
		])

	if(subIsImpatient):
		possible.append_array([
			( sub_I_changed_my_mind +"Let's fast-forward to you using me "+ RNG.pick(["in any way you desire", "in every possible way"]) +"~" ),
		])

	if(subIsMean):
		possible.append_array([
			( sub_I_changed_my_mind +"Now make me feel good, or get lost. Your choice." ),
			( "If you really think you've got something worth my attention, now would be the time."+ ( " Don't keep me waiting." if(subIsImpatient) else "" ) ),
			"Stop fucking toying with me.. Or don't, actually.",
			( sub_I_changed_my_mind +""+ RNG.pick(["Focus on nothing except pleasuring me", "Make it your only goal to pleasure me"]) +", and "+ RNG.pick(["I'll let you", "you can"]) +" do "+ RNG.pick(["anything", "whatever"]) +" you "+ RNG.pick(["crave", "want"]) +"." ),
		])

		if( subLikesOralSexReceiving && subHasPenisTheyCanUse && domLikesOralSexGiving && RNG.chance(10) ):
			possible.append_array([
				( sub_I_changed_my_mind + "Y'know, if you really want to slurp on my cock that bad, you can just ask~" ),
			])

		if(subIsImpatient):
			possible.append_array([
				"If you want to use me so much, just do so. Don't waste my fucking time.",
				( RNG.pick(["Stop", "Quit"]) +" being so "+ ("intimidating" if(domIsMean) else "gentle") + ", and just "+ RNG.pickWeightedPairs([ ["have some fun with me", 1.0], ["play with me", 1.0], [( ( "get "+ RNG.pick(dom_thoseAssets_thatAsset__array) +" of yours over here" ) if( ( dom_thoseAssets_thatAsset__array.size() >= 1 ) && RNG.chance(80) ) else "drag your ass over here" ), 5.0] ]) +" already." ),
			])

			if( sub_playtoy__array.size() >= 1 ):
				possible.append_array([
					( RNG.pick(["I'm running low on patience", "I don't have the patience for this", "You're using up all of my patience"]) +". You want this "+ RNG.pick(sub_playtoy__array) +" or not?" ),
				])
	else:
		possible.append_array([
			( sub_I_changed_my_mind +"I w- want you to go all out on me,," ),
			"I love the way you drool over me~. Care to bring these lips a little closer?",
			"I- I surrender.. Please be gentle..",
			"So.. theoretically.. if you could do anything you wanted to me, what would it be? Huffh.. Show me.",
		])

		if( dom_thoseAssets_thatAsset__array.size() >= 1 ):
			possible.append_array([
				( sub_I_changed_my_mind +"I'd love to see what "+ RNG.pick(dom_thoseAssets_thatAsset__array) +" of yours can do~" ),
			])

		if(subLikesBondage):
			possible.append_array([
				"Wanna show me your toy collection? Huffh..",
			])

		if(subIsImpatient):
			possible.append_array([
				"Hurry up and use me.. P- Please,,",
			])

	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )


func incl_dom_refuse_request_text(_info:Dictionary):
	var speechComprehensibility = _info.speechComprehensibility

	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4

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

	saynn( "[say=dom]"+ RNG.pick(possible) +"[/say]" )


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

	var painBaseValue:int = 12 if(domSpecialActionParamBodyPart == "neck") else 6
	var painInflictedFromBite = ceil(painBaseValue * domSpecialActionParamStrength)

	# Ensures nibbles never fully fill out the pain meter (unless it is already)
	var isBiteGentle:bool = (domSpecialActionParamStrength <= 0.3)
	var painMaxAllowed = max( sub.getPain(), sub.painThreshold() - 1 ) if(isBiteGentle) else sub.painThreshold()
	painInflictedFromBite = min( painInflictedFromBite, ( painMaxAllowed - sub.getPain() ) )

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

	saynn( RNG.pick(possible) )

	possible = []

	var domReactEvents = []

	var sub = getRoleChar("sub")
	var domPawn = getRolePawn("dom")
	var subPawn = getRolePawn("sub")

	var subIsInPain:bool = ( sub.getPain() >= sub.painThreshold() )
	var subLustRatio:float = getSubLustRatio()
	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var subPersonalityMeanScore:float = subPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var subIsMean:bool = subPersonalityMeanScore > 0.4
	var subIsKind:bool = subPersonalityMeanScore < -0.4
	var subInterestInBeingBitten:float = subPawn.scoreFetishMax({ Fetish.Masochism: 1.0 })
	var subLikesBeingBitten:bool = subInterestInBeingBitten >= 0.5
	var subDislikesBeingBitten:bool = subInterestInBeingBitten <= -0.5
	var subFakesIndifferenceToBites:bool = (subLustRatio < 0.50)

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
	
	saynn( "[say=sub]"+ RNG.pick(possible) +"[/say]" )

	if( domReactEvents.size() > 0 ):
		saynn( RNG.pick(domReactEvents) )


func incl_power_reversal_stamina_cost():
	var sub = getRoleChar("sub")

	if( sub.isPlayer() ):
		addMessage( "{sub.You} used "+ str(SUB_STAMINA_COST_POWER_REVERSAL_ATTEMPT) +" stamina." )


func getAnimData() -> Array:
	var sub = getRoleChar("sub")

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
		if(subKneeledAtInteractionStart):
			return [StageScene.Duo, "stand", { pc="dom", npc="sub", npcAction="kneel" }]

		return [StageScene.Duo, "stand", { pc="dom", npc="sub", npcAction="kneel", flipNPC=true }]

	if( getState() == "about_to_sex" ):
		return [StageScene.SexStart, "start", { pc="dom", npc="sub" }]

	if( getState() == "after_sex" ):
		return [StageScene.Duo, "stand", { pc="dom", npc="sub" }]

	var hasSuccessfullyPerformedPowerReversal:bool = ( getState() in ["strength_power_reversal__success__wall_bash__1", "strength_power_reversal__success__martial_arts__4correct1", "agility_power_reversal__success__suddenly_free__2", "agility_power_reversal__success__squishy_bone__5", "agility_power_reversal__success__holocard__2paws4", "agility_power_reversal__success__holocard__2breasts6"] )

	if(hasSuccessfullyPerformedPowerReversal):
		return [StageScene.SexFreeStanding, "tease", { pc="sub", npc="dom" }]

	if( getState() in ["agility_power_reversal__success__squishy_bone__2"] ):
		return [StageScene.SexOral, "tease", { pc="dom", npc="dom", bodyState={ hide=true } }]
	if( getState() in ["agility_power_reversal__success__squishy_bone__3"] ):
		return [StageScene.SexOral, "sex", { pc="dom", npc="dom", bodyState={ hide=true } }]
	if( getState() in ["agility_power_reversal__success__squishy_bone__4squishy1"] ):
		return [StageScene.SexOral, "fast", { pc="dom", npc="dom", bodyState={ hide=true } }]
	if( getState() in ["agility_power_reversal__success__squishy_bone__4squishy2"] ):
		return [StageScene.SexOral, "fast", { pc="dom", npc="dom", npcCum=true, bodyState={ hide=true } }]
	if( getState() in ["agility_power_reversal__success__squishy_bone__4subs1"] ):
		return [StageScene.SexOral, "sex", { pc="sub", npc="dom", bodyState={ exposedCrotch=true, hard=true } }]
	if( getState() in ["agility_power_reversal__success__squishy_bone__4subs2"] ):
		return [StageScene.SexOral, "sex", { pc="sub", npc="dom", pcCum=true, bodyState={ exposedCrotch=true, hard=true } }]
	if( getState() in ["agility_power_reversal__success__squishy_bone__4subs3"] ):
		return [StageScene.SexOral, "start", { pc="sub", npc="dom", pcCum=true, bodyState={ exposedCrotch=true, hard=true } }]

	if( getState() in ["agility_power_reversal__success__holocard__2paws2", "agility_power_reversal__success__holocard__2paws3"] ):
		return [StageScene.Duo, "kneel", { pc="dom", npc="sub", flipNPC=true }]
	if( getState() in ["agility_power_reversal__success__holocard__2breasts1"] ):
		return [StageScene.Duo, "stand", { pc="sub", npc="dom" }]
	if( getState() in ["agility_power_reversal__success__holocard__2breasts2lick1"] ):
		return [StageScene.BreastFeeding, "tease", { pc="sub", npc="dom" }]
	if( getState() in ["agility_power_reversal__success__holocard__2breasts3lick1"] ):
		return [StageScene.BreastFeeding, "tease", { pc="sub", npc="dom", bodyState={ exposedChest=true } }]
	if( getState() in ["agility_power_reversal__success__holocard__2breasts3lick2", "agility_power_reversal__success__holocard__2breasts4refuse1"] ):
		return [StageScene.BreastFeeding, "feed", { pc="sub", npc="dom", bodyState={ exposedChest=true } }]
	if( getState() in ["agility_power_reversal__success__holocard__2breasts4lick1"] ):
		return [StageScene.BreastFeeding, "feed", { pc="dom", npc="dom", bodyState={ hide=true } }]
	if( getState() in ["agility_power_reversal__success__holocard__2breasts5embrace1"] ):
		return [StageScene.SexOral, "start", { pc="sub", npc="dom" }]

	if( getState() in ["strength_power_reversal__failure__unpersuasive__2obey1"] ):
		return [StageScene.Duo, "stand", { pc="sub", npc="dom", npcAction="kneel" }]

	if( getState() in ["agility_power_reversal__success__suddenly_free__1"] ):
		return [StageScene.Duo, "stand", { pc="dom", npc="sub" }]

	if( sub.isPlayer() ):
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__2melt1", "agility_power_reversal__failure__dream_of_slime__3play1warp1", "agility_power_reversal__failure__dream_of_slime__3bottom1", "agility_power_reversal__failure__dream_of_slime__3top1"] ):
			return [StageScene.Solo, "stand", { pc="dom" }]
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__3play1cuddle1"] ):
			return [StageScene.GivingBirth, "idle", { pc="dom" }]
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__3play1fondling1"] ):
			return [StageScene.BreastGroping, "grope", { pc="dom", npc="dom", npcBodyState={ hide=true } }]
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__3play1gravity1"] ):
			return [StageScene.SexSpitroast, "grope", { pc="dom", npc="dom", npc2="dom", npcBodyState={ hide=true }, npc2BodyState={ hide=true } }]
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__3bottom2"] ):
			return [StageScene.Solo, "stand", { pc="dom", bodyState={ naked=true, hard=true } }]
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__3bottom3"] ):
			return [StageScene.SexFreeStanding, "fast", { pc="dom", npc="dom", bodyState={ naked=true, hard=true }, npcBodyState={ hide=true } }]
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__3bottom4"] ):
			return [StageScene.SexFreeStanding, "inside", { pc="dom", npc="dom", pcCum=true, bodyState={ naked=true, hard=true }, npcBodyState={ hide=true } }]
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__3top2oral1"] ):
			return [StageScene.SexOralForced, "suck", { pc="dom", npc="dom", bodyState={ hide=true } }]
		if( getState() in ["agility_power_reversal__failure__dream_of_slime__3top3", "agility_power_reversal__failure__dream_of_slime__3top4"] ):
			return [StageScene.SexFullNelson, "sex", { pc="dom", npc="dom", bodyState={ hide=true }, npcBodyState={ exposedCrotch=true } }]

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
		return "{dom.name} is teasing {sub.name}."
	if(_role == "sub"):
		return "{sub.name} is being teased by {dom.name}."

	return .getPreviewLineForRole(_role)

func isPawnBeingFucked(pawn) -> bool:
	return (
			( getRoleForPawn(pawn) == "dom" )
		&& ( getState() in ["agility_power_reversal__success__squishy_bone__4subs1", "agility_power_reversal__success__squishy_bone__4subs2"] )
	)

func isPawnFuckingSomeone(pawn) -> bool:
	return (
			( getRoleForPawn(pawn) == "sub" )
		&& ( getState() in ["agility_power_reversal__success__squishy_bone__4subs1", "agility_power_reversal__success__squishy_bone__4subs2"] )
	)

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

func shouldHideRelativeActionChances() -> bool:
	return true

func saveData():
	var data = .saveData()

	data["subResistedTimes"] = subResistedTimes
	data["subResistedWhileNotWaitingOrHesitatingTimes"] = subResistedWhileNotWaitingOrHesitatingTimes
	data["subResistedWithAttentionDivertAttemptTimes"] = subResistedWithAttentionDivertAttemptTimes
	data["subSoftenedTimes"] = subSoftenedTimes
	data["subSoftenedWhileWaitingTimes"] = subSoftenedWhileWaitingTimes
	data["subResistOrSoftenEventText"] = subResistOrSoftenEventText
	data["subRubbedAgainstDomTimes"] = subRubbedAgainstDomTimes
	data["subSnarkCooldown"] = subSnarkCooldown
	data["subSnarkUsedTimes"] = subSnarkUsedTimes
	data["subBrattinessRatio"] = subBrattinessRatio
	data["subMayBegToBeFreelyUsed"] = subMayBegToBeFreelyUsed
	data["subMayAttemptAttentionDivert"] = subMayAttemptAttentionDivert
	data["subMayAttemptPowerReversal"] = subMayAttemptPowerReversal
	data["subPowerReversalUnequippedRestraints"] = subPowerReversalUnequippedRestraints
	data["subPowerReversalObtainedRestraints"] = subPowerReversalObtainedRestraints
	data["subPowerReversalPersistentDict"] = subPowerReversalPersistentDict
	data["subAdditionalLustFromSpecials"] = subAdditionalLustFromSpecials
	data["subStaminaRecovered"] = subStaminaRecovered
	data["subConsentedToUndressing"] = subConsentedToUndressing
	data["subConsentedToAnalSexReceiving"] = subConsentedToAnalSexReceiving
	data["subConsentedToAnalSexGiving"] = subConsentedToAnalSexGiving
	data["subConsentedToFreeUse"] = subConsentedToFreeUse
	data["subIsTooFrightenedToEscape"] = subIsTooFrightenedToEscape
	data["subWasHypnotizedIntoKneeling"] = subWasHypnotizedIntoKneeling
	data["subWasHypnotizedIntoStandingStill"] = subWasHypnotizedIntoStandingStill
	data["subEscapeUponEaseGripProbability"] = subEscapeUponEaseGripProbability
	data["subKneeledAtInteractionStart"] = subKneeledAtInteractionStart
	data["subIntendsToKneel"] = subIntendsToKneel
	data["subIntendsToStandStill"] = subIntendsToStandStill
	data["subAttemptedPowerReversal"] = subAttemptedPowerReversal
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
	subResistedWithAttentionDivertAttemptTimes = SAVE.loadVar(_data, "subResistedWithAttentionDivertAttemptTimes", 0)
	subSoftenedTimes = SAVE.loadVar(_data, "subSoftenedTimes", 0)
	subSoftenedWhileWaitingTimes = SAVE.loadVar(_data, "subSoftenedWhileWaitingTimes", 0)
	subResistOrSoftenEventText = SAVE.loadVar(_data, "subResistOrSoftenEventText", "")
	subRubbedAgainstDomTimes = SAVE.loadVar(_data, "subRubbedAgainstDomTimes", 0)
	subSnarkCooldown = SAVE.loadVar(_data, "subSnarkCooldown", 0)
	subSnarkUsedTimes = SAVE.loadVar(_data, "subSnarkUsedTimes", 0)
	subBrattinessRatio = SAVE.loadVar(_data, "subBrattinessRatio", 0.5)
	subMayBegToBeFreelyUsed = SAVE.loadVar(_data, "subMayBegToBeFreelyUsed", false)
	subMayAttemptAttentionDivert = SAVE.loadVar(_data, "subMayAttemptAttentionDivert", false)
	subMayAttemptPowerReversal = SAVE.loadVar(_data, "subMayAttemptPowerReversal", false)
	subPowerReversalUnequippedRestraints = SAVE.loadVar(_data, "subPowerReversalUnequippedRestraints", [])
	subPowerReversalObtainedRestraints = SAVE.loadVar(_data, "subPowerReversalObtainedRestraints", [])
	subPowerReversalPersistentDict = SAVE.loadVar(_data, "subPowerReversalPersistentDict", {})
	subAdditionalLustFromSpecials = SAVE.loadVar(_data, "subAdditionalLustFromSpecials", 0.0)
	subStaminaRecovered = SAVE.loadVar(_data, "subStaminaRecovered", 0)
	subConsentedToUndressing = SAVE.loadVar(_data, "subConsentedToUndressing", false)
	subConsentedToAnalSexReceiving = SAVE.loadVar(_data, "subConsentedToAnalSexReceiving", false)
	subConsentedToAnalSexGiving = SAVE.loadVar(_data, "subConsentedToAnalSexGiving", false)
	subConsentedToFreeUse = SAVE.loadVar(_data, "subConsentedToFreeUse", false)
	subIsTooFrightenedToEscape = SAVE.loadVar(_data, "subIsTooFrightenedToEscape", false)
	subWasHypnotizedIntoKneeling = SAVE.loadVar(_data, "subWasHypnotizedIntoKneeling", false)
	subWasHypnotizedIntoStandingStill = SAVE.loadVar(_data, "subWasHypnotizedIntoStandingStill", false)
	subEscapeUponEaseGripProbability = SAVE.loadVar(_data, "subEscapeUponEaseGripProbability", 0.0)
	subKneeledAtInteractionStart = SAVE.loadVar(_data, "subKneeledAtInteractionStart", false)
	subIntendsToKneel = SAVE.loadVar(_data, "subIntendsToKneel", false)
	subIntendsToStandStill = SAVE.loadVar(_data, "subIntendsToStandStill", false)
	subAttemptedPowerReversal = SAVE.loadVar(_data, "subAttemptedPowerReversal", false)
	subWasPinnedToTheGround = SAVE.loadVar(_data, "subWasPinnedToTheGround", false)
	subWasUndressed = SAVE.loadVar(_data, "subWasUndressed", false)

	domHasUsedFlirtLineByAlias = SAVE.loadVar(_data, "domHasUsedFlirtLineByAlias", {})
	domFlirtCooldown = SAVE.loadVar(_data, "domFlirtCooldown", 0)
	domRefusedUndressingRequestTimes = SAVE.loadVar(_data, "domRefusedUndressingRequestTimes", 0)
	domRefusedPenetrationRequestTimes = SAVE.loadVar(_data, "domRefusedPenetrationRequestTimes", 0)
	domHasBittenSubTimes = SAVE.loadVar(_data, "domHasBittenSubTimes", 0)
	domRefusedAnalSexReceiving = SAVE.loadVar(_data, "domRefusedAnalSexReceiving", false)
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

func applyOrgasmSensationToLine(line:String) -> String:
	return (
			"[rainbow freq=0.05 sat=0.25 val=1.0]"
		+ line
		+ "[/rainbow]"
	)

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

func getIncompleteSpeciesFullName(species: Array) -> String:
	if( species.size() == 0 ):
		return "Wild"

	var specie = GlobalRegistry.getSpecies( RNG.pick(species) )

	if(specie == null):
		return "Wild"

	return specie.getVisibleName()

func getSpacerText() -> String:
	if( RNG.chance(90) ):
		return ""

	return RNG.pick([
		"Space space wanna go to space yes please space.",
		"Space space going to space can't wait.",
		"Oh oh this is space. We're in space.",
		"Don't like space, don't like space.",
	])

func clearMessagesForChar(character:BaseCharacter) -> void:
	# Clears messages added with addMessage that aren't cleared by choosing the default "Continue" action
	if( character.isPlayer() ):
		GM.main.clearMessages()

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

	var forcedObedienceRatio:float = clamp( sub.getForcedObedienceLevel(), 0.0, 1.0 )
	var subPersonalitySubbyRatio:float = ( subPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 }) + 1.0 ) / 2.0
	var subInterestInAnalSexReceiving:float = subPawn.scoreFetishMax({ Fetish.AnalSexReceiving: 1.0 })

	var lustRatioFromSubbinessRatio:float = subPersonalitySubbyRatio
	var lustRatioFromBrattinessRatio:float = 1.0 - (0.6 * subBrattinessRatio)
	var lustRatioFromInterestInAnalSexReceiving:float = clamp(subInterestInAnalSexReceiving + 1.0, 0.0, 1.0)

	var lustRatioCombined:float = lerp(
		(
				lustRatioFromSubbinessRatio
			* lustRatioFromBrattinessRatio
			* lustRatioFromInterestInAnalSexReceiving
		),
		1.0,
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

func getSubPowerReversalSuccessChance(stat:String) -> float:
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")

	var domStatValue:int = dom.getStat(stat)
	var subStatValue:int = sub.getStat(stat)
	var subStatAdvantage:int = subStatValue - domStatValue

	var successChance:float = 0.0

	if(subStatAdvantage < -10):
		successChance = 0.0
		return successChance

	successChance = lerp(
		30.0,
		70.0,
		min(
			0.02 * (subStatAdvantage + 10),
			1.0
		)
	)

	return successChance

func unequipSubRestraintsPreventingPowerReversal():
	var sub = getRoleChar("sub")
	var subInventory:Inventory = sub.getInventory()

	var restraintsBlockingArms:Array = subInventory.getEquippedItemsWithBuff(Buff.RestrainedArmsBuff)
	var restraintsBlockingHands:Array = subInventory.getEquippedItemsWithBuff(Buff.BlockedHandsBuff)

	for restraintsToUnequip in [restraintsBlockingArms, restraintsBlockingHands]:
		if( restraintsToUnequip.size() > 0 ):
			for restraint in restraintsToUnequip:
				var restraintItemSnippet:Dictionary = getSnippetFromRestraintItem(restraint)

				subPowerReversalUnequippedRestraints.append({
					a_name = restraintItemSnippet.a_name,
					A_name = restraintItemSnippet.A_name,
					nameIsPlaceholder = restraintItemSnippet.nameIsPlaceholder,
					nameIsPlural = restraintItemSnippet.nameIsPlural,
					level = (
							1000000
						if( restraint.restraintData.hasSmartLock() )
						else restraint.restraintData.getLevel()
					),
				})

				subInventory.unequipItem(restraint)

	subPowerReversalUnequippedRestraints.shuffle()

func getLockDescForMostSecureUnequippedRestraint():
	var lockDesc:String = "Level 1"
	var maxLevel:int = 1

	for restraint in subPowerReversalUnequippedRestraints:
		if(restraint.level == 1000000):
			lockDesc = "SMART-LOCKED"
			return lockDesc

		if(restraint.level > maxLevel):
			maxLevel = restraint.level

	lockDesc = ( "Level "+ str(maxLevel) )
	return lockDesc

func addSubRestraintUponFailingPowerReversal():
	var dom = getRoleChar("dom")
	var sub = getRoleChar("sub")
	var subInventory:Inventory = sub.getInventory()

	var knownRestraintIDs:Array = subInventory.getRestraintsThatCanBeForcedDuringSex(ItemTag.CanBeForcedByGuards)
	var possibleRestraintIDs:Array = []

	for knownRestraintID in knownRestraintIDs:
		var item:ItemBase = GlobalRegistry.getItemRef(knownRestraintID)

		var itemSlot = item.getClothingSlot()
		var bodypartSlot = item.getRequiredBodypart()

		if( itemSlot in [InventorySlot.Anal, InventorySlot.Vagina, InventorySlot.Torso] ):
			continue
		elif( bodypartSlot != null && sub.getFirstItemThatCoversBodypart(bodypartSlot) != null ):
			continue
		elif( !sub.invCanEquipSlot(itemSlot) ):
			continue
		elif( subInventory.hasSlotEquipped(itemSlot) && ( subInventory.getEquippedItem(itemSlot) != null ) && !subInventory.getEquippedItem(itemSlot).isRemoved() && !subInventory.getEquippedItem(itemSlot).isDamaged() ):
			continue
		else:
			var restraintData:RestraintData = item.getRestraintData()
			if(restraintData == null):
				continue

			possibleRestraintIDs.append(item.id)

	if( possibleRestraintIDs.size() == 0 ):
		return

	var randomRestraintID:String = RNG.pick(possibleRestraintIDs)
	var randomRestraintItem:ItemBase = GlobalRegistry.createItem(randomRestraintID)

	subInventory.forceEquipByStoreOtherUnlessRestraint(randomRestraintItem, dom)

	var restraintItemSnippet:Dictionary = getSnippetFromRestraintItem(randomRestraintItem)

	subPowerReversalObtainedRestraints.append({
		a_name = restraintItemSnippet.a_name,
		A_name = restraintItemSnippet.A_name,
		nameIsPlaceholder = restraintItemSnippet.nameIsPlaceholder,
		nameIsPlural = restraintItemSnippet.nameIsPlural,
	})

func getSnippetFromRestraintItem(restraintItem:ItemBase) -> Dictionary:
	var snippet:Dictionary = {
		a_name = "a restraint",
		nameIsPlaceholder = true,
		nameIsPlural = false,
	}

	var visibleNameLowercase:String = restraintItem.getVisibleName().to_lower()
	var clothingSlot = restraintItem.getClothingSlot()

	if(clothingSlot == InventorySlot.Eyes):
		snippet = {
			a_name = "an eyes restraint",
			nameIsPlaceholder = false,
			nameIsPlural = false,
		}

		if("hypnovisor" in visibleNameLowercase):
			snippet.a_name = "a hypnovisor"
		elif("blindfold" in visibleNameLowercase):
			snippet.a_name = "a blindfold"
		else:
			snippet.nameIsPlaceholder = true
	elif(clothingSlot == InventorySlot.Mouth):
		snippet = {
			a_name = "a maw restraint",
			nameIsPlaceholder = false,
			nameIsPlural = false,
		}

		if("ball gag" in visibleNameLowercase):
			snippet.a_name = "a ball gag"
		elif("canine dildo gag" in visibleNameLowercase):
			snippet.a_name = "a canine dildo gag"
		elif("dildo gag" in visibleNameLowercase):
			snippet.a_name = "a dildo gag"
		elif("ring gag" in visibleNameLowercase):
			snippet.a_name = "a ring gag"
		elif("basket muzzle" in visibleNameLowercase):
			snippet.a_name = "a basket muzzle"
		else:
			snippet.nameIsPlaceholder = true
	elif(clothingSlot == InventorySlot.Wrists):
		snippet = {
			a_name = "wrist restraints",
			nameIsPlaceholder = false,
			nameIsPlural = true,
		}

		if("wrist cuffs" in visibleNameLowercase):
			snippet.a_name = "wrist cuffs"
		elif("zip ties" in visibleNameLowercase):
			snippet.a_name = "wrist zip ties"
		else:
			snippet.nameIsPlaceholder = true
	elif(clothingSlot == InventorySlot.Hands):
		snippet = {
			a_name = "paw restraints",
			nameIsPlaceholder = false,
			nameIsPlural = true,
		}

		if("bondage mittens" in visibleNameLowercase):
			snippet.a_name = "bondage mittens"
		else:
			snippet.nameIsPlaceholder = true
	elif(clothingSlot == InventorySlot.Ankles):
		snippet = {
			a_name = "ankle restraints",
			nameIsPlaceholder = false,
			nameIsPlural = true,
		}

		if("ankle cuffs" in visibleNameLowercase):
			snippet.a_name = "ankle cuffs"
		elif("zip ties" in visibleNameLowercase):
			snippet.a_name = "ankle zip ties"
		else:
			snippet.nameIsPlaceholder = true

	snippet.A_name = Util.capitalizeFirstLetter(snippet.a_name)

	return snippet

func getValidFragmentsForAssociativeSequenceForChar(character:BaseCharacter) -> Array:
	var validFragments:Array = [
		"Abandoned", "Absolute", RNG.pick(["Abyss", "Abyssal"]), "Access", "Addiction", "Afterburner", "Airdrop", "Airlock", "Algorithm", "Alluring", "Alone", "Aloof", "Altitude", "Angular", RNG.pick(["Anomalous", "Anomaly"]), "Antiseptic", "Antiquated", "Arboretum", "Arcane", RNG.pick(["Arguing", "Argument"]), RNG.pick(["Arouse", "Arousing"]), "Artifact", RNG.pick(["Assemble", "Assembler", "Assembly"]), "Asteroid", "Attention", "Attic", "Audible", "Augmentation", "Auxillary", "Available", "Avionics", "Avoiding", "Axiom",
		#
		"Beacon", "Beast", "Behind", "Belly", "Bending", "Beneath", "Binturong", "Biodiversity", "Biosignature", "Bittersweet", "Blahaj", "Blink", "Blueprint", "Bluespace", "Blurry", RNG.pick(["Book", "Bookshelf"]), "Bootloader", "Border", "Bottomless", "Bouncing", "Bound", "Bounty", "Brakes", "Breach", "Breath", "Breeze", "Bright", "Buzzer", "Bypass",
		#
		"Calling", "Campfire", "Canvas", "Capacitor", "Cargo", "Casual", "Ceiling", "Celestial", "Chamber", "Champagne", RNG.pick(["Chaos", "Chaotic"]), "Charging", "Charming", "Chase", "Chimera", "Choice", "Chubby", "Chute", "Circular", "Claws", "Clearance", RNG.pick(["Climb", "Climbing"]), "Closure", "Clueless", "Cluster", "Clutter", "Coalescence", "Collar", RNG.pick(["Collect", "Collectibles", "Collective"]), "Combustion", "Cometary", "Command", RNG.pick(["Compromise", "Compromised"]), "Concrete", "Conduit", "Confidential", "Console", "Construct", "Contact", RNG.pick(["Container", "Containment"]), "Corruption", "Counter", "Crash", "Craving", "Crescent", "Crewmate", "Crumbs", "Curtain", "Cushion", "Cybernetics",
		#
		"Darkness", "Date", "Dawn", "Debris", "Declassified", "Density", "Derelict", "Descent", "Determine", "Deviant", "Diplomacy", "Disco", "Discrete", "Disengage", "Diskette", "Dissociate", "Distortion", "Divergence", "Division", "Downpour", "Downstairs", "Drawbridge", "Drawing", "Dreadnought", RNG.pick(["Dream", "Dreaming"]), RNG.pick(["Drifter", "Drifting"]), "Dripping", RNG.pick(["Drive", "Driving"]), "Dusk",
		#
		"Eclipse", "Eerie", RNG.pick(["Eject", "Ejection"]), "Elevator", "Elysium", "Enclosure", "Encryption", "Engine", "Enormous", "Entity", "Equipment", "Escalation", "Euclid", "Euphoria", RNG.pick(["Eventual", "Eventually"]), "Excavation", RNG.pick(["Except", "Exception"]), "Exchange", "Exhale", "Exoplanet", RNG.pick(["Expect", "Expectations"]), "Expedition", "Experience", "Experiment", "Exposure",
		#
		"Fabricate", "Failure", "Faint", RNG.pick(["Fall", "Fallible", "Falling"]), "Favor", "Featureless", "Federation", "Feelings", "Feral", "Fiction", "Field", "Figure", "Fireplace", "Firmware", "Fishnets", RNG.pick(["Flee", "Fleeing", "Fleet"]), "Flexible", "Flicker", RNG.pick(["Flow", "Flowing"]), "Fluctuation", "Footsteps", "Forsaken", "Foundation", "Fountain", "Fracture", "Fragile", "Freight", "Friction", "Frontier", "Frustration", RNG.pick(["Fuse", "Fusion"]),
		#
		"Gateway", "Gesture", "Gilgamesh", "Glacier", RNG.pick(["Glass", "Glasses"]), "Glimpse", "Glitch", "Goggles", "Gravity", "Greed", "Greenhouse", "Guilt", "Gunfire",
		#
		"Halcyon", RNG.pick(["Hard", "Hardware"]), "Harness", "Haste", "Hatch", "Hauler", "Heatsink", "Helmet", "Hibernation", "Hiss", "Hoard", "Holographic", "Horizon", "Horny", "Hotline", "Hull", "Humming", "Hungry", RNG.pick(["Howl", "Howling"]), "Hybrid", "Hydroponics",
		#
		"Illusion", "Imagining", "Immense", "Immodest", "Impact", "Imprint", "Incense", "Incident", "Indecent", "Inertial", "Inferno", "Inflatable", "Inhale", "Injury", "Inside", "Insignia", "Install", "Instinct", "Interceptor", "Interface", "Integrity", "Intertwine", RNG.pick(["Intimacy", "Intimate"]), "Intrusive", "Isolation", "Isotope",
		#
		"Jammed", "Jealous", "Journal", "Judicial", "Jump",
		#
		"Keepsake", "Kennel", "Keycard", "Keygen", "Kinetic", "Kinky", "Kinship", RNG.pick(["Kiss", "Kissing"]),
		#
		"Labyrinth", "Landing", "Layers", RNG.pick(["Leak", "Leaking"]), "Library", "Licking", "Lilac", "Liminal", "Lissajous", "Lockers", "Logistics", "Loop", RNG.pick(["Lustful", "Lusting"]), "Luxury",
		#
		"Machinery", "Maid", "Maintain", "Malfunction", "Malware", "Maneuver", "Manifest", "Manifold", RNG.pick(["Mask", "Masking"]), "Massive", "Matrix", "Meadow", "Mechanical", "Meltdown", "Mending", RNG.pick(["Mess", "Messy"]), "Methalox", RNG.pick(["Mirror", "Mirroring"]), "Missile", "Mission", "Monitoring", "Monorail", "Morning", "Moss", "Muffled", "Mushroom",
		#
		"Nanotrasen", "Narrow", "Nascent", "Neon", "Nervous", "Network", "Neurolysis", RNG.pick(["Night", "Nightfall"]), "Noisy", "Nominal", "Nonchalant", RNG.pick(["Nude", "Nudes"]),
		#
		"Objective", "Observer", "Offer", "Ominous", "Ordnance", "Oscillating", RNG.pick(["Outer", "Outside", "Outskirts"]), "Outline", "Overcast", "Overlay", "Owner", "Oxygen",
		#
		"Package", "Panopticon", "Panoramic", RNG.pick(["Paint", "Painting"]), "Pawprint", "Perimeter", "Phantom", "Pizza", "Platform", "Playtime", "Pleasure", "Pledge", "Plushie", RNG.pick(["Point", "Pointing", "Pointless"]), "Possessive", "Pounce", RNG.pick(["Present", "Presenting"]), "Pressure", "Primal", "Privacy", "Prospecting", "Proximity", "Psychotronics", "Pull", "Purpose",
		#
		"Quarantine", "Quarters", "Quantum", "Quasar", "Quicksand", "Quivering",
		#
		RNG.pick(["Rain", "Rainbow", "Rainfall"]), "Reaction", "Reactor", "Rebellion", "Receiver", "Reconnaissance", "Recovery", "Refinery", RNG.pick(["Reflect", "Reflection"]), "Regeneration", "Relay", "Relic", "Relief", "Rendezvouz", RNG.pick(["Responsibility", "Responsible"]), RNG.pick(["Retrospect", "Retrospective"]), "Ricochet", "Riot", "Ritual", "Robotics", RNG.pick(["Route", "Routing"]), "Rubber", "Rust",
		#
		"Saliva", RNG.pick(["Scale", "Scales"]), "Scanning", "Scar", "Scent", RNG.pick(["Scratch", "Scritches"]), "Sealed", "Sector", RNG.pick(["Secure", "Security"]), "Seeking", "Sentimental", "Sewers", "Shackles", "Shard", "Sheath", "Shell", "Shelter", "Shipment", "Shiver", "Shrug", "Shutter", "Shuttle", "Sibling", "Signal", "Simulation", "Skirmish", "Skylight", "Sliding", "Slippery", "Slumber", "Smoke", RNG.pick(["Snap", "Snapping"]), "Snowfall", "Soaking", "Solaris", "Source", "Spacecraft", "Spark", "Species", "Squadron", RNG.pick(["Squeeze", "Squeezable"]), "Squirming", RNG.pick(["Star", "Stardust", "Stare", "Stargazing"]), "Station", "Steam", "Stellar", "Step", RNG.pick(["Strange", "Stranger"]), "Stray", "Subject", "Subroutine", "Substrate", "Subterranean", "Suite", RNG.pick(["Supply", "Supplier"]), "Surface", "Surveillance", "Suspect", "Sustain", "Synapse", "Syndicate", RNG.pick(["Synthesize", "Synthetic"]), RNG.pick(["System", "Systems"]),
		#
		"Tabletop", "Talking", "Tangled", RNG.pick(["Tease", "Teasing"]), "Temptation", "Terraform", "Terrestrial", "Territorial", "Thermal", "Thick", "Thighs", "Thirsty", "Threshold", "Throbbing", "Through", RNG.pick(["Thrust", "Thrusters"]), "Together", "Toolkit", "Touch", RNG.pick(["Train", "Training"]), "Transaction", RNG.pick(["Transmission", "Transmitter"]), "Treatment", RNG.pick(["Tremble", "Trembling"]), "Trouble",
		#
		"Unauthorized", "Underwear", "Unethical", "Unicellular", RNG.pick(["Union", "United"]), "Unsettling",
		#
		"Vector", "Vents", "Virtual", "Voidsteel", "Volunteer", "Vortex",
		#
		"Wander", "Wavelength", "Whimper", RNG.pick(["Whirling", "Whirring"]), "Whiskers", "Whisper", "Wildcard", "Wireframe", "Wishful", "Worship",
		#
		"Yard",
		#
		"Zenith",
	]

	var characterPersonality:Personality = character.getPersonality()
	var characterPersonalitySubbyScore:float = characterPersonality.personalityScoreMax({ PersonalityStat.Subby: 1.0 })
	var characterIsSubby:bool = characterPersonalitySubbyScore > 0.4
	var characterPersonalityMeanScore:float = characterPersonality.personalityScoreMax({ PersonalityStat.Mean: 1.0 })
	var characterIsMean:bool = characterPersonalityMeanScore > 0.4
	var characterPersonalityBratScore:float = characterPersonality.personalityScoreMax({ PersonalityStat.Brat: 1.0 })
	var characterIsBratty:bool = characterPersonalityBratScore > 0.4
	var characterPersonalityNaiveScore:float = characterPersonality.personalityScoreMax({ PersonalityStat.Naive: 1.0 })
	var characterIsNaive:bool = characterPersonalityNaiveScore > 0.4
	var characterPersonalityCowardScore:float = characterPersonality.personalityScoreMax({ PersonalityStat.Coward: 1.0 })
	var characterIsCowardly:bool = characterPersonalityCowardScore > 0.4

	var characterFetishHolder:FetishHolder = GM.pc.getFetishHolder()
	var characterInterestInBeingHypnotized:float = characterFetishHolder.scoreFetishMax({ Fetish.HypnosisSubject: 1.0 })
	var characterLikesBeingHypnotized:bool = characterInterestInBeingHypnotized >= 0.5
	var characterInterestInLactation:float = characterFetishHolder.scoreFetishMax({ Fetish.Lactation: 1.0 })
	var characterLikesLactation:bool = characterInterestInLactation >= 0.5
	var characterInterestInPenetrativeSex:float = characterFetishHolder.scoreFetishMax({ Fetish.AnalSexGiving: 1.0, Fetish.AnalSexReceiving: 1.0, Fetish.VaginalSexGiving: 1.0, Fetish.VaginalSexReceiving: 1.0 })
	var characterLikesPenetrativeSex:bool = characterInterestInPenetrativeSex >= 0.5
	var characterInterestInImpregnation:float = characterFetishHolder.scoreFetishMax({ Fetish.Breeding: 1.0, Fetish.BeingBred: 1.0 })
	var characterLikesImpregnation:bool = characterInterestInImpregnation >= 0.5
	var characterInterestInPaws:float = characterFetishHolder.scoreFetishMax({ Fetish.FeetplayReceiving: 1.0 })
	var characterLikesPaws:bool = characterInterestInPaws >= 0.5
	var characterInterestInTransformation:float = characterFetishHolder.scoreFetishMax({ Fetish.TFReceiving: 1.0, Fetish.TFGiving: 1.0 })
	var characterLikesTransformation:bool = characterInterestInTransformation >= 0.5


	if( character.isStaff() ):
		validFragments.append_array(["Promotion", "Vacation"])

	if( character.isGuard() ):
		validFragments.append_array(["Checkpoint", "Confiscate", "Exemplary", "Inspection", "Oppress", RNG.pick(["Order", "Orders"]), "Paperwork", "Patrol", "Respect", "Seize", "Standby"])
	else:
		validFragments.append_array(["Perspective"])


	if(characterIsSubby):
		validFragments.append_array(["Fuckthing", "Playtoy", "Swallow"])

		if(!characterIsMean):
			validFragments.append_array(["Helpless", "Nonverbal", "Quiet", "Treat"])

	if(characterIsMean):
		validFragments.append_array(["Arrogant", "Despicable", "Douche", "Erratic", "Expendable", "Malicious", "Monster", "Prowl", "Savage", "Zero"])
	else:
		validFragments.append_array(["Aftercare", "Angel", RNG.pick(["Blush", "Blushing"]), "Cherish", RNG.pick(["Comfort", "Comforting"]), RNG.pick(["Cuddle", "Cuddling"]), RNG.pick(["Embrace", "Embracing"]), "Emotional", "Fluffy", "Gentle", "Heartache", RNG.pick(["Hold", "Holding"]), "Home", RNG.pick(["Hope", "Hopeful"]), "Pawholding", "Promise", RNG.pick(["Protect", "Protective"]), "Rescue", "Treasure", RNG.pick(["Warm", "Warmth"]), RNG.pick(["Yearn", "Yearning"])])

	if(characterIsBratty):
		validFragments.append_array(["Defiance", "Mischief", "Rascal"])

	if(characterIsNaive):
		validFragments.append_array(["Destiny", "Faith", "Inevitable"])
	else:
		validFragments.append_array(["Bribes", "Pattern", "Superstition"])

	if(characterIsCowardly):
		validFragments.append_array(["Coward"])


	if(characterLikesBeingHypnotized):
		validFragments.append_array(["Comply", "Fetch", "Laundry", "Lunch", "Obedient", "Puppet", RNG.pick(["Serve", "Servitude"]), "Succumb", "Towel", "Trinket", "Useful"])
	if(characterLikesLactation):
		validFragments.append_array(["Breasts", "Fondling", "Groping", "Milkers"])
	if(characterLikesPenetrativeSex):
		validFragments.append_array(["Fuckable", RNG.pick(["Knot", "Knotting"]), "Missionary", RNG.pick(["Sex", "Sexy"])])
	if(characterLikesImpregnation):
		validFragments.append_array([RNG.pick(["Breed", "Breeding"]), "Fertile", "Impregnate"])
	if(characterLikesPaws):
		validFragments.append_array(["Hindpaws", "Pawpads", "Pawslut"])
	if(characterLikesTransformation):
		validFragments.append_array([RNG.pick(["Reshape", "Reshaping"]), "Shifting", RNG.pick(["Transform", "Transforming"])])
	if( character.isPlayer() && OPTIONS.isContentEnabled(ContentType.Watersports) ):
		validFragments.append_array(["Piss", "Urine"])


	if( character.isPlayer() ):
		if( GM.main.getFlag("AlexRynardModule.ch1IntroSceneHappened", false) ):
			validFragments.append_array(["Broken", "Datapad", "Entrust", "Fangs", "Mindless", "Prototype", "Vulpine", "Workshop"])
		if( GM.main.getFlag("AlexRynardModule.ch2FinalSceneHappened", false) ):
			validFragments.append_array(["Alex"])

		if( GM.main.getFlag("ArticaModule.corruptionBegan", false) ):
			validFragments.append_array(["Jogauni", "Tribe"])
		if( ( GlobalRegistry.getModule("ArticaModule") != null ) && GlobalRegistry.getModule("ArticaModule").isVerySlut() ):
			validFragments.append_array(["Artica"])

		if( GM.main.getFlag("ElizaModule.s3hap", false) ):
			validFragments.append_array(["Laboratory", "Rift"])
		if( GM.main.getFlag("ElizaModule.storyCompleted", false) || ( GM.main.getFlag("ElizaModule.dateOutcome", "") == "perfect" ) ):
			validFragments.append_array(["Eliza"])

		if( ( GM.main.getFlag("JackiModule.jackiCorruption", 0.0) >= 0.2 ) || ( GM.main.getFlag("JackiModule.jackiLust", 0.0) >= 0.2 ) ):
			validFragments.append_array(["Exercise", "Wolfie"])
		if( ( GM.main.getFlag("JackiModule.jackiCorruption", 0.0) >= 0.8 ) || ( GM.main.getFlag("JackiModule.jackiLust", 0.0) >= 0.8 ) ):
			validFragments.append_array(["Jacki"])

		if( GM.main.getFlag("DrugDenModule.Kidlat1Hap", false) ):
			validFragments.append_array(["Cardboard", "Corridor", "Junkie"])
		if( GM.main.getFlag("DrugDenModule.Kidlat8Hap", false) ):
			validFragments.append_array(["Kidlat"])

		if( GM.main.getFlag("RahiModule.rahi2SceneHappened", false) ):
			validFragments.append_array(["Kitty", "Waterfall"])
		if( GM.main.getFlag("RahiModule.rahiSlaveryStage", 0) >= 7 ):
			validFragments.append_array(["Rahi"])

		if( GM.main.getFlag("SocketModule.h2completed", false) ):
			validFragments.append_array(["Implant", "Maintenance"])
		if( GM.main.getFlag("SocketModule.h5completed", false) ):
			validFragments.append_array(["Socket"])

		if( GM.main.getFlag("TaviModule.Tavi_IntroducedTo", false) ):
			validFragments.append_array(["Loyalty"])
		if( ( GlobalRegistry.getModule("TaviModule") != null ) && ( GlobalRegistry.getModule("TaviModule").getOverallCorruptStage() >= 2 ) ):
			validFragments.append_array(["Tavi"])

		var dynamicInmateIDs:Array = GM.main.getDynamicCharacterIDsFromPool(CharacterPool.Inmates)

		for dynamicInmateID in dynamicInmateIDs:
			var someInmateChar:BaseCharacter = GlobalRegistry.getCharacter(dynamicInmateID)

			if(someInmateChar == null):
				continue

			var someInmateCharName:String = someInmateChar.getName()

			if(" " in someInmateCharName):
				continue

			var affectionValue:float = GM.main.RS.getAffection("pc", dynamicInmateID)
			var lustValue:float = GM.main.RS.getLust("pc", dynamicInmateID)

			if( (affectionValue > -0.7) && (lustValue < 0.7) ):
				continue

			validFragments.append(someInmateCharName)

	return validFragments

func getNonsenseFragmentsForAssociativeSequence() -> Array:
	var nonsenseFragments:Array = ["Afterthot", "Ahtimeter", "Artichoking", "Asciilating", "Bathwasser", "Binturight", "Bonetrouser", "Clayless", "Cockwaffle", "Deearem", "Disappointance", "Domroutine", "Elephantom", "Errandee", "Fangerine", "Fatherboard", "Faxolotl", "Fineapple", "Fingertits", "Flabingo", "Flamecatcher", "Gabecube", "Honsepower", "Libertea", "Minceraft", "Minestripper", "Nomnominal", "Nutflix", "Phoneydew", "Pomegrenade", "Renuissance", "Rhinoculars", "Rollertoaster", "Schlongest", "Slavemaxxing", "Slopsurf", "Stereorail", "Twinktank", "Twobunal", "Wifeguard", "Xnopyt", "Yestification"]
	return nonsenseFragments

func getMutatedSequence(correctSequence:Array, mutationInstructions:Array) -> Array:
	var mutatedSequence:Array = correctSequence.duplicate()

	for instruction in mutationInstructions:
		if(instruction.action == "overwrite"):
			mutatedSequence[instruction.idx] = instruction.value
		elif(instruction.action == "swap"):
			var firstIdx:int = instruction.indexes[0]
			var secondIdx:int = instruction.indexes[1]

			var temp:String = mutatedSequence[firstIdx]
			mutatedSequence[firstIdx] = mutatedSequence[secondIdx]
			mutatedSequence[secondIdx] = temp

	return mutatedSequence

func generateAssociativeSequenceParamsForChar(character:BaseCharacter) -> Dictionary:
	var sequenceParams:Dictionary = {}

	var validFragments:Array = getValidFragmentsForAssociativeSequenceForChar(character)
	sequenceParams.sequence = []
	while( sequenceParams.sequence.size() < 4 ):
		var validFragment = RNG.grab(validFragments)
		if(validFragment == null):
			sequenceParams.sequence = ["Something", "Went", "Horribly", "Wrong"]
			break
		if(validFragment in sequenceParams.sequence):
			continue
		sequenceParams.sequence.append(validFragment)

	var misleadingFragments:Array = []
	while( misleadingFragments.size() < 7 ):
		var validFragment = RNG.grab(validFragments)
		if(validFragment == null):
			validFragment = "Missing"
		else:
			if(validFragment in sequenceParams.sequence):
				continue
			if(validFragment in misleadingFragments):
				continue
		misleadingFragments.append(validFragment)

	sequenceParams.misleadingFragments = misleadingFragments
	sequenceParams.initialHintIdx = RNG.randi_range(0, 3)

	var swappableIndexes:Array = [0, 1, 2, 3]
	swappableIndexes.erase(sequenceParams.initialHintIdx)
	var indexesWithoutInitialHintIdx:Array = swappableIndexes.duplicate()

	var firstIdx:int = RNG.grab(swappableIndexes)
	var secondIdx:int = RNG.grab(swappableIndexes)
	var thirdIdx:int = swappableIndexes[0]
	var hasCoinFlipSucceeded:bool = RNG.chance(50)

	# Initial hint in correct place, word in thirdIdx (before swap) is correct but intentionally misplaced
	var mutationInstructionsA:Array = [{
		action = "overwrite",
		idx = firstIdx,
		value = misleadingFragments[0],
	}, {
		action = "overwrite",
		idx = secondIdx,
		value = misleadingFragments[1],
	}, {
		action = "swap",
		indexes = [
			( firstIdx if(hasCoinFlipSucceeded) else secondIdx ),
			thirdIdx,
		]
	}]

	# Initial hint in correct place, word in thirdIdx (before swap) is correct but intentionally misplaced
	var mutationInstructionsB:Array = [{
		action = "overwrite",
		idx = ( firstIdx if(hasCoinFlipSucceeded) else secondIdx ),
		value = misleadingFragments[2],
	}, {
		action = "overwrite",
		idx = thirdIdx,
		value = misleadingFragments[3],
	}, {
		action = "swap",
		indexes = [
			( secondIdx if(hasCoinFlipSucceeded) else firstIdx ),
			thirdIdx,
		]
	}]

	var mutationInstruction_misplaceInitialHint:Dictionary = {
		action = "swap",
		indexes = [
			sequenceParams.initialHintIdx,
			RNG.pick(indexesWithoutInitialHintIdx),
		]
	}

	sequenceParams.actions1 = []

	sequenceParams.actions1.append_array([
		{
			sequence = getMutatedSequence(
				sequenceParams.sequence,
				mutationInstructionsA
			),
			result = "correct",
		}, {
			sequence = getMutatedSequence(
				sequenceParams.sequence,
				mutationInstructionsB
			),
			result = "correct",
		}
	])

	# Reverse coin flip
	mutationInstructionsA[2].indexes[0] = ( firstIdx if(!hasCoinFlipSucceeded) else secondIdx )
	mutationInstructionsB[0].idx = ( firstIdx if(!hasCoinFlipSucceeded) else secondIdx )
	mutationInstructionsB[2].indexes[0] = ( secondIdx if(!hasCoinFlipSucceeded) else firstIdx )

	# Use different misleading words
	mutationInstructionsA[0].value = misleadingFragments[4]
	mutationInstructionsA[1].value = misleadingFragments[5]
	mutationInstructionsB[2].value = misleadingFragments[6]

	sequenceParams.actions1.append_array([
		{
			sequence = getMutatedSequence(
				sequenceParams.sequence,
				[
					mutationInstructionsA[0],
					mutationInstructionsA[1],
					mutationInstructionsA[2],
					mutationInstruction_misplaceInitialHint,
				]
			),
			result = "inattentive",
		}, {
			sequence = getMutatedSequence(
				sequenceParams.sequence,
				[
					mutationInstructionsB[0],
					{
						action = "overwrite",
						idx = thirdIdx,
						value = RNG.pick( getNonsenseFragmentsForAssociativeSequence() ),
					},
					mutationInstructionsB[2],
				]
			),
			result = "nonsense",
		}
	])

	sequenceParams.actions1.shuffle()

	return sequenceParams

func generateAssociativeSequenceParamsForActionStageIdx(actionStageIdx:int) -> void:
	var sequenceParams:Dictionary = subPowerReversalPersistentDict

	var misplacedFragmentIdx_withinSolutionSequence:int = -1
	var misplacedFragmentIdx_withinChosenSequence:int = -1
	var misleadingFragmentValues:Array = []
	for fragmentIdx in 4:
		if( subPowerReversalPersistentDict.chosenSequence[fragmentIdx] == subPowerReversalPersistentDict.sequence[fragmentIdx] ):
			# correct
			continue
		elif( subPowerReversalPersistentDict.chosenSequence[fragmentIdx] in subPowerReversalPersistentDict.sequence ):
			# misplaced (part of solution but incorrect position)
			var misplacedFragmentValue:String = subPowerReversalPersistentDict.chosenSequence[fragmentIdx]
			misplacedFragmentIdx_withinSolutionSequence = subPowerReversalPersistentDict.sequence.find(misplacedFragmentValue)
			misplacedFragmentIdx_withinChosenSequence = fragmentIdx
			subPowerReversalPersistentDict.chosenSequenceMisplacedFragmentIdx = fragmentIdx
		else:
			# misleading (not part of solution)
			misleadingFragmentValues.append( subPowerReversalPersistentDict.chosenSequence[fragmentIdx] )

	var hasCoinFlipSucceeded:bool = RNG.chance(50)

	var swappableIndexes:Array = [0, 1, 2, 3]
	swappableIndexes.erase(sequenceParams.initialHintIdx)

	if(actionStageIdx == 2):
		swappableIndexes.erase(misplacedFragmentIdx_withinChosenSequence)
		swappableIndexes.erase(misplacedFragmentIdx_withinSolutionSequence)

		var remainingIdx:int = swappableIndexes[0]

		var mutationInstruction_misplaceInitialHint:Dictionary = {
			action = "swap",
			indexes = [
				sequenceParams.initialHintIdx,
				RNG.pick([ remainingIdx, misplacedFragmentIdx_withinChosenSequence ]),
			]
		}

		sequenceParams.actions2 = [
			{
				sequence = getMutatedSequence(
					sequenceParams.sequence,
					[
						{
							action = "swap",
							indexes = [
								remainingIdx,
								( misplacedFragmentIdx_withinChosenSequence if(hasCoinFlipSucceeded) else misplacedFragmentIdx_withinSolutionSequence ),
							]
						},
					]
				),
				result = "correct",
			}, {
				sequence = getMutatedSequence(
					sequenceParams.sequence,
					[
						{
							action = "overwrite",
							idx = remainingIdx,
							value = RNG.grab(misleadingFragmentValues)
						},
						{
							action = "swap",
							indexes = [
								remainingIdx,
								( misplacedFragmentIdx_withinChosenSequence if(!hasCoinFlipSucceeded) else misplacedFragmentIdx_withinSolutionSequence ), # Reversed
							]
						},
					]
				),
				result = "inattentive",
			}, {
				sequence = getMutatedSequence(
					sequenceParams.sequence,
					[
						{
							action = "swap",
							indexes = [
								misplacedFragmentIdx_withinSolutionSequence,
								misplacedFragmentIdx_withinChosenSequence,
							]
						},
					]
				),
				result = "inattentive",
			}, {
				sequence = getMutatedSequence(
					sequenceParams.sequence,
					[
						mutationInstruction_misplaceInitialHint,
					]
				),
				result = "inattentive",
			},
		]

		sequenceParams.actions2.shuffle()
	elif(actionStageIdx == 3):
		var indexesWithoutInitialHintIdx:Array = swappableIndexes.duplicate()

		var mutationInstruction_misplaceInitialHint:Dictionary = {
			action = "swap",
			indexes = [
				sequenceParams.initialHintIdx,
				RNG.pick(indexesWithoutInitialHintIdx),
			]
		}

		var firstIdx:int = RNG.grab(swappableIndexes)
		var secondIdx:int = RNG.grab(swappableIndexes)
		var thirdIdx:int = swappableIndexes[0]

		sequenceParams.actions3 = [
			{
				sequence = sequenceParams.sequence,
				result = "correct",
			}, {
				sequence = getMutatedSequence(
					sequenceParams.sequence,
					[
						{
							action = "overwrite",
							idx = firstIdx,
							value = RNG.pick(sequenceParams.misleadingFragments)
						},
					]
				),
				result = "inattentive",
			}, {
				sequence = getMutatedSequence(
					sequenceParams.sequence,
					[
						{
							action = "swap",
							indexes = [
								secondIdx,
								thirdIdx,
							]
						},
					]
				),
				result = "inattentive",
			}, {
				sequence = getMutatedSequence(
					sequenceParams.sequence,
					[
						mutationInstruction_misplaceInitialHint,
					]
				),
				result = "inattentive",
			},
		]

		sequenceParams.actions3.shuffle()

func getCurrentPowerReversalStageIdx() -> int:
	var currentActionStageIdx:int = subPowerReversalPersistentDict.currentActionStageIdx if( subPowerReversalPersistentDict.has("currentActionStageIdx") ) else 1
	return currentActionStageIdx

func getCurrentPowerReversalActionList() -> Array:
	var currentActionStageIdx:int = getCurrentPowerReversalStageIdx()

	var stageActionList:Array = []
	if(currentActionStageIdx == 3):
		stageActionList = subPowerReversalPersistentDict.actions3
	elif(currentActionStageIdx == 2):
		stageActionList = subPowerReversalPersistentDict.actions2
	else:
		stageActionList = subPowerReversalPersistentDict.actions1

	return stageActionList

func startPowerReversedInteraction() -> void:
	var sub = getRoleChar("sub")

	clearMessagesForChar(sub)
	startInteraction("SneakUpTease", {dom=getRoleID("sub"), sub=getRoleID("dom")})

func getDialogueLines_reactToSuccessfulPowerReversal() -> Array:
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domIsKind:bool = domPersonalityMeanScore < -0.4

	var domPersonalitySubbyScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var domIsSubby:bool = domPersonalitySubbyScore < -0.4

	var dialogueLines:Array = []

	if(domIsSubby):
		dialogueLines.append_array([
			"W- What are you d- doing..",
			"Y-.. You can't do that..",
			"You will regret t- this.. A- Ah..",
		])
	else:
		dialogueLines.append_array([
			"Did you forget your place, toy?",
			"Are we really doing this now?",
		])

		if(!domIsKind):
			dialogueLines.append_array([
				"What do you think you're doing??",
				"We both know how this ends, you shuffling around won't change that.",
			])

	if(domIsMean):
		dialogueLines.append_array([
			"You fucking brat.",
			"Get your fucking hands off me.",
			"Bitch, I'll make you regret this.",
		])
	elif(domIsKind):
		dialogueLines.append_array([
			"Mmhh.. Show me more.",
		])

	return dialogueLines

func getDialogueLines_reactToFailedPowerReversal() -> Array:
	var domPawn = getRolePawn("dom")

	var domPersonalityMeanScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Mean: 1.0 })
	var domIsMean:bool = domPersonalityMeanScore > 0.4
	var domIsKind:bool = domPersonalityMeanScore < -0.4

	var domPersonalitySubbyScore:float = domPawn.scorePersonalityMax({ PersonalityStat.Subby: 1.0 })
	var domIsSubby:bool = domPersonalitySubbyScore < -0.4

	var dialogueLines:Array = []

	if(domIsSubby):
		dialogueLines.append_array([
			"Y- You won't have your way with m- me..",
		])
	else:
		dialogueLines.append_array([
			"Not another move, pet.",
			"Still haven't learned your place?",
		])

		if(!domIsKind):
			dialogueLines.append_array([
				"You're powerless against me.",
			])

	if(domIsMean):
		dialogueLines.append_array([
			"Don't fucking try that again you whore.",
		])
	elif(domIsKind):
		dialogueLines.append_array([
			"Hey, are you alright? I'll try to be more careful handling you.",
			"You're very soft, I trust you won't try that again~",
		])

	return dialogueLines

# For some creatures this will be incorrect, sorry..
func getBoyBoun(characterRole:String) -> String:
	var character = getRoleChar(characterRole)

	var boyNoun = (
			RNG.pick(["thing", "critter"])
		if( character.getGender() == Gender.Other )
		else (
				RNG.pick(["boy", "girl"])
			if ( character.heShe() == "they" )
			else (
					"girl"
				if ( character.heShe() == "she" )
				else "boy"
			)
		)
	)

	return boyNoun

func resetLustState() -> void:
	for role in ["dom", "sub"]:
		var character = getRoleChar(role)
		var items = character.getInventory().getAllEquippedItems()
		for itemSlot in items:
			var item = items[itemSlot]
			item.resetLustState()
		character.updateAppearance()
