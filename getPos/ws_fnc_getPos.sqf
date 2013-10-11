// GetPos function
// v2 (15.09.2013)
// By Wolfenswan [FA]: wolfenswanarps@gmail.com | folkarps.com
// Thanks to Shuko for SHK_pos
//
// FEATURE
// Turn input into legit positional array [x,y,z], returns array
// For a more powerful getPos script look up SHK_pos by Shuko
//
// USAGE
// Minimal:
// [location] call ws_fnc_getPos;
// Full:
// [location,radius (int or true), minDistance,angle,road (bool), building allowed (bool), water allowed (bool)] call ws_fnc_getPos;
//
// OUTPUT
// Array: [x,y,z]
//
// PARAMETERS
// 1. location can be String (Markername), Array [x,y,z] or Objectname														| MANDATORY
// 2. radius has to be int > 0 and defines the radius around the position. If set to true it will instead return a position inside a trigger/marker passed in the 1. parameter	| OPTIONAL - default is 0
// 3. minimal distance from center, has to be int > 0 and > radius		 													| OPTIONAL - default is 0
// 4. Minimal and maximal angle from center. Array: [minAngle,maxAngle] with both values being integers from 0- 360							| OPTIONAL - default is [0,360]
// 5. road (bool) forces pos to be placed on road 																	| OPTIONAL - default is false
// 6. building allowed (bool) enables the position to be in/on a building														| OPTIONAL - default is false
// 7. water allowed (bool) enables the position to be on water as well														| OPTIONAL - default is false
//
// EXAMPLES
// ["spawnmarker"] call ws_fnc_getPos; - turns the marker location into a position array
// ["spawnmarker",0,0,[0,360],true] call ws_fnc_getPos; - gets a position on a road in closest possible distance to the marker location
// [church,250] call ws_fnc_getPos; - gets a position in 250m radius to the object named "church"
// [v1,500,100,[0,180],false,true] call ws_fnc_getPos; - gets a position in 500m radius, 100m minimal distance and a 180° angle to the object named "v1" and also allows position // to be on a building
//
// TODO
// check if marker is area, if yes place pos within

private ["_debug","_count","_posloc","_pos","_posradius","_mindis","_dir","_road","_building","_water","_posX","_posY"];

_debug = false; if !(isNil "ws_debug") then {_debug = ws_debug};   //Debug mode. If ws_debug is globally defined it overrides _debug

//Declaring variables
_count = count _this;
_posloc = _this select 0;
_pos = [0,0,0];
_posradius = 0;
_mindis = 0;
_dir = random 360;
_road = false;
_building = false;
_water = false;

//Optional variables parsed
if (_count > 1) then {_posradius = _this select 1;};
if (_count > 2) then {_mindis = _this select 2;};
if (_count > 3) then {_dir = random (_this select 3)};
if (_count > 4) then {_road = _this select 4;};
if (_count > 5) then {_building = _this select 5;};
if (_count > 6) then {_water = _this select 6;};

//Interpreting variables

//Getting a good position from the parsed values
switch (typename _posloc) do {
	case "STRING": {_pos = getMarkerPos _posloc;};
	case "OBJECT": {_pos = getPos _posloc;};
	case "ARRAY": {_pos = _posloc};
	default {[_posloc,["ARRAY","OBJECT","STRING"],"ws_fnc_getPos"] call ws_fnc_typecheck;};
};

_posX = (_pos select 0);
_posY = (_pos select 1);
_pos set [2,0];

//Fault checks
//Checking the variables we have against what we should have
{[_x,["ARRAY"],"ws_fnc_getPos"] call ws_fnc_typecheck;}  forEach [_pos];
[_posradius,["SCALAR","BOOLEAN"],"ws_fnc_getPos"] call ws_fnc_typecheck;
{[_x,["SCALAR"],"ws_fnc_getPos"] call ws_fnc_typecheck;} forEach [_mindis,_dir,_posX,_posY];
{[_x,["BOOL"],"ws_fnc_getPos"] call ws_fnc_typecheck;} forEach [_road,_water];

switch (typename _posradius) do {
	case "SALAR": {
		if (_mindis > _posradius) then {_mindis = _posradius * 2};

		if (_posradius > 0) then {
		_newX = _posX + ((random _posradius) * sin _dir);
		_newY = _posY + ((random _posradius) * cos _dir);
		_pos = [_newX,_newY,0];
		};
	};
	case "BOOL": {
	_pos = [_posloc] call ws_fnc_getPosInArea;
	};
};

if (_mindis > 0) then {
	while {_pos distance _posloc < _mindis} do {
		_newX = _posX + ((random _posradius) * sin _dir);
		_newY = _posY + ((random _posradius) * cos _dir);
		_pos = [_newX,_newY,0];
	};
};


//If the position has to be on dry land
if (!_water && (surfaceIsWater _pos)) then {
	_pos = [_pos] call ws_fnc_NearestLandPos;
};

//If building positions are disallowed
if (!_building && (count (_pos nearObjects ["House",10]) >= 1)) then {
	player sidechat "2";
	_i = 0;
	_distance = 0;
	_done = false;
	while {!_done && _i <= 50} do {
		for "_x" from 0 to 340 step 20 do {
			_distance = _distance + 50;
			_pos set [0,_posX + (_distance * sin _x)];
			_pos set [1,_posY + (_distance * cos _x)];
			if !(count (_pos nearObjects ["House",10]) >= 1) exitWith {_done = true};
		};
		_i = _i + 1;
	};
};

//If the position is supposed to be on a road
if (_road) then {
	_pos = [_pos] call ws_fnc_NearestRoadPos;
};

if (_debug) then {
player globalchat format ["DEBUG: ws_fnc_getPos done. Pos is %1, direction is %2",_pos,_dir];
  _mkr = createMarker [format ["%1",_pos], _pos];
  _mkr setMarkerType "mil_dot";
  _mkr setMarkerColor "ColorGreen";
  _mkr setMarkerSize [0.5,0.5];
};

//Return the new position
_pos