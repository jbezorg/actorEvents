Scriptname _ae_framework extends Quest  Conditional

Spell     Property Monitor        Auto  
Spell[]   Property eventFlags     Auto
Quest[]   Property customOwner    Auto
Int[]     Property customBlockHi  Auto
Int[]     Property customBlockLo  Auto
String[]  Property customCallback Auto
String[]  Property customStat     Auto
Bool[]    Property customRemove   Auto
Int[]     Property customPriority Auto

Actor[]             Property monitored        Auto
ActiveMagicEffect[] Property monitoredEffect  Auto
Int[]               Property monitoredCount   Auto

Int       Property VOID         = -2147483648 AutoReadOnly
Int       Property MAX_SPAN     = 8           AutoReadOnly
Int       Property PRI_DEFAULT  = 5           AutoReadOnly
String    Property HEALTH       = "Health"    AutoReadOnly
String    Property MAGICKA      = "Magicka"   AutoReadOnly
String    Property STAMINA      = "Stamina"   AutoReadOnly
String    Property _PING        = "_ping"     AutoReadOnly
String    Property _START       = "_start"    AutoReadOnly
String    Property _END         = "_end"      AutoReadOnly
String    Property PREFIX_      = "ae::"      AutoReadOnly
String    Property PURGE        = "purge"     AutoReadOnly
String    Property ENABLE_      = "enable"    AutoReadOnly
String    Property DISABLE_     = "disable"   AutoReadOnly
String    Property REMOVE_      = "remove"    AutoReadOnly
String    Property ACTORADD     = "add"       AutoReadOnly
String    Property ACTORCLEAR   = "clear"     AutoReadOnly
Bool      Property VERBOSE      = true        AutoReadOnly

String Property ANIM_START
	String function Get()
		return PREFIX_ + "anim" + _START
	endFunction
endProperty
String Property ANIM_END
	String function Get()
		return PREFIX_ + "anim" + _END
	endFunction
endProperty
String Property UPDATE
	String function Get()
		return PREFIX_ + "update"
	endFunction
endProperty
String Property MONITORING
	String function Get()
		return PREFIX_ + "monitor"
	endFunction
endProperty

; =============================================================================
; API Functions ===============================================================
; =============================================================================
Bool function monitor(Actor akActor, Bool abMonitor = true)
	if !akActor
		Debug.TraceConditional(PREFIX_ + "monitor: actor is none", VERBOSE)
		return false
	endIf
	String sName = akActor.GetLeveledActorBase().GetName()

	Int idx = monitored.Find(akActor)

	if abMonitor
		if idx < 0
			idx = addToActorArray(akActor, monitored)
		endIf
		if !akActor.HasSpell(Monitor)
			akActor.AddSpell(Monitor)
		else
			SendModEvent(PREFIX_ + akActor.GetFormID() as String + _PING)
		endIf
		
		monitoredCount[idx] = getActorRegistrationCount(akActor)		

		Debug.TraceConditional(PREFIX_ + "monitor: " + sName + " registered with AE", VERBOSE)
		return true
	elseIf idx > 0
		monitoredCount[idx] = monitoredCount[idx] - 1

		if monitoredCount[idx] <= 0
			monitored[idx]      = none
			monitoredCount[idx] = 0

			if akActor.HasSpell(Monitor)
				akActor.RemoveSpell(Monitor)
			endIf
			Debug.TraceConditional(PREFIX_ + "monitor: " + sName + " cleared AE registration", VERBOSE)
		else
			Debug.TraceConditional(PREFIX_ + "monitor: " + sName + " still tracked by other mods", VERBOSE)
		endIf

		return true
	else
		if akActor.HasSpell(Monitor)
			akActor.RemoveSpell(Monitor)
		endIf

		Debug.TraceConditional(PREFIX_ + "monitor: " + sName + " not registered with AE", VERBOSE)
		return false
	endIf
endFunction

Bool function isRagdolling(Actor akActor)
	return akActor.HasSpell(eventFlags[0])
endFunction

