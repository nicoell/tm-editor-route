namespace RouteRenderer
{

	bool bDebug = false;

	namespace Stats
	{
		int32 RenderedLines = 0;
		int32 RequestedLines = 0;
		double RenderTime = 0;

		namespace Internal
		{
			uint32 MovWindowSize = 32;
			uint32 WinIndex = 0;
			array<uint64> RenderTimes;
		}
	}

	void Render()
	{
		uint64 startTime = Time::get_Now();
		
		Stats::RenderedLines = 0;
		Stats::RequestedLines = 0;
		
		auto camera = Camera::GetCurrent();
		if (camera is null) { return; }

		Events::RenderCtx::Proj = Camera::GetProjectionMatrix();
		Events::RenderCtx::MouseCoords = UI::GetMousePos();
		Events::RenderCtx::bIsMiddleMouseClicked = UI::IsMouseClicked(UI::MouseButton::Middle, false);
		
		nvg::MiterLimit(0.f);
		nvg::LineCap(nvg::LineCapType::Round);

		for (uint32 row = 0; row < RouteContainer::Routes.Length; row++)
		{
			const uint32 i = RouteContainer::Table::OrderedRouteIndices[row];
			if (RouteContainer::Table::VisibleRoutes[i])
			{
				auto route = RouteContainer::Routes[i];
				bool isSelected = RouteContainer::Table::SelectedRouteIndex == i;

				if (Setting_RenderSelectedOnly && !isSelected) { continue; }

				RenderRouteLine(route, isSelected);
				RenderEvents(route, isSelected);

				auto@ sample = route.CurrentSample;

				{
					RenderGizmo(sample);
					RenderBox(sample);
				}

			}
		}
		// Draw Selected Route later
		if (bDebug) { trace("After Render: " + Time::get_Now());}

		UpdateRenderTime(Time::get_Now() - startTime);

		bDebug = false;
	}

	void UpdateRenderTime(uint64 newRenderTime)
	{
		if (Stats::Internal::RenderTimes.Length != Stats::Internal::MovWindowSize) { Stats::Internal::RenderTimes.Resize(Stats::Internal::MovWindowSize); }

		Stats::Internal::WinIndex = Stats::Internal::WinIndex % Stats::Internal::MovWindowSize;
		Stats::Internal::RenderTimes.InsertAt(Stats::Internal::WinIndex, newRenderTime);
		Stats::Internal::WinIndex++;

		Stats::RenderTime = 0;
		for(uint32 i = 0; i < Stats::Internal::MovWindowSize; i++)
		{ Stats::RenderTime += Stats::Internal::RenderTimes[i]; }
		Stats::RenderTime /= Stats::Internal::MovWindowSize;
	}

	void RenderRouteLine(Route::FRoute@ route, bool isSelected)
	{
		vec4 color = isSelected ? vec4(Setting_SelectedRouteColor, 1) : vec4(Setting_RouteColor, 0.8);
		nvg::StrokeWidth(Setting_RouteLineWidth);
		nvg::StrokeColor(color);

		// Let nanovg handle scale and transform for free
		nvg::Scale(CameraExt::ScaleToDisplay);
		nvg::Translate(CameraExt::DisplayPos);

		// Pull projection matrix into local register
		mat4 proj = Camera::GetProjectionMatrix();
		// New variables in loop scope are expensive. Define them outside the loop.
		vec4 pclip; 
		vec3 p;
		bool bIsLineStart = true;

		const uint32 numPositions = route.Positions.Length;

		nvg::BeginPath();
		for (uint32 i = 0; i < numPositions; i++) 
		{
			if (route.bIsDiscontinuousArray[i])
			{
				bIsLineStart = true; i++;
			}
			else
			{
				// Load variable from array to local register to speed up matrix multiplication (since mat4 opMul takes  reference)
				p = route.Positions[i];
				
				pclip = proj * p;
				if (pclip.w >= 0) 
				{
					bIsLineStart = true; 
				}
				else if (bIsLineStart)
				{
					nvg::MoveTo(vec2(pclip.x / pclip.w + 1, pclip.y / pclip.w + 1));
					bIsLineStart = false;
				}
				else 
				{
					nvg::LineTo(vec2(pclip.x / pclip.w + 1, pclip.y / pclip.w + 1)); 
				}
			}
		}
		nvg::ResetTransform();
		nvg::Stroke();
	}

	void RenderEvents(Route::FRoute@ route, bool isSelected)
	{
		mat4 proj = Camera::GetProjectionMatrix();
		vec4 pclip; 
		vec3 p;
		vec2 dp = CameraExt::DisplayPos;
		vec2 sc = CameraExt::ScaleToDisplay;
		for(int32 eventTypeIdx = 0; eventTypeIdx < Events::EventType::NumTypes; eventTypeIdx++)
		{
			if (Events::CanEverRender(eventTypeIdx) && Events::IsVisible(eventTypeIdx))
			{
				auto events = route.Events[eventTypeIdx];
				for(uint32 eventIdx = 0; eventIdx < route.Events[eventTypeIdx].Length; eventIdx++)
				{
					p = events[eventIdx].Position;
					pclip = proj * p;
					
					if (pclip.w < 0) 
					{
						events[eventIdx].Render(dp + vec2(pclip.x / pclip.w + 1, pclip.y / pclip.w + 1) * sc, isSelected); 
					}
				}
			}
		}
	}

	void RenderGizmo(Route::FSampleData@ sample)
	{
		if (!Setting_RenderGizmo) { return; }

		mat4 proj = Camera::GetProjectionMatrix();

		vec3 p = sample.Position;
		vec4 pclip = proj * p;

		if (pclip.w < 0) 
		{
			vec2 origin = vec2(pclip.x / pclip.w + 1, pclip.y / pclip.w + 1);
			array<vec3> axes(3);
			axes[0] = vec3(1, 0, 0) * Setting_GizmoScale;
			axes[1] = vec3(0, 1, 0) * Setting_GizmoScale;
			axes[2] = vec3(0, 0, 1) * Setting_GizmoScale;

			array<vec4> cols(3);
			cols[0] = vec4(1, 0, 0, 1);
			cols[1] = vec4(0, 1, 0, 1);
			cols[2] = vec4(0, 0, 1, 1);
			
			for(uint32 aIdx = 0; aIdx < 3; aIdx++) 
			{
				p = sample.Position + sample.Rotation * axes[aIdx];
				pclip = proj * p;

				if (pclip.w < 0)
				{
					nvg::BeginPath();
					nvg::Scale(CameraExt::ScaleToDisplay);
					nvg::Translate(CameraExt::DisplayPos);
					nvg::MoveTo(origin);
					nvg::LineTo(vec2(pclip.x / pclip.w + 1, pclip.y / pclip.w + 1));
					nvg::StrokeWidth(Setting_GizmoWidth);
					nvg::StrokeColor(cols[aIdx]);
					nvg::ResetTransform();
					nvg::Stroke();
				}
			}
		}
	}

	void RenderBox(Route::FSampleData@ sample)
	{
		if (!Setting_RenderCarBox) { return; }

		mat4 proj = Camera::GetProjectionMatrix();

		vec3 p = sample.Position;
		vec4 pclip = proj * p;

		const float carHalfWidth = 2.1f;
		const float carHeightUp = 1.75f;
		const float carHeightDown = 0.0f;
		const float carLengthFront = 4.37f;
		const float carLengthBack = 3.2f;

		if (pclip.w < 0) 
		{

			// Cube vertices scaled to match car box
			array<vec3> verts(8);
			verts[0] = vec3(-.5f,  .5f, -.5f) * vec3(carHalfWidth, carHeightUp, carLengthBack);
			verts[1] = vec3( .5f,  .5f, -.5f) * vec3(carHalfWidth, carHeightUp, carLengthBack);
			verts[2] = vec3( .5f, -.5f, -.5f) * vec3(carHalfWidth, carHeightDown, carLengthBack);
			verts[3] = vec3(-.5f, -.5f, -.5f) * vec3(carHalfWidth, carHeightDown, carLengthBack);
			verts[4] = vec3( .5f,  .5f,  .5f) * vec3(carHalfWidth, carHeightUp, carLengthFront);
			verts[5] = vec3(-.5f,  .5f,  .5f) * vec3(carHalfWidth, carHeightUp, carLengthFront);
			verts[6] = vec3(-.5f, -.5f,  .5f) * vec3(carHalfWidth, carHeightDown, carLengthFront);
			verts[7] = vec3( .5f, -.5f,  .5f) * vec3(carHalfWidth, carHeightDown, carLengthFront);

			/*
			 * Indices to cube verts ordered to draw cube with 12 lines
			 * 0-<-1 1-<-4 4-<-5 5-<-0
			 *     |     |     |     |
			 * 3---2 2---7 7---6 6---3
			 */
			array<array<uint32>> indices = {{3, 2, 1, 0}, {2, 7, 4, 1}, {7, 6, 5, 4}, {6, 3, 0, 5}};

			for(uint32 sIdx = 0; sIdx < 4; sIdx++) 
			{
				p = sample.Position + sample.Rotation * verts[indices[sIdx][0]];
				pclip = proj * p;
				if (pclip.w < 0) 
				{
					nvg::BeginPath();
					nvg::Scale(CameraExt::ScaleToDisplay);
					nvg::Translate(CameraExt::DisplayPos);
					nvg::MoveTo(vec2(pclip.x / pclip.w + 1, pclip.y / pclip.w + 1));
					for(uint32 vIdx = 1; vIdx < 4; vIdx++) 
					{
						p = sample.Position + sample.Rotation * verts[indices[sIdx][vIdx]];
						pclip = proj * p;
						if (pclip.w < 0) 
						{
							nvg::LineTo(vec2(pclip.x / pclip.w + 1, pclip.y / pclip.w + 1));
						}
					}
					nvg::StrokeWidth(Setting_BoxWidth);
					nvg::StrokeColor(Setting_CarBoxColor);
					nvg::ResetTransform();
					nvg::Stroke();
				}
			}
		}
	}
}