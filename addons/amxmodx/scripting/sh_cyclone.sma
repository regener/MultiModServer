// CYCLONE!

/* CVARS - copy and paste to shconfig.cfg

//cyclone
cyclone_level 9
cyclone_cooldown 60		// Time in seconds the player must wait before he can use the power again
cyclone_range 1000		// Size of the cyclone
cyclone_force 800		// Power of the cyclone
cyclone_time 100			// Time in 1/10th of a second (10 sec now)
cyclone_playersonly	1	// The cyclone only picks up players if this is set to 1,
					// if set to 0 the cyclone will pick up all entities ( WARNING VERY HEAVY FOR YOUR CPU AND I-NET IF THE MAP CONTAINTS MANY ENTITIES)

	Made with some help from Gorlag/Batman and examples from sh_unclesam by AssKicR / vittu / Eric Lidman
	
UPDATES::
 - Added cooldown timer
 - Removed unnecesary code
 - Added CVAR force
 - Improved tornado physics
 - Players now swirl around the tornado
 - Entities are picked up by the cyclone
 - More efficient code
 - Other entities then players are now also picked up
*/

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Cyclone"
new bool:ghasCyclonePowers[SH_MAXSLOTS+1]
new gCycloneTimer, gCurrentCyclone				// Allow only 1 cyclone at the time for now ( I don't know what happens if 2 cyclones get caucht in each other )
new white, gSpriteLightning
new gRange, gForce
new bool:gPlayersOnly
new players[SH_MAXSLOTS], pnum

public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Cyclone","1.32","K-OS")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("cyclone_level", "9" )
	register_cvar("cyclone_cooldown", "60" )
	register_cvar("cyclone_range", "1000" )
	register_cvar("cyclone_force", "800" )
	register_cvar("cyclone_time", "100" )
	register_cvar("cyclone_playersonly", "1" )

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Tornado", "You become a cyclone and you sux", true, "cyclone_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","newRound","b")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_srvcmd("cyclone_init", "cyclone_init")
	shRegHeroInit(gHeroName, "cyclone_init")

	// KEY DOWN
	register_srvcmd("cyclone_kd", "cyclone_kd")
	shRegKeyDown(gHeroName, "cyclone_kd")

	// LOOP
	set_task(0.15,"cyclone_loop",0,"",0,"b" )
}

public plugin_precache()
{
	precache_sound("ambience/thunder_clap.wav")
	precache_sound("de_torn/tk_windStreet.wav")
	precache_sound("de_torn/torn_Templewind.wav")

	white = precache_model("sprites/xssmke1.spr")
	gSpriteLightning = precache_model("sprites/lgtning.spr")
}

public cyclone_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has wolverine skills
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	ghasCyclonePowers[id] = (hasPowers!=0)
}

public newRound(id)
{
	gCycloneTimer = 0
	gCurrentCyclone = 0
	gPlayerUltimateUsed[id] = false
}

