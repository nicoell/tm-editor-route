namespace EditorRouteUI
{
	int32 ContextRouteIdx = -1;

	// ---------------------------------------------------------------
	// Route Table
	// ---------------------------------------------------------------
	void DrawActiveRouteContent()
	{
		// ---------------------------------------------------------------
		// Setup Style and calc var

		float paddingBetween;
		{
			int32 _sv = 0;
			_sv += PushStyleVar(UI::StyleVar::ItemSpacing, vec2(8., 0.));
			paddingBetween = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;
			PopStyleVar(_sv);
		}

		vec2 tableChildSize;
		const vec2 contentRegion = UI::GetContentRegionAvail();
		{
			const float minListWidth = 120.;
			const float maxListWidth = 180.;

			tableChildSize.x = Math::Clamp(0.2 * contentRegion.x, minListWidth, maxListWidth);
			tableChildSize.y = contentRegion.y;
		}
		vec2 detailsChildSize;
		{
			detailsChildSize.x = contentRegion.x - tableChildSize.x - paddingBetween;
			detailsChildSize.y = contentRegion.y;
		}
		{
			int32 sc = 0;
			// ---------------------------------------------------------------
			// Route Selection Table
			int32 windowFlags = UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse;
			sc += PushStyleColor(UI::Col::ChildBg, vec4(0., 0., 0., 64.)/255.);
			if (UI::BeginChild("RecordedRoutesSelection", tableChildSize, false, windowFlags))
			{
				// ---------------------------------------------------------------
				// Calc Sizes
				vec2 buttonRowSize;
				const float buttonHeight = UI::GetTextLineHeightWithSpacing();
				{
					const float numButtonRows = 1.;
					buttonRowSize.x = tableChildSize.x - 1;
					buttonRowSize.y = numButtonRows * buttonHeight;
				}
				vec2 tableSize;
				{
					tableSize.x = tableChildSize.x - 1;
					tableSize.y = tableChildSize.y - buttonRowSize.y - UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).y - 1; // -1 to prevent border cutoff
				}

				// ---------------------------------------------------------------
				// Route Table
				int32 clickedHoveredRoute = -1;
				const int32 tableFlags = UI::TableFlags::RowBg | UI::TableFlags::ScrollY | UI::TableFlags::Sortable | UI::TableFlags::BordersH | UI::TableFlags::BordersV | UI::TableFlags::SizingFixedFit | UI::TableFlags::Resizable ;
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
							int32 _sv = 0; int32 _sc = 0;
							_sv += PushStyleVarForced(UI::StyleVar::FramePadding, vec2(0, 0));
							_sc += PushStyleColor(UI::Col::FrameBg, vec4(89., 239., 134., 32.)/255.);
							_sc += PushStyleColor(UI::Col::FrameBgHovered, vec4(89., 239., 134., 64.)/255.);
							_sc += PushStyleColor(UI::Col::FrameBgActive, vec4(89., 239., 134., 96.)/255.);
							RouteContainer::Table::VisibleRoutes[i] = UI::Checkbox("##IsVisible", RouteContainer::Table::VisibleRoutes[i]);
							UI::PopStyleColor(_sc);
							UI::PopStyleVar(_sv);

							UI::TableNextColumn();
							
							// ---------------------------------------------------------------
							// Route ID and Duration

							if (UI::Selectable(i + "\t\\$aaa"+ Text::Format("%0.2f s", double(RouteContainer::Routes[i].GetDuration()) / 1000.) +"" + "##IsSelected", RouteContainer::Table::SelectedRouteIndex == i, UI::SelectableFlags::SpanAllColumns | UI::SelectableFlags::AllowOverlap))
							{
								RouteContainer::Table::SetSelectedRoute(i);
							}

							if (UI::IsItemHovered() && UI::IsMouseClicked(UI::MouseButton::Right)) { clickedHoveredRoute = i; }
							
							UI::PopID();
						}
					}
					UI::EndTable();

					// ---------------------------------------------------------------
					// Context Menu
					if (clickedHoveredRoute >=0) 
					{ 
						UI::OpenPopup("RouteTableContextMenu"); 
						ContextRouteIdx = clickedHoveredRoute; 
					}
					{
						if (UI::BeginPopup("RouteTableContextMenu", UI::WindowFlags::NoMove ))
						{
							if (UI::MenuItem(Icons::Flag + "Show Route " + ContextRouteIdx + " only", "r"))
							{
								for (uint32 i = 0; i < RouteContainer::Routes.Length; i++)
								{
									RouteContainer::Table::VisibleRoutes[i] = i == uint32(ContextRouteIdx);
								}
							}
							// ---------------------------------------------------------------
							// Extra spacing before destructive items
							UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0., 4.));
							UI::Separator();
							UI::Separator();
							UI::PopStyleVar(1);
							if (UI::MenuItem("\\$d32" + Icons::Trash + " Delete Route"))
							{
								RouteIdxToDelete = ContextRouteIdx;
                            	UI::CloseCurrentPopup();
							}
							UI::EndPopup();
						}
						else 
						{
							ContextRouteIdx = -1;
						}
					}

					// ---------------------------------------------------------------
					// Buttons to Show, Hide and Invert selections
					{
						// Reduce Spacing a bit
						int32 _sv = 0;
						_sv += PushStyleVarForced(UI::StyleVar::ItemSpacing, UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing) / 2.);
						
						const int32 numButtons = 3;
						vec2 buttonSize = buttonRowSize;
						{
							buttonSize.x = buttonRowSize.x - UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x * (numButtons - 1);
							buttonSize.x = buttonSize.x / numButtons;
						}

						if (UI::Button(Icons::Kenney::RadioChecked + "##All", buttonSize))
						{
							for (uint32 row = 0; row < RouteContainer::Routes.Length; row++)
							{     
								RouteContainer::Table::VisibleRoutes[row] = true;
							}
						}
						RUtils::AddTooltipText("Select All");
						UI::SameLine();
						if (UI::Button(Icons::Kenney::Radio + "##None", buttonSize))
						{
							for (uint32 row = 0; row < RouteContainer::Routes.Length; row++)
							{     
								RouteContainer::Table::VisibleRoutes[row] = false;
							}
						}
						RUtils::AddTooltipText("Unselect All");
						UI::SameLine();
						if (UI::Button(Icons::Kenney::Adjust + "##Invert", buttonSize))
						{
							for (uint32 row = 0; row < RouteContainer::Routes.Length; row++)
							{     
								RouteContainer::Table::VisibleRoutes[row] = !RouteContainer::Table::VisibleRoutes[row];
							}
						}
						RUtils::AddTooltipText("Invert Selection");

						PopStyleVar(_sv);
					}
				}
			}
			UI::EndChild();
			
			PopStyleColor(sc);
		}
		// ---------------------------------------------------------------
		// Spacing
		{
			int32 _sv = 0;
			_sv += PushStyleVarForced(UI::StyleVar::ItemSpacing, vec2(paddingBetween, 0.));
			UI::SameLine();
			PopStyleVar(_sv);
		}

		{
			// ---------------------------------------------------------------
			// Selected Route Details Panel
			int32 windowFlags = UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoScrollWithMouse;
			int32 sc = 0;
			sc += PushStyleColor(UI::Col::ChildBg, vec4(0., 0., 0., 64.)/255.);
			if (UI::BeginChild("RecordedRoutesDetails", detailsChildSize, false, windowFlags))
			{
				// BeginTabBar doesn't return bool for whatever reason?
				UI::BeginTabBar("DetailsTabCategoryv2", UI::TabBarFlags::FittingPolicyScroll | UI::TabBarFlags::NoCloseWithMiddleMouseButton);
				{
					TabGeneral::Draw();
					TabIO::Draw();
					TabSettings::Draw();
					UI::EndTabBar();
				}
			}
			UI::EndChild();
			PopStyleColor(sc);
		}
	}
}