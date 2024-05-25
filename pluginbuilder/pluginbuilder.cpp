#include <cpptoml.h>
#include <cstdlib> // for system()
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <regex>
#include <stack>
#include <stdexcept>
#include <string>
#include <unordered_set>
#include <vector>
#include <windows.h> // for Windows API functions

namespace fs = std::filesystem;

std::vector<fs::path> whitelist = {"src", "info.toml", "LICENSE", "Readme.md"};

void CloneRepository(const std::string& repoUrl, fs::path& tempDir)
{
	std::string command = "git clone " + repoUrl + " " + tempDir.string();
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

fs::path GetTempDirectory()
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
	return tempDirectory;
}

// ----------------------------------------------------------
// MCPP
// ----------------------------------------------------------
std::vector<fs::path> findASFiles(const fs::path& srcDir)
{
	std::vector<fs::path> inputFiles;

	for (const auto& entry : fs::recursive_directory_iterator(srcDir))
	{
		if (entry.path().extension() == ".as")
		{
			inputFiles.push_back(entry.path());
		}
	}

	return inputFiles;
}

void findDependencies(const fs::path& file, std::unordered_map<fs::path, std::vector<fs::path>>& dependencies, const fs::path& rootDir)
{
	std::ifstream inFile(file);
	std::string line;
	while (std::getline(inFile, line))
	{
		if (line.find("//#require ") != std::string::npos)
		{
			std::string dependency = line.substr(line.find("\"") + 1);
			dependency = dependency.substr(0, dependency.find("\""));
			fs::path dependencyPath = rootDir / fs::weakly_canonical(fs::path(dependency));
			dependencies[file].push_back(dependencyPath);
		}
	}
}

void buildDependencyGraph(const std::vector<fs::path>& inputFiles, std::unordered_map<fs::path, std::vector<fs::path>>& dependencies, const fs::path& rootDir)
{
	for (const auto& file : inputFiles)
	{
		findDependencies(file, dependencies, rootDir);
		if (dependencies.find(file) == dependencies.end())
		{
			dependencies[file] = {}; // Ensure all files are included, even without dependencies
		}
	}
}

bool isCyclicUtil(const fs::path& file, std::unordered_map<fs::path, bool>& visited, std::unordered_map<fs::path, bool>& recStack, const std::unordered_map<fs::path, std::vector<fs::path>>& dependencies)
{
	if (!visited[file])
	{
		visited[file] = true;
		recStack[file] = true;

		for (const auto& dep : dependencies.at(file))
		{
			if (!visited[dep] && isCyclicUtil(dep, visited, recStack, dependencies))
				return true;
			else if (recStack[dep])
				return true;
		}
	}
	recStack[file] = false;
	return false;
}

bool detectCycle(const std::unordered_map<fs::path, std::vector<fs::path>>& dependencies)
{
	std::unordered_map<fs::path, bool> visited;
	std::unordered_map<fs::path, bool> recStack;

	for (const auto& pair : dependencies)
	{
		if (isCyclicUtil(pair.first, visited, recStack, dependencies))
			return true;
	}
	return false;
}

// Utility function for topological sort using DFS
void topologicalSortUtil(const fs::path& file, const std::unordered_map<fs::path, std::vector<fs::path>>& dependencies, std::unordered_set<fs::path>& visited, std::stack<fs::path>& stack)
{
	visited.insert(file);

	for (const auto& dep : dependencies.at(file))
	{
		if (visited.find(dep) == visited.end())
		{
			topologicalSortUtil(dep, dependencies, visited, stack);
		}
	}

	stack.push(file);
}

// Function to perform topological sort
std::vector<fs::path> topologicalSort(const std::unordered_map<fs::path, std::vector<fs::path>>& dependencies)
{
	std::vector<fs::path> sortedFiles;
	std::unordered_set<fs::path> visited;
	std::stack<fs::path> stack;

	for (const auto& pair : dependencies)
	{
		if (visited.find(pair.first) == visited.end())
		{
			topologicalSortUtil(pair.first, dependencies, visited, stack);
		}
	}

	while (!stack.empty())
	{
		sortedFiles.push_back(stack.top());
		stack.pop();
	}

	std::reverse(sortedFiles.begin(), sortedFiles.end());
	return sortedFiles;
}

void createEntryPointFile(const std::vector<fs::path>& sortedFiles, const fs::path& entryPointFilePath)
{
	std::ofstream entryPointFile(entryPointFilePath);

	for (const auto& file : sortedFiles)
	{
		entryPointFile << "EP_COMMENT START FILE: " << file.string() << "\n";
		entryPointFile << "#include \"" << file.string() << "\"\n";
		entryPointFile << "EP_COMMENT END FILE: " << file.string() << "\n";
	}

	entryPointFile.close();
}

