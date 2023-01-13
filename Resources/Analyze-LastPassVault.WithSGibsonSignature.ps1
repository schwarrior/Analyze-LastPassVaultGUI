# Analyze-LastPassVaultGUI PowerShell script
# Written by Rob Woodruff with help from ChatGPT and Steve Gibson
# More information and updates can be found at https://github.com/FuLoRi/Analyze-LastPassVaultGUI

# PURPOSE:
# This script prompts the user for the XML contents of their LastPass vault (input file) and the location,
# name, and format (HTML or CSV) of the analysis file (output file). The script then does the following:
#    1) Decodes the hex-encoded URL into human-readable ASCII characters
#    2) Marks fields encrypted with CBC as "OK"
#    3) Marks fields encrypted with ECB with a warning message
#    4) Marks empty fields (only the ones that are normally encrypted) as "Blank" 
#    5) Generates the requested output file
#    6) Displays a status message

# LICENSE:
# This software is licensed under GNU General Public License (GPL) v3.

# DISCLAIMER:
# By downloading, installing, or using this software, you agree to the terms of this software disclaimer.
# This software is provided “as is” and no warranties, either expressed or implied, are made regarding its
# accuracy, reliability, or performance. The user assumes the entire risk associated with the use and
# performance of this software. In no event shall the creators and/or distributors of this software be liable
# for any damages, including, but not limited to, direct, indirect, special, incidental, or consequential
# damages arising out of the use of or inability to use this software, even if the creators and/or
# distributors of this software have been advised of the possibility of such damages.

# Set the version number and date
$scriptVersion = "1.1"
$scriptDate = "2023-01-08"

# Load the System.Windows.Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create the GUI form
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(620, 560)
$form.StartPosition = "CenterScreen"
$form.Text = "Analyze LastPass Vault"

# Create the "Instructions" group
$instructionsGroup = New-Object System.Windows.Forms.GroupBox
$instructionsGroup.Size = New-Object System.Drawing.Size(580, 290)
$instructionsGroup.Location = New-Object System.Drawing.Point(10, 10)
$instructionsGroup.Text = "Instructions for use"

$instructionsText = @'
1. Press the "Copy Query" button below to copy a short 3-line JavaScript query to your clipboard.

2. Open Chrome or Edge. Login to LastPass so that you're looking at your vault.

3. Press F12 to open the developer tools. Select the "Console" tab to move to that view. You'll have a cursor.

4. Paste the JavaScript query into the console and press "Enter". Your page will fill with a large XML dump.

5. Look carefully at the bottom of the page for the "Show More" and "Copy" options.

6. Click "Copy" to copy all of that query response data onto the clipboard.

7. Return here and press the "Paste" button to paste the vault XML into the text field. This may take a moment.

8. Specify your desired location, name, and format for the output file and click "Analyze".

9. Open the output file to see the decoded URLs and a brief analysis of each encrypted field.
Note: "OK" means it's encrypted with CBC, "Blank" means the field is empty, and a warning means it's encrypted with ECB.
'@

# Create the instructions label
$instructionsLabel = New-Object System.Windows.Forms.Label
$instructionsLabel.Location = New-Object System.Drawing.Point(10, 20)
$instructionsLabel.Size = New-Object System.Drawing.Size(560, 240)
$instructionsLabel.Text = $instructionsText

# Create the "Copy Query" button
$copyQueryButton = New-Object System.Windows.Forms.Button
$copyQueryButton.Size = New-Object System.Drawing.Size(75, 23)
$copyQueryButton.Location = New-Object System.Drawing.Point(250, 260)
$copyQueryButton.Text = "Copy Query"

# Add an action when the "Copy Query" button is clicked
$copyQueryButton.Add_Click({
	# Create a literal multiline string containing the JavaScript query
	$jsQuery=@'
fetch("https://lastpass.com/getaccts.php", {method: "POST"})
  .then(response => response.text())
  .then(text => console.log(text.replace(/>/g, ">\n")));
'@
	
    # Copy the text to the clipboard
    [System.Windows.Forms.Clipboard]::SetText($jsQuery)

})

