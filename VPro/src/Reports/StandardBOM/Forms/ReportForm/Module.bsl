
////////////////////////////////////////////////////////////////////////////////
// MODULE VARIABLES

Var Template;
Var Document;
Var TableOfOperations, ContentTable;
Var RowAppearance;

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS GENERATING REPORT

&AtServer
// Procedure of product content scheme formation.
// 
Procedure DisplayProductContent()
	
	If ContentTable.Count() < 2 Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Standard bill of materials is not filled';ru='Не заполнен нормативный состав изделия';vi='Chưa điền thành phần định mức sản phẩm'");
		Message.Message();
		
		Return;
		
	EndIf;
	
	RowIndex = ContentTable.Count() - 1;
	TotalsCorrespondence = New Map;
	
	While RowIndex >= 0 Do 
		
        CurRow = ContentTable[RowIndex];
		
		If RowIndex = 0 Then
			CurRow.Cost = TotalsCorrespondence.Get(CurRow.Level);
		Else
			NextRow = ContentTable[RowIndex - 1];
			If CurRow.Node Then
				CurRow.Cost = TotalsCorrespondence.Get(CurRow.Level);
				If TotalsCorrespondence.Get(CurRow.Level - 1) = Undefined Then 
					TotalsCorrespondence.Insert(CurRow.Level - 1, CurRow.Cost);
				Else
					TotalsCorrespondence[CurRow.Level - 1] = TotalsCorrespondence[CurRow.Level - 1] + CurRow.Cost;
				EndIf;	
				TotalsCorrespondence.Insert(CurRow.Level, 0);
			Else
				If TotalsCorrespondence.Get(CurRow.Level - 1) = Undefined Then 
					TotalsCorrespondence.Insert(CurRow.Level - 1, CurRow.Cost);
				Else
					TotalsCorrespondence[CurRow.Level - 1] = TotalsCorrespondence[CurRow.Level - 1] + CurRow.Cost;
				EndIf;				
			EndIf;
			
		EndIf;
		
		RowIndex = RowIndex - 1;
		
	EndDo;
	
	For Each ContentRow IN ContentTable Do
		
		Template.Area("ContentRow|ProductsAndServices").Indent = ContentRow.Level*2;
		TemplateArea = Template.GetArea("ContentRow|ContentColumn");
		
		TemplateArea.Parameters.PresentationOfProductsAndServices 	= ContentRow.ProductsAndServices.Description +" "+ContentRow.Characteristic.Description;
		TemplateArea.Parameters.ProductsAndServices				= ContentRow.ProductsAndServices;
		TemplateArea.Parameters.Quantity					= ContentRow.Quantity;
		TemplateArea.Parameters.MeasurementUnit			= ContentRow.MeasurementUnit;
		TemplateArea.Parameters.AccountingPrice                 = ContentRow.AccountingPrice;
		TemplateArea.Parameters.Cost	         		= ContentRow.Cost;
		
		RowIndex = ContentTable.IndexOf(ContentRow);
		
		If ContentRow.Node Then
			TemplateArea.Area(1,2,1,19).BackColor = RowAppearance[ContentRow.Level - Int(ContentRow.Level / 5) * 5];
		EndIf;
		
		If RowIndex < ContentTable.Count() - 1 Then
			
			NexRows = ContentTable[RowIndex+1];
			
			If NexRows.Level > ContentRow.Level Then
				Document.Put(TemplateArea);
				Document.StartRowGroup(ContentRow.ProductsAndServices.Description);
			ElsIf NexRows.Level < ContentRow.Level Then
				Document.Put(TemplateArea);
				DifferenceOfLevels = ContentRow.Level - NexRows.Level;
				While DifferenceOfLevels >= 1 Do
					Document.EndRowGroup();
					DifferenceOfLevels = DifferenceOfLevels - 1;
				EndDo;
			Else
				Document.Put(TemplateArea);
			EndIf;
		Else
			Document.Put(TemplateArea);
			Document.EndRowGroup();
		EndIf;
		
	EndDo;
	
	ContentTable.Clear();
	
EndProcedure // DisplayProductContent()

