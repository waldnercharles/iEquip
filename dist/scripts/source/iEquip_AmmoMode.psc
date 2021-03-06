
Scriptname iEquip_AmmoMode extends Quest

Import UI
Import UICallback
Import Utility
import _Q2C_Functions
Import iEquip_AmmoExt
import stringUtil

iEquip_WidgetCore property WC auto
iEquip_ProMode property PM auto
iEquip_PlayerEventHandler property EH auto

actor property PlayerRef auto
FormList property iEquip_AmmoItemsFLST auto

string property sAmmoIconSuffix = "" auto hidden
int property iAmmoListSorting = 1 auto hidden
int property iActionOnLastAmmoUsed = 1 auto hidden

bool property bAmmoMode = false auto hidden
bool bReadyForAmmoModeAnim = false
bool property bAmmoModePending = false auto hidden

int property Q = 0 auto hidden
int[] property aiTargetQ auto hidden
bool[] abNeedsSorting

int[] property aiCurrentAmmoIndex auto hidden
string[] property asCurrentAmmo auto hidden
form property currentAmmoForm auto hidden

int ilastSortType = 0

bool bBoundAmmoAdded = false
bool[] property abBoundAmmoInQueue auto hidden
string[] asBoundAmmoNames
string[] asBoundAmmoIcons

string[] asAmmoIcons

String HUD_MENU = "HUD Menu"
String WidgetRoot

event onInit()
	aiTargetQ = new int[2]
	aiTargetQ[0] = 0
	aiTargetQ[1] = 0

	aiCurrentAmmoIndex = new int[2]
	aiCurrentAmmoIndex[0] = 0
	aiCurrentAmmoIndex[1] = 0

	asCurrentAmmo = new string[2]
	asCurrentAmmo[0] = ""
	asCurrentAmmo[1] = ""

	abNeedsSorting = new bool[2]
	abNeedsSorting[0] = false
	abNeedsSorting[1] = false

	abBoundAmmoInQueue = new bool[2]
	abBoundAmmoInQueue[0] = false
	abBoundAmmoInQueue[1] = false

	asBoundAmmoNames = new string[2]
	asBoundAmmoNames[0] = "Bound Arrow"
	asBoundAmmoNames[1] = "Bound Bolt"

	asBoundAmmoIcons = new string[2]
	asBoundAmmoIcons[0] = "BoundArrow"
	asBoundAmmoIcons[1] = "BoundBolt"

	asAmmoIcons = new string[2]
	asAmmoIcons[0] = "Arrow"
	asAmmoIcons[1] = "Bolt"
endEvent

function OnWidgetLoad()
	WidgetRoot = WC.WidgetRoot
	if aiTargetQ[0] == 0
        aiTargetQ[0] = JArray.object()
        JMap.setObj(WC.iEquipQHolderObj, "arrowQ", aiTargetQ[0])
    endIf
    if aiTargetQ[1] == 0
        aiTargetQ[1] = JArray.object()
        JMap.setObj(WC.iEquipQHolderObj, "boltQ", aiTargetQ[1])
    endIf
    if WC.isEnabled
    	updateAmmoLists()
    endIf
endFunction

;This function is normally the first thing called in the Ammo Mode sequence
function selectAmmoQueue(int weaponType)
	debug.trace("iEquip_AmmoMode prepareAmmoQueue called, weaponType: " + weaponType)
	Q = ((weaponType == 9) as int)
	if iAmmoListSorting == 2 || iAmmoListSorting == 4
		selectLastUsedAmmo(Q)
	else
		selectBestAmmo(Q)
	endIf
endFunction

int function getCurrentAmmoObject()
	debug.trace("iEquip_AmmoMode getCurrentAmmoObject called")
	return jArray.getObj(aiTargetQ[Q], aiCurrentAmmoIndex[Q])
endFunction

function onAmmoAdded(form addedAmmo)
	debug.trace("iEquip_AmmoMode onAmmoAdded called - addedAmmo: " + addedAmmo.GetName())
	int isBolt = (addedAmmo as ammo).isBolt() as int
	int count = jArray.count(aiTargetQ[isBolt])
	if bAmmoMode && currentAmmoForm == addedAmmo && count > 1
    	setSlotCount(PlayerRef.GetItemCount(addedAmmo))
    elseif !isAlreadyInAmmoQueue(addedAmmo, aiTargetQ[isBolt])
    	AddToAmmoQueue(addedAmmo, addedAmmo.GetName(), isBolt)
    	count = jArray.count(aiTargetQ[isBolt])
    	if count > 1
    		abNeedsSorting[isBolt] = true
    		sortAmmoLists()
    	else
    		selectBestAmmo(isBolt)
    	endIf
    	;If we've just added ammo to a previously empty queue
    	if count == 1 && Q == isBolt
    		debug.trace("iEquip_AmmoMode onAmmoAdded - just added ammo to an empty queue, Q: " + Q + ", isBolt: " + isBolt + ", bAmmoModePending: " + bAmmoModePending + ", bAmmoMode: " + bAmmoMode)
    		;If we equipped a ranged weapon without any suitable ammo and we still have it equipped we can now toggle ammo mode
    		if bAmmoModePending
    			toggleAmmoMode()
    		endIf
    	endIf
    endIf
