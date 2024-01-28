// namespace State
// {
// 	bool MenuButtonDown = false;
// }

// void OnKeyPress(bool down, VirtualKey key)
// {
// 	if (key == VirtualKey::Menu) {
// 		State::MenuButtonDown = down;
// 	}
// }

// void OnMouseButton(bool down, int32 button, int32 x, int32 y)
// {
// 	if (button == 0 && down && State::MenuButtonDown) {
// 		Setting_Follow = false;
// 	}
// }

void Main()
{
	Fonts::Load();
	Events::CreateCDOs();

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
				trace("Ready to record Routes but RouteContainer not setup!");
			}
		}
		if (GameState::IsReadyToRenderRoute())
		{
			// RouteSpectrum::ProcessRequest();
		}
	}
}

void Update(float dt)
{
	if (GameState::IsReadyToRenderRoute())
	{
		RouteTime::UpdateTime(dt);
	}
}

void Render()
{
	if (GameState::IsReadyToRenderRoute())
	{
		EditorRouteUI::Show();
		RouteSpectrum::ProcessRequest();
		RouteRenderer::Render();
	}
	
	// RouteRenderer::DebugTests();
}

void RenderEarly()
{
	CameraExt::Tick();
}
