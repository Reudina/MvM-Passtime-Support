# MvM-Passtime-Support
Remade Passtime To Allow Spawning Of The Passtime Ball In MVM Missions (Without Crashing)

# Requirements
Custom models included with the Download are required.

# How To Use
Simply add, via Hammer, PointTemplates(Rafmod) or VScript, A "Info_Passtime_Ball_Spawn" to the map.  
The Info_Passtime_Ball_Spawn requires 3 KeyValues to function:  
. A Targetname of "IPBSSpawn"  
. A TeamNum Of 2 or 3 depending on if its for a regular mission or a reverse one.  
. An Origin  
 
For best results, place at a height of -60HU off the ground and above a flat surface.  
(Not Required to function, but helps prevent bugs)  

Load the VScript like you would any other VScript With:  
    InitWaveOutput  
    {  
        Target BigNet  
        Action RunScriptCode  
        param "IncludeScript(`passtime_ball_thing.nut`, getroottable())"  
    }  
///////////////////////////////////////////////////////////////  
Currently requires wave reload to function if it is the first time being run on a map, plan to fix at a later date.  
