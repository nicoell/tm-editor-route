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
		int32 sc = 0; int32 sv = 0;
		const vec4 bgColor = UI::IsWindowFocused(UI::FocusedFlags::RootAndChildWindows) ? UI::GetStyleColor(UI::Col::TitleBgActive) : UI::GetStyleColor(UI::Col::TitleBg);
		sc += PushStyleColorForced(UI::Col::ChildBg, bgColor);

		vec2 timeControlChildSize = vec2(UI::GetWindowContentRegionWidth(), TimeControlChildHeight);

		const int32 windowFlags = UI::WindowFlags::NoResize | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse | UI::WindowFlags::AlwaysUseWindowPadding;
		if (UI::BeginChild("TimeControlChild", timeControlChildSize, false, windowFlags))
		{
			// ---------------------------------------------------------------
			// Setup Style and calculate child regions
			int32 _sc = 0; int32 _sv = 0;

			_sc += PushStyleColorForced(UI::Col::ChildBg, vec4(0.));
			_sc += PushStyleColorForced(UI::Col::Button, vec4(0.));


			const float paddingBetween = 2;
			vec2 controlsChildSize;
			vec2 contentRegion = timeControlChildSize;
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
				// Reduce Spacing a bit
				int32 __sv = 0;
				__sv += PushStyleVarForced(UI::StyleVar::ItemSpacing, UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing) / 2.);
				
				const int32 numButtons = 4;
				vec2 buttonSize =  UI::GetContentRegionAvail();
				{
					buttonSize.x = buttonSize.x - UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x * (numButtons - 1);
					buttonSize.x = buttonSize.x / numButtons;
				}

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
				PopStyleVar(__sv);
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

					double curTimeInSeconds = (RouteTime::MinTime + TimePercentage * RouteTime::Duration) / 1000.;
					float minTimeInSeconds = (RouteTime::MinTime + TimeControlLimits.x * RouteTime::Duration) / 1000.;
					float maxTimeInSeconds = (RouteTime::MinTime + TimeControlLimits.y * RouteTime::Duration) / 1000.;

					
					int32 __sc = 0; int32 __sv = 0;

					float framePaddingY = (searchChildSize.y - UI::GetTextLineHeight()) / 2.;
					framePaddingY = Math::Max(0, framePaddingY);
					__sv += PushStyleVarForced(UI::StyleVar::FramePadding, vec2(0, framePaddingY));


					vec2 drawPosition = UI::GetWindowPos() + UI::GetCursorPos();
					drawPosition.x += 1; // Border things
					vec2 drawRegion = vec2(UI::GetWindowContentRegionWidth(), searchChildSize.y);
					drawRegion.x -= 1; // Border things

					DrawTimeLine(drawPosition, drawRegion);

					__sc += PushStyleColorForced(UI::Col::FrameBg, vec4(0.));
					__sc += PushStyleColorForced(UI::Col::FrameBgActive, vec4(0.));
					__sc += PushStyleColorForced(UI::Col::FrameBgHovered, vec4(0.));
					__sc += PushStyleColorForced(UI::Col::SliderGrab, vec4(0.));
					__sc += PushStyleColorForced(UI::Col::SliderGrabActive, vec4(0.));
					__sc += PushStyleColorForced(UI::Col::Text, vec4(0, 0, 0, 1));

					const vec2 cursorPos = UI::GetCursorPos();

					// Slider without Text
					curTimeInSeconds = UI::SliderFloat("##TimeSlider", curTimeInSeconds, minTimeInSeconds, maxTimeInSeconds, " ");
					const double curTime = curTimeInSeconds * 1000.; // Back to ms
					TimePercentage = RouteTime::GetTimePercentage(curTime);

					// Custom Slider Text
					{
						string text = Text::Format("%.3f s", curTimeInSeconds);
						const vec2 baseSliderTextPos = cursorPos + vec2(0, framePaddingY);

						const vec4 spectrumColor = RouteSpectrum::CalcCurrentSpectrumColorByTime(RUtils::AsInt(RouteTime::GetTimeByPercentage(0.5)));
						const vec3 contrastColor = ContrastColor::Get(spectrumColor.xyz);

						UI::PushStyleVar(UI::StyleVar::SelectableTextAlign, vec2(0.5, 0.5));

						{
							// Text Shadow (using Spectrum Color)
							UI::PushStyleColor(UI::Col::Text, vec4(spectrumColor.xyz, 1));
							UI::SetCursorPos(baseSliderTextPos + vec2(2, 2));
							UI::Selectable(text, false);
							UI::PopStyleColor(1);
						}
						
						{
							// Text Foreground (using Contrast Color) in Fake Bold
							UI::PushStyleColor(UI::Col::Text, vec4(contrastColor, 1));
							UI::SetCursorPos(baseSliderTextPos);
							UI::Selectable(text, false);
							UI::SetCursorPos(baseSliderTextPos + vec2(1, 0)); // Offset text to get fake Bold effect
							UI::Selectable(text, false);
							UI::PopStyleColor(1);
						}

						UI::PopStyleVar(1);
					}

					bIsTimeLineSliderActive = UI::IsItemActive();
					bIsTimeLineSliderHovered = UI::IsItemHovered();

					// Keeping this as an idea to align text with slider
					// {
					// 	__sv += PushStyleVarForced(UI::StyleVar::SelectableTextAlign, vec2(TimePercentage, 0.5));
					// 	UI::SetCursorPos(cursorPos + vec2(0, framePaddingY - 2));
					// 	UI::Selectable(text, false);
					// 	PopStyleVar(); __sv--;
					// }

					TimePercentage = Math::Clamp(TimePercentage, TimeControlLimits.x, TimeControlLimits.y);

					PopStyleColor(__sc);
					PopStyleVar(__sv);
				}
				UI::EndDisabled();
			}
			UI::EndChild();
			PopStyleVar(_sv);
			PopStyleColor(_sc);
			
		}
		UI::EndChild();

		UI::PopStyleVar(sv);
		UI::PopStyleColor(sc);

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

			const vec4 sliderGrabColor = UI::GetStyleColor(UI::Col::SliderGrab);
			const vec3 contrastColor = ContrastColor::Get(sliderGrabColor.xyz);

			const float relGrabHeight = 0.9;
			vec2 customSliderGrabSize = vec2(UI::GetStyleVarFloat(UI::StyleVar::GrabMinSize), relGrabHeight * drawRegion.y);
			vec2 customSliderDrawPos = drawPosition + (vec2(t, (1.0 - relGrabHeight)/2) * drawRegion) - (vec2(t, 0) * customSliderGrabSize);

			const float sliderGrabRounding = UI::GetStyleVarFloat(UI::StyleVar::GrabRounding);

			drawlist.AddRectFilled(vec4(customSliderDrawPos, customSliderGrabSize), sliderGrabColor, sliderGrabRounding);
			drawlist.AddRect(vec4(customSliderDrawPos, customSliderGrabSize),  vec4(contrastColor, .5f), sliderGrabRounding, 1.0f);
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