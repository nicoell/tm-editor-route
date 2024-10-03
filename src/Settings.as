// Dict "SettingName" -> FSettingMeta
dictionary SettingsMetaDict;

class FMetaSetting
{
	Meta::PluginSetting@ Setting = null;
	float MinFloat = NumericLimits::FLT_LOWEST / 2;
	float MaxFloat = NumericLimits::FLT_MAX / 2;
	int32 MinInt = NumericLimits::INT32_MIN / 2;
	int32 MaxInt = NumericLimits::INT32_MAX / 2;
	uint32 MinUInt = 0;
	uint32 MaxUInt = NumericLimits::UINT32_MAX / 2;
	bool bIsDraggable = false;
	bool bIsSlider = false;
	bool bIsColor = false;
	bool bIsMultiLine = false;
	bool bIsPassword = false;

	FMetaSetting() {};

	// Bool constructor
	FMetaSetting(const string &in varName, bool defaultValue) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		SettingsMetaDict[varName] = this;
	}

	// Float constructor
	FMetaSetting(const string &in varName, float defaultValue, float minValue = NumericLimits::FLT_LOWEST / 2, float maxValue = NumericLimits::FLT_MAX / 2, bool draggable = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinFloat = minValue;
		MaxFloat = maxValue;
		bIsDraggable = draggable;
		bIsSlider = (minValue != NumericLimits::FLT_LOWEST / 2 && maxValue != NumericLimits::FLT_MAX / 2);
		SettingsMetaDict[varName] = this;
	}

	// Int8 constructor
	FMetaSetting(const string &in varName, int8 defaultValue, int8 minValue = NumericLimits::INT8_MIN / 2, int8 maxValue = NumericLimits::INT8_MAX / 2, bool draggable = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinInt = minValue;
		MaxInt = maxValue;
		bIsDraggable = draggable;
		bIsSlider = (minValue != NumericLimits::INT8_MIN / 2 && maxValue != NumericLimits::INT8_MAX / 2);
	   SettingsMetaDict[varName] = this;
	}

	// Int16 constructor
	FMetaSetting(const string &in varName, int16 defaultValue, int16 minValue = NumericLimits::INT16_MIN / 2, int16 maxValue = NumericLimits::INT16_MAX / 2, bool draggable = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinInt = minValue;
		MaxInt = maxValue;
		bIsDraggable = draggable;
		bIsSlider = (minValue != NumericLimits::INT16_MIN / 2 && maxValue != NumericLimits::INT16_MAX / 2);
		SettingsMetaDict[varName] = this;
	}

	// Int32 constructor
	FMetaSetting(const string &in varName, int32 defaultValue, int32 minValue = NumericLimits::INT32_MIN / 2, int32 maxValue = NumericLimits::INT32_MAX / 2, bool draggable = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinInt = minValue;
		MaxInt = maxValue;
		bIsDraggable = draggable;
		bIsSlider = (minValue != NumericLimits::INT32_MIN / 2 && maxValue != NumericLimits::INT32_MAX / 2);
		SettingsMetaDict[varName] = this;
	}

	// UInt8 constructor
	FMetaSetting(const string &in varName, uint8 defaultValue, uint8 minValue = NumericLimits::UINT8_MIN / 2, uint8 maxValue = NumericLimits::UINT8_MAX / 2, bool draggable = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinUInt = minValue;
		MaxUInt = maxValue;
		bIsDraggable = draggable;
		bIsSlider = (minValue != NumericLimits::UINT16_MIN / 2 && maxValue != NumericLimits::UINT16_MAX / 2);
		SettingsMetaDict[varName] = this;
	}

	// UInt16 constructor
	FMetaSetting(const string &in varName, uint16 defaultValue, uint16 minValue = NumericLimits::UINT16_MIN / 2, uint16 maxValue = NumericLimits::UINT16_MAX / 2, bool draggable = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinUInt = minValue;
		MaxUInt = maxValue;
		bIsDraggable = draggable;
		bIsSlider = (minValue != NumericLimits::UINT32_MIN / 2 && maxValue != NumericLimits::UINT32_MAX / 2);
		SettingsMetaDict[varName] = this;
	}

	// UInt32 constructor
	FMetaSetting(const string &in varName, uint32 defaultValue, uint32 minValue = NumericLimits::UINT32_MIN / 2, uint32 maxValue = NumericLimits::UINT32_MAX / 2, bool draggable = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinUInt = minValue;
		MaxUInt = maxValue;
		bIsDraggable = draggable;
		SettingsMetaDict[varName] = this;
	}

	// Vec2 constructor
	FMetaSetting(const string &in varName, vec2 defaultValue, float minValue = NumericLimits::FLT_LOWEST / 2, float maxValue = NumericLimits::FLT_MAX / 2, bool draggable = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinFloat = minValue;
		MaxFloat = maxValue;
		bIsDraggable = draggable;
		SettingsMetaDict[varName] = this;
	}

	// Vec3 constructor
	FMetaSetting(const string &in varName, vec3 defaultValue, float minValue = NumericLimits::FLT_LOWEST / 2, float maxValue = NumericLimits::FLT_MAX / 2, bool draggable = false, bool color = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinFloat = minValue;
		MaxFloat = maxValue;
		bIsDraggable = draggable;
		bIsColor = color;
		SettingsMetaDict[varName] = this;
	}

	// Vec4 constructor
	FMetaSetting(const string &in varName, vec4 defaultValue, float minValue = NumericLimits::FLT_LOWEST / 2, float maxValue = NumericLimits::FLT_MAX / 2, bool draggable = false, bool color = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MinFloat = minValue;
		MaxFloat = maxValue;
		bIsDraggable = draggable;
		bIsColor = color;
		SettingsMetaDict[varName] = this;
	}

	// String constructor
	FMetaSetting(const string &in varName, const string &in defaultValue, int32 maxLength = -1, bool multiline = false, bool password = false) {
		@Setting = Meta::ExecutingPlugin().GetSetting(varName);

		MaxInt = maxLength;
		bIsMultiLine = multiline;
		bIsPassword = password;
		SettingsMetaDict[varName] = this;
	}

	string get_Name() const property { return Setting.Name; }
	string get_Description() const property { return Setting.Description; }
	string get_Category() const property { return Setting.Category; }
	string get_VarName() const property { return Setting.VarName; }
	Meta::PluginSettingType get_Type() const property { return Setting.Type; }
	bool get_bIsVisible() const property { return Setting.Visible; }
}

