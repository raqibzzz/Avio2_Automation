*** Settings ***
Library             Browser
Library             OperatingSystem
Resource            Resource/variables.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Variables ***
${USERNAME_FIELD}       id=loginUsernameInput
${PASSWORD_FIELD}       id=loginPasswordInput
${LOGIN_BUTTON}         id=loginButton
${DASHBOARD_HEADER}     id=headerDropdownButton
${Eye_button}           css=.mtx-eye-off
${LOGOUT_MENU}          id=headerDropdownButton
${LOGOUT_BUTTON}        id=headerMenuItemLogout
${ERROR_MESSAGE}        css=.text-danger.show
${SESSION_TIMEOUT_MSG}  xpath=//span[contains(@class,'title') and contains(text(),'Session logged out')]

*** Test Cases ***

Invalid Login - Wrong Password
    [Documentation]    Test login with wrong password
    Navigate To Login Page
    Enter Credentials    ${USERNAME}    wrongpassword
    Highlight Element    ${Eye_button}
    Click    ${Eye_button}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Sleep    2s
    Wait For Elements State    ${ERROR_MESSAGE}    visible    timeout=10s
    Get Text    ${ERROR_MESSAGE}    ==    Invalid username or password
    Clear Credentials

*** Keywords ***

Open Browser To Login Page
    Set Environment Variable    NO_PROXY    127.0.0.1,localhost
    Set Environment Variable    NODE_TLS_REJECT_UNAUTHORIZED    0
    New Browser    ${BROWSER}    headless=False    slowMo=2000ms    args=["--ignore-certificate-errors"]
    New Context    ignoreHTTPSErrors=True
    New Page    ${LOGIN_URL}
    Wait For Elements State    ${USERNAME_FIELD}    visible    timeout=10s

Navigate To Login Page
    ${pages}=    Get Page Ids
    ${count}=    Get Length    ${pages}
    IF    ${count} == 0
        New Page    ${LOGIN_URL}
    ELSE
        Go To    ${LOGIN_URL}
    END
    Wait For Elements State    ${USERNAME_FIELD}    visible    timeout=10s

Add Custom Cursor
    Evaluate JavaScript    html    (el) => { const style = document.createElement('style'); style.innerHTML = '*, *::before, *::after { cursor: crosshair !important; }'; document.head.appendChild(style); }

Enter Credentials
    [Arguments]    ${user}    ${pass}
    Fill Text      ${USERNAME_FIELD}    ${user}
    Click          ${PASSWORD_FIELD}
    Fill Text      ${PASSWORD_FIELD}    ${pass}
    Sleep          1s

Logout
    Sleep    2s
    Wait For Elements State    ${LOGOUT_MENU}    visible    timeout=15s
    Highlight Element    ${LOGOUT_MENU}
    Click    ${LOGOUT_MENU}
    Sleep    1s
    Wait For Elements State    ${LOGOUT_BUTTON}    visible    timeout=15s
    Highlight Element    ${LOGOUT_BUTTON}
    Click    ${LOGOUT_BUTTON}
    Sleep    2s
    Wait For Elements State    ${USERNAME_FIELD}    visible    timeout=15s

Clear Credentials
    Click    ${USERNAME_FIELD}
    Keyboard Key    press    Control+a
    Keyboard Key    press    Backspace
    Click    ${PASSWORD_FIELD}
    Keyboard Key    press    Control+a
    Keyboard Key    press    Backspace
    Sleep    2s

Highlight Element
    [Arguments]    ${selector}
    Wait For Elements State    ${selector}    visible    timeout=15s
    Evaluate JavaScript    ${selector}    (element) => { element.style.border = '3px solid red'; element.style.backgroundColor = 'rgba(255, 255, 0, 0.3)'; element.style.transition = 'all 0.3s'; }
    Sleep    0.5s
    Evaluate JavaScript    ${selector}    (element) => { element.style.border = ''; element.style.backgroundColor = ''; }