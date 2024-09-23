# PowerShell script to install Python on Windows

# Define the Python installer URL (Modify version if necessary)
$pythonInstallerUrl = "https://www.python.org/ftp/python/3.11.6/python-3.11.6-amd64.exe"
$installerPath = "$env:TEMP\python-installer.exe"

# Function to download and install Python
function Install-Python {
    Write-Host "Downloading Python installer..."
    Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath

    Write-Host "Running Python installer..."
    Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

    Write-Host "Python installation completed. Verifying installation..."
    python --version
}

# Check if Python is already installed
if (Get-Command "python" -ErrorAction SilentlyContinue) {
    Write-Host "Python is already installed."
} else {
    Install-Python
}
