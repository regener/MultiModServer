// MOLE MAN! - from Marvel Comics, ruler of Subterranea and the creatures of Monster Island.

/* CVARS - copy and paste to shconfig.cfg

//Mole Man
moleman_level 5

*/

#include <amxmodx>
#include <engine>
#include <superheromod>

// GLOBAL VARIABLES
new HeroName[]="Mole Man"
new bool:HasMoleMan[SH_MAXSLOTS+1]
//--------------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Mole Man", "1.0", "vittu")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("moleman_level", "5")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(HeroName, "Tame Monsters", "Monsters will no longer attack or spawn on you.", false, "moleman_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("moleman_init", "moleman_init")
	shRegHeroInit(HeroName, "moleman_init")

	// NEW SPAWN
	register_event("ResetHUD", "newSpawn", "b")
}
//--------------------------------------------------------------------------------------------------
public moleman_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1, temp, 5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2, temp, 5)
	new hasPowers = str_to_num(temp)

	switch(hasPowers)
	{
		case true:
		{
			HasMoleMan[id] = true
			newSpawn(id)
		}

		case false:
		{
			if ( HasMoleMan[id] )
				reset_flag(id)

			HasMoleMan[id] = false
		}
	}
}
//--------------------------------------------------------------------------------------------------
public newSpawn(id)
{
	if ( !is_user_alive(id) || !HasMoleMan[id] || !shModActive() )
		return

	set_entity_flags(id, FL_NOTARGET, 1)
}
//--------------------------------------------------------------------------------------------------
reset_flag(id)
{
	if ( !is_user_alive(id) )
		return

	set_entity_flags(id, FL_NOTARGET, 0)
}
//--------------------------------------------------------------------------------------------------
public client_connect(id)
{
	HasMoleMan[id] = false
}
//--------------------------------------------------------------------------------------------------