namespace EditorRouteUI
{
	const uint32 RouteTableRouteIDUserID = 0;
	const uint32 RouteTableLengthUserID = 1;

    [Setting hidden]
	bool bIsWindowOpen = true;
	bool bAreRoutesAvailable = false;

	const vec2 WindowSize = vec2(640, 280);
	vec2 MinWindowSize = vec2(480, 280); // y will be dynamically calculated
	float TimeControlChildHeight;
	vec2 ContentWindowSize;
	vec2 DefaultWindowPadding;
	vec2 DefaultItemSpacing;
	float TitleBarSize = 0;

	float TimePercentage = 0.;
	vec2 TimeControlLimits(0., 1.);
	bool bIsPaused = false;
	bool bIsLooped = false;

	RouteSpectrum::ESpectrumType CurrentSpectrumType;
	int32 RouteIdxToDelete = -1;

	void SelectRoute(const uint32 routeIndex, const RouteSpectrum::ESpectrumType spectrum)
	{
		RouteContainer::Table::SetSelectedRoute(routeIndex);
		RouteSpectrum::RequestRouteSpectrum(routeIndex, spectrum);
	}

	void RenderMenu()
	{
		if (UI::MenuItem(Strings::MenuTitle, "", bIsWindowOpen))
		{
			bIsWindowOpen = !bIsWindowOpen;
		}
	}

	void Show()
	{
		if (!bIsWindowOpen) { return; }

		// ---------------------------------------------------------------
		// Refresh States, apply Style and calc sizes
		bAreRoutesAvailable = RouteContainer::HasRoutes();

		TimeControlChildHeight = UI::GetFrameHeightWithSpacing();
		const int2 numStyleVarColors = PushStyle();

		TitleBarSize = UI::GetTextLineHeight() + 2 * UI::GetStyleVarVec2(UI::StyleVar::FramePadding).y;
		MinWindowSize.y = TimeControlChildHeight + TitleBarSize + 2 * UI::GetStyleVarVec2(UI::StyleVar::WindowPadding).y;

		// ---------------------------------------------------------------
		// Window
		if (UI::Begin(Strings::WindowTitle, bIsWindowOpen, UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse))
		{
			CurrentSpectrumType = RouteSpectrum::CurrentSpectrum;
			ContentWindowSize = UI::GetContentRegionAvail();
			const float emptySpace = ContentWindowSize.y - TimeControlChildHeight;
			ContentWindowSize.y -= TimeControlChildHeight + UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).y;
			RouteIdxToDelete = -1;

			if (ContentWindowSize.y <= 1 ) { ContentWindowSize.y = 0; }

			const bool bCollapseContentChildWindow = ContentWindowSize.y <= 0; 
			const bool bShowContentChildWindowContent = ContentWindowSize.y >= 2*(UI::GetTextLineHeightWithSpacing()); 

			// ---------------------------------------------------------------
			// If there's enough space, draw the ContentChildWindow with the Route Table
			if (!bCollapseContentChildWindow)
			{
				int32 sv = 0;
				sv += PushStyleVarForced(UI::StyleVar::WindowPadding, DefaultWindowPadding);
				int32 windowFlags = UI::WindowFlags::NoDocking | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse;
				if (UI::BeginChild("Content", ContentWindowSize, UI::ChildFlags::AlwaysUseWindowPadding, windowFlags))
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
				PopStyleVar(sv);
			}
			else if (emptySpace > 0)
			{
				// Ensure TimeControl sticks to bottom of Window
				int32 sv = 0;
				sv += PushStyleVarForced(UI::StyleVar::ItemSpacing, vec2(0., 0.));
				UI::Dummy(vec2(0, emptySpace));
				PopStyleVar(sv);
			}

			// ---------------------------------------------------------------
			// In any case, draw the Time Controls even if no Routes are available
			ShowTimeControl();

			RouteContainer::DeleteRoute(RouteIdxToDelete);
			SelectRoute(RouteContainer::Table::SelectedRouteIndex, CurrentSpectrumType);
		}
		UI::End();