public cyclone_kd()
{
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	if(!is_user_alive(id) )
		return PLUGIN_HANDLED

	if( gCurrentCyclone || gPlayerUltimateUsed[id] ) {
		client_print(id,print_chat,"[SH](Cyclone) The wind has no energy, let the wind rest first!")
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

//	client_print(id,print_chat,"[SH](Cyclone) The wind will take care of your enemies!")
	gCurrentCyclone = id
	gCycloneTimer = get_cvar_num("cyclone_time")
	gPlayersOnly = (get_cvar_num("cyclone_playersonly")!=0)
	gForce = get_cvar_num("cyclone_force")

	gPlayerUltimateUsed[id] = true
	ultimateTimer(id, float(get_cvar_num("cyclone_cooldown")))
	
	gRange = get_cvar_num("cyclone_range")

	playThunderSound(gCurrentCyclone)
	playWind1Sound(gCurrentCyclone)

	return PLUGIN_HANDLED
}

public cyclone_loop()
{
	if( !gCurrentCyclone) return

	if( !is_user_alive(gCurrentCyclone) || !shModActive() || gCycloneTimer < 1) {
		gCurrentCyclone = 0
		gCycloneTimer = 0
		return
	}

	gCycloneTimer--

	new Float:fl_Origin[3]
	entity_get_vector(gCurrentCyclone, EV_VEC_origin, fl_Origin)
	
	// Do the cool grafics stuff
	// Random Z vector
	new Origin[3]	
	FVecIVec(fl_Origin, Origin)
	Origin[2] += random(1000) - 200	// Mostly above the player

	new randomNum = 1 + random(19)
	WhiteFluffyCycloneWave(Origin, gRange/2, randomNum)
		
	if(randomNum == 1) {
		Origin[0] += random(800)-400
		Origin[1] += random(800)-400
		Origin[2] += 600
	
		lightning_effect(gCurrentCyclone, Origin, 20)
		playThunderSound(gCurrentCyclone)
	}
	else if(randomNum == 2)
		playWind1Sound(gCurrentCyclone)
	else if(randomNum == 3)
		playWind2Sound(gCurrentCyclone)
		
	// Do player physics	
	if(gPlayersOnly) {
		get_players(players, pnum, "a")
		for (new i = 0; i < pnum; i++) {
			if(players[i] == gCurrentCyclone) continue

			if(get_entity_distance(players[i], gCurrentCyclone) > gRange ) 	
				continue

			SuckPlayerIntoCyclone(players[i], fl_Origin, gRange/2)
		}
	}
	else {
		new mdlname[16], CycloneVictim = -1
		
		while( (CycloneVictim = find_ent_in_sphere(CycloneVictim, fl_Origin, float(gRange))) ) {
			if(CycloneVictim == gCurrentCyclone) continue
			
			entity_get_string(CycloneVictim , EV_SZ_model, mdlname, 16)
			if(contain(mdlname, "models") != -1)	// Only use ents with a model
				SuckPlayerIntoCyclone(CycloneVictim, fl_Origin, gRange/2)
		}
	}
}

SuckPlayerIntoCyclone(id, Float:fl_Eye[3], offset)
{
	new Float:fl_Player[3], Float:fl_Target[3], Float:fl_Velocity[3], Float:fl_Distance
	entity_get_vector(id, EV_VEC_origin, fl_Player)

	// I only want the horizontal direction
	fl_Player[2] = 0.0
	
	fl_Target[0] = fl_Eye[0]
	fl_Target[1] = fl_Eye[1]
	fl_Target[2] = 0.0

	// Calculate the direction and add some offset to the original target,
	// so we don't fly strait into the eye but to the side of it.

	fl_Distance = vector_distance(fl_Player, fl_Target)

	fl_Velocity[0] = (fl_Target[0] -  fl_Player[0]) / fl_Distance	
	fl_Velocity[1] = (fl_Target[1] -  fl_Player[1]) / fl_Distance

	fl_Target[0] += fl_Velocity[1]*offset
	fl_Target[1] -= fl_Velocity[0]*offset

	// Recalculate our direction and set our velocity
	fl_Distance = vector_distance(fl_Player, fl_Target)

	fl_Velocity[0] = (fl_Target[0] -  fl_Player[0]) / fl_Distance	
	fl_Velocity[1] = (fl_Target[1] -  fl_Player[1]) / fl_Distance

	fl_Velocity[0] = fl_Velocity[0] * gForce
	fl_Velocity[1] = fl_Velocity[1] * gForce
	fl_Velocity[2] = 0.4 * gForce
	
	entity_set_vector(id, EV_VEC_velocity, fl_Velocity)
}

WhiteFluffyCycloneWave(vec[3], radius, life)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec)
	write_byte(21)		//TE_BEAMCYLINDER
	write_coord(vec[0])
	write_coord(vec[1])
	write_coord(vec[2])
	write_coord(vec[0])
	write_coord(vec[1])
	write_coord(vec[2] + radius)
	write_short(white)
	write_byte(0)		// startframe
	write_byte(0)		// framerate
	write_byte(life)	// life
	write_byte(128)		// width 128
	write_byte(0)		// noise
	write_byte(255)		// r
	write_byte(255)		// g
	write_byte(255)		// b
	write_byte(200)		// brightness
	write_byte(0)		// scroll speed
	message_end()
}

lightning_effect(id, vec[3], life)
{
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY) //message begin
	write_byte(1)
	write_short(id)		// start entity
	write_coord(vec[0])	// end position
	write_coord(vec[1])
	write_coord(vec[2])
	write_short(gSpriteLightning) // sprite index
	write_byte(0)		// starting frame
	write_byte(0)		// frame rate in 0.1's
	write_byte(life)	// life in 0.1's
	write_byte(10)		// line width in 0.1's
	write_byte(25)		// noise amplitude in 0.01's
	write_byte(255)		// Red
	write_byte(255)		// Green
	write_byte(255)		// Blue
	write_byte(255)		// brightness
	write_byte(0)		// scroll speed in 0.1's
	message_end()
}

playThunderSound(id) {
	emit_sound(id, CHAN_AUTO, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}

playWind1Sound(id) {
	emit_sound(id, CHAN_AUTO, "de_torn/tk_windStreet.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}

playWind2Sound(id) {
	emit_sound(id, CHAN_AUTO, "de_torn/torn_Templewind.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}
