//**********************************************************************************
//
//        _   _       _        ___  ___      _        ___  ___          _
//       | | | |     | |       |  \/  |     | |       |  \/  |         | |
//       | |_| | ___ | |_   _  | .  . | ___ | |_   _  | .  . | ___   __| |___
//       |  _  |/ _ \| | | | | | |\/| |/ _ \| | | | | | |\/| |/ _ \ / _` / __|
//       | | | | (_) | | |_| | | |  | | (_) | | |_| | | |  | | (_) | (_| \__ \
//       \_| |_/\___/|_|\__, | \_|  |_/\___/|_|\__, | \_|  |_/\___/ \__,_|___/
//                       __/ |                  __/ |
//                      |___/                  |___/
//
//                       Website: http://www.holymolymods.com
//*********************************************************************************
// Coded for Openwarfare Mod by [105]HolyMoly  Nov.06/2013
// V.5.0 Final

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include openwarfare\_utils;

/*
	Search and Rescue
	Attackers objective: Bomb one of 2 positions
	Defenders objective: Defend these 2 positions / Defuse planted bombs
	Round ends:	When one team is eliminated, bomb explodes, bomb is defused, or roundlength time is reached
	Map ends:	When one team reaches the score limit, or time limit or round limit is reached
	Respawning:	Players can be revived by friendlies if tags are picked up or remain dead if enemies pick up tags.

	Level requirements
	------------------
		Allied Spawnpoints:
			classname		mp_sd_spawn_attacker
			Allied players spawn from these. Place at least 16 of these relatively close together.

		Axis Spawnpoints:
			classname		mp_sd_spawn_defender
			Axis players spawn from these. Place at least 16 of these relatively close together.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

		Bombzones:
			classname					trigger_multiple
			targetname					bombzone
			script_gameobjectname		bombzone
			script_bombmode_original	<if defined this bombzone will be used in the original bomb mode>
			script_bombmode_single		<if defined this bombzone will be used in the single bomb mode>
			script_bombmode_dual		<if defined this bombzone will be used in the dual bomb mode>
			script_team					Set to allies or axis. This is used to set which team a bombzone is used by in dual bomb mode.
			script_label				Set to A or B. This sets the letter shown on the compass in original mode.
			This is a volume of space in which the bomb can planted. Must contain an origin brush.

		Bomb:
			classname				trigger_lookat
			targetname				bombtrigger
			script_gameobjectname	bombzone
			This should be a 16x16 unit trigger with an origin brush placed so that it's center lies on the bottom plane of the trigger.
			Must be in the level somewhere. This is the trigger that is used when defusing a bomb.
			It gets moved to the position of the planted bomb model.

	Level script requirements
	-------------------------
		Team Definitions:
			game["allies"] = "marines";
			game["axis"] = "opfor";
			This sets the nationalities of the teams. Allies can be american, british, or russian. Axis can be german.

			game["attackers"] = "allies";
			game["defenders"] = "axis";
			This sets which team is attacking and which team is defending. Attackers plant the bombs. Defenders protect the targets.

		If using minefields or exploders:
			maps\mp\_load::main();

	Optional level script settings
	------------------------------
		Soldier Type and Variation:
			game["american_soldiertype"] = "normandy";
			game["german_soldiertype"] = "normandy";
			This sets what character models are used for each nationality on a particular map.

			Valid settings:
				american_soldiertype	normandy
				british_soldiertype		normandy, africa
				russian_soldiertype		coats, padded
				german_soldiertype		normandy, africa, winterlight, winterdark

		Exploder Effects:
			Setting script_noteworthy on a bombzone trigger to an exploder group can be used to trigger additional effects.
*/

/*QUAKED mp_sd_spawn_attacker (0.0 1.0 0.0) (-16 -16 0) (16 16 72)
Attacking players spawn randomly at one of these positions at the beginning of a round.*/

/*QUAKED mp_sd_spawn_defender (1.0 0.0 0.0) (-16 -16 0) (16 16 72)
Defending players spawn randomly at one of these positions at the beginning of a round.*/

main()
{

	if(getdvar("mapname") == "mp_background")
		return;

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	level.scr_sr_sdmode = getdvarx( "scr_sr_sdmode", "int", 0, 0, 1  );
	level.scr_sr_scoreboard_bomb_carrier = getdvarx( "scr_sr_scoreboard_bomb_carrier", "int", 0, 0, 1 );
	level.scr_sr_bomb_notification_enable = getdvarx( "scr_sr_bomb_notification_enable", "int", 1, 0, 1 );
	level.scr_sr_planting_sound = getdvarx( "scr_sr_planting_sound", "int", 1, 0, 1 );
	level.scr_sr_defusing_sound = getdvarx( "scr_sr_defusing_sound", "int", 1, 0, 1 );
	level.scr_sr_show_briefcase = getdvarx( "scr_sr_show_briefcase", "int", 1, 0, 1 );
	level.scr_sr_bombsites_enabled = getdvarx( "scr_sr_bombsites_enabled", "int", 0, 0, 4 );
	level.scr_sr_bombtimer_show = getdvarx( "scr_sr_bombtimer_show", "int", 1, 0, 1 );
	level.scr_sr_defenders_show_both = getdvarx( "scr_sr_defenders_show_both", "int", 0, 0, 1 );

        level.scr_sr_objective_takedamage_enable = getdvarx( "scr_sr_objective_takedamage_enable", "int", 0, 0, 1 );
        level.scr_sr_objective_takedamage_option = getdvarx( "scr_sr_objective_takedamage_option", "int", 0, 0, 1 );

        if ( level.scr_sr_objective_takedamage_option )
                level.scr_sr_objective_takedamage_health = getdvarx( "scr_sr_objective_takedamage_health", "int", 500, 1, 2000 );
        else
                level.scr_sr_objective_takedamage_counter = getdvarx( "scr_sr_objective_takedamage_counter", "int", 5, 1, 20 );

        level.scr_sr_allow_defender_explosivepickup = getdvarx( "scr_sr_allow_defender_explosivepickup", "int", 0, 0, 1 );
        level.scr_sr_allow_defender_explosivedestroy = getdvarx( "scr_sr_allow_defender_explosivedestroy", "int", 0, 0, 1 );
        level.scr_sr_allow_defender_explosivedestroy_time = getdvarx( "scr_sr_allow_defender_explosivedestroy_time", "int", 10, 1, 60 );
        level.scr_sr_allow_defender_explosivedestroy_sound = getdvarx( "scr_sr_allow_defender_explosivedestroy_sound", "int", 0, 0, 1 );
        level.scr_sr_allow_defender_explosivedestroy_win = getdvarx( "scr_sr_allow_defender_explosivedestroy_win", "int", 0, 0, 1 );
        level.scr_sr_allow_quickdefuse = getdvarx( "scr_sr_allow_quickdefuse", "int", 0, 0, 1 );

	level.scr_sr_dogtag_autoremoval_time = getdvarx( "scr_sr_dogtag_autoremoval_time", "int", 15, 0, 60 );
	level.scr_sr_enemy_dogtag_score = getdvarx( "scr_sr_enemy_dogtag_score", "int", 10, 0, 500 );
        level.scr_sr_team_dogtag_score = getdvarx( "scr_sr_team_dogtag_score", "int", 5, 0, 500 );
        level.scr_sr_dogtag_obits = getdvarx( "scr_sr_dogtag_obits", "int", 1, 0, 1 );
        level.scr_sr_denied_player_sound = getdvarx( "scr_sr_denied_player_sound", "int", 0, 0, 1 );
        level.scr_sr_denied_team_sound = getdvarx( "scr_sr_denied_team_sound", "int", 1, 0, 1 );
        level.scr_sr_show_dogtags_minimap = getdvarx( "scr_sr_show_dogtags_minimap", "int", 1, 0, 1 );
        level.scr_sr_dogtags_explode_fx = getdvarx( "scr_sr_dogtags_explode_fx", "int", 1, 0, 1 );
        level.scr_sr_dogtag_attacker_owner_score = getdvarx( "scr_sr_dogtag_attacker_owner_score", "int", 5, 0, 500 );

        level.scr_sr_random_second_chance = getdvarx( "scr_sr_random_second_chance", "int", 75, 0, 100 );
	level.scr_sr_revive_time = getdvarx( "scr_sr_revive_time", "int", 2, 2, 10 );

	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 1, 1, 1 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 5, 0, 500 );
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 2, 0, 500 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 3, 0, 5000 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 4, 0, 1440 );


	level.teamBased = true;
	level.overrideTeamScore = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onDeadEvent = ::onDeadEvent;
	level.onOneLeftEvent = ::onOneLeftEvent;
	level.onTimeLimit = ::onTimeLimit;
	level.onRoundSwitch = ::onRoundSwitch;
	level.getTeamKillPenalty = ::sr_getTeamKillPenalty;
	level.getTeamKillScore = ::sr_getTeamKillScore;

	level.endGameOnScoreLimit = false;

	game["dialog"]["gametype"] = gameTypeDialog( "searchrescue" );
	game["dialog"]["offense_obj"] = "obj_destroy";
	game["dialog"]["defense_obj"] = "obj_defend";
}


