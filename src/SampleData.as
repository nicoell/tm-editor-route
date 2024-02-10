namespace Samples
{
	enum EPropType
	{
		Time = 0,
		Position,
		Velocity,
		Rotation,
		Speed,
		Altitude,
		AvgFPS,
		// [New-PropType]: Define new PropType above this line
		// ---------------------------------------------------------------
		NumTypes,
		None = NumTypes
	};

	namespace Prop
	{
		RouteSpectrum::ESpectrumType get_SpectrumType(EPropType i) property
		{
			switch(i)
			{
				case EPropType::Time: return RouteSpectrum::ESpectrumType::None;
				case EPropType::Position: return RouteSpectrum::ESpectrumType::None;
				case EPropType::Velocity: return RouteSpectrum::ESpectrumType::Speed;
				case EPropType::Rotation: return RouteSpectrum::ESpectrumType::None;
				case EPropType::Speed: return RouteSpectrum::ESpectrumType::Speed;
				case EPropType::Altitude: return RouteSpectrum::ESpectrumType::Altitude;
				case EPropType::AvgFPS: return RouteSpectrum::ESpectrumType::AvgFPS;
				// [New-PropType]: Implement here for new PropTypes
			}
            error("Missing mapping from PropType to SpectrumType for PropType: " + i);
			return RouteSpectrum::ESpectrumType::None;
		}

		string get_Name(EPropType i) property
		{
			switch(i)
			{
				case EPropType::Time: return "Time";
				case EPropType::Position: return "Position";
				case EPropType::Velocity: return "Velocity";
				case EPropType::Rotation: return "Rotation";
				case EPropType::Speed: return "Speed";
				case EPropType::Altitude: return "Altitude";
				case EPropType::AvgFPS: return "Average FPS";
				// [New-PropType]: Implement here for new PropTypes
			}
            error("Missing name for : " + i);
			return "Unknown";
		}
	}

	class FSampleData
	{
		int32 Time;
		vec3 Position;
		vec3 Velocity;
		quat Rotation;
		bool bIsDiscontinuous = false;
		float AvgFrametime;

		float get_Speed() const property { return Velocity.Length() * 3.6f; }
		float get_Altitude() const property { return Position.y; }
		float get_AvgFPS() const property { return AvgFrametime != 0 ? 1000. / AvgFrametime : 0; }

		Private::FPropVariant get_Prop(EPropType i)
		{
			switch(i)
			{
				case EPropType::Time: return Private::FPropFloat(Time);
				case EPropType::Position: return Private::FPropVec3(Position);
				case EPropType::Velocity: return Private::FPropVec3(Velocity);
				case EPropType::Rotation: return Private::FPropQuat(Rotation);
				case EPropType::Speed: return Private::FPropFloat(Speed);
				case EPropType::Altitude: return Private::FPropFloat(Altitude);
				case EPropType::AvgFPS: return Private::FPropFloat(AvgFPS);
				// [New-PropType]: Implement here for new PropTypes
			}
            error("Missing mapping from PropType to SpectrumType for PropType: " + i);
			return Private::FPropInt32(0);
		}
	}

	FSampleData Lerp(const FSampleData &in a, const FSampleData &in b, float t)
	{
		// Don't interpolate discontinuous data (if earlier data is discontinuous)
		if ((a.bIsDiscontinuous && a.Time < b.Time) || (b.bIsDiscontinuous && b.Time < a.Time))
		{
			return t < 0.5 ? a : b;
		}
		FSampleData sample;
		sample.Time = RUtils::Lerp(a.Time, b.Time, t);
		sample.Position = Math::Lerp(a.Position, b.Position, t);
		sample.Velocity = Math::Lerp(a.Velocity, b.Velocity, t);
		sample.Rotation = Math::Slerp(a.Rotation, b.Rotation, t);
		sample.bIsDiscontinuous = t < 0.5 ? a.bIsDiscontinuous : b.bIsDiscontinuous;
		sample.AvgFrametime = Math::Lerp(a.AvgFrametime, b.AvgFrametime, t);
		// [New-PropType]: Potentially implement here for new PropTypes that are not calculated dynamically

		return sample;
	}

	namespace Private
	{
		// [New-PropType]: If the underlyign Data Type is not yet implemented, add it here 
		class FPropVariant
		{
			float opImplConv() const { error("Requested Property cannot be cast to type float");  return 0; }
			double opImplConv() const { error("Requested Property cannot be cast to type double");  return 0; }
			vec2 opImplConv() const { error("Requested Property cannot be cast to type vec2");  return vec2(0); }
			vec3 opImplConv() const { error("Requested Property cannot be cast to type vec3");  return vec3(0); }
			vec4 opImplConv() const { error("Requested Property cannot be cast to type vec4");  return vec4(0); }
			quat opImplConv() const { error("Requested Property cannot be cast to type quat");  return quat(0); }
			int8 opImplConv() const { error("Requested Property cannot be cast to type int8");  return 0; }
			int16 opImplConv() const { error("Requested Property cannot be cast to type int16");  return 0; }
			int32 opImplConv() const { error("Requested Property cannot be cast to type int32");  return 0; }
			int64 opImplConv() const { error("Requested Property cannot be cast to type int64");  return 0; }
			uint8 opImplConv() const { error("Requested Property cannot be cast to type uint8");  return 0; }
			uint16 opImplConv() const { error("Requested Property cannot be cast to type uint16");  return 0; }
			uint32 opImplConv() const { error("Requested Property cannot be cast to type uint32");  return 0; }
			uint64 opImplConv() const { error("Requested Property cannot be cast to type uint64");  return 0; }

			string opImplConv() const { error("Requested Property cannot be cast to type string");  return "Unknown"; }
			string Format(const string &in fmt) const { error("Requested Property cannot be formatted as string");  return "Unknown"; }
		}

		class FPropFloat : FPropVariant
		{
			float Val;
			FPropFloat(float &in val) { Val = val; }
			float opImplConv() const override { return Val; }
			double opImplConv() const override { return Val; }
			string opImplConv() const override { return "" + Val; }
			string Format(const string &in fmt) const override { return Text::Format(fmt, Val); }
		}
		class FPropDouble : FPropVariant
		{
			double Val;
			FPropDouble(double &in val) { Val = val; }
			double opImplConv() const override { return Val; }
			float opImplConv() const override { return Val; }
			string opImplConv() const override { return "" + Val; }
			string Format(const string &in fmt) const override { return Text::Format(fmt, Val); }
		}
		class FPropVec2 : FPropVariant
		{
			vec2 Val;
			FPropVec2(vec2 &in val) { Val = val; }
			vec2 opImplConv() const override { return Val; }
			string opImplConv() const override { return Val.ToString(); }
			string Format(const string &in fmt) const override 
			{ 
				int32 i = fmt.IndexOfI("%s");
				if (i >= 0) 
				{
					string ret;
					if (i > 0) {ret += fmt.SubStr(0, i);}
					ret += string(this);
					ret += fmt.SubStr(2);
					return ret;
				}
				error("Could not find '%s' format specifier: " + fmt);
				return fmt;
			}
		}
		class FPropVec3 : FPropVariant
		{
			vec3 Val;
			FPropVec3(vec3 &in val) { Val = val; }
			vec3 opImplConv() const override { return Val; }
			string opImplConv() const override { return Val.ToString(); }
			string Format(const string &in fmt) const override 
			{ 
				int32 i = fmt.IndexOfI("%s");
				if (i >= 0) 
				{
					string ret;
					if (i > 0) {ret += fmt.SubStr(0, i);}
					ret += string(this);
					ret += fmt.SubStr(2);
					return ret;
				}
				error("Could not find '%s' format specifier: " + fmt);
				return fmt;
			}
		}
		class FPropVec4 : FPropVariant
		{
			vec4 Val;
			FPropVec4(vec4 &in val) { Val = val; }
			vec4 opImplConv() const override { return Val; }
			string opImplConv() const override { return Val.ToString(); }
			string Format(const string &in fmt) const override 
			{ 
				int32 i = fmt.IndexOfI("%s");
				if (i >= 0) 
				{
					string ret;
					if (i > 0) {ret += fmt.SubStr(0, i);}
					ret += string(this);
					ret += fmt.SubStr(2);
					return ret;
				}
				error("Could not find '%s' format specifier: " + fmt);
				return fmt;
			}
		}
		class FPropQuat : FPropVariant
		{
			quat Val;
			FPropQuat(quat &in val) { Val = val; }
			quat opImplConv() const override { return Val; }
			string opImplConv() const override { return Val.ToString(); }
			string Format(const string &in fmt) const override 
			{ 
				int32 i = fmt.IndexOfI("%s");
				if (i >= 0) 
				{
					string ret;
					if (i > 0) {ret += fmt.SubStr(0, i);}
					ret += string(this);
					ret += fmt.SubStr(2);
					return ret;
				}
				error("Could not find '%s' format specifier: " + fmt);
				return fmt;
			}
		}
		class FPropInt32 : FPropVariant
		{
			int32 Val;
			FPropInt32(int32 &in val) { Val = val; }
			int32 opImplConv() const override { return Val; }
			int64 opImplConv() const override { return Val; }
			string opImplConv() const override { return "" + Val; }
			string Format(const string &in fmt) const override { return Text::Format(fmt, Val); }
		}
		class FPropUInt32 : FPropVariant
		{
			uint32 Val;
			FPropUInt32(int32 &in val) { Val = val; }
			uint32 opImplConv() const override { return Val; }
			uint64 opImplConv() const override { return Val; }
			string opImplConv() const override { return "" + Val; }
			string Format(const string &in fmt) const override { return Text::Format(fmt, Val); }
		}

		// While this is useful, frequent use can result in irregular frametime spikes likely due to memory alloc/dealloc
		class FPropAny
		{
			FPropVariant@ Prop;
			
			FPropAny(float &in val) { @Prop = FPropFloat(val); }
			FPropAny(double &in val) { @Prop = FPropDouble(val); }
			FPropAny(vec2 &in val) { @Prop = FPropVec2(val); }
			FPropAny(vec3 &in val) { @Prop = FPropVec3(val); }
			FPropAny(vec4 &in val) { @Prop = FPropVec4(val); }
			FPropAny(quat &in val) { @Prop = FPropQuat(val); }
			FPropAny(int32 &in val) { @Prop = FPropInt32(val); }
			FPropAny(uint32 &in val) { @Prop = FPropUInt32(val); }
			float opImplConv() const { return Prop; }
			double opImplConv() const { return Prop; }
			vec2 opImplConv() const { return Prop; }
			vec3 opImplConv() const { return Prop; }
			vec4 opImplConv() const { return Prop; }
			quat opImplConv() const { return Prop; }
			int8 opImplConv() const { return Prop; }
			int16 opImplConv() const { return Prop; }
			int32 opImplConv() const { return Prop; }
			int64 opImplConv() const { return Prop; }
			uint8 opImplConv() const { return Prop; }
			uint16 opImplConv() const { return Prop; }
			uint32 opImplConv() const { return Prop; }
			uint64 opImplConv() const { return Prop; }
			
			string opImplConv() const { return Prop; }
			string Format(const string &in fmt) const { return Prop.Format(fmt); }
		}
	}
}