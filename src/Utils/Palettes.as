
namespace CosPalette
{
	// The MIT License
	// https://www.youtube.com/c/InigoQuilez
	// https://iquilezles.org/
	// Copyright © 2015 Inigo Quilez
	// Copyright © 2024 Nico Ell: Modified for TM Angelscript
	// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	const vec3[] _A = 
	{
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.8,0.5,0.4),
		vec3(0.5,0.5,0.5),
	};
	const vec3[] _B = 
	{
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.5,0.5,0.5),
		vec3(0.2,0.4,0.2),
		vec3(0.5,0.5,0.5)
	};
	const vec3[] _C = 
	{
		vec3(1.0,1.0,1.0),
		vec3(1.0,1.0,1.0),
		vec3(1.0,1.0,1.0),
		vec3(1.0,1.0,0.5),
		vec3(1.0,0.7,0.4),
		vec3(2.0,1.0,0.0),
		vec3(2.0,1.0,1.0),
		vec3(0.5,0.5,0.5)
	};
	const vec3[] _D = 
	{
		vec3(0.0,0.33,0.67),
		vec3(0.0,0.10,0.20),
		vec3(0.3,0.20,0.20),
		vec3(0.8,0.90,0.30),
		vec3(0.0,0.15,0.20),
		vec3(0.5,0.20,0.25),
		vec3(0.0,0.25,0.25),
		vec3(-.5,-.25,0.00)
	};

	enum Presets
	{
		Rainbow = 0,
		DesertSky,
		Cream,
		Phaser,
		Variety,
		Eighties,
		Cactusflower,
		Spectrum
	};
	
	vec3 Col(const float t, const Presets preset)
	{
		return Col(t, _A[int(preset)], _B[int(preset)], _C[int(preset)], _D[int(preset)]);
	}

	vec3 Col(const float t, const int32 preset)
	{
		return Col(t, _A[int(preset)], _B[int(preset)], _C[int(preset)], _D[int(preset)]);
	}

	vec3 Col(const float t, const vec3 &in a, const vec3 &in b, const vec3 &in c, const vec3 &in d)
	{
		vec3 z = vec3(
			Math::Cos(6.28318f * (c.x * t + d.x)),
			Math::Cos(6.28318f * (c.y * t + d.y)),
			Math::Cos(6.28318f * (c.z * t + d.z)));
		return a + b * z;
	}

	vec3 Col(const int32 i, const Presets preset, const float fac = 0.1f)
	{
		return Col(float(i) * fac, _A[int(preset)], _B[int(preset)], _C[int(preset)], _D[int(preset)]);
	}

	vec3 Col(const int32 i, const int32 preset, const float fac = 0.1f)
	{
		return Col(float(i) * fac, _A[int(preset)], _B[int(preset)], _C[int(preset)], _D[int(preset)]);
	}

	vec3 Col(const int32 i, const vec3 &in a, const vec3 &in b, const vec3 &in c, const vec3 &in d, const float fac = 0.1f)
	{
		const float t = float(i) * fac;
		vec3 z = vec3(
			Math::Cos(6.28318f * (c.x * t + d.x)),
			Math::Cos(6.28318f * (c.y * t + d.y)),
			Math::Cos(6.28318f * (c.z * t + d.z)));
		return a + b * z;
	}
}