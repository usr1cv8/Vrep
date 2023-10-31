#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// Определяет список команд заполнения.
//
// Parameters:
//   FillCommands - ValueTable - Таблица с командами заполнения. Для изменения.
//       See описание 1 параметра процедуры ЗаполнениеОбъектовПереопределяемый.ПередДобавлениемКомандЗаполнения().
//   Parameters - Structure - Вспомогательные параметры. Для чтения.
//       See описание 2 параметра процедуры ЗаполнениеОбъектовПереопределяемый.ПередДобавлениемКомандЗаполнения().
//
Procedure AddFillCommands(FillCommands, Parameters) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region EventsHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Filter.Property("Owner") And TypeOf(Parameters.Filter.Owner) = Type("CatalogRef.ProductsAndServices") Then
		// Если задана связь параметров выбора по значению номенклатуры,
		// то дополним параметры выбора отбором по владельцу - номенклатурной группе.
		
		AttributeValues = CommonUse.ObjectAttributesValues(Parameters.Filter.Owner, "ProductsAndServicesCategory, ProductsAndServicesType, UseCharacteristics");
		
		ProductsAndServices 		  = Parameters.Filter.Owner;
		ProductsAndServicesCategory = AttributeValues.ProductsAndServicesCategory;
		
		TextOfMessage = "";
		If Not ValueIsFilled(ProductsAndServices) Then
			TextOfMessage = NStr("ru='Не заполнена номенклатура!';en='Products and services are not filled in.';vi='Chưa điền mặt hàng!'");
		ElsIf Parameters.Property("ThisIsReceiptDocument") And AttributeValues.ProductsAndServicesType = Enums.ProductsAndServicesTypes.Service Then
			TextOfMessage = NStr("ru='Для услуг сторонних контрагентов не ведется учет по характеристикам!';en='Accounting by characteristics is not kept for services of external counterparties.';vi='Đối với dịch vụ của đối tác bên ngoài, không tiến hành kế toán theo đặc tính!'");
		ElsIf Not AttributeValues.UseCharacteristics Then
			TextOfMessage = NStr("ru='Для номенклатуры не ведется учет по характеристикам!';en='Accounting by characteristics is not kept for the products and services.';vi='Mặt hàng không tiến hành kế toán theo đặc tính!'");
		EndIf;
		
		If Not IsBlankString(TextOfMessage) Then
			CommonUseClientServer.MessageToUser(TextOfMessage);
			StandardProcessing = False;
			Return;
		EndIf;
			
		FilterArray = New Array;
		FilterArray.Add(ProductsAndServices);
		FilterArray.Add(ProductsAndServicesCategory);
		
		Parameters.Filter.Insert("Owner", FilterArray);
		
	EndIf;
	
	If Not Parameters.Filter.Property("NotValid") Then
		Parameters.Filter.Insert("NotValid", False);
	EndIf;
	
EndProcedure // ОбработкаПолученияДанныхВыбора()

#EndRegion

#Region PrintInterface
// Заполняет список команд печати.
// 
// Parameters:
//   PrintCommands - ValueTable - состав полей See в функции УправлениеПечатью.СоздатьКоллекциюКомандПечати
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

#EndRegion

#Region InternalHandlers

// Функция возвращает список имен «ключевых» реквизитов.
//
Function GetObjectAttributesBeingLocked() Export
	
	Result = New Array;
	
	Return Result;
	
EndFunction // ПолучитьБлокируемыеРеквизитыОбъекта()

#EndRegion

#Region SubsystemHandlers

#Region DataImportFromExternalSources

Procedure OnDefineDataImportSamples(DataLoadSettings, UUID) Export
	
	Sample_xlsx = GetTemplate("DataLoadSample_xlsx");
	DataLoadSample_xlsx = PutToTempStorage(Sample_xlsx, UUID);
	DataLoadSettings.Insert("DataLoadSample_xlsx", DataLoadSample_xlsx);
	
	DataLoadSettings.Insert("DataLoadSample_mxl", "DataLoadSample_mxl");
	
	Sample_csv = GetTemplate("DataLoadSample_csv");
	DataLoadSample_csv = PutToTempStorage(Sample_csv, UUID);
	DataLoadSettings.Insert("DataLoadSample_csv", DataLoadSample_csv);
	
EndProcedure

