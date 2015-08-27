// DAZZLER!

/* CVARS - copy and paste to shconfig.cfg

//Dazzler
dazzler_level 0
dazzler_radius 3000		//radius of people affected
dazzler_cooldown 15		//# of seconds before Dazzler can flash

*/

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Dazzler"
new bool:gHasDazzler[SH_MAXSLOTS+1]
new const gSoundFlash[] = "debris/beamstart15.wav"
new gSprite[4]
new gPcvarRadius, gPcvarCooldown
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Dazzler", SH_VERSION_STR, "{HOJ} Batman")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("dazzler_level", "0")
	gPcvarRadius = register_cvar("dazzler_radius", "3000")
	gPcvarCooldown = register_cvar("dazzler_cooldown", "15")

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Sparkle Flash", "Flash Nearby Enemies - Grows in intensity as you level up")
	sh_set_hero_bind(gHeroID)
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	gSprite[0] = precache_model("sprites/flare3.spr")
	gSprite[1] = precache_model("sprites/flare6.spr")
	gSprite[2] = precache_model("sprites/blueflare2.spr")
	gSprite[3] = precache_model("sprites/redflare2.spr")
	precache_sound(gSoundFlash)
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if ( gHeroID != heroID ) return

	gHasDazzler[id] = mode ? true : false

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerInCooldown[id] = false
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if ( gHeroID != heroID || sh_is_freezetime() ) return
	if ( !is_user_alive(id) || !gHasDazzler[id] ) return

	if ( key == SH_KEYDOWN ) {

		// Let them know they already used their ultimate if they have
		if ( gPlayerInCooldown[id] ) {
			sh_sound_deny(id)
			return
		}

		new Float:idLevelPct = float(sh_get_user_lvl(id)) / float(sh_get_num_lvls())

		new num = floatround(1.0 + (8.0 * idLevelPct))
		new life = floatround(1.0 + (8.0 * idLevelPct))
		new size = floatround(50.0 + (150.0 * idLevelPct))

		// just checks to see if this may be causing server crashes...
		life = clamp(life, 1, 10)
		size = clamp(size, 50, 200)

		// OK Power dazzle enemies closer than x distance
		new players[SH_MAXSLOTS], playerCount, player
		new fromOrigin[3], toOrigin[3], distanceBetween
		new dazzlerRadius = get_pcvar_num(gPcvarRadius)
		new CsTeams:idTeam = cs_get_user_team(id)
		new count = 0

		get_user_origin(id, fromOrigin)

		get_players(players, playerCount, "ah")

		for ( new i = 0; i < playerCount; i++ ) {
			player = players[i]

			if ( idTeam != cs_get_user_team(player) ) {
				get_user_origin(player, toOrigin)
				distanceBetween = get_distance(fromOrigin, toOrigin)

				if ( distanceBetween < dazzlerRadius ) {
					// tracer fireworks
					dazzler_sprite_flash(toOrigin, toOrigin, num, life, size, 10)
					dazzler_sprite_flash(fromOrigin, toOrigin, 10, 5, 10, 1000)

					emit_sound(id, CHAN_STATIC, gSoundFlash, VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)
					emit_sound(player, CHAN_STATIC, gSoundFlash, VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)

					count++
				}
			}
		}

		if ( count > 0 ) {
			new Float:cooldown = get_pcvar_float(gPcvarCooldown)
			if ( cooldown > 0.0 ) sh_set_cooldown(id, cooldown)
		}
	}
}
//----------------------------------------------------------------------------------------------
dazzler_sprite_flash(fromOrigin[3], toOrigin[3], count, life, size, speed)
{
	// TE_SPRITETRAIL - GLOW SPRITE
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITETRAIL)	// line of moving glow sprites with gravity, fadeout, and collisions
	write_coord(fromOrigin[0])	// pos
	write_coord(fromOrigin[1])
	write_coord(fromOrigin[2])
	write_coord(toOrigin[0])	// pos
	write_coord(toOrigin[1])
	write_coord(toOrigin[2] + 100)
	write_short(gSprite[random_num(0, 3)])	// (sprite index)
	write_byte(count)	// (count)
	write_byte(life)	// (life in 0.1's)
	write_byte(size)	// byte (scale in 0.1's)
	write_byte(speed)	// (velocity along vector in 10's)
	write_byte(5)		// (randomness of velocity in 10's)
	message_end()
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gHasDazzler[id] = false
}
//----------------------------------------------------------------------------------------------