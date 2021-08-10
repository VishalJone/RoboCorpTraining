*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library            RPA.Browser.Selenium
Library            RPA.Excel.Files
Library            RPA.HTTP
Library            RPA.PDF
Library            Process 
Library            RPA.FileSystem
Library            RPA.Tables
Library            RPA.Archive
Library            RPA.Dialogs
Library            RPA.Robocloud.Secrets

*** Variables ***
${GLOBAL_RETRY_AMOUNT}    5x
${GLOBAL_RETRY_INTERVAL}    0.5s

*** Keywords ***
CSV dialog
    Add heading     User information  size=Small 
    Add text input  CSVURL          label=Url of the CSV
    ${result}=      Run dialog
    Download    ${result}[CSVURL]    overwrite=true


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    Robotsecret
    Open Available Browser    ${secret}[websiteURL]
    Close Modal Box


*** Keywords ***
Close Modal Box
    Click Button   OK


*** Keywords ***
Fill the form from CSV file
    ${table}=    Read table from CSV    orders.csv    header=True
    FOR    ${table_row}    IN    @{table}
        Wait Until Keyword Succeeds   ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Fill the Form for One    ${table_row}
    END

    
*** Keywords ***
#Create a PDF and a Screenshot that is store in a temp file 
#then adds both of them in a single PDF. 
Create Screenshot and PDF
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}receipt${/}temps${/}${order_number}_image.png
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipt${/}temps${/}${order_number}_html.pdf
    ${files}=    Create List
    ...    ${CURDIR}${/}output${/}receipt${/}temps${/}${order_number}_html.pdf
    ...    ${CURDIR}${/}output${/}receipt${/}temps${/}${order_number}_image.png
    Add Files To Pdf    ${files}    ${CURDIR}${/}output${/}receipt${/}Fullorder${order_number}.pdf


*** Keywords ***
Clear temps file
    Remove Directory    ${CURDIR}${/}output${/}receipt${/}temps    recurvise=True


*** Keywords ***
#Input Text, click preview Button and save to PDF + Screenshot the preview
Fill the Form for One
    [Arguments]    ${table_row}
    Select From List By Value    id:head    ${table_row}[Head]
    Select Radio Button    body     ${table_row}[Body]
    Input Text    //*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input   ${table_row}[Legs]
    Input Text    id:address    ${table_row}[Address]
    Click Button    id:preview
    Click Button    id:order
    Create Screenshot and PDF    ${table_row}[Order number]
    Click Button    id:order-another
    Close Modal Box
    

*** Keywords ***
Zip all PDF
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipt    ${CURDIR}${/}output${/}receipt.zip    recursive=True        


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    CSV dialog
    Open the robot order website
    Fill the form from CSV file
    Clear temps file
    Zip all PDF