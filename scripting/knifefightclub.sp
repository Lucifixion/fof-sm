#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <steamtools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =  
{
	name = "Knife Fight Club",
	author = "GoopSwagger",
	description = "",
	version = "1.0.0",
	url = ""
}

int iPlayerManager = -1;
int iPlayerScoreOffset = -1;

int iPlayerKnife[MAXPLAYERS+1] = {-1, ...};
int iPlayerKnifeCount[MAXPLAYERS+1] = {0, ...};

int iPlayerSpawned[MAXPLAYERS+1] = {0, ...};

ConVar fof_sv_kfc_spawnknifes;

ConVar fof_sv_kfc_pointlimit;
ConVar fof_sv_kfc_wintime;

ConVar fof_sv_kfc_backstab;

ConVar fof_sv_kfc_knifedecay_time;

Handle hObjectiveIndicator = INVALID_HANDLE;
Handle hFlavorIndicator = INVALID_HANDLE;

Handle hWinIndicator = INVALID_HANDLE;
Handle hKnifeIndicator = INVALID_HANDLE;

int iWinningPlayer = -1;
float flWinTime = 0.0;

bool bGameOver = false;

public void OnPluginStart()
{
	fof_sv_kfc_spawnknifes = CreateConVar("fof_sv_kfc_spawnknifes", "3");
	
	fof_sv_kfc_pointlimit = CreateConVar("fof_sv_kfc_pointlimit", "16");
	fof_sv_kfc_wintime = CreateConVar("fof_sv_kfc_wintime", "15");

	fof_sv_kfc_backstab = CreateConVar("fof_sv_kfc_backstab", "1");
	
	fof_sv_kfc_knifedecay_time = CreateConVar("fof_sv_kfc_knifedecay_time", "12");

	hObjectiveIndicator = CreateHudSynchronizer();
	hFlavorIndicator = CreateHudSynchronizer();
	
	hWinIndicator = CreateHudSynchronizer();
	hKnifeIndicator = CreateHudSynchronizer();

	iWinningPlayer = -1;
	flWinTime = 0.0;

	HookEvent( "player_death", Event_PlayerDeath );
	
	HookEntityOutput( "weapon_knife", "OnPlayerPickup", Output_OnPlayerPickupKnife );
	
	for (int i = 1; i <= MaxClients;i++) 
	{
		if (!IsClientValid(i)) continue;
		
		HookClient(i);
	}
}

public void Output_OnPlayerPickupKnife(const char[] output, int caller, int activator, float delay)
{
	//char szWinnerName[128];
	//GetClientName(activator, szWinnerName, sizeof(szWinnerName));
	//
	//PrintToChat(activator, szWinnerName);
}

public void Output_OnPlayerThrowKnife(int client)
{
	//char szWinnerName[128];
	//GetClientName(client, szWinnerName, sizeof(szWinnerName));
	//
	//PrintToChat(client, szWinnerName);
}

public void OnMapStart()
{
	iPlayerManager = FindEntityByClassname(MaxClients+1, "player_manager");
	iPlayerScoreOffset = FindSendPropInfo("CPlayerResource", "m_iExp");
	
	bGameOver = false;
	
	SDKHook(iPlayerManager, SDKHook_ThinkPost, Hook_OnPlayerManagerThinkPost);
}

public void HookClient(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, Hook_OnPlayerWeaponEquip);
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnPlayerTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, Hook_OnPlayerSetTransmit);
	SDKHook(client, SDKHook_SpawnPost, Hook_OnPlayerSpawnPost);
	
	iPlayerSpawned[client] = 0;
}

public void OnConfigsExecuted()
{
	Steam_SetGameDescription("Knife Fight Club"); 

	RequestFrame(Frame_UpdateConVars);
}

public void Frame_UpdateConVars()
{
	FindConVar("fof_sv_dm_comp").SetInt(0);
	FindConVar("fof_sv_dm_comp_points").SetInt(0);
	
	FindConVar("fof_sv_currentmode").SetInt(1);
	FindConVar("fof_sv_shootout_custom").SetInt(1);
	
	FindConVar("fof_sv_weaponmenu").SetBool(false);
}

public void UpdateObjectiveTextParameters()
{
	SetHudTextParams(-1.0, 0.025, 1.0, 206, 206, 206, 255, 2, 0.0, 0.0, 0.0);
}

public void UpdateFlavorTextParameters()
{
	SetHudTextParams(-1.0, 0.075, 7.5, 206, 172, 0, 255, 0, 0.0, 0.0, 1.0);
}