onPrecacheGameType()
{
	game["bombmodelname"] = "mil_tntbomb_mp";
	game["bombmodelnameobj"] = "mil_tntbomb_mp";
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";
	precacheModel(game["bombmodelname"]);
	precacheModel(game["bombmodelnameobj"]);

	precacheShader("waypoint_bomb");
	precacheShader("hud_suitcase_bomb");
	precacheShader("waypoint_target");
	precacheShader("waypoint_target_a");
	precacheShader("waypoint_target_b");
	precacheShader("waypoint_defend");
	precacheShader("waypoint_defend_a");
	precacheShader("waypoint_defend_b");
	precacheShader("waypoint_defuse");
	precacheShader("waypoint_defuse_a");
	precacheShader("waypoint_defuse_b");
	precacheShader("compass_waypoint_target");
	precacheShader("compass_waypoint_target_a");
	precacheShader("compass_waypoint_target_b");
	precacheShader("compass_waypoint_defend");
	precacheShader("compass_waypoint_defend_a");
	precacheShader("compass_waypoint_defend_b");
	precacheShader("compass_waypoint_defuse");
	precacheShader("compass_waypoint_defuse_a");
	precacheShader("compass_waypoint_defuse_b");
	precacheShader("compass_waypoint_bomb");

	precacheStatusIcon( "hud_status_bomb" );

	precacheString( &"MP_EXPLOSIVES_RECOVERED_BY" );
	precacheString( &"MP_EXPLOSIVES_DROPPED_BY" );
	precacheString( &"MP_EXPLOSIVES_PLANTED_BY" );
	precacheString( &"MP_EXPLOSIVES_DEFUSED_BY" );
	precacheString( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	precacheString( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	precacheString( &"MP_CANT_PLANT_WITHOUT_BOMB" );
	precacheString( &"MP_PLANTING_EXPLOSIVE" );
	precacheString( &"MP_DEFUSING_EXPLOSIVE" );

	precacheModel( "prop_suitcase_bomb" );

	precacheShader( "cross_hud" );
	precacheShader( "skull_hud" );
	precacheShader("hud_status_dead");
        precacheModel( "skull_ddogtag" );
        precacheModel( "cross_ddogtag" );

        game[level.gameType]["cross_fx"] = loadfx( "impacts/dogtag_explode_white" );
        game[level.gameType]["skull_fx"] = loadfx( "impacts/dogtag_explode_red" );

}

sr_getTeamKillPenalty( eInflictor, attacker, sMeansOfDeath, sWeapon )
{
	teamkill_penalty = maps\mp\gametypes\_globallogic::default_getTeamKillPenalty( eInflictor, attacker, sMeansOfDeath, sWeapon );

	if ( ( isdefined( self.isDefusing ) && self.isDefusing ) || ( isdefined( self.isPlanting ) && self.isPlanting ) )
	{
		teamkill_penalty = teamkill_penalty * level.teamKillPenaltyMultiplier;
	}

	return teamkill_penalty;
}

sr_getTeamKillScore( eInflictor, attacker, sMeansOfDeath, sWeapon )
{
	teamkill_score = maps\mp\gametypes\_rank::getScoreInfoValue( "kill" );

	if ( ( isdefined( self.isDefusing ) && self.isDefusing ) || ( isdefined( self.isPlanting ) && self.isPlanting ) )
	{
		teamkill_score = teamkill_score * level.teamKillScoreMultiplier;
	}

	return int(teamkill_score);
}

onRoundSwitch()
{
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	if ( game["teamScores"]["allies"] == level.scorelimit - 1 && game["teamScores"]["axis"] == level.scorelimit - 1 )
	{
		// overtime! team that's ahead in kills gets to defend.
		aheadTeam = getBetterTeam();
		if ( aheadTeam != game["defenders"] )
		{
			game["switchedsides"] = !game["switchedsides"];
		}
		else
		{
			level.halftimeSubCaption = "";
		}
		level.halftimeType = "overtime";
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
	}
}

getBetterTeam()
{
	kills["allies"] = 0;
	kills["axis"] = 0;
	deaths["allies"] = 0;
	deaths["axis"] = 0;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		team = player.pers["team"];
		if ( isDefined( team ) && (team == "allies" || team == "axis") )
		{
			kills[ team ] += player.kills;
			deaths[ team ] += player.deaths;
		}
	}

	if ( kills["allies"] > kills["axis"] )
		return "allies";
	else if ( kills["axis"] > kills["allies"] )
		return "axis";

	// same number of kills

	if ( deaths["allies"] < deaths["axis"] )
		return "allies";
	else if ( deaths["axis"] < deaths["allies"] )
		return "axis";

	// same number of deaths

	if ( randomint(2) == 0 )
		return "allies";
	return "axis";
}

onStartGameType()
{
	if ( !isDefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	setClientNameMode( "manual_change" );

	game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";
	game["strings"]["bomb_defused"] = &"MP_BOMB_DEFUSED";

	precacheString( game["strings"]["target_destroyed"] );
	precacheString( game["strings"]["bomb_defused"] );

	level._effect["bombexplosion"] = loadfx("explosions/tanker_explosion");

	maps\mp\gametypes\_globallogic::setObjectiveText( game["attackers"], &"OBJECTIVES_SD_ATTACKER" );
	maps\mp\gametypes\_globallogic::setObjectiveText( game["defenders"], &"OBJECTIVES_SD_DEFENDER" );

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"OBJECTIVES_SD_ATTACKER" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"OBJECTIVES_SD_DEFENDER" );
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], &"OBJECTIVES_SD_ATTACKER_SCORE" );
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], &"OBJECTIVES_SD_DEFENDER_SCORE" );
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], &"OBJECTIVES_SD_ATTACKER_HINT" );
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], &"OBJECTIVES_SD_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_attacker" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_sd_spawn_defender" );

	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	level.displayRoundEndText = true;

	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	maps\mp\gametypes\_gameobjects::main(allowed);

	thread updateGametypeDvars();

	thread bombs();

        //Dogtag ObjIds
        level.dogtagObjIds = 0;

}

onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;
        self.isDisconnected = false;

	// Create the hud element for the new connected player
	self.hud_cross_icon = newClientHudElem( self );
	self.hud_cross_icon.x = 0;
	self.hud_cross_icon.y = 142;
	self.hud_cross_icon.alignX = "center";
	self.hud_cross_icon.alignY = "middle";
	self.hud_cross_icon.horzAlign = "center_safearea";
	self.hud_cross_icon.vertAlign = "center_safearea";
	self.hud_cross_icon.alpha = 0;
	self.hud_cross_icon.archived = true;
	self.hud_cross_icon.hideWhenInMenu = true;
	self.hud_cross_icon setShader( "cross_hud", 32, 32);
	if(self.pers["team"] == game["attackers"])
		spawnPointName = "mp_sd_spawn_attacker";
	else
		spawnPointName = "mp_sd_spawn_defender";

	if ( level.multiBomb && !isDefined( self.carryIcon ) && self.pers["team"] == game["attackers"] && !level.bombPlanted )
	{
		if ( level.splitscreen )
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 35, 35 );
			self.carryIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -10, -50 );
			self.carryIcon.alpha = 0.75;
		}
		else
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 50, 50 );
			self.carryIcon setPoint( "CENTER", "CENTER", 220, 140 );
			self.carryIcon.alpha = 0.75;
		}
	}

	spawnPoints = getEntArray( spawnPointName, "classname" );
	assert( spawnPoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );

	self spawn( spawnpoint.origin, spawnpoint.angles );
	level notify ( "spawned_player" );

	if ( level.scr_sr_allow_quickdefuse == 1 )
		self.didQuickDefuse = false;

	if ( level.scr_sr_allow_defender_explosivepickup && level.scr_sr_allow_defender_explosivedestroy && self.pers["team"] == game["defenders"] && getDvar( "g_gametype" ) == "sr" )
		self thread allowDefenderExplosiveDestroy();

		if (isDefined(self.toBeRespawned) && self.toBeRespawned == true) {
			self.toBeRespawned = false;
			self setOrigin( self.toBeRespawnedOrigin );
			self ExecClientCommand("gocrouch");
			self ExecClientCommand("goprone");
			self.health = 50;
		} else {
			self.pers["stats"]["misc"]["hitman"] = 0;
			self.pers["stats"]["misc"]["medic"] = 0;
		}

}


onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	thread checkAllowSpectating();


	// No tags for falling, suicides or team kills
	//if( isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] && attacker != self )
	if( isPlayer( attacker ) && attacker != self && sHitLoc != "head" && sHitLoc != "helmet" && sMeansOfDeath != "MOD_MELEE") {
		if (isDefined(self.revivedOnce) && self.revivedOnce == true) { // Has already been revived once so no more revival
			broadcastInfo("eliminate", attacker, self);
		} else {
			broadcastInfo("shot", attacker, self);
			self thread spawnTags( attacker );
		}
	} else if (sHitLoc == "head" || sHitLoc == "helmet") {
		broadcastInfo("hs", attacker, self);
	}  else if (sMeansOfDeath == "MOD_MELEE") {
		broadcastInfo("knife", attacker, self);	
	} else if ( sMeansOfDeath == "MOD_FALLING" || ( isPlayer( attacker ) && attacker == self ) ) {
		broadcastInfo("suicide", attacker, self);
	}
	if( isDefined( self.destroyingExplosive ) && self.destroyingExplosive == true ) {
		self updateSecondaryProgressBar( undefined, undefined, true, undefined );
	}

	if( isPlayer( attacker ) && attacker.pers["team"] != self.pers["team"] && attacker != self ) {
		thread maps\mp\gametypes\_finalkillcam::onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	}
	if ( isDefined( self.hud_cross_icon ) )
		self.hud_cross_icon destroy();
}

broadcastInfo(type, attacker, victim, debugMsg) {
	for ( i = 0; i < level.players.size; i++ ) {
		msg = "";
		if (type == "shot") {
			if (level.players[i].pers["team"] == attacker.pers["team"]) {
				msg += "^2" + attacker.name + " ^7shot down ";
			} else {
				msg += "^1" + attacker.name + " ^7shot down ";
			}
			if (level.players[i].pers["team"] == victim.pers["team"]) {
				msg += "^2" + victim.name + "^7!";
			} else {
				msg += "^1" + victim.name + "^7!";
			}

		} else if (type == "hs") {
			if (level.players[i].pers["team"] == attacker.pers["team"]) {
				msg += "^2" + attacker.name + " ^7has eliminated with a headshot ";
			} else {
				msg += "^1" + attacker.name + " ^7has eliminated with a headshot ";
			}
			if (level.players[i].pers["team"] == victim.pers["team"]) {
				msg += "^2" + victim.name + "^7!";
			} else {
				msg += "^1" + victim.name + "^7!";
			}
		} else if (type == "knife") {
			if (level.players[i].pers["team"] == attacker.pers["team"]) {
				msg += "^2" + attacker.name + " ^7has eliminated with a knife melee ";
			} else {
				msg += "^1" + attacker.name + " ^7has eliminated with a knife melee ";
			}
			if (level.players[i].pers["team"] == victim.pers["team"]) {
				msg += "^2" + victim.name + "^7!";
			} else {
				msg += "^1" + victim.name + "^7!";
			}
		} else if (type == "suicide") {
			if (level.players[i].pers["team"] == victim.pers["team"]) {
				msg += "^2" + victim.name + " ^7.... has been ELIMINATED by ... himself... commiting suicide!";
			} else {
				msg += "^1" + victim.name + " ^7.... has been ELIMINATED by ... himself... commiting suicide!";
			}
		} else if (type == "revive") {
			if (level.players[i].pers["team"] == attacker.pers["team"]) {
				msg += "^2" + attacker.name + "^7.... Revived ";
			} else {
				msg += "^1" + attacker.name + "^7.... Revived ";
			}
			if (level.players[i].pers["team"] == victim.pers["team"]) {
				msg += "^2" + victim.name + " ^7!";
			} else {
				msg += "^1" + victim.name + " ^7!";
			}
		} else if (type == "eliminate") {
			if (level.players[i].pers["team"] == victim.pers["team"]) {
				msg += "^2" + victim.name + " ^7.... has been ELIMINATED!";
			} else {
				msg += "^1" + victim.name + " ^7.... has been ELIMINATED!";
			}
		} else if (type == "debug") {
			msg = debugMsg;
		}
		ClientPrint(level.players[i], msg);
	}

}

checkAllowSpectating()
{
	wait ( 0.05 );

	update = false;
	if ( !level.aliveCount[ game["attackers"] ] )
	{
		level.spectateOverride[game["attackers"]].allowEnemySpectate = 1;
		update = true;
	}
	if ( !level.aliveCount[ game["defenders"] ] )
	{
		level.spectateOverride[game["defenders"]].allowEnemySpectate = 1;
		update = true;
	}
	if ( update )
		maps\mp\gametypes\_spectating::updateSpectateSettings();
}


sr_endGame( winningTeam, endReasonText )
{

	logPrint("SR_ENDGAME;" + winningTeam + "\n");

	if ( isdefined( winningTeam ) )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );

	thread maps\mp\gametypes\_finalkillcam::endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
	if ( level.bombExploded || level.bombDefused )
		return;

	if ( team == "all" )
	{
		if ( level.bombPlanted )
			sr_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
		else
			sr_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		if ( level.bombPlanted )
			return;

		sr_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		sr_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
	}
}


onOneLeftEvent( team )
{
	if ( level.bombExploded || level.bombDefused )
		return;

	//if ( team == game["attackers"] )
	warnLastPlayer( team );
}


onTimeLimit()
{
	if ( level.teamBased )
		sr_endGame( game["defenders"], game["strings"]["time_limit_reached"] );
	else
		sr_endGame( undefined, game["strings"]["time_limit_reached"] );
}


warnLastPlayer( team )
{
	if ( !isdefined( level.warnedLastPlayer ) )
		level.warnedLastPlayer = [];

	if ( isDefined( level.warnedLastPlayer[team] ) )
		return;

	level.warnedLastPlayer[team] = true;

	players = level.players;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( isDefined( player.pers["team"] ) && player.pers["team"] == team && isdefined( player.pers["class"] ) )
		{
			if ( player.sessionstate == "playing" && !player.afk )
				break;
		}
	}

	if ( i == players.size )
		return;

	players[i] thread giveLastAttackerWarning();
}


giveLastAttackerWarning()
{
	self endon("death");
	self endon("disconnect");

	fullHealthTime = 0;
	interval = .05;

	while(1)
	{
		if ( self.health != self.maxhealth )
			fullHealthTime = 0;
		else
			fullHealthTime += interval;

		wait interval;

		if (self.health == self.maxhealth && fullHealthTime >= 3)
			break;
	}

	//self iprintlnbold(&"MP_YOU_ARE_THE_ONLY_REMAINING_PLAYER");
	self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "last_alive" );

	self maps\mp\gametypes\_missions::lastManSD();
}


updateGametypeDvars()
{
	level.plantTime = getdvarx( "scr_sr_planttime", "float", 5, 0, 20 );
	level.defuseTime = getdvarx( "scr_sr_defusetime", "float", 8, 0, 20 );
	level.bombTimer = getdvarx( "scr_sr_bombtimer", "float", 60, 1, 300 );
	level.multiBomb = getdvarx( "scr_sr_multibomb", "int", 0, 0, 1 );

	// Calculate the bomb timer with the random modifier
	maxModifier = level.bombTimer - 5;
	if ( maxModifier < 0 ) {
		maxModifier = 0;
	}
	level.scr_sr_bombtimer_modifier = getdvarx( "scr_sr_bombtimer_modifier", "int", 0, 0, maxModifier );
	level.bombTimer = randomFloatRange( level.bombTimer - level.scr_sr_bombtimer_modifier, level.bombTimer + level.scr_sr_bombtimer_modifier + 1 );

	level.teamKillPenaltyMultiplier = dvarFloatValue( "teamkillpenalty", 2, 0, 10 );
	level.teamKillScoreMultiplier = dvarFloatValue( "teamkillscore", 4, 0, 40 );
}


