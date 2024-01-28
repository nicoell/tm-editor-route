namespace Events
{
	[Setting category="Display" name="Render Gear Events"]
	bool Setting_RenderGearEvents = true;

	class GearEvent : IEvent
	{
		int32 Gear;

		void Record() override
		{
			Gear = RecordCtx::Player.EngineCurGear;
			Color = vec3(0.3, 0.3, 0.3);
			RenderText = "" + Icons::Cog + "" + Gear;
		}

		bool ShouldRecordEntry(IEvent@ other) const override
		{
			auto otherTyped = cast<GearEvent>(other);
			return otherTyped is null || otherTyped.Gear != Gear;
		}

		// ---------------------------------------------------------------
		// CDO Only functions
		// ---------------------------------------------------------------
		string GetName() const override { return "Gear"; }
		bool CanEverRender() override { return true; }
		bool IsVisible() override { return Setting_RenderGearEvents; }
		void SetIsVisible(bool isVisible) override { Setting_RenderGearEvents = isVisible; }
	}
}
