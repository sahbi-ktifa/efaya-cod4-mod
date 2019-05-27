#include openwarfare\_eventmanager;
#include maps\mp\_utility;
#include openwarfare\_utils;

init()
{
	
	level._efx["tactical_insertion_beacon_green"] = loadfx( "misc/laser_mov_green2" );
	level._efx["tactical_insertion_beacon_red"]= loadfx( "misc/laser_mov_red" );
	
	level.scr_tactical_insert_allow_damage = getdvarx( "scr_tactical_insert_allow_damage", "int", 1, 0, 1 );
	level.scr_tactical_insert_debug = getdvarx( "scr_tactical_insert_debug", "int", 0, 0, 1 );
	
	precacheModel( "model_russian_crouch_efaya" );

	level thread addNewEvent( "onPlayerConnected", ::onPlayerConnected );
}

onPlayerConnected()
{
	self.insertion_marker = undefined;
	self.marker_fx = [];
	
	self thread addNewEvent( "onPlayerSpawned", ::onPlayerSpawned );
	self thread addNewEvent( "onJoinedTeam", ::onJoinedTeam );
	self thread addNewEvent( "onJoinedSpectators", ::onJoinedSpectators ); 
	self thread onDisconnected(); 
	
}

onPlayerSpawned()
{
	self thread monitorTacticalInsert();
}

CleanUpMarker()
{
	if( isDefined( self.insertion_marker ) )
	{
		if( isDefined( self.insertion_marker.visual ) )
			self.insertion_marker.visual delete();
		
		if( level.scr_tactical_insert_allow_damage && isDefined( self.insertion_marker.visual.sold ) )
			self.insertion_marker.visual.sold delete();
			
		if( self.marker_fx.size )
			for( i=0; i < self.marker_fx.size; i++ )
				if( isDefined( self.marker_fx[i] ) )
					self.marker_fx[i] delete();
		
		self.insertion_marker delete();
	}
}

monitorTacticalInsert()
{
	self endon( "disconnect" );
	self endon( "death" );
	
	for( ;; )
	{
		self waittill ( "grenade_fire", grenade, weaponName );
		
		if( weaponName == "c4_mp" )
		{
			self thread trackInsertionPoint( grenade );
		}	
	}
}

onJoinedTeam()
{
	if( isDefined( self.insertion_marker ) )
		self CleanUpMarker();
}

onJoinedSpectators()
{
	if( isDefined( self.insertion_marker ) )
		self CleanUpMarker();
}

onDisconnected()
{
	self waittill("disconnect");
	
	if( isDefined( self.insertion_marker ) )
		self CleanUpMarker();
}

trackInsertionPoint( grenade )
{
	self endon( "disconnect" );
	
   grenade waitTillNotMoving();
   
   self playSound ( "tactical_insert_planted" );
   
   self.insertion_marker = spawn( "script_origin", self.origin );
   self.insertion_marker.origin = self.origin;
   self.insertion_marker.team = self.pers["team"];
   self.insertion_marker.angles = self.angles;
   self.insertion_marker.visual = grenade;
   
   if( level.scr_tactical_insert_allow_damage )
   {
      grenade.collision = spawn( "trigger_radius", self.origin-(0,0,5), 0, 30, 30 );
      grenade.collision.owner = self;
      grenade.collision.team = self.pers["team"];
      grenade.collision.health = 100;
      grenade.collision thread insertion_damage();
      grenade.collision thread MonitorForDamage("dmg");
      self.insertion_marker.visual.sold = grenade.collision;
   }
   
   grenade.insertion_fx_ownteam = spawnBeaconFX( self.insertion_marker.origin, level._efx["tactical_insertion_beacon_green"] );
   grenade.insertion_fx_ownteam.team = self.pers["team"];
   grenade.insertion_fx_ownteam thread showToTeam();   
   self.marker_fx[self.marker_fx.size] = grenade.insertion_fx_ownteam;
   
   grenade.insertion_fx_otherteam = spawnBeaconFX( self.insertion_marker.origin, level._efx["tactical_insertion_beacon_red"] );
   grenade.insertion_fx_otherteam.team = getOtherTeam( self.pers["team"] );
   grenade.insertion_fx_otherteam thread showToTeam();
   self.marker_fx[self.marker_fx.size] = grenade.insertion_fx_otherteam;
}

