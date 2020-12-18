local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local RandomLua = require(game.ReplicatedStorage.Shared.Utils.RandomLua)

local function noop() end

local SPUtil = {}

function SPUtil:rad_to_deg(rad)
	return rad * 180.0 / math.pi
end

function SPUtil:deg_to_rad(degrees)
	return degrees * math.pi / 180
end

function SPUtil:dir_ang_deg(x,y)
	return SPUtil:rad_to_deg(math.atan2(y,x))
end

function SPUtil:ang_deg_dir(deg)
	local rad = SPUtil:deg_to_rad(deg)
	return Vector2.new(
		math.cos(rad),
		math.sin(rad)
	)
end

function SPUtil:part_cframe_rotation(part)
	return CFrame.new(-part.CFrame.p) * (part.CFrame)
end

function SPUtil:table_clear(tab)
	for k,v in pairs(tab) do tab[k]=nil end
end

function SPUtil:vec3_lerp(a,b,t)
	return a:Lerp(b,t)
end

local _seed = tick() % 1000
local _rand = RandomLua.mwc(_seed)
function SPUtil:rand_rangef(min,max)
	return _rand:rand_rangef(min,max)
end

function SPUtil:rand_rangei(min,max)
	return _rand:rand_rangei(min,max)
end

function SPUtil:clamp(val,min,max)
	return math.min(max,math.max(min,val))
end

function SPUtil:tra(val)
	return 1 - val
end

function SPUtil:format_ms_time(ms_time)
	ms_time = math.floor(ms_time)
	return string.format(
		"%d:%d%d",
		ms_time/60000,
		(ms_time/10000)%6,
		(ms_time/1000)%10
	)
end

local __cached_camera = nil
local function get_camera()
	if __cached_camera == nil then __cached_camera = game.Workspace.Camera end
	return __cached_camera
end
function SPUtil:get_camera() return get_camera() end

function SPUtil:lookat_camera_cframe(position)
	local camera_cf = SPUtil:get_camera().CFrame
	local look_vector = camera_cf.LookVector.Unit
	local normal_dir = look_vector * -1
	return CFrame.new(position, position + normal_dir)
end

function SPUtil:try(call)
	return xpcall(function()
		call()
	end, function(err)
		return {
			Error = err;
			StackTrace = debug.traceback();
		}
	end)
end

function SPUtil:look_at(eye, target)
	local forwardVector = (target - eye).Unit
	local upVector = Vector3.new(0, 1, 0)
	local rightVector = forwardVector:Cross(upVector)
	local upVector2 = rightVector:Cross(forwardVector)
	return CFrame.fromMatrix(eye, rightVector, upVector2)
end

function SPUtil:is_mobile()
	return game:GetService("UserInputService").TouchEnabled
end

local _sputil_screengui = nil
local function verify_sputil_screengui()
	if _sputil_screengui ~= nil then return true end
	if game.Players.LocalPlayer == nil then
		return false
	end
	if game.Players.LocalPlayer:FindFirstChild("PlayerGui") == nil then
		return false
	end
	local TESTGUI_NAME = "SPUtil_test"
	if game.Players.LocalPlayer.PlayerGui:FindFirstChild(TESTGUI_NAME) == nil then
		_sputil_screengui = Instance.new("ScreenGui",game.Players.LocalPlayer.PlayerGui)
		_sputil_screengui.Name = TESTGUI_NAME
		_sputil_screengui.ResetOnSpawn = false
	end
	return true
end

function SPUtil:topbar_size() return 36 end

local __cached_screen_size = Vector2.new(0,0)
local __cached_absolute_size = Vector2.new()
function SPUtil:screen_size()
	if verify_sputil_screengui() == false then
		return __cached_screen_size
	end
	local abs_size = _sputil_screengui.AbsoluteSize
	if __cached_absolute_size ~= abs_size then
		__cached_absolute_size = abs_size
		__cached_screen_size = Vector2.new(abs_size.X + 0, abs_size.Y + SPUtil:topbar_size())
	end
	return __cached_screen_size
end

function SPUtil:time_to_str(time)
	return os.date("%H:%M %d/%m/%Y",time)
end

function SPUtil:bind_input_fire(object_, callback_)
	local cb = function(i,n)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			callback_(i,n)
		end
	end
	local suc, err = pcall(function()
		object_.Activated:Connect(cb)
	end)
	if not suc then
		object_.InputBegan:Connect(cb)
	end
end

function SPUtil:input_callback(_callback)
	return function(...)
		if not _callback then return end
		local i = select(2, ...)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			_callback(...)
		end
	end
end

function SPUtil:find_distance(x1, y1, x2, y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

function SPUtil:find_angle(point, center)
	local dx = point.X - center.X;

	local dy = -(point.Y - center.Y);

	local inRads = math.atan2(dy, dx);

	if (inRads < 0) then
		inRads = math.abs(inRads);
	else
		inRads = 2 * math.pi - inRads;
	end

	return math.deg(inRads);
end

function SPUtil:button(_instance, _expand_size, _local_services, _callback)
	local SFXManager = require(game.ReplicatedStorage.Shared.Core.Engine.SFXManager)
	local original_size = _instance.Size
	_expand_size = _expand_size or UDim2.new(0, 0, 0, 0)

	_instance.MouseEnter:Connect(function()
		SPUtil:try(function()
			_instance:TweenSize(original_size+_expand_size, Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.2, true)
		end)
	end)

	_instance.MouseLeave:Connect(function()
		SPUtil:try(function()
			_instance:TweenSize(original_size, Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.2, true)
		end)
	end)

	SPUtil:bind_input_fire(_instance, function()
		if _callback then
			if _local_services then
				_local_services._sfx_manager:play_sfx(SFXManager.SFX_BUTTONPRESS)
			end
			_callback()
		end
	end)
end

function SPUtil:bind_to_frame(_callback)
	return RunService.Heartbeat:Connect(_callback)
end

function SPUtil:should_component_be_visible(a, b)
	return a == nil and true or (a == b and true or false)
end

function SPUtil:copy_table(datatable)
	local tblRes={}
	if type(datatable)=="table" then
		for k,v in pairs(datatable) do tblRes[k]=SPUtil:copy_table(v) end
	else
		tblRes=datatable
	end
	return tblRes
end

function SPUtil:player_name_from_id(id)
	local name

	for _, itr_plr in pairs(game.Players:GetChildren()) do
		if itr_plr.UserId == id then return itr_plr.Name end
	end

	local suc, err = pcall(function()
		name = game.Players:GetNameFromUserIdAsync(id)
	end)
	return suc and name or "N/A"
end

function SPUtil:spawn(_callback)
	spawn(_callback)
end

function SPUtil:bind_to_key(key_code, _callback)
	_callback = _callback or noop
	return UserInputService.InputBegan:Connect(function(inputob)
		if inputob.KeyCode == key_code then
			_callback()
		end
	end)
end

function SPUtil:bind_to_key_release(key_code, _callback)
	_callback = _callback or noop
	return UserInputService.InputEnded:Connect(function(inputob)
		if inputob.KeyCode == key_code then
			_callback()
		end
	end)
end

return SPUtil