		PopStyleColor(numStyleVarColors.y);
		PopStyleVar(numStyleVarColors.x);
	}


	int2 PushStyle()
	{
		UI::SetNextWindowSize(int32(WindowSize.x), int32(WindowSize.y), UI::Cond::FirstUseEver);

		int32 sv = 0; int32 sc = 0;

		sv += PushStyleVarForced(UI::StyleVar::WindowMinSize, vec2(MinWindowSize.x, MinWindowSize.y));

		sv += PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(0, 0.5));
		sv += PushStyleVar(UI::StyleVar::WindowBorderSize, 0);
		sv += PushStyleVar(UI::StyleVar::ChildBorderSize, 0);
		sv += PushStyleVar(UI::StyleVar::PopupBorderSize, 0);
		sv += PushStyleVar(UI::StyleVar::FrameBorderSize, 0);

		DefaultWindowPadding = UI::GetStyleVarVec2(UI::StyleVar::WindowPadding);
		sv += PushStyleVarForced(UI::StyleVar::WindowPadding, vec2(0., 0.));
		sv += PushStyleVar(UI::StyleVar::FramePadding, vec2(8., 2.));
		DefaultItemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing);
		sv += PushStyleVar(UI::StyleVar::ItemSpacing, vec2(1., 1.));
		sv += PushStyleVar(UI::StyleVar::ItemInnerSpacing, vec2(4., 2.));
		sv += PushStyleVar(UI::StyleVar::CellPadding, vec2(1, 1));

		sv += PushStyleVar(UI::StyleVar::IndentSpacing, 4.);
		sv += PushStyleVar(UI::StyleVar::ScrollbarSize, 16.);
		sv += PushStyleVar(UI::StyleVar::GrabMinSize, 8.);
		sv += PushStyleVar(UI::StyleVar::WindowRounding, 0);

		sv += PushStyleVar(UI::StyleVar::ChildRounding, 0);
		sv += PushStyleVar(UI::StyleVar::FrameRounding, 0);
		sv += PushStyleVar(UI::StyleVar::PopupRounding, 4.);
		sv += PushStyleVar(UI::StyleVar::ScrollbarRounding, 4);

		sv += PushStyleVar(UI::StyleVar::GrabRounding, 4.);
		sv += PushStyleVar(UI::StyleVar::TabRounding, 4);
		sv += PushStyleVar(UI::StyleVar(1), 0.25); // DisableAlpha is missing from StyleVar enum as the time of writing

		sc += PushStyleColor(UI::Col::TitleBgActive, vec4(5., 125., 74., 228)/255.);
		sc += PushStyleColor(UI::Col::ResizeGrip, vec4(89., 239., 134., 32.)/255.);
		sc += PushStyleColor(UI::Col::ResizeGripHovered, vec4(89., 239., 134., 196.)/255.);
		sc += PushStyleColor(UI::Col::ResizeGripActive, vec4(233., 196., 1., 228.)/255.);
		sc += PushStyleColor(UI::Col::Separator, vec4(233., 196., 1., 32.)/255.);
		sc += PushStyleColor(UI::Col::SeparatorHovered, vec4(233., 196., 1., 128.)/255.);
		sc += PushStyleColor(UI::Col::SeparatorActive, vec4(233., 196., 1., 228.)/255.);
		sc += PushStyleColor(UI::Col::FrameBg, vec4(0., 0., 0, 255.)/255.);
		sc += PushStyleColor(UI::Col::FrameBgHovered, vec4(0., 0., 0, 196.)/255.);
		sc += PushStyleColor(UI::Col::FrameBgActive, vec4(0., 0., 0., 228.)/255.);
		sc += PushStyleColor(UI::Col::CheckMark, vec4(233., 196., 1., 228.)/255.);

		sc += PushStyleColorForced(UI::Col::SliderGrab, vec4(0., 0., 0., 196.)/255.);
		sc += PushStyleColorForced(UI::Col::SliderGrabActive, vec4(0., 0., 0., 228.)/255.);
		sc += PushStyleColor(UI::Col::ScrollbarGrab, vec4(233., 196., 1., 32.)/255.);
		sc += PushStyleColor(UI::Col::ScrollbarGrabHovered, vec4(233., 196., 1., 196.)/255.);
		sc += PushStyleColor(UI::Col::ScrollbarGrabActive, vec4(233., 196., 1., 228.)/255.);

		sc += PushStyleColor(UI::Col::Button, vec4(125., 125., 125., 64.)/255.);
		sc += PushStyleColor(UI::Col::ButtonHovered,  vec4(1., 123., 65., 128.)/255.);
		sc += PushStyleColor(UI::Col::ButtonActive,  vec4(233., 196., 1., 228.)/255.);

		sc += PushStyleColor(UI::Col::Header, vec4(1., 123., 65., 128.)/255.);
		sc += PushStyleColor(UI::Col::HeaderHovered, vec4(1., 123., 65., 128.)/255.);
		sc += PushStyleColor(UI::Col::HeaderActive, vec4(89., 239., 134., 128.)/255.);
		sc += PushStyleColor(UI::Col::TableHeaderBg, vec4(125., 125., 125., 1.)/255.);
		sc += PushStyleColor(UI::Col::TableBorderLight, vec4(1., 123., 65., 32.)/255.);
		sc += PushStyleColor(UI::Col::TableBorderStrong, vec4(1., 123., 65., 96.)/255.);
		sc += PushStyleColor(UI::Col::Tab, vec4(1., 123., 65., 96.)/255.);
		sc += PushStyleColor(UI::Col::TabActive, vec4(1., 123., 65., 196.)/255.);
		sc += PushStyleColor(UI::Col::TabUnfocused, vec4(1., 123., 65., 32.)/255.);
		sc += PushStyleColor(UI::Col::TabUnfocusedActive, vec4(1., 123., 65., 148.)/255.);
		sc += PushStyleColor(UI::Col::TabHovered, vec4(1., 123., 65., 224.)/255.);

		sc += PushStyleColor(UI::Col::PopupBg, vec4(0., 0., 0, 240.)/255.);

		sc += PushStyleColor(UI::Col::Text, vec4(224, 229, 217, 255.)/255.);

		return int2(sv, sc);
	}
}