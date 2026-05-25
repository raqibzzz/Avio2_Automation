*** Settings ***
Library             Browser
Library             OperatingSystem
Library             Collections
Resource            ../Resource/variables.robot
Resource            ../Resource/Keywords.robot
Suite Setup         Open Browser And Login
Suite Teardown      Close Browser

*** Test Cases ***

Shortcut000_Check Receiver UI
    [Documentation]    Verify Shortcuts card exists before running tests
    ${available}=    Is Shortcuts Available
    IF    not $available
        Skip    No Shortcuts card found - Device is Transmitter or Receiver without Admin rights - all tests skipped
    END
    Log    Shortcuts card confirmed - proceeding with all shortcut tests


Shortcut001_OSD Reset To ScrollLock And Save
    [Documentation]    Reset OSD to ScrollLock - set non-ScrollLock key first if needed
    Go To Dashboard
    Open Shortcuts Panel
    ${current_key}=    Get Text    ${OSD_SHORTCUT_TEXT}
    Log    Current OSD shortcut: ${current_key}

    IF    '${current_key}'.strip() == 'Scroll Lock'
        Log    OSD is ScrollLock - need to set different key first
   ${osd_keys}=    Create List
...    Alt+o    Alt+p    Alt+k    Alt+j    Alt+n    Alt+b
        Set Valid Shortcut And Save    ${OSD_MENU_BTN}    ${osd_keys}
        Sleep    2s
    END

    # Now Reset to ScrollLock
    Highlight Element    ${OSD_MENU_BTN}
    Click    ${OSD_MENU_BTN}
    Sleep    2s
    Wait For Elements State    ${RESET_OPTION}    visible    timeout=5s
    Highlight Element    ${RESET_OPTION}
    Click    ${RESET_OPTION}
    Sleep    1s
    Wait For Elements State    ${SAVE_BUTTON}    visible    timeout=15s
    Highlight Element    ${SAVE_BUTTON}
    Click    ${SAVE_BUTTON}
    Sleep    2s
    Log    OSD reset to ScrollLock and saved

Shortcut002_OSD Reset To ScrollLock And Cancel
    [Documentation]    Set non-ScrollLock key first then reset and cancel
    Go To Dashboard
    Open Shortcuts Panel
    ${current_key}=    Get Text    ${OSD_SHORTCUT_TEXT}
    Log    Current OSD shortcut: ${current_key}

    IF    '${current_key}'.strip() == 'Scroll Lock'
        Log    OSD is ScrollLock - need to set different key first
   ${osd_keys}=    Create List
...    Alt+o    Alt+p    Alt+k    Alt+j    Alt+n    Alt+b
        Set Valid Shortcut And Save    ${OSD_MENU_BTN}    ${osd_keys}
        Sleep    2s
    END

    # Now Reset and Cancel
    Highlight Element    ${OSD_MENU_BTN}
    Click    ${OSD_MENU_BTN}
    Sleep    2s
    Wait For Elements State    ${RESET_OPTION}    visible    timeout=5s
    Highlight Element    ${RESET_OPTION}
    Click    ${RESET_OPTION}
    Sleep    1s
    Wait For Elements State    ${CANCEL_BUTTON}    visible    timeout=10s
    Highlight Element    ${CANCEL_BUTTON}
    Click    ${CANCEL_BUTTON}
    Sleep    2s
    Log    OSD reset cancelled - no changes saved

Shortcut003_OSD Edit Shortcut With Invalid Key - Save Disabled
    [Documentation]    Verify OK button disabled for invalid shortcut then cancel
    Go To Dashboard
    Open Shortcuts Panel
    Highlight Element    ${OSD_MENU_BTN}
    Click    ${OSD_MENU_BTN}
    Sleep    2s
    Wait For Elements State    ${EDIT_OPTION}    visible    timeout=5s
    Highlight Element    ${EDIT_OPTION}
    Click    ${EDIT_OPTION}
    Sleep    1s
    Wait For Elements State    ${KEY_INPUT}    visible    timeout=5s
    Highlight Element    ${KEY_INPUT}
    Click    ${KEY_INPUT}
    Keyboard Key    press    a
    Sleep    1s
    ${is_disabled}=    Get Attribute    ${OK_BUTTON}    disabled
    Should Not Be Equal    ${is_disabled}    ${None}
    Log    OK button correctly disabled for invalid shortcut
    Highlight Element    ${DIALOG_CANCEL}
    Click    ${DIALOG_CANCEL}
    Sleep    2s
    Log    Dialog cancelled - no changes saved

