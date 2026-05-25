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