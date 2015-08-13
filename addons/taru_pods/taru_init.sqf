/*
	Taru Pod's mod script by Halv - inspired by XENO Taru Pod Mod

	Copyright (C) 2015  Halvhjearne

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

	Contact : halvhjearne@gmail.com
*/

if(isServer)exitWith{
	HALV_fnc_parapod = compileFinal "
		_player = _this select 0;
		_para = _this select 1;
		if(!(isNull _player) && (_para isKindOf 'ParachuteBase' || _para isKindOf 'Pod_Heli_Transport_04_base_F'))then{
			_para call EPOCH_server_setVToken;
		};
	";
	"HALVPV_PARAPOD" addPublicVariableEventHandler {(_this select 1) call HALV_fnc_parapod};
//		diag_log format["[HALV_fnc_parapod]: %1",_this];
};

if(hasInterface && !isDedicated)then{
	HALV_attachTarupods = {
		_heli = _this select 0;
		_pod = _this select 1;
		_action = _this select 2;
		if !(isTouchingGround _heli)exitWith{titleText ["Need to be touching ground to attach a pod ...","PLAIN DOWN"];};
		_heli removeAction _action;
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_up_IN.wss", player];
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_up_OUT.wss", player];
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_up_IN.wss", _heli];
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_up_OUT.wss", _heli];
		_attribs = switch (typeOf _pod)do{
			case "Land_Pod_Heli_Transport_04_bench_F":{[[0,-1,-1.2],680]};
			case "Land_Pod_Heli_Transport_04_covered_F":{[[0,-1,-0.82],1413]};
			case "Land_Pod_Heli_Transport_04_medevac_F":{[[0,-1,-0.82],1321]};
			case "Land_Pod_Heli_Transport_04_box_F":{[[0,-1,-0.82],1270]};
			case "Land_Pod_Heli_Transport_04_fuel_F":{[[0,-1,-0.82],13311]};
			case "Land_Pod_Heli_Transport_04_repair_F":{[[0,-1,-0.82],1270]};
			case "Land_Pod_Heli_Transport_04_ammo_F":{[[0,-1,-0.82],1270]};
			default{[[0,-1,-0.82],1270]};
		};
		_pod disableCollisionWith _heli;
		_pod attachTo [_heli,(_attribs select 0)];
		_taruweight = (weightRTD _heli)select 3;
		_set = _taruweight + (_attribs select 1);
		_heli setCustomWeightRTD _set;
		_mass = ((getMass _heli)+(getMass _pod));
		_heli setMass _mass;
		_pod setVariable ["R3F_LOG_disabled",true,true];
		_pod enableRopeAttach false;
//workaround for ropes not being disabled with above command before ropes has been attached once
		if(ropeAttachEnabled _pod)then{
			[_heli,_pod]spawn{
				_heli = _this select 0;
				_pod = _this select 1;
				_heli setSlingLoad _pod;
				waitUntil{!isNull (getSlingLoad _heli)};
				sleep 2;
				_heli setSlingLoad objNull;
				_pod enableRopeAttach false;
			};
		};
	};

	HALV_detachTarupods = {
		_heli = _this select 0;
		_pod = _this select 1;
		_action = _this select 2;
		_heli removeAction _action;
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_down_IN.wss", player];
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_down_OUT.wss", player];
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_down_IN.wss", _heli];
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_down_OUT.wss", _heli];
		detach _pod;
		_attribs = switch (typeOf _pod)do{
			case "Land_Pod_Heli_Transport_04_bench_F":{680};
			case "Land_Pod_Heli_Transport_04_covered_F":{1413};
			case "Land_Pod_Heli_Transport_04_medevac_F":{1321};
			case "Land_Pod_Heli_Transport_04_box_F":{1270};
			case "Land_Pod_Heli_Transport_04_fuel_F":{13311};
			case "Land_Pod_Heli_Transport_04_repair_F":{1270};
			case "Land_Pod_Heli_Transport_04_ammo_F":{1270};
			default{1270};
		};
		_taruweight = (weightRTD _heli)select 3;
		_set = _taruweight - _attribs;
		_heli setCustomWeightRTD _set;
		_mass = ((getMass _heli)-(getMass _pod));
		_heli setMass _mass;
		_pod setVariable ["R3F_LOG_disabled",false,true];
		_pod enableRopeAttach true;
		_pos = getPosATL _pod;
		sleep 2;
		_pod enableCollisionWith _heli;
		if(_pos select 2 > 25)then{
			_pos = getPosATL _pod;
			_chute = createVehicle ["B_Parachute_02_F", _pos, [], 0, "CAN_COLLIDE"];
			HALVPV_PARAPOD = [player,_chute];
			publicVariableServer "HALVPV_PARAPOD";
			_chute disableCollisionWith _pod;
			_chute disableCollisionWith _heli;
			_pod attachTo [_chute,[0,0,0.6]];
			_dt = diag_tickTime;
			waitUntil{sleep 1;(isTouchingGround _pod || diag_tickTime - _dt > 150)};
			if !(isNull _chute)then{
				detach _chute;
				deleteVehicle _chute;
			};
			_pos = getPos _pod;
			_pos set [2,0];
			_pod setPos _pos;
		};
	};

	HALV_fnc_checkattachedpods = {
		_currentpod = objNull;
		{
			_var1 = _x getVariable ["R3F_LOG_est_transporte_par",objNull];
			_var2 = _x getVariable ["R3F_LOG_est_deplace_par",objNull];
			if(_x isKindOf "Pod_Heli_Transport_04_base_F" && isNull _var1 && isNull _var2)exitWith{
				_currentpod = _x;
			};
		}forEach (attachedObjects _this);
		_currentpod
	};

	_taruAttachAction = -1;
	_tarudetachAction = -1;
	_slingLoadAction = -1;
	_claimaction = -1;
	_lastvehicle = objNull;
	_lastpod = objNull;
	_changed = false;
	
	while{alive player}do{
		if !(player isEqualTo vehicle player)then{
			_vehicle = vehicle player;
			_isTaru = _vehicle isKindOf "O_Heli_Transport_04_F";
			if(_isTaru)then{
				_currentpod = _vehicle call HALV_fnc_checkattachedpods;
				_R3F_LOG_heliporte = _vehicle getVariable ["R3F_LOG_heliporte",objNull];
				if (isNull _currentpod)then{
					_pods = (_vehicle nearEntities ["Pod_Heli_Transport_04_base_F",5.5])-[_vehicle];
					if(count _pods > 0)then{
						_newpod = _pods select 0;
						if(isNil {_newpod getVariable "R3F_LOG_disabled"})then {
							_newpod setVariable ["R3F_LOG_disabled", false];
						};
						_disabled = _newpod getVariable ["R3F_LOG_disabled",true];
						if (!_disabled && isNull _R3F_LOG_heliporte)then{
							if(_taruAttachAction < 0)then{
								_txt = gettext(configFile >> 'cfgvehicles' >> (typeOf _newpod) >> 'displayName');
								_taruAttachAction = _vehicle addAction [format["<img size='1.5'image='\a3\Ui_f\data\map\Markers\Military\pickup_ca.paa'/> Attach: %1",_txt],{[_this select 0,_this select 3,_this select 2]call HALV_attachTarupods;},_newpod,-1, true, true, "User5", "player isEqualTo driver _target"];
							};
						}else{
							_vehicle removeAction _taruAttachAction;
							_taruAttachAction = -1;
						};
					}else{
						_vehicle removeAction _taruAttachAction;
						_taruAttachAction = -1;
					};
				}else{
					_vehicle removeAction _taruAttachAction;
					_taruAttachAction = -1;
				};
				if (!(isNull _currentpod) && isNull(getSlingLoad _vehicle) && isNull _R3F_LOG_heliporte)then{
					_txt = gettext (configFile >> 'cfgvehicles' >> (typeOf _currentpod) >> 'displayName');
					if(_tarudetachAction < 0)then{
						_tarudetachAction = _vehicle addAction [format["<img size='1.5'image='\a3\Ui_f\data\map\Markers\Military\end_ca.paa'/> Drop: %1",_txt],{[_this select 0,_this select 3,_this select 2] spawn HALV_detachTarupods;},_currentpod,-1, true, true,"User5","player isEqualTo driver _target"];
					};
					if(_tarudetachAction > -1)then{
						_pos = getPosATL _vehicle;
						if(surfaceIsWater _pos)then{_pos = getPosASL _vehicle;};
						if(_pos select 2 < 25 && _changed)then{
							_vehicle setUserActionText [_tarudetachAction,format["<img size='1.5'image='\a3\Ui_f\data\map\Markers\Military\end_ca.paa'/> Drop: %1",_txt]];
							_changed = false;
						};
						if(_pos select 2 > 25 && !_changed)then{
							_vehicle setUserActionText [_tarudetachAction,format["<img size='1.5'image='\a3\Ui_f\data\map\VehicleIcons\iconparachute_ca.paa'/> Drop: %1",_txt]];
							_changed = true;
						};
					};
				}else{
					_vehicle removeAction _tarudetachAction;
					_tarudetachAction = -1;
				};
			}else{
				_vehicle removeAction _taruAttachAction;
				_taruAttachAction = -1;
				_vehicle removeAction _tarudetachAction;
				_tarudetachAction = -1;
			};

			_lastvehicle = _vehicle;
		}else{
			_lastvehicle removeAction _taruAttachAction;
			_taruAttachAction = -1;
			_lastvehicle removeAction _tarudetachAction;
			_tarudetachAction = -1;
			_lastvehicle removeAction _slingLoadAction;
			_slingLoadAction = -1;
		};
		_ct = cursorTarget;
		if !(isNull _ct)then{
			_isTarupod = _ct isKindOf "Pod_Heli_Transport_04_base_F";
			if(_isTarupod)then{
				_pid = getPlayerUID player;
				_podowner = _ct getVariable ["HALV_PODOWNER","0"];
				if(locked _ct in [0,1] && !(_podowner in [Epoch_my_GroupUID,_pid]))then{
					if(_claimaction < 0)then{
						_txt = gettext(configFile >> 'cfgvehicles' >> (typeOf _ct) >> 'displayName');
						_claimaction = _ct addAction [format["<img size='1.5'image='\a3\Ui_f\data\map\VehicleIcons\iconmanmedic_ca.paa'/> <t color='#0096ff'>Claim %1</t>",_txt],
						{
							_obj= _this select 0;
							_id = _this select 2; 
							_obj removeAction _id;
							_pid = getPlayerUID player;
							_newowner = _pid;
							if !(Epoch_my_GroupUID isEqualTo "")then{
								_newowner = Epoch_my_GroupUID;
							};
							_obj setVariable ["HALV_PODOWNER",_newowner,true];
						}, "",1, true, true, "","player distance _target < 5 && locked _target in [0,1]"];
					};
				}else{
					_ct removeAction _claimaction;
					_claimaction = -1;
				};
				_lastpod = _ct;
			}else{
				_lastpod removeAction _claimaction;
				_claimaction = -1;
			};
		}else{
			_lastpod removeAction _claimaction;
			_claimaction = -1;
		};
		sleep 1;
	};

	waitUntil{alive player};
	execVM __FILE__;
};