public void UpdateWinTextParameters()
{
	SetHudTextParams(-1.0, 0.70, 1.0, 206, 206, 206, 255, 2, 0.0, 0.0, 0.0);
}

public void UpdateKnifeTextParameters(bool fade)
{
	int r = fade ? 206 : 206;
	int g = fade ? 172 : 206;
	int b = fade ? 0   : 206;

	SetHudTextParams(-1.0, 0.75, 1.0, r, g, b, 255, 2, 0.0, 0.0, 0.0);
}

public Action Event_PlayerDeath( Handle hEvent, char[] szEventName, bool bDontBroadcast ) {
	int iVictim = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	DropKnives(iVictim);
	
	return Plugin_Continue;
}

public void DropKnives(int client)
{
	float vecPosition[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vecPosition);
	vecPosition[2] += 20;

	float flStrength = 50 + iPlayerKnifeCount[client] * 17.5;
	for(int i = 0; i < iPlayerKnifeCount[client]; i++)
	{
		float vecVelocity[3];
		vecVelocity[0] = GetURandomFloat() - 0.5;
		vecVelocity[1] = GetURandomFloat() - 0.5;
		
		NormalizeVector(vecVelocity, vecVelocity);
		ScaleVector(vecVelocity, flStrength);
		
		vecVelocity[2] = 150.0;
		
		int iKnife = CreateEntityByName("weapon_knife");
		SetEntPropVector(iKnife, Prop_Data, "m_vecAbsOrigin", vecPosition);
		SetEntPropVector(iKnife, Prop_Data, "m_vecBaseVelocity", vecVelocity);
		DispatchSpawn(iKnife);
		ActivateEntity(iKnife);
	}
}

public void Hook_OnPlayerManagerThinkPost(int manager) {
	SetEntDataArray(manager, iPlayerScoreOffset, iPlayerKnifeCount, MaxClients+1);
}

public void OnGameFrame()
{
	if(!bGameOver)
	{
		UpdateWinningPlayer();
		UpdateObjectiveIndicator();
		
		UpdateKnifeIndicator();
		UpdateWinIndicator();
	}
	else
	{
		ClearIndicators();
	}
	
	//UpdateEquipMenu();
}

public void UpdateObjectiveIndicator()
{
	for (int i = 1; i <= MaxClients;i++) 
	{
		if (!IsClientInGame(i)) continue;

		UpdateObjectiveTextParameters();
		int iKnifeCount = fof_sv_kfc_pointlimit.IntValue;

		char buffer[128];
		Format(buffer, sizeof(buffer), "GET %d KNIVES TO WIN", iKnifeCount);

		if(!IsFakeClient(i)) ShowSyncHudText(i, hObjectiveIndicator, buffer);
	}
}

public void UpdateWinIndicator()
{
	float flValue = fof_sv_kfc_wintime.FloatValue - ( GetGameTime() - flWinTime );
	
	if( flValue < 0.0 )
		flValue = 0.0;

	UpdateWinTextParameters();
	
	if( iWinningPlayer != -1 && IsClientValid(iWinningPlayer) ) 
	{
		char szWinnerName[128];
		GetClientName(iWinningPlayer, szWinnerName, sizeof(szWinnerName));
	
		for (int i = 1; i <= MaxClients;i++) 
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) continue;

			bool bWinner = (i == iWinningPlayer);

			char buffer[128];
			Format(buffer, sizeof(buffer), "%s %s IN %.1f SECONDS", bWinner ? "YOU" : szWinnerName, bWinner ? "WIN" : "WINS", flValue);

			ShowSyncHudText(i, hWinIndicator, buffer);
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients;i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) continue;
			
			ShowSyncHudText(i, hWinIndicator, " "); // clear
		}
	}
}

public void UpdateKnifeIndicator()
{
	for (int i = 1; i <= MaxClients;i++) 
	{
		if (!IsClientInGame(i)) continue;

		UpdateKnifeTextParameters( iWinningPlayer != -1 && iWinningPlayer == i );
		int iKnifeCount = GetKnifeCount(i);

		char buffer[128];
		Format(buffer, sizeof(buffer), "%d KNIVES", iKnifeCount);

		if(!IsFakeClient(i)) ShowSyncHudText(i, hKnifeIndicator, buffer);
		iPlayerKnifeCount[i] = iKnifeCount;
	}
}

public void ClearIndicators()
{
	for (int i = 1; i <= MaxClients;i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		
		ShowSyncHudText(i, hObjectiveIndicator, " ");
		ShowSyncHudText(i, hFlavorIndicator, " ");
		
		ShowSyncHudText(i, hWinIndicator, " ");
		ShowSyncHudText(i, hKnifeIndicator, " ");
	}
}

