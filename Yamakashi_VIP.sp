/************** CHANGELOG **************
/
/	1.0 - Pierwsze wydanie pluginu.
/	1.1 - Naprawienie dwóch bugów.
/	1.2 - Dodanie możliwości przywrócenia części HP za HS.
/	2.0 - Zmodyfikowanie praktycznie całego kodu.
/	2.1 - Dodanie komendy !vip
/	2.2 - Aktualizacja kodu
/
****************************************/

/* [ Includes ] */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>
#include <clientprefs>
#include <scp>

/* [ Compiler Options ] */
#pragma semicolon 1
#pragma newdecls required

/* [ Defines ] */
#define PluginTag 	"{darkred}[ {lightred}★{darkred} VIP by Yamakashi {lightred}★ {darkred}]{default}"

/* [ ConVars ] */
ConVar g_cvWelcomeHUD;
ConVar g_cvWelcomeChat;
ConVar g_cvHealth;
ConVar g_cvGravity;
ConVar g_cvSpeed;
ConVar g_cvFlashbang;
ConVar g_cvHeGranade;
ConVar g_cvSmokeGranade;
ConVar g_cvIncGranade;
ConVar g_cvMolotov;
ConVar g_cvHealthShot;
ConVar g_cvDecoy;
ConVar g_cvDefuser;
ConVar g_cvDoubleJump;
ConVar g_cvHelmet;
ConVar g_cvArmor;
ConVar g_cvMoneyOnRoundStart;
ConVar g_cvExtraMoneyForKill;
ConVar g_cvExtraMoneyForHS;
ConVar g_cvExtraMoneyForPlant;
ConVar g_cvExtraMoneyForDefuse;
ConVar g_cvVipTableTag;
ConVar g_cvVipChatTag;
ConVar g_cvWeaponsMenu;
ConVar g_cvRoundWeaponsMenu;
ConVar g_cvVipLotteryON;
ConVar g_cvVIPLotteryRound;
ConVar g_cvVIPLotteryPlayersNeeded;
ConVar g_cvFirstAidKitsON;
ConVar g_cvFirstAidKits;
ConVar g_cvFirstAidKitBonusHealth;
ConVar g_cvFirstAidKitMaxHealth;
ConVar g_cvHealthForHs;
ConVar g_cvVipTableTagEnable;
ConVar g_cvVipChatTagEnable;

/* [ Integers ] */
int g_iGrenadeOffsets[] =  { 15, 17, 16, 14, 18, 17 };
int g_iRounds = 0;
int g_iHeal[65];
int g_iRoundCount = 0;

/* [ Booleans ] */
bool g_bOldButtons[65] = false;

/* [ Handles ] */
Handle g_hWelcomeVIP_HUD;

/* [ Plugin Author and Information ] */
public Plugin myinfo =
{
	name = "[CS:GO] VIP by Yamakashi",
	author = "Yamakashi",
	description = "Zaawansowany VIP na serwery CS:GO",
	version = "2.1",
	url = "https://steamcommunity.com/id/yamakashisteam"
}

