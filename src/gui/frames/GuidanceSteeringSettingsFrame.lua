---
-- GuidanceSteeringStrategyFrame
--
-- Frame to handle the settings and to modify the current guidance data.
--
-- Copyright (c) Wopster, 2019

---@class GuidanceSteeringSettingsFrame
GuidanceSteeringSettingsFrame = {}

local GuidanceSteeringSettingsFrame_mt = Class(GuidanceSteeringSettingsFrame, TabbedMenuFrameElement)

GuidanceSteeringSettingsFrame.CONTROLS = {
    WIDTH_DISPLAY = "widthDisplay",
    WIDTH_PLUS = "guidanceSteeringMinusButton",
    WIDTH_MINUS = "guidanceSteeringPlusButton",
    WIDTH_RESET = "guidanceSteeringResetWidthButton",
    WIDTH_INCREMENT = "guidanceSteeringWidthIncrementElement",
    WIDTH_TEXT = "guidanceSteeringWidthText",
    WIDTH_INPUT = "guidanceSteeringWidthInput",

    OFFSET_DISPLAY = "offsetDisplay",
    OFFSET_PLUS = "guidanceSteeringMinusOffsetButton",
    OFFSET_MINUS = "guidanceSteeringPlusOffsetButton",
    OFFSET_RESET = "guidanceSteeringResetOffsetButton",
    OFFSET_INCREMENT = "guidanceSteeringOffsetIncrementElement",
    OFFSET_TEXT = "guidanceSteeringOffsetWidthText",
    OFFSET_INPUT = "guidanceSteeringOffsetWidthInput",

    HEADLAND_DISPLAY = "headlandDisplay",
    HEADLAND_MODE = "guidanceSteeringHeadlandModeElement",
    HEADLAND_DISTANCE = "guidanceSteeringHeadlandDistanceElement",

    TOGGLE_SHOW_LINES = "guidanceSteeringShowLinesElement",
    OFFSET_LINES = "guidanceSteeringLinesOffsetElement",
    TOGGLE_SNAP_TERRAIN_ANGLE = "guidanceSteeringSnapAngleElement",
    TOGGLE_ENABLE_STEERING = "guidanceSteeringEnableSteeringElement",
    TOGGLE_AUTO_INVERT_OFFSET = "guidanceSteeringAutoInvertOffsetElement",

    TOGGLE_DOT_LINES = "guidanceSteeringShowLinesAsDotsElement",

    CONTAINER = "container",
    BOX_LAYOUT_SETTINGS = "boxLayoutSettings",
}

GuidanceSteeringSettingsFrame.INCREMENTS = { 0.01, 0.05, 0.1, 0.5, 1 }

---Creates a new instance of the GuidanceSteeringSettingsFrame.
---@return GuidanceSteeringSettingsFrame
function GuidanceSteeringSettingsFrame.new(ui, i18n)
    local self = TabbedMenuFrameElement.new(nil, GuidanceSteeringSettingsFrame_mt)

    self.ui = ui
    self.i18n = i18n

    self.currentGuidanceWidth = 0
    self.currentWidthIncrement = 0

    self.currentGuidanceOffset = 0
    self.currentOffsetIncrement = 0

    self.allowSave = false

    self:registerControls(GuidanceSteeringSettingsFrame.CONTROLS)

    return self
end

function GuidanceSteeringSettingsFrame:copyAttributes(src)
    GuidanceSteeringSettingsFrame:superClass().copyAttributes(self, src)

    self.ui = src.ui
    self.i18n = src.i18n
end

function GuidanceSteeringSettingsFrame:initialize()
    local headlandModes = {}
    for _, mode in pairs(OnHeadlandState.MODES) do
        table.insert(headlandModes, self.i18n:getText(("guidanceSteering_headland_mode_%d"):format(mode - 1)))
    end

    self.guidanceSteeringHeadlandModeElement:setTexts(headlandModes)

    self.guidanceSteeringHeadlandDistanceElement:setText(tostring(0))
    
    self:changeWidth(0)
    self:changeOffsetWidth(0)

    self:build()
end

