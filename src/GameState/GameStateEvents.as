// TODO: These could actually be done with a proper callback system using fundefs

namespace GameState
{
	void OnEditorEnter()
	{
		RUtils::DebugTrace("OnEditorEnter");
	}
	void OnEditorLeave()
	{
		RUtils::DebugTrace("OnEditorLeave");
		CleanupAll();
	}
	void OnPlayInEditorEnter()
	{
		RUtils::DebugTrace("OnPlayInEditorEnter");
		
		if (Setting_Recorder_ClearTrailsOnPlay)
		{
			CleanupRuntime();
		}
		else
		{
			CleanupRuntimeKeepRoutes();
		}
	}
	void OnPlayInEditorLeave()
	{
		RUtils::DebugTrace("OnPlayInEditorLeave");
		InitRuntime();
	}

	void OnStartRun()
	{
		RUtils::DebugTrace("OnStartRun");
		RouteContainer::AdvanceRoute();
	}

	void OnRetireRun()
	{
		RUtils::DebugTrace("OnRetireRun");
		GameState::ResetRespawnCounter();
	}

	void OnFinishRun()
	{
		RUtils::DebugTrace("OnFinishRun");
	}

	void OnRespawnRun()
	{
		RUtils::DebugTrace("OnRespawnRun");
		RouteRecorder::State::bRequestDiscontinuousEntry = true;
	}

	// ---------------------------------------------------------------
	// Bundled Helpers
	// ---------------------------------------------------------------

	void InitRuntime()
	{
		RouteContainer::FinalizeRoutes();
		RouteContainer::CacheStats();
		RouteTime::Init();
		RouteRenderer::bDebug = true;
		RUtils::DebugTrace("InitRuntime");
		EditorRouteUI::SelectRoute(0, RouteSpectrum::ESpectrumType::Default);
		EditorRouteUI::TabGeneral::Ctx::bForceReselect = true;
		
	}

	void CleanupRuntime()
	{
		RouteContainer::Reset();
		RouteTime::Reset();
		RouteSpectrum::ResetRuntime();
		RouteRenderer::Reset();
	}

	void CleanupRuntimeKeepRoutes()
	{
		RouteContainer::Table::Reset();
		RouteTime::Reset();
		RouteSpectrum::ResetRuntime();
		RouteRenderer::Reset();
	}

	void CleanupAll()
	{
		RouteContainer::Reset();
		RouteTime::Reset();
		RouteSpectrum::ResetAll();
		RouteRenderer::Reset();
	}
}