*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Test Cases ***

Invalid Login - Wrong Username
    [Documentation]    Test login with wrong username
    [Teardown]    Take Screenshot On Failure
    Navigate To Login Page
    Enter Credentials    wrongusername    ${PASSWORD}
    Highlight Element    ${EYE_BUTTON}
    Click    ${EYE_BUTTON}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Sleep    2s
    Wait For Elements State    ${ERROR_MESSAGE}    visible    timeout=10s
    Get Text    ${ERROR_MESSAGE}    ==    Invalid username or password
    Clear Credentials
