
namespace RouteRenderer
{

	bool bDebug = false;

	namespace Stats
	{
		int32 RenderedLines = 0;
		int32 RequestedLines = 0;
		double RenderTime = 0;

		namespace Private
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

AS_IF DEPENDENCY_EDITOR
		// Reset ActiveDrawInstanceIds at the beginning of the frame
    	ActiveDrawInstanceIds.Resize(0);
AS_ENDIF

		for (uint32 row = 0; row < RouteContainer::Routes.Length; row++)
		{
			const uint32 routeIdx = RouteContainer::Table::OrderedRouteIndices[row];
			bool isSelected = RouteContainer::Table::SelectedRouteIndex == routeIdx;
			if (RouteContainer::Table::VisibleRoutes[routeIdx] && !isSelected)
			{
				RenderRoute(routeIdx);
			}
		}

		// Draw Selected Route later
		if (RouteContainer::Routes.Length > 0)
		{
			const uint32 routeIdx = RouteContainer::Table::SelectedRouteIndex;
			if (RouteContainer::Table::VisibleRoutes[routeIdx])
			{
				RenderRoute(routeIdx);
			}
		}

		// Cleanup unused DrawInstances
	    CleanupUnusedEPP();

		if (bDebug) { RUtils::DebugTrace("After Render: " + Time::get_Now());}

		UpdateRenderTime(Time::get_Now() - startTime);

		bDebug = false;
	}

	void Reset()
	{
		if (RUtils::ShouldUseEditorPlusPlus())
		{
			ResetEPP();
		}
	}

	void RenderRoute(const uint32 routeIdx)
	{
		auto route = RouteContainer::Routes[routeIdx];
		bool isSelected = RouteContainer::Table::SelectedRouteIndex == routeIdx;

		if (Setting_RenderSelectedOnly && !isSelected) { return; }

		if (RUtils::ShouldUseEditorPlusPlus())
		{
			RenderRouteLineEPP(route);
		}
		else
		{
			vec4 color = isSelected ? vec4(Setting_SelectedRouteColor, 1) : vec4(Setting_RouteColor, 0.8);

			nvg::StrokeWidth(Setting_RouteLineWidth);
			{
				nvg::StrokeColor(vec4(color.xyz, color.w * Setting_ElapsedRouteOpacityModifier));
				RenderRouteLine(route, 0, route.BestSampleIndex + 1);
			}
			{
				nvg::StrokeColor(color);
				RenderRouteLine(route, route.BestSampleIndex, route.GetNumSamples() - route.BestSampleIndex);
			}
		}

		RenderEvents(route, isSelected);

		auto@ sample = route.CurrentSample;
		{
			RenderGizmo(sample);
			RenderBox(sample);
		}
	}

	void UpdateRenderTime(uint64 newRenderTime)
	{
		if (Stats::Private::RenderTimes.Length != Stats::Private::MovWindowSize) { Stats::Private::RenderTimes.Resize(Stats::Private::MovWindowSize); }

		Stats::Private::WinIndex = Stats::Private::WinIndex % Stats::Private::MovWindowSize;
		Stats::Private::RenderTimes.InsertAt(Stats::Private::WinIndex, newRenderTime);
		Stats::Private::WinIndex++;

		Stats::RenderTime = 0;
		for(uint32 i = 0; i < Stats::Private::MovWindowSize; i++)
		{ Stats::RenderTime += Stats::Private::RenderTimes[i]; }
		Stats::RenderTime /= Stats::Private::MovWindowSize;
	}

