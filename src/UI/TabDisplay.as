namespace EditorRouteUI
{
	// ---------------------------------------------------------------
	// Display Tab
	// ---------------------------------------------------------------
	namespace TabDisplay
	{
		class ItemBase
		{
			uint32 Idx;
			string GetName() const { return "ItemBase"; };
            void DrawValueUI() {}
		}

        class CheckBoxItemBase : ItemBase
        {
            bool bIsChecked;
            void DrawValueUI() override 
            {
                int32 sc = 0; int32 sv = 0;
                sv += PushStyleVarForced(UI::StyleVar::FramePadding, vec2(0, 0));
                sc += PushStyleColor(UI::Col::FrameBg, vec4(89., 239., 134., 32.)/255.);
                sc += PushStyleColor(UI::Col::FrameBgHovered, vec4(89., 239., 134., 64.)/255.);
                sc += PushStyleColor(UI::Col::FrameBgActive, vec4(89., 239., 134., 96.)/255.);
                bool isChecked =UI::Checkbox("##DisplayItemCheckbox" + "Idx", bIsChecked);
                PopStyleColor(sc);
                PopStyleVar(sv);
                if (isChecked != bIsChecked)
                {
                    bIsChecked = isChecked;
                    OnValueChanged();
                };
            }

            void OnValueChanged() {}
        }

        class RenderEventCheckBoxItem : CheckBoxItemBase
        {
            Events::EventType EventType;
            string GetName() const override { return "Display " + Events::GetCDO(EventType).GetName() + " Events"; };
            RenderEventCheckBoxItem(int32 typeIdx) 
            { 
                EventType = Events::EventType(typeIdx);
                bIsChecked = Events::IsVisible(EventType);
            }
            void OnValueChanged() override { Events::SetIsVisible(EventType, bIsChecked); }
        }

        class RenderGizmoCheckBoxItem : CheckBoxItemBase
        {
            RenderGizmoCheckBoxItem() { bIsChecked = Setting_RenderGizmo; }
            string GetName() const override { return "Display Gizmo"; }
            void OnValueChanged() override { Setting_RenderGizmo = bIsChecked; }
        }

        class RenderCarBoxCheckBoxItem : CheckBoxItemBase
        {
            RenderCarBoxCheckBoxItem() { bIsChecked = Setting_RenderCarBox; }
            string GetName() const override { return "Display Car Box"; }
            void OnValueChanged() override { Setting_RenderCarBox = bIsChecked; }
        }

        class RenderSelectedOnlyCheckBoxItem : CheckBoxItemBase
        {
            RenderSelectedOnlyCheckBoxItem() { bIsChecked = Setting_RenderSelectedOnly; }
            string GetName() const override { return "Display Selected Routes Only"; }
            void OnValueChanged() override { Setting_RenderSelectedOnly = bIsChecked; }
        }

		array<ItemBase@> RowItems;
		void Init()
		{
			if (RowItems.IsEmpty())
			{
                for(int32 eventTypeIdx = 0; eventTypeIdx < Events::EventType::NumTypes; eventTypeIdx++)
                {
                    if (Events::CanEverRender(eventTypeIdx))
                    {
                        RowItems.InsertLast(RenderEventCheckBoxItem(eventTypeIdx));
                    }
                }
                RowItems.InsertLast(RenderGizmoCheckBoxItem());
                RowItems.InsertLast(RenderCarBoxCheckBoxItem());
                RowItems.InsertLast(RenderSelectedOnlyCheckBoxItem());
			}
		}

		void Draw()
		{
			Init();

            // Display Events yes/no
            // Display All/Selected Route

			if(UI::BeginTabItem("Display", UI::TabItemFlags::NoReorder))
			{
				const vec2 contentRegion = UI::GetContentRegionAvail();

				const int32 tableFlags = UI::TableFlags::RowBg | UI::TableFlags::SizingStretchProp | UI::TableFlags::BordersInnerV | UI::TableFlags::ScrollY;
				if (UI::BeginTable("DisplayTabTable", 2, tableFlags, contentRegion))
				{
                    int32 _sv = 0;
					_sv += PushStyleVar(UI::StyleVar::FramePadding, vec2(8., 0.));

					UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 180.f);
					UI::TableSetupColumn("Value");

					UI::ListClipper clipper(RowItems.Length);
					while(clipper.Step())
					{
						for (int32 i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
						{
							ItemBase@ item = RowItems[i];
							UI::PushID("DisplayRowItem" + i);

							UI::TableNextRow();
							UI::TableNextColumn();
                    
							UI::Text(item.GetName());

							UI::TableNextColumn();
							item.DrawValueUI();
							UI::PopID();
						}
					}
					PopStyleVar(_sv);
					UI::EndTable();
				}
				CurrentSpectrumType = RouteSpectrum::ESpectrumType::Default;
				UI::EndTabItem();
			}
		}

	}
}