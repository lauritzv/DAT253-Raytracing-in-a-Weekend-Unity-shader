// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Fra https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509640(v=vs.85).aspx
//https://msdn.microsoft.com/en-us/library/windows/desktop/ff471421(v=vs.85).aspx
// https://docs.unity3d.com/Manual/RenderDocIntegration.html
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html

typedef vector <float, 3> vec3;  // to get more similar code to book
typedef vector <float, 2> vec2;
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

v2f vert(appdata v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	return o;
}

static float rand_seed = 0.0;
static float2 rand_uv = float2(0.0, 0.0);

//// http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
//// rand num generator http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
float noise(in vec2 uv)
{
	float2 n = frac(sin(dot(uv, float2(12.9898, 78.233) * 2.0)) * 43758.5453);
	return abs(n.x + n.y) * 0.5;
}

float random_number()
{
	float rn = noise(float2(rand_uv.x + rand_seed, rand_uv.y + rand_seed));
	rand_seed += 0.233;

	return rn;
}

vec3 random_in_unit_sphere()
{
	vec3 p;
	do {
		p = 2.0 * vec3(random_number(), random_number(), random_number()) - vec3(1.0, 1.0, 1.0);
	} while (dot(p, p) >= 1.0);
	return p;
}

struct hit_record
{
	float t;
	vec3 position;
	vec3 normal;
	int object_index;
};

vec3 reflect(vec3 v, vec3 n)
{
	return v - 2 * dot(v, n) * n;
}

bool refract(vec3 v, vec3 n, float ni_over_nt, out vec3 refracted)
{
	vec3 uv = normalize(v);
	float dt = dot(uv, n);
	float discriminant = 1.0 - ni_over_nt * ni_over_nt * (1 - dt * dt);
	if (discriminant > 0)
	{
		refracted = ni_over_nt * (uv - n * dt) - n * sqrt(discriminant);
		return true;
	}
	else return false;
}

float schlick(float cosine, float refraction)
{
	float r0 = (1.0 - refraction) / (1.0 + refraction);
	r0 *= r0;
	return r0 + (1.0 - r0) * pow(1.0 - cosine, 5);
}

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

class sphere 
{
	// geometry variables:
	vec3 center;
	float radius;

	// material variables:
	vec3 albedo;		// color
	int material_type;	// 0: lambertian diffuse (matte) / 1: metallic (reflective) / 2: dielectric (refractive)
	float fuzz;			// roughness
	float refraction;	// rafraction index

	//does the ray hit the sphere?
	bool hit(ray r, float t_min, float t_max, out hit_record record)
	{
		record.object_index = 0;

		vec3 oc = r.origin - center;

		float a = dot(r.direction, r.direction);
		float b = dot(oc, r.direction);
		float c = dot(oc, oc) - radius * radius;
		float discriminant = b * b - a * c;

		if (discriminant > 0.0) // intersected!
		{
			float temp = (-b - sqrt(discriminant)) / a;
			if (temp < t_max && temp > t_min)
			{
				record.t = temp;
				record.position = r.point_at_parameter(record.t);
				record.normal = (record.position - center) / radius;
				return true;
			}
			temp = (-b + sqrt(discriminant)) / a;
			if (temp < t_max && temp > t_min) {
				record.t = temp;
				record.position = r.point_at_parameter(record.t);
				record.normal = (record.position - center) / radius;
				return true;
			}
		}
		return false;
	}