endFunction

function onAmmoRemoved(form removedAmmo)
	debug.trace("iEquip_AmmoMode onAmmoRemoved called - removedAmmo: " + removedAmmo.GetName())
	;If we've still got at least one of it left check if it's the current ammo and update the count
	if PlayerRef.GetItemCount(removedAmmo) > 0
		if bAmmoMode && currentAmmoForm == removedAmmo
	    	setSlotCount(PlayerRef.GetItemCount(removedAmmo))
	    endIf
	;Otherwise if we've removed the last of this ammo check if it's in the relevant ammo queue and remove it
	elseIf iEquip_AmmoItemsFLST.HasForm(removedAmmo)
		int isBolt = (removedAmmo as ammo).isBolt() as int
		int targetQ = aiTargetQ[isBolt]
		int i = 0
		bool found = false
		while i < JArray.count(targetQ) && !found
			found = (removedAmmo == jMap.getForm(jArray.getObj(targetQ, i), "Form"))
			if found
				removeAmmoFromQueue(isBolt, i)
				;If we're in ammo mode and the ammo we've just removed matches the currently equipped ammo
				if bAmmoMode && (currentAmmoForm == removedAmmo)
					;If we've got at least one other type of ammo equip it now
					if JArray.count(targetQ) > 0
						checkAndEquipAmmo(false, true)
					;Otherwise check what is to happen when last ammo used up
					else
						bool switchedRangedWeapon = false
						if iActionOnLastAmmoUsed == 1 || iActionOnLastAmmoUsed == 2 ;If we've chosen one of the Switch Type options first check for a ranged weapon of a different type
							int typeToFind = 7
							if !isBolt
								typeToFind = 9
							endIf
							switchedRangedWeapon = PM.quickRangedFindAndEquipWeapon(typeToFind, false)
						endIf
						; If we haven't found an alternative ranged weapon, or we've selected Do Nothing...
						if iActionOnLastAmmoUsed == 0 || (iActionOnLastAmmoUsed == 1 && !switchedRangedWeapon)
							WC.setSlotToEmpty(0)
						; ...or Cycle / Switch Out
						elseIf iActionOnLastAmmoUsed == 3 || (iActionOnLastAmmoUsed == 2 && !switchedRangedWeapon)
							if PM.bCurrentlyQuickRanged
								PM.quickRanged()
							else
								PM.quickRangedSwitchOut(true)
							endIf
						endIf
					endIf
				endIf
			else
				i += 1
			endIf
		endWhile
	endIf
endFunction

function toggleAmmoMode(bool toggleWithoutAnimation = false, bool toggleWithoutEquipping = false)
	debug.trace("iEquip_AmmoMode toggleAmmoMode called, toggleWithoutAnimation: " + toggleWithoutAnimation + ", toggleWithoutEquipping" + toggleWithoutEquipping + ", bAmmoModePending: " + bAmmoModePending)
	if !bAmmoMode && jArray.count(aiTargetQ[Q]) < 1
		debug.trace("iEquip_AmmoMode toggleAmmoMode - no ammo for the selected weapon, setting bAmmoModePending to true")
		debug.Notification("You do not appear to have any ammo to equip for this type of weapon")
		WC.checkAndFadeLeftIcon(1, 5)
		bAmmoModePending = true
	else
		bAmmoMode = !bAmmoMode
		WC.bAmmoMode = bAmmoMode
		bReadyForAmmoModeAnim = false
		Self.RegisterForModEvent("iEquip_ReadyForAmmoModeAnimation", "ReadyForAmmoModeAnimation")
		if bAmmoMode
			bAmmoModePending = false ;Reset
			if WC.bLeftIconFaded ;In case we're coming from bAmmoModePending and it's still faded out
				WC.checkAndFadeLeftIcon(0, 0)
				Utility.Wait(0.3)
			endIf
			;Hide the left hand poison elements if currently shown
			if WC.abPoisonInfoDisplayed[0]
				WC.hidePoisonInfo(0)
			endIf
			if WC.CM.abIsChargeMeterShown[0]
				WC.CM.updateChargeMeterVisibility(0, false)
			endIf
			;Now unequip the left hand to avoid any strangeness when switching ranged weapons in bAmmoMode
			if !(WC.asCurrentlyEquipped[1] == "Bound Bow" || WC.asCurrentlyEquipped[1] == "Bound Crossbow")
				WC.UnequipHand(0)
			endIf
			;Prepare and run the animation
			if !toggleWithoutAnimation
				UI.invokebool(HUD_MENU, WidgetRoot + ".prepareForAmmoModeAnimation", true)
				while !bReadyForAmmoModeAnim
					Utility.Wait(0.01)
				endwhile
				AmmoModeAnimateIn()
			endIf
			if WC.bPreselectMode
				;Equip the ammo and update the left hand slot in the widget
				checkAndEquipAmmo(false, true, true)
				;Show the counter if previously hidden
				if !WC.abIsCounterShown[0]
					WC.setCounterVisibility(0, true)
				endIf
			endIf
		else
			if !toggleWithoutAnimation
				UI.invokebool(HUD_MENU, WidgetRoot + ".prepareForAmmoModeAnimation", false)
				while !bReadyForAmmoModeAnim
					Utility.Wait(0.01)
				endwhile
				AmmoModeAnimateOut(toggleWithoutEquipping)
			endIf
		endIf
		Self.UnregisterForModEvent("iEquip_ReadyForAmmoModeAnimation")
	endIf
