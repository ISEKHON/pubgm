
LogicReportBug = LogicReportBug or {}

function LogicReportBug:report(deviceName, posVec, angle, reasonID, text)
	
	if posVec == nil then
		log("LogicReportBug info posVec == nil or dirVec == nil");
		return
	end
	if deviceName == nil then
		deviceName = ""
	end
	log("LogicReportBug info device_name:"..deviceName..", reasonID:"..reasonID..", pos_x:"..posVec.x..", pos_y:"..posVec.y..", pos_z:"..posVec.z..", angle:"..angle..", text:"..text);
	local tInfo = {
		device_name = deviceName,
		pos_x = posVec.x, 
		pos_y = posVec.y, 
		pos_z = posVec.z,
		angle = angle,
		reason_id = reasonID,
		text = text,
	}
	NetUtil.SendPkg("report_bug_info", tInfo);
end