bombs()
{
	level.bombPlanted = false;
	level.bombDefused = false;
	level.bombExploded = false;

	trigger = getEnt( "sd_bomb_pickup_trig", "targetname" );
	if ( !isDefined( trigger ) )
	{
		maps\mp\_utility::error("No sd_bomb_pickup_trig trigger found in map.");
		return;
	}

	visuals[0] = getEnt( "sd_bomb", "targetname" );
	if ( !isDefined( visuals[0] ) )
	{
		maps\mp\_utility::error("No sd_bomb script_model found in map.");
		return;
	}

	visuals[0] setModel( "prop_suitcase_bomb" );

	if ( !level.multiBomb )
	{
		level.sdBomb = maps\mp\gametypes\_gameobjects::createCarryObject( game["attackers"], trigger, visuals, (0,0,32) );

		if ( level.scr_sr_allow_defender_explosivepickup )
 	                level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "any" );
 	   	else
			level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );

		level.sdBomb maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
		level.sdBomb maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );

		level.sdBomb maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", undefined );
		level.sdBomb maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", undefined );

		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setCarryIcon( "hud_suitcase_bomb" );
		level.sdBomb.allowWeapons = true;
		level.sdBomb.onPickup = ::onPickup;
		level.sdBomb.onDrop = ::onDrop;
	}
	else
	{
		trigger delete();
		visuals[0] delete();
	}


	level.bombZones = [];

	bombZones = getEntArray( "bombzone", "targetname" );

	for ( index = 0; index < bombZones.size; index++ )
	{
		trigger = bombZones[index];
		visuals = getEntArray( bombZones[index].target, "targetname" );

		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,64) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
		bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
		bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );

		if ( !level.multiBomb )
			bombZone maps\mp\gametypes\_gameobjects::setKeyObject( level.sdBomb );

		label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		bombZone.label = label;
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		bombZone.onBeginUse = ::onBeginUse;
		bombZone.onEndUse = ::onEndUse;
		bombZone.onUse = ::onUsePlantObject;
		bombZone.onCantUse = ::onCantUse;

		if( level.scr_sr_show_briefcase == 1 )
			bombZone.useWeapon = "briefcase_bomb_mp";

		for ( i = 0; i < visuals.size; i++ )
		{
			if ( isDefined( visuals[i].script_exploder ) )
			{
				bombZone.exploderIndex = visuals[i].script_exploder;
				break;
			}
		}

		level.bombZones[level.bombZones.size] = bombZone;

		bombZone.bombDefuseTrig = getent( visuals[0].target, "targetname" );
		assert( isdefined( bombZone.bombDefuseTrig ) );
		bombZone.bombDefuseTrig.origin += (0,0,-10000);
		bombZone.bombDefuseTrig.label = label;
	}

	for ( index = 0; index < level.bombZones.size; index++ )
	{
		array = [];
		for ( otherindex = 0; otherindex < level.bombZones.size; otherindex++ )
		{
			if ( otherindex != index )
				array[ array.size ] = level.bombZones[otherindex];
		}
		level.bombZones[index].otherBombZones = array;
	}
	// Settings for bombsites
	if ( level.scr_sr_bombsites_enabled == 1 && level.bombZones.size == 2 )
	{
		if( percentChance( 50 ) )
			{
				// Use both bombs, just set a dummy if this is chosen.
				index = index;
			}
			else
			{
				if( percentChance( 50 ) )
					level.bombZones[0] disableObject();
				else
					level.bombZones[1] disableObject();
			}

	}
	else if ( level.scr_sr_bombsites_enabled == 3 && level.bombZones.size == 2 )
	{
				index = 1;
				level.bombZones[1] disableObject();
	}
	else if ( level.scr_sr_bombsites_enabled == 4 )
			{
				index = 0;
				level.bombZones[0] disableObject();
			}
		// Random bomb, either bombsite a or bombsite b
	else if ( level.scr_sr_bombsites_enabled == 2 && level.bombZones.size == 2 )
			{
				if( percentChance( 50 ) )
					level.bombZones[0] disableObject();
				else
					level.bombZones[1] disableObject();
			}
// End Settings bombsites
}

onBeginUse( player )
{
	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if( level.scr_sr_defusing_sound == 1 )
			player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;

		if ( level.scr_sr_allow_quickdefuse )
 	      //player thread openwarfare\_objoptions::quickDefuse();
 	      player thread quickDefuse();

		if ( isDefined( level.sdBombModel ) )
			level.sdBombModel hide();
	}
	else
	{
		if( level.scr_sr_planting_sound == 1 )
			player playSound( "mp_bomb_plant" );

		player.isPlanting = true;

		if ( level.multibomb )
		{
			for ( i = 0; i < self.otherBombZones.size; i++ )
			{
				self.otherBombZones[i] maps\mp\gametypes\_gameobjects::allowUse( "none" );
			}
		}
	}
}

onEndUse( team, player, result )
{
	if ( !isAlive( player ) )
		return;

	player.isDefusing = false;
	player.isPlanting = false;

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( level.sdBombModel ) && !result )
		{
			level.sdBombModel show();
		}
	}
	else
	{
		if ( level.multibomb && !result )
		{
			for ( i = 0; i < self.otherBombZones.size; i++ )
			{
				self.otherBombZones[i] maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
			}
		}
	}
}

onCantUse( player )
{
	player iPrintLnBold( &"MP_CANT_PLANT_WITHOUT_BOMB" );
}

onUsePlantObject( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlanted( self, player );
		player logString( "bomb planted: " + self.label );

		lpselfnum = player getEntityNumber();
		lpGuid = player getGuid();
		logPrint("BP;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");

		// disable all bomb zones except this one
		for ( index = 0; index < level.bombZones.size; index++ )
		{
			if ( level.bombZones[index] == self )
				continue;

			if ( level.scr_sr_sdmode == 0 ) {
				level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
			} else {
				level.bombZones[index] maps\mp\gametypes\_gameobjects::allowUse( "none" );
			}
		}

		if( level.scr_sr_planting_sound == 0 )
			player playSound( "mp_bomb_plant" );

		player notify ( "bomb_planted" );

		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );

		if ( level.scr_sr_bomb_notification_enable == 1 )
			maps\mp\gametypes\_globallogic::leaderDialog( "bomb_planted" );

		maps\mp\gametypes\_globallogic::givePlayerScore( "plant", player );
		player thread [[level.onXPEvent]]( "plant" );
	}

}

onUseDefuseObject( player )
{
	wait .05;

	player notify ( "bomb_defused" );
	player logString( "bomb defused: " + self.label );
	level thread bombDefused();

	lpselfnum = player getEntityNumber();
	lpGuid = player getGuid();
	logPrint("BD;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");

	// disable this bomb zone
	self maps\mp\gametypes\_gameobjects::disableObject();

	if ( !level.hardcoreMode )
		iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );

	maps\mp\gametypes\_globallogic::leaderDialog( "bomb_defused" );

	maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", player );
	player thread [[level.onXPEvent]]( "defuse" );
}

onDrop( player )
{
	if ( !level.bombPlanted )
	{
		if( isDefined( player ) &&  player.pers["team"] == game["attackers"] ) {

			player.isBombCarrier = false;

                        if( isDefined( player.name ) )
			        printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", game["attackers"], player );

			if ( level.scr_sr_scoreboard_bomb_carrier == 1 && isAlive( player ) ) {
				player.statusicon = "";
			}

		        maps\mp\gametypes\_globallogic::leaderDialog( "bomb_lost", player.pers["team"] );

		        if ( isDefined( player ) )
		 	        player logString( "bomb dropped" );
		        else
		 	        logString( "bomb dropped" );

	                self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );

		        maps\mp\_utility::playSoundOnPlayers( game["bomb_dropped_sound"], game["attackers"] );

                } else if( isDefined( player ) &&  player.pers["team"] == game["defenders"] ) {

                        player.isBombCarrier = false;

 	                maps\mp\_utility::playSoundOnPlayers( game["bomb_dropped_sound"], game["defenders"] );

                        if( isDefined( player.name ) )
                                printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", game["defenders"], player );

                        maps\mp\gametypes\_globallogic::leaderDialog( "bomb_lost", player.pers["team"] );

		        if ( isDefined( player ) )
		 	        player logString( "bomb dropped" );
		        else
		 	        logString( "bomb dropped" );

                        self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
                        self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );

                        self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", undefined );
                        self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", undefined );

                        self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );

                } else {

                        self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
                        self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );

                        self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", undefined );
                        self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", undefined );

                        self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
                }


        }
}

onPickup( player )
{

	if ( !level.bombDefused )
        {

	        if ( isDefined( player ) && player.pers["team"] == game["defenders"] && level.scr_sr_allow_defender_explosivedestroy ) {

                        player.isBombCarrier = true;

		        player iprintlnBold( &"OW_DESTROY_EXPLOSIVES" );

                        self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", undefined );
                        self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", undefined );

                        self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" );
                        self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" );

                        self maps\mp\gametypes\_gameobjects::setVisibleTeam( "enemy" );

		        if ( isDefined( player ) && isDefined( player.name ) ) {
			        printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", game["defenders"], player );
                        }

		        maps\mp\gametypes\_globallogic::leaderDialog( "bomb_taken", player.pers["team"] );
                        maps\mp\_utility::playSoundOnPlayers( game["bomb_recovered_sound"], game["defenders"] );

		        player logString( "bomb taken" );
                }

	        if ( isDefined( player ) && player.pers["team"] == game["attackers"] ) {

                        player.isBombCarrier = true;

                        if( level.scr_sr_scoreboard_bomb_carrier == 1 ) {
		                player.statusicon = "hud_status_bomb";
                        }

		        self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );

                        maps\mp\_utility::playSoundOnPlayers( game["bomb_recovered_sound"], game["attackers"] );
		        maps\mp\gametypes\_globallogic::leaderDialog( "bomb_taken", player.pers["team"] );

		        if ( isDefined( player ) && isDefined( player.name ) ) {
			        printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", game["attackers"], player );
                        }

		        player logString( "bomb taken" );
	        }

        }
}

onReset()
{

}

