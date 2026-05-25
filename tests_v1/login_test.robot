*** Settings ***
Library             Browser
Resource            Resource/variables.robot
Suite Setup         Open Browser To Login Page
Suite Teardown      Close Browser

*** Variables ***
${USERNAME_FIELD}       id=loginUsernameInput
${PASSWORD_FIELD}       id=loginPasswordInput
${LOGIN_BUTTON}         id=loginButton
${DASHBOARD_HEADER}     css=.product-name
${EYE_BUTTON}           css=.mtx-eye-off
${LOGOUT_MENU}          id=headerDropdownButton
${LOGOUT_BUTTON}        id=headerMenuItemLogout

*** Test Cases ***

Valid Login And Logout
    [Documentation]    Login with valid credentials, verify dashboard loads, then logout
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Click    ${EYE_BUTTON}
    Sleep    1s
    Click    ${LOGIN_BUTTON}
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=10s
    Logout

*** Keywords ***
Open Browser To Login Page
    New Browser    ${BROWSER}    headless=False    args=["--ignore-certificate-errors"]
    New Context    ignoreHTTPSErrors=True
    New Page       ${LOGIN_URL}
    Wait For Elements State    ${USERNAME_FIELD}    visible    timeout=10s

Enter Credentials
    [Arguments]    ${user}    ${pass}
    Fill Text      ${USERNAME_FIELD}    ${user}
    Click          ${PASSWORD_FIELD}
    Fill Text      ${PASSWORD_FIELD}    ${pass}
    Sleep          1s

Logout
    Sleep    2s
    Click    ${LOGOUT_MENU}
    Sleep    1s
    Wait For Elements State    ${LOGOUT_BUTTON}    visible    timeout=5s
    Click    ${LOGOUT_BUTTON}
    Wait For Elements State    ${USERNAME_FIELD}    visible    timeout=10s

Take Screenshot On Failure
    Run Keyword If Test Failed    Take Screenshot    filename=failure_{index}
