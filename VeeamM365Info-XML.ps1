<#
    .SYNOPSIS
    This script checks the license and version of Veeam for Microsoft 365.
    It collects detailed information and creates an XML file as output.

    .INPUTS
    None

    .OUTPUTS
    The script creates a XML file formated for PRTG.

    .LINK
    https://raw.githubusercontent.com/tn-ict/Public/master/Disclaimer/DISCLAIMER

    .NOTES
    Author  : Andreas Bucher
    Version : 1.0.0
    Purpose : XML-Part of the PRTG-Sensor VeeamM365Info

    .EXAMPLE
    Run this script with task scheduler use powershell.exe as program and the following parameters:
    -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "C:\Script\VeeamM365Info-XML.ps1"
    This will place a file in C:\Temp\VeeamResults where it can be retreived by the PRTG sensor
#>
#----------------------------------------------------------[Declarations]----------------------------------------------------------
# Use TLS1.2 for Invoke-Webrequest
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# General parameters
$nl               = [Environment]::NewLine
$resultFolder     = "C:\Temp\VeeamResults"
$resultxml        = "VeeamM365Info.xml"

# PRTG parameters
$ExpWarning = 30 # Warninglevel in days for license expiry
$ExpError   = 14 # Errorlevel in days for license expiry

# Define VeeamInfos object and parameters
$VeeamInfos = [PSCustomObject]@{
    Value             = 0
    Text              = ""
    Warning           = 0
    Error             = 0
    FullVersion       = 0
    Version           = 0
    Build             = 0
    SupportId         = 0
    LicenseStatus     = ""
    ExpirationDate    = 0
    ExpirationDays    = 0
    Licensed          = 0
    Used              = 0
}

