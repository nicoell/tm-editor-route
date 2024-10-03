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

	void AddTooltipText(const string &in text)
	{
		if (text.Length > 0 && UI::IsItemHovered(UI::HoveredFlags::AllowWhenDisabled | 1 << 12))
		{
			UI::SetNextWindowSize(400, 0, UI::Cond::Appearing);
			UI::BeginTooltip();
			UI::TextWrapped(text);
			UI::EndTooltip();
		}
	}

	void HelpMarker(const string& in text)
	{
		UI::TextDisabled(Icons::QuestionCircle);
		AddTooltipText(text);
	}

	bool IsBase64Url(const string &in str)
	{
		// Check if the string contains only base64url characters
		string pattern = "^[A-Za-z0-9_-]+$";
		if (Regex::Match(str, pattern, Regex::Flags::ECMAScript).Length == 0)
		{
			return false;
		}

		// Check if the length is a multiple of 4 (after padding)
		int32 len = str.Length;
		int32 padLen = len % 4 == 0 ? 0 : 4 - (len % 4);

		if ((len + padLen) % 4 != 0)
		{
			return false;
		}

		return true;
	}

	bool CheckNaNOrInf(const float v, const string &in id = "Unnamed")
	{
		bool detected = false;
		if (Math::IsNaN(v)) {
			warn(id + ": NaN detected");
			detected = true;
		}
		if (Math::IsInf(v)) {
			warn(id + ": Inf detected");
			detected = true;
		}
		return detected;
	}

	bool CheckNaNOrInf(const double v, const string &in id = "Unnamed")
	{
		bool detected = false;
		if (Math::IsNaN(v)) {
			warn(id + ": NaN detected");
			detected = true;
		}
		if (Math::IsInf(v)) {
			warn(id + ": Inf detected");
			detected = true;
		}
		return detected;
	}

	bool CheckNaNOrInf(const vec2 &in v, const string &in id = "Unnamed")
	{
		bool detected = false;
		if (Math::IsNaN(v.x) || Math::IsNaN(v.y)) {
			warn(id + ": NaN detected in vec2");
			detected = true;
		}
		if (Math::IsInf(v.x) || Math::IsInf(v.y)) {
			warn(id + ": Inf detected in vec2");
			detected = true;
		}
		return detected;
	}

	bool CheckNaNOrInf(const vec3 &in v, const string &in id = "Unnamed")
	{
		bool detected = false;
		if (Math::IsNaN(v.x) || Math::IsNaN(v.y) || Math::IsNaN(v.z)) {
			warn(id + ": NaN detected in vec3");
			detected = true;
		}
		if (Math::IsInf(v.x) || Math::IsInf(v.y) || Math::IsInf(v.z)) {
			warn(id + ": Inf detected in vec3");
			detected = true;
		}
		return detected;
	}

	bool CheckNaNOrInf(const vec4 &in v, const string &in id = "Unnamed")
	{
		bool detected = false;
		if (Math::IsNaN(v.x) || Math::IsNaN(v.y) || Math::IsNaN(v.z) || Math::IsNaN(v.w)) {
			warn(id + ": NaN detected in vec4");
			detected = true;
		}
		if (Math::IsInf(v.x) || Math::IsInf(v.y) || Math::IsInf(v.z) || Math::IsInf(v.w)) {
			warn(id + ": Inf detected in vec4");
			detected = true;
		}
		return detected;
	}

	bool CheckNaNOrInf(const quat &in v, const string &in id = "Unnamed")
	{
		bool detected = false;
		if (Math::IsNaN(v.x) || Math::IsNaN(v.y) || Math::IsNaN(v.z) || Math::IsNaN(v.w)) {
			warn(id + ": NaN detected in quat");
			detected = true;
		}
		if (Math::IsInf(v.x) || Math::IsInf(v.y) || Math::IsInf(v.z) || Math::IsInf(v.w)) {
			warn(id + ": Inf detected in quat");
			detected = true;
		}
		return detected;
	}

	mat3 CreateOrthoBasisMat(vec3 forward, vec3 upward)
	{
		forward = forward.Normalized();
		upward -= forward * Math::Dot(upward, forward);
		upward = upward.Normalized();
		return mat3(/*right*/ Math::Cross(upward, forward).Normalized(), upward, forward);
	}

	vec3 OrthonormalizeBasisVectors(vec3 &out forward, vec3 &out upward)
	{
		forward = forward.Normalized();
		upward -= forward * Math::Dot(upward, forward);
		upward = upward.Normalized();
		return Math::Cross(upward, forward).Normalized();
	}

	quat CreateOrthoBasisQuat(const vec3&in forward, const vec3&in upward)
	{
		return OrthoBasisMatToQuat(CreateOrthoBasisMat(forward, upward));
	}

	quat OrthoBasisMatToQuat(const mat3 &in m)
	{
		// Adapted for OpenPlanet Angelscript
		// Based on https://d3cw3dd2w32x2b.cloudfront.net/wp-content/uploads/2015/01/matrix-to-quat.pdf
		// Obtained from https://math.stackexchange.com/a/3183435/220949
		// With considerations from Blender https://github.com/blender/blender/blob/main/source/blender/blenlib/intern/math_rotation.c 
		// - Avoids the need of normalization for degenerate case

		float s, x, y, z, w;
		if (m.zz < 0.0f) 
		{
			if (m.xx > m.yy) 
			{
				s = 2.0f * Math::Sqrt(/*trace*/ 1.0f + m.xx - m.yy - m.zz);
				if (m.yz < m.zy) { s = -s; }
				x = 0.25f * s;
				s = 1.0f / s;
				w = (m.yz - m.zy) * s;
				y = (m.xy + m.yx) * s;
				z = (m.zx + m.xz) * s;
				if ((s == 2.0f) && (w == 0.0f && y == 0.0f && z == 0.0f)) { x = 1.0f; }
			} else 
			{
				s = 2.0f * Math::Sqrt(/*trace*/ 1.0f - m.xx + m.yy - m.zz);
				if (m.zx < m.xz) { s = -s; }
				y = 0.25f * s;
				s = 1.0f / s;
				w = (m.zx - m.xz) * s;
				x = (m.xy + m.yx) * s;
				z = (m.yz + m.zy) * s;
				if ((s == 2.0f) && (w == 0.0f && x == 0.0f && z == 0.0f)) { y = 1.0f; }
			}
		} else 
		{
			if (m.xx < -m.yy) 
			{
				s = 2.0f * Math::Sqrt(/*trace*/ 1.0f - m.xx - m.yy + m.zz);
				if (m.xy < m.yx) { s = -s; }
				z = 0.25f * s;
				s = 1.0f / s;
				w = (m.xy - m.yx) * s;
				x = (m.zx + m.xz) * s;
				y = (m.yz + m.zy) * s;
				if ((s == 2.0f) && (w == 0.0f && x == 0.0f && y == 0.0f)) { z = 1.0f; }
			} else 
			{
				s = 2.0f * Math::Sqrt(/*trace*/ 1.0f + m.xx + m.yy + m.zz);
				w = 0.25f * s;
				s = 1.0f / s;
				x = (m.yz - m.zy) * s;
				y = (m.zx - m.xz) * s;
				z = (m.xy - m.yx) * s;
				if ((s == 2.0f) && (x == 0.0f && y == 0.0f && z == 0.0f)) { w = 1.0f; }
			}
		}
		return quat(x, y, z, w);
	}

	bool ShouldUseEditorPlusPlus()
	{
AS_IF DEPENDENCY_EDITOR
		if (!Setting_Enable3DLines) { return false; }
		auto epp = Meta::GetPluginFromID("Editor");
		return (epp is null) ? false : epp.Enabled;
AS_ELSE
		return false;
AS_ENDIF
	}

#if ER_DEBUG
	void DebugTrace(const string& in s){ trace(Icons::MapO + s); }
	void DebugPrint(const string& in s){ print(Icons::MapO + s); }
	void DebugWarn(const string& in s){ warn(Icons::MapO + s); }
	void DebugError(const string& in s){ error(Icons::MapO + s); }
#else
	void DebugTrace(const string& in s){ }
	void DebugPrint(const string& in s){ }
	void DebugWarn(const string& in s){ }
	void DebugError(const string& in s){ }
#endif
}
