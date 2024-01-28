namespace Events
{
	class WheelsContactEvent : IEvent
	{
		uint32 WheelsContactCount;
		void Record() override
		{
			WheelsContactCount = RecordCtx::Player.WheelsContactCount;
			RenderText = "" + Icons::Car + "" + WheelsContactCount;
		}

		bool ShouldRecordEntry(IEvent@ other) const override
		{
			auto otherTyped = cast<WheelsContactEvent>(other);
			return otherTyped is null || otherTyped.WheelsContactCount != WheelsContactCount;
		}
		string GetUITooltip() const override { return "Wheel Contact Count"; }


		// ---------------------------------------------------------------
		// CDO Only functions
		// ---------------------------------------------------------------
		string GetName() const override { return "#Wheels Contact"; }
		bool CanEverRender() override { return false; }
		bool IsVisible() override { return false; }
		void SetIsVisible(bool isVisible) override { }
	}
}