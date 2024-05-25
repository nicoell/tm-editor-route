namespace RouteRecorder
{
	namespace State
	{
		bool bRequestDiscontinuousEntry = false;
		int32 RecordStarttime;
	}

	void Record()
	{
		auto route = RouteContainer::GetCurrentRoute();
		auto currentRaceTime = TimeUtils::GetGameTime() - State::RecordStarttime;
	
		if (currentRaceTime < 0) 
		{
			warn("Cannot record. Time is negative.");
			return; 
		}

		CSmScriptPlayer@ scriptPlayer = GameState::GetScriptPlayer();
		{
			Samples::FSampleData newEntry;
			newEntry.Time = currentRaceTime;
			newEntry.Velocity = scriptPlayer.Velocity;
			newEntry.Position = scriptPlayer.Position;
			
			newEntry.Rotation = RUtils::CreateOrthoBasisQuat(
				scriptPlayer.AimDirection,
				scriptPlayer.UpDirection);
				
			newEntry.bIsDiscontinuous = State::bRequestDiscontinuousEntry;
			newEntry.AvgFrametime = GetAverageFrameTime();

			if (ShouldRecordEntry(newEntry, route.GetLastSampleData()))
			{
				route.SampleDataArray.InsertLast(newEntry);
				route.bIsDiscontinuousArray.InsertLast(newEntry.bIsDiscontinuous);
			}
		}
		
		// ---------------------------------------------------------------
		Events::RecordCtx::CurrentRaceTime = currentRaceTime;
		@Events::RecordCtx::Player = scriptPlayer;

		{
			for(int32 i = 0; i < Events::EventType::NumTypes; i++)
			{
				Events::IEvent@ newEvent = Events::CreateEvent(i);
				if (newEvent !is null)
				{
					newEvent.Record();
					if (newEvent.ShouldRecordEntry(route.GetLastEvent(i)))
					{
						route.InsertEventLast(i, newEvent);
						newEvent.OnRecorded();
					}
				}
			}
		}

		// ---------------------------------------------------------------
		// Reset State
		State::bRequestDiscontinuousEntry = false;
	}

	bool ShouldRecordEntry(Samples::FSampleData@ new, Samples::FSampleData@ prev)
	{
		return prev is null || 
			new.bIsDiscontinuous != prev.bIsDiscontinuous ||
			Math::Abs(new.Time - prev.Time) >= Setting_Recorder_TimeStep ||
			(new.Position - prev.Position).LengthSquared() >= Setting_Recorder_PositionStep * Setting_Recorder_PositionStep;
	}

	float[] FrameTimes (4);
	int8 CurFrame;
	float GetAverageFrameTime() { return 0.25 * (FrameTimes[0] + FrameTimes[1] + FrameTimes[2] + FrameTimes[3]); }
	void RecordFrameTimes(float dt)
	{
		FrameTimes[CurFrame++] = dt;
		CurFrame = CurFrame % 4;
	}

	// ---------------------------------------------------------------

	void AddDebugData(int32 numEntries = 1, int32 maxNumElements = 4000, bool useRandom = false) 
	{
		for(int32 i = 0; i < numEntries; i++)
		{
			RouteContainer::AdvanceRoute();
			auto route = RouteContainer::GetCurrentRoute();

			maxNumElements = useRandom ? Math::Rand(maxNumElements / 2, maxNumElements) : maxNumElements;
			for(int32 k = 0; k < maxNumElements; k++)
			{
				Samples::FSampleData newEntry;
				newEntry.Time = k * 4222;
				newEntry.Position = vec3(0, 0, 0);
				route.SampleDataArray.InsertLast(newEntry);
				route.bIsDiscontinuousArray.InsertLast(k % 8 == 0);
			}
		}
	}
}