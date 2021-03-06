ScriptName iEquip_KeyHandler extends Quest
;This script sets up and handles all the key assignments and keypress actions

import Input
Import UI

iEquip_EditMode Property EM Auto
iEquip_WidgetCore Property WC Auto
iEquip_AmmoMode Property AM Auto
iEquip_ProMode Property PM Auto
iEquip_MCM Property MCM Auto
iEquip_RechargeScript Property RC Auto
iEquip_HelpMenu Property HM Auto

Actor Property PlayerRef  Auto
Message Property iEquip_UtilityMenu Auto

;Main gameplay keys
Int Property iShoutKey = 21 Auto Hidden ;Y
Int Property iLeftKey = 34 Auto Hidden ;G
Int Property iRightKey = 35 Auto Hidden ;H
Int Property iConsumableKey = 48 Auto Hidden ;B
Int Property iUtilityKey = 29 Auto Hidden ;Left Ctrl - Active in all modes

;Optional hotkeys
Int Property iOptConsumeKey = -1 Auto Hidden
Int Property iOptDirQueueKey = -1 Auto Hidden

;Edit Mode Keys
Int Property iEditNextKey = 55 Auto Hidden ;Num *
Int Property iEditPrevKey = 181 Auto Hidden ;Num /
Int Property iEditUpKey = 200 Auto Hidden ;Up arrow
Int Property iEditDownKey = 208 Auto Hidden ;Down arrow
Int Property iEditRightKey = 205 Auto Hidden ;Right arrow
Int Property iEditLeftKey = 203 Auto Hidden ;Left arrow
Int Property iEditScaleUpKey = 78 Auto Hidden ;Num +
Int Property iEditScaleDownKey = 74 Auto Hidden ;Num -
Int Property iEditDepthKey  = 72 Auto Hidden ;Num 8
Int Property iEditRotateKey  = 79 Auto Hidden ;Num 1
Int Property iEditTextKey = 80 Auto Hidden ;Num 2
Int Property iEditAlphaKey = 81 Auto Hidden ;Num 3
Int Property iEditRulersKey = 75 Auto Hidden ;Num 4
Int Property iEditResetKey = 82 Auto Hidden ;Num 0
Int Property iEditLoadPresetKey = 76 Auto Hidden ;Num 5
Int Property iEditSavePresetKey = 77 Auto Hidden ;Num 6
Int Property iEditDiscardKey = 83 Auto Hidden ;Num .

; Delays
float Property fMultiTapDelay = 0.3 Auto Hidden
float Property fLongPressDelay = 0.5 Auto Hidden
float Property fPressAndHoldDelay = 1.0 Auto Hidden

; Bools
bool Property bAllowKeyPress = true Auto Hidden
bool Property bNormalSystemPageBehav = true Auto Hidden
bool bIsUtilityKeyHeld = false
bool bIsQueueMenuComboKeyKeyHeld = false
bool bNotInLootMenu = true

; Ints
int Property iUtilityKeyDoublePress = 0 Auto Hidden
Int iWaitingKeyCode = 0
Int iMultiTap = 0

; MCM settings
bool property bConsumeItemHotkeyEnabled = false auto hidden
bool property bQueueMenuComboKeyEnabled = false auto hidden
bool property bPreselectEnabled = false auto hidden
bool property bQuickShieldEnabled = false auto hidden
bool property bQuickRangedEnabled = false auto hidden
bool property bQuickHealEnabled = false auto hidden

; Strings
string sPreviousState = ""

; ------------------
; - GENERAL EVENTS -
; ------------------

function GameLoaded()
	GotoState("")
    
	self.RegisterForMenu("InventoryMenu")
	self.RegisterForMenu("MagicMenu")
	self.RegisterForMenu("FavoritesMenu")
	self.RegisterForMenu("Journal Menu")
	self.RegisterForMenu("LootMenu")
    
	UnregisterForAllKeys() ;Re-enabled by onWidgetLoad once widget is ready to prevent any wierdness with keys being pressed before the widget has refreshed
    
	bIsUtilityKeyHeld = false
    bNotInLootMenu = true
endFunction

