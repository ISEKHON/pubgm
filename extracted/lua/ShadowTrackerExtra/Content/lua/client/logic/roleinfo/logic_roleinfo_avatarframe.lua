--[[
  个人信息头像框的相关逻辑
]]--

RoleInfoAvatarFrameSystem = RoleInfoAvatarFrameSystem or
{
	AvatarFrameList = {},
    UsedId = 0,
}

function RoleInfoAvatarFrameSystem.Enter()
	--log("RoleInfoAvatarFrameSystem Enter");
    RoleInfoAvatarFrameSystem.UsedId = DataMgr.roleData.cur_avatar_box_id;
    RoleInfoAvatarFrameSystem.get_avatar_box_list();
end

function RoleInfoAvatarFrameSystem.Release()
	--log("RoleInfoAvatarFrameSystem Release");
    RoleInfoAvatarFrameSystem.AvatarFrameList = {}
end

function RoleInfoAvatarFrameSystem.change_avatar_box(item_id)
	--log_tree("RoleInfoAvatarFrameSystem.change_avatar_box=", {item_id});
    NetUtil.SendPriorityPkg(false, "change_avatar_box_rsp", "change_avatar_box", item_id);
end

function RoleInfoAvatarFrameSystem.change_avatar_box_rsp(ok, item_id)
	--log_tree("RoleInfoAvatarFrameSystem.change_avatar_box_rsp=", {ok, item_id});
    if ok == 0 then
        DataMgr.roleData.cur_avatar_box_id = item_id;
        RoleInfoAvatarFrameSystem.UsedId = DataMgr.roleData.cur_avatar_box_id;
        if RoleInfoAvatarFrameUI.IsShow() then
            RoleInfoAvatarFrameUI.RefreshSelect()
        end
        --刷新个人信息界面与大厅界面的头像
        RoleInfoUI.UpdateAvatarFrame()
        -- 更新大厅显示数据
        LobbyUI:RefreshPlayerData()
    else
        DataMgr.ShowMessageBoxByID(ok)
    end    
end

function RoleInfoAvatarFrameSystem.get_avatar_box_list()
	--log_tree("RoleInfoAvatarFrameSystem.get_avatar_box_list");
    NetUtil.SendPriorityPkg(false, "get_avatar_box_list_rsp", "get_avatar_box_list");
end

function RoleInfoAvatarFrameSystem.get_avatar_box_list_rsp(ok, list, cur_avatar_box_id)
	--log_tree("RoleInfoAvatarFrameSystem.get_avatar_box_list_rsp=", {ok, list, cur_avatar_box_id});
    if ok == 0 then
        DataMgr.roleData.cur_avatar_box_id = cur_avatar_box_id;
        RoleInfoAvatarFrameSystem.UsedId = DataMgr.roleData.cur_avatar_box_id;
        RoleInfoAvatarFrameSystem.AvatarFrameList = list
        if RoleInfoAvatarFrameUI.IsShow() then
            RoleInfoAvatarFrameUI.Refresh()
        end
        --刷新个人信息界面与大厅界面的头像
        RoleInfoUI.UpdateAvatarFrame()
        -- 更新大厅显示数据
        LobbyUI:RefreshPlayerData()
    else
        DataMgr.ShowMessageBoxByID(ok)
    end
end

--[[网络回调]]--
s2c["change_avatar_box_rsp"] = RoleInfoAvatarFrameSystem.change_avatar_box_rsp;
s2c["get_avatar_box_list_rsp"] = RoleInfoAvatarFrameSystem.get_avatar_box_list_rsp;