std::string generateMacroArguments(const std::vector<std::string>& macros)
{
	std::stringstream macroArgs;
	for (const auto& macro : macros)
	{
		macroArgs << "-D" << macro << " ";
	}
	return macroArgs.str();
}

int runPreprocessorCmd(const fs::path& inputFile, const fs::path& outputFile, const std::vector<std::string>& additionalMacros = {})
{
	// Define the macro map
	const std::vector<std::string> macros = {
		{"AS_IF=#if"},
		{"AS_ELIF=#elif"},
		{"AS_ELSE=#else"},
		{"AS_ENDIF=#endif"},
		{"EP_COMMENT=//"}};

	std::string command = ".\\tools\\mcpp-2.7.2\\bin\\mcpp.exe -W0 -P " + generateMacroArguments(macros) + generateMacroArguments(additionalMacros) + inputFile.string() + " -o " + outputFile.string();
	int result = system(command.c_str());
	if (result != 0)
	{
		throw std::runtime_error("Error running mcpp preprocessor");
	}
	return result;
}

void checkAndLogFile(const fs::path& filePath)
{
	std::cerr << "Checking file path: " << filePath << std::endl;
	if (fs::exists(filePath))
	{
		std::cerr << "File exists: " << filePath << std::endl;
	}
	else
	{
		std::cerr << "File does not exist: " << filePath << std::endl;
	}
}

void splitPreprocessedOutput(const fs::path& preprocessedFile, const fs::path& outputDir)
{
	if (!fs::is_directory(outputDir))
	{
		throw std::runtime_error("Output path is not a directory: " + outputDir.string());
	}

	checkAndLogFile(preprocessedFile);

	std::ifstream inFile(preprocessedFile);
	if (!inFile.is_open())
	{
		throw std::runtime_error("Failed to open preprocessed file: " + preprocessedFile.string());
	}
	std::string line;
	std::ofstream outFile;
	std::string currentFileName;
	fs::path currentFile;

	std::regex startFileRegex(R"(^//[^\S\r\n]+START FILE: (.+)$)");
	std::regex endFileRegex(R"(^//[^\S\r\n]+END FILE: (.+)$)");
	std::smatch match;
	while (std::getline(inFile, line))
	{
		if (std::regex_match(line, match, startFileRegex))
		{
			if (outFile.is_open())
			{
				outFile.close();
			}
			currentFileName = match[1].str();
			currentFile = outputDir / fs::path(currentFileName);

			fs::create_directories(currentFile.parent_path());
			outFile.open(currentFile);
		}
		else if (std::regex_match(line, match, endFileRegex))
		{
			if (match[1].str() != currentFileName)
			{
				throw std::runtime_error("Mismatched START and END FILE markers for: " + match[1].str());
			}
			if (outFile.is_open())
			{
				outFile.close();
			}
		}
		else
		{
			if (outFile.is_open())
			{
				outFile << line << "\n";
			}
		}
	}
}

int preprocess(const fs::path& srcDir, const std::vector<std::string>& additionalMacros = {})
{
	fs::path tempDir = GetTempDirectory();

	// Step 1: Find all .as files
	std::vector<fs::path> inputFiles = findASFiles(srcDir);

	if (inputFiles.empty()) { return 1; }

	// Step 2: Build dependency graph
	std::unordered_map<fs::path, std::vector<fs::path>> dependencies;
	buildDependencyGraph(inputFiles, dependencies, srcDir);

	// Detect and throw error on circular dependencies
	if (detectCycle(dependencies))
	{
		throw std::runtime_error("Circular dependency detected");
	}

	// Step 3: Topological sort to order files by dependency
	std::vector<fs::path> sortedFiles = topologicalSort(dependencies);

	// Ensure all files are included, even without dependencies
	std::unordered_set<fs::path> allFiles(inputFiles.begin(), inputFiles.end());
	for (const auto& file : sortedFiles)
	{
		allFiles.erase(file);
	}
	sortedFiles.insert(sortedFiles.end(), allFiles.begin(), allFiles.end());

	// Step 4: Create entry-point file
	fs::path entryPointFilePath = tempDir / "entry_point.as";
	createEntryPointFile(sortedFiles, entryPointFilePath);

	// Step 5: Run mcpp
	fs::path preprocessedFile = tempDir / "preprocessed_output.as";
	runPreprocessorCmd(entryPointFilePath, preprocessedFile, additionalMacros);

	// Step 6: Split preprocessed output back into original files
	splitPreprocessedOutput(preprocessedFile, srcDir);

	std::cout << "Preprocessing completed successfully!" << std::endl;

	return 0;
}

