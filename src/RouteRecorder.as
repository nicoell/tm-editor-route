[Setting category="Recorder" name="Time Step (ms)"]
int32 Setting_Recorder_TimeStep = 500.;
[Setting category="Recorder" name="Position Step (m)"]
float Setting_Recorder_PositionStep = 1.;

namespace RouteRecorder
{
	namespace State
	{
		bool bRequestDiscontinuousEntry = false;
	}

	void Record()
	{
		auto route = RouteContainer::GetCurrentRoute();
		auto currentRaceTime = RouteTime::GetGameTime() - route.StartTime;
	
		if (currentRaceTime < 0) 
		{
			warn("Cannot record. Time is negative.");
			return; 
		}

		CSmScriptPlayer@ scriptPlayer = GameState::GetScriptPlayer();
		{
			Route::FSampleData newEntry;
			newEntry.Time = currentRaceTime;
			newEntry.Velocity = scriptPlayer.Velocity;
			newEntry.Position = scriptPlayer.Position;
			newEntry.Rotation = CalcRotation(
				scriptPlayer.AimDirection.Normalized(),
				scriptPlayer.UpDirection);
			newEntry.bIsDiscontinuous = State::bRequestDiscontinuousEntry;
			
			if (ShouldRecordEntry(newEntry, route.GetLastSampleData()))
			{
				route.SampleDataArray.InsertLast(newEntry);
				route.Positions.InsertLast(newEntry.Position);
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

	void AddDebugData(int32 numElements = 4000) 
	{
		RouteContainer::AdvanceRoute();
		auto route = RouteContainer::GetCurrentRoute();
		for(int32 i = 0; i < numElements; i++)
		{
			Route::FSampleData newEntry;
			newEntry.Time = i;
			newEntry.Position = vec3(0, 0, 0);
			route.SampleDataArray.InsertLast(newEntry);
			route.Positions.InsertLast(newEntry.Position);
			route.bIsDiscontinuousArray.InsertLast(i % 8 == 0);
		}
		GameState::InitRuntime();
	}

	bool ShouldRecordEntry(Route::FSampleData new, Route::FSampleData@ prev)
	{
		return prev is null || 
			new.bIsDiscontinuous != prev.bIsDiscontinuous ||
			Math::Abs(new.Time - prev.Time) >= Setting_Recorder_TimeStep ||
			(new.Position - prev.Position).LengthSquared() >= Setting_Recorder_PositionStep * Setting_Recorder_PositionStep;
	}

	quat CalcRotation(vec3 fwd, vec3 up)
	{
		up -= fwd * Math::Dot(up, fwd);
		up = up.Normalized();
		vec3 right = Math::Cross(up, fwd).Normalized();

		quat q;
		q.w = Math::Sqrt(1.f + right.x + up.y + fwd.z) / 2.f;

		if (Math::Abs(q.w) < 1e-4) 
		{
			q = quat(0.f, 0.f, 0.f, 1.f);
		} else {
			float t = 1.f / (4.f * q.w);
			q.x = (up.z - fwd.y) * t;
			q.y = (fwd.x - right.z) * t;
			q.z = (right.y - up.x) * t;
		}
		
		return q.Normalized();
	}
}