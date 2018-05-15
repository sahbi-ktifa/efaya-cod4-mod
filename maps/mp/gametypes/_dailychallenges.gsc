#include openwarfare\_eventmanager;
#include openwarfare\_utils;

#include maps\mp\gametypes\_hud_util;

/**
	Daily Challenges Module
	
	Basically, pick 3 random challenges at startup, and give players a reward upon completion.
	Challenge are redoable many times each day.
**/
init()
{	 
	if (getDvar("scr_allow_daily_challenges") == "1") {
		 precacheShader("weapon_knife");
		 precacheShader("weapon_c4");
		 precacheShader("weapon_rpg7");
		 precacheShader("weapon_claymore");
		 precacheShader("weapon_mp5");
		 precacheShader("weapon_m16a4");
		 precacheShader("weapon_m40a3");
		 precacheShader("weapon_benelli_m4");
		 precacheShader("weapon_fraggrenade");
		 precacheShader("weapon_rpd");
		 precacheShader("killiconheadshot");
		 precacheShader("killiconsuicide");
		 precacheShader("hud_status_dead");
		  
		// Load the challenges
		dailyChallengesList = getdvarlistx( "scr_daily_challenges_", "string", "" );

		// Load the challenges into an array
		level.challenges = [];
		
		for ( i=0; i < dailyChallengesList.size; i++ ) {
			// Split the challenges
			dailyChallenges = strtok( dailyChallengesList[i], ";" );
			for (j = 0; j < dailyChallenges.size; j++) {
				level.challenges[j] = dailyChallenges[j];
			}
			
		}
		//level.scr_challenges = getDvar( "scr_daily_challenges");						   
		//level.challenges = strtok(level.scr_challenges, ";");
		one = -1;
		two = -1;
		three = -1;
		while (one < 0 || two < 0 || three < 0) {
			rand = RandomInt( level.challenges.size );
			if (one == -1) {
				one = rand;
				continue;
			}
			if (two == -1 && rand != one) {
				two = rand;
				continue;
			}
			if (three == -1 && rand != one && rand != two) {
				three = rand;
				continue;
			}
		}	
		
		
		level.daily_challenges = [];
		level.daily_challenges["challenge1"] = [];
		level.daily_challenges["challenge1"]["ref"] = strtok(level.challenges[one], ":")[0];
		level.daily_challenges["challenge1"]["label"] = strtok(level.challenges[one], ":")[1];
		level.daily_challenges["challenge1"]["amount"] = strtok(level.challenges[one], ":")[2];
		level.daily_challenges["challenge1"]["difficulty"] = strtok(level.challenges[one], ":")[3];
		level.daily_challenges["challenge2"] = [];
		level.daily_challenges["challenge2"]["ref"] = strtok(level.challenges[two], ":")[0];
		level.daily_challenges["challenge2"]["label"] = strtok(level.challenges[two], ":")[1];
		level.daily_challenges["challenge2"]["amount"] = strtok(level.challenges[two], ":")[2];
		level.daily_challenges["challenge2"]["difficulty"] = strtok(level.challenges[two], ":")[3];
		level.daily_challenges["challenge3"] = [];
		level.daily_challenges["challenge3"]["ref"] = strtok(level.challenges[three], ":")[0];
		level.daily_challenges["challenge3"]["label"] = strtok(level.challenges[three], ":")[1];
		level.daily_challenges["challenge3"]["amount"] = strtok(level.challenges[three], ":")[2];
		level.daily_challenges["challenge3"]["difficulty"] = strtok(level.challenges[three], ":")[3];
		
		level thread onPlayerConnected();
	}
}

onPlayerConnected() {
	for(;;)
	{
		level waittill("connected", player);
		player.daily_challenges = [];
		player.daily_challenges["challenge1"] = 0;
		player.daily_challenges["challenge2"] = 0;
		player.daily_challenges["challenge3"] = 0;
	}
}

showDailyChallenges() {
	if (getDvar("scr_allow_daily_challenges") == "1") {
		wait(6.0);
		
		showDailyChallenge(0);
		showDailyChallenge(1);
		showDailyChallenge(2);
	}
}

