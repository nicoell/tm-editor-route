namespace EditorRouteUI
{
	
	const uint32 RouteTableRouteIDUserID = 0;
	const uint32 RouteTableLengthUserID = 1;

	bool bIsWindowOpen = false;
	bool bAreRoutesAvailable = false;

	
	const int32 PlayerChildHeight = 32;
	const int2 WindowSize = int2(640, 280);
	const int2 MinWindowSize = int2(480, PlayerChildHeight);
	int2 CurrentWindowSize = WindowSize;
	float TitleBarSize = 0;

	float TimePercentage = 0.;
	vec2 TimeControlLimits(0., 1.);
	bool bIsPaused = false;
	bool bIsLooped = false;

	RouteSpectrum::ESpectrumType CurrentSpectrumType;

	void UpdateTime(float dt)
	{   
	}

	void SelectRoute(const uint32 routeIndex, const RouteSpectrum::ESpectrumType spectrum)
	{
		RouteContainer::Table::SetSelectedRoute(routeIndex);
		RouteSpectrum::RequestRouteSpectrum(routeIndex, spectrum);
	}

	void Show()
	{
		// ---------------------------------------------------------------
		// Refresh States, apply Style and calc sizes
		bAreRoutesAvailable = RouteContainer::HasRoutes();

		const int2 numStyleVarColors = PushStyle();

		TitleBarSize = UI::GetTextLineHeight() + 2 * UI::GetStyleVarVec2(UI::StyleVar::FramePadding).y;

		// ---------------------------------------------------------------
		// Window
		if (UI::Begin(Icons::MapO + " Editor Route", bIsWindowOpen, UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse))
		{
			CurrentSpectrumType = RouteSpectrum::CurrentSpectrum;
			CurrentWindowSize = int2(int(UI::GetWindowSize().x), int(UI::GetWindowSize().y));
			const vec2 contentWindowSize = vec2(UI::GetWindowContentRegionWidth(), CurrentWindowSize.y - PlayerChildHeight - TitleBarSize);

			const bool bCollapseContentChildWindow = contentWindowSize.y <= 1.0; 
			const bool bShowContentChildWindowContent = contentWindowSize.y >= 24.0; 

			// ---------------------------------------------------------------
			// If there's enough space, draw the ContentChildWindow with the Route Table
			if (!bCollapseContentChildWindow)
			{
				UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(6., 6.));
				int32 windowFlags = UI::WindowFlags::NoDocking | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse | UI::WindowFlags::AlwaysUseWindowPadding;
				if (UI::BeginChild("Content", contentWindowSize, false, windowFlags))
				{
					// ---------------------------------------------------------------
					// Only draw Content if there's enough space to at least hint there is a Table
					if (bShowContentChildWindowContent)
					{
						// ---------------------------------------------------------------
						// Show Route Table if we have Routes
						if (RouteContainer::HasRoutes())
						{
							ShowRouteTable();
						}
						else
						{
							// Show Info if no Routes are available yet
							UI::Text(Icons::Kenney::Info + "Enter Test Mode or Validate the Track to record routes.");
						}
					}
				}
				UI::EndChild();
				UI::PopStyleVar(1);
			}

			// ---------------------------------------------------------------
			// In any case, draw the Time Controls even if no Routes are available
			ShowTimeControl();

			SelectRoute(RouteContainer::Table::SelectedRouteIndex, CurrentSpectrumType);
		}
		UI::End();

		UI::PopStyleColor(numStyleVarColors.y);
		UI::PopStyleVar(numStyleVarColors.x);
	}

	

	

	

	int2 PushStyle()
	{
		int32 sv = 0; int32 sc = 0;
		UI::SetNextWindowSize(WindowSize.x, WindowSize.y, UI::Cond::FirstUseEver);
		UI::PushStyleVar(UI::StyleVar::WindowMinSize, vec2(MinWindowSize.x, MinWindowSize.y + TitleBarSize)); sv++;

		UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(0, 0.5)); sv++;
		UI::PushStyleVar(UI::StyleVar::WindowBorderSize, 0); sv++;
		UI::PushStyleVar(UI::StyleVar::ChildBorderSize, 0); sv++;
		UI::PushStyleVar(UI::StyleVar::PopupBorderSize, 0); sv++;
		UI::PushStyleVar(UI::StyleVar::FrameBorderSize, 0); sv++;

		UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0., 0.)); sv++;
		UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(8., 2.)); sv++;
		UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(1., 1.)); sv++;
		UI::PushStyleVar(UI::StyleVar::ItemInnerSpacing, vec2(12., 2.)); sv++;
		UI::PushStyleVar(UI::StyleVar::CellPadding, vec2(1, 1)); sv++;

		UI::PushStyleVar(UI::StyleVar::IndentSpacing, 4.); sv++;
		UI::PushStyleVar(UI::StyleVar::ScrollbarSize, 16.); sv++;
		UI::PushStyleVar(UI::StyleVar::GrabMinSize, 4.); sv++;
		UI::PushStyleVar(UI::StyleVar::WindowRounding, 0); sv++;

		UI::PushStyleVar(UI::StyleVar::ChildRounding, 0); sv++;
		UI::PushStyleVar(UI::StyleVar::FrameRounding, 0); sv++;
		UI::PushStyleVar(UI::StyleVar::PopupRounding, 0.); sv++;
		UI::PushStyleVar(UI::StyleVar::ScrollbarRounding, 0); sv++;

		UI::PushStyleVar(UI::StyleVar::GrabRounding, 0.); sv++;
		UI::PushStyleVar(UI::StyleVar::TabRounding, 0); sv++;
		UI::PushStyleVar(UI::StyleVar(1), 0.25); sv++; // DisableAlpha is missing from StyleVar enum as the time of writing

		UI::PushStyleColor(UI::Col::TitleBgActive, vec4(5., 125., 74., 228)/255.); sc++;
		UI::PushStyleColor(UI::Col::ResizeGrip, vec4(89., 239., 134., 32.)/255.); sc++;
		UI::PushStyleColor(UI::Col::ResizeGripHovered, vec4(89., 239., 134., 196.)/255.); sc++;
		UI::PushStyleColor(UI::Col::ResizeGripActive, vec4(233., 196., 1., 228.)/255.); sc++;
		UI::PushStyleColor(UI::Col::Separator, vec4(233., 196., 1., 32.)/255.); sc++;
		UI::PushStyleColor(UI::Col::SeparatorHovered, vec4(233., 196., 1., 128.)/255.); sc++;
		UI::PushStyleColor(UI::Col::SeparatorActive, vec4(233., 196., 1., 228.)/255.); sc++;
		UI::PushStyleColor(UI::Col::FrameBg, vec4(0., 0., 0, 255.)/255.); sc++;
		UI::PushStyleColor(UI::Col::FrameBgHovered, vec4(0., 0., 0, 196.)/255.); sc++;
		UI::PushStyleColor(UI::Col::FrameBgActive, vec4(0., 0., 0., 228.)/255.); sc++;
		UI::PushStyleColor(UI::Col::CheckMark, vec4(233., 196., 1., 228.)/255.); sc++;

		UI::PushStyleColor(UI::Col::SliderGrab, vec4(0., 0., 0., 196.)/255.); sc++;
		UI::PushStyleColor(UI::Col::SliderGrabActive, vec4(0., 0., 0., 228.)/255.); sc++;
		UI::PushStyleColor(UI::Col::ScrollbarGrab, vec4(233., 196., 1., 32.)/255.); sc++;
		UI::PushStyleColor(UI::Col::ScrollbarGrabHovered, vec4(233., 196., 1., 196.)/255.); sc++;
		UI::PushStyleColor(UI::Col::ScrollbarGrabActive, vec4(233., 196., 1., 228.)/255.); sc++;

		UI::PushStyleColor(UI::Col::Button, vec4(125., 125., 125., 64.)/255.); sc++;
		UI::PushStyleColor(UI::Col::ButtonHovered,  vec4(1., 123., 65., 128.)/255.); sc++;
		UI::PushStyleColor(UI::Col::ButtonActive,  vec4(233., 196., 1., 228.)/255.); sc++;

		UI::PushStyleColor(UI::Col::Header, vec4(1., 123., 65., 128.)/255.); sc++;
		UI::PushStyleColor(UI::Col::HeaderHovered, vec4(1., 123., 65., 128.)/255.); sc++;
		UI::PushStyleColor(UI::Col::HeaderActive, vec4(89., 239., 134., 128.)/255.); sc++;
		UI::PushStyleColor(UI::Col::TableHeaderBg, vec4(125., 125., 125., 1.)/255.); sc++;
		UI::PushStyleColor(UI::Col::TableBorderLight, vec4(1., 123., 65., 32.)/255.); sc++;
		UI::PushStyleColor(UI::Col::TableBorderStrong, vec4(1., 123., 65., 96.)/255.); sc++;
		UI::PushStyleColor(UI::Col::Tab, vec4(1., 123., 65., 96.)/255.); sc++;
		UI::PushStyleColor(UI::Col::TabActive, vec4(1., 123., 65., 96.)/255.); sc++;
		UI::PushStyleColor(UI::Col::TabUnfocused, vec4(1., 123., 65., 96.)/255.); sc++;
		UI::PushStyleColor(UI::Col::TabUnfocusedActive, vec4(1., 123., 65., 96.)/255.); sc++;
		UI::PushStyleColor(UI::Col::TabHovered, vec4(1., 123., 65., 96.)/255.); sc++;

		UI::PushStyleColor(UI::Col::PopupBg, vec4(0., 0., 0, 240.)/255.); sc++;

		UI::PushStyleColor(UI::Col::Text, vec4(224, 229, 217, 255.)/255.); sc++;

		return int2(sv, sc);
	}
}