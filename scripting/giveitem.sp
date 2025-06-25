#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo =  
{
	name = "Weapon Commands",
	author = "GoopSwagger",
	description = "",
	version = "1.0.0",
	url = ""
}

public void OnPluginStart()
{
	RegAdminCmd("sm_giveitem", Command_GiveItem, ADMFLAG_BAN);
}

public Action:Command_GiveItem(int client, int args)
{
	char szTarget[32], szItem[32];
	GetCmdArg(1, szTarget, sizeof(szTarget));
	if(args < 2){
		PrintToChat(client, "Usage: sm_giveitem <target> <weapon>");
		return Plugin_Handled;
	}

	GetCmdArg(2, szItem, sizeof(szItem));
		
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
		szTarget,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_NO_IMMUNITY,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		if(IsPlayerAlive(target_list[i]))
			GivePlayerItem(target_list[i], szItem, 0);
	}

	return Plugin_Handled;
}