&AtServer
// Procedure of product operation scheme formation.
// 
Procedure OutputOperationsContent()
	
	RowIndex = TableOfOperations.Count() - 1;
	TotalsCorrespondenceTimeNorm = New Map;
	MapTotalsDuration = New Map;
	TotalsCorrespondenceCost = New Map;
	
	While RowIndex >= 0 Do 
		
        CurRow = TableOfOperations[RowIndex];
		
		If RowIndex = 0 Then
			
			CurRow.TimeNorm = TotalsCorrespondenceTimeNorm.Get(CurRow.Level);
			CurRow.Duration = MapTotalsDuration.Get(CurRow.Level);
			CurRow.Cost = TotalsCorrespondenceCost.Get(CurRow.Level);
			
		Else
			
			NextRow = TableOfOperations[RowIndex - 1];
			
			If CurRow.Node Then
				
				CurRow.TimeNorm = TotalsCorrespondenceTimeNorm.Get(CurRow.Level);
				If TotalsCorrespondenceTimeNorm.Get(CurRow.Level - 1) = Undefined Then 
					TotalsCorrespondenceTimeNorm.Insert(CurRow.Level - 1, CurRow.TimeNorm);
				Else
					TotalsCorrespondenceTimeNorm[CurRow.Level - 1] = TotalsCorrespondenceTimeNorm[CurRow.Level - 1] + CurRow.TimeNorm;
				EndIf;	
				TotalsCorrespondenceTimeNorm.Insert(CurRow.Level, 0);
				
				CurRow.Duration = MapTotalsDuration.Get(CurRow.Level);
				If MapTotalsDuration.Get(CurRow.Level - 1) = Undefined Then 
					MapTotalsDuration.Insert(CurRow.Level - 1, CurRow.Duration);
				Else
					MapTotalsDuration[CurRow.Level - 1] = MapTotalsDuration[CurRow.Level - 1] + CurRow.Duration;
				EndIf;	
				MapTotalsDuration.Insert(CurRow.Level, 0);
				
				CurRow.Cost = TotalsCorrespondenceCost.Get(CurRow.Level);
				If TotalsCorrespondenceCost.Get(CurRow.Level - 1) = Undefined Then 
					TotalsCorrespondenceCost.Insert(CurRow.Level - 1, CurRow.Cost);
				Else
					TotalsCorrespondenceCost[CurRow.Level - 1] = TotalsCorrespondenceCost[CurRow.Level - 1] + CurRow.Cost;
				EndIf;	
				TotalsCorrespondenceCost.Insert(CurRow.Level, 0);
				
			Else
				
				If TotalsCorrespondenceTimeNorm.Get(CurRow.Level - 1) = Undefined Then 
					TotalsCorrespondenceTimeNorm.Insert(CurRow.Level - 1, CurRow.TimeNorm);
				Else
					TotalsCorrespondenceTimeNorm[CurRow.Level - 1] = TotalsCorrespondenceTimeNorm[CurRow.Level - 1] + CurRow.TimeNorm;
				EndIf;	
				
				If MapTotalsDuration.Get(CurRow.Level - 1) = Undefined Then 
					MapTotalsDuration.Insert(CurRow.Level - 1, CurRow.Duration);
				Else
					MapTotalsDuration[CurRow.Level - 1] = MapTotalsDuration[CurRow.Level - 1] + CurRow.Duration;
				EndIf;	
				
				If TotalsCorrespondenceCost.Get(CurRow.Level - 1) = Undefined Then 
					TotalsCorrespondenceCost.Insert(CurRow.Level - 1, CurRow.Cost);
				Else
					TotalsCorrespondenceCost[CurRow.Level - 1] = TotalsCorrespondenceCost[CurRow.Level - 1] + CurRow.Cost;
				EndIf;	
				
			EndIf;
			
		EndIf;
		
		RowIndex = RowIndex - 1;
		
	EndDo;
	
	GroupRowsIsOpen = False;
	
	For Each RowOperation IN TableOfOperations Do
		
		Template.Area("RowOperation|ProductsAndServices").Indent = RowOperation.Level * 2;
		TemplateArea = Template.GetArea("RowOperation|ContentColumn");
		
		If RowOperation.Node Then
			TemplateArea.Parameters.PresentationOfProductsAndServices = RowOperation.ProductsAndServices.Description +" "+RowOperation.Characteristic.Description;
		Else
			TemplateArea.Parameters.PresentationOfProductsAndServices = RowOperation.ProductsAndServices.Description;
		EndIf;
		
		TemplateArea.Parameters.ProductsAndServices = RowOperation.ProductsAndServices;
		TemplateArea.Parameters.Norm		 = RowOperation.TimeNorm;
		TemplateArea.Parameters.Duration = RowOperation.Duration;
		TemplateArea.Parameters.AccountingPrice  = RowOperation.AccountingPrice;
		TemplateArea.Parameters.Cost	 = RowOperation.Cost;
		
		RowIndex = TableOfOperations.IndexOf(RowOperation);
		
		If RowOperation.Node Then
			TemplateArea.Area(1,2,1,19).BackColor = RowAppearance[RowOperation.Level - Int(RowOperation.Level / 5) * 5];
		EndIf;
		
		If RowIndex < TableOfOperations.Count() - 1 Then
			
			NexRows = TableOfOperations[RowIndex+1];
			
			If NexRows.Level > RowOperation.Level Then
				
				Document.Put(TemplateArea);
				Document.StartRowGroup(RowOperation.ProductsAndServices.Description);
				GroupRowsIsOpen = True;
				
			ElsIf NexRows.Level < RowOperation.Level Then
				
				Document.Put(TemplateArea);
				DifferenceOfLevels = RowOperation.Level - NexRows.Level;                                  
				While DifferenceOfLevels >= 1 Do
					
					Document.EndRowGroup();
					DifferenceOfLevels = DifferenceOfLevels - 1;
					
				EndDo;
				
			Else
				
				Document.Put(TemplateArea);
				
			EndIf;
			
		Else
			
			Document.Put(TemplateArea);
			
			//Check the need to close the grouping
			If GroupRowsIsOpen Then 
				
				Document.EndRowGroup();
				GroupRowsIsOpen = False;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	TableOfOperations.Clear();
	
EndProcedure // DisplayOperationContent()

