#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo =  
{
	name = "DisableDamageTypes",
	author = "GoopSwagger",
	description = "",
	version = "1.0.0",
	url = ""
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "trigger_hurt_fof"))
	{
		SDKHook(entity, SDKHook_Spawn, SDKHook_OnTriggerHurtSpawn);
	}
}

public void SDKHook_OnTriggerHurtSpawn(int trigger)
{
	int iDamageBits = GetEntProp(trigger, Prop_Data, "m_bitsDamageInflict");
	if(iDamageBits & DMG_FALL) {
		SetEntProp(trigger, Prop_Data, "m_bitsDamageInflict", (iDamageBits & ~DMG_FALL));
	}
}

public void OnClientPostAdminCheck(int client) 
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (damagetype & DMG_FALL)
		return Plugin_Handled;

	return Plugin_Continue;
}

stock bool IsClientValid(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
} 