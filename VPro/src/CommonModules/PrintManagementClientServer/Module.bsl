///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

Function PrintFormsCollectionFieldsNames() Export
	
	Fields = New Array;
	Fields.Add("TemplateName");
	Fields.Add("NameUPPER");
	Fields.Add("TemplateSynonym");
	Fields.Add("SpreadsheetDocument");
	Fields.Add("Copies");
	Fields.Add("Picture");
	Fields.Add("FullPathToTemplate");
	Fields.Add("FileNamePrintedForm");
	Fields.Add("OfficeDocuments");
	
	Return Fields;
	
EndFunction

// See PrintManagement.PrintToFile.
Function SavingSettings() Export
	
	SavingSettings = New Structure;
	SavingSettings.Insert("SavingFormats", New Array);
	SavingSettings.Insert("PackIntoArchive", False);
	SavingSettings.Insert("TransliterateFilesNames", False);
	SavingSettings.Insert("SignatureAndSeal", False);
	
	Return SavingSettings;
	
EndFunction

#EndRegion
