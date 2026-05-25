*** Variables ***
${BASE_URL}         https://${DEVICE_IP}
${BROWSER}          chromium
${USERNAME}         Tester
${PASSWORD}         Matrox1234!
${LOGIN_URL}        ${BASE_URL}/#/login
${SOURCE_X100015}       id=mtx-smallX100015
${SOURCE_X100008}       id=mtx-smallX100008
${CONNECTED_STATUS}     css=.background-success

# — Login —
${USERNAME_FIELD}       id=loginUsernameInput
${PASSWORD_FIELD}       id=loginPasswordInput
${LOGIN_BUTTON}         id=loginButton
${DASHBOARD_HEADER}     id=headerDropdownButton
${Eye_button}           css=.mtx-eye-off
${LOGOUT_MENU}          id=headerDropdownButton
${LOGOUT_BUTTON}        id=headerMenuItemLogout
${ERROR_MESSAGE}        css=.text-danger.show
${SESSION_TIMEOUT_MSG}  xpath=//span[contains(@class,'title') and contains(text(),'Session logged out')]


# — Shortcuts —
${SHORTCUTS_CARD}       css=img[alt="Image representing Shortcuts settings"]
${OSD_MENU_BTN}         xpath=//*[@id='hotkeysOSD accessOptionsButton']
${OSD_SHORTCUT_TEXT}    xpath=//tr[@id='OSD access']//p[@class='source-shortcut']
${DEVICE_MENU_BTNS}     css=[id^='hotkeys'][id$='OptionsButton']:not([id='hotkeysOSD accessOptionsButton'])
${EDIT_OPTION}          xpath=//div[@class='content'][text()='Edit...']
${RESET_OPTION}         xpath=//div[@class='content'][text()='Reset']

# — Shortcut Dialog —
${KEY_INPUT}            css=.cdk-overlay-container .cdk-overlay-pane:last-child #HotkeyInput
${OK_BUTTON}            css=.cdk-overlay-container .cdk-overlay-pane:last-child #OkButton
${DIALOG_CANCEL}        css=.cdk-overlay-container .cdk-overlay-pane:last-child #CancelButton

# — Panel Buttons —
${CANCEL_BUTTON}        id=cancelButton
${SAVE_BUTTON}          id=saveButton