function GuidanceSteeringSettingsFrame:onFrameOpen()
    GuidanceSteeringSettingsFrame:superClass().onFrameOpen(self)

    local increments = {}
    for _, increment in pairs(GuidanceSteeringSettingsFrame.INCREMENTS) do
        table.insert(increments, tostring(self:getUnitLength(increment)))
    end

    self.guidanceSteeringWidthIncrementElement:setTexts(increments)
    self.guidanceSteeringOffsetIncrementElement:setTexts(increments)

    local offsets = stream({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }):map(function(offset)
        return tostring(offset * GuidanceSteering.GROUND_CLEARANCE_OFFSET)
    end)
    self.offsets = offsets:toList()
    self.guidanceSteeringLinesOffsetElement:setTexts(self.offsets)

    local vehicle = self.ui:getVehicle()
    if vehicle ~= nil then
        local spec = vehicle.spec_globalPositioningSystem
        local data = spec.guidanceData

        self.guidanceSteeringShowLinesElement:setIsChecked(g_currentMission.guidanceSteering:isShowGuidanceLinesEnabled())
        self.guidanceSteeringShowLinesAsDotsElement:setIsChecked(g_currentMission.guidanceSteering:isShowGuidanceLinesAsDotsEnabled())
        self.guidanceSteeringSnapAngleElement:setIsChecked(g_currentMission.guidanceSteering:isTerrainAngleSnapEnabled())
        self.guidanceSteeringEnableSteeringElement:setIsChecked(spec.guidanceSteeringIsActive)
        self.guidanceSteeringAutoInvertOffsetElement:setIsChecked(spec.autoInvertOffset)
        
        self:changeWidth(data.width)
        self:changeOffsetWidth(data.offsetWidth)

        local currentHeadlandActDistance = spec.headlandActDistance
        self.guidanceSteeringHeadlandModeElement:setState(spec.headlandMode)
        self.guidanceSteeringHeadlandDistanceElement:setText(tostring(currentHeadlandActDistance))

        self.allowSave = true
    end

    self.boxLayoutSettings:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayoutSettings)
        self:setSoundSuppressed(false)
    end
end

function GuidanceSteeringSettingsFrame:onFrameClose()
    GuidanceSteeringSettingsFrame:superClass().onFrameClose(self)

    if self.allowSave then
        -- Client only
        g_currentMission.guidanceSteering:setIsShowGuidanceLinesEnabled(self.guidanceSteeringShowLinesElement:getIsChecked())
        g_currentMission.guidanceSteering:setIsShowGuidanceLinesAsDotsEnabled(self.guidanceSteeringShowLinesAsDotsElement:getIsChecked())
        g_currentMission.guidanceSteering:setIsTerrainAngleSnapEnabled(self.guidanceSteeringSnapAngleElement:getIsChecked())
        g_currentMission.guidanceSteering:setIsGuidanceEnabled(self.guidanceSteeringEnableSteeringElement:getIsChecked())
        g_currentMission.guidanceSteering:setIsAutoInvertOffsetEnabled(self.guidanceSteeringAutoInvertOffsetElement:getIsChecked())
        g_currentMission.guidanceSteering:setLineOffset(tonumber(self.offsets[self.guidanceSteeringLinesOffsetElement:getState()]))

        local vehicle = self.ui:getVehicle()
        if vehicle ~= nil then
            local spec = vehicle.spec_globalPositioningSystem
            local data = spec.guidanceData

            local state = self.guidanceSteeringWidthIncrementElement:getState()
            local headlandMode = self.guidanceSteeringHeadlandModeElement:getState()
            local headlandActDistance = tonumber(self.guidanceSteeringHeadlandDistanceElement:getText()) or 0
            local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state]

            -- Todo: cleanup later
            local guidanceSteeringIsActive = g_currentMission.guidanceSteering:isGuidanceEnabled()
            if guidanceSteeringIsActive and not data.isCreated then
                g_currentMission:showBlinkingWarning(self.i18n:getText("guidanceSteering_warning_createTrackFirst"), 4000)
            else
                spec.lastInputValues.guidanceSteeringIsActive = guidanceSteeringIsActive
            end

            spec.lastInputValues.autoInvertOffset = g_currentMission.guidanceSteering:isAutoInvertOffsetEnabled()
            spec.lastInputValues.widthIncrement = math.abs(increment)

            if spec.headlandMode ~= headlandMode or spec.headlandActDistance ~= headlandActDistance then
                spec.headlandMode = headlandMode
                spec.headlandActDistance = headlandActDistance
                -- Update other clients
                g_client:getServerConnection():sendEvent(HeadlandModeChangedEvent:new(vehicle, headlandMode, headlandActDistance))
            end

            if data.width ~= nil and data.width ~= self.currentGuidanceWidth
                or data.offsetWidth ~= nil and data.offsetWidth ~= self.currentGuidanceOffset then
                data.width = self.currentGuidanceWidth
                data.offsetWidth = self.currentGuidanceOffset

                vehicle:updateGuidanceData(data, false, false)
            end
        end

        self.allowSave = false
    end
