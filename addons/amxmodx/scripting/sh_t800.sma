// T-800- Robot powers

/* CVARS - copy and paste to shconfig.cfg

//T-800
t800_level 8
t800_time 5		        //How long is T-800 mode
t800_cooldown 30		//Whats the cooldown of T-800 mode
t800_paramult 5		    //how strong is the para

*/

#include <amxmod>
#include <superheromod>
#include <Vexd_Utilities>

// VARIABLES
new gHeroName[]="T-800"
new bool:gHasT800Power[SH_MAXSLOTS+1]
new gT800Timer[SH_MAXSLOTS+1]
new bool:gMorphed[SH_MAXSLOTS+1]
new gLastWeapon[SH_MAXSLOTS+1]
new gKills, gmsgScreenFade
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO T-800","2.0","Bum_Boy16")
 
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("t800_level", "8" )
        register_cvar("t800_time", "5" )
        register_cvar("t800_cooldown", "30" )
        register_cvar("t800_paramult", "5" )
  
	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Change into a T-800", "Get a giant mini gun and you are indistructable", true, "t800_level")
  
	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("t800_init", "t800_init")
	shRegHeroInit(gHeroName, "t800_init")

        // New Round
    	register_event("ResetHUD","t800_newround","b")

	// DEATH
	register_event("DeathMsg", "t800_death", "a")

        // Model Change
	register_event("CurWeapon","weaponChange","be","1=1")

        // Extra Damage
	register_event("Damage", "t800_damage", "b", "2!0")

	// LOOP
	set_task(1.0,"t800_loop",0,"",0,"b")

	// KEY DOWN
	register_srvcmd("t800_kd", "t800_kd")
	shRegKeyDown(gHeroName, "t800_kd")

	gmsgScreenFade = get_user_msgid("ScreenFade")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_model("models/shmod/t800_m249.mdl")
	precache_model("models/shmod/t800_minigun.mdl")
        precache_model("models/player/t800/t800.mdl")
}
//----------------------------------------------------------------------------------------------
public t800_init()
{
	// First Argument is an id
	new temp[128]
	read_argv(1,temp,5)
	new id=str_to_num(temp)
  
	// 2nd Argument is 0 or 1 depending on whether the id has iron man powers
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)
  
	gHasT800Power[id]=(hasPowers!=0)

	if ( !hasPowers ) {
		if ( is_user_alive(id) && gT800Timer[id] >= 0 ) {
			t800_endmode(id)
		}
	}
	else {
		gT800Timer[id] = -1
                if ( is_user_connected(id) ) switchmodel(id)
	}
}
//----------------------------------------------------------------------------------------------
public t800_newround(id)
{
	if ( gHasT800Power[id] && is_user_alive(id) && shModActive() ) {
              t800_endmode(id) 

	      new wpnid = read_data(2)
	      if (wpnid != CSW_M249 && wpnid > 0) {
		    new wpn[32]
		    get_weaponname(wpnid,wpn,31)
		    engclient_cmd(id,wpn)
	      } 
	}

	gPlayerUltimateUsed[id] = false
	gT800Timer[id] = -1
}
//----------------------------------------------------------------------------------------------
public t800_death()
{
	new id = read_data(2)

	gPlayerUltimateUsed[id] = false
	gT800Timer[id]= -1
	if (gHasT800Power[id]) {
		t800_endmode(id)
	}
}
//----------------------------------------------------------------------------------------------
public t800_loop()
{
	if (!shModActive()) return

	for ( new id = 1; id <= SH_MAXSLOTS; id++ ) {
		if ( gHasT800Power[id] && is_user_alive(id)  )  {
			if ( gT800Timer[id] > 0 ) {
				gT800Timer[id]--
				new message[128]
				format(message, 127, "%d seconds left of being a T-800 hurry up", gT800Timer[id])
				set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,87)
				show_hudmessage(id, message)

	                        // Make sure still on para
	                        new clip,ammo,weaponID = get_user_weapon(id,clip,ammo)
	                        if ( weaponID != CSW_M249 ) {
		                         shGiveWeapon(id,"weapon_m249",true)
	                         }

			        message_begin(MSG_ONE,gmsgScreenFade,{0,0,0},id)
			        write_short(15)
			        write_short(15)
			        write_short(12)
			        write_byte(255)
			        write_byte(0)
			        write_byte(0)
			        write_byte(50)
			        message_end()
			}
			else if ( gT800Timer[id] == 0 ) {
				   t800_endmode(id)
			}

                        if ( gT800Timer[id] == -1 ) {
				   drop_para(id)
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public switchmodel(id)
{
	if ( !is_user_alive(id) || !gHasT800Power[id] ) return

	//If user is holding a shield do not change model, since we don't have one with a shield
	new v_mdl[32]
	Entvars_Get_String(id, EV_SZ_viewmodel, v_mdl, 31)
	if ( containi(v_mdl, "v_shield_") != -1) return

	new wpnid = read_data(2)
	if (wpnid == CSW_M249) {
		// Weapon Model change thanks to [CCC]Taz-Devil
		Entvars_Set_String(id, EV_SZ_viewmodel, "models/shmod/t800_m249.mdl")
                Entvars_Set_String(id, EV_SZ_weaponmodel, "models/shmod/t800_minigun.mdl")
	}
}
//----------------------------------------------------------------------------------------------
public weaponChange(id)
{
	if ( !gHasT800Power[id] || !shModActive() ) return

	new wpnid = read_data(2)

	if ( wpnid == CSW_M249 ) switchmodel(id)
}
//----------------------------------------------------------------------------------------------
public t800_damage(id)
{
	if (!shModActive() || !is_user_alive(id)) return

	new damage = read_data(2)
	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)
	new headshot = bodypart == 1 ? 1 : 0

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	if ( gHasT800Power[attacker] && weapon == CSW_M249 && is_user_alive(id) ) {
		// do extra damage
		new extraDamage = floatround(damage * get_cvar_float("t800_paramult") - damage)
		if (extraDamage > 0) shExtraDamage( id, attacker, extraDamage, "m249", headshot )
	}
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public t800_kd()
{
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED

	// First Argument is an id with NightCrawler Powers!
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) || !is_user_connected(id) ) return PLUGIN_HANDLED

	// Let them know they already used their ultimate if they have
	if ( gPlayerUltimateUsed[id] || gT800Timer[id] > 0 ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

        if ( is_user_connected(id) && get_user_godmode(id) == 1 ) {
              playSoundDenySelect(id)
	      client_print(id,print_chat,"[SH](T-800) Error loading you are already in godmode")
              return PLUGIN_HANDLED
        }

	gT800Timer[id] = get_cvar_num("t800_time")+1
        shGiveWeapon(id,"weapon_m249",true) 
	set_user_godmode(id,1)
        t800_morph(id)
        gKills = get_user_frags(id)
	ultimateTimer(id, get_cvar_num("t800_cooldown") * 1.0)

	new message[128]
	format(message, 127, "You have become a T-800 KILL!")
	set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,87)
	show_hudmessage(id, message)

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public t800_morph(id)
{
	if ( !is_user_alive(id) || gMorphed[id] ) return

	#if defined AMXX_VERSION
	cs_set_user_model(id, "t800")
	#else
	CS_SetModel(id, "t800")
	#endif

	gMorphed[id] = true
}
//----------------------------------------------------------------------------------------------
public t800_endmode(id)
{
	gT800Timer[id] = -1
	setScreenFlash(id, 0, 0, 0, 1, 0)

	// Switch back to previous weapon...
	if ( gLastWeapon[id] != CSW_M249 ) shSwitchWeaponID( id, gLastWeapon[id] )

        if ( gMorphed[id] && is_user_connected(id) ) t800_unmorph(id)

	if ( gHasT800Power[id] && is_user_alive(id) ) {
	      set_user_godmode(id)
              drop_para(id)  
	}
}
//----------------------------------------------------------------------------------------------
public t800_unmorph(id)
{
        new totalkill = get_user_frags(id) - gKills

	if ( gMorphed[id] ) {
		set_hudmessage(255, 0, 0, -1.0, 0.45, 2, 0.02, 4.0, 0.01, 0.1, 86)
                if (totalkill == 1) {
		     show_hudmessage(id,"T-800 Mode has ended, you have killed 1 person")
                } 
                else {
		     show_hudmessage(id,"T-800 Mode has ended, you have killed %d people",totalkill)
                }
                 

		#if defined AMXX_VERSION
		cs_reset_user_model(id)
		#else
		CS_ClearModel(id)
		#endif

		gMorphed[id] = false
	}
}
//----------------------------------------------------------------------------------------------
public drop_para(id)
{
        engclient_cmd(id,"drop","weapon_m249")   

	new iCurrent = -1
	new Float:weapvel[3]

	while ( (iCurrent = FindEntity(iCurrent, "weaponbox")) > 0 ) {

		//Skip anything not owned by this client
		if ( Entvars_Get_Edict(iCurrent, EV_ENT_owner) != id) continue

		Entvars_Get_Vector(iCurrent, EV_VEC_velocity, weapvel)

		//If Velocities are all Zero its on the ground already and should stay there
		if (weapvel[0] == 0.0 && weapvel[1] == 0.0 && weapvel[2] == 0.0) continue

		RemoveEntity(iCurrent)
	}
}
//----------------------------------------------------------------------------------------------