// DRACULA!

/* CVARS - copy and paste to shconfig.cfg

//Dracula
dracula_level 0
dracula_pctperlev 0.03	//What percent of damage to give back per level of player

*/

// v1.17.5 - JTP - Added code to allow you to regen to your max heatlh

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Dracula"
new bool:gHasDracula[SH_MAXSLOTS+1]
new gPcvarPctPerLev
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Dracula", SH_VERSION_STR, "{HOJ} Batman/JTP10181")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("dracula_level", "0")
	gPcvarPctPerLev = register_cvar("dracula_pctperlev", "0.03")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Vampiric Drain", "Gain HP by attacking players - More HPs per level")
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if ( gHeroID != heroID ) return

	gHasDracula[id] = mode ? true : false

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
public client_damage(attacker, victim, damage, wpnindex)
{
	if ( !sh_is_active() ) return
	if ( !is_user_connected(victim) || !is_user_alive(attacker) ) return

	// Should nades not count? maybe remove them later
	if ( gHasDracula[attacker] && CSW_P228 <= wpnindex <= CSW_P90 ) {
		dracula_suckblood(attacker, damage)
	}
}
//----------------------------------------------------------------------------------------------
// Leave this public so it can be called with a forward from Longshot
public dracula_suckblood(attacker, damage)
{
	if ( sh_is_active() && gHasDracula[attacker] && is_user_alive(attacker) )
	{
		// Add some HP back!
		new giveHPs = floatround(damage * get_pcvar_float(gPcvarPctPerLev) * sh_get_user_lvl(attacker))

		// Get this here so it doesn't have to be called in sh_add_hp again
		new maxHPs = sh_get_max_hp(attacker)

		if ( get_user_health(attacker) < maxHPs && giveHPs > 0 )
		{
			new alphanum = clamp((damage * 2), 40, 200)
			sh_screen_fade(attacker, 0.5, 0.25, 255, 10, 10, alphanum) //Red Screen Flash
			sh_add_hp(attacker, giveHPs, maxHPs)
		}
	}
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gHasDracula[id] = false
}
//----------------------------------------------------------------------------------------------