end

function GuidanceSteeringSettingsFrame:updateToolTipBoxVisibility(box)
    local hasText = box.text ~= nil and box.text ~= ""
    box:setVisible(hasText)
end

function GuidanceSteeringSettingsFrame:build()
    local uiFilename = self.ui.uiFilename

    self.widthDisplay:setImageFilename(uiFilename)
    self.widthDisplay:setImageUVs(nil, unpack(GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.WIDTH_DISPLAY)))

    self.offsetDisplay:setImageFilename(uiFilename)
    self.offsetDisplay:setImageUVs(nil, unpack(GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.OFFSET_DISPLAY)))

    -- Buttons
    self.guidanceSteeringPlusButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringMinusButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringResetWidthButton:setImageFilename(nil, uiFilename)

    self.guidanceSteeringPlusOffsetButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringMinusOffsetButton:setImageFilename(nil, uiFilename)
    self.guidanceSteeringResetOffsetButton:setImageFilename(nil, uiFilename)

    self.guidanceSteeringPlusButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_PLUS))
    self.guidanceSteeringMinusButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_MIN))
    self.guidanceSteeringResetWidthButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_RESET))
    --
    self.guidanceSteeringPlusOffsetButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_PLUS))
    self.guidanceSteeringMinusOffsetButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_MIN))
    self.guidanceSteeringResetOffsetButton:setImageUVs(nil, GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.BUTTON_RESET))
end

---Callbacks

function GuidanceSteeringSettingsFrame:onClickIncrementWidth()
    self:changeWidthInDirection(1)
end

function GuidanceSteeringSettingsFrame:onClickDecrementWidth()
    self:changeWidthInDirection(-1)
end

function GuidanceSteeringSettingsFrame:onWidthChanged(_, text)
    if string.sub(text,#text) ~= "." then
        self:changeWidth(tonumber(text) or 0);
    end
end

function GuidanceSteeringSettingsFrame:onClickResetWidth()
    self:changeWidth(0)
end

function GuidanceSteeringSettingsFrame:onClickAutoWidth()
    local vehicle = self.ui:getVehicle()

    if vehicle ~= nil then
        local spec = vehicle.spec_globalPositioningSystem
        local width, offset = GlobalPositioningSystem.getActualWorkWidth(spec.guidanceNode, vehicle)

        self:changeWidth(width)        
        self:changeOffsetWidth(offset)

        self:updateOffsetUVs()
    end
end

function GuidanceSteeringSettingsFrame:changeWidthInDirection(direction)    
    local state = self.guidanceSteeringWidthIncrementElement:getState()
    local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state] * direction
    self:changeWidth(self.currentGuidanceWidth + increment)
end

function GuidanceSteeringSettingsFrame:changeWidth(newWidth)
    self.currentGuidanceWidth = math.max(newWidth, 0)
    if 2 * math.abs(self.currentGuidanceOffset) >= self.currentGuidanceWidth then
        local newOffset = self.currentGuidanceWidth / 2 * (self.currentGuidanceOffset / math.abs(self.currentGuidanceOffset))
        self:changeOffsetWidth(newOffset)
    end
    self.guidanceSteeringWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceWidth))
    self.guidanceSteeringWidthInput:setText(tostring(self.currentGuidanceWidth))