event OnMenuOpen(string MenuName)
	if MenuName == "LootMenu"
        bNotInLootMenu = false
    else
        sPreviousState = GetState()
        GotoState("INVENTORYMENU")
        
        UnregisterForUpdate()
        iWaitingKeyCode = 0
        iMultiTap = 0
        
        RegisterForGameplayKeys()
	endIf
endEvent

event OnMenuClose(string MenuName)
    if MenuName == "LootMenu"
        bNotInLootMenu = true
    else     
        GotoState(sPreviousState)
    endIf
endEvent

event OnUpdate()
	debug.trace("iEquip KeyHandler OnUpdate called multiTap: "+iMultiTap)
    bAllowKeyPress = false
    
    runUpdate()
    
    iMultiTap = 0
    iWaitingKeyCode = 0
    bAllowKeyPress = true
endEvent

; ---------------------
; - DEFAULT BEHAVIOUR -
; ---------------------

event OnKeyDown(int KeyCode)
    
    if KeyCode == iUtilityKey && !bIsQueueMenuComboKeyKeyHeld
        bIsUtilityKeyHeld = true
    elseIf KeyCode == iOptDirQueueKey && bQueueMenuComboKeyEnabled && !bIsUtilityKeyHeld
        bIsQueueMenuComboKeyKeyHeld = true
        GoToState("QUEUEMENUCOMBOKEYHELD")
    endIf

    if bAllowKeyPress
        if KeyCode != iWaitingKeyCode && iWaitingKeyCode != 0 ;The player pressed a different key, so force the current one to process if there is one
            UnregisterForUpdate()
            OnUpdate()
        endIf
        iWaitingKeyCode = KeyCode
    
        if iMultiTap == 0 ; This is fhte first time the key has been pressed
            RegisterForSingleUpdate(fPressAndHoldDelay)
        elseIf iMultiTap == 1 ;This is the second time the key has been pressed.
            iMultiTap = 2
            RegisterForSingleUpdate(fMultiTapDelay)
        elseIf iMultiTap == 2 ; This is the third time the key has been pressed
            iMultiTap = 3
            RegisterForSingleUpdate(0.0)
        endIf
    endif
endEvent

event OnKeyUp(Int KeyCode, Float HoldTime)
    if KeyCode == iUtilityKey
        bIsUtilityKeyHeld = false
    elseIf KeyCode == iOptDirQueueKey
        bIsQueueMenuComboKeyKeyHeld = false
    endIf

    if bAllowKeyPress
        if KeyCode == iWaitingKeyCode && iMultiTap == 0
            float updateTime = 0.0
        
            if HoldTime >= fLongPressDelay ;If longpress.
                iMultiTap = -1
            else ; Turns out the key is a multiTap
                iMultiTap = 1
                updateTime = fMultiTapDelay
            endIf
            
            RegisterForSingleUpdate(updateTime)
        endIf
    endIf
endEvent

