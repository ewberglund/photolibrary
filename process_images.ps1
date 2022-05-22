param(
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $RootPath,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $StorageKey,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $StorageName,
    [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $AzureContainerName
)

function Process-Folder($LocalPath, $BlobPath, $Context, $AzureContainerName) {

    echo "Processing folder $LocalPath"

    # Download existing index.html
    $HtmlPath = $LocalPath + "index.html"

    if ($BlobPath) {
	$HtmlBlobName = "$BlobPath/index.html"
    }
    else {
	$HtmlBlobName = "index.html"
    }

    $blob = Get-AzStorageBlob -Context $Context -Container $AzureContainerName -Blob $HtmlBlobName -ErrorAction Ignore

    if ($blob) {
	Get-AzStorageBlobContent -Context $Context -CloudBlob $blob.ICloudBlob -Destination $LocalPath -Force
    }

    foreach ($Directory in Get-ChildItem -Directory $LocalPath) {
	$NewLocalPath = $LocalPath + $Directory.Name + "/"
	$NewBlobPath = $BlobPath + "/" + $Directory.Name

	$LinkHtml = "<a href=`"$baseUrl$NewBlobPath/index.html`">$($Directory.Name)</a>"
	Add-Content -Path $HtmlPath -Value $LinkHtml

	Process-Folder -LocalPath $NewLocalPath -BlobPath $NewBlobPath -Context $Context -AzureContainerName $AzureContainerName
    }

    $ExistingNames = Get-AzStorageBlob -Container $AzureContainerName -Context $Context | Select-Object -Property Name

    foreach ($file in Get-ChildItem -File $LocalPath) {
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
	$blobName = "./$NewName"

	$ImageHtml = "<img src=`"$blobName`"/><p>$($File.Name)</p>"
	Add-Content -Path $HtmlPath -Value $ImageHtml

	echo "Uploading image file $($file.Name)"

	Set-AzStorageBlobContent -Container $AzureContainerName -File $file -Blob $blobName -Context $Context
    }

    $blobName = "$BlobPath/index.html"
    echo "Uploading html file $blobName"

    # Upload HTML File
    if ([System.IO.File]::Exists($htmlPath)) {
	Set-AzStorageBlobContent -Container $AzureContainerName -File $htmlPath -Blob $blobName -Context $Context
    }
}

# Install Azure client
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
} 

$StorageContext = New-AzStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey

Process-Folder -LocalPath $RootPath -BlobPath "main" -Context $StorageContext -AzureContainerName $AzureContainerName