/* [ Plugin Startup ] */
public void OnPluginStart()
{
	/* [ Commands ] */
	RegConsoleCmd("sm_vip", Vip_CMD);
	
	/* [ ConVars ] */	
	g_cvWelcomeHUD = CreateConVar("sm_vip_welcome_hud", "1", "Czy podczas wejścia VIP'a na serwer ma wyświetlać się przywitanie na hudzie? (1 = Tak, 0 = Nie)");
	g_cvWelcomeChat = CreateConVar("sm_vip_welcome_chat", "0", "Czy podczas wejścia VIP'a na serwer ma wyświetlać się przywitanie na chacie? (1 = Tak, 0 = Nie)");
	
	g_cvHealth = CreateConVar("sm_vip_health", "120", "Ile hp ma posiadać VIP przy starcie rundy?"); 
	g_cvGravity = CreateConVar("sm_vip_gravity", "1.0", "Jaką grawitację ma posiadać VIP. (1.0 = Standard)");
	g_cvSpeed = CreateConVar("sm_vip_speed", "1.0", "Jakiego speeda ma posiadać VIP? (1.0 = Standard)");
	
	g_cvFlashbang = CreateConVar("sm_vip_flashbang", "0", "Czy VIP ma dostawać flasha przy starcie rundy (1 = Tak, 0 = Nie)");
	g_cvHeGranade = CreateConVar("sm_vip_hegranade", "0", "Czy VIP ma dostawać granat wybuchowy przy starcie rundy (1 = Tak, 0 = Nie)");
	g_cvSmokeGranade = CreateConVar("sm_vip_smokegranade", "0", "Czy VIP ma dostawać smokea przy starcie rundy (1 = Tak, 0 = Nie)");
	g_cvIncGranade = CreateConVar("sm_vip_incgranade", "0", "Czy VIP ma dostawać granat taktyczny przy starcie rundy (1 = Tak, 0 = Nie)");
	g_cvMolotov = CreateConVar("sm_vip_molotov", "0", "Czy VIP ma dostawać molotova przy starcie rundy (1 = Tak, 0 = Nie)");
	g_cvHealthShot = CreateConVar("sm_vip_healthshot", "0", "Czy VIP ma dostawać healthshota przy starcie rundy (1 = Tak, 0 = Nie)");
	
	g_cvDecoy = CreateConVar("sm_vip_decoy", "0", "Czy VIP ma dostawać wabik przy starcie rundy (1 = Tak, 0 = Nie)");
	g_cvDefuser = CreateConVar("sm_vip_defuser", "0", "Czy VIP po stronie CT ma dostawać darmowego defusa (1 = Tak, 0 = Nie)");
	g_cvDoubleJump = CreateConVar("sm_vip_doublejump", "1", "Czy VIP ma posiadać double jumpa (1 = Tak, 0 = Nie)");
	g_cvHelmet = CreateConVar("sm_vip_helmet", "1", "Czy VIP ma dostawać hełm przy starcie rundy (1 = Tak, 0 = Nie)");
	g_cvArmor = CreateConVar("sm_vip_armor", "1", "Czy VIP ma dostawać kamizelke przy starcie rundy (1 = Tak, 0 = Nie)");
	
	g_cvMoneyOnRoundStart = CreateConVar("sm_vip_extra_money_on_round_start", "0", "Ile dodatkowych $ ma dostawać VIP na początku rundy?");
	g_cvExtraMoneyForKill = CreateConVar("sm_vip_extra_money_for_kill", "0", "Ile dodatkowych $ ma dostawać VIP za killa?");
	g_cvExtraMoneyForHS = CreateConVar("sm_vip_extra_money_for_hs", "0", "Ile dodatkowych $ ma dostawać VIP za headshota?");
	g_cvExtraMoneyForPlant = CreateConVar("sm_vip_extra_money_for_plant", "0", "Ile dodatkowych $ ma dostawać VIP za podłożenie bomby?");
	g_cvExtraMoneyForDefuse = CreateConVar("sm_vip_extra_money_for_defuse", "0", "Ile dodatkowych $ ma dostawać VIP za rozbrojenie bomby?");
	
	g_cvVipTableTagEnable  = CreateConVar("sm_vip_table_tag_enable", "1", "Czy VIP ma posiadać Tag w tabeli?");
	g_cvVipTableTag = CreateConVar("sm_vip_table_tag", "[VIP]", "Prefix VIPa w tabeli");
	g_cvVipChatTagEnable  = CreateConVar("sm_chat_table_tag_enable", "1", "Czy VIP ma posiadać Tag na chacie?");
	g_cvVipChatTag = CreateConVar("sm_vip_chat_tag", "★VIP★", "Prefix VIPa na chacie");
	g_cvWeaponsMenu = CreateConVar("sm_vip_weapons_menu", "1", "Czy VIPowi powinno wyświetlać się menu z brońmi?");
	g_cvRoundWeaponsMenu = CreateConVar("sm_vip_round_weapons_menu", "2", "Od której rundy menu z brońmi powinno się wyśtwietlać?");
	
	g_cvVipLotteryON = CreateConVar("sm_vip_lottery_on", "1", "Czy VIP ma być losowany co mapę? (1 = Tak, 0 = Nie)");
	g_cvVIPLotteryRound = CreateConVar("sm_vip_lottery_round", "2", "W której rundzie ma być losowany VIP? (Rozgrzewka jest liczona jako runda)");
	g_cvVIPLotteryPlayersNeeded = CreateConVar("sm_vip_lottery_players_needed", "1", "Ile graczy ma być na serwerze aby losowanie się odbyło?");
	
	g_cvFirstAidKitsON = CreateConVar("sm_vip_first_aid_kits_on", "1", "Czy VIP ma posiadać apteczki? (1 = Tak, 0 = Nie)");
	g_cvFirstAidKits = CreateConVar("sm_vip_first_aid_kits", "2", "Ilość apteczek do uleczenia się. (bind e +use)");
	g_cvFirstAidKitBonusHealth = CreateConVar("sm_vip_first_aid_kit_bonus_health", "10", "Wartość uleczenia jednej apteczki");
	g_cvFirstAidKitMaxHealth = CreateConVar("sm_vip_first_aid_kit_max_health", "120", "Ile hp może mieć maksymalnie VIP po uleczeniu się.");
	g_cvHealthForHs = CreateConVar("sm_vip_heatlh_for_hs", "10", "Ile hp ma dostawać VIP za zabójstwo hs?");
	
	/* [ Hooks ] */
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("announce_phase_end", Event_RestartRound);
	HookEvent("cs_intermission", Event_RestartRound);
	HookEvent("cs_win_panel_match", Event_RestartRound);
	
	/* [ Timers ] */
	CreateTimer(180.0, Advertisement, _, TIMER_REPEAT);
	
	/* [ Hud ] */
	if(g_cvWelcomeHUD.BoolValue) g_hWelcomeVIP_HUD = CreateHudSynchronizer();
	
	/* [ Check Player ] */
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i))
			OnClientPutInServer(i);
}

