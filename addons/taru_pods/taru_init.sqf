/*
	Taru Pod's mod script
	by Halv
	inspired by XENO Taru Pod Mod
*/

if(isServer)exitWith{
	if(!isNil "HALV_fnc_parapod")exitWith{};
	HALV_fnc_parapod = {
		_para = _this select 1;
		if(_para isKindOf "ParachuteBase")then{
			_para call EPOCH_server_setVToken;
		};
//		diag_log format["[HALV_fnc_parapod]: %1",_this];
	};
	"HALVPV_PARAPOD" addPublicVariableEventHandler {(_this select 1) call HALV_fnc_parapod};
};

if(hasInterface && !isDedicated)then{
	HALV_attachTarupods = {
		_heli = _this select 0;
		_pod = _this select 1;
		_action = _this select 2;
		if !(isTouchingGround _heli)exitWith{titleText ["Need to be touching ground to attach a pod ...","PLAIN DOWN"];};
		_heli removeAction _action;
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_up_IN.wss", player];
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_up_IN.wss", _heli];
		_attribs = switch (typeOf _pod)do{
			case "Land_Pod_Heli_Transport_04_bench_F":{[[0,0,-1.2],680]};
			case "Land_Pod_Heli_Transport_04_covered_F":{[[0,-1,-0.82],1413]};
			case "Land_Pod_Heli_Transport_04_medevac_F":{[[-0.14,-1.05,-0.82],1321]};
			case "Land_Pod_Heli_Transport_04_box_F":{[[-0.14,-1.05,-0.82],1270]};
			case "Land_Pod_Heli_Transport_04_fuel_F":{[[0,-0.282,-0.82],13311]};
			case "Land_Pod_Heli_Transport_04_repair_F":{[[-0.14,-1.05,-0.82],1270]};
			case "Land_Pod_Heli_Transport_04_ammo_F":{[[-0.14,-1.05,-0.82],1270]};
			default{[[0,-1,-0.82],1270]};
		};
		_pod disableCollisionWith _heli;
		_pod attachTo [_heli,(_attribs select 0)];
		_heli setCustomWeightRTD (_attribs select 1);
		_pod setVariable ["R3F_LOG_disabled",true,true];
	};

	HALV_detachTarupods = {
		_heli = _this select 0;
		_pod = _this select 1;
		_action = _this select 2;
		_heli removeAction _action;
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_down_IN.wss", player];
		playSound3D ["A3\Sounds_F\vehicles\air\Heli_Transport_01\gear_down_IN.wss", _heli];
		detach _pod;
		_pos = getPosATL _pod;
		if(_pos select 2 > 10)then{
			sleep 2;
			_pos = getPosATL _pod;
			_chute = createVehicle ["B_Parachute_02_F", _pos, [], 0, "FLY"];
			HALVPV_PARAPOD = [player,_chute];
			publicVariableServer "HALVPV_PARAPOD";
			_chute disableCollisionWith _pod;
			_chute disableCollisionWith _heli;
			_pod attachTo [_chute, [0,0,1]];
			waitUntil{isTouchingGround _pod};
			if(!isNull _chute)then{
				detach _chute;
				deleteVehicle _chute;
			};
			_pos = getPos _pod;
		};
		_pos set [2,0];
		_pod setPos _pos;
		_pod enableCollisionWith _heli;
		_heli setCustomWeightRTD 0;
		_pod setVariable ["R3F_LOG_disabled",false,true];
	};

	HALV_fnc_checkattachedpods = {
		_currentpod = [];
		{
			if(_x isKindOf "Pod_Heli_Transport_04_base_F")exitWith{
				_currentpod = [_x];
			};
		}forEach (attachedObjects _this);
		_currentpod
	};

	_taruAttachAction = -1;
	_tarudetachAction = -1;
	_changed = false;

	while{alive player}do{
		_vehicle = vehicle player;
		if !(player isEqualTo _vehicle)then{
			_isTaru = _vehicle isKindOf "O_Heli_Transport_04_F";
			if(_isTaru && player == driver _vehicle)then{
				_currentpod = _vehicle call HALV_fnc_checkattachedpods;
				if (_currentpod isEqualTo [])then{
					_pods = _vehicle nearEntities ["Pod_Heli_Transport_04_base_F",7];
					if(count _pods > 0)then{
						_newpod = _pods select 0;
						_disabled = _newpod getVariable ["R3F_LOG_disabled",false];
						if(!_disabled)then{
							if(_taruAttachAction < 0)then{
								_txt = gettext (configFile >> 'cfgvehicles' >> (typeOf _newpod) >> 'displayName');
								_taruAttachAction = _vehicle addAction [format["<img size='1.5'image='\a3\Ui_f\data\map\Markers\Military\pickup_ca.paa'/> Attach: %1",_txt],{((_this select 3)+[_this select 2])call HALV_attachTarupods;},[_vehicle,_newpod],-1, false, true, "", ""];
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
				if !(_currentpod isEqualTo [])then{
					_typeOf = typeOf (_currentpod select 0);
					_txt = gettext (configFile >> 'cfgvehicles' >> _typeOf >> 'displayName');
					if(_tarudetachAction < 0)then{
						_ttxt = "<img size='1.5'image='\a3\Ui_f\data\map\Markers\Military\end_ca.paa'/> Drop: %1";
						_pos = getPosATL _vehicle;
						if(_pos select 2 > 10)then{_ttxt = "<img size='1.5'image='\a3\Ui_f\data\map\VehicleIcons\iconparachute_ca.paa'/> Drop: %1";_changed = true;};
						_tarudetachAction = _vehicle addAction [format[_ttxt,_txt],{((_this select 3)+[_this select 2]) spawn HALV_detachTarupods;},[_vehicle,_currentpod select 0],-1, false, true, "", ""];
					};
					if(_tarudetachAction > -1)then{
						_pos = getPosATL _vehicle;
						if(_pos select 2 < 10 && _changed)then{
							_vehicle setUserActionText [_tarudetachAction,format["<img size='1.5'image='\a3\Ui_f\data\map\Markers\Military\end_ca.paa'/> Drop: %1",_txt]];
							_changed = false;
						};
						if(_pos select 2 > 10 && !_changed)then{
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
		}else{
			_vehicle removeAction _taruAttachAction;
			_taruAttachAction = -1;
			_vehicle removeAction _tarudetachAction;
			_tarudetachAction = -1;
		};
		sleep 1;
	};

	waitUntil{alive player};
	execVM __FILE__;
};