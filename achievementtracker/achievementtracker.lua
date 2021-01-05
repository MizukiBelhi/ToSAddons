if STATUS_ACHIEVE_SETTINGS == nil then
	STATUS_ACHIEVE_SETTINGS = {};
	STATUS_ACHIEVE_SETTINGS.posx = 400;
	STATUS_ACHIEVE_SETTINGS.posy = 150;
	STATUS_ACHIEVE_SETTINGS.locked = true;
	STATUS_ACHIEVE_SETTINGS.through = false;
	STATUS_ACHIEVE_SETTINGS.hidden = false;
	STATUS_ACHIEVE_SETTINGS.LOGGED = {};
end

STATUS_ACHIEVE_DEFAULTS = {};
STATUS_ACHIEVE_DEFAULTS.posx = 400;
STATUS_ACHIEVE_DEFAULTS.posy = 150;
STATUS_ACHIEVE_DEFAULTS.locked = true;
STATUS_ACHIEVE_DEFAULTS.through = false;
STATUS_ACHIEVE_DEFAULTS.hidden = false;
STATUS_ACHIEVE_DEFAULTS.LOGGED = {};
STATUS_ACHIEVE_CURRY = 0;

function ACHIEVEMENTTRACKER_ON_INIT(addon, frame)
	addon:RegisterMsg("GAME_START_3SEC", "LOAD_AT");
end

function LOAD_AT()
	local acutil = require("acutil");
	local settings, err = acutil.loadJSON("../addons/achievementtracker/settings.json", STATUS_ACHIEVE_DEFAULTS);

	if err then
		print("[AT] Error loading Settings");
	end

	if settings == nil then
		settings = STATUS_ACHIEVE_DEFAULTS;
	end

	STATUS_ACHIEVE_SETTINGS = settings;
	
	local frm = ui.GetFrame("achievementTracker");
	if ui.GetFrame("achievementTracker") == nil then
		frm = ui.CreateNewFrame("questinfoset_2", "achievementTracker");
		frm:RemoveChild('quest_custom');
		frm:RemoveChild('quest_custom_name');
		frm:RemoveChild('member');
		frm:RemoveChild('openMark');
		frm:RemoveChild('gbQuestInfoTitle');
		frm:RemoveChild('warptimer');
	end

	local title = GET_CHILD(frm, 'name', 'ui::CRichText');
	title:SetText('{@st43b}{s16}Achievement Tracker');
	title:SetOffset(70, 4);
	
	frm:Resize(240,630);
	
	--print(frm:GetWidth()..","..frm:GetHeight());
	frm:RemoveChild('member');
	local gbox = frm:CreateOrGetControl("groupbox", "member", 0, 0, 240, 50);
	AUTO_CAST(gbox);
	

	gbox:ShowWindow(STATUS_ACHIEVE_SETTINGS.hidden == true and 0 or 1)

	
	local button = frm:CreateOrGetControl("picture", "UntrackAll", frm:GetWidth()-62, 5, 20, 20);
	AUTO_CAST(button);
	button:SetText('{img M_selectAll_btn 20 20}');
	button:SetTextTooltip("{@st42b}Untrack All{/}");
	button:SetEventScript(ui.LBUTTONUP, "AT_UNTRACK_ALL");
	
	button = frm:CreateOrGetControl("picture", "UntrackCompleted", frm:GetWidth()-42, 5, 20, 20);
	AUTO_CAST(button);
	button:SetText('{img M-delete_btn 20 20}');
	button:SetTextTooltip("{@st42b}Untrack Completed{/}");
	button:SetEventScript(ui.LBUTTONUP, "AT_UNTRACK_COMPLETED");
	
	button = frm:CreateOrGetControl("picture", "HideTracked", frm:GetWidth()-22, 5, 20, 20);
	AUTO_CAST(button);
	button:SetText('{img plus_button 20 20}');
	button:SetTextTooltip("{@st42b}Toggle Hidden{/}");
	button:SetEventScript(ui.LBUTTONUP, "AT_TOGGLE_HIDE");
	
	local _drg = GET_CHILD_RECURSIVELY(frm, "drag");
	if _drg ~= nil then
		frm:RemoveChild("drag");
	end
	
	local drag = frm:CreateOrGetControl("picture", "drag", 0, 0, frm:GetWidth(), frm:GetHeight());
	AUTO_CAST(drag);
	drag:ShowWindow(1);
	drag:CreateInstTexture();
	if STATUS_ACHIEVE_SETTINGS.locked == false then
		drag:FillClonePicture("AA000000");
	else
		drag:FillClonePicture("00000000");
		drag:ShowWindow(0);
	end
	drag:EnableHitTest(1);

	drag:SetEventScript(ui.LBUTTONDOWN, "AT_PROCESS_MOUSE");
	
	frm:SetSkinName('status');
	frm:EnableHitTest(STATUS_ACHIEVE_SETTINGS.through and 0 or 1);
	
	frm:MoveFrame(STATUS_ACHIEVE_SETTINGS.posx, STATUS_ACHIEVE_SETTINGS.posy);
	frm:RunUpdateScript("AT_UPDATE_ACHIEVEMENTS");
	
	if AT_tablelength(STATUS_ACHIEVE_SETTINGS.LOGGED) ~= 0 then
		for idx,_ in pairs(STATUS_ACHIEVE_SETTINGS.LOGGED) do
			AT_ADD(tonumber(idx));
		end
	end
