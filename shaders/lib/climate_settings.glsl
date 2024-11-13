// this file contains all things for seasons, weather, and biome specific settings.
// i gotta start centralizing shit someday. 

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////// SEASONS /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

//const float sunPathRotation;

/////////////////////////////////////////////////////////////////////////////// VERTEX SHADER
#ifdef Seasons
	#ifdef SEASONS_VSH

		//3D noise from 2d texture
		float densityAtPos2(in vec3 pos, float scale){
			vec3 p = floor(pos);
			vec3 f = fract(pos);
			vec2 uv =  p.xz + f.xz + p.y * vec2(0.0,1.0);
			vec2 coord =  uv/scale;
			
			//The y channel has an offset to avoid using two textures fetches
			vec2 xy = texture2D(noisetex, coord).yx;

			return mix(xy.r,xy.g, f.y/scale);
		}

		uniform int worldDay;  
		uniform float noPuddleAreas;

	    void YearCycleColor (
	        inout vec3 FinalColor,
	        vec3 glcolor,
			inout float SnowySeason,

			int leafID, // for DH 1 is leaves, 0 is not
			bool isPlants,
			mat4 gbufferModelViewInverse
	    ){
	    	// colors for things that arent leaves and using the tint index.
	    	vec3 SummerCol = vec3(Summer_R, Summer_G, Summer_B);
	    	vec3 AutumnCol = vec3(Fall_R, Fall_G, Fall_B);
	    	vec3 WinterCol = vec3(Winter_R, Winter_G, Winter_B) ;
	    	vec3 SpringCol = vec3(Spring_R, Spring_G, Spring_B);
			

			// decide if you want to replace biome colors or tint them.
			
			SummerCol *= glcolor;
			AutumnCol *= glcolor;
			WinterCol = vec3(1.0, 1.0, 0.5); // dormant grass
			SpringCol = vec3(1.0, 1.0, 0.5); // dormant grass

			// Create function here for DH that reads the input color and identifies what leaf it should be

	    	// do leaf colors different because thats cool and i like it
			switch (leafID) {
				case 1: // distant horizons leaves
					SummerCol = glcolor; // no change ever
					AutumnCol = glcolor;
					WinterCol = glcolor;
					SpringCol = vec3(1.0, 0.0, 0.0);
				case 16: // vines
				case 56: // oak leaves and others (tinted)
					SummerCol = glcolor; // no change for summer

					vec3 position = (mat3(gl_ModelViewMatrix) * vec3(gl_Vertex)) + gl_ModelViewMatrix[3].xyz;
					vec3 worldpos = mat3(gbufferModelViewInverse) * position + gbufferModelViewInverse[3].xyz + cameraPosition;
										
					float AutumnPatches = densityAtPos2(worldpos, 100.0) * 1.5;

					float sharpness = 2.0;
					AutumnPatches = 1/(1 + pow(AutumnPatches/(1-AutumnPatches), -sharpness));

					AutumnCol = mix(glcolor * vec3(Fall_Leaf_R, Fall_Leaf_G, Fall_Leaf_B), vec3(0.6, 0.2, 0.1), AutumnPatches);
					WinterCol = vec3(0.41, 0.33, 0.2); // winter brown (same color as oak log)
					SpringCol = vec3(0.82, 0.86, 0.4);
					break;
				case 57: // birch leaves
					SummerCol = glcolor; // no change for summer
					AutumnCol = vec3(1.6, 1.2, 0); // bright yellow fall birch
					WinterCol = vec3(0.9, 0.9, 0.9);
					SpringCol = glcolor * vec3(Spring_Leaf_R, Spring_Leaf_G, Spring_Leaf_B);
					break;
				case 58: // spruce leaves
					SummerCol = glcolor; // no change ever
					AutumnCol = glcolor;
					WinterCol = glcolor;
					SpringCol = glcolor;
					// SummerCol = vec3(0.0, 1.0, 0.0);
					// AutumnCol = vec3(1.0, 0.0, 0.0);
					// WinterCol = vec3(1.0, 1.0, 1.0);
					// SpringCol = vec3(0.0, 0.0, 1.0);
					break;
				case 59: // cherry leaves
					SummerCol = vec3(0.49, 0.57, 0.165); // give a normal leaf color in the summer
					AutumnCol = vec3(0.30, 0.10, 0.20); // burnt red ish
					WinterCol = vec3(0.22, 0.13, 0.17); // winter brown (same color as cherry log)
					SpringCol = vec3(1.0); // keep original (in this case, it is not made grayscale first)
					break;
				case 60: // azalea leaves
				case 61: // azalea plants
					SummerCol = vec3(1.0); // no change for summer
					AutumnCol = vec3(1.0, 0.5, 0);
					WinterCol = vec3(0.35, 0.27, 0.11);
					SpringCol = vec3(1.0);
					break;
			}

			// length of each season in minecraft days
			int SeasonLength = Season_Length; 

			// loop the year. multiply the season length by the 4 seasons to create a years time.
			float YearLoop = ((worldDay & 0xFFFF) + Start_Season * SeasonLength) % (SeasonLength * 4);

			// the time schedule for each season
			float SummerTime;
			float AutumnTime;
			float WinterTime;
			float SpringTime;

			if (leafID == 59 || leafID == 60) { // do not lerp for cherry or azalea leaves on either side of spring
				SummerTime =        clamp(YearLoop                  ,0, SeasonLength) / SeasonLength;
				AutumnTime =        clamp(YearLoop - SeasonLength   ,0, SeasonLength) / SeasonLength;
				WinterTime = floor( clamp(YearLoop - SeasonLength*2 ,0, SeasonLength) / SeasonLength);
				SpringTime = floor((clamp(YearLoop - SeasonLength*3 ,0, SeasonLength) / SeasonLength)+0.5);
			} else {
				SummerTime = clamp(YearLoop                  ,0, SeasonLength) / SeasonLength;
				AutumnTime = clamp(YearLoop - SeasonLength   ,0, SeasonLength) / SeasonLength;
				WinterTime = clamp(YearLoop - SeasonLength*2 ,0, SeasonLength) / SeasonLength;
				SpringTime = clamp(YearLoop - SeasonLength*3 ,0, SeasonLength) / SeasonLength;
			}

			// lerp all season colors together
			vec3 SummerToFall = mix(SummerCol,        AutumnCol, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, SummerTime))));
			vec3 FallToWinter =   mix(SummerToFall,   WinterCol, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, AutumnTime))));
			vec3 WinterToSpring = mix(FallToWinter,   SpringCol, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, WinterTime))));
			vec3 SpringToSummer = mix(WinterToSpring, SummerCol, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, SpringTime))));
			
			// make it so that you only have access to parts of the texture that use the tint index
			#ifdef DH_SEASONS
				bool IsTintIndex = isPlants || (leafID == 1);
				if(IsTintIndex) FinalColor = SpringToSummer;
			#else
				bool IsTintIndex = floor(dot(glcolor,vec3(0.5))) < 1.0 || (59 <= leafID && leafID <= 61);
				// multiply final color by the final lerped color, because it contains all the other colors.
				if(IsTintIndex) FinalColor = SpringToSummer;
			#endif



			#ifdef Snowy_Winter
				// this is to make snow only exist in winter
	    		float FallToWinter_snowfall = AutumnTime > 0.5 ? 1.0 : 0.0;
	    		float WinterToSpring_snowfall = mix(FallToWinter_snowfall, 0.0, pow(WinterTime, 3));
				SnowySeason = WinterToSpring_snowfall;
			#else
				SnowySeason = 0.0;
			#endif
	    }
	#endif
