### Plugin Builder Script Documentation

> I do not recommend to anyone using this. It is highly experimental, hacked and unstable.

This document provides step-by-step instructions on how to install all the dependencies required to run the Plugin Builder script and how to use the script.

#### Table of Contents

1. [Dependencies](#dependencies)
2. [Installation](#installation)
   - [Install Git](#install-git)
   - [Install 7-Zip](#install-7-zip)
   - [Install vcpkg](#install-vcpkg)
3. [Usage](#usage)
   - [Running the Script](#running-the-script)

### Dependencies

- Git
- 7-Zip
- vcpkg (for cpptoml package)
- Visual Studio (with C++ support)
- mcpp

### Installation

#### Install Git

1. Download Git from the official website: [https://git-scm.com/downloads](https://git-scm.com/downloads)
2. Run the installer and follow the instructions to complete the installation.
3. Verify the installation by opening a command prompt and typing:

   ```sh
   git --version
   ```

#### Install 7-Zip

1. Download 7-Zip from the official website: [https://www.7-zip.org/download.html](https://www.7-zip.org/download.html)
2. Run the installer and follow the instructions to complete the installation.
3. Verify the installation by opening a command prompt and typing:

   ```sh
   7z
   ```

   This should display the 7-Zip command-line options.
   
#### Install vcpkg

Follow the official Microsoft documentation to install and set up vcpkg: [Get Started with vcpkg](https://learn.microsoft.com/en-us/vcpkg/get-started/get-started-msbuild).

#### Download mcpp

1. Download mcpp from the official website: https://mcpp.sourceforge.net/download.html
2. Make `mcpp.exe` available to the command line by adding it to PATH enviroment variable.

### Usage

#### Running the Script

1. Ensure all dependencies are installed as per the instructions above.
2. Open the `pluginbuilder.sln` solution file in Visual Studio. This solution is pre-configured with all necessary settings.
3. Build the project to generate the executable.
4. Run the executable from the command line or within Visual Studio.

   ```sh
   <path-to-executable> <command> [<openPlanetPluginsPath>]
   ```

   Where `<command>` can be one of the following:
   -  `debug <openPlanetPluginsPath>`: Copy files and run preprocessing in debug mode.
   - `release`: Run preprocessing in release mode.

Example:

```sh
pluginbuilder.exe debug C:/Users/YourUsername/OpenplanetNext/Plugins
pluginbuilder.exe release
```

#### Debug Mode

1. Copy all whitelisted files and folders (`src`, `info.toml`, `LICENSE`, `Readme.md`) to the specified output folder `C:\Users\Nico\OpenplanetNext\Plugins\EditorRouteDev`. Ensure to delete contents of this folder beforehand.
2. Run the preprocessing directly on the `src` folder copied to `C:\Users\Nico\OpenplanetNext\Plugins\EditorRouteDev`, replacing the file contents with the preprocessed files.

#### Release Mode
1. Clone the repository.
2. Run the preprocessing directly on the `src` folder that was cloned.
3. Zip all whitelisted files and folders (`src`, `info.toml`, `LICENSE`, `Readme.md`) to `EditorRoute.op`.

### Writing Code

#### `//#require` Comment

To handle dependencies between AngelScript files, use the `//#require` comment to specify the required files. Paths are relative to the root folder.

Example:
```c++
//#require "My/Other/File.as"
```

This directive ensures that `My/Other/File.as` is processed before the current file.

#### Preprocessor Directives

To use builtin OpenPlanet preprocessor directives, use these predefined custom macros:
```c++
#define AS_IF #if
#define AS_ELIF #elif
#define AS_ELSE #else
#define AS_ENDIF #endif
```

Use these macros in your AngelScript files:
```angelscript
AS_IF TMNEXT
  print("I am running on Trackmania (2020)");
AS_ELIF MP4
  print("I am running on Maniaplanet 4");
AS_ELSE
  print("I am running on a different game");
AS_ENDIF
```

