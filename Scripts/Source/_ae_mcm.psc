Scriptname _ae_mcm extends SKI_ConfigBase

_ae_framework property ae         auto

; OIDs (T:Text B:Toggle S:Slider M:Menu, C:Color, K:Key)
int[] _priority
int[] _sliderLo
int[] _sliderHi
int[] _removeMe

function cleanRegisteredStatEvents()
	int idx = ae.customOwner.length
	while idx > 0
		idx -= 1

		_ae_mod_base me = ae.customOwner[idx] as _ae_mod_base
		
		if !ae.customRemove[idx] && !ae.customOwner[idx]
			ae.blankCallback(idx)
			me.aeRegisterActors(false)

			ae.SendModEvent(ae.UPDATE, ae.PURGE, idx as float)
			Debug.TraceConditional(ae.PREFIX_ + ae.UPDATE + ae.PURGE + "=" +idx, ae.VERBOSE)
		elseIf ae.customOwner[idx]
			if me.myVersion != me.aeGetVersion()
				me.aeUpdate( me.myVersion )
				me.myVersion = me.aeGetVersion()
			endIf

			me.aeRegisterActors()
			
			if me.myIndex != idx
				me.myIndex = idx
			endIf
		endIf
	endWhile
endFunction

function reRegisterActors()
	Debug.Notification( "$REREGISTER" )
	Int idx = 0
	Int len = ae.customOwner.length

	idx = len
	while idx > 0
		idx -= 1
		if ae.customOwner[idx]
			( ae.customOwner[idx] as _ae_mod_base ).aeRegisterActors(false)
		endIf
	endWhile

	idx = len
	while idx > 0
		idx -= 1
		if ae.customOwner[idx]
			( ae.customOwner[idx] as _ae_mod_base ).aeRegisterActors()
		endIf
	endWhile
endFunction

int function GetVersion()
	return 2210
endFunction

string function GetStringVer()
	return StringUtil.Substring((GetVersion() as float / 1000.0) as string, 0, 4)
endFunction

event OnConfigInit()
	Pages = New String[1]
	Pages[0] = "$PAGE0"

	_priority = new Int[20]
	_sliderLo = new Int[20]
	_sliderHi = new Int[20]
	_removeMe = new Int[20]
endEvent

event OnVersionUpdate(int a_version)
	if (a_version >= 2210 && CurrentVersion < 2210)
		reRegisterActors()
	endIf
endEvent

event OnPageReset(string a_page)
	if (a_page == "" || !Self.IsRunning() )
		LoadCustomContent("jbezorg/actorEvents.dds", 271, 95)
		return
	else
		UnloadCustomContent()
	endIf


	if ( a_page == Pages[0] )
		String thisOwnerName
		Int idx = ae.customOwner.length
		while idx > 0
			idx -= 1
			if !ae.customRemove[idx]
				thisOwnerName = ae.customOwner[idx].GetName()
				_removeMe[idx]  = AddToggleOption(thisOwnerName + " Remove",  ae.customRemove[idx], OPTION_FLAG_NONE)
				_sliderLo[idx]  = AddSliderOption(ae.customStat[idx] + " Low",  ae.customBlockLo[idx], "{0}0%", OPTION_FLAG_NONE)
				_priority[idx]  = AddSliderOption(thisOwnerName + " Priority", ae.customPriority[idx], "{0}", OPTION_FLAG_NONE)
				_sliderHi[idx]  = AddSliderOption(ae.customStat[idx] + " High", ae.customBlockHi[idx], "{0}0%", OPTION_FLAG_NONE)
			endIf
		endWhile
	endIf
endEvent

event OnOptionSliderOpen(int a_option)
	Int idxL = _sliderLo.Find(a_option)
	Int idxH = _sliderHi.Find(a_option)
	Int idxP = _priority.Find(a_option)
	Int iLimit = 0

	if idxL >= 0
		SetSliderDialogStartValue(ae.customBlockLo[idxL])
		SetSliderDialogDefaultValue(ae.customBlockLo[idxL])
		iLimit = ae.customBlockHi[idxL] - ae.MAX_SPAN
		if iLimit < 0
			iLimit = 0
		endIf
		SetSliderDialogRange(iLimit, ae.customBlockHi[idxL])
	endIf

	if idxH >= 0
		SetSliderDialogStartValue(ae.customBlockHi[idxH])
		SetSliderDialogDefaultValue(ae.customBlockHi[idxH])
		iLimit = ae.customBlockLo[idxH] + ae.MAX_SPAN
		if iLimit > 9
			iLimit = 9
		endIf
		SetSliderDialogRange(ae.customBlockLo[idxH], iLimit)
	endIf

	if idxP >= 0
		SetSliderDialogStartValue(ae.customPriority[idxP])
		SetSliderDialogDefaultValue(ae.customPriority[idxP])
		SetSliderDialogRange(0, 10)
	endIf

	SetSliderDialogInterval(1)
endEvent

event OnOptionSliderAccept(int a_option, float a_value)
	Int idxL = _sliderLo.Find(a_option)
	Int idxH = _sliderHi.Find(a_option)
	Int idxP = _priority.Find(a_option)

	if idxL >= 0
		ae.customBlockLo[idxL] = a_value as Int
		SetSliderOptionValue(a_option, ae.customBlockLo[idxL], "{0}0%")
	endIf

	if idxH >= 0
		ae.customBlockHi[idxH] = a_value as Int
		SetSliderOptionValue(a_option, ae.customBlockHi[idxH], "{0}0%")
	endIf

	if idxP >= 0
		ae.customPriority[idxP] = a_value as Int
		SetSliderOptionValue(a_option, ae.customPriority[idxP], "{0}")
	endIf
endEvent

event OnOptionSelect(int a_option)
	Bool bRemove = false
	Int idx      = _removeMe.Find(a_option)

	if idx >= 0
		ae.customRemove[idx] = !ae.customRemove[idx]
		bRemove = ShowMessage("$REMOVEWARN", true)
		if ae.customRemove[idx] && bRemove && ShowMessage("$LASTCHANCE", true)
			ae.customOwner[idx]    = none
			ae.customBlockHi[idx]  = ae.VOID
			ae.customBlockLo[idx]  = ae.VOID
			ae.customCallback[idx] = ""
			ae.customStat[idx]     = ""
			ae.customRemove[idx]   = true
			ae.customPriority[idx] = 0
			ae.SendModEvent(ae.UPDATE, ae.REMOVE_, idx as float)
			ForcePageReset()
		else
			ae.customRemove[idx] = false
		endIf
	endIf
endEvent

event OnOptionHighlight(int a_option)
	Bool bL = _sliderLo.Find(a_option) >= 0
	Bool bH = _sliderHi.Find(a_option) >= 0
	Bool bP = _priority.Find(a_option) >= 0
	Bool bR = _removeMe.Find(a_option) >= 0

	if bL
		SetInfoText("$INFO_LOW")
	elseIf bH
		SetInfoText("$INFO_HI")
	elseIf bP
		SetInfoText("$INFO_PRIORITY")
	elseIf bR
		SetInfoText("$INFO_REMOVE")
	endIf
endEvent