/* [ Timers ] */
public Action Advertisement(Handle timer)
{
	CPrintToChatAll("%s Plugin został napisany przez {lime}Yamakashiego.", PluginTag);
}

/* [ Standart Actions ] */
public void OnMapStart()
{
	AutoExecConfig(true, "Yamakashi_VIP", "yPlugins");
}

public void OnClientPutInServer(int client)
{
	g_iHeal[client] = 0;
}

public void OnClientPostAdminCheck(int client)
{
	char sVipTag[128];
	g_cvVipChatTag.GetString(sVipTag, sizeof(sVipTag));
			
	if(g_cvWelcomeHUD.BoolValue)
	{
		if(IsPlayerVIP(client))
		{
			char sText[100];
			Format(sText, sizeof(sText), "%s %N \n", sVipTag, client);
			Format(sText, sizeof(sText), "%s Wbija na serwer! ", sText);
		
			SetHudTextParams(-1.0, 0.125, 7.0, 45, 209, 0, 255, 0, 0.25, 1.5, 0.5);
			for(int i = 1; i <= MaxClients; i++)
				if(IsValidClient(i))
					ShowSyncHudText(i, g_hWelcomeVIP_HUD, sText);
		}
	}
	
	if(g_cvWelcomeChat.BoolValue)
		if(IsPlayerVIP(client))
			CPrintToChatAll("%s %s {lime}%N{default} wchodzi na serwer!", PluginTag, sVipTag, client);
}

