///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Opens the additional report form with the specified option.
//
// Parameters:
//  Ссылка - СправочникСсылка.ДополнительныеОтчетыИОбработки - Ссылка дополнительного отчета.
//  КлючВарианта - Строка - Имя варианта дополнительного отчета.
//
Procedure OnAttachReport(OpenParameters) Export
	
	ReportsVariants.OnAttachReport(OpenParameters);
	
EndProcedure

// Получает тип субконто счета по его номеру.
//
// Parameters:
//  Account - ChartOfAccountsRef - Ссылка счета.
//  SubkontoNumber - Number - Номер субконто.
//
// Returns:
//   TypeDescription - Тип субконто.
//   Неопределено - Если не удалось получить тип субконто (нет такого субконто или нет прав).
//
Function ExtDimensionType(Account, SubkontoNumber) Export
	
	If Account = Undefined Then 
		Return Undefined;
	EndIf;
	
	MetadataObject = Account.Metadata();
	
	If Not Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
		Return Undefined;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	ChartOfAccountsExtDimensionTypes.ExtDimensionType.ValueType AS Type
	|FROM
	|	&FullTableName AS ChartOfAccountsExtDimensionTypes
	|WHERE
	|	ChartOfAccountsExtDimensionTypes.Ref = &Ref
	|	AND ChartOfAccountsExtDimensionTypes.LineNumber = &LineNumber");
	
	Query.Text = StrReplace(Query.Text, "&FullTableName", MetadataObject.FullName() + ".ExtDimensionTypes");
	
	Query.SetParameter("Ref", Account);
	Query.SetParameter("LineNumber", SubkontoNumber);
	
	SELECTION = Query.Execute().Select();
	
	If Not SELECTION.Next() Then
		Return Undefined;
	EndIf;
	
	Return SELECTION.Type;
	
EndFunction

Function PropertiesReportOprionFromFile(FileDescription, ReportOptionBase) Export 
	
	Return ReportsVariants.PropertiesReportOprionFromFile(FileDescription, ReportOptionBase);
	
EndFunction

Procedure ShareUserSettings(SelectedUsers, SettingsDescription) Export 
	
	ReportsVariants.ShareUserSettings(SelectedUsers, SettingsDescription);
	
EndProcedure

Function IsPredefinedReportOption(ReportVariant) Export 
	
	Return ReportsVariants.IsPredefinedReportOption(ReportVariant);
	
EndFunction

#EndRegion
