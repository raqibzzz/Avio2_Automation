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

Shortcut006_Device Shortcuts Edit With Alt Keys And Save
    [Documentation]    Assign unique keys to each device - save after each one
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

            # Get current shortcut value
            ${current_value}=    Get Text
            ...    xpath=(//tr[not(@id='OSD access')]//p[@class='source-shortcut'])[${index + 1}]
            ${current_value}=    Set Variable    ${current_value.strip()}
            Log    Current shortcut for device ${index + 1}: ${current_value}

            # Add current value to used keys
            IF    '${current_value}' != 'None' and '${current_value}' != ''
                Append To List    ${used_keys}    ${current_value}
            END

            ${key_assigned}=    Set Variable    ${EMPTY}

            FOR    ${key}    IN    @{key_options}
                IF    '${key_assigned}' != '${EMPTY}'
                    BREAK
                END
                IF    $key not in $used_keys
                    Log    Trying key: ${key}

                    # Open ... menu
                    Highlight Element    ${btn}
                    Evaluate JavaScript    ${btn}    (el) => el.click()
                    Wait For Elements State    ${EDIT_OPTION}    visible    timeout=5s
                    Click    ${EDIT_OPTION}
                    Wait For Elements State    ${KEY_INPUT}    visible    timeout=5s
                    Click    ${KEY_INPUT}
                    Keyboard Key    press    ${key}

                    # Check OK enabled
                    ${ok_status}    ${ok_value}=    Run Keyword And Ignore Error
                    ...    Wait For Elements State    ${OK_BUTTON}    enabled    timeout=3s

                    IF    '${ok_status}' == 'PASS'
                        Highlight Element    ${OK_BUTTON}
                        Click    ${OK_BUTTON}

                        # Check if Save appeared
                        ${save_status}    ${save_value}=    Run Keyword And Ignore Error
                        ...    Wait For Elements State    ${SAVE_BUTTON}    visible    timeout=4s

                        IF    '${save_status}' == 'PASS'
                            Highlight Element    ${SAVE_BUTTON}
                            Click    ${SAVE_BUTTON}
                            # Wait for Save to complete
                            Wait For Elements State    ${SAVE_BUTTON}    hidden    timeout=10s
                            ${key_assigned}=    Set Variable    ${key}
                            Append To List    ${used_keys}    ${key}
                            Log    Device ${index + 1} saved with key ${key}
                            # Refresh btn reference after save
                            ${device_btns}=    Get Elements    ${DEVICE_MENU_BTNS}
                            ${btn}=    Set Variable    ${device_btns}[${index}]
                        ELSE
                            Log    Save not appeared - key ${key} same as current - trying next
                            Append To List    ${used_keys}    ${key}
                        END
                    ELSE
                        Log    Key ${key} conflicts - trying next
                        Highlight Element    ${DIALOG_CANCEL}
                        Click    ${DIALOG_CANCEL}
                        Wait For Elements State    ${DIALOG_CANCEL}    hidden    timeout=5s
                    END
                ELSE
                    Log    Key ${key} already used - skipping
                END
            END

            IF    '${key_assigned}' == '${EMPTY}'
                Log    WARNING: No valid key found for device ${index + 1}
            END
        END
        Log    All devices processed successfully
    END