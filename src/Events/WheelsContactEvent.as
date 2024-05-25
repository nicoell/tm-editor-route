namespace Events
{
	class FWheelsContactEvent : IEvent
	{
		uint32 WheelsContactCount;
		void Record() override
		{
			WheelsContactCount = RecordCtx::Player.WheelsContactCount;
		}

		bool ShouldRecordEntry(IEvent@ other) const override
		{
			auto otherTyped = cast<FWheelsContactEvent>(other);
			return otherTyped is null || otherTyped.WheelsContactCount != WheelsContactCount;
		}
		string GetUITooltip() const override { return "Wheel Contact Count"; }
		string GetUIValue() const override { return Icons::Car + WheelsContactCount; }

		FArchive@ SaveArchive() override
		{
			FArchive@ ar = IEvent::SaveArchive();
			ar.Set('w', WheelsContactCount);
			return ar;
		}

		void LoadArchive(FArchive &in ar) override
		{
			IEvent::LoadArchive(ar);
			WheelsContactCount = ar.Get('w');
		}

		// ---------------------------------------------------------------
		// CDO Only functions
		// ---------------------------------------------------------------
		string GetName() const override { return "#Wheels Contact"; }
		bool CanEverRender() override { return false; }
		bool IsVisible() override { return false; }
		void SetIsVisible(bool isVisible) override { }
	}
}