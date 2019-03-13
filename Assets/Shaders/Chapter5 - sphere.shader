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

		fixed4 frag(v2f i) : SV_Target
		{
			vec3 lower_left_corner = { -2, -1, -1 };
			vec3 horizontal = { 4, 0, 0 };
			vec3 vertical = { 0, 2, 0 };
			vec3 origin = { 0, 0, 0 };

			float u = i.uv.x;
			float v = i.uv.y; ray r;

			r.make(origin, lower_left_corner + u * horizontal + v * vertical);
			vec3 col = color(r);
			return fixed4(col,1);
		}
		ENDCG
	}
	}
}
