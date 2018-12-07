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
// Recoded for Openwarfare by Samuel
// Changes by [105]HolyMoly
// V.1.Final


#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include openwarfare\_eventmanager;
#include openwarfare\_utils;

init()
{
        level.scr_objective_safezone_enable = getdvarx( "scr_objective_safezone_enable", "int", 0, 0, 1 );
        level.scr_objective_safezone_radius = getdvarx( "scr_objective_safezone_radius", "int", 100, 50, 500 );

        level.scr_sd_objective_takedamage_enable = getdvarx( "scr_sd_objective_takedamage_enable", "int", 0, 0, 1 );
        level.scr_sd_objective_takedamage_option = getdvarx( "scr_sd_objective_takedamage_option", "int", 0, 0, 1 );

        if ( level.scr_sd_objective_takedamage_option )
                level.scr_sd_objective_takedamage_health = getdvarx( "scr_sd_objective_takedamage_health", "int", 500, 1, 2000 );
        else
                level.scr_sd_objective_takedamage_counter = getdvarx( "scr_sd_objective_takedamage_counter", "int", 5, 1, 20 );

        level.scr_sd_allow_defender_explosivepickup = getdvarx( "scr_sd_allow_defender_explosivepickup", "int", 0, 0, 1 );
        level.scr_sd_allow_defender_explosivedestroy = getdvarx( "scr_sd_allow_defender_explosivedestroy", "int", 0, 0, 1 );
        level.scr_sd_allow_defender_explosivedestroy_time = getdvarx( "scr_sd_allow_defender_explosivedestroy_time", "int", 10, 1, 60 );
        level.scr_sd_allow_defender_explosivedestroy_sound = getdvarx( "scr_sd_allow_defender_explosivedestroy_sound", "int", 0, 0, 1 );
        level.scr_sd_allow_defender_explosivedestroy_win = getdvarx( "scr_sd_allow_defender_explosivedestroy_win", "int", 0, 0, 1 );
        level.scr_sd_allow_quickdefuse = getdvarx( "scr_sd_allow_quickdefuse", "int", 0, 0, 1 );

		level.scr_csd_allow_quickdefuse = getdvarx( "scr_csd_allow_quickdefuse", "int", 0, 0, 1 );
		level.scr_csd_objective_takedamage_enable = getdvarx( "scr_csd_objective_takedamage_enable", "int", 0, 0, 1 );

        //Level thread to create and control all safe zones.
        level thread setSafeZones();

        if ( level.gameType == "sd" && level.scr_sd_objective_takedamage_enable ||  level.gameType == "sr" && level.scr_sr_objective_takedamage_enable ||  level.gameType == "csd" && level.scr_csd_objective_takedamage_enable )
        {
                level._effect["bombexplosion"] = loadfx( "props/barrelexp" );
                game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";
                game["strings"]["bomb_defused"] = &"MP_BOMB_DEFUSED";
                precacheString( game["strings"]["target_destroyed"] );
                precacheString( game["strings"]["bomb_defused"] );

                level thread createDamageArea();
        }

        level thread addNewEvent( "onPlayerConnected", ::onPlayerConnected );

}

onPlayerConnected()
{
	self thread addNewEvent( "onPlayerSpawned", ::onPlayerSpawned );
}

onPlayerSpawned()
{

	if ( level.scr_sd_allow_quickdefuse == 1 || level.scr_csd_allow_quickdefuse == 1 )
		self.didQuickDefuse = false;

	//The per-player monitor thread uses level safezones,
	if ( level.scr_objective_safezone_enable == 1 )
		self thread monitorSafeZoneLevel();

	if ( level.scr_sd_allow_defender_explosivepickup && level.scr_sd_allow_defender_explosivedestroy && self.pers["team"] == game["defenders"] && getDvar( "g_gametype" ) == "sd" )
		self thread allowDefenderExplosiveDestroy();
}

