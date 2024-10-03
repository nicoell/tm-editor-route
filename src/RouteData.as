namespace Route
{
	class FRoute
	{

		FRoute()
		{
			SetupEvents();
		}

		FRoute(FArchive &in ar)
		{
			SetupEvents();
			if (ar.Data.GetType() != Json::Type::Object) { throw("Json Archive is not an Object."); }

			{
				// Load Samples
				// And pull out bIsDiscontinuous into array for increased rendering performance
				auto arArr = ar.Get('samples');
				SampleDataArray.Reserve(arArr.Length);
				bIsDiscontinuousArray.Reserve(arArr.Length);
				for(uint32 i = 0; i < arArr.Length; i++)
				{
					SampleDataArray.InsertLast(Samples::FSampleData());
					SampleDataArray[i].LoadArchive(arArr.Get(i));
					bIsDiscontinuousArray.InsertLast(SampleDataArray[i].bIsDiscontinuous);
				}
			}
			{
				// Load Events
				auto arEvents = ar.Get('events');
				for(int32 eventTypeIdx = 0; eventTypeIdx < Events::EventType::NumTypes; eventTypeIdx++)
				{
					if (arEvents.HasKey(Events::ToPersistentTypeString(eventTypeIdx)))
					{
						auto eventType = Events::EventType(eventTypeIdx);
						if (eventType != Events::EventType::None)
						{
							auto arTypeEvents = arEvents.Get(Events::ToPersistentTypeString(eventTypeIdx));
							const int32 numTypeEvents = arTypeEvents.Length;
							if (numTypeEvents > 0)
							{
								for(int32 eventIdx = 0; eventIdx < numTypeEvents; eventIdx++)
								{
									Events::CtorCtx::bIsCDO = true;
									Events[eventTypeIdx].InsertLast(Events::CreateEvent(eventType));
									Events::CtorCtx::bIsCDO = false;
									Events[eventTypeIdx][eventIdx].LoadArchive(arTypeEvents.Get(eventIdx));
								}
								RUtils::DebugTrace("Loaded " + numTypeEvents + " Events for EventTypeIdx: " + eventTypeIdx);
							}
							else
							{
								RUtils::DebugTrace("Zero Entries for EventTypeIdx: " + eventTypeIdx);
							}
						}
						else
						{
							RUtils::DebugTrace("Imported Route contains unsupported Events. Events not loaded.");
						}
					} else
					{
						RUtils::DebugTrace("No Entries for EventTypeIdx: " + eventTypeIdx);
					}
				}
			}
		}

		void SetupEvents() 
		{
			Events.Reserve(Events::EventType::NumTypes);
			NearbyEventDescs.Reserve(Events::EventType::NumTypes);
			for(int32 i = 0; i < Events::EventType::NumTypes; i++)
			{
				Events.InsertLast(array<Events::IEvent@>());
				NearbyEventDescs.InsertLast(Events::FNearbyEventDesc());
			}
		}

		FArchive@ SaveArchive()
		{
			FArchive ar(Json::Object());
			// Save Samples
			{
				FArchive arSamples(Json::Array());
				for(uint32 i = 0; i < SampleDataArray.Length; i++)
				{
					arSamples.Add(SampleDataArray[i].SaveArchive());
				}
				ar.Set('samples', arSamples);
			}
			// Save Events
			{
				FArchive arEvents(Json::Object());
				for(int32 eventTypeIdx = 0; eventTypeIdx < Events::EventType::NumTypes; eventTypeIdx++)
				{
					const int32 numTypeEvents = Events[eventTypeIdx].Length;
					if (numTypeEvents > 0)
					{
						FArchive arTypeEvents(Json::Array());
						for(int32 eventIdx = 0; eventIdx < numTypeEvents; eventIdx++)
						{
							arTypeEvents.Add(Events[eventTypeIdx][eventIdx].SaveArchive());
						}
						arEvents.Set(Events::ToPersistentTypeString(eventTypeIdx), arTypeEvents);
					}
				}
				ar.Set('events', arEvents);
			}
			return ar;
		}

		// ---------------------------------------------------------------
		// Serialized Members
		// ---------------------------------------------------------------
		array<Samples::FSampleData> SampleDataArray;
		array<array<Events::IEvent@>> Events;

		// ---------------------------------------------------------------
		// Members
		// ---------------------------------------------------------------
		uint32 ID = 0; // Don't serialize?
		array<bool> bIsDiscontinuousArray;
		int32 BestSampleIndex = 0;
		Samples::FSampleData CurrentSample; // Interpolated Sample at Current Time

		array<Events::FNearbyEventDesc> NearbyEventDescs;
		
		// Stats
		uint32 MaxMagnitudeIndex;
		uint32 MaxAltitudeIndex;

		// ---------------------------------------------------------------
		// Functions
		// ---------------------------------------------------------------
		int32 GetDuration() const {	return GetMaxTime() - GetMinTime(); }
		int32 GetMinTime() const 
		{
			return SampleDataArray.IsEmpty() ? 0 : SampleDataArray[0].Time;
		}
		int32 GetMaxTime() const 
		{
			return SampleDataArray.IsEmpty() ? 0 : SampleDataArray[SampleDataArray.Length - 1].Time;
		}

		// ---------------------------------------------------------------
		// Events

		Events::IEvent@ GetLastEvent(const int32 eventTypeIdx) 
		{ 
			return GetLastEvent(Events::EventType(eventTypeIdx)); 
		} 
		Events::IEvent@ GetLastEvent(Events::EventType eventType) 
		{ 
			return eventType >= 0 && uint32(eventType) < Events.Length && !Events[int32(eventType)].IsEmpty() 
				? @Events[eventType][Events[eventType].Length - 1] 
				: null;
		}
		void InsertEventLast(const int32 eventTypeIdx, Events::IEvent@ event) 
		{ 
			Events[eventTypeIdx].InsertLast(event);
		} 
		void InsertEventLast(Events::EventType eventType, Events::IEvent@ event)
		{
			Events[eventType].InsertLast(event);
		}

		void FindNearbyEventDescByTime(const int32 time, const int32 eventTypeIdx, Events::FNearbyEventDesc@ nearbyDesc)
		{
			auto@ eventsToSearch = Events[eventTypeIdx];
			if (eventsToSearch.IsEmpty())
			{
				nearbyDesc.Reset();
			}
			else
			{
				const uint32 bestIdx = BinarySearchEventsByTime(eventsToSearch, time);
				nearbyDesc.ClosestIdx = bestIdx;

				if (eventsToSearch[bestIdx].Time < time)
				{
					nearbyDesc.PrevIdx = bestIdx;
					nearbyDesc.CurrentIdx = bestIdx;
					nearbyDesc.NextIdx = bestIdx + 1;
				} 
				else if (eventsToSearch[bestIdx].Time > time)
				{
					nearbyDesc.PrevIdx = bestIdx - 1;
					nearbyDesc.CurrentIdx = bestIdx - 1;
					nearbyDesc.NextIdx = bestIdx;
				}
				else
				{
					nearbyDesc.PrevIdx = bestIdx - 1;
					nearbyDesc.CurrentIdx = bestIdx;
					nearbyDesc.NextIdx = bestIdx + 1;
				}

				nearbyDesc.PrevIdx = nearbyDesc.PrevIdx < eventsToSearch.Length ? nearbyDesc.PrevIdx : NumericLimits::UINT32_MAX;
				nearbyDesc.CurrentIdx = nearbyDesc.CurrentIdx < eventsToSearch.Length ? nearbyDesc.CurrentIdx : NumericLimits::UINT32_MAX;
				nearbyDesc.NextIdx = nearbyDesc.NextIdx < eventsToSearch.Length ? nearbyDesc.NextIdx : NumericLimits::UINT32_MAX;
			}
		}
		void FindNearbyEventDesc(const float t, const int32 eventTypeIdx, Events::FNearbyEventDesc@ nearbyDesc)
		{
			FindNearbyEventDescByTime(RUtils::Lerp(GetMinTime(), GetMaxTime(), t), eventTypeIdx, nearbyDesc);
		}

		Events::FNearbyEventDesc@ GetCurrentNearbyEventDesc(const int32 eventTypeIdx)
		{
			return NearbyEventDescs[eventTypeIdx];
		}

		Events::IEvent@ GetCurrentEvent(const int32 eventTypeIdx, Events::FNearbyEventDesc@ desc)
		{
			if (desc is null) { return null; }
			return desc.CurrentIdx < Events[eventTypeIdx].Length ? Events[eventTypeIdx][desc.CurrentIdx] : null;
		}
		Events::IEvent@ GetClosestEvent(const int32 eventTypeIdx, Events::FNearbyEventDesc@ desc)
		{
			if (desc is null) { return null; }
			return desc.ClosestIdx < Events[eventTypeIdx].Length ? Events[eventTypeIdx][desc.ClosestIdx] : null;
		}
		Events::IEvent@ GetPreviousEvent(const int32 eventTypeIdx, Events::FNearbyEventDesc@ desc)
		{
			if (desc is null) { return null; }
			return desc.PrevIdx < Events[eventTypeIdx].Length ? Events[eventTypeIdx][desc.PrevIdx] : null;
		}
		Events::IEvent@ GetNextEvent(const int32 eventTypeIdx, Events::FNearbyEventDesc@ desc)
		{
			if (desc is null) { return null; }
			return desc.NextIdx < Events[eventTypeIdx].Length ? Events[eventTypeIdx][desc.NextIdx] : null;
		}

		Events::IEvent@ GetCachedCurrentEvent(const int32 eventTypeIdx)
		{
			auto desc = NearbyEventDescs[eventTypeIdx];
			if (desc is null) { return null; }
			return desc.CurrentIdx < Events[eventTypeIdx].Length ? Events[eventTypeIdx][desc.CurrentIdx] : null;
		}
		Events::IEvent@ GetCachedClosestEvent(const int32 eventTypeIdx)
		{
			auto desc = NearbyEventDescs[eventTypeIdx];
			if (desc is null) { return null; }
			return desc.ClosestIdx < Events[eventTypeIdx].Length ? Events[eventTypeIdx][desc.ClosestIdx] : null;
		}
		Events::IEvent@ GetCachedPreviousEvent(const int32 eventTypeIdx)
		{
			auto desc = NearbyEventDescs[eventTypeIdx];
			if (desc is null) { return null; }
			return desc.PrevIdx < Events[eventTypeIdx].Length ? Events[eventTypeIdx][desc.PrevIdx] : null;
		}
		Events::IEvent@ GetCachedNextEvent(const int32 eventTypeIdx)
		{
			auto desc = NearbyEventDescs[eventTypeIdx];
			if (desc is null) { return null; }
			return desc.NextIdx < Events[eventTypeIdx].Length ? Events[eventTypeIdx][desc.NextIdx] : null;
		}

		void CacheNearbyEvents(const int32 time)
		{
			for(int32 eventTypeIdx = 0; eventTypeIdx < Events::EventType::NumTypes; eventTypeIdx++)
			{
				FindNearbyEventDescByTime(time, eventTypeIdx, NearbyEventDescs[eventTypeIdx]);
			}
		}

		uint32 BinarySearchEventsByTime(array<Events::IEvent@>@ eventsToSearch, const int32 time)
		{
			if (eventsToSearch.Length <= 1) { return 0; }
			uint32 l = 0;
			uint32 h = eventsToSearch.Length - 1;
			if (time <= eventsToSearch[0].Time) { return l; }
			if (time >= eventsToSearch[eventsToSearch.Length - 1].Time) { return h; }
			while(l <= h)
			{
				uint32 m = (l + h) / 2;
				if (time < eventsToSearch[m].Time) { h = m - 1; }
				else if (time > eventsToSearch[m].Time) { l = m + 1; }
				else { return m; }
			}
			int32 lt = eventsToSearch[l].Time; 
			int32 ht = eventsToSearch[h].Time;
			// l > h => lt > ht
			// => lt != time && ht != time 
			// => lt != ht
			if ((lt - time) < (time - ht))
			{
				return l;
			}
			else 
			{
				return h;
			}
		}

		// ---------------------------------------------------------------
		// Samples

		uint32 GetNumSamples() const { return SampleDataArray.Length; }
		Samples::FSampleData@ GetLastSampleData() { return SampleDataArray.IsEmpty() ? null : @SampleDataArray[SampleDataArray.Length - 1]; }

		void CacheInterpolatedSample(const int32 time)
		{
			CurrentSample = LerpSampleByTime(time, BestSampleIndex);
		}

		Samples::FSampleData LerpSampleByTime(const int32 time) const
		{
			if (GetNumSamples() == 0) { return Samples::FSampleData(); }
			uint32 nextBestIdx; float ratio;
			const uint32 bestIdx = BinarySearchSamplesByTime(time, nextBestIdx, ratio);

			if (bestIdx != nextBestIdx)
			{
				return Samples::Lerp(SampleDataArray[bestIdx], SampleDataArray[nextBestIdx], ratio);

			}
			return SampleDataArray[bestIdx];
		}
		Samples::FSampleData LerpSampleByTime(const int32 time, uint32 &out outBestIdx) const
		{
			if (GetNumSamples() == 0) { outBestIdx = 0; return Samples::FSampleData(); }
			uint32 nextBestIdx; float ratio;
			const uint32 bestIdx = BinarySearchSamplesByTime(time, nextBestIdx, ratio);
			outBestIdx = bestIdx;

			if (bestIdx != nextBestIdx)
			{
				return Samples::Lerp(SampleDataArray[bestIdx], SampleDataArray[nextBestIdx], ratio);

			}
			return SampleDataArray[bestIdx];
		}

		Samples::FSampleData LerpSample(const float t)
		{
			return LerpSampleByTime(RUtils::Lerp(GetMinTime(), GetMaxTime(), t));
		}

		uint32 BinarySearchSamplesByTime(const int32 time, uint32 &out nextBestIdx, float &out ratio)
		{
			ratio = 0.;
			nextBestIdx = 0;
			if (SampleDataArray.Length <= 1) { return 0; }
			uint32 l = 0;
			uint32 h = SampleDataArray.Length - 1;
			if (time <= SampleDataArray[0].Time) { nextBestIdx = l; return l; }
			if (time >= SampleDataArray[SampleDataArray.Length - 1].Time) { nextBestIdx = h; return h; }
			while(l <= h)
			{
				uint32 m = (l + h) / 2;
				if (time < SampleDataArray[m].Time) { h = m - 1; }
				else if (time > SampleDataArray[m].Time) { l = m + 1; }
				else { nextBestIdx = m; return m; }
			}
			int32 lt = SampleDataArray[l].Time; 
			int32 ht = SampleDataArray[h].Time;
			// l > h => lt > ht
			// => lt != time && ht != time 
			// => lt != ht
			ratio = float(time - ht) / float(lt - ht);

			if ((lt - time) < (time - ht))
			{
				ratio = 1 - ratio;
				nextBestIdx = h; 
				return l;
			}
			else 
			{
				nextBestIdx = l;
				return h;
			}
		}

		// ---------------------------------------------------------------
		// Stats

		void CacheStats()
		{
			MaxMagnitudeIndex = 0;
			MaxAltitudeIndex = 0;
			if (GetNumSamples() == 0) { return; }
			
			float maxMagnitude = NumericLimits::FLT_LOWEST;
			float maxAltitude = NumericLimits::FLT_LOWEST;
			for (uint32 i = 0; i < GetNumSamples() - 1; i++) 
			{
				const Samples::FSampleData@ sample = SampleDataArray[i];
				const float magnitude = sample.Velocity.Length();
				if (magnitude > maxMagnitude)
				{
					MaxMagnitudeIndex = i;
					maxMagnitude = magnitude;
				}
				const float altitude = sample.Position.y;
				if (altitude > maxAltitude)
				{
					MaxAltitudeIndex = i;
					maxAltitude = altitude;
				}
			}
		}

		uint32 CreateRenderHash() const
		{
			uint32 seed = 0;
			const uint32 magic_number = 0x9e3779b9; // A large prime number

			// Hash the ID
			seed ^= ID + magic_number + (seed << 6) + (seed >> 2);

			// Hash the number of samples
			uint32 numSamples = GetNumSamples();
			seed ^= numSamples + magic_number + (seed << 6) + (seed >> 2);

			// Hash the length of the Events array
			uint32 eventsLength = Events.Length;
			seed ^= eventsLength + magic_number + (seed << 6) + (seed >> 2);

			// Hash the minimum time (cast to uint32 to handle potential negative values)
			uint32 minTime = uint32(GetMinTime());
			seed ^= minTime + magic_number + (seed << 6) + (seed >> 2);

			// Hash the maximum time (cast to uint32 to handle potential negative values)
			uint32 maxTime = uint32(GetMaxTime());
			seed ^= maxTime + magic_number + (seed << 6) + (seed >> 2);

			return seed;
		}
	}
}