end

function AT_TOGGLE_HIDE()
	local frm = ui.GetFrame("achievementTracker");
	if frm == nil then return 0; end
	local gbox = GET_CHILD(frm, 'member', 'ui::CGroupBox');
	
	STATUS_ACHIEVE_SETTINGS.hidden = not STATUS_ACHIEVE_SETTINGS.hidden;
	gbox:ShowWindow(STATUS_ACHIEVE_SETTINGS.hidden == true and 0 or 1);

	AT_SAVE();
end

function AT_UNTRACK_ALL()
	if AT_tablelength(STATUS_ACHIEVE_SETTINGS.LOGGED) ~= 0 then
		for idx,_ in pairs(STATUS_ACHIEVE_SETTINGS.LOGGED) do
			AT_REMOVE(tonumber(idx));
		end
	end
	
	AT_ACHIEVE();
end

function AT_UNTRACK_COMPLETED()
	if AT_tablelength(STATUS_ACHIEVE_SETTINGS.LOGGED) ~= 0 then
		local clslist, clscnt = GetClassList("Achieve");
		for idx,_ in pairs(STATUS_ACHIEVE_SETTINGS.LOGGED) do

			local cls = GetClassByIndexFromList(clslist, tonumber(idx));
			if cls ~= nil then

				local nowpoint = GetAchievePoint(GetMyPCObject(), cls.NeedPoint);
				local per = (100/cls.NeedCount)*nowpoint;
				
				if per >= 100 then
					AT_REMOVE(tonumber(idx));
				end
			end
		end
	end
	AT_ACHIEVE();
end

function AT_SAVE()
	local acutil = require("acutil");
	acutil.saveJSON("../addons/achievementtracker/settings.json", STATUS_ACHIEVE_SETTINGS);
end

function AT_tablelength(T)
  	local count = 0
  	for _ in pairs(T) do count = count + 1 end
  	return count
end

function AT_PROCESS_MOUSE(parent, ctrl)
	if STATUS_ACHIEVE_SETTINGS.locked == true then
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
	
	frame:RunUpdateScript("AT_PROCESS_MOVE");
end

function AT_PROCESS_MOVE(ctrl)
	local frame = ctrl:GetTopParentFrame();

	if mouse.IsLBtnPressed() == 0 then
		AT_SAVE();
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

	STATUS_ACHIEVE_SETTINGS.posx = dx;
	STATUS_ACHIEVE_SETTINGS.posy = dy;
	AT_SAVE();
	frame:SetOffset(dx, dy);
	
	return 1;
