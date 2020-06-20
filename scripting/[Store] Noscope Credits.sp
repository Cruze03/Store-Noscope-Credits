/* Thanks Ak0 & Grey83(NoScope Detector). Took help from their plugin's code*/

#pragma semicolon 1
//#pragma newdecls required

#include <colorvariables>
#include <smlib>
#include <store>

ConVar gc_bToggleChatMsg,
		gc_iNoscopeWeapon,
		gc_iAmountNoscopebelow15mtrs,
		gc_iAmountNoscopeabove15mtrs,
		gc_sTag;
		
bool g_bToggleChatMsg;

char g_sTag[100];
	
int g_iNoscopeWeapon, g_iAmountNoscope15, g_iAmountNoscope16;

public Plugin myinfo = 
{
	name			= 	"[Store] NoScope Credits",
	author			= 	"Cruze",
	description		= 	"Credits for noscope",
	version			= 	"1.3",
	url			= 	"http://steamcommunity.com/profiles/76561198132924835"
}


public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO && GetEngineVersion() != Engine_CSS) 
		SetFailState("Plugin supports CSS and CS:GO only.");
	
	gc_bToggleChatMsg					=	CreateConVar("sm_ns_chatmsg", 					"1", 		"Print credits messages to chat? 0 to disable.");
	gc_iNoscopeWeapon					=	CreateConVar("sm_ns_noscopeweapon", 				"3", 		"Weapons to count for Noscope. 1 = awp, 2 = scout, any other integer = both");
	gc_iAmountNoscopebelow15mtrs		=	CreateConVar("sm_ns_noscope_below15mtrs", 		"30", 		"Amount of credits to give to users noscoping enemy who is below 15 mtrs away. 0 to disable.");
	gc_iAmountNoscopeabove15mtrs		=	CreateConVar("sm_ns_noscope_above15mtrs", 		"60", 		"Amount of credits to give to users noscoping enemy who is above 15 mtrs away. 0 to disable.");
	
	HookConVarChange(gc_bToggleChatMsg, OnSettingChanged);
	HookConVarChange(gc_iNoscopeWeapon, OnSettingChanged);
	HookConVarChange(gc_iAmountNoscopebelow15mtrs, OnSettingChanged);
	HookConVarChange(gc_iAmountNoscopeabove15mtrs, OnSettingChanged);
	
	AutoExecConfig(true, "cruze_creditsfornoscope");
	
	HookEvent("player_death", OnPlayerDeath);
	
	LoadTranslations("cruze_creditsfornoscope.phrases");
}

public void OnConfigsExecuted()
{
	gc_sTag = FindConVar("sm_store_chat_tag");
	gc_sTag.GetString(g_sTag, sizeof(g_sTag));
	
	g_bToggleChatMsg			= GetConVarBool(gc_bToggleChatMsg);
	g_iNoscopeWeapon			= GetConVarInt(gc_iNoscopeWeapon);
	g_iAmountNoscope15		= GetConVarInt(gc_iAmountNoscopebelow15mtrs);
	g_iAmountNoscope16		= GetConVarInt(gc_iAmountNoscopeabove15mtrs);
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gc_bToggleChatMsg)
	{
		g_bToggleChatMsg = !!StringToInt(newValue);
	}
	else if(convar == gc_iNoscopeWeapon)
	{
		g_iNoscopeWeapon = StringToInt(newValue);
	}
	else if (convar == gc_iAmountNoscopebelow15mtrs)
	{
		g_iAmountNoscope15 = StringToInt(newValue);
	}
	else if (convar == gc_iAmountNoscopeabove15mtrs)
	{
		g_iAmountNoscope16 = StringToInt(newValue);
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!IsValidClient(victim) || !IsValidClient(attacker))
	{
		return;
	}
	if (victim == attacker)
		return;

	if(GetClientTeam(victim) == GetClientTeam(attacker))
		return;
	
	char iweapon[64];
	
	int NewNoscopeWeapon;
	
	GetEventString(event, "weapon", iweapon, sizeof(iweapon));

	float NoscopeDistance = Entity_GetDistance(victim, attacker);
	NoscopeDistance = Math_UnitsToMeters(NoscopeDistance);
	
	
	char WeaponName[16];
	if(g_iNoscopeWeapon == 1)
	{
		NewNoscopeWeapon = StrContains(iweapon, "awp") != -1;
		Format(WeaponName, sizeof(WeaponName), "AWP");
	}
	else if(g_iNoscopeWeapon == 2)
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
		if(NoscopeDistance <= 15.0 && g_iAmountNoscope15 > 1)
		{
			Store_SetClientCredits(attacker, Store_GetClientCredits(attacker) + g_iAmountNoscope15);
			
			if(g_bToggleChatMsg)
			{
				CPrintToChatAll("%t", "NoScopeb15All", g_sTag, attacker, victim, WeaponName, NoscopeDistance);
				CPrintToChat(attacker, "%t", "NoScopeb15", g_sTag, g_iAmountNoscope15);
			}
		}
		else if(NoscopeDistance > 15.0 && g_iAmountNoscope16 > 1)
		{
			Store_SetClientCredits(attacker, Store_GetClientCredits(attacker) + g_iAmountNoscope16);
			
			if(g_bToggleChatMsg)
			{
				CPrintToChatAll("%t", "NoScopea15All", g_sTag, attacker, victim, WeaponName, NoscopeDistance);
				CPrintToChatAll("%t", "NoScopea15", g_sTag, attacker, g_iAmountNoscope16);
				char noscopemessage[32];
				Format(noscopemessage, sizeof(noscopemessage), "%t", "HawkEyed", attacker);
				if(noscopemessage[0])
				{
						for(int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, true))
					{
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
