WebviewResultHandler = WebviewResultHandler or 
{}

function WebviewResultHandler.Handle(errorCode)
	log(string.format("WebviewResultHandler.Handle errorCode(%d)", errorCode));
	if (errorCode == 0) then
		Client.SuspendSound();
	elseif (errorCode == 400) then
		Client.WakeupFromSuspendSound();
	end
end