endFunction

event ReadyForAmmoModeAnimation(string sEventName, string sStringArg, Float fNumArg, Form kSender)
	debug.trace("iEquip_AmmoMode ReadyForAmmoModeAnimation called")
	If(sEventName == "iEquip_ReadyForAmmoModeAnimation")
		bReadyForAmmoModeAnim = true
	endIf
endEvent

function AmmoModeAnimateIn()
	debug.trace("iEquip_AmmoMode AmmoModeAnimateIn called")		
	;Get icon name and item name data for the item currently showing in the left hand slot and the ammo to be equipped
	int ammoObject = jArray.getObj(aiTargetQ[Q], aiCurrentAmmoIndex[Q])
	string[] widgetData = new string[4]
	widgetData[0] = jMap.getStr(jArray.getObj(WC.aiTargetQ[0], WC.aiCurrentQueuePosition[0]), "Icon")
	widgetData[1] = WC.asCurrentlyEquipped[0]
	widgetData[2] = jMap.getStr(ammoObject, "Icon") + sAmmoIconSuffix
	widgetData[3] = asCurrentAmmo[Q]
	;Set the left preselect index to whatever is currently equipped in the left hand ready for cycling the preselect slot in ammo mode
	WC.aiCurrentlyPreselected[0] = WC.aiCurrentQueuePosition[0]
	;Update the left hand widget - will animate the current left item to the left preselect slot and animate in the ammo to the main left slot
	Self.RegisterForModEvent("iEquip_AmmoModeAnimationComplete", "onAmmoModeAnimationComplete")
	PM.bWaitingForAmmoModeAnimation = true
	UI.InvokeStringA(HUD_MENU, WidgetRoot + ".ammoModeAnimateIn", widgetData)
	WC.bCyclingLHPreselectInAmmoMode = true
	WC.updateAttributeIcons(0, WC.aiCurrentlyPreselected[0], false, true)
	;If we've just equipped a bound weapon the ammo will already be equipped, otherwise go ahead and equip the ammo
	if bBoundAmmoAdded
		bBoundAmmoAdded = false ;Reset
	else
		checkAndEquipAmmo(false, true, false)
	endIf
	;Update the left hand counter
	WC.setSlotCount(0, PlayerRef.GetItemCount(jMap.getForm(ammoObject, "Form")))
	;Show the counter if previously hidden
	if !WC.abIsCounterShown[0]
		WC.setCounterVisibility(0, true)
	endIf
	;Show the names if previously faded out on timer	
	if WC.bNameFadeoutEnabled
		if !WC.abIsNameShown[0] ;Left Name
			WC.showName(0)
		endIf
		if !WC.abIsNameShown[5] ;Left Preselect Name
			WC.showName(5)
		endIf
	endIf
endFunction

