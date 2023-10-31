
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	If Not OnlineUserSupport.UseOnlineSupportAllowedInCurrentOperationMode() Then
		// Administration right is not checked as subsystem
		// is used only in the local mode.
		Raise NStr("en='Online user support is not allowed in the current work mode.';ru='Использование Интернет-поддержки запрещено в текущем режиме работы.';vi='Cấm sử dụng hỗ trợ qua Internet trong chế độ làm việc hiện tại.'");
	EndIf;
	
	If Not Users.InfobaseUserWithFullAccess(, True, False) Then
		// Administration right is not checked as subsystem
		// is used only in the local mode.
		Raise
			NStr("en='Insufficient access rights."
""
"Setting of the connection to the online support parameters is available only to the system administrator.';ru='Недостаточно прав доступа."
""
"Настройка параметров подключения к Интернет-поддержке пользователей доступна только администратору системы.';vi='Không đủ quyền truy cập."
""
"Chỉ người quản trị hệ thống mới được phép tùy chỉnh tham số kết nối với hỗ trợ người sử dụng qua Internet .'");
	EndIf;
	
	IsClientServerIB = (NOT CommonUse.FileInfobase());
	WindowOptionsKey = String(IsClientServerIB);
	
	Items.GroupConnectionFromServer.Visible = IsClientServerIB;
	Items.DecorationRecommendationsKS83.Visible = IsClientServerIB;
	
	QueryText      = "";
	ParameterColumns = New Array;
	Tables           = New Array;
	
	If IsClientServerIB Then
		ParameterColumns.Add("ConnectionToOUSServiceFromServer.Value AS ConnectionToOUSServiceFromServer");
		Tables.Add("Constant.ConnectionToOUSServiceFromServer AS ConnectionToOUSServiceFromServer");
	EndIf;
	
	ParameterColumns.Add("CASE
		|		WHEN ConnectionTimeoutToOnlineSupportService.Value = 0
		|			THEN 30
		|		ELSE ConnectionTimeoutToOnlineSupportService.Value
		|	END AS ConnectionTimeoutToOnlineSupportService");
	Tables.Add("Constant.ConnectionTimeoutToOnlineSupportService AS ConnectionTimeoutToOnlineSupportService");
	
	ColumnsPag = "";
	For Iterator = 0 To ParameterColumns.UBound() Do
		ColumnsPag = ColumnsPag + ?(Iterator > 0, ",", "") + ParameterColumns[Iterator];
	EndDo;
	
	TablesPag = "";
	For Iterator = 0 To Tables.UBound() Do
		TablesPag = TablesPag + ?(Iterator > 0, ",", "") + Tables[Iterator];
	EndDo;
	
	QueryText = "SELECT " + ColumnsPag + " FROM " + TablesPag + ";" + Chars.LF;
	QueryText = QueryText
		+
		"SELECT TOP 1
		|	UsersOnlineSupportParameters.Name AS ParameterName,
		|	UsersOnlineSupportParameters.Value AS ParameterValue
		|FROM
		|	InformationRegister.UsersOnlineSupportParameters AS UsersOnlineSupportParameters
		|WHERE
		|	UsersOnlineSupportParameters.Name = ""login""";
	
	ParametersQuery = New Query(QueryText);
	PackageResults = ParametersQuery.ExecuteBatch();
	
	NetworkParametersSelection = PackageResults[0].Select();
	NetworkParametersSelection.Next();
	
	If IsClientServerIB Then
		ConnectionFromServer = Number(NetworkParametersSelection.ConnectionToOUSServiceFromServer);
	EndIf;
	
	ConnectionTimeout = Number(NetworkParametersSelection.ConnectionTimeoutToOnlineSupportService);
	
	// Display authorization parameters
	AuthorizationParametersSelection = PackageResults[1].Select();
	While AuthorizationParametersSelection.Next() Do
		Login = AuthorizationParametersSelection.ParameterValue;
	EndDo;
	
	// Override username and password if they are not filled
	If IsBlankString(Login) Then
		UserData = OnlineUserSupportClientServer.NewOnlineSupportUserData();
		OnlineUserSupportOverridable.OnDefineOnlineSupportUserData(
			UserData);
		If TypeOf(UserData) = Type("Structure")
			AND UserData.Property("Login") Then
			Login = String(UserData.Login);
		EndIf;
	EndIf;
	
	If IsBlankString(Login) Then
		Items.DecorationExplanationLoginPassword.Title = NStr("en='You are not authorized yet';ru='Вы еще не авторизованы';vi='Bạn vẫn chưa đăng nhập'");
		Items.Login.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "OnlineSupportChangeAuthorizationData" AND TypeOf(Parameter) = Type("Structure") Then
		
		If Parameter.Property("Login") Then
			
			Login = Parameter.Login;
			If IsBlankString(Login) Then
				Items.DecorationExplanationLoginPassword.Title = NStr("en='You are not authorized yet';ru='Вы еще не авторизованы';vi='Bạn vẫn chưa đăng nhập'");
				Items.Login.Visible = False;
			Else
				Items.DecorationExplanationLoginPassword.Title =
					NStr("en='When connecting online support, the following is used:';ru='При подключении Интернет-поддержки используется:';vi='Khi kết nỗi hỗ trợ qua Internet đã sử dụng:'");
				Items.Login.Visible = True;
			EndIf;
			
		EndIf;
		
	ElsIf EventName = "CheckOnlineSupportParametersFormOpening" Then
		
		If TypeOf(Parameter) = Type("Structure") AND Parameter.Property("FormIsOpened") Then
			Parameter.FormIsOpened = IsOpen();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure ConnectionFromServerOnChange(Item)
	
	OnChangeConnectionFromServer(ConnectionFromServer);
	
EndProcedure

&AtClient
Procedure ConnectionTimeoutOnChange(Item)
	
	TimeoutOnChangeAtServer(ConnectionTimeout);
	
EndProcedure

&AtClient
Procedure DecorationExplanationGettingLoginPasswordDataProcessorNavigationRef(Item, URL, StandardProcessing)
	
	StandardProcessing = False;
	OnlineUserSupportClient.OpenInternetPage(
		"https://1c-dn.com/user/profile/",
		NStr("en='Support users of 1C:Enterprise 8';ru='Поддержка пользователей системы 1С:Предприятие 8';vi='Hỗ trợ người sử dụng hệ thống 1C:DOANH NGHIỆP 8'"));
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure EnterLoginPasswordOrRegister(Command)
	
	OnlineUserSupportClient.ConnectOnlineUserSupport();
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServerNoContext
Procedure TimeoutOnChangeAtServer(Val Timeout)
	
	Constants.ConnectionTimeoutToOnlineSupportService.Set(Timeout);
	
EndProcedure

&AtServerNoContext
Procedure OnChangeConnectionFromServer(Val ConnectionFromServer)
	
	Constants.ConnectionToOUSServiceFromServer.Set((ConnectionFromServer = 1));
	
EndProcedure

#EndRegion