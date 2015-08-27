// THOR! from Marvel Comics. Asgardian god, son of Odin, wielder of the enchanted uru hammer Mjolnir.

/* CVARS - copy and paste to shconfig.cfg

//Thor
thor_level 8
thor_pctofdmg 75		//Percent of Damage Taken that is dealt back at your attacker (def 75%)
thor_cooldown 45		//Amount of time before next available use (def 45)

*/

/*
* v1.2 - vittu - 12/31/05
*      - Cleaned up code.
*      - Changed damage cvar to a percent of damage taken.
*      - Changed sounds.
*      - Changed look of effects.
*
*/

#include <amxmod>
#include <superheromod>

// GLOBAL VARIABLES
new g_heroName[]="Thor"
new bool:g_hasThor[SH_MAXSLOTS+1]
new g_spriteLightning
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Thor", "1.1", "TreDizzle")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("thor_level", "8")
	register_cvar("thor_pctofdmg", "75")
	register_cvar("thor_cooldown", "45")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(g_heroName, "Thunder Bolt", "Strike Attackers with a Mighty Lightning Bolt from Thor's uru hammer Mjolnir.", false, "thor_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("thor_init", "thor_init")
	shRegHeroInit(g_heroName, "thor_init")

	// EVENTS
	register_event("ResetHUD", "newSpawn", "b")
	register_event("Damage", "thor_damage", "b", "2!0")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound("ambience/thunder_clap.wav")
	precache_sound("buttons/spark5.wav")
	g_spriteLightning = precache_model("sprites/lgtning.spr")
}
//----------------------------------------------------------------------------------------------
public thor_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	g_hasThor[id] = (hasPowers != 0)
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	gPlayerUltimateUsed[id] = false
}
//----------------------------------------------------------------------------------------------
public thor_damage(id)
{
	if ( !shModActive() || !is_user_connected(id) ) return
	if ( !g_hasThor[id] || gPlayerUltimateUsed[id] ) return

	new damage = read_data(2)
	new attacker = get_user_attacker(id)

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	// Thor still attacks if Thor user dies from attackers damage
	if ( is_user_alive(attacker) && !get_user_godmode(attacker) && id != attacker ) {
		emit_sound(id, CHAN_STATIC, "ambience/thunder_clap.wav", 0.6, ATTN_NORM, 0, PITCH_NORM)
		emit_sound(attacker, CHAN_STATIC, "buttons/spark5.wav", 0.4, ATTN_NORM, 0, PITCH_NORM)

		// Deal a % of the damage back at them
		new extraDamage = floatround(damage * get_cvar_num("thor_pctofdmg") * 0.01 )
		if (extraDamage == 0) extraDamage = 1
		shExtraDamage(attacker, id, extraDamage, "thunder bolt")

		// create some effects
		if ( extraDamage > 70 ) extraDamage = 70
		else if ( extraDamage < 20 ) extraDamage = 20
		lightning_effect(id, attacker, extraDamage)

		// make attacker feel it
		new alphanum = damage * 2
		if ( alphanum > 200 ) alphanum = 200
		else if ( alphanum < 40 ) alphanum = 40
		setScreenFlash(attacker, 255, 255, 224, 10, alphanum)
		sh_screenShake(attacker, 12, 10, 14)

		if ( is_user_alive(id) ) {
			// Set cooldown if Thor is still alive
			new thorCooldown = get_cvar_num("thor_cooldown")
			if (thorCooldown > 0) ultimateTimer(id, thorCooldown * 1.0)
		}
	}
}
//----------------------------------------------------------------------------------------------
public lightning_effect(id, targetid, lineWidth)
{
	// Main Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(8)				//TE_BEAMENTS
	write_short(id)			// start entity
	write_short(targetid)		// entity
	write_short(g_spriteLightning)	// model
	write_byte(0)			// starting frame
	write_byte(200)		// frame rate
	write_byte(15)			// life
	write_byte(lineWidth)	// line width
	write_byte(6)			// noise amplitude
	write_byte(255)		// r, g, b
	write_byte(255)		// r, g, b
	write_byte(224)		// r, g, b
	write_byte(125)		// brightness
	write_byte(0)			// scroll speed
	message_end()

	// Extra Lightning
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(8)				//TE_BEAMENTS
	write_short(id)			// start entity
	write_short(targetid)		// entity
	write_short(g_spriteLightning)	// model
	write_byte(10)			// starting frame
	write_byte(200)		// frame rate
	write_byte(15)			// life
	write_byte(floatround(lineWidth/2.5))	// line width
	write_byte(18)			// noise amplitude
	write_byte(255)		// r, g, b
	write_byte(255)		// r, g, b
	write_byte(224)		// r, g, b
	write_byte(125)		// brightness
	write_byte(0)			// scroll speed
	message_end()
}
//----------------------------------------------------------------------------------------------