void Main()
{
	Fonts::Load();
	Events::CreateCDOs();

#if ER_DEBUG
	RouteRecorder::AddDebugData(7);
	GameState::InitRuntime();
#endif

	while (true) 
	{
		yield();

		GameState::Tick();
		if (GameState::IsReadyToRecordRoute())
		{
			if (RouteContainer::HasRoutes())
			{
				RouteRecorder::Record();
			}
			else
			{
				RUtils::DebugTrace("Ready to record Routes but RouteContainer not setup!");
			}
		}
		if (GameState::IsReadyToRenderRoute())
		{
			// Nothing atm
		}
	}
}

void Update(float dt)
{
	if (GameState::IsReadyToRenderRoute())
	{
		RouteTime::UpdateTime(dt);
	}
	// Start recording frame times as soon as player exists to have frame times ready when recording starts
	// This is only ever true in Editor
	if (GameState::State::bDoesPlayerExist)
	{
		RouteRecorder::RecordFrameTimes(dt);
	}
}

void Render()
{
	if (GameState::IsReadyToRenderRoute())
	{
		EditorRouteUI::Show();
		RouteSpectrum::ProcessRequests();

		if (EditorRouteUI::bIsWindowOpen)
		{
			RouteRenderer::Render();
		}
	}
}

void RenderMenu()
{
	EditorRouteUI::RenderMenu();
}

void RenderEarly()
{
	CameraExt::Tick();
}
