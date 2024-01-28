// Collection of various helper functions
// Might need to clean up at some point
namespace RUtils
{
	vec4 CreateRandomColor(int32 i)
	{
		const float goldenAngle = 137.5077640;
		const float hue = i * goldenAngle;
		const float sat = 0.9 - 0.25 * 0.5 * (1 + Math::Sin(hue / 360.));
		const float val = 0.6 - 0.2 * 0.5 * (1 + Math::Cos(hue / 360.));

		return UI::HSV(hue, sat, val);
	}

	vec4 GetRectAtCursor(vec2 size, vec2 offset = vec2(0, 0))
	{
		offset += UI::GetWindowPos();
		offset += UI::GetCursorPos();
		return vec4(offset, size);
	}

	double InMS(int32 intInMs) { return double(intInMs); }
	int32 AsInt(double dblInMs) { return int32(dblInMs); }

	double Clamp(const double x, const double min, const double max)
	{
		if (x < min)
		{
			return min;
		}
		else if (x > max)
		{
			return max;
		}
		return x;
	}

	bool IsInRange(const double x, const double min, const double max)
	{
		 if (x < min || x > max)
		{
			return false;
		}
		return true;
	}
	
	bool IsInRange(const int32 x, const int32 min, const int32 max)
	{
		 if (x < min || x > max)
		{
			return false;
		}
		return true;
	}

	bool IsNearlyEqual(const float x, const float y, const float threshold = 1e-4)
	{
		return Math::Abs(x - y) < threshold;
	}
	bool IsNearlyEqual(const double x, const double y, const double threshold = 1e-4)
	{
		return Math::Abs(x - y) < threshold;
	}
	bool IsNearlyEqual(const vec2 &in x, const vec2 &in y, const double threshold = 1e-4)
	{
		return IsNearlyEqual(x.x, y.x, threshold) && IsNearlyEqual(x.y, y.y, threshold);
	}
	
	bool IsOnScreen(const vec2 &in ss)
	{
		return ss.x > 0 && ss.y > 0 &&
		ss.x < Draw::GetWidth() && ss.y < Draw::GetHeight();
	}

	

	int32 Lerp(const int32 a, const int32 b, const float t)
	{
		return int32(Math::Round(Math::Lerp(float(a), float(b), t)));
	}
}