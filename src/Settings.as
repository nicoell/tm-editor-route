[Setting category="Display" name="Route Color" color]
vec3 Setting_RouteColor = vec3(0.9, 0.9, 0.9);

[Setting category="Display" name="Selected Route Color" color]
vec3 Setting_SelectedRouteColor = vec3(0.2, 1, 0.3);

[Setting category="Display" name="Elapsed Route Opacity Modifier"]
float Setting_ElapsedRouteOpacityModifier = 0.25;

[Setting category="Display" name="Elapsed Route Width Modifier"]
float Setting_ElapsedRouteWidthModifier = 0.25;

[Setting category="Display" name="Elapsed Event Opacity Modifier"]
float Setting_ElapsedEventOpacityModifier = 0.25;

[Setting category="Display" name="Car Box color" color]
vec4 Setting_CarBoxColor = vec4(.9f, .3f, .7f, 0.8);

[Setting category="Display" name="Render Gizmo"]
bool Setting_RenderGizmo = true;

[Setting category="Display" name="Render Car Box"]
bool Setting_RenderCarBox = true;

[Setting category="Display" name="Render Selected Only"]
bool Setting_RenderSelectedOnly = false;

[Setting category="Display" name="Route line width" min=1.0 max=10.0]
float Setting_RouteLineWidth = 1;

[Setting category="Display" name="Box line width" min=1.0 max=10.0]
float Setting_BoxWidth = 1;

[Setting category="Display" name="Gizmo line width" min=1.0 max=10.0]
float Setting_GizmoWidth = 2;

[Setting category="Display" name="Gizmo scale" min=1.0 max=10.0]
float Setting_GizmoScale = 2.5f;

[Setting category="Display" name="Event scale" min=0.4 max=2.0]
float Setting_EventScale = 1.0f;



[Setting category="Interface" name="Enable Editor Route Style"]
bool bEnableEditorRouteStyle = true;

[Setting category="Interface" name="Spectrum Palette"]
RouteSpectrum::ESpectrumPalette RequestedPalette = RouteSpectrum::ESpectrumPalette::Spectrum;

[Setting category="Interface" name="Disable unreadable detail colors"]
bool bPreventBadSpectrumReadability = true;
