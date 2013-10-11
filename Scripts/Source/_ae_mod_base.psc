Scriptname _ae_mod_base extends Quest  

_ae_framework Property ae Auto
{
Required:

This has to point to _ae_base
}
String Property myEvent Auto
{
Required:

This is the base name for your mod's AE events
}
String Property myCallback Auto
{
Required:

This is the base name for your mod's AE event callback
}
Actor[] Property myActorsList Auto
{
Required:

This has to point to a form list containing actors your Mod
monitors.
}
String[] Property publicModEvents Auto
{
Optional:

This is registry of public mod events sent out by your mod.
see: http://www.creationkit.com/RegisterForModEvent_-_Form
}

Int  Property  myIndex   = -1 Auto Hidden
Int  Property  myVersion = -1 Auto Hidden

Bool function qualifyActor(Actor akActor = none, String asStat = "")
	Debug.Trace("AE::WARNING: you have not defined a 'qualifyActor' function in your mod. Your events will not trigger.")
	return false
endFunction

function aeRegisterMod()
	Debug.Trace("AE::WARNING: you have not defined a 'aeRgisterMod' function in your mod.")
endFunction

function aeUnRegisterMod()
	ae.unRegister(self)
	aeRegisterActors(false)
	myIndex = -1
endFunction

function aeUninstallMod()
	Debug.Trace("AE::WARNING: you have not defined a 'aeUninstallMod' function in your mod.")
endFunction

int function aeGetVersion()
	return -1
endFunction

function aeUpdate( int aiVersion )
endFunction

Bool function aeCheck()
	return ae.check(self) >= 0
endFunction

function aeRegisterActors(Bool abAdd = true)
	Int idx = myActorsList.length
	Debug.TraceConditional(ae.PREFIX_ + "register actors: " + idx, ae.VERBOSE)

	While idx > 0
		idx -= 1
		ae.monitor(myActorsList[idx] as Actor, abAdd)
	EndWhile
endFunction

function aeRegisterEvents()
	Debug.TraceConditional(ae.PREFIX_ + "register event: " + myEvent + ae._START + ", " + myCallback, ae.VERBOSE)
	RegisterForModEvent(myEvent + ae._START, myCallback)
	RegisterForModEvent(ae.UPDATE,     "OnAEUpdate")
	RegisterForModEvent(ae.MONITORING, "OnAEMonitor")
endFunction

; If our actors are cleared before we are done with them
event OnAEMonitor(String asEventName, string asEvent, float afActorId, Form akSender)
	Actor thisActor = Game.GetForm(afActorId as Int) as Actor
	Quest thisQuest = akSender as Quest
	if thisQuest == self && asEvent == ae.ACTORCLEAR && ae.customOwner.Find(self) >= 0 && myActorsList.Find(thisActor) >= 0
		ae.monitor(thisActor)
	endIf
endEvent

event OnAEUpdate(String asEventName, string asEvent, float afModIdx, Form akSender)
	Int   thisModIdx = afModIdx as Int
	Quest thisQuest  = akSender as Quest

	Debug.Notification("EC::OnAEUpdate:" + asEvent)
	If thisModIdx == myIndex
		if asEvent == ae.ENABLE_
			RegisterForModEvent(myEvent + ae._START, myCallback)
			aeRegisterActors()
		endIf
		if asEvent == ae.DISABLE_
			UnregisterForModEvent(myCallback)
			aeRegisterActors(false)
		endIf
		if asEvent == ae.REMOVE_
			UnregisterForModEvent(myCallback)
			UnregisterForModEvent("OnAEUpdate")
			UnregisterForModEvent("OnAEMonitor")
			aeUnRegisterMod()
			aeUninstallMod()
		endIf
		if asEvent == ae.PURGE
			aeRegisterMod()
			RegisterForModEvent(myEvent + ae._START, myCallback)
		endIf
	endIf
endEvent

