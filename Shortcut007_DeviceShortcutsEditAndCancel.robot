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
