#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>

public Plugin myinfo = 
{
	name = "No Explosion Ringing",
	author = "Striker, GoopSwagger",
	description = "",
	version = "1.0.0",
	url = ""
};

new Handle:hSetPlayerDSP = INVALID_HANDLE;

public void OnPluginStart()
{
	new Handle:gameconf = LoadGameConfigFile("fof.ringing"); 
	if(gameconf == INVALID_HANDLE) 
    { 
        SetFailState("Failed to find fof.ringing.txt gamedata"); 
    }
	new offset = GameConfGetOffset(gameconf, "SetPlayerDSP"); 
	if(offset == -1) 
	{ 
		SetFailState("Failed to find offset for SetPlayerDSP"); 
		CloseHandle(gameconf); 
	}
	StartPrepSDKCall(SDKCall_Static); 
	if(!PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CreateInterface")) 
	{ 
		SetFailState("Failed to get CreateInterface"); 
		CloseHandle(gameconf); 
	}
	
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer); 
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL); 
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	new String:interface_id[64]; 
	if(!GameConfGetKeyValue(gameconf, "EngineInterface", interface_id, sizeof(interface_id))) 
	{ 
		SetFailState("Failed to get EngineInterface key in gamedata"); 
		CloseHandle(gameconf); 
	} 

	new Handle:temp = EndPrepSDKCall(); 
	new Address:addr = SDKCall(temp, interface_id, 0); 

	CloseHandle(gameconf); 
	CloseHandle(temp);

	if(!addr) 
	{ 
		SetFailState("Failed to get %s ptr", interface_id); 
	} 
    
	hSetPlayerDSP = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, Hook_SetPlayerDSP);
	DHookAddParam(hSetPlayerDSP, HookParamType_Unknown);
	DHookAddParam(hSetPlayerDSP, HookParamType_Int);
	DHookAddParam(hSetPlayerDSP, HookParamType_Bool);
	DHookRaw(hSetPlayerDSP, false, addr);
}

public MRESReturn:Hook_SetPlayerDSP(Handle:hParams)
{
	int dsp = DHookGetParam(hParams, 2);
	
	if( ((dsp >= 32) || (dsp <= 37)))
	{
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}