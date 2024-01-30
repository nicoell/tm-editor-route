namespace RouteSpectrum
{
	Bitmap::Bitmap@ SpectrumData;
	UI::Texture@[] RouteSpectrumTextures = {null, null};
	// Double Buffering the Textures because the order of execution during Render() is:
	// 1. DrawCall to Imgui using currently available RouteSpectrum Texture
	// 2. Request new RouteSpectrum (from within Imgui)
	// 3. Process Requests and if Update is required, startnew Coroutine
	namespace PingPong
	{
		int8 Index = 0;

		int8 Write(){ return Index; }
		int8 Read() { return Index ^ 1; }
		void Swap() { Index ^= 1; }

	}
	int32 SpectrumSize = 512;

	uint32 SelectedRouteIndex = 0;
	enum ESpectrumType
	{
		Default,
		Speed = Default,
		Altitude,
		Gear,
		NumTypes,
		None = NumTypes
	};

	enum ESpectrumPalette
	{
		Rainbow = 0,
		DesertSky,
		Cream,
		Phaser,
		Variety,
		Eighties,
		Cactusflower,
		Spectrum
	};
	
	[Setting category="Display" name="Spectrum Palette"]
	ESpectrumPalette RequestedPalette = ESpectrumPalette::Spectrum;

	uint32 RequestedRouteIndex = 0;
	ESpectrumType RequestedSpectrum = ESpectrumType::Default;
	uint32 CurrentRouteIndex = NumericLimits::UINT32_MAX;
	ESpectrumType CurrentSpectrum = ESpectrumType::NumTypes;
	ESpectrumPalette CurrentPalette = RequestedPalette;

	void ResetAll()
	{
		@SpectrumData = null;
		CurrentRouteIndex = NumericLimits::UINT32_MAX;
		CurrentSpectrum = ESpectrumType::NumTypes;
	}
	void ResetRuntime()
	{
		CurrentRouteIndex = NumericLimits::UINT32_MAX;
		CurrentSpectrum = ESpectrumType::NumTypes;
	}

	void ProcessRequest()
	{
		const bool bRequiresUpdate = CurrentRouteIndex != RequestedRouteIndex || CurrentSpectrum != RequestedSpectrum || CurrentPalette != RequestedPalette;
		if (bRequiresUpdate)
		{
			startnew(ProcessRequestCoroutine);
		}
	}

	void ProcessRequestCoroutine()
	{
		auto route = RouteContainer::GetSelectedRoute();
		const bool bCanUpdate = route !is null && route.GetNumSamples() != 0;

		if (bCanUpdate)
		{
			CurrentRouteIndex = RequestedRouteIndex;
			CurrentSpectrum = RequestedSpectrum;
			CurrentPalette = RequestedPalette;

			if (SpectrumData is null || SpectrumData.Header.GetWidth() != SpectrumSize) 
			{
				SpectrumSize = Math::Clamp(SpectrumSize, 16, 1024);
				@SpectrumData = Bitmap::Bitmap(SpectrumSize, 1, 32);
			}

			SpectrumData.MoveTo(0, 0);
			switch(CurrentSpectrum)
			{
				case ESpectrumType::Speed: { CreateSpectrum_Speed(route); }
				case ESpectrumType::Altitude: { CreateSpectrum_Altitude(route); }
				case ESpectrumType::Gear: { CreateSpectrum_Gear(route); }
				default: CreateSpectrum_Speed(route);
			}
			@RouteSpectrumTextures[PingPong::Write()] = SpectrumData.CreateUITexture();
			PingPong::Swap();
		}
		else 
		{
			CurrentRouteIndex = NumericLimits::UINT32_MAX;
			CurrentSpectrum = ESpectrumType::NumTypes;
		}
	}

	void RequestRouteSpectrum(const uint32 routeIndex, const ESpectrumType spectrum)
	{
		RequestedRouteIndex = routeIndex;
		RequestedSpectrum = spectrum;
	}

	// ---------------------------------------------------------------
	// Spectrum Colors
	// ---------------------------------------------------------------

	// Speed
	// ---------------------------------------------------------------
	vec4 CalcSpectrumColor_Speed(Route::FRoute@ route, Route::FSampleData@ sample)
	{
		const float maxVal = route.SampleDataArray[route.MaxMagnitudeIndex].Velocity.Length();
		const float fac = maxVal != 0 ? 1. / maxVal : 1.;
		const float v = sample.Velocity.Length() * fac;
		return vec4(CosPalette::Col(v, CurrentPalette), 1);
	}

	void CreateSpectrum_Speed(Route::FRoute@ route)
	{
		float t;
		Route::FSampleData@ sample = null;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			t = float(i) / SpectrumSize;
			@sample = route.LerpSample(t);
			SpectrumData.Write32(RGBAColor(CalcSpectrumColor_Speed(route, sample)));
		}
	}

	// Altitude
	// ---------------------------------------------------------------
	vec4 CalcSpectrumColor_Altitude(Route::FRoute@ route, Route::FSampleData@ sample)
	{
		const float maxVal = route.SampleDataArray[route.MaxAltitudeIndex].Position.y;
		const float fac = maxVal != 0 ? 1. / maxVal : 1.;
		const float v = sample.Position.y * fac;
		return vec4(CosPalette::Col(v, CurrentPalette), 1);
	}

	void CreateSpectrum_Altitude(Route::FRoute@ route)
	{
		float t;
		Route::FSampleData@ sample;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			t = float(i) / SpectrumSize;
			@sample = route.LerpSample(t);
			SpectrumData.Write32(RGBAColor(CalcSpectrumColor_Altitude(route, sample)));
		}
	}

	// Gears
	// ---------------------------------------------------------------
	vec4 CalcSpectrumColor_Gear(Events::GearEvent@ gearEvent)
	{
		const int32 v = gearEvent is null ? 0 : gearEvent.Gear;
		return vec4(CosPalette::Col(v, CurrentPalette, 0.2), 1); // 0.2 due to MaxGear 5
	}

	void CreateSpectrum_Gear(Route::FRoute@ route)
	{
		Events::FNearbyEventDesc nearbyDesc;
		const int32 eventIdx = int32(Events::EventType::GearEvent);
		float t;
		Events::GearEvent@ gearEvent;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			t = float(i) / SpectrumSize;
			route.FindNearbyEventDesc(t, eventIdx, nearbyDesc);
			@gearEvent = cast<Events::GearEvent>(route.GetPreviousEvent(eventIdx, nearbyDesc));
			SpectrumData.Write32(RGBAColor(CalcSpectrumColor_Gear(gearEvent)));
		}
	}
}
