--[[
	AutoCage (C) @Kruithne <kruithne@gmail.com>
	Licensed under GNU General Public Licence version 3.

	https://github.com/Kruithne/AutoCageAddon

	AutoCage.lua - Core engine file for the addon.
]]

local petCagedPattern = string.gsub(BATTLE_PET_NEW_PET, "%%s", ".*%%[([A-Za-z%%s0-9%'%-]+)%%].*");
local acHasHooked = false;

L_AUTOCAGE_CAGED_MESSAGE = {
	["frFR"] = "Dupliquer animal de compagnie; la mise en cage pour vous!",
	["deDE"] = "Duplizieren pet; Käfighaltung es für Sie!",
	["enGB"] = "Duplicate pet; caging it for you!",
	["enUS"] = "Duplicate pet; caging it for you!",
	["itIT"] = "Duplicare animale; messa in gabbia per voi!",
	["koKR"] = "애완 동물을 복제 ; 케이지 에 넣어!",
	["zhCN"] = "重复宠物;把它关在笼子里！",
	["zhTW"] = "重複寵物;把它關在籠子裡！",
	["ruRU"] = "Повторяющиеся питомца; положить его в клетку!",
	["esES"] = "Duplicar mascota; ponerlo en una jaula!",
	["esMX"] = "Duplicar mascota; ponerlo en una jaula!",
	["ptBR"] = "Duplicar para animais de estimação ; colocá-lo em uma gaiola!"
};

L_AUTOCAGE_LOADED = {
	["frFR"] = "Chargé!",
	["deDE"] = "Geladen!",
	["enGB"] = "Loaded!",
	["enUS"] = "Loaded!",
	["itIT"] = "Caricato!",
	["koKR"] = "로드!",
	["zhCN"] = "加载!",
	["zhTW"] = "載入!",
	["ruRU"] = "Загружен!",
	["esES"] = "Cargado!",
	["esMX"] = "Cargado!",
	["ptBR"] = "Carregado!"
};

L_AUTOCAGE_CHECKBOX = {
	["frFR"] = "Automatiquement les doublons de cage",
	["deDE"] = "Automatisch Käfig Duplikate",
	["enGB"] = "Automatically cage duplicates",
	["enUS"] = "Automatically cage duplicates",
	["itIT"] = "Automaticamente i duplicati di gabbia",
	["koKR"] = "자동으로 케이지 중복",
	["zhCN"] = "自动笼子里重复",
	["zhTW"] = "自動籠子裡重複",
	["ruRU"] = "Автоматически Кейдж дубликаты",
	["esES"] = "Automáticamente duplicados de jaula",
	["esMX"] = "Automáticamente duplicados de jaula",
	["ptBR"] = "Duplicatas de gaiola automaticamente",
};

L_AUTOCAGE_CHECKBOX_TOOLTIP = {
	["frFR"] = "Si activé, les animaux de compagnie en double qui s'apprend on mettra automatiquement dans une cage.",
	["deDE"] = "Wenn aktiviert, werden doppelte Haustiere, die erlernt werden automatisch in einen Käfig gesetzt.",
	["enGB"] = "If enabled, duplicate pets that get learnt will automatically be put in a cage.",
	["enUS"] = "If enabled, duplicate pets that get learnt will automatically be put in a cage.",
	["itIT"] = "Se abilitata, animali duplicati che avere imparati metterà automaticamente in una gabbia.",
	["koKR"] = "사용 하면 배운 얻을 중복 애완 동물 감 금 소에 게 자동으로 됩니다.",
	["zhCN"] = "如果启用，把学到的重复宠物自动将会在一个笼子里。",
	["zhTW"] = "如果啟用，把學到的重複寵物自動將會在一個籠子裡。",
	["ruRU"] = "Если этот параметр включен, повторяющиеся животные, которые научились получать автоматически ставится в клетке.",
	["esES"] = "Si se activa, automáticamente se pondrá mascotas duplicadas que haz aprendidas en una jaula.",
	["esMX"] = "Si se activa, automáticamente se pondrá mascotas duplicadas que haz aprendidas en una jaula.",
	["ptBR"] = "Se habilitado, animais de estimação duplicados que se aprendeu serão automaticamente colocados em uma gaiola.",
};