spawnBeaconFX( origin, fx )
{
	effect =  spawnFx( fx, origin, (0,0,1), (1,0,0) );
	triggerFx( effect );
	
	return effect;
}

waitTillNotMoving()
{
	prevorigin = (0,0,0);
	while( isDefined( self ) )
	{
		if ( self.origin == prevorigin )
			break;

		prevorigin = self.origin;
		wait .15;
	}
}

showToTeam()
{
	level endon( "game_ended" );
	self endon( "death" );

	while( isDefined( self ) )
	{
		self hide();
		players = getEntArray( "player", "classname" );
		for( i = 0; i < players.size ; i++ )
		{
			player = players[i];
			
			if( isDefined( player.pers["team"] ) && player.pers["team"] == self.team )
			{
				self ShowToPlayer( player );
			}
		}
			
		wait( 0.05 );
	}
}

insertion_damage()
{
	level endon( "game_ended" );
	self endon( "death" );
	
	while( distance2d( self.origin, self.owner.origin ) <= 50 )
		wait( 0.05 );
		
	self setContents( 1 );

	while( isDefined( self ) )
	{
		self waittill( "dmg", dmg, attacker );
		
		// check if the player can damage sentry gun
		if( self friendlyCheck( attacker ) )
			continue;
		
		// reduce the sentry gun's health
		self.health -= dmg;
		
		// send the player some feedback
		if( isdefined( attacker ) )
			attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( false );
		
		// debug only
		if( level.scr_tactical_insert_debug )
		{
			if( isdefined( attacker ) )
			{
				attacker iprintlnbold( "Health:  " + self.health );
				attacker iprintlnBold( "Damage:  " + dmg );
			}
		}
		
		// destroy sentry if no health is left
		if( self.health <= 0 )
		//self playSound ( "tactical_insert_destroyed" );
			break;
	}
	
	if( isdefined( self.owner ) )
		self playSound ( "tactical_insert_destroyed" );
		self.owner thread CleanUpMarker();
}

MonitorForDamage(dmgEvent)
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	
	while( isDefined( self ) )
	{
		players = level.players;
		for( i = 0; i < players.size; i++ )
		{
			player = players[i];

			forward = vector_scale( anglesToForward( player getPlayerAngles() ), 10000 );
			startOrigin = player getEye() + (0,0,20);
			endOrigin = startOrigin + forward;
			trace = bulletTrace( startOrigin, endOrigin, true, player );

			wait( 0.05 );

			if( isDefined( trace["entity"] ) && trace["entity"] == self )
			{
				sWeapon = player getCurrentWeapon();
				if( player attackButtonPressed() && player getAmmoCount( sWeapon ) > 0 )
				{
					iDamage = 40;
					self notify( dmgEvent, iDamage, player );
				}
			}
		}
		
		wait( 0.05 );
	}
}

friendlyCheck( attacker )
{
	if( level.scr_tactical_insert_debug )
		return( false );
		
	if( attacker == self.owner )
		return( true );
	
	if( attacker.pers["team"] == self.team )
		return( true );
	
	return( false );
}

