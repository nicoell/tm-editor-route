namespace EditorRouteUI
{
	bool bIsTimeLineSliderActive = false;
	bool bIsTimeLineSliderHovered = false;
	// ---------------------------------------------------------------
	// Time Control
	// ---------------------------------------------------------------
	void ShowTimeControl()
	{
		// ---------------------------------------------------------------
		// Read Time State to UI State
		bIsPaused = RouteTime::bIsPaused;
		bIsLooped = RouteTime::bIsLooped;
		TimePercentage = RouteTime::GetTimePercentage();
		TimeControlLimits = RouteTime::TimeRange;
		
		// ---------------------------------------------------------------
		// Create ChildWindow for all TimeControls
		const vec4 bgColor = UI::IsWindowFocused(UI::FocusedFlags::RootAndChildWindows) ? vec4(5., 125., 74., 128)/255. : vec4(5., 125., 74., 16)/255.;
		UI::PushStyleColor(UI::Col::ChildBg, bgColor);
		UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(6., 6.));

		const int32 windowFlags = UI::WindowFlags::NoResize | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse | UI::WindowFlags::AlwaysUseWindowPadding;
		if (UI::BeginChild("TimeControlChild", UI::GetContentRegionAvail(), false, windowFlags))
		{
			
			// ---------------------------------------------------------------
			// Setup Style and calculate child regions
			UI::PushStyleColor(UI::Col::ChildBg, vec4(0.));
			UI::PushStyleColor(UI::Col::Button, vec4(0.));
			UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0., 0.));

			const float paddingBetween = 2;
			vec2 controlsChildSize;
			vec2 contentRegion = UI::GetContentRegionAvail();// - UI::GetStyleVarVec2(UI::StyleVar::WindowPadding);
			contentRegion.x -= paddingBetween;
			{
				const float minControlsWidth = 120.;
				const float maxControlsWidth = 180.;

				controlsChildSize.x = Math::Round(Math::Clamp(0.2 * contentRegion.x, minControlsWidth, maxControlsWidth));
				controlsChildSize.y = contentRegion.y;
			}
			vec2 searchChildSize;
			{
				searchChildSize.x = contentRegion.x - controlsChildSize.x;
				searchChildSize.y = contentRegion.y;
			}	

			if (UI::BeginChild("ControlsChild", controlsChildSize, false, windowFlags))
			{            
				// ---------------------------------------------------------------
				// Player Controls
				vec2 buttonSize = UI::GetContentRegionAvail();
				buttonSize.x /= 4;

				const bool isDisabled = !bAreRoutesAvailable;
				UI::BeginDisabled(isDisabled);
				if (UI::Button(Icons::Kenney::StepBackward + "##ControlBack", buttonSize))
				{
					TimePercentage = 0.;
				}
				UI::SameLine();
				if (UI::Button(bIsPaused ? (Icons::Kenney::CaretRight + "###ControlPlay") : (Icons::Kenney::Pause + "###ControlPlay"), buttonSize))
				{
					bIsPaused = !bIsPaused;
				}
				UI::SameLine();
				if (UI::Button(Icons::Kenney::StepForward + "##ControlForward", buttonSize))
				{
					TimePercentage = 1.;
				}
				UI::SameLine();
				if (UI::Button(Icons::EllipsisV + "##ControlMore", buttonSize))
				{
					UI::OpenPopup("ControlMenuPopup");
				}
				UI::SameLine();
				UI::EndDisabled();
				
				// ---------------------------------------------------------------
				// ControlMenuPopup
				{
					vec2 popupPosOffset = vec2(-buttonSize.x / 2, buttonSize.y);
					ShowControlMenuPopup(popupPosOffset);
				}
			}
			UI::EndChild();
			
			// ---------------------------------------------------------------
			// Padding
			UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(paddingBetween, 0.));
			UI::SameLine();
			UI::PopStyleVar();

			if (UI::BeginChild("SearchChild", searchChildSize, false, windowFlags))
			{
				// ---------------------------------------------------------------
				// Search Bar
				
				const bool isDisabled = !bAreRoutesAvailable;
				UI::BeginDisabled(isDisabled);
				{
					float windowRegionWidth = UI::GetWindowContentRegionWidth();
					float timeSliderWidth = windowRegionWidth;

					UI::SetNextItemWidth(timeSliderWidth);

					double curTime = (RouteTime::MinTime + TimePercentage * RouteTime::Duration) / 1000.;
					float minTime = (RouteTime::MinTime + TimeControlLimits.x * RouteTime::Duration) / 1000.;
					float maxTime = (RouteTime::MinTime + TimeControlLimits.y * RouteTime::Duration) / 1000.;

					UI::PushFont(Fonts::UI(Fonts::Type::DroidSansBold));
					UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0));
					UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(0, 1));

					const vec2 magicPosOffset = vec2(2, 2); // Not sure which style this comes from
					vec2 drawPosition = UI::GetWindowPos() + UI::GetCursorPos()  + magicPosOffset;
					const vec2 magicSizeOffset = vec2(-2, -4); // Not sure which style this comes from. Maybe font size?
					vec2 drawRegion = vec2(UI::GetWindowContentRegionWidth() - magicPosOffset.x, UI::GetFrameHeight()) + magicSizeOffset;

					DrawTimeLine(drawPosition, drawRegion);
					
					UI::PushStyleColor(UI::Col::FrameBg, vec4(0.));
					UI::PushStyleColor(UI::Col::FrameBgActive, vec4(0.));
					UI::PushStyleColor(UI::Col::FrameBgHovered, vec4(0.));
					UI::PushStyleColor(UI::Col::Text, vec4(0, 0, 0, 1));
				
					curTime = UI::SliderFloat("##TimeSlider", curTime, minTime, maxTime, "%.3f s");
					TimePercentage = RouteTime::GetTimePercentage(curTime * 1000.);

					bIsTimeLineSliderActive = UI::IsItemActive();
					bIsTimeLineSliderHovered = UI::IsItemHovered();

					// TimePercentage = UI::SliderFloat("##TimeSlider", TimePercentage, TimeControlLimits.x, TimeControlLimits.y); 
					TimePercentage = Math::Clamp(TimePercentage, TimeControlLimits.x, TimeControlLimits.y);

					UI::PopStyleColor(4);
					UI::PopStyleVar(2);
					UI::PopFont();
				}
				UI::EndDisabled();
			}
			UI::EndChild();
			UI::PopStyleVar();
			UI::PopStyleColor(2);
			
		}
		UI::EndChild();

		UI::PopStyleVar(1);
		UI::PopStyleColor(1);

		// ---------------------------------------------------------------
		// Apply UI State to Time
		RouteTime::bIsPaused = bIsPaused;
		RouteTime::bIsLooped = bIsLooped;

		const bool isDirty = !RUtils::IsNearlyEqual(TimePercentage, RouteTime::GetTimePercentage()) || !RUtils::IsNearlyEqual(TimeControlLimits, RouteTime::TimeRange);
		if (isDirty)
		{
			RouteTime::SetTimeRange(TimeControlLimits, false);
			RouteTime::SetTimePercentage(TimePercentage, true);
		}
	}

	void DrawTimeLine(const vec2& in drawPosition, const vec2 drawRegion)
	{
		auto drawlist = UI::GetWindowDrawList();
		
		//vec2 drawRegion = vec2(width, height);
		vec4 fullSpectrumRect = vec4(drawPosition, drawRegion);

		auto route = RouteContainer::GetSelectedRoute();
		auto spectrumTexture = RouteSpectrum::RouteSpectrumTextures[RouteSpectrum::PingPong::Read()];
		if (route is null || spectrumTexture is null || route.GetNumSamples() == 0 || route.GetDuration() == 0 || RouteTime::Duration == 0)
		{
			drawlist.AddRect(fullSpectrumRect, vec4(0,0,0,0.5));
		}
		else
		{
			// ---------------------------------------------------------------
			// Scale Rect to fit to time of current route vs max time overall
			vec2 offset = vec2(0, 0.);
			vec2 scale = vec2(1, 1.);
			{
				const double routeMinTime = RUtils::InMS(route.GetMinTime());
				const double routeDuration = RUtils::InMS(route.GetDuration());
				scale.x = routeDuration / RouteTime::Duration;
				offset.x = (routeMinTime - RouteTime::MinTime)  / RouteTime::Duration;
			}

			vec4 spectrumRect = vec4(drawPosition + offset * drawRegion, scale * drawRegion);

			drawlist.AddImage(spectrumTexture, spectrumRect.xy, spectrumRect.zw);

			vec4 borderColor = bIsTimeLineSliderHovered || bIsTimeLineSliderActive ?  UI::GetStyleColor(UI::Col::SliderGrabActive) : UI::GetStyleColor(UI::Col::SliderGrab);
			drawlist.AddRect(fullSpectrumRect, borderColor);


			const double duration = RUtils::InMS(route.GetDuration());
			float t = duration != 0 ? RUtils::InMS(route.CurrentSample.Time - route.GetMinTime()) / RUtils::InMS(route.GetDuration()) : 0.0;

			t = Math::Clamp(t, 0., 1.);
		}
	}

	void ShowControlMenuPopup(const vec2 &in offset)
	{
		// ---------------------------------------------------------------
		// Comment
		// ---------------------------------------------------------------
		UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(4., 4.));
		UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0., 2.));
		UI::PushStyleColor(UI::Col::Separator, vec4(128., 128., 128., 96.)/255.);
		vec2 popupPos = UI::GetWindowPos() + UI::GetCursorPos() + offset;
		UI::SetNextWindowPos(int(popupPos.x), int(popupPos.y));
		if (UI::BeginPopup("ControlMenuPopup", UI::WindowFlags::NoMove ))
		{
			if (UI::MenuItem(Icons::Repeat + " Loop", "", bIsLooped))
			{
				bIsLooped = !bIsLooped;
			}
			// ---------------------------------------------------------------
			// Extra spacing before destructive items
			UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0., 4.));
			UI::Separator();
			UI::Separator();
			UI::PopStyleVar(1);
			if (UI::MenuItem("\\$d32" + Icons::Trash + " Clear Routes"))
			{
				GameState::CleanupRuntime();
			}
			UI::EndPopup();
		}
		UI::PopStyleColor();
		UI::PopStyleVar(2);
	}
}