function runUpdate()
    ;Handle widget visibility update on any registered key press
    WC.updateWidgetVisibility()

    if iMultiTap == -1   ; Longpress
        if iWaitingKeyCode == iConsumableKey
            if bNotInLootMenu && WC.bConsumablesEnabled && !bConsumeItemHotkeyEnabled
                WC.consumeItem()
            endIf
            
        elseIf PM.bPreselectMode
            if iWaitingKeyCode == iLeftKey
                PM.equipPreselectedItem(0) 
            elseIf iWaitingKeyCode == iRightKey
                PM.equipPreselectedItem(1)
            elseIf iWaitingKeyCode == iShoutKey
                if bNotInLootMenu && PM.bShoutPreselectEnabled && WC.bShoutEnabled
                    PM.equipPreselectedItem(2)
                endIf
            endIf
            
        elseIf iWaitingKeyCode == iLeftKey
            if AM.bAmmoMode 
                AM.toggleAmmoMode(false, false)
            else
                RC.rechargeWeapon(0)
            endIf
        elseIf iWaitingKeyCode == iRightKey
            RC.rechargeWeapon(1)
        endIf
        
    elseIf iMultiTap == 0  ; LongpressHold
        if PM.bPreselectMode && (iWaitingKeyCode == iLeftKey ||  iRightKey)
            PM.equipAllPreselectedItems()
        endIf
        
    elseIf iMultiTap == 1  ; Single tap
        If iWaitingKeyCode == iLeftKey
            int RHItemType = PlayerRef.GetEquippedItemType(1)
            if AM.bAmmoMode || (PM.bPreselectMode && (RHItemType == 7 || RHItemType == 12))
                AM.cycleAmmo(bIsUtilityKeyHeld)
            else
                WC.cycleSlot(0, bIsUtilityKeyHeld)
            endIf

        elseIf iWaitingKeyCode == iRightKey
            WC.cycleSlot(1, bIsUtilityKeyHeld)

        elseIf iWaitingKeyCode == iShoutKey
            if bNotInLootMenu && WC.bShoutEnabled
                WC.cycleSlot(2, bIsUtilityKeyHeld)
            endIf
                
        elseIf iWaitingKeyCode == iConsumableKey
            if bNotInLootMenu
                if WC.bConsumablesEnabled
                    WC.cycleSlot(3, bIsUtilityKeyHeld)
                elseIf WC.bPoisonsEnabled
                    WC.cycleSlot(4, bIsUtilityKeyHeld)
                endIf
            endIf

        elseIf iWaitingKeyCode == iOptConsumeKey 
            if bConsumeItemHotkeyEnabled && bNotInLootMenu && WC.bConsumablesEnabled
                WC.consumeItem()
            endIf

        elseIf iWaitingKeyCode == iUtilityKey
            ;0 = Exit, 1 = Queue Menu, 2 = Edit Mode, 3 = MCM, 4 = Refresh Widget
            int iAction = iEquip_UtilityMenu.Show() 
            
            if iAction != 0 ;Exit
                if iAction == 1
                    WC.openQueueManagerMenu()
                elseif iAction == 2
                    toggleEditMode()
                elseif iAction == 3
                    openiEquipMCM()
                elseif iAction == 4
                    ;HM.openHelpMenu()
                    debug.MessageBox("This feature is currently disabled")
                elseif iAction == 5
                    ;WC.refreshWidget()
                    debug.MessageBox("This feature is currently disabled")
                endIf
            endIf
        endIf
        
    elseIf iMultiTap == 2  ; Double tap
        If iWaitingKeyCode == iUtilityKey
            if iUtilityKeyDoublePress == 1
                WC.openQueueManagerMenu()
            elseIf iUtilityKeyDoublePress == 2
                toggleEditMode()
            elseIf iUtilityKeyDoublePress == 3
                openiEquipMCM()
            endIf
        elseIf iWaitingKeyCode == iConsumableKey
            if bNotInLootMenu && WC.bConsumablesEnabled && WC.bPoisonsEnabled
                WC.cycleSlot(4, bIsUtilityKeyHeld)
            endIf
        elseIf iWaitingKeyCode == iLeftKey
            int RHItemType = PlayerRef.GetEquippedItemType(1)
            
            if AM.bAmmoMode || (PM.bPreselectMode && (RHItemType == 7 || RHItemType == 12))
                WC.cycleSlot(0, bIsUtilityKeyHeld)
            elseIf WC.bPoisonsEnabled
                WC.applyPoison(0)
            endIf
        elseIf iWaitingKeyCode == iRightKey && WC.bPoisonsEnabled
            WC.applyPoison(1)
        endIf
        
    elseIf WC.bProModeEnabled && iMultiTap == 3  ;Triple tap
        if iWaitingKeyCode == iShoutKey && bPreselectEnabled && bNotInLootMenu
            PM.togglePreselectMode()
        elseIf iWaitingKeyCode == iLeftKey && bQuickShieldEnabled
            PM.quickShield()
        elseIf iWaitingKeyCode == iRightKey && bQuickRangedEnabled
            PM.quickRanged()
        elseIf iWaitingKeyCode == iConsumableKey && bQuickHealEnabled && bNotInLootMenu
            PM.quickHeal()
        endIf
    endIf
endFunction

; --------------------
; - OTHER BEHAVIOURS -
; --------------------

