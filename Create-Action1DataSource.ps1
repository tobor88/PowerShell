# The below script is used to create an Action1 data_source object. The API is new and bugged as of 3/10/2022 and is unable to complete these actions just yet

# Authenticate to Action1 API
$Url = "https://app.action1.com/api/3.0"
$Body = @{
    client_id="api-key-asdf...@action1.com"
    client_secret="00000000000000000000000000000000"                     
}  # End Body
$Response = Invoke-WebRequest -Uri "$Url/oauth2/token" -ContentType "application/x-www-form-urlencoded" -Method POST -Body $Body


# Get the JWT Token from above authentication and create header
$JWT = $Response.Content | ConvertFrom-Json | Select-Object -ExpandProperty access_token
$Header = @{
    Authorization="Bearer $JWT"
}  # End Token


# Check if data source already exists
# ORG-ID CAN ONLY BE SET TO ALL LAST CHECKED 3/10/2022
$DataSource = Invoke-WebRequest -Uri "$Url/data_sources/all/your-data-source-id" -Headers $Header -Method GET -ContentType "application/x-www-form-urlencoded" -ErrorVariable Error

If ($Error) {

    # Data source should only be created onece then updated after that. If the data source does not exist this section creates it
    $Columns = @{}
    $Columns.ProcessName
    $Columns.Id
    $Columns.MachineName
    
    $PostData = @{
        id = "your-data-source-id"
        type = "DataSource"
        name = "Your Data Source Name"
        builtin = "no"
        self = "$Url/data_sources/all/your-data-source-id"
        status = "Draft"
	      description = "Description of your data source"
        language = "PowerShell"
	      script_text = 'Get-Process # Your script here should return a PSObject. You can define the property values you want returned using the $Columns variable above'
        columns = $Columns
    }  # End PostData
    $StoreResult = Invoke-WebRequest -Uri "$Url/data_sources/all" -Headers $Header -Method POST -ContentType "application/x-www-form-urlencoded" -Body ($PostData | ConvertTo-Json)
    
}  # End If
Else {

    # This updates an already existing data_source because it does not need to be created again
    $PublishedResult = Invoke-WebRequest -Uri "$Url/data_sources/all/your-data-source-id" -Headers $Header -Method PATCH -ContentType "application/x-www-form-urlencoded"

}  # End Else
