Shader "Unlit/Raytracing/Sphere"
{
	SubShader
	{
	Pass
	{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Assets/Shaders/includes.cginc"

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
				return ((-b - sqrt(discriminant)) / (2.0 * a));
			}
		};

		vec3 normal_color(ray r)
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

		fixed4 frag(v2f i) : SV_Target
		{
			vec3 lower_left_corner = { -2, -1, -1 };
			vec3 horizontal = { 4, 0, 0 };
			vec3 vertical = { 0, 2, 0 };
			vec3 origin = { 0, 0, 0 };

			float u = i.uv.x;
			float v = i.uv.y; ray r;

			r.make(origin, lower_left_corner + u * horizontal + v * vertical);
			vec3 col = normal_color(r);
			return fixed4(col,1);
		}
		ENDCG
	}
	}
}