; - Inventory
state INVENTORYMENU
	event OnKeyDown(int KeyCode)
        if KeyCode == iUtilityKey
            bIsUtilityKeyHeld = true
        endIf
     
        if bAllowKeyPress
            bAllowKeyPress = false
        
            if KeyCode == iLeftKey
                WC.AddToQueue(0)
            elseIf KeyCode == iRightKey
                WC.AddToQueue(1)
            elseIf KeyCode == iShoutKey
                WC.AddToQueue(2)
            elseIf KeyCode == iConsumableKey
                WC.AddToQueue(3)		
            endIf
            
            bAllowKeyPress = true
        endIf
	endEvent
endState

; - Editmode
state EDITMODE
    event OnKeyUp(Int KeyCode, Float HoldTime)
        if bAllowKeyPress
            if KeyCode == iWaitingKeyCode && iMultiTap == 0
                float updateTime = 0.0
            
                if HoldTime >= fLongPressDelay ;If longpress.
                    iMultiTap = -1
                else ; Turns out the key is a multiTap
                    iMultiTap = 1
                    
                    If (KeyCode == iEditRotateKey || KeyCode == iEditRulersKey)
                        updateTime = fMultiTapDelay
                    endIf
                endIf
                
                RegisterForSingleUpdate(updateTime)
            endIf
        endIf
    endEvent

    function runUpdate()
        if iMultiTap == 0   ; Press and hold
            if iWaitingKeyCode == iEditNextKey || iWaitingKeyCode == iEditPrevKey
                EM.ToggleCycleRange()
            elseIf iWaitingKeyCode == iEditAlphaKey
                EM.IncrementStep(2)
            elseIf iWaitingKeyCode == iEditRotateKey
                EM.IncrementStep(1)
            elseIf (iWaitingKeyCode == iEditLeftKey || iWaitingKeyCode == iEditRightKey || iWaitingKeyCode == iEditUpKey ||\
                    iWaitingKeyCode == iEditDownKey || iWaitingKeyCode == iEditScaleUpKey || iWaitingKeyCode == iEditScaleDownKey)
                EM.IncrementStep(0)
            elseIf iWaitingKeyCode == iEditTextKey
                EM.ShowColorSelection(2) ;Text color
            elseIf iWaitingKeyCode == iEditRulersKey
                EM.ShowColorSelection(0) ;Highlight color
            endIf
            
        elseIf iMultiTap == 1  ;Single tap
            if iWaitingKeyCode == iEditUpKey
                EM.MoveElement(0)
            elseIf iWaitingKeyCode == iEditDownKey
                EM.MoveElement(1)
            elseIf iWaitingKeyCode == iEditLeftKey
                EM.MoveElement(2)
            elseIf iWaitingKeyCode == iEditRightKey
                EM.MoveElement(3)
            elseIf iWaitingKeyCode == iEditScaleUpKey
                EM.ScaleElement(0)
            elseIf iWaitingKeyCode == iEditScaleDownKey
                EM.ScaleElement(1)
            elseIf iWaitingKeyCode == iEditRotateKey
                EM.RotateElement()
            elseIf iWaitingKeyCode == iEditAlphaKey
                EM.SetElementAlpha()
            elseIf iWaitingKeyCode == iEditDepthKey
                EM.SwapElementDepth()
            elseIf iWaitingKeyCode == iEditTextKey
                EM.ToggleTextAlignment()
            elseIf iWaitingKeyCode == iEditNextKey
                EM.CycleElements(1)
            elseIf iWaitingKeyCode == iEditPrevKey
                EM.CycleElements(-1)
            elseIf iWaitingKeyCode == iEditResetKey
                EM.ResetElement()
            elseIf iWaitingKeyCode == iEditLoadPresetKey
                EM.ShowPresetList()
            elseIf iWaitingKeyCode == iEditSavePresetKey
                EM.SavePreset()
            elseIf iWaitingKeyCode == iEditRulersKey
                EM.ToggleRulers()
            elseIf iWaitingKeyCode == iEditDiscardKey
                EM.DiscardChanges()
            elseIf iWaitingKeyCode == iUtilityKey
                ToggleEditMode()
            endIf
            
        elseIf iMultiTap == 2  ; Double tap
            if iWaitingKeyCode == iEditRotateKey
                EM.ToggleRotation()
            elseIf iWaitingKeyCode == iEditRulersKey
                EM.ShowColorSelection(1) ;Current item info color
            endIf
            
        endIf
    endFunction
