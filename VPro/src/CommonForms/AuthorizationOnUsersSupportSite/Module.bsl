
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	Authentication = StandardSubsystemsServer.AuthenticationParametersOnSite();
	If Authentication <> Undefined Then
		Login  = Authentication.Login;
		Password = Authentication.Password;
	EndIf;
	
	RememberPassword = Not IsBlankString(Password);
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure GoToRegistrationOnSitePress(Item)
	
	GotoURL("https://1c-dn.com/user/updates/");
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure AuthenticationDataSaveAndContinue()
	
	If IsBlankString(Login) AND Not IsBlankString(Password) Then
		CommonUseClientServer.MessageToUser(NStr("en='Enter user code for authorization on the 1C website.';ru='Введите код пользователя для авторизации на сайте фирмы 1С.';vi='Hãy nhập mã người sử dụng để đăng nhập Website công ty 1C.'"),, "Login");
		Return;
	EndIf;
		
	If IsBlankString(Login) Then
		SaveAuthenticationData(Undefined);
		Result = DialogReturnCode.Cancel;
	Else
		SaveAuthenticationData(New Structure("Login,Password", Login, ?(RememberPassword, Password, "")));
		Result = New Structure("Login,Password", Login, Password);
	EndIf;
	
	Close(Result);
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServerNoContext
Procedure SaveAuthenticationData(Val Authentication)
	
	StandardSubsystemsServer.SaveAuthenticationParametersOnSite(Authentication);
	
EndProcedure

#EndRegion