function AmmoModeAnimateOut(bool toggleWithoutEquipping = false)
	debug.trace("iEquip_AmmoMode AmmoModeAnimateOut called")
	WC.hideAttributeIcons(5)
	;Get icon and item name for item currently showing in the left preselect slot ready to update the main slot
	int leftPreselectObject = jArray.getObj(WC.aiTargetQ[0], WC.aiCurrentlyPreselected[0])
	string[] widgetData = new string[3]
	widgetData[0] = jMap.getStr(jArray.getObj(aiTargetQ[Q], aiCurrentAmmoIndex[Q]), "Icon") + sAmmoIconSuffix
	widgetData[1] = jMap.getStr(leftPreselectObject, "Icon")
	widgetData[2] = jMap.getStr(leftPreselectObject, "Name")
	;Update the widget - will throw away the ammo and animate the icon from preselect back to main position
	Self.RegisterForModEvent("iEquip_AmmoModeAnimationComplete", "onAmmoModeAnimationComplete")
	PM.bWaitingForAmmoModeAnimation = true
	UI.InvokeStringA(HUD_MENU, WidgetRoot + ".ammoModeAnimateOut", widgetData)
	;Update the main slot index
	int leftObject = jArray.getObj(WC.aiTargetQ[0], WC.aiCurrentQueuePosition[0])
	if !WC.bPreselectMode
		WC.aiCurrentQueuePosition[0] = WC.aiCurrentlyPreselected[0]
		WC.asCurrentlyEquipped[0] = jMap.getStr(leftObject, "Name")
	endIf
	;And re-equip the left hand item, which should in turn force a re-equip on the right hand to a 1H item, as long as we've not just toggled out of ammo mode as a result of us equipping a 2H weapon in the right hand
	if !toggleWithoutEquipping
		WC.cycleHand(0, WC.aiCurrentQueuePosition[0], jMap.getForm(leftObject, "Form"))
	endIf
	;Show the left name if previously faded out on timer
	if WC.bNameFadeoutEnabled && !WC.abIsNameShown[0] ;Left Name
		WC.showName(0)
	endIf
	;Hide the left hand counter again if the new left hand item doesn't need it
	if !WC.itemRequiresCounter(0) && !WC.isWeaponPoisoned(0, WC.aiCurrentQueuePosition[0], true)
		WC.setCounterVisibility(0, false)
	;Otherwise update the counter for the new left hand item
	else
		if WC.itemRequiresCounter(0)
			WC.setSlotCount(0, PlayerRef.GetItemCount(jMap.getForm(leftPreselectObject, "Form")))
		elseif WC.isWeaponPoisoned(0, WC.aiCurrentQueuePosition[0], true)
			WC.checkAndUpdatePoisonInfo(0)
		endIf
	endIf
	WC.CM.checkAndUpdateChargeMeter(0)
endFunction

event onAmmoModeAnimationComplete(string sEventName, string sStringArg, Float fNumArg, Form kSender)
	debug.trace("iEquip_AmmoMode onAmmoModeAnimationComplete called")
	If(sEventName == "iEquip_AmmoModeAnimationComplete")
		PM.bWaitingForAmmoModeAnimation = false
		Self.UnregisterForModEvent("iEquip_AmmoModeAnimationComplete")
	endIf
endEvent

function cycleAmmo(bool reverse, bool ignoreEquipOnPause = false)
	debug.trace("iEquip_AmmoMode cycleAmmo called")
	int queueLength = jArray.count(aiTargetQ[Q])
	int targetIndex
	;No need for any checking here at all, we're just cycling ammo so just cycle and equip
	if reverse
		targetIndex = aiCurrentAmmoIndex[Q] - 1
		if targetIndex < 0
			targetIndex = queueLength - 1
		endIf
	else
		targetIndex = aiCurrentAmmoIndex[Q] + 1
		if targetIndex == queueLength
			targetIndex = 0
		endIf
	endIf
	if targetIndex != aiCurrentAmmoIndex[Q]
		aiCurrentAmmoIndex[Q] = targetIndex
		checkAndEquipAmmo(reverse, ignoreEquipOnPause)
	endIf
endFunction

function selectBestAmmo(int thisQ)
	debug.trace("iEquip_AmmoMode selectBestAmmo called")
	aiCurrentAmmoIndex[thisQ] = 0
	asCurrentAmmo[thisQ] = jMap.getStr(jArray.getObj(aiTargetQ[thisQ], 0), "Name")
	if bAmmoMode
		checkAndEquipAmmo(false, true)
	endIf
endFunction

function selectLastUsedAmmo(int thisQ)
	debug.trace("iEquip_AmmoMode selectLastUsedAmmo called")
	int i = 0
	bool found = false
	if asCurrentAmmo[thisQ] != ""
		while i < jArray.count(aiTargetQ[thisQ]) && !found
			if asCurrentAmmo[thisQ] != jMap.getStr(jArray.getObj(aiTargetQ[thisQ], i), "Name")
				i += 1
			else
				found = true
			endIf
		endwhile
	endIf
	;if the last used ammo isn't found in the newly sorted queue then set the queue position to 0 and update the name ready for updateWidget
	if !found
		aiCurrentAmmoIndex[thisQ] = 0
		asCurrentAmmo[thisQ] = jMap.getStr(jArray.getObj(aiTargetQ[thisQ], 0), "Name")
	;if the last used ammo is found in the newly sorted queue then set the queue position to the index where it was found
	else
		aiCurrentAmmoIndex[thisQ] = i
	endIf
