local Roact = require(game.ReplicatedStorage.Libraries.Roact)

local ScoreOverlay = require(script.Parent.ScoreOverlay)

local SPUtil = require(game.ReplicatedStorage.Shared.Utils.SPUtil)

local GameplayMain = Roact.PureComponent:extend("GameplayMain")

function GameplayMain:init()
	self.bound_to_frame = SPUtil:bind_to_frame(function()
		if self.props.isPlaying == false then
			self.props.history:push("/results")
		end
	end)
end

function GameplayMain:willUnmount()

end

function GameplayMain:render()
	local stats = self.props.stats
	return Roact.createElement("Frame", {
		Name = "GameplayMain",
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
        StatsOverlay = Roact.createElement(ScoreOverlay, {
            marvs = stats.marvelouses;
            perfs = stats.perfects;
            greats = stats.greats;
            goods = stats.goods;
            bads = stats.bads;
            misses = stats.misses;
            score = stats.score;
            accuracy = stats.accuracy;
            time_left = stats.time_left;
            combo = stats.combo;
        });
		ExitButton = Roact.createElement("TextButton", {
			BackgroundColor3 = Color3.fromRGB(255, 53, 53),
			Position = UDim2.new(0.02, 0, 0.05, 0),
			Size = UDim2.new(0.1, 0, 0.05, 0),
			Font = Enum.Font.GothamSemibold,
			Text = "Exit",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			[Roact.Event.InputBegan] = SPUtil:input_callback(function()
				self.props.backOut()
			end)
		}, {
			Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			})
		})
	})
end

return GameplayMain
