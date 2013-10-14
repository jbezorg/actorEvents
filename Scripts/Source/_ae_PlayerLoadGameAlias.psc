Scriptname _ae_PlayerLoadGameAlias extends ReferenceAlias  

event OnPlayerLoadGame()
	_ae_mod_base me = self.GetOwningQuest() as _ae_mod_base
	
	me.aeRegisterEvents()

	me.aeUpdate( me.myVersion )
	me.myVersion = me.aeGetVersion()
endEvent
