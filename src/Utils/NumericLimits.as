namespace NumericLimits
{
	const int8 INT8_MIN = -0x80;
	const int8 INT8_MAX = 0x7F;
	const int16 INT16_MIN = -0x8000;
	const int16 INT16_MAX = 0x7FFF;
	const int32 INT32_MIN = -0x80000000;
	const int32 INT32_MAX = 0x7FFFFFFF;
	const int64 INT64_MIN = -0x8000000000000000;
	const int64 INT64_MAX = 0x7FFFFFFFFFFFFFFF;
	const uint8 UINT8_MIN = 0x0;
	const uint8 UINT8_MAX = 0xFF;
	const uint16 UINT16_MAX = 0xFFFF;
	const uint16 UINT16_MIN = 0x0;
	const uint32 UINT32_MAX = 0xFFFFFFFF;
	const uint32 UINT32_MIN = 0x0;
	const uint64 UINT64_MAX = 0xFFFFFFFFFFFFFFFF;
	const uint64 UINT64_MIN = 0x0;

	const float FLT_MAX = 3.402823466e+38;
	const float FLT_LOWEST = -FLT_MAX;
	const float FLT_MIN = 1.175494351e-38;
	const float FLT_EPSILON = 1.192092896e-07;
	const float FLT_NAN = (vec2(0.) / vec2(0.)).x;
	const float FLT_INF = (vec2(1.) / vec2(0.)).x;

	const double DBL_MAX = 1.7976931348623158e+308;
	const double DBL_LOWEST = -DBL_MAX;
	const double DBL_MIN = 2.2250738585072014e-308;
	const double DBL_EPSILON = 2.2204460492503131e-016;
	const double DBL_NAN = (vec2(0.) / vec2(0.)).x;
	const double DBL_INF = (vec2(1.) / vec2(0.)).x;

}