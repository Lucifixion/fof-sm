#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>
#include <steamtools>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =  
{
	name = "No Cannons",
	author = "GoopSwagger",
	description = "",
	version = "1.0.0",
	url = ""
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if ( StrEqual(classname, "func_tank_fof") )
	{
		SDKHook(entity, SDKHook_Spawn, Hook_OnCannonSpawn);
		return;
	}
}

public void Hook_OnCannonSpawn(int entity)
{
	RemoveEntity(entity);
}