end

function AT_ADD(aid)

	local t,p = pcall(AT_ADDS, aid);
	if not(t) then
		print("[AT] "..tostring(p));
	end

end

function AT_ADDS(aid)
	local frm = ui.GetFrame("achievementTracker");
	if frm == nil then return 0; end
	
	local clslist, clscnt = GetClassList("Achieve");
	local cls = GetClassByIndexFromList(clslist, aid);
	if cls == nil then
		return 0; --achievement doesnt exist
	end
	
	
	local gbox = GET_CHILD(frm, 'member', 'ui::CGroupBox');
	gbox:SetOffset(0,25);
	gbox:SetGravity(ui.LEFT, ui.TOP);
	gbox:EnableHitTest(1);
	local ctrlset = gbox:CreateOrGetControlSet('emptyset2', 'at_entry_'..tostring(aid), 0, 30);
	tolua.cast(ctrlset, 'ui::CControlSet');
	local topFrame = ui.GetFrame('questinfoset_2');
	local ctrlSetSkinName = topFrame:GetUserConfig('CTRLSETSKINNAME');
	ctrlset:SetSkinName(ctrlSetSkinName);
	ctrlset:Resize(gbox:GetWidth() - gbox:GetX(), ctrlset:GetHeight());
	ctrlset:EnableHitTest(1);
	local omitByWidth = topFrame:GetUserConfig('TITLE_OMITBYTWIDTH');
	local fixWidth = topFrame:GetUserConfig('TITLE_FIXWIDTH');
	
	local content = ctrlset:CreateOrGetControl('richtext', 'title', -5, 5, ctrlset:GetWidth(), 60);
	if content ~=nil then
		content:SetTextTooltip('{@st42b}'..cls.Desc..'{/}');
		content:EnableHitTest(1);
		content:SetTextAlign("right","right");
		if omitByWidth ~= nil then
			content:EnableTextOmitByWidth(tonumber(omitByWidth));
		end

		if fixWidth ~= nil then
			content:SetTextFixWidth(tonumber(fixWidth));
		end
		--QUEST_TITLE_FONT..
		content:SetText('{@st42_red_small}{#ff9000}'..cls.DescTitle);
	end
	
	local te = GET_CHILD(ctrlset, 'gauge', 'ui::CPicture');
	local gaug2 = nil;
	local gaug = nil;
	
	local gaugeOffset = 20;
	
	if te == nil then
		gaug = ctrlset:CreateOrGetControl("picture", "gauge", 10, 30, ctrlset:GetWidth()-gaugeOffset, 15);
		tolua.cast(gaug, "ui::CPicture");
		gaug:ShowWindow(1);
		gaug:EnableHitTest(0);
		gaug:CreateInstTexture();
		gaug:FillClonePicture("DD222222");
		
		gaug2 = gaug:CreateOrGetControl("picture", "gauge", 1, 1, ctrlset:GetWidth()-gaugeOffset-2, 13);
		tolua.cast(gaug2, "ui::CPicture");
		gaug2:ShowWindow(1);
		gaug2:EnableHitTest(0);
		gaug2:CreateInstTexture();
		gaug2:FillClonePicture("FF11AAAA");
	end
	gaug = ctrlset:CreateOrGetControl("picture", "gauge", 10, 20, ctrlset:GetWidth()-gaugeOffset, 15);
	gaug2 = gaug:CreateOrGetControl("picture", "gauge", 1, 1, ctrlset:GetWidth()-gaugeOffset-2, 13);
	
	local nowpoint = GetAchievePoint(GetMyPCObject(), cls.NeedPoint);
	local per = (100/cls.NeedCount)*nowpoint;
	local neededWidth = (gaug2:GetWidth())*(per/100);
	
	local pointText = ctrlset:CreateOrGetControl('richtext', 'point', 0, 8, ctrlset:GetWidth(), 60);
	pointText:SetText("{@st42}{#AAAAAA}(" .. nowpoint .. "/" .. cls.NeedCount .. ")");
	pointText:EnableHitTest(0);
	pointText:SetTextAlign("right","right");
	pointText:SetOffset(-10, 8);
	
	AT_DRAW_GAUGE(ctrlset, 0, 0, neededWidth, gaug2:GetWidth(), 13);
	
	STATUS_ACHIEVE_SETTINGS.LOGGED[tostring(aid)] = 1;

	AT_REBUILD();
	AT_SAVE();
