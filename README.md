# Ctypesgen Windows Demo

Generate Python bindings for C libraries using ctypesgen on Windows with automatic setup.

## Quick Start

1. **Install Prerequisites**
   - Python 3.x
   - CMake 3.22+
   - Visual Studio or Build Tools for Visual Studio
   - Git

2. **Build and Run**
   ```cmd
   # Clone and build everything automatically
   git clone https://github.com/dudaka/ctypesgen-windows-demo.git
   cd ctypesgen-windows-demo
   build.bat
   ```

3. **Test the Result**
   ```cmd
   python demoapp.py
   ```

That's it! The build script automatically:
- Clones MinGW-w64 from GitHub
- Clones ctypesgen from GitHub  
- Builds the C library
- Generates Python bindings
- Runs the demo

## What This Demo Does

- **C Library**: Simple math functions in `demolib.c`
- **Python Bindings**: Auto-generated with ctypesgen
- **Demo App**: Python script that calls C functions

## Manual Build Steps

If you prefer to run commands manually:

```cmd
# 1. Configure with CMake
cmake -B build -S .

# 2. Build the library
cmake --build build --config Release

# 3. Generate Python bindings
cmake --build build --target python_bindings --config Release

# 4. Run the demo
python demoapp.py
```

## Expected Output

```text
a 1
b 2
result 3
DB_C_TYPE_STRING 1
```

## How It Works

1. **Automatic Setup**: CMake automatically clones and builds MinGW-w64 and ctypesgen from source
2. **C Compilation**: Uses Visual Studio compiler to build the demo library
3. **Binding Generation**: Uses ctypesgen with MinGW's GCC preprocessor to parse headers
4. **Python Integration**: Generated bindings let Python call C functions directly

## Files

- `demolib.c` / `demolib.h` - Simple C library with math functions
- `demoapp.py` - Python demo using the generated bindings
- `CMakeLists.txt` - Build configuration with automatic tool setup
- `build.bat` - Windows quick-start script

## Troubleshooting

**"Cannot load library" error:**

- Make sure you're running from the project directory
- Check that `demolib.dll` exists in the build output

**ctypesgen errors:**

- The build process automatically handles this by building ctypesgen from source
- MinGW provides the GCC preprocessor that ctypesgen needs on Windows

**Build failures:**

- Make sure you have Visual Studio or Build Tools installed
- Run from a Developer Command Prompt for best results