/* [ Events ] */
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client)) return Plugin_Continue;
	if(!IsPlayerVIP(client)) return Plugin_Continue;
	if(GameRules_GetProp("m_bWarmupPeriod") == 1) return Plugin_Continue;
	
	/* [ Table Tag ] */
	if(g_cvVipTableTagEnable.BoolValue)
	{
		char sVipTag[128];
		g_cvVipTableTag.GetString(sVipTag, sizeof(sVipTag));
		CS_SetClientClanTag(client, sVipTag);
	}
	
	/* [ Health ] */
	SetEntityHealth(client, g_cvHealth.IntValue);
		
	/* [ Grenades ] */
	if(g_cvFlashbang.BoolValue) GivePlayerItem(client, "weapon_flashbang");
	if(g_cvHeGranade.BoolValue) GivePlayerItem(client, "weapon_hegrenade");
	if(g_cvSmokeGranade.BoolValue) GivePlayerItem(client, "weapon_smokegrenade");
	if(g_cvIncGranade.BoolValue) GivePlayerItem(client, "weapon_incgrenade");
	if(g_cvMolotov.BoolValue) GivePlayerItem(client, "weapon_molotov");
	if(g_cvHealthShot.BoolValue) GivePlayerItem(client, "weapon_healthshot");
	if(g_cvDecoy.BoolValue) GivePlayerItem(client, "weapon_decoy");
		
	/* [ Defuser] */
	if(g_cvDefuser.BoolValue)
		if(GetClientTeam(client) == CS_TEAM_CT && GetEntProp(client, Prop_Send, "m_bHasDefuser") == 0)
				GivePlayerItem(client, "item_defuser");
	
	/* [ Helmet ] */
	if(g_cvHelmet.BoolValue)
		if(g_iRoundCount != 1)
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	
	/* [ Kevlar ] */
	if(g_cvArmor.BoolValue)	SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		
	/* [ Extra Money ] */
	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	SetEntProp(client, Prop_Send, "m_iAccount", money + g_cvMoneyOnRoundStart.IntValue);
	
	/* [ Speed ] */ 
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_cvSpeed.FloatValue);
	
	/* [ Gravity ] */
	SetEntityGravity(client, g_cvGravity.FloatValue);

	/* [ Weapon Menu ] */
	if(g_cvWeaponsMenu.BoolValue)
		if(g_iRoundCount >= g_cvRoundWeaponsMenu.IntValue)
			ShowPrimaryWeapons(client);
			
	/* [ Heals ] */
	if(g_cvFirstAidKitsON.BoolValue)
		g_iHeal[client] = g_cvFirstAidKits.IntValue;
		
	return Plugin_Continue;
}
public Action round(int client, int args)
{
	PrintToChat(client, "runda: %d", g_iRoundCount);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!IsValidClient(client) || !IsValidClient(attacker))
		return Plugin_Continue; 
	if(!IsPlayerVIP(attacker) || !IsPlayerVIP(attacker))
		return Plugin_Continue;
	if(GetClientTeam(attacker) == GetClientTeam(client))
		return Plugin_Continue;

	int money = GetEntProp(attacker, Prop_Send, "m_iAccount");
	int health = GetClientHealth(attacker);
	bool hs = event.GetBool("headshot");

	if(hs) 
	{
		/* [ Health for HeadShot ] */
		if(health + g_cvHealthForHs.IntValue <= g_cvFirstAidKitMaxHealth.IntValue)		
			SetEntityHealth(attacker, health + g_cvHealthForHs.IntValue);
		else
			SetEntityHealth(attacker, g_cvFirstAidKitMaxHealth.IntValue);
		
		/* [ Money for Headshot ] */
		if(g_cvExtraMoneyForHS.IntValue > 0) SetEntProp(attacker, Prop_Send, "m_iAccount", g_cvExtraMoneyForHS.IntValue + money);
	}
	
	/* [ Money for Kill ] */
	if(g_cvExtraMoneyForKill.IntValue > 0) SetEntProp(attacker, Prop_Send, "m_iAccount", g_cvExtraMoneyForKill.IntValue + money);

	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{
	g_iRoundCount++;
	if(g_cvVipLotteryON.BoolValue)
	{
		int winner = GetRandomPlayer(3);
		int random_round = g_cvVIPLotteryRound.IntValue;
	
		g_iRounds = g_iRounds + 1;
		
		if(g_iRounds == random_round)
		{
			if(!IsValidClient(winner)) CPrintToChatAll("%s Na serwerze znajduje się za mało graczy do wylosowania VIP'a", PluginTag);
			
			AddUserFlags(winner, Admin_Reservation);
			CPrintToChatAll("%s {lightred}Trwa losowanie VIP'a...", PluginTag);
			CPrintToChatAll("%s {lightred}-----", PluginTag);
			CPrintToChatAll("%s {lightred}-----", PluginTag);
			CPrintToChatAll("%s {lightred}-----", PluginTag);
			CPrintToChatAll("%s {lightred}Losowym VIP'em zostaje {darkred}%N{lightred}! {green}Gratulujemy!", PluginTag, winner);		
		}
	}
}

