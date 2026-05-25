*** Settings ***
Library             Browser
Resource            Resource/keywords.robot
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
