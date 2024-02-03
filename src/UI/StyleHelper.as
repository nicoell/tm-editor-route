namespace EditorRouteUI
{

	int32 PushStyleColor(UI::Col idx, const vec4&in col, bool bAlwaysOn = false) 
	{
		if (bEnableEditorRouteStyle || bAlwaysOn) { UI::PushStyleColor(idx, col); return 1; }
		return 0;
	}
	int32 PushStyleColorForced(UI::Col idx, const vec4&in col) { return PushStyleColor(idx, col, true); }

	int32 PushStyleVar(UI::StyleVar var, float value, bool bAlwaysOn = false)
	{
		if (bEnableEditorRouteStyle || bAlwaysOn) { UI::PushStyleVar(var, value); return 1; }
		return 0;
	}
	int32 PushStyleVarForced(UI::StyleVar var, float value) { return PushStyleVar(var, value, true); }

	int32 PushStyleVar(UI::StyleVar var, const vec2&in value, bool bAlwaysOn = false)
	{
		if (bEnableEditorRouteStyle || bAlwaysOn) { UI::PushStyleVar(var, value); return 1; }
		return 0;
	}
	int32 PushStyleVarForced(UI::StyleVar var, const vec2&in value) { return PushStyleVar(var, value, true); }

	void PopStyleColor(int count = 1) { if (count > 0) { UI::PopStyleColor(count); }}
	void PopStyleVar(int count = 1) { if (count > 0) { UI::PopStyleVar(count); }}
}