	bool scatter(ray r, hit_record rec, out vec3 attenuation, out ray scattered)
	{
		if (material_type == 0) // chapter 7: diffuse lambertian
		{
			vec3 target = rec.position + rec.normal + random_in_unit_sphere();
			r.make(rec.position, target - rec.position);
			scattered = r;
			attenuation = albedo;
			return true;
		}

		else if (material_type == 1) // chapter 8: metallic
		{
			vec3 reflected = reflect(normalize(r.direction), rec.normal);
			r.make(rec.position, reflected + fuzz * random_in_unit_sphere() );
			scattered = r;
			attenuation = albedo;
			return (dot(scattered.direction, rec.normal) > 0);
		}

		else if (material_type == 2) // chapter 9: refractive dielectric
		{
			vec3 outward_normal;
			vec3 reflected = reflect(r.direction, rec.normal);
			float ni_over_nt;
			attenuation = vec3(1.0, 1.0, 1.0);
			vec3 refracted;
			float reflect_prob;
			float cosine;
			if (dot(r.direction, rec.normal) > 0.0)
			{
				outward_normal = -rec.normal;
				ni_over_nt = refraction;
				cosine = dot(r.direction, rec.normal) / length(r.direction);
				cosine = sqrt(1.0 - refraction * refraction * (1.0 - cosine * cosine));
			}
			else
			{
				outward_normal = rec.normal;
				ni_over_nt = 1.0 / refraction;
				cosine = -dot(r.direction, rec.normal) / length(r.direction);
			}
			if (refract(r.direction, outward_normal, ni_over_nt, refracted))
				reflect_prob = schlick(cosine, refraction);
			else reflect_prob = 1.0;
			
			if (random_number() < reflect_prob)
				scattered.make(rec.position, reflected);
			else
				scattered.make(rec.position, refracted);
			return true;
		}
		
		else // invalid material_type
		{
			scattered = r;
			attenuation = albedo;
			return false;
		}
	}

};

uint MAXIMUM_DEPTH = 7;
static const uint NUMBER_OF_SPHERES = 6;
static const sphere WORLD[NUMBER_OF_SPHERES] =
{
	// vec3 pos, float radius, vec3 albedo, int materialtype, float roughness, float rafraction
	{ vec3(0.0, 0.0, -1.0)      , 0.5   , vec3(0.8, 0.3, 0.3), 0, 0.0, 1.0}, //diffuse sphere
	{ vec3(0.0, -100.5, -1.0)   , 100.0 , vec3(0.8, 0.8, 0.0), 0, 0.0, 1.0}, // diffuse "ground"
	{ vec3(-1.11, -0.1, -2.12)  , 0.5   , vec3(0.3, 0.3, 0.4), 1, 0.3, 1.0},  // metallic sphere
	{ vec3(1.11, -0.2, -1.0)    , 0.3   , vec3(0.3, 0.3, 0.4), 1, 1.5, 1.0},  // metallic sphere
	{ vec3(-1.0, 0.0, -1.0)     , 0.5   , vec3(1.0, 1.0, 1.0), 2, 0.0, 1.5},  // dielectric sphere outer shell
	{ vec3(-1.0, 0.0, -1.0)     , -0.45 , vec3(1.0, 1.0, 1.0), 2, 0.0, 1.5}  // dielectric sphere inner shell
};

bool hit_anything(ray r, float t_min, float t_max, out hit_record record) 
{
	hit_record tempr;
	bool hit = false;
	float closest = t_max;

	for (uint i = 0; i < NUMBER_OF_SPHERES; i++)
	{
		sphere s = WORLD[i];

		if (s.hit(r, t_min, closest, tempr))
		{
			hit = true;
			closest = tempr.t;
			record = tempr;
			record.object_index = i;
		}
	}
	return hit;
}

vec3 bgcolor(ray r)
{
	vec3 unit_direction = r.direction;
	float t = 0.5*(unit_direction.y + 1.0);
	return (1 - t) * vec3(1, 1, 1) + t * vec3(0.5, 0.7, 1);
}

vec3 color(ray r)
{
	vec3 accumCol = vec3(1.0, 1.0, 1.0);
	hit_record rec;

	for (uint i = 0; i < MAXIMUM_DEPTH && hit_anything(r, 0.001, 1000.0, rec); i++)
	{
		ray scattered;
		vec3 attenuation;

		WORLD[rec.object_index].scatter(r, rec, attenuation, scattered);
		r = scattered;

		//vec3 target = rec.position + rec.normal + random_in_unit_sphere();
		//r.make(rec.position, target - rec.position);
		accumCol *= attenuation;
	}

	if (i == MAXIMUM_DEPTH)
		return vec3(0.0, 0.0, 0.0);
	else
		return accumCol * bgcolor(r);
}
