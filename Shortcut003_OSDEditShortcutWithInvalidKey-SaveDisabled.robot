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