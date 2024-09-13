namespace EditorRouteUI
{
	// ---------------------------------------------------------------
	// General Tab
	// ---------------------------------------------------------------
	namespace TabGeneral
	{
		class FItemBase
		{
			uint32 Idx;
			string GetName() const { return "FItemBase"; };
			string GetTooltip() const { return ""; };
			string GetValue() const { return "Value"; }

			void Select() { Ctx::SelectedItem = Idx; OnSelect(); }
			void OnSelect() { return; }

			RouteSpectrum::ESpectrumType GetSpectrum() const { return RouteSpectrum::ESpectrumType::None; }
			vec4 GetSpectrumColor() const { return UI::GetStyleColor(UI::Col::Text); }

			string GetActionName() const { return ""; }
			void RunAction() const { return; }
		}

		class FSamplePropertyItemBase : FItemBase
		{
			Samples::EPropType PropType;
			RouteSpectrum::ESpectrumType GetSpectrum() const override { return Samples::Prop::SpectrumType[PropType]; };
			vec4 GetSpectrumColor() const override { return RouteSpectrum::CalcSampleSpectrumColor(GetSpectrum(), Ctx::Route, GetSample()); }
			string GetName() const override { return Samples::Prop::Name[PropType]; };
			string GetValue() const override 
			{ 
				if (GetSample() is null) { return "-"; } 
				string fmt = GetValueFormat();
				if (fmt.Length <= 0) { return GetSample().Prop[PropType]; }
				return GetSample().Prop[PropType].Format(fmt);
			}
			string GetValueFormat() { return ""; }
			Samples::FSampleData@ GetSample() const { return Ctx::Route.CurrentSample; }
		}

		class FEventItemBase : FItemBase
		{
			Events::EventType EventType;
			string GetName() const override { return Events::GetCDO(EventType).GetName(); };
			string GetValue() const override { return GetEvent() is null ? "-" : GetEvent().GetUIValue(); }
			string GetTooltip() const override { return Events::GetCDO(EventType).GetUITooltip(); }
			Events::IEvent@ GetEvent() const { return null; }

			Events::IEvent@ GetCurrentEvent() const { return Ctx::Route.GetCachedCurrentEvent(int32(EventType)); }
			Events::IEvent@ GetClosestEvent() const { return Ctx::Route.GetCachedClosestEvent(int32(EventType)); }
			Events::IEvent@ GetPreviousEvent() const { return Ctx::Route.GetCachedPreviousEvent(int32(EventType)); }
			Events::IEvent@ GetNextEvent() const { return Ctx::Route.GetCachedNextEvent(int32(EventType)); }
		}

		// ---------------------------------------------------------------
		// Duration
		class FDurationItem : FItemBase
		{
			string GetName() const override { return "Duration"; }
			string GetValue() const override { return Text::Format("%0.2f s", double(Ctx::Route.GetDuration()) / 1000.); }
		}
		// ---------------------------------------------------------------
		// Recorded Frames
		class FRecordedFramesItem : FItemBase
		{
			string GetName() const override { return "Recorded Frames"; }
			string GetValue() const override { return "" + Ctx::Route.GetNumSamples(); }
		}
		// ---------------------------------------------------------------
		// Speed
		class FMaxSpeedItem : FSamplePropertyItemBase
		{
			FMaxSpeedItem() { PropType = Samples::EPropType::Speed; }
			string GetName() const override { return "Max " + FSamplePropertyItemBase::GetName(); }
			Samples::FSampleData@ GetSample() const override { return Ctx::Route.SampleDataArray[Ctx::Route.MaxMagnitudeIndex]; }
			string GetValueFormat() override { return "%.2f km/h"; }
			string GetActionName() const override { return Strings::GotoTime; }
			void RunAction() const override 
			{
				RouteTime::SetTime(GetSample().Time);
			}
		}

		class FCurrentSpeedItem : FSamplePropertyItemBase
		{
			FCurrentSpeedItem() { PropType = Samples::EPropType::Speed; }
			string GetValueFormat() override { return "%.2f km/h"; }
		}
		// ---------------------------------------------------------------
		// "Altitude"

		class FMaxAltitudeItem : FSamplePropertyItemBase
		{
			FMaxAltitudeItem() { PropType = Samples::EPropType::Altitude; }
			string GetName() const override { return "Max " + FSamplePropertyItemBase::GetName(); }
			Samples::FSampleData@ GetSample() const override { return Ctx::Route.SampleDataArray[Ctx::Route.MaxAltitudeIndex]; }
			string GetValueFormat() override { return "%.2f m"; }
			string GetTooltip() const override { return "Position z-Coordinate"; }
			string GetActionName() const override { return Strings::GotoTime; }
			void RunAction() const override 
			{
				RouteTime::SetTime(GetSample().Time);
			}

		}

		class FCurrentAltitudeItem : FSamplePropertyItemBase
		{
			FCurrentAltitudeItem() { PropType = Samples::EPropType::Altitude; }
			string GetValueFormat() override { return "%.2f m"; }
			string GetTooltip() const override { return "Position z-Coordinate"; }
		}
		// ---------------------------------------------------------------
		// Position
		class FCurrentPositionItem : FSamplePropertyItemBase
		{
			FCurrentPositionItem() { PropType = Samples::EPropType::Position; }
		}
		// ---------------------------------------------------------------
		// AvgFPS
		class FCurrentAvgFPSItem : FSamplePropertyItemBase
		{
			FCurrentAvgFPSItem() { PropType = Samples::EPropType::AvgFPS; }
		}
		// ---------------------------------------------------------------
		// Gears
		class FGearItemBase : FEventItemBase
		{
			FGearItemBase() { EventType = Events::EventType::GearEvent; }
			Events::FGearEvent@ GetGearEvent() const { return cast<Events::FGearEvent>(GetEvent()); }
			RouteSpectrum::ESpectrumType GetSpectrum() const override { return RouteSpectrum::ESpectrumType::Gear; }
			vec4 GetSpectrumColor() const override { return GetGearEvent() !is null ? RouteSpectrum::CalcSpectrumColor_Gear(GetGearEvent()) : FItemBase::GetSpectrumColor(); }
			string GetActionName() const override { return Strings::GotoTime; }
			void RunAction() const override 
			{
				if (GetGearEvent() !is null) { RouteTime::SetTime(GetGearEvent().Time); }
			}
		}
		// Current Gear
		class FCurrentGearItem : FGearItemBase
		{
			string GetName() const override { return "Gear"; }
			string GetActionName() const override { return ""; } // Disable Action for Current Gear
			Events::IEvent@ GetEvent() const override { return GetCurrentEvent(); }
		}
		// Previous Gear
		class FPrevGearItem : FGearItemBase
		{
			string GetName() const override { return "Previous Gear"; }
			Events::IEvent@ GetEvent() const override { return GetPreviousEvent(); }
			string GetActionName() const override { return Strings::GotoPrev; }
		}
		// Next Gear
		class FNextGearItem : FGearItemBase
		{
			string GetName() const override { return "Next Gear"; }
			Events::IEvent@ GetEvent() const override { return GetNextEvent(); }
			string GetActionName() const override { return Strings::GotoNext; }
		}
		// ---------------------------------------------------------------
		// Wheels Contact Count
		class FWheelsContactItem : FEventItemBase
		{
			FWheelsContactItem() { EventType = Events::EventType::WheelsContactEvent; }
			Events::IEvent@ GetEvent() const override { return GetCurrentEvent(); }
		}
		// ---------------------------------------------------------------
		// VehicleType
		class FVehicleTypeItemBase : FEventItemBase
		{
			FVehicleTypeItemBase() { EventType = Events::EventType::VehicleTypeEvent; }
			Events::FVehicleTypeEvent@ GetVehicleTypeEvent() const { return cast<Events::FVehicleTypeEvent>(GetEvent()); }
			RouteSpectrum::ESpectrumType GetSpectrum() const override { return RouteSpectrum::ESpectrumType::VehicleType; }
			vec4 GetSpectrumColor() const override { return GetVehicleTypeEvent() !is null ? RouteSpectrum::CalcSpectrumColor_VehicleType(GetVehicleTypeEvent()) : FItemBase::GetSpectrumColor(); }
			string GetActionName() const override { return Strings::GotoTime; }
			void RunAction() const override 
			{
				if (GetVehicleTypeEvent() !is null) { RouteTime::SetTime(GetVehicleTypeEvent().Time); }
			}
		}
		// Current VehicleType
		class FCurrentVehicleTypeItem : FVehicleTypeItemBase
		{
			string GetName() const override { return "VehicleType"; }
			string GetActionName() const override { return ""; } // Disable Action for Current VehicleType
			Events::IEvent@ GetEvent() const override { return GetCurrentEvent(); }
		}
		// Previous VehicleType
		class FPrevVehicleTypeItem : FVehicleTypeItemBase
		{
			string GetName() const override { return "Previous VehicleType"; }
			Events::IEvent@ GetEvent() const override { return GetPreviousEvent(); }
			string GetActionName() const override { return Strings::GotoPrev; }
		}
		// Next VehicleType
		class FNextVehicleTypeItem : FVehicleTypeItemBase
		{
			string GetName() const override { return "Next VehicleType"; }
			Events::IEvent@ GetEvent() const override { return GetNextEvent(); }
			string GetActionName() const override { return Strings::GotoNext; }
		}

		namespace Strings
		{
			string GotoTime = Icons::LocationArrow + " Goto";
			string GotoPrev = Icons::ArrowLeft + " Previous";
			string GotoNext = "Next " + Icons::ArrowRight;
		}
		
		namespace Ctx
		{
			uint32 SelectedItem = 0;
			Route::FRoute@ Route;
			RouteSpectrum::ESpectrumType SpectrumType;
			bool bForceReselect = false;
		}
		array<FItemBase@> RowItems;
		void Init()
		{
			if (RowItems.IsEmpty())
			{
				RowItems.Reserve(14);
				RowItems.InsertLast(FDurationItem());
				RowItems.InsertLast(FCurrentSpeedItem());
				RowItems.InsertLast(FMaxSpeedItem());
				RowItems.InsertLast(FPrevGearItem());
				RowItems.InsertLast(FCurrentGearItem());
				RowItems.InsertLast(FNextGearItem());
				RowItems.InsertLast(FPrevVehicleTypeItem());
				RowItems.InsertLast(FCurrentVehicleTypeItem());
				RowItems.InsertLast(FNextVehicleTypeItem());
				RowItems.InsertLast(FCurrentPositionItem());
				RowItems.InsertLast(FCurrentAltitudeItem());
				RowItems.InsertLast(FMaxAltitudeItem());
				RowItems.InsertLast(FWheelsContactItem());
				RowItems.InsertLast(FCurrentAvgFPSItem());
				RowItems.InsertLast(FRecordedFramesItem());

				for(uint32 i = 0; i < RowItems.Length; i++) { RowItems[i].Idx = i; }
			}
		}

		void Draw()
		{
			Init();

			@Ctx::Route = RouteContainer::GetSelectedRoute();
			Ctx::SpectrumType = CurrentSpectrumType;
			if(UI::BeginTabItem("General", UI::TabItemFlags::NoReorder))
			{
				const vec2 contentRegion = UI::GetContentRegionAvail();

				const int32 tableFlags = UI::TableFlags::RowBg | UI::TableFlags::SizingStretchProp | UI::TableFlags::Resizable | UI::TableFlags::BordersInnerV | UI::TableFlags::ScrollY;
				if (UI::BeginTable("GeneralTabTable", 3, tableFlags, contentRegion))
				{
					int32 _sv = 0;
					_sv += PushStyleVar(UI::StyleVar::FramePadding, vec2(8., 0.));

					UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch, 0.25f);
					UI::TableSetupColumn("Value", UI::TableColumnFlags::WidthStretch, 0.5f);
					UI::TableSetupColumn("Action", UI::TableColumnFlags::WidthStretch, 0.25f);

					UI::ListClipper clipper(RowItems.Length);
					while(clipper.Step())
					{
						for (int32 i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
						{
							int32 __sv = 0; int32 __sc = 0;
							FItemBase@ item = RowItems[i];
							UI::PushID("GeneralRowItem" + i);

							UI::TableNextRow();
							UI::TableNextColumn();

							if (UI::Selectable(
								item.GetName() +
								// (item.GetSpectrum() != RouteSpectrum::ESpectrumType::None ? (" " + Icons::PaintBrush) : "") + 
								"##" + item.Idx, 
								Ctx::SelectedItem == item.Idx, UI::SelectableFlags::SpanAllColumns | UI::SelectableFlags::AllowOverlap))
							{
								item.Select();
							}
							else if (Ctx::SelectedItem == item.Idx)
							{
								// Triger OnSelect when bForceReselect is true
								if (Ctx::bForceReselect) { item.OnSelect(); }
								if (item.GetSpectrum() != RouteSpectrum::ESpectrumType::None)
								{
									Ctx::SpectrumType = item.GetSpectrum();
								}
							}
							RUtils::AddTooltipText(item.GetTooltip());
							if (item.GetSpectrum() != RouteSpectrum::ESpectrumType::None)
							{
								RUtils::AddTooltipText("Selecting this item shows its Spectrum Timeline.");
							}

							UI::TableNextColumn();

							if (item.GetSpectrum() != RouteSpectrum::ESpectrumType::None)
							{
								const vec4 spectrumColor = item.GetSpectrumColor();
								const vec3 contrastColor = ContrastColor::Get(spectrumColor.xyz);
								const vec4 tableBGColor = UI::GetStyleColor(UI::Col::TableRowBg);
								const vec3 tableConstrastColor = ContrastColor::Get(tableBGColor.xyz);

								if (bPreventBadSpectrumReadability && tableConstrastColor.x != contrastColor.x)
								{
									UI::Text(item.GetValue());
									UI::SameLine();
									UI::PushStyleColor(UI::Col::Text, spectrumColor);
									UI::Text(Icons::LightbulbO);
									RUtils::AddTooltipText("Item is not colored to prevent bad readability.");
									
									UI::PopStyleColor();
								}
								else
								{
									UI::PushStyleColor(UI::Col::Text, spectrumColor);
									UI::Text(item.GetValue());
									UI::SameLine();
									UI::Text(Icons::LightbulbO);
									UI::PopStyleColor();
								}
							}
							else 
							{
								UI::Text(item.GetValue());
							}

							UI::TableNextColumn();
							if (item.GetActionName().Length != 0)
							{
								__sv += PushStyleVarForced(UI::StyleVar::SelectableTextAlign, vec2(0.5, 0.5));
								__sc += PushStyleColor(UI::Col::Text, UI::GetStyleColor(UI::Col::ButtonActive));
								if (UI::Selectable(item.GetActionName(), false))
								{
									item.Select();
									item.RunAction();
								}
							}
							PopStyleColor(__sc);
							PopStyleVar(__sv);
							UI::PopID();
						}
					}
					PopStyleVar(_sv);
					UI::EndTable();
				}
				CurrentSpectrumType = RouteSpectrum::ESpectrumType::Default;
				UI::EndTabItem();
			}
			@Ctx::Route = null;
			CurrentSpectrumType = Ctx::SpectrumType;
			Ctx::bForceReselect = false;
		}

	}
}