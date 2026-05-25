*** Settings ***
Library             Browser
Library             OperatingSystem
Resource            Resource/variables.robot
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser


*** Test Cases ***

Valid Login
    [Documentation]    Test login with valid credentials
    Navigate To Login Page
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Highlight Element    ${Eye_button}
    Click    ${Eye_button}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Sleep    4s
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Log    Successfully logged in - now testing page refresh

    # --- Page Refresh Scenario ---
    Reload
    Sleep    3s
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Log    Page refreshed - session still active and dashboard still visible

    Logout
    