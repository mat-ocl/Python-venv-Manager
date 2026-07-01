# PowerShell Python venv Manager

A lightweight, zero-dependency cross-platform (Win, Mac, Linux) suite of PowerShell functions to streamline the entire lifecycle of Python virtual environments. It brings smart automation, cross-platform path handling, and interactive terminal shortcuts to your everyday Python workflow.

## 🚀 Features

* **`cenv` (Create Environment):** Quick-create virtual environments (defaults to `.venv`) and automatically pairs with an immediate activation prompt.
* **`act` (Activate Environment):** Smart activation. Pass an explicit folder name, let it automatically find a single environment, or choose from an interactive menu if multiple environments exist.
* **`deact` (Deactivate Environment):** A clean shortcut to exit your active environment safely with graceful error handling.
* **`denv` (Destroy Environment):** Safely tears down environments. It automatically checks if the targeted environment is active and shuts it down before asking for final deletion confirmation.
* **`Get-LocalVenvs` (Gets environments):** Internal function to find environments based on Activate.ps1 script existence. Can also be used on it's own. It lists the environments and the paths to the scripts.
---

## 🛠️ Installation

Add these functions to your PowerShell profile so they are available in every new terminal session.

1. Open your PowerShell profile in notepad (or nano, vim or any similar tool):
```powershell
notepad $PROFILE

```
*(If prompted to create a new file, click **Yes**).*

2. Copy the entire contents of the `venv-manager.ps1` script from this repository and paste them directly into your profile file.
3. Save the file (`Ctrl + S`) and reload your terminal session to apply the changes:
```powershell
. $PROFILE

```


---

## 📖 Usage Examples

### 1. Initializing a New Project

Create your environment instantly. It defaults to naming the folder `.venv`.

```powershell
cenv

```

*Output:*

```text
Creating Python virtual environment in '.\.venv'...
Environment '.venv' created successfully!
Activate it now? (Y/n): 

```

### 2. Automatic Smart Activation

If your folder has exactly one environment folder (e.g., `.venv` or `venv`), just type:

```powershell
act

```

It detects the script path and activates it immediately without prompting you with options.

### 3. Explicit / Shortcut Execution

Skip the discovery engine entirely by passing a specific folder name to activate or destroy:

```powershell
act my_test_env
denv my_test_env

```

### 4. Interactive Handling for Multi-Environment Workspaces

If you happen to have multiple environments in the same workspace directory, both `act` and `denv` seamlessly adapt to interactive menus:

```powershell
denv

```

*Output:*

```text
Multiple environments found. Please select which one to DESTROY:
[0] .venv
[1] build_env
Enter the number: 0
Are you sure you want to permanently delete '.venv'? (y/N): y
Destroying virtual environment '.venv'...
Environment '.venv' successfully deleted.

```

### 5. Deactivation

Exit your virtual environment gracefully at any point:

```powershell
deact

```

---

## 📜 License

This project is open-source and available under the [MIT License](https://mit-license.org/).