&AtServer
// Function forms tree by request.
//
// Parameters:
//  exProductsAndServices - CatalogRef.ProductsAndServices - products.
//
Function GenerateTree(ProductsAndServices, Specification, Characteristic)
	
	ContentStructure = GenerateContentStructure();
	ContentStructure.ProductsAndServices		= ProductsAndServices;
	ContentStructure.Characteristic		= Characteristic;
	ContentStructure.MeasurementUnit	= ProductsAndServices.MeasurementUnit;
	ContentStructure.Quantity			= Report.Quantity;
	ContentStructure.Specification		= Specification;
	ContentStructure.ProcessingDate		= Report.CalculationDate;
	ContentStructure.PriceKind     		= Report.PriceKind;
	ContentStructure.Level			= 0;
	ContentStructure.AccountingPrice		= 0;
	ContentStructure.Cost			= 0;
	
	Array = New Array;
	Array.Add(Type("Number"));
	TypeDescription = New TypeDescription(Array, , , New NumberQualifiers(15, 3));
	
	ContentTable = New ValueTable;
	
	ContentTable.Columns.Add("Stage");
	ContentTable.Columns.Add("Type");
	ContentTable.Columns.Add("ProductsAndServices");
	ContentTable.Columns.Add("Characteristic");
	ContentTable.Columns.Add("MeasurementUnit");
	ContentTable.Columns.Add("Quantity", TypeDescription);
    ContentTable.Columns.Add("Level");
	ContentTable.Columns.Add("Node");
	ContentTable.Columns.Add("AccountingPrice", TypeDescription);
	ContentTable.Columns.Add("Cost", TypeDescription);
	
	TableOfOperations = New ValueTable;
	
	TableOfOperations.Columns.Add("ProductsAndServices");
	TableOfOperations.Columns.Add("Characteristic");
	TableOfOperations.Columns.Add("TimeNorm", TypeDescription);
	TableOfOperations.Columns.Add("Duration", TypeDescription);
	TableOfOperations.Columns.Add("Level");
	TableOfOperations.Columns.Add("Node");
	TableOfOperations.Columns.Add("AccountingPrice", TypeDescription);
	TableOfOperations.Columns.Add("Cost", TypeDescription);
	
//	SmallBusinessServer.Denoding(ContentStructure, ContentTable, TableOfOperations);
	Denoding(ContentStructure, ContentTable);
	
EndFunction // GenerateTree()

&AtServer
// Procedure forms report by product content.
//
Procedure GenerateReport(ProductsAndServices, Characteristic, Specification)
	
	If Not ValueIsFilled(ProductsAndServices) Then
		
		MessageText = NStr("en='The Products and services field is required';ru='Поле Номенклатура не заполнено';vi='Chưa điền trường Mặt hàng'");
		MessageField = "ProductsAndServices";
		SmallBusinessServer.ShowMessageAboutError(Report, MessageText,,,MessageField);
		
		Return;
	
	EndIf;
	
	If Not ValueIsFilled(Specification) Then
		
		MessageText = NStr("en='The ""Bill of materials"" field is not filled in';ru='Поле Спецификация не заполнено';vi='Chưa điền trường Bảng kê chi tiết'");
		MessageField = "Specification";
		SmallBusinessServer.ShowMessageAboutError(Report, MessageText,,,MessageField);
		
		Return;
	
	EndIf;
	
	Document = SpreadsheetDocumentReport;
	Document.Clear();
	
	GenerateTree(ProductsAndServices, Specification, Characteristic);
	
	Report.Cost = ContentTable.Total("Cost") + TableOfOperations.Total("Cost");
	
	Template = Reports.StandardBOM.GetTemplate("Template");
	
	TemplateArea = Template.GetArea("Title");
	TemplateArea.Parameters.Title = NStr("en='Standard product content on ';ru='Стандартный состав продукта на ';vi='Thành phần chuẩn của sản phẩm trong'") 
										+ Format(Report.CalculationDate, NStr("en = 'L=en; DLF=DD'; ru = 'L=ru; DLF=DD'; vi = 'L=vi; DLF=DD'")) + Chars.LF
										+ NStr("en='Product:';ru='Продукт: ';vi='Sản phẩm: '") + ProductsAndServices.Description
										+ ?(ValueIsFilled(Report.Characteristic), ", " + Report.Characteristic, "")
										+ ", " + Specification + Chars.LF
										+ NStr("en='Quantity: ';ru='Количество; ';vi='Số lượng; '") + Report.Quantity + " " + ProductsAndServices.MeasurementUnit
										+ NStr("en=', cost: ';ru=', стоимость: ';vi=', giá trị: '") + Report.Cost + " " + Report.PriceKind.PriceCurrency.Description
										+ Chars.LF;
	Document.Put(TemplateArea);
	
	RowAppearance = New Array;
	
	RowAppearance.Add(WebColors.MediumTurquoise);
	RowAppearance.Add(WebColors.MediumGreen);
	RowAppearance.Add(WebColors.AliceBlue);
	RowAppearance.Add(WebColors.Cream);
	RowAppearance.Add(WebColors.Azure);

	TemplateArea = Template.GetArea("ContentTitle|ContentColumn");
	Document.Put(TemplateArea);
	
	DisplayProductContent();
	
	If Constants.FunctionalOptionUseTechOperations.Get() AND TableOfOperations.Count() > 0 Then
	
		TemplateAreaOperations = Template.GetArea("Indent");
		Document.Put(TemplateAreaOperations);
		
		TemplateArea = Template.GetArea("OperationTitle|ContentColumn");
		Document.Put(TemplateArea);
		
		OutputOperationsContent();
		
	EndIf;	

EndProcedure // GenerateReport()

