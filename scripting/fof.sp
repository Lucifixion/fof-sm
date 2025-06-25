#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1
#include <fof>

#define PLUGIN_VERSION 		"1.0.0"

public Plugin myinfo =  {
	name = "Fistful of Tools", 
	author = "GoopSwagger", 
	description = "Fistful of Frags natives and forwards for SourceMod", 
	version = PLUGIN_VERSION, 
	url = ""
};

Handle hUpdatePlayerModel;
Handle hEndMultiplayerGame;

public void OnPluginStart()
{
	GameData conf = LoadGameConfigFile("fof.games");
	if (!conf)
		SetFailState("Gamedata \"fof/addons/sourcemod/gamedata/fof.games.txt\" does not exist.");
		
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CFOFPlayer::UpdatePlayerModel");
	hUpdatePlayerModel = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CFOFGamerules::EndMultiplayerGame");
	hEndGame = EndPrepSDKCall();
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int max)
{
	CreateNative("FOF_SetClientTeam", Native_FOF_SetClientTeam);
	CreateNative("FOF_EndMultiplayerGame", Native_FOF_EndMultiplayerGame);

	RegPluginLibrary("fof");
	return APLRes_Success;
}

int gamerules;

public void OnMapStart()
{
	gamerules = FindEntityByClassname(MaxClients+1, "hl2mp_gamerules");
}

public any Native_FOF_SetClientTeam(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int team = GetNativeCell(2);
	bool updateModel = GetNativeCell(3);

	SetEntProp(client, Prop_Send, "m_iTeamNum", team, 8);
	if(updateModel)
		SDKCall(hUpdatePlayerModel, client);

	return 0;
}

public any Native_FOF_EndMultiplayerGame(Handle plugin, int numParams)
{
	return SDKCall(hEndMultiplayerGame, gamerules);
}

