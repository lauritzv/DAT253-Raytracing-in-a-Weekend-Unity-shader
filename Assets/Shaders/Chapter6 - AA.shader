Shader "Unlit/Raytracing/AASpheres"
{
	Properties
	{
		_aa_samples("Number of AA-samples", Range(1,100)) = 16
		[Toggle] _gammacorrect("Gamma-correction", Range(0,1)) = 1  // [Toggle] creates a checkbox in gui and gives it 0 or 1
		_sphereOneHeight("Interactive Sphere Height", Range(-2,5)) = 0
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

			class camera
			{
				vec3 lower_left_corner;
				vec3 horizontal;
				vec3 vertical;
				vec3 origin;

				void make()
				{
					lower_left_corner = vec3(-2, -1, -1);
					horizontal = vec3(4, 0, 0);
					vertical = vec3(0, 2, 0);
					origin = vec3(0, 0, 0);
				}

				ray get_ray(float u, float v)
				{
					ray r;
					r.make(origin, lower_left_corner + u * horizontal + v * vertical - origin);
					return r;
				}
			};

			vec3 normal_color(ray r)
			{
				hit_record rec;
				if (hit_anything(r, 0.0001, 1000, rec))
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
						rand_uv = j * i.uv;
						float ru = i.uv.x + random_number() / _ScreenParams.x;
						float rv = i.uv.y + random_number() / _ScreenParams.y;
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
