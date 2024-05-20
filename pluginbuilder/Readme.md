### Plugin Builder Script Documentation

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

### Usage

#### Running the Script

1. Ensure all dependencies are installed as per the instructions above.
2. Open the `pluginbuilder.sln` solution file in Visual Studio. This solution is pre-configured with all necessary settings.
3. Build the project to generate the executable.
4. Run the executable from the command line or within Visual Studio.

   ```sh
   <path-to-executable>
   ```

   The script will clone the repository, update the TOML file, create a ZIP archive, and move it to the specified destination.
