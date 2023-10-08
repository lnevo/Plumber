-- Replace default gossip icon with Dragonriding course medal
local _, addon = ...

local EL = CreateFrame("Frame");

local match = string.match;
local UnitName = UnitName;

local RACE_TIMES = "^Race Times";
local NPC_NAME = "Bronze Timekeeper";

local RankIcons = {
    [1] = "Interface\\AddOns\\Plumber\\Art\\GossipIcons\\Medal_Gold",
    [2] = "Interface\\AddOns\\Plumber\\Art\\GossipIcons\\Medal_Silver",
    [3] = "Interface\\AddOns\\Plumber\\Art\\GossipIcons\\Medal_Bronze",
    [4] = "Interface\\AddOns\\Plumber\\Art\\GossipIcons\\Medal_None",
};

do
    local locale = GetLocale();

    if locale == "enUS" then
        RACE_TIMES = "^Race Times";
        NPC_NAME = "Bronze Timekeeper";

    elseif locale == "esMX" then
        RACE_TIMES = "^Tiempos de la carrera";
        NPC_NAME = "Cronometradora bronce";

    elseif locale == "ptBR" then
        RACE_TIMES = "^Tempos da Corrida";
        NPC_NAME = "Guarda-tempo Bronze";

    elseif locale == "frFR" then
        RACE_TIMES = "^Temps des courses";
        NPC_NAME = "Chronométreuse de bronze";

    elseif locale == "deDE" then
        RACE_TIMES = "^Rennzeiten";
        NPC_NAME = "Bronzezeithüter";

    elseif locale == "esES" then
        RACE_TIMES = "^Tiempos de carrera";
        NPC_NAME = "Vigilante del tiempo bronce";

    elseif locale == "itIT" then
        RACE_TIMES = "^Tempi della Corsa";
        NPC_NAME = "Custode del Tempo Bronzea";

    elseif locale == "ruRU" then
        RACE_TIMES = "^Время гонки";
        NPC_NAME = "Бронзовая хранительница времени";

    elseif locale == "koKR" then
        RACE_TIMES = "^경주 시간";
        NPC_NAME = "청동 시간지기";

    elseif locale == "zhTW" then
        RACE_TIMES = "^競賽時間";
        NPC_NAME = "青銅時空守衛者";

    elseif locale == "zhCN" then
        RACE_TIMES = "^竞速时间";
        NPC_NAME = "青铜时光守护者";
    end
end


local function UpdateGossipIcons_Default(ranks)
    local f = GossipFrame;

    if not (f:IsShown() and f.gossipOptions) then return end;

    for i = 1, #ranks do
        if f.gossipOptions[i] then
            f.gossipOptions[i].icon = RankIcons[ranks[i]];
        end
    end

    f:Update();
end

local function UpdateGossipIcons_Immersion(ranks)
    local f = ImmersionFrame;

    if not (f and f:IsShown() and f.TitleButtons and f.TitleButtons.Active) then return end;

    local numActive = #f.TitleButtons.Active;
    if numActive ~= #ranks then return end;

    for i, button in ipairs(f.TitleButtons.Active) do
        button:SetIcon( RankIcons[ranks[i]] );
    end
end

local UpdateGossipIcons = UpdateGossipIcons_Default;


local function ProcessLines(...)
    local n = select('#', ...);
    local i = 1;
    local line, medal;
    local ranks = {};
    local k = 1;
    local rankID;

    while i < n do
        line = select(i, ...);
        if match(line, "[Cc][Ff][Ff][Ff][Ff][Dd]100") then  --title: Normal, Advanced, Reverse, etc.
            i = i + 1;
            line = select(i, ...);
            medal = match(line, "medal%-small%-(%a+)");
            if medal then
                if medal == "gold" then
                    rankID = 1;
                elseif medal == "silver" then
                    rankID = 2;
                elseif medal == "bronze" then
                    rankID = 3;
                else
                    rankID = 4;
                end
            else
                rankID = 4;
                i = i + 1;
            end

            ranks[k] = rankID;
            k = k + 1;
        end
        i = i + 1;
    end

    if k == 1 then
        --print("No Data")
        EL:QueryAuraTooltipInto();
    else
        UpdateGossipIcons(ranks);
        EL:PostDataFullyRetrieved();
    end
end

local function ProcessAuraByAuraInstanceID(auraInstanceID)
    local info = C_TooltipInfo.GetUnitBuffByAuraInstanceID("player", auraInstanceID);
    if info and info.lines and info.lines[2] then
        ProcessLines( string.split("\r", info.lines[2].leftText) );
    else
        --Tooltip data not ready
        EL:QueryAuraTooltipInto(auraInstanceID)
    end
