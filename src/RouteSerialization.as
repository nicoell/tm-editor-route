namespace RouteSerialization
{
	bool bIsSaving = false;
	bool bIsLoading = false;

	void ExportRouteToFile(int32 routeIndex, string &in filePath)
	{
		if (bIsSaving) { return; }
		bIsSaving = true;

		RouteSerialization::Private::FExportContext ctx;
		ctx.ExportTarget = Private::EExportTarget::File;
		ctx.RouteIndex = routeIndex;
		ctx.Path = filePath;
		startnew(RouteSerialization::Private::BeginSerializeRoute, ctx);		
	}

	void UploadRoute(int32 routeIndex)
	{
		if (bIsSaving) { return; }
		bIsSaving = true;

		RouteSerialization::Private::FExportContext ctx;
		ctx.ExportTarget = Private::EExportTarget::HttpPost;
		ctx.RouteIndex = routeIndex;
		ctx.Path = Setting_UploadEditorRouteURL;
		startnew(RouteSerialization::Private::BeginSerializeRoute, ctx);
	}

	void LoadRoute(string &in filePath)
	{
		if (bIsLoading) { return; }

		bIsLoading = true;

		RouteSerialization::Private::FLoadContext ctx;
		ctx.FilePath = filePath;
		startnew(RouteSerialization::Private::BeginLoadRoute, ctx);		
	}

	// ---------------------------------------------------------------
	
	namespace Private
	{
		enum EExportTarget
		{
			File,
			HttpPost
		}
		class FExportContext
		{
			uint32 RouteIndex;
			EExportTarget ExportTarget;
			string Path;
		}

		void BeginSerializeRoute(ref@ _ctx)
		{
			auto ctx = cast<FExportContext@>(_ctx);
			auto route = RouteContainer::GetRoute(ctx.RouteIndex);
			if (route is null)
			{
				RUtils::DebugWarn("BeginSerializeRoute received invalid route.");
				return;
			}

			FArchive@ routeArchive = route.SaveArchive();

			AsyncJson::FTaskContext taskCtx (routeArchive.Data, ctx.ExportTarget == EExportTarget::File ? ExportRouteFile : ExportRouteHTTPPost, ctx);

			AsyncJson::WriteTask(taskCtx);
			
			bIsSaving = false;
		}

		void ExportRouteFile(AsyncJson::FTaskResult@ result)
		{
			if (result is null)
			{
				error("ExportRouteFile received null result.");
				return;
			}

			auto ctx = cast<FExportContext@>(result.UserData);
			if (ctx is null)
			{
				error("ExportRouteFile received null FExportContext.");
				return;
			}

			try
			{
				string folderPath = EditorRoutePath::DirName(ctx.Path);
				// Create the folder if it does not exist
				if (!IO::FolderExists(folderPath))
				{
					IO::CreateFolder(folderPath, true);
				}
			}
			catch
			{
				error("Error setting up folder for export:\n"  + getExceptionInfo());
			}

			try
			{
				// Write the string to the file (overwrite if it exists)
				IO::File file(ctx.Path, IO::FileMode::Write);
				file.Write(result.JsonString);
				file.Close();
			}
			catch
			{
				error("Error exporting Route to file:\n"  + getExceptionInfo());
			}

			EditorRouteUI::TabIO::bIsRoutesFileListDirty = true;
		}

		void ExportRouteHTTPPost(AsyncJson::FTaskResult@ result)
		{
			if (result is null)
			{
				error("ExportRouteHTTPPost received null result.");
				return;
			}

			auto ctx = cast<FExportContext@>(result.UserData);
			if (ctx is null)
			{
				error("ExportRouteHTTPPost received null FExportContext.");
				return;
			}

			try
			{
				auto request = Net::HttpPost(Setting_UploadEditorRouteURL, result.JsonString, "application/json");
				while(!request.Finished()) { yield(); }

				auto status = request.ResponseCode();
				if (status < 200 || status >= 300)
				{
					throw("HTTP Response Status Code: " + status);
				}
				else
				{
					print("HTTP Post Success: " + status);
				}
			}
			catch
			{
				error("Error uploading EditorRoute to '" + Setting_UploadEditorRouteURL + "'\n" + getExceptionInfo());
			}
		}

		// ---------------------------------------------------------------
		// Loading
		// ---------------------------------------------------------------
		class FLoadContext
		{
			string FilePath;
		}

		void BeginLoadRoute(ref@ _ctx)
		{
			auto ctx = cast<FLoadContext@>(_ctx);
			Json::Value json;
			try
			{
				json = Json::FromFile(ctx.FilePath);
			}
			catch
			{
				error("Error loading Route File:\n" + getExceptionInfo());
			}

			try
			{
				if (GameState::IsReadyToRenderRoute())
				{
					Route::FRoute route(FArchive(json));
					RouteContainer::AddRoute(route);
				} else 
				{
					throw("Can only load Route while in Editor and not driving.");
				}
			}
			catch
			{
				error("Error importing route:\n" + getExceptionInfo());
			}

			GameState::InitRuntime();

			bIsLoading = false;
		}

	}
}
