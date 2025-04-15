# MvM-Passtime-Support
Re-Made Fundamental Aspects Of The Passtime_Ball Entity with VScript To Allow It To Function In MvM Missions (Without Crashing)

#Bugs  
.disconnecting with the ball breaks everything  
.reseting the wave while the ball is held dosent remove the required thinks  

# How To Use
Simply add, via Hammer, PointTemplates(Rafmod) or VScript, An "Info_Passtime_Ball_Spawn" to the map.  

The Info_Passtime_Ball_Spawn requires 3 KeyValues to function:  
. A Targetname of "ipbsspawn"  (suffixs Supported If You Need Multiple Ball Spawns. (Only Ever Have One Active At A Time)  
. A TeamNum Of 2 or 3 (2 For Red, 3 For Blu)  
. An Origin  (For best results, place at a height of -60HU off the ground and above a flat surface.)  
 
Load the VScript like you would any other VScript With:  
    `InitWaveOutput`   
    `{`  
        `Target BigNet`    
        `Action RunScriptCode`    
        `param "IncludeScript(``passtime_ball_thing.nut``, getroottable())"`    
    `}`   
 *Only required in 1 wave    

 Below Functions can be called with `DoEntFire`  
 Eg. `DoEntFire(``worldspawn``, ``RunScriptCode``, ``InitiateSpawn()``, 0, null, null)`
///////////////////////////////////////////////////////////////  

# Important Functions  
--- `InitiateSpawn()` ---  
: Call This To Spawn The Bomb

--- `PTBHitTarget()` ---     
: Call This To Detonate The Bomb And Respawn It.    

--- `RespawnPTBomb()` ---  
: Same As Above But Dosent Cause The Bomb To Explode.
  
--- `dropptbomb(false)` ---   
: Call This With The (false) Param To Cause Holder To Drop The Ball.    

--- `dropptbomb(true)` ---   
: Call This With The (True) Param To Cause Holder To Throw The Ball.    