end

function AT_REMOVE(aid)
	local frm = ui.GetFrame('achievementTracker');
	if frm == nil then return 0; end
	
	local gbox = GET_CHILD(frm, 'member', 'ui::CGroupBox');
	gbox:RemoveChild('at_entry_'..tostring(aid));
	
	STATUS_ACHIEVE_SETTINGS.LOGGED[tostring(aid)] = nil;
	
	AT_REBUILD();
	AT_SAVE();
end

function AT_REBUILD()
	local frm = ui.GetFrame('achievementTracker');
	if frm == nil then return 0; end
	local gbox = GET_CHILD(frm, 'member', 'ui::CGroupBox');
	STATUS_ACHIEVE_CURRY = 0
	
	for idx,_ in pairs(STATUS_ACHIEVE_SETTINGS.LOGGED) do
		print("[AT] Rebuilding: "..tostring(idx));
		
		local ctrl = GET_CHILD(gbox, 'at_entry_'..tostring(idx), 'ui::CControlSet');
		if ctrl ~= nil then
			tolua.cast(ctrl, 'ui::CControlSet');
			ctrl:SetOffset(ctrl:GetX(), STATUS_ACHIEVE_CURRY);
			
			STATUS_ACHIEVE_CURRY = STATUS_ACHIEVE_CURRY+35
		end
	end
	gbox:Resize(240, STATUS_ACHIEVE_CURRY+35);
end

function AT_UPDATE_ACHIEVEMENTS()

	local t,p = pcall(AT_UPDATE_ACHIEVEMENTSS);
	if not(t) then
		print("[AT] "..tostring(p));
	end
	
	return 1;

end

function AT_UPDATE_ACHIEVEMENTSS()
	local frm = ui.GetFrame('achievementTracker');
	if frm == nil then return 1; end
	local gbox = GET_CHILD(frm, 'member', 'ui::CGroupBox');
	if gbox == nil then return 1; end
	
	local title = GET_CHILD(frm, 'name', 'ui::CRichText');
	title:SetText('{@st43b}{s16}Achievement Tracker');
	
	if AT_tablelength(STATUS_ACHIEVE_SETTINGS.LOGGED) ~= 0 then
		local clslist, clscnt = GetClassList("Achieve");
		for idx,_ in pairs(STATUS_ACHIEVE_SETTINGS.LOGGED) do
			local ctrl = GET_CHILD(gbox, 'at_entry_'..tostring(idx), 'ui::CControlSet');
			if ctrl ~= nil then
				tolua.cast(ctrl, 'ui::CControlSet');
				
				local cls = GetClassByIndexFromList(clslist, tonumber(idx));
				if cls ~= nil then
					local gaugebg = GET_CHILD(ctrl, 'gauge', 'ui::CPicture');
					local gauge = GET_CHILD(gaugebg, 'gauge', 'ui::CPicture');

					local nowpoint = GetAchievePoint(GetMyPCObject(), cls.NeedPoint);
					local per = (100/cls.NeedCount)*nowpoint;
					local neededWidth = (gaugebg:GetWidth()-2)*(per/100);
					
					
					
					local pointText = ctrl:CreateOrGetControl('richtext', 'point', 20, 28, ctrl:GetWidth(), 60);
					pointText:SetTextAlign("right","right");
					pointText:SetOffset(-8, 21);
					
					if per < 100 then
						AT_DRAW_GAUGE(ctrl, 0, 0, neededWidth, gaugebg:GetWidth()-2, 13);
						pointText:SetText("{@st42_red_small}{#AAAAAA}(" .. nowpoint .. "/" .. cls.NeedCount .. ")");
						pointText:EnableHitTest(0);
					else
						gaugebg:ShowWindow(0);
						gauge:ShowWindow(0);
						
						pointText:SetText('{img medal 28 28}');
					end
				end
			end
		end
	end
	return 1;
