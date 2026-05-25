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