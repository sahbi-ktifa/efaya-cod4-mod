//******************************************************************************
//  _____                  _    _             __
// |  _  |                | |  | |           / _|
// | | | |_ __   ___ _ __ | |  | | __ _ _ __| |_ __ _ _ __ ___
// | | | | '_ \ / _ \ '_ \| |/\| |/ _` | '__|  _/ _` | '__/ _ \
// \ \_/ / |_) |  __/ | | \  /\  / (_| | |  | || (_| | | |  __/
//  \___/| .__/ \___|_| |_|\/  \/ \__,_|_|  |_| \__,_|_|  \___|
//       | |               We don't make the game you play.
//       |_|                 We make the game you play BETTER.
//
//            Website: http://openwarfaremod.com/
//******************************************************************************

#include maps\mp\_utility;
#include common_scripts\utility;
#include openwarfare\_utils;
#include maps\mp\gametypes\_hud_util;


init()
{
	// Get the main module's dvar
	level.scr_show_team_status = getdvarx( "scr_show_team_status", "int", 0, 0, 2 );

	// If show team status is not enabled then there's nothing else to do here
	if ( level.scr_show_team_status == 0 || !level.teamBased )
		return;

	level thread onPrematchOver();
	level thread onGameEnded();
}


onPrematchOver()
{
	if (level.gametype != "sr" && level.gametype != "csd") {
		self waittill( "prematch_over" );
		createHudElements();
		self startTeamStatusRefresh();
	} else {
		self waittill( "prematch_over" );
		createSRHudElements();
		self startSRTeamStatusRefresh();
	}
}

onGameEnded()
{
		if (level.gametype != "sr" && level.gametype != "csd") {
			self waittill("game_ended");
			wait (2.0);
			destroyHudElements();
		} else {
			self waittill("game_ended");
			wait (2.0);
			destroySRHudElements();
		}
}


destroyHudElements()
{
	// Destroy all the HUD elements
	game["teamStatusIconAllies"] destroy();
	game["teamStatusTextAlliesAlive"] destroy();
	game["teamStatusIconAxis"] destroy();
	game["teamStatusTextAxisAlive"] destroy();

	if ( level.scr_show_team_status == 2 ) {
		game["teamStatusIconAlliesForAxis"] destroy();
		game["teamStatusTextAlliesAliveForAxis"] destroy();
		game["teamStatusIconAxisForAllies"] destroy();
		game["teamStatusTextAxisAliveForAllies"] destroy();
	}

	return;
}