end

function AT_SHOW_CONTROLS(tabIndex)
	local statusFrame = ui.GetFrame("status");
	if tabIndex == 1 then
		local ctrls = statusFrame:CreateOrGetControl("richtext", "at_title", 15, 135, 150, 24);
		AUTO_CAST(ctrls);
		ctrls:SetText('{@st42}Tracker:');
		ctrls:ShowWindow(1);
		
		ctrls = statusFrame:CreateOrGetControl("checkbox", "at_lock", 100, 135, 150, 24);
		ctrls = tolua.cast(ctrls, "ui::CCheckBox");
		ctrls:SetText("{@st42}Lock Tracker");
		ctrls:SetClickSound("button_click_big");
		ctrls:SetOverSound("button_over");
		--ctrls:SetTextTooltip("{@st42b}Lock Tracker{/}");
		ctrls:SetEventScript(ui.LBUTTONUP, "AT_ON_LOCK");
		ctrls:SetCheck(STATUS_ACHIEVE_SETTINGS.locked and 1 or 0);
		ctrls:ShowWindow(1);
		
		ctrls = statusFrame:CreateOrGetControl("checkbox", "at_through", 230, 135, 24, 24);
		ctrls = tolua.cast(ctrls, "ui::CCheckBox");
		ctrls:SetText("{@st42}Enable Clickthrough");
		ctrls:SetClickSound("button_click_big");
		ctrls:SetOverSound("button_over");
		--ctrls:SetTextTooltip("{@st42b}Enable Clickthrough{/}");
		ctrls:SetEventScript(ui.LBUTTONUP, "AT_ON_THROUGH");
		ctrls:SetCheck(STATUS_ACHIEVE_SETTINGS.through and 1 or 0);
		ctrls:ShowWindow(1);
	else
		local ctrls = statusFrame:CreateOrGetControl("checkbox", "at_lock", 50, 135, 24, 24);
		ctrls:ShowWindow(0);
		ctrls = statusFrame:CreateOrGetControl("checkbox", "at_through", 50, 135, 24, 24);
		ctrls:ShowWindow(0);
		ctrls = statusFrame:CreateOrGetControl("richtext", "at_title", 5, 135, 150, 24);
		ctrls:ShowWindow(0);
	end
end


function AT_ON_THROUGH(frame, ctrl)
	local frm = ui.GetFrame("achievementTracker");
	if frm == nil then
		return 1;
	end

	local isCheck = ctrl:IsChecked();
	frm:EnableHitTest(isCheck == 1 and 0 or 1);
	
	STATUS_ACHIEVE_SETTINGS.through = isCheck == 1 and true or false;
	
	AT_SAVE();
end


function AT_ON_LOCK(frame, ctrl)
	local id = tonumber(argStr);
	local isCheck = ctrl:IsChecked();
	
	STATUS_ACHIEVE_SETTINGS.locked = isCheck == 1 and true or false;
	
	
	local frm = ui.GetFrame("achievementTracker");
	if frm == nil then return 0; end
	
	local _drg = GET_CHILD_RECURSIVELY(frm, "drag");
	if _drg ~= nil then
		frm:RemoveChild("drag");
	end
	
	local drag = frm:CreateOrGetControl("picture", "drag", 0, 0, frm:GetWidth(), frm:GetHeight());
	AUTO_CAST(drag);
	drag:ShowWindow(1);
	drag:CreateInstTexture();
	if STATUS_ACHIEVE_SETTINGS.locked == false then
		drag:FillClonePicture("AA000000");
	else
		drag:FillClonePicture("00000000");
		drag:ShowWindow(0);
	end
	drag:EnableHitTest(1);

	drag:SetEventScript(ui.LBUTTONDOWN, "AT_PROCESS_MOUSE");
	AT_SAVE();
