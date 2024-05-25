namespace InputHandler
{
	bool bIsShiftKeyPressed = false;
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) 
{
	if (key == VirtualKey::Shift && InputHandler::bIsShiftKeyPressed != down)
	{
		InputHandler::bIsShiftKeyPressed = down;
	}

	return UI::InputBlocking::DoNothing;
}