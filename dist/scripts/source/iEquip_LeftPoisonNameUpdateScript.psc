ScriptName iEquip_LeftPoisonNameUpdateScript Extends Quest Hidden

iEquip_WidgetCore Property WC Auto

Import UICallback

String WidgetRoot

Float fDelay
Float fDuration

bool bWaitingForNameFadeoutUpdate = false

function registerForNameFadeoutUpdate()
	WidgetRoot = WC.WidgetRoot
	fDelay = WC.fPoisonNameFadeoutDelay
	fDuration = WC.fNameFadeoutDuration
	if WC.bNameFadeoutEnabled && fDelay > 0
		RegisterForSingleUpdate(fDelay)
		bWaitingForNameFadeoutUpdate = true
	endIf
endFunction

function unregisterForNameFadeoutUpdate()
	UnregisterForUpdate()
	bWaitingForNameFadeoutUpdate = false
endFunction

event OnUpdate()
	if bWaitingForNameFadeoutUpdate ;Failsafe bool to block OnUpdate if triggered from another script on the quest
		bWaitingForNameFadeoutUpdate = false
		WC.abIsPoisonNameShown[0] = false
		Int iHandle = UICallback.Create("HUD Menu", WidgetRoot + ".tweenWidgetNameAlpha")
		If(iHandle)
			UICallback.PushInt(iHandle, 11) ;Which _mc we're fading out
			UICallback.PushFloat(iHandle, 0) ;Target alpha which for FadeOut is 0
			UICallback.PushFloat(iHandle, fDuration) ;FadeOut duration
			UICallback.Send(iHandle)
		EndIf
	endIf
endEvent