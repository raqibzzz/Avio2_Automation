*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Test Cases ***

Tab Navigation
    [Documentation]    Test Tab key moves focus between fields correctly
    [Teardown]    Take Screenshot On Failure
    Navigate To Login Page
    Click    ${USERNAME_FIELD}
    Keyboard Key    press    Tab
    Sleep    1s
    Keyboard Input    type    testpassword
    Sleep    1s
    Get Text    ${PASSWORD_FIELD}    ==    testpassword
    Keyboard Key    press    Tab
    Sleep    1s
    Keyboard Key    press    Enter
    Sleep    2s
    Wait For Elements State    ${ERROR_MESSAGE}    visible    timeout=10s
    Clear Credentials
