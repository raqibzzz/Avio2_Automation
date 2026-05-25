*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Variables ***
${TX_URL}               https://${DEVICE_IP}/#/transmitter/streaming
${BITRATE_DROPDOWN}     css=button.mtx-select >> nth=1
${SAVE_BUTTON}          id=saveButton

*** Test Cases ***

Cycle Through Video Bitrate Levels
    [Documentation]    Open TX streaming page and cycle through all video bitrate options
    [Teardown]    Take Screenshot On Failure
    Navigate To Login Page
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Highlight Element    ${EYE_BUTTON}
    Click    ${EYE_BUTTON}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Navigate To Transmitter Streaming Page
    @{options}=    Create List    Standard 10G    High 10G    Custom    Standard 1G
    FOR    ${option}    IN    @{options}
        Select Bitrate Option    ${option}
        Sleep    2s
        Verify Selected Bitrate    ${option}
        Save Changes
        Log    Successfully set bitrate to: ${option}
    END
    Log    All bitrate options cycled successfully
    Logout

*** Keywords ***

Navigate To Transmitter Streaming Page
    Go To    ${TX_URL}
    Wait For Elements State    ${BITRATE_DROPDOWN}    visible    timeout=15s

Select Bitrate Option
    [Arguments]    ${option_text}
    Click    ${BITRATE_DROPDOWN}
    Sleep    1s
    Click    css=div.mtx-menu-item:has-text("${option_text}")
    Sleep    1s

Verify Selected Bitrate
    [Arguments]    ${expected}
    ${selected}=    Get Text    css=button.mtx-select >> nth=1
    Should Be Equal    ${selected.strip()}    ${expected}

Save Changes
    Wait For Elements State    ${SAVE_BUTTON}    visible    timeout=10s
    Highlight Element    ${SAVE_BUTTON}
    Click    ${SAVE_BUTTON}
    Sleep    1s
    ${dialog_visible}=    Run Keyword And Return Status    Wait For Elements State    css=button.mtx-button-warning-gradient    visible    timeout=5s
    IF    ${dialog_visible}
        Wait For Elements State    css=button.mtx-button-warning-gradient    visible    timeout=10s
        Evaluate JavaScript    css=button.mtx-button-warning-gradient    (elem) => { elem.click(); }
        Wait For Elements State    css=atx-common-dialog    hidden    timeout=10s
    END
    Sleep    2s