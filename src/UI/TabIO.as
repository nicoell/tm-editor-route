namespace EditorRouteUI
{
	// ---------------------------------------------------------------
	// IO Tab
	// ---------------------------------------------------------------
	namespace TabIO
	{
		// Class to hold game map information
		class FGameMapInfo
		{
			string UID;
			string RelativeFolder;
			string MapName;
			string MapNameForUI;
			bool bIsValid;

			FGameMapInfo()
			{
				UID = "Invalid";
				RelativeFolder = "";
				MapName = "";
				bIsValid = false;
			}

			FGameMapInfo(CGameCtnChallengeInfo &in gameMapInfo)
			{
				RelativeFolder = EditorRoutePath::Normalize(gameMapInfo.Path);
				if (gameMapInfo.Fid !is null)
				{
					MapName = gameMapInfo.Fid.ShortFileName;
					MapNameForUI = gameMapInfo.NameForUi;
					UID = gameMapInfo.MapUid;
				}
				else
				{
					MapName = "Unnamed";
					MapNameForUI = "Unnamed";
					UID = "Unassigned";
				}
				bIsValid = true;
			}

			string EncodeMapFolderName()
			{
				return "{" + UID + "}" + MapName;
			}
		}
		
		// Class to hold route map information
		class FRouteMapInfo
		{
			string UID;
			string MapName;
			// Only the current Map has OpenPlanet Formatted names
			string MapNameForUI;
			string RelativeFolder;
			bool bIsCurrentMap;
			array<FSavedRouteInfo@> Routes;
			
			FRouteMapInfo(const string &in uid, const string &in mapName, const string &in relativeFolder)
			{
				UID = uid;
				MapName = mapName;
				MapNameForUI = mapName; // No special map name for UI for routes loaded from file
				RelativeFolder = relativeFolder;
				bIsCurrentMap = false;
			}

			FRouteMapInfo(const FGameMapInfo &in mapInfo)
			{
				UID = mapInfo.UID;
				MapName = mapInfo.MapName;
				MapNameForUI = mapInfo.MapNameForUI;
				RelativeFolder = EditorRoutePath::Join(mapInfo.RelativeFolder, EncodeMapFolderName());
				bIsCurrentMap = true;
			}

			void SetCurrentMapInfo(const FGameMapInfo &in mapInfo)
			{
				if (UID == mapInfo.UID)
				{
					MapNameForUI = mapInfo.MapNameForUI;
					bIsCurrentMap = true;
				}
			}

			string EncodeMapFolderName()
			{
				return "{" + UID + "}" + MapName;
			}
		}

		// Class to hold saved route information
		class FSavedRouteInfo
		{
			string FullPath;
			string FileName;
			string RouteName;
			int64 Timestamp;

			FSavedRouteInfo(const string &in fullPath, const string &in fileName, const string &in routeName, int64 timestamp)
			{
				FullPath = fullPath;
				FileName = fileName;
				RouteName = routeName;
				Timestamp = timestamp;
			}
		}
		
		// ---------------------------------------------------------------
		// Variables
		// ---------------------------------------------------------------
		const string RoutesPathRelative = "/Saved/Routes";
		string RoutesPath;

		dictionary MapUIDToRoutesDict;
		dictionary FolderTreeToMapUIDDict;

		string UserRouteName = "MyEditorRoute";
		FGameMapInfo CurrentMapInfo;

		bool bIsRoutesFileListDirty = true;

		// ---------------------------------------------------------------
		// Functions
		// ---------------------------------------------------------------
		void ProcessRouteFile(const string &in fullPath)
		{
			if (EditorRoutePath::HasExtension(fullPath, "json"))
			{
				string relativePath = EditorRoutePath::Normalize(Regex::Replace(fullPath, "^" + RoutesPath + "/?", "", Regex::Flags::ECMAScript));

				string relativeFolder = EditorRoutePath::DirName(relativePath);
				string fileName = EditorRoutePath::FileName(relativePath);
				string pattern = "(\\d*)_(.*)\\.json";
				string[]@ matches = Regex::Search(fileName, pattern, Regex::Flags::ECMAScript);

				string routeName;
				int64 timestamp;

				if (matches.Length > 2)
				{
					routeName = matches[2].Length > 0 ? matches[2] : "Unnamed";
					timestamp = matches[1].Length > 0 ? Text::ParseInt64(matches[1]) : 0;
				}
				else if (matches.Length > 1)
				{
					routeName = "Unnamed";
					timestamp = 0;
				}

				string mapName = EditorRoutePath::LastFolder(relativeFolder);

				string uid = Regex::Replace(mapName, "^[^{]*\\{([^\\}]+)\\}.*$", "$1", Regex::Flags::ECMAScript);
				mapName = Regex::Replace(mapName, "^[^{]*\\{[^\\}]*\\}", "", Regex::Flags::ECMAScript);

				if (RUtils::IsBase64Url(uid))
				{
					if (!MapUIDToRoutesDict.Exists(uid))
					{
						FRouteMapInfo mapRouteInfo(uid, mapName, relativeFolder);
						MapUIDToRoutesDict.Set(uid, @mapRouteInfo);
					}
					FRouteMapInfo@ mapRouteInfo;
					MapUIDToRoutesDict.Get(uid, @mapRouteInfo);

					FSavedRouteInfo@ routeInfo = FSavedRouteInfo(fullPath, fileName, routeName, timestamp);
					mapRouteInfo.Routes.InsertLast(routeInfo);

					return;
				}
				else
				{
					RUtils::DebugWarn("Invalid MapUID '" + uid + "'");
				}
			}
			
			RUtils::DebugPrint("Skipping unsupported file: \\$aaa" + fullPath);
		}

		void RegisterCurrentMap()
		{
			if (!MapUIDToRoutesDict.Exists(CurrentMapInfo.UID))
			{
				FRouteMapInfo mapRouteInfo(CurrentMapInfo);
				MapUIDToRoutesDict.Set(CurrentMapInfo.UID, @mapRouteInfo);
			}
			else
			{
				FRouteMapInfo@ mapRouteInfo;
				MapUIDToRoutesDict.Get(CurrentMapInfo.UID, @mapRouteInfo);
				mapRouteInfo.SetCurrentMapInfo(CurrentMapInfo);
			}
		}

		void PopulateFolderTree()
		{
			array<string> uids = MapUIDToRoutesDict.GetKeys();
			int32 foundIndex = uids.Find(CurrentMapInfo.UID);
			if (foundIndex >= 0)
			{
				uids.RemoveAt(foundIndex);
				uids.InsertAt(0, CurrentMapInfo.UID);
			}

			for (uint32 i = 0; i < uids.Length; i++)
			{
				string uid = uids[i];
				FRouteMapInfo@ mapRouteInfo;
				MapUIDToRoutesDict.Get(uid, @mapRouteInfo);

				string mapFolderFromRoot = EditorRoutePath::Join("root", mapRouteInfo.RelativeFolder);
				array<string> folderParts = EditorRoutePath::Split(mapFolderFromRoot);
				dictionary@ currentLevel = FolderTreeToMapUIDDict;
				for (uint32 j = 0; j < folderParts.Length; j++)
				{
					string folderPart = folderParts[j];
					if (j == folderParts.Length - 1)
					{
						if (!currentLevel.Exists(uid))
						{
							dictionary newLevel;
							currentLevel.Set(uid, @newLevel);
						}
						currentLevel.Get(uid, @currentLevel);
					}
					else
					{
						if (!currentLevel.Exists(folderPart))
						{
							dictionary newLevel;
							currentLevel.Set(folderPart, @newLevel);
						}
						currentLevel.Get(folderPart, @currentLevel);
					}
				}
			}
		}

		// ---------------------------------------------------------------
		// Init
		// ---------------------------------------------------------------
		void Init()
		{
			// ---------------------------------------------------------------
			// Current Map Info
			try
			{
				auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
				auto map = editor.Challenge;
				CurrentMapInfo = FGameMapInfo(map.MapInfo);
			} catch 
			{
				CurrentMapInfo = FGameMapInfo();
			};

			// ---------------------------------------------------------------
			// Load and process Route Files
			if (bIsRoutesFileListDirty)
			{

				RoutesPath = EditorRoutePath::Normalize(IO::FromStorageFolder(RoutesPathRelative));
				IO::CreateFolder(RoutesPath, true);

				auto routesFileList = IO::IndexFolder(RoutesPath, true);
				routesFileList.Reverse(); // Reverse to show newest file first

				// Clear old Data
				MapUIDToRoutesDict.DeleteAll();
				FolderTreeToMapUIDDict.DeleteAll();

				for (uint32 i = 0; i < routesFileList.Length; i++)
				{
					ProcessRouteFile(routesFileList[i]);
				}

				// Add / Modify entry for current map
				// ---------------------------------------------------------------
				RegisterCurrentMap();
				
				// Populate FolderTreeToMapUIDDict and place current Map at first index
				// ---------------------------------------------------------------
				PopulateFolderTree();

				bIsRoutesFileListDirty = false;
			}
		}

		// ---------------------------------------------------------------
		// Draw Functions for Table Nodes & Rows
		// ---------------------------------------------------------------
		void DrawRouteInfoNode(FRouteMapInfo@ mapRouteInfo, FSavedRouteInfo@ route, int32 rowIndex) 
		{
			UI::TableNextRow();
			UI::TableNextColumn();

			// Name
			// ---------------------------------------------------------------
			if (UI::TreeNode(route.RouteName, UI::TreeNodeFlags::Leaf | UI::TreeNodeFlags::SpanAvailWidth))
			{
				UI::TreePop();
			}
			RUtils::AddTooltipText("File: " + route.FileName);

			// Time
			// ---------------------------------------------------------------
			UI::TableNextColumn();
			UI::Text(Time::FormatString("\\$i\\$ccc%Y-%m-%d \\$aaa%H:%M:%S", route.Timestamp));

			// Actions
			// ---------------------------------------------------------------
			UI::TableNextColumn();

			// Load Route
			if (UI::Button(Icons::SignIn + "##" + rowIndex)) 
			{
				RouteSerialization::LoadRoute(route.FullPath);
			}
			RUtils::AddTooltipText("Load Route");
			UI::SameLine();
			
			// Open Folder
			if (UI::Button(Icons::FolderO + "##" + rowIndex)) 
			{
				OpenExplorerPath(EditorRoutePath::DirName(route.FullPath));
			}
			RUtils::AddTooltipText("Open Folder");
			UI::SameLine();

			// Delete File
			const bool bIsShiftPressed = InputHandler::bIsShiftKeyPressed;
			if (UI::Button((bIsShiftPressed ?  "\\$d32" : "\\$aaa") + Icons::Trash + "##" + rowIndex) && bIsShiftPressed) 
			{
				IO::Delete(route.FullPath);
				// Refresh the routes list
				bIsRoutesFileListDirty = true;
			}
			if (bIsShiftPressed)
			{
				RUtils::AddTooltipText("Delete Route file");
			}
			else
			{
				RUtils::AddTooltipText("Hold '\\$iShift\\$i'-Key to delete Routes");
			}
		}

		void DrawExportRouteRow(FRouteMapInfo &inout mapRouteInfo)
		{
			UI::TableNextRow();
			UI::TableNextColumn();
						
			int32 sv = 0;
			sv += PushStyleVarForced(UI::StyleVar::CellPadding, UI::GetStyleVarVec2(UI::StyleVar::CellPadding) + vec2(0., 3.));
			
			UI::TableSetBgColor(UI::TableBgTarget::RowBg0, vec4(233., 196., 1., 32.) / 255.);

			const bool bHasSelectedRoute = RouteContainer::GetSelectedRoute() !is null;
			const bool bCanSaveFile = CurrentMapInfo.bIsValid && bHasSelectedRoute;
			if (RouteSerialization::bIsSaving)
			{
				UI::ProgressBar(-0.001 * Time::Now, vec2(0), "Processing...");
			}
			else if (bCanSaveFile)
			{
				UI::SeparatorText("Export Route " + RouteContainer::Table::SelectedRouteIndex);
				UI::TableNextColumn();

				UI::TableNextRow();
				UI::TableNextColumn();
				UI::TableSetBgColor(UI::TableBgTarget::RowBg0, vec4(233., 196., 1., 32.) / 255.);

				bool bHasChanged = false;
				UI::PushItemWidth(-1);
				UserRouteName = UI::InputText("##Route Name" + mapRouteInfo.UID, UserRouteName, bHasChanged, UI::InputTextFlags::AutoSelectAll);
				UI::PopItemWidth();
				if (bHasChanged)
				{
					UserRouteName = EditorRoutePath::NormalizeFileName(UserRouteName);
				}
				
				UI::TableNextColumn();

				UI::Text(Time::FormatString("\\$ccc%Y-%m-%d \\$aaa%H:%M:%S", Time::Stamp));
				
				UI::TableNextColumn();
				// Save to File
				if (UI::Button(Icons::FloppyO + "##" + mapRouteInfo.UID))
				{
					string routeFileName = EditorRoutePath::NormalizeFileName(Time::Stamp + "_" + UserRouteName) + ".json";
					string savedRoutePath = EditorRoutePath::Join(
						RoutesPath, 
						EditorRoutePath::Join(mapRouteInfo.RelativeFolder, routeFileName)
					);

					RouteSerialization::ExportRouteToFile(RouteContainer::Table::SelectedRouteIndex, savedRoutePath);
				}
				RUtils::AddTooltipText("Export to file");
				UI::SameLine();

				// Upload to BlenderMania
				if (UI::Button(Icons::CloudUpload + "##" + mapRouteInfo.UID))
				{
					RouteSerialization::UploadRoute(RouteContainer::Table::SelectedRouteIndex);
				}
				RUtils::AddTooltipText("Export to \\$i'" + Setting_UploadEditorRouteURL + "'");
			}
			else if (!CurrentMapInfo.bIsValid)
			{
				UI::Text("Invalid Map");
			}
			else if (!bHasSelectedRoute)
			{
				UI::Text("Select a Route to export");
			}

			UI::PopStyleVar(sv);
		}

		void DrawMapFolderNode(FRouteMapInfo &inout mapRouteInfo) 
		{
			UI::TableNextRow();
			UI::TableNextColumn();

			if (mapRouteInfo.bIsCurrentMap)
			{
				if (UI::TreeNode(Text::OpenplanetFormatCodes(mapRouteInfo.MapNameForUI) + "##" + mapRouteInfo.UID, UI::TreeNodeFlags::Framed | UI::TreeNodeFlags::Leaf | UI::TreeNodeFlags::DefaultOpen | UI::TreeNodeFlags::SpanAllColumns))
				{
					UI::TableNextColumn();
					UI::Text("Current Map");
					DrawExportRouteRow(mapRouteInfo);
					for (int32 row = 0; uint32(row) < mapRouteInfo.Routes.Length; row++) 
					{
						DrawRouteInfoNode(mapRouteInfo, mapRouteInfo.Routes[row], row);
					}
					UI::TreePop();
				}
			}
			else
			{
				if (UI::TreeNode(Text::OpenplanetFormatCodes(mapRouteInfo.MapNameForUI) + "##" + mapRouteInfo.UID, UI::TreeNodeFlags::Framed | UI::TreeNodeFlags::SpanAllColumns))
				{
					for (int32 row = 0; uint32(row) < mapRouteInfo.Routes.Length; row++) 
					{
						DrawRouteInfoNode(mapRouteInfo, mapRouteInfo.Routes[row], row);
					}
					UI::TreePop();
				}
			}
		}

		void DrawFolderNode(const string &in folderName, dictionary@ subFolders, const string &in folderDisplayName, const string &in currentPath, const bool bIsRoot = false) 
		{
			UI::TableNextRow();
			UI::TableNextColumn();

			string folderPath = currentPath.Length == 0 ? folderName : currentPath + "/" + folderName;

			bool bIsOpen;
			if (bIsRoot)
			{
				bIsOpen = UI::TreeNode(Icons::Sitemap + " " + folderDisplayName + "##" + folderPath, UI::TreeNodeFlags::DefaultOpen | UI::TreeNodeFlags::Leaf | UI::TreeNodeFlags::Bullet);
			}
			else
			{
				int32 additionalTreeNodeFlags = UI::TreeNodeFlags::None;
				if (CurrentMapInfo.RelativeFolder.StartsWith(EditorRoutePath::Normalize(folderPath)))
				{
					additionalTreeNodeFlags = UI::TreeNodeFlags::DefaultOpen;
				}

				bIsOpen = UI::TreeNode(Icons::FolderO + " " + folderDisplayName + "##" + folderPath, UI::TreeNodeFlags::Framed | UI::TreeNodeFlags::SpanFullWidth | UI::TreeNodeFlags::SpanAllColumns | additionalTreeNodeFlags);
			}
			
			if (bIsOpen) 
			{
				UI::TableNextColumn();
				UI::TableNextColumn();

				if (bIsRoot)
				{
					if (UI::Button(Icons::Refresh))
					{
						bIsRoutesFileListDirty = true;
					}
					RUtils::AddTooltipText("Refresh Files");
					UI::SameLine();

					// Open Folder
					if (UI::Button(Icons::FolderO + "##RootSavedRoutes")) 
					{
						OpenExplorerPath(RoutesPath);
					}
					RUtils::AddTooltipText("Open Folder");
					UI::SameLine();
#if ER_DEBUG
					UI::SameLine();
					if (UI::Button(Icons::Print))
					{
						LogFolderTree();
						LogMapUIDToRoutes();
					}
#endif
				}
				if (subFolders !is null) 
				{
					array<string> subFolderKeys = subFolders.GetKeys();
					for (uint32 i = 0; i < subFolderKeys.Length; i++) 
					{
						auto subFolderKey = subFolderKeys[i];
						dictionary@ subSubFolders;
						subFolders.Get(subFolderKey, @subSubFolders);

						FRouteMapInfo@ mapRouteInfo;
						if (MapUIDToRoutesDict.Get(subFolderKey, @mapRouteInfo))
						{
							DrawMapFolderNode(mapRouteInfo);
						}
						else
						{
							DrawFolderNode(subFolderKey, subSubFolders, subFolderKey, folderPath);
						}
					}
				}
				UI::TreePop();
			}
		}
		
		// ---------------------------------------------------------------
		// Draw
		// ---------------------------------------------------------------
		void Draw()
		{
			if(UI::BeginTabItem("Saved Routes", UI::TabItemFlags::NoReorder))
			{
				Init();
				// ---------------------------------------------------------------
				if (UI::BeginTable("SavedRoutesTree", 3, UI::TableFlags::RowBg | UI::TableFlags::SizingStretchProp | UI::TableFlags::Resizable | UI::TableFlags::BordersInnerV | UI::TableFlags::ScrollY)) 
				{
					UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch, 0.5f);
					UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthStretch, 0.3f);
					UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthStretch, 0.2f);

					// Start drawing from the root folder
					dictionary@ rootFolders;
					FolderTreeToMapUIDDict.Get("root", @rootFolders);
					DrawFolderNode("", rootFolders, "Saved Routes", "", true);

					UI::EndTable();
				}

				UI::EndTabItem();
			}
		}

		// ---------------------------------------------------------------
		// Debug
		// ---------------------------------------------------------------
		void PrintFolderTree(dictionary@ folderTree, int32 depth = 0)
		{
			array<string> keys = folderTree.GetKeys();
			for (uint32 i = 0; i < keys.Length; i++)
			{
				string key = keys[i];
				dictionary@ subFolder;
				folderTree.Get(key, @subFolder);

				// Construct indentation for structured output
				string indent = "";
				for (int32 j = 0; j < depth * 2; j++)
				{
					indent += " ";
				}

				// Print the key
				RUtils::DebugPrint(indent + key);

				// Recursively print the sub-folder
				PrintFolderTree(subFolder, depth + 1);
			}
		}
		void LogFolderTree()
		{
			RUtils::DebugPrint("Folder Tree Structure:");
			PrintFolderTree(FolderTreeToMapUIDDict);
		}
		void PrintMapUIDToRoutes(dictionary@ mapUIDToRoutes, int32 depth = 0)
		{
			array<string> keys = mapUIDToRoutes.GetKeys();
			for (uint32 i = 0; i < keys.Length; i++)
			{
				string key = keys[i];
				FRouteMapInfo@ mapRouteInfo;
				mapUIDToRoutes.Get(key, @mapRouteInfo);

				// Construct indentation for structured output
				string indent = "";
				for (int32 j = 0; j < depth * 2; j++)
				{
					indent += " ";
				}

				// Print the key and map name
				RUtils::DebugPrint(indent + "UID: " + key);
				RUtils::DebugPrint(indent + "  Map Name: " + mapRouteInfo.MapName);

				// Print the routes
				for (uint32 j = 0; j < mapRouteInfo.Routes.Length; j++)
				{
					FSavedRouteInfo@ route = mapRouteInfo.Routes[j];
					RUtils::DebugPrint(indent + "    Route: " + route.FileName);
				}
			}
		}

		void LogMapUIDToRoutes()
		{
			RUtils::DebugPrint("Map UID to Routes Structure:");
			PrintMapUIDToRoutes(MapUIDToRoutesDict, 0);
		}
	}
}