*** Settings ***
Library             Browser
Library             OperatingSystem
Resource            Resource/variables.robot
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser


*** Test Cases ***

Empty Username Only
    [Documentation]    Sign-in button should be disabled with only Password value
    Navigate To Login Page
    Click          ${PASSWORD_FIELD}
    Fill Text      ${PASSWORD_FIELD}    ${PASSWORD}
    Highlight Element    ${LOGIN_BUTTON}
    Sleep    1s
    ${is_disabled}=    Get Attribute    ${LOGIN_BUTTON}    disabled
    Should Not Be Equal    ${is_disabled}    ${None}
    Log    Login button is correctly disabled with only password filled
    Clear Credentials