#endif

	    vec3 getSeasonColor( int worldDay ){

			// length of each season in minecraft days
			// for example, at 1, a season is 1 day long
	    	int SeasonLength = 1; 

			// loop the year. multiply the season length by the 4 seasons to create a years time.
	    	float YearLoop = mod(worldDay & 0xFFFF + SeasonLength, SeasonLength * 4);

	    	// the time schedule for each season
	    	float SummerTime = clamp(YearLoop                  ,0, SeasonLength) / SeasonLength;
	    	float AutumnTime = clamp(YearLoop - SeasonLength   ,0, SeasonLength) / SeasonLength;
	    	float WinterTime = clamp(YearLoop - SeasonLength*2 ,0, SeasonLength) / SeasonLength;
	    	float SpringTime = clamp(YearLoop - SeasonLength*3 ,0, SeasonLength) / SeasonLength;

	    	// colors for things
	    	vec3 SummerCol = vec3(Summer_R, Summer_G, Summer_B);
	    	vec3 AutumnCol = vec3(Fall_R, Fall_G, Fall_B);
	    	vec3 WinterCol = vec3(Winter_R, Winter_G, Winter_B);
	    	vec3 SpringCol = vec3(Spring_R, Spring_G, Spring_B);

	    	// lerp all season colors together
	    	vec3 SummerToFall =   mix(SummerCol,      AutumnCol, SummerTime);
	    	vec3 FallToWinter =   mix(SummerToFall,   WinterCol, AutumnTime);
	    	vec3 WinterToSpring = mix(FallToWinter,   SpringCol, WinterTime);
	    	vec3 SpringToSummer = mix(WinterToSpring, SummerCol, SpringTime);

	    	// return the final color of the year, because it contains all the other colors, at some point.
	    	return SpringToSummer;
	    }
