namespace EditorRoutePath
{
    string Normalize(const string &in path)
    {
       // Replace backslashes with forward slashes
        string normalizedPath = Regex::Replace(path, "\\\\", "/", Regex::Flags::ECMAScript);
        
        // Remove any redundant slashes (e.g., "///" to "/")
        normalizedPath = Regex::Replace(normalizedPath, "/{2,}", "/", Regex::Flags::ECMAScript);
        
        // Keep/add preceding slashes unless the path starts with a drive letter
        if (normalizedPath.Length > 1 && !normalizedPath.StartsWith("/") && !Regex::Contains(normalizedPath, "^[A-Za-z]:", Regex::Flags::ECMAScript))
        {
            normalizedPath = "/" + normalizedPath;
        }
        
        return normalizedPath;
    }

    string NormalizeFileName(string &in str)
	{
		const string pattern = "[\\\\/:*?\"<>|]"; // Matches any character in the set
    	// Replace all matches of invalid characters with an empty string
    	return Regex::Replace(str, pattern, "", Regex::Flags::ECMAScript);
	}

    string Join(const string &in path1, const string &in path2)
    {
        string normalizedPath1 = Normalize(path1);
        string normalizedPath2 = Normalize(path2);

        if (normalizedPath1.Length == 0)
        {
            return normalizedPath2;
        }
        if (normalizedPath2.Length == 0)
        {
            return normalizedPath1;
        }

        normalizedPath1 = Normalize(normalizedPath1 + "/" + normalizedPath2);

        return normalizedPath1;
    }

    string DirName(const string &in path)
    {
        string normalizedPath = Normalize(path);
        string pattern = "(.*)/[^/]*$";
        string[]@ matches = Regex::Search(normalizedPath, pattern, Regex::Flags::ECMAScript);

        if (matches.Length > 1)
        {
            return matches[1] + "/";
        }
        return "";
    }

    string FileName(const string &in path)
    {
        string normalizedPath = Normalize(path);
        string pattern = ".*/([^/]*)$";
        string[]@ matches = Regex::Search(normalizedPath, pattern, Regex::Flags::ECMAScript);

        if (matches.Length > 1)
        {
            return matches[1];
        }
        return normalizedPath;
    }

    array<string> Split(const string &in path)
    {
        string normalizedPath = Normalize(path);
        
        // Regex to split the path while keeping the drive letter if present
        string pattern = "^([A-Za-z]:)?(.*)$";
        string[]@ matches = Regex::Search(normalizedPath, pattern, Regex::Flags::ECMAScript);
        
        array<string> components;

        if (matches.Length > 2)
        {
            // Add drive letter if present
            if (matches[1].Length > 0)
            {
                components.InsertLast(matches[1]);
            }

            // Split the rest of the path into components
            array<string> pathComponents = matches[2].Split("/");
            for (uint32 i = 0; i < pathComponents.Length; i++)
            {
                if (pathComponents[i].Length > 0)
                {
                    components.InsertLast(pathComponents[i]);
                }
            }
        }

        return components;
    }

    string LastFolder(const string &in path)
    {
        string normalizedPath = Normalize(path);
        string[]@ matches = Regex::Search(normalizedPath, ".*\\/([^\\/]+)\\/", Regex::Flags::ECMAScript);
        return matches.Length > 1 ? matches[1] : "";
    }

    string FileNameWithoutExtension(const string &in path)
    {
        string fileName = FileName(path);
        string pattern = "^(.*)\\.[^.]+$";
        string[]@ matches = Regex::Search(fileName, pattern, Regex::Flags::ECMAScript);

        if (matches.Length > 1)
        {
            return matches[1];
        }
        return fileName;
    }

