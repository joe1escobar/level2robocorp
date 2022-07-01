*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${CURDIR}${/}temp
${RPA_SECRET_MANAGER}               RPA.Robocorp.Vault.FileSecrets
${RPA_SECRET_FILE}                  .\\vault.json


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${inputParam}=    Collect input parameter from user
    Open the robot order website
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ${orders}=    Get orders    ${inputParam}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        #Submit the order
        Wait Until Keyword Succeeds    5x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the robot order browser


*** Keywords ***
Open the robot order website
    ${url}=    Get Secret    url
    Open Available Browser    ${url}[string]

Get orders
    [Arguments]    ${inputParam}

    Download    https://robotsparebinindustries.com/${inputParam.url}    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Close the annoying modal
    Click Button    css:button.btn-dark

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input.form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Wait Until Element Is Visible    id:robot-preview
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${order}.pdf
    RETURN    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${order}.pdf

Take a screenshot of the robot
    [Arguments]    ${order}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${order}.png
    RETURN    ${OUTPUT_DIR}${/}${order}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open PDF    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${OUTPUT_DIR}/receipts.zip

Collect input parameter from user
    Add heading    URL
    Add text input    url
    ...    label=URL
    ...    placeholder=Enter url to get orders csv file
    ...    rows=1
    ${result}=    Run dialog
    RETURN    ${result}

Close the robot order browser
    Close Browser
