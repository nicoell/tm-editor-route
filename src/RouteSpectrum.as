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

	uint32 RequestedRouteIndex = 0;
	ESpectrumType RequestedSpectrum = ESpectrumType::Default;
	uint32 CurrentRouteIndex = NumericLimits::UINT32_MAX;
	ESpectrumType CurrentSpectrum = ESpectrumType::NumTypes;

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
		const bool bRequiresUpdate = CurrentRouteIndex != RequestedRouteIndex || CurrentSpectrum != RequestedSpectrum;
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

	void CreateSpectrum_Speed(Route::FRoute@ route)
	{
		const float maxVal = route.SampleDataArray[route.MaxMagnitudeIndex].Velocity.Length();
		const float fac = maxVal != 0 ? 1. / maxVal : 1.;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			float t = float(i) / SpectrumSize;
			auto data = route.LerpSample(t);
			const float v = data.Velocity.Length() * fac;
			SpectrumData.Write32(RGBAColor(CosPalette::Col(v, CosPalette::Presets::Spectrum)));
		}
	}
	void CreateSpectrum_Altitude(Route::FRoute@ route)
	{
		const float maxVal = route.SampleDataArray[route.MaxAltitudeIndex].Position.y;
		const float fac = maxVal != 0 ? 1. / maxVal : 1.;
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			float t = float(i) / SpectrumSize;
			auto data = route.LerpSample(t);
			const float v = data.Position.y * fac;
			SpectrumData.Write32(RGBAColor(CosPalette::Col(v, CosPalette::Presets::Spectrum)));
		}
	}
	void CreateSpectrum_Gear(Route::FRoute@ route)
	{
		Events::FNearbyEventDesc nearbyDesc;
		const int32 eventIdx = int32(Events::EventType::GearEvent);
		const float fac = 1. / 5.; // MaxGear 5
		for(int32 i = 0; i < SpectrumSize; i++)
		{
			float t = float(i) / SpectrumSize;
			route.FindNearbyEventDesc(t, eventIdx, nearbyDesc);
			auto gear = cast<Events::GearEvent>(route.GetPreviousEvent(eventIdx, nearbyDesc));
			const int32 v = gear is null ? 0 : gear.Gear;
			SpectrumData.Write32(RGBAColor(CosPalette::Col(v, CosPalette::Presets::Spectrum, fac)));
		}
	}
}
