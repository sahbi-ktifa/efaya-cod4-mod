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
#include maps\mp\gametypes\_hud_util;
#include openwarfare\_utils;

// Rallypoints should be destroyed on leaving your team/getting killed
// Compass icons need to be looked at
// Doesn't seem to be setting angle on spawn so that you are facing your rallypoint

/*
	Competitive Search and Destroy
	Attackers objective: Bomb one of 2 positions
	Defenders objective: Defend these 2 positions / Defuse planted bombs
	Round ends:	When one team is eliminated, bomb explodes, bomb is defused, or roundlength time is reached
	Map ends:	When one team reaches the score limit, or time limit or round limit is reached
	Respawning:	Players remain dead for the round and will respawn at the beginning of the next round

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

	level.scr_csd_sdmode = getdvarx( "scr_csd_sdmode", "int", 0, 0, 1  );
	level.scr_csd_scoreboard_bomb_carrier = getdvarx( "scr_csd_scoreboard_bomb_carrier", "int", 0, 0, 1 );
	level.scr_csd_bomb_notification_enable = getdvarx( "scr_csd_bomb_notification_enable", "int", 1, 0, 1 );
	level.scr_csd_planting_sound = getdvarx( "scr_csd_planting_sound", "int", 1, 0, 1 );
	level.scr_csd_defusing_sound = getdvarx( "scr_csd_defusing_sound", "int", 1, 0, 1 );
	level.scr_csd_show_briefcase = getdvarx( "scr_csd_show_briefcase", "int", 1, 0, 1 );
	level.scr_csd_bombsites_enabled = getdvarx( "scr_csd_bombsites_enabled", "int", 0, 0, 4 );
	level.scr_csd_bombtimer_show = getdvarx( "scr_csd_bombtimer_show", "int", 1, 0, 1 );
	level.scr_csd_defenders_show_both = getdvarx( "scr_csd_defenders_show_both", "int", 0, 0, 1 );
	level.scr_csd_allow_defender_explosivepickup = getdvarx( "scr_csd_allow_defender_explosivepickup", "int", 0, 0, 1 );  
	
	level.scr_csd_minimum_wage = getdvard( "scr_csd_minimum_wage", "int", 200 );
	level.scr_csd_enemy_killed_reward = getdvard( "scr_csd_enemy_killed_reward", "int", 250 );
	level.scr_csd_winning_round_reward = getdvard( "scr_csd_winning_round_reward", "int", 500 );
	level.scr_csd_loosing_round_reward = getdvard( "scr_csd_loosing_round_reward", "int", 150 );
	level.scr_csd_planting_reward = getdvard( "scr_csd_planting_reward", "int", 200 );
	level.scr_csd_defusing_reward = getdvard( "scr_csd_defusing_reward", "int", 400 );
	
	level.assault_allies_weapons = [];
	level.assault_axis_weapons = [];
	level.pistol_allies_weapons = [];
	level.pistol_axis_weapons = [];
	level.sniper_allies_weapons = [];
	level.sniper_axis_weapons = [];
	level.smg_shotgun_allies_weapons = [];
	level.smg_shotgun_axis_weapons = [];
	level.grenade_weapons = [];
	loadDefaultArray(level.assault_allies_weapons, "scr_csd_assault_allies_weapons", "m16_silencer_mp:M16:weapon_m16:650;m14_reflex_mp:Famas:weapon_m14:750;m4_reflex_mp:Remington R5:weapon_m4carbine:800");
	loadDefaultArray(level.assault_axis_weapons, "scr_csd_assault_axis_weapons", "ak47_silencer_mp:AK-47:weapon_ak47:550;g36c_reflex_mp:Commando:weapon_g36c:800;g3_reflex_mp:Honey Badger:weapon_g3:720");
	loadDefaultArray(level.pistol_allies_weapons, "scr_csd_pistol_allies_weapons", "usp_mp:RE45:weapon_usp_45:250;colt45_silencer_mp:RK5 Silencer:weapon_colt_45:310;deserteaglegold_mp:Desert Eagle:weapon_desert_eagle_gold:390");
	loadDefaultArray(level.pistol_axis_weapons, "scr_csd_pistol_axis_weapons", "usp_mp:RE45:weapon_usp_45:250;colt45_silencer_mp:RK5 Silencer:weapon_colt_45:310;deserteagle_mp:.44 Magnum:weapon_desert_eagle:390");
	loadDefaultArray(level.sniper_allies_weapons, "scr_csd_sniper_allies_weapons", "m40a3_mp:L96:weapon_m40a3:950;barrett_mp:Barrett:weapon_barrett50cal:1200;rpd_mp:M1 Garand:weapon_rpd:570;saw_mp:Mosin Nagant:weapon_m249saw:650");
	loadDefaultArray(level.sniper_axis_weapons, "scr_csd_sniper_axis_weapons", "remington700_mp:Ballista:weapon_remington700:950;m21_mp:M21:weapon_m14_scoped:1170;rpd_mp:M1 Garand:weapon_rpd:570;m60e4_mp:Kark98:weapon_m60e4:700");
	loadDefaultArray(level.smg_shotgun_allies_weapons, "scr_csd_smg_shotgun_allies_weapons", "mp5_silencer_mp:MP5 Silencer:weapon_mp5:630;p90_reflex_mp:P90:weapon_p90:720;m1014_mp:Brecci:weapon_benelli_m4:430");
	loadDefaultArray(level.smg_shotgun_axis_weapons, "scr_csd_smg_shotgun_axis_weapons", "uzi_mp:Uzi:weapon_mini_uzi:500;ak74u_reflex_mp:AK-74u:weapon_aks74u:630;winchester1200_mp:M133:weapon_winchester1200:350");
	loadDefaultArray(level.grenade_weapons, "scr_csd_grenade_weapons", "frag_grenade_mp:Frag grenade:weapon_fraggrenade:250;flash_grenade_mp:Flash grenade:weapon_flashbang:200;smoke_grenade_mp:Smoke grenade:weapon_smokegrenade:150;concussion_grenade_mp:Stun grenade:weapon_concgrenade:150");

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
	level.getTeamKillPenalty = ::sd_getTeamKillPenalty;
	level.getTeamKillScore = ::sd_getTeamKillScore;				
	level.onLoadoutGiven = ::onLoadoutGiven;
	level.onPlayerConnect = ::onPlayerConnect;

	level.endGameOnScoreLimit = false;

	//game["dialog"]["gametype"] = gameTypeDialog( "csgo" );
	game["dialog"]["offense_obj"] = "obj_destroy";
	game["dialog"]["defense_obj"] = "obj_defend";
	
	game["buy"] = "ok";
}

loadDefaultArray(array, key, _default) {
	tmp_value = getdvard( key, "string", _default );
	tmp_values = strtok(tmp_value, ";");
	for (i = 0; i < tmp_values.size; i++) {
		array[i] = strtok(tmp_values[i], ":");
	}
}

onPrecacheGameType()
{
	game["bombmodelname"] = "mil_tntbomb_mp";
	game["bombmodelnameobj"] = "mil_tntbomb_mp";
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";
	precacheModel(game["bombmodelname"]);
	precacheModel(game["bombmodelnameobj"]);

	game["menu_buyloadout"] = "buyloadout";
	precacheMenu(game["menu_buyloadout"]);
	
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
	game["startWeapon"] = "beretta_mp";
	precacheShader( "weapon_m9beretta" );
	
	thread onPlayerConnect();
}

onPlayerConnect() {
	while(true)
	{
		self waittill("connected", player);
				
		game[player.name] = [];
		game[player.name]["money"] = level.scr_csd_minimum_wage;	
		game[player.name]["menu_step"] = "base";	

		player thread onMenuResponse();		
	}	
	
}

resetClientVariables(step)
{
	// Reset all the variables used in the menu 
	self setClientDvars(
		"ui_buyloadout_step", game[self.name]["menu_step"]
	);
	switch ( step ) {
		case "base":
			self setClientDvars(
				"ui_item1_name", "1. Assault weapons",
				"ui_item2_name", "2. SMG / Shotguns weapons",
				"ui_item3_name", "3. Sniper weapons",
				"ui_item4_name", "4. Pistols",
				"ui_item5_name", "5. Grenades"
			);		
			break;
		case "assault":
			if (self.pers["team"] == "axis") {
				self setClientDvars(
					"ui_item1_name", "1. Assault weapons",
					"ui_item1_image", "1. Assault weapons",
					"ui_item1_cost", "1. Assault weapons"
				);		
			} else {
				self setClientDvars(
					"ui_item1_name", "1. Assault weapons",
					"ui_item1_image", "1. Assault weapons",
					"ui_item1_cost", "1. Assault weapons"
				);		
			}
			break;
	}
}

onMenuResponse()
{
	self endon("disconnect");
	
	for(;;)
	{
		self waittill("menuresponse", menu, response);
		
		println( self getEntityNumber() + " menuresponse: " + menu + " " + response );
					
		if (isDefined(game["menu_buyloadout"]) && response == game["menu_buyloadout"]) {
			if (game["buy"] == "NOK") {
				ClientPrint(self, "Buying time is over (25s)");
			} else {
				self closeMenu();
				self closeInGameMenu();
				self resetClientVariables("base");
				self openMenu(game["menu_buyloadout"]);			
			}
		}
		
		if( response == "endgame" )
		{
			continue;
		}
		
		if( menu == game["menu_buyloadout"] )
		{
			//self closeMenu();
			//self closeInGameMenu();
			
			ClientPrint(self, response);
			if (game[self.name]["menu_step"] == "base") {
				if (response == "1") {
					game[self.name]["menu_step"] = "assault";
				} else if (response == "2") {
					game[self.name]["menu_step"] = "smg";
				} else if (response == "3") {
					game[self.name]["menu_step"] = "sniper";
				} else if (response == "4") {
					game[self.name]["menu_step"] = "pistol";
				} else if (response == "5") {
					game[self.name]["menu_step"] = "grenade";
				}
			} else if (response == "6") { //Back to the menu
				game[self.name]["menu_step"] = "base";			
			} else { //I'm gonna buy something...
				ClientPrint(self, response);	
			}
			
			self resetClientVariables(game[self.name]["menu_step"]);		
		}
	}
}

sd_getTeamKillPenalty( eInflictor, attacker, sMeansOfDeath, sWeapon )
{
	teamkill_penalty = maps\mp\gametypes\_globallogic::default_getTeamKillPenalty( eInflictor, attacker, sMeansOfDeath, sWeapon );

	if ( ( isdefined( self.isDefusing ) && self.isDefusing ) || ( isdefined( self.isPlanting ) && self.isPlanting ) )
	{
		teamkill_penalty = teamkill_penalty * level.teamKillPenaltyMultiplier;
	}
	
	return teamkill_penalty;
}

sd_getTeamKillScore( eInflictor, attacker, sMeansOfDeath, sWeapon )
{
	teamkill_score = maps\mp\gametypes\_rank::getScoreInfoValue( "kill" );
	
	if ( ( isdefined( self.isDefusing ) && self.isDefusing ) || ( isdefined( self.isPlanting ) && self.isPlanting ) )
	{
		teamkill_score = teamkill_score * level.teamKillScoreMultiplier;
	}
	
	return int(teamkill_score);
}

buyAxisAssault(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	cost = 0;
	weapon = "";
	switch(response)
	{
		case "1":
			weapon = "m16_reflex_mp";
			cost = 850;
			break;

		case "2":
			weapon = "ak47_reflex_mp";
			cost = 750;
			break;
		case "3":
			weapon = "g36c_reflex_mp";
			cost = 800;
			break;
		case "4":
			weapon = "mp44_mp";
			cost = 600;
			break;
	}
	self buyWeaponAction(weapon, cost);
}

buyAlliesAssault(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	cost = 0;
	weapon = "";
	switch(response)
	{
		case "1":
			weapon = "m4_reflex_mp";
			cost = 850;
			break;

		case "2":
			weapon = "g3_reflex_mp";
			cost = 700;
			break;
		case "3":
			weapon = "commando_reflex_mp";
			cost = 1000;
			break;
		case "4":
			weapon = "m14_reflex_mp";
			cost = 700;
			break;
	}
	self buyWeaponAction(weapon, cost);
}

buyAxisSmg(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	cost = 0;
	weapon = "";
	switch(response)
	{
		case "1":
			weapon = "ak74u_mp";
			cost = 500;
			break;

		case "2":
			weapon = "uzi_mp";
			cost = 450;
			break;
		case "3":
			weapon = "skorpion_mp";
			cost = 400;
			break;	
		case "4":
			weapon = "winchester1200_mp";
			cost = 350;
			break;			
	}
	self buyWeaponAction(weapon, cost);
}

buyAlliesSmg(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	cost = 0;
	weapon = "";
	switch(response)
	{
		case "1":
			weapon = "mp5_mp";
			cost = 450;
			break;

		case "2":
			weapon = "p90_mp";
			cost = 550;
			break;	
		case "3":
			weapon = "m1014_mp";
			cost = 300;
			break;			
	}
	self buyWeaponAction(weapon, cost);
}

buyAxisSniper(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	cost = 0;
	weapon = "";
	switch(response)
	{
		case "1":
			weapon = "m21_mp";
			cost = 400;
			break;

		case "2":
			weapon = "dragunov_mp";
			cost = 450;
			break;	
		case "3":
			weapon = "kark98_mp";
			cost = 250;
			break;			
	}
	self buyWeaponAction(weapon, cost);
}

buyAlliesSniper(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	cost = 0;
	weapon = "";
	switch(response)
	{
		case "1":
			weapon = "barrett_mp";
			cost = 400;
			break;

		case "2":
			weapon = "remington700_mp";
			cost = 450;
			break;	
		case "3":
			weapon = "mosin_mp";
			cost = 250;
			break;			
	}
	
	self buyWeaponAction(weapon, cost);
}

buyWeaponAction(weapon, cost) {
	if (game[self.name]["money"] < cost) {
		ClientPrint(self, "Not enough money to purchase this weapon");
	} else {
		if (game[self.name]["weapon"] != game["startWeapon"]) {
			ClientPrint(self, "Dropping : " + game[self.name]["weapon"]);
			currentWeapon = self getCurrentWeapon();
			self dropItem( currentWeapon );
		}
		ClientPrint(self, "Buying : " + weapon);
		self giveWeapon( weapon );
		self giveMaxAmmo( weapon );
		self setSpawnWeapon( weapon );
		self switchToWeapon( weapon );
		game[self.name]["weapon"] = weapon;
		game[self.name]["money"] -= cost;
		self thread displayBuying(cost);
		self playLocalSound( "cash" );
	}
}

buyNadePistol(response)
{
	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	cost = 0;
	weapon = "";
	nade = false;
	switch(response)
	{
		case "1":
			weapon = "colt45_mp";
			cost = 150;
			break;

		case "2":
			weapon = "usp_silencer_mp";
			cost = 250;
			break;	
		case "3":
			weapon = "deserteagle_mp";
			cost = 300;
			break;
		case "4":
			weapon = "frag_grenade_mp";
			cost = 200;
			nade = true;
			break;			
		case "5":
			weapon = "flash_grenade_mp";
			cost = 100;
			nade = true;
			break;			
		case "6":
			weapon = "smoke_grenade_mp";
			cost = 150;
			nade = true;
			break;			
		case "7":
			weapon = "concussion_grenade_mp";
			cost = 100;
			nade = true;
			break;			
	}

	if (game[self.name]["money"] < cost) {
		ClientPrint(self, "Not enough money to purchase this weapon");
	} else {
		ClientPrint(self, "Buying : " + weapon);
		self giveWeapon( weapon );
		self giveMaxAmmo( weapon );
		if (nade) {
			self SwitchToOffhand( weapon );
		} else {
			self switchToWeapon( weapon );
		}
		game[self.name]["money"] -= cost;
		self thread displayBuying(cost);
		self playLocalSound( "cash" );
	}
}

displayBuying(price) {

	moneyBuy = self createFontString( "objective", 1.8 );
	moneyBuy.archived = true;
	moneyBuy.hideWhenInMenu = true;
	moneyBuy setPoint( "CENTER", "CENTER", 250, -150 );
	moneyBuy.alignX = "left";
	moneyBuy.sort = -1;
	moneyBuy.alpha = 0.75;
	moneyBuy.color = ( 0.8, 0.8, 0 );
	moneyBuy setText("-" + price + " $");
	
	wait 2;
	moneyBuy destroy();	
}

displayGaining(price) {

	moneyGain = self createFontString( "objective", 1.8 );
	moneyGain.archived = true;
	moneyGain.hideWhenInMenu = true;
	moneyGain setPoint( "CENTER", "CENTER", 250, -150 );
	moneyGain.alignX = "left";
	moneyGain.sort = -1;
	moneyGain.alpha = 0.75;
	moneyGain.color = ( 0.8, 0.8, 0 );
	moneyGain setText("+" + price + " $");
	
	wait 2;
	moneyGain destroy();	
}

onLoadoutGiven()
{
	// Give player CSGO loadouts
	self giveCSGOLevelLoadout();
}

giveCSGOLevelLoadout()
{

	// Remove all weapons and perks from the player
	self thread maps\mp\gametypes\_gameobjects::_disableWeapon();
	self takeAllWeapons();
	self clearPerks();	
	
	// Make sure the player gets any hardpoint that he/she already had
	if ( isDefined( self.pers["hardPointItem"] ) ) {
		self maps\mp\gametypes\_hardpoints::giveHardpointItem( self.pers["hardPointItem"] );
	}
	
	self.specialty = [];
	self.specialty[0] = "specialty_null";
	//self setPerk( self.specialty[0] );
	self.specialty[1] = "specialty_bulletdamage";
	self setPerk( self.specialty[1] );
	self.specialty[2] = "specialty_bulletpenetration";
	self setPerk( self.specialty[2] );
	
	self giveWeapon( game["startWeapon"] );
	self giveMaxAmmo( game["startWeapon"] );
	self setSpawnWeapon( game["startWeapon"] );
	self switchToWeapon( game["startWeapon"] );
	if (isDefined(game[self.name]["weapon"])) {
		self giveWeapon( game[self.name]["weapon"] );
		self giveMaxAmmo( game[self.name]["weapon"] );
		self setSpawnWeapon( game[self.name]["weapon"] );
		self switchToWeapon( game[self.name]["weapon"] );
	} 	
	
	// Enable the new weapon
	self thread maps\mp\gametypes\_gameobjects::_enableWeapon();
}

updateBuyTime() {
	count = 0;
	while (1) {
		count++;
		wait 1;		
		
		if (count > 25) {
			game["buy"] = "NOK";
			break;
		}
	}
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
	thread updateBuyTime();
}


onSpawnPlayer()
{
	self.isPlanting = false;
	self.isDefusing = false;
	self.isBombCarrier = false;

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
	self thread showMoney(self.name);
	self giveCSGOLevelLoadout();
	level notify ( "spawned_player" );
}

showMoney(name)
{
	self endon("disconnect");	
	
	// Create the money left
	moneyLeft = self createFontString( "objective", 1.8 );
	moneyLeft.archived = true;
	moneyLeft.hideWhenInMenu = true;
	moneyLeft setPoint( "CENTER", "CENTER", 250, -200 );
	moneyLeft.alignX = "left";
	moneyLeft.sort = -1;
	moneyLeft.alpha = 0.75;
	moneyLeft.color = ( 1, 1, 0 );
	moneyLeft setText("0 $");	
	
	oldMoney = 0;
	// Update the level and kills info until the player dies
	while ( isDefined( self ) && isAlive( self ) ) {
		wait (0.05);
		
		// Check if money has changed
		if ( IsDefined(game[name]) && game[name]["money"] != oldMoney ) {
			moneyLeft setText( game[name]["money"] + " $");
			oldMoney = game[name]["money"];
		}		
	}
	
	// Destroy the HUD elements
	moneyLeft destroy();	

}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if ( isPlayer( attacker ) ) {
		game[attacker.name]["money"] += level.scr_csd_enemy_killed_reward;
		attacker thread displayGaining(level.scr_csd_enemy_killed_reward);
	}
	game[self.name]["weapon"] = undefined;
	thread checkAllowSpectating();
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


sd_endGame( winningTeam, endReasonText )
{
	if ( isdefined( winningTeam ) )
		[[level._setTeamScore]]( winningTeam, [[level._getTeamScore]]( winningTeam ) + 1 );

	for ( index = 0; index < level.players.size; index++ )
	{
		if ( level.players[index].pers["team"] ==  winningTeam) {
			game[level.players[index].name]["money"] += level.scr_csd_winning_round_reward;
			level.players[index] thread displayGaining(level.scr_csd_winning_round_reward);
			level.players[index] playLocalSound( "cash" );
		} else {
			game[level.players[index].name]["money"] += level.scr_csd_loosing_round_reward;
			level.players[index] thread displayGaining(level.scr_csd_loosing_round_reward);
			level.players[index] playLocalSound( "cash" );
		}
	}
	
	thread maps\mp\gametypes\_globallogic::endGame( winningTeam, endReasonText );
}


onDeadEvent( team )
{
	if ( level.bombExploded || level.bombDefused )
		return;

	if ( team == "all" )
	{
		if ( level.bombPlanted )
			sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
		else
			sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["attackers"] )
	{
		if ( level.bombPlanted )
			return;

		sd_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
	}
	else if ( team == game["defenders"] )
	{
		sd_endGame( game["attackers"], game["strings"][game["defenders"]+"_eliminated"] );
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
		sd_endGame( game["defenders"], game["strings"]["time_limit_reached"] );
	else
		sd_endGame( undefined, game["strings"]["time_limit_reached"] );
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
	level.plantTime = getdvarx( "scr_csd_planttime", "float", 5, 0, 20 );
	level.defuseTime = getdvarx( "scr_csd_defusetime", "float", 8, 0, 20 );
	level.bombTimer = getdvarx( "scr_csd_bombtimer", "float", 60, 1, 300 );
	level.multiBomb = getdvarx( "scr_csd_multibomb", "int", 0, 0, 1 );
	
	// Calculate the bomb timer with the random modifier
	maxModifier = level.bombTimer - 5;
	if ( maxModifier < 0 ) {
		maxModifier = 0;
	}
	level.scr_csd_bombtimer_modifier = getdvarx( "scr_csd_bombtimer_modifier", "int", 0, 0, maxModifier );
	level.bombTimer = randomFloatRange( level.bombTimer - level.scr_csd_bombtimer_modifier, level.bombTimer + level.scr_csd_bombtimer_modifier + 1 );	
	
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
		 if ( level.scr_csd_allow_defender_explosivepickup )
 	      level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "any" );
 	   	else
				level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "friendly" );
		level.sdBomb maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "compass_waypoint_bomb" );
		level.sdBomb maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
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
		if( level.scr_csd_show_briefcase == 1 )
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
	if ( level.scr_csd_bombsites_enabled == 1 && level.bombZones.size == 2 )
	{
		if(percentChance(50))
			{
				// Use both bombs, just set a dummy if this is chosen.
				index = index;
			}
			else
			{
				if(percentChance(50))
					level.bombZones[0] disableObject();
				else
					level.bombZones[1] disableObject();
			}

	}
	else if ( level.scr_csd_bombsites_enabled == 3 && level.bombZones.size == 2 )
	{
				index = 1;
				level.bombZones[1] disableObject();
	}
	else if (level.scr_csd_bombsites_enabled == 4)
			{
				index = 0;
				level.bombZones[0] disableObject();
			}
		// Random bomb, either bombsite a or bombsite b
	else if ( level.scr_csd_bombsites_enabled == 2 && level.bombZones.size == 2 )
			{
				if(percentChance(50))
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
		if( level.scr_csd_defusing_sound == 1 )
			player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;

		if ( level.scr_csd_allow_quickdefuse )
 	      player thread openwarfare\_objoptions::quickDefuse();
 	      
		if ( isDefined( level.sdBombModel ) )
			level.sdBombModel hide();
	}
	else
	{
		if( level.scr_csd_planting_sound == 1 )
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

			if ( level.scr_csd_sdmode == 0 ) {
				level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
			} else {
				level.bombZones[index] maps\mp\gametypes\_gameobjects::allowUse( "none" );			
			}
		}

		if( level.scr_csd_planting_sound == 0 )
			player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );
		if ( !level.hardcoreMode )
			iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );

		if ( level.scr_csd_bomb_notification_enable == 1 )
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
	level thread bombDefused(player);

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
		if ( isDefined( player ) && isDefined( player.name ) && player.pers["team"] == game["attackers"] ) {
			player.isBombCarrier = false;
			
			printOnTeamArg( &"MP_EXPLOSIVES_DROPPED_BY", game["attackers"], player );

			if ( level.scr_csd_scoreboard_bomb_carrier == 1 && isAlive( player ) ) {
				player.statusicon = "";
			}
		}

//		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_lost", player.pers["team"] );
		if ( isDefined( player ) )
		 	player logString( "bomb dropped" );
		 else
		 	logString( "bomb dropped" );
	}

	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_bomb" );
	
	if ( isDefined( player ) && player.pers["team"] == game["attackers"] )
		maps\mp\_utility::playSoundOnPlayers( game["bomb_dropped_sound"], game["attackers"] );
	else if ( isDefined( player ) )
 	    player playSoundToPlayer( game["bomb_dropped_sound"], player );
}


onPickup( player )
{
	player.isBombCarrier = true;

	if ( level.scr_csd_scoreboard_bomb_carrier == 1 && isDefined( player ) && player.pers["team"] == game["attackers"] ) {
		player.statusicon = "hud_status_bomb";
	}

	if ( isDefined( player ) && player.pers["team"] == game["defenders"] && level.scr_csd_allow_defender_explosivedestroy )
		player iprintln( &"OW_DESTROY_EXPLOSIVES" );
 	 
	if ( isDefined( player ) && player.pers["team"] == game["attackers"] )
		self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" );

	if ( !level.bombDefused  && isDefined( player ) && player.pers["team"] == game["attackers"] )
	{
		if ( isDefined( player ) && isDefined( player.name ) )
			printOnTeamArg( &"MP_EXPLOSIVES_RECOVERED_BY", game["attackers"], player );

		maps\mp\gametypes\_globallogic::leaderDialog( "bomb_taken", player.pers["team"] );
		player logString( "bomb taken" );
	}
	if ( isDefined( player ) && player.pers["team"] == game["attackers"] )
		maps\mp\_utility::playSoundOnPlayers( game["bomb_recovered_sound"], game["attackers"] );
	else if ( isDefined( player ) )
 	  player playSoundToPlayer( game["bomb_recovered_sound"], player );
}


onReset()
{
}


bombPlanted( destroyedObj, player )
{
	maps\mp\gametypes\_globallogic::pauseTimer();
	level.bombPlanted = true;
	
	game[player.name]["money"] += level.scr_csd_planting_reward;
	player thread displayGaining(level.scr_csd_planting_reward);
	player playLocalSound( "cash" );
	
	if ( level.scr_csd_bomb_notification_enable == 1 )
		destroyedObj.visuals[0] thread maps\mp\gametypes\_globallogic::playTickingSound();
	level.tickingObject = destroyedObj.visuals[0];

	level.timeLimitOverride = true;
	
	setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
	
	if ( level.scr_csd_bombtimer_show == 1 )
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
	if ( level.scr_csd_sdmode == 0 ) {
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
	if ( level.scr_csd_sdmode == 0 ) {
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

	if( level.scr_csd_show_briefcase == 1 )
		defuseObject.useWeapon = "briefcase_bomb_defuse_mp";

	level.defuseObject = defuseObject;

	BombTimerWait();
	setDvar( "ui_bomb_timer", 0 );
  if ( level.scr_csd_bomb_notification_enable == 1 )
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

	sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );
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

bombDefused(player)
{
	level.tickingObject maps\mp\gametypes\_globallogic::stopTickingSound();
	level.bombDefused = true;
	
	game[player.name]["money"] += level.scr_csd_defusing_reward;
	player thread displayGaining(level.scr_csd_defusing_reward);
	player playLocalSound( "cash" );
	
	setDvar( "ui_bomb_timer", 0 );

	level notify("bomb_defused");

	wait 1.5;

	setGameEndTime( 0 );

	sd_endGame( game["defenders"], game["strings"]["bomb_defused"] );
}


disableObject()
{
	// Check if the bombzone should still show to the defenders
	if ( level.scr_csd_defenders_show_both == 1 ) {
		self maps\mp\gametypes\_gameobjects::setVisibleTeam( "friendly" );
		self maps\mp\gametypes\_gameobjects::allowUse( "none" );
	} else {
		self maps\mp\gametypes\_gameobjects::disableObject();
	}	
}