///////////////////////////////////////////////////////////////////////////////
///////////////////////////// BIOME SPECIFICS /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

	uniform float nightVision;

	uniform float isJungles;
	uniform float isSwamps;
	uniform float isDarkForests;
	uniform float sandStorm;
	uniform float snowStorm;

#ifdef PER_BIOME_ENVIRONMENT

	void BiomeFogColor(
		inout vec3 FinalFogColor
	){
		

		// this is a little complicated? lmao
		vec3 BiomeColors = vec3(0.0);
		BiomeColors.r = isSwamps*SWAMP_R + isJungles*JUNGLE_R + isDarkForests*DARKFOREST_R + sandStorm*1.0 + snowStorm*0.9;
		BiomeColors.g = isSwamps*SWAMP_G + isJungles*JUNGLE_G + isDarkForests*DARKFOREST_G + sandStorm*0.5 + snowStorm*0.95;
		BiomeColors.b = isSwamps*SWAMP_B + isJungles*JUNGLE_B + isDarkForests*DARKFOREST_B + sandStorm*0.3 + snowStorm*1.0;

		// insure the biome colors are locked to the fog shape and lighting, but not its orignal color.
		BiomeColors *= max(dot(FinalFogColor,vec3(0.33333)), MIN_LIGHT_AMOUNT*0.025 + nightVision*0.2); 
		
		// these range 0.0-1.0. they will never overlap.
		float Inbiome = isJungles+isSwamps+isDarkForests+sandStorm+snowStorm;

		// interpoloate between normal fog colors and biome colors. the transition speeds are conrolled by the biome uniforms.
		FinalFogColor = mix(FinalFogColor, BiomeColors, Inbiome);
	}

	void BiomeFogDensity(
		inout vec4 UniformDensity,
		inout vec4 CloudyDensity,
		float maxDistance
	){	
		// these range 0.0-1.0. they will never overlap.
		float Inbiome = isJungles+isSwamps+isDarkForests+sandStorm+snowStorm;

		vec2 BiomeFogDensity = vec2(0.0); // x = uniform  ||  y = cloudy
		// BiomeFogDensity.x = isSwamps*SWAMP_UNIFORM_DENSITY + isJungles*JUNGLE_UNIFORM_DENSITY + isDarkForests*DARKFOREST_UNIFORM_DENSITY + sandStorm*15  + snowStorm*150;
		// BiomeFogDensity.y = isSwamps*SWAMP_CLOUDY_DENSITY + isJungles*JUNGLE_CLOUDY_DENSITY + isDarkForests*DARKFOREST_CLOUDY_DENSITY + sandStorm*255 + snowStorm*255;

		BiomeFogDensity.x = isSwamps*SWAMP_UNIFORM_DENSITY + isJungles*JUNGLE_UNIFORM_DENSITY + isDarkForests*DARKFOREST_UNIFORM_DENSITY + sandStorm*0.0 + snowStorm*0.01;
		BiomeFogDensity.y = isSwamps*SWAMP_CLOUDY_DENSITY + isJungles*JUNGLE_CLOUDY_DENSITY + isDarkForests*DARKFOREST_CLOUDY_DENSITY + sandStorm*0.5 + snowStorm*0.1;
		
		UniformDensity = mix(UniformDensity, vec4(BiomeFogDensity.x), Inbiome*maxDistance);
		CloudyDensity  = mix(CloudyDensity,  vec4(BiomeFogDensity.y), Inbiome*maxDistance);
	}

	float BiomeVLFogColors(inout vec3 DirectLightCol, inout vec3 IndirectLightCol){
		
		// this is a little complicated? lmao
		vec3 BiomeColors = vec3(0.0);
		BiomeColors.r = isSwamps*SWAMP_R + isJungles*JUNGLE_R + isDarkForests*DARKFOREST_R + sandStorm*1.0 + snowStorm*0.9;
		BiomeColors.g = isSwamps*SWAMP_G + isJungles*JUNGLE_G + isDarkForests*DARKFOREST_G + sandStorm*0.3 + snowStorm*0.95;
		BiomeColors.b = isSwamps*SWAMP_B + isJungles*JUNGLE_B + isDarkForests*DARKFOREST_B + sandStorm*0.1 + snowStorm*1.0;

		// insure the biome colors are locked to the fog shape and lighting, but not its orignal color.
		// DirectLightCol = BiomeColors * max(dot(DirectLightCol,vec3(0.33333)), MIN_LIGHT_AMOUNT*0.025 + nightVision*0.2); 
		// IndirectLightCol = BiomeColors * max(dot(IndirectLightCol,vec3(0.33333)), MIN_LIGHT_AMOUNT*0.025 + nightVision*0.2); 
		
		DirectLightCol = BiomeColors * max(dot(DirectLightCol,vec3(0.33333)), MIN_LIGHT_AMOUNT*0.025 + nightVision*0.2); 
		IndirectLightCol = BiomeColors * max(dot(IndirectLightCol,vec3(0.33333)), MIN_LIGHT_AMOUNT*0.025 + nightVision*0.2); 
		
		// these range 0.0-1.0. they will never overlap.
		float Inbiome = isJungles+isSwamps+isDarkForests+sandStorm+snowStorm;

		return Inbiome;
	}

