// SONIC! - from the Sega Sonic the Hedgehog video games.

/* CVARS - copy and paste to shconfig.cfg

//Sonic
sonic_level 0
sonic_gravity 0.40	//default 0.40 = lower gravity
sonic_armor 170	//default 170
sonic_health 170	//default 170
sonic_speed 510	//how fast he runs

*/

/*
* v1.2 - vittu - 6/22/05
*      - Minor code clean up.
*
*/

#include <amxmod>
#include <superheromod>

// VARIABLES
new gHeroName[]= "Sonic"
new bool:gHasSonicPower[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Sonic", "1.2", "D-unit")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("sonic_level", "0")
	register_cvar("sonic_gravity", "0.40")
	register_cvar("sonic_armor", "170")
	register_cvar("sonic_health", "170")
	register_cvar("sonic_speed", "510")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Fast & Jump High", "Run Fast, Jump High, more Health and Armor", false, "sonic_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("sonic_init", "sonic_init")
	shRegHeroInit(gHeroName, "sonic_init")

	// Let Server know about Sonic's Variables
	shSetMaxHealth(gHeroName, "sonic_health")
	shSetMinGravity(gHeroName, "sonic_gravity")
	shSetMaxArmor(gHeroName, "sonic_armor")
	shSetMaxSpeed(gHeroName, "sonic_speed", "[0]")

}
//----------------------------------------------------------------------------------------------
public sonic_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	// This gets run if they had the power but don't anymore
	if ( !hasPowers && gHasSonicPower[id] && is_user_alive(id) ) {
		shRemHealthPower(id)
		shRemGravityPower(id)
		shRemArmorPower(id)
		shRemSpeedPower(id)
	}

	// Sets this variable to the current status
	gHasSonicPower[id] = (hasPowers != 0)
}
//---------------------------------------------------------------------------------------------