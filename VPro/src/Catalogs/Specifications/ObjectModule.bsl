#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Var RecordNew;

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf; 
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Owner", Owner);
	Query.SetParameter("ProductCharacteristic", ProductCharacteristic);
	
	// При записи первой спецификации по связке номенклатура-характеристика устанавливаем ее основной
	If Not DeletionMark And Not NotValid And RecordNew=True Then
		Query.Text =
		"SELECT ALLOWED TOP 1
		|	Specifications.Ref AS Ref
		|FROM
		|	Catalog.Specifications AS Specifications
		|WHERE
		|	Specifications.Ref <> &Ref
		|	AND Specifications.Owner = &Owner
		|	AND Specifications.ProductCharacteristic = &ProductCharacteristic";
		If Query.Execute().IsEmpty() Then
			Record = InformationRegisters.DefaultSpecifications.CreateRecordManager();
			Record.ProductsAndServices = Owner;
			Record.Characteristic = ProductCharacteristic;
			Record.Specification = Ref;
			Record.Write(True);
		EndIf; 
	EndIf;
	
	// Удаление старых данных об основной спецификации при изменении номенклатуры / характеристики спецификации
	If RecordNew<>True Then
		Query.Text =
		"SELECT ALLOWED
		|	DefaultSpecifications.ProductsAndServices AS ProductsAndServices,
		|	DefaultSpecifications.Characteristic AS Characteristic
		|FROM
		|	InformationRegister.DefaultSpecifications AS DefaultSpecifications
		|WHERE
		|	DefaultSpecifications.Specification = &Ref
		|	AND (DefaultSpecifications.ProductsAndServices <> &Owner
		|			OR DefaultSpecifications.Characteristic <> &ProductCharacteristic
		|			OR DefaultSpecifications.Specification.NotValid)";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Record = InformationRegisters.DefaultSpecifications.CreateRecordManager();
			Record.ProductsAndServices = Selection.ProductsAndServices;
			Record.Characteristic = Selection.Characteristic;
			Record.Delete();	
		EndDo; 
	EndIf; 
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf; 
	
	// Снятие признака основной для помеченных на удаление и недействительных спецификаций
	If (DeletionMark Or NotValid) And Not Ref.IsEmpty() Then
		
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.Text =
		"SELECT ALLOWED
		|	DefaultSpecifications.Specification AS Specification,
		|	DefaultSpecifications.ProductsAndServices AS ProductsAndServices,
		|	DefaultSpecifications.Characteristic AS Characteristic
		|FROM
		|	InformationRegister.DefaultSpecifications AS DefaultSpecifications
		|WHERE
		|	DefaultSpecifications.Specification = &Ref
		|	AND NOT DefaultSpecifications.Specification.DeletionMark";
		Selection = Query.Execute().Select();
		
		Try
			While Selection.Next() Do
				Record = InformationRegisters.DefaultSpecifications.CreateRecordManager();
				Record.ProductsAndServices = Selection.ProductsAndServices;
				Record.Characteristic = Selection.Characteristic;
				Record.Specification = Selection.Specification;
				Record.Delete();
			EndDo;
			If Selection.Count()>0 Then
				TextOfMessage = NStr("en='The %1 BOM is invalid or marked for removal. The sign <основная>s been filmed.';ru='Спецификация %1 недействительна или помечена на удаление. Признак <основная> снят.';vi='Bảng kê chi tiết %1 không có hiệu lực hoặc đã bị đặt dấu xóa. Đã bỏ dấu hiệu <chính>.'");
				TextOfMessage = StrTemplate(TextOfMessage, Description);
				CommonUseClientServer.MessageToUser(TextOfMessage);
			EndIf; 
		Except
			TextOfMessage = NStr("en='It was not possible to remove the main feature for the %1 BOM.';ru='Не удалось снять признак основной для спецификации %1.';vi='Không thể bỏ dấu hiệu chính đối với bảng kê chi tiết %1.'");
			TextOfMessage = StrTemplate(TextOfMessage, Description);
			CommonUseClientServer.MessageToUser(TextOfMessage);
		EndTry;

	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ProductionKind) Then
		For Each TabularSectionRow In Content Do
			TabularSectionRow.Stage = Catalogs.ProductionStages.EmptyRef();
		EndDo; 
		For Each TabularSectionRow In Operations Do
			TabularSectionRow.Stage = Catalogs.ProductionStages.EmptyRef();
		EndDo;
	Else
		For Each TabularSectionRow In Content Do
			If Not ValueIsFilled(TabularSectionRow.Stage) Then
				TabularSectionRow.Stage = Catalogs.ProductionStages.ProductionComplete;
			EndIf; 
		EndDo; 
		For Each TabularSectionRow In Operations Do
			If Not ValueIsFilled(TabularSectionRow.Stage) Then
				TabularSectionRow.Stage = Catalogs.ProductionStages.ProductionComplete;
			EndIf; 
		EndDo;
	EndIf;
	
	RecordNew = IsNew();
	
	If Not ValueIsFilled(DocOrder) Then
		DocOrder = Undefined;
	EndIf; 
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf; 
	
	If ValueIsFilled(ProductionKind) Then
		CheckedAttributes.Add("Content.Stage");
		CheckedAttributes.Add("Operations.Stage");
	EndIf; 
	
	// Дублирование и наличие незапланированных этапов
	Query = New Query;
	Query.SetParameter("ProductionKind", ProductionKind);
	Query.SetParameter("Content", Content.Unload());
	Query.SetParameter("Operations", Operations.Unload());
	Query.Text = 
	"SELECT
	|	ProductionKindsStages.LineNumber AS LineNumber,
	|	ProductionKindsStages.Stage AS Stage,
	|	1 AS Quantity
	|INTO Stages
	|FROM
	|	Catalog.ProductionKinds.Stages AS ProductionKindsStages
	|WHERE
	|	ProductionKindsStages.Ref = &ProductionKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Content.LineNumber AS LineNumber,
	|	Content.Stage AS Stage
	|INTO Content
	|FROM
	|	&Content AS Content
	|WHERE
	|	Content.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.LineNumber AS LineNumber,
	|	Operations.Stage AS Stage
	|INTO Operations
	|FROM
	|	&Operations AS Operations
	|WHERE
	|	Operations.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Content.LineNumber AS LineNumber,
	|	Content.Stage AS Stage,
	|	""Content"" AS TabularSectionName
	|FROM
	|	Content AS Content
	|WHERE
	|	NOT Content.Stage IN
	|				(SELECT
	|					Stages.Stage
	|				FROM
	|					Stages)
	|
	|UNION ALL
	|
	|SELECT
	|	Operations.LineNumber,
	|	Operations.Stage,
	|	""Operations""
	|FROM
	|	Operations AS Operations
	|WHERE
	|	NOT Operations.Stage IN
	|				(SELECT
	|					Stages.Stage
	|				FROM
	|					Stages)";
	Result = Query.ExecuteBatch();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		TextOfMessage = StrTemplate(NStr("en='Unplanned stage used: %1';ru='Используется незапланированный этап: %1';vi='Đang sử dụng giai đoạn chưa lập kế hoạch: %1'"), Selection.Stage);
		CommonUseClientServer.MessageToUser(TextOfMessage,
		ThisObject,
		CommonUseClientServer.PathToTabularSection(Selection.TabularSectionName, Selection.LineNumber, "Stage"),
		,
		Cancel);
	EndDo; 
	
	// Проверка на участвие в производстве при изменении признака использования этапов
	If Not IsNew() 
		And (ProductionKind<>Ref.ProductionKind) Then
		Query = New Query;
		Query.SetParameter("Specification", Ref);
		Query.Text =
		"SELECT TOP 1
		|	ProductionOrderProducts.Ref AS Ref
		|FROM
		|	Document.ProductionOrder.Products AS ProductionOrderProducts
		|WHERE
		|	ProductionOrderProducts.Specification = &Specification
		|	AND ProductionOrderProducts.Ref.Posted
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	InventoryAssemblyProducts.Ref
		|FROM
		|	Document.InventoryAssembly.Products AS InventoryAssemblyProducts
		|WHERE
		|	InventoryAssemblyProducts.Specification = &Specification
		|	AND InventoryAssemblyProducts.Ref.Posted
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	JobSheetOperations.Ref
		|FROM
		|	Document.JobSheet.Operations AS JobSheetOperations
		|WHERE
		|	JobSheetOperations.Specification = &Specification
		|	AND JobSheetOperations.Ref.Posted";
		If Not Query.Execute().IsEmpty() Then
			TextOfMessage = NStr("en='The specification is used in documents. Changing the type of production is prohibited';ru='Спецификация используется в документах. Изменение вида производства запрещено';vi='Bảng kê chi tiết được sử dụng trong các văn bản. Cấm thay đổi dạng sản xuất'");
			CommonUseClientServer.MessageToUser(TextOfMessage,
			ThisObject,
			"ProductionKind",
			,
			Cancel);
		EndIf; 
	EndIf;
	
	UseParametricSpecifications = GetFunctionalOption("UseParametricSpecifications");
	For Each TabularSectionRow In Content Do
		If UseParametricSpecifications And Not ValueIsFilled(TabularSectionRow.ProductsAndServices) And IsBlankString(TabularSectionRow.FormulaProductsAndServices)  Then
			TextOfMessage = StrTemplate(NStr("en='No item or formula for determining it is specified in the %1 line';ru='Не указана номенклатура или формула ее определения в строке %1';vi='Chưa chỉ ra mặt hàng hoặc công thức xác định nó tại dòng %1'"), TabularSectionRow.LineNumber);
			CommonUseClientServer.MessageToUser(TextOfMessage,
			ThisObject,
			CommonUseClientServer.PathToTabularSection("Content", TabularSectionRow.LineNumber, "ProductsAndServices"),
			,
			Cancel);
		ElsIf Not UseParametricSpecifications And Not ValueIsFilled(TabularSectionRow.ProductsAndServices) Then 
			TextOfMessage = StrTemplate(NStr("en='No item is listed in the %1 line';ru='Не указана номенклатура в строке %1';vi='Chưa chỉ ra mặt hàng tại dòng %1'"), TabularSectionRow.LineNumber);
			CommonUseClientServer.MessageToUser(TextOfMessage,
			ThisObject,
			CommonUseClientServer.PathToTabularSection("Content", TabularSectionRow.LineNumber, "ProductsAndServices"),
			,
			Cancel);
		EndIf;
		If Not UseParametricSpecifications And Not ValueIsFilled(TabularSectionRow.MeasurementUnit) And GetFunctionalOption("AccountingInVariousUOM") Then
			TextOfMessage = StrTemplate(NStr("en='No unit of measurement in line %1';ru='Не указана единица измерения в строке %1';vi='Chưa chỉ ra đơn vị tính tại dòng %1'"), TabularSectionRow.LineNumber);
			CommonUseClientServer.MessageToUser(TextOfMessage,
			ThisObject,
			CommonUseClientServer.PathToTabularSection("Content", TabularSectionRow.LineNumber, "MeasurementUnit"),
			,
			Cancel);
		EndIf; 
	EndDo; 
	
EndProcedure

#EndIf 
