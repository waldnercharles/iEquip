Scriptname iEquip_MCM_htk extends iEquip_MCM_helperfuncs

iEquip_KeyHandler Property KH Auto

string[] utilityKeyDoublePressOptions
int mcmUnmapFLAG

; #############
; ### SETUP ###

function initData()
    mcmUnmapFLAG = MCM.OPTION_FLAG_WITH_UNMAP

    utilityKeyDoublePressOptions = new String[4]
    utilityKeyDoublePressOptions[0] = "Disabled"
    utilityKeyDoublePressOptions[1] = "Queue Menu"
    utilityKeyDoublePressOptions[2] = "Edit Mode"
    utilityKeyDoublePressOptions[3] = "MCM"
endFunction

function drawPage()
    MCM.AddTextOptionST("htk_txt_htkHelp", "Show hotkey help", "")
        
    MCM.AddEmptyOption()
    MCM.AddHeaderOption("Main Hotkeys")
    MCM.AddKeyMapOptionST("htk_key_leftHand", "Left Hand Hotkey", KH.iLeftKey, mcmUnmapFLAG)
    MCM.AddKeyMapOptionST("htk_key_rightHand", "Right Hand Hotkey", KH.iRightKey, mcmUnmapFLAG)
    MCM.AddKeyMapOptionST("htk_key_shout", "Shout Hotkey", KH.iShoutKey, mcmUnmapFLAG)
    MCM.AddKeyMapOptionST("htk_key_consumPoison", "Consumable/Poison Hotkey", KH.iConsumableKey, mcmUnmapFLAG)
            
    MCM.AddHeaderOption("Utility Hotkey Options")
    MCM.AddKeyMapOptionST("htk_key_util", "Utility Hotkey", KH.iUtilityKey, mcmUnmapFLAG)
    MCM.AddMenuOptionST("htk_men_utilDubPress", "Utility key double press", utilityKeyDoublePressOptions[KH.iUtilityKeyDoublePress])
    MCM.AddToggleOptionST("htk_tgl_utilCompat", "Quickmenu Compatibility", !KH.bNormalSystemPageBehav)

    MCM.SetCursorPosition(1)
            
    ;These are just so the right side lines up nicely with the left!
    MCM.AddEmptyOption()
    MCM.AddEmptyOption()
    
    MCM.AddHeaderOption("Key Press Options")
    MCM.AddSliderOptionST("htk_sld_multiTapDelay", "Multi-Tap Delay", KH.fMultiTapDelay, "{1} seconds")
    MCM.AddSliderOptionST("htk_sld_longPrsDelay", "Long Press Delay", KH.fLongPressDelay, "{1} seconds")
    MCM.AddSliderOptionST("htk_sld_prsHoldDelay", "Press & Hold Delay", KH.fPressAndHoldDelay, "{1} seconds")
    MCM.AddHeaderOption("Optional Additional Hotkeys")
    MCM.AddToggleOptionST("htk_tgl_optConsumeHotkey", "Enable consume item hotkey", KH.bConsumeItemHotkeyEnabled)
    if KH.bConsumeItemHotkeyEnabled
        MCM.AddKeyMapOptionST("htk_key_optional_consumeItem", "Consume item hotkey", KH.iOptConsumeKey, mcmUnmapFLAG)
    endIf
    MCM.AddToggleOptionST("htk_tgl_optDirectQueueHotkey", "Enable direct queue menu combo key", KH.bQueueMenuComboKeyEnabled)
    if KH.bQueueMenuComboKeyEnabled
        MCM.AddKeyMapOptionST("htk_key_optional_queueMenuCombo", "Direct queue menu combo key", KH.iOptDirQueueKey, mcmUnmapFLAG)
    endIf

endFunction

; ######################
; ### Hotkey Options ###
; ######################