# Add the instructions label to the instructions group
$instructionsGroup.Controls.Add($instructionsLabel)

# Add the "Copy Query" button to the "Instructions" group
$instructionsGroup.Controls.Add($copyQueryButton)

# Add the instructions group to the form
$form.Controls.Add($instructionsGroup)

# Create the left pane
$leftPane = New-Object System.Windows.Forms.GroupBox
$leftPane.Size = New-Object System.Drawing.Size(280, 200)
$leftPane.Location = New-Object System.Drawing.Point(10, 310)
$leftPane.Text = "Provide LastPass vault XML"

# Create the radio buttons for the left pane
$browseXMLRadio = New-Object System.Windows.Forms.RadioButton
$browseXMLRadio.Size = New-Object System.Drawing.Size(75, 17)
$browseXMLRadio.Location = New-Object System.Drawing.Point(10, 20)
$browseXMLRadio.Text = "Browse"
$browseXMLRadio.Checked = $false
$browseXMLRadio.Add_CheckedChanged({
	$xmlBrowseField.Enabled = $true
	$browseXMLButton.Enabled = $true
	$xmlPasteField.Enabled = $false
	$pasteXMLButton.Enabled = $false
})

$pasteXMLRadio = New-Object System.Windows.Forms.RadioButton
$pasteXMLRadio.Size = New-Object System.Drawing.Size(75, 17)
$pasteXMLRadio.Location = New-Object System.Drawing.Point(10, 70)
$pasteXMLRadio.Text = "Paste"
$pasteXMLRadio.Checked = $true
$pasteXMLRadio.Add_CheckedChanged({
	$xmlBrowseField.Enabled = $false
	$browseXMLButton.Enabled = $false
	$xmlPasteField.Enabled = $true
	$pasteXMLButton.Enabled = $true
})

# Create the "Browse" button for the left pane
$browseXMLButton = New-Object System.Windows.Forms.Button
$browseXMLButton.Size = New-Object System.Drawing.Size(75, 23)
$browseXMLButton.Location = New-Object System.Drawing.Point(195, 40)
$browseXMLButton.Text = "Browse"
$browseXMLButton.Enabled = $false

# Create the "Browse" text field for the left pane
$xmlBrowseField = New-Object System.Windows.Forms.TextBox
$xmlBrowseField.Size = New-Object System.Drawing.Size(165, 20)
$xmlBrowseField.Location = New-Object System.Drawing.Point(10, 40)
$xmlBrowseField.Enabled = $false

# Create the "Paste" button for the left pane
$pasteXMLButton = New-Object System.Windows.Forms.Button
$pasteXMLButton.Size = New-Object System.Drawing.Size(75, 23)
$pasteXMLButton.Location = New-Object System.Drawing.Point(10, 90)
$pasteXMLButton.Text = "Paste"
$pasteXMLButton.Enabled = $true

# Create the "Paste" text field for the left pane
$xmlPasteField = New-Object System.Windows.Forms.TextBox
$xmlPasteField.Size = New-Object System.Drawing.Size(260, 60)
$xmlPasteField.Location = New-Object System.Drawing.Point(10, 120)
$xmlPasteField.Multiline = $true
$xmlPasteField.ScrollBars = "Vertical"
$xmlPasteField.Enabled = $true

# Add the controls to the left pane
$leftPane.Controls.Add($browseXMLRadio)
$leftPane.Controls.Add($pasteXMLRadio)
$leftPane.Controls.Add($xmlBrowseField)
$leftPane.Controls.Add($browseXMLButton)
$leftPane.Controls.Add($xmlPasteField)
$leftPane.Controls.Add($pasteXMLButton)

# Create the right pane
$rightPane = New-Object System.Windows.Forms.GroupBox
$rightPane.Size = New-Object System.Drawing.Size(280, 110)
$rightPane.Location = New-Object System.Drawing.Point(310, 310)
$rightPane.Text = "Specify output file"

