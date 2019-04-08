Shader "Unlit/Raytracing/Background"
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
		float u = i.uv.x; 
		float v = i.uv.y;
		ray r;

		vec3 lower_left_corner = { -2, -1, -1 };
		vec3 horizontal = { 4, 0, 0 };
		vec3 vertical = { 0, 2, 0 };
		vec3 origin = { 0, 0, 0 };

		r.make(origin, lower_left_corner + u * horizontal + v * vertical);
		col3 col = bgcolor(r);

		return fixed4(col,1);
	}

ENDCG

}
}}