State htk_txt_htkHelp
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Show a full description of what actions are available on each hotkey")
        elseIf currentEvent == "Select"
            bool bKeepReading
    
            if MCM.WC.bProModeEnabled
                bKeepReading = MCM.ShowMessage("Left/Right Hotkeys in Regular Mode\n\nSingle Press - Cycle queue forwards\nSingle Press with Utility Key held - Cycle queue backwards\n"+\
                                               "Double Press - Apply current poison\nTriple Press - Recharge enchanted item\nPress and hold - Enable Preselect Mode\n\n"+\
                                               "Left/Right Hotkeys in Preselect Mode\n\nSingle Press - Cycle preselect queue forwards\n"+\
                                               "Single Press with Utility Key held - Cycle preselect queue backwards\nLongpress - Equip preselected item\n"+\
                                               "Press and hold - Equip all preselected items\n\nPage 1/4",  true, "Next page", "Exit")
                if bKeepReading 
                    bKeepReading = MCM.ShowMessage("Shout Hotkey in Regular Mode\n\nSingle Press - Cycle queue forwards\nSingle Press with Utility Key held - Cycle queue backwards\nPress and hold - Open queue management menu\n\n"+\
                                                   "Shout Hotkey in Preselect Mode\n\nSingle Press - Cycle preselect queue forwards\nSingle Press with Utility Key held - Cycle preselect queue backwards\n"+\
                                                   "Longpress - Equip preselected shout/power\n\nPage 2/4",  true, "Next page", "Exit")
                    if bKeepReading
                        bKeepReading = MCM.ShowMessage("Consumable/Poison Hotkey\n\nSingle Press - Cycle consumable queue forwards\nSingle Press with Utility Key held - Cycle consumable queue backwards\n"+\
                                                       "Press and hold - Consume current potion/food/drink\n\nDouble Press - Cycle poison queue forwards\n"+\
                                                       "Double Press with Utility Key held - Cycle poison queue backwards\n\nConsumable/Poison Hotkey in Preselect Mode\n\n"+\
                                                       "Press and hold - Exit Preselect Mode\n\nPage 3/4", true, "Next page", "Exit")
                    endIf
                endIf
            else
                bKeepReading = MCM.ShowMessage("Left/Right Hotkeys in Regular Mode\n\nSingle Press - Cycle queue forwards\nSingle Press with Utility Key held - Cycle queue backwards\n"+\
                                               "Double Press - Apply current poison\nTriple Press - Recharge enchanted item\n\nPage 1/4",  true, "Next page", "Exit")
                if bKeepReading
                    bKeepReading = MCM.ShowMessage("Shout Hotkey in Regular Mode\n\nSingle Press - Cycle queue forwards\n"+\
                                                   "Single Press with Utility Key held - Cycle queue backwards\n\nPage 2/4",  true, "Next page", "Exit")
                    if bKeepReading
                        bKeepReading = MCM.ShowMessage("Consumable/Poison Hotkey\n\nSingle Press - Cycle consumable queue forwards\nSingle Press with Utility Key held - Cycle consumable queue backwards\n"+\
                                                       "Press and hold - Consume current potion/food/drink\n\nDouble Press - Cycle poison queue forwards\n"+\
                                                       "Double Press with Utility Key held - Cycle poison queue backwards\n\nPage 3/4", true, "Next page", "Exit")
                    endIf
                endIf
            endIf
            
            if bKeepReading
                if MCM.WC.bEditModeEnabled
                    MCM.ShowMessage("Utility Hotkey\n\nSingle Press - Open Queue Management Menu\n\nDouble Press - Toggle Edit Mode\n\n"+\
                                    "Triple Press - Direct access to the iEquip MCM\n\nPage 4/4", false, "Exit")
                else
                    MCM.ShowMessage("Utility Hotkey\n\nSingle Press - Open Queue Management Menu\n\n"+\
                                    "Triple Press - Direct access to the iEquip MCM\n\nPage 4/4", false, "Exit")
                endIf
            endIf 
        endIf
    endEvent
endState

; ----------------
; - Main Hotkeys -
; ----------------

