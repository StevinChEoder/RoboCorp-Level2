*** Settings ***
Documentation       Order robots from the website RobotSPareBin Industries Inc.
...                 Saves the order receipt for each as a pdf
...                 Saves the screenshot of each robot inside the pdf
...                 Creates a zip file of the orders

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             html_tables.py
Library             Collections
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the csv file
    Get Orders
    Loop through the orders
    Create a zip archive of the orders pdfs
    Close the RobotSpareBin Website


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}

Get Orders
    ${Orders}=    Read table from CSV    orders.csv
    RETURN    ${Orders}

Loop through the orders
    ${Orders}=    Get Orders

    FOR    ${order}    IN    @{Orders}
        # Log    ${order}[Address]
        Fill the form    ${order}
    END

Close the annoying modal and get mapping of part numbers
    Click Button    xpath://button[contains(text(),'OK')]
    Click Button    xpath://button[contains(text(),'Show model info')]
    Wait Until Page Contains Element    xpath://table[@id='model-info']
    ${html_table}=    Get Element Attribute    xpath://table[@id='model-info']    outerHTML
    ${table}=    Read Table From Html    ${html_table}
    &{dictPartNos}=    Create Dictionary

    FOR    ${row}    IN    @{table}
        ${key}=    Set Variable    ${row}[${1}]
        ${value}=    Set Variable    ${row}[${0}]
        Set To Dictionary    ${dictPartNos}    ${key}    ${value}
        # Log    ${row}[${0}]
    END

    # Below loop is only for debugging
    # FOR    ${key}    IN    @{dictPartNos}
    # ${value}=    Set Variable    ${dictPartNos}[${key}]
    # Log    ${key}=${value}
    # END

Fill the form
    [Arguments]    ${order}
    Close the annoying modal and get mapping of part numbers
    # Log    ${order}[Head]
    # Log    xpath://option[@value='${order}[Head]']
    Select From List By Value    xpath://select[@id='head']    ${order}[Head]
    Click Element    xpath://input[@value='${order}[Body]']
    Input Text    xpath://input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text    xpath://input[@id='address']    ${order}[Address]
    Click Button    xpath://button[@id='preview']
    Click Button    xpath://button[@id='order']
    ${ElementExists}=    Is Element Visible    //div[@class='alert alert-danger']
    WHILE    $ElementExists
        Click Button    xpath://button[@id='order']
        ${ElementExists}=    Is Element Visible    //div[@class='alert alert-danger']
    END
    ${ReceiptFilePath}=    Save the receipt as a pdf    ${order}[Order number]
    ${imageFilePath}=    Take a screenshot of the robot    ${order}[Order number]
    ${listOfImage}=    Create List    ${imageFilePath}
    Add Files To Pdf    ${listOfImage}    ${ReceiptFilePath}    ${True}
    Remove File    ${imageFilePath}
    Click Button    xpath://button[@id='order-another']

Save the receipt as a pdf
    [Arguments]    ${ReceiptName}
    Wait Until Page Contains Element    xpath://div[@id='receipt']
    ${receipt_html}=    Get Element Attribute    //div[@id='receipt']    outerHTML
    ${ReceiptFilePath}=    Set Variable    ${OUTPUT_DIR}${/}Orders${/}${ReceiptName}.Pdf
    Html To Pdf    ${receipt_html}    ${ReceiptFilePath}
    RETURN    ${ReceiptFilePath}

Take a screenshot of the robot
    [Arguments]    ${ReceiptName}
    Wait Until Page Contains Element    xpath://div[@id='robot-preview-image']
    ${image_html}=    Get Element Attribute    //div[@id='robot-preview-image']    outerHTML
    ${imageFilePath}=    Set Variable    ${OUTPUT_DIR}${/}Orders${/}${ReceiptName}.png
    Screenshot    //div[@id='robot-preview-image']    ${imageFilePath}
    RETURN    ${imageFilePath}

Create a zip archive of the orders pdfs
    ${zipFileName}=    Set Variable    ${OUTPUT_DIR}${/}Orders.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Orders    ${zipFileName}

Close the RobotSpareBin Website
    Close Browser