endState

;Direct Queue Menu Combo Key Held
state QUEUEMENUCOMBOKEYHELD
    event OnKeyUp(Int KeyCode, Float HoldTime)
        debug.trace("iEquip_KeyHandler OnKeyUp called in QUEUEMENUCOMBOKEYHELD state")
        if KeyCode == iUtilityKey
            bIsUtilityKeyHeld = false
        elseIf KeyCode == iOptDirQueueKey
            bIsQueueMenuComboKeyKeyHeld = false
            Gotostate("")
        endIf

        if bAllowKeyPress
            if KeyCode == iWaitingKeyCode && iMultiTap == 0
                iMultiTap = 1                
                RegisterForSingleUpdate(fMultiTapDelay)
            endIf
        endIf
    endEvent

    function runUpdate()
        debug.trace("iEquip_KeyHandler runUpdate called in QUEUEMENUCOMBOKEYHELD state - iMultiTap == " + iMultiTap)
        ;Handle widget visibility update on any registered key press
        WC.updateWidgetVisibility()
        if iMultiTap == 1  ;Single tap
            if iWaitingKeyCode == iLeftKey
                WC.openQueueManagerMenu(1)
            elseIf iWaitingKeyCode == iRightKey
                WC.openQueueManagerMenu(2)
            elseIf iWaitingKeyCode == iShoutKey
                WC.openQueueManagerMenu(3)
            elseIf iWaitingKeyCode == iConsumableKey
                WC.openQueueManagerMenu(4)
            endIf
            
        elseIf iMultiTap == 2  ; Double tap
            if iWaitingKeyCode == iConsumableKey
                WC.openQueueManagerMenu(5)
            endIf
            
        endIf
    endFunction
endState

; -----------------
; - MISCELLANEOUS -
; -----------------

function updateKeyMaps()
    UnregisterForAllKeys()

    if EM.isEditMode
        RegisterForEditModeKeys()
    else
        RegisterForGameplayKeys()
    endIf
endFunction

function ToggleEditMode()
	debug.trace("iEquip KeyHandler toggleEditMode called")
    UnregisterForAllKeys()

    if WC.bEditModeEnabled
    	if EM.isEditMode
            GoToState("")
    		RegisterForGameplayKeys()
    	else
            GoToState("EDITMODE")
    		RegisterForEditModeKeys()
            updateEditModeKeys()
    	endIf
        
    	EM.ToggleEditMode()
    else
        debug.Messagebox("Edit Mode is currently disabled in the MCM")
    endIf
endFunction

function resetEditModeKeys()
    iEditNextKey = 55
    iEditPrevKey = 181
    iEditUpKey = 200
    iEditDownKey = 208
    iEditLeftKey = 203
    iEditRightKey = 205
    iEditScaleUpKey = 78
    iEditScaleDownKey = 74
    iEditRotateKey = 80
    iEditAlphaKey = 81
    iEditDepthKey = 72
    iEditTextKey = 79
    iEditRulersKey = 77
    iEditResetKey = 82
    iEditLoadPresetKey = 75
    iEditSavePresetKey = 76
    iEditDiscardKey = 83
endFunction

function updateEditModeKeys()
    int[] keys = new int[18]

    keys[0] = iUtilityKey
    keys[1] = iEditPrevKey
    keys[2] = iEditNextKey
    keys[3] = iEditUpKey
    keys[4] = iEditDownKey
    keys[5] = iEditLeftKey
    keys[6] = iEditRightKey
    keys[7] = iEditScaleUpKey
    keys[8] = iEditScaleDownKey
    keys[9] = iEditRotateKey
    keys[10] = iEditAlphaKey
    keys[11] = iEditTextKey
    keys[12] = iEditDepthKey
    keys[13] = iEditRulersKey
    keys[14] = iEditResetKey
    keys[15] = iEditLoadPresetKey
    keys[16] = iEditSavePresetKey
    keys[17] = iEditDiscardKey
    
    InvokeIntA(WC.HUD_MENU, WC.WidgetRoot + ".setEditModeButtons", keys)
