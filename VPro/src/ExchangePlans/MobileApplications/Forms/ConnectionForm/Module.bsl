&AtServer
Procedure GenerateQR()
	
	AddressForConnectToMainDataBase = GetInfoBaseURL();
	QRString = "sbmcs" + ";" + AddressForConnectToMainDataBase + ";" + User; 
	QRCodeData = PrintManagement.QRCodeData(QRString, 0, 190);
	QRCode = PutToTempStorage(QRCodeData, UUID);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AddressForConnectToMainDataBase = GetInfoBaseURL();
	
	If Find(AddressForConnectToMainDataBase, "e1c://") = True Then
		Items.DecorationStep23Caption.Title = NStr("en='Visit the page describing the synchronization settings with the mobile application.';ru='Посетите страницу с описанием настройки синхронизации с мобильным приложением.';vi='Hãy truy cập trang có mô tả tùy chỉnh đồng bộ hóa với ứng dụng di động.'");
		Items.DecorationLink.Visible = True;
		Items.QRCode.Visible = False;
	Else
		Items.DecorationStep23Caption.Title = NStr("en='After downloading the mobile application, use this QR code to establish a connection.';ru='После загрузки мобильного приложения используйте этот QR-код для установки соединения.';vi='Sau khi kết nhập ứng dụng di động, hãy sử dụng mã QR để thiết lập kết nối.'");
		Items.DecorationLink.Visible = False;
		Items.QRCode.Visible = True;
	EndIf;
		
	If Parameters.Property("User") Then
		User = Parameters.User;
	Else
		SetPrivilegedMode(True);
		CurUser = Users.CurrentUser();
		If CurUser.Description= "<No set>" Then
			User = "";
		Else
			User = InfoBaseUsers.CurrentUser().Name;
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	GenerateQR();
	
EndProcedure

&AtClient
Procedure DecorationQRAndroidClick(Item)
	
	URL = "https://play.google.com/store/apps/details?id=com.e1c.MobileSmallBusiness";
	GotoURL(URL);
	
EndProcedure

&AtClient
Procedure DecorationButtonAndroidClick(Item)
	
	URL = "https://play.google.com/store/apps/details?id=vn.e1c.cmm";
	GotoURL(URL);
	
EndProcedure

&AtClient
Procedure DecorationQRiOSClick(Item)
	
	URL = "https://itunes.apple.com/ru/app/1s-unf/id590223043?mt=8";
	GotoURL(URL);
	
EndProcedure

&AtClient
Procedure DecorationButtoniOSClick(Item)
	
	URL = "https://itunes.apple.com/vn/app/1c-qu%E1%BA%A3n-l%C3%BD-doanh-nghi%E1%BB%87p/id1441075148?mt=8";
	GotoURL(URL);
	
EndProcedure

&AtClient
Procedure DecorationLinkClick(Item)
	
	URL = "http://old.1c.com.vn/san-pham/1c-quan-ly-tong-the-arm-/ung-dung-mobile-quan-ly-tong-the/tuy-chinh-dong-bo-hoa";
	GotoURL(URL);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	Notify("CustomizeMobileApplicationsReady");
	
EndProcedure