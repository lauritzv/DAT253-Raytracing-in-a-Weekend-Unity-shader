Shader "Unlit/Raytracing/Dielectrics"
{
	Properties
	{
		_aa_samples("Number of AA-samples", Range(1,256)) = 16
		MAXIMUM_DEPTH("Max depth", Range(2,50)) = 7
		[Toggle] _gammacorrect("Gamma-correction", Range(0,1)) = 1  // [Toggle] creates a checkbox in gui and gives it 0 or 1
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			int _gammacorrect;
			int _aa_samples;

			#include "Assets/Shaders/includes.cginc"

			fixed4 frag(v2f i) : SV_Target
			{
				camera c;
				c.make();

				vec3 col = { 0,0,0 };
				ray r;
				for (int j = 1; j <= _aa_samples; j++)
				{
					rand_uv = j * i.uv;
					float ru = i.uv.x + random_number() / _ScreenParams.x;
					float rv = i.uv.y + random_number() / _ScreenParams.y;
					r = c.get_ray(ru, rv);
					//vec3 p = r.point_at_parameter(2.0);
					col += color(r);
				}

				col /= _aa_samples;

				if (_gammacorrect > 0) {
					col = sqrt(col); // gamma correction
				}
				return fixed4(col,1);
			}
			ENDCG
		}
	}
}
