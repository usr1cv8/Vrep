#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest") Then
		Return;
	EndIf;
	
	Parameters.Property("TitleGroups", TitleGroups);
	
	Location = Undefined;
	If Not Parameters.Property("Location", Location) Then
		Raise NStr("en='Service parameter ""Display"" is not passed.';ru='Не передан служебный параметр ""Отображение"".';vi='Chưa truyền tham số hệ thống ""Display"".'");
	EndIf;
	If Location = DataCompositionFieldPlacement.Auto Then
		GroupLocation = "Auto";
	ElsIf Location = DataCompositionFieldPlacement.Vertically Then
		GroupLocation = "Vertically";
	ElsIf Location = DataCompositionFieldPlacement.Together Then
		GroupLocation = "Together";
	ElsIf Location = DataCompositionFieldPlacement.Horizontally Then
		GroupLocation = "Horizontally";
	ElsIf Location = DataCompositionFieldPlacement.SpecialColumn Then
		GroupLocation = "SpecialColumn";
	Else
		Raise StrReplace(NStr("en='Incorrect value of the ""Location"" parameter: ""%1"".';ru='Некорретное значение параметра ""Расположение"": ""%1"".';vi='Sai giá trị tham số ""Vị trí"": ""%1"".'"), "%1", String(Location));
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OK(Command)
	ChooseAndClose();
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure ChooseAndClose()
	ChoiceResult = New Structure;
	ChoiceResult.Insert("TitleGroups", TitleGroups);
	ChoiceResult.Insert("Location", DataCompositionFieldPlacement[GroupLocation]);
	NotifyChoice(ChoiceResult);
	If IsOpen() Then
		Close(ChoiceResult);
	EndIf;
EndProcedure

#EndRegion