State htk_key_leftHand
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Select a hotkey to control the left hand widget functions\nDefault: V")
        elseIf currentEvent == "Change"
            KH.iLeftKey = currentVar as int
            KH.updateKeyMaps()
            MCM.SetKeyMapOptionValueST(KH.iLeftKey)
        elseIf currentEvent == "Default"
            KH.iLeftKey = 47 
            MCM.SetKeyMapOptionValueST(KH.iLeftKey)
        endIf
    endEvent
endState

State htk_key_rightHand
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Select a hotkey to control the right hand widget functions\nDefault: B")
        elseIf currentEvent == "Change"
            KH.iRightKey = currentVar as int
            KH.updateKeyMaps()
            MCM.SetKeyMapOptionValueST(KH.iRightKey)
        elseIf currentEvent == "Default"
            KH.iRightKey = 48 
            MCM.SetKeyMapOptionValueST(KH.iRightKey)
        endIf
    endEvent
endState

State htk_key_shout
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Select a hotkey to control the shout widget functions\nDefault: Y")
        elseIf currentEvent == "Change"
            KH.iShoutKey = currentVar as int
            KH.updateKeyMaps()
            MCM.SetKeyMapOptionValueST(KH.iShoutKey)
        elseIf currentEvent == "Default"
            KH.iShoutKey = 45 
            MCM.SetKeyMapOptionValueST(KH.iShoutKey)
        endIf
    endEvent
endState

State htk_key_consumPoison
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Select a hotkey to control the consumable and poison widgets functions\nDefault: X")
        elseIf currentEvent == "Change"
            KH.iConsumableKey = currentVar as int
            KH.updateKeyMaps()
            MCM.SetKeyMapOptionValueST(KH.iConsumableKey)
        elseIf currentEvent == "Default"
            KH.iConsumableKey = 21
            MCM.SetKeyMapOptionValueST(KH.iConsumableKey)
        endIf
    endEvent
endState
        
; --------------------------
; - Utility Hotkey Options -
; --------------------------

State htk_key_util
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Select a hotkey for accessing various menus and modes\nDefault: NumLock")
        elseIf currentEvent == "Change"
            KH.iUtilityKey = currentVar as int
            KH.updateKeyMaps()
            MCM.SetKeyMapOptionValueST(KH.iUtilityKey)
        elseIf currentEvent == "Default"
            KH.iUtilityKey = 69
            MCM.SetKeyMapOptionValueST(KH.iUtilityKey)
        endIf
    endEvent
endState

State htk_men_utilDubPress
    event OnBeginState()
        if currentEvent == "Open"
            fillMenu(KH.iUtilityKeyDoublePress, utilityKeyDoublePressOptions, 0)
        elseIf currentEvent == "Accept"
            KH.iUtilityKeyDoublePress = currentVar as int
            MCM.SetMenuOptionValueST(utilityKeyDoublePressOptions[KH.iUtilityKeyDoublePress])
        endIf
    endEvent
endState

State htk_tgl_utilCompat
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Enable this if you have \"Stay at System Page\" installed\nDefault: Off")
        elseIf currentEvent == "Select"
            KH.bNormalSystemPageBehav = !KH.bNormalSystemPageBehav
            MCM.SetToggleOptionValueST(!KH.bNormalSystemPageBehav)
        elseIf currentEvent == "Default"
            KH.bNormalSystemPageBehav = true 
            MCM.SetToggleOptionValueST(!KH.bNormalSystemPageBehav)
        endIf
    endEvent
endState

; ---------------------
; - Key Press Options -
; ---------------------

State htk_sld_multiTapDelay
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("This defines the maximum delay there can be between key presses for them to register as a multi-tap (double/triple press)\n"+\
                            "Set this to the minimum time in which you can comfortably execute a multi-tap\nDefault: 0.3 seconds")
        elseIf currentEvent == "Open"
            fillSlider(KH.fMultiTapDelay, 0.2, 1.0, 0.1, 0.3)
        elseIf currentEvent == "Accept"
            KH.fMultiTapDelay = currentVar
            MCM.SetSliderOptionValueST(KH.fMultiTapDelay, "{1} seconds")
        endIf
    endEvent