endFunction

function checkAndEquipAmmo(bool reverse, bool ignoreEquipOnPause, bool animate = true, bool equip = true)
	debug.trace("iEquip_AmmoMode checkAndEquipAmmo called - reverse: " + reverse + ", ignoreEquipOnPause: " + ignoreEquipOnPause + ", animate: " + animate)
	currentAmmoForm = jMap.getForm(jArray.getObj(aiTargetQ[Q], aiCurrentAmmoIndex[Q]), "Form")
	int ammoCount = PlayerRef.GetItemCount(currentAmmoForm)
	;Check we've still got the at least one of the target ammo, if not remove it from the queue and advance the queue again
	if ammoCount < 1
		removeAmmoFromQueue(Q, aiCurrentAmmoIndex[Q])
		cycleAmmo(reverse, ignoreEquipOnPause)
	;Otherwise update the widget and either register for the EquipOnPause update or equip immediately
	else
		if animate
			int ammoObject = jArray.getObj(aiTargetQ[Q], aiCurrentAmmoIndex[Q])
			asCurrentAmmo[Q] = jMap.getStr(ammoObject, "Name")

			float fNameAlpha = WC.afWidget_A[8]
			if fNameAlpha < 1
				fNameAlpha = 100
			endIf
			;Update the widget
			int iHandle = UICallback.Create(HUD_MENU, WidgetRoot + ".updateWidget")
			If(iHandle)
				UICallback.PushInt(iHandle, 0) ;Left hand widget
				UICallback.PushString(iHandle, jMap.getStr(ammoObject, "Icon") + sAmmoIconSuffix) ;New icon
				UICallback.PushString(iHandle, asCurrentAmmo[Q]) ;New name
				UICallback.PushFloat(iHandle, fNameAlpha) ;Current item name alpha value
				UICallback.Send(iHandle)
			endIf
			;Update the left hand counter
			setSlotCount(ammoCount)
			if !WC.abIsCounterShown[0]
				WC.setCounterVisibility(0, true)
			endIf
			if WC.bNameFadeoutEnabled && !WC.abIsNameShown[0] ;Left Name
				WC.showName(0)
			endIf
		endIf
		;Equip the ammo
		if equip
			if !ignoreEquipOnPause && WC.bEquipOnPause
				WC.LHUpdate.registerForEquipOnPauseUpdate(Reverse, true)
			else
				debug.trace("iEquip_AmmoMode checkAndEquipAmmo - about to equip " + asCurrentAmmo[Q])
				PlayerRef.EquipItemEx(currentAmmoForm as Ammo)
			endIf
		endIf
	endIf
endFunction

function removeAmmoFromQueue(int isBolt, int i)
	debug.trace("iEquip_AmmoMode removeItemFromQueue called")
	iEquip_AmmoItemsFLST.RemoveAddedForm(jMap.getForm(jArray.getObj(aiTargetQ[isBolt], i), "Form"))
	EH.updateEventFilter(iEquip_AmmoItemsFLST)
	jArray.eraseIndex(aiTargetQ[isBolt], i)
	if aiCurrentAmmoIndex[isBolt] > i ;if the item being removed is before the currently equipped item in the queue update the index for the currently equipped item
		aiCurrentAmmoIndex[isBolt] = aiCurrentAmmoIndex[isBolt] - 1
	elseif aiCurrentAmmoIndex[isBolt] == i ;if you have removed the currently equipped item then if it was the last in the queue advance to index 0 and cycle the slot
		if aiCurrentAmmoIndex[isBolt] == jArray.count(aiTargetQ[isBolt])
			aiCurrentAmmoIndex[isBolt] = 0
		endIf
	endIf
endFunction

function setSlotCount(int count)
	debug.trace("iEquip_AmmoMode setSlotCount called - count: " + count)
	int[] widgetData = new int[2]
	widgetData[0] = 0
	widgetData[1] = count
	UI.invokeIntA(HUD_MENU, WidgetRoot + ".updateCounter", widgetData)
endFunction

bool function switchingRangedWeaponType(int itemType)
	return Q != ((itemType == 9) as int)
endFunction

function equipAmmo()
	debug.trace("iEquip_AmmoMode equipAmmo called")
	PlayerRef.EquipItemEx(currentAmmoForm as Ammo)
endFunction

