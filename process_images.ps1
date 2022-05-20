Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RootPath
)

Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $StorageKey
)

Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $StorageName
)

Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $AzureContainerName
)

function Process-Folder {
    param (
	[string]$FolderToProcess
    )

    param (
	$Context
    )

    foreach ($Directory in Get-ChildItem -Directory $FolderToProcess) {
	Process-Folder $file.Name $Context
    }

    $ExistingNames = Get-AzStorageBlob -Container $AzureContainerName -Context $Context | Select-Object -Property Name

    # Download existing index.html
    $HtmlPath = "./index.html"
    Get-AzStorageBlobContent -Context $Context -Container $AzureContainerName -Blob $HtmlBlobName -Destination $RootPath -Force

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
	$BlobName = "full/path/folder/structure/file.jpg"

	$Html = "<img src=`"./$NewName`"/><p>$($File.Name)</p>"
	Add-Content -Path $HtmlPath -Value $Html
    }
}

# Install Azure client
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
} 

Connect-AzAccount

$StorageContext = New-AzStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey

Process-Folder $RootPath $StorageContext
