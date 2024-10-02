namespace Events
{
	enum EventType
	{
		None = -1,
		GearEvent,
		WheelsContactEvent,
		VehicleTypeEvent,
		NumTypes
	};
	
	enum PersistentEventType
	{
		Invalid = -1,
		GearEvent = 0,
		WheelsContactEvent = 1,
		VehicleTypeEvent = 2,
		// Persistent Event Type Values never change and will be used for versioning
	};

	EventType FromPersistentType(int32 persistentTypeIdx)
	{
		return FromPersistentType(PersistentEventType(persistentTypeIdx));
	}
	
	Events::EventType FromPersistentType(PersistentEventType type)
	{
		switch(type)
		{
			case PersistentEventType::GearEvent: return Events::EventType::GearEvent;
			case PersistentEventType::WheelsContactEvent: return Events::EventType::WheelsContactEvent;
			case PersistentEventType::VehicleTypeEvent: return Events::EventType::VehicleTypeEvent;
			default: return EventType::None;
		}
	}

	PersistentEventType ToPersistentType(int32 typeIdx)
	{
		return ToPersistentType(Events::EventType(typeIdx));
	}
	
	PersistentEventType ToPersistentType(Events::EventType type)
	{
		switch(type)
		{
			case EventType::GearEvent: { return PersistentEventType::GearEvent; }
			case EventType::WheelsContactEvent: { return PersistentEventType::WheelsContactEvent; }
			case EventType::VehicleTypeEvent: { return PersistentEventType::VehicleTypeEvent; }
			default: return PersistentEventType::Invalid;
		}
	}
	string ToPersistentTypeString(int32 typeIdx) { return "" + ToPersistentType(typeIdx); }
	string ToPersistentTypeString(Events::EventType type) { return "" + ToPersistentType(type); }

	// ---------------------------------------------------------------
	// Event Class Default Objects
	// ---------------------------------------------------------------
	IEvent@[] CDOs (EventType::NumTypes);

	void CreateCDOs()
	{
		CtorCtx::bIsCDO = true;
		for(int32 eventTypeIdx = 0; eventTypeIdx < Events::EventType::NumTypes; eventTypeIdx++)
		{
			@CDOs[eventTypeIdx] = CreateEvent(eventTypeIdx);
		}
		CtorCtx::bIsCDO = false;
	}

	IEvent@ GetCDO(EventType type) { return CDOs[int32(type)]; }
	IEvent@ GetCDO(int32 typeIdx) { return CDOs[typeIdx]; }
	
	bool CanEverRender(EventType type) { return CDOs[int32(type)].CanEverRender(); }
	bool CanEverRender(int32 typeIdx) { return CDOs[typeIdx].CanEverRender(); }
	bool IsVisible(EventType type) { return CDOs[int32(type)].IsVisible(); }
	bool IsVisible(int32 typeIdx) { return CDOs[typeIdx].IsVisible(); }
	void SetIsVisible(EventType type, bool isVisible) { CDOs[int32(type)].SetIsVisible(isVisible); }
	void SetIsVisible(int32 typeIdx, bool isVisible) { CDOs[typeIdx].SetIsVisible(isVisible); }

	// ---------------------------------------------------------------

	class FNearbyEventDesc
	{
		uint32 CurrentIdx;
		uint32 PrevIdx;
		uint32 NextIdx;
		uint32 ClosestIdx;

		FNearbyEventDesc()
		{
			Reset();
		}

		void Reset() 
		{
			CurrentIdx = NumericLimits::UINT32_MAX;
			PrevIdx = NumericLimits::UINT32_MAX;
			NextIdx = NumericLimits::UINT32_MAX;
			ClosestIdx = NumericLimits::UINT32_MAX;
		}
	}

	IEvent@ CreateEvent(int32 typeIdx) { return CreateEvent(EventType(typeIdx)); }
	IEvent@ CreateEvent(EventType type)
	{
		switch(type)
		{
			case EventType::GearEvent: { return FGearEvent(); }
			case EventType::WheelsContactEvent: { return FWheelsContactEvent(); }
			case EventType::VehicleTypeEvent: { return FVehicleTypeEvent(); }
			default: return null;
		}
	}
	
	namespace CtorCtx
	{
		bool bIsCDO = false;
	}
	namespace RecordCtx
	{
		CSmScriptPlayer@ Player;
		CSceneVehicleVisState@ VisState;
		int32 CurrentRaceTime;
		vec3 Position;
	}
	namespace RenderCtx
	{
		mat4 Proj;
		vec2 MouseCoords;
		bool bIsMiddleMouseClicked;
		bool IsHoveredSquare(const vec2 &in screenPos, const float sideLength) { return (MouseCoords - screenPos).LengthSquared() < sideLength * sideLength; }
		bool IsHoveredCircle(const vec2 &in screenPos, const float radius) { return (MouseCoords - screenPos).Length() < radius; }
	}

	class IEvent
	{
		// ---------------------------------------------------------------
		// Serialized Members
		// ---------------------------------------------------------------
		int32 Time;
		vec3 Position;

		// ---------------------------------------------------------------
		// Members
		// ---------------------------------------------------------------
		bool bIsHovered = false;

		IEvent()
		{
			if (!CtorCtx::bIsCDO)
			{
				Time = RecordCtx::CurrentRaceTime;
				Position = RecordCtx::Player.Position;
			}
		}

		string GetUIValue() const { return "Event"; }
		float GetRadius() const { return 14.f; }
		vec3 GetStrokeColor() const { return vec3(0.05, 0.05, 0.05); }
		vec3 GetFillColor() const { return vec3(0.2, 0.2, 0.2); }
		vec3 GetTextColor() const { return vec3(1., 1., 1.); }

		void Record() {}

		bool ShouldRecordEntry(IEvent@ other) const { return false;}
		void OnRecorded() const { RUtils::DebugTrace("Recorded Event: " + GetName()); }
		/**
		 * Render function is only called for visible points on the screen.
		 * pos: 2D Screen Positon
		 * Additionally Events::RenderCtx can be accessed during Rendering.
		 */
		void Render(vec2 screenPos, bool bIsRouteSelected) 
		{
			const float radius = GetRadius() * Setting_EventScale;
			const float dotRadius = 3.f * Setting_EventScale;

			vec2 offsetPos = vec2(screenPos.x, screenPos.y - radius - dotRadius);
			bIsHovered = (RenderCtx::MouseCoords - offsetPos).LengthSquared() < (radius * radius);
		
			float alphaMod = /* bIsEventElapsed */ Time < RUtils::AsInt(RouteTime::Time) ? Setting_ElapsedEventOpacityModifier : 1.;

			nvg::StrokeWidth(bIsRouteSelected ? 1.5 : 1.);
			nvg::StrokeColor(vec4((bIsHovered ? GetTextColor() : GetStrokeColor()), (bIsRouteSelected ? 0.8 : 0.4) * alphaMod));
			nvg::FillColor(vec4(GetFillColor(), (bIsHovered ? 1. : .8) * alphaMod));

			// ---------------------------------------------------------------
			// Dot
			nvg::BeginPath();
			nvg::RoundedRect(screenPos.x - dotRadius, screenPos.y - dotRadius, 2*dotRadius, 2*dotRadius, dotRadius);
			nvg::Fill();
			nvg::Stroke();

			// ---------------------------------------------------------------
			// Background
			nvg::BeginPath();
			nvg::RoundedRect(offsetPos.x - radius, offsetPos.y - radius, 2*radius, 2*radius, .5*radius);
			nvg::Fill();
			nvg::Stroke();

			// ---------------------------------------------------------------
			// Event Text
			nvg::FillColor(vec4(GetTextColor(), (bIsHovered ? 0.75 : 1.0) * alphaMod));
			nvg::BeginPath();
			nvg::FontSize(16 * Setting_EventScale);
			nvg::FontFace(Fonts::nvg(Fonts::Type::DroidSansBold));
			nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
			nvg::Text(offsetPos, GetUIValue());

			// ---------------------------------------------------------------
			// Click handling
			// Note: This feels awkward to be done in Render, but it is kind of convinient
			if (bIsHovered && RenderCtx::bIsMiddleMouseClicked)
			{
				RouteTime::SetTime(Time);
			}
		};

		void Reset()
		{
			bIsHovered = false;
		}

		FArchive@ SaveArchive()
		{
			FArchive ar(Json::Object());
			ar.Set('t', FArchive(Time));
			ar.Set('p', FArchive(Position));
			return ar;
		}

		void LoadArchive(FArchive &in ar)
		{
			Time = ar.Get('t');
			Position = ar.Get('p');
		}

		// ---------------------------------------------------------------
		// CDO Only functions
		// ---------------------------------------------------------------
		string GetName() const { return "None"; }
		string GetUITooltip() const { return ""; }
		bool CanEverRender() { return false; }
		bool IsVisible() { return false; }
		void SetIsVisible(bool isVisible) { }
	}
}