end

function ACHIEVE_ON_TRACK(frame, ctrl, argStr)
	local id = tonumber(argStr);
	local isCheck = ctrl:IsChecked();
	
	STATUS_ACHIEVE_SETTINGS.LOGGED[tostring(id)] = isCheck;
	
	if isCheck == 0 then
		STATUS_ACHIEVE_SETTINGS.LOGGED[tostring(id)] = nil;
		AT_REMOVE(id);
	else
		AT_ADD(id);
	end
	
	print("logged "..argStr.." ch: "..tostring(isCheck));
	
end

function AT_DRAW_GAUGE(ctrlset, xPos, yPos, width, fullwidth, height, color)

	local gaugebg = GET_CHILD(ctrlset, 'gauge', 'ui::CPicture');
	local gauge = GET_CHILD(gaugebg, 'gauge', 'ui::CPicture');
	gauge:Resize(width, height);

end


function STATUS_VIEW(frame, curtabIndex)
    if curtabIndex == 0 then
        STATUS_INFO_VIEW(frame);
    elseif curtabIndex == 1 then
        STATUS_ACHIEVE_VIEW(frame);
    elseif curtabIndex == 2 then
        STATUS_LOGOUTPC_VIEW(frame);
    end
	
	AT_SHOW_CONTROLS(curtabIndex);
end



function ACHIEVE_RESET(frame)
	DebounceScript("STATUS_ACHIEVE_INIT", 0.5, 0);
	DebounceScript("AT_ACHIEVE", 0.5, 0);
end


function AT_ACHIEVE()
	local frame = ui.GetFrame("status");
    local achieveGbox = frame:GetChild('achieveGbox');
    local internalBox = achieveGbox:GetChild("internalBox");

    local clslist, clscnt = GetClassList("Achieve");

    local equipAchieveName = pc.GetEquipAchieveName();
	
    for i = 0, clscnt - 1 do

        local cls = GetClassByIndexFromList(clslist, i);
        if cls == nil then
            break;
        end


		local eachAchiveCSet = GET_CHILD(internalBox, 'ACHIEVE_RICHTEXT_' .. i, 'ui::CControlSet');
		tolua.cast(eachAchiveCSet, "ui::CControlSet");
		
		if eachAchiveCSet ~= nil then
		
			local eachAchiveReqBtn = GET_CHILD_RECURSIVELY(eachAchiveCSet, 'req_reward_btn');
			local xp = eachAchiveReqBtn:GetX();
			local yp = eachAchiveReqBtn:GetY();

			local ctrls = eachAchiveCSet:CreateOrGetControl("checkbox", "achieve_show", xp-25, yp+8, 24, 27);
			ctrls = tolua.cast(ctrls, "ui::CCheckBox");
			ctrls:SetText("");
			ctrls:SetClickSound("button_click_big");
			ctrls:SetOverSound("button_over");
			ctrls:SetTextTooltip("{@st42b}Track{/}");
			ctrls:SetEventScript(ui.LBUTTONUP, "ACHIEVE_ON_TRACK");
			ctrls:SetEventScriptArgString(ui.LBUTTONUP, tostring(i));
			if STATUS_ACHIEVE_SETTINGS.LOGGED[tostring(i)] ~= nil then
				ctrls:SetCheck(1);
			else
				ctrls:SetCheck(0);
			end
		end
	end
end
