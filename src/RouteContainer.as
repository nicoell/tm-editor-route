namespace RouteContainer
{
	array<Route::FRoute@> Routes;
	int32 MinTime;
	int32 MaxTime;

	bool HasRoutes()
	{
		return !Routes.IsEmpty();
	}

	Route::FRoute@ GetCurrentRoute()
	{
		if (!HasRoutes())
		{
			error("RouteContainer: No Route available");
			return null;
		}

		return Routes[Routes.Length - 1];
	}
	Route::FRoute@ GetPreviousRoute()
	{
		if (Routes.Length < 2)
		{
			return null;
		}
		return Routes[Routes.Length - 2];
	}

	void Reset()
	{
		MinTime = NumericLimits::INT32_MAX;
		MaxTime = NumericLimits::INT32_MIN;
		Routes.RemoveRange(0, Routes.Length);
		Table::Reset();
	}

	void AdvanceRoute()
	{
		int32 currentGameTime = RouteTime::GetGameTime();
		if (!Routes.IsEmpty() && GetCurrentRoute().GetNumSamples() == 0)
		{
			GetCurrentRoute().StartTime = currentGameTime;
			trace("Reuse current empty Route");
		}
		else 
		{
			trace("Start a New Route");
			auto newRoute = Route::FRoute();
			newRoute.StartTime = currentGameTime;
			newRoute.ID = Routes.Length;
			Routes.InsertLast(newRoute);
		}
	}

	void DeleteRoute(const int32 i)
	{
		if (i >= 0 && uint32(i) < Routes.Length)
		{
			Routes.RemoveAt(uint32(i));
			Table::VisibleRoutes.RemoveAt(uint32(i));
			RouteContainer::Table::SelectedRouteIndex = i == 0 ? i : i - 1;

			for (int32 k = i; k < int32(Routes.Length); k++)
			{
				Routes[k].ID = k;
			}
			
			for (int32 k = 0; k < int32(Table::OrderedRouteIndices.Length); k++)
			{
				if (Table::OrderedRouteIndices[k] == i) 
				{
					Table::OrderedRouteIndices.RemoveAt(k);
					k--;
				}
				else if (Table::OrderedRouteIndices[k] > i) 
				{
					Table::OrderedRouteIndices[k]--;
				}
			}
		}

		RouteContainer::CacheStats();
	}

	void FinalizeRoutes()
	{
		for (int32 i = 0; i < int32(Routes.Length); i++)
		{
			if (Routes[i].GetNumSamples() == 0)
			{
				Routes.RemoveAt(i);
				i--;
			}
			else
			{
				Routes[i].ID = i;
				Table::RegisterRoute(i);
			}
		}
	}

	void CacheStats()
	{
		MinTime = NumericLimits::INT32_MAX;
		MaxTime = NumericLimits::INT32_MIN;
		for (uint32 i = 0; i < Routes.Length; i++)
		{
			auto@ route = Routes[i];
			route.CacheStats();
			MinTime = Math::Min(MinTime, route.GetMinTime());
			MaxTime = Math::Max(MaxTime, route.GetMaxTime());
		}
	}

	void CacheRouteData(int32 time)
	{
		for (uint32 i = 0; i < Routes.Length; i++)
		{
			auto@ route = Routes[i];
			route.CacheInterpolatedSample(time);
			route.CacheNearbyEvents(time);
		}
	}

	Route::FRoute@ GetSelectedRoute() 
	{
		if (Table::SelectedRouteIndex < Routes.Length) { return Routes[Table::SelectedRouteIndex]; }
		return null;
	}

	// TODO: I don't like this data being here as part of the RouteContainer, this is UI Data
	namespace Table
	{
		array<uint32> OrderedRouteIndices;
		array<bool> VisibleRoutes;
		uint32 SelectedRouteIndex;

		bool IsRouteSelected() { return SelectedRouteIndex < OrderedRouteIndices.Length; }

		void RegisterRoute(uint32 routeId)
		{
			OrderedRouteIndices.InsertLast(routeId);
			VisibleRoutes.InsertLast(true);
		}

		void SetSelectedRoute(uint32 i)
		{
			SelectedRouteIndex = i;
		}

		void Reset()
		{
			SetSelectedRoute(0);
			OrderedRouteIndices.RemoveRange(0, OrderedRouteIndices.Length);
			VisibleRoutes.RemoveRange(0, VisibleRoutes.Length);
		}

		bool CompareWithSortSpecs(const uint32 &in a, const uint32 &in b)
		{
			auto sortSpecs =  UI::TableGetSortSpecs();
			for(uint32 i = 0; i < sortSpecs.Specs.Length; i++)
			{
				auto spec = sortSpecs.Specs[i];

				auto route0 = spec.SortDirection == UI::SortDirection::Ascending ? Routes[a] : Routes[b];
				auto route1 = spec.SortDirection == UI::SortDirection::Ascending ? Routes[b] : Routes[a];
				
				switch(spec.ColumnUserID)
				{
					case EditorRouteUI::RouteTableLengthUserID: return route0.GetDuration() < route1.GetDuration();
					case EditorRouteUI::RouteTableRouteIDUserID:
					default: 
						return route0.ID < route1.ID;
				}
			}
			return a < b; // Fallback
		}

		void SortWithSortSpecs()
		{
			if (!OrderedRouteIndices.IsEmpty()) { OrderedRouteIndices.Sort(CompareWithSortSpecs); }
		}
	}
}