end

function GuidanceSteeringSettingsFrame:onClickIncrementOffsetWidth()
    self:changeOffsetWidthInDirection(1)
end

function GuidanceSteeringSettingsFrame:onClickDecrementOffsetWidth()
    self:changeOffsetWidthInDirection(-1)
end

function GuidanceSteeringSettingsFrame:onClickInvertOffset()
    self:changeOffsetWidth(-self.currentGuidanceOffset)    
    self:updateOffsetUVs()
end

function GuidanceSteeringSettingsFrame:onClickResetOffsetWidth()
    self:changeOffsetWidth(0)
end

function GuidanceSteeringSettingsFrame:onOffsetWidthChanged(_, text)
    if string.sub(text,#text) ~= "." then
        self:changeOffsetWidth(tonumber(text) or 0);
    end
end

function GuidanceSteeringSettingsFrame:changeOffsetWidthInDirection(direction)
    local state = self.guidanceSteeringOffsetIncrementElement:getState()
    local increment = GuidanceSteeringSettingsFrame.INCREMENTS[state] * direction    
    self:changeOffsetWidth(self.currentGuidanceOffset + increment)
end

function GuidanceSteeringSettingsFrame:changeOffsetWidth(newOffset)
    local threshold = self.currentGuidanceWidth * 0.5
    newOffset = MathUtil.clamp(newOffset~=newOffset and 0 or newOffset, -threshold, threshold)
    self.currentGuidanceOffset = newOffset
    self.guidanceSteeringOffsetWidthText:setText(self:getFormattedUnitLength(self.currentGuidanceOffset))
    self.guidanceSteeringOffsetWidthInput:setText(tostring(self.currentGuidanceOffset))   
    self:updateOffsetUVs()
end

function GuidanceSteeringSettingsFrame:onHeadlandDistanceChanged(_, text)
    local lastDistance = tonumber(text)
    local textLength = utf8Strlen(text)

    if lastDistance == nil and textLength > 0 then
        lastDistance = 0
        self.guidanceSteeringHeadlandDistanceElement:setText(tostring(lastDistance))
    end

    if lastDistance ~= nil then
        if lastDistance > OnHeadlandState.MAX_ACT_DISTANCE then
            lastDistance = OnHeadlandState.MAX_ACT_DISTANCE
            self.guidanceSteeringHeadlandDistanceElement:setText(tostring(lastDistance))
        end
    end
end

function GuidanceSteeringSettingsFrame:updateOffsetUVs()
    if self.currentGuidanceOffset < 0 then
        self.offsetDisplay:setImageUVs(nil, unpack(GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.OFFSET_DISPLAY)))
    else
        self.offsetDisplay:setImageUVs(nil, unpack(GuiUtils.getUVs(GuidanceSteeringSettingsFrame.UVS.OFFSET_DISPLAY_RIGHT)))
    end
end

function GuidanceSteeringSettingsFrame:getUnitLength(meters)
    if self.i18n.useMiles then
        return meters * 3.2808
    end

    return meters
end

function GuidanceSteeringSettingsFrame:getFormattedUnitLength(meters)
    local unitLength = self:getUnitLength(meters)
    if self.i18n.useMiles then
        return string.format("%.2f %s", unitLength, "ft")
    end

    return string.format("%.2f %s", unitLength, "m")
end

GuidanceSteeringSettingsFrame.L10N_SYMBOL = {}

GuidanceSteeringSettingsFrame.UVS = {
    WIDTH_DISPLAY = { 0, 0, 130, 130 },
    BUTTON_PLUS = { 260, 0, 65, 65 },
    BUTTON_MIN = { 260, 65, 65, 65 },
    BUTTON_RESET = { 325, 0, 65, 65 },
    OFFSET_DISPLAY = { 130, 0, 130, 130 },
    OFFSET_DISPLAY_RIGHT = { 520, 0, 130, 130 },
    HEADLAND_DISPLAY = { 390, 0, 130, 130 },
}
