Function Find-MsBuild([int] $MaxVersion = 2017)
{
    $agentPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\msbuild.exe"
    $devPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe"
    $proPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\msbuild.exe"
    $communityPath = "$Env:programfiles (x86)\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe"
    $fallback2015Path = "${Env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"
    $fallback2013Path = "${Env:ProgramFiles(x86)}\MSBuild\12.0\Bin\MSBuild.exe"
    $fallbackPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319"
        
    If ((2017 -le $MaxVersion) -And (Test-Path $agentPath)) { return $agentPath } 
    If ((2017 -le $MaxVersion) -And (Test-Path $devPath)) { return $devPath } 
    If ((2017 -le $MaxVersion) -And (Test-Path $proPath)) { return $proPath } 
    If ((2017 -le $MaxVersion) -And (Test-Path $communityPath)) { return $communityPath } 
    If ((2015 -le $MaxVersion) -And (Test-Path $fallback2015Path)) { return $fallback2015Path } 
    If ((2013 -le $MaxVersion) -And (Test-Path $fallback2013Path)) { return $fallback2013Path } 
    If (Test-Path $fallbackPath) { return $fallbackPath } 
        
    throw "Yikes - Unable to find msbuild"
}

function Get-XmlNode([ xml ]$XmlDocument, [string]$NodePath, [string]$NamespaceURI = "", [string]$NodeSeparatorCharacter = '.')
{
    # If a Namespace URI was not given, use the Xml document's default namespace.
    if ([string]::IsNullOrEmpty($NamespaceURI)) { $NamespaceURI = $XmlDocument.DocumentElement.NamespaceURI }   
     
    # In order for SelectSingleNode() to actually work, we need to use the fully qualified node path along with an Xml Namespace Manager, so set them up.
    $xmlNsManager = New-Object System.Xml.XmlNamespaceManager($XmlDocument.NameTable)
    $xmlNsManager.AddNamespace("ns", $NamespaceURI)
    $fullyQualifiedNodePath = "/ns:$($NodePath.Replace($($NodeSeparatorCharacter), '/ns:'))"
     
    # Try and get the node, then return it. Returns $null if the node was not found.
    $node = $XmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
    return $node
}

$currentLocation = Get-Location
$projectFilePath = Join-Path $currentLocation "WinDivertSharp\WinDivertSharp.csproj"

$msbuildPath = Find-MsBuild

[xml] $proj = Get-Content $projectFilePath

$packageIdNode = Get-XmlNode -XmlDocument $proj -NodePath "Project.PropertyGroup.PackageId"

if($packageIdNode -eq $null) {
    $packageId = $proj.Project.PropertyGroup.Title[0]
} else {
    $packageId = $proj.Project.PropertyGroup.PackageId[0]
}

$version = $proj.Project.PropertyGroup.Version[0]

& $msbuildPath /property:Configuration=Release $projectFilePath
& $msbuildPath /property:Configuration=Release /t:pack $projectFilePath

if (-not $?) {
    Write-Host "Error occurred during msbuild process"
    exit 1
}

$nupkg = Join-Path (Split-Path -Path $projectFilePath) "bin/Release/$packageId.$version.nupkg"

Copy-Item -Path $nupkg -Destination C:\Nuget.Local

$nugetKeyPath = Join-Path $currentLocation ".nuget-apikey"

if(!(Test-Path $nugetKeyPath)) {
    $nugetKeyPath = "C:\.nuget-apikey"
}

if(!(Test-Path $nugetKeyPath)) {
    Write-Host "Please put .nuget-apikey in your project directory or in C:\ drive root in order to upload to nuget."
    exit
}

$apiKey = Get-Content $nugetKeyPath

$deployNuget = Read-Host -Prompt "Do you want to upload $packageId to nuget?"

if($deployNuget[0] -eq 'y') {
    dotnet nuget push $nupkg -k $apiKey -s https://api.nuget.org/v3/index.json
}