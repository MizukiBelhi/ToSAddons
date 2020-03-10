
if mrg == nil then
	mrg = {};
	mrg.default = {};
	mrg.default.posX = 100;
	mrg.default.posY = 100;
	mrg.lockFrame = true;
	mrg.settings = {};
end


function MINIREWARDGAUGE_ON_INIT(addon, frame)
	
	mrg.LoadSettings();
	
	local acutil = require("acutil");
	acutil.slashCommand("/mrglock", MINIREWARDGAUGE_TOGGLE_LOCK);
	acutil.slashCommand("/mrgedit", MINIREWARDGAUGE_TOGGLE_EDIT);
	CHAT_SYSTEM("[MRG] Loaded");
	
	mrg.lockFrame = true;
end

function MINIREWARDGAUGE_TOGGLE_LOCK()
	if mrg.lockFrame == true then
		CHAT_SYSTEM("[MRG] Frame Unlocked");
		mrg.lockFrame = false;
	else
		CHAT_SYSTEM("[MRG] Frame Locked");
		mrg.lockFrame = true;
	end
end

function MINIREWARDGAUGE_TOGGLE_EDIT()
	if mrg.lockFrame == true then
		MINIREWARDGAUGE_TOGGLE_LOCK();
	end
	
	imcAddOn.BroadMsg("OPEN_INDUN_REWARD_HUD");
	CHAT_SYSTEM("[MRG] RewardGauge visible.");
end


function mrg.LoadSettings()
	local acutil = require("acutil");
	local settings, err = acutil.loadJSON("../addons/minirewardgauge/settings.json", mrg.default);

	if err then
		print("[MRG] Error loading Settings");
	end

	if settings == nil then
		settings = mrg.default;
		settings.posX = ui.GetFrame("indun_reward_hud"):GetX();
		settings.posY = ui.GetFrame("indun_reward_hud"):GetY();
	end

	mrg.settings = settings;
end

function mrg.SaveSettings()
	local acutil = require("acutil");
	acutil.saveJSON("../addons/minirewardgauge/settings.json", mrg.settings);
end


function MINIREWARDGAUGE_PROCESS_MOUSE(parent, ctrl)
	if mrg.lockFrame == true then
		return;
	end
	
	local frame = parent:GetTopParentFrame();
        
	local mx, my = GET_MOUSE_POS();
	mx = mx / ui.GetRatioWidth();
	my = my / ui.GetRatioHeight();
	frame:SetUserValue("MOUSE_X", mx);
	frame:SetUserValue("MOUSE_Y", my);
	frame:SetUserValue("BEFORE_W", frame:GetX());
	frame:SetUserValue("BEFORE_H", frame:GetY());
	
	
	frame:RunUpdateScript("MINIREWARDGAUGE_PROCESS_MOVE");
end

function MINIREWARDGAUGE_PROCESS_MOVE(ctrl)
	local frame = ctrl:GetTopParentFrame();

	if mouse.IsLBtnPressed() == 0 then
		mrg.SaveSettings();
		return 0;
	end
	
	local mx, my = GET_MOUSE_POS();
	mx = mx / ui.GetRatioWidth();
	my = my / ui.GetRatioHeight();
	local x = frame:GetUserIValue("MOUSE_X");
	local y = frame:GetUserIValue("MOUSE_Y");
	local dx = mx - x;
	local dy = my - y;
	

	local width = frame:GetUserIValue("BEFORE_W");
	local height = frame:GetUserIValue("BEFORE_H");
	dx = width + dx;
	dy = height + dy;

	mrg.settings.posX = dx;
	mrg.settings.posY = dy;
	mrg.SaveSettings();
	frame:SetOffset(dx, dy);
	
	return 1;
end


function INDUN_REWARD_HUD_OPEN(frame, msg, argStr, argNum)
    frame:ShowWindow(1);

    if argStr == nil then
        return
    end

    if argNum == nil then
        argNum = 0;
    end
	
	frame:Resize(100, 40);

	frame:MoveFrame(mrg.settings.posX, mrg.settings.posY);
	
	local drag = frame:CreateOrGetControl("picture", "drag", 0, 0, 100, 40);
	AUTO_CAST(drag);
	drag:EnableHitTest(1);
	drag:SetEventScript(ui.LBUTTONDOWN, "MINIREWARDGAUGE_PROCESS_MOUSE");

	
	for i = 1, 5 do
		local rewardPic = GET_CHILD_RECURSIVELY(frame, 'rewardPic' .. i);
		rewardPic:ShowWindow(0);
	
		local rewardTxt = GET_CHILD_RECURSIVELY(frame, 'rewardText' .. i);
		rewardTxt:ShowWindow(0);
	end
	
	local rewardGauge = GET_CHILD_RECURSIVELY(frame, 'rewardGauge');
	rewardGauge:ShowWindow(0);
	
	
	local percentText = GET_CHILD_RECURSIVELY(frame, 'percentText');
	percentText:SetMargin(50, 0, 0, 0);
	percentText:SetOffset(0, 12);
	percentText:EnableHitTest(0)
	
	local monPic = GET_CHILD_RECURSIVELY(frame, 'monPic');
	monPic:EnableHitTest(0)
	
	local infoText = GET_CHILD_RECURSIVELY(frame, 'infoText');
	infoText:ShowWindow(0);

	if argStr == "RiftDungeon" then
		INDUN_REWARD_HUD_SET_POINT(frame, argNum, true);
	else
		local indunCls = GetClass('Indun', argStr);
		if TryGetProp(indunCls, 'DungeonType', 'None') == 'MissionIndun' then
			INDUN_REWARD_HUD_SET_POINT(frame, argNum, false);
		else
			INDUN_REWARD_HUD_SET_POINT(frame, argNum, true);
		end
	end

end