endFunction

function RegisterForGameplayKeys()
	debug.trace("iEquip KeyHandler RegisterForGameplayKeys called")
	RegisterForKey(iShoutKey)
	RegisterForKey(iLeftKey)
	RegisterForKey(iRightKey)
	RegisterForKey(iConsumableKey)
	RegisterForKey(iUtilityKey)
    if bConsumeItemHotkeyEnabled
        RegisterForKey(iOptConsumeKey)
    endIf
    if bQueueMenuComboKeyEnabled
        RegisterForKey(iOptDirQueueKey)
    endIf
endFunction

function RegisterForEditModeKeys()
	debug.trace("iEquip KeyHandler RegisterForEditModeKeys called")
	RegisterForKey(iEditLeftKey)
	RegisterForKey(iEditRightKey)
	RegisterForKey(iEditUpKey)
	RegisterForKey(iEditDownKey)
	RegisterForKey(iEditScaleUpKey)
	RegisterForKey(iEditScaleDownKey)
	RegisterForKey(iEditNextKey)
	RegisterForKey(iEditPrevKey)
	RegisterForKey(iEditResetKey)
	RegisterForKey(iEditLoadPresetKey)
	RegisterForKey(iEditSavePresetKey)
	RegisterForKey(iEditRotateKey)
	RegisterForKey(iEditDepthKey)
	RegisterForKey(iEditAlphaKey)
	RegisterForKey(iEditTextKey)
	RegisterForKey(iEditRulersKey)
	RegisterForKey(iEditDiscardKey)
	RegisterForKey(iUtilityKey)
endFunction

function openiEquipMCM(bool inMCMSelect = false)
    int key_j 
    int key_down
    int key_scroll
    int key_enter
    
    if Game.UsingGamepad()
        key_j = 270
        key_down = 267
        key_scroll = 280
        key_enter = 276
    else
        key_j = GetMappedKey("Journal")
        key_down = GetMappedKey("Back")
        key_scroll = 76
        key_enter = GetMappedKey("Activate")
    endIf
    
    if inMCMSelect
        TapKey(key_j)
        Utility.WaitMenuMode(0.3)
        TapKey(key_j)
        Utility.WaitMenuMode(0.3)
        TapKey(key_j)
        Utility.WaitMenuMode(0.005)
        TapKey(key_j)
        Utility.Wait(0.5)
    endIf
    
    if Game.IsMenuControlsEnabled() && !Utility.IsInMenuMode() && !IsTextInputEnabled() &&\
       !IsMenuOpen("Dialogue Menu") && !IsMenuOpen("Crafting Menu")
        float startTime = Utility.GetCurrentRealTime()
        float elapsedTime
        int i = 0
        
        while elapsedTime <= 2.5
            if IsMenuOpen("Journal Menu")
                if bNormalSystemPageBehav ; Compatibility with open system page mod 
                    TapKey(key_scroll)
                    Utility.WaitMenuMode(0.005)
                endIf
                
                while i < 3 ;Should take us to MCM Menu entry in the Settings List
                    TapKey(key_down)
                    Utility.WaitMenuMode(0.005)
                    i += 1
                EndWhile
                
                elapsedTime = 3.0
            else
                TapKey(key_j)
                Utility.WaitMenuMode(0.1)
                elapsedTime = Utility.GetCurrentRealTime() - startTime
            endIf
        endWhile
 
        if MCM.bIsFirstEnabled
            MCM.bEnabled = !MCM.bEnabled
            WC.bJustEnabled = true
            MCM.bIsFirstEnabled = false
        endIf
        
        if elapsedTime == 3.0
            TapKey(key_enter) 
            Utility.WaitMenuMode(0.005)
            
            i = 0
            while i < 128
                TapKey(key_down)
                Utility.WaitMenuMode(0.005)
                
                if GetString("Journal Menu", "_root.ConfigPanelFader.configPanel._modList.selectedEntry.text") == "iEquip"
                    TapKey(key_enter)
                    i = 128
                else
                    i += 1
                endIf
            endWhile
        endIf
    endIf
endFunction
