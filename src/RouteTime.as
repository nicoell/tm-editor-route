namespace RouteTime
{
	bool bIsPaused = true;
	bool bIsLooped = false;
	double Time;
	double LastUpdateTime;
	double MinTime;
	double MaxTime;
	double Duration;
	vec2 TimeRange = vec2(0, 1);
	float PlaybackSpeed = 1;
	
	void Reset()
	{
	}

	void Init()
	{
		MinTime = RUtils::InMS(RouteContainer::MinTime);
		MaxTime = RUtils::InMS(RouteContainer::MaxTime);
		Duration = MaxTime - MinTime;
		TimeRange = vec2(0, 1);
		Time = 0;
		LastUpdateTime = -1;

		UpdateTime(0., true);
	}

	int GetGameTime() { return GetApp().Network.PlaygroundClientScriptAPI.GameTime; }
	void SetTimeRange(vec2 timeRange , bool markDirty = true) { TimeRange = timeRange; if (markDirty) { UpdateTime(0); } }
	void SetTime(double timeInMs, bool markDirty = true) { Time = timeInMs; if (markDirty) { UpdateTime(0); } }
	void SetTime(int timeInt, bool markDirty = true) { SetTime(RUtils::InMS(timeInt), markDirty); }
	void SetTimePercentage(float percentage, bool markDirty = true) { Time = MinTime + Duration * percentage;  if (markDirty) { UpdateTime(0); } }
	double GetCurrentMinTime() { return RUtils::Clamp(MinTime + TimeRange.x * Duration, MinTime, MaxTime); }
	double GetCurrentMaxTime() { return RUtils::Clamp(MinTime + TimeRange.y * Duration, MinTime, MaxTime); }
	double GetCurrentDuration() { return GetCurrentMaxTime() - GetCurrentMinTime(); }
	float GetTimePercentage(double inTime) { return RUtils::IsNearlyEqual(Duration, 0) ? 0 : (inTime - MinTime) / Duration; }
	float GetTimePercentage() { return RUtils::IsNearlyEqual(Duration, 0) ? 0 : (Time - MinTime) / Duration; }
	double GetTimeByPercentage(const float t) { return MinTime + t * Duration; }

	bool IsTimeInRange(double timeInMs) { return RUtils::IsInRange(timeInMs, GetCurrentMinTime(), GetCurrentMaxTime()); }
	bool IsTimeInRange(int timeInt) { return IsTimeInRange(RUtils::InMS(timeInt)); }

	void UpdateTime(float dt, bool bForceUpdate = false)
	{
		if (!bIsPaused)
		{
			Time += PlaybackSpeed * dt;
		}
		double currentMinTime = GetCurrentMinTime();
		double currentMaxTime = GetCurrentMaxTime();
		double currentDuration = GetCurrentDuration();
		if (bIsLooped)
		{
			for(int32 i = 0; i < 2; i++)
			{
				if (Time < currentMinTime)
				{
					double delta = Time - currentMinTime;
					delta = RUtils::Clamp(delta, -currentDuration, 0);
					Time = currentMaxTime + delta;
					continue;
				}
				else if (Time > currentMaxTime)
				{
					double delta = Time - currentMaxTime;
					delta = RUtils::Clamp(delta, 0, currentDuration);
					Time = currentMinTime + delta;
					continue;
				}
				break;
			}
		}
		else 
		{
			Time = RUtils::Clamp(Time, currentMinTime, currentMaxTime);
		}

		if (bForceUpdate || !RUtils::IsNearlyEqual(LastUpdateTime, Time))
		{
			RouteContainer::CacheRouteData(RUtils::AsInt(Time));
			LastUpdateTime = Time;
		}
	}
}