Scriptname _ae_cleanup extends ReferenceAlias  

_ae_mcm       property mcm        auto

event OnPlayerLoadGame()
	mcm.cleanRegisteredStatEvents()
endEvent