&AtServerNoContext
// Receives the set of data from the server for the ProductsAndServicesOnChange procedure.
//
Function GetDataProductsAndServicesOnChange(StructureData)
	
	StructureData.Insert("Specification", SmallBusinessServer.GetDefaultSpecification(StructureData.ProductsAndServices, StructureData.Characteristic, True));
	
	Return StructureData;
	
EndFunction // ReceiveDataProductsAndServicesOnChange()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - ACTIONS OF THE FORM COMMAND PANELS

&AtClient
// Procedure is called when clicking "Generate" command
// panel of tabular field.
//
Procedure Generate(Command)
	
	GenerateReport(Report.ProductsAndServices, Report.Characteristic, Report.Specification);
	
EndProcedure // Generate()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF HEADER ATTRIBUTES

&AtClient
// Procedure - event handler OnChange of the ProductsAndServices input field.
//
Procedure ProductsAndServicesOnChange(Item)
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", Report.ProductsAndServices);
	StructureData.Insert("Characteristic", Report.Characteristic);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	Report.Specification = StructureData.Specification;

EndProcedure // ProductsAndServicesOnChange()

&AtClient
// Procedure - event handler OnChange of the Characteristic input field.
//
Procedure CharacteristicOnChange(Item)
	
	StructureData = New Structure;
	StructureData.Insert("ProductsAndServices", Report.ProductsAndServices);
	StructureData.Insert("Characteristic", Report.Characteristic);
	
	StructureData = GetDataProductsAndServicesOnChange(StructureData);
	Report.Specification = StructureData.Specification;
	
EndProcedure // CharacteristicOnChange()

// Procedure - OnOpen form event handler
//
&AtClient
Procedure OnOpen(Cancel)
	
	Report.CalculationDate = CurrentDate();
		
EndProcedure // OnOpen() 

// Procedure - event handler OnCreateAtServer of the form.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ProductsAndServices") Then
		
		If ValueIsFilled(Parameters.ProductsAndServices) Then
			
			StructureData = New Structure;
			
			If TypeOf(Parameters.ProductsAndServices ) = Type("CatalogRef.ProductsAndServices") Then
				StructureData.Insert("ProductsAndServices", Parameters.ProductsAndServices);
				StructureData.Insert("Characteristic", Catalogs.ProductsAndServicesCharacteristics.EmptyRef());
				StructureData      = GetDataProductsAndServicesOnChange(StructureData);
				Report.ProductsAndServices   = StructureData.ProductsAndServices;
				Report.Specification   = StructureData.Specification;
			Else // Specifications
				Report.ProductsAndServices   = Parameters.ProductsAndServices.Owner;
				Report.Characteristic = Parameters.ProductsAndServices.ProductCharacteristic;
				Report.Specification   = Parameters.ProductsAndServices;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Report.PriceKind = Catalogs.PriceKinds.Accounting;
	Report.Quantity = 1;
	
EndProcedure // OnCreateAtServer()

&AtServer
Procedure OnSaveUserSettingsAtServer(Settings)
	ReportsVariants.OnSaveUserSettingsAtServer(ThisObject, Settings);
EndProcedure

#Region ПроцедурыИФункцииРазузлования

// Формирование структуры с определенным составом полей для процедуры 
// разузлования.
//
// Parameters:
//  Нет.
//
// Returns:
//  Structure - структура с определенным составом полей для процедуры 
//              разузлования.
//
Function GenerateContentStructure()
	
	Structure = New Structure();
	
	// Поля описания текущего узла.
	Structure.Insert("Stage");
	Structure.Insert("Type");
	Structure.Insert("ProductsAndServices");
	Structure.Insert("Characteristic");
	Structure.Insert("MeasurementUnit");
	Structure.Insert("Quantity");
	Structure.Insert("AccountingPrice");
	Structure.Insert("Cost");
	Structure.Insert("ProductsQuantity");
	Structure.Insert("Specification");
	
	Structure.Insert("ContentRowType");
	
	// Вспомогательные данные.
	Structure.Insert("Object");
	Structure.Insert("ProcessingDate", '00010101');
	Structure.Insert("Level");
	Structure.Insert("PriceKind");
	
	Return Structure;
	
EndFunction // обСформироватьСтруктуруСостава()

