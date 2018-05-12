--
-- This is a version of Emrus's 'Shadowed UF Inline Absorb' for heal absorb instead
-- "https://www.curseforge.com/wow/addons/shadoweduf_inlineabsorb"
--

local ADDON_NAME, PRIVATE_TABLE = ...
local HealAbsorb = ShadowUF.modules["healAbsorb"]

function HealAbsorb:OnLayoutApplied(frame)
	if (not frame.visibility[self.frameKey] or not frame.visibility.healthBar) then return end

	if (frame.visibility.healAbsorb) then
		frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", self, "UpdateFrame")
	else
		frame:UnregisterSingleEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", self, "UpdateFrame")
	end
end

function HealAbsorb:OnLayoutWidgets(frame)
	if (frame[self.frameKey] == nil) then return end

	local cap = ShadowUF.db.profile.units[frame.unitType][self.frameKey].cap or 1.30
	local width = ShadowUF.db.profile.units[frame.unitType][self.frameKey].width or 0.6
	local reverseFill = ShadowUF.db.profile.units[frame.unitType][self.frameKey].reverseFill ~= frame.healthBar:GetReverseFill()
	local flip = not ShadowUF.db.profile.units[frame.unitType][self.frameKey].flip
	local bar = frame[self.frameKey]

	bar.total = nil

	-- Sets size and theme
	bar:SetSize(frame.healthBar:GetSize())
	bar:SetStatusBarTexture(ShadowUF.Layout.mediaPath.statusbar)
	bar:SetStatusBarColor(ShadowUF.db.profile.healthColors[self.colorKey].r, ShadowUF.db.profile.healthColors[self.colorKey].g, ShadowUF.db.profile.healthColors[self.colorKey].b, ShadowUF.db.profile.bars.alpha)
	bar:GetStatusBarTexture():SetHorizTile(false)
	bar:SetOrientation(frame.healthBar:GetOrientation())
	bar:SetReverseFill(reverseFill)
	bar:Hide()

	bar.simple = true
	bar:SetFrameLevel(frame.topFrameLevel + 1)

	bar:ClearAllPoints()
	if (bar:GetOrientation() == "HORIZONTAL") then
		bar:SetWidth(frame.healthBar:GetWidth() * cap)
		bar:SetPoint(reverseFill and "RIGHT" or "LEFT", frame.healthBar)
		bar:SetPoint(flip and "TOP" or "BOTTOM", frame.healthBar)
		bar:SetPoint(flip and "BOTTOM" or "TOP", frame.healthBar, flip and "TOP" or "BOTTOM", 0, (flip and -1 or 1) * frame.healthBar:GetHeight() * width)
	else
		bar:SetHeight(frame.healthBar:GetHeight() * cap)
		bar:SetPoint(reverseFill and "TOP" or "BOTTOM", frame.healthBar)
		bar:SetPoint(flip and "RIGHT" or "LEFT", frame.healthBar)
		bar:SetPoint(flip and "LEFT" or "RIGHT", frame.healthBar, flip and "RIGHT" or "LEFT", (flip and -1 or 1) * frame.healthBar:GetWidth() * width, 0)
	end
end

function HealAbsorb:PositionBar(frame, incAmount)
	local bar = frame[self.frameKey]

	incAmount = UnitGetTotalHealAbsorbs(frame.unit) or 0

	local health = UnitHealth(frame.unit)
	if (health <= 0 or incAmount <= 0) then
		bar.total = nil
		bar:Hide()
		return
	end

	if (not bar.total) then
		bar:Show()
	end

	bar.total = incAmount

	bar:SetMinMaxValues(0, UnitHealthMax(frame.unit) * (ShadowUF.db.profile.units[frame.unitType][self.frameKey].cap or 1.30))
	bar:SetValue(bar.total)
end

function HealAbsorb:OnConfigurationLoad()
	local args = ShadowUF.Config.unitTable.args.bars.args.healAbsorb.args
	args.reverseFill = {
		order = 4,
		type = "toggle",
		name = PRIVATE_TABLE.L["Reverse fill"],
		desc = PRIVATE_TABLE.L["Changes the fill direction so the bar fill opposite the health bar."],
		arg = "healAbsorb.reverseFill",
		hidden = false,
	}
	args.width = {
		order = 5,
		type = "range",
		name = PRIVATE_TABLE.L["Width"],
		desc = PRIVATE_TABLE.L["How thick the absorb bar is compared to the health bar."],
		min = 0,
		max = 1,
		step = 0.05,
		isPercent = true,
		arg = "healAbsorb.width",
		hidden = false,
	}
	args.flip = {
		order = 6,
		type = "toggle",
		name = PRIVATE_TABLE.L["Flip side"],
		desc = PRIVATE_TABLE.L["Changes the side the absorb bar is attached too"],
		arg = "healAbsorb.flip",
		hidden = false,
	}
end


local OriginalLoadUnitDefaults = ShadowUF.LoadUnitDefaults
function ShadowUF:LoadUnitDefaults()
	OriginalLoadUnitDefaults(self)

	-- Initialize defaults
	for _, unit in pairs(self.unitList) do
		if (not self.fakeUnits[unit]) then
			if (unit ~= "battleground" and unit ~= "battlegroundpet" and unit ~= "arena" and unit ~= "arenapet" and unit ~= "boss") then
				self.defaults.profile.units[unit].healAbsorb = {
					enabled = true,
					cap = 1.30,
					reverseFill = true,
					width = 0.6,
					flip = false
				}
			end
		end
	end
end