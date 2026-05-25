*** Settings ***
Library             Browser
Library             RequestsLibrary
Library             Collections
Library             OperatingSystem
Resource            Resource/keywords.robot

*** Variables ***
${REBOOT_TIMEOUT}       180s
${POLL_INTERVAL}        10s
${AUTH_ENDPOINT}        /auth/v1/users/login
${REBOOT_ENDPOINT}      /mgmt/v1/reboot
${HEALTH_ENDPOINT}      /mgmt/v1/healthstatus/ishealthy

*** Test Cases ***

Reboot Device And Verify Recovery
    [Documentation]    Triggers a device reboot via API and waits for recovery via health endpoint
    [Teardown]    Run Keyword If Test Failed    Log    Test failed — no browser open for screenshot

    # Step 1: Get auth token
    ${token}=    Get Auth Token Via API

    # Step 2: Trigger reboot
    Trigger Reboot Via API    ${token}

    # Step 3: Wait for device to go offline
    Wait For Device To Go Offline

    # Step 4: Poll until device is healthy again (3 min timeout)
    Wait For Device To Come Back Online

    Log    Device successfully rebooted and is healthy

    # Step 5: WebUI verification (reserved for future use)
    # Open Browser To Login Page
    # Navigate To Login Page
    # Enter Credentials    ${USERNAME}    ${PASSWORD}
    # Highlight Element    ${EYE_BUTTON}
    # Click    ${EYE_BUTTON}
    # Sleep    1s
    # Highlight Element    ${LOGIN_BUTTON}
    # Click    ${LOGIN_BUTTON}
    # Wait For Elements State    ${DASHBOARD_HEADER}    visible    timeout=15s
    # Log    Device successfully rebooted and WebUI is accessible
    # Logout
    # Close Browser

*** Keywords ***

Get Auth Token Via API
    [Documentation]    POSTs to auth endpoint with Basic Auth and returns Bearer token
    Evaluate            __import__('urllib3').disable_warnings()    modules=urllib3
    ${base_url}=        Set Variable    https://${DEVICE_IP}
    ${auth}=            Create List     ${USERNAME}    ${PASSWORD}
    Create Session      avio2_auth    ${base_url}    verify=False    auth=${auth}
    ${headers}=         Create Dictionary    Content-Type=application/json
    ${response}=        POST On Session
    ...                 avio2_auth
    ...                 ${AUTH_ENDPOINT}
    ...                 headers=${headers}
    ...                 expected_status=200
    ${token}=           Get From Dictionary    ${response.json()}    accessToken
    Log                 Auth token retrieved successfully
    RETURN              ${token}

Trigger Reboot Via API
    [Documentation]    POSTs to reboot endpoint using Bearer token
    [Arguments]         ${token}
    ${base_url}=        Set Variable    https://${DEVICE_IP}
    Create Session      avio2_mgmt    ${base_url}    verify=False
    ${headers}=         Create Dictionary
    ...                 Authorization=Bearer ${token}
    ...                 Content-Type=application/json
    ${response}=        POST On Session
    ...                 avio2_mgmt
    ...                 ${REBOOT_ENDPOINT}
    ...                 headers=${headers}
    ...                 expected_status=any
    Log                 Reboot triggered. Response status: ${response.status_code}
    Sleep               3s

Wait For Device To Go Offline
    [Documentation]    Polls ishealthy until the device stops responding (confirming reboot started)
    Log                 Waiting for device to go offline...
    FOR    ${i}    IN RANGE    12
        ${status}=    Run Keyword And Return Status
        ...           GET On Session    avio2_mgmt    ${HEALTH_ENDPOINT}    expected_status=200
        IF    not ${status}
            Log    Device is offline. Reboot confirmed started.
            RETURN
        END
        Sleep    5s
    END
    Log    Warning: Device did not appear to go offline within 60s — continuing anyway

Wait For Device To Come Back Online
    [Documentation]    Polls ishealthy every 10s for up to 3 minutes until true is returned
    Log                 Polling for device recovery (timeout: ${REBOOT_TIMEOUT})...
    ${start_time}=      Get Time    epoch
    FOR    ${i}    IN RANGE    18
        ${elapsed}=    Evaluate    int(__import__('time').time()) - ${start_time}
        Log             Poll attempt ${i+1} — ${elapsed}s elapsed
        ${status}=      Run Keyword And Return Status
        ...             GET On Session    avio2_mgmt    ${HEALTH_ENDPOINT}    expected_status=200
        IF    ${status}
            ${response}=    GET On Session    avio2_mgmt    ${HEALTH_ENDPOINT}
            ${body}=        Convert To String    ${response.text}
            IF    '${body.strip()}' == 'true'
                Log    Device is back online and healthy!
                RETURN
            END
        END
        Log             Device not ready yet. Waiting ${POLL_INTERVAL}...
        Sleep           ${POLL_INTERVAL}
    END
    Fail    Device did not recover within ${REBOOT_TIMEOUT}