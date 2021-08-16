#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <dhooks>

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "GOKZ Bot Model Fix",
	author = "zer0.k",
	description = "Fix GOKZ bots having broken animation in third person",
	version = "1.1",
	url = "https://github.com/zer0k-z/gokz-botmodelfix"
};
Handle gH_DHooks_OnSetEntityModel;
bool gB_Active;
bool gB_LateLoaded;
#define PLAYER_MODEL_T_FIX "models/player/custom_player/legacy/tm_leet_varianta.mdl"
#define PLAYER_MODEL_CT_FIX "models/player/custom_player/legacy/ctm_idf_variantc.mdl"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	gB_LateLoaded = true;
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvents();
	if (gB_LateLoaded)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsFakeClient(client) && !IsClientSourceTV(client))
			{
				DHookEntity(gH_DHooks_OnSetEntityModel, true, client);
			}
		}
	}
}

public void OnAllPluginsLoaded()
{
	gB_Active = LibraryExists("gokz-playermodels");
}

public void OnLibraryAdded(const char[] name)
{
	gB_Active = gB_Active || StrEqual(name, "gokz-playermodels");
}

public void OnLibraryRemoved(const char[] name)
{
	gB_Active = gB_Active && !StrEqual(name, "gokz-playermodels");
}

public void OnMapStart()
{
	PrecachePlayerModels();
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client) && !IsClientSourceTV(client))
	{	
		DHookEntity(gH_DHooks_OnSetEntityModel, true, client);
	}
}

void HookEvents()
{
	GameData gameData = new GameData("sdktools.games");
	int offset;
	offset = gameData.GetOffset("SetEntityModel");
	if (offset == -1)
	{
		SetFailState("Failed to get SetEntityModel offset");
	}
	gH_DHooks_OnSetEntityModel = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnSetEntityModel);
	DHookAddParam(gH_DHooks_OnSetEntityModel, HookParamType_CharPtr);
}

void PrecachePlayerModels()
{
	PrecacheModel(PLAYER_MODEL_T_FIX, true);
	PrecacheModel(PLAYER_MODEL_CT_FIX, true);
}

public MRESReturn DHooks_OnSetEntityModel(int client, Handle params)
{
	char model[PLATFORM_MAX_PATH];
	GetClientModel(client, model, sizeof(model));

	if (gB_Active && !StrEqual(model, PLAYER_MODEL_CT_FIX) && !StrEqual(model, PLAYER_MODEL_T_FIX))
	{
		RequestFrame(RequestFrame_FixBotModel, client);
	}
	return MRES_Ignored;
}

public void RequestFrame_FixBotModel(int client)
{
	if (!IsClientInGame(client) || !IsFakeClient(client) || IsClientSourceTV(client))
	{
		return;
	}
	switch (GetClientTeam(client))
	{
		case CS_TEAM_T:
		{
			SetEntityModel(client, PLAYER_MODEL_T_FIX);
		}
		case CS_TEAM_CT:
		{
			SetEntityModel(client, PLAYER_MODEL_CT_FIX);
		}
	}
	UpdatePlayerModelAlpha(client);
}

void UpdatePlayerModelAlpha(int client)
{
	ConVar gCV_gokz_player_models_alpha = FindConVar("gokz_player_models_alpha");
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, _, _, _, gCV_gokz_player_models_alpha.IntValue);
}