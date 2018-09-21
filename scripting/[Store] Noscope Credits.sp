/* Thanks Ak0 & Grey83(NoScope Detector). Took help from their plugin's code*/

#pragma semicolon 1
//#pragma newdecls required

#include <colorvariables>
#include <store>

ConVar CSE_NoscopeWeapon,
		CSE_AmountNoscope,
		gc_sTag;

char g_sTag[32], weapon[16];
	
int g_NoscopeWeapon, g_AmountNoscope;

public Plugin myinfo = 
{
	name				= 	"[Store] NoScope Credits",
	author			= 	"Cruze",
	description		= 	"Credits for noscope",
	version			= 	"1.0",
	url				= 	""
}


public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO && GetEngineVersion() != Engine_CSS) 
		SetFailState("Plugin supports CSS and CS:GO only.");
	
	CSE_NoscopeWeapon		=	CreateConVar("cse_noscopeweapon", 	"3", 		"Weapons to count for Noscope. 1 = awp, 2 = scout, any other integer = both");
	CSE_AmountNoscope		=	CreateConVar("cse_noscope", 			"30", 		"Amount of credits to give to users noscoping enemy. 0 to disable.");
	
	AutoExecConfig(true, "cruze_creditsforspecifiedevents");
	
	g_NoscopeWeapon		= GetConVarInt(CSE_NoscopeWeapon);
	g_AmountNoscope		= GetConVarInt(CSE_AmountNoscope);
	
	HookEvent("player_death", OnPlayerDeath);
}
public void OnAllPluginsLoaded()
{
	HookConVarChange(CSE_AmountNoscope, OnSettingChanged);
	HookConVarChange(CSE_NoscopeWeapon, OnSettingChanged);
}
public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == CSE_NoscopeWeapon)
	{
		g_NoscopeWeapon = StringToInt(newValue);
	}
	else if (convar == CSE_AmountNoscope)
	{
		g_AmountNoscope = StringToInt(newValue);
	}
}

public OnConfigsExecuted()
{
	gc_sTag = FindConVar("sm_store_chat_tag");
	gc_sTag.GetString(g_sTag, sizeof(g_sTag));
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim == attacker)
		return;
	
	if(g_NoscopeWeapon == 1)
	{
		g_NoscopeWeapon = (StrContains(weapon, "awp") != -1);
	}
	else if(g_NoscopeWeapon == 2)
	{
		g_NoscopeWeapon =  (StrContains(weapon, "ssg08") != -1 || StrContains(weapon, "scout") != -1);
	}
	else//if(g_NoscopeWeapon == 3)
	{
		g_NoscopeWeapon = (StrContains(weapon, "awp") != -1 || StrContains(weapon, "ssg08") != -1 || StrContains(weapon, "scout") != -1);
	}

	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if(g_NoscopeWeapon && !GetEntProp(attacker, Prop_Send, "m_bIsScoped"))
	{
		if(IsValidClient(attacker) && g_AmountNoscope > 1)
		{
			char PlayerNameAttacker[MAX_NAME_LENGTH], PlayerNameVictim[MAX_NAME_LENGTH];
			GetClientName(attacker, PlayerNameAttacker, sizeof(PlayerNameAttacker));
			GetClientName(victim, PlayerNameVictim, sizeof(PlayerNameVictim));
			Store_SetClientCredits(attacker, Store_GetClientCredits(attacker) + g_AmountNoscope);
			
			CPrintToChatAll("%s \x03%s\x01 just noscoped \x03%s\x01 with {blue}%s{default} and earned {green}%i{default} credits.", g_sTag, PlayerNameAttacker, PlayerNameVictim, weapon, g_AmountNoscope);
		}
	}
}

	
bool IsValidClient(client, bool bAllowBots = true, bool bAllowDead = true)
{
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
    {
        return false;
    }
    return true;
}
