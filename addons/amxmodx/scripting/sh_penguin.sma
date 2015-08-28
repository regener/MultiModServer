// PENGUIN! - From Batman. Oswald Chesterfield Cobblepot, is a "reformed" master criminal.

/*****AMX Mod X ONLY! Requires Fakemeta module*****/

/* CVARS - copy and paste to shconfig.cfg

//Penguin
penguin_level 0
penguin_grenademult 1.0		//Damage multiplyer, 1.0 = no xtra dmg (def 1.0)
penguin_grenadetimer 30.0	//How many seconds delay for new grenade after nade is thrown (def 30.0)
penguin_cooldown 120.0		//How many seconds until penguin grenade can be used again (def 120.0)
penguin_fuse 5.0			//Length of time Penguin grenades can seek for before blowing up (def 5.0)
penguin_nadespeed 900		//Speed of Penguin grenades when seeking (def 900)

*/

/*
* v1.2 - vittu - 9/28/05
*      - Minor code clean up and changes.
*      - Fixed getting actual grenade id.
*      - Fixed pausing of grenade blowing up used for fuse cvar.
*      - Fixed grenade touching to only explode on enemy contact.
*      - Added view model, so you know when you have a penguin nade.
*      - Made a hack job, so multiplier/cooldown will work if nade is paused
*          past when nades are supposed to blow. This will likely have bugs.
*
*    Based on AMXX Heatseeking Hegrenade 1.3 by Cheap_Suit.
*    HE Grenade Model by Opposing Forces Team, xinsomniacboix, Indolence, & haZaa.
*   	Yang wrote, "Cred goez to vittu's sexiness on gambit and cheap_suit who created the original plugin".
*/

#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <superheromod>

#define AMMOX_HEGRENADE 12

