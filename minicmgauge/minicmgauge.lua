
if mcg == nil then
	mcg = {};
	mcg.default = {};
	mcg.default.posX = 100;
	mcg.default.posY = 100;
	mcg.lockFrame = true;
	mcg.settings = {};
	mcg.currentLevel = 0;
	CHAT_SYSTEM("[MCG] Loaded");
end


function MINICMGAUGE_ON_INIT(addon, frame)
	
	mcg.LoadSettings();
	
	local acutil = require("acutil");
	acutil.slashCommand("/cmlock", MINICMGAUGE_TOGGLE_LOCK);
	acutil.slashCommand("/cmedit", MINICMGAUGE_TOGGLE_EDIT);
	
	mcg.lockFrame = true;
	
	ON_CHALLENGE_MODE_TOTAL_KILL_COUNT(ui.GetFrame("challenge_mode"), "EDIT", "none#none");
	ui.GetFrame("minicmgauge"):ShowWindow(0);
	ui.GetFrame("challenge_mode"):ShowWindow(0);
end

function MINICMGAUGE_TOGGLE_LOCK()
	if mcg.lockFrame == true then
		CHAT_SYSTEM("[MCG] Frame Unlocked");
		mcg.lockFrame = false;
		
		local drag = GET_CHILD_RECURSIVELY(ui.GetFrame("minicmgauge"), "drag");
		if drag ~= nil then
			AUTO_CAST(drag);
			drag:FillClonePicture("AA000000");
		end
	else
		CHAT_SYSTEM("[MCG] Frame Locked");
		mcg.lockFrame = true;
		
		local drag = GET_CHILD_RECURSIVELY(ui.GetFrame("minicmgauge"), "drag");
		if drag ~= nil then
			AUTO_CAST(drag);
			drag:FillClonePicture("00000000");
		end
	end
end

function MINICMGAUGE_TOGGLE_EDIT()
	if mcg.lockFrame == true then
		MINICMGAUGE_TOGGLE_LOCK();
	end
	
	ON_CHALLENGE_MODE_TOTAL_KILL_COUNT(ui.GetFrame("challenge_mode"), "EDIT", "none#none");
	
	ui.GetFrame("challenge_mode"):ShowWindow(1);
	
	CHAT_SYSTEM("[MCG] CMGauge visible.");
end


function mcg.LoadSettings()
	local acutil = require("acutil");
	local settings, err = acutil.loadJSON("../addons/minicmgauge/settings.json", mcg.default);

	if err then
		print("[MCG] Error loading Settings");
	end

	if settings == nil then
		settings = mcg.default;
		settings.posX = ui.GetFrame("challenge_mode"):GetX();
		settings.posY = ui.GetFrame("challenge_mode"):GetY();
	end

	mcg.settings = settings;
end

function mcg.SaveSettings()
	local acutil = require("acutil");
	acutil.saveJSON("../addons/minicmgauge/settings.json", mcg.settings);
end


function MINICMGAUGE_PROCESS_MOUSE(parent, ctrl)
	if mcg.lockFrame == true then
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
	
	
	frame:RunUpdateScript("MINICMGAUGE_PROCESS_MOVE");
end

function MINICMGAUGE_PROCESS_MOVE(ctrl)
	local frame = ctrl:GetTopParentFrame();

	if mouse.IsLBtnPressed() == 0 then
		mcg.SaveSettings();
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

	mcg.settings.posX = dx;
	mcg.settings.posY = dy;
	mcg.SaveSettings();
	frame:SetOffset(dx, dy);
	
	return 1;
end