	void RenderRouteLine(const Route::FRoute@ route, const int32 startIdx, const int32 count)
	{
		// Let nanovg handle scale and transform for free
		nvg::Scale(CameraExt::ScaleToDisplay);
		nvg::Translate(CameraExt::DisplayPos);

		// Pull projection matrix into local register
		const mat4 proj = Camera::GetProjectionMatrix();
		// Extracting matrix elements into individual floats
		const float xx = proj.xx, xy = proj.xy, xw = proj.xw;
		const float yx = proj.yx, yy = proj.yy, yw = proj.yw;
		const float zx = proj.zx, zy = proj.zy, zw = proj.zw;
		const float wx = proj.tx, wy = proj.ty, ww = proj.tw;
		// New vectors in loop scope are expensive. Define them outside the loop.
		vec3 p; 
		bool bIsLineStart = true;

		const uint32 numPositions = startIdx + count;

		const auto bIsDiscontinuousArrayCopy = route.bIsDiscontinuousArray;
		const auto@ sampleArray = @route.SampleDataArray;

		nvg::BeginPath();
		for (uint32 i = startIdx; i < numPositions; i++) 
		{
			if (bIsDiscontinuousArrayCopy[i])
			{
				bIsLineStart = true; i++;
			}
			else
			{
				// Load vector from array to local register
				p = sampleArray[i].Position;

				if ((xw * p.x + yw * p.y + zw * p.z + ww) >= 0) 
				{
					bIsLineStart = true; 
				}
				else if (bIsLineStart)
				{
					nvg::MoveTo(vec2(
						(xx * p.x + yx * p.y + zx * p.z + wx) / (xw * p.x + yw * p.y + zw * p.z + ww) + 1,
						(xy * p.x + yy * p.y + zy * p.z + wy) / (xw * p.x + yw * p.y + zw * p.z + ww) + 1));
					bIsLineStart = false;
				}
				else 
				{
					nvg::LineTo(vec2(
						(xx * p.x + yx * p.y + zx * p.z + wx) / (xw * p.x + yw * p.y + zw * p.z + ww) + 1,
						(xy * p.x + yy * p.y + zy * p.z + wy) / (xw * p.x + yw * p.y + zw * p.z + ww) + 1)); 
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

	void RenderGizmo(Samples::FSampleData@ sample)
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

	void RenderBox(Samples::FSampleData@ sample)
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

AS_IF DEPENDENCY_EDITOR
	// Dictionary to store DrawInstances, mapping from DrawInstance ID to DrawInstance handle
    dictionary DrawInstancesEPP;

    // Array to keep track of DrawInstances used in the current frame
    array<string> ActiveDrawInstanceIds;

	// Function to render a route using DrawInstance
    void RenderRouteLineEPP(const Route::FRoute@ route)
    {
        // Create a render hash for the route
        uint32 drawInstanceId = route.CreateRenderHash();
		string drawInstanceIdStr = "EditorRoute_" + drawInstanceId;

        // Keep track of used DrawInstance IDs
        ActiveDrawInstanceIds.InsertLast(drawInstanceIdStr);

        Editor::DrawLinesAndQuads::DrawInstance@ drawInstance;

        // Get or create the DrawInstance
        if (!DrawInstancesEPP.Exists(drawInstanceIdStr))
        {
			RUtils::DebugTrace("Create new DrawInstance #" + drawInstanceIdStr);
            @drawInstance = Editor::DrawLinesAndQuads::GetOrCreateDrawInstance(drawInstanceIdStr);
            DrawInstancesEPP.Set(drawInstanceIdStr, @drawInstance);
        }
        else
        {
            // Retrieve the DrawInstance from the dictionary
            @drawInstance = cast<Editor::DrawLinesAndQuads::DrawInstance@>(DrawInstancesEPP[drawInstanceIdStr]);
        }

        // If the DrawInstance has no line segments, we need to populate it
        if (drawInstance.NbLineSegments() == 0)
        {
			RUtils::DebugTrace("Fill DrawInstance #" + drawInstanceIdStr);

            // Fill the DrawInstance with line segments
            const int32 startIdx = 0;
            const int32 count = route.GetNumSamples();

            const uint32 numPositions = startIdx + count;

            const auto bIsDiscontinuousArrayCopy = route.bIsDiscontinuousArray;
            const auto@ sampleArray = @route.SampleDataArray;

            int32 lastValidIndex = -1;

			drawInstance.ResizeLineSegments(numPositions - 1);

            for (uint32 i = startIdx; i < numPositions; i++)
            {
                if (bIsDiscontinuousArrayCopy[i])
                {
                    // Handle discontinuities by resetting lastValidIndex
                    lastValidIndex = -1;
                }
                else
                {
                    if (lastValidIndex >= 0)
                    {
                        // Add a line segment between the last valid point and the current point
                        drawInstance.PushLineSegment(sampleArray[lastValidIndex].Position + vec3(0, 64.25, 0), sampleArray[i].Position + vec3(0, 64.25, 0));
                    }
                    lastValidIndex = i;
                }
            }

            // Request the line color (NonSelected Color without Alpha)
            drawInstance.RequestLineColor(vec3(Setting_RouteColor.x, Setting_RouteColor.y, Setting_RouteColor.z));
        }

        // Call Draw on the DrawInstance to render it
        drawInstance.Draw();
    }

    // Function to clean up unused DrawInstances after rendering
    void CleanupUnusedEPP()
    {
        array<string>@ allKeys = DrawInstancesEPP.GetKeys();
        for (uint i = 0; i < allKeys.Length; i++)
        {
            string key = allKeys[i];
            if (ActiveDrawInstanceIds.Find(key) < 0)
            {
				RUtils::DebugTrace("Delete DrawInstance #" + key);
                // The DrawInstance was not used in this frame
                auto drawInstance = cast<Editor::DrawLinesAndQuads::DrawInstance@>(DrawInstancesEPP[key]);
                drawInstance.Deregister();
                DrawInstancesEPP.Delete(key);
            }
        }
    }

	void ResetEPP()
	{
		array<string>@ allKeys = DrawInstancesEPP.GetKeys();
        for (uint i = 0; i < allKeys.Length; i++)
        {
            string key = allKeys[i];
			RUtils::DebugTrace("Delete DrawInstance #" + key);
			// The DrawInstance was not used in this frame
			auto drawInstance = cast<Editor::DrawLinesAndQuads::DrawInstance@>(DrawInstancesEPP[key]);
			drawInstance.Deregister();
			DrawInstancesEPP.Delete(key);
		}
	}
AS_ELSE
	void RenderRouteLineEPP(const Route::FRoute@ route) {}
	void CleanupUnusedEPP() {}
	void ResetEPP() {}
AS_ENDIF

}