createHudElements()
{
	// Create the elements to show the allies team status
	game["teamStatusIconAllies"] = createServerIcon( game["icons"]["allies"], 32, 32, "allies" );
	game["teamStatusIconAllies"].archived = true;
	game["teamStatusIconAllies"].hideWhenInMenu = true;
	game["teamStatusIconAllies"].alignX = "center";
	game["teamStatusIconAllies"].alignY = "top";
	game["teamStatusIconAllies"].sort = -3;
	game["teamStatusIconAllies"].alpha = 0.9;

	game["teamStatusTextAlliesAlive"] = createServerFontString( "objective", 1.5, "allies" );
	game["teamStatusTextAlliesAlive"].archived = true;
	game["teamStatusTextAlliesAlive"].hideWhenInMenu = true;
	game["teamStatusTextAlliesAlive"].alignX = "left";
	game["teamStatusTextAlliesAlive"].alignY = "top";
	game["teamStatusTextAlliesAlive"].sort = -1;
	game["teamStatusTextAlliesAlive"] maps\mp\gametypes\_hud::fontPulseInit();

	// Create the elements to show the allies team status
	game["teamStatusIconAxis"] = createServerIcon( game["icons"]["axis"], 32, 32, "axis" );
	game["teamStatusIconAxis"].archived = true;
	game["teamStatusIconAxis"].hideWhenInMenu = true;
	game["teamStatusIconAxis"].alignX = "center";
	game["teamStatusIconAxis"].alignY = "top";
	game["teamStatusIconAxis"].sort = -3;
	game["teamStatusIconAxis"].alpha = 0.9;

	game["teamStatusTextAxisAlive"] = createServerFontString( "objective", 1.5, "axis" );
	game["teamStatusTextAxisAlive"].archived = true;
	game["teamStatusTextAxisAlive"].hideWhenInMenu = true;
	game["teamStatusTextAxisAlive"].alignX = "left";
	game["teamStatusTextAxisAlive"].alignY = "top";
	game["teamStatusTextAxisAlive"].sort = -1;
	game["teamStatusTextAxisAlive"] maps\mp\gametypes\_hud::fontPulseInit();

	if ( !level.hardcoreMode || level.scr_hud_hardcore_show_minimap ) {
		game["teamStatusIconAllies"].horzAlign = "left";
		game["teamStatusIconAllies"].vertAlign = "top";
		game["teamStatusIconAllies"].alignX = "left";
		game["teamStatusIconAllies"].x = 116;
		game["teamStatusIconAllies"].y = 22;
		game["teamStatusTextAlliesAlive"].horzAlign = "left";
		game["teamStatusTextAlliesAlive"].vertAlign = "top";
		game["teamStatusTextAlliesAlive"].x = 118;
		game["teamStatusTextAlliesAlive"].y = 37;

		game["teamStatusIconAxis"].horzAlign = "left";
		game["teamStatusIconAxis"].vertAlign = "top";
		game["teamStatusIconAxis"].alignX = "left";
		game["teamStatusIconAxis"].x = 116;
		game["teamStatusIconAxis"].y = 22;
		game["teamStatusTextAxisAlive"].horzAlign = "left";
		game["teamStatusTextAxisAlive"].vertAlign = "top";
		game["teamStatusTextAxisAlive"].x = 118;
		game["teamStatusTextAxisAlive"].y = 37;

	} else {
		game["teamStatusIconAllies"].horzAlign = "right";
		game["teamStatusIconAllies"].vertAlign = "bottom";
		game["teamStatusIconAllies"].x = -58;
		game["teamStatusIconAllies"].y = -85;
		game["teamStatusTextAlliesAlive"].horzAlign = "right";
		game["teamStatusTextAlliesAlive"].vertAlign = "bottom";
		game["teamStatusTextAlliesAlive"].x = -72;
		game["teamStatusTextAlliesAlive"].y = -70;

		game["teamStatusIconAxis"].horzAlign = "right";
		game["teamStatusIconAxis"].vertAlign = "bottom";
		game["teamStatusIconAxis"].x = -58;
		game["teamStatusIconAxis"].y = -85;
		game["teamStatusTextAxisAlive"].horzAlign = "right";
		game["teamStatusTextAxisAlive"].vertAlign = "bottom";
		game["teamStatusTextAxisAlive"].x = -72;
		game["teamStatusTextAxisAlive"].y = -70;

		if ( level.scr_show_team_status == 1) {
			game["teamStatusIconAllies"].x = -28;
			game["teamStatusIconAllies"].y = -85;
			game["teamStatusTextAlliesAlive"].x = -42;
			game["teamStatusTextAlliesAlive"].y = -70;

			game["teamStatusIconAxis"].x = -28;
			game["teamStatusIconAxis"].y = -85;
			game["teamStatusTextAxisAlive"].x = -42;
			game["teamStatusTextAxisAlive"].y = -70;
		}
	}

	if ( level.scr_show_team_status == 2) {
		// Create the elements to show the allies team status
		game["teamStatusIconAlliesForAxis"] = createServerIcon( game["icons"]["allies"], 32, 32, "axis" );
		game["teamStatusIconAlliesForAxis"].archived = true;
		game["teamStatusIconAlliesForAxis"].hideWhenInMenu = true;
		game["teamStatusIconAlliesForAxis"].alignX = "center";
		game["teamStatusIconAlliesForAxis"].alignY = "top";
		game["teamStatusIconAlliesForAxis"].sort = -3;
		game["teamStatusIconAlliesForAxis"].alpha = 0.9;

		game["teamStatusTextAlliesAliveForAxis"] = createServerFontString( "objective", 1.5, "axis" );
		game["teamStatusTextAlliesAliveForAxis"].archived = true;
		game["teamStatusTextAlliesAliveForAxis"].hideWhenInMenu = true;
		game["teamStatusTextAlliesAliveForAxis"].alignX = "left";
		game["teamStatusTextAlliesAliveForAxis"].alignY = "top";
		game["teamStatusTextAlliesAliveForAxis"].sort = -1;
		game["teamStatusTextAlliesAliveForAxis"] maps\mp\gametypes\_hud::fontPulseInit();

		// Create the elements to show the allies team status
		game["teamStatusIconAxisForAllies"] = createServerIcon( game["icons"]["axis"], 32, 32, "allies" );
		game["teamStatusIconAxisForAllies"].archived = true;
		game["teamStatusIconAxisForAllies"].hideWhenInMenu = true;
		game["teamStatusIconAxisForAllies"].alignX = "center";
		game["teamStatusIconAxisForAllies"].alignY = "top";
		game["teamStatusIconAxisForAllies"].sort = -3;
		game["teamStatusIconAxisForAllies"].alpha = 0.9;

		game["teamStatusTextAxisAliveForAllies"] = createServerFontString( "objective", 1.5, "allies" );
		game["teamStatusTextAxisAliveForAllies"].archived = true;
		game["teamStatusTextAxisAliveForAllies"].hideWhenInMenu = true;
		game["teamStatusTextAxisAliveForAllies"].alignX = "left";
		game["teamStatusTextAxisAliveForAllies"].alignY = "top";
		game["teamStatusTextAxisAliveForAllies"].sort = -1;
		game["teamStatusTextAxisAliveForAllies"] maps\mp\gametypes\_hud::fontPulseInit();

		if ( !level.hardcoreMode || level.scr_hud_hardcore_show_minimap ) {
			game["teamStatusIconAlliesForAxis"].horzAlign = "left";
			game["teamStatusIconAlliesForAxis"].vertAlign = "top";
			game["teamStatusIconAlliesForAxis"].alignX = "left";
			game["teamStatusIconAlliesForAxis"].x = 116;
			game["teamStatusIconAlliesForAxis"].y = 58;
			game["teamStatusTextAlliesAliveForAxis"].horzAlign = "left";
			game["teamStatusTextAlliesAliveForAxis"].vertAlign = "top";
			game["teamStatusTextAlliesAliveForAxis"].x = 118;
			game["teamStatusTextAlliesAliveForAxis"].y = 73;

			game["teamStatusIconAxisForAllies"].horzAlign = "left";
			game["teamStatusIconAxisForAllies"].vertAlign = "top";
			game["teamStatusIconAxisForAllies"].alignX = "left";
			game["teamStatusIconAxisForAllies"].x = 116;
			game["teamStatusIconAxisForAllies"].y = 58;
			game["teamStatusTextAxisAliveForAllies"].horzAlign = "left";
			game["teamStatusTextAxisAliveForAllies"].vertAlign = "top";
			game["teamStatusTextAxisAliveForAllies"].x = 118;
			game["teamStatusTextAxisAliveForAllies"].y = 73;
		} else {
			game["teamStatusIconAlliesForAxis"].horzAlign = "right";
			game["teamStatusIconAlliesForAxis"].vertAlign = "bottom";
			game["teamStatusIconAlliesForAxis"].x = -28;
			game["teamStatusIconAlliesForAxis"].y = -85;
			game["teamStatusTextAlliesAliveForAxis"].horzAlign = "right";
			game["teamStatusTextAlliesAliveForAxis"].vertAlign = "bottom";
			game["teamStatusTextAlliesAliveForAxis"].x = -42;
			game["teamStatusTextAlliesAliveForAxis"].y = -70;

			game["teamStatusIconAxisForAllies"].horzAlign = "right";
			game["teamStatusIconAxisForAllies"].vertAlign = "bottom";
			game["teamStatusIconAxisForAllies"].x = -28;
			game["teamStatusIconAxisForAllies"].y = -85;
			game["teamStatusTextAxisAliveForAllies"].horzAlign = "right";
			game["teamStatusTextAxisAliveForAllies"].vertAlign = "bottom";
			game["teamStatusTextAxisAliveForAllies"].x = -42;
			game["teamStatusTextAxisAliveForAllies"].y = -70;
		}
	}

	return;
}


