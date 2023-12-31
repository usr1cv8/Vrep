
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not ValueIsFilled(CommandParameter) Then
		Return;
	EndIf;
	
	If GroupIsSelected(CommandParameter) Then
		Raise NStr("en='Cannot select a segment group.';ru='Нельзя выбирать группу сегментов.';vi='Không được chọn nhóm phân khúc.'");
	EndIf;
	
	ReportParametersAndFilter = New Structure("Segment", CommandParameter);
	
	FormParameters = New Structure("VariantKey, Filter, GenerateAtOpen, ReportVariantsCommandVisible, CloseAtOwnerClose",
		"SegmentCompositionContext", ReportParametersAndFilter, True, False, True);
	
	OpenForm("Report.SegmentComposition.Form", 
		FormParameters,
		CommandExecuteParameters.Source,
		True,
		CommandExecuteParameters.Window);
	
EndProcedure

&AtServer
Function GroupIsSelected(Segment)
	
	Return Segment.IsFolder;
	
EndFunction