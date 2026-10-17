
LogUtil = LogUtil or {	
}

function LogUtil.clientLog(msg,toScreen)
   
   sandbox.Log("Log", msg)
   
   toScreen = toScreen or false;
   if toScreen then
	  Client.ShowScreenDebugMessage(msg);
   end
   
end

_G.log = LogUtil.clientLog;
_G.print = LogUtil.clientLog;
_G.logc = LogUtil.clientLog;
_G.logu = LogUtil.clientLog;



