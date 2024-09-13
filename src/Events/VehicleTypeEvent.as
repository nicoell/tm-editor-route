namespace Events
{
	enum EVehicleType {
		Unknown = -1,
		CharacterPilot = 0,
		CarSport,  // stadium
		CarSnow,
		CarRally,
		CarDesert
	}

	EVehicleType FromVehicleStateVehicleType(VehicleState::VehicleType type)
	{
		switch(type)
		{
			case VehicleState::VehicleType::CharacterPilot: return EVehicleType::CharacterPilot;
			case VehicleState::VehicleType::CarSport: return EVehicleType::CarSport;
			case VehicleState::VehicleType::CarSnow: return EVehicleType::CarSnow;
			case VehicleState::VehicleType::CarRally: return EVehicleType::CarRally;
			case VehicleState::VehicleType::CarDesert: return EVehicleType::CarDesert;
			default: return EVehicleType::Unknown;
		}
	}

	class FVehicleTypeEvent : IEvent
	{
		EVehicleType VehicleType;

		void Record() override
		{
			if (RecordCtx::VisState !is null)
			{
				VehicleType = FromVehicleStateVehicleType(VehicleState::GetVehicleType(RecordCtx::VisState));
			}
			else 
			{
				VehicleType = EVehicleType::Unknown;
			}
		}

		bool ShouldRecordEntry(IEvent@ other) const override
		{
			auto otherTyped = cast<FVehicleTypeEvent>(other);
			return otherTyped is null || otherTyped.VehicleType != VehicleType;
		}

		string GetUIValue() const override 
		{
			return Icons::Car;
		}
		vec3 GetColor() const override 
		{ 
			switch(VehicleType)
			{
				case EVehicleType::CarSport: return vec3(0.47, 0.03, 0.59);
				case EVehicleType::CarSnow: return vec3(0.82, 0.02, 0.02);
				case EVehicleType::CarRally: return vec3(1.00, 0.56, 0.04);
				case EVehicleType::CarDesert: return vec3(1.00, 0.91, 0.25);
				default:
					return vec3(0.3, 0.3, 0.3); 
			}
		}

		FArchive@ SaveArchive() override
		{
			FArchive@ ar = IEvent::SaveArchive();
			ar.Set('vt', int32(VehicleType));
			return ar;
		}

		void LoadArchive(FArchive &in ar) override
		{
			IEvent::LoadArchive(ar);
			int32 vehicleTypeVal = ar.Get('vt', int32(EVehicleType::Unknown));
			VehicleType = EVehicleType(vehicleTypeVal);
		}

		// ---------------------------------------------------------------
		// CDO Only functions
		// ---------------------------------------------------------------
		string GetName() const override { return "VehicleType"; }
		bool CanEverRender() override { return true; }
		bool IsVisible() override { return Setting_RenderVehicleTypeEvents; }
		void SetIsVisible(bool isVisible) override { Setting_RenderVehicleTypeEvents = isVisible; }
	}
}