    string FileNameWithoutExtension(const string &in path, const string &in extension)
    {
        string fileName = FileName(path);
        string pattern = "\\.(" + extension + ")$";
        string[]@ matches = Regex::Search(fileName, pattern, Regex::Flags::ECMAScript | Regex::Flags::CaseInsensitive);
        if (matches.Length > 1)
        {
            return matches[1];
        }
        return "";
    }

    bool HasExtension(const string &in path, const string &in extension)
    {
        string fileName = FileName(path);
        string pattern = "\\.(" + extension + ")$";
        return Regex::Search(fileName, pattern, Regex::Flags::ECMAScript | Regex::Flags::CaseInsensitive).Length > 0;
    }

    // ---------------------------------------------------------------

    namespace Tests
    {
        void RunTests()
        {
            TestNormalize();
            TestNormalizeFileName();
            TestJoin();
            TestDirName();
            TestFileName();
            TestLastFolder();
            TestFileNameWithoutExtension();
            TestHasExtension();
        }

        void TestNormalize()
        {
            print("\\$00f Testing Normalize...");
            AssertEqual(EditorRoutePath::Normalize("C:\\\\Users\\\\Test"), "C:/Users/Test", "Normalize backslashes");
            AssertEqual(EditorRoutePath::Normalize("C:/Users///Test/"), "C:/Users/Test/", "Normalize redundant slashes");
            AssertEqual(EditorRoutePath::Normalize("/Users/Test/"), "/Users/Test/", "Normalize trailing slash");
            AssertEqual(EditorRoutePath::Normalize("Users/Test"), "/Users/Test", "Normalize preceding slash");
            AssertEqual(EditorRoutePath::Normalize("C:/Users/Test"), "C:/Users/Test", "Normalize drive letter");
            AssertEqual(EditorRoutePath::Normalize("\\Users/Test\\"), "/Users/Test/", "Normalize mixed slashes");
            AssertNotEqual(EditorRoutePath::Normalize("C:/Users/../Test"), "C:/Test", "(Unsupported) Normalize path with parent directory fails");
            AssertNotEqual(EditorRoutePath::Normalize("./Users/Test"), "/Users/Test", "(Unsupported) Normalize path with current directory fails");
        }

        void TestNormalizeFileName()
        {
            print("\\$00f Testing NormalizeFileName...");
            AssertEqual(EditorRoutePath::NormalizeFileName("file:name|with*invalid<>characters?"), "filenamewithinvalidcharacters", "Normalize invalid characters");
            AssertEqual(EditorRoutePath::NormalizeFileName("valid_file-name.ext"), "valid_file-name.ext", "Normalize valid filename");
        }

        void TestJoin()
        {
            print("\\$00f Testing Join...");
            AssertEqual(EditorRoutePath::Join("C:/Users", "Test"), "C:/Users/Test", "Join two paths");
            AssertEqual(EditorRoutePath::Join("/Users/", "Test"), "/Users/Test", "Join with trailing slash in the first path");
            AssertEqual(EditorRoutePath::Join("Users", "Test"), "/Users/Test", "Join two relative paths");
            AssertEqual(EditorRoutePath::Join("", "Test"), "/Test", "Join with empty first path");
            AssertEqual(EditorRoutePath::Join("C:/Users", ""), "C:/Users", "Join with empty second path");
        }

        void TestDirName()
        {
            print("\\$00f Testing DirName...");
            AssertEqual(EditorRoutePath::DirName("C:/Users/Test/file.txt"), "C:/Users/Test/", "DirName for a file path");
            AssertEqual(EditorRoutePath::DirName("/Users/Test/"), "/Users/Test/", "DirName for a directory path");
            AssertEqual(EditorRoutePath::DirName("/Users/Test"), "/Users/", "DirName for file without extension");
            AssertEqual(EditorRoutePath::DirName("file.txt"), "/", "DirName for a file in the current directory");
            AssertEqual(EditorRoutePath::DirName("/file.txt"), "/", "DirName for a file in the root directory");
        }