# Create the "File name" field and "Browse" button for the right pane
$fileNameTextField = New-Object System.Windows.Forms.TextBox
$fileNameTextField.Size = New-Object System.Drawing.Size(165, 20)
$fileNameTextField.Location = New-Object System.Drawing.Point(10, 30)

$browseOutputButton = New-Object System.Windows.Forms.Button
$browseOutputButton.Size = New-Object System.Drawing.Size(75, 23)
$browseOutputButton.Location = New-Object System.Drawing.Point(185, 30)
$browseOutputButton.Text = "Browse"

# Create the drop-down menu for the right pane
$formatLabel = New-Object System.Windows.Forms.Label
$formatLabel.Size = New-Object System.Drawing.Size(45, 13)
$formatLabel.Location = New-Object System.Drawing.Point(10, 70)
$formatLabel.Text = "Format:"

$formatMenu = New-Object System.Windows.Forms.ComboBox
$formatMenu.Size = New-Object System.Drawing.Size(60, 21)
$formatMenu.Location = New-Object System.Drawing.Point(60, 70)
$formatMenu.Items.AddRange(@("CSV", "HTML"))
$formatMenu.SelectedIndex = 0

# Create the "Analyze" button for the right pane
$analyzeButton = New-Object System.Windows.Forms.Button
$analyzeButton.Size = New-Object System.Drawing.Size(75, 23)
$analyzeButton.Location = New-Object System.Drawing.Point(185, 70)
$analyzeButton.Text = "Analyze"

# Add the controls to the right pane
$rightPane.Controls.Add($fileNameTextField)
$rightPane.Controls.Add($browseOutputButton)
$rightPane.Controls.Add($formatLabel)
$rightPane.Controls.Add($formatMenu)
$rightPane.Controls.Add($analyzeButton)

# Add the panes to the form
$form.Controls.Add($leftPane)
$form.Controls.Add($rightPane)

# Create the author label
$authorLabel = New-Object System.Windows.Forms.Label
$authorLabel.Size = New-Object System.Drawing.Size(130, 60)
$authorLabel.Location = New-Object System.Drawing.Point(310, 440)
$authorLabel.Text = @"
Written by Rob Woodruff
Version: $scriptVersion
Date: $scriptDate
"@

# Add the author label to the form
$form.Controls.Add($authorLabel)

# Create the "Check for updates" button
$checkForUpdatesButton = New-Object System.Windows.Forms.Button
$checkForUpdatesButton.Size = New-Object System.Drawing.Size(130, 23)
$checkForUpdatesButton.Location = New-Object System.Drawing.Point(460, 440)
$checkForUpdatesButton.Text = "Check for updates"

# Open the URL in the default web browser when the button is clicked
$checkForUpdatesButton.Add_Click({
	Start-Process "https://github.com/FuLoRi/Analyze-LastPassVaultGUI/"
})

# Add the "Check for updates" button to the form
$form.Controls.Add($checkForUpdatesButton)

# Set up the browse button to open a file selection dialog
$browseXMLButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "XML files (*.xml)|*.xml"
    if ($openFileDialog.ShowDialog() -eq "OK") {
		# Insert the selected file's path into the existing text field
		$xmlBrowseField.Text = $openFileDialog.FileName

		# Clear the contents of the "Paste" text field
		$xmlPasteField.Text = ""
    }
})

# Add an event handler for the "Paste" button's "Click" event
$pasteXMLButton.Add_Click({
	# Read the contents of the clipboard and insert it into the "Paste" text field
    $xmlPasteField.Text = [System.Windows.Forms.Clipboard]::GetText()

	# Convert the XML content to an XML object
	[xml]$xml = $xmlPasteField.Text
})

# Set up the browse button to open a folder selection dialog
$browseOutputButton.Add_Click({
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
	$saveFileDialog.Filter = "CSV files (*.csv)|*.csv|HTML files (*.html)|*.html"
    if ($saveFileDialog.ShowDialog() -eq "OK") {
        $fileNameTextField.Text = $saveFileDialog.FileName
    }
})

