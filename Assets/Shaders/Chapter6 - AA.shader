﻿Shader "Unlit/Raytracing/AASpheres"
{
	Properties
	{
		_aa_samples("Number of AA-samples", Range(1,100)) = 16
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

			vec3 normal_color(ray r)
			{
				hit_record rec;
				if (hit_anything(r, 0.0001, MAXIMUM_DEPTH, rec))
				{
					return 0.5 * (rec.normal + vec3(1, 1, 1));
				}
				else
				{
					return bgcolor(r);
				}
			}

			fixed4 frag(v2f i) : SV_Target
			{
				camera c;
				c.make();

				vec3 col = { 0,0,0 };
				ray r;
				if (_aa_samples > 1)
				{
					for (int j = 1; j <= _aa_samples; j++)
					{
						float rand_nr = rand(j*i.uv);
						float ru = i.uv.x + rand_nr / _ScreenParams.x;
						float rv = i.uv.y + rand_nr / _ScreenParams.y;
						r = c.get_ray(ru, rv);
						vec3 p = r.point_at_parameter(2.0);
						col += normal_color(r);
					}
					col /= _aa_samples;
				}
				else // AA samples = 1. No randomization for cleaner edges.
				{
					r = c.get_ray(i.uv.x, i.uv.y);
					col = normal_color(r);
				}

				if (_gammacorrect > 0) {
					col = sqrt(col); // gamma correction
				}
				return fixed4(col,1);
			}
			ENDCG
		}
	}
}