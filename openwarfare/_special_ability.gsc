#include openwarfare\_eventmanager;
#include maps\mp\_utility;
#include openwarfare\_utils;

init()
{
	
	level.scr_tactical_insert_allow_damage = getdvarx( "scr_tactical_insert_allow_damage", "int", 1, 0, 1 );
	level.scr_tactical_insert_debug = getdvarx( "scr_tactical_insert_debug", "int", 0, 0, 1 );
	
	precacheModel( "model_russian_crouch_efaya" );
	precacheModel( "model_usmc_crouch_efaya" );
	precacheModel("vm_rccar_efaya");

	level thread addNewEvent( "onPlayerConnected", ::onPlayerConnected );
}

onPlayerConnected()
{
	self.insertion_marker = undefined;
	self.marker_fx = [];
	
	self thread addNewEvent( "onPlayerSpawned", ::onPlayerSpawned );
	self thread addNewEvent( "onPlayerKilled", ::onPlayerKilled );
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
		
		self.insertion_marker delete();

		if (isdefined(self.use_marker) && isdefined(self.insertion_marker) && self.using_marker == true) {
			if ( isDefined( self.spawn_model ) ) {		
				self.spawn_model delete();
			}			
			self unlink();	
			visionSetNaked( getDvar( "mapname" ), 0 );	
		}
	}
	if( isDefined( self.using_mobile_drone ) ) {
		self.using_mobile_drone = false;
		self setPerk( "specialty_tactical_insertion" );
		self ShowAllParts();
		visionSetNaked( getDvar( "mapname" ), 0 );		
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
	self CleanUpMarker();
}

onJoinedSpectators()
{
	self CleanUpMarker();
}

onPlayerKilled()
{
	self CleanUpMarker();
}

onDisconnected()
{
	self waittill("disconnect");
	
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
      grenade.collision.health = 25;
      grenade.collision thread insertion_damage();
      grenade.collision thread MonitorForDamage("dmg");
      self.insertion_marker.visual.sold = grenade.collision;
   }
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
		
		// reduce the camera's health
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
		
		// destroy camera if no health is left
		if( self.health <= 0 )
		//self playSound ( "tactical_insert_destroyed" );
			break;
	}
	
	if( isdefined( self.owner ) ) {
		ClientPrint(self, "tactical_insert_destroyed");	
		self playSound ( "tactical_insert_destroyed" );
		self.owner thread CleanUpMarker();
	}
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
		self tactical_cam();
	} else if (self.pers["team"] == "axis") {
		self mobile_drone();
	}
}

mobile_drone() {
	if (isdefined(self.mobile_drone_destroyed)) {
		ClientPrint(self, "Your mobile tactical drone has been destroyed.");
		return;
	}
	if ( !isdefined(self.using_mobile_drone) || (self.using_mobile_drone == false && !isdefined(self.spawn_waiting_model))) {
		// Spawn mobile drone
		self freezeControls( true );	
		self.using_mobile_drone = self getOrigin();	
		self goBlack();
		self disableWeapons();
		wait(1.5);
		self spawnCrouchModel(self.using_mobile_drone);
		self detachHead();
		self detachAll();
		self setModel("vm_rccar_efaya");
		self unlink();
		self setOrigin(self.using_mobile_drone + (50,0,5));
		self setClientDvars(
			"cg_thirdPerson", 1,
			"cg_thirdPersonRange", 70,
			"cg_footsteps", 0
		);
		wait(0.5);
		visionSetNaked( "mpIntro", 0 );
		self.ab_blackscreen destroy();
		self.ab_blackscreen2 destroy();
		self freezeControls( false );			
		ClientPrint(self, "Currently using mobile tactical drone...");
	} else if (isdefined(self.mobile_drone_pos) && isDefined( self.spawn_waiting_model )) {
		// Join mobile drone
		self freezeControls( true );	
		self.using_mobile_drone = self getOrigin();	
		self goBlack();
		self disableWeapons();
		wait(1.5);
		self.spawn_waiting_model delete();
		self.spawn_waiting_model_collision delete();
		self spawnCrouchModel(self.using_mobile_drone);
		self detachHead();
		self detachAll();
		self setModel("vm_rccar_efaya");
		self unlink();
		self setOrigin(self.mobile_drone_pos);
		self setClientDvars(
			"cg_thirdPerson", 1,
			"cg_thirdPersonRange", 70,
			"cg_footsteps", 0
		);
		wait(0.5);
		visionSetNaked( "mpIntro", 0 );
		self.ab_blackscreen destroy();
		self.ab_blackscreen2 destroy();
		self freezeControls( false );			
		ClientPrint(self, "Currently using mobile tactical drone...");
	} else {
		// Quit mobile drone
		self freezeControls( true );	
		self goBlack();		
		wait(1.5);
		if ( isDefined( self.spawn_model ) ) {		
			self.spawn_model delete();
			self.spawn_model_collision delete();
		}
		self setClientDvars(
			"cg_thirdPerson", 0,
			"cg_footsteps", 1
		);
		self.mobile_drone_pos = self getOrigin();
		self unlink();
		self setOrigin(self.using_mobile_drone + (0,0,5));
		self maps\mp\gametypes\_teams::playerModelForClass( self.pers["class"] );
		self ShowAllParts();
		// Spawn waiting drone
		self.spawn_waiting_model = spawn( "script_model", self.mobile_drone_pos );
		self.spawn_waiting_model setModel("vm_rccar_efaya");
		self.spawn_waiting_model setContents( 1 );
		self.spawn_waiting_model_collision = spawn( "trigger_radius", self.mobile_drone_pos, 0, 30, 25 );
		self.spawn_waiting_model_collision.owner = self;
		self.spawn_waiting_model_collision.health = 25;
		self.spawn_waiting_model_collision setContents( 1 );
		self.spawn_waiting_model_collision thread spawn_model_damage("dmg_spawn_mobile_model", false);
		self.spawn_waiting_model_collision thread MonitorForDamage("dmg_spawn_mobile_model");

		wait(0.5);
		visionSetNaked( getDvar( "mapname" ), 0 );		
		self.ab_blackscreen destroy();
		self.ab_blackscreen2 destroy();
		self freezeControls( false );
		self enableWeapons();		
		self.using_mobile_drone = false;					
	}
}

detachHead()
{
	// Get all the attached models from the player
	attachedModels = self getAttachSize();
	
	// Check which one is the head and detach it
	for ( am=0; am < attachedModels; am++ ) {
		thisModel = self getAttachModelName( am );
		
		// Check if this one is the head and remove it
		if ( isSubstr( thisModel, "head_mp_" ) ) {
			self detach( thisModel, "" );
			break;
		}		
	}
	
	return;
}

tactical_cam() {
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
		
		self spawnCrouchModel(self.use_marker);
		
		wait(0.5);
		visionSetNaked( "mpIntro", 0 );
		self.ab_blackscreen destroy();
		self.ab_blackscreen2 destroy();
		self freezeControls( false );

		self.using_marker = true;		
		ClientPrint(self, "Currently watching through tactical cam...");
		self linkTo( self.insertion_marker );
	} else if (isdefined(self.use_marker) && isdefined(self.insertion_marker) && self.insertion_marker.team == self.pers["team"] && isdefined(self.using_marker) && self.using_marker == true) {
		self.using_marker = false;	
		self freezeControls( true );
		self goBlack();
		wait(1);
		if ( isDefined( self.spawn_model ) ) {		
			self.spawn_model delete();
			self.spawn_model_collision delete();
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
}

spawnCrouchModel(marker) {
	// Spawn fake player model			
	self.spawn_model = spawn( "script_model", marker );
	if (self.pers["team"] == "axis") {
		self.spawn_model setModel("model_russian_crouch_efaya");
	} else {
		self.spawn_model setModel("model_usmc_crouch_efaya");
	}
	self.spawn_model setContents( 1 );
	self.spawn_model setplayerangles(self getplayerangles());
	self.spawn_model_collision = spawn( "trigger_radius", self.origin, 0, 30, 45 );
	self.spawn_model_collision.owner = self;
	self.spawn_model_collision.health = self.health;
	self.spawn_model_collision setContents( 1 );
	self.spawn_model_collision thread spawn_model_damage("dmg_spawn_model", true);
	self.spawn_model_collision thread MonitorForDamage("dmg_spawn_model");
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

spawn_model_damage(trigger, selfDamaged)
{
	level endon( "game_ended" );
	self endon( "death" );
	
	while( isDefined( self ) )
	{
		self waittill( trigger, dmg, attacker );
		
		self.health -= dmg;
		// reduce the player's health
		if (selfDamaged) {
			self.owner.health -= dmg;
		}
		
		// send the player some feedback
		if( isdefined( attacker ) )
			attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( false );
		
		if( self.health <= 0 )
			break;
	}

	if (self.owner && isDefined(self.owner.spawn_waiting_model)) {
		self.owner.spawn_waiting_model delete();
		self.owner.spawn_waiting_model_collision delete();
	}
}