# Set up the "Analyze" button to run
$analyzeButton.Add_Click({
	# Check if the "Browse" radio button is checked
	if ($browseXMLRadio.Checked) {
		# Use the contents of the "Browse" text field as the input file
		$InFile = $xmlBrowseField.Text
	}
	else {
		# Set $InFile to a dummy value since it won't be used
		$InFile = "<xml>"
	}

    # Check which input method is being used
    if ($pasteXMLRadio.Checked) {
        # Validate the pasted XML data
        if (-not $xmlPasteField.Text) {
            # Display an error message if the pasted data is empty
            [System.Windows.Forms.MessageBox]::Show("Please enter or paste XML data into the text field.")
			return
        }
        else {
            # Set the XML data variable to the pasted data
            [xml]$xml = $xmlPasteField.Text

            # Proceed with the rest of the script here...
        }
    }
    else {
        # Validate the input file path
        if (-not $xmlBrowseField.Text) {
            # Display an error message if the file path is empty
            [System.Windows.Forms.MessageBox]::Show("Please enter a valid file path.")
			return
        }
        else {
            # Check if the input file exists
            if (-not (Test-Path -Path $xmlBrowseField.Text)) {
                # Display an error message if the file does not exist
                [System.Windows.Forms.MessageBox]::Show("The specified file does not exist.")
				return
            }
            else {
                # Set the XML data variable to the contents of the input file
                [xml]$xml = Get-Content -Path $InFile

                # Proceed with the rest of the script here...
            }
        }
    }
	
   # Set the script parameters
    $OutFile = $fileNameTextField.Text
    $Format = $formatMenu.SelectedItem

     # Load the XML into a variable
	if ($browseXMLRadio.Checked) {
		[xml]$xml = Get-Content -Path $InFile
	} else {
		[xml]$xml = $xmlPasteField.Text
	}

    # Initialize an empty array to store the results
    $results = @()

    # Iterate over the account elements in the XML file
    foreach ($account in $xml.response.accounts.account) {
        # Initialize a new object to store the data for this account
        $result = [pscustomobject]@{
            Name = $account.name
            URL = $account.url
            ID = $account.id
            Group = $account.group
            Extra = $account.extra
            IsBookmark = $account.isbookmark
            NeverAutofill = $account.never_autofill
            LastTouch = $account.last_touch
            LastModified = $account.last_modified
            LaunchCount = $account.launch_count
            UserName = $account.login.u
            Password = $account.login.p
        }

        # Convert the hexadecimal values to text/ASCII
        $hex = $result.URL
        if (-not [System.Text.RegularExpressions.Regex]::IsMatch($hex, '^[0-9a-fA-F]+$')) {
            # String is not a hexadecimal string
            $result.URL = "ERROR: Invalid hexadecimal string."
        } else {
            $result.URL = (-join($hex|sls ".."-a|% m*|%{[char]+"0x$_"}))
        }

        # Use a regular expression to identify values encrypted with ECB
        $pattern = '^!'
        $encryptedValues = @('Name', 'Extra', 'UserName', 'Password', 'Group')

        foreach ($encryptedValue in $encryptedValues) {
            if (!$result.$encryptedValue) {
                # Value is blank
                $result.$encryptedValue = "Blank"
            } elseif ($result.$encryptedValue -match $pattern) {
                # Value is encrypted with CBC
                $result.$encryptedValue = "OK"
            } else {
                # Value is encrypted with ECB
                $result.$encryptedValue = "WARNING: Encrypted with ECB!"
            }
        }

        # Add the result object to the array
        $results += $result
    }

    # Save the output file
    if ($Format -eq "CSV") {
        $results | Export-Csv -Path $OutFile -NoTypeInformation
    } else {
        $html = $results | ConvertTo-Html -Fragment
        $html | Out-File -FilePath $OutFile
    }

    # Show a success message
    [System.Windows.Forms.MessageBox]::Show("Analysis complete.", "Success", "OK", "Information")
	
	# Open the output file in the default viewer
	Start-Process $OutFile
})

