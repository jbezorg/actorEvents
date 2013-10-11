Scriptname _ae_PlayerLoadGameAlias extends ReferenceAlias  

event OnPlayerLoadGame()
	( self.GetOwningQuest() as _ae_mod_base ).aeRegisterEvents()
endEvent
