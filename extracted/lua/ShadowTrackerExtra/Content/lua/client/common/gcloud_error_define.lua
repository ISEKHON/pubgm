
--[[
  GClould网络异常定义
]]--

GCLOULD_ErrorInnerError = 1;
GCLOULD_ErrorNetworkException = 2;
GCLOULD_ErrorTimeout = 3;
GCLOULD_ErrorInvalidArgument = 4;
GCLOULD_ErrorLengthError = 5;
GCLOULD_ErrorUnknown = 6;
GCLOULD_ErrorEmpty = 7;
GCLOULD_ErrorNotInitialized = 9;
GCLOULD_ErrorNotSupported = 10;
GCLOULD_ErrorNotInstalled = 11;
GCLOULD_ErrorSystemError = 12;
GCLOULD_ErrorNoPermission = 13;

GCLOULD_ErrorInvalidGameId = 14;

--AccountService; from 100
GCLOULD_ErrorInvalidToken = 100;
GCLOULD_ErrorNoToken = 101;
GCLOULD_ErrorAccessTokenExpired = 102;
GCLOULD_ErrorRefreshTokenExpired = 103;
GCLOULD_ErrorPayTokenExpired = 104;
GCLOULD_ErrorLoginFailed = 105;
GCLOULD_ErrorUserCancel = 106;
GCLOULD_ErrorUserDenied = 107;
GCLOULD_ErrorChecking = 108;
GCLOULD_ErrorNeedRealNameAuth = 109;

--Connector; from 200
GCLOULD_ErrorNoConnection = 200;
GCLOULD_ErrorConnectFailed = 201;
GCLOULD_ErrorIsConnecting = 202;
GCLOULD_ErrorGcpError = 203;
GCLOULD_ErrorPeerCloseConnection = 204;
GCLOULD_ErrorPeerStopSession = 205;
GCLOULD_ErrorPkgNotCompleted = 206;
GCLOULD_ErrorSendError = 207;
GCLOULD_ErrorRecvError = 208;
GCLOULD_ErrorStayInQueue = 209;
GCLOULD_ErrorSvrIsFull = 210;
GCLOULD_ErrorTokenSvrError = 211;
GCLOULD_ErrorAuthFailed = 212;
GCLOULD_ErrorOverflow = 213;