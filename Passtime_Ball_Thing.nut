////////////////////////////////////////////////////////////////////
//			My Descent into madness as i remake					  //
//					the Passtime logic							  //
////////////////////////////////////////////////////////////////////
printl(__FILE__ + " has loaded");
////////////////////////////////////////////////////////////////////
PrecacheModel("materials/passtime/hud/passtime_ball_reticle_passlock_custom.vmt")
PrecacheModel("materials/passtime/hud/passtime_ball_reticle_piece_1_custom.vmt")

//globals
::PlayerManager <- Entities.FindByClassname(null, "tf_player_manager")
::GetPlayerUserID <- function(player){return NetProps.GetPropIntArray(PlayerManager, "m_iUserID", player.entindex())}

///////////////////////////////////////////////////////////////////////
//////////////////   Pre Game Setup ///////////////////////////////////
//////////////////////////////////////////////////////////////////////
function resetvalues()  //failsafe to reset any values that would fuck up things if not reset
{
	::ptbombholder		<- null
	::defaultbombspawn 	<- Vector(0, 0, 0)
	::ptbteamcolour		<- 0
	::ptbtc_as_str		<- "0, 0, 0, 0"
	::arewegood			<- false
}

function OnGameEvent_teamplay_round_start(params) // call functions on round start
{
	resetvalues()
	checkforptbspawn()
	
	if (arewegood == true)
	{
		spawnptbomb(defaultbombspawn, ptbteamcolour, ptbtc_as_str)	
		spawnkeylogic(ptbtc_as_str)
	}	
}

function checkforptbspawn() // Ensure that a valid "Info_Passtime_ball_Spawn" exists
{
	local validptbspawn = Entities.FindByName(null, "ipbsspawn")
	if (validptbspawn) 
	{
		defaultbombspawn = validptbspawn.GetOrigin() 
		ptbteamcolour	 = validptbspawn.GetTeam()
		if(ptbteamcolour == 3){ptbtc_as_str = "151, 200, 249, 255"}
		else if(ptbteamcolour == 2){ptbtc_as_str = "249, 61, 61, 255"}
		else{ptbtc_as_str = "0, 0, 0, 0"}
		arewegood		 = true
	}

	else{ClientPrint(null, 3, "\x07FF3F3F Failed To Find Valid 'Info_Passtime_Ball_Spawn'")}
}

function spawnptbomb(ptbspawn_pos, ptb_team, ptb_lockcol) //Spawn the PTBomb
{
	::psuedo_passtime_bomb <- SpawnEntityFromTable("passtime_ball", 
	{
		targetname	= "ptbomb"
		Origin 		= ptbspawn_pos
		TeamNum 	= ptb_team
	})

	local passtime_bomb_trigger = SpawnEntityFromTable("trigger_Multiple"
	{
		targetname 	= "ptbombtrigger"
		Origin 		= ptbspawn_pos
		spawnflags	= 1
		StartDisabled = true
		
		
		"OnSTartTouch#1" : "!activatorCallScriptFunctiontestforvalidcarrier-1-1"
	})

	::passtime_bomb_reti1 <- SpawnEntityFromTable("env_sprite_oriented"
	{
		targetname 	= "reticle1"
		model 		= "passtime/hud/passtime_ball_reticle_piece_1.vmt"
		spawnflags  = 1
		origin 		= ptbspawn_pos
		scale 		= 0.00001
		rendercolor = ptb_lockcol
	})

	::passtime_bomb_reti2 <- SpawnEntityFromTable("env_sprite_oriented"
	{
		targetname 	= "reticle2"
		model 		= "passtime/hud/passtime_ball_reticle_piece_2.vmt"
		spawnflags  = 1
		origin 		= ptbspawn_pos
		scale 		= 0.00001
		rendercolor = ptb_lockcol
	})

	passtime_bomb_trigger.AcceptInput("SetParent", "ptbomb", "", null)
	EntFireByHandle(passtime_bomb_trigger, "Enable", "", 2, null, null)
	passtime_bomb_trigger.SetSize(Vector(-25,-25,-25), Vector(25,25,25))
	passtime_bomb_trigger.SetSolid(2)

	AddThinkToEnt(passtime_bomb_reti1, "followbomb")
	AddThinkToEnt(passtime_bomb_reti2, "followbomb")

	function followbomb()
	{
		passtime_bomb_reti1.KeyValueFromVector("origin", psuedo_passtime_bomb.GetCenter())
		passtime_bomb_reti2.KeyValueFromVector("origin", psuedo_passtime_bomb.GetCenter())

		local currentangles1 = passtime_bomb_reti1.GetLocalAngles()
		passtime_bomb_reti1.SetLocalAngles(currentangles1 + QAngle(1, 1, 1))

		local currentangles2 = passtime_bomb_reti2.GetLocalAngles()
		passtime_bomb_reti2.SetLocalAngles(currentangles2 + QAngle(1, 1, 1))

		return -1
	}
}