public Action Event_BombPlanted(Event event, const char[] name, bool bDontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int money = GetEntProp(client, Prop_Send, "m_iAccount");

	if(IsPlayerVIP(client) && IsValidClient(client))
		SetEntProp(client, Prop_Send, "m_iAccount", money + g_cvExtraMoneyForPlant.IntValue);
}

public Action Event_BombDefused(Event event, const char[] name, bool bDontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int money = GetEntProp(client, Prop_Send, "m_iAccount");

	if(IsPlayerVIP(client) && IsValidClient(client))
		SetEntProp(client, Prop_Send, "m_iAccount", money + g_cvExtraMoneyForDefuse.IntValue);
}

public Action Event_RestartRound(Event event, const char[] name, bool dontBroadcast)
{
	g_iRoundCount = 0;
	g_iRounds = 0;
}

/* [ Heal and Double Jump] */
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!IsValidClient(client)) return Plugin_Continue;
	if(!IsPlayerVIP(client)) return Plugin_Continue;
	if(!IsPlayerAlive(client)) return Plugin_Continue;
	
	/* [ Double Jump ] */
	if(g_cvDoubleJump.BoolValue)
	{
		static int g_fLastButtons[MAXPLAYERS + 1], g_fLastFlags[MAXPLAYERS + 1], g_iJumps[MAXPLAYERS + 1], fCurFlags, fCurButtons;
		fCurFlags = GetEntityFlags(client);
		fCurButtons = GetClientButtons(client);
		if(g_fLastFlags[client] & FL_ONGROUND && !(fCurFlags & FL_ONGROUND) && !(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)g_iJumps[client]++;
		else if(fCurFlags & FL_ONGROUND)g_iJumps[client] = 0;
		else if(!(g_fLastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP && g_iJumps[client] == 1)
		{
			g_iJumps[client]++;
			float vVel[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
			vVel[2] = 250.0;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
		}

		g_fLastFlags[client] = fCurFlags;
		g_fLastButtons[client] = fCurButtons;
	}
	
	/* [ Heal ] */
	if(g_cvFirstAidKitsON.BoolValue)
	{	
		if(!g_bOldButtons[client] && buttons & IN_USE)
		{
			g_bOldButtons[client] = true;
	
			if(g_iHeal[client] > 0)
			{
				int maxHP = GetConVarInt(g_cvFirstAidKitMaxHealth);
				int plusHP = GetConVarInt(g_cvFirstAidKitBonusHealth);
				int health = GetClientHealth(client);
			
				if(maxHP <= health)
					CPrintToChat(client, "%s Nie możesz się uleczyć, ponieważ masz {lime}%d {lightred}HP{default}.", PluginTag, health);
				else
				{
					if(maxHP - plusHP <= health) SetEntityHealth(client, maxHP);
					else SetEntityHealth(client, health + plusHP);
			
					g_iHeal[client]--;
					CPrintToChat(client, "%s Uleczyłeś się. Liczba pozostałych uleczeń to {lime}%d{default}!", PluginTag, g_iHeal[client]);
				}
			}
			else
				CPrintToChat(client, "%s {lightred}Nie posiadasz więcej uleczeń .", PluginTag, g_iHeal[client]);
			
			if(g_bOldButtons[client] && !(buttons & IN_USE))
				g_bOldButtons[client] = false;
		}
	}
	return Plugin_Continue;
}

/* [ Weapons Menu ] */
public void ShowPrimaryWeapons(int client)
{
	Menu VIPweapon = new Menu(Primary_weapon_Handler);
	VIPweapon.SetTitle("[# VIP by Yamakashi :: Wybór Broni # ]");
	VIPweapon.AddItem("weapon_ak47", "AK-47");
	VIPweapon.AddItem("weapon_m4a1", "M4A4");
	VIPweapon.AddItem("weapon_m4a1_silencer", "M4A1-S");
	VIPweapon.AddItem("weapon_awp", "AWP");
	VIPweapon.AddItem("weapon_ssg08", "SCOUT");
	VIPweapon.AddItem("weapon_xm1014", "XM1014");
	VIPweapon.AddItem("weapon_famas", "FAMAS");
	VIPweapon.AddItem("weapon_p90", "P90");
	VIPweapon.Display(client, 30);
}

public int Primary_weapon_Handler(Menu menu, MenuAction action, int client, int position)
{
	if(action == MenuAction_Select)
	{
		char sItem[32];
		menu.GetItem(position, sItem, sizeof(sItem));

		if(IsPlayerAlive(client))
		{
			StripAllWeapons(client);
			GivePlayerItem(client, "weapon_knife");
			GivePlayerItem(client, sItem);
			ShowSecondaryWeapons(client);
		}
	}
	else if(action == MenuAction_End)
		menu.Close();
}

public void ShowSecondaryWeapons(int client)
{
	Menu VIPweapon2 = new Menu(Secondary_weapon_Handler);
	VIPweapon2.SetTitle("[# VIP by Yamakashi :: Wybór Broni # ]");
	VIPweapon2.AddItem("weapon_deagle", "Deagle");
	VIPweapon2.AddItem("weapon_revolver", "R8 Revolver");
	VIPweapon2.AddItem("weapon_fiveseven", "Five-Seven");
	VIPweapon2.AddItem("weapon_tec9", "Tec-9");
	VIPweapon2.AddItem("weapon_cz75a", "CZ7a");
	VIPweapon2.AddItem("weapon_elite", "Dual Elites");
	VIPweapon2.AddItem("weapon_p250", "p250");
	VIPweapon2.Display(client, 30);
}

public int Secondary_weapon_Handler(Menu menu, MenuAction action, int client, int position)
{

	if(action == MenuAction_Select)
	{
		char sItem[32];
		menu.GetItem(position, sItem, sizeof(sItem));
		if(IsPlayerAlive(client)) GivePlayerItem(client, sItem);
	}
	else if (action == MenuAction_End)
		menu.Close();
}

public Action Vip_CMD(int client, int args)
{
	Menu VipInfo = new Menu(VipInfo_Handler);
	char sBuffer[1024];
	
	int MoneyOnRoundStart = g_cvMoneyOnRoundStart.IntValue;
	int ExtraMoneyForKill = g_cvExtraMoneyForKill.IntValue;
	int ExtraMoneyForHS = g_cvExtraMoneyForHS.IntValue;
	int ExtraMoneyForPlant = g_cvExtraMoneyForPlant.IntValue;
	int ExtraMoneyForDefuse = g_cvExtraMoneyForDefuse.IntValue;
	int HealthForHS = g_cvHealthForHs.IntValue;
	

	VipInfo.SetTitle("[ # VIP by Yamakashi :: Informacje o Vipie # ]");
	if(g_cvWelcomeHUD.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Powitanie na HUD podczas wejscia na serwer.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvWelcomeChat.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Powitanie na chacie podczas wejscia na serwer.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvHealth.IntValue > 100)
	{
		Format(sBuffer, sizeof(sBuffer), "Ma %d HP.", g_cvHealth.IntValue);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvGravity.FloatValue > 1.0)
	{
		Format(sBuffer, sizeof(sBuffer), "Zwiekszona grawitacje.", sBuffer);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvSpeed.FloatValue > 1.0)
	{
		Format(sBuffer, sizeof(sBuffer), "Zwiekszony movement speed.", sBuffer);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}	
		
	if(g_cvFlashbang.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje Flasha na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvHeGranade.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje HE na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvSmokeGranade.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje Smoke na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvIncGranade.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje granat taktyczny na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvMolotov.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje Molotova na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvHealthShot.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje healthshota na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvDecoy.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje Decoya na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvDefuser.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje Defusera na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvDoubleJump.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Ma double jumpa.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvHelmet.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje Helm na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvArmor.BoolValue)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje Kevlara na poczatku rundy.");
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	if(MoneyOnRoundStart > 0)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje dodatkowe %i $ na poczatku rundy.", MoneyOnRoundStart);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	if(ExtraMoneyForKill > 0)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje dodatkowe %i $ za zabojstwo.", ExtraMoneyForKill);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	if(ExtraMoneyForHS > 0)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje dodatkowe %i $ za headshota.", ExtraMoneyForHS);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	if(ExtraMoneyForPlant > 0)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje dodatkowe %i $ za podlozenie bomby.", ExtraMoneyForPlant);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	if(ExtraMoneyForDefuse > 0)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje dodatkowe %i $ za rozbrojenie bomby.", ExtraMoneyForDefuse);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
		
	if(g_cvVipTableTagEnable.BoolValue)
	{
		char sVipTag[128];
		g_cvVipTableTag.GetString(sVipTag, sizeof(sVipTag));
		Format(sBuffer, sizeof(sBuffer), "Tag w tabeli: %s.", sVipTag);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	if(g_cvVipChatTagEnable.BoolValue)
	{
		char VipTag[128];
		g_cvVipChatTag.GetString(VipTag, sizeof(VipTag));
		Format(sBuffer, sizeof(sBuffer), "Tag na chacie: %s.", VipTag);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	if(g_cvWeaponsMenu.BoolValue)
	{
		int FromRound = g_cvRoundWeaponsMenu.IntValue;
		Format(sBuffer, sizeof(sBuffer), "Od %i rundy wyswietla mu sie menu z bronmi", FromRound);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}

	if(g_cvFirstAidKitsON.BoolValue)
	{
		int FirstAidKits = GetConVarInt(g_cvFirstAidKits);
		int FirstAidKitsHeal = GetConVarInt(g_cvFirstAidKitBonusHealth);
		Format(sBuffer, sizeof(sBuffer), "Posiada %i apteczek o wartosci %i HP", FirstAidKits, FirstAidKitsHeal);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED);
	}
	
	if(HealthForHS > 0)
	{
		Format(sBuffer, sizeof(sBuffer), "Dostaje +%i HP za headshota", HealthForHS);
		VipInfo.AddItem("", sBuffer, ITEMDRAW_DISABLED); 
	}
	
	VipInfo.Display(client, 60);
}
	
public int VipInfo_Handler(Menu menu, MenuAction action, int client, int position)
{
	if(action == MenuAction_End)
		menu.Close();
}
	
/* [ Helpers ] */
stock void StripAllWeapons(int client)
{
	int iEnt;
	for (int i = 0; i <= 2; i++)
	{
		while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iEnt);
			AcceptEntityInput(iEnt, "Kill");
		}
	}
}

stock void RemoveNades(int client)
{
	while(RemoveWeaponBySlot(client, 3))	{  }
	for(int i = 0; i < 6; i++)
	SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_iGrenadeOffsets[i]);
}

stock bool RemoveWeaponBySlot(int client, int slot)
{
	int entity = GetPlayerWeaponSlot(client, slot);
	if (IsValidEdict(entity)) {
		RemovePlayerItem(client, entity);
		AcceptEntityInput(entity, "Kill");
		return true;
	}
	return false;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	if(IsFakeClient(client)) return false;
	return IsClientInGame(client);
}

stock int GetRandomPlayer(int team) 
{
	int random_player = GetConVarInt(g_cvVIPLotteryPlayersNeeded);
	int[] clients = new int[MaxClients];
	int clientCount;

	for(int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
		if((GetClientTeam(i) == team) && IsPlayerAlive(i))
			clients[clientCount++] = i;

	
	if (clientCount <= random_player)
	return -1;

	return clients[GetRandomInt(0, clientCount-1)];
}

stock bool IsPlayerVIP(int client)
{
	if (CheckCommandAccess(client, "ys_vip", 0, true))
		return true;

	return false;
}