local SPUtil = require(game.ReplicatedStorage.Shared.Utils.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.Utils.CurveUtil)
local TriggerButton = require(game.ReplicatedStorage.Client.Components.Screens.Gameplay.Engine.NoteTrack.TriggerButton)
local GameSlot = require(game.ReplicatedStorage.Client.Components.Screens.Gameplay.Engine.Enums.GameSlot)
local EnvironmentSetup = require(game.ReplicatedStorage.Client.Components.Screens.Gameplay.Engine.EnvironmentSetup)
local GameTrack = require(game.ReplicatedStorage.Client.Components.Screens.Gameplay.Engine.Enums.GameTrack)
local AssertType = require(game.ReplicatedStorage.Shared.Utils.AssertType)
local DebugOut = require(game.ReplicatedStorage.Shared.Utils.DebugOut)

local NoteTrack = {}

function NoteTrack:new(_game, _parent_track_system, _track_obj, _game_track)
	AssertType:is_enum_member(_game_track, GameTrack)
	local self = {}
	
	local _trigger_button
	local _start_position
	local _end_position
	
	function self:cons(player_info)
		local start_position_marker = _track_obj:FindFirstChild("StartPosition")
		if start_position_marker == nil then
			return DebugOut:errf("StartPosition marker not found under _track_obj(%s)", _track_obj.Name)
		end
		_start_position = start_position_marker.Position
		
		local end_position_marker = _track_obj:FindFirstChild("EndPosition")
		if end_position_marker == nil then
			return DebugOut:errf("EndPosition marker not found under _track_obj(%s)", _track_obj.Name)
		end
		_end_position = end_position_marker.Position
		
		_trigger_button = TriggerButton:new(
			_game,
			self,
			self:get_end_position()
		)
	end
	
	function self:get_track_obj() return _track_obj end
	function self:get_start_position() return _start_position end
	function self:get_end_position() return _end_position end
	
	function self:press()
		_trigger_button:press()
	end 
	function self:release()
		_trigger_button:release()
	end
	
	function self:update(dt_scale)
		_trigger_button:update(dt_scale)
	end
	
	function self:teardown()
		_trigger_button:teardown()
		_track_obj:Destroy()
	end
	
	self:cons()
	return self
end

return NoteTrack