function onBoundRangedWeaponEquipped(int weaponType)
	Q = (weaponType == 9) as int
	int i = 100 ;Max wait while is 1 sec
	while !bBoundAmmoAdded && i > 0
		Utility.Wait(0.01)
		i -= 1
	endWhile
	debug.trace("iEquip_WidgetCore onBoundWeaponEquipped - bBoundAmmoAdded: " + bBoundAmmoAdded + ", breakout count: " + (100 - i)) 
	;If the bound ammo has not been detected and added to the queue we just need to assume it's there and add a dummy to the queue so it can be displayed in the widget
	if !bBoundAmmoAdded
		int boundAmmoObj = jMap.object()
		jMap.setStr(boundAmmoObj, "Icon", asBoundAmmoIcons[Q])
		jMap.setStr(boundAmmoObj, "Name", asBoundAmmoNames[Q])
		jArray.addObj(aiTargetQ[Q], boundAmmoObj)
		;Set the current queue position and name to the last index (ie the newly added bound ammo)
		aiCurrentAmmoIndex[Q] = jArray.count(aiTargetQ[Q]) - 1
		asCurrentAmmo[Q] = asBoundAmmoNames[Q]
		bBoundAmmoAdded = true
	endIf
	toggleAmmoMode()
endFunction

function addBoundAmmoToQueue(form boundAmmo, string ammoName)
	debug.trace("iEquip_AmmoMode addBoundAmmoToQueue called - ammoName: " + ammoName)
	Q = (boundAmmo as ammo).isBolt() as int
	;If we've already added a dummy object to the ammo queue we only need to add the form
	int targetObject = jArray.getObj(aiTargetQ[Q], jArray.count(aiTargetQ[Q]) - 1)
	currentAmmoForm = boundAmmo
	if stringutil.Find(jMap.getStr(targetObject, "Name"), "bound", 0) > -1
		;debug.trace("iEquip_AmmoMode addBoundAmmoToQueue - adding Form to dummy object")
		jMap.setForm(targetObject, "Form", boundAmmo)
	;Otherwise create a new jMap object for the ammo and add it to the relevant ammo queue
	else
		;debug.trace("iEquip_AmmoMode addBoundAmmoToQueue - adding new bound ammo object")
		int boundAmmoObj = jMap.object()
		jMap.setForm(boundAmmoObj, "Form", boundAmmo)
		jMap.setStr(boundAmmoObj, "Icon", asBoundAmmoIcons[Q])
		jMap.setStr(boundAmmoObj, "Name", ammoName)
		;Set the current queue position and name to the last index (ie the newly added bound ammo)
		jArray.addObj(aiTargetQ[Q], boundAmmoObj)
		aiCurrentAmmoIndex[Q] = jArray.count(aiTargetQ[Q]) - 1 ;We've just added a new object to the queue so this is correct
		asCurrentAmmo[Q] = ammoName
		bBoundAmmoAdded = true
		abBoundAmmoInQueue[Q] = true
	endIf
endFunction

function checkAndRemoveBoundAmmo(int weaponType)
	debug.trace("iEquip_AmmoMode checkAndRemoveBoundAmmo called")
	Q = (weaponType == 9) as int
	int targetIndex = jArray.count(aiTargetQ[Q]) - 1
	if iEquip_AmmoExt.IsAmmoBound(jMap.getForm(jArray.getObj(aiTargetQ[Q], targetIndex), "Form") as ammo)
		jArray.eraseIndex(aiTargetQ[Q], targetIndex)
		if iAmmoListSorting == 2 || iAmmoListSorting == 4
			selectLastUsedAmmo(Q)
		else
			selectBestAmmo(Q)
		endIf
	endIf
	abBoundAmmoInQueue[Q] = false
endFunction

;Functions previously in AmmoScript

