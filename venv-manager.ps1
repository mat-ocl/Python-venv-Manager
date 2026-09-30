# Python-venv-Manager
# https://github.com/mat-ocl

function Get-LocalVenvs {
    # Scan for Activate.ps1 files up to 2 levels deep
    $activateScripts = Get-ChildItem -Path ".*", "*" -Filter "Activate.ps1" -Recurse -Depth 2 -ErrorAction SilentlyContinue | 
                       Where-Object { $_.FullName -match '[\/\\][^\/\\]+[\/\\]Scripts[\/\\]Activate\.ps1$' }

    # Return a structured array of custom objects
    foreach ($script in $activateScripts) {
        [PSCustomObject]@{
            Name = $script.Directory.Parent.Name
            Path = $script.FullName
        }
    }
}

function act {
    param(
        [string]$Name = ""
    )

    # Scenario 1: User explicitly requested a specific environment name
    if ($Name) {
        $explicitPath = [System.IO.Path]::Combine(".", $Name, "Scripts", "Activate.ps1")
        if (Test-Path $explicitPath) {
            & $explicitPath
            return
        } else {
            Write-Host "Could not find a virtual environment named '$Name' in this directory." -ForegroundColor Red
            return
        }
    }

    # Scenario 2: No name provided -> Fall back to automatic discovery
    $venvs = @(Get-LocalVenvs)

    if (-not $venvs) {
        Write-Host "No virtual environment found in the current directory." -ForegroundColor Red
        return
    }

    if ($venvs.Count -eq 1) {
        & $venvs[0].Path
    }
    else {
        Write-Host "Multiple environments found. Please choose one:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $venvs.Count; $i++) {
            Write-Host "[$i] $($venvs[$i].Name)" -ForegroundColor Cyan
        }
        
        $selection = Read-Host "Enter the number"
        if ($selection -match '^\d+$' -and $selection -lt $venvs.Count) {
            & $venvs[$selection].Path
        } else {
            Write-Host "Invalid selection. Activation cancelled." -ForegroundColor Red
        }
    }
}

function deact {
    if (Get-Command deactivate -ErrorAction SilentlyContinue) {
        deactivate
    } else {
        Write-Host "No active Python virtual environment found to deactivate." -ForegroundColor Yellow
    }
}

function cenv {
    param(
        [string]$Name = ".venv"
    )

    Write-Host "Creating Python virtual environment in '.\$Name'..." -ForegroundColor Cyan
    python -m venv $Name

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Environment '$Name' created successfully!" -ForegroundColor Green
        $activate = Read-Host "Activate it now? (Y/n)"
        if ($activate -eq "" -or $activate -eq "y") {
            act -Name $Name

            # Prompt to install requirements if present
            if (Test-Path "requirements.txt") {
                $installReqs = Read-Host "Found 'requirements.txt'. Install dependencies now? (Y/n)"
                if ($installReqs -eq "" -or $installReqs -match '^[Yy]$') {
                    ienv
                }
            }
        }
    } else {
        Write-Host "Failed to create virtual environment. Ensure Python is installed and in your PATH." -ForegroundColor Red
    }
}

function denv {
    param([string]$Name = "")

    # 1. Active environment safety check
    if ($env:VIRTUAL_ENV) {
        $activeEnvName = Split-Path $env:VIRTUAL_ENV -Leaf
        if ($activeEnvName -eq "Scripts" -or $activeEnvName -eq "bin") {
            $activeEnvName = Split-Path (Split-Path $env:VIRTUAL_ENV -Parent) -Leaf
        }
    }

    # 2. Get local environments using our helper
    $venvs = @(Get-LocalVenvs)
    $targetEnv = $null

    if ($Name) {
        # Find explicit match
        $targetEnv = $venvs | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    } elseif ($venvs.Count -eq 1) {
        # Fallback to the single available environment
        $targetEnv = $venvs[0]
    } elseif ($venvs.Count -gt 1) {
        # Prompt user if multiple exist and no name was given
        Write-Host "Multiple environments found. Please select which one to DESTROY:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $venvs.Count; $i++) {
            Write-Host "[$i] $($venvs[$i].Name)" -ForegroundColor Cyan
        }
        $selection = Read-Host "Enter the number"
        if ($selection -match '^\d+$' -and $selection -lt $venvs.Count) {
            $targetEnv = $venvs[$selection]
        }
    }

    if (-not $targetEnv) {
        Write-Host "No environment selected or found to destroy." -ForegroundColor Red
        return
    }

    # 3. Deactivate if it's the active one
    if ($activeEnvName -and $activeEnvName -eq $targetEnv.Name) {
        Write-Host "The environment '$($targetEnv.Name)' is currently active. Deactivating first..." -ForegroundColor Yellow
        deact
    }

    # 4. Confirm and delete the actual directory parent path
    $targetFolder = Split-Path (Split-Path $targetEnv.Path -Parent) -Parent
    $confirmation = Read-Host "Are you sure you want to permanently delete '$($targetEnv.Name)'? (y/N)"
    if ($confirmation -eq "y") {
        Write-Host "Destroying virtual environment '$($targetEnv.Name)'..." -ForegroundColor Cyan
        Remove-Item -Path $targetFolder -Recurse -Force -ErrorAction Stop
        Write-Host "Environment '$($targetEnv.Name)' successfully deleted." -ForegroundColor Green
    } else {
        Write-Host "Destruction cancelled." -ForegroundColor Yellow
    }
}

function ienv {
    param(
        [string]$File = "requirements.txt",
        [switch]$UpgradePip
    )

    # 1. Verify an environment is currently active
    if (-not $env:VIRTUAL_ENV) {
        Write-Host "No active virtual environment detected." -ForegroundColor Yellow
        $activateFirst = Read-Host "Would you like to activate one first? (Y/n)"
        if ($activateFirst -eq "" -or $activateFirst -match '^[Yy]$') {
            act
            # Re-check activation after 'act' runs
            if (-not $env:VIRTUAL_ENV) {
                Write-Host "Cannot install dependencies without an active environment." -ForegroundColor Red
                return
            }
        } else {
            return
        }
    }

    # 2. Check if the requirements file exists
    if (-not (Test-Path $File)) {
        Write-Host "Requirements file '$File' not found in the current directory." -ForegroundColor Red
        return
    }

    # 3. Optional/Recommended: Ensure pip is up to date
    if ($UpgradePip) {
        Write-Host "Upgrading pip..." -ForegroundColor Cyan
        python -m pip install --upgrade pip
    }

    # 4. Install dependencies
    Write-Host "Installing dependencies from '$File' into '$($env:VIRTUAL_ENV)'..." -ForegroundColor Cyan
    python -m pip install -r $File

    if ($LASTEXITCODE -eq 0) {
        Write-Host "All dependencies installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "An error occurred while installing dependencies." -ForegroundColor Red
    }
}