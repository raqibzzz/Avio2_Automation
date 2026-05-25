*** Settings ***
Library             Browser
Library             OperatingSystem
Resource            Resource/variables.robot
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser


*** Test Cases ***
    
Empty Credentials
    [Documentation]    Sign-in button should be disabled when both fields are empty
    Navigate To Login Page
    Highlight Element    ${LOGIN_BUTTON}
    ${is_disabled}=    Get Attribute    ${LOGIN_BUTTON}    disabled
    Run Keyword If    '${is_disabled}' != 'None'    Log    Login button is correctly disabled
    Should Not Be Equal    ${is_disabled}    ${None}
    Sleep    2s


