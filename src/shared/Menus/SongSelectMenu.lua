local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local GameSlot = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameSlot)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local MarketplaceService = game:GetService("MarketplaceService")

local LeaderboardDisplay = require(game.ReplicatedStorage.Menus.Utils.LeaderboardDisplay)
local SongStartMenu = require(game.ReplicatedStorage.Menus.SongStartMenu)
local ConfirmationPopupMenu = require(game.ReplicatedStorage.Menus.ConfirmationPopupMenu)
local SettingsMenu = require(game.ReplicatedStorage.Menus.SettingsMenu)
local MultiplayerLobbyMenu = require(game.ReplicatedStorage.Menus.MultiplayerLobbyMenu)
local Configuration	= require(game.ReplicatedStorage.Configuration)
local CustomServerSettings = require(game.Workspace.CustomServerSettings)

local SongSelectMenu = {}

function SongSelectMenu:new(_local_services)
	local self = MenuBase:new()

	local _song_select_ui
	local _selected_songkey = SongDatabase:invalid_songkey()
	local _is_supporter = false

	local section_container
	local tab_container

	local _input = _local_services._input

	local _leaderboard_display
	
	function self:cons()
		_song_select_ui = EnvironmentSetup:get_menu_protos_folder().SongSelectUI:Clone()

		section_container = _song_select_ui.SectionContainer
		tab_container = _song_select_ui.TabContainer

		local song_list = section_container.SongSection.SongList
		
		--Expand the scrolling list to fit contents
		song_list.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			song_list.CanvasSize = UDim2.new(0, 0, 0, song_list.UIListLayout.AbsoluteContentSize.Y)
		end)
		
		local song_list_element_proto = song_list.SongListElementProto
		song_list_element_proto.Parent = nil
		for itr_songkey, itr_songdata in SongDatabase:key_itr() do
			local itr_list_element = song_list_element_proto:Clone()
			itr_list_element.Parent = song_list
			itr_list_element.LayoutOrder = itr_songkey

			--SongDatabase:render_coverimage_for_key(song_cover, song_cover.SongCoverOverlay, itr_songkey)
			itr_list_element.SongCover.Image = SongDatabase:get_image_for_key(itr_songkey)
			itr_list_element.NameDisplay.Text = SongDatabase:get_title_for_key(itr_songkey)
			itr_list_element.DifficultyDisplay.Text = string.format("Difficulty: %d",SongDatabase:get_difficulty_for_key(itr_songkey))
			if SongDatabase:key_get_audiomod(itr_songkey) == SongDatabase.SongMode.SupporterOnly then
				itr_list_element.DifficultyDisplay.Text = itr_list_element.DifficultyDisplay.Text .. " (Supporter Only)"
			end
			
			SPUtil:bind_input_fire(itr_list_element, function(input)
				_local_services._sfx_manager:play_sfx(SFXManager.SFX_BUTTONPRESS)
				self:select_songkey(itr_songkey)
			end)
			
		end
		
		_leaderboard_display = LeaderboardDisplay:new(
			section_container.LeaderboardSection, 
			section_container.LeaderboardSection.LeaderboardList.LeaderboardListElementProto
		)
		
		section_container.SongInfoSection.NoSongSelectedDisplay.Visible = true
		section_container.SongInfoSection.SongInfoDisplay.Visible = false
		section_container.PlayButton.Visible = false

		SPUtil:bind_input_fire(section_container.PlayButton, function()
			_local_services._sfx_manager:play_sfx(SFXManager.SFX_MENU_OPEN)
			self:play_button_pressed()
		end)

		SPUtil:bind_input_fire(tab_container.SettingsButton, function()
			_local_services._menus:push_menu(SettingsMenu:new(_local_services))
		end)

		SPUtil:bind_input_fire(tab_container.MultiplayerButton, function()
			_local_services._menus:push_menu(MultiplayerLobbyMenu:new(_local_services))
		end)

		
		section_container.SongInfoSection.NoSongSelectedDisplay.Visible = true

		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, asset_id, is_purchased)
			if asset_id == CustomServerSettings.SupporterGamepassID and is_purchased == true then
				_is_supporter = true
				self:select_songkey(_selected_songkey)
				self:show_gamepass_menu()
			end
		end)
		
		spawn(function()
			_is_supporter = MarketplaceService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, CustomServerSettings.SupporterGamepassID)
			self:select_songkey(_selected_songkey)
		end)
	end
	
	function self:select_songkey(songkey)
		if SongDatabase:contains_key(songkey) ~= true then return end
		section_container.SongInfoSection.NoSongSelectedDisplay.Visible = false
		_selected_songkey = songkey
		
		--SongDatabase:render_coverimage_for_key(section_container.SongInfoSection.SongInfoDisplay.SongCover, section_container.SongInfoSection.SongInfoDisplay.SongCover.SongCoverOverlay, _selected_songkey)
		section_container.SongInfoSection.SongInfoDisplay.NameDisplay.Text = SongDatabase:get_title_for_key(_selected_songkey)
		section_container.SongInfoSection.SongInfoDisplay.DifficultyDisplay.Text = string.format("Difficulty: %d",SongDatabase:get_difficulty_for_key(_selected_songkey))
		section_container.SongInfoSection.SongInfoDisplay.ArtistDisplay.Text = SongDatabase:get_artist_for_key(_selected_songkey)
		section_container.SongInfoSection.SongInfoDisplay.DescriptionDisplay.Text = SongDatabase:get_description_for_key(_selected_songkey)
		section_container.SongInfoSection.SongInfoDisplay.SongCover.Image = SongDatabase:get_image_for_key(_selected_songkey)

		for _, itr_nps_ob in pairs(section_container.SongInfoSection.SongInfoDisplay.NpsGraph.Items:GetChildren()) do
			if itr_nps_ob:IsA("Frame") then
				itr_nps_ob:Destroy()
			end
		end

		local nps_graph = SongDatabase:get_nps_graph_for_key(_selected_songkey)
		local max_nps = 0
		for _, nps in pairs(nps_graph) do
			max_nps = math.max(nps, max_nps)
		end

		for _, nps in pairs(nps_graph) do
			local nps_point = Instance.new("Frame")
			nps_point.BorderSizePixel = 0
			nps_point.Size = UDim2.new(1/#nps_graph, 0, nps/(max_nps+5), 0)
			nps_point.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			nps_point.Parent = section_container.SongInfoSection.SongInfoDisplay.NpsGraph.Items
		end

		section_container.SongInfoSection.SongInfoDisplay.NpsGraph.MaxNps.Text = string.format("MAX NPS: %d", max_nps)
		
		
		section_container.SongInfoSection.SongInfoDisplay.Visible = true
		section_container.PlayButton.Visible = true
		
		_leaderboard_display:refresh_leaderboard(songkey)
	end
	
	function self:play_button_pressed()
		if SongDatabase:contains_key(_selected_songkey) then
			_local_services._menus:push_menu(SongStartMenu:new(_local_services, _selected_songkey, GameSlot.SLOT_1))
		end
	end
	
	--[[Override--]] function self:do_remove()
		_song_select_ui:Destroy()
	end
	
	--[[Override--]] function self:set_is_top_element(val)
		if val then
			EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
			_song_select_ui.Parent = EnvironmentSetup:get_player_gui_root()
			self:select_songkey(_selected_songkey)
		else
			_song_select_ui.Parent = nil
		end
	end
	
	self:cons()
	
	return self
end

return SongSelectMenu