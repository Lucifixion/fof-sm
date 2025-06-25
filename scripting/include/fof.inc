#if defined _fof_included
	#endinput
#endif
#define _fof_included

enum FOFTeam
{
	FOFTeam_Unassigned = 0,
	FOFTeam_Spectator,
	FOFTeam_Vigilantes,
	FOFTeam_Desperados,
	FOFTeam_Banditos,
	FOFTeam_Rangers,
	FOFTeam_Zombies,

	FOFTeam_COUNT,
};

enum FOFResourceType
{
	FOFResource_Ping,
	FOFResource_Score,
	FOFResource_Exp, // Notoriety
	FOFResource_FoFState, // Badges/Dev marks, what a blunder.
	FOFResource_Deaths,
	FOFResource_Connected,
	FOFResource_Team,
	FOFResource_Alive,
	FOFResource_Health,
	FOFResource_COUNT,
};

enum FOFState
{
	FOFState_Flag0 = 0, // 0
	FOFState_Insatiable = 1, // PERK, enabled by default
	FOFState_BrassKnuckles = 2, // PERK
	FOFState_Quickdraw, // PERK, unused
	FOFState_HasSecondaryFire,
	FOFState_Flag5, // 5, used by bots in cm
	FOFState_HandgunThrow, // PERK
	FOFState_Boots,
	FOFState_Flag8, // mask thing
	FOFState_Flag9,
	FOFState_Scoped,
	// BREAK BAD STATES
	FOFState_Disarmed,
	FOFState_Flag12,
	FOFState_HasLoot,
	FOFState_CanFistfight,
	FOFState_PublicEnemy, // cash scale thing ?? perhaps public enemy
	FOFState_PunchingOrThrowing,
	FOFState_WantsWeapon,
	// END OF BREAK BAD STATES
	FOFState_Flag18,
	FOFState_DynamiteBundle,
	FOFState_Slide = 20, // PERK
	FOFState_Jumpmaster = 21, // PERK
	FOFState_Flag22,
	FOFState_HeavyLoads = 23, // PERK
	FOFState_Flag24,
}

enum FOFAmmoType
{
	FOFAmmo_Dummy,
	FOFAmmo_Revolver = 1, // 357
	FOFAmmo_Rifle = 2,
	FOFAmmo_Rifle2,
	FOFAmmo_XBowBolt,
	FOFAmmo_XBowBolt2,
	FOFAmmo_Knife,
	FOFAmmo_Axe,
	FOFAmmo_Machete = 8,
	FOFAmmo_Buckshot = 9,
	FOFAmmo_RockSalt = 10,
	FOFAmmo_Grenade,
	FOFAmmo_Dynamite_B,
	FOFAmmo_Dynamite_weak,
	FOFAmmo_Gatling,
}

/**
 * Removes all weapons from a client
 *
 * @param client        Player's index.
 */
public void FOF_RemoveAllWeapons(int client)
{
	int offset = FindSendPropInfo( "CFOF_Player","m_hMyWeapons" );

	for(int i = 0; i < 48; i++)
	{
		int weapon = GetEntDataEnt2( client, offset + (i * 4) );

		if( weapon == -1 ) continue;

		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
}

/**
 * Check whether or not a state is set on a player
 *
 * @param client        Player's index.
 * @param state         FOFState constant
 * @return              True if set, false otherwise
 * @error               Invalid client index.
 */
stock bool FOF_IsClientInState(int client, FOFState state)
{
	int currentClientState = GetEntProp(client, Prop_Send, "m_nPlayerInfo");
	int bit = 1 << view_as<int>(state);
	return ((currentClientState & bit) == bit);
}

/**
 * Add a state to a player
 *
 * @param client        Player's index.
 * @param state         FOFState constant
 * @error               Invalid client index.
 */
stock void FOF_AddClientState(int client, FOFState state)
{
	int currentClientState = GetEntProp(client, Prop_Send, "m_nPlayerInfo");
	int bit = 1 << view_as<int>(state);
	SetEntProp(client, Prop_Send, "m_nPlayerInfo", currentClientState | bit );
}

/**
 * Remove a state from a player
 *
 * @param client        Player's index.
 * @param state         FOFState constant
 * @error               Invalid client index.
 */
stock void FOF_RemoveClientState(int client, FOFState state)
{
	int currentClientState = GetEntProp(client, Prop_Send, "m_nPlayerInfo");
	int bit = 1 << view_as<int>(state);
	SetEntProp(client, Prop_Send, "m_nPlayerInfo", currentClientState & ~bit ); 
}

/**
 * Gets a client's current team.
 *
 * @param client        Client index.
 * @return              Current FOFTeam of client.
 * @error               Invalid client index.
 */
stock FOFTeam FOF_GetClientTeam(int client)
{
	return view_as<FOFTeam>(GetClientTeam(client));
}

/**
 * Sets a client's current team.
 *
 * @param client        Client index.
 * @param team          FOFTeam team symbol.
 * @error               Invalid client index.
 */
native void FOF_SetClientTeam(int client, FOFTeam team, bool updateModel = true);

/**
 * Ends the round.
 */
native void FOF_EndMultiplayerGame();