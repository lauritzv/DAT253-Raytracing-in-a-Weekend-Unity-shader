Shader "Unlit/Raytracing/UVGradient"
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

		col3 col = col3(
			i.uv.x,
			i.uv.y,
			0);
		return fixed4(col,1);
	}

	ENDCG
}
}}