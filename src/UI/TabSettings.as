namespace EditorRouteUI
{
	// ---------------------------------------------------------------
	// Display Tab
	// ---------------------------------------------------------------
	namespace TabSettings
	{
		class FItemBase
		{
			uint32 Idx;
			Meta::PluginSetting@ Setting = null;
			string GetCategory() const { return ""; };
			string GetName() const { return "FItemBase"; };
			string GetDescription() const { return ""; };
			string GetLabel() const { return GetName() + "##" + Idx; }

			void DrawWidget() 
			{
				UpdateValue();

				if (DrawColorWidget()) {}
				else if (DrawComboWidget()) {}
				else if (DrawSliderWidget()) {}
				else { DrawInputWidget(); }
			
				ClampValue();

				if (GetDescription().Length > 0)
				{
					UI::SameLine();
					RUtils::HelpMarker(GetDescription());
				}

				CompareValueChanged();

				if (bHasChanged) 
				{
					bHasChanged = false;
					OnValueChanged(); 
				}
			}

			bool bHasChanged = false;

			bool bShouldClampMin = true;
			bool bShouldClampMax = true;
			bool bIsSlider = true;
			bool bIsColor = true;
			bool bIsCombo = true;
			bool bIsMultiLine = false;
			bool bIsPassword = false;

			void ClampValue() {}

			bool IsValid() const { return true; }
			bool DrawComboWidget() { return false; }
			bool DrawSliderWidget() { return false; }
			bool DrawColorWidget() { return false; }
			bool DrawInputWidget() { return false; }
			void CompareValueChanged() { }
			void OnValueChanged() {}
			void InitValue() {}
			void UpdateValue() {}
		}

		mixin class _ValueClamp
		{
			private int32 ClampValueMin(int32 _value, int _minValue) { return Math::Max(_value, _minValue); }
			private float ClampValueMin(float _value, float _minValue) { return Math::Max(_value, _minValue); }
			private double ClampValueMin(double _value, double _minValue) { return _value < _minValue ? _minValue : _value; }
			private vec2 ClampValueMin(vec2 &in _value, float _minValue) { return vec2(Math::Max(_value.x, _minValue), Math::Max(_value.y, _minValue)); }
			private vec3 ClampValueMin(vec3 &in _value, float _minValue) { return vec3(Math::Max(_value.x, _minValue), Math::Max(_value.y, _minValue), Math::Max(_value.z, _minValue)); }
			private vec4 ClampValueMin(vec4 &in _value, float _minValue) { return vec4(Math::Max(_value.x, _minValue), Math::Max(_value.y, _minValue), Math::Max(_value.z, _minValue), Math::Max(_value.w, _minValue)); }

			private int32 ClampValueMax(int32 _value, int32 _maxValue) { return Math::Min(_value, _maxValue); }
			private float ClampValueMax(float _value, float _maxValue) { return Math::Min(_value, _maxValue); }
			private double ClampValueMax(double _value, double _maxValue) { return _value > _maxValue ? _maxValue : _value; }
			private vec2 ClampValueMax(vec2 &in _value, float _maxValue) { return vec2(Math::Min(_value.x, _maxValue), Math::Min(_value.y, _maxValue)); }
			private vec3 ClampValueMax(vec3 &in _value, float _maxValue) { return vec3(Math::Min(_value.x, _maxValue), Math::Min(_value.y, _maxValue), Math::Max(_value.z, _maxValue)); }
			private vec4 ClampValueMax(vec4 &in _value, float _maxValue) { return vec4(Math::Min(_value.x, _maxValue), Math::Min(_value.y, _maxValue), Math::Max(_value.z, _maxValue), Math::Max(_value.w, _maxValue)); }
			void ClampValue() override
			{
				if (bShouldClampMin) { Value = ClampValueMin(Value, MinValue); }
				if (bShouldClampMax) { Value = ClampValueMax(Value, MaxValue); }
			}
		}

		mixin class _SliderWidget
		{
			private int DrawSliderWidget(int _value, int _minValue, int _maxValue) { return UI::SliderInt(GetLabel(), _value, _minValue, _maxValue); }
			private float DrawSliderWidget(float _value, float _minValue, float _maxValue) { return UI::SliderFloat(GetLabel(), _value, _minValue, _maxValue); }
			private double DrawSliderWidget(double _value, double _minValue, double _maxValue) { return UI::SliderDouble(GetLabel(), _value, _minValue, _maxValue); }
			private vec2 DrawSliderWidget(vec2 &in _value, float _minValue, float _maxValue) { return UI::SliderFloat2(GetLabel(), _value, _minValue, _maxValue); }
			private vec3 DrawSliderWidget(vec3 &in _value, float _minValue, float _maxValue) { return UI::SliderFloat3(GetLabel(), _value, _minValue, _maxValue); }
			private vec4 DrawSliderWidget(vec4 &in _value, float _minValue, float _maxValue) { return UI::SliderFloat4(GetLabel(), _value, _minValue, _maxValue); }

			bool DrawSliderWidget() override 
			{ 
				if (bIsSlider) 
				{
					int32 sc = 0;
					sc += PushStyleColorForced(UI::Col::SliderGrab, DefaultSliderGrab);
					sc += PushStyleColorForced(UI::Col::SliderGrabActive, DefaultSliderGrabActive);
					Value = DrawSliderWidget(Value, MinValue, MaxValue);
					PopStyleColor(sc);
				} 
				return bIsSlider; 
			}
		}
		mixin class _InputWidget
		{
			private int DrawInputWidget(int _value) { return UI::InputInt(GetLabel(), _value); }
			private float DrawInputWidget(float _value) { return UI::InputFloat(GetLabel(), _value); }
			private vec2 DrawInputWidget(vec2 &in _value) { return UI::InputFloat2(GetLabel(), _value); }
			private vec3 DrawInputWidget(vec3 &in _value) { return UI::InputFloat3(GetLabel(), _value); }
			private vec4 DrawInputWidget(vec4 &in _value) { return UI::InputFloat4(GetLabel(), _value); }
			private string DrawInputWidget(string &in _value) { return UI::InputText(GetLabel(), _value, bHasChanged); }
			private bool DrawInputWidget(bool _value) 
			{
				int32 sc = 0; int32 sv = 0;
				sv += PushStyleVarForced(UI::StyleVar::FramePadding, vec2(0, 0));
				sc += PushStyleColor(UI::Col::FrameBg, vec4(89., 239., 134., 32.)/255.);
				sc += PushStyleColor(UI::Col::FrameBgHovered, vec4(89., 239., 134., 64.)/255.);
				sc += PushStyleColor(UI::Col::FrameBgActive, vec4(89., 239., 134., 96.)/255.);
				bool newVal = UI::Checkbox(GetLabel(), _value);
				PopStyleColor(sc);
				PopStyleVar(sv);
				return newVal;
			}

			bool DrawInputWidget() override { Value = DrawInputWidget(Value); return true; }
		}
		mixin class _ColorWidget
		{
			private vec3 DrawColorWidget(vec3 &in _value) { return UI::InputColor3(GetLabel(), _value); }
			private vec4 DrawColorWidget(vec4 &in _value) { return UI::InputColor4(GetLabel(), _value); }

			bool DrawColorWidget() override { if (bIsColor) { Value = DrawColorWidget(Value); } return bIsColor; }
		}

		mixin class _ComboWidget
		{
			bool DrawComboWidget() override
			{
				if (bIsCombo)
				{
					if (UI::BeginCombo(GetLabel(), ValueStrings[Value]))
					{
						for(int32 i = 0; i < int32(ValueStrings.Length) && i < MaxValue; i++)
						{
							const bool bIsSelected = Value == i;
							if (UI::Selectable(ValueStrings[i], bIsSelected))
							{
								Value = i;
							}
							if (bIsSelected) { UI::SetItemDefaultFocus(); }
						}
						UI::EndCombo();
					}
				}
				return bIsCombo;
			}
		}

		mixin class _ValueChangedCompare
		{
			void CompareValueChanged() override { bHasChanged = PrevValue != Value; PrevValue = Value; }
		}

		mixin class _ValueBool
		{
			bool Value; bool PrevValue;

			void UpdateValue() override { if (Setting !is null) { Value = Setting.ReadBool(); } }
			void OnValueChanged() override { if (Setting !is null) { Setting.WriteBool(Value); } }
		}
		mixin class _ValueInt
		{
			int32 Value; int32 PrevValue;
			int32 MinValue = NumericLimits::INT32_MIN / 2;
			int32 MaxValue = NumericLimits::INT32_MAX / 2;

			void InitValue() override 
			{
				FMetaSetting@ metaSetting = cast<FMetaSetting@>(SettingsMetaDict[Setting.VarName]);
				MinValue = metaSetting.MinInt;
				MaxValue = metaSetting.MaxInt;
				bIsSlider = metaSetting.bIsSlider;
			}
			void UpdateValue() override { if (Setting !is null) { Value = Setting.ReadInt32(); } }
			void OnValueChanged() override { if (Setting !is null) { Setting.WriteInt32(Value); } }
		}
		mixin class _ValueEnum
		{
			array<string>@ ValueStrings; // Only supports continous enums starting at 0 :)
			int32 Value; int32 PrevValue;
			int32 MinValue = NumericLimits::INT32_MIN / 2;
			int32 MaxValue = NumericLimits::INT32_MAX / 2;

			void InitValue() override 
			{
				FMetaSetting@ metaSetting = cast<FMetaSetting@>(SettingsMetaDict[Setting.VarName]);
				MinValue = metaSetting.MinInt;
				MaxValue = metaSetting.MaxInt;
				bIsSlider = metaSetting.bIsSlider;
			}
			void UpdateValue() override { if (Setting !is null) { Value = Setting.ReadEnum(); } }
			void OnValueChanged() override { if (Setting !is null) { Setting.WriteEnum(Value); } }
		}
		mixin class _ValueFloat
		{
			float Value; float PrevValue;
			float MinValue = NumericLimits::FLT_LOWEST / 2;
			float MaxValue = NumericLimits::FLT_MAX / 2;
			
			void InitValue() override 
			{
				FMetaSetting@ metaSetting = cast<FMetaSetting@>(SettingsMetaDict[Setting.VarName]);
				MinValue = metaSetting.MinFloat;
				MaxValue = metaSetting.MaxFloat;
				bIsSlider = metaSetting.bIsSlider;
			}
			void UpdateValue() override { if (Setting !is null) { Value = Setting.ReadFloat(); } }
			void OnValueChanged() override { if (Setting !is null) { Setting.WriteFloat(Value); } }
		}

		mixin class _ValueVec2
		{
			vec2 Value; vec2 PrevValue;
			float MinValue = NumericLimits::FLT_LOWEST / 2;
			float MaxValue = NumericLimits::FLT_MAX / 2;

			void InitValue() override 
			{
				FMetaSetting@ metaSetting = cast<FMetaSetting@>(SettingsMetaDict[Setting.VarName]);
				MinValue = metaSetting.MinFloat;
				MaxValue = metaSetting.MaxFloat;
			}
			void UpdateValue() override { if (Setting !is null) { Value = Setting.ReadVec2(); } }
			void OnValueChanged() override { if (Setting !is null) { Setting.WriteVec2(Value); } }
		}
		mixin class _ValueVec3
		{
			vec3 Value; vec3 PrevValue;
			float MinValue = NumericLimits::FLT_LOWEST / 2;
			float MaxValue = NumericLimits::FLT_MAX / 2;

			void InitValue() override 
			{
				FMetaSetting@ metaSetting = cast<FMetaSetting@>(SettingsMetaDict[Setting.VarName]);
				MinValue = metaSetting.MinFloat;
				MaxValue = metaSetting.MaxFloat;
				bIsColor = metaSetting.bIsColor;
			}
			void UpdateValue() override { if (Setting !is null) { Value = Setting.ReadVec3(); } }
			void OnValueChanged() override { if (Setting !is null) { Setting.WriteVec3(Value); } }
		}
		mixin class _ValueVec4
		{
			vec4 Value; vec4 PrevValue;
			float MinValue = NumericLimits::FLT_LOWEST / 2;
			float MaxValue = NumericLimits::FLT_MAX / 2;

			void InitValue() override 
			{
				FMetaSetting@ metaSetting = cast<FMetaSetting@>(SettingsMetaDict[Setting.VarName]);
				MinValue = metaSetting.MinFloat;
				MaxValue = metaSetting.MaxFloat;
				bIsColor = metaSetting.bIsColor;
			}
			void UpdateValue() override { if (Setting !is null) { Value = Setting.ReadVec4(); } }
			void OnValueChanged() override { if (Setting !is null) { Setting.WriteVec4(Value); } }
		}
		mixin class _ValueString
		{
			string Value;
			int32 MaxLength = NumericLimits::INT32_MAX;

			void InitValue() override 
			{
				FMetaSetting@ metaSetting = cast<FMetaSetting@>(SettingsMetaDict[Setting.VarName]);
				MaxLength = metaSetting.MaxInt;
			}
			void UpdateValue() override { if (Setting !is null) { Value = Setting.ReadString(); } }
			void OnValueChanged() override { if (Setting !is null) { Setting.WriteString(Value); } }
		}

		class FItemBoolBase : FItemBase, _ValueBool, _InputWidget, _ValueChangedCompare {}
		class FItemInt32Base : FItemBase, _ValueInt, _SliderWidget, _InputWidget, _ValueClamp, _ValueChangedCompare {}
		class FItemFloatBase : FItemBase, _ValueFloat, _SliderWidget, _InputWidget, _ValueClamp, _ValueChangedCompare {}
		class FItemVec2Base : FItemBase, _ValueVec2, _SliderWidget, _InputWidget, _ValueClamp, _ValueChangedCompare {}
		class FItemVec3Base : FItemBase, _ValueVec3, _SliderWidget, _InputWidget, _ColorWidget, _ValueClamp, _ValueChangedCompare {}
		class FItemVec4Base : FItemBase, _ValueVec4, _SliderWidget, _InputWidget, _ColorWidget, _ValueClamp, _ValueChangedCompare {}
		class FItemStringBase : FItemBase, _ValueString, _InputWidget {}
		class FItemEnumBase : FItemBase, _ValueEnum, _InputWidget, _ComboWidget, _ValueClamp, _ValueChangedCompare {}

		mixin class _PluginSetting
		{
			bool IsValid() const override { return Setting !is null; }
			string GetName() const override { return Setting.Name; }
			string GetCategory() const override { return Setting.Category; }
			string GetDescription() const override { return Setting.Description; }

			void InitSettings(Meta::PluginSetting@ s) 
			{
				@Setting = s;

				InitValue();
			}
		}

		class FRenderEventCheckBoxItem : FItemBoolBase
		{
			Events::EventType EventType;
			string GetCategory() const override { return "Events"; };
			string GetName() const override { return "Display " + Events::GetCDO(EventType).GetName() + " Events"; };
			FRenderEventCheckBoxItem(int32 typeIdx) 
			{ 
				EventType = Events::EventType(typeIdx);
				Value = Events::IsVisible(EventType);
			}
			void OnValueChanged() override { Events::SetIsVisible(EventType, Value); }
		}

		class FItemSettingBool : FItemBoolBase, _PluginSetting { FItemSettingBool(Meta::PluginSetting@ s) { InitSettings(s); } }
		class FItemSettingInt32 : FItemInt32Base, _PluginSetting { FItemSettingInt32(Meta::PluginSetting@ s) { InitSettings(s); } }
		class FItemSettingFloat : FItemFloatBase, _PluginSetting { FItemSettingFloat(Meta::PluginSetting@ s) { InitSettings(s); } }
		class FItemSettingVec2 : FItemVec2Base, _PluginSetting { FItemSettingVec2(Meta::PluginSetting@ s) { InitSettings(s); } }
		class FItemSettingVec3 : FItemVec3Base, _PluginSetting { FItemSettingVec3(Meta::PluginSetting@ s) { InitSettings(s); } }
		class FItemSettingVec4 : FItemVec4Base, _PluginSetting { FItemSettingVec4(Meta::PluginSetting@ s) { InitSettings(s); } }
		class FItemSettingString : FItemStringBase, _PluginSetting { FItemSettingString(Meta::PluginSetting@ s) { InitSettings(s); } }
		class FItemSettingEnum : FItemEnumBase, _PluginSetting { FItemSettingEnum(Meta::PluginSetting@ s) { InitSettings(s); } }

		class FItemSettingSpectrumPalette : FItemSettingEnum
		{
			FItemSettingSpectrumPalette(Meta::PluginSetting@ s) 
			{ 
				super(s);
				@ValueStrings = RouteSpectrum::SpectrumPaletteNames;
			}
			void InitValue() override 
			{
				FMetaSetting@ metaSetting = cast<FMetaSetting@>(SettingsMetaDict[Setting.VarName]);
				MinValue = 0;
				MaxValue = RouteSpectrum::SpectrumPaletteNames.Length;
				bIsSlider = metaSetting.bIsSlider;
			}
		}

		dictionary ItemsByCategory;
		array<string> Categories;
		bool bIsInitialized = false;

		void Init()
		{
			if (!bIsInitialized)
			{
				ItemsByCategory.DeleteAll();
				Categories.RemoveRange(0, Categories.Length);

				auto settings = Meta::ExecutingPlugin().GetSettings();
				for(uint32 i = 0; i < settings.Length; i++)
				{
					auto@ setting = settings[i];
					if (!setting.Visible) { continue; }

					switch (setting.Type)
					{
						case Meta::PluginSettingType::Bool: AddItemToCategory(FItemSettingBool(setting)); break;
						case Meta::PluginSettingType::Int32: AddItemToCategory(FItemSettingInt32(setting)); break;
						case Meta::PluginSettingType::Float: AddItemToCategory(FItemSettingFloat(setting)); break;
						case Meta::PluginSettingType::Vec2: AddItemToCategory(FItemSettingVec2(setting)); break;
						case Meta::PluginSettingType::Vec3: AddItemToCategory(FItemSettingVec3(setting)); break;
						case Meta::PluginSettingType::Vec4: AddItemToCategory(FItemSettingVec4(setting)); break;
						case Meta::PluginSettingType::String: AddItemToCategory(FItemSettingString(setting)); break;
						case Meta::PluginSettingType::Enum:
						{
							if (setting.TypeName == "ESpectrumPalette")
							{
								AddItemToCategory(FItemSettingSpectrumPalette(setting));
							}
							break;
						}
					}
				}

#if ER_DEBUG
				auto keys = SettingsMetaDict.GetKeys();
				for(uint32 i = 0; i < keys.Length; i++)
				{
					trace(keys[i]);
				}
#endif

				Categories = ItemsByCategory.GetKeys();
				bIsInitialized = true;
			}
		}

		void AddItemToCategory(FItemBase@ item)
		{
			if (!ItemsByCategory.Exists(item.GetCategory()))
			{
				array<FItemBase@> items;
				ItemsByCategory.Set(item.GetCategory(), items);
			}
			array<FItemBase@>@ items;
			ItemsByCategory.Get(item.GetCategory(), @items);
			
			items.InsertLast(item);
		}

		void Draw()
		{
			if(UI::BeginTabItem(Icons::Cog, UI::TabItemFlags::NoReorder))
			{
				Init();

				const vec2 contentRegion = UI::GetContentRegionAvail();

				const int32 tableFlags = UI::TableFlags::RowBg | UI::TableFlags::SizingStretchProp | UI::TableFlags::Resizable | UI::TableFlags::BordersInnerV | UI::TableFlags::ScrollY;
				if (UI::BeginTable("DisplayTabTable", 1, tableFlags, contentRegion))
				{
					int32 _sv = 0;
					_sv += PushStyleVar(UI::StyleVar::FramePadding, vec2(8., 0.));

					UI::TableSetupColumn("Entry");

					UI::TableNextRow();
					UI::TableNextColumn();

					for (uint32 i = 0; i < Categories.Length; i++)
					{
						string category = Categories[i];

						if (UI::TreeNode(category, UI::TreeNodeFlags::Framed | UI::TreeNodeFlags::SpanFullWidth | UI::TreeNodeFlags::DefaultOpen))
						{
							array<FItemBase@>@ items;
							ItemsByCategory.Get(category, @items);
							
							for (uint32 j = 0; j < items.Length; j++)
							{
								FItemBase@ item = items[j];
								UI::PushID(category + "DisplayRowItem" + j);

								UI::TableNextRow();
								UI::TableNextColumn();
								
								item.DrawWidget();
								
								UI::PopID();
							}
							UI::TreePop();
						}
					}
					PopStyleVar(_sv);
					UI::EndTable();
				}
				UI::EndTabItem();
			}
		}
	}
}