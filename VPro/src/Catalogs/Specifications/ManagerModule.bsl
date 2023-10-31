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

Procedure ChangeSignBasicSpecification(ProductsAndServices, Characteristic, Specification) Export
	
	Manager = InformationRegisters.DefaultSpecifications.CreateRecordManager();
	Manager.ProductsAndServices = ProductsAndServices;
	Manager.Characteristic = Characteristic;
	Manager.Read();
	If Manager.Selected() And Manager.Specification=Specification Then
		Manager.Delete();
	Else
		If CommonUse.ObjectAttributeValue(Specification, "DeletionMark") Then
			TextOfMessage = NStr("en='The %1 BOM is marked for removal. Installing a sign <основная>unindable.';ru='Спецификация %1 помечена на удаление. Установка признака <основная> невозможен.';vi='Bảng kê chi tiết %1 đã bị đặt dấu xóa. Không thể thiết lập dấu hiệu <chính>.'");
			TextOfMessage = StrTemplate(TextOfMessage, Specification);
			CommonUseClientServer.MessageToUser(TextOfMessage);
			Return;
		EndIf; 
		Manager.ProductsAndServices = ProductsAndServices;
		Manager.Characteristic = Characteristic;
		Manager.Specification = Specification;
		Manager.Write(True);
	EndIf; 
	
EndProcedure

// Возвращает список реквизитов, которые разрешается редактировать
// с помощью обработки группового изменения объектов.
//
Function EditedAttributesInGroupDataProcessing() Export
	
	EditableAttributes = New Array;
	
	EditableAttributes.Add("Owner");
	EditableAttributes.Add("ProductCharacteristic");
	EditableAttributes.Add("ProductionKind");
	EditableAttributes.Add("DocOrder");
	EditableAttributes.Add("Comment");
	EditableAttributes.Add("NotValid");
	
	Return EditableAttributes;
	
EndFunction

#EndRegion

#Region EventsHandlers

// Процедура обработчик события ОбработкаПолученияДанныхВыбора.
//
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Cancel = False;
	ProductionServer.AddSpecificationFilters(Parameters, Cancel);
	
EndProcedure // ОбработкаПолученияДанныхВыбора()

#EndRegion

#Region DataImportFromExternalSources

Procedure DataImportFieldsFromExternalSource(ImportFieldsTable, DataLoadSettings) Export
	
	//
	// Для группы полей действует правило: хотя бы одно поле в группе должно быть выбрано в колонках
	//
	
	TypeDescriptionString25 = New TypeDescription("String", , , , New StringQualifiers(25));
	TypeDescriptionString100 = New TypeDescription("String", , , , New StringQualifiers(100));
	TypeDescriptionString150 = New TypeDescription("String", , , , New StringQualifiers(150));
	TypeDescriptionString200 = New TypeDescription("String", , , , New StringQualifiers(200));
	TypesDescriptionNumber15_2 = New TypeDescription("Number", , , , New NumberQualifiers(15, 2, AllowedSign.Nonnegative));
	TypesDescriptionNumber15_3 = New TypeDescription("Number", , , , New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	TypeDescriptionColumn = New TypeDescription("EnumRef.SpecificationContentRowTypes");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ContentRowType", "Type rows", TypeDescriptionString25, TypeDescriptionColumn);
	
	TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServices");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Barcode", "Barcode", TypeDescriptionString200, TypeDescriptionColumn, "ProductsAndServices", 1, , True);
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "SKU", "SKU", TypeDescriptionString25, TypeDescriptionColumn, "ProductsAndServices", 2, , True);
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "DescriptionOfProductsAndServices", "ProductsAndServices (description)", TypeDescriptionString100, TypeDescriptionColumn, "ProductsAndServices", 3, , True);
	
	If GetFunctionalOption("UseCharacteristics") Then
		
		TypeDescriptionColumn = New TypeDescription("CatalogRef.ProductsAndServicesCharacteristics");
		DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Characteristic", "Characteristic (description)", TypeDescriptionString150, TypeDescriptionColumn);
		
	EndIf;
	
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Quantity", "Quantity", TypeDescriptionString25, TypesDescriptionNumber15_3, , , True);
	
	TypeDescriptionColumn = New TypeDescription("CatalogRef.UOMClassifier, CatalogRef.UOM");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "MeasurementUnit", "UOM. chng.", TypeDescriptionString25, TypeDescriptionColumn);
	
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "CostPercentage", "Proportion cost", TypeDescriptionString25, TypesDescriptionNumber15_2);
	
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "ProductsQuantity", "Quantity products", TypeDescriptionString25, TypesDescriptionNumber15_3);
	
	TypeDescriptionColumn = New TypeDescription("CatalogRef.Specifications");
	DataImportFromExternalSources.AddImportDescriptionField(ImportFieldsTable, "Specification", "Specification (description)", TypeDescriptionString100, TypeDescriptionColumn);
	