Int function register(Quest akOwner, Int aiStatBlockHi, Int aiStatBlockLo, String asCallback, String asStat = "")
	if asStat == ""
		asStat = HEALTH
	endIf

	if customOwner.Find(akOwner) >= 0
		Debug.TraceConditional(PREFIX_ + "register: " + akOwner + " already registered", VERBOSE)
		return -1
	endIf
	if aiStatBlockHi > 9 || aiStatBlockLo < 0
		Debug.TraceConditional(PREFIX_ + "register: aiStatBlockHi && aiStatBlockLo valid range 0-9", VERBOSE)
		return -1
	endIf
	if aiStatBlockHi - aiStatBlockLo > MAX_SPAN
		Debug.TraceConditional(PREFIX_ + "register: aiStatBlockHi && aiStatBlockLo valid diff " + MAX_SPAN, VERBOSE)
		aiStatBlockHi = aiStatBlockLo + MAX_SPAN
	endIf

	Int iRet = -1
	Int idx  = customOwner.length
	while idx > 0 && iRet < 0
		idx -= 1
		if customRemove[idx]
			iRet                = idx
			customOwner[idx]    = akOwner
			customBlockHi[idx]  = aiStatBlockHi
			customBlockLo[idx]  = aiStatBlockLo
			customCallback[idx] = asCallback
			customStat[idx]     = asStat
			customRemove[idx]   = false
			customPriority[idx] = PRI_DEFAULT
		endIf
	endWhile

	if iRet >= 0
		Debug.TraceConditional(PREFIX_ + "register: " + asCallback + " registered for " + asStat + ", range: " + aiStatBlockLo + "-" + aiStatBlockHi, VERBOSE)
		( akOwner as _ae_mod_base ).aeRegisterActors()
	else
		Debug.TraceConditional(PREFIX_ + "register: " + asCallback + " unable to registered for " + asStat + " event", VERBOSE)
	endIf

	return iRet
endFunction

bool function unRegister(Quest akOwner)
	Int idx = customOwner.Find(akOwner)
	if idx < 0
		Debug.TraceConditional(PREFIX_ + "unregister: "+akOwner+" not registered", VERBOSE)
		return false
	else
		Debug.TraceConditional(PREFIX_ + "unregister: "+akOwner+" unregistered", VERBOSE)
		( akOwner as _ae_mod_base ).aeRegisterActors(false)
		blankCallback(idx)
		return true
	endIf
endFunction

Int function check(Quest akOwner)
	return customOwner.Find(akOwner)
endFunction

Int function GetModIndexByName(String asName)
	Int idx = customOwner.Length
	while idx > 0
		idx -= 1
		if customOwner[idx].GetName() == asName
			return idx
		endIf
	endWhile
	return -1
endFunction

ObjectReference function GetLastAttacker(Actor akActor)
	Int idx = monitored.Find(akActor)
	if idx >= 0
		_ae_events_mes thisMonitor = monitoredEffect[idx] as _ae_events_mes
		if thisMonitor
			return thisMonitor.aggressor
		endIf
	endIf
	
	return none
endFunction


; =============================================================================
; Utility Functions ===========================================================
; =============================================================================
int function getActorRegistrationCount(Actor akActor)
	int count = 0
	int idx = customOwner.length

	while idx > 0
		idx -= 1
		if customOwner[idx] && ( customOwner[idx] as _ae_mod_base ).myActorsList.Find(akActor) >= 0
			count += 1
		endIf
	endWhile

	return count
endFunction

function blankIntArray(Int[] aiArray)
	Int idx = aiArray.length
	while idx > 0
		idx -= 1
		aiArray[idx] = VOID
	endWhile
endFunction

function blankCallback(Int idx)
	customOwner[idx]    = none
	customBlockHi[idx]  = VOID
	customBlockLo[idx]  = VOID
	customCallback[idx] = ""
	customStat[idx]     = ""
	customRemove[idx]   = true
	customPriority[idx] = 0
endFunction

Int function addToActorArray(Actor akActor, Actor[] akActorArray)
	Int idx = akActorArray.Find(none)
	if idx >= 0
		akActorArray[idx] = akActor
	endIf
	Return idx
endFunction

Int function removeFromActorArray(Actor akActor, Actor[] akActorArray)
	Int idx = akActorArray.Find(akActor)
	if idx >= 0
		akActorArray[idx] = none
	endIf
	Return idx
endFunction

; unsigned 0 to 65,535
Int function getUnsignedWord(Int aiDword, Bool abHighWord = false)
	if abHighWord
		return Math.RightShift(Math.LogicalAnd(0xFFFF0000, aiDword), 16)
	else
		return Math.LogicalAnd(0x0000FFFF, aiDword)
	endIf
endFunction

; unsigned 0 to 65,535
Int function setUnsignedWord(Int aiDword, Int aiValue, Bool abHighWord = false)
	Int iLWord = Math.LogicalAnd(0x0000FFFF, aiDword)
	Int iHWord = Math.LogicalAnd(0xFFFF0000, aiDword)

	; if we are setting the high word we want to preserve the low word
	; and vice-versa. Hence the logical or with the opposite word.
	if abHighWord
		return Math.LogicalOr(Math.LeftShift(aiValue, 16), iLWord)
	else
		return Math.LogicalOr(Math.LogicalAnd(0x0000FFFF, aiValue), iHWord)
	endIf
endFunction



event OnInit()
	if monitoredEffect.length != 128
		monitoredEffect = New ActiveMagicEffect[128]
	endIf
endEvent