bombPlanted( destroyedObj, player )
{
	maps\mp\gametypes\_globallogic::pauseTimer();
	level.bombPlanted = true;

	if ( level.scr_sr_bomb_notification_enable == 1 )
		destroyedObj.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();

	level.tickingObject = destroyedObj.visuals[0];

	level.timeLimitOverride = true;

	setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );

	if ( level.scr_sr_bombtimer_show == 1 )
		setDvar( "ui_bomb_timer", 1 );

	if ( !level.multiBomb )
	{
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setDropped();
		level.sdBombModel = level.sdBomb.visuals[0];
	}
	else
	{

		for ( index = 0; index < level.players.size; index++ )
		{
			if ( isDefined( level.players[index].carryIcon ) )
				level.players[index].carryIcon destroyElem();
		}

		trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );

		tempAngle = randomfloat( 360 );
		forward = (cos( tempAngle ), sin( tempAngle ), 0);
		forward = vectornormalize( forward - vector_scale( trace["normal"], vectordot( forward, trace["normal"] ) ) );
		dropAngles = vectortoangles( forward );

		level.sdBombModel = spawn( "script_model", trace["position"] );
		level.sdBombModel.angles = dropAngles;
		level.sdBombModel setModel( "prop_suitcase_bomb" );
	}
	destroyedObj maps\mp\gametypes\_gameobjects::allowUse( "none" );

	// Check if we need to hide the bomb site in the radar
	if ( level.scr_sr_sdmode == 0 ) {
		destroyedObj maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	}

	label = destroyedObj maps\mp\gametypes\_gameobjects::getLabel();

	// create a new object to defuse with.
	trigger = destroyedObj.bombDefuseTrig;
	trigger.origin = level.sdBombModel.origin;
	visuals = [];
	defuseObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,32) );
	defuseObject maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	defuseObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );

	// Check if we need to show the defuse/defend icons
	if ( level.scr_sr_sdmode == 0 ) {
		defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" + label );
		defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" + label );
		defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" + label );
		defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" + label );
	} else {
		// Show defuse/defend on both sites
		for ( idx = 0; idx < level.bombZones.size; idx++ ) {
			label = level.bombZones[ idx ] maps\mp\gametypes\_gameobjects::getLabel();
			level.bombZones[ idx ] maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_defuse" + label );
			level.bombZones[ idx ] maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "compass_waypoint_defend" + label );
			level.bombZones[ idx ] maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" + label );
			level.bombZones[ idx ] maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" + label );
		}
	}

	defuseObject.label = label;
	defuseObject.onBeginUse = ::onBeginUse;
	defuseObject.onEndUse = ::onEndUse;
	defuseObject.onUse = ::onUseDefuseObject;

	if( level.scr_sr_show_briefcase == 1 )
		defuseObject.useWeapon = "briefcase_bomb_defuse_mp";

	level.defuseObject = defuseObject;

	BombTimerWait();
	setDvar( "ui_bomb_timer", 0 );

        if ( level.scr_sr_bomb_notification_enable == 1 )
		destroyedObj.visuals[0] maps\mp\gametypes\_globallogic::stopTickingSound();

	if ( level.gameEnded || level.bombDefused )
		return;

	level.bombExploded = true;

	explosionOrigin = level.sdBombModel.origin;
	level.sdBombModel hide();

	if ( isdefined( player ) )
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
	else
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );

	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );

	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );

	if ( isDefined( destroyedObj.exploderIndex ) )
		exploder( destroyedObj.exploderIndex );

	for ( index = 0; index < level.bombZones.size; index++ )
		level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
	defuseObject maps\mp\gametypes\_gameobjects::disableObject();

	setGameEndTime( 0 );

	wait 3;

	sr_endGame( game["attackers"], game["strings"]["target_destroyed"] );
}

BombTimerWait()
{
	level endon("game_ended");
	level endon("bomb_defused");
	level endon("wrong_wire");
	wait level.bombTimer;
}

playSoundinSpace( alias, origin )
{
	org = spawn( "script_origin", origin );
	org.origin = origin;
	org playSound( alias  );
	wait 10; // MP doesn't have "sounddone" notifies =(
	org delete();
}

bombDefused()
{
	level.tickingObject maps\mp\gametypes\_globallogic::stopTickingSound();
	level.bombDefused = true;
	setDvar( "ui_bomb_timer", 0 );

	level notify("bomb_defused");

	wait 1.5;

	setGameEndTime( 0 );

	sr_endGame( game["defenders"], game["strings"]["bomb_defused"] );
}


disableObject()
{
	// Check if the bombzone should still show to the defenders
	if ( level.scr_sr_defenders_show_both == 1 ) {
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
		self maps\mp\gametypes\_gameobjects::allowUse( "none" );
	} else {
		self maps\mp\gametypes\_gameobjects::disableObject();
	}
}

createDamageArea()
{
        if ( getDvar( "g_gametype" ) != "sr" )
                return;

        while ( !isDefined( level.bombZones ) )
                wait( 0.5 );

        bombZones = getEntArray( "bombzone", "targetname" );
        level.damageArea = [];
        level.damageArea2 = [];
        level.objectiveTakeDamage = false; //used to make sure only one script_model makes a call to destroy target

        for ( index = 0; index < bombZones.size; index++ )
        {
                visuals = getEntArray( bombZones[index].target, "targetname" );
                if ( index == 0 )
                {
                        if ( level.scr_sr_objective_takedamage_option )
                                level.objectiveHealth[index] = level.scr_sr_objective_takedamage_health;
                        else
                                level.objectiveHealth[index] = level.scr_sr_objective_takedamage_counter;

                        level.objDamageCounter[index] = 0;
                        level.objDamageTotal[index] = 0;
                        level.isLosingHealth[index] = false;

                        //Script models with no setModel used to check for damage.
                        for ( i = 0; i < 5; i++ )
                        {
                                switch( i )
                                {
                                        case 0:
                                                level.damageArea[index] = spawn( "script_model", bombZones[index].origin + ( 0, 0, 85 ) );
                                                break;
                                        case 1:
                                                level.damageArea[index] = spawn( "script_model", bombZones[index].origin + ( 75, 0, 10 ) );
                                                break;
                                        case 2:
                                                level.damageArea[index] = spawn( "script_model", bombZones[index].origin + ( -75, 0, 10 ) );
                                                break;
                                        case 3:
                                                level.damageArea[index] = spawn( "script_model", bombZones[index].origin + ( 0, 75, 10 ) );
                                                break;
                                        case 4:
                                                level.damageArea[index] = spawn( "script_model", bombZones[index].origin + ( 0, -75, 10 ) );
                                                break;
                                }

                                level.damageArea[index] setcandamage( true ); //Allows the script_model to receive damage
                                level.damageArea[index].health = 100000; //A high value is all we need
                                level.damageArea[index] thread waitForDamage( index, bombZones[index], visuals );
                       }
               }

               else {
                       if ( level.scr_sr_objective_takedamage_option )
                               level.objectiveHealth[index] = level.scr_sr_objective_takedamage_health;
                       else
                               level.objectiveHealth[index] = level.scr_sr_objective_takedamage_counter;

                       level.objDamageCounter[index] = 0;
                       level.objDamageTotal[index] = 0;
                       level.isLosingHealth[index] = false;

                               for ( i = 0; i < 5; i++ )
                               {
                                       switch( i )
                                       {
                                               case 0:
                                                       level.damageArea2[index] = spawn( "script_model", bombZones[index].origin + ( 0, 0, 85 ) );
                                                       break;
                                               case 1:
                                                       level.damageArea2[index] = spawn( "script_model", bombZones[index].origin + ( 75, 0, 10 ) );
                                                       break;
                                               case 2:
                                                       level.damageArea2[index] = spawn( "script_model", bombZones[index].origin + ( -75, 0, 10 ) );
                                                       break;
                                               case 3:
                                                       level.damageArea2[index] = spawn( "script_model", bombZones[index].origin + ( 0, 75, 10 ) );
                                                       break;
                                               case 4:
                                                       level.damageArea2[index] = spawn( "script_model", bombZones[index].origin + ( 0, -75, 10 ) );
                                                       break;
                                       }

                                       level.damageArea2[index] setcandamage( true );
                                       level.damageArea2[index].health = 100000;
                                       level.damageArea2[index] thread waitForDamage( index, bombZones[index], visuals );
                               }


               }

        }

}

waitForDamage( index, object, visuals )
{
        attacker = undefined;

        while ( 1 )
        {
                if ( level.objectiveHealth[index] <= 0 )
                        break;

                self waittill( "damage", damage, attacker );

                if ( level.scr_sr_objective_takedamage_option )
                {
                        level.objDamageCounter[index]++;
                        level.objDamageTotal[index] += damage;
                }

                wait( 0.1 );

                if ( isDefined( attacker ) && isPlayer( attacker ) )
                {
                        if ( attacker.pers["team"] == game["defenders"] )
                        {
                                if ( !level.isLosingHealth[index] )
                                {
                                        level.isLosingHealth[index] = true;
                                                if ( level.scr_sr_objective_takedamage_option )
                                                {
                                                        level.objectiveHealth[index] -= int( level.objDamageTotal[index] / level.objDamageCounter[index] );
                                                        level.objDamageCounter[index] = 0;
                                                        level.objDamageTotal[index] = 0;
                                                }

                                                else
                                                {
                                                        level.objectiveHealth[index]--;
                                                }

                                                wait( 0.1 );

                                                level.isLosingHealth[index] = false;
                                }
                        }
                }

                wait( 0.1 );
        }

        if ( !level.objectiveTakeDamage )
        {
                level.objectiveTakeDamage = true;
                self thread destroyObjective( object, visuals, attacker );
        }
}