Shortcut004_OSD Edit Shortcut With Valid Key And Save
    [Documentation]    Edit OSD shortcut - system tries keys until valid one found
    Go To Dashboard
    Open Shortcuts Panel
   ${osd_keys}=    Create List
...    Alt+o    Alt+p    Alt+k    Alt+j    Alt+n    Alt+b
    ${assigned}=    Set Valid Shortcut And Save    ${OSD_MENU_BTN}    ${osd_keys}
    Log    OSD shortcut assigned: ${assigned}

Shortcut005_OSD Edit Shortcut And Cancel
    [Documentation]    Edit OSD shortcut then cancel dialog - no changes saved
    Go To Dashboard
    Open Shortcuts Panel
    Highlight Element    ${OSD_MENU_BTN}
    Click    ${OSD_MENU_BTN}
    Sleep    2s
    Wait For Elements State    ${EDIT_OPTION}    visible    timeout=5s
    Highlight Element    ${EDIT_OPTION}
    Click    ${EDIT_OPTION}
    Sleep    1s
    Wait For Elements State    ${KEY_INPUT}    visible    timeout=5s
    Highlight Element    ${KEY_INPUT}
    Click    ${KEY_INPUT}
    Keyboard Key    press    Alt+o
    Sleep    1s
    Highlight Element    ${DIALOG_CANCEL}
    Click    ${DIALOG_CANCEL}
    Sleep    2s
    Log    OSD shortcut edit cancelled from dialog - no changes saved

Shortcut006_Device Shortcuts Edit With Alt Keys And Save
    [Documentation]    Assign unique keys to each device avoiding all conflicts
    Go To Dashboard
    Open Shortcuts Panel
    ${device_btns}=    Get Elements    ${DEVICE_MENU_BTNS}
    ${count}=          Get Length      ${device_btns}

    IF    ${count} == 0
        Log    No device shortcuts found - skipping
    ELSE
        ${key_options}=    Create List
        ...    Alt+1    Alt+2    Alt+3    Alt+4    Alt+5
        ...    Alt+6    Alt+7    Alt+8    Alt+9
        ...    Alt+F1    Alt+F2    Alt+F3    Alt+F4    Alt+F5

        ${used_keys}=    Create List

        FOR    ${index}    ${btn}    IN ENUMERATE    @{device_btns}
            Log    Processing device ${index + 1}
            Highlight Element    ${btn}
            Evaluate JavaScript    ${btn}    (el) => el.click()
            Sleep    2s
            Wait For Elements State    ${EDIT_OPTION}    visible    timeout=5s
            Highlight Element    ${EDIT_OPTION}
            Click    ${EDIT_OPTION}
            Sleep    1s
            Wait For Elements State    ${KEY_INPUT}    visible    timeout=5s

            ${key_assigned}=    Set Variable    ${EMPTY}

            FOR    ${key}    IN    @{key_options}
                IF    '${key_assigned}' != '${EMPTY}'
                    BREAK
                END
                IF    $key not in $used_keys
                    Click    ${KEY_INPUT}
                    Sleep    0.5s
                    Keyboard Key    press    ${key}
                    Sleep    1s
                    ${status}    ${value}=    Run Keyword And Ignore Error
                    ...    Wait For Elements State    ${OK_BUTTON}    enabled    timeout=3s
                    IF    '${status}' == 'PASS'
                        ${key_assigned}=    Set Variable    ${key}
                        Append To List    ${used_keys}    ${key}
                        Log    Assigned ${key} to device ${index + 1}
                    ELSE
                        Log    Key ${key} conflicts - trying next
                        Click    ${KEY_INPUT}
                        Sleep    0.5s
                    END
                END
            END

            IF    '${key_assigned}' == '${EMPTY}'
                Log    WARNING: No valid key found for device ${index + 1}
                Click    ${DIALOG_CANCEL}
                Sleep    1s
            ELSE
                Highlight Element    ${OK_BUTTON}
                Click    ${OK_BUTTON}
                Sleep    1s
            END
        END

        Wait For Elements State    ${SAVE_BUTTON}    visible    timeout=15s
        Highlight Element    ${SAVE_BUTTON}
        Click    ${SAVE_BUTTON}
        Sleep    2s
        Log    All device shortcuts assigned and saved
    END

