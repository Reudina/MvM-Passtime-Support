////////////////////////////////////////////////////////////////////
//			My Descent into madness as i remake Passtime		  //
////////////////////////////////////////////////////////////////////
printl(__FILE__ + " has loaded");
////////////////////////////////////////////////////////////////////

//Globals
::ROOT <- getroottable()
::PlayerManager <- Entities.FindByClassname(null, "tf_player_manager")
::GetPlayerUserID <- function(player){return NetProps.GetPropIntArray(PlayerManager, "m_iUserID", player.entindex())}
::ErrorHeader <- "\x07FF3F3F //////////" + __FILE__ + "////////// \n"

::PasstimeSupport <- 
{
    Cleanup = function()
    {
        // cleanup any persistent changes here
        
        // keep this at the end
        delete ::PasstimeSupport
    }
    
    OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
    OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }
    
    
	///////////////////////////////////////////////////////////////////////
	//////////////////   Pre Game Setup ///////////////////////////////////
	//////////////////////////////////////////////////////////////////////
	firsttime 				= true
	arewegood				= false
	HolderID 				= null
	defaultbombspawn	 	= Vector(0, 0, 0)
	ptbteamcolour 			= 0
	ptbtc_as_str			= "0, 0, 0, 0"
	ptbombholder 			= null

	function ResetValues() //reset any values that would fuck up things if not reset
	{
		arewegood				= false
		HolderID 				= null
		defaultbombspawn	 	= Vector(0, 0, 0)
		ptbteamcolour 			= 0
		ptbtc_as_str			= "0, 0, 0, 0"
		ptbombholder 			= null
		AddThinkToEnt(ptbombholder, "null")
		
	}

	function InitiateSpawn() //spawnBall. Spawns tf_glow if first time being run.
	{
		ResetValues()
		CheckForPTBSpawn()
		if (arewegood == true)
		{
			if(firsttime == true)
			{
				firsttime = false
				SpawnKeyLogic(ptbtc_as_str)
				SpawnPTBomb(defaultbombspawn, ptbteamcolour, ptbtc_as_str)
			}
			else{SpawnPTBomb(defaultbombspawn, ptbteamcolour, ptbtc_as_str)}
		}
	}

	function CheckForPTBSpawn() // Ensure that a valid "Info_Passtime_ball_Spawn" exists
	{
		local validptbspawn = Entities.FindByName(null, "ipbsspawn*")
		local enabledptbspawn = NetProps.GetPropInt(validptbspawn, "m_bDisabled")
		if (validptbspawn && validptbspawn.GetClassname() == "info_passtime_ball_spawn")
		{
			if (enabledptbspawn == 0)
			{
				defaultbombspawn = validptbspawn.GetOrigin()
				ptbteamcolour	 = validptbspawn.GetTeam()
				if(ptbteamcolour == 3){ptbtc_as_str = "125 168 196 255"}
				else if(ptbteamcolour == 2){ptbtc_as_str = "189 59 59 255"}
				else{ptbtc_as_str = "0, 0, 0, 0"}
				arewegood		 = true
			}
			else {ClientPrint(null, 3, ErrorHeader + "\x07FF3F3F Found Valid 'Info_Passtime_Ball_Spawn', But It's Not Enabled")}

		}
		else{ClientPrint(null, 3, ErrorHeader + "\x07FF3F3F Failed To Find Valid 'Info_Passtime_Ball_Spawn'")}
	}
	
	function SpawnPTBomb(ptbspawn_pos, ptb_team, ptb_lockcol) //Spawn the PTBomb
	{

		::PTS_PTBall <- SpawnEntityFromTable("passtime_ball",
		{
			targetname	= "ptbomb"
			Origin 		= ptbspawn_pos
			TeamNum 	= ptb_team
		})

		::PTS_PTTrigger <- SpawnEntityFromTable("trigger_multiple",
		{
			targetname 	= "ptbombtrigger"
			Origin 		= ptbspawn_pos
			spawnflags	= 1
			StartDisabled = true

			"OnStartTouch#1" : "!selfRunScriptCodePasstimeSupport.TestForValidCarrier()-1-1"
		})

		::PTS_Reticle_1 <- SpawnEntityFromTable("env_sprite_oriented",
		{
			targetname 	= "reticle1"
			model 		= "passtime/hud/passtime_ball_reticle_piece_1.vmt"
			spawnflags  = 1
			origin 		= ptbspawn_pos
			scale 		= 0.00001
			rendercolor = ptb_lockcol
		})

		::PTS_Reticle_2 <- SpawnEntityFromTable("env_sprite_oriented",
		{
			targetname 	= "reticle2"
			model 		= "passtime/hud/passtime_ball_reticle_piece_2.vmt"
			spawnflags  = 1
			origin 		= ptbspawn_pos
			scale 		= 0.00001
			rendercolor = ptb_lockcol
		})

		PTS_PTTrigger.AcceptInput("SetParent", "ptbomb", "", null)
		EntFireByHandle(PTS_PTTrigger, "Enable", "", 0.5, null, null)
		PTS_PTTrigger.SetSize(Vector(-25,-25,-25), Vector(25,25,25))
		PTS_PTTrigger.SetSolid(2)

		AddThinkToEnt(PTS_Reticle_1, "PTSFollowBomb")
		AddThinkToEnt(PTS_Reticle_2, "PTSFollowBomb")

		NetProps.SetPropEntity(PTS_PTBall_Glow, "m_hTarget", PTS_PTBall)

		function PTSFollowBomb()
		{
			PTS_Reticle_1.KeyValueFromVector("origin", PTS_PTBall.GetCenter())
			PTS_Reticle_2.KeyValueFromVector("origin", PTS_PTBall.GetCenter())

			local currentangles1 = PTS_Reticle_1.GetLocalAngles()
			PTS_Reticle_1.SetLocalAngles(currentangles1 + QAngle(1, 1, 1))

			local currentangles2 = PTS_Reticle_2.GetLocalAngles()
			PTS_Reticle_2.SetLocalAngles(currentangles2 + QAngle(1, 1, 1))

			return -1
		}
	}

	function SpawnKeyLogic(glowcol) //spawn a tf_glow
	{
		::PTS_PTBall_Glow <- SpawnEntityFromTable("tf_glow",
		{
			targetname = "ptbombglow"
			target = "bignet"
			GlowColor = glowcol
		})
	}
	function GivePlayerPTS_PTBall_Weapon(player, className, itemID) // PTBall weapon
	{
		::PTS_PTBall_Weapon <- Entities.CreateByClassname(className)
		NetProps.SetPropInt(PTS_PTBall_Weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", itemID)
		NetProps.SetPropBool(PTS_PTBall_Weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
		NetProps.SetPropBool(PTS_PTBall_Weapon, "m_bValidatedAttachedEntity", true)
		PTS_PTBall_Weapon.SetTeam(player.GetTeam())
		PTS_PTBall_Weapon.DispatchSpawn()
		
		player.Weapon_Equip(PTS_PTBall_Weapon)
		player.Weapon_Switch(PTS_PTBall_Weapon)
		
		return PTS_PTBall_Weapon
	}
	//////////////////////////////////////////////////////////////////////////
	////////////////		Post Bomb Pickup                //////////////////
	//////////////////////////////////////////////////////////////////////////

	function TestForValidCarrier()
	{
		local probablytheholder = Entities.FindByClassnameNearest("player", PTS_PTBall.GetCenter(), 100)

		if (probablytheholder.IsBotOfType(1337) == false)
		{
			if(probablytheholder.GetTeam() == ptbteamcolour)
			{
				if (probablytheholder.IsStealthed() == false)
				{
					ptbombholder = probablytheholder
					EquipPTBall()
				}
			}
		}
	}

	DropPTBall = function(isthrow) // drop bomb
	{
		HolderID = null
		local previousheldwep = NetProps.GetPropEntityArray(ptbombholder, "m_hMyWeapons", 0)
		local dropatholder = ptbombholder.EyePosition()
		local ispartofthrow = isthrow
		AddThinkToEnt(ptbombholder, "null")
		PTS_PTBall_Weapon.AcceptInput("kill", "", null, null)
		ptbombholder.AddCustomAttribute("disable weapon switch", 0, -1 )
		ptbombholder.AddCustomAttribute("no_attack", 0, -1 )
		ptbombholder.AddCustomAttribute("cannot disguise", 0, -1 )
		ptbombholder.Weapon_Switch(previousheldwep)
		PasstimeSupport.SpawnPTBomb(dropatholder, ptbteamcolour, ptbtc_as_str)
		NetProps.SetPropEntity(PTS_PTBall_Glow, "m_hTarget", PTS_PTBall)

		if(ispartofthrow == true){PasstimeSupport.ThrowPTBall()}
		else
		{
			ClientPrint(null, 3, "\x07dcc037" + NetProps.GetPropString(ptbombholder, "m_szNetname") + " Has \x07FF3F3F Dropped \x07dcc037 The Bomb")
			ptbombholder = null
		}
	}

	function EquipPTBall() //equip bomb
	{
		KillPTBall()
		HolderID = GetPlayerUserID(ptbombholder)
		NetProps.SetPropEntity(PTS_PTBall_Glow, "m_hTarget", ptbombholder)
		GivePlayerPTS_PTBall_Weapon(ptbombholder, "tf_weapon_grapplinghook", 1152)
		ptbombholder.AddCustomAttribute("disable weapon switch", 1, -1 )
		ptbombholder.AddCustomAttribute("no_attack", 1, -1 )
		ptbombholder.AddCustomAttribute("cannot disguise", 1, -1 )	
		ptbombholder.ValidateScriptScope()
		ptbombholder.GetScriptScope().buttons_last <- 0
		local BombHolderScope = ptbombholder.GetScriptScope()
		AddThinkToEnt(ptbombholder, "HolderInputThink")
		BombHolderScope.HolderInputThink <- HolderInputThink
		ClientPrint(null, 3, "\x07dcc037" + NetProps.GetPropString(ptbombholder, "m_szNetname") + " Has \x04 Picked Up \x07dcc037 The Bomb")
	}

	function HolderInputThink()	// read buttons
	{
		local buttons = NetProps.GetPropInt(self, "m_nButtons")
		local buttons_changed = buttons_last ^ buttons
		local buttons_pressed = buttons_changed & buttons
		local buttons_released = buttons_changed & (~buttons)

		if (buttons_pressed & Constants.FButtons.IN_RELOAD){PasstimeSupport.DropPTBall(false)}
		if (buttons_released & Constants.FButtons.IN_ATTACK){PasstimeSupport.DropPTBall(true)}
		
		buttons_last = buttons
		return -1
	}

	function ThrowPTBall() //throw bomb
	{
		local throwereyeangles 	= ptbombholder.EyeAngles()
		local throwerforward 	= throwereyeangles.Forward()
		local howfardoithrow	=  throwerforward * 900
		PTS_PTBall.SetPhysVelocity(howfardoithrow)
		ClientPrint(null, 3, "\x07dcc037" + NetProps.GetPropString(ptbombholder, "m_szNetname") + " Has \x04 Thrown \x07dcc037 The Bomb")
		ptbombholder = null
	}

	//////////////////////////////////////////////////////////////////////////
	////////////////		Game Events And Triggers        //////////////////
	/////////////////////////////////////////////////////////////////////////
	function KillPTBall() //generic function to kill the bomb and associeted
	{
		if(PTS_PTBall.IsValid())
		{
			AddThinkToEnt(PTS_Reticle_1, "null")
			AddThinkToEnt(PTS_Reticle_2, "null")
			PTS_Reticle_1.Destroy()
			PTS_Reticle_2.Destroy()
			PTS_PTBall.Destroy()
		}
	}

	function PTBHitTarget() //kills and respawns bomb. call this function when detonating bomb.
	{
		SpawnEntityFromTable("tf_generic_bomb",
		{
			targetname = "targetdetonate"
			Origin = PTS_PTBall.GetOrigin()
			damage = 100
			radius = 50
			health = 1
			explode_particle = "rd_robot_explosion"
			sound = "weapons/loose_cannon_explode.wav"
			friendlyfire = 1
		})
		DoEntFire("targetdetonate", "Detonate", "", 0, null, null)
		ReSpawnPTBomb()
	}

	function ReSpawnPTBomb() //called manually or if a bomb explodes(hits target or out of bounds)
	{
		CheckForPTBSpawn()
		KillPTBall()
		SpawnPTBomb(defaultbombspawn, ptbteamcolour, ptbtc_as_str)
	}
	
	function OnGameEvent_player_death(params) //drop bomb on holder death
	{
		if (params.userid == GetPlayerUserID(ptbombholder))
		{
			if (params.death_flags & 32){}
			else{DropPTBall(false)}
		}
		else{}
	}

	function OnGameEvent_player_disconnect(params) // drop bomb on player disconnect
	{
		if (params.userid == HolderID){DropPTBall(false)}
	}

	function OnGameEvent_mvm_wave_complete(params){KillPTBall()}
	function OnGameEvent_mvm_wave_Failed(params){KillPTBall()}
	function OnGameEvent_teamplay_round_win(params){KillPTBall()}
};

__CollectGameEventCallbacks(PasstimeSupport)