showDailyChallenge( index )
{
	if ( level.inReadyUpPeriod )
		return;
	
	// don't want the hud elements when the game is over
	assert( game["state"] != "postgame" );
	
	if ( !isdefined( self.daily_challenges_icons ) )
	{
		self.daily_challenges_icons = [];
		self.daily_challenges_names = [];
	}
	
	iconsize = 24;
	
	if ( !isdefined( self.daily_challenges_icons[ index ] ) )
	{
		assert( !isdefined( self.daily_challenges_names[ index ] ) );
		
		xpos = -5;
		if ( level.splitScreen )
			ypos = 0 - (80 + iconsize * (2 - index));
		else
			ypos = 0 - (165 + iconsize * (2 - index));
		
		icon = createIcon( "white", iconsize, iconsize );
		icon setPoint( "BOTTOMRIGHT", undefined, xpos, ypos );
		icon.archived = false;
		icon.foreground = true;
		
		completion = createFontString( "default", 1.4 );
		completion setParent( icon );
		completion setPoint( "RIGHT", "LEFT", -5, 0 );
		completion.archived = false;
		completion.alignX = "right";
		completion.alignY = "middle";
		completion.foreground = true;

		text = createFontString( "default", 1.4 );
		text setParent( completion );
		text setPoint( "RIGHT", "LEFT", -32, 0 );
		text.archived = false;
		text.alignX = "right";
		text.alignY = "middle";
		text.foreground = true;

		self.daily_challenges_icons[ index ] = icon;
		self.daily_challenges_names[ index ] = text;
		self.daily_challenges_completions[ index ] = completion;
	}
	
	icon = self.daily_challenges_icons[ index ];
	text = self.daily_challenges_names[ index ];
	completion = self.daily_challenges_completions[ index ];
	
	if ( isDefined( icon ) ) {
		icon.alpha = 1;
		icon setShader( getChallengeIcon(level.daily_challenges["challenge" + (index + 1)]["ref"]), iconsize, iconsize );
	}
	
	if ( isDefined( text ) ) {
		completion.alpha = 0.75;
		completion setText(" : " + self.daily_challenges["challenge" + (index + 1)] + "/" + level.daily_challenges["challenge" + (index + 1)]["amount"]);
		text.alpha = 0.75;
		text setText(level.daily_challenges["challenge" + (index + 1)]["label"]);
	}
}

