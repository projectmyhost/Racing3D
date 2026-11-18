Add-Type -AssemblyName System.IO.Compression.FileSystem

$carsZip = 'C:\Users\Pongo\Downloads\lowpoly_cars_free.zip'
$roadsZip = 'C:\Users\Pongo\Downloads\[FREE] Modular Roads - Base.zip'

New-Item -ItemType Directory -Force -Path 'assets/models/cars' | Out-Null
New-Item -ItemType Directory -Force -Path 'assets/models/roads' | Out-Null

Write-Host "Extracting cars..."
$zipCars = [System.IO.Compression.ZipFile]::OpenRead($carsZip)
foreach ($entry in $zipCars.Entries) {
    if ($entry.FullName.EndsWith('.glb')) {
        $fileName = [System.IO.Path]::GetFileName($entry.FullName)
        $destPath = Join-Path 'assets/models/cars' $fileName
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
        Write-Host "Extracted car: $fileName"
    }
}
$zipCars.Dispose()

Write-Host "Extracting modular roads..."
$zipRoads = [System.IO.Compression.ZipFile]::OpenRead($roadsZip)
foreach ($entry in $zipRoads.Entries) {
    if ($entry.FullName.EndsWith('.glb') -or $entry.FullName.EndsWith('.png') -or $entry.FullName.EndsWith('.jpg')) {
        $fileName = [System.IO.Path]::GetFileName($entry.FullName)
        if ($fileName -ne "") {
            $destPath = Join-Path 'assets/models/roads' $fileName
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destPath, $true)
            Write-Host "Extracted road asset: $fileName"
        }
    }
}
$zipRoads.Dispose()

Write-Host "Extraction complete!"

