--设备与系统数据

DeviceOSInfo = DeviceOSInfo or
{
	InfoList = 
	{
		ClientVersion = "",
		SystemSoftware = "",
		SystemHardware = "",
		TelecomOper = "",
		NetWork = "",
		ScreenWidth = 0,
		ScreenHight = 0,
		Density = 0,
		CpuHardware = "",
		Memory = 0,
		GLRender = "",
		GLVersion = "",
		DeviceId = "",
		vClientIP = "",
		DeviceName = "",
	}
}

function DeviceOSInfo.getDeviceOSInfo()
	DeviceOSInfo.InfoList.ClientVersion = Client.GetAppVersion();
	DeviceOSInfo.InfoList.SystemSoftware = Client.GetOSVersion();
	DeviceOSInfo.InfoList.SystemHardware = Client.GetPhoneType();
	DeviceOSInfo.InfoList.TelecomOper = Client.GetTelecomSvr();
	DeviceOSInfo.InfoList.NetWork = Client.GetNetWorkType();
	DeviceOSInfo.InfoList.ScreenWidth = Client.GetScreenWidth();
	DeviceOSInfo.InfoList.ScreenHight = Client.GetScreenHight();
	DeviceOSInfo.InfoList.Density = Client.GetScreenDensity();
	DeviceOSInfo.InfoList.CpuHardware = Client.GetCpuType();
	DeviceOSInfo.InfoList.Memory = Client.GetMemorySize();
	DeviceOSInfo.InfoList.GLRender = Client.GetGLType();
	DeviceOSInfo.InfoList.GLVersion = Client.GetGLVersion();
	DeviceOSInfo.InfoList.DeviceId = Client.GetPhoneDeviceID();
	DeviceOSInfo.InfoList.vClientIP = Client.GetIpAddr();	
	DeviceOSInfo.InfoList.DeviceName = BP_DeviceNameBeforeAuthLogin;
end