//Called once on game start to set level safe zones.
setSafeZones()
{
        // Delete any safezones
	if( isDefined( game["safezones"] ) ) {
                for( index = 0; index < game["safezones"].size; index++ )
                {
                        game["safezones"][index] delete();

                }
        }

	game["safezones"] = [];
	gametype = getDvar( "g_gametype" );
	objZones = [];

	switch( gametype )
	{
		case "csd":
		case "sd":
		case "sr":
		case "dem":
		case "re":
	                objZones = getEntArray( "bombzone", "targetname" );
			break;

		case "ctf":
		        objZones = getEntArray( "ctf_flag_pickup_trig", "targetname" );
			break;

		case "sab":
		case "sab2":
		case "ass":
		case "tgr":
		case "grd":
		        objZones[0] = getEnt( "sab_bomb_axis", "targetname" );
			objZones[1] = getEnt( "sab_bomb_allies", "targetname" );
			break;

		case "koth":
			level thread monitorSafeZonesKoth();
			break;

		case "gr":
			level thread monitorSafeZonesGreed();
			break;

                case "dom":
		        objZones1 = getEntArray( "flag_primary", "targetname" );
			objZones2 = getEntArray( "flag_secondary", "targetname" );

			i = 0;
			j = 0;

			for ( i = 0; i < objZones1.size; i++ )
				objZones[i] = objZones1[i];

			for ( j = i; j < objZones2.size + i; j++ )
				objZones[j] = objZones2[j-i];
			break;

		default:
			break;

	}

	for ( index = 0; index < objZones.size; index++ )
	{
		game["safezones"][index] = spawn( "trigger_radius", objZones[index].origin + ( 0, 0, -48 ), 0, level.scr_objective_safezone_radius, 200 );
	}

}

monitorSafeZonesKoth()
{
        level endon("game_ended");

        // Delete any safezones
	if( isDefined( game["safezones"] ) ) {
                for( index = 0; index < game["safezones"].size; index++ )
                {
                        game["safezones"][index] delete();

                }
        }

        currentRadio = undefined;
        origin = undefined;
        radios = getEntArray( "hq_hardpoint", "targetname" );

        while ( 1 )
        {

                //Called the first time an HQ is created.
                if ( isDefined( level.prevradio ) && !isDefined( currentRadio ) )
                {
                        currentRadio = level.prevradio;

                        for ( index = 0; index < radios.size; index++ )
                        {
                                if ( radios[index] == currentRadio )
                                {
                                        origin = index;
                                        break;
                                }
                        }

                        game["safezones"][0] = spawn( "trigger_radius", radios[origin].origin + ( 0, 0, -100 ), 0, level.scr_objective_safezone_radius, 200 );
                }

                else if ( isDefined( level.prevradio ) && isDefined( currentRadio ) && currentRadio != level.prevradio )
                {
                        currentRadio = level.prevradio;

                        for ( index = 0; index < radios.size; index++ )
                        {
                                if ( radios[index] == currentRadio )
                                {
                                        origin = index;
                                        break;
                                }

                        }

                        game["safezones"][0].origin = game["safezones"][0].origin + ( 0, 0, -100 );
                }

                wait( 1.0 );

        }

}

monitorSafeZonesGreed()
{

        level endon("game_ended");

        // Delete any safezones
	if( isDefined( game["safezones"] ) ) {
                for( index = 0; index < game["safezones"].size; index++ )
                {
                        game["safezones"][index] delete();

                }
        }

        while ( 1 )
        {
	        if( isDefined( level.activeDropZones ) && level.activeDropZones.size > 0 )
	        {
		        for( i=0; i<level.activeDropZones.size; i++ )
		        {
			        if( !isDefined( game["safezones"][i] ) )
			        {
				        game["safezones"][i] = spawn( "trigger_radius", level.activeDropZones[i].origin + ( 0, 0, -100 ), 0, level.scr_objective_safezone_radius, 200 );
			        }

			        else if( game["safezones"][i].origin != ( level.activeDropZones[i].origin + ( 0, 0, -100 ) ) )
			        {
				        game["safezones"][i].origin = level.activeDropZones[i].origin + ( 0, 0, -100 );
			        }
		        }

                }

                wait( 1.0 );

        }

}