endState

State htk_sld_longPrsDelay
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("This defines the length of time you need to hold a key down for for it to register as a Long Press\n"+\
                            "This does not conflict with the multi-tap setting so set it to whatever you are comfortable with, "+\
                            "but not so short that every key press is classed as a Long Press!\nDefault: 0.5 seconds")
        elseIf currentEvent == "Open"
            fillSlider(KH.fLongPressDelay, 0.3, 1.5, 0.1, 0.5)
        elseIf currentEvent == "Accept"
            KH.fLongPressDelay = currentVar
            MCM.SetSliderOptionValueST(KH.fLongPressDelay, "{1} seconds")
        endIf
    endEvent
endState

State htk_sld_prsHoldDelay
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("This defines the length of time you need to hold a key down for for it to register as Press & Hold for actions like toggling Preselect and Equip All Preselected Items\n"+\
                            "Make sure there is enough difference between this and the Long Press Delay setting to avoid key presses being misinterpreted.\nDefault: 1.0 seconds")
        elseIf currentEvent == "Open"
            fillSlider(KH.fPressAndHoldDelay, 0.6, 2.0, 0.1, 1.0)
        elseIf currentEvent == "Accept"
            KH.fPressAndHoldDelay = currentVar
            MCM.SetSliderOptionValueST(KH.fPressAndHoldDelay, "{1} seconds")
        endIf
    endEvent
endState

; --------------------
; - Optional Hotkeys -
; --------------------

State htk_tgl_optConsumeHotkey
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("This enables an additional hotkey for consuming items shown in the consumable slot.\nThis replaces the default longpress on the consumable key\nDefault: Off")
        else
            If currentEvent == "Select"
                KH.bConsumeItemHotkeyEnabled = !KH.bConsumeItemHotkeyEnabled
            elseIf currentEvent == "Default"
            KH.bConsumeItemHotkeyEnabled = false
            endIf
            ;MCM.SetToggleOptionValueST(KH.bConsumeItemHotkeyEnabled)
            MCM.forcePageReset()
        endIf
    endEvent
endState

State htk_key_optional_consumeItem
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Select a hotkey to consume the item currently shown in the consumable slot\nDefault: X")
        elseIf currentEvent == "Change"
            KH.iOptConsumeKey = currentVar as int
            KH.updateKeyMaps()
            MCM.SetKeyMapOptionValueST(KH.iOptConsumeKey)
        elseIf currentEvent == "Default"
            KH.iOptConsumeKey = -1
            MCM.SetKeyMapOptionValueST(KH.iOptConsumeKey)
        endIf
    endEvent
endState

State htk_tgl_optDirectQueueHotkey
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("This enables an additional key to use in combination with the main hotkeys for direct access to that slots Queue Management Menu\nDefault: Off")
        else
            If currentEvent == "Select"
                KH.bQueueMenuComboKeyEnabled = !KH.bQueueMenuComboKeyEnabled
            elseIf currentEvent == "Default"
            KH.bQueueMenuComboKeyEnabled = false
            endIf
            ;MCM.SetToggleOptionValueST(KH.bQueueMenuComboKeyEnabled)
            MCM.forcePageReset()
        endIf
    endEvent
endState

State htk_key_optional_queueMenuCombo
    event OnBeginState()
        if currentEvent == "Highlight"
            MCM.SetInfoText("Select a combo key\nTo access the queue menus press and hold this key then tap the left/right/shout/consumable key, or double tap the consumable key for the poison queue menu.\nDefault: X")
        elseIf currentEvent == "Change"
            KH.iOptDirQueueKey = currentVar as int
            KH.updateKeyMaps()
            MCM.SetKeyMapOptionValueST(KH.iOptDirQueueKey)
        elseIf currentEvent == "Default"
            KH.iOptDirQueueKey = -1
            MCM.SetKeyMapOptionValueST(KH.iOptDirQueueKey)
        endIf
    endEvent
endState