destroyObjective( object, visuals, attacker )
{

        if ( isDefined( level.bombExploded ) && !level.bombExploded )
                level.bombExploded = true;
        else
                return;

        for ( i = 0; i < visuals.size; i++ )
        {
		if ( isDefined( visuals[i].script_exploder ) )
		{
			object.exploderIndex = visuals[i].script_exploder;
			break;
		}
	}

        visuals[0] radiusDamage( object.origin, 512, 200, 20, attacker, "MOD_EXPLOSIVE", "briefcase_bomb_mp" );

        rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], object.origin + ( 0, 0, 50 ), ( 0, 0, 1 ), ( cos( rot ),sin( rot ),0 ) );
	triggerFx( explosionEffect );

	exploder( object.exploderIndex );

	thread playSoundinSpace( "exp_suitcase_bomb_main", object.origin );

	setGameEndTime( 0 );

	wait( 3.0 );

	sr_endGame( game["attackers"], game["strings"]["target_destroyed"] );

}

allowDefenderExplosiveDestroy() // Finally fixed animation issue
{
        self endon( "disconnect" );
        self endon( "death" );

        self.destroyingExplosive = false;
        self.explosiveDestroyed = false;
        lastWeapon = self getCurrentWeapon();
        startTime = 0;
        destroyTime = level.scr_sr_allow_defender_explosivedestroy_time;

        while ( isAlive( self ) && !level.bombPlanted && !level.gameEnded && !self.explosiveDestroyed )
        {
                while ( isAlive( self ) && self meleeButtonPressed() && self.isBombCarrier && !level.gameEnded )
                {
                        if ( startTime == 0 )
                        {
                                if ( level.scr_sr_allow_defender_explosivedestroy_sound ) {
                                        self playSound( "mp_bomb_defuse" );
                                }

                                wait( 0.5 ); //Give time for melee animation to finish

                                if ( self meleeButtonpressed() )
                                {
                                        if( level.scr_sr_show_briefcase )
                                        {
                                                self thread openwarfare\_speedcontrol::setModifierSpeed( "_objpoints", 95 );
                                                self giveWeapon( "briefcase_bomb_mp" );
                                                self setWeaponAmmoStock( "briefcase_bomb_mp", 0 );
                                                self setWeaponAmmoClip( "briefcase_bomb_mp", 0 );
                                                self switchToWeapon( "briefcase_bomb_mp" );
                                                self maps\mp\gametypes\_gameobjects::attachUseModel( "prop_suitcase_bomb","tag_inhand", true );

                                                if( !self meleeButtonPressed() ) {
                                                        self execClientCommand( "weapprev" );
                                                        break;
                                                }

                                                while ( self getCurrentWeapon() != "briefcase_bomb_mp")
            	                                        wait( 0.25 );

                                        }

                                        else

                                        {
                                                self thread openwarfare\_healthsystem::stopPlayer( true );
                                        }

                                        startTime = openwarfare\_timer::getTimePassed();
                                        self.destroyingExplosive = true;
                                }

                                else

                                {
                                        if( level.scr_sr_show_briefcase ) {
                                                self execClientCommand( "weapprev" );
                                        }

                                        break;
                                }

                        }

                        wait( 0.05 );

                        timeHack = ( openwarfare\_timer::getTimePassed() - startTime ) / 1000;
                        self updateSecondaryProgressBar( timeHack, destroyTime, false, &"OW_DESTROYING_EXPLOSIVES" );

                        if ( timeHack >= destroyTime )
                        {
                                self.explosiveDestroyed = true;
                                break;
                        }

                        if( level.scr_sr_show_briefcase && self getCurrentWeapon() != "briefcase_bomb_mp" )
      	                        break;

                        if( level.scr_sr_show_briefcase )
                        {

                                if ( !isDefined( self.carryObject ) ) {
                                        self execClientCommand( "weapprev" );
                                        self thread openwarfare\_speedcontrol::setModifierSpeed( "_objpoints", 0 );
                                        break;
                                }

                                if( !self meleeButtonPressed() ) {
                                        self execClientCommand( "weapprev" );
                                        self thread openwarfare\_speedcontrol::setModifierSpeed( "_objpoints", 0 );
                                        break;
                                }

                                if( self fragButtonPressed() || self SecondaryOffhandButtonPressed() || self UseButtonPressed() ) {
                                        self execClientCommand( "weapprev" );
                                        self thread openwarfare\_speedcontrol::setModifierSpeed( "_objpoints", 0 );
                                        break;
                                }
                        }

                        else

                        {
                                if ( !isDefined( self.carryObject ) ) {
                                        self thread openwarfare\_healthsystem::stopPlayer( false );
                                        break;
                                }

                                if( !self meleeButtonPressed() ) {
                                        self thread openwarfare\_healthsystem::stopPlayer( false );
                                        break;
                                }


                                if( self fragButtonPressed() || self SecondaryOffhandButtonPressed() || self UseButtonPressed() ) {
                                        self thread openwarfare\_healthsystem::stopPlayer( false );
                                        break;
                                }
                        }
                }


                self updateSecondaryProgressBar( undefined, undefined, true, undefined );
                self.destroyingExplosive = false;

                self maps\mp\gametypes\_gameobjects::detachUseModels();

                startTime = 0;

                wait( 0.50 );

        }

        if ( !level.bombPlanted && !level.gameEnded && level.scr_sr_allow_defender_explosivedestroy_win )
        {
                setGameEndTime( 0 );

                sr_endGame( game["defenders"], &"OW_EXPLOSIVES_DESTROYED" );

                if( level.scr_sr_show_briefcase ) {
                        self freezeControls( false );
                        self execClientCommand( "weapprev" );
                        wait( 0.50 );
                        self freezeControls( true );
                }

                maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", self );
		self thread [[level.onXPEvent]]( "defuse" );

        }

        else if ( !level.scr_sr_allow_defender_explosivedestroy_win && !level.bombPlanted && !level.gameEnded )
        {
	        self.isBombCarrier = false;

                if( level.scr_sr_show_briefcase ) {

                        self execClientCommand( "weapprev" );
                        wait( 0.50 );
                        self thread openwarfare\_speedcontrol::setModifierSpeed( "_objpoints", 0 );
                }

                else

                {
                        self thread openwarfare\_healthsystem::stopPlayer( false );
                }

	        self takeWeapon( "briefcase_bomb_mp" );

                // Notify defenders
                self printBoldOnTeam( &"OW_EXPLOSIVES_DESTROYED", game["defenders"] );
                playSoundOnPlayers( "mp_obj_captured", game["defenders"] );

	        if ( isDefined( level.sdBomb ) )
		        level.sdBomb maps\mp\gametypes\_gameobjects::disableObject();
        }

        else

        {
                // Finish animation if trying to Destroy Explosives
                if( level.gameEnded && self meleeButtonPressed() && self hasWeapon( "briefcase_bomb_mp") ) {
                        if( level.scr_sr_show_briefcase ) {
                                self freezeControls( false );
                                self execClientCommand( "weapprev" );
                                wait( 0.50 );
                                self freezeControls( true );
                        }
                }
        }

}

quickDefuse()
{
        self endon( "disconnect" );
        self endon( "death" );

        if ( self.didQuickDefuse )
  	        return;

        self.isChangingWire = false;

        if ( isAlive( self ) && self.isDefusing && !level.gameEnded && !level.bombExploded )
        {
                bombwire[0] = &"OW_RED_WIRE";
                bombwire[1] = &"OW_GREEN_WIRE";
                bombwire[2] = &"OW_YELLOW_WIRE";
                bombwire[3] = &"OW_BLUE_WIRE";

                correctWire = randomIntRange( 0, 4 );
                playerChoice = 0;

                self iprintlnbold( &"OW_QUICK_DEFUSE_1" );
                self iprintlnbold( &"OW_QUICK_DEFUSE_2" );

                while ( self.isDefusing && isAlive( self ) && !level.gameEnded && !level.bombExploded && !self.didQuickDefuse )
                {
                        if ( self attackButtonPressed() ) {
      	                        self.didQuickDefuse = true;
				self thread quickDefuseResults( playerChoice, correctWire );

                        } else if ( self adsButtonPressed() && !self.isChangingWire ) {
                                self.isChangingWire = true;
                                self allowAds( false );

                                if ( playerChoice == 3 )
                                        playerChoice = 0;
                                else
                                        playerChoice++;

                                self iprintlnbold( bombwire[playerChoice] );
                                wait( 0.1 );
                                self.isChangingWire = false;
                                self allowAds( true );
                        }

                        wait( 0.05 );
                }

        }

}