#endif

///////////////////////////////////////////////////////////////////////////////
////////////////////////////// FOG CONTROLLER /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

#ifdef TIMEOFDAYFOG
	// uniform int worldTime;
	void FogDensities(
		inout float Uniform, inout float Cloudy, inout float Rainy, float maxDistance, float DailyWeather_UniformFogDensity, float DailyWeather_CloudyFogDensity
	) {
	
	    float Time = worldTime%24000;

		// set schedules for fog to appear at specific ranges of time in the day.
		float Morning = clamp((Time-22000.0)/2000.0,0.0,1.0) + clamp((2000.0-Time)/2000.0,0.0,1.0);
		float Noon 	  = clamp(Time/2000.0,0.0,1.0) * clamp((12000.0-Time)/2000.0,0.0,1.0);
		float Evening = clamp((Time-10000.0)/2000.0,0.0,1.0) * clamp((14000.0-Time)/2000.0,0.0,1.0);
		float Night   = clamp((Time-13000.0)/2000.0,0.0,1.0) * clamp((23000.0-Time)/2000.0,0.0,1.0);

		// set densities.		   morn, noon, even, night
		vec4 UniformDensity = TOD_Fog_mult * vec4(Morning_Uniform_Fog, Noon_Uniform_Fog, Evening_Uniform_Fog, Night_Uniform_Fog);
		vec4 CloudyDensity =  TOD_Fog_mult * vec4(Morning_Cloudy_Fog, Noon_Cloudy_Fog, Evening_Cloudy_Fog, Night_Cloudy_Fog);
		
		Rainy = Rainy*RainFog_amount;
		
		#ifdef Daily_Weather
			// let daily weather influence fog densities.
			UniformDensity = max(UniformDensity, DailyWeather_UniformFogDensity);
			CloudyDensity = max(CloudyDensity, DailyWeather_CloudyFogDensity);
		#endif

		#ifdef PER_BIOME_ENVIRONMENT
			BiomeFogDensity(UniformDensity, CloudyDensity, maxDistance); // let biome fog hijack to control densities, and overrride any other density controller...
		#endif

		Uniform *= Morning*UniformDensity.r + Noon*UniformDensity.g + Evening*UniformDensity.b + Night*UniformDensity.a;
		Cloudy *= Morning*CloudyDensity.r + Noon*CloudyDensity.g + Evening*CloudyDensity.b + Night*CloudyDensity.a;
	}
#endif
