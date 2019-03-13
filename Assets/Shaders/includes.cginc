// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Fra https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509640(v=vs.85).aspx
//https://msdn.microsoft.com/en-us/library/windows/desktop/ff471421(v=vs.85).aspx
// https://docs.unity3d.com/Manual/RenderDocIntegration.html
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html

typedef vector <float, 3> vec3;  // to get more similar code to book
typedef vector <fixed, 3> col3;

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float2 uv : TEXCOORD0;
	float4 vertex : SV_POSITION;
};

struct hit_record {
	float t;
	vec3 position;
	vec3 normal;
};

v2f vert(appdata v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	return o;
}

// http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
// rand num generator http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
float rand(in float2 uv)
{
	float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233)*2.0)) * 43758.5453));
	return abs(noise.x + noise.y) * 0.5;
};

class ray
{
	void make(vec3 orig, vec3 dir)
	{
		origin = orig;
		direction = dir;
	}
	vec3 point_at_parameter(float t)
	{
		return origin + t * direction;
	}
	vec3 origin;
	// access directly instead of via function
	vec3 direction;
};

//does the ray hit the sphere?
float hit_sphere(vec3 center, float radius, ray r)
{
	vec3 oc = r.origin - center;

	float a = dot(r.direction, r.direction);
	float b = 2 * dot(oc, r.direction);
	float c = dot(oc, oc) - radius * radius;
	float discriminant = b * b - 4.0 * a * c;
	if (discriminant < 0.0) 
	{
		return -1.0;
	}
	else 
	{
		return ( (-b -sqrt( discriminant )) / (2.0 * a) );
	}
};

vec3 bgcolor(ray r)
{
	vec3 unit_direction = r.direction;
	float t = 0.5*(unit_direction.y + 1.0);
	return (1 - t) * vec3(1, 1, 1) + t * vec3(0.5, 0.7, 1);
}

vec3 color(ray r) 
{
	col3 col;
	col3 spherecenter = { 0,0,-1 };
	float radius = 0.5;
	float t = hit_sphere(spherecenter, radius, r);
	if (t > 0.0)
	{
		vec3 N = normalize(r.point_at_parameter(t) - spherecenter);
		col = 0.5 * (N + vec3(1, 1, 1)); // rescale normal color to 0-1
	}
	else col = bgcolor(r);
	
	return col;
}

