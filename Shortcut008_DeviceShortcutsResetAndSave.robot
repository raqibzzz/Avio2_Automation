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