quickDefuseResults( playerChoice, correctWire )
{
        level endon ( "game_ended" );

        if ( playerChoice == correctWire && isAlive( self ) && !level.gameEnded && !level.bombExploded ) {
  	        level.defuseObject thread onUseDefuseObject( self );
						//[[level._setTeamScore]]( self.pers["team"], [[level._getTeamScore]]( self.pers["team"] ) + 1 );

        } else if ( playerChoice != correctWire && isAlive( self ) && !level.gameEnded && !level.bombExploded ) {
  	        level notify( "wrong_wire" );
        }

}

spawnTags( attacker )
{

		self.pers["tag"] = true;
		wait(1.0);
        // Place spawnpoint on the ground based on player box size
        basePosition = playerPhysicsTrace( self.origin, self.origin + ( 0, 0, -99999 ) );

        // Create pickup trigger
        trigger = spawn( "trigger_radius", basePosition, 0, 20, 50 );
        trigger endon( "picked_up" );
        trigger endon( "timed_out" );
        trigger.owner = attacker; // Attacker retrieval points
        trigger.team = attacker.pers["team"];

        // Friendly tags
	friendlyTag = spawn( "script_model", basePosition + ( 0, 0, 20 ) );
        friendlyTag endon( "picked_up" );
        friendlyTag endon( "timed_out" );
	friendlyTag setModel( "cross_ddogtag" );
	friendlyTag.team = self.pers["team"];
        friendlyTag.owner = self;

	// Enemy tags
	enemyTag = spawn( "script_model", basePosition + ( 0, 0, 20 ) );
        enemyTag endon( "picked_up" );
        enemyTag endon( "timed_out" );
	enemyTag setModel( "skull_ddogtag" );
	if (attacker.pers["team"] != self.pers["team"]) {
		enemyTag.team = attacker.pers["team"];
	} else {
		if (self.pers["team"] == "axis") {
			enemyTag.team = "allies";
		} else {
			enemyTag.team = "axis";
		}
	}
        enemyTag.owner = self;

        //Delete on disconnect
        self thread onJoinedDisconnect( enemyTag, friendlyTag, trigger );

        //Rotate
        friendlyTag thread rotate();
        enemyTag thread rotate();

        // Show tags to proper teams
        friendlyTag thread showTagToTeam();
        enemyTag thread showTagToTeam();

        // Show friendly tag locations on minimap ( only 9 Tag Obj Ids will show at once )
        if( level.scr_sr_show_dogtags_minimap > 0 && level.dogtagObjIds < 9 ) { // 9 tags + 2defend + 2attack + 1bomb + 1 Hardpoint( possible) = 15 max allowed Ids
                friendlyTag thread showOnMinimap( basePosition );
        }

        // Wait for another player to pickup the dogtags
        trigger thread removeTriggerOnPickup( friendlyTag, enemyTag, trigger );

        // Remove the trigger and dogtags if the dog tag expire
        if( level.scr_sr_dogtag_autoremoval_time > 0 ) {
                trigger thread removeTriggerOnTimeout( friendlyTag, enemyTag, trigger, attacker );
        }

}

rotate()

{
	self endon( "picked_up" );
	self endon( "timed_out" );


	while( true )

	{

           self movez( 20, 1.5, 0.3, 0.3 );

	   self rotateyaw( 360, 1.5, 0, 0 );

	   wait( 1.5 );

	   self movez( -20, 1.5, 0.3, 0.3 );

	   self rotateyaw( 360 ,1.5, 0, 0 );

	   wait( 1.5 );

	}

}

onJoinedDisconnect( enemyTag, friendlyTag, trigger )
{

        self endon( "spawned_player" );
        self endon( "game_ended" );

        self waittill_any( "disconnect", "joined_team", "joined_spectators" );

        // Notify to stop other threads
        trigger notify( "picked_up" );
        friendlyTag notify( "picked_up" );
        enemyTag notify( "picked_up" );

	trigger notify( "timed_out" );
	friendlyTag notify( "timed_out" );
	enemyTag notify( "timed_out" );

        // Delete Trigger and Model
        if( isDefined( trigger ) ) {
                trigger delete();
        }

	if( isDefined( friendlyTag ) ) {
                friendlyTag delete();
        }

        if( isDefined( enemyTag ) ) {
                enemyTag delete ();
        }


}

removeTriggerOnPickup( friendlyTag, enemyTag, trigger )
{

	trigger endon( "timed_out" );
	friendlyTag endon( "timed_out" );
	enemyTag endon( "timed_out" );


	trigger waittill( "trigger", player );

	// If by some chance a dead player activates the trigger, the dogtag will simply be deleted!
	if ( isAlive( player ) ) {

		// Cannot pick up dogtag if in spawn protection.......may be Invisible
		if( isDefined( player.spawn_protected ) && player.spawn_protected == true ) {
			player thread removeTriggerOnPickup( friendlyTag, enemyTag, trigger );
			return;
		}

		// Friendly team picks up Dogtag
		if( player.pers["team"] == friendlyTag.team ) {
			if (!isDefined(friendlyTag.reviveCounter) || friendlyTag.reviveCounter < level.scr_sr_revive_time) {
				player.hud_cross_icon.alpha = 1;
				if (!isDefined(friendlyTag.reviveCounter)) {
					friendlyTag.reviveCounter = 0;
				}
				ClientPrint(player, "Reviving : " + friendlyTag.reviveCounter + " / " + level.scr_sr_revive_time);
				friendlyTag.reviveCounter += 1;
				player playLocalSound( "scramble" );
				wait (0.5);
				player.hud_cross_icon.alpha = 0;
				player thread removeTriggerOnPickup( friendlyTag, enemyTag, trigger );
				return;
			}
			player.hud_cross_icon.alpha = 0;

			if ( level.scr_sr_denied_player_sound == 1 )
			player playLocalSound( "denied_sr" );

			//Play sound to other team
			if ( level.scr_sr_denied_team_sound == 1 && friendlyTag.team == "allies" )
			playSoundOnPlayers( "denied_sr", "axis" );

			if ( level.scr_sr_denied_team_sound == 1  && friendlyTag.team == "axis" )
			playSoundOnPlayers( "denied_sr", "allies" );

			// Give player a score
			player thread givePlayerScore( "take", level.scr_sr_team_dogtag_score );

			// Show assist point for saving friendly
			player maps\mp\gametypes\_globallogic::incPersStat( "assists", 1 );
			player.assists = player maps\mp\gametypes\_globallogic::getPersStat( "assists" );

			// Send notice to players according to team
			if ( level.scr_sr_dogtag_obits == 1 && player.pers["team"] == "allies" )
			broadcastInfo("revive", player, friendlyTag.owner);
			//iprintln("^3" + player.name + "^7.... Revived^3 " + friendlyTag.owner.name );

			if ( level.scr_sr_dogtag_obits == 1 && player.pers["team"] == "axis" )
			broadcastInfo("revive", player, friendlyTag.owner);
			//iprintln("^1" + player.name + "^7.... Revived^1 " + friendlyTag.owner.name );

			//Update stat
			player.pers["stats"]["misc"]["medic"] += 1;
			player setClientDvar( "ps_medic", player.pers["stats"]["misc"]["medic"] );


			//Respawn tag owner
			friendlyTag.owner clearLowerMessage();
			friendlyTag.owner.toBeRespawned = true;
			friendlyTag.owner.toBeRespawnedOrigin = player.origin;
			trigger thread revivePlayer(friendlyTag.owner);

			// Send owner notification
			notifyData = spawnStruct();
			notifyData.titleText = "REVIVED";
			notifyData.notifyText ="by " + player.name;
			notifyData.iconName = "cross_hud";
			notifyData.sound = sayTeamVoice( friendlyTag.owner, "1mc_revived" );

			if( friendlyTag.team == "allies" ) {
				notifyData.glowColor = ( 1, 0.7, 0 ); // Yellow

			} else {
				notifyData.glowColor = ( 1, 0, 0 ); // Red

			}

			notifyData.duration = 4.0;

			friendlyTag.owner thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );

			player logString( player.pers["team"] + " " + "kill denied" );
			lpselfnum = player getEntityNumber();
			lpGuid = player getGuid();
			logPrint("SRKD;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");

			trigger playSound( "dogtag_sr_pickup" );

			// Notify trigger and model picked up
			trigger notify( "picked_up" );
			friendlyTag notify( "picked_up" );
			enemyTag notify( "picked_up" );

			// Delete Trigger and Model
			trigger delete();
			friendlyTag delete();
			enemyTag delete ();

		}

		// Enemy team picks up DogTag
		if ( player.pers["team"] == enemyTag.team ) {

			if( isDefined( player ) && isAlive( player ) ) {
				sayTeamVoice( player, "1mc_confirmedkill", true );
			}

			// Give player a score
			player thread givePlayerScore( "take", level.scr_sr_enemy_dogtag_score );

			//Update stat
			player.pers["stats"]["misc"]["hitman"] += 1;
			player setClientDvar( "ps_hitman", player.pers["stats"]["misc"]["hitman"] );

			// Send notice to players according to team
			if ( level.scr_sr_dogtag_obits == 1 && player.pers["team"] == "allies" )
			broadcastInfo("eliminate", player, enemyTag.owner);
			//      iprintln("^1" + enemyTag.owner.name + " ^7.... has been ELIMINATED!");

			if ( level.scr_sr_dogtag_obits == 1 && player.pers["team"] == "axis" )
			broadcastInfo("eliminate", player, enemyTag.owner);
			//iprintln("^3" + enemyTag.owner.name + " ^7.... has been ELIMINATED!");

			// Send owner notification
			notifyData = spawnStruct();
			notifyData.titleText = "ENEMY CONFIRMED KILL";
			notifyData.notifyText ="by " + player.name;
			notifyData.iconName = "skull_hud";
			notifyData.sound = sayTeamVoice( enemyTag.owner, "1mc_mission_fail" );


			if( enemyTag.team == "axis" ) {
				notifyData.glowColor = ( 1, 0.7, 0 ); // Yellow
			} else {
				notifyData.glowColor = ( 1, 0, 0 ); // Red
			}

			notifyData.duration = 4.0;

			enemyTag.owner thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );

			player logString( player.pers["team"] + " " + "kill confirmed" );
			lpselfnum = player getEntityNumber();
			lpGuid = player getGuid();
			logPrint("SRKC;" + lpGuid + ";" + lpselfnum + ";" + player.name + "\n");

			// Points for retrieving dogtags from the enemy the attacker killed
			if( trigger.owner == player ) {
				// Give player a score
				player thread givePlayerScore( "take", level.scr_sr_dogtag_attacker_owner_score - level.scr_sr_enemy_dogtag_score );
			}

			enemyTag.owner.pers["tag"] = false;
			trigger playSound( "dogtag_sr_pickup" );

			// Notify trigger and model picked up
			trigger notify( "picked_up" );
			friendlyTag notify( "picked_up" );
			enemyTag notify( "picked_up" );

			// Delete Trigger and Model
			trigger delete();
			friendlyTag delete();
			enemyTag delete ();
		}
	} else {
		player thread removeTriggerOnPickup( friendlyTag, enemyTag, trigger );
		return;
	}


}