public void UpdateEquipMenu()
{
	for (int i = 1; i <= MaxClients;i++) 
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
	
		ShowVGUIPanel(i, "class", _, false);
	}
}

public void UpdateWinningPlayer()
{
	if(iWinningPlayer == -1)
	{
		for (int i = 1; i <= MaxClients;i++) 
		{
			if (!IsClientValid(i)) continue;
			
			if(GetKnifeCount(i) >= fof_sv_kfc_pointlimit.IntValue ) {
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", true);
				iWinningPlayer = i;
				flWinTime = GetGameTime();
				break;
			}
		}
	}
	else {
		bool validClient = IsClientValid(iWinningPlayer);
		if( !validClient || GetKnifeCount(iWinningPlayer) < fof_sv_kfc_pointlimit.IntValue ) {
			if( validClient )
				SetEntProp(iWinningPlayer, Prop_Send, "m_bGlowEnabled", false);
			iWinningPlayer = -1;
			flWinTime = 0.0;
			return;
		}
		
		float flValue = fof_sv_kfc_wintime.FloatValue - ( GetGameTime() - flWinTime );
		
		if( flValue < 0.0 )
			WinGame();
	}
}

public void WinGame()
{
	if(!bGameOver)
	{
		for (int i = 1; i <= MaxClients;i++) 
		{
			if (!IsClientValid(i)) continue;
			
			SetEntProp(i, Prop_Send, "m_fFlags", ( GetEntProp(i, Prop_Send, "m_fFlags") | (1 << 6) ));
		}

		StartMessageAll("GoodBadYou");
		EndMessage();

		CreateTimer(16.0, Timer_ChangeMap);

		bGameOver = true;
	}
}

public Action Timer_ChangeMap(Handle timer)
{
	char buffer[128];
	GetNextMap(buffer, sizeof(buffer));
	
	ForceChangeLevel(buffer, "");
	return Plugin_Continue;
}

public int GetKnifeCount(int client)
{
	return (EntRefToEntIndex(iPlayerKnife[client]) != INVALID_ENT_REFERENCE) ? GetEntProp(client, Prop_Data, "m_iAmmo", _, 6) + 1 : 0;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "fof_crate_low") || StrEqual(classname, "fof_crate_med") || StrEqual(classname, "fof_crate") || StrEqual(classname, "fof_crate_special"))
	{
		SDKHook(entity, SDKHook_Spawn, Hook_OnCrateSpawn);
		return;
	}
	
	if (StrEqual(classname, "weapon_knife"))
	{
		CreateTimer(fof_sv_kfc_knifedecay_time.FloatValue, Timer_KnifeDecay, EntIndexToEntRef(entity));
	}
	
	if (StrEqual(classname, "thrown_knife"))
	{
		SDKHook(entity, SDKHook_Spawn, Hook_OnThrownKnifeSpawn);
	}
}

public void Hook_OnThrownKnifeSpawn(int entity)
{
	RequestFrame(Frame_OnThrownKnifeSpawn, entity);
}

public void Frame_OnThrownKnifeSpawn(int knife)
{
	Output_OnPlayerThrowKnife(GetEntPropEnt(knife, Prop_Send, "m_hOwnerEntity"));
}

public Action Timer_KnifeDecay(Handle timer, int knife)
{
	int knifeIndex = EntRefToEntIndex(knife);
	if (knifeIndex != INVALID_ENT_REFERENCE ) 
	{
		int owner = GetEntProp(knifeIndex, Prop_Send, "m_hOwnerEntity");
		if (!(owner == -1))
			return Plugin_Continue;
		RemoveEntity(knifeIndex);
	}
	return Plugin_Continue;
}

public void Hook_OnCrateSpawn(int entity)
{
	RemoveEntity(entity);
}

public void OnClientPostAdminCheck(int client) 
{
	HookClient(client);
}

public void OnClientDisconnect(int client)
{
	if (client == iWinningPlayer)
	{
		DropKnives(client);
		iWinningPlayer = -1;
		flWinTime = 0.0;
	}
}

public Action Hook_OnPlayerWeaponEquip(int client, int weapon)
{
	char buffer[128];
	GetEntityClassname(weapon, buffer, sizeof(buffer));
		
	if ( (StrEqual(buffer, "weapon_fists")) )
	{
		if( EntRefToEntIndex(iPlayerKnife[client]) == INVALID_ENT_REFERENCE )
		{
			if((EntRefToEntIndex(iPlayerKnife[client]) == INVALID_ENT_REFERENCE))
				GivePlayerItem( client, "weapon_knife" );
			RequestFrame(Frame_OnPlayerSpawn, client);
			// CreateTimer(0.5, Timer_KnifeCheck, client);
		}
	}
	else if ( !(StrEqual(buffer, "weapon_knife")) )
	{
		RemoveEntity( weapon );
		return Plugin_Handled;
	} else {
		iPlayerKnife[client] = EntIndexToEntRef( weapon );
	}
	
	return Plugin_Continue;
}
 
