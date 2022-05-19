Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RootPath
)

function Process-Folder {
    param (
	[string]$FolderToProcess
    )

    foreach ($Directory in Get-ChildItem -Directory $FolderToProcess) {
	Process-Folder $file.Name
    }

    $ExistingNames = Get-AzStorageBlob -Container $ContainerName -Context $Context | Select-Object -Property Name

    # Download existing index.html
    $HtmlPath = ""

    foreach ($File in Get-ChildItem -File $ImageFolder) {
	$Hash = (Get-FileHash $File).Hash
	$Extension = ($File.Name -split "\.")[-1]

	if ($extension -Match "html") {
	    continue
	}

	$NewName = $Hash + "." + $Extension

	if ($ExistingNames -contains $NewName) {
	    continue
	}

	# Upload file

	$html = "<img src=`"./$NewName`"/><p>$($File.Name)</p>"
	Add-Content -Path $HtmlPath -Value $html
    }
}

# Install Azure client
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
} 

Process-Folder $RootPath
