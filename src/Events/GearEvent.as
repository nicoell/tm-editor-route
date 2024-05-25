namespace Events
{
	class FGearEvent : IEvent
	{
		int32 Gear;

		void Record() override
		{
			Gear = RecordCtx::Player.EngineCurGear;
		}

		bool ShouldRecordEntry(IEvent@ other) const override
		{
			auto otherTyped = cast<FGearEvent>(other);
			return otherTyped is null || otherTyped.Gear != Gear;
		}

		string GetUIValue() const override { return Icons::Cog + Gear; }
		vec3 GetColor() const override { return vec3(0.3, 0.3, 0.3); }

		FArchive@ SaveArchive() override
		{
			FArchive@ ar = IEvent::SaveArchive();
			ar.Set('g', Gear);
			return ar;
		}

		void LoadArchive(FArchive &in ar) override
		{
			IEvent::LoadArchive(ar);
			Gear = ar.Get('g');
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