EndProcedure

Procedure OnDefineDataImportSamples(DataLoadSettings, UUID) Export
	
	Sample_csv = GetTemplate("DataLoadSample_csv");
	DataLoadSample_csv = PutToTempStorage(Sample_csv, UUID);
	DataLoadSettings.Insert("DataLoadSample_csv", DataLoadSample_csv);
	
	DataLoadSettings.Insert("DataLoadSample_mxl", "DataLoadSample_mxl");
	
	Sample_xlsx = GetTemplate("DataLoadSample_xlsx");
	DataLoadSample_xlsx = PutToTempStorage(Sample_xlsx, UUID);
	DataLoadSettings.Insert("DataLoadSample_xlsx", DataLoadSample_xlsx);
	
EndProcedure

Procedure MatchImportedDataFromExternalSource(MappingSettings, ResultAddress) Export
	
	DataMatchingTable	= MappingSettings.DataMatchingTable;
	DataTableSize			= DataMatchingTable.Count();
	DataLoadSettings		= MappingSettings.DataLoadSettings;
	
	// ТаблицаСопоставленияДанных - Тип ДанныеФормыКоллекция
	For Each FormTableRow In DataMatchingTable Do
		
		// Номенклатура по ШтрихКоду, Артикулу, Наименованию
		DataImportFromExternalSourcesOverridable.CompareProducts(FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.SKU, FormTableRow.DescriptionOfProductsAndServices);
		
		// ТипСтроки по ТипСтроки.Наименование
		DataImportFromExternalSourcesOverridable.MapRowType(FormTableRow.ContentRowType, FormTableRow.ТипСтрокиСостава_ВходящиеДанные, Enums.SpecificationContentRowTypes.Material);
		
		If GetFunctionalOption("UseCharacteristics") Then
			
			If ValueIsFilled(FormTableRow.ProductsAndServices) Then
				
				// Характеристика по Владельцу и Наименованию
				DataImportFromExternalSourcesOverridable.MapCharacteristic(FormTableRow.Characteristic, FormTableRow.ProductsAndServices, FormTableRow.Barcode, FormTableRow.Характеристика_ВходящиеДанные);
				
			EndIf;
			
		EndIf;
		
		// Количество
		DataImportFromExternalSourcesOverridable.ConvertRowToNumber(FormTableRow.Count, FormTableRow.Количество_ВходящиеДанные, 1);
		
		// ЕдиницыИзмерения по Наименованию 
		DefaultValue = ?(ValueIsFilled(FormTableRow.ProductsAndServices), FormTableRow.ProductsAndServices.MeasurementUnit, Catalogs.UOMClassifier.pcs);
		DataImportFromExternalSourcesOverridable.MapUOM(FormTableRow.ProductsAndServices, FormTableRow.MeasurementUnit, FormTableRow.ЕдиницаИзмерения_ВходящиеДанные, DefaultValue);
		
		// Доля стоимости
		DataImportFromExternalSourcesOverridable.ConvertRowToNumber(FormTableRow.CostPercentage, FormTableRow.ДоляСтоимости_ВходящиеДанные, 1);
		
		// Количество продукции
		DataImportFromExternalSourcesOverridable.ConvertRowToNumber(FormTableRow.ProductsQuantity, FormTableRow.КоличествоПродукции_ВходящиеДанные, 1);
		
		// Спецификации по владельцу, наименованию
		DataImportFromExternalSourcesOverridable.MapSpecification(FormTableRow.Specification, FormTableRow.Спецификация_ВходящиеДанные, FormTableRow.ProductsAndServices);
		
		CheckDataCorrectnessInTableRow(FormTableRow);
		
		DataImportFromExternalSources.DataMappingProgress(DataMatchingTable.IndexOf(FormTableRow), DataTableSize);
		
	EndDo;
	
	PutToTempStorage(DataMatchingTable, ResultAddress);
	
EndProcedure

Procedure CheckDataCorrectnessInTableRow(FormTableRow, FillingObjectFullName = "") Export
	
	ServiceFieldName = DataImportFromExternalSources.ServiceFieldNameImportToApplicationPossible();
	
	FormTableRow[ServiceFieldName] = ValueIsFilled(FormTableRow.ProductsAndServices) 
		And  ValueIsFilled(FormTableRow.ContentRowType) 
		And FormTableRow.Count <> 0;
	
EndProcedure

#EndRegion

#Region ObjectVersioning

// StandardSubsystems.ВерсионированиеОбъектов

// Определяет настройки объекта для подсистемы ВерсионированиеОбъектов.
//
// Parameters:
//  Settings - Structure - настройки подсистемы.
Procedure OnGettingObjectsVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ВерсионированиеОбъектов

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

#EndIf