getChallengeIcon(key) {
	ClientPrint(self, key); 
	label = "";
	switch( key ) {
		case "DC_HEADSHOTS":
			label = "killiconheadshot";
			break;
		case "DC_ASSAULT_KILLS":
			label = "weapon_m16a4";
			break;
		case "DC_KILLS":
			label = "hud_status_dead";
			break;
		case "DC_SMG_KILLS":
			label = "weapon_mp5";
			break;
		case "DC_SNIPER_KILLS":
			label = "weapon_m40a3";
			break;
		case "DC_SHOTGUN_KILLS":
			label = "weapon_benelli_m4";
			break;
		case "DC_KNIFE_KILLS":
			label = "weapon_knife";
			break;
		case "DC_CLASSIC_KILLS":
			label = "weapon_rpd";
			break;
		case "DC_ASSISTS":
			label = "hud_status_dead";
			break;
		case "DC_CLAYMORE_KILLS":
			label = "weapon_claymore";
			break;
		case "DC_C4_KILLS":
			label = "weapon_c4";
			break;
		case "DC_RPG_KILLS":
			label = "weapon_rpg7";
			break;
		case "DC_SUICIDE":
			label = "killiconsuicide";
			break;
		case "DC_GRENADE_KILLS":
			label = "weapon_fraggrenade";
			break;
			
	}
	return label;
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if (getDvar("scr_allow_daily_challenges") == "1") {
		for (index = 1; index < 4; index++) {
			match = false;
			if ((sHitLoc == "head" || sHitLoc == "helmet") && level.daily_challenges["challenge" + index]["ref"] == "DC_HEADSHOTS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if (sMeansOfDeath == "MOD_MELEE" && level.daily_challenges["challenge" + index]["ref"] == "DC_KNIFE_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && sWeapon == "claymore_mp" && level.daily_challenges["challenge" + index]["ref"] == "DC_CLAYMORE_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && level.daily_challenges["challenge" + index]["ref"] == "DC_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && sWeapon == "c4_mp" && level.daily_challenges["challenge" + index]["ref"] == "DC_C4_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && sWeapon == "rpg_mp" && level.daily_challenges["challenge" + index]["ref"] == "DC_RPG_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && isSubStr( sWeapon, "frag_" ) && level.daily_challenges["challenge" + index]["ref"] == "DC_GRENADE_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && (isSubStr( sWeapon, "m16_" ) || isSubStr( sWeapon, "m14_" ) || isSubStr( sWeapon, "ak47_" ) || isSubStr( sWeapon, "g3_" ) || isSubStr( sWeapon, "g36c_" ) || isSubStr( sWeapon, "m4_" )) && level.daily_challenges["challenge" + index]["ref"] == "DC_ASSAULT_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && (isSubStr( sWeapon, "mp5_" ) || isSubStr( sWeapon, "skorpion_" ) || isSubStr( sWeapon, "uzi_" ) || isSubStr( sWeapon, "ak74u_" ) || isSubStr( sWeapon, "p90_" )) && level.daily_challenges["challenge" + index]["ref"] == "DC_SMG_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && (isSubStr( sWeapon, "m1014_" ) || isSubStr( sWeapon, "winchester1200_" )) && level.daily_challenges["challenge" + index]["ref"] == "DC_SHOTGUN_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && (isSubStr( sWeapon, "rpd_" ) || isSubStr( sWeapon, "saw_" ) || isSubStr( sWeapon, "m60e4_" )) && level.daily_challenges["challenge" + index]["ref"] == "DC_CLASSIC_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			} else if ( isPlayer( attacker ) && attacker != self && (isSubStr( sWeapon, "dragunov_" ) || isSubStr( sWeapon, "m40a3_" ) || isSubStr( sWeapon, "barrett_" ) || isSubStr( sWeapon, "remington700_" ) || isSubStr( sWeapon, "m21_" )) && level.daily_challenges["challenge" + index]["ref"] == "DC_SNIPER_KILLS") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			}
			if (( sMeansOfDeath == "MOD_FALLING" || ( isPlayer( attacker ) && attacker == self ) ) && level.daily_challenges["challenge" + index]["ref"] == "DC_SUICIDE") {
				attacker.daily_challenges["challenge" + index] += 1;
				match = true;
			}
			
			if (match == true) {
				updateCompletion(attacker, index - 1);
			}		
		}
	}
}

playerAssist() {
	if (getDvar("scr_allow_daily_challenges") == "1") {
		for (index = 1; index < 4; index++) {
			match = false;
			if (level.daily_challenges["challenge" + index]["ref"] == "DC_ASSISTS") {
				self.daily_challenges["challenge" + index] += 1;
				match = true;
			}
			
			if (match == true) {
				updateCompletion(self, index - 1);
			}
		}
	}
}

updateCompletion(attacker, index) {
	if (attacker.daily_challenges["challenge" + (index + 1)]  <= level.daily_challenges["challenge" + (index + 1)]["amount"]) {
		if (int(attacker.daily_challenges["challenge" + (index + 1)]) == int(level.daily_challenges["challenge" + (index + 1)]["amount"])) {
			attacker.daily_challenges_names[ index ].color = ( 0.14, 0.49, 0 );
			attacker.daily_challenges_completions[ index ].color = ( 0.14, 0.49, 0 );
		}
		attacker.daily_challenges_completions[ index ] setText(" : " + attacker.daily_challenges["challenge" + (index + 1)] + "/" + level.daily_challenges["challenge" + (index + 1)]["amount"]);
	}
}

playerSpawned() {
	if (getDvar("scr_allow_daily_challenges") == "1") {
		/*for (index = 0; index < 3; index++) {
			if (isPlayer( self ) && int(self.daily_challenges["challenge" + (index + 1)]) == int(level.daily_challenges["challenge" + (index + 1)]["amount"])) {
				self.daily_challenges_names[ (index + 1) ].color = ( 1, 1, 1 );
				self.daily_challenges_completions[ (index + 1) ].color = ( 1, 1, 1 );
				self.daily_challenges["challenge" + (index + 1)] = 0;
				self.daily_challenges_completions[ (index + 1) ] setText(" : " + self.daily_challenges["challenge" + (index + 1)] + "/" + level.daily_challenges["challenge" + (index + 1)]["amount"]);
				
				//TODO : Give Reward
				self giveMaxAmmo("frag_grenade_mp");
				currentWeapon = self getCurrentWeapon();		
				self giveMaxAmmo(currentWeapon);
				self thread openwarfare\_speedcontrol::setModifierSpeed( "_daily_challenges", 120 );
			}
		}*/
	}
}