local UiUtil = {}

function UiUtil.corner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

function UiUtil.makeToast(parent: Instance, position: UDim2, width: number)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, width, 0, 52)
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 20
	frame.Parent = parent

	UiUtil.corner(frame, 10)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = ""
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.ZIndex = 21
	label.Parent = frame

	local thread = nil

	local function show(message: string)
		label.Text = message
		frame.Visible = true
		if thread then
			task.cancel(thread)
		end
		thread = task.delay(3.5, function()
			frame.Visible = false
			thread = nil
		end)
	end

	return show
end

return UiUtil