// ---------------------------------------------------------------

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

#define DEFINE_SETTING_VAR(_category, _name, _description, _type, _settingName, _defaultValue) \
	[Setting category=_category name=_name description=_description] \
	_type _settingName = _defaultValue;

#define DEFINE_SETTING_VAR_MIN_MAX(_category, _name, _description, _type, _settingName, _defaultValue, _minValue, _maxValue) \
	[Setting category=_category name=_name description=_description min=_minValue max=_maxValue] \
	_type _settingName = _defaultValue;

#define DEFINE_SETTING_VAR_MIN_MAX_DRAG(_category, _name, _description, _type, _settingName, _defaultValue, _minValue, _maxValue) \
	[Setting category=_category name=_name description=_description min=_minValue max=_maxValue drag] \
	_type _settingName = _defaultValue;

#define DEFINE_SETTING_VAR_MIN_MAX_COLOR(_category, _name, _description, _type, _settingName, _defaultValue, _minValue, _maxValue) \
	[Setting category=_category name=_name description=_description min=_minValue max=_maxValue color] \
	_type _settingName = _defaultValue;

#define DEFINE_SETTING_VAR_MULTILINE(_category, _name, _description, _type, _settingName, _defaultValue) \
	[Setting category=_category name=_name description=_description multiline] \
	_type _settingName = _defaultValue;

#define DEFINE_SETTING_VAR_PASSWORD(_category, _name, _description, _type, _settingName, _defaultValue) \
	[Setting category=_category name=_name description=_description password] \
	_type _settingName = _defaultValue;

#define DEFINE_SETTING(category, name, description, type, settingName, defaultValue) \
	DEFINE_SETTING_VAR(category, name, description, type, settingName, defaultValue) \
	FMetaSetting settingMeta_##settingName = FMetaSetting(TOSTRING(settingName), defaultValue);

#define DEFINE_SETTING_WITH_MIN_MAX(category, name, description, type, settingName, defaultValue, minValue, maxValue) \
	DEFINE_SETTING_VAR_MIN_MAX(category, name, description, type, settingName, defaultValue, minValue, maxValue) \
	FMetaSetting settingMeta_##settingName = FMetaSetting(TOSTRING(settingName), defaultValue, minValue, maxValue);

#define DEFINE_SETTING_WITH_MIN_MAX_DRAG(category, name, description, type, settingName, defaultValue, minValue, maxValue) \
	DEFINE_SETTING_VAR_MIN_MAX_DRAG(category, name, description, type, settingName, defaultValue, minValue, maxValue) \
	FMetaSetting settingMeta_##settingName = FMetaSetting(TOSTRING(settingName), defaultValue, minValue, maxValue, true);

#define DEFINE_SETTING_WITH_MIN_MAX_COLOR(category, name, description, type, settingName, defaultValue, minValue, maxValue) \
	DEFINE_SETTING_VAR_MIN_MAX_COLOR(category, name, description, type, settingName, defaultValue, minValue, maxValue) \
	FMetaSetting settingMeta_##settingName = FMetaSetting(TOSTRING(settingName), defaultValue, minValue, maxValue, false, true);

#define DEFINE_SETTING_MULTILINE(category, name, description, type, settingName, defaultValue) \
	DEFINE_SETTING_VAR_MULTILINE(category, name, description, type, settingName, defaultValue) \
	FMetaSetting settingMeta_##settingName = FMetaSetting(TOSTRING(settingName), defaultValue, -1, true, false);