monitorSafeZoneLevel()
{
        self endon( "death" );
        self endon( "disconnect" );

        for (;;)
        {
                self waittill( "grenade_fire", explosive, weaponName );

                if ( weaponName == "c4_mp" || weaponName == "claymore_mp" )
                {
                        explosive.weaponName = weaponName;
                        explosive maps\mp\gametypes\_weapons::waitTillNotMoving();

                        for ( index = 0; index < game["safezones"].size; index++ )
                        {
                                if ( isDefined( explosive ) && explosive isTouching( game["safezones"][index] ) )
                                {
                                        stockCount = self getWeaponAmmoStock( explosive.weaponName );
                                        maxStock = weaponMaxAmmo( explosive.weaponName );

                                        if ( stockCount < maxStock )
                                                self setWeaponAmmoStock( explosive.weaponName, stockCount + 1 );

                                        explosive delete();
                                        break;
                                }

                        }

                }

        }

}

createDamageArea()
{
        if ( level.gameType != "sd" || level.gameType != "sr" || level.gameType != "csd" )
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
                        if( level.gameType == "sd" ) {
                                if ( level.scr_sd_objective_takedamage_option )
                                        level.objectiveHealth[index] = level.scr_sd_objective_takedamage_health;
                                else
                                        level.objectiveHealth[index] = level.scr_sd_objective_takedamage_counter;
                        }

                        if( level.gameType == "sr" ) {
                                if ( level.scr_sr_objective_takedamage_option )
                                        level.objectiveHealth[index] = level.scr_sr_objective_takedamage_health;
                                else
                                        level.objectiveHealth[index] = level.scr_sr_objective_takedamage_counter;
                        }

						if( level.gameType == "csd" ) {
                                if ( level.scr_csd_objective_takedamage_option )
                                        level.objectiveHealth[index] = level.scr_csd_objective_takedamage_health;
                                else
                                        level.objectiveHealth[index] = level.scr_csd_objective_takedamage_counter;
                        }

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
                       if( level.gameType == "sd" ) {
                               if ( level.scr_sd_objective_takedamage_option )
                                       level.objectiveHealth[index] = level.scr_sd_objective_takedamage_health;
                               else
                                       level.objectiveHealth[index] = level.scr_sd_objective_takedamage_counter;
                       }

                       if( level.gameType == "sr" ) {
                               if ( level.scr_sr_objective_takedamage_option )
                                       level.objectiveHealth[index] = level.scr_sr_objective_takedamage_health;
                               else
                                       level.objectiveHealth[index] = level.scr_sr_objective_takedamage_counter;
                       }

					   if( level.gameType == "csd" ) {
                               if ( level.scr_csd_objective_takedamage_option )
                                       level.objectiveHealth[index] = level.scr_csd_objective_takedamage_health;
                               else
                                       level.objectiveHealth[index] = level.scr_csd_objective_takedamage_counter;
                       }

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

                if( level.gameType == "sd" ) {
                        if ( level.scr_sd_objective_takedamage_option )
                        {
                                level.objDamageCounter[index]++;
                                level.objDamageTotal[index] += damage;
                        }
                }

                if( level.gameType == "sr" ) {
                        if ( level.scr_sr_objective_takedamage_option )
                        {
                                level.objDamageCounter[index]++;
                                level.objDamageTotal[index] += damage;
                        }
                }

				if( level.gameType == "csd" ) {
                        if ( level.scr_csd_objective_takedamage_option )
                        {
                                level.objDamageCounter[index]++;
                                level.objDamageTotal[index] += damage;
                        }
                }

                wait( 0.1 );

                if ( isDefined( attacker ) && isPlayer( attacker ) )
                {
                        if ( attacker.pers["team"] == game["defenders"] )
                        {
                                if ( !level.isLosingHealth[index] )
                                {
                                        level.isLosingHealth[index] = true;
                                                if( level.gameType == "sd" ) {

                                                        if ( level.scr_sd_objective_takedamage_option )
                                                        {
                                                                level.objectiveHealth[index] -= int( level.objDamageTotal[index] / level.objDamageCounter[index] );
                                                                level.objDamageCounter[index] = 0;
                                                                level.objDamageTotal[index] = 0;
                                                        }

                                                        else
                                                        {
                                                                level.objectiveHealth[index]--;
                                                        }

                                                }

                                                if( level.gameType == "sr" ) {

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
                                                }

												if( level.gameType == "csd" ) {

                                                        if ( level.scr_csd_objective_takedamage_option )
                                                        {
                                                                level.objectiveHealth[index] -= int( level.objDamageTotal[index] / level.objDamageCounter[index] );
                                                                level.objDamageCounter[index] = 0;
                                                                level.objDamageTotal[index] = 0;
                                                        }

                                                        else
                                                        {
                                                                level.objectiveHealth[index]--;
                                                        }

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

        if( level.gameType == "sd" ) {
	        thread maps\mp\gametypes\sd::playSoundinSpace( "exp_suitcase_bomb_main", object.origin );
        }

        if( level.gameType == "sr" ) {
	        thread maps\mp\gametypes\sr::playSoundinSpace( "exp_suitcase_bomb_main", object.origin );
        }

		if( level.gameType == "csd" ) {
	        thread maps\mp\gametypes\csd::playSoundinSpace( "exp_suitcase_bomb_main", object.origin );
        }

	setGameEndTime( 0 );

	wait( 3.0 );

        if( level.gameType == "sd" ) {
	        maps\mp\gametypes\sd::sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );
        }

        if( level.gameType == "sr" ) {
	        maps\mp\gametypes\sr::sr_endGame( game["attackers"], game["strings"]["target_destroyed"] );
        }

		if( level.gameType == "csd" ) {
	        maps\mp\gametypes\csd::sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );
        }

}

allowDefenderExplosiveDestroy() // Finally fixed animation issue
{
        self endon( "disconnect" );
        self endon( "death" );

        self.destroyingExplosive = false;
        self.explosiveDestroyed = false;
        lastWeapon = self getCurrentWeapon();
        startTime = 0;
        destroyTime = level.scr_sd_allow_defender_explosivedestroy_time;

        while ( isAlive( self ) && !level.bombPlanted && !level.gameEnded && !self.explosiveDestroyed )
        {
                while ( isAlive( self ) && self meleeButtonPressed() && self.isBombCarrier && !level.gameEnded )
                {
                        if ( startTime == 0 )
                        {
                                if ( level.scr_sd_allow_defender_explosivedestroy_sound )
                                        playSoundOnPlayers( "mp_ingame_summary", game["attackers"] );

                                wait( 0.5 ); //Give time for melee animation to finish

                                if ( self meleeButtonpressed() )
                                {
                                        if( level.scr_sd_show_briefcase )
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

                                                while ( self getCurrentWeapon() != "briefcase_bomb_mp" )
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
                                        if( level.scr_sd_show_briefcase ) {
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

                        if( level.scr_sd_show_briefcase && self getCurrentWeapon() != "briefcase_bomb_mp" )
      	                        break;

                        if( level.scr_sd_show_briefcase )
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

        if ( !level.bombPlanted && !level.gameEnded && level.scr_sd_allow_defender_explosivedestroy_win )
        {
                setGameEndTime( 0 );

                maps\mp\gametypes\sd::sd_endGame( game["defenders"], &"OW_EXPLOSIVES_DESTROYED" );

                if( level.scr_sd_show_briefcase ) {
                        self freezeControls( false );
                        self execClientCommand( "weapprev" );
                        wait( 0.50 );
                        self freezeControls( true );
                }

                maps\mp\gametypes\_globallogic::givePlayerScore( "defuse", self );
		self thread [[level.onXPEvent]]( "defuse" );

        }

        else if ( !level.scr_sd_allow_defender_explosivedestroy_win && !level.bombPlanted && !level.gameEnded )
        {
	        self.isBombCarrier = false;

                if( level.scr_sd_show_briefcase ) {

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
                        if( level.scr_sd_show_briefcase ) {
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
  	        level.defuseObject thread maps\mp\gametypes\sd::onUseDefuseObject( self );

        } else if ( playerChoice != correctWire && isAlive( self ) && !level.gameEnded && !level.bombExploded ) {
  	        level notify( "wrong_wire" );
        }

}
