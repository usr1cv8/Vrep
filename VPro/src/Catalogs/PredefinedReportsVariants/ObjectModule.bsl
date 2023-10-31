#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure BeforeWrite(Cancel)
	If AdditionalProperties.Property("PredefinedOnesFilling") Then
		CheckFillingPredefined(Cancel);
	EndIf;
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not AdditionalProperties.Property("PredefinedOnesFilling") Then
		Raise NStr("en='The ""Predefined report variants"" catalog is changed only when data is filled in automatically.';ru='Справочник ""Предопределенные варианты отчетов"" изменяется только при автоматическом заполнении его данных.';vi='Danh mục ""Phương án định trước của báo cáo"" chỉ được thay đổi khi tự động điền dữ liệu báo cáo.'");
	EndIf;
EndProcedure

// Basic checks of the data correctness of the predefined reports.
Procedure CheckFillingPredefined(Cancel)
	If DeletionMark Then
		Return;
	ElsIf Not ValueIsFilled(Report) Then
		ErrorText = NotFilledField("Report");
	Else
		Return;
	EndIf;
	Cancel = True;
	ReportsVariants.ErrorByVariant(Ref, ErrorText);
EndProcedure

Function NotFilledField(FieldName)
	Return StrReplace(NStr("en='The ""%1"" field is not filled in';ru='Не заполнено поле ""%1""';vi='Chưa điền trường ""%1""'"), "%1", FieldName);
EndFunction

#EndRegion

#EndIf