end

local function EL_OnUpdate(self, elapsed)
    self.t = self.t + elapsed;
    if self.t > 0.2 then
        self.t = 0;
        self:SetScript("OnUpdate", nil);

        if self.auraInstanceID then
            ProcessAuraByAuraInstanceID(self.auraInstanceID);
            --print("Delayed Process")
        end
    end
end

function EL:QueryAuraTooltipInto(auraInstanceID)
    self.t = 0;
    if auraInstanceID then
        self.auraInstanceID = auraInstanceID;
    end
    self:SetScript("OnUpdate", EL_OnUpdate);
    --print("Query")
end

function EL:PostDataFullyRetrieved()
    self.auraInstanceID = nil;
    self:UnregisterEvent("UNIT_AURA");
    self:UnregisterEvent("GOSSIP_CLOSED");
    self:SetScript("OnUpdate", nil);
end



local function ProcessFunc(auraInfo)
    if auraInfo.icon == 237538 then
        --API.SaveLocalizedText(auraInfo.name);
        if string.find(auraInfo.name, RACE_TIMES) then
            ProcessAuraByAuraInstanceID(auraInfo.auraInstanceID);
            return true
        end
    end
end


function EL:UpdateRaceTimesFromAura()
    local unit = "player";
    local filter = "HELPFUL";
    local usePackedAura = true;

    AuraUtil.ForEachAura(unit, filter, nil, ProcessFunc, usePackedAura);
end


local function EL_OnEvent(self, event, ...)
    if event == "GOSSIP_SHOW" then
        if UnitName("npc") == NPC_NAME then
            self:RegisterUnitEvent("UNIT_AURA", "player");
            self:RegisterEvent("GOSSIP_CLOSED");
            EL:UpdateRaceTimesFromAura();
        end
        --API.SaveLocalizedText(UnitName("npc"));
    elseif event == "GOSSIP_CLOSED" then
        self:PostDataFullyRetrieved();

    elseif event == "UNIT_AURA" then
        EL:UpdateRaceTimesFromAura();
    end
end


local TEMP_RANKS;

local function SetStorylineDialogButtonIcon(...)
    if not TEMP_RANKS then return end;

    local button;
    for i = 1, select("#", ...) do
        button = select(i, ...);
        if button.icon and TEMP_RANKS[i] then
            button.icon:SetTexture(RankIcons[TEMP_RANKS[i]])
        end
    end
end

local function UdpateGossipIcons_Storyline(ranks)
    TEMP_RANKS = ranks;
    C_Timer.After(1, function()
        if Storyline_DialogChoicesScrollFrame:IsVisible() then
            SetStorylineDialogButtonIcon(Storyline_DialogChoicesScrollFrame.container:GetChildren());
        end
    end)
end


function EL:EnableModule()
    self:RegisterEvent("GOSSIP_SHOW");
    self:SetScript("OnEvent", EL_OnEvent);


    --Find compatible addons
    local IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded;

    if IsAddOnLoaded("Immersion") then
        UpdateGossipIcons = UpdateGossipIcons_Immersion;
    elseif IsAddOnLoaded("Storyline") then
        if Storyline_DialogChoicesScrollFrame and Storyline_DialogChoicesScrollFrame.container then
            UpdateGossipIcons = UdpateGossipIcons_Storyline;
        end
    end
end

function EL:DisableModule()
    self:UnregisterEvent("GOSSIP_SHOW");
    self:UnregisterEvent("GOSSIP_CLOSED");
    self:UnregisterEvent("UNIT_AURA");
end

local function EnableModule(state)
    if state then
        EL:EnableModule();
    else
        EL:DisableModule();
    end
end


do
    local L = addon.L;

    local defaultIcon = "|TInterface/AddOns/Plumber/Art/GossipIcons/GossipIcon:16:16:0:0|t";
    local newIcon = "|TInterface/AddOns/Plumber/Art/GossipIcons/Medal_Gold:16:16:0:0|t";
    local description = string.format(L["ModuleDescription GossipFrameMedal Format"], defaultIcon, newIcon);

    local moduleData = {
        name = L["ModuleName GossipFrameMedal"],
        dbKey = "GossipFrameMedal",
        description = description,
        toggleFunc = EnableModule,
    };

    addon.ControlCenter:AddModule(moduleData);
end