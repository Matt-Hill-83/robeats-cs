local NoteResult = require(game.ReplicatedStorage.Shared.Core.Engine.Enums.NoteResult)
local SFXManager = require(game.ReplicatedStorage.Shared.Core.Engine.SFXManager)
local NoteResultPopupEffect = require(game.ReplicatedStorage.Shared.Core.Engine.Effects.NoteResultPopupEffect)
local HoldingNoteEffect = require(game.ReplicatedStorage.Shared.Core.Engine.Effects.HoldingNoteEffect)

local NumberUtil = require(game.ReplicatedStorage.Shared.Utils.NumberUtil)

local ScoreManager = {}

function ScoreManager:new(_game)
	local self = {}
	self.hit_deviance = {}
	
	local chain = 0
	function self:getchain() return chain end
	
	self.bonus = 100
	self.score = 0
	self.chain = 0
	
	local marvCount = 0
	local perfectCount = 0
	local greatCount = 0
	local goodCount = 0
	local badCount = 0
	local missCount = 0
	local maxChain = 0
	local totalCount = 0
	local maxscore = 1000000
	
	local hit_color = {
		[0] = Color3.fromRGB(255, 0, 0);
		[1] = Color3.fromRGB(190, 10, 240);
		[2] = Color3.fromRGB(56, 10, 240);
		[3] = Color3.fromRGB(7, 232, 74);
		[4] = Color3.fromRGB(252, 244, 5);
		[5] = Color3.fromRGB(255, 255, 255);
	}

	local _didChange = Instance.new("BindableEvent")

	function self:getEndRecords() return  marvCount, perfectCount, greatCount, goodCount, badCount, missCount, maxChain, self.score end
	function self:getAccuracy()
		local totalCount = marvCount + perfectCount +  greatCount + goodCount + badCount + missCount
		if totalCount == 0 then 
			return 0
		else
			return 100*( ( marvCount + perfectCount + (greatCount*0.66) + (goodCount*0.33) + (badCount*0.166) ) / totalCount)
		end
	end
	
	function self:getGlobalAccuracy(marv,perf,great,good,bad,miss)
		local totalCount = marv + perf + great + good + bad + miss
		if totalCount == 0 then 
			return 0
		else
			return 100*( ( marv + perf + (great*0.66) + (good*0.33) + (bad*0.166) ) / totalCount)
		end
	end
	
	function self:getScore()
		local spread = {marvCount, perfectCount, greatCount, goodCount, badCount}
		return self:calculateTotalScore(spread)
	end
	
	function self:getGlobalScore(marv,perf,great,good,bad)
		local spread = {marv,perf,great,good,bad}
		return self:calculateTotalScore(spread)
	end

	function self:addHitToDeviance(hit_time_ms, time_to_end, note_result)
		local song_length = _game._audio_manager:get_song_length_ms()
		local to_add = {
			x = (hit_time_ms-time_to_end)/song_length,
			y = NumberUtil.InverseLerp(-360, 360, time_to_end),
			result = note_result;
			color = hit_color[note_result];
		}

		self.hit_deviance[#self.hit_deviance+1] = to_add
	end

	function self:getHitDeviance() return self.hit_deviance end
	
	function self:calculateTotalScore(spread)
		local totalnotes =_game._audio_manager:get_note_count()
		local marv = 0
		for total = 1, spread[1] do
			marv = marv + self:resultToPointTotal(NoteResult.Marvelous,totalnotes)
		end
		local perf = 0
		for total = 1, spread[2] do
			perf = perf + self:resultToPointTotal(NoteResult.Perfect,totalnotes)
		end
		local great = 0
		for total = 1, spread[3] do
			great = great + self:resultToPointTotal(NoteResult.Great,totalnotes)
		end
		local good = 0
		for total = 1, spread[4] do
			good = good + self:resultToPointTotal(NoteResult.Good,totalnotes)
		end
		local bad = 0
		for total = 1, spread[5] do
			bad = bad + self:resultToPointTotal(NoteResult.Bad,totalnotes)
		end
		return marv + perf + great + good + bad
	end
	
	function self:calculateNoteScore(totalnotes,hitvalue,hitbonusvalue,hitbonus,hitpunishment)
		local prebonus = self.bonus + hitbonus - hitpunishment
		if prebonus>100 then
			self.bonus = 100
		elseif prebonus<0 then
			self.bonus = 0
		else
			self.bonus = prebonus
		end
		local basescore = (maxscore * 0.5 / totalnotes) * (hitvalue / 320)
		local bonusscore = (maxscore * 0.5 / totalnotes) * (hitbonusvalue * math.sqrt(self.bonus) / 320)
		local score = basescore + bonusscore
		return score
	end

	function self:resultToPointTotal(note_result,totalnotes)
		if note_result == NoteResult.Marvelous then
			return self:calculateNoteScore(totalnotes,320,32,2,0)
		elseif note_result == NoteResult.Perfect then
			return self:calculateNoteScore(totalnotes,300,32,1,0)
		elseif note_result == NoteResult.Great then
			return self:calculateNoteScore(totalnotes,200,16,0,8)
		elseif note_result == NoteResult.Good then
			return self:calculateNoteScore(totalnotes,100,8,0,24)
		elseif note_result == NoteResult.Bad then
			return self:calculateNoteScore(totalnotes,50,4,0,44)
		else
			if totalCount > 0 then
				return self:calculateNoteScore(totalnotes,0,0,0,100)
			else
				return 0
			end
		end
	end

	local _frame_has_played_sfx = false

	function self:registerHit(
		note_result,
		slot_index,
		track_index,
		params
	)
		local track = _game:get_tracksystem(slot_index):get_track(track_index)
		_game._effects:add_effect(NoteResultPopupEffect:new(
			_game,
			track:get_end_position() + Vector3.new(0,0.25,0),
			note_result
		))

		if params.PlaySFX == true then
			
			--Make sure only one sfx is played per frame
			if _frame_has_played_sfx == false then
				if note_result == NoteResult.Perfect or note_result == NoteResult.Marvelous then
					if params.IsHeldNoteBegin == true then
						_game._audio_manager:get_hit_sfx_group():play_first()
					else
						_game._audio_manager:get_hit_sfx_group():play_alternating()
					end

				elseif note_result == NoteResult.Great then
					_game._audio_manager.get_hit_sfx_group():play_first()
				elseif note_result == NoteResult.Good or note_result == NoteResult.Bad then
					_game._sfx_manager:play_sfx(SFXManager.SFX_DRUM_OKAY)
				else
					_game._sfx_manager:play_sfx(SFXManager.SFX_MISS)
				end
				_frame_has_played_sfx = true
			end
			
			--Create an effect at HoldEffectPosition if PlayHoldEffect is true
			if params.PlayHoldEffect then
				if note_result ~= NoteResult.Miss then
					_game._effects:add_effect(HoldingNoteEffect:new(
						_game,
						params.HoldEffectPosition,
						note_result
					))
				end
			end
		end

		local _add_to_devaince = true
		
		--Incregertment stats
		if note_result == NoteResult.Marvelous then
			chain = chain + 1
			marvCount = marvCount + 1
		elseif note_result == NoteResult.Perfect then
			chain = chain + 1
			perfectCount = perfectCount + 1
		elseif note_result == NoteResult.Great then
			 greatCount =  greatCount + 1
		elseif note_result == NoteResult.Good then
			goodCount = goodCount + 1
		elseif note_result == NoteResult.Bad then
			chain = chain + 1
			badCount = badCount + 1
		else
			if chain > 0 then
				chain = 0
				missCount = missCount + 1

			elseif params.TimeMiss == true then
				missCount = missCount + 1
			else
				_add_to_devaince = false
			end
		end

		if _add_to_devaince then
			self:addHitToDeviance(params.HitTime, params.TimeToEnd, note_result)
		end
		
		local totalnotes =_game._audio_manager:get_note_count()
		self.score = self.score + self:resultToPointTotal(note_result,totalnotes)
		
		maxChain = math.max(chain,maxChain)

		self:fireChange()
	end

	function self:getStatTable()
		local marv_count, perf_count, great_count, good_count, bad_count, miss_count, max_combo, score = self:getEndRecords()
		local combo = self:getchain()
		local accuracy = self:getAccuracy()

		return {
			score = score;
			marvelouses = marv_count;
			perfects = perf_count;
			greats = great_count;
			goods = good_count;
			bads = bad_count;
			misses = miss_count;
			combo = combo;
			accuracy = accuracy;
			max_combo = max_combo;
		}
	end

	function self:fireChange()
		_didChange:Fire(self:getStatTable())
	end

	function self:bindToChange(_callback)
		return _didChange.Event:Connect(_callback)
	end

	function self:update(dt_scale)
		_frame_has_played_sfx = false
	end

	self:fireChange()

	return self
end

return ScoreManager