startTeamStatusRefresh()
{
	self endon("game_ended");

	previousTeamStatus["allies"] = -1;
	previousTeamStatus["axis"] = -1;

	for (;;)
	{
		wait (0.1);

		// Initialize counters
		teamStatus["allies"]["alive"] = 0;
		teamStatus["allies"]["dead"] = 0;
		teamStatus["axis"]["alive"] = 0;
		teamStatus["axis"]["dead"] = 0;

		// Cycle through all the players
		for ( index = 0; index < level.players.size; index++ )
		{
			player = level.players[index];

			// Update counters depending on player's team and status
			switch ( player.pers["team"] )
			{
				case "allies":
					if ( isAlive( player ) && ( level.gametype != "ftag" || !player.freezeTag["frozen"] ) ) {
						teamStatus["allies"]["alive"]++;
					} else {
						teamStatus["allies"]["dead"]++;
					}
					break;
				case "axis":
					if ( isAlive( player ) && ( level.gametype != "ftag" || !player.freezeTag["frozen"] ) ) {
						teamStatus["axis"]["alive"]++;
					} else {
						teamStatus["axis"]["dead"]++;
					}
					break;
			}
		}

		// Update the HUD elements
		if ( previousTeamStatus["allies"] != teamStatus["allies"]["alive"] ) {
			previousTeamStatus["allies"] = teamStatus["allies"]["alive"];

			if ( teamStatus["allies"]["alive"] > 0 ) {
				game["teamStatusTextAlliesAlive"].color = ( 0.07, 0.69, 0.26 );
			} else {
				game["teamStatusTextAlliesAlive"].color = ( 0.694, 0.220, 0.114 );
			}
			game["teamStatusTextAlliesAlive"] setValue( teamStatus["allies"]["alive"] );
			game["teamStatusTextAlliesAlive"] thread maps\mp\gametypes\_hud::fontPulse( level );

			if ( level.scr_show_team_status == 2 ) {
				if ( teamStatus["allies"]["alive"] > 0 ) {
					game["teamStatusTextAlliesAliveForAxis"].color = ( 0.07, 0.69, 0.26 );
				} else {
					game["teamStatusTextAlliesAliveForAxis"].color = ( 0.694, 0.220, 0.114 );
				}
				game["teamStatusTextAlliesAliveForAxis"] setValue( teamStatus["allies"]["alive"] );
				game["teamStatusTextAlliesAliveForAxis"] thread maps\mp\gametypes\_hud::fontPulse( level );
			}
		}

		if ( previousTeamStatus["axis"] != teamStatus["axis"]["alive"] ) {
			previousTeamStatus["axis"] = teamStatus["axis"]["alive"];

			if ( teamStatus["axis"]["alive"] > 0 ) {
				game["teamStatusTextAxisAlive"].color = ( 0.07, 0.69, 0.26 );
			} else {
				game["teamStatusTextAxisAlive"].color = ( 0.694, 0.220, 0.114 );
			}
			game["teamStatusTextAxisAlive"] setValue( teamStatus["axis"]["alive"] );
			game["teamStatusTextAxisAlive"] thread maps\mp\gametypes\_hud::fontPulse( level );

			if ( level.scr_show_team_status == 2 ) {
				if ( teamStatus["axis"]["alive"] > 0 ) {
					game["teamStatusTextAxisAliveForAllies"].color = ( 0.07, 0.69, 0.26 );
				} else {
					game["teamStatusTextAxisAliveForAllies"].color = ( 0.694, 0.220, 0.114 );
				}
				game["teamStatusTextAxisAliveForAllies"] setValue( teamStatus["axis"]["alive"] );
				game["teamStatusTextAxisAliveForAllies"] thread maps\mp\gametypes\_hud::fontPulse( level );
			}
		}
	}
}

