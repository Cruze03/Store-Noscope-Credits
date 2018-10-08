/* Thanks Ak0 & Grey83(NoScope Detector). Took help from their plugin's code*/

#pragma semicolon 1
//#pragma newdecls required

#include <colorvariables>
#include <smlib>
#include <store>

ConVar NS_ToggleChatMsg,
		NS_NoscopeWeapon,
		NS_AmountNoscopebelow15mtrs,
		NS_AmountNoscopeabove15mtrs,
		gc_sTag;
		
bool g_ToggleChatMsg;

char g_sTag[32], iweapon[16];
	
int g_NoscopeWeapon, NewNoscopeWeapon, g_AmountNoscope15, g_AmountNoscope16;

public Plugin myinfo = 
{
	name			= 	"[Store] NoScope Credits",
	author			= 	"Cruze",
	description		= 	"Credits for noscope",
	version			= 	"1.2",
	url			= 	"http://steamcommunity.com/profiles/76561198132924835"
}


public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO && GetEngineVersion() != Engine_CSS) 
		SetFailState("Plugin supports CSS and CS:GO only.");
	
	NS_ToggleChatMsg					=	CreateConVar("sm_ns_chatmsg", 					"1", 		"Print credits messages to chat? 0 to disable.");
	NS_NoscopeWeapon					=	CreateConVar("sm_ns_noscopeweapon", 				"3", 		"Weapons to count for Noscope. 1 = awp, 2 = scout, any other integer = both");
	NS_AmountNoscopebelow15mtrs		=	CreateConVar("sm_ns_noscope_below15mtrs", 		"30", 		"Amount of credits to give to users noscoping enemy who is below 15 mtrs away. 0 to disable.");
	NS_AmountNoscopeabove15mtrs		=	CreateConVar("sm_ns_noscope_above15mtrs", 		"60", 		"Amount of credits to give to users noscoping enemy who is above 15 mtrs away. 0 to disable.");
	
	HookConVarChange(NS_ToggleChatMsg, OnSettingChanged);
	HookConVarChange(NS_NoscopeWeapon, OnSettingChanged);
	HookConVarChange(NS_AmountNoscopebelow15mtrs, OnSettingChanged);
	HookConVarChange(NS_AmountNoscopeabove15mtrs, OnSettingChanged);
	
	AutoExecConfig(true, "cruze_creditsfornoscope");
	
	HookEvent("player_death", OnPlayerDeath);
}

public OnConfigsExecuted()
{
	gc_sTag = FindConVar("sm_store_chat_tag");
	gc_sTag.GetString(g_sTag, sizeof(g_sTag));
	
	g_ToggleChatMsg			= GetConVarBool(NS_ToggleChatMsg);
	g_NoscopeWeapon			= GetConVarInt(NS_NoscopeWeapon);
	g_AmountNoscope15		= GetConVarInt(NS_AmountNoscopebelow15mtrs);
	g_AmountNoscope16		= GetConVarInt(NS_AmountNoscopeabove15mtrs);
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == NS_ToggleChatMsg)
	{
		g_ToggleChatMsg = !!StringToInt(newValue);
	}
	else if(convar == NS_NoscopeWeapon)
	{
		g_NoscopeWeapon = StringToInt(newValue);
	}
	else if (convar == NS_AmountNoscopebelow15mtrs)
	{
		g_AmountNoscope15 = StringToInt(newValue);
	}
	else if (convar == NS_AmountNoscopeabove15mtrs)
	{
		g_AmountNoscope16 = StringToInt(newValue);
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim == attacker)
		return;

	if(IsValidClient(victim) && IsValidClient(attacker))
	{
		if(GetClientTeam(victim) == GetClientTeam(attacker))
			return;
	}
	
	GetEventString(event, "weapon", iweapon, sizeof(iweapon));

	float NoscopeDistance = Entity_GetDistance(victim, attacker);
	NoscopeDistance = Math_UnitsToMeters(NoscopeDistance);
	
	
	char WeaponName[16];
	if(g_NoscopeWeapon == 1)
	{
		NewNoscopeWeapon = StrContains(iweapon, "awp") != -1;
		Format(WeaponName, sizeof(WeaponName), "AWP");
	}
	else if(g_NoscopeWeapon == 2)
	{
		NewNoscopeWeapon =  StrContains(iweapon, "ssg08") != -1 || StrContains(iweapon, "scout") != -1;
		Format(WeaponName, sizeof(WeaponName), "SSG 08");
	}
	else//if(g_NoscopeWeapon == 3)
	{
		NewNoscopeWeapon = StrContains(iweapon, "awp") != -1 || StrContains(iweapon, "ssg08") != -1 || StrContains(iweapon, "scout") != -1;
		if(StrEqual(iweapon, "awp"))
		{
			Format(WeaponName, sizeof(WeaponName), "AWP");
		}
		else if(StrEqual(iweapon, "ssg08") || StrEqual(iweapon, "ssg08"))
		{
			Format(WeaponName, sizeof(WeaponName), "SSG 08");
		}
	}
	if((NewNoscopeWeapon) && !GetEntProp(attacker, Prop_Send, "m_bIsScoped"))
	{
		if(NoscopeDistance <= 15.0 && g_AmountNoscope15 > 1)
		{
			if(IsValidClient(attacker))
			{
				char PlayerNameAttacker[MAX_NAME_LENGTH], PlayerNameVictim[MAX_NAME_LENGTH];
				GetClientName(attacker, PlayerNameAttacker, sizeof(PlayerNameAttacker));
				GetClientName(victim, PlayerNameVictim, sizeof(PlayerNameVictim));
				Store_SetClientCredits(attacker, Store_GetClientCredits(attacker) + g_AmountNoscope15);
			
				if(g_ToggleChatMsg)
				{
					CPrintToChatAll("%s \x03%s\x01 just noscoped \x03%s\x01 with {blue}%s{default} who was {red}%.2f{default} meters away.", g_sTag, PlayerNameAttacker, PlayerNameVictim, WeaponName, NoscopeDistance);
					CPrintToChat(attacker, "%s You earned {green}%i{default} credits for noscoping enemy.", g_sTag, g_AmountNoscope15);
				}
			}
		}
		else if(NoscopeDistance > 15.0 && g_AmountNoscope16 > 1)
		{
			if(IsValidClient(attacker))
			{
				char PlayerNameAttacker[MAX_NAME_LENGTH], PlayerNameVictim[MAX_NAME_LENGTH];
				GetClientName(attacker, PlayerNameAttacker, sizeof(PlayerNameAttacker));
				GetClientName(victim, PlayerNameVictim, sizeof(PlayerNameVictim));
				Store_SetClientCredits(attacker, Store_GetClientCredits(attacker) + g_AmountNoscope16);
			
				if(g_ToggleChatMsg)
				{
					CPrintToChatAll("%s \x03%s\x01 noscoped \x03%s\x01 with {blue}%s{default} who was {red}%.2f{default} meters away.", g_sTag, PlayerNameAttacker, PlayerNameVictim, WeaponName, NoscopeDistance);
					CPrintToChatAll("%s \x03%s\x01 earned {green}%i{default} credits for noscoping enemy.", g_sTag, PlayerNameAttacker, g_AmountNoscope16);
					for(int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, true))
					{
						char noscopemessage[32];
						Format(noscopemessage, sizeof(noscopemessage), "Hawk Eyed %s", PlayerNameAttacker);
						SetHudTextParams(0.5, 0.3, 5.0, 255, 0, 0, 255, 1, 1.00, 0.5, 0.5);
						ShowHudText(i, -1, noscopemessage);
					}
				}
			}
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