revivePlayer(player) {

	wait(1.0);
	if (!level.gameEnded) {
		player.pers["tag"] = false;
		player.revivedOnce = true;
		player thread [[level.spawnPlayer]]();		
	}

}

removeTriggerOnTimeout( friendlyTag, enemyTag, trigger, attacker )
{

	trigger endon( "picked_up" );
	friendlyTag endon( "picked_up" );
	enemyTag endon( "picked_up" );

	// Wait for this tag to timeout
	wait( level.scr_sr_dogtag_autoremoval_time );

        // Play fx for Tag model explode
        if( level.scr_sr_dogtags_explode_fx == 1 ) {

                team = trigger.team;

                // Red FX
                enemyTag.fx = spawnFx( game[level.gameType]["skull_fx"], enemyTag.origin );
                wait( 0.05 );
                triggerFx( enemyTag.fx );
                enemyTag.fx thread showFxToTeam( team );

                // White FX
                friendlyTag.fx = spawnFx( game[level.gameType]["cross_fx"], friendlyTag.origin );
                wait( 0.05 );
                triggerFx( friendlyTag.fx );
                friendlyTag.fx thread showFxToTeam( level.otherTeam[ team ] );


        }

        // Second chance to spawn on expired Tags
        if( level.scr_sr_random_second_chance > 0 ) {
                if( percentChance( level.scr_sr_random_second_chance ) ) {

                        if( !level.gameEnded ) {

                                // Send owner notification
	                        notifyData = spawnStruct();
	                        notifyData.titleText = "SECOND CHANCE";
	                        notifyData.notifyText ="Keep on Fighting!";
	                        notifyData.iconName = "cross_hud";
                                notifyData.sound = sayTeamVoice( enemyTag.owner, "1mc_goodtogo" );


	                        if( enemyTag.team == "axis" ) {
                                        notifyData.glowColor = ( 1, 0.7, 0 ); // Yellow

                                } else {
                                        notifyData.glowColor = ( 1, 0, 0 ); // Red

                                }

	                        notifyData.duration = 4.0;

                                enemyTag.owner thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );

                                // Send notice to players according to team
                                if ( level.scr_sr_dogtag_obits == 1 && attacker.pers["team"] == "allies" )
                                        iprintln("^1" + enemyTag.owner.name + " ^7.... got a Second Chance!");

                                if ( level.scr_sr_dogtag_obits == 1 && attacker.pers["team"] == "axis" )
                                        iprintln("^3" + enemyTag.owner.name + " ^7.... got a Second Chance!");

                                //Respawn tag owner
                                enemyTag.owner clearLowerMessage();
                                enemyTag.owner thread [[level.spawnPlayer]]();

                        }


                }  else {

                        if( !level.gameEnded ) {

                                // Send owner notification
	                        notifyData = spawnStruct();
	                        notifyData.titleText = "TIME EXPIRED";
	                        notifyData.notifyText ="Killed by " + attacker.name;
	                        notifyData.iconName = "skull_hud";
                                notifyData.sound = sayTeamVoice( enemyTag.owner, "1mc_control_lost" );

	                        if( enemyTag.team == "axis" ) {
                                        notifyData.glowColor = ( 1, 0.7, 0 ); // Yellow
                                } else {
                                        notifyData.glowColor = ( 1, 0, 0 ); // Red
                                }

	                        notifyData.duration = 4.0;

                                enemyTag.owner thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );

                                // Send notice to players according to team
                                if ( level.scr_sr_dogtag_obits == 1 && attacker.pers["team"] == "allies" )
                                        iprintln("^1" + enemyTag.owner.name + " ^7.... has been ELIMINATED!");

                                if ( level.scr_sr_dogtag_obits == 1 && attacker.pers["team"] == "axis" )
                                        iprintln("^3" + enemyTag.owner.name + " ^7.... has been ELIMINATED!");

                        }

                }

        } else {

                if( !level.gameEnded ) {

                        // Send owner notification
	                notifyData = spawnStruct();
	                notifyData.titleText = "TIME EXPIRED";
	                notifyData.notifyText ="Killed by " + attacker.name;
	                notifyData.iconName = "skull_hud";
                        notifyData.sound = sayTeamVoice( enemyTag.owner, "1mc_control_lost" );

	                if( enemyTag.team == "axis" ) {
                                 notifyData.glowColor = ( 1, 0.7, 0 ); // Yellow
                        } else {
                                 notifyData.glowColor = ( 1, 0, 0 ); // Red
                        }

	                notifyData.duration = 4.0;

                        enemyTag.owner thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );

                        // Send notice to players according to team
                        if ( level.scr_sr_dogtag_obits == 1 && attacker.pers["team"] == "allies" )
                                iprintln("^1" + enemyTag.owner.name + " ^7.... has been ELIMINATED!");

                        if ( level.scr_sr_dogtag_obits == 1 && attacker.pers["team"] == "axis" )
                                iprintln("^3" + enemyTag.owner.name + " ^7.... has been ELIMINATED!");
                }

        }

	// Notify trigger and model timed out
	trigger notify( "timed_out" );
	friendlyTag notify( "timed_out" );
	enemyTag notify( "timed_out" );

        // Delete Trigger and Model
	trigger delete();
	friendlyTag delete();
	enemyTag delete();

}

showTagToTeam()
{

        while( isDefined( self ) ) // use while() in case player changes team!
        {
               self hide();

               for( i = 0 ; i < level.players.size ; i ++ )
               {
                       player = level.players[i];

                       if ( player.pers["team"] == self.team )
                               self showToPlayer( player );

               }

               wait( 0.05 );

        }

}

showFxToTeam( team )
{

        if( isDefined( self ) )
        {
               self hide();

               for( i = 0 ; i < level.players.size ; i ++ )
               {
                       player = level.players[i];

                       if ( player.pers["team"] == team )
                               self showToPlayer( player );

               }

        }

}

givePlayerScore( event, score )
{
	self maps\mp\gametypes\_rank::giveRankXP( event, score );

	self.pers["score"] += score;
	self maps\mp\gametypes\_persistence::statAdd( "score", ( self.pers["score"] - score ) );
	self.score = self.pers["score"];
	self notify ( "update_playerscore_hud" );
}

showOnMinimap( position )
{
	// Get the next objective ID to use
	objCompass = maps\mp\gametypes\_gameobjects::getNextObjID();
	if ( objCompass != -1 ) {
		objective_add( objCompass, "active", position + ( 0, 0, 25 ) );
		objective_icon( objCompass, "cross_hud" );
                objective_team( objCompass, self.team );

                level.dogtagObjIds++;

	}

	self waittill( "death" );

	// Delete the objective
	if ( objCompass != -1 ) {
		objective_delete( objCompass );
		maps\mp\gametypes\_gameobjects::resetObjID( objCompass );

                level.dogtagObjIds--;
	}

}
