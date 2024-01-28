namespace CameraExt
{
	vec2 DisplayPos;
	vec2 DisplaySize;
	vec2 ScaleToDisplay;

	void Tick()
	{
		auto camera = Camera::GetCurrent();
		if (camera is null) { return; }
		
		vec2 topLeft = 1 - (camera.DrawRectMax + 1) / 2;
		vec2 bottomRight = 1 - (camera.DrawRectMin + 1) / 2;
		DisplaySize = vec2(Draw::GetWidth(), Draw::GetHeight());
		DisplayPos = topLeft * DisplaySize;
		DisplaySize *= bottomRight - topLeft;
		ScaleToDisplay = 0.5 * DisplaySize;
	}
}