        void TestFileName()
        {
            print("\\$00f Testing FileName...");
            AssertEqual(EditorRoutePath::FileName("C:/Users/Test/file.txt"), "file.txt", "FileName for a file path");
            AssertEqual(EditorRoutePath::FileName("/Users/Test/"), "", "FileName for a directory path");
            AssertEqual(EditorRoutePath::FileName("/Users/Test"), "Test", "FileName for file without extension");
            AssertEqual(EditorRoutePath::FileName("file.txt"), "file.txt", "FileName for a file in the current directory");
            AssertEqual(EditorRoutePath::FileName("/"), "", "FileName for the root directory");
        }

        void TestLastFolder()
        {
            print("\\$00f Testing LastFolder...");
            AssertEqual(EditorRoutePath::LastFolder("C:/Users/Test/"), "Test", "LastFolder for an absolute path");
            AssertEqual(EditorRoutePath::LastFolder("Users/Test"), "Users", "LastFolder for a relative path");
            AssertEqual(EditorRoutePath::LastFolder("/"), "", "LastFolder for the root directory");
            AssertEqual(EditorRoutePath::LastFolder("C:/"), "", "LastFolder for a drive root directory");
        }

        void TestFileNameWithoutExtension()
        {
            print("\\$00f Testing FileNameWithoutExtension...");
            AssertEqual(EditorRoutePath::FileNameWithoutExtension("C:/Users/Test/file.txt"), "file", "FileNameWithoutExtension with extension");
            AssertEqual(EditorRoutePath::FileNameWithoutExtension("C:/Users/Test/file"), "file", "FileNameWithoutExtension without extension");
            AssertEqual(EditorRoutePath::FileNameWithoutExtension("C:/Users/Test/file.name.txt"), "file.name", "FileNameWithoutExtension with multiple dots");
            AssertEqual(EditorRoutePath::FileNameWithoutExtension("C:/Users/Test/.hiddenfile"), "", "FileNameWithoutExtension for hidden file");
        }

        void TestHasExtension()
        {
            print("\\$00f Testing HasExtension...");
            AssertEqual(EditorRoutePath::HasExtension("C:/Users/Test/file.txt", "txt"), true, "HasExtension matching");
            AssertEqual(EditorRoutePath::HasExtension("C:/Users/Test/file.txt", "json"), false, "HasExtension non-matching");
            AssertEqual(EditorRoutePath::HasExtension("C:/Users/Test/file.TXT", "txt"), true, "HasExtension case insensitive match");
            AssertEqual(EditorRoutePath::HasExtension("C:/Users/Test/file", "txt"), false, "HasExtension without extension");
        }

        void AssertEqual(const string &in actual, const string &in expected, const string &in testName)
        {
            if (actual == expected)
            {
                print("\\$0f0 Passed: " + testName);
            }
            else
            {
                print("\\$f00 Failed: " + testName + " | Expected: " + expected + " | Actual: " + actual);
            }
        }

        void AssertEqual(bool actual, bool expected, const string &in testName)
        {
            if (actual == expected)
            {
                print("\\$0f0 Passed: " + testName);
            }
            else
            {
                print("\\$f00 Failed: " + testName + " | Expected: " + expected + " | Actual: " + actual);
            }
        }

        void AssertNotEqual(const string &in actual, const string &in expected, const string &in testName)
        {
            if (actual != expected)
            {
                print("\\$0f0 Passed: " + testName);
            }
            else
            {
                print("\\$f00 Failed: " + testName + " | Expected: " + expected + " | Actual: " + actual);
            }
        }

        void AssertNotEqual(bool actual, bool expected, const string &in testName)
        {
            if (actual != expected)
            {
                print("\\$0f0 Passed: " + testName);
            }
            else
            {
                print("\\$f00 Failed: " + testName + " | Expected: " + expected + " | Actual: " + actual);
            }
        }

        void Main()
        {
            RunTests();
        }

    }
}