function ON_CHALLENGE_MODE_TOTAL_KILL_COUNT(frame, msg, str, arg)
	local msgList = StringSplit(str, '#');
	if #msgList < 1 then
		return;
	end
	
	--The frame cannot be hidden otherwise the timer stops working
	frame:Resize(1, 1);
	frame:MoveFrame(mcg.settings.posX, mcg.settings.posY);
	frame:SetSkinName("None");
	frame:ShowWindow(1);
	
	local miniFrame = ui.GetFrame("minicmgauge");
	miniFrame:ShowWindow(1);
	miniFrame:Resize(200, 60);
	miniFrame:MoveFrame(mcg.settings.posX, mcg.settings.posY);
	miniFrame:SetSkinName("None");
	
	
	local picMax = GET_CHILD(frame, "challenge_pic_max", "ui::CPicture");
	picMax:ShowWindow(0);
	
	local challenge_pic_logo = GET_CHILD(frame, "challenge_pic_logo", "ui::CPicture");
	challenge_pic_logo:ShowWindow(0);
	
	local picLevel = GET_CHILD(frame, "challenge_pic_lv", "ui::CPicture");
	picLevel:ShowWindow(0);
	
	local textTimer = GET_CHILD(frame, "challenge_mode_timer", "ui::CPicture");
	--textTimer:ShowWindow(0);
	
	local picTimer = GET_CHILD(frame, "challenge_time", "ui::CPicture");
	--picTimer:ShowWindow(0);
	
	local cmbg = GET_CHILD_RECURSIVELY(frame, "challenge_pic_lv_bg");
	AUTO_CAST(cmbg);
	cmbg:SetImage("");
	
	local progressGauge = GET_CHILD(frame, "challenge_gauge_lv", "ui::CGauge");
	AUTO_CAST(progressGauge);
	progressGauge:ShowWindow(0);
	
	
	
	local bgimg = miniFrame:CreateOrGetControl("picture", "bg", 0, 0, 200, 60);
	AUTO_CAST(bgimg);
	bgimg:SetImage("minicmbg");
	bgimg:Resize(200,100);
	bgimg:SetOffset(0, 0);
	bgimg:SetMargin(0, 0, 0, 0);
	bgimg:EnableHitTest(0);
	

	local levelText = miniFrame:CreateOrGetControl("richtext", "lvlTexts", 50, 25, 150, 40);
	AUTO_CAST(levelText);
	levelText:SetText("{@st43}{s20}Lv: "..(mcg.currentLevel or 0));
	levelText:EnableHitTest(0);
	levelText:SetOffset(75, 5);

	
	local cmText = miniFrame:CreateOrGetControl("richtext", "cmTexts", 0, 8, 150, 40);
	AUTO_CAST(cmText);
	cmText:SetText("{@st43}{s20}CM");
	cmText:EnableHitTest(0);
	cmText:SetOffset(5, 5);
	

	local cmPText = miniFrame:CreateOrGetControl("richtext", "cmPercentText", 50, 8, 150, 40);
	AUTO_CAST(cmPText);
	cmPText:EnableHitTest(0);
	cmPText:SetOffset(5, 25);
	

	local mingauge = miniFrame:CreateOrGetControl("gauge", "gauge", 0, 0, 198, 10);
	AUTO_CAST(mingauge);
	mingauge:Resize(190, 10);
	mingauge:SetOffset(5, 47);
	mingauge:SetSkinName("minicm_gauge");
	mingauge:EnableHitTest(0);
	

	local timePic = miniFrame:GetChild("ttext");
	if timePic == nil then
		timePic= miniFrame:CreateOrGetControl("richtext", "ttext", 0, 0, 23, 23);
		AUTO_CAST(timePic);
		timePic:SetOffset(135, 25);
		timePic:EnableHitTest(0);
		timePic:RunUpdateScript("MCG_TIMER_UPDATE");
	else
		AUTO_CAST(timePic);
		timePic:RunUpdateScript("MCG_TIMER_UPDATE");
	end

	local _drg = GET_CHILD_RECURSIVELY(miniFrame, "drag");
	if _drg ~= nil then
		frame:RemoveChild("drag");
	end
	
	local drag = miniFrame:CreateOrGetControl("picture", "drag", 0, 0, 200, 60);
	AUTO_CAST(drag);
	drag:CreateInstTexture();
	drag:FillClonePicture("00000000");
	if mcg.lockFrame == false then
		drag:FillClonePicture("AA000000");
	end
	drag:EnableHitTest(1);

	drag:SetEventScript(ui.LBUTTONDOWN, "MINICMGAUGE_PROCESS_MOUSE");
	
	if tostring(msg) == "EDIT" then
		levelText:SetText("{@st43}{s20}Lv: 1");
		mingauge:SetMaxPointWithTime(1, 1, 0.1, 0.5);
		cmPText:SetText("{@st43}{s20}0%");
		timePic:SetText("{@st43}{s20}00:00");
	end
	
	
	if msgList[1] == "SHOW" then
		ui.OpenFrame("challenge_mode");
		frame:ShowWindow(1);

		local challenge_pic_logo = GET_CHILD(frame, "challenge_pic_logo", "ui::CPicture");
		challenge_pic_logo:SetImage("challenge_text");
		
		local level = tonumber(msgList[2]);
		local progressGauge = GET_CHILD(frame, "challenge_gauge_lv", "ui::CGauge");
		progressGauge:SetSkinName("challenge_gauge_lv1");
		progressGauge:SetMaxPointWithTime(0, 1, 0.1, 0.5);
		
		mingauge:SetMaxPointWithTime(0, 1, 0.1, 0.5);
		
		mcg.currentLevel = 1;
		

		local picMax = GET_CHILD(frame, "challenge_pic_max", "ui::CPicture");
		picMax:ShowWindow(0);
		picMax:StopUpdateScript("MAX_PICTURE_FADEINOUT");
		
		local picLevel = GET_CHILD(frame, "challenge_pic_lv", "ui::CPicture");
		picLevel:SetImage("challenge_gauge_no" .. level);

		local textTimer = GET_CHILD(frame, "challenge_mode_timer", "ui::CPicture");
		textTimer:SetTextByKey('time', "00:00");
		timePic:SetText("{@st43}{s20}00:00");

	elseif msgList[1] == "HIDE" then
		frame:ShowWindow(0);
		miniFrame:ShowWindow(0);
		
		mcg.currentLevel = 0;
		
		local picMax = GET_CHILD(frame, "challenge_pic_max", "ui::CPicture");
		picMax:ShowWindow(0);
		picMax:StopUpdateScript("MAX_PICTURE_FADEINOUT");
		
		local textTimer = GET_CHILD(frame, "challenge_mode_timer", "ui::CPicture");
		textTimer:StopUpdateScript("CHALLENGE_MODE_TIMER");

	elseif msgList[1] == "GAUGERESET" then
		frame:ShowWindow(1);

		local level = tonumber(msgList[2]);
		local progressGauge = GET_CHILD(frame, "challenge_gauge_lv", "ui::CGauge");
		progressGauge:SetSkinName("challenge_gauge_lv" .. math.floor((level - 1) / 2) + 1);
		progressGauge:SetMaxPointWithTime(0, 1, 0.1, 0.5);
		
		mingauge:SetMaxPointWithTime(0, 1, 0.1, 0.5);

		mcg.currentLevel = level;
		
		levelText:SetText("{@st43}{s20}Lv: "..mcg.currentLevel);
		
		local picMax = GET_CHILD(frame, "challenge_pic_max", "ui::CPicture");
		picMax:ShowWindow(0);
		picMax:StopUpdateScript("MAX_PICTURE_FADEINOUT");

		local textTimer = GET_CHILD(frame, "challenge_mode_timer", "ui::CPicture");
		textTimer:StopUpdateScript("CHALLENGE_MODE_TIMER");
	elseif msgList[1] == "START_CHALLENGE_TIMER" then
		frame:ShowWindow(1);

		local textTimer = GET_CHILD(frame, "challenge_mode_timer", "ui::CPicture");
		--textTimer:StopUpdateScript("CHALLENGE_MODE_TIMER");
		textTimer:RunUpdateScript("CHALLENGE_MODE_TIMER");

		textTimer:SetUserValue("CHALLENGE_MODE_START_TIME", tostring(imcTime.GetAppTimeMS()));
		textTimer:SetUserValue("CHALLENGE_MODE_LIMIT_TIME", msgList[2]);
		
	elseif msgList[1] == "REFRESH" then
		frame:ShowWindow(1);

		local killCount = tonumber(msgList[2]);
		local targetKillCount = tonumber(msgList[3]);
		local progressGauge = GET_CHILD(frame, "challenge_gauge_lv", "ui::CGauge");
		progressGauge:SetMaxPointWithTime(killCount, targetKillCount, 0.1, 0.5);
		--progressGauge:ShowWindow(1);
		
		mingauge:SetMaxPointWithTime(killCount, targetKillCount, 0.1, 0.5);
		
		local kcPercent = (100/targetKillCount)*killCount;
		kcPercent = math.floor(kcPercent);
		
		if kcPercent > 100 then
			kcPercent = 100;
		end
		
		cmPText:SetText("{@st43}{s20}"..tostring(kcPercent).."%");
	elseif msgList[1] == "MONKILLMAX" then
		--rame:ShowWindow(1);
		
		local picMax = GET_CHILD(frame, "challenge_pic_max", "ui::CPicture");
		picMax:ShowWindow(0);
		picMax:RunUpdateScript("MAX_PICTURE_FADEINOUT", 0.01);
	end
	--frame:ShowWindow(0);
end


function MCG_TIMER_UPDATE(timer)
	local frm = ui.GetFrame("challenge_mode");
	if frm == nil then return 1; end
	
	local otherTimer = frm:GetChild("challenge_mode_timer");
	
	if otherTimer == nil then return 1; end
	
	local theTime = otherTimer:GetTextByKey("time");
	
	local miniFrm = ui.GetFrame("minicmgauge");
	if miniFrm ~= nil then
		local timeText = miniFrm:GetChild("ttext");
		AUTO_CAST(timeText);
		timeText:SetText("{@st43}{s20}"..theTime);
	end
	
	return 1;
end