Shortcut007_Device Shortcuts Edit And Cancel
    [Documentation]    Edit device shortcut then cancel dialog - no changes saved
    Go To Dashboard
    Open Shortcuts Panel
    ${device_btns}=    Get Elements    ${DEVICE_MENU_BTNS}
    ${count}=          Get Length      ${device_btns}

    IF    ${count} == 0
        Log    No device shortcuts found - skipping
    ELSE
        ${first_btn}=    Set Variable    ${device_btns}[0]
        Highlight Element    ${first_btn}
        Evaluate JavaScript    ${first_btn}    (el) => el.click()
        Sleep    2s
        Wait For Elements State    ${EDIT_OPTION}    visible    timeout=5s
        Highlight Element    ${EDIT_OPTION}
        Click    ${EDIT_OPTION}
        Sleep    1s
        Wait For Elements State    ${KEY_INPUT}    visible    timeout=5s
        Highlight Element    ${KEY_INPUT}
        Click    ${KEY_INPUT}
        Keyboard Key    press    Control+1
        Sleep    1s
        Highlight Element    css=.cdk-overlay-container #CancelButton
        Click    css=.cdk-overlay-container #CancelButton
        Sleep    2s
        Log    Device shortcut changes cancelled from dialog
    END

Shortcut008_Device Shortcuts Reset And Save
    [Documentation]    Reset all device shortcuts that have keys assigned
    Go To Dashboard
    Open Shortcuts Panel
    ${device_rows}=    Get Elements    xpath=//tr[not(@id='OSD access') and .//p[@class='source-shortcut']]
    ${count}=          Get Length      ${device_rows}
    Log    Found ${count} device rows

    IF    ${count} == 0
        Log    No device shortcuts found - nothing to reset
    ELSE
        FOR    ${row}    IN    @{device_rows}
            ${shortcut}=    Get Text    ${row} >> p.source-shortcut
            Log    Current shortcut: ${shortcut}
            IF    '${shortcut}'.strip() != 'None'
                ${btn}=    Get Element    ${row} >> button[id$='OptionsButton']
                Highlight Element    ${btn}
                Evaluate JavaScript    ${btn}    (el) => el.click()
                Sleep    2s
                Wait For Elements State    ${RESET_OPTION}    visible    timeout=5s
                Highlight Element    ${RESET_OPTION}
                Click    ${RESET_OPTION}
                Sleep    1s
                Log    Reset clicked for device
            ELSE
                Log    Device already None - skipping
            END
        END
        Wait For Elements State    ${SAVE_BUTTON}    visible    timeout=10s
        Highlight Element    ${SAVE_BUTTON}
        Click    ${SAVE_BUTTON}
        Sleep    2s
        Log    All device shortcuts reset and saved
    END

Shortcut009_Device Shortcuts Reset And Cancel
    [Documentation]    Assign key to device first then reset and cancel
    Go To Dashboard
    Open Shortcuts Panel
    ${device_btns}=    Get Elements    ${DEVICE_MENU_BTNS}
    ${count}=          Get Length      ${device_btns}

    IF    ${count} == 0
        Log    No device shortcuts found - skipping
    ELSE
        # Step 1 - Assign a valid key first
        ${first_btn}=    Set Variable    ${device_btns}[0]
        ${device_keys}=    Create List
        ...    Alt+1    Alt+2    Alt+3    Alt+4    Alt+5
        ...    Alt+6    Alt+7    Alt+8    Alt+9
        ${result}=    Set Valid Shortcut And Save    ${first_btn}    ${device_keys}
        Log    Key assigned: ${result}
        Sleep    2s

        IF    '${result}' == '${EMPTY}'
            Log    Could not assign key - skipping reset
        ELSE
            # Step 2 - Now Reset and Cancel
            Go To Dashboard
            Open Shortcuts Panel
            ${device_btns}=    Get Elements    ${DEVICE_MENU_BTNS}
            ${first_btn}=    Set Variable    ${device_btns}[0]
            Highlight Element    ${first_btn}
            Evaluate JavaScript    ${first_btn}    (el) => el.click()
            Sleep    2s
            Wait For Elements State    ${RESET_OPTION}    visible    timeout=5s
            Highlight Element    ${RESET_OPTION}
            Click    ${RESET_OPTION}
            Sleep    1s
            Wait For Elements State    ${CANCEL_BUTTON}    visible    timeout=10s
            Highlight Element    ${CANCEL_BUTTON}
            Click    ${CANCEL_BUTTON}
            Sleep    2s
            Log    Device reset cancelled successfully
        END
    END