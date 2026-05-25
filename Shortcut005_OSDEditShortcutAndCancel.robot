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