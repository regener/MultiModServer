//Wario! - NewWarioHammer Low Speed,High DMG
//
/* CVARS - copy and paste to shconfig.cfg

//Wario 
Wario_level 21 
Wario_health 100	//Default 100 (no extra health)
Wario_armor 100		//Default 150
Wario_gravity .10	//Default 1.0 = no extra gravity (0.50 is 50% normal gravity, ect.)
Wario_speed 100		//Default -1 = no extra speed, this cvar is for all weapons (for faster then normal speed set to 261 or higher)
Wario_knifemult 2.1		//Damage multiplyer for his knife 
*/

#include <amxmodx>
#include <superheromod>
#include <fakemeta> 
new HeroName[] = "Wario"
new bool:HasHero[SH_MAXSLOTS+1]
 
new CvarknifeDmgMult 
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Wario","1.0","ak$pecial")
	
	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("Wario_level", "21")
	register_cvar("Wario_health", "100")
	register_cvar("Wario_armor", "100")
	register_cvar("Wario_gravity", ".10")
	register_cvar("Wario_speed", "100")
	CvarknifeDmgMult = register_cvar("Wario_knifemult", "2.1") 

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(HeroName, "Be Wario", "NewWarioHammer Low Speed,High DMG", false, "Wario_level")
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("Wario_init", "Wario_init")
	shRegHeroInit(HeroName, "Wario_init")
		
	// EVENTS
 
	register_event("CurWeapon", "weapon_change", "be", "1=1")
	register_event("Damage", "Wario_damage", "b", "2!0") 
	// Let Server know about the hero's variables
	shSetShieldRestrict(HeroName)
	shSetMaxHealth(HeroName, "Wario_health")
	shSetMaxArmor(HeroName, "Wario_armor")
	shSetMinGravity(HeroName, "Wario_gravity")
	shSetMaxSpeed(HeroName, "Wario_speed", "[0]")
}
public plugin_precache()
{ 
	precache_model("models/shmod/Wario_v_knife.mdl")
	} 
public Wario_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1, temp, 5)
	new id = str_to_num(temp)
	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2, temp, 5)
	new hasPowers = str_to_num(temp) 
	//
	// Reset their shield restrict status
	// Shield restrict MUST be before weapons are given out
	shResetShield(id)

	switch(hasPowers)
	{
		case true:
		{
			HasHero[id] = true

			if ( is_user_alive(id) )
			{ 
				Wario_weapons(id)
				switch_model(id)
			}
		} 
		case false:
		{ 
			// Check is needed since this gets run on clearpowers even if user didn't have this hero
	if ( is_user_alive(id) && HasHero[id] )
			{
				// This gets run if they had the power but don't anymore
				engclient_cmd(id, "drop", "weapon_knife") 
				 
				shRemHealthPower(id)
				shRemArmorPower(id)
				shRemGravityPower(id)
				shRemSpeedPower(id)
			}
	HasHero[id] = false 

			}
	} 
}

 

public Wario_weapons(id)
{
	if ( !shModActive() || !is_user_alive(id) || !HasHero[id] )
		return

	shGiveWeapon(id, "weapon_knife")
}
switch_model(id)
{
	if ( !shModActive() || !is_user_alive(id) || !HasHero[id] )
		return

	new clip, ammo, wpnid = get_user_weapon(id, clip, ammo)

	if ( wpnid == CSW_KNIFE )
	{
		set_pev(id, pev_viewmodel2, "models/shmod/Wario_v_knife.mdl")
	}
}
public weapon_change(id)
{
	if ( !shModActive() || !HasHero[id] )
		return

	new wpnid = read_data(2)

	if ( wpnid != CSW_KNIFE )
		return

	switch_model(id)

	new clip = read_data(3)

	// Never Run Out of Ammo!
	if ( clip == 0 )
		shReloadAmmo(id)
}
public Wario_damage(id)
{
	if ( !shModActive() || !is_user_alive(id) )
		return

	new weapon, bodypart, attacker = get_user_attacker(id, weapon, bodypart)

	if ( attacker <= 0 || attacker > SH_MAXSLOTS )
		return

	if ( HasHero[attacker] && weapon == CSW_KNIFE && is_user_alive(id) )
	{
		new damage = read_data(2)
		new headshot = bodypart == 1 ? 1 : 0

		// do extra damage
		new extraDamage = floatround(damage * get_pcvar_float(CvarknifeDmgMult) - damage)
		if ( extraDamage > 0 )
			shExtraDamage(id, attacker, extraDamage, "knife", headshot)
	}
} 


