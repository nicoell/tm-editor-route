namespace RouteSpectrum
{
	enum ESpectrumType
	{
		Default,
		Speed = Default,
		Altitude,
		Gear,
		AvgFPS,
		VehicleType,
		// [New-SpectrumType]: Define new SpectrumType above this line
		// ---------------------------------------------------------------
		NumTypes,
		None = NumTypes
	}
	namespace Private
	{
		enum ESpectrumDataSource
		{
			Sample,
			Event,
			// ---------------------------------------------------------------
			NumTypes,
			None = NumTypes
		}

		ESpectrumDataSource get_SpectrumDataSource(ESpectrumType spectrumType) property
		{
			switch(spectrumType)
			{
				case ESpectrumType::NumTypes: return ESpectrumDataSource::None;
				case ESpectrumType::Speed: return ESpectrumDataSource::Sample;
				case ESpectrumType::Altitude: return ESpectrumDataSource::Sample;
				case ESpectrumType::Gear: return ESpectrumDataSource::Event;
				case ESpectrumType::AvgFPS: return ESpectrumDataSource::Sample;
				case ESpectrumType::VehicleType: return ESpectrumDataSource::Event;
				// [New-SpectrumType]: Implement here for new SpectrumType
			}
			error("Missing mapping from SpectrumType to SpectrumDataSource for SpectrumType: " + spectrumType);
			return ESpectrumDataSource::None;
		}

		Events::EventType get_EventType(ESpectrumType spectrumType) property
		{
			switch(spectrumType)
			{
				case ESpectrumType::NumTypes: return Events::EventType::None;
				case ESpectrumType::Gear: return Events::EventType::GearEvent;
				case ESpectrumType::VehicleType: return Events::EventType::VehicleTypeEvent;
				// [New-SpectrumType]: Implement here for new SpectrumType with DataSource Event
			}
			error("Missing mapping from SpectrumType to EventType for SpectrumType: " + spectrumType);
			return Events::EventType::None;
		}
	}

	// ---------------------------------------------------------------
	// Calc Spectrum Colors
	// ---------------------------------------------------------------
	vec4 CalcCurrentSpectrumColor()
	{
		if (RouteContainer::GetSelectedRoute() is null) { return vec4(1, 1, 1, 1); }
		return CalcSpectrumColorByTime(RouteSpectrum::RequestedSpectrum, RouteContainer::GetSelectedRoute(), RUtils::AsInt(RouteTime::Time));
	}

	vec4 CalcCurrentSpectrumColorByTime(const int32 time)
	{
		if (RouteContainer::GetSelectedRoute() is null) { return vec4(1, 1, 1, 1); }
		return CalcSpectrumColorByTime(RouteSpectrum::RequestedSpectrum, RouteContainer::GetSelectedRoute(), time);
	}

	vec4 CalcSpectrumColorByTime(ESpectrumType spectrumType, Route::FRoute@ route, const int32 time)
	{
		switch(Private::SpectrumDataSource[spectrumType])
		{
			case Private::ESpectrumDataSource::NumTypes: return vec4(1, 1, 1, 1);
			case Private::ESpectrumDataSource::Sample: return CalcSampleSpectrumColorByTime(spectrumType, route, time);
			case Private::ESpectrumDataSource::Event: return CalcEventSpectrumColorByTime(spectrumType, route, time);
		}
		error("Missing mapping for SpectrumDataSource: " + spectrumType);
		return vec4(1, 1, 1, 1);
	}

	vec4 CalcSampleSpectrumColorByTime(ESpectrumType spectrumType, Route::FRoute@ route, const int32 time)
	{
		Samples::FSampleData@ sample = route.LerpSampleByTime(time);
		return CalcSampleSpectrumColor(spectrumType, route, sample);
	}

	vec4 CalcSampleSpectrumColor(ESpectrumType spectrumType, Route::FRoute@ route, Samples::FSampleData@ sample)
	{
		switch(spectrumType)
		{
			case ESpectrumType::NumTypes: return vec4(1, 1, 1, 1);
			case ESpectrumType::Speed: { return CalcSpectrumColor_Speed(route, sample); }
			case ESpectrumType::Altitude: { return CalcSpectrumColor_Altitude(route, sample); }
			case ESpectrumType::AvgFPS: { return CalcSpectrumColor_AvgFPS(route, sample); }
			// [New-SpectrumType]: Implement here for new SpectrumType with DataSource Sample
		}
		error("Missing mapping from SpectrumType to CalcSpectrumColor for SpectrumType: " + spectrumType);
		return vec4(1, 1, 1, 1);
	}
	
	vec4 CalcEventSpectrumColorByTime(ESpectrumType spectrumType, Route::FRoute@ route, const int32 time)
	{
		Events::FNearbyEventDesc nearbyDesc;
		int32 eventIdx = int32(Private::EventType[spectrumType]);
		route.FindNearbyEventDescByTime(time, eventIdx , nearbyDesc);
		return CalcEventSpectrumColor(spectrumType, route.GetPreviousEvent(eventIdx, nearbyDesc));
	}

	vec4 CalcEventSpectrumColor(ESpectrumType spectrumType, Events::IEvent@ event)
	{
		switch(spectrumType)
		{
			case ESpectrumType::Gear: { return CalcSpectrumColor_Gear(event); }
			case ESpectrumType::VehicleType: { return CalcSpectrumColor_VehicleType(event); }
			// [New-SpectrumType]: Implement here for new SpectrumType with DataSource Event
		}
		return vec4(1, 1, 1, 1);
	}

	// ---------------------------------------------------------------
	// Spectrum Texture Data Generation
	// ---------------------------------------------------------------
	void CreateSpectrum(ESpectrumType spectrumType, Route::FRoute@ route)
	{
		switch(spectrumType)
		{
			case ESpectrumType::Speed: { CreateSpectrum_Speed(route); }
			case ESpectrumType::Altitude: { CreateSpectrum_Altitude(route); }
			case ESpectrumType::Gear: { CreateSpectrum_Gear(route); }
			case ESpectrumType::AvgFPS: { CreateSpectrum_AvgFPS(route); }
			case ESpectrumType::VehicleType: { CreateSpectrum_VehicleType(route); }
			// [New-SpectrumType]: Implement here for new SpectrumType
			default: CreateSpectrum_Speed(route);
		}
		// NOTE: There's no fallthrough for Spectrum Texture Data generation to always have some texture available
		// NOTE: CreateSpectrum implementations are more performance critical and should use less nested function calls
	}

	// ---------------------------------------------------------------
	// Concrete Spectrum Type Implemenations
	// ---------------------------------------------------------------
	
	// ---------------------------------------------------------------
	// Speed
	// ---------------------------------------------------------------
	vec4 CalcSpectrumColor_Speed(Route::FRoute@ route, Samples::FSampleData@ sample)
	{
		const float maxVal = route.SampleDataArray[route.MaxMagnitudeIndex].Velocity.Length();
		const float fac = maxVal != 0 ? 1. / maxVal : 1.;
		const float v = sample.Velocity.Length() * fac;
		return vec4(CosPalette::Col(v, CurrentPalette), 1);
	}

	void CreateSpectrum_Speed(Route::FRoute@ route)
	{
		float t;
		Samples::FSampleData@ sample = null;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			t = float(i) / SpectrumSize;
			@sample = route.LerpSample(t);
			SpectrumData.Write32(RGBAColor(CalcSpectrumColor_Speed(route, sample)));
		}
	}

	// ---------------------------------------------------------------
	// Altitude
	// ---------------------------------------------------------------
	vec4 CalcSpectrumColor_Altitude(Route::FRoute@ route, Samples::FSampleData@ sample)
	{
		const float maxVal = route.SampleDataArray[route.MaxAltitudeIndex].Position.y;
		const float fac = maxVal != 0 ? 1. / maxVal : 1.;
		const float v = sample.Position.y * fac;
		return vec4(CosPalette::Col(v, CurrentPalette), 1);
	}

	void CreateSpectrum_Altitude(Route::FRoute@ route)
	{
		float t;
		Samples::FSampleData@ sample;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			t = float(i) / SpectrumSize;
			@sample = route.LerpSample(t);
			SpectrumData.Write32(RGBAColor(CalcSpectrumColor_Altitude(route, sample)));
		}
	}

	// ---------------------------------------------------------------
	// Gears
	// ---------------------------------------------------------------
	vec4 CalcSpectrumColor_Gear(Events::IEvent@ event)
	{
		const int32 v = (cast<Events::FGearEvent>(event) is null) ? 0 : (cast<Events::FGearEvent>(event).Gear);
		return vec4(CosPalette::Col(v, CurrentPalette, 0.2), 1); // 0.2 due to MaxGear 5
	}

	void CreateSpectrum_Gear(Route::FRoute@ route)
	{
		Events::FNearbyEventDesc nearbyDesc;
		const int32 eventIdx = int32(Events::EventType::GearEvent);
		float t;
		Events::IEvent@ event;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			t = float(i) / SpectrumSize;
			route.FindNearbyEventDesc(t, eventIdx, nearbyDesc);
			@event = route.GetPreviousEvent(eventIdx, nearbyDesc);
			SpectrumData.Write32(RGBAColor(CalcSpectrumColor_Gear(event)));
		}
	}

	// ---------------------------------------------------------------
	// VehicleType
	// ---------------------------------------------------------------
	vec4 CalcSpectrumColor_VehicleType(Events::IEvent@ event)
	{
		const int32 v = (cast<Events::FVehicleTypeEvent>(event) is null) ? 0 : (cast<Events::FVehicleTypeEvent>(event).VehicleType);
		return vec4(CosPalette::Col(v, CurrentPalette, 1./5.), 1); // 5 different Vehicle Types
	}

	void CreateSpectrum_VehicleType(Route::FRoute@ route)
	{
		Events::FNearbyEventDesc nearbyDesc;
		const int32 eventIdx = int32(Events::EventType::VehicleTypeEvent);
		float t;
		Events::IEvent@ event;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			t = float(i) / SpectrumSize;
			route.FindNearbyEventDesc(t, eventIdx, nearbyDesc);
			@event = route.GetPreviousEvent(eventIdx, nearbyDesc);
			SpectrumData.Write32(RGBAColor(CalcSpectrumColor_VehicleType(event)));
		}
	}

	// ---------------------------------------------------------------
	// AvgFPS
	// ---------------------------------------------------------------
	vec4 CalcSpectrumColor_AvgFPS(Route::FRoute@ route, Samples::FSampleData@ sample)
	{
		const float fac = 1. / 144.;
		const float v = sample.AvgFPS * fac;
		return vec4(CosPalette::Col(v, CurrentPalette), 1);
	}

	void CreateSpectrum_AvgFPS(Route::FRoute@ route)
	{
		float t;
		Samples::FSampleData@ sample;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			t = float(i) / SpectrumSize;
			@sample = route.LerpSample(t);
			SpectrumData.Write32(RGBAColor(CalcSpectrumColor_AvgFPS(route, sample)));
		}
	}
}