Procedure DataImportFieldsFromExternalSource(ImportFieldsTable, DataLoadSettings) Export
	
	//
	// Для группы полей действует правило: хотя бы одно поле в группе должно быть выбрано в колонках
	//
	
	TypeDescriptionString11 = New TypeDescription("String", , , , New StringQualifiers(11));
	TypeDescriptionString25 = New TypeDescription("String", , , , New StringQualifiers(25));
	TypeDescriptionString150 = New TypeDescription("String", , , , New StringQualifiers(150));
	TypeDescriptionString0000 = New TypeDescription("String", , , , New StringQualifiers(0));
	
	TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CharacteristicTitle", "Characteristic (description)", TypeDescriptionString150, TypeDescriptionColumn, "Characteristic", 1, True, True);
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CharacteristicDescriptionForPrint", "Characteristic (description for printing)", TypeDescriptionString0000, TypeDescriptionColumn, "Characteristic", 2, , True);
	
	FieldVisibility = (TypeOf(DataLoadSettings.CommonValue) = Type("CatalogRef.ProductsAndServices"));
	TypeDescriptionColumn = New TypeDescription("Boolean");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ApplyProductsAndServicesPrices", "Copy prices productsandservices (only for new)", TypeDescriptionString25, TypeDescriptionColumn, , , , , FieldVisibility);
	
	// ДополнительныеРеквизиты
//	DataImportFromExternalSources.ПодготовитьСоответствиеПоДополнительнымРеквизитам(DataLoadSettings, Catalogs.AdditionalAttributesAndInformationSets.Catalog_ProductsAndServicesCharacteristics);
//	If DataLoadSettings.AdditionalAttributesDescription.Count() > 0 Then
//		
//		FieldName = DataImportFromExternalSources.ИмяПоляДобавленияДополнительныхРеквизитов();
//		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, FieldName, "Additional attributes", TypeDescriptionString150, TypeDescriptionString11, , , , , , True, Catalogs.AdditionalAttributesAndInformationSets.Catalog_ProductsAndServicesCharacteristics);
//		
//	EndIf;
	
EndProcedure

Procedure MatchImportedDataFromExternalSource(MappingSettings, ResultAddress) Export
	
	DataMatchingTable	= MappingSettings.DataMatchingTable;
	DataTableSize			= DataMatchingTable.Count();
	DataLoadSettings		= MappingSettings.DataLoadSettings;
	
	CharacteristicsOwner = DataLoadSettings.CommonValue;
	
	// ТаблицаСопоставленияДанных - Тип ДанныеФормыКоллекция
	For Each FormTableRow In DataMatchingTable Do
		
		// Характеристика по Наименованию, НаименованиеДляПечати
//		DataImportFromExternalSourcesOverridable.СопоставитьХарактеристикуПоНаименованию(FormTableRow.Characteristic, FormTableRow.CharacteristicTitle, FormTableRow.ХарактеристикаНаименованиеДляПечати, ВладелецХарактеристик);
		
		DataImportFromExternalSourcesOverridable.ConvertStringToBoolean(FormTableRow.ApplyProductsAndServicesPrices, FormTableRow.ПрименитьЦеныНоменклатуры_ВходящиеДанные);
		
		// Дополнительные реквизиты
		If DataLoadSettings.ВыбранныеДополнительныеРеквизиты.Count() > 0 Then
			
//			DataImportFromExternalSourcesOverridable.СопоставитьДополнительныеРеквизиты(FormTableRow, DataLoadSettings.ВыбранныеДополнительныеРеквизиты);
			
		EndIf;
		
		CheckDataCorrectnessInTableRow(FormTableRow);
		
		DataImportFromExternalSources.DataMappingProgress(DataMatchingTable.IndexOf(FormTableRow), DataTableSize);
		
	EndDo;
	
	PutToTempStorage(DataMatchingTable, ResultAddress);
	
EndProcedure

Procedure CheckDataCorrectnessInTableRow(FormTableRow, FillingObjectFullName = "") Export
	
	FormTableRow._СтрокаСопоставлена = ValueIsFilled(FormTableRow.Characteristic);
	
	ServiceFieldName = DataImportFromExternalSources.ServiceFieldNameImportToApplicationPossible();
	
	FormTableRow[ServiceFieldName] = FormTableRow._СтрокаСопоставлена
											Or (Not FormTableRow._СтрокаСопоставлена And Not IsBlankString(FormTableRow.CharacteristicTitle));
	
EndProcedure

#EndRegion

#EndRegion

#EndIf