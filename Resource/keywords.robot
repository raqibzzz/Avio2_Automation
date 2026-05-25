*** Settings ***
Library             Browser
Library             OperatingSystem
Resource            variables.robot
Library             Collections



*** Variables ***
${USERNAME_FIELD}       id=loginUsernameInput
${PASSWORD_FIELD}       id=loginPasswordInput
${LOGIN_BUTTON}         id=loginButton
${DASHBOARD_HEADER}     id=headerDropdownButton
${EYE_BUTTON}           css=.mtx-eye-off
${LOGOUT_MENU}          id=headerDropdownButton
${LOGOUT_BUTTON}        id=headerMenuItemLogout
${ERROR_MESSAGE}        css=.text-danger.show
${SESSION_TIMEOUT_MSG}  xpath=//span[contains(@class,'title') and contains(text(),'Session logged out')]
${SOURCES_PANE}         css=div.folder-image >> nth=0
${SOURCE_CARDS}         css=mtx-thumbnail[id^=mtx-small]


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

Add Custom Cursor
    Evaluate JavaScript    html    (el) => { const style = document.createElement('style'); style.innerHTML = '*, *::before, *::after { cursor: crosshair !important; }'; document.head.appendChild(style); }

Take Screenshot On Failure
    Run Keyword If Test Failed    Take Screenshot    filename=failure_{index}

Open Sources Pane
    Evaluate JavaScript    css=div.folder-image >> nth=0    (elem) => { elem.dispatchEvent(new MouseEvent('dblclick', {bubbles: true})); }
    Sleep    2s
    Get Element Count    ${SOURCE_CARDS}    assertion_operator=greater than    assertion_expected=0

Connect Disconnect Source
    [Arguments]    ${source}    ${name}
    Log    Connecting to ${name}
    Evaluate JavaScript    ${source}    (elem) => { elem.dispatchEvent(new MouseEvent('dblclick', {bubbles: true})); }
    Sleep    2s
    Wait For Elements State    css=.background-success    visible    timeout=10s
    Log    ${name} connected, waiting 5 seconds
    Sleep    5s
    Log    Disconnecting ${name}
    Evaluate JavaScript    ${source}    (elem) => { elem.dispatchEvent(new MouseEvent('dblclick', {bubbles: true})); }
    Sleep    2s
    Log    ${name} disconnected

Open Browser And Login
    Open Browser To Login Page
    Enter Credentials    ${USERNAME}    ${PASSWORD}
    Highlight Element    ${Eye_button}
    Click    ${Eye_button}
    Sleep    1s
    Highlight Element    ${LOGIN_BUTTON}
    Click    ${LOGIN_BUTTON}
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    Log    Logged in successfully

Open Shortcuts Panel
    [Documentation]    Opens shortcuts panel - skips if not available
    ${available}=    Is Shortcuts Available
    IF    not $available
        Skip    No Shortcuts card - Device is Transmitter or Receiver without Admin rights
    END
    ${card}=    Get Element    css=img[alt="Image representing Shortcuts settings"]
    Evaluate JavaScript    css=img[alt="Image representing Shortcuts settings"]
    ...    (el) => el.closest('.mtx-thumbnail').click()
    Wait For Elements State    ${OSD_MENU_BTN}    visible    timeout=10s
    Log    Shortcuts panel opened

Open OSD Menu
    Wait For Elements State    ${OSD_ROW}    visible    timeout=10s
    Hover    ${OSD_ROW}
    Wait For Elements State    ${OSD_MENU_BTN}    visible
    Highlight Element          ${OSD_MENU_BTN}
    Click                      ${OSD_MENU_BTN}

Open Menu For Item
    [Arguments]    ${label}
    ${row}=    Set Variable    xpath=//p[contains(normalize-space(),'${label}')]
    ${menu}=   Set Variable    ${row}/ancestor::div[contains(@class,'source-item')]//i[contains(@class,'mtx-dots-horizontal')]

    Wait For Elements State    ${row}    visible
    Hover    ${row}
    Wait For Elements State    ${menu}    visible
    Click    ${menu}
Go To Dashboard
    Go To    ${BASE_URL}/#/
    Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=10s
    Log    Back on dashboard

