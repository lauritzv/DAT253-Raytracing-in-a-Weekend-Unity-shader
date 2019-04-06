Shader "Unlit/Raytracing/MovableCamera"
{
	Properties
	{
		// Editor exposed parameters:
		_aa_samples("Number of AA-samples", Range(1,256)) = 64
		MAXIMUM_DEPTH("Max depth", Range(2,50)) = 16
		_vfov("V-FOV", Range(30.0,180.0)) = 90.0
		[Toggle] _gammacorrect("Gamma-correction", Range(0,1)) = 1  // [Toggle] creates a checkbox in gui and gives it 0 or 1

		// Parameters set from camera script:
		[HideInInspector]_CameraPosition("Camera-position", vector) = (-2.0, 2.0, 1.0, 0.0)
		[HideInInspector]_CameraTarget("Camera-target", vector) = (0.0, 0.0, -1.0, 0.0)
		[HideInInspector]_CameraUp("Camera-target", vector) = (0.0, 1.0, 0.0, 0.0)
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
			float _vfov;
			#include "Assets/Shaders/includes.cginc"

			vec3 _CameraPosition;
			vec3 _CameraTarget;
			vec3 _CameraUp;

			static const float PI = 3.14159265f;

			class movable_camera
			{
				vec3 lower_left_corner;
				vec3 horizontal;
				vec3 vertical;
				vec3 origin;

				void make(vec3 lookfrom, vec3 lookat, vec3 vup, float vfov, float aspect)
				{
					vec3 u;
					vec3 v;
					vec3 w;

					float theta = vfov * PI / 180.0;
					float half_height = tan(theta / 2.0);
					float half_width = aspect * half_height;
					origin = lookfrom;
					w = normalize(lookfrom - lookat);
					u = normalize(cross(vup, w));
					v = cross(w, u);

					lower_left_corner = origin - half_width * u - half_height * v - w;
					horizontal = 2 * half_width*u;
					vertical = 2 * half_height*v;
				}

				ray get_ray(float u, float v)
				{
					ray r;
					r.make(origin, lower_left_corner + u * horizontal + v * vertical - origin);
					return r;
				}
			};

			fixed4 frag(v2f i) : SV_Target
			{
				movable_camera c;
				c.make(_CameraPosition, _CameraTarget, _CameraUp, _vfov, float(_ScreenParams.x) / float(_ScreenParams.y) );

				vec3 col = { 0,0,0 };
				ray r;
				for (int j = 1; j <= _aa_samples; j++)
				{
					rand_uv = j * i.uv;
					float ru = i.uv.x + random_number() / _ScreenParams.x;
					float rv = i.uv.y + random_number() / _ScreenParams.y;
					r = c.get_ray(ru, rv);
					col += color(r);
				}

				col /= _aa_samples;

				if (_gammacorrect > 0)
					col = sqrt(col); // gamma correction
				
				return fixed4(col,1);
			}
			ENDCG
		}
	}
}