// GLOBAL VARIABLES
new gHeroName[]="Penguin"
new bool:gHasPenguinPower[SH_MAXSLOTS+1]
new bool:gPauseEntity[999]
new bool:gPenguinNade[SH_MAXSLOTS+1][999]
new Float:gNadeSpeed
new gSpriteTrail
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Penguin", "1.2", "Yang/vittu")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("penguin_level", "0")
	register_cvar("penguin_grenademult", "1.0")
	register_cvar("penguin_grenadetimer", "30.0")
	register_cvar("penguin_cooldown", "120.0")
	register_cvar("penguin_fuse", "5.0")
	register_cvar("penguin_nadespeed", "900")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Seeking HE-Penguins", "Throw HE Grenade strapped Pengiun friends that Seek out your enemy, also refill HE Grenades.", false, "penguin_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("penguin_init", "penguin_init")
	shRegHeroInit(gHeroName, "penguin_init")

	// NEW SPAWN
	register_event("ResetHUD", "newSpawn", "b")

	// EXTRA NADE DAMAGE
	register_event("Damage", "penguin_damage", "b", "2!0")

	// CURRENT WEAPON
	register_event("CurWeapon", "weaponChange", "be", "1=1")

	// FIND THROWN GRENADES
	register_event("AmmoX", "on_AmmoX", "b")

	// FAKEMETA FORWARD
	register_forward(FM_Think, "fw_entity_think", 0)

	// ROUND START
	register_logevent("round_start", 2, "1=Round_Start")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	gSpriteTrail = precache_model("sprites/smoke.spr")
	precache_model("models/shmod/penguin_w_hegrenade.mdl")
	precache_model("models/shmod/penguin_v_hegrenade.mdl")
}
//----------------------------------------------------------------------------------------------
public penguin_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	gHasPenguinPower[id] = (hasPowers!=0)

	if ( gHasPenguinPower[id] && is_user_alive(id) ) {
		penguin_weapons(id)
		switchmodel(id)
	}
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	if ( shModActive() && is_user_alive(id) && gHasPenguinPower[id] ) {
		gPlayerUltimateUsed[id] = false
		set_task(0.1, "penguin_weapons", id)
		for(new i = SH_MAXSLOTS+1; i < sizeof(gPauseEntity)-1; i++) {
			gPenguinNade[id][i] = false
		}
	}
}
//----------------------------------------------------------------------------------------------
public penguin_weapons(id)
{
	if ( shModActive() && is_user_alive(id) ) {
		shGiveWeapon(id, "weapon_hegrenade")
	}
}
//----------------------------------------------------------------------------------------------
public switchmodel(id)
{
	if ( !is_user_alive(id) || gPlayerUltimateUsed[id] ) return

	// If user is holding a shield do not change model, since we don't have one with a shield
	new v_mdl[32]
	entity_get_string(id, EV_SZ_viewmodel, v_mdl, 31)
	if ( containi(v_mdl, "v_shield_") != -1 ) return

	new clip, ammo, wpnid = get_user_weapon(id, clip, ammo)
	if ( wpnid == CSW_HEGRENADE ) {
		// Weapon Model change thanks to [CCC]Taz-Devil
		entity_set_string(id, EV_SZ_viewmodel, "models/shmod/penguin_v_hegrenade.mdl")
	}
}
//----------------------------------------------------------------------------------------------
public weaponChange(id)
{
	if ( !shModActive() || !gHasPenguinPower[id] || gPlayerUltimateUsed[id] ) return

	new wpnid = read_data(2)

	if ( wpnid != CSW_HEGRENADE ) return

	switchmodel(id)
}
//----------------------------------------------------------------------------------------------
public on_AmmoX(id)
{
	if ( !shModActive() || !is_user_alive(id) ) return

	new iAmmoType = read_data(1)
	new iAmmoCount = read_data(2)

	if ( iAmmoType == AMMOX_HEGRENADE && gHasPenguinPower[id] ) {

		if ( iAmmoCount == 0 ) {
			set_task(get_cvar_float("penguin_grenadetimer"), "penguin_weapons", id)

			if ( !gPlayerUltimateUsed[id] ) {
				new iGrenade = -1
				while ( (iGrenade = find_ent_by_class(iGrenade, "grenade")) > 0 ) {
					new model[32]
					entity_get_string(iGrenade, EV_SZ_model, model, 31)
					if ( id == entity_get_edict(iGrenade, EV_ENT_owner) && equal(model, "models/w_hegrenade.mdl") ) {
						entity_set_model(iGrenade, "models/shmod/penguin_w_hegrenade.mdl")

						// Set speed here since it gets called so much
						gNadeSpeed = get_cvar_float("penguin_nadespeed")
						if ( gNadeSpeed <= 0.0 ) gNadeSpeed = 1.0

						gPauseEntity[iGrenade] = true

						new parm[3]
						parm[0] = iGrenade
						parm[1] = id
						// If this changes so must nade_reset time or cooldown may not be set
						// The longer the nade_rest time the more chance for error with attacker identity
						set_task(1.0, "find_target", 0, parm, 3)

						// Set the fuse
						set_task(get_cvar_float("penguin_fuse"), "unpause_nade", iGrenade, parm, 2)
					}
				}
			}
		}
		else if ( iAmmoCount > 0 ) {
			// Got a new nade remove the timer
			remove_task(id)
		}
	}
}
//----------------------------------------------------------------------------------------------
public find_target(parm[])
{
	new grenadeID = parm[0]
	new grenadeOwner = parm[1]

	if ( is_valid_ent(grenadeID) ) {
		new shortestDistance = 9999
		new nearestPlayer = 0
		new distance, team[33], rgb[3], players[SH_MAXSLOTS], pnum

		get_user_team(grenadeOwner, team, 32)

		// Find all alive enemies and set trail color
		if ( cs_get_user_team(grenadeOwner) == CS_TEAM_CT ) {
			get_players(players, pnum, "ae", "TERRORIST")
			rgb = {50, 50, 175}
		}
		else {
			get_players(players, pnum, "ae", "CT")
			rgb = {175, 50, 50}
		}

		// Find the closest enemy
		for (new i = 0; i < pnum; i++) {
			if ( !is_user_alive(players[i]) ) continue

			distance =  get_entity_distance(players[i], grenadeID)

			if ( distance <= shortestDistance ) {
				shortestDistance = distance
				nearestPlayer = players[i]
			}
		}

		// Make the nade seek that enemy if one exists
		if ( nearestPlayer > 0 ) {
			// Trail on grenade
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(22)				// TE_BEAMFOLLOW
			write_short(grenadeID)		// entity:attachment to follow
			write_short(gSpriteTrail)	// sprite index
			write_byte(10)		// life in 0.1's
			write_byte(3)		// line width in 0.1's
			write_byte(rgb[0])	// r
			write_byte(rgb[1])	// g
			write_byte(rgb[2])	// b
			switch(random_num(0,2)) {
				case 0:write_byte(64)	// brightness
				case 1:write_byte(128)
				case 2:write_byte(192)
			}
			message_end()

			parm[2] = nearestPlayer
			set_task(0.1, "seek_target", grenadeID+1000, parm, 3, "b")
		}
	}
}
//----------------------------------------------------------------------------------------------
public seek_target(parm[])
{
	new grenade = parm[0]
	new target = parm[2]

	if ( !is_valid_ent(grenade) ) {
		remove_task(grenade+1000)
		return
	}

	if ( is_user_alive(target) ) {
		entity_set_follow(grenade, target)
	}
	else {
		// Remove the seek loop
		remove_task(grenade+1000)

		// Stop the Trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(99)			//TE_KILLBEAM
		write_short(grenade)	// entity
		message_end()

		// Find a new player to seek
		set_task(0.1, "find_target", 0, parm, 3)
	}
}
//----------------------------------------------------------------------------------------------
stock entity_set_follow(entity, target)
{
	if ( !is_valid_ent(entity) || !is_user_alive(target) ) return 0

	new Float:fl_Origin[3], Float:fl_EntOrigin[3]
	entity_get_vector(target, EV_VEC_origin, fl_Origin)
	entity_get_vector(entity, EV_VEC_origin, fl_EntOrigin)

	new Float:fl_InvTime = (gNadeSpeed / vector_distance(fl_Origin, fl_EntOrigin))

	new Float:fl_Distance[3]
	fl_Distance[0] = fl_Origin[0] - fl_EntOrigin[0]
	fl_Distance[1] = fl_Origin[1] - fl_EntOrigin[1]
	fl_Distance[2] = fl_Origin[2] - fl_EntOrigin[2]

	new Float:fl_Velocity[3]
	fl_Velocity[0] = fl_Distance[0] * fl_InvTime
	fl_Velocity[1] = fl_Distance[1] * fl_InvTime
	fl_Velocity[2] = fl_Distance[2] * fl_InvTime

	entity_set_vector(entity, EV_VEC_velocity, fl_Velocity)

	new Float:fl_NewAngle[3]
	vector_to_angle(fl_Velocity, fl_NewAngle)
	entity_set_vector(entity, EV_VEC_angles, fl_NewAngle)

	return 1
}
//----------------------------------------------------------------------------------------------
public pfn_touch(ptr, ptd)
{
	// Only if penguin nade touches an enemy explode, else wait for fuse timer to run out
	if (ptr <= SH_MAXSLOTS) return

	if ( !is_valid_ent(ptr) || !is_valid_ent(ptd) ) return

	new szClassNamePtr[32], szClassNamePtd[32]
	entity_get_string(ptr, EV_SZ_classname, szClassNamePtr, 31)
	entity_get_string(ptd, EV_SZ_classname, szClassNamePtd, 31)

	if ( !equal(szClassNamePtr, "grenade") && !equal(szClassNamePtd, "player") ) return
	if ( !gPauseEntity[ptr] ) return

	if ( !is_user_connected(ptd) || get_user_godmode(ptd) ) return

	new grenadeOwner = entity_get_edict(ptr, EV_ENT_owner)

	if ( cs_get_user_team(grenadeOwner) == cs_get_user_team(ptd) ) return

	new parm[2]
	parm[0] = ptr
	parm[1] = grenadeOwner
	unpause_nade(parm)
}
//----------------------------------------------------------------------------------------------
public unpause_nade(parm[])
{
	new ent = parm[0]
	new id = parm[1]

	remove_task(ent)

	gPenguinNade[id][ent] = true
	set_task(0.4, "nade_reset", 0, parm, 2)

	gPauseEntity[ent] = false
}
//----------------------------------------------------------------------------------------------
public nade_reset(parm[])
{
	new ent = parm[0]
	new id = parm[1]

	gPenguinNade[id][ent] = false
}
//----------------------------------------------------------------------------------------------
public fw_entity_think(ent)
{
	if ( ent <= SH_MAXSLOTS || ent > sizeof(gPauseEntity)-1 ) return FMRES_IGNORED

	if ( gPauseEntity[ent] ) {
		new Float:nextThink = entity_get_float(ent, EV_FL_nextthink)
		set_pev(ent, pev_nextthink, nextThink + 0.1)
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}
//----------------------------------------------------------------------------------------------
public penguin_damage(id)
{
	if ( !shModActive() || !is_user_connected(id) ) return

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

	if ( attacker == 0 && weapon == 0 && is_user_connected(id) ) {
		for ( new atkr = 1; atkr <= SH_MAXSLOTS; atkr++ ) {
			if ( gHasPenguinPower[atkr] && is_user_connected(atkr) && !gPlayerUltimateUsed[atkr] ) {
				for(new i = SH_MAXSLOTS+1; i < sizeof(gPauseEntity)-1; i++) {
					if ( gPenguinNade[atkr][i] ) {
						if ( is_user_alive(id) ) {
							// do extra damage
							new extraDamage = floatround(damage * get_cvar_float("penguin_grenademult") - damage)
							if (extraDamage > 0) shExtraDamage(id, atkr, extraDamage, "grenade")
						}

						new parm[2]
						parm[0] = i
						parm[1] = atkr
						// Set the cooldown in x seconds because nades can hurt more then one person
						set_task(0.2, "cooldown", 0, parm, 2)

						return
					}
				}
			}
		}
	}

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	if ( gHasPenguinPower[attacker] && is_user_connected(id) && weapon == CSW_HEGRENADE  && !gPlayerUltimateUsed[attacker] ) {
		if ( is_user_alive(id) ) {
			// do extra damage
			new extraDamage = floatround(damage * get_cvar_float("penguin_grenademult") - damage)
			if (extraDamage > 0) shExtraDamage(id, attacker, extraDamage, "grenade")
		}
		for(new i = SH_MAXSLOTS+1; i < sizeof(gPauseEntity)-1; i++) {
			if ( gPenguinNade[attacker][i] ) {
				new parm[2]
				parm[0] = i
				parm[1] = attacker
				// Set the cooldown in x seconds because nades can hurt more then one person
				set_task(0.2, "cooldown", 0, parm, 2)
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public cooldown(parm[])
{
	new grenade = parm[0]
	new id = parm[1]

	gPenguinNade[id][grenade] = false

	if ( !is_user_alive(id) || gPlayerUltimateUsed[id] ) return

	// Cooldown will only be set if user hurts someone with a Grenader nade
	new Float:penguinCooldown = get_cvar_float("penguin_cooldown")
	if (penguinCooldown > 0.0) ultimateTimer(id, penguinCooldown)
}
//----------------------------------------------------------------------------------------------
public round_start()
{
	// Reset any paused entity ids just in case
	for(new i = SH_MAXSLOTS+1; i < sizeof(gPauseEntity)-1; i++) {
		gPauseEntity[i] = false
	}
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gHasPenguinPower[id] = false
}
//----------------------------------------------------------------------------------------------