function updateAmmoLists()
	debug.trace("iEquip_AmmoMode updateAmmoList() called")
	int i
	int aB = 0
	int count
	form ammoForm
	while aB < 2
		;First check if anything needs to be removed from either queue
		count = jArray.count(aiTargetQ[aB])
		if iAmmoListSorting == 3
			jArray.clear(aiTargetQ[aB])
			iEquip_AmmoItemsFLST.Revert()
			EH.updateEventFilter(iEquip_AmmoItemsFLST)
		else
			i = 0
			while i < count && count > 0
				ammoForm = jMap.getForm(jArray.getObj(aiTargetQ[aB], i), "Form")
				if !ammoForm || PlayerRef.GetItemCount(ammoForm) < 1
					iEquip_AmmoItemsFLST.RemoveAddedForm(ammoForm)
					EH.updateEventFilter(iEquip_AmmoItemsFLST)
					jArray.eraseIndex(aiTargetQ[aB], i)
					count -= 1
					i -= 1
				endIf
				i += 1
			endWhile
		endIf
		aB += 1
	endWhile
	;Scan player inventory for all ammo and add it if not already found in the queue
	count = GetNumItemsOfType(PlayerRef, 42)
	debug.trace("iEquip_AmmoMode updateAmmoList() - Number of ammo types found in inventory: " + count)
	i = 0
	String AmmoName
	int isBolt
	while i < count && count > 0
		ammoForm = GetNthFormOfType(PlayerRef, 42, i)
		isBolt = (ammoForm as Ammo).isBolt() as int
		AmmoName = ammoForm.GetName()
		;The Javelin check is to get the Spears by Soolie javelins which are classed as arrows/bolts and all of which have more descriptive names than simply Javelin, which is from Throwing Weapons and is an equippable throwing weapon
		if stringutil.Find(AmmoName, "arrow", 0) > -1 || stringutil.Find(AmmoName, "bolt", 0) > -1 || iEquip_AmmoExt.IsAmmoJavelin(ammoForm as ammo)
			;Make sure we're only adding arrows to the arrow queue or bolts to the bolt queue
			if !isAlreadyInAmmoQueue(ammoForm, aiTargetQ[isBolt])
				AddToAmmoQueue(ammoForm, AmmoName, isBolt)
				abNeedsSorting[isBolt as int] = true
			endIf
		endIf
		i += 1
	endWhile
	if iAmmoListSorting == 3 || (!iAmmoListSorting == 0 && (abNeedsSorting[0] || abNeedsSorting[1] || iAmmoListSorting != ilastSortType)) ;iAmmoListSorting == 0 is Unsorted
		sortAmmoLists()
	endIf
	iLastSortType = iAmmoListSorting	
endFunction

function sortAmmoLists()
	debug.trace("iEquip_AmmoMode sortAmmoLists called")
	int i = 0
	while i < 2
		if abNeedsSorting[i]
			if iAmmoListSorting == 1 ;By damage, highest first
				sortAmmoQueue("Damage", aiTargetQ[i], i)
			elseIf iAmmoListSorting == 2 ;By name alphabetically
				sortAmmoQueueByName(aiTargetQ[i], i)
			elseIf iAmmoListSorting == 3 ;By quantity, most first
				sortAmmoQueue("Count", aiTargetQ[i], i)
			endIf
			abNeedsSorting[i] = false
		endIf
		i += 1
	endWhile
endFunction

function updateAmmoListsOnSettingChange()
	debug.trace("iEquip_AmmoMode updateAmmoListsOnSettingChange called")
	int i = 0
	bool[] boundAmmoRemoved = new bool[2]
	boundAmmoRemoved[0] = false
	boundAmmoRemoved[1] = false
	int tempBoundAmmoObj
	while i < 2
		;First we need to check if we currently have Bound Ammo in the queue - if we do store it and remove it from the queue
		int queueLength = jArray.count(aiTargetQ[i])
		int targetObject = jArray.getObj(aiTargetQ[i], queueLength - 1)
		if iEquip_AmmoExt.IsAmmoBound(jMap.getForm(targetObject, "Form") as ammo)
			tempBoundAmmoObj = targetObject
			jArray.eraseIndex(aiTargetQ[i], queueLength - 1)
			boundAmmoRemoved[i] = true
		endIf
		i += 1
	endWhile
	;Now prepare the ammo queues with the new sorting option
	updateAmmoLists()
	;And if we previously set aside bound ammo we can now re-add it to the end of the queue and reselect it
	i = 0
	while i < 2
		if boundAmmoRemoved[i]
			jArray.addObj(aiTargetQ[i], tempBoundAmmoObj)
			aiCurrentAmmoIndex[i] = jArray.count(aiTargetQ[i]) - 1
			asCurrentAmmo[i] = jMap.getStr(tempBoundAmmoObj, "Name")
		endIf
		i += 1
	endWhile
	if bAmmoMode
		checkAndEquipAmmo(false, false)
	endIf
endFunction

bool function isAlreadyInAmmoQueue(form itemForm, int targetQ)
	debug.trace("iEquip_AmmoWidget isAlreadyInQueue() called - itemForm: " + itemForm)
	bool found = false
	int i = 0
	while i < JArray.count(targetQ) && !found
		found = (itemform == jMap.getForm(jArray.getObj(targetQ, i), "Form"))
		i += 1
	endWhile
	debug.trace("iEquip_AmmoWidget isAlreadyInQueue() - returning found: " + found)
	return found
endFunction

