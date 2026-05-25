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
${SOURCES_PANE}         css=div.folder-image >> nth=0
${SOURCE_CARDS}         css=mtx-thumbnail[id^=mtx-small]

*** Test Cases ***

Connect And Disconnect All Sources
    [Documentation]    Login, open sources pane, dynamically find all TX cards, connect each for 5 seconds then disconnect
    [Teardown]    Take Screenshot On Failure
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Click    ${EYE_BUTTON}
    Sleep    1s
    Click    ${LOGIN_BUTTON}
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=10s
    Open Sources Pane
    ${sources}=    Get Elements    ${SOURCE_CARDS}
    Log    Found ${sources.__len__()} sources
    FOR    ${source}    IN    @{sources}
        ${id}=    Get Attribute    ${source}    id
        Log    Processing source: ${id}
        Connect Disconnect Source    ${source}    ${id}
    END
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

Open Sources Pane
    Evaluate JavaScript    css=div.folder-image >> nth=0    (elem) => { elem.dispatchEvent(new MouseEvent('dblclick', {bubbles: true})); }
    Sleep    2s
    Get Element Count    ${SOURCE_CARDS}    assertion_operator=greater than    assertion_expected=0

Connect Disconnect Source
    [Arguments]    ${source}    ${name}
    Log    Connecting to ${name}
    Click With Options    ${source}    clickCount=2
    Sleep    2s
    Wait For Elements State    css=.background-success    visible    timeout=10s
    Log    ${name} connected, waiting 5 seconds
    Sleep    5s
    Log    Disconnecting ${name}
    Click With Options    ${source}    clickCount=2
    Sleep    2s
    Log    ${name} disconnected

Logout
    Sleep    2s
    Click    ${LOGOUT_MENU}
    Sleep    1s
    Wait For Elements State    ${LOGOUT_BUTTON}    visible    timeout=5s
    Click    ${LOGOUT_BUTTON}
    Wait For Elements State    ${USERNAME_FIELD}    visible    timeout=10s

Take Screenshot On Failure
    Run Keyword If Test Failed    Take Screenshot    filename=failure_{index}