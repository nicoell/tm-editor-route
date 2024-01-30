namespace EditorRouteUI
{
	// ---------------------------------------------------------------
	// Route Table
	// ---------------------------------------------------------------
	void ShowRouteTable()
	{
		// ---------------------------------------------------------------
		// Setup Style and calc var
		const float paddingBetween = 8;
		vec2 tableChildSize;
		const vec2 contentRegion = UI::GetContentRegionAvail();
		{
			const float minListWidth = 120.;
			const float maxListWidth = 180.;

			tableChildSize.x = Math::Clamp(0.2 * contentRegion.x, minListWidth, maxListWidth) - (paddingBetween / 2);
			tableChildSize.y = contentRegion.y;
		}
		vec2 detailsChildSize;
		{
			detailsChildSize.x = contentRegion.x - tableChildSize.x - (paddingBetween / 2);
			detailsChildSize.y = contentRegion.y;
		}

		// Only push now after activating, so child sizes were calculated with padding
		UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(0., 0.));
		{
			// ---------------------------------------------------------------
			// Route Selection Table
			int32 windowFlags = UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse;
			UI::PushStyleColor(UI::Col::ChildBg, vec4(0., 0., 0., 64.)/255.);
			if (UI::BeginChild("RecordedRoutesSelection", tableChildSize, false, windowFlags))
			{
				// ---------------------------------------------------------------
				// Calc Sizes
				vec2 buttonRowSize;
				const float buttonHeight =  UI::GetTextLineHeightWithSpacing() + 2;
				{
					const float numButtonRows = 1.;
					buttonRowSize.x = tableChildSize.x - 1;
					buttonRowSize.y = numButtonRows * buttonHeight;
				}
				vec2 tableSize;
				{
					tableSize.x = tableChildSize.x - 1;
					tableSize.y = tableChildSize.y - buttonRowSize.y - 1; // -1 to prevent border cutoff
				}

				// ---------------------------------------------------------------
				// Route Table
				const int32 tableFlags = UI::TableFlags::RowBg | UI::TableFlags::ScrollY | UI::TableFlags::Sortable | UI::TableFlags::BordersH | UI::TableFlags::BordersV | UI::TableFlags::SizingFixedFit;
				if (UI::BeginTable("Recorded Routes", 2, tableFlags, tableSize))
				{
					UI::Indent(2);
					// ---------------------------------------------------------------
					// Headers
					const float renderColWidth = 20.;
					UI::TableSetupColumn(Icons::Flag + "##Render", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoSort | UI::TableColumnFlags::IndentEnable, renderColWidth);
					UI::TableSetupColumn("Route ID", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::DefaultSort, tableSize.x - renderColWidth, RouteTableRouteIDUserID);

					UI::TableHeadersRow();

					// ---------------------------------------------------------------
					// Sorting
					auto sortSpecs = UI::TableGetSortSpecs();
					if (sortSpecs !is null && sortSpecs.Dirty)
					{
						RouteContainer::Table::SortWithSortSpecs();
						sortSpecs.Dirty = false;
					}
					
					// ---------------------------------------------------------------
					// Clipped List
					UI::ListClipper clipper(RouteContainer::Routes.Length);
					while(clipper.Step())
					{
						for (int32 row = clipper.DisplayStart; row < clipper.DisplayEnd; row++)
						{     
							const uint32 i = RouteContainer::Table::OrderedRouteIndices[row]; 
							
							UI::PushID("RecordedRoutes" + i);

							UI::TableNextRow();
							UI::TableNextColumn();

							// ---------------------------------------------------------------
							// Visibility Checbox
							UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(0, 0));
							UI::PushStyleColor(UI::Col::FrameBg, vec4(89., 239., 134., 32.)/255.);
							UI::PushStyleColor(UI::Col::FrameBgHovered, vec4(89., 239., 134., 64.)/255.);
							UI::PushStyleColor(UI::Col::FrameBgActive, vec4(89., 239., 134., 96.)/255.);
							RouteContainer::Table::VisibleRoutes[i] = UI::Checkbox("##IsVisible", RouteContainer::Table::VisibleRoutes[i]);
							UI::PopStyleColor(3);
							UI::PopStyleVar();

							UI::TableNextColumn();

							if (UI::Selectable(i + "##IsSelected", RouteContainer::Table::SelectedRouteIndex == i, UI::SelectableFlags::SpanAllColumns | UI::SelectableFlags::AllowOverlap))
							{
								RouteContainer::Table::SetSelectedRoute(i);
							}
							UI::PopID();
						}
					}
					UI::EndTable();

					// ---------------------------------------------------------------
					// Buttons to Show, Hide and Invert selections

					if (UI::Button(Icons::Kenney::RadioChecked + "##All", vec2(buttonRowSize.x / 3., buttonHeight)))
					{
						for (uint32 row = 0; row < RouteContainer::Routes.Length; row++)
						{     
							RouteContainer::Table::VisibleRoutes[row] = true;
						}
					}
					if (UI::IsItemHovered())
					{
						UI::BeginTooltip();
						UI::Text("Show All");
						UI::EndTooltip();
					}
					UI::SameLine();
					if (UI::Button(Icons::Kenney::Radio + "##None", vec2(buttonRowSize.x / 3., buttonHeight)))
					{
						for (uint32 row = 0; row < RouteContainer::Routes.Length; row++)
						{     
							RouteContainer::Table::VisibleRoutes[row] = false;
						}
					}
					if (UI::IsItemHovered())
					{
						UI::BeginTooltip();
						UI::Text("Hide All");
						UI::EndTooltip();
					}
					UI::SameLine();
					if (UI::Button(Icons::Kenney::Adjust + "##Invert", vec2(buttonRowSize.x / 3., buttonHeight)))
					{
						for (uint32 row = 0; row < RouteContainer::Routes.Length; row++)
						{     
							RouteContainer::Table::VisibleRoutes[row] = !RouteContainer::Table::VisibleRoutes[row];
						}
					}
					if (UI::IsItemHovered())
					{
						UI::BeginTooltip();
						UI::Text("Invert");
						UI::EndTooltip();
					}
				}
			}
			UI::EndChild();
			
			UI::PopStyleColor();
		}
		// ---------------------------------------------------------------
		// Spacing
		UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(paddingBetween, 0.));
		UI::SameLine();
		UI::PopStyleVar();

		{
			// ---------------------------------------------------------------
			// Selected Route Details Panel
			int32 windowFlags = UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse;
			UI::PushStyleColor(UI::Col::ChildBg, vec4(0., 0., 0., 64.)/255.);
			if (UI::BeginChild("RecordedRoutesDetails", detailsChildSize, false, windowFlags))
			{
				// BeginTabBar doesn't return bool for whatever reason?
				UI::BeginTabBar("DetailsTabCategory", UI::TabBarFlags::FittingPolicyScroll | UI::TabBarFlags::NoCloseWithMiddleMouseButton);
				{
					TabGeneral::Draw();
					TabDisplay::Draw();
					UI::EndTabBar();
				}

				// if (RouteContainer::Table::IsRouteSelected())
				// {
				//     const int32 i = RouteContainer::Table::SelectedRouteIndex;
				//     auto@ route = RouteContainer::Routes[i];
				//     {
				//         auto@ sample = route.SampleDataArray[route.MaxMagnitudeIndex];
				//         UI::Text("Max Speed: ");
				//         UI::SameLine();
				//         if (UI::Button("" + sample.Velocity.Length()))
				//         {
				//             RouteTime::SetTime(sample.Time);
				//         }
				//     }
				//     {
				//         auto@ sample = route.SampleDataArray[route.MaxAltitudeIndex];
				//         UI::Text("Max Altitude: ");
				//         UI::SameLine();
				//         if (UI::Button("" + sample.Position.y))
				//         {
				//             RouteTime::SetTime(sample.Time);
				//         }
				//     }
				//     UI::Text("NumCData " + route.GetNumSamples());
				//     UI::Text("R MinTime " + route.GetMinTime() + " (" + RUtils::InMS(route.GetMinTime()) + " ms)");
				//     UI::Text("R MaxTime " + route.GetMaxTime() + " (" + RUtils::InMS(route.GetMaxTime()) + " ms)");
				//     UI::Text("S Time " + route.CurrentSample.Time + " (" + RUtils::InMS(route.CurrentSample.Time) + " ms)");
				//     UI::Separator();
				//     // for (uint32 ci = 0; ci < route.GetNumSamples(); ci++)
				//     // {
						
				//     //     UI::Text(ci + " : " + route.SampleDataArray[ci].Time + " (" + RUtils::InMS(route.SampleDataArray[ci].Time) + " ms)");
				//     // }
				// }
				// else 
				// {
				//     for (int32 i = 0; i < 20; i++)
				//     {
				//         UI::Text(i + " scrollable region");
				//     }
				// }
			}
			UI::EndChild();
			UI::PopStyleColor();
		}
		
		UI::PopStyleVar();
	}
}