--[[
	AutoCage_GetLocalizedString
	Selects the localized string from a localization table.
]]
function AutoCage_GetLocalizedString(strings)
	if strings[GetLocale()] ~= nil then
		return strings[GetLocale()];
	end
	return "Unknown";
end

--[[
	AutoCage_HandleAutoCaging
	Takes the name of a pet and cages "duplicates".
]]
function AutoCage_HandleAutoCaging(petString)
	C_PetJournal.ClearSearchFilter(); -- Clear filter so we have a full pet list.
	local total, owned = C_PetJournal.GetNumPets();
	local found = false;

	for index = 1, owned do -- Loop every pet owned (unowned will be over the offset).
		local pGuid, _, _, pNickname, pLevel, pIsFav, _, pName = C_PetJournal.GetPetInfoByIndex(index);
		if pName == petString then
			if found and pLevel == 1 and not pIsFav then
				AutoCage_Message(petString .. " :: " .. AutoCage_GetLocalizedString(L_AUTOCAGE_CAGED_MESSAGE));
				C_PetJournal.CagePetByID(pGuid);
			else
				found = true;
			end
		end
	end
end

--[[
	AutoCage_Load
	Run set-up tasks when addon is loaded.
]]
function AutoCage_Load()

	if AutoCageEnabled == nil then
		-- No global enabled variable found, setting default.
		AutoCageEnabled = true;
	end

	-- Set the checkbox to the correct state now we've loaded.
	-- Technically AutoCage_Load is called before AutoCage_JournalHook but
	-- if for some reason it's not, this is a safety net for that.
	if AutoCage_EnabledButton ~= nil then
		AutoCage_EnabledButton:SetChecked(AutoCageEnabled);
	end
end

--[[
	AutoCage_JournalHook
	Hook our enable checkbox onto the journal frame.
]]
function AutoCage_JournalHook()
	if achasHooked then
		return;
	end

	-- Set-up enable/disable check-button.
	checkButton = CreateFrame("CheckButton", "AutoCage_EnabledButton", PetJournal, "ChatConfigCheckButtonTemplate");
	checkButton:SetPoint("LEFT", PetJournalSummonButton, "RIGHT", 10, -2);
	checkButton:SetChecked(AutoCageEnabled);
	AutoCage_EnabledButtonText:SetPoint("LEFT", checkButton, "RIGHT", -1, 0);
	AutoCage_EnabledButtonText:SetText(AutoCage_GetLocalizedString(L_AUTOCAGE_CHECKBOX));
	checkButton.tooltip = AutoCage_GetLocalizedString(L_AUTOCAGE_CHECKBOX_TOOLTIP);
	checkButton:SetScript("OnClick", 
	  function()
	    if AutoCageEnabled then
	    	AutoCageEnabled = false;
	    else
	    	AutoCageEnabled = true;
	    end
	  end
	);

	acHasHooked = true;
end

--[[
	AutoCage_Message
	Prints a formatted message to the default chat frame.
]]
function AutoCage_Message(msg)
	DEFAULT_CHAT_FRAME:AddMessage("\124cffc79c6eAutoCage:\124r \124cff69ccf0" .. msg .."\124r");
end

-- Event handling frame.
local eventFrame = CreateFrame("FRAME");
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM");
eventFrame:RegisterEvent("ADDON_LOADED");

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "CHAT_MSG_SYSTEM" and AutoCageEnabled then
		local msg, format = ...;
		local match = string.match(msg, petCagedPattern);
		if match ~= nil then
			AutoCage_HandleAutoCaging(match);
		end
	elseif event == "ADDON_LOADED" then
		local addon = ...;
		if addon == "Blizzard_Collections" then
			AutoCage_JournalHook();
		elseif addon == "AutoCage" then
			AutoCage_Load();

			if IsAddOnLoaded("Blizzard_Collections") then
				AutoCage_JournalHook();
			end
		end
	end
end);