*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Test Cases ***

Login Same User Two Sessions
    [Documentation]    Verify same user login logs out previous session
    [Teardown]    Take Screenshot On Failure
    Navigate To Login Page

    # --- First session ---
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Highlight Element    ${EYE_BUTTON}
    Click    ${EYE_BUTTON}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Log    First session logged in

    # --- Get first page ID ---
    ${pages}=    Get Page Ids
    ${page1}=    Set Variable    ${pages}[0]
    Log    Page 1 ID: ${page1}

    # --- Open second session in new tab ---
    New Page    ${LOGIN_URL}
    Wait For Elements State    ${USERNAME_FIELD}    visible    timeout=10s
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Highlight Element    ${EYE_BUTTON}
    Click    ${EYE_BUTTON}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Log    Second session logged in

    # --- Get second page ID ---
    ${pages}=    Get Page Ids
    ${page2}=    Set Variable    ${pages}[1]
    Log    Page 2 ID: ${page2}

    # --- Switch to first page to verify session timeout ---
    Log    Switching to first session to verify timeout
    Switch Page    ${page1}
    Sleep    5s
    Wait Until Keyword Succeeds    5x    5s    Wait For Elements State    ${SESSION_TIMEOUT_MSG}    visible    timeout=10s
    Highlight Element    ${SESSION_TIMEOUT_MSG}
    Sleep    3s
    ${msg}=    Get Text    ${SESSION_TIMEOUT_MSG}
    Should Be Equal    ${msg}    Session logged out
    Log    First session correctly logged out

    # --- Close first page and logout from second ---
    Close Page
    Log    Switching back to second session
    Switch Page    ${page2}
    Sleep    2s
    Logout