createSRHudElements() {

	game["playerStatusIconAllies"] = createServerIcon( game["icons"]["allies"], 24, 24 );
	game["playerStatusIconAllies"].x = -35;
	game["playerStatusIconAllies"].archived = true;
	game["playerStatusIconAllies"].hideWhenInMenu = true;
	game["playerStatusIconAllies"].alignX = "center";
	game["playerStatusIconAllies"].alignY = "top";
	game["playerStatusIconAllies"].sort = -3;
	game["playerStatusIconAllies"].alpha = 0.9;
	game["playerStatusIconAllies"].horzAlign = "center";
	game["playerStatusIconAllies"].vertAlign = "top";
	game["playerStatusIconAllies"].y = 5;

	game["playerStatusIconAxis"] = createServerIcon( game["icons"]["axis"], 24, 24 );
	game["playerStatusIconAxis"].x = 45;
	game["playerStatusIconAxis"].archived = true;
	game["playerStatusIconAxis"].hideWhenInMenu = true;
	game["playerStatusIconAxis"].alignX = "center";
	game["playerStatusIconAxis"].alignY = "top";
	game["playerStatusIconAxis"].sort = -3;
	game["playerStatusIconAxis"].alpha = 0.9;
	game["playerStatusIconAxis"].horzAlign = "center";
	game["playerStatusIconAxis"].vertAlign = "top";
	game["playerStatusIconAxis"].y = 5;

	game["playerStatusAliveAllies"] = createServerFontString( "default", 1.4 );
	game["playerStatusAliveAllies"] setPoint( "CENTER", "TOP", game["playerStatusIconAllies"].x + 10, 24 );
	game["playerStatusAliveAllies"] setValue( 0 );
	game["playerStatusAliveAllies"].info = 0;
	game["playerStatusAliveAllies"].archived = false;
	game["playerStatusAliveAllies"].foreground = true;
	game["playerStatusAliveAllies"].hidewheninmenu = true;
	game["playerStatusAliveAllies"].color = ( 0.694, 0.220, 0.114 );
	game["playerStatusAliveAllies"] maps\mp\gametypes\_hud::fontPulseInit();

	game["playerStatusAliveAxis"] = createServerFontString( "default", 1.4 );
	game["playerStatusAliveAxis"] setPoint( "CENTER", "TOP", game["playerStatusIconAxis"].x + 10, 24 );
	game["playerStatusAliveAxis"] setValue( 0 );
	game["playerStatusAliveAxis"].info = 0;
	game["playerStatusAliveAxis"].archived = false;
	game["playerStatusAliveAxis"].foreground = true;
	game["playerStatusAliveAxis"].hidewheninmenu = true;
	game["playerStatusAliveAxis"].color = ( 0.694, 0.220, 0.114 );
	game["playerStatusAliveAxis"] maps\mp\gametypes\_hud::fontPulseInit();

	game["playerStatusDeadIconAllies"] = createServerIcon( "hud_status_dead", 16, 16 );
	game["playerStatusDeadIconAllies"].x = game["playerStatusIconAllies"].x - 20;
	game["playerStatusDeadIconAllies"].archived = true;
	game["playerStatusDeadIconAllies"].hideWhenInMenu = true;
	game["playerStatusDeadIconAllies"].alignX = "center";
	game["playerStatusDeadIconAllies"].alignY = "top";
	game["playerStatusDeadIconAllies"].sort = -3;
	game["playerStatusDeadIconAllies"].horzAlign = "center";
	game["playerStatusDeadIconAllies"].vertAlign = "top";
	game["playerStatusDeadIconAllies"].y = 5;

	if (level.gametype == "sr") {
		game["playerStatusReviveIconAllies"] = createServerIcon( "cross_hud", 16, 16, "allies" );
		game["playerStatusReviveIconAllies"].x = game["playerStatusIconAllies"].x - 20;
		game["playerStatusReviveIconAllies"].archived = true;
		game["playerStatusReviveIconAllies"].hideWhenInMenu = true;
		game["playerStatusReviveIconAllies"].alignX = "center";
		game["playerStatusReviveIconAllies"].alignY = "top";
		game["playerStatusReviveIconAllies"].sort = -3;
		game["playerStatusReviveIconAllies"].horzAlign = "center";
		game["playerStatusReviveIconAllies"].vertAlign = "top";
		game["playerStatusReviveIconAllies"].y = 20;

		game["playerStatusEliminateIconAllies"] = createServerIcon( "skull_hud", 16, 16, "axis" );
		game["playerStatusEliminateIconAllies"].x = game["playerStatusIconAllies"].x - 20;
		game["playerStatusEliminateIconAllies"].archived = true;
		game["playerStatusEliminateIconAllies"].hideWhenInMenu = true;
		game["playerStatusEliminateIconAllies"].alignX = "center";
		game["playerStatusEliminateIconAllies"].alignY = "top";
		game["playerStatusEliminateIconAllies"].sort = -3;
		game["playerStatusEliminateIconAllies"].horzAlign = "center";
		game["playerStatusEliminateIconAllies"].vertAlign = "top";
		game["playerStatusEliminateIconAllies"].y = 20;

	}
	game["playerStatusDeadIconAxis"] = createServerIcon( "hud_status_dead", 16, 16 );
	game["playerStatusDeadIconAxis"].x = game["playerStatusIconAxis"].x + 23;
	game["playerStatusDeadIconAxis"].archived = true;
	game["playerStatusDeadIconAxis"].hideWhenInMenu = true;
	game["playerStatusDeadIconAxis"].alignX = "center";
	game["playerStatusDeadIconAxis"].alignY = "top";
	game["playerStatusDeadIconAxis"].sort = -3;
	game["playerStatusDeadIconAxis"].horzAlign = "center";
	game["playerStatusDeadIconAxis"].vertAlign = "top";
	game["playerStatusDeadIconAxis"].y = 5;

	if (level.gametype == "sr") {
		game["playerStatusReviveIconAxis"] = createServerIcon( "cross_hud", 16, 16, "axis" );
		game["playerStatusReviveIconAxis"].x = game["playerStatusIconAxis"].x + 23;
		game["playerStatusReviveIconAxis"].archived = true;
		game["playerStatusReviveIconAxis"].hideWhenInMenu = true;
		game["playerStatusReviveIconAxis"].alignX = "center";
		game["playerStatusReviveIconAxis"].alignY = "top";
		game["playerStatusReviveIconAxis"].sort = -3;
		game["playerStatusReviveIconAxis"].horzAlign = "center";
		game["playerStatusReviveIconAxis"].vertAlign = "top";
		game["playerStatusReviveIconAxis"].y = 20;

		game["playerStatusEliminateIconAxis"] = createServerIcon( "skull_hud", 16, 16, "allies" );
		game["playerStatusEliminateIconAxis"].x = game["playerStatusIconAxis"].x + 23;
		game["playerStatusEliminateIconAxis"].archived = true;
		game["playerStatusEliminateIconAxis"].hideWhenInMenu = true;
		game["playerStatusEliminateIconAxis"].alignX = "center";
		game["playerStatusEliminateIconAxis"].alignY = "top";
		game["playerStatusEliminateIconAxis"].sort = -3;
		game["playerStatusEliminateIconAxis"].horzAlign = "center";
		game["playerStatusEliminateIconAxis"].vertAlign = "top";
		game["playerStatusEliminateIconAxis"].y = 20;
	}

	game["playerStatusDeadAllies"] = createServerFontString( "default", 1.4 );
	game["playerStatusDeadAllies"] setPoint( "CENTER", "TOP", game["playerStatusIconAllies"].x - 32, 10 );
	game["playerStatusDeadAllies"] setValue( 0 );
	game["playerStatusDeadAllies"].info = 0;
	game["playerStatusDeadAllies"].archived = false;
	game["playerStatusDeadAllies"].foreground = true;
	game["playerStatusDeadAllies"].hidewheninmenu = true;
	game["playerStatusDeadAllies"].color = ( 0.694, 0.220, 0.114 );
	game["playerStatusDeadAllies"] maps\mp\gametypes\_hud::fontPulseInit();

	if (level.gametype == "sr") {
		game["playerStatusReviveAllies"] = createServerFontString( "default", 1.4 );
		game["playerStatusReviveAllies"] setPoint( "CENTER", "TOP", game["playerStatusIconAllies"].x - 32, 25 );
		game["playerStatusReviveAllies"] setValue( 0 );
		game["playerStatusReviveAllies"].info = 0;
		game["playerStatusReviveAllies"].archived = false;
		game["playerStatusReviveAllies"].foreground = true;
		game["playerStatusReviveAllies"].hidewheninmenu = true;
		game["playerStatusReviveAllies"].color = ( 0.694, 0.220, 0.114 );
		game["playerStatusReviveAllies"] maps\mp\gametypes\_hud::fontPulseInit();
	}

	game["playerStatusDeadAxis"] = createServerFontString( "default", 1.4 );
	game["playerStatusDeadAxis"] setPoint( "CENTER", "TOP", game["playerStatusIconAxis"].x + 35, 10 );
	game["playerStatusDeadAxis"] setValue( 0 );
	game["playerStatusDeadAxis"].info = 0;
	game["playerStatusDeadAxis"].archived = false;
	game["playerStatusDeadAxis"].foreground = true;
	game["playerStatusDeadAxis"].hidewheninmenu = true;
	game["playerStatusDeadAxis"].color = ( 0.694, 0.220, 0.114 );
	game["playerStatusDeadAxis"] maps\mp\gametypes\_hud::fontPulseInit();

	if (level.gametype == "sr") {
		game["playerStatusReviveAxis"] = createServerFontString( "default", 1.4 );
		game["playerStatusReviveAxis"] setPoint( "CENTER", "TOP", game["playerStatusIconAxis"].x + 35, 25 );
		game["playerStatusReviveAxis"] setValue( 0 );
		game["playerStatusReviveAxis"].info = 0;
		game["playerStatusReviveAxis"].archived = false;
		game["playerStatusReviveAxis"].foreground = true;
		game["playerStatusReviveAxis"].hidewheninmenu = true;
		game["playerStatusReviveAxis"].color = ( 0.694, 0.220, 0.114 );
		game["playerStatusReviveAxis"] maps\mp\gametypes\_hud::fontPulseInit();
	}
}


