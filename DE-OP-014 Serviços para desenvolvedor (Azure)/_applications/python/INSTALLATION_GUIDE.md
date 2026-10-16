# Azure Functions Core Tools Installation & Troubleshooting Guide

## Issue Summary
The Azure Functions Core Tools installation is failing due to:
1. Permission issues (EPERM errors)
2. Download interruptions
3. Corrupted previous installation

## Solutions (Try in Order)

### Solution 1: Install with Chocolatey (Recommended for Windows)

```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Azure Functions Core Tools
choco install azure-functions-core-tools-4 -y
```

### Solution 2: Manual Download & Install

1. Download directly from GitHub:
   - Visit: https://github.com/Azure/azure-functions-core-tools/releases
   - Download: `Azure.Functions.Cli.win-x64.4.5.0.zip`

2. Extract and add to PATH:
   ```powershell
   # Extract to a permanent location
   $installPath = "$env:LOCALAPPDATA\Programs\AzureFunctionsCoreTools"
   Expand-Archive -Path "Azure.Functions.Cli.win-x64.4.5.0.zip" -DestinationPath $installPath -Force
   
   # Add to PATH
   $env:PATH += ";$installPath"
   [Environment]::SetEnvironmentVariable("PATH", $env:PATH, [EnvironmentVariableTarget]::User)
   
   # Verify
   func --version
   ```

### Solution 3: Run PowerShell as Administrator & Clean Install

```powershell
# 1. Run PowerShell as Administrator

# 2. Clean up corrupted installation
Remove-Item -Path "$env:APPDATA\npm\node_modules\azure-functions-core-tools" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\npm\func.cmd" -Force -ErrorAction SilentlyContinue

# 3. Install with npm
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

### Solution 4: Use Standalone MSI Installer

```powershell
# Download MSI installer
$url = "https://github.com/Azure/azure-functions-core-tools/releases/download/4.5.0/func-cli-4.5.0-x64.msi"
$output = "$env:TEMP\func-cli-installer.msi"
Invoke-WebRequest -Uri $url -OutFile $output

# Install
Start-Process msiexec.exe -ArgumentList "/i $output /quiet" -Wait

# Add to PATH (may require restart)
refreshenv
func --version
```

## Alternative: Test Without func CLI

You can test the function app logic without Azure Functions Core Tools:

### Option A: Use the Test Script

```powershell
# 1. Update credentials in test_database.py
# 2. Install dependencies
C:/UserData/z004stze/Documents/Private/mine/ada/.1351/_applications/python/.venv/Scripts/python.exe -m pip install pyodbc

# 3. Run tests
C:/UserData/z004stze/Documents/Private/mine/ada/.1351/_applications/python/.venv/Scripts/python.exe test_database.py
```

### Option B: Deploy Directly to Azure

You can deploy without local testing using VS Code:

1. Install VS Code extension: "Azure Functions"
2. Sign in to Azure
3. Right-click on project folder
4. Select "Deploy to Function App..."
5. Test directly in Azure Portal

### Option C: Use Azure Functions with VS Code Debugging

1. Install Python dependencies:
   ```powershell
   C:/UserData/z004stze/Documents/Private/mine/ada/.1351/_applications/python/.venv/Scripts/python.exe -m pip install -r requirements.txt
   ```

2. Create `.vscode/launch.json`:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Attach to Python Functions",
         "type": "python",
         "request": "attach",
         "port": 9091,
         "preLaunchTask": "func: host start"
       }
     ]
   }
   ```

3. Press F5 to debug

## Verify Installation

After any installation method:

```powershell
# Check version
func --version

# Should output: 4.x.x

# Navigate to project
cd C:\UserData\z004stze\Documents\Private\mine\ada\.1351\_applications\python

# Start Functions
func start
```

## Common Errors & Fixes

### Error: "spawn func ENOENT"
- **Cause:** func.exe not in PATH
- **Fix:** Restart PowerShell or run: `refreshenv`

### Error: "EPERM: operation not permitted"
- **Cause:** Permission issues or locked files
- **Fix:** Run PowerShell as Administrator or use Chocolatey

### Error: Download timeout
- **Cause:** Network issues or firewall
- **Fix:** Use manual download (Solution 2)

## Testing Without func CLI

If all installation attempts fail, you can still:

1. **Test database operations:**
   ```powershell
   python test_database.py
   ```

2. **Deploy directly to Azure:**
   - Use Azure Portal
   - Use Azure CLI: `az functionapp deployment source config-zip`
   - Use GitHub Actions CI/CD

3. **Use Docker:**
   ```dockerfile
   FROM mcr.microsoft.com/azure-functions/python:4-python3.11
   COPY . /home/site/wwwroot
   RUN pip install -r /home/site/wwwroot/requirements.txt
   ```

## Next Steps

1. Try Solution 1 (Chocolatey) - easiest and most reliable
2. If that fails, try manual download (Solution 2)
3. Meanwhile, test database operations using test_database.py
4. Consider deploying directly to Azure for testing

## Need Help?

If you continue having issues:
1. Check Windows Event Viewer for detailed errors
2. Verify antivirus isn't blocking installations
3. Try installing in a different directory
4. Contact Azure Support for enterprise environments