# Display the GUI form
$form.ShowDialog()

# SIG # Begin signature block
# MIIihgYJKoZIhvcNAQcCoIIidzCCInMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTUOSSK95jVhKb7GOhc4Vp/jk
# Ov2ggh2HMIICPzCCAcWgAwIBAgIQBVVWvPJepDU1w6QP1atFcjAKBggqhkjOPQQD
# AzBhMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9v
# dCBHMzAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGExCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEczMHYwEAYHKoZI
# zj0CAQYFK4EEACIDYgAE3afZu4q4C/sLfyHS8L6+c/MzXRq8NOrexpu80JX28MzQ
# C7phW1FGfp4tn+6OYwwX7Adw9c+ELkCDnOg/QW07rdOkFFk2eJ0DQ+4QE2xy3q6I
# p6FrtUPOZ9wj/wMco+I+o0IwQDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQE
# AwIBhjAdBgNVHQ4EFgQUs9tIpPmhxdiuNkHMEWNpYim8S8YwCgYIKoZIzj0EAwMD
# aAAwZQIxAK288mw/EkrRLTnDCgmXc/SINoyIJ7vmiI1Qhadj+Z4y3maTD/HMsQmP
# 3Wyr+mt/oAIwOWZbwmSNuJ5Q3KjVSaLtx9zRSX8XAbjIho9OjIgrqJqpisXRAL34
# VOKa5Vt8sycXMIIDWTCCAt+gAwIBAgIQD7inQLkVjQNRQ7xZ2fBAKTAKBggqhkjO
# PQQDAzBhMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwg
# Um9vdCBHMzAeFw0yMTA0MjkwMDAwMDBaFw0zNjA0MjgyMzU5NTlaMGQxCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE8MDoGA1UEAxMzRGlnaUNl
# cnQgR2xvYmFsIEczIENvZGUgU2lnbmluZyBFQ0MgU0hBMzg0IDIwMjEgQ0ExMHYw
# EAYHKoZIzj0CAQYFK4EEACIDYgAEu7SsJ6VIDaJTX48ugT4vU3a4CJSimqqKi5i1
# sfD8KhW7ubOlIi/9asC94lVoYGuXNMFmU3Ej/BrVyiAPAkCio0paRqORUyuV8gPp
# q6bTh3Yv52SfnjVR/MNjNXh25Ph3o4IBVzCCAVMwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAdBgNVHQ4EFgQUm1+wNrqdBq4ZJ73AoCLAi4s4d+0wHwYDVR0jBBgwFoAUs9tI
# pPmhxdiuNkHMEWNpYim8S8YwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMHYGCCsGAQUFBwEBBGowaDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# ZGlnaWNlcnQuY29tMEAGCCsGAQUFBzAChjRodHRwOi8vY2FjZXJ0cy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRHbG9iYWxSb290RzMuY3J0MEIGA1UdHwQ7MDkwN6A1oDOG
# MWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEdsb2JhbFJvb3RHMy5j
# cmwwHAYDVR0gBBUwEzAHBgVngQwBAzAIBgZngQwBBAEwCgYIKoZIzj0EAwMDaAAw
# ZQIweL1JlWVxAdBGV2hlDmip3DYIwe791I7bQGU/Df+Tr8KuY4ajfsu0kVp47AcD
# Zwd8AjEA558f8QdbrDTGOLy1pVDO5uo4fj55kOSkW6sCDegH/FamWords1Cy3fL6
# ZnSe0BZjMIIE3DCCBGGgAwIBAgIQAol57pL7c+E4wqJkrc2goDAKBggqhkjOPQQD
# AzBkMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xPDA6BgNV
# BAMTM0RpZ2lDZXJ0IEdsb2JhbCBHMyBDb2RlIFNpZ25pbmcgRUNDIFNIQTM4NCAy
# MDIxIENBMTAeFw0yMjAzMzEwMDAwMDBaFw0yNTA0MjMyMzU5NTlaMIIBEDETMBEG
# CysGAQQBgjc8AgEDEwJVUzEbMBkGCysGAQQBgjc8AgECEwpDYWxpZm9ybmlhMR0w
# GwYDVQQPDBRQcml2YXRlIE9yZ2FuaXphdGlvbjERMA8GA1UEBRMIQzE0MTE4MTIx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1MYWd1
# bmEgTmlndWVsMSQwIgYDVQQKExtHaWJzb24gUmVzZWFyY2ggQ29ycG9yYXRpb24x
# JDAiBgNVBAsTG0dpYnNvbiBSZXNlYXJjaCBDb3Jwb3JhdGlvbjEkMCIGA1UEAxMb
# R2lic29uIFJlc2VhcmNoIENvcnBvcmF0aW9uMHYwEAYHKoZIzj0CAQYFK4EEACID
# YgAE/h8DgIMTNS8lfSb2Av0ZSI9o89Zoz0oGzk/ek+IUygcdMP10tnHEAG1+K3Az
# R2t+HUzstILqrnvtyQarGuJ5y0g+IrTHw7Fa68anLbMcSsKwZV4X7Q6dQA2we9DT
# Rnl4o4ICKDCCAiQwHwYDVR0jBBgwFoAUm1+wNrqdBq4ZJ73AoCLAi4s4d+0wHQYD
# VR0OBBYEFLuAz7K9CXmZcxBcT0ydnTl+p+loMDEGA1UdEQQqMCigJgYIKwYBBQUH
# CAOgGjAYDBZVUy1DQUxJRk9STklBLUMxNDExODEyMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzCBqwYDVR0fBIGjMIGgME6gTKBKhkhodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRHbG9iYWxHM0NvZGVTaWduaW5nRUND
# U0hBMzg0MjAyMUNBMS5jcmwwTqBMoEqGSGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEdsb2JhbEczQ29kZVNpZ25pbmdFQ0NTSEEzODQyMDIxQ0ExLmNy
# bDA9BgNVHSAENjA0MDIGBWeBDAEDMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cu
# ZGlnaWNlcnQuY29tL0NQUzCBjgYIKwYBBQUHAQEEgYEwfzAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFcGCCsGAQUFBzAChktodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRHbG9iYWxHM0NvZGVTaWduaW5nRUND
# U0hBMzg0MjAyMUNBMS5jcnQwDAYDVR0TAQH/BAIwADAKBggqhkjOPQQDAwNpADBm
# AjEA4NmolHe1l1/nGaZTm1lBxQt+gwcoqFcCxUMVhIqA/Vx8X7b/w3JSmJAj05sV
# hdumAjEAqOZy0LqlesjOrJ4eH1OrKqBD63Oac03iFZhD9F3lbfHkRfdfagOTfZev
# qG1jSv/nMIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0B
# AQwFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz
# 7MKnJS7JIT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS
# 5F/WBTxSD1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7
# bXHiLQwb7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfI
# SKhmV1efVFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jH
# trHEtWoYOAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14
# Ztk6MUSaM0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2
# h4mXaXpI8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt
# 6zPZxd9LBADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPR
# iQfhvbfmQ6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ER
# ElvlEFDrMcXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4K
# Jpn15GkvmB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAd
# BgNVHQ4EFgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SS
# y4IxLVGLp6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAC
# hjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURS
# b290Q0EuY3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRV
# HSAAMA0GCSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyh
# hyzshV6pGrsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO
# 0Cre+i1Wz/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo
# 8L8vC6bp8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++h
# UD38dglohJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5x
# aiNrIv8SuFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIGrjCCBJag
# AwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIw
# MzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQg
# UlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCw
# zIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34V6gCff1DtITaEfFz
# sbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ
# 7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7
# QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/teP
# c5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCY
# OjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9K
# oRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6
# dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM
# 1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbC
# dLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbEC
# AwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1N
# hS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9P
# MA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcB
# AQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggr
# BgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAI
# BgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7Zv
# mKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI
# 2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/ty
# dBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVP
# ulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQeJsG33irr9p6xeZmB
# o1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc
# 6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3c
# HXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0d
# KNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZP
# J/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLe
# Mt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDy
# Divl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBsAwggSooAMCAQICEAxNaXJLlPo8
# Kko9KQeAPVowDQYJKoZIhvcNAQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJT
# QTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTAeFw0yMjA5MjEwMDAwMDBaFw0z
# MzExMjEyMzU5NTlaMEYxCzAJBgNVBAYTAlVTMREwDwYDVQQKEwhEaWdpQ2VydDEk
# MCIGA1UEAxMbRGlnaUNlcnQgVGltZXN0YW1wIDIwMjIgLSAyMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAz+ylJjrGqfJru43BDZrboegUhXQzGias0BxV
# Hh42bbySVQxh9J0Jdz0Vlggva2Sk/QaDFteRkjgcMQKW+3KxlzpVrzPsYYrppijb
# kGNcvYlT4DotjIdCriak5Lt4eLl6FuFWxsC6ZFO7KhbnUEi7iGkMiMbxvuAvfTux
# ylONQIMe58tySSgeTIAehVbnhe3yYbyqOgd99qtu5Wbd4lz1L+2N1E2VhGjjgMtq
# edHSEJFGKes+JvK0jM1MuWbIu6pQOA3ljJRdGVq/9XtAbm8WqJqclUeGhXk+DF5m
# jBoKJL6cqtKctvdPbnjEKD+jHA9QBje6CNk1prUe2nhYHTno+EyREJZ+TeHdwq2l
# fvgtGx/sK0YYoxn2Off1wU9xLokDEaJLu5i/+k/kezbvBkTkVf826uV8MefzwlLE
# 5hZ7Wn6lJXPbwGqZIS1j5Vn1TS+QHye30qsU5Thmh1EIa/tTQznQZPpWz+D0CuYU
# bWR4u5j9lMNzIfMvwi4g14Gs0/EH1OG92V1LbjGUKYvmQaRllMBY5eUuKZCmt2Fk
# +tkgbBhRYLqmgQ8JJVPxvzvpqwcOagc5YhnJ1oV/E9mNec9ixezhe7nMZxMHmsF4
# 7caIyLBuMnnHC1mDjcbu9Sx8e47LZInxscS451NeX1XSfRkpWQNO+l3qRXMchH7X
# zuLUOncCAwEAAaOCAYswggGHMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAA
# MBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsG
# CWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6FtltTYUvcyl2mi91jGogj57IbzAdBgNV
# HQ4EFgQUYore0GH8jzEU7ZcLzT0qlBTfUpwwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0
# cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNI
# QTI1NlRpbWVTdGFtcGluZ0NBLmNybDCBkAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0
# cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5
# NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAVaoq
# GvNG83hXNzD8deNP1oUj8fz5lTmbJeb3coqYw3fUZPwV+zbCSVEseIhjVQlGOQD8
# adTKmyn7oz/AyQCbEx2wmIncePLNfIXNU52vYuJhZqMUKkWHSphCK1D8G7WeCDAJ
# +uQt1wmJefkJ5ojOfRu4aqKbwVNgCeijuJ3XrR8cuOyYQfD2DoD75P/fnRCn6wC6
# X0qPGjpStOq/CUkVNTZZmg9U0rIbf35eCa12VIp0bcrSBWcrduv/mLImlTgZiEQU
# 5QpZomvnIj5EIdI/HMCb7XxIstiSDJFPPGaUr10CU+ue4p7k0x+GAWScAMLpWnR1
# DT3heYi/HAGXyRkjgNc2Wl+WFrFjDMZGQDvOXTXUWT5Dmhiuw8nLw/ubE19qtcfg
# 8wXDWd8nYiveQclTuf80EGf2JjKYe/5cQpSBlIKdrAqLxksVStOYkEVgM4DgI974
# A6T2RUflzrgDQkfoQTZxd639ouiXdE4u2h4djFrIHprVwvDGIqhPm73YHJpRxC+a
# 9l+nJ5e6li6FV8Bg53hWf2rvwpWaSxECyIKcyRoFfLpxtU56mWz06J7UWpjIn7+N
# uxhcQ/XQKujiYu54BNu90ftbCqhwfvCXhHjjCANdRyxjqCU4lwHSPzra5eX25pvc
# fizM/xdMTQCi2NYBDriL7ubgclWJLCcZYfZ3AYwxggRpMIIEZQIBATB4MGQxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE8MDoGA1UEAxMzRGln
# aUNlcnQgR2xvYmFsIEczIENvZGUgU2lnbmluZyBFQ0MgU0hBMzg0IDIwMjEgQ0Ex
# AhACiXnukvtz4TjComStzaCgMAkGBSsOAwIaBQCgQDAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAjBgkqhkiG9w0BCQQxFgQUCErqHhAiLi1fWItBt832IHSsC4Aw
# CwYHKoZIzj0CAQUABGgwZgIxAK+VWZMXFLYY459la2d93Pdb95ftOZFclgKcZO5F
# o1JCo/DgkuhtF4SoO8nYwSEcYAIxANyvs8nFkFd1sFW5vMWhEW1VZ1uQYnT2UJlQ
# h+bz7OW/TZanzdxPm+qXxHK//e98BaGCAyAwggMcBgkqhkiG9w0BCQYxggMNMIID
# CQIBATB3MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7
# MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1l
# U3RhbXBpbmcgQ0ECEAxNaXJLlPo8Kko9KQeAPVowDQYJYIZIAWUDBAIBBQCgaTAY
# BgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzAxMDkx
# NjUxMjFaMC8GCSqGSIb3DQEJBDEiBCBfGqubU307mjeqawa5Tb5/DEnlwJmVofQM
# WhCviVMeDjANBgkqhkiG9w0BAQEFAASCAgCJmpds7WLzh94I4ssLQvRvnW1gJbmV
# owW2+JvJz/Tpu1RLBKhJ8NSMCY6/KqbmLwkGlnS5A6SeugSLzssr1mIjik5chm9h
# lu9Tfh8RuzOyJuhmRvMu5ACOJTV4hXHG6JvKCxg9duB9tRqZPT4PeVdxGMYHTKwz
# 42/WuzSxn9tlHKD2Z1c6kOIQeDWP4J8xckW5JUfHv1fijLkc6oChuekktGOtd32b
# lL/ncM9APQcxFzyGlWbsSBcDtJO/Cgq0o2s7/ONmlXrhrq6QGfmMYCcpDVD0pDmG
# sE5Oz6RZCJoe/VDAJ3qnXdYSvheUj4y99hUVmx40MQDvLFqYsCtt5CDxIRt5k9Q2
# tkDNhGqHbjgyIFssnaFwf0LPy8naxeug2iW0gJ+YzXFYL8N2RUyPP14qFb9BF+OI
# 06k931P8pira3vVtIrViZeoT6LU+l298+5/NP63UHXmaz21vOOy9tjmpnWrcDs8k
# DnOfLoxxyKpTG2kZiwt1iH5WqYb8ctbHxTR1c4pZDiYosypPcxrEKwqQt+qO+C28
# ehsghPdindqnVJxcgpfWa+Xuq0LmRYntobkvxsEzGYp3z0hMG8S0D2ZWcnVh0bL9
# g526FbhLbNYkbi5ucRYWUPtVBd5cNXAM7i5ea9daxUnZMEswavlvuhbhJyQmkSIk
# aoKlms2dt77R1g==
# SIG # End signature block
