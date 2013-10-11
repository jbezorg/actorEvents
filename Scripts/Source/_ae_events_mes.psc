Scriptname _ae_events_mes extends activemagiceffect  

String[]        property Animation  auto
_ae_framework   property ae         auto
ObjectReference property aggressor  auto

; stat mode event base name
String sMEBN   = ""
; Health event index
Int    iHEIdx  = -1
; Magicka event index
Int    iMEIdx  = -1
; Stamina event index
Int    iSEIdx  = -1
; Active magic effect index
Int    iAMEIdx = -1

Actor  kTarget = none

event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	aggressor = akAggressor
endEvent

event OnMagicEffectApply(ObjectReference akCaster, MagicEffect akEffect)
	if ( akCaster && ( akCaster as Actor ).IsHostileToActor( kTarget ) )
		aggressor = akCaster
	endIf
endEvent

event OnStatEventStart(String asEventName, string asStat, float afModIdx, Form akSender)
	Int idx = afModIdx as Int
	Actor kSender    = akSender as Actor
	Float fStatValue = kSender.GetActorValuePercentage(asStat) * 10.0

	if asStat == ae.HEALTH && iHEIdx < 0
		iHEIdx = idx
	endIf
	if asStat == ae.MAGICKA && iMEIdx < 0
		iMEIdx = idx
	endIf
	if asStat == ae.STAMINA && iSEIdx < 0
		iSEIdx = idx
	endIf
endEvent

event OnStatEventEnd(String asEventName, string asStat, float afModIdx, Form akSender)
	Actor kSender    = akSender as Actor
	Float fStatValue = kSender.GetActorValuePercentage(asStat) * 10.0
	Int   iStatBlock = Math.Floor(fStatValue)
	Int   idx        = -1

	if asStat == ae.HEALTH && iHEIdx >= 0
		if (ae.customBlockHi[iHEIdx] < iStatBlock || ae.customBlockLo[iHEIdx] > iStatBlock)\
			&& kSender.HasSpell(ae.eventFlags[1]) && kSender.RemoveSpell(ae.eventFlags[1])
			idx = iHEIdx
			iHEIdx = -1
		endIf
	endIf
	if asStat == ae.MAGICKA && iMEIdx >= 0
		if (ae.customBlockHi[iMEIdx] < iStatBlock || ae.customBlockLo[iMEIdx] > iStatBlock)\
			&& kSender.HasSpell(ae.eventFlags[2]) && kSender.RemoveSpell(ae.eventFlags[2])
			idx = iMEIdx
			iMEIdx = -1
		endIf
	endIf
	if asStat == ae.STAMINA && iSEIdx >= 0
		if (ae.customBlockHi[iSEIdx] < iStatBlock || ae.customBlockLo[iSEIdx] > iStatBlock)\
			&& kSender.HasSpell(ae.eventFlags[3]) && kSender.RemoveSpell(ae.eventFlags[3])
			idx = iSEIdx
			iSEIdx = -1
		endIf
	endIf
	
	if idx >= 0
		akSender.SendModEvent(ae.customCallback[idx] + ae._END, asStat, fStatValue)
	endIf
endEvent

event OnActorPing(String asEventName, string asStat, float afModIdx, Form akSender)
	iAMEIdx = ae.monitored.Find(kTarget)
	ae.monitoredEffect[iAMEIdx] = self
endEvent

event OnAnimationEvent(ObjectReference akSource, string asEventName)
	if akSource == kTarget as ObjectReference && asEventName == Animation[0]\
		&& !kTarget.HasSpell(ae.eventFlags[0]) && kTarget.AddSpell(ae.eventFlags[0], false)

		kTarget.SendModEvent(ae.ANIM_START, "ragdoll", Utility.GetCurrentRealTime())
	endIf
	if akSource == kTarget as ObjectReference  && asEventName == Animation[1]\
		&& kTarget.HasSpell(ae.eventFlags[0]) && kTarget.RemoveSpell(ae.eventFlags[0])

		kTarget.SendModEvent(ae.ANIM_END, "ragdoll", Utility.GetCurrentRealTime())
	endIf
endEvent

event OnEffectStart(Actor akTarget, Actor akCaster)
	while !akTarget.Is3DLoaded()
	endWhile
	
	kTarget = akTarget
	
	; to ensure that only this actor only receives
	; events from itself, we use it's form id cast
	; as a string as part of the the mod event name.
	sMEBN = ae.PREFIX_ + kTarget.GetFormID() as String
	RegisterForModEvent(sMEBN + ae._START, "OnStatEventStart")
	RegisterForModEvent(sMEBN + ae._END,   "OnStatEventEnd")
	RegisterForModEvent(sMEBN + ae._PING,  "OnActorPing")

	Int idx = Animation.Length
	while idx > 0
		idx -= 1
		RegisterForAnimationEvent(kTarget, Animation[idx])
	endWhile

	iAMEIdx = ae.monitored.Find(kTarget)
	ae.monitoredEffect[iAMEIdx] = self
	ae.SendModEvent(ae.MONITORING, ae.ACTORADD, kTarget.GetFormID() as float)

	Debug.TraceConditional(ae.PREFIX_ + ae.MONITORING + " " + ae.ACTORADD + " " + kTarget.GetFormID() + " " + iAMEIdx, ae.VERBOSE)
endEvent

event OnEffectFinish(Actor akTarget, Actor akCaster)
	ae.monitoredEffect[iAMEIdx] = none
	ae.SendModEvent(ae.MONITORING, ae.ACTORCLEAR, kTarget.GetFormID() as float)
endEvent
