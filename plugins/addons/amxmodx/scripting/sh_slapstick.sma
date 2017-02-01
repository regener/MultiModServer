#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

/* CVARS - copy into shconfig.cfg

// Slapstick
slapstick_level 5
slapstick_cooldown 10		// # of seconds before Slapstick can slap again
slapstick_slapdam 1			//How much damage per slap
slapstick_slapnum 10		//How many times does he slap
slapstick_slapvel 50		//How hard slaps are

*/

// Slapstick! Slap yourself away from enemies
// Forearm Modified by Emp`

// GLOBAL VARIABLES
#define TE_WORLDDECAL   116
#define TE_BLOODSPRITE    115

new gHeroName[]="Slapstick"
new bool:g_hasSlapstickPower[SH_MAXSLOTS+1]
new spr_blood_drop
new spr_blood_spray
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Slapstick","1.1","Emp`")

  // DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
  register_cvar("slapstick_level", "5" )
  register_cvar("slapstick_cooldown", "10" )
  register_cvar("slapstick_slapnum", "10" )
  register_cvar("slapstick_slapdam", "1" )
  register_cvar("slapstick_slapvel", "50" )

  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  shCreateHero(gHeroName, "Comic Slap!", "Slap yourself around the map!", true, "slapstick_level" )

  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  register_event("ResetHUD","newRound","b")

  // KEY DOWN
  register_srvcmd("slapstick_kd", "slapstick_kd")
  shRegKeyDown(gHeroName, "slapstick_kd")

  // INIT
  register_srvcmd("slapstick_init", "slapstick_init")
  shRegHeroInit(gHeroName, "slapstick_init")

}
//----------------------------------------------------------------------------------------------
public slapstick_init()
{
  new temp[6]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)

  // 2nd Argument is 0 or 1 depending on whether the id has iron man powers
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)

  g_hasSlapstickPower[id]=(hasPowers!=0)

}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
  spr_blood_drop = precache_model("sprites/blood.spr")
  spr_blood_spray = precache_model("sprites/bloodspray.spr")
}
//----------------------------------------------------------------------------------------------
public fx_blood(id)
{
    new origin[3]
    get_user_origin(id, origin)

    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_BLOODSPRITE)
    write_coord(origin[0]+random_num(-20,20))
    write_coord(origin[1]+random_num(-20,20))
    write_coord(origin[2]+random_num(-20,20))
    write_short(spr_blood_spray)
    write_short(spr_blood_drop)
    write_byte(248) // color index
    write_byte(10) // size
    message_end()
}
//----------------------------------------------------------------------------------------------
public fx_blood_large(id)
{
  new origin[3]
  get_user_origin(id, origin)
  // Blood decals
  static const blood_large[2] = {204,205}

  // Large splash
  for (new i = 0; i < 3; i++) {
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_WORLDDECAL)
    write_coord(origin[0]+random_num(-50,50))
    write_coord(origin[1]+random_num(-50,50))
    write_coord(origin[2]-36)
    write_byte(blood_large[random_num(0,1)]) // index
    message_end()
  }
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public slapstick_kd()
{
  if ( !hasRoundStarted() ) return PLUGIN_HANDLED

  new temp[6]
  // First Argument is an id with Forearm Powers!
  read_argv(1,temp,5)
  new id=str_to_num(temp)

  if ( !is_user_alive(id) ) return PLUGIN_HANDLED

  new Float:Cooldown = get_cvar_float("slapstick_cooldown")
  new slapnum = get_cvar_num("slapstick_slapnum")

  // Let them know they already used their ultimate if they have
  if ( gPlayerUltimateUsed[id] )
  {
    playSoundDenySelect(id)
    return PLUGIN_HANDLED
  }

  if ( !is_user_alive(id) ) return PLUGIN_HANDLED

  // okay, start the slapping
  set_task(0.5, "slap_self", id, "", 0, "a", slapnum)
  ultimateTimer(id, Cooldown)

  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public slap_self(id)
{
  if( !is_user_alive(id)) return

  new Float:vector[3], hp = get_user_health(id)
  new slapdam = get_cvar_num("slapstick_slapdam")
  new Float:slapvel = get_cvar_float("slapstick_slapvel")

  //only do the loop 3 times
  for(new i = 0; i<3; i++)
  {
    vector[i] = random_float(-1*slapvel, slapvel)
  }
  Entvars_Set_Vector(id, EV_VEC_velocity, vector)

  shExtraDamage(id, id, slapdam, "Comic Slap")

  if(hp<50)
    fx_blood_large(id)
  else if(hp<75)
    fx_blood(id)
}
//----------------------------------------------------------------------------------------------