namespace Route
{
	class FSampleData
	{
		int32 Time;
		vec3 Position;
		vec3 Velocity;
		quat Rotation;
		bool bIsDiscontinuous = false;
	}

	FSampleData Lerp(const FSampleData &in a, const FSampleData &in b, float t)
	{
		// Don't interpolate discontinuous data (if earlier data is discontinuous)
		if ((a.bIsDiscontinuous && a.Time < b.Time) || (b.bIsDiscontinuous && b.Time < a.Time))
		{
			return t < 0.5 ? a : b;
		}
		FSampleData sample;
		sample.Time = RUtils::Lerp(a.Time, b.Time, t);// int(Math::Round(Math::Lerp(float(a.Time), float(b.Time), t)));
		sample.Position = Math::Lerp(a.Position, b.Position, t);
		sample.Velocity = Math::Lerp(a.Velocity, b.Velocity, t);
		sample.Rotation = Math::Slerp(a.Rotation, b.Rotation, t);
		sample.bIsDiscontinuous = t < 0.5 ? a.bIsDiscontinuous : b.bIsDiscontinuous;
		return sample;
	}
}