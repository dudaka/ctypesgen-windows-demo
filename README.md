Small Demonstration of Ctypesgen - Windows Version (Source-Built Tools)
=======================================================================

This little demonstration shows how bindings for a very simple C library 
and associated header can be quickly generated using Ctypesgen and accessed 
by a Python program on Windows. This enhanced version automatically builds 
both MinGW-w64 and ctypesgen from their GitHub source repositories.

## Quick Start (CMake with Auto Source Setup)

For the fastest setup with automatic MinGW-w64 and ctypesgen source installation:

```cmd
# Windows - Automatic source-based setup and build
build.bat

# Or setup tools only  
setup_mingw.bat     # MinGW-w64 from source
cmake --build build --target setup_ctypesgen_env  # ctypesgen from source

# Linux/macOS  
chmod +x build.sh
./build.sh
```

The enhanced build script will automatically clone and setup both MinGW-w64 and ctypesgen from their GitHub repositories!

## Prerequisites

### Basic Requirements

- Python 3.x
- CMake 3.22 or later
- Microsoft Visual C++ compiler (comes with Visual Studio or Build Tools for Visual Studio)

### For Automatic Source Setup (Recommended)

- **Git** (for cloning MinGW-w64 and ctypesgen source) - [Download here](https://git-scm.com/download/win)
- **Internet connection** (for cloning both repositories)

### Manual Setup (Alternative)

- **MinGW-w64** (provides gcc for preprocessing) - Manual installation required
- **ctypesgen** (install via pip or from source) - Manual installation required

## Automatic Tool Installation

This project now automatically installs both required tools from their GitHub sources:

- **MinGW-w64**: Cloned from https://github.com/mingw-w64/mingw-w64 
- **ctypesgen**: Cloned from https://github.com/ctypesgen/ctypesgen

No manual installation needed! The CMake build system handles everything.
pip install git+https://github.com/ctypesgen/ctypesgen.git
```

To verify the installation, run:

```cmd
ctypesgen --version
```

## Setting up Visual C++ Compiler (cl.exe)

Before compiling C code, you need to set up the Visual C++ compiler environment. The `cl.exe` compiler needs to be available in your PATH with the proper environment variables.

### Option 1: Using Developer Command Prompt (Recommended)

The easiest way is to use the **Developer Command Prompt** or **Developer PowerShell** that comes with Visual Studio:

1. Search for "Developer Command Prompt" or "Developer PowerShell" in the Start menu
2. Run all subsequent commands in this terminal

### Option 2: Manual Setup in Regular Terminal

If you prefer to use a regular Command Prompt or PowerShell, you need to run the Visual Studio environment setup script:

**For Command Prompt:**
```cmd
"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
```

**For PowerShell:**
```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
```

**Alternative paths for different Visual Studio editions:**
- **Visual Studio Build Tools**: `"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"`
- **Visual Studio Professional**: `"C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"`
- **Visual Studio Enterprise**: `"C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"`

### Verify cl.exe is available

After setting up the environment, verify that the compiler is available:

```cmd
cl
```

You should see output like:
```
Microsoft (R) C/C++ Optimizing Compiler Version 19.xx.xxxxx for x64
Copyright (C) Microsoft Corporation.  All rights reserved.

usage: cl [ option... ] filename... [ /link linkoption... ]
```

## Steps for Windows

### Option A: Automatic MinGW Setup (Recommended)

This approach automatically downloads and configures MinGW-w64, then uses ctypesgen to generate bindings.

#### 1. Run the automatic setup

```cmd
# Build everything with automatic MinGW setup
build.bat

# Or setup MinGW only first
setup_mingw.bat
```

The script will:
- Clone MinGW-w64 source from Git repository if not found
- Create a GCC wrapper using the system cl.exe compiler
- Set up environment scripts for ctypesgen compatibility
- Test the installation

#### 2. Verify MinGW setup

After running the setup, test that GCC is available:

```cmd
# Use the generated environment script
call build\setup_mingw_env.bat

# Test GCC
gcc --version
```

#### 3. Generate Python bindings and run demo

```cmd
cd build
cmake --build . --target demo_with_mingw --config Release
```

### Option B: Manual MinGW Installation

This approach uses manual MinGW installation, as in the original guide.

#### 1. Install MinGW-w64 (one-time setup)

```cmd
winget install BrechtSanders.WinLibs.POSIX.UCRT
```

Add MinGW to your PATH (restart your terminal after installation or run):

**For PowerShell:**
```powershell
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin"
```

**For Command Prompt:**
```cmd
set PATH=%PATH%;C:\Users\%USERNAME%\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin
```

**Permanent installation (run as Administrator in PowerShell):**
```powershell
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe\mingw64\bin", [EnvironmentVariableTarget]::Machine)
```

#### 2. Compile the shared C library as a Windows DLL

```cmd
cl /LD demolib.c /Fe:demolib.dll
```

#### 3. Generate the bindings automatically

```cmd
ctypesgen -o pydemolib.py -l demolib.dll demolib.h
```

This will now work perfectly and generate complete bindings with function definitions!

#### 4. Run the Python app

```cmd
python demoapp.py
```

Expected output:
```
a 1
b 2
result 3
DB_C_TYPE_STRING 1
```

### Option A2: CMake Build (Modern Approach)

This approach uses CMake for a more portable and modern build system.

#### Prerequisites for CMake

- CMake 3.22 or later ([Download CMake](https://cmake.org/download/))
- Visual Studio Build Tools or Visual Studio (same as Option A)
- Python 3.x with ctypesgen installed

#### 1. Configure the build

Open a Developer Command Prompt or PowerShell and navigate to the project directory:

```cmd
mkdir build
cd build
cmake ..
```

Or for a specific generator (e.g., Visual Studio):

```cmd
mkdir build
cd build
cmake -G "Visual Studio 17 2022" -A x64 ..
```

#### 2. Build the library

```cmd
cmake --build . --config Release
```

#### 3. Generate Python bindings (optional)

```cmd
cmake --build . --target python_bindings --config Release
```

#### 4. Run the test

```cmd
cmake --build . --target demo_test --config Release
ctest -C Release
```

**Note**: For single-config generators (like Makefiles), use `ctest` without the `-C` flag:
```cmd
ctest
```

Or run the executable directly:

```cmd
Release\demo_test.exe
```

#### 5. Run Python demo (optional)

```cmd
cmake --build . --target run_python_demo --config Release
```

#### Install the library (optional)

```cmd
cmake --install . --prefix install
```

### Option B: Manual Approach (Fallback)

If you prefer not to install MinGW or encounter issues:

#### 1. Compile the DLL

```cmd
cl /LD demolib.c /Fe:demolib.dll
```

#### 2. Create manual bindings

Create a file called `demoapp_manual.py` with the following content:

```python
#!/usr/bin/env python3
import ctypes
import sys
import os

def do_demo():
    try:
        # Load the DLL directly with ctypes
        dll_path = os.path.join(os.path.dirname(__file__), "demolib.dll")
        demolib = ctypes.CDLL(dll_path)
        
        # Define the function signature
        demolib.trivial_add.argtypes = [ctypes.c_int, ctypes.c_int]
        demolib.trivial_add.restype = ctypes.c_int
        
        # Test the function
        a = 1
        b = 2
        result = demolib.trivial_add(a, b)
        print("a", a)
        print("b", b)
        print("result", result)
        
    except Exception as e:
        print(f"Error: {e}")
        return False
    
    return True

if __name__ == "__main__":
    do_demo()
```

Then run:

```cmd
python demoapp_manual.py
```

### Testing with C Program

You can also try executing the same code from a C program:

- Compile test code:

  ```cmd
  cl demoapp.c demolib.c
  ```

- Execute:

  ```cmd
  demoapp.exe
  ```

- Observe the same results as before:

  ```text
  a 1
  b 2
  result 3
  ```

## Notes for Windows

- On Windows, shared libraries use the `.dll` extension instead of `.so`
- The Microsoft Visual C++ compiler (`cl.exe`) is used instead of `gcc`
- Function exports may need to be explicitly declared with `__declspec(dllexport)`
- **Key insight**: ctypesgen requires a C preprocessor to parse header files
- **Solution**: Installing MinGW provides `gcc` which ctypesgen can use for preprocessing
- **Alternative**: Manual ctypes bindings avoid preprocessing issues entirely
- **CMake benefits**: Provides cross-platform build configuration, automatic dependency management, and integration with modern development tools

## CMake Benefits

Using CMake offers several advantages:

- **Cross-platform**: Works on Windows, Linux, and macOS
- **IDE integration**: Generates project files for Visual Studio, VS Code, etc.
- **Dependency management**: Handles library linking automatically
- **Testing integration**: Built-in support for CTest
- **Installation support**: Easy packaging and distribution
- **Python integration**: Custom targets for ctypesgen and running Python scripts

## Why ctypesgen Sometimes Fails on Windows

ctypesgen was designed for Unix-like systems and expects:
1. A C preprocessor (`gcc -E`) to parse header files
2. GCC-specific preprocessor flags
3. Standard C library headers in predictable locations

On Windows without MinGW:
- No `gcc` command available
- Microsoft's `cl.exe` preprocessor uses different flags
- ctypesgen falls back to incomplete parsing

## Troubleshooting

### If you get "Cannot load library" errors:

1. Make sure `demolib.dll` is in the same directory as the Python script
2. Check that the DLL was compiled for the same architecture (x64/x86) as your Python
3. Verify that Visual C++ Redistributable is installed

### If ctypesgen generates incomplete bindings:

1. **Install MinGW**: Follow Option A above to install MinGW-w64
2. **Verify gcc is available**: Run `gcc --version` in your terminal
3. **Check PATH**: Ensure MinGW's bin directory is in your system PATH
4. **Fallback**: Use the manual approach (Option B) which always works

### If MinGW installation issues:

1. Try alternative installation: `choco install mingw` (if you have Chocolatey)
2. Use manual approach as it doesn't require any external dependencies
3. Consider using WSL (Windows Subsystem for Linux) for a Linux-like environment

### If CTest fails with "Unknown argument: --config":

The correct flag is `-C` (uppercase), not `--config`:

```cmd
# Correct (multi-config generators like Visual Studio)
ctest -C Release

# Incorrect
ctest --config Release
```

For single-config generators (like Makefiles), omit the configuration:
```cmd
ctest
```