Function GetSpecificationContent(ContentStructure)
	
	ПоЗакупочнымЦенам = False;
	
	Query = New Query;
	Query.SetParameter("ПоЗакупочнымЦенам", ПоЗакупочнымЦенам);
	Query.SetParameter("PriceKind", ?(ПоЗакупочнымЦенам, Catalogs.PriceKinds.Accounting, ContentStructure.PriceKind));
	Query.SetParameter("Specification", ContentStructure.Specification);
	Query.SetParameter("Quantity", ContentStructure.Quantity);
	Query.SetParameter("ProcessingDate", ContentStructure.ProcessingDate);
	Query.SetParameter("RoundMethodsTable", SmallBusinessServer.RoundingTable());
	
	ЭлементыЗапроса = New Array;
	ЭлементыЗапроса.Add(
	"SELECT
	|	RoundMethodsTable.Method AS Order,
	|	RoundMethodsTable.Value AS Value
	|INTO RoundMethodsTable
	|FROM
	|	&RoundMethodsTable AS RoundMethodsTable");
	
	If GetFunctionalOption("UseParametricSpecifications")
		And ValueIsFilled(ContentStructure.Specification)
		And CommonUse.ObjectAttributeValue(ContentStructure.Specification, "IsTemplate") Then
		SpecificationObject = ContentStructure.Specification.GetObject();
		Cancel = False;
		ProductionFormulasServer.FillSpecification(SpecificationObject, Cancel);
		If Cancel Then
			TextOfMessage = StrTemplate(NStr("en='Ошибка формирования: не удалось рассчитать состав параметрической спецификации %1.';ru='Ошибка формирования: не удалось рассчитать состав параметрической спецификации %1.';vi='Lỗi hình thành: không thể tính được thành phần của thông số tham số %1.'"), ContentStructure.Specification);
			Raise TextOfMessage;
		EndIf;
		Query.SetParameter("Content", SpecificationObject.Content.Unload());
		Query.SetParameter("Operations", SpecificationObject.Operations.Unload());
		QueryText = 
		"SELECT
		|	SpecificationsContent.ContentRowType AS ContentRowType,
		|	SpecificationsContent.Stage AS Stage,
		|	SpecificationsContent.ProductsAndServices AS ProductsAndServices,
		|	SpecificationsContent.Characteristic AS Characteristic,
		|	SpecificationsContent.MeasurementUnit AS MeasurementUnit,
		|	SpecificationsContent.Specification AS Specification,
		|	SpecificationsContent.Quantity AS Quantity,
		|	SpecificationsContent.ProductsQuantity AS ProductsQuantity
		|INTO СоставПоШаблону
		|FROM
		|	&Content AS SpecificationsContent
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OperationSpecification.Stage AS Stage,
		|	OperationSpecification.Operation AS Operation,
		|	OperationSpecification.Quantity AS Quantity,
		|	OperationSpecification.TimeNorm AS TimeNorm,
		|	OperationSpecification.ProductsQuantity AS ProductsQuantity
		|INTO ОперацииПоШаблону
		|FROM
		|	&Operations AS OperationSpecification
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	СоставПоШаблону.ContentRowType AS ContentRowType,
		|	VALUE(Enum.ProductsAndServicesTypes.InventoryItem) AS Type,
		|	СоставПоШаблону.Stage AS Stage,
		|	СоставПоШаблону.ProductsAndServices AS ProductsAndServices,
		|	СоставПоШаблону.Characteristic AS Characteristic,
		|	СоставПоШаблону.MeasurementUnit AS MeasurementUnit,
		|	CASE
		|		WHEN VALUETYPE(СоставПоШаблону.MeasurementUnit) = TYPE(Catalog.Uom)
		|			THEN CAST(СоставПоШаблону.MeasurementUnit AS Catalog.Uom).Factor
		|		ELSE 1
		|	END AS Factor,
		|	СоставПоШаблону.Specification AS Specification,
		|	СоставПоШаблону.Quantity * &Quantity AS Quantity,
		|	СоставПоШаблону.ProductsQuantity AS ProductsQuantity
		|INTO Content
		|FROM
		|	СоставПоШаблону AS СоставПоШаблону
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.ProductsAndServicesTypes.Operation),
		|	VALUE(Enum.ProductsAndServicesTypes.Operation),
		|	ОперацииПоШаблону.Stage,
		|	ОперацииПоШаблону.Operation,
		|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef),
		|	ОперацииПоШаблону.TimeNorm,
		|	1,
		|	VALUE(Catalog.Specifications.EmptyRef),
		|	CASE
		|		WHEN CAST(ОперацииПоШаблону.Operation AS Catalog.ProductsAndServices).FixedCost
		|			THEN CASE
		|					WHEN ОперацииПоШаблону.Quantity = 0
		|						THEN 1
		|					ELSE ОперацииПоШаблону.Quantity
		|				END
		|		ELSE ОперацииПоШаблону.TimeNorm
		|	END * &Quantity,
		|	ОперацииПоШаблону.ProductsQuantity
		|FROM
		|	ОперацииПоШаблону AS ОперацииПоШаблону";
	Else
		QueryText = 
		"SELECT
		|	SpecificationsContent.ContentRowType AS ContentRowType,
		|	VALUE(Enum.ProductsAndServicesTypes.InventoryItem) AS Type,
		|	SpecificationsContent.Stage AS Stage,
		|	SpecificationsContent.ProductsAndServices AS ProductsAndServices,
		|	SpecificationsContent.Characteristic AS Characteristic,
		|	SpecificationsContent.MeasurementUnit AS MeasurementUnit,
		|	CASE
		|		WHEN VALUETYPE(SpecificationsContent.MeasurementUnit) = TYPE(Catalog.Uom)
		|			THEN SpecificationsContent.MeasurementUnit.Factor
		|		ELSE 1
		|	END AS Factor,
		|	SpecificationsContent.Specification AS Specification,
		|	ISNULL(SpecificationsContent.Quantity, 0) * &Quantity AS Quantity,
		|	ISNULL(SpecificationsContent.ProductsQuantity, 0) AS ProductsQuantity
		|INTO Content
		|FROM
		|	Catalog.Specifications.Content AS SpecificationsContent
		|WHERE
		|	SpecificationsContent.Ref = &Specification
		|	AND NOT SpecificationsContent.Ref.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.ProductsAndServicesTypes.Operation),
		|	VALUE(Enum.ProductsAndServicesTypes.Operation),
		|	OperationSpecification.Stage,
		|	OperationSpecification.Operation,
		|	VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef),
		|	OperationSpecification.TimeNorm,
		|	1,
		|	VALUE(Catalog.Specifications.EmptyRef),
		|	CASE
		|		WHEN OperationSpecification.Operation.FixedCost
		|			THEN CASE
		|					WHEN OperationSpecification.Quantity = 0
		|						THEN 1
		|					ELSE OperationSpecification.Quantity
		|				END
		|		ELSE OperationSpecification.TimeNorm
		|	END * &Quantity,
		|	ISNULL(OperationSpecification.ProductsQuantity, 0)
		|FROM
		|	Catalog.Specifications.Operations AS OperationSpecification
		|WHERE
		|	OperationSpecification.Ref = &Specification
		|	AND NOT OperationSpecification.Ref.DeletionMark";
	EndIf;
	ЭлементыЗапроса.Add(QueryText);
	ЭлементыЗапроса.Add(
	"SELECT
	|	Content.ContentRowType AS ContentRowType,
	|	Content.Stage AS Stage,
	|	Content.Type AS Type,
	|	Content.ProductsAndServices AS ProductsAndServices,
	|	Content.Characteristic AS Characteristic,
	|	Content.MeasurementUnit AS MeasurementUnit,
	|	Content.Specification AS Specification,
	|	Content.Quantity AS Quantity,
	|	Content.ProductsQuantity AS ProductsQuantity,
	|	CASE
	|		WHEN &ПоЗакупочнымЦенам
	|				AND NOT Content.ContentRowType = VALUE(Enum.ProductsAndServicesTypes.Operation)
	|			THEN CAST(ISNULL(ЗакупочныеЦены.Price, 0) * Content.Factor AS NUMBER(15, 2))
	|		ELSE (CAST(CASE
	|					WHEN Content.MeasurementUnit = ProductsAndServicesPricesSliceLast.MeasurementUnit
	|						THEN ISNULL(ProductsAndServicesPricesSliceLast.Price, 0)
	|					ELSE ISNULL(ProductsAndServicesPricesSliceLast.Price, 0) / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1) * Content.Factor
	|				END / ISNULL(RoundMethodsTable.Value, 0.01) AS NUMBER(15, 0))) * ISNULL(RoundMethodsTable.Value, 0.01)
	|	END AS AccountingPrice,
	|	0 AS Cost
	|FROM
	|	Content AS Content
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(
	|				&ProcessingDate,
	|				PriceKind = &PriceKind
	|					AND (ProductsAndServices, Characteristic) IN
	|						(SELECT
	|							Content.ProductsAndServices,
	|							Content.Characteristic
	|						FROM
	|							Content
	|						WHERE
	|							(NOT &ПоЗакупочнымЦенам
	|								OR Content.ContentRowType = VALUE(Enum.ProductsAndServicesTypes.Operation)))) AS ProductsAndServicesPricesSliceLast
	|			LEFT JOIN RoundMethodsTable AS RoundMethodsTable
	|			ON ProductsAndServicesPricesSliceLast.PriceKind.RoundingOrder = RoundMethodsTable.Order
	|		ON Content.ProductsAndServices = ProductsAndServicesPricesSliceLast.ProductsAndServices
	|			AND Content.Characteristic = ProductsAndServicesPricesSliceLast.Characteristic
	|			AND (NOT &ПоЗакупочнымЦенам
	|				OR Content.ContentRowType = VALUE(Enum.ProductsAndServicesTypes.Operation))
	|		LEFT JOIN (SELECT
	|			Purchases.ProductsAndServices AS ProductsAndServices,
	|			Purchases.Characteristic AS Characteristic,
	|			MIN(CAST(CASE
	|						WHEN Purchases.Quantity = 0
	|							THEN 0
	|						ELSE Purchases.Amount * CurrencyRatesSliceLast.ExchangeRate / CurrencyRatesSliceLast.Multiplicity / Purchases.Quantity
	|					END AS NUMBER(15, 2))) AS Price
	|		FROM
	|			(SELECT
	|				Purchases.ProductsAndServices AS ProductsAndServices,
	|				Purchases.Characteristic AS Characteristic,
	|				MAX(Purchases.Period) AS Period
	|			FROM
	|				AccumulationRegister.Purchases AS Purchases
	|			WHERE
	|				Purchases.Period < &ProcessingDate
	|				AND (Purchases.ProductsAndServices, Purchases.Characteristic) IN
	|						(SELECT
	|							Content.ProductsAndServices,
	|							Content.Characteristic
	|						FROM
	|							Content AS Content
	|						WHERE
	|							&ПоЗакупочнымЦенам
	|							AND NOT Content.ContentRowType = VALUE(Enum.ProductsAndServicesTypes.Operation))
	|			
	|			GROUP BY
	|				Purchases.ProductsAndServices,
	|				Purchases.Characteristic) AS ПоследниеЗакупки
	|				LEFT JOIN AccumulationRegister.Purchases AS Purchases
	|				ON (Purchases.ProductsAndServices = ПоследниеЗакупки.ProductsAndServices)
	|					AND (Purchases.Characteristic = ПоследниеЗакупки.Characteristic)
	|					AND (Purchases.Period = ПоследниеЗакупки.Period),
	|			InformationRegister.CurrencyRates.SliceLast(
	|					&ProcessingDate,
	|					Currency IN
	|						(SELECT
	|							AccountingCurrency.Value
	|						FROM
	|							Constant.AccountingCurrency AS AccountingCurrency)) AS CurrencyRatesSliceLast
	|		
	|		GROUP BY
	|			Purchases.ProductsAndServices,
	|			Purchases.Characteristic) AS ЗакупочныеЦены
	|		ON Content.ProductsAndServices = ЗакупочныеЦены.ProductsAndServices
	|			AND Content.Characteristic = ЗакупочныеЦены.Characteristic
	|			AND (&ПоЗакупочнымЦенам)
	|			AND (NOT Content.ContentRowType = VALUE(Enum.ProductsAndServicesTypes.Operation))");
	
	Query.Text = StrConcat(
	ЭлементыЗапроса,
	"
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|");
		
	Return Query.Execute().Select();
	
EndFunction // ПолучитьСоставСпецификации()

// Процедура добавляет новый узел в стек номенклатуры для разузлования.
//
// Parameters:
//  ContentStructure - Структура состава
//	StackProductsAndServices - ТаблицаЗначений стек номенклатуры
//	StackProductsAndServicesStackEntries - ТаблицаЗначений стек входов номенклатуры
//	NewRowStack - ValueTableRow - строка стека
//	curRow     - ValueTableRow - текущая строка.
//
Procedure AddNode(ContentStructure, StackProductsAndServices, StackProductsAndServicesStackEntries, NewRowStack, curRow)
	
	NewRowStack = StackProductsAndServices.Add();
	NewRowStack.ProductsAndServices	= curRow.ProductsAndServices;
	NewRowStack.Characteristic = curRow.Characteristic;
	NewRowStack.Specification	= curRow.Specification;
	NewRowStack.Level		= curRow.Level;
	
	// Инициализация вложенного стека.
	StackProductsAndServicesStackEntries = StackProductsAndServicesStackEntries.CopyColumns();
	NewRowStack.StackEntries = StackProductsAndServicesStackEntries;
	
	// Заполнение структуры состава.
	ContentStructure.Stage					= curRow.Stage;
	ContentStructure.Type					= curRow.Type;
	ContentStructure.ContentRowType		= curRow.ContentRowType;
	ContentStructure.ProductsAndServices			= curRow.ProductsAndServices;
	ContentStructure.Characteristic			= curRow.Characteristic;
	ContentStructure.MeasurementUnit		= curRow.MeasurementUnit;
	ContentStructure.Quantity				= curRow.Quantity / ?(curRow.ProductsQuantity <> 0, curRow.ProductsQuantity, 1);
	ContentStructure.ProductsQuantity	= curRow.ProductsQuantity;
	ContentStructure.Level				= NewRowStack.Level;
	ContentStructure.AccountingPrice			= curRow.AccountingPrice;
	ContentStructure.Cost				= ContentStructure.Quantity * curRow.AccountingPrice;
		
	If curRow.Specification.DeletionMark Then
		ContentStructure.Specification = Catalogs.Specifications.EmptyRef();
	Else
		ContentStructure.Specification = curRow.Specification;
	EndIf;
		
EndProcedure // ДобавитьУзел()

// Выполняет разузлование узла.
//
// Parameters:
//  ContentStructure - Структура, описывающая обрабатываемый узел
//	ContentTable - ТаблицаЗначений состава и операций
//  
Procedure RunExplosion(ContentStructure, ContentTable)
	
	ContentNewRow = ContentTable.Add();
	FillPropertyValues(ContentNewRow, ContentStructure);
	ContentNewRow.Node				= False;
	
	If ContentStructure.ContentRowType = Enums.SpecificationContentRowTypes.Node
	 Or ContentStructure.ContentRowType = Enums.SpecificationContentRowTypes.Assembly
	 Or ContentStructure.Level = 0 Then
			
		ContentNewRow.Node			= True;
	 
	EndIf;
		
EndProcedure // ВыполнитьРазузлование()	

// Процедура разузлования.
//
// Parameters:
//  ContentStructure - Структура, описывающая обрабатываемый узел
//	Объект
//	ContentTable - ТаблицаЗначений состава и операций
//  
Procedure Denoding(ContentStructure, ContentTable)
	
	// Инициализация стека номенклатуры.
	StackProductsAndServices = New ValueTable();
	StackProductsAndServices.Columns.Add("ProductsAndServices");
	StackProductsAndServices.Columns.Add("Characteristic");
	StackProductsAndServices.Columns.Add("Specification");
	StackProductsAndServices.Columns.Add("Level");
	
	StackProductsAndServices.Columns.Add("StackEntries");
	
	StackProductsAndServices.Indexes.Add("ProductsAndServices, Characteristic, Specification");
	
	// Инициализация таблицы Входы.
	StackProductsAndServicesStackEntries = New ValueTable();
	StackProductsAndServicesStackEntries.Columns.Add("ContentRowType");
	StackProductsAndServicesStackEntries.Columns.Add("Stage");
	StackProductsAndServicesStackEntries.Columns.Add("Type");
	StackProductsAndServicesStackEntries.Columns.Add("ProductsAndServices");
	StackProductsAndServicesStackEntries.Columns.Add("Characteristic");
	StackProductsAndServicesStackEntries.Columns.Add("MeasurementUnit");
	StackProductsAndServicesStackEntries.Columns.Add("Quantity");
	StackProductsAndServicesStackEntries.Columns.Add("ProductsQuantity");
	StackProductsAndServicesStackEntries.Columns.Add("Specification");
	StackProductsAndServicesStackEntries.Columns.Add("Level");
	StackProductsAndServicesStackEntries.Columns.Add("AccountingPrice");
	StackProductsAndServicesStackEntries.Columns.Add("Cost");
	
	ContentStructure.Level = 0;
	
	// Начальное заполнение стека.
	NewRowStack = StackProductsAndServices.Add();
	NewRowStack.ProductsAndServices	= ContentStructure.ProductsAndServices;
	NewRowStack.Characteristic	= ContentStructure.Characteristic;
	NewRowStack.Specification	= ContentStructure.Specification;
	NewRowStack.Level		= ContentStructure.Level;
	
	NewRowStack.StackEntries		= StackProductsAndServicesStackEntries;
	
	RunExplosion(ContentStructure, ContentTable);
	
	// Пока есть, что разузловывать.
	While StackProductsAndServices.Count() <> 0 Do
		
		ProductsAndServicesSelection = GetSpecificationContent(ContentStructure);
		
		If ProductsAndServicesSelection<>Undefined Then
			
			While ProductsAndServicesSelection.Next() Do
				
				If Not ValueIsFilled(ProductsAndServicesSelection.ProductsAndServices) Then
					Continue;
				EndIf;
				
				// Проверяем рекурсивный вход.
				SearchStructure = New Structure;
				SearchStructure.Insert("ProductsAndServices",	ProductsAndServicesSelection.ProductsAndServices);
				SearchStructure.Insert("Characteristic",	ProductsAndServicesSelection.Characteristic);
				SearchStructure.Insert("Specification",	ProductsAndServicesSelection.Specification);
				
				RecursiveEntryStrings = StackProductsAndServices.FindRows(SearchStructure);
				
				If RecursiveEntryStrings.Count() <> 0 Then
					
					For Each EntAttributeString In RecursiveEntryStrings Do
						
						TextOfMessage = StrTemplate(
						NStr("en='Обнаружено рекурсивное вхождение элемента %1 в элемент %2!';ru='Обнаружено рекурсивное вхождение элемента %1 в элемент %2!';vi='Tìm thấy sự xuất hiện đệ quy của mục %1 trong mục %2!'"),
						ProductsAndServicesSelection.ProductsAndServices,
						ContentStructure.ProductsAndServices);
						SmallBusinessServer.ShowMessageAboutError(ContentStructure.Object, TextOfMessage);
						
					EndDo;
					
					Continue;
					
				EndIf;
				
				// Добавление новых узлов.
				NewStringEnter = StackProductsAndServicesStackEntries.Add();
				FillPropertyValues(NewStringEnter, ProductsAndServicesSelection, "ContentRowType, Stage, Type, ProductsAndServices, Characteristic, MeasurementUnit, ProductsQuantity, Specification");
				
				RateUnitDimensions			= ?(TypeOf(ContentStructure.MeasurementUnit) = Type("CatalogRef.Uom"),
				ContentStructure.MeasurementUnit.Factor,
				1);
															
				NewStringEnter.Quantity			= ProductsAndServicesSelection.Quantity * RateUnitDimensions;
				NewStringEnter.Level				= NewRowStack.Level + 1;
				NewStringEnter.AccountingPrice			= Number(ProductsAndServicesSelection.AccountingPrice);
				NewStringEnter.Cost			= Number(ProductsAndServicesSelection.Cost) * RateUnitDimensions;
				
			EndDo; // ВыборкаНоменклатуры
			
		EndIf; 
		
		// Конец ветви или нет?
		If StackProductsAndServicesStackEntries.Count() = 0 Then
			
			// Удаляем из стека номенклатуру, которая не имеет продолжения.
			StackProductsAndServices.Delete(NewRowStack);
			
			ReadinessFlag = True;
			While StackProductsAndServices.Count() <> 0 And ReadinessFlag Do
				
				// Получаем предыдущую строку стека номенклатуры.
				PreStringProductsAndServicesStack = StackProductsAndServices.Get(StackProductsAndServices.Count() - 1);
				
				// Удаляем из стека входов.
				PreStringProductsAndServicesStack.StackEntries.Delete(0);
					
				If PreStringProductsAndServicesStack.StackEntries.Count() = 0 Then
					
					// Если стек входов пустой, удаляем строку из стека номенклатуры.
					StackProductsAndServices.Delete(PreStringProductsAndServicesStack);
					
				Else // разузловываем следующую номенклатуру из стека входов.
					
					ReadinessFlag = False;
					
					curRow = PreStringProductsAndServicesStack.StackEntries.Get(0);
					
					AddNode(ContentStructure, StackProductsAndServices, StackProductsAndServicesStackEntries, NewRowStack, curRow);
					RunExplosion(ContentStructure, ContentTable);
					
				EndIf;
				
			EndDo;
			
		Else // добавляем узлы
			
			curRow = StackProductsAndServicesStackEntries.Get(0);
			
			AddNode(ContentStructure, StackProductsAndServices, StackProductsAndServicesStackEntries, NewRowStack, curRow);
			RunExplosion(ContentStructure, ContentTable);
			
		EndIf;
		
	EndDo; // СтекНоменклатуры
	
EndProcedure // Разузлование() 

#EndRegion