void CopyFilesAndFolders(const fs::path& srcDir, const fs::path& destDir, const std::vector<fs::path>& filesAndFolders)
{
	for (const auto& path : filesAndFolders)
	{
		fs::path srcPath = srcDir / path;
		fs::path destPath = destDir / path;

		if (fs::exists(srcPath))
		{
			fs::create_directories(destPath.parent_path());
			if (fs::is_directory(srcPath))
			{
				fs::copy(srcPath, destPath, fs::copy_options::recursive);
			}
			else
			{
				fs::copy(srcPath, destPath);
			}
		}
		else
		{
			std::cerr << "Warning: Whitelisted path does not exist: " << srcPath << std::endl;
		}
	}
}

int debug(const fs::path& openPlanetPluginsPath)
{
	fs::path srcDir = "src";
	fs::path destDir = openPlanetPluginsPath / "EditorRouteDev";

	try
	{
		// Safely remove old contents of the destination directory
		if (fs::exists(destDir)) { fs::remove_all(destDir); }

		// Copy whitelisted folders and files to the destination directory
		CopyFilesAndFolders(fs::current_path(), destDir, whitelist);

		// Run preprocessing on the copied src folder
		fs::path destSrcDir = destDir / "src";

		const std::vector<std::string> additionalMacros = 
		{
			{"ER_DEBUG=1"},
		};

		preprocess(destSrcDir, additionalMacros);
	}
	catch (const std::exception& e)
	{
		std::cerr << "Error: " << e.what() << std::endl;
		return 1;
	}

	return 0;
}

int release()
{
	fs::path tempDir;
	try
	{
		tempDir = GetTempDirectory();
		std::string repoUrl = "https://github.com/nicoell/tm-editor-route.git";
		fs::path tomlFile = tempDir / "info.toml";
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
		std::string version = UpdateTomlAndGetVersion(tomlFile.string());

		std::cout << "Run preprocessing on the src folder..." << std::endl;
		// Run preprocessing on the copied src folder
		fs::path destSrcDir = tempDir / "src";

		const std::vector<std::string> additionalMacros = 
		{
			{"ER_RELEASE=1"},
		};
		preprocess(destSrcDir, additionalMacros);

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

int main(int argc, char* argv[])
{
	if (argc < 2)
	{
		std::cerr << "Usage: " << argv[0] << " <command> [<openPlanetPluginsPath>]\n";
		std::cerr << "Commands:\n";
		std::cerr << "  debug <openPlanetPluginsPath>: Copy files and run preprocessing in debug mode.\n";
		std::cerr << "  release: Run preprocessing in release mode.\n";
		return 1;
	}

	std::string command = argv[1];
	fs::path openPlanetPluginsPath;

	// Check for the 'debug' command and ensure the path is provided
	if (command == "debug")
	{
		if (argc < 3)
		{
			std::cerr << "Usage: " << argv[0] << " debug <openPlanetPluginsPath>\n";
			return 1;
		}
		openPlanetPluginsPath = fs::path(argv[2]).make_preferred();
	}

	// Verify we're running in the correct directory
	// Check for info.toml in the current directory
	fs::path currentDir = fs::current_path();
	fs::path infoTomlPath = currentDir / "info.toml";

	if (!fs::exists(infoTomlPath))
	{
		std::cerr << "Error: info.toml not found in the current directory.\n";
		return 1;
	}

	// Read and verify info.toml
	try
	{
		auto config = cpptoml::parse_file(infoTomlPath.string());
		auto meta = config->get_table("meta");
		if (!meta)
		{
			std::cerr << "Error: 'meta' table not found in info.toml.\n";
			return 1;
		}
		auto name = meta->get_as<std::string>("name");
		if (!name || *name != "Editor Route")
		{
			std::cerr << "Error: 'name' entry in 'meta' table is not 'Editor Route'.\n";
			return 1;
		}
	}
	catch (const std::exception& e)
	{
		std::cerr << "Error reading info.toml: " << e.what() << std::endl;
		return 1;
	}

	if (command == "debug")
	{
		return debug(openPlanetPluginsPath);
	}
	else if (command == "release")
	{
		return release();
	}
	else
	{
		std::cerr << "Unknown command: " << command << std::endl;
		return 1;
	}
}
