#include <cpptoml.h>
#include <cstdlib> // for system()
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
#include <windows.h> // for Windows API functions

namespace fs = std::filesystem;

void CloneRepository(const std::string& repoUrl, const std::string& tempDir)
{
	std::string command = "git clone " + repoUrl + " " + tempDir;
	int result = std::system(command.c_str());
	if (result != 0)
	{
		throw std::runtime_error("Failed to clone repository: command exited with code " + std::to_string(result));
	}
}

std::string GetVersionFromToml(const std::shared_ptr<cpptoml::table>& config)
{
	auto meta = config->get_table("meta");
	if (meta)
	{
		auto version = meta->get_as<std::string>("version");
		if (version)
		{
			return *version;
		}
	}
	throw std::runtime_error("Version not found in TOML file");
}

void UpdateDefinesInToml(const std::shared_ptr<cpptoml::table>& config)
{
	auto script = config->get_table("script");
	if (!script)
	{
		throw std::runtime_error("Script table not found in TOML file");
	}

	auto defines = script->get_array_of<std::string>("defines");
	if (!defines)
	{
		throw std::runtime_error("Defines array not found in script table of TOML file");
	}

	std::vector<std::string> newDefines;
	for (const auto& define : *defines)
	{
		if (define == "ER_DEBUG")
		{
			newDefines.push_back("ER_SHIPPING");
		}
		else
		{
			newDefines.push_back(define);
		}
	}

	auto newDefinesToml = cpptoml::make_array();
	for (const auto& define : newDefines)
	{
		newDefinesToml->push_back(define);
	}
	script->insert("defines", newDefinesToml);
}

void WriteTomlFile(const std::string& filePath, const std::shared_ptr<cpptoml::table>& config)
{
	std::ofstream out(filePath, std::ios::out | std::ios::trunc);
	if (!out)
	{
		throw std::runtime_error("Failed to open file for writing: " + filePath);
	}
	out << (*config);
	out.close();
	if (out.fail())
	{
		throw std::runtime_error("Failed to write to file: " + filePath);
	}
}

std::string UpdateTomlAndGetVersion(const std::string& filePath)
{
	try
	{
		auto config = cpptoml::parse_file(filePath);
		std::string version = GetVersionFromToml(config);
		UpdateDefinesInToml(config);
		WriteTomlFile(filePath, config);
		return version;
	}
	catch (const std::exception& e)
	{
		std::cerr << "Error updating TOML file and getting version: " << e.what() << std::endl;
		throw;
	}
}

void CreateZip(const std::string& zipPath, const fs::path& basePath, const std::vector<fs::path>& whitelist)
{
	auto currentPath = fs::current_path();
	fs::current_path(basePath);

	std::string command = "7z a -tzip \"" + zipPath + "\"";
	for (const auto& file : whitelist)
	{
		command += " \"" + file.string() + "\"";
	}

	int result = std::system(command.c_str());
	if (result != 0)
	{
		fs::current_path(currentPath);
		throw std::runtime_error("Failed to create ZIP archive with 7-Zip");
	}

	fs::current_path(currentPath);
}

bool ConfirmOverwrite(const std::string& filePath)
{
	std::cout << "The file " << filePath << " already exists. Do you want to replace it? (Y/N): ";
	char response;
	std::cin >> response;
	return response == 'Y' || response == 'y';
}

std::string GetTempDirectory()
{
	char tempPath[MAX_PATH];
	if (GetTempPathA(MAX_PATH, tempPath) == 0)
	{
		throw std::runtime_error("Failed to get temporary path");
	}

	char tempDir[MAX_PATH];
	if (GetTempFileNameA(tempPath, "plugin", 0, tempDir) == 0)
	{
		throw std::runtime_error("Failed to get temporary directory name");
	}

	// Create a directory from the temp file name
	fs::path tempDirectory(tempDir);
	fs::remove(tempDirectory); // Remove the temp file
	fs::create_directory(tempDirectory); // Create a directory instead
	return tempDirectory.string();
}

int main()
{
	std::string tempDir;
	try
	{
		tempDir = GetTempDirectory();
		std::string repoUrl = "https://github.com/nicoell/tm-editor-route.git";
		std::string tomlFile = tempDir + "/info.toml";
		std::string zipFile = "EditorRoute.op";

		std::vector<fs::path> whitelist = {"src", "info.toml", "LICENSE", "Readme.md"};

		if (fs::exists(tempDir))
		{
			std::cout << "Removing existing temporary directory..." << std::endl;
			fs::remove_all(tempDir);
		}

		std::cout << "Cloning repository..." << std::endl;
		CloneRepository(repoUrl, tempDir);

		std::cout << "Updating TOML configuration and reading version..." << std::endl;
		std::string version = UpdateTomlAndGetVersion(tomlFile);

		std::cout << "Creating ZIP archive..." << std::endl;
		CreateZip(zipFile, tempDir, whitelist);

		fs::path destination = fs::current_path() / "archive" / version;
		std::cout << "Creating destination directory: " << destination << std::endl;
		fs::create_directories(destination);

		if (!fs::exists(destination))
		{
			throw std::runtime_error("Failed to create destination directory: " + destination.string());
		}

		fs::path sourceZipPath = fs::absolute(fs::path(tempDir) / zipFile);
		fs::path destinationZipPath = fs::absolute(destination / zipFile);

		if (fs::exists(destinationZipPath))
		{
			if (!ConfirmOverwrite(destinationZipPath.string()))
			{
				std::cout << "Operation canceled by user." << std::endl;
				fs::remove_all(tempDir);
				return 0;
			}
		}

		std::cout << "Moving ZIP file to destination: " << destinationZipPath << std::endl;
		fs::rename(sourceZipPath, destinationZipPath);

		std::cout << "Cleaning up temporary files..." << std::endl;
		fs::remove_all(tempDir);

		std::cout << "Build completed successfully." << std::endl;
	}
	catch (const std::exception& e)
	{
		std::cerr << "Error: " << e.what() << std::endl;
		if (!tempDir.empty() && fs::exists(tempDir))
		{
			std::cout << "Cleaning up temporary files..." << std::endl;
			fs::remove_all(tempDir);
		}
		return 1;
	}

	return 0;
}
