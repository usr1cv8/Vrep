#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure PresentationFieldsReceiveDataProcessor(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("DeletionMark");
	Fields.Add("Number");
	Fields.Add("DateMailings");
	Fields.Add("SendingMethod");
	Fields.Add("Status");
	
EndProcedure

Procedure PresentationReceiveDataProcessor(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	TitlePresentation = NStr("en='Mailing';ru='Рассылка';vi='Gửi đi'");
	
	If Data.DeletionMark Then
		Status = NStr("en='(deleted)';ru='(удален)';vi='(đã xóa)'");
	Else
		Status = "(" + Lower(Data.Status) + ")";
	EndIf;
	
	Presentation = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='%1 %2: %3 %4 %5';ru='%1 %2: %3 %4 %5';vi='%1 %2: %3 %4 %5'"),
		TitlePresentation,
		Data.SendingMethod,
		ObjectPrefixationClientServer.GetNumberForPrinting(Data.Number, True, True),
		?(ValueIsFilled(Data.DateMailings), "from " + Format(Data.DateMailings, "DLF=D"), ""),
		Status);
	
EndProcedure

#EndRegion

#EndIf