*** Settings ***
Library             Browser
Library             OperatingSystem
Resource            Resource/variables.robot
Resource            Resource/keywords.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser


*** Test Cases ***
Invalid Login - Wrong USERNAME
    [Documentation]    Test login with wrong username
    Navigate To Login Page
    Enter Credentials    wrongusername    ${PASSWORD}
    Highlight Element    ${Eye_button}
    Click    ${Eye_button}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Sleep    2s
    Wait For Elements State    ${ERROR_MESSAGE}    visible    timeout=10s
    Get Text    ${ERROR_MESSAGE}    ==    Invalid username or password
    Clear Credentials