public void Frame_OnPlayerSpawn(int client)
{
	SetEntProp(client, Prop_Data, "m_iAmmo", fof_sv_kfc_spawnknifes.IntValue - 1, _, 6);
	SetEntProp(client, Prop_Send, "m_nPlayerInfo", 3145858);
}

// dipshit check for equip menu bugs
public Action Timer_KnifeCheck(Handle timer, int client)
{
	if(!IsClientValid(client))
		return Plugin_Continue;

	if((EntRefToEntIndex(iPlayerKnife[client]) == INVALID_ENT_REFERENCE)) {
		GivePlayerItem( client, "weapon_knife" );
		SetEntProp(client, Prop_Data, "m_iAmmo", fof_sv_kfc_spawnknifes.IntValue - 1, _, 6);
	}
	return Plugin_Continue;
}

public Action Hook_OnPlayerTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if(attacker == 0)
		return Plugin_Continue;

	char buffer[128];
	GetEntityClassname(inflictor == attacker ? GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon") : inflictor, buffer, sizeof(buffer));

	if ( StrEqual(buffer, "thrown_knife") )
	{
		damage = 1000.0;
		return Plugin_Changed;
	} 
	else if ( fof_sv_kfc_backstab.BoolValue && StrEqual(buffer, "weapon_knife") && IsBehindAndFacingTarget( attacker, client ) )
	{
		damage = 1000.0;
		return Plugin_Changed;
	} 

	return Plugin_Continue;
}

public Action Hook_OnPlayerSetTransmit(int entity, int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFoFCash", 0.0);

	if( iWinningPlayer == entity && iWinningPlayer != -1 && IsClientValid(iWinningPlayer) )
		SetEdictFlags(entity, ( GetEdictFlags(entity) | FL_EDICT_ALWAYS ) );

	return Plugin_Continue;
}

public Action Hook_OnPlayerSpawnPost(int client)
{
	if(iPlayerSpawned[client] < 2) {
		UpdateFlavorTextParameters();
	
		if(!IsFakeClient(client)) ShowSyncHudText(client, hFlavorIndicator, "THROW KNIVES FOR AN INSTANT KILL");
		iPlayerSpawned[client]++;
	}

	return Plugin_Continue;
}

public bool IsBehindAndFacingTarget( int client, int target )
{
	float clientOrigin[3];
	float targetOrigin[3];

	GetClientAbsOrigin( client, clientOrigin );
	GetClientAbsOrigin( target, targetOrigin );

	// Get a vector from owner origin to target origin
	float vecToTarget[3];
	SubtractVectors( targetOrigin, clientOrigin, vecToTarget );
	vecToTarget[0] = 0.0;
	NormalizeVector( vecToTarget, vecToTarget );

	// Get owner forward view vector
	float vecOwnerForward[3];
	float angOwnerForward[3];
	GetClientEyeAngles( client, angOwnerForward );
	GetAngleVectors( angOwnerForward, vecOwnerForward, NULL_VECTOR, NULL_VECTOR );
	vecOwnerForward[2] = 0.0;
	NormalizeVector( vecOwnerForward, vecOwnerForward );

	// Get target forward view vector
	float vecTargetForward[3];
	float angTargetForward[3];
	GetClientEyeAngles( target, angTargetForward );
	GetAngleVectors( angTargetForward, vecTargetForward, NULL_VECTOR, NULL_VECTOR );
	vecTargetForward[2] = 0.0;
	NormalizeVector( vecTargetForward, vecTargetForward );

	// Make sure owner is behind, facing and aiming at target's back
	float flPosVsTargetViewDot = GetVectorDotProduct( vecToTarget, vecTargetForward );	// Behind?
	float flPosVsOwnerViewDot = GetVectorDotProduct( vecToTarget, vecOwnerForward );		// Facing?
	float flViewAnglesDot = GetVectorDotProduct( vecTargetForward, vecOwnerForward );	// Facestab?

	return ( flPosVsTargetViewDot > 0.0 && flPosVsOwnerViewDot > 0.5 && flViewAnglesDot > -0.3 );
}

stock bool IsClientValid(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
} 