startSRTeamStatusRefresh() {
	self endon("game_ended");

	for (;;)
	{
		wait (0.1);

		alliesAlive = 0;
		alliesRevive = 0;
		alliesDead = 0;
		axisAlive = 0;
		axisRevive = 0;
		axisDead = 0;

		for ( index = 0; index < level.players.size; index++ )
		{
			player = level.players[index];
			if (isAlive(player)) {
				if (player.pers["team"] == "allies") {
					alliesAlive += 1;
				} else if (player.pers["team"] == "axis") {
					axisAlive += 1;
				}
			} else if (!isAlive(player) && isDefined(player.pers["tag"]) && player.pers["tag"] == true) {
				if (player.pers["team"] == "allies") {
					alliesRevive += 1;
				} else if (player.pers["team"] == "axis") {
					axisRevive += 1;
				}
			} else if (!isAlive(player)) {
				if (player.pers["team"] == "allies") {
					alliesDead += 1;
				} else if (player.pers["team"] == "axis") {
					axisDead += 1;
				}
			}
		}
		if (game["playerStatusAliveAllies"].info != alliesAlive) {
			game["playerStatusAliveAllies"].info = alliesAlive;
			if (game["playerStatusAliveAllies"].info == 0) {
				game["playerStatusAliveAllies"].color = ( 0.694, 0.220, 0.114 );
			} else if (game["playerStatusAliveAllies"].info > 0) {
				game["playerStatusAliveAllies"].color = ( 0.07, 0.69, 0.26 );
			}
			game["playerStatusAliveAllies"] setValue(alliesAlive);
			game["playerStatusAliveAllies"] thread maps\mp\gametypes\_hud::fontPulse( level );
		}
		if (game["playerStatusAliveAxis"].info != axisAlive) {
			game["playerStatusAliveAxis"].info = axisAlive;
			if (game["playerStatusAliveAxis"].info == 0) {
				game["playerStatusAliveAxis"].color = ( 0.694, 0.220, 0.114 );
			} else if (game["playerStatusAliveAxis"].info > 0) {
				game["playerStatusAliveAxis"].color = ( 0.07, 0.69, 0.26 );
			}
			game["playerStatusAliveAxis"] setValue(axisAlive);
			game["playerStatusAliveAxis"] thread maps\mp\gametypes\_hud::fontPulse( level );
		}
		if (game["playerStatusDeadAllies"].info != alliesDead) {
			game["playerStatusDeadAllies"].info = alliesDead;
			game["playerStatusDeadAllies"] setValue(alliesDead);
			game["playerStatusDeadAllies"] thread maps\mp\gametypes\_hud::fontPulse( level );
		}
		if (level.gametype == "sr" && game["playerStatusReviveAllies"].info != alliesRevive) {
			game["playerStatusReviveAllies"].info = alliesRevive;
			if (game["playerStatusReviveAllies"].info == 0) {
				game["playerStatusReviveAllies"].color = ( 0.694, 0.220, 0.114 );
			} else if (game["playerStatusReviveAllies"].info > 0) {
				game["playerStatusReviveAllies"].color = ( 1, 1, 0.108 );
			}
			game["playerStatusReviveAllies"] setValue(alliesRevive);
			game["playerStatusReviveAllies"] thread maps\mp\gametypes\_hud::fontPulse( level );
		}
		if (game["playerStatusDeadAxis"].info != axisDead) {
			game["playerStatusDeadAxis"].info = axisDead;
			game["playerStatusDeadAxis"] setValue(axisDead);
			game["playerStatusDeadAxis"] thread maps\mp\gametypes\_hud::fontPulse( level );
		}
		if (level.gametype == "sr" && game["playerStatusReviveAxis"].info != axisRevive) {
			game["playerStatusReviveAxis"].info = axisRevive;
			if (game["playerStatusReviveAxis"].info == 0) {
				game["playerStatusReviveAxis"].color = ( 0.694, 0.220, 0.114 );
			} else if (game["playerStatusReviveAxis"].info > 0) {
				game["playerStatusReviveAxis"].color = ( 1, 1, 0.108 );
			}
			game["playerStatusReviveAxis"] setValue(axisRevive);
			game["playerStatusReviveAxis"] thread maps\mp\gametypes\_hud::fontPulse( level );
		}
	}
}

destroySRHudElements() {
		game["playerStatusIconAllies"] destroy();
		game["playerStatusIconAxis"] destroy();
		game["playerStatusAliveAllies"] destroy();
		game["playerStatusAliveAxis"] destroy();
		game["playerStatusDeadIconAllies"] destroy();
		game["playerStatusDeadIconAxis"] destroy();
		game["playerStatusDeadAllies"] destroy();
		game["playerStatusDeadAxis"] destroy();
		if (level.gametype == "sr") {
			game["playerStatusReviveIconAllies"] destroy();
			game["playerStatusEliminateIconAllies"] destroy();
			game["playerStatusReviveIconAxis"] destroy();
			game["playerStatusEliminateIconAxis"] destroy();
			game["playerStatusReviveAllies"] destroy();
			game["playerStatusReviveAxis"] destroy();
		}
}
