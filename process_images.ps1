param(
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $RootPath,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$StorageKey,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$StorageName,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$AzureContainerName
)

function Process-Folder([string]$LocalPath, [string]$BlobPath, $Context) {

    foreach ($Directory in Get-ChildItem -Directory $FolderToProcess) {
	$NewLocalPath = $LocalPath + "/" + $Directory.Name
	$NewBlobPath = $BlobPath + "/" + $Directory.Name
	Process-Folder -FolderToProcess $NewLocalPath -BlobPath $NewBlobPath -Context $Context
    }

    $ExistingNames = Get-AzStorageBlob -Container $AzureContainerName -Context $Context | Select-Object -Property Name

    # Download existing index.html
    $HtmlPath = "$FolderToProcess/index.html"
    Get-AzStorageBlobContent -Context $Context -Container $AzureContainerName -Blob $HtmlBlobName -Destination $FolderToProcess -Force

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

	# Upload Photo
	$Url = $FolderToProcess + '/' + $NewName

	$Html = '<img src="$Url"/><p>$($File.Name)</p>'
	Add-Content -Path $HtmlPath -Value $Html
    }

    # Upload HTML File
}

# Install Azure client
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
} 

Connect-AzAccount

$StorageContext = New-AzStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey

Process-Folder -LocalPath $RootPath -BlobPath "" -Context $StorageContext
