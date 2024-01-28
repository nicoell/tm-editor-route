// TODO: These could actually be done with a proper callback system using fundefs
namespace GameState
{
	void OnEditorEnter()
	{
		trace("OnEditorEnter");
	}
	void OnEditorLeave()
	{
		trace("OnEditorLeave");
		CleanupAll();
	}
	void OnPlayInEditorEnter()
	{
		trace("OnPlayInEditorEnter");
		CleanupRuntime();
	}
	void OnPlayInEditorLeave()
	{
		trace("OnPlayInEditorLeave");
		InitRuntime();
	}

	void OnStartRun()
	{
		trace("OnStartRun");
		RouteContainer::AdvanceRoute();
	}

	void OnRetireRun()
	{
		trace("OnRetireRun");
		GameState::ResetRespawnCounter();
	}

	void OnFinishRun()
	{
		trace("OnFinishRun");
	}

	void OnRespawnRun()
	{
		trace("OnRespawnRun");
		RouteRecorder::State::bRequestDiscontinuousEntry = true;
	}

	// ---------------------------------------------------------------
	// Bundled Helpers
	// ---------------------------------------------------------------

	void InitRuntime()
	{
		RouteContainer::CacheStats();
		RouteTime::Init();
		RouteRenderer::bDebug = true;
		trace("InitRuntime");
		EditorRouteUI::SelectRoute(0, RouteSpectrum::ESpectrumType::Default);
		EditorRouteUI::TabGeneral::Ctx::bForceReselect = true;
		
	}

	void CleanupRuntime()
	{
		RouteContainer::Reset();
		RouteTime::Reset();
		RouteSpectrum::ResetRuntime();
	}

	void CleanupAll()
	{
		RouteContainer::Reset();
		RouteTime::Reset();
		RouteSpectrum::ResetAll();
	}
}