triggerAbility() {
	self endon("disconnect");
	self endon("death");
	level endon( "game_ended" );

	if (self.pers["team"] == "allies") {
		if( !isdefined(self.insertion_marker)) {
			ClientPrint(self, "No tactical cam available.");
			return;
		}
		if( isdefined(self.insertion_marker) && self.insertion_marker.team == self.pers["team"] && (!isdefined(self.using_marker) || self.using_marker == false)) {
			self.use_marker = self getOrigin();	
			self goBlack();
			self disableWeapons();		
			self freezeControls( true );
			self hide();			
			wait(1.5);
			self setOrigin(self.insertion_marker.origin);
			
			// Spawn fake model			
			self.spawn_model = spawn( "script_model", self.use_marker );
			self.spawn_model setModel("model_russian_crouch_efaya");
			self.spawn_model setContents( 1 );
			self.spawn_model_collision = spawn( "trigger_radius", self.origin-(0,0,5), 0, 30, 72 );
      		self.spawn_model_collision.owner = self;
			self.spawn_model_collision.health = self.health;
      		self.spawn_model_collision setContents( 1 );
      		self.spawn_model_collision thread spawn_model_damage();
			self.spawn_model_collision thread MonitorForDamage("dmg_spawn_model");
			
			wait(0.5);
			visionSetNaked( "mpIntro", 0 );
			self.ab_blackscreen destroy();
			self.ab_blackscreen2 destroy();
			self freezeControls( false );

			self.using_marker = true;		
			ClientPrint(self, "Currently Watching through tactical cam...");
			self linkTo( self.insertion_marker );
		} else if (isdefined(self.use_marker) && isdefined(self.insertion_marker) && self.insertion_marker.team == self.pers["team"] && isdefined(self.using_marker) && self.using_marker == true) {
			self.using_marker = false;	
			self freezeControls( true );
			self goBlack();
			wait(1);
			if ( isDefined( self.spawn_model ) ) {		
				self.spawn_model delete();
			}			
			self unlink();
			self setOrigin(self.use_marker);
			wait(0.5);
			visionSetNaked( getDvar( "mapname" ), 0 );		
			self.ab_blackscreen destroy();
			self.ab_blackscreen2 destroy();

			self enableWeapons();
			self freezeControls( false );
			self show();
		}
	} else if (self.pers["team"] == "axis") {

	}
}

goBlack() {
	if ( !isDefined( self.ab_blackscreen ) ) {
		self.ab_blackscreen = newClientHudElem( self );
		self.ab_blackscreen.x = 0;
		self.ab_blackscreen.y = 0;
		self.ab_blackscreen.alignX = "left";
		self.ab_blackscreen.alignY = "top";
		self.ab_blackscreen.horzAlign = "fullscreen";
		self.ab_blackscreen.vertAlign = "fullscreen";
		self.ab_blackscreen.sort = -5;
		self.ab_blackscreen.color = (0,0,0);
		self.ab_blackscreen.archived = false;
		self.ab_blackscreen setShader( "black", 640, 480 );	
		self.ab_blackscreen.alpha = 0;
	}
	if ( !isDefined( self.ab_blackscreen2 ) ) {	
		self.ab_blackscreen2 = newClientHudElem( self );
		self.ab_blackscreen2.x = 0;
		self.ab_blackscreen2.y = 0;
		self.ab_blackscreen2.alignX = "left";
		self.ab_blackscreen2.alignY = "top";
		self.ab_blackscreen2.horzAlign = "fullscreen";
		self.ab_blackscreen2.vertAlign = "fullscreen";
		self.ab_blackscreen2.sort = -4;
		self.ab_blackscreen2.color = (0,0,0);
		self.ab_blackscreen2.archived = false;
		self.ab_blackscreen2 setShader( "black", 640, 480 );	
		self.ab_blackscreen2.alpha = 0;		
	}
	self.ab_blackscreen fadeOverTime(1);
	self.ab_blackscreen.alpha = 1;
	self.ab_blackscreen2 fadeOverTime(1);
	self.ab_blackscreen2.alpha = 1;
}

spawn_model_damage()
{
	level endon( "game_ended" );
	self endon( "death" );
	
	while( isDefined( self ) )
	{
		self waittill( "dmg_spawn_model", dmg, attacker );
		
		// reduce the player's health
		self.health -= dmg;
		self.owner.health -= dmg;
		
		// send the player some feedback
		if( isdefined( attacker ) )
			attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( false );
		
		if( self.health <= 0 )
			break;
	}
}