#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo =  
{
	name = "Moneybags",
	author = "GoopSwagger",
	description = "",
	version = "1.0.0",
	url = ""
}

ConVar fof_sv_moneyamount

public void OnPluginStart()
{
	fof_sv_moneyamount = CreateConVar("fof_sv_moneyamount", "100000")
	
	for (new i = 1; i <= MaxClients; i++) {
		if(IsClientValid(i)) {
			SDKHook(i, SDKHook_SetTransmit, Hook_OnPlayerTransmit);
		}
	}
}

public void OnClientPostAdminCheck(int client) 
{
	SDKHook(client, SDKHook_SetTransmit, Hook_OnPlayerTransmit);
}
 
public Hook_OnPlayerTransmit(client)
{
	if(IsClientValid(client)) {
		SetEntPropFloat(client, Prop_Send, "m_flFoFCash", fof_sv_moneyamount.FloatValue);
	}
}

stock bool IsClientValid(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
} 