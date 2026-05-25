*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Test Cases ***

Enter Key As Sign In
    [Documentation]    Test that Enter key works instead of clicking Sign-in button
    [Teardown]    Take Screenshot On Failure
    Navigate To Login Page
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Highlight Element    ${PASSWORD_FIELD}
    Sleep    1s
    Keyboard Key    press    Enter
    Sleep    4s
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Logout
