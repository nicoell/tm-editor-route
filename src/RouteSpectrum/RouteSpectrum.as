namespace RouteSpectrum
{

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
	}

	// ---------------------------------------------------------------

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

	uint32 RequestedRouteIndex = 0;
	ESpectrumType RequestedSpectrum = ESpectrumType::Default;

	uint32 CurrentRouteIndex = NumericLimits::UINT32_MAX;
	ESpectrumType CurrentSpectrum = ESpectrumType::NumTypes;
	ESpectrumPalette CurrentPalette = RequestedPalette;

	// ---------------------------------------------------------------

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

	// ---------------------------------------------------------------
	void RequestRouteSpectrum(const uint32 routeIndex, const ESpectrumType spectrum)
	{
		RequestedRouteIndex = routeIndex;
		// Never request Spectrum None
		RequestedSpectrum = spectrum == ESpectrumType::None ? ESpectrumType::Default : spectrum;
	}

	void ProcessRequests()
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
			CreateSpectrum(CurrentSpectrum, route);
			@RouteSpectrumTextures[PingPong::Write()] = SpectrumData.CreateUITexture();
			PingPong::Swap();
		}
		else 
		{
			CurrentRouteIndex = NumericLimits::UINT32_MAX;
			CurrentSpectrum = ESpectrumType::NumTypes;
		}
	}
	
}