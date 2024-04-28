namespace Events
{
	enum EventType
	{
		None = -1,
		GearEvent,
		WheelsContactEvent,
		NumTypes
	};

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
			case EventType::GearEvent: { return GearEvent(); }
			case EventType::WheelsContactEvent: { return WheelsContactEvent(); }
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
		IEvent(int) {} // TODO: Unused explicit constructor to prevent AngelScript bug
		int32 Time;
		vec3 Position;
		float Radius = 14.f;
		string RenderText = "";
		bool bIsHovered = false;
		vec3 Color = vec3(0.2, 0.2, 0.2);

		IEvent()
		{
			if (!CtorCtx::bIsCDO)
			{
				Time = RecordCtx::CurrentRaceTime;
				Position = RecordCtx::Player.Position;
			}
		}

		void Record() {}

		bool ShouldRecordEntry(IEvent@ other) const { return false;}
		string GetUIValue() const { return RenderText; }
		void OnRecorded() const { RUtils::DebugTrace("Recorded Event: " + GetName()); }
		/**
		 * Render function is only called for visible points on the screen.
		 * pos: 2D Screen Positon
		 * Additionally Events::RenderCtx can be accessed during Rendering.
		 */
		void Render(vec2 screenPos, bool bIsRouteSelected) 
		{
			const float radius = Radius * Setting_EventScale;
			const float dotRadius = 3.f * Setting_EventScale;

			vec2 offsetPos = vec2(screenPos.x, screenPos.y - radius - dotRadius);
			bIsHovered = (RenderCtx::MouseCoords - offsetPos).LengthSquared() < (radius * radius);
		
			float alphaMod = /* bIsEventElapsed */ Time < RUtils::AsInt(RouteTime::Time) ? Setting_ElapsedEventOpacityModifier : 1.f;

			nvg::StrokeWidth(bIsRouteSelected ? 1.5 : 1.);
			nvg::StrokeColor(vec4(Color * 0.2, (bIsRouteSelected ? 0.8 : 0.4)) * alphaMod);
			nvg::FillColor(vec4(Color, (bIsHovered ? 1. : .8) * alphaMod));

			// ---------------------------------------------------------------
			// Dot
			nvg::BeginPath();
			nvg::RoundedRectVarying(screenPos.x - dotRadius, screenPos.y - dotRadius, 2*dotRadius, 2*dotRadius, 0, 0, dotRadius, dotRadius);
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
			nvg::FillColor(vec4(ContrastColor::Get(Color), (bIsHovered ? 0.75 : 1.0) * alphaMod));
			nvg::BeginPath();
			nvg::FontSize(16 * Setting_EventScale);
			nvg::FontFace(Fonts::nvg(Fonts::Type::DroidSansBold));
			nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
			nvg::Text(offsetPos, RenderText);

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