Set OSD Shortcut
    [Arguments]    ${key}
    Highlight Element    ${OSD_MENU_BTN}
    Click    ${OSD_MENU_BTN}
    Sleep    2s
    Wait For Elements State    ${EDIT_OPTION}    visible    timeout=5s
    Highlight Element    ${EDIT_OPTION}
    Click    ${EDIT_OPTION}
    Sleep    1s
    Wait For Elements State    css=.cdk-overlay-container #HotkeyInput    visible    timeout=5s
    Highlight Element    css=.cdk-overlay-container #HotkeyInput
    Click    css=.cdk-overlay-container #HotkeyInput
    Keyboard Key    press    ${key}
    Sleep    1s
    Wait For Elements State    css=.cdk-overlay-container #OkButton    enabled    timeout=5s
    Highlight Element    css=.cdk-overlay-container #OkButton
    Click    css=.cdk-overlay-container #OkButton
    Sleep    1s
    Log    OSD shortcut set to ${key}

Check Key Conflict
    [Arguments]    ${key_text}
    ${rows}=    Get Elements    xpath=//tr[not(@id='OSD access')]//p[@class='source-shortcut']
    FOR    ${row}    IN    @{rows}
        ${text}=    Get Text    ${row}
        IF    '${text}'.strip() == '${key_text}'
            RETURN    True
        END
    END
    RETURN    False


Set Valid Shortcut And Save
    [Arguments]    ${menu_btn}    ${preferred_keys}
    [Documentation]    Try each key until valid and different from current then save

    Highlight Element    ${menu_btn}
    Evaluate JavaScript    ${menu_btn}    (el) => el.click()
    Wait For Elements State    ${EDIT_OPTION}    visible    timeout=5s
    Highlight Element    ${EDIT_OPTION}
    Click    ${EDIT_OPTION}
    Wait For Elements State    ${KEY_INPUT}    visible    timeout=5s

    ${key_assigned}=    Set Variable    ${EMPTY}

    FOR    ${key}    IN    @{preferred_keys}
        IF    '${key_assigned}' != '${EMPTY}'
            BREAK
        END

        Log    Trying key: ${key}
        Click    ${KEY_INPUT}
        Keyboard Key    press    ${key}

        ${status}    ${value}=    Run Keyword And Ignore Error
        ...    Wait For Elements State    ${OK_BUTTON}    enabled    timeout=3s

        IF    '${status}' == 'PASS'
            Log    Key ${key} is VALID
            ${key_assigned}=    Set Variable    ${key}
        ELSE
            Log    Key ${key} INVALID or conflicts - trying next
            Click    ${KEY_INPUT}
        END
    END

    IF    '${key_assigned}' == '${EMPTY}'
        Log    WARNING: No valid key found - cancelling
        Click    ${DIALOG_CANCEL}
        Wait For Elements State    ${DIALOG_CANCEL}    hidden    timeout=5s
        RETURN    ${EMPTY}
    END

    Highlight Element    ${OK_BUTTON}
    Click    ${OK_BUTTON}
    Wait For Elements State    ${OK_BUTTON}    hidden    timeout=5s

    ${save_status}    ${save_value}=    Run Keyword And Ignore Error
    ...    Wait For Elements State    ${SAVE_BUTTON}    visible    timeout=5s

    IF    '${save_status}' == 'PASS'
        Highlight Element    ${SAVE_BUTTON}
        Click    ${SAVE_BUTTON}
        Wait For Elements State    ${SAVE_BUTTON}    hidden    timeout=10s
        Log    Key ${key_assigned} saved successfully
    ELSE
        Log    Save not appeared - same key as current - trying next
        ${remaining}=    Evaluate    [k for k in $preferred_keys if k != '${key_assigned}']
        IF    len($remaining) > 0
            ${result}=    Set Valid Shortcut And Save    ${menu_btn}    ${remaining}
            RETURN    ${result}
        END
    END

    RETURN    ${key_assigned}

Is Shortcuts Available
    [Documentation]    Check if Shortcuts card exists on the dashboard
    Go To Dashboard
    Sleep    2s
    ${exists}=    Evaluate JavaScript    html
    ...    () => {
    ...        const imgs = document.querySelectorAll('img');
    ...        for (const img of imgs) {
    ...            if (img.alt && img.alt.includes('Shortcuts')) return true;
    ...        }
    ...        return false;
    ...    }
    IF    $exists
        Log    Shortcuts card found - Receiver UI with Admin rights confirmed
        RETURN    ${TRUE}
    ELSE
        Log    Shortcuts card NOT found - Transmitter UI or Receiver without Admin rights
        RETURN    ${FALSE}
    END
