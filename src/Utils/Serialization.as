class FArchive
{
	Json::Value@ Data = null;
	uint32 Length { get const { return Data.Length; } }

	FArchive() { @Data = null; }
	FArchive(Json::Value &in data) { @Data = data; }
	FArchive(FArchive &in ar) { @Data = ar.Data; }

	FArchive@ opAssign(const FArchive &in ar) { @Data = ar.Data; return this; }
	
	FArchive(int8 x) { @Data = Json::Value(x); }
	FArchive(int16 x) { @Data = Json::Value(x); }
	FArchive(int32 x) { @Data = Json::Value(x); }
	FArchive(int64 x) { @Data = Json::Value(x); }
	FArchive(uint8 x) { @Data = Json::Value(x); }
	FArchive(uint16 x) { @Data = Json::Value(x); }
	FArchive(uint32 x) { @Data = Json::Value(x); }
	FArchive(uint64 x) { @Data = Json::Value(x); }
	FArchive(float x) { @Data = Math::IsInf(x) || Math::IsNaN(x) ? Json::Value("NaN") : Json::Value(x); }
	FArchive(double x) { @Data = Math::IsInf(x) || Math::IsNaN(x) ? Json::Value("NaN") : Json::Value(x); }
	FArchive(bool x) { @Data = Json::Value(x); }
	FArchive(const vec2 &in x) 
	{
		@Data = Json::Array(); 
		for(int32 i = 0; i < 2; i++)
		{
			if (Math::IsInf(x[i]) || Math::IsNaN(x[i])) { @Data = Json::Value("NaN" ); return; }
			Data.Add(x[i]);
		}
	}
	FArchive(const vec3 &in x) 
	{
		@Data = Json::Array(); 
		for(int32 i = 0; i < 3; i++)
		{
			if (Math::IsInf(x[i]) || Math::IsNaN(x[i])) { @Data = Json::Value("NaN" ); return; }
			Data.Add(x[i]);
		}
	}
	FArchive(const vec4 &in x) 
	{
		@Data = Json::Array(); 
		for(int32 i = 0; i < 4; i++)
		{
			if (Math::IsInf(x[i]) || Math::IsNaN(x[i])) { @Data = Json::Value("NaN" ); return; }
			Data.Add(x[i]);
		}
	}
	FArchive(const quat &in x) 
	{
		@Data = Json::Array(); 
		if (Math::IsInf(x.x) || Math::IsNaN(x.x)) { @Data = Json::Value("NaN" ); return; }
		Data.Add(x.x);
		if (Math::IsInf(x.y) || Math::IsNaN(x.y)) { @Data = Json::Value("NaN" ); return; }
		Data.Add(x.y);
		if (Math::IsInf(x.z) || Math::IsNaN(x.z)) { @Data = Json::Value("NaN" ); return; }
		Data.Add(x.z);
		if (Math::IsInf(x.w) || Math::IsNaN(x.w)) { @Data = Json::Value("NaN" ); return; }
		Data.Add(x.w);
	}

	int8 opImplConv() const { return Data; }
	int16 opImplConv() const { return Data; }
	int32 opImplConv() const { return Data; }
	int64 opImplConv() const { return Data; }
	uint8 opImplConv() const { return Data; }
	uint16 opImplConv() const { return Data; }
	uint32 opImplConv() const { return Data; }
	uint64 opImplConv() const { return Data; }
	float opImplConv() const { return Data.GetType() != Json::Type::Number ? NumericLimits::FLT_NAN : Data; }
	double opImplConv() const{ return Data.GetType() != Json::Type::Number ? NumericLimits::DBL_NAN : Data; }
	bool opImplConv() const { return Data; }
	vec2 opImplConv() const { auto v = Data; return v.GetType() == Json::Type::Array ? vec2(v[0], v[1]) : vec2(NumericLimits::FLT_NAN); }
	vec3 opImplConv() const { auto v = Data; return v.GetType() == Json::Type::Array ? vec3(v[0], v[1], v[2]) : vec3(NumericLimits::FLT_NAN); }
	vec4 opImplConv() const { auto v = Data; return v.GetType() == Json::Type::Array ? vec4(v[0], v[1], v[2], v[3]) : vec4(NumericLimits::FLT_NAN); }
	quat opImplConv() const { auto v = Data; return v.GetType() == Json::Type::Array ? quat(v[0], v[1], v[2], v[3]) : quat(NumericLimits::FLT_NAN); }

	FArchive Get(const string &in key) const { return FArchive(Data[key]); }
	FArchive Get(const int32 idx) const { return FArchive(Data[idx]); }
	FArchive Get(const string &in key, const FArchive &in defaultValue) const
	{
		auto ar = Get(key);
		if (ar.GetType() != Json::Type::Null && ar.Data.GetType() != Json::Type::Unknown)
		{ 
			return ar;
		}
		return defaultValue;
	}
	FArchive Get(const int32 idx, const FArchive &in defaultValue) const
	{
		auto ar = Get(idx);
		if (ar.GetType() != Json::Type::Null && ar.Data.GetType() != Json::Type::Unknown)
		{ 
			return ar;
		}
		return defaultValue;
	}
	FArchive Get(const string &in key, Json::Value &in defaultValue) const
	{
		auto ar = Get(key);
		if (ar.GetType() != Json::Type::Null && ar.Data.GetType() != Json::Type::Unknown)
		{ 
			return ar;
		}
		return FArchive(defaultValue);
	}
	FArchive Get(const int32 idx, Json::Value &in defaultValue) const
	{
		auto ar = Get(idx);
		if (ar.GetType() != Json::Type::Null && ar.Data.GetType() != Json::Type::Unknown)
		{ 
			return ar;
		}
		return FArchive(defaultValue);
	}

	Json::Type GetType() const { return Data.GetType(); }

	void Set(const string &in key, FArchive &in ar) { Data[key] = ar.Data; }
	void Set(const int32 idx, FArchive &in ar) { Data[idx] = ar.Data; }
	void Set(const string &in key, Json::Value &in data) { Data[key] = data; }
	void Set(const int32 idx, Json::Value &in data) { Data[idx] = data; }

	bool HasKey(const string &in key) const { return Data.HasKey(key); }
	void Remove(const string &in key) { Data.Remove(key); }
	void Remove(const int32 idx) { Data.Remove(idx); }

	void Add(Json::Value@ data) { Data.Add(data); }
	void Add(FArchive@ ar) { Data.Add(ar.Data); }

	string[]@ GetKeys() const { return Data.GetKeys(); }
}