#-----------------------------------------------------------[Functions]------------------------------------------------------------
# Export XML
function Set-XMLContent {
    param(
        $VeeamInfos
    )

    $VeeamInfos.Text = $VeeamInfos.Text + " - Veeam Backup & Replication v." + $VeeamInfos.FullVersion

    # Create XML-Content
    $result= ""
    $result+= '<?xml version="1.0" encoding="UTF-8" ?>' + $nl
    $result+= "<prtg>" + $nl

    $result+=   "<Error>$($VeeamInfos.Error)</Error>" + $nl
    $result+=   "<Text>$($VeeamInfos.Text)</Text>" + $nl

    $result+=   "<result>" + $nl
    $result+=   "  <channel>Status</channel>" + $nl
    $result+=   "  <value>$($VeeamInfos.Value)</value>" + $nl
    $result+=   "  <Warning>$($VeeamInfos.Warning)</Warning>" + $nl
    $result+=   "  <LimitMaxWarning>2</LimitMaxWarning>" + $nl
    $result+=   "  <LimitMaxError>3</LimitMaxError>" + $nl
    $result+=   "  <LimitMode>1</LimitMode>" + $nl
    $result+=   "  <showChart>1</showChart>" + $nl
    $result+=   "  <showTable>1</showTable>" + $nl
    $result+=   "</result>" + $nl

    $result+=   "<result>" + $nl
    $result+=   "  <channel>Version</channel>" + $nl
    $result+=   "  <value>$($VeeamInfos.Version)</value>" + $nl
    $result+=   "  <Float>1</Float>" + $nl
    $result+=   "  <DecimalMode>All</DecimalMode>" + $nl
    $result+=   "  <showChart>0</showChart>" + $nl
    $result+=   "  <showTable>0</showTable>" + $nl
    $result+=   "</result>" + $nl

    $result+=   "<result>" + $nl
    $result+=   "  <channel>Build</channel>" + $nl
    $result+=   "  <value>$($VeeamInfos.Build)</value>" + $nl
    $result+=   "  <showChart>0</showChart>" + $nl
    $result+=   "  <showTable>0</showTable>" + $nl
    $result+=   "</result>" + $nl

    $result+=   "<result>" + $nl
    $result+=   "  <channel>SupportID</channel>" + $nl
    $result+=   "  <value>$($VeeamInfos.SupportId)</value>" + $nl
    $result+=   "  <showChart>0</showChart>" + $nl
    $result+=   "  <showTable>0</showTable>" + $nl
    $result+=   "</result>" + $nl

    $result+=   "<result>" + $nl
    $result+=   "  <channel>License expiry</channel>" + $nl
    $result+=   "  <value>$($VeeamInfos.ExpirationDays)</value>" + $nl
    $result+=   "  <CustomUnit>Days</CustomUnit>" + $nl
    $result+=   "  <LimitMinWarning>$ExpWarning</LimitMinWarning>" + $nl
    $result+=   "  <LimitWarningMsg>Lizenz läuft aus</LimitWarningMsg>" + $nl
    $result+=   "  <LimitMinError>$ExpError</LimitMinError>" + $nl
    $result+=   "  <LimitErrorMsg>Lizenz läuft aus</LimitErrorMsg>" + $nl
    $result+=   "  <LimitMode>1</LimitMode>" + $nl
    $result+=   "  <showChart>1</showChart>" + $nl
    $result+=   "  <showTable>1</showTable>" + $nl
    $result+=   "</result>" + $nl

    $result+=   "<result>" + $nl
    $result+=   "  <channel>Verfügbare Lizenzen</channel>" + $nl
    $result+=   "  <value>$($VeeamInfos.Licensed)</value>" + $nl
    $result+=   "  <showChart>1</showChart>" + $nl
    $result+=   "  <showTable>1</showTable>" + $nl
    $result+=   "</result>" + $nl

    $result+=   "<result>" + $nl
    $result+=   "  <channel>Benutzte Lizenzen</channel>" + $nl
    $result+=   "  <value>$($VeeamInfos.Used)</value>" + $nl
    $result+=   "  <LimitMaxWarning>$($VeeamInfos.Licensed)</LimitMaxWarning>" + $nl
    $result+=   "  <LimitWarningMsg>Lizenzen aufgebraucht</LimitWarningMsg>" + $nl
    $result+=   "  <LimitMode>1</LimitMode>" + $nl
    $result+=   "  <showChart>1</showChart>" + $nl
    $result+=   "  <showTable>1</showTable>" + $nl
    $result+=   "</result>" + $nl

    $result+= "</prtg>" + $nl

    # Write XML-File
    if(-not (test-path $resultFolder)){ New-Item -Path $resultFolder -ItemType Directory }
    $xmlFilePath = "$resultFolder\$resultxml"
    $result | Out-File $xmlFilePath -Encoding utf8

}
# Get Veeam License Status
function Get-LicenseStatus {
    param(
        $VeeamInfos
    )

    # Get License Status
    if     ($VeeamInfos.LicenseStatus -eq "Valid")         { $VeeamInfos.Value = 1; $VeeamInfos.Warning = 0; $VeeamInfos.Error = 0; $VeeamInfos.Text = "Lizenz valid" }
    elseif ($VeeamInfos.LicenseStatus -eq "Invalid")       { $VeeamInfos.Value = 3; $VeeamInfos.Warning = 0; $VeeamInfos.Error = 1; $VeeamInfos.Text = "Lizenz invalid" }
    elseif ($VeeamInfos.LicenseStatus -eq "Expired")       { $VeeamInfos.Value = 2; $VeeamInfos.Warning = 1; $VeeamInfos.Error = 0; $VeeamInfos.Text = "Lizenz ausgelaufen" }
    elseif ($VeeamInfos.LicenseStatus -eq "Not Installed") { $VeeamInfos.Value = 2; $VeeamInfos.Warning = 1; $VeeamInfos.Error = 0; $VeeamInfos.Text = "Lizenz nicht installiert" }
    elseif ($VeeamInfos.LicenseStatus -eq "Warning")       { $VeeamInfos.Value = 2; $VeeamInfos.Warning = 1; $VeeamInfos.Error = 0; $VeeamInfos.Text = "Lizenz Warning" }
    elseif ($VeeamInfos.LicenseStatus -eq "Error")         { $VeeamInfos.Value = 3; $VeeamInfos.Warning = 0; $VeeamInfos.Error = 1; $VeeamInfos.Text = "Lizenz Error" }
    else                                                   { $VeeamInfos.Value = 3; $VeeamInfos.Warning = 0; $VeeamInfos.Error = 1; $VeeamInfos.Text = "Lizenz unbekannter Fehler" }

    Return $VeeamInfos
}
#-----------------------------------------------------------[Execute]------------------------------------------------------------
# Get license infos
$License = Get-VBOLicense

# Fill license status
$VeeamInfos.LicenseStatus  = $License.Status
$VeeamInfos.ExpirationDate = $License.ExpirationDate
$VeeamInfos.ExpirationDays = ($License.ExpirationDate - (Get-Date)).Days
$VeeamInfos.SupportId      = $License.SupportId

# Get license usage
$VeeamInfos.Licensed = $License.TotalNumber
$VeeamInfos.Used     = (Get-VBOLicensedUser).Count

# Get license status
$VeeamInfos = Get-LicenseStatus $VeeamInfos

# Get version infos
$Fullversion            = Get-VBOVersion
$VeeamInfos.FullVersion = $Fullversion.ProductVersion

# Parse and fill version and build
$Version            = $FullVersion.ProductVersion.Split(".")
$Build              = $Version[3].Split(" ")
$VeeamInfos.Version = $Version[0] + "." + $Version[1]
$VeeamInfos.Build   = $Build[0]

# Return XML
Set-XMLContent $VeeamInfos