function spawnkeylogic(glowcol) //spawn a tf_glow
{
	::passtime_bomb_glow <- SpawnEntityFromTable("tf_glow" 
	{
		targetname = "ptbombglow"
		target = "ptbomb"
		GlowColor = glowcol
	})
}

::GivePlayerPTBallWeapon <- function(player, className, itemID) // PTBall weapon
{
    ::ptballweapon <- Entities.CreateByClassname(className)
    NetProps.SetPropInt(ptballweapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", itemID)
    NetProps.SetPropBool(ptballweapon, "m_AttributeManager.m_Item.m_bInitialized", true)
    NetProps.SetPropBool(ptballweapon, "m_bValidatedAttachedEntity", true)
    ptballweapon.SetTeam(player.GetTeam())
    ptballweapon.DispatchSpawn()
    	
    player.Weapon_Equip(ptballweapon)
    player.Weapon_Switch(ptballweapon)

    return ptballweapon
}

//////////////////////////////////////////////////////////////////////////
////////////////		Post Bomb Pickup                //////////////////
/////////////////////////////////////////////////////////////////////////
function testforvalidcarrier()  //ensure carrier can pick up bomb
{
	local probablytheholder = Entities.FindByClassnameNearest("player", psuedo_passtime_bomb.GetCenter(), 100)
	
	if(probablytheholder.GetTeam() == ptbteamcolour)
	{
		if (probablytheholder.IsStealthed() == false) 
		{
			ptbombholder = probablytheholder
			equipptbomb()
		}
	}
}

function equipptbomb() //equip bomb
{
	passtime_bomb_reti1.Destroy()
	passtime_bomb_reti2.Destroy()
	DoEntFire("ptbomb", "kill", "", -1, null, null)
	
	NetProps.SetPropEntity(passtime_bomb_glow, "m_hTarget", ptbombholder)
	GivePlayerPTBallWeapon(ptbombholder, "tf_weapon_grapplinghook", 1152)
	ptbombholder.AddCustomAttribute("disable weapon switch", 1, -1 )
	ptbombholder.AddCustomAttribute("no_attack", 1, -1 )
	ptbombholder.AddCustomAttribute("cannot disguise", 1, -1 )

	
	ptbombholder.ValidateScriptScope()
	ptbombholder.GetScriptScope().buttons_last <- 0
	AddThinkToEnt(ptbombholder, "holderinputthink")
	
	ClientPrint(null, 3, "\x07dcc037" + NetProps.GetPropString(ptbombholder, "m_szNetname") + " Has \x04 Picked Up \x07dcc037 The Bomb")
}

function holderinputthink()	// read buttons
{
	local buttons = NetProps.GetPropInt(self, "m_nButtons")
	local buttons_changed = buttons_last ^ buttons
	local buttons_pressed = buttons_changed & buttons
	local buttons_released = buttons_changed & (~buttons)
	
	if (buttons_pressed & Constants.FButtons.IN_RELOAD){dropptbomb(false)}
	
	if (buttons_pressed & Constants.FButtons.IN_ATTACK){}

	if (buttons_released & Constants.FButtons.IN_ATTACK){dropptbomb(true)}

	if (ptbombholder.IsStealthed() == true){dropptbomb(false)}

	buttons_last = buttons
	return -1
}

function dropptbomb(isthrow) // drop bomb
{
	local previousheldwep = NetProps.GetPropEntityArray(ptbombholder, "m_hMyWeapons", 0)
	local dropatholder = ptbombholder.EyePosition()
	local ispartofthrow = isthrow
	AddThinkToEnt(ptbombholder, "null")
	ptballweapon.Destroy()
	ptbombholder.AddCustomAttribute("disable weapon switch", 0, -1 )
	ptbombholder.AddCustomAttribute("no_attack", 0, -1 )
	ptbombholder.AddCustomAttribute("cannot disguise", 0, -1 )
	ptbombholder.Weapon_Switch(previousheldwep)
	spawnptbomb(dropatholder, ptbteamcolour, ptbtc_as_str)
	NetProps.SetPropEntity(passtime_bomb_glow, "m_hTarget", psuedo_passtime_bomb)

	if(ispartofthrow == true){throwptbomb()}
	else
	{
		ClientPrint(null, 3, "\x07dcc037" + NetProps.GetPropString(ptbombholder, "m_szNetname") + " Has \x07FF3F3F Dropped \x07dcc037 The Bomb")
		ptbombholder = null
	}
}

function throwptbomb() //throw bomb
{
	local throwereyeangles 	= ptbombholder.EyeAngles()
	local throwerforward 	= throwereyeangles.Forward()
	local howfardoithrow	=  throwerforward * 900
	psuedo_passtime_bomb.SetPhysVelocity(howfardoithrow)
	ClientPrint(null, 3, "\x07dcc037" + NetProps.GetPropString(ptbombholder, "m_szNetname") + " Has \x04 Thrown \x07dcc037 The Bomb")
	ptbombholder = null
}

//////////////////////////////////////////////////////////////////////////
////////////////		Game Events And Triggers        //////////////////
/////////////////////////////////////////////////////////////////////////
function OnGameEvent_player_death(params) //drop bomb on holder death
{
	if (params.userid == GetPlayerUserID(ptbombholder))
	{
		if (params.death_flags & 32){}
		else{dropptbomb(false)}
	}
	else{}
}

function OnGameEvent_player_disconnect(params) // drop bomb on player disconnect
{
	if (params.userid == GetPlayerUserID(ptbombholder)){dropptbomb(false)}
	else{}
}

	







__CollectGameEventCallbacks(this)


//////////////////////////////////////////////
/////Scrapped due to too many issues//////////
//////////////////////////////////////////////



// function spawnpasslock()
// {
// 	::ptbombpasslockparent <- SpawnEntityFromTable("info_teleport_destination"
// 	{
// 		targetname = "psupasslockparent"
// 		origin = Vector(0, 0, 0)
// 	})

// 	::ptbombpasslock <- SpawnEntityFromTable("env_sprite_oriented"
// 	{
// 		targetname = "psupasslock"
// 		model 		= "materials/passtime/hud/passtime_ball_reticle_passlock_custom.vmt"
// 		origin		=Vector(-1600,0,-82)
// 		angles 		= Vector(90, 0, 0)
// 		scale 		= 0.00001
// 		spawnflags	= 1
// 	})

// 	::ptbombpasslockcircle <- SpawnEntityFromTable("env_sprite_oriented"
// 	{
// 		targetname = "psupasslockcircle"
// 		model 		= "materials/passtime/hud/passtime_ball_reticle_piece_1_custom.vmt"
// 		origin		= Vector(-1600,0,-82)
// 		angles 		= Vector(90, 0, 0)
// 		scale 		= 0.00001
// 		spawnflags	= 1
// 	})
// 	ptbombpasslock.AcceptInput("SetParent", "psupasslockparent", null, null)
// 	ptbombpasslockcircle.AcceptInput("SetParent", "psupasslock", null, null)

// 	function rotatecircle()
// 	{
// 		local currentrotation = ptbombpasslockcircle.GetAbsAngles()
// 		ptbombpasslockcircle.SetAbsAngles(currentrotation + QAngle(0, 1, 0)) 
		
// 		return -1
// 	}
// 	AddThinkToEnt(ptbombpasslockcircle, "rotatecircle")
// }

//spawnpasslock()

// function bindtoholder()
// {
// 	local holderangles	= ptbombholder.EyeAngles()
// 	local holderorigin	= ptbombholder.EyePosition()
// 	local holderpitch 	= holderangles.Pitch()
// 	local scaleamount	= Vector(holderpitch, 0, 0) * 10

// 	ptbombpasslockparent.SetAbsOrigin(holderorigin)
// 	ptbombpasslock.SetLocalOrigin(Vector(600, 0, -120) - scaleamount)
// 	ptbombpasslockparent.SetAbsAngles(ptbombholder.GetAbsAngles())
	
// 	return -1
// }

//AddThinkToEnt(ptbombpasslockparent, "bindtoholder")
//AddThinkToEnt(ptbombpasslockparent, "null")
		//ptbombpasslockparent.Destroy()

//   velocity = x units per second
// a velocity of 1000 will move 1000 units per second
// At an angle of 0, velocity of 1000 and height of the character (approx -60 z) will travel roughly 370 in its given direction. (x / y)

//Given this:

// angle of   0			= 435 -100
// angle of  90 (89)	= 0
// angle of -90 (-89)	= 0
// angle of -45			= 12000


