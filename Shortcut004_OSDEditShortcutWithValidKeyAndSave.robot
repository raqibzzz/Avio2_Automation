*** Settings ***
Library             Browser
Library             OperatingSystem
Library             Collections
Resource            ../Resource/variables.robot
Resource            ../Resource/Keywords.robot
Suite Setup         Open Browser And Login
Suite Teardown      Close Browser

*** Test Cases ***

Shortcut000_Check Receiver UI
    [Documentation]    Verify Shortcuts card exists before running tests
    ${available}=    Is Shortcuts Available
    IF    not $available
        Skip    No Shortcuts card found - Device is Transmitter or Receiver without Admin rights - all tests skipped
    END
    Log    Shortcuts card confirmed - proceeding with all shortcut tests

Shortcut004_OSD Edit Shortcut With Valid Key And Save
    [Documentation]    Edit OSD shortcut - system tries keys until valid one found
    Go To Dashboard
    Open Shortcuts Panel
   ${osd_keys}=    Create List
...    Alt+p    Alt+k    Alt+j    Alt+n    Alt+b
    ${assigned}=    Set Valid Shortcut And Save    ${OSD_MENU_BTN}    ${osd_keys}
    Log    OSD shortcut assigned: ${assigned}