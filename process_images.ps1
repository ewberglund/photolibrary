Param(
	[Parameter(Mandatory = $true)]
	[String]
	$ImageFolder
)

foreach ($file in Get-ChildItem -Recurse -File $ImageFolder) {
	$hash = (Get-FileHash $file).Hash

	if ($file.Name -Match $hash) {
		continue
	}

	$extension = ($file.Name -split "\.")[-1]

	if ($extension -Match "html") {
		continue
	}

	Rename-Item -Path $file -NewName "$hash.$extension"
	$newpath = $file.Directory.FullName -replace [Regex]::Escape("$ImageFolder\"), "./"

	$html = "<img src=`"$newpath/$hash.$extension`"/><p>$($file.Name)</p>"
	Add-Content -Path "$ImageFolder/index.html" -Value $html
}
