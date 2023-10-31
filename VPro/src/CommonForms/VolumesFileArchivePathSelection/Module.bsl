
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	If StandardSubsystemsServerCall.ClientWorkParameters().FileInfobase Then
		Items.PathToWindowsArchive.Title = NStr("en='For the 1C:Enterprise server under Microsoft Windows';ru='Для сервера 1С:Предприятия под управлением Microsoft Windows';vi='Đối với server 1C:DOANH NGHIỆP với hệ điều hành Microsoft Windows'"); 
	Else
		Items.PathToWindowsArchive.ChoiceButton = False; 
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure PathToArchiveWindowsInitialSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not FileFunctionsServiceClient.FileOperationsExtensionConnected() Then
		FileFunctionsServiceClient.ShowWarningAboutNeedToFileOperationsExpansion(Undefined);
		Return;
	EndIf;
	
	Dialog = New FileDialog(FileDialogMode.Open);
	
	Dialog.Title                    = NStr("en='Select file';ru='Выберите файл';vi='Hãy chọn tệp'");
	Dialog.FullFileName               = ?(ThisObject.PathToWindowsArchive = "", "files.zip", ThisObject.PathToWindowsArchive);
	Dialog.Multiselect           = False;
	Dialog.Preview      = False;
	Dialog.CheckFileExist  = True;
	Dialog.Filter                       = NStr("en='Zip archives(*.zip)|*.zip';ru='Архивы zip(*.zip)|*.zip';vi='Tệp nén zip(*.zip)|*.zip'");
	
	If Dialog.Choose() Then
		
		ThisObject.PathToWindowsArchive = Dialog.FullFileName;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure Place(Command)
	
	ClearMessages();
	
	If IsBlankString(PathToWindowsArchive) AND IsBlankString(PathToLinuxArchive) Then
		Text = NStr("en='Specify the full name"
"of the archive with files of the initial image (file *.zip)';ru='Укажите полное"
"имя архива с файлами начального образа (файл *.zip)';vi='Hãy chỉ ra"
"tên gọi đầy đủ của tệp nén với tệp ảnh ban đầu (tệp *.zip)'");
		CommonUseClientServer.MessageToUser(Text, , "PathToWindowsArchive");
		Return;
	EndIf;
	
	If Not StandardSubsystemsClientReUse.ClientWorkParameters().FileInfobase Then
	
		If Not IsBlankString(PathToWindowsArchive) AND (Left(PathToWindowsArchive, 2) <> "\\" OR Find(PathToWindowsArchive, ":") <> 0) Then
			ErrorText = NStr("en='Path to archive with initial"
"image files must be in UNC format (\\servername\resource).';ru='Путь к архиву"
"с файлами начального образа должен быть в формате UNC (\\servername\resource).';vi='Đường dẫn đến lưu trữ"
"với các tệp của ảnh ban đầu cần có định dạng UNC (\\servername\resource).'");
			CommonUseClientServer.MessageToUser(ErrorText, , "PathToWindowsArchive");
			Return;
		EndIf;
	
	EndIf;
	
	Status(
		NStr("en='File placement from"
"archive with initial image files is executed...';ru='Осуществляется размещение файлов из"
"архива с файлами начального образа...';vi='Tiến hành sắp xếp tệp từ kho lưu trữ với tệp ảnh ban đầu...'"),
		,
		NStr("en='File placement from"
"archive with initial image files is executed...';ru='Осуществляется размещение файлов из"
"архива с файлами начального образа...';vi='Tiến hành sắp xếp tệp từ kho lưu trữ với tệp ảnh ban đầu...'"),
		PictureLib.CreateInitialImage);
	
	AddFilesToVolumes();
	
	NotificationText = NStr("en='File placement from archive"
"with initial image files is successfully completed.';ru='Размещение файлов из архива с файлами"
"начального образа успешно завершено.';vi='Đã hoàn tất thành công sắp xếp tệp từ nơi lưu giữ với tệp"
"ảnh ban đầu.'");
	ShowUserNotification(NotificationText);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Procedure AddFilesToVolumes()
	
	FileFunctionsService.AddFilesToVolumes(PathToWindowsArchive, PathToLinuxArchive);
	
EndProcedure

#EndRegion
