*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Test Cases ***

Connect And Disconnect All Sources
    [Documentation]    Login, open sources pane, dynamically find all TX cards, connect each for 5 seconds then disconnect
    [Teardown]    Take Screenshot On Failure
    Navigate To Login Page
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Highlight Element    ${EYE_BUTTON}
    Click    ${EYE_BUTTON}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=10s
    Open Sources Pane
    ${sources}=    Get Elements    ${SOURCE_CARDS}
    Log    Found ${sources.__len__()} sources
    FOR    ${source}    IN    @{sources}
        ${id}=    Get Attribute    ${source}    id
        Log    Processing source: ${id}
        Connect Disconnect Source    ${source}    ${id}
    END
    Logout
