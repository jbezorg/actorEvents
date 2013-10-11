Scriptname _ae_statevent_mes extends activemagiceffect  Conditional

_ae_framework property ae              auto
String        property stat            auto
Spell         property statSpell       auto
Int           property statBlock       auto hidden
Float         property statValue       auto hidden

Actor kTarget
; stat mode event base name
String sMEBN = ""

event OnEffectStart(Actor akTarget, Actor akCaster)
	kTarget   = akTarget
	sMEBN     = ae.PREFIX_ + kTarget.GetFormID() as String
	statValue = kTarget.GetActorValuePercentage(stat) * 10.0	
	statBlock = Math.Floor( statValue )

	if statBlock < 0
		statBlock = 0
	elseIf statBlock > 10
		statBlock = 10
	endIf

	if !kTarget.HasSpell(statSpell)
		Int oIdx         = 0
		Int cIdx         = 0
		Int pIdx         = 0
		Int iPSum        = 0
		Float fRoll      = 0.0
		Float fRangeHi   = 1.0
		Float fRangeLo   = 0.0
		Bool bActive     = false
		Bool bBaseCheck  = false
		Bool bStatCheck  = false
		Bool bListCheck  = false
		Int[] iCallBacks = new int[20]

		; does any event quilify? If so build a list of them
		; for random selection
		oIdx = ae.customOwner.length
		while oIdx > 0
			oIdx -= 1

			bListCheck = ae.customPriority[oIdx] > 0 && (ae.customOwner[oIdx] as _ae_mod_base).myActorsList.Find(kTarget) >= 0
			bStatCheck = bListCheck && ae.customBlockHi[oIdx] >= statBlock && ae.customBlockLo[oIdx] <= statBlock
			bBaseCheck = bStatCheck && ae.customStat[oIdx] == stat && ae.customOwner[oIdx] && (ae.customOwner[oIdx] as _ae_mod_base).qualifyActor(kTarget, stat)

			if bBaseCheck
				Debug.TraceConditional(ae.PREFIX_ + "statevent: " + ae.customCallback[oIdx] + " queued", ae.VERBOSE)
				bActive          = true
				iCallBacks[cIdx] = oIdx
				iPSum           += ae.customPriority[oIdx]
				cIdx += 1
			elseIf ae.customOwner[oIdx]
				Debug.TraceConditional(ae.PREFIX_ + "statevent: " + ae.customCallback[oIdx] + " not queued", ae.VERBOSE)
			endIf
		endWhile

		; Why check again? Multiple events for the same stat can trigger
		; at the same time. We check again and add the spell right after
		; to filter out simultaneous events
		if bActive && !kTarget.HasSpell(statSpell) && kTarget.AddSpell(statSpell, false)
			if cIdx > 1
				fRoll = Utility.RandomFloat()
				oIdx = 0
				while oIdx < cIdx && bActive
					pIdx = iCallBacks[oIdx]
					fRangeLo = fRangeHi - ( ae.customPriority[pIdx] / iPSum )

					if fRoll >= fRangeLo && fRoll <= fRangeHi
						bActive = false
					else
						oIdx += 1
						fRangeHi = fRangeLo
						Debug.TraceConditional(ae.PREFIX_ + "statevent: " + ae.customCallback[pIdx] + ae._START + " not triggered", ae.VERBOSE)
					endIf
				endWhile
			endIf
			
			; if for some reason one was not picked
			; or if there is only one event
			if bActive
				pIdx = iCallBacks[0]
			endIf

			; send this info to the effect script running on _ae_events_mes
			; to start watching for the closing event.
			kTarget.SendModEvent(sMEBN + ae._START, stat, pIdx)
			Debug.TraceConditional(ae.PREFIX_ + "statevent: " + sMEBN + ae._START + " triggered", ae.VERBOSE)
			kTarget.SendModEvent(ae.customCallback[pIdx] + ae._START, stat, statValue)
			Debug.TraceConditional(ae.PREFIX_ + "statevent: " + ae.customCallback[pIdx] + ae._START + " triggered", ae.VERBOSE)
		endIf
	endIf
endEvent

event OnEffectFinish(Actor akTarget, Actor akCaster)
	if kTarget && kTarget.HasSpell(statSpell)
		kTarget.SendModEvent(sMEBN + ae._END, stat)
	endIf
endEvent
