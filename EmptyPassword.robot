*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Test Cases ***

Empty Password Only
    [Documentation]    Sign-in button should be disabled with only Username value
    [Teardown]    Take Screenshot On Failure
    Navigate To Login Page
    Fill Text      ${USERNAME_FIELD}    ${USERNAME}
    Highlight Element    ${LOGIN_BUTTON}
    Sleep    1s
    ${is_disabled}=    Get Attribute    ${LOGIN_BUTTON}    disabled
    Should Not Be Equal    ${is_disabled}    ${None}
    Log    Login button is correctly disabled with only username filled
    Clear Credentials