#define DEFINE_SETTING_PASSWORD(category, name, description, type, settingName, defaultValue) \
	DEFINE_SETTING_VAR_PASSWORD(category, name, description, type, settingName, defaultValue) \
	FMetaSetting settingMeta_##settingName = FMetaSetting(TOSTRING(settingName), defaultValue, -1, false, true);

DEFINE_SETTING_WITH_MIN_MAX("Recorder", "Time Step (ms)", "Upon exceeding this threshold a new sample will be recorded. If the car is moving slowly, the Time Step is the main condition that leads to samples being recorded.", int32, Setting_Recorder_TimeStep, 500, 50, 10000)
DEFINE_SETTING_WITH_MIN_MAX("Recorder", "Position Step (m)", "Upon exceeding this threshold a new sample will be recorded. If the car is moving fast,the Position Step is the main condition that leads to samples being recorded..", float, Setting_Recorder_PositionStep, 1.0, 0.0, 100.0)
DEFINE_SETTING("Recorder", "Clear trails on Play", "Clear trails when entering Test Mode / Track Validation.", bool, Setting_Recorder_ClearTrailsOnPlay, true)

DEFINE_SETTING("Display", "Spectrum Palette", "Changes the colors of Spectrum used to color code the Stats and the Time Control.", RouteSpectrum::ESpectrumPalette, RequestedPalette, RouteSpectrum::ESpectrumPalette::Spectrum)

DEFINE_SETTING("Display", "Show Selected Only", "Show only the selected Editor Route.", bool, Setting_RenderSelectedOnly, false)

DEFINE_SETTING_WITH_MIN_MAX_COLOR("Display", "Route Color", "Line-Color unselected Editor Routes.", vec3, Setting_RouteColor, vec3(0.9, 0.9, 0.9), 0.0, 1.0)
DEFINE_SETTING_WITH_MIN_MAX_COLOR("Display", "Selected Route Color", "Line-Color selected Editor Routes.", vec3, Setting_SelectedRouteColor, vec3(0.2, 1, 0.3), 0.0, 1.0)
DEFINE_SETTING_WITH_MIN_MAX_DRAG("Display", "Route line width", "Width of the route line.", float, Setting_RouteLineWidth, 1.0, 1.0, 10.0)

DEFINE_SETTING_WITH_MIN_MAX("Display", "Elapsed Route Opacity", "Line-Color Opacity before the current time.", float, Setting_ElapsedRouteOpacityModifier, 0.25, 0.0, 1.0)

DEFINE_SETTING("Display", "Show Car Box", "Show the Car box..", bool, Setting_RenderCarBox, true)
DEFINE_SETTING_WITH_MIN_MAX_COLOR("Display", "Car Box color", "Color of the car box.", vec4, Setting_CarBoxColor, vec4(0.9f, 0.3f, 0.7f, 0.8), 0.0, 1.0)
DEFINE_SETTING_WITH_MIN_MAX_DRAG("Display", "Box line width", "Width of the box line.", float, Setting_BoxWidth, 1.0, 1.0, 10.0)
DEFINE_SETTING_WITH_MIN_MAX_DRAG("Display", "Event scale", "Scale of the event.", float, Setting_EventScale, 1.0f, 0.4, 2.0)

DEFINE_SETTING("Display", "Show Rotation Gizmo", "Show the Rotation Gizmo.", bool, Setting_RenderGizmo, true)
DEFINE_SETTING_WITH_MIN_MAX_DRAG("Display", "Gizmo line width", "Width of the gizmo line.", float, Setting_GizmoWidth, 2.0, 1.0, 10.0)
DEFINE_SETTING_WITH_MIN_MAX_DRAG("Display", "Gizmo scale", "Scale of the gizmo.", float, Setting_GizmoScale, 2.5f, 1.0, 10.0)


DEFINE_SETTING("Display", "Render Gear Events", "Render gear events.", bool, Setting_RenderGearEvents, true)
DEFINE_SETTING("Display", "Render VehicleType Events", "Render vehicle type events.", bool, Setting_RenderVehicleTypeEvents, true)
DEFINE_SETTING_WITH_MIN_MAX("Display", "Elapsed Event Opacity", "Opacity of events before the current time", float, Setting_ElapsedEventOpacityModifier, 0.25, 0.0, 1.0)

DEFINE_SETTING("Interface", "Enable Editor Route Style", "Whether to use the custom Editor Route UI Style or the default Style.", bool, bEnableEditorRouteStyle, true)
DEFINE_SETTING("Interface", "Disable unreadable detail colors", "Disables coloring of Stats in the UI when the text color is hard to read on the background.", bool, bPreventBadSpectrumReadability, true)

DEFINE_SETTING("Blender Integration", "POST URL", "The full URL (including port) that the Editor Route will be POSTed to.", string, Setting_UploadEditorRouteURL, "http://localhost:42069/trails")

DEFINE_SETTING("Experimental", "Enable 3D-Lines", "(Requires Editor++ Plugin) Render Lines as 3D-Lines in the World with depth-testing. Does not support different Line Widths and detailed Line Colors.", bool, Setting_Enable3DLines, false)
