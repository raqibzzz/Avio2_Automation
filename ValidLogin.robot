*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Test Cases ***

Valid Login And Logout
    [Documentation]    Login with valid credentials, verify dashboard loads, then logout
    [Teardown]    Take Screenshot On Failure
    Navigate To Login Page
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Highlight Element    ${EYE_BUTTON}
    Click    ${EYE_BUTTON}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Sleep    4s
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Log    Successfully logged in - now testing page refresh
    Reload
    Sleep    3s
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Log    Page refreshed - session still active
    Logout