function AddToAmmoQueue(form ammoForm, string ammoName, int isBolt)
	debug.trace("iEquip_AmmoMode AddToAmmoQueue() called")
	;Add to the formlist
	iEquip_AmmoItemsFLST.AddForm(ammoForm)
	EH.updateEventFilter(iEquip_AmmoItemsFLST)
	;Create the ammo object
	int AmmoItem = jMap.object()
	jMap.setForm(AmmoItem, "Form", ammoForm)
	jMap.setStr(AmmoItem, "Icon", getAmmoIcon(AmmoName, isBolt))
	jMap.setStr(AmmoItem, "Name", AmmoName)
	jMap.setFlt(AmmoItem, "Damage", (ammoForm as ammo).GetDamage())
	jMap.setInt(AmmoItem, "Count", PlayerRef.GetItemCount(AmmoForm))
	;Add it to the relevant ammo queue
	jArray.addObj(aiTargetQ[isBolt], AmmoItem)
	debug.trace("iEquip_AmmoMode AddToAmmoQueue() finished")
endFunction

String function getAmmoIcon(string AmmoName, int isBolt)
	debug.trace("iEquip_AmmoMode getAmmoIcon() called - AmmoName: " + AmmoName)
	String iconName
	if stringutil.Find(AmmoName, "spear", 0) > -1 || stringutil.Find(AmmoName, "javelin", 0) > -1
		iconName = "Spear"
	else
		;Set base icon string
		iconName = asAmmoIcons[isBolt]
		;Check if it is likely to have an additional effect - bit hacky checking the name but I've no idea how to check for attached magic effects!
		if stringutil.Find(AmmoName, "fire", 0) > -1 || stringutil.Find(AmmoName, "torch", 0) > -1 || stringutil.Find(AmmoName, "burn", 0) > -1 || stringutil.Find(AmmoName, "incendiary", 0) > -1
			iconName += "Fire"
		elseIf stringutil.Find(AmmoName, "frost", 0) > -1 || stringutil.Find(AmmoName, "ice", 0) > -1 || stringutil.Find(AmmoName, "freez", 0) > -1 || stringutil.Find(AmmoName, "cold", 0) > -1
			iconName += "Ice"
		elseIf stringutil.Find(AmmoName, "shock", 0) > -1 || stringutil.Find(AmmoName, "spark", 0) > -1 || stringutil.Find(AmmoName, "electr", 0) > -1
			iconName += "Shock"
		elseIf stringutil.Find(AmmoName, "poison", 0) > -1
			iconName += "Poison"
		endIf
	endIf
	debug.trace("iEquip_AmmoMode getAmmoIcon() returning iconName: " + iconName)
	return iconName
endFunction

function sortAmmoQueueByName(int targetQ, int thisQ)
	debug.trace("iEquip_AmmoMode sortAmmoQueueByName() called")
	int queueLength = jArray.count(targetQ)
	int tempAmmoQ = jArray.objectWithSize(queueLength)
	int i = 0
	string ammoName
	while i < queueLength
		ammoName = jMap.getStr(jArray.getObj(targetQ, i), "Name")
		jArray.setStr(tempAmmoQ, i, ammoName)
		i += 1
	endWhile
	jArray.sort(tempAmmoQ)
	i = 0
	int iIndex
	bool found
	while i < queueLength
		ammoName = jArray.getStr(tempAmmoQ, i)
		iIndex = 0
		found = false
		while iIndex < queueLength && !found
			if ammoName != jMap.getStr(jArray.getObj(targetQ, iIndex), "Name")
				iIndex += 1
			else
				found = true
			endIf
		endWhile
		if i != iIndex
			jArray.swapItems(targetQ, i, iIndex)
		endIf
		i += 1
	endWhile
	;/i = 0
    while i < queueLength
        debug.trace("iEquip_AmmoMode - sortAmmoQueueByName, sorted order: " + i + ", " + jMap.getForm(jArray.getObj(targetQ, i), "Form").GetName())
        i += 1
    endWhile/;
	selectLastUsedAmmo(thisQ)
endFunction

function sortAmmoQueue(string theKey, int targetQ, int thisQ)
    debug.trace("iEquip_AmmoMode sortAmmoQueue called - Sort by: " + theKey)
    int n = jArray.count(targetQ)
    int i
    While (n > 1)
        i = 1
        n -= 1
        While (i <= n)
            Int j = i 
            int k = (j - 1) / 2
            While (jMap.getFlt(jArray.getObj(targetQ, j), theKey) < jMap.getFlt(jArray.getObj(targetQ, k), theKey))
                jArray.swapItems(targetQ, j, k)
                j = k
                k = (j - 1) / 2
            EndWhile
            i += 1
        EndWhile
        jArray.swapItems(targetQ, 0, n)
    EndWhile
    i = 0
    while i < n
        debug.trace("iEquip_AmmoMode - sortAmmoQueue, sorted order: " + i + ", " + jMap.getForm(jArray.getObj(targetQ, i), "Form").GetName() + ", " + theKey + ": " + jMap.getFlt(jArray.getObj(targetQ, i), theKey))
        i += 1
    endWhile
    selectBestAmmo(thisQ)
EndFunction
