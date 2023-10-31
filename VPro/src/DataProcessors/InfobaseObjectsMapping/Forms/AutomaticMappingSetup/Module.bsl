
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	MappingFieldList = Parameters.MappingFieldList;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshExplanationLabelText();
	
EndProcedure

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure MappingFieldListOnChange(Item)
	
	RefreshExplanationLabelText();
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure PerformMapping(Command)
	
	NotifyChoice(MappingFieldList.Copy());
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NotifyChoice(Undefined);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure RefreshExplanationLabelText()
	
	MarkedListItemArray = CommonUseClientServer.GetArrayOfMarkedListItems(MappingFieldList);
	
	If MarkedListItemArray.Count() = 0 Then
		
		ExplanatoryInscription = NStr("en='Objects will be mapped only by internal identifiers.';ru='Сопоставление будет выполнено только по внутренним идентификаторам объектов.';vi='Sẽ thực hiện so sánh chỉ theo tên nội bộ của đối tượng.'");
		
	Else
		
		ExplanatoryInscription = NStr("en='Objects will be mapped by internal identifiers and selected fields.';ru='Сопоставление будет выполнено по внутренним идентификаторам объектов и по выбранным полям.';vi='Sẽ thực hiện so sánh theo tên nội bộ của các đối tượng và theo trường đã chọn.'");
		
	EndIf;
	
EndProcedure

#EndRegion
