
////////////////////////////////////////////////////////////////////////////////
// SERVICE PROGRAMMING INTERFACE

// Procedure initializes the IsFirstLaunch session parameters.
//
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	
	
EndProcedure //SessionParametersSetting_IsFirstLaunch()

// Defines whether the passed object is a document
//
Function IsMetadataKindDocument(ObjectName)
	
	Return Not Metadata.Documents.Find(ObjectName) = Undefined;
	
EndFunction // IsMetadataKindDocument()

// Used in the first start assistant
//
// Called:
// InfobaseUpdateClientOverridable.OpenFirstStartAssistant();
//
Function GetActivityKind() Export
	
	ActivityKind = Constants.ActivityKind.Get();
	
	If Catalogs.Companies.MainCompany.Description <> NStr("en = 'LLC ""Our company"";'ru = 'ООО ""Наша фирма""'")
	AND Not IsBlankString(Catalogs.Companies.MainCompany.Description)
	AND Not ValueIsFilled(ActivityKind) Then
		SetPrivilegedMode(True);
		ActivityKind = Enums.CompanyActivityKinds.TradeServicesProduction;
		Constants.ActivityKind.Set(ActivityKind);
		Constants.FunctionalOptionUseSubsystemPayroll.Set(True);
		Constants.FunctionalOptionUseWorkSubsystem.Set(True);
		Constants.FunctionalOptionUseSubsystemProduction.Set(True);
		SetPrivilegedMode(False);
		ActivityKindSelected = True;
	EndIf;
	
	Return ActivityKind;
	
EndFunction // GetActivityKind()

// Function converts row to the plural
//
// Parameters: 
//  Word1 - word form in singular
//  ("box") Word2 - word form for numeral
//  2-4 ("box") Word3 - word form for numeral 5-10
//  ("boxes") IntegerNumber - integer number
//
// Returns:
//  string - one of the rows depending on the IntegerNumber parameter
//
// Definition:
//  Designed to generate "correct" signature to numerals
//
Function FormOfMultipleNumbers(Word1, Word2, Word3, Val IntegerNumber) Export
	
	// Change integer sign, otherwise, negative numbers will be converted incorrectly.
	If IntegerNumber < 0 Then
		IntegerNumber = -1 * IntegerNumber;
	EndIf;
	
	If IntegerNumber <> Int(IntegerNumber) Then 
		// for nonintegral numbers - always the second form
		Return Word2;
	EndIf;
	
	// Balance
	Balance = IntegerNumber%10;
	If (IntegerNumber >10) AND (IntegerNumber<20) Then
		// for the second dozen - always the third form
		Return Word3;
	ElsIf Balance=1 Then
		Return Word1;
	ElsIf (Balance>1) AND (Balance<5) Then
		Return Word2;
	Else
		Return Word3;
	EndIf;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// CONDITIONAL DESIGN PROCEDURES AND FUNCTIONS

// Procedure sets conditional design in
// the dynamic lists of the "Date" column.
//
Procedure SetDesignDateColumn(DinList) Export
	
	ListOfItemsForDeletion = New ValueList;
	For Each ConditionalAppearanceItem IN DinList.SettingsComposer.Settings.ConditionalAppearance.Items Do
		If ConditionalAppearanceItem.UserSettingID = "PresetOnlyTimeDateField"
			OR ConditionalAppearanceItem.Presentation = "Date field format (today – only time)" Then
			ListOfItemsForDeletion.Add(ConditionalAppearanceItem);
		EndIf;
	EndDo;
	For Each Item IN ListOfItemsForDeletion Do
		DinList.SettingsComposer.Settings.ConditionalAppearance.Items.Delete(Item.Value);
	EndDo;
	
	DesignElement = DinList.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	DesignElement.Presentation = "Date field format (today – only time)";
	DesignElement.UserSettingID = "PresetOnlyTimeDateField";
	
	DesignElement.Use = True;
	
	FilterItemGroup = DesignElement.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemGroup.Use = True;
	
	FilterItem = FilterItemGroup.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.Use		= True;
	FilterItem.ComparisonType		= DataCompositionComparisonType.GreaterOrEqual;
	FilterItem.LeftValue		= New DataCompositionField("Date");
	FilterItem.RightValue	= New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	FilterItem = FilterItemGroup.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.Use		= True;
	FilterItem.ComparisonType		= DataCompositionComparisonType.LessOrEqual;
	FilterItem.LeftValue		= New DataCompositionField("Date");
	FilterItem.RightValue	= New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
	DesignElement.Appearance.SetParameterValue("Format", "DF=h:mm");
	
	MadeOutField = DesignElement.Fields.Items.Add();
	MadeOutField.Field = New DataCompositionField("Date");
	
EndProcedure // SetDesignDateColumn()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS OF DOCUMENT HEADER FILLING

// Procedure is designed to fill in
// the documents general attributes. It is called in the OnCreateAtServer event handlers in the form modules of all documents.
//
// Parameters:
//  DocumentObject					- object of the edited document;
//  OperationKind						- optional, operation kind row ("Purchase"
// 									or "Sell") if it is not passed, the attributes that depend on the operation type are not filled in
//
//  ParameterCopiedObject		- REF in document copying either structure with
//  data copying BasisParameter				- ref to base document or a structure with copying data
//
Procedure FillDocumentHeader(Object,
	OperationKind = "",
	ParameterCopyingValue = Undefined,
	BasisParameter = Undefined,
	PostingIsAllowed,
	FillingValues = Undefined) Export
	
	User 		= Users.CurrentUser();
	DocumentMetadata = Object.Ref.Metadata();
	PostingIsAllowed = DocumentMetadata.Posting = Metadata.ObjectProperties.Posting.Allow;
	
	If ValueIsFilled(BasisParameter)
		AND Not TypeOf(BasisParameter) = Type("Structure") Then
		
		BasisDocumentMetadata = BasisParameter.Metadata();
		
	EndIf;
	
	If ValueIsFilled(ParameterCopyingValue) 
		AND Not TypeOf(ParameterCopyingValue) = Type("Structure") Then
		
		CopyingDocumentMetadata =  ParameterCopyingValue.Metadata();
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		Object.Author				= User;
		
		If Not ValueIsFilled(ParameterCopyingValue)
		   AND IsDocumentAttribute("DocumentCurrency", Object.Ref.Metadata()) Then
			
			If Not ValueIsFilled(Object.DocumentCurrency) Then
				
				Object.DocumentCurrency = Constants.NationalCurrency.Get();
				
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(ParameterCopyingValue)
		   AND IsDocumentAttribute("CashCurrency", Object.Ref.Metadata()) Then
			
			If Not ValueIsFilled(Object.CashCurrency) Then
				
				Object.CashCurrency = Constants.NationalCurrency.Get();
				
			EndIf;
			
		EndIf;
		
		If IsDocumentAttribute("SettlementsCurrency", Object.Ref.Metadata()) Then
			
			If Not ValueIsFilled(Object.SettlementsCurrency) Then
				
				Object.SettlementsCurrency = Constants.NationalCurrency.Get();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	//  Exceptions
	If DocumentMetadata.Name = "ReceiptCR"
	OR DocumentMetadata.Name = "ReceiptCRReturn" Then
	
		If Not ValueIsFilled(Object.Ref)
			AND IsDocumentAttribute("Responsible", DocumentMetadata)
			AND Not (FillingValues <> Undefined 
				AND FillingValues.Property("Responsible") 
				AND ValueIsFilled(FillingValues.Responsible))
			AND Not ValueIsFilled(Object.Responsible) Then
			
			Object.Responsible = 
				SmallBusinessReUse.GetValueByDefaultUser(User, "MainResponsible");
			
		EndIf;
		
		Return;
		
	EndIf;
	
	//  Filling
	If Not ValueIsFilled(Object.Ref) Then
		
		If IsDocumentAttribute("AmountIncludesVAT", DocumentMetadata) Then 					// Document has the AmountIncludesVAT attribute
			
			If ValueIsFilled(BasisParameter) 												// Fill in if the base parameter is filled in
				AND Not TypeOf(BasisParameter) = Type("Structure")									// (in some cases, a structure is passed instead of a document ref)
				AND IsMetadataKindDocument(BasisDocumentMetadata.Name) 						// and base is a document and not, for example, a catalog
				AND IsDocumentAttribute("AmountIncludesVAT", BasisDocumentMetadata) Then 	// that has the similar attribute "AmountIncludesVAT"
				
				Object.AmountIncludesVAT = BasisParameter.AmountIncludesVAT;
				
			ElsIf ValueIsFilled(ParameterCopyingValue) 								// Fill in if the copying parameter is filled in.
				AND Not TypeOf(ParameterCopyingValue) = Type("Structure")							// (in some cases, a structure is passed instead of a document ref)
				AND IsMetadataKindDocument(CopyingDocumentMetadata.Name)						// and is a document 
				AND IsDocumentAttribute("AmountIncludesVAT", CopyingDocumentMetadata) Then	// that has the similar attribute "AmountIncludesVAT"
				
				Object.AmountIncludesVAT = ParameterCopyingValue.AmountIncludesVAT;
				
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(ParameterCopyingValue) Then
			
			If DocumentMetadata.Name = "RetailReport" Then
				If IsDocumentAttribute("PositionAssignee", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "PositionAssignee");
					If ValueIsFilled(SettingValue) Then
						If Object.PositionAssignee <> SettingValue Then
							Object.PositionAssignee = SettingValue;
						EndIf;
					Else
						Object.PositionAssignee = Enums.AttributePositionOnForm.InHeader;
					EndIf;
				EndIf;
				If IsDocumentAttribute("PositionResponsible", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "PositionResponsible");
					If ValueIsFilled(SettingValue) Then
						If Object.PositionResponsible <> SettingValue Then
							Object.PositionResponsible = SettingValue;
						EndIf;
					Else
						Object.PositionResponsible = Enums.AttributePositionOnForm.InHeader;
					EndIf;
				EndIf;
				Return;
			EndIf;
			
			If IsDocumentAttribute("Company", DocumentMetadata) 
				AND Not (FillingValues <> Undefined AND FillingValues.Property("Company") AND ValueIsFilled(FillingValues.Company))
				AND Not (ValueIsFilled(BasisParameter)
				AND ValueIsFilled(Object.Company)) Then
				SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainCompany");
				If ValueIsFilled(SettingValue) Then
					If Object.Company <> SettingValue Then
						Object.Company = SettingValue;
					EndIf;
				Else
					Object.Company = GetPredefinedCompany();
				EndIf;
			EndIf;
			
			If IsDocumentAttribute("SalesStructuralUnit", DocumentMetadata) 
				AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.SalesStructuralUnit)) Then
				SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainDepartment");
				
				If ValueIsFilled(SettingValue) Then
					If Object.SalesStructuralUnit <> SettingValue Then
						Object.SalesStructuralUnit = SettingValue;
					EndIf;
				Else
					Object.SalesStructuralUnit = Catalogs.StructuralUnits.MainDepartment;	
				EndIf;
			EndIf;
			
			If IsDocumentAttribute("Department", DocumentMetadata) 
				AND Not (FillingValues <> Undefined AND FillingValues.Property("Department") AND ValueIsFilled(FillingValues.Department))
				AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.Department)) Then
				SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainDepartment");
				If ValueIsFilled(SettingValue) Then
					If Object.Department <> SettingValue Then
						Object.Department = SettingValue;
					EndIf;
				Else
					Object.Department = Catalogs.StructuralUnits.MainDepartment;
				EndIf;
			EndIf;
			
			If IsDocumentAttribute("DocumentCurrency", DocumentMetadata)
				AND Not ValueIsFilled(Object.DocumentCurrency)
				AND Not (FillingValues <> Undefined
				    AND FillingValues.Property("DocumentCurrency")
				    AND ValueIsFilled(FillingValues.DocumentCurrency)) Then
				Object.DocumentCurrency = Constants.NationalCurrency.Get();
			EndIf;
			
			If DocumentMetadata.Name = "WorkOrder"
			 OR DocumentMetadata.Name = "PurchaseOrder"
			 OR DocumentMetadata.Name = "Payroll"
			 OR DocumentMetadata.Name = "SalesTarget"
			 OR DocumentMetadata.Name = "PayrollSheet"
			 OR DocumentMetadata.Name = "OtherExpenses"
			 OR DocumentMetadata.Name = "CostAllocation"
			 OR DocumentMetadata.Name = "JobSheet"
			 OR DocumentMetadata.Name = "Timesheet"
			 OR DocumentMetadata.Name = "TimeTracking"
			 Then
				If IsDocumentAttribute("StructuralUnit", DocumentMetadata) 
					AND Not (FillingValues <> Undefined AND FillingValues.Property("StructuralUnit") AND ValueIsFilled(FillingValues.StructuralUnit))
					AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.StructuralUnit)) Then
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainDepartment");
					If ValueIsFilled(SettingValue) 
						AND StructuralUnitTypeToChoiceParameters("StructuralUnit", DocumentMetadata, SettingValue) Then
						If Object.StructuralUnit <> SettingValue Then
							Object.StructuralUnit = SettingValue;
						EndIf;
					Else
						Object.StructuralUnit = Catalogs.StructuralUnits.MainDepartment;	
					EndIf;
						
				EndIf;
			EndIf;
				
			If IsDocumentAttribute("StructuralUnitReserve", DocumentMetadata) 
				AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.StructuralUnitReserve)) Then
				SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainWarehouse");
				If ValueIsFilled(SettingValue) 
					AND StructuralUnitTypeToChoiceParameters("StructuralUnitReserve", DocumentMetadata, SettingValue) Then
					If Object.StructuralUnitReserve <> SettingValue Then
						Object.StructuralUnitReserve = SettingValue;
					EndIf;
				Else
					Object.StructuralUnitReserve = MainWarehouse();
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "AdditionalCosts"
			 OR DocumentMetadata.Name = "InventoryReconciliation"
			 OR DocumentMetadata.Name = "InventoryReceipt"
			 OR DocumentMetadata.Name = "ProcessingReport"
			 OR DocumentMetadata.Name = "SubcontractorReport"
			 OR DocumentMetadata.Name = "TransferBetweenCells"
			 OR DocumentMetadata.Name = "FixedAssetsEnter"
			 OR DocumentMetadata.Name = "SupplierInvoice"
			 OR DocumentMetadata.Name = "GoodsReceipt"
			 OR DocumentMetadata.Name = "GoodsExpense"
			 OR DocumentMetadata.Name = "CustomerInvoice"
			 OR DocumentMetadata.Name = "InventoryWriteOff"
			 Then
				If IsDocumentAttribute("StructuralUnit", DocumentMetadata) 
					AND Not (FillingValues <> Undefined AND FillingValues.Property("StructuralUnit") AND ValueIsFilled(FillingValues.StructuralUnit))
					AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.StructuralUnit)) Then
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainWarehouse");
					If ValueIsFilled(SettingValue) 
						AND StructuralUnitTypeToChoiceParameters("StructuralUnit", DocumentMetadata, SettingValue) Then
						If Object.StructuralUnit <> SettingValue Then
							Object.StructuralUnit = SettingValue;
						EndIf;
					Else
						Object.StructuralUnit = MainWarehouse();
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "InventoryAssembly" Then
				
				// Structural unit.
				SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainDepartment");
				If Not (FillingValues <> Undefined AND FillingValues.Property("StructuralUnit") AND ValueIsFilled(FillingValues.StructuralUnit))
					AND Not (ValueIsFilled(BasisParameter)
					AND ValueIsFilled(Object.StructuralUnit)) Then
					If ValueIsFilled(SettingValue) 
						AND StructuralUnitTypeToChoiceParameters("StructuralUnit", DocumentMetadata, SettingValue) Then
						If Object.StructuralUnit <> SettingValue Then
							Object.StructuralUnit = SettingValue;
						EndIf;
					Else
						Object.StructuralUnit = Catalogs.StructuralUnits.MainDepartment;	
					EndIf;
				EndIf;
				
				// Structural unit of products.
				If Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.ProductsStructuralUnit)) Then
					If ValueIsFilled(Object.StructuralUnit.TransferRecipient)
						AND (Object.StructuralUnit.TransferRecipient.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse
							OR Object.StructuralUnit.TransferRecipient.StructuralUnitType = Enums.StructuralUnitsTypes.Department) Then
						Object.ProductsStructuralUnit = Object.StructuralUnit.TransferRecipient;
						Object.ProductsCell = Object.StructuralUnit.TransferRecipientCell;
					Else
						Object.ProductsStructuralUnit = Object.StructuralUnit;
					EndIf;
				EndIf;
						
				// Inventory structural unit.
				If Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.InventoryStructuralUnit)) Then
					If ValueIsFilled(Object.StructuralUnit.TransferSource)
						AND (Object.StructuralUnit.TransferSource.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse
							OR Object.StructuralUnit.TransferSource.StructuralUnitType = Enums.StructuralUnitsTypes.Department) Then
						Object.InventoryStructuralUnit = Object.StructuralUnit.TransferSource;
						Object.CellInventory = Object.StructuralUnit.TransferSourceCell;
					Else
						Object.InventoryStructuralUnit = Object.StructuralUnit;
					EndIf;
				EndIf;
				
				// Structural unit of waste.
				If Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.DisposalsStructuralUnit)) Then
					If ValueIsFilled(Object.StructuralUnit.DisposalsRecipient) Then
						Object.DisposalsStructuralUnit = Object.StructuralUnit.DisposalsRecipient;
						Object.DisposalsCell = Object.StructuralUnit.DisposalsRecipientCell;
					Else
						Object.DisposalsStructuralUnit = Object.StructuralUnit;
					EndIf;
				EndIf;
				
			EndIf;
			
			If DocumentMetadata.Name = "InventoryTransfer" Then
				
				// Structural unit.
				SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainWarehouse");
				If Not (FillingValues <> Undefined AND FillingValues.Property("StructuralUnit") AND ValueIsFilled(FillingValues.StructuralUnit))
					AND Not (ValueIsFilled(BasisParameter) 
					AND ValueIsFilled(Object.StructuralUnit)) Then
					If ValueIsFilled(SettingValue) 
						AND StructuralUnitTypeToChoiceParameters("StructuralUnit", DocumentMetadata, SettingValue) Then
						If Object.StructuralUnit <> SettingValue Then
							Object.StructuralUnit = SettingValue;
						EndIf;
					Else
						Object.StructuralUnit = CommonUseClientServer.PredefinedItem("Catalog.StructuralUnits.MainWarehouse");
					EndIf;
				EndIf;
				
				// Structural unit receiver.
				If Not (FillingValues <> Undefined AND FillingValues.Property("StructuralUnitPayee") AND ValueIsFilled(FillingValues.StructuralUnitPayee))
					AND Not (ValueIsFilled(BasisParameter) 
					AND ValueIsFilled(Object.StructuralUnitPayee)) Then
					If ValueIsFilled(Object.StructuralUnit.TransferRecipient) Then
						Object.StructuralUnitPayee = Object.StructuralUnit.TransferRecipient;
						Object.CellPayee = Object.StructuralUnit.TransferRecipientCell;
					EndIf;
				EndIf;
				
			EndIf;
			
			If DocumentMetadata.Name = "ProductionOrder" Then
				
				// Structural unit.
				SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainDepartment");
				If Not (ValueIsFilled(BasisParameter) 
					AND ValueIsFilled(Object.StructuralUnit))
					AND Not (FillingValues <> Undefined AND FillingValues.Property("StructuralUnit") AND ValueIsFilled(FillingValues.StructuralUnit)) Then
					If ValueIsFilled(SettingValue) 
						AND StructuralUnitTypeToChoiceParameters("StructuralUnit", DocumentMetadata, SettingValue) Then
						If Object.StructuralUnit <> SettingValue Then
							Object.StructuralUnit = SettingValue;
						EndIf;
					Else
						Object.StructuralUnit = Catalogs.StructuralUnits.MainDepartment;	
					EndIf;
				EndIf;
				
				// Structural unit of reserve.
				If Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.StructuralUnitReserve)) Then
					If ValueIsFilled(Object.StructuralUnit.TransferSource) Then
						Object.StructuralUnitReserve = Object.StructuralUnit.TransferSource;
					EndIf;
				EndIf;
				
			EndIf;
			
			If IsDocumentAttribute("Responsible", DocumentMetadata)
				AND Not (FillingValues <> Undefined AND FillingValues.Property("Responsible") AND ValueIsFilled(FillingValues.Responsible))
				AND Not ValueIsFilled(Object.Responsible) Then
				Object.Responsible = SmallBusinessReUse.GetValueByDefaultUser(User, "MainResponsible");
			EndIf;
			
			If IsDocumentAttribute("PriceKind", DocumentMetadata)
			   AND DocumentMetadata.Name <> "RetailReport"
			   AND DocumentMetadata.Name <> "ReceiptCR"
			   AND DocumentMetadata.Name <> "ReceiptCRReturn" 
			   AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.PriceKind)) Then
				SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "MainPriceKindSales");
				If ValueIsFilled(SettingValue) Then
					If Object.PriceKind <> SettingValue Then
						Object.PriceKind = SettingValue;
					EndIf;
				Else
					Object.PriceKind = Catalogs.PriceKinds.Wholesale;
				EndIf;
			EndIf;
			
			If IsDocumentAttribute("PriceKind", DocumentMetadata)
			   AND ValueIsFilled(Object.PriceKind) 
			   AND Not ValueIsFilled(BasisParameter) Then
				If IsDocumentAttribute("AmountIncludesVAT", DocumentMetadata) Then
					Object.AmountIncludesVAT = Object.PriceKind.PriceIncludesVAT;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "ProductionOrder" Then
				If IsDocumentAttribute("OrderState", DocumentMetadata) 
					AND Not (FillingValues <> Undefined AND FillingValues.Property("OrderState") AND ValueIsFilled(FillingValues.OrderState))
					AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.OrderState)) Then
					If Constants.UseProductionOrderStates.Get() Then
						SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "StatusOfNewProductionOrder");
						If ValueIsFilled(SettingValue) Then
							If Object.OrderState <> SettingValue Then
								Object.OrderState = SettingValue;
							EndIf;
						Else
							Object.OrderState = Catalogs.ProductionOrderStates.Open;
						EndIf;
					Else
						Object.OrderState = Constants.ProductionOrdersInProgressStatus.Get();
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "PurchaseOrder" Then
				If IsDocumentAttribute("OrderState", DocumentMetadata) 
					AND Not (FillingValues <> Undefined AND FillingValues.Property("OrderState") AND ValueIsFilled(FillingValues.OrderState))
					AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.OrderState)) Then
					If Constants.UsePurchaseOrderStates.Get() Then
						SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "StatusOfNewPurchaseOrder");
						If ValueIsFilled(SettingValue) Then
							If Object.OrderState <> SettingValue Then
								Object.OrderState = SettingValue;
							EndIf;
						Else
							Object.OrderState = Catalogs.PurchaseOrderStates.Open;
						EndIf;
					Else
						Object.OrderState = Constants.PurchaseOrdersInProgressStatus.Get();
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "CustomerOrder" Then
				If IsDocumentAttribute("OrderState", DocumentMetadata) 
					AND Not (FillingValues <> Undefined AND FillingValues.Property("OrderState") AND ValueIsFilled(FillingValues.OrderState))
					AND Not (ValueIsFilled(BasisParameter) AND ValueIsFilled(Object.OrderState)) Then
					If Constants.UseCustomerOrderStates.Get() Then
						SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "StatusOfNewCustomerOrder");
						If ValueIsFilled(SettingValue) Then
							If Object.OrderState <> SettingValue Then
								Object.OrderState = SettingValue;
							EndIf;
						Else
							Object.OrderState = Catalogs.CustomerOrderStates.Open;
						EndIf;
					Else
						Object.OrderState = Constants.CustomerOrdersInProgressStatus.Get();
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "PurchaseOrder" Then
				If IsDocumentAttribute("ReceiptDatePosition", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "ReceiptDatePositionInPurchaseOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.ReceiptDatePosition <> SettingValue Then
							Object.ReceiptDatePosition = SettingValue;
						EndIf;
					Else
						Object.ReceiptDatePosition = Enums.AttributePositionOnForm.InHeader;	
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "CustomerOrder" AND Object.OperationKind = Enums.OperationKindsCustomerOrder.WorkOrder Then
				If IsDocumentAttribute("WorkKindPosition", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "WorkKindPositionInWorkOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.WorkKindPosition <> SettingValue Then
							Object.WorkKindPosition = SettingValue;
						EndIf;
					Else
						Object.WorkKindPosition = Enums.AttributePositionOnForm.InHeader;	
					EndIf;
				EndIf;
				If IsDocumentAttribute("UseProducts", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "UseProductsInWorkOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.UseProducts <> SettingValue Then
							Object.UseProducts = SettingValue;
						EndIf;
					Else
						Object.UseProducts = True;	
					EndIf;
				EndIf;
				If IsDocumentAttribute("UseEnterpriseResources", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "UseEnterpriseResourcesInWorkOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.UseEnterpriseResources <> SettingValue Then
							Object.UseEnterpriseResources = SettingValue;
						EndIf;
					Else
						Object.UseEnterpriseResources = True;
					EndIf;
				EndIf;
				If IsDocumentAttribute("UseConsumerMaterials", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "UseConsumerMaterialsInWorkOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.UseConsumerMaterials <> SettingValue Then
							Object.UseConsumerMaterials = SettingValue;
						EndIf;
					Else
						Object.UseConsumerMaterials = True;	
					EndIf;
				EndIf;
				If IsDocumentAttribute("UseMaterials", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "UseMaterialsInWorkOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.UseMaterials <> SettingValue Then
							Object.UseMaterials = SettingValue;
						EndIf;
					Else
						Object.UseMaterials = True;	
					EndIf;
				EndIf;
				If IsDocumentAttribute("UsePerformerSalaries", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "UsePerformerSalariesInWorkOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.UsePerformerSalaries <> SettingValue Then
							Object.UsePerformerSalaries = SettingValue;
						EndIf;
					Else
						Object.UsePerformerSalaries = True;	
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "WorkOrder" Then
				If IsDocumentAttribute("WorkKindPosition", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "WorkKindPositionInWorkTask");
					If ValueIsFilled(SettingValue) Then
						If Object.WorkKindPosition <> SettingValue Then
							Object.WorkKindPosition = SettingValue;
						EndIf;
					Else
						Object.WorkKindPosition = Enums.AttributePositionOnForm.InHeader;	
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "CustomerOrder" AND Object.OperationKind <> Enums.OperationKindsCustomerOrder.WorkOrder Then
				If IsDocumentAttribute("ShipmentDatePosition", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "ShipmentDatePositionInCustomerOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.ShipmentDatePosition <> SettingValue Then
							Object.ShipmentDatePosition = SettingValue;
						EndIf;
					Else
						Object.ShipmentDatePosition = Enums.AttributePositionOnForm.InHeader;	
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "AcceptanceCertificate"
				OR DocumentMetadata.Name = "CustomerInvoice" Then
				If IsDocumentAttribute("CustomerOrderPosition", DocumentMetadata)
					
					AND Not (FillingValues <> Undefined
					AND FillingValues.Property("CustomerOrderPosition")
					AND ValueIsFilled(FillingValues.CustomerOrderPosition))
					
					AND Not (ValueIsFilled(BasisParameter)
					AND ValueIsFilled(Object.CustomerOrderPosition)
					AND Object.CustomerOrderPosition = Enums.AttributePositionOnForm.InTabularSection) Then
					
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "CustomerOrderPositionInShipmentDocuments");
					If ValueIsFilled(SettingValue) Then
						If Object.CustomerOrderPosition <> SettingValue Then
							Object.CustomerOrderPosition = SettingValue;
						EndIf;
					Else
						Object.CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader;
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "SupplierInvoice" Then
				If IsDocumentAttribute("PurchaseOrderPosition", DocumentMetadata)
					
					AND Not (FillingValues <> Undefined
					AND FillingValues.Property("PurchaseOrderPosition")
					AND ValueIsFilled(FillingValues.PurchaseOrderPosition))
					
					AND Not (ValueIsFilled(BasisParameter) 
					AND ValueIsFilled(Object.PurchaseOrderPosition)
					AND Object.PurchaseOrderPosition = Enums.AttributePositionOnForm.InTabularSection) Then
					
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "PurchaseOrderPositionInReceiptDocuments");
					If ValueIsFilled(SettingValue) Then
						If Object.PurchaseOrderPosition <> SettingValue Then
							Object.PurchaseOrderPosition = SettingValue;
						EndIf;
					Else
						Object.PurchaseOrderPosition = Enums.AttributePositionOnForm.InHeader;
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "InventoryTransfer" Then
				If IsDocumentAttribute("CustomerOrderPosition", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "CustomerOrderPositionInInventoryTransfer");
					If ValueIsFilled(SettingValue) Then
						If Object.CustomerOrderPosition <> SettingValue Then
							Object.CustomerOrderPosition = SettingValue;
						EndIf;
					Else
						Object.CustomerOrderPosition = Enums.AttributePositionOnForm.InHeader;
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentMetadata.Name = "ProductionOrder" Then
				If IsDocumentAttribute("UseEnterpriseResources", DocumentMetadata) Then 
					SettingValue = SmallBusinessReUse.GetValueByDefaultUser(User, "UseEnterpriseResourcesInProductionOrder");
					If ValueIsFilled(SettingValue) Then
						If Object.UseEnterpriseResources <> SettingValue Then
							Object.UseEnterpriseResources = SettingValue;
						EndIf;
					Else
						Object.UseEnterpriseResources = True;
					EndIf;
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure // FillDocumentHeader()

// Function returns predefined company.
//
Function GetPredefinedCompany() Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Companies.Ref AS Company
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Predefined";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Company;
	Else	
		Return Catalogs.Companies.EmptyRef();
	EndIf;	
	
EndFunction // GetPredefinedCompany()	

// The function returns a default specification for products and services, characteristics.
//
Function GetDefaultSpecification(ProductsAndServices, Characteristic = Undefined, WithTemplates = False) Export
	
	If Not AccessRight("Read", Metadata.Catalogs.Specifications) Or Not AccessRight("Read", Metadata.InformationRegisters.DefaultSpecifications) Then
		Return Catalogs.Specifications.EmptyRef();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ProductsAndServices", ProductsAndServices);
	Query.SetParameter("Characteristic", ?(Characteristic=Undefined, Catalogs.ProductsAndServicesCharacteristics.EmptyRef(), Characteristic));
	Query.SetParameter("WithTemplates", WithTemplates);
	Query.Text =
	"SELECT ALLOWED
	|	DefaultSpecifications.Specification AS Specification,
	|	0 AS Order
	|FROM
	|	InformationRegister.DefaultSpecifications AS DefaultSpecifications
	|WHERE
	|	DefaultSpecifications.ProductsAndServices = &ProductsAndServices
	|	AND DefaultSpecifications.Characteristic = &Characteristic
	|	AND DefaultSpecifications.Specification.Owner = DefaultSpecifications.ProductsAndServices
	|	AND DefaultSpecifications.Specification.ProductCharacteristic = DefaultSpecifications.Characteristic
	|	AND (&WithTemplates
	|			OR NOT DefaultSpecifications.Specification.IsTemplate)
	|
	|UNION ALL
	|
	|SELECT
	|	DefaultSpecifications.Specification,
	|	1
	|FROM
	|	InformationRegister.DefaultSpecifications AS DefaultSpecifications
	|WHERE
	|	DefaultSpecifications.ProductsAndServices = &ProductsAndServices
	|	AND DefaultSpecifications.Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|	AND DefaultSpecifications.Specification.Owner = DefaultSpecifications.ProductsAndServices
	|	AND DefaultSpecifications.Specification.ProductCharacteristic = DefaultSpecifications.Characteristic
	|	AND (&WithTemplates
	|			OR NOT DefaultSpecifications.Specification.IsTemplate)
	|
	|ORDER BY
	|	Order";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Specification;
	Else
		Return Catalogs.Specifications.EmptyRef();
	EndIf; 
	
EndFunction// GetDefaultSpecification()

// The function returns a value list with accessible for user companies, for use in list form
// Paramaters:
//   LegalEntityIndividual - Enum.CounterpartyKinds - if value is filling list is filtered
//
Function CompaniesChoiseList(LegalEntityIndividual = Undefined) Export 
	
	CompanyList = New ValueList;
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	Companies.Ref AS Ref
		|FROM
		|	Catalog.Companies AS Companies
		|	//%LegalEntityIndividual
		|ORDER BY
		|	Ref
		|AUTOORDER";
		
	If LegalEntityIndividual <> Undefined Then
		
		CaseText = "Where Companies.LegalEntityIndividual = &LegalEntityIndividual ";
		Query.Text = StrReplace(Query.Text, "//%LegalEntityIndividual", CaseText);
		Query.SetParameter("LegalEntityIndividual", LegalEntityIndividual); 
	
	EndIf; 
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Выбрать();
	While Selection.Next() Do
		CompanyList.Add(Selection.Ref);
	EndDo;
	
	Return CompanyList;
	
EndFunction

//////////////////////////////////////////////////////////////////////////////// 
// EXPORT PROCEDURES AND FUNCTIONS 

// Displays a message on filling error.
//
Procedure ShowMessageAboutError(ErrorObject, MessageText, TabularSectionName = Undefined, LineNumber = Undefined, Field = Undefined, Cancel = False) Export
	
	Message = New UserMessage();
	Message.Text = MessageText;
	
	If Not CommonUse.FileInfobase() Then
		
		// Platform 8.2.15
		
	Else
		
		If TabularSectionName <> Undefined Then
			Message.Field = TabularSectionName + "[" + (LineNumber - 1) + "]." + Field;
		ElsIf ValueIsFilled(Field) Then
			Message.Field = Field;
		EndIf;
		
		Message.SetData(ErrorObject);
		
	EndIf;
	
	Message.Message();
	
	Cancel = True;
	
EndProcedure // MessageAboutError()

// Allows to determine whether there is attribute
// with the passed name among the document header attributes.
//
// Parameters: 
//  AttributeName - desired attribute row
// name, DocumentMetadata - document metadata description object among attributes of which the search is executed.
//
// Returns:
//  True - if you find attribute with the same name, False - did not find.
//
Function IsDocumentAttribute(AttributeName, DocumentMetadata) Export

	Return Not (DocumentMetadata.Attributes.Find(AttributeName) = Undefined);

EndFunction // DocumentAttributeExist()

// Allows to determine whether there is attribute
// with the passed name among the document header attributes.
//
// Parameters: 
//  AttributeName - desired attribute row
// name, DocumentMetadata - document metadata description object among attributes of which the search is executed.
//
// Returns:
//  True - if you find attribute with the same name, False - did not find.
//
Function DocumentAttributeExistsOnLink(AttributeName, DocumentRef) Export

	DocumentMetadata = DocumentRef.Metadata();
	Return Not (DocumentMetadata.Attributes.Find(AttributeName) = Undefined);

EndFunction // DocumentAttributeExist()

// Checks whether structural unit meets selection
// parameters of attribute with the passed name.
//
// Parameters: 
//  AttributeName - desired attribute row
// name, DocumentMetadata - document metadata description object among attributes of which the search is executed.
//
// Returns:
//  True - if you find attribute with the same name, False - did not find.
//
Function StructuralUnitTypeToChoiceParameters(AttributeName, DocumentMetadata, SettingValue)

	ChoiceParameters = DocumentMetadata.Attributes[AttributeName].ChoiceParameters;
	StructuralUnitType = SettingValue.StructuralUnitType;
	For Each ChoiceParameter IN ChoiceParameters Do
		If ChoiceParameter.Name = "Filter.StructuralUnitType" Then
			If TypeOf(ChoiceParameter.Value) = Type("FixedArray") Then
				For Each ParameterValue IN ChoiceParameter.Value Do
					If StructuralUnitType = ParameterValue Then
						Return True;
					EndIf; 
				EndDo;
			ElsIf TypeOf(ChoiceParameter.Value) = Type("EnumRef.StructuralUnitsTypes") 
				AND StructuralUnitType = ChoiceParameter.Value Then
				Return True;
			EndIf; 
		EndIf; 
	EndDo;
	  
	Return False;	  

EndFunction 

// The procedure deletes a checked attribute from the array of checked attributes.
Procedure DeleteAttributeBeingChecked(CheckedAttributes, CheckedAttribute) Export
	
	FoundAttribute = CheckedAttributes.Find(CheckedAttribute);
	If ValueIsFilled(FoundAttribute) Then
		CheckedAttributes.Delete(FoundAttribute);
	EndIf;
	
EndProcedure // DeleteAttributeBeingChecked()

// Procedure creates a new key of links for tables.
//
// Parameters:
//  DocumentForm - ManagedForm, contains a
//                 document form whose attributes are processed by the procedure.
//
Function CreateNewLinkKey(DocumentForm) Export

	ValueList = New ValueList;
	
	TabularSection = DocumentForm.Object[DocumentForm.TabularSectionName];
	For Each TSRow IN TabularSection Do
        ValueList.Add(TSRow.ConnectionKey);
	EndDo;

    If ValueList.Count() = 0 Then
		ConnectionKey = 1;
	Else
		ValueList.SortByValue();
		ConnectionKey = ValueList.Get(ValueList.Count() - 1).Value + 1;
	EndIf;

	Return ConnectionKey;

EndFunction //  CreateNewLinkKey()

// Procedure writes user new setting.
//
Procedure SetUserSetting(SettingValue, SettingName, User = Undefined) Export
	
	If Not ValueIsFilled(User) Then
		
		User = Users.AuthorizedUser();
		
	EndIf;
	
	RecordSet = InformationRegisters.UserSettings.CreateRecordSet();

	RecordSet.Filter.User.Use	= True;
	RecordSet.Filter.User.Value		= User;
	RecordSet.Filter.Setting.Use		= True;
	RecordSet.Filter.Setting.Value			= ChartsOfCharacteristicTypes.UserSettings[SettingName];

	Record = RecordSet.Add();

	Record.User	= User;
	Record.Setting	= ChartsOfCharacteristicTypes.UserSettings[SettingName];
	Record.Value		= ChartsOfCharacteristicTypes.UserSettings[SettingName].ValueType.AdjustValue(SettingValue);
	
	RecordSet.Write();
	
	RefreshReusableValues();
	
EndProcedure // SetUserSetting()

// Function returns the related User employees for the passed record
//
// User - (Catalog.Users) User for whom a value table with records is received
//
Function GetUserEmployees(User = Undefined) Export
	
	If User = Undefined Then
		User = Users.CurrentUser();
	EndIf;
	
	Query = New Query("SELECT
	|	UserEmployees.Employee AS Employee
	|FROM
	|	InformationRegister.UserEmployees AS UserEmployees
	|WHERE
	|	UserEmployees.User = &User");
	Query.SetParameter("User", User);
	QueryResult = Query.Execute();
	
	UserEmployees = QueryResult.Unload().UnloadColumn("Employee");
	
	Return UserEmployees;
	
EndFunction // GetUserEmployees()

// Procedure sets conditional design.
//
Procedure MarkMainItemWithBold(SelectedItem, List, SettingName = "MainItem") Export
	
	ListOfItemsForDeletion = New ValueList;
	For Each ConditionalAppearanceItem IN List.SettingsComposer.Settings.ConditionalAppearance.Items Do
		If ConditionalAppearanceItem.UserSettingID = SettingName Then
			ListOfItemsForDeletion.Add(ConditionalAppearanceItem);
		EndIf;
	EndDo;
	For Each Item IN ListOfItemsForDeletion Do
		List.SettingsComposer.Settings.ConditionalAppearance.Items.Delete(Item.Value);
	EndDo;
	
	If Not ValueIsFilled(SelectedItem) Then
		Return;
	EndIf;
	
	ConditionalAppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	
	FilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	FilterItem.LeftValue = New DataCompositionField("Ref");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = SelectedItem;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Font", New Font(, , True));
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	ConditionalAppearanceItem.UserSettingID = SettingName;
	ConditionalAppearanceItem.Presentation = "Selection of main item";
	
EndProcedure

// Function receives greatest common denominator of two numbers.
//
Function GetGCD(a, b)
	
	Return ?(b = 0, a, GetGCD(b, a % b));
	
EndFunction // GetNOD()

// Function receives greatest common denominator for array.
//
Function GetGCDForArray(NumbersArray, Multiplicity) Export
	
	If NumbersArray.Count() = 0 Then
		Return 0;
	EndIf;
	
	GCD = NumbersArray[0] * Multiplicity;
	
	For Each Ct IN NumbersArray Do
		GCD = GetGCD(GCD, Ct * Multiplicity);
	EndDo;
	
	Return GCD;
	
EndFunction // GetGCDForArray()

// Function checks whether profile is set for user.
//
Function ProfileSetForUser(User = Undefined, ProfileId = "", Profile = Undefined) Export
	
	If User = Undefined Then
		User = Users.CurrentUser();
	EndIf;

	If Profile = Undefined Then
		Profile = Catalogs.AccessGroupsProfiles.GetRef(New UUID(ProfileId));
	EndIf;
	
	Query = New Query;
	Query.SetParameter("User", User);
	Query.SetParameter("Profile", Profile);
	
	Query.Text =
	"SELECT
	|	AccessGroupsUsers.User
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroupsUsers
	|WHERE
	|	(NOT AccessGroupsUsers.Ref.DeletionMark)
	|	AND AccessGroupsUsers.User = &User
	|	AND (AccessGroupsUsers.Ref.Profile = &Profile
	|			OR AccessGroupsUsers.Ref.Profile = VALUE(Catalog.AccessGroupsProfiles.Administrator))";
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Result.Next() Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction // ProfileSetToUser()

// Function checks users’ administrative rights
//
//
Function InfobaseUserWithFullAccess(User = Undefined,
                                    CheckSystemAdministrationRights = False,
                                    ForPrivilegedMode = True) Export
	// Used as replacement:
	// SmallBusinessServer.ProfileSetForUser(, , PredefinedValue("Catalog.AccessGroupsProfiles.Administrator"))
	
	Return Users.InfobaseUserWithFullAccess(User, CheckSystemAdministrationRights, ForPrivilegedMode);
	
EndFunction //UserWithFullAccess()

// Procedure adds structure values to the values list
//
// ValueList - values list to which structure values will be added;
// StructureWithValues - structure values of which will be added to the values list;
// AddDuplicates - check box that adjusts adding 
//
Procedure StructureValuesToValuesList(ValueList, StructureWithValues, AddDuplicates = False) Export
	
	For Each StructureItem IN StructureWithValues Do
		
		If Not ValueIsFilled(StructureItem.Value) OR 
			(NOT AddDuplicates AND Not ValueList.FindByValue(StructureItem.Value) = Undefined) Then
			
			Continue;
			
		EndIf;
		
		ValueList.Add(StructureItem.Value, StructureItem.Key);
		
	EndDo;
	
EndProcedure // StructureValuesToValuesList()

// Receives contact persons of a counterparty by the counterparty
//
Function GetCounterpartyContactPersons(Counterparty) Export
	
	ContactPersonsList = New ValueList;
	
	Query = New Query("SELECT * FROM Catalog.ContactPersons AS ContactPersons WHERE ContactPersons.Owner = &Counterparty");
	Query.SetParameter("Counterparty", Counterparty);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ContactPersonsList.Add(Selection.Ref);
		
	EndDo;
	
	Return ContactPersonsList;
	
EndFunction // GetContactPersonsOfCounterparty()

// Subscription to events during document copying.
//
Procedure OnCopyObject(Source) Export
	
	If Not IsBlankString(Source.Comment) Then
		Source.Comment = "";
	EndIf;
	
EndProcedure // OnCopyObject()

// Receives TS row presentation for display in the Content field.
//
Function GetContentText(ProductsAndServices, Characteristic = Undefined) Export
	
	ContentTemplate = SmallBusinessServer.GetProductsAndServicesPresentationForPrinting(
						?(ValueIsFilled(ProductsAndServices.DescriptionFull), ProductsAndServices.DescriptionFull, ProductsAndServices.Description),
						Characteristic, ProductsAndServices.SKU);
	
	Return ContentTemplate;
	
EndFunction // GetDataContentSelectionStart()

// Function - Reference to binary file data.
//
// Parameters:
//  AttachedFile - CatalogRef - reference to catalog with name "*AttachedFiles".
//  FormID - UUID - Form ID, which is used in the preparation of binary file data.
// 
// Returned value:
//   - String - address in temporary storage; 
//   - Undefined, if you can not get the data.
//
Function ReferenceToBinaryFileData(AttachedFile, FormID) Export
	
	SetPrivilegedMode(True);
	Try
		Return AttachedFiles.GetFileData(AttachedFile, FormID).FileBinaryDataRef;
	Except
		Return Undefined;
	EndTry;
	
EndFunction // ReferenceToBinaryFileData()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS

// Function receives table from the temporary table.
//
Function TableFromTemporaryTable(TempTablesManager, Table) Export
	
	Query = New Query(
	"SELECT *
	|	FROM " + Table + " AS Table");
	Query.TempTablesManager = TempTablesManager;
	
	Return Query.Execute().Unload();
	
EndFunction // TableFromTemporaryTable()

// Function dependinding on the accounting flag
// by the company of company-organization or document organization.
//
// Parameters:
// Company - CatalogRef.Companies.
//
// Returns:
//  CatalogRef.Company - ref to the company.
//
Function GetCompany(Company) Export
	
	Return ?(Constants.AccountingBySubsidiaryCompany.Get(), Constants.SubsidiaryCompany.Get(), Company);
	
EndFunction // GetCompany()

// The procedure defines the following: if when editing
// a document date, the document numbering period changes,
// the document is assigned a new unique number.
//
// Parameters:
//  DocumentRef - ref to a document from
// which procedure DocumentNewDate is called - new date of
// the DocumentInitialDate document - initial document date 
//
// Returns:
//  Number - dates difference.
//
Function CheckDocumentNumber(DocumentRef, NewDocumentDate, InitialDateOfDocument) Export
	
	// Define number change periodicity assigned for the current documents kind
	NumberChangePeriod = DocumentRef.Metadata().NumberPeriodicity;
	
	//Depending on the set numbers change
	//periodicity define the difference of an old and a new document version dates.
	If NumberChangePeriod = Metadata.ObjectProperties.DocumentNumberPeriodicity.Year Then
		DATEDIFF = BegOfYear(InitialDateOfDocument) - BegOfYear(NewDocumentDate);
	ElsIf NumberChangePeriod = Metadata.ObjectProperties.DocumentNumberPeriodicity.Quarter Then
		DATEDIFF = BegOfQuarter(InitialDateOfDocument) - BegOfQuarter(NewDocumentDate);
	ElsIf NumberChangePeriod = Metadata.ObjectProperties.DocumentNumberPeriodicity.Month Then
		DATEDIFF = BegOfMonth(InitialDateOfDocument) - BegOfMonth(NewDocumentDate);
	ElsIf NumberChangePeriod = Metadata.ObjectProperties.DocumentNumberPeriodicity.Day Then
		DATEDIFF = InitialDateOfDocument - NewDocumentDate;
	Else
		Return 0;
	EndIf;
	
	Return DATEDIFF;
	
EndFunction // CheckDocumentNumber()

// Function defines product sale taxation type with VAT.
//
// Parameters:
// Company - CatalogRef.Companies - Company for which Warehouse
// taxation system is defined. - CatalogRef.Warehouses - Retail warehouse for which
// Date taxation system is defined - Date of taxation system definition
//
Function VATTaxation(Company, Warehouse = Undefined, Date) Export
	
	Query = New Query;
	
	If ValueIsFilled(Date) Then
		Query.SetParameter("Date",Date);
	Else
		Query.SetParameter("Date", CurrentDate());
	EndIf;
	
	Query.SetParameter("Company", Company);
	Query.SetParameter("Warehouse", Warehouse);
	
	Query.Text = 
	"SELECT
	|	VALUE(Enum.VATTaxationTypes.NotTaxableByVAT) AS VATTaxation
	|FROM
	|	InformationRegister.CompaniesTaxationSystems.SliceLast(&Date, Company = &Company) AS Taxation
	|WHERE
	|	Taxation.TaxationSystem = VALUE(Enum.TaxationSystems.Simplified)";
	
	VATTaxation = Enums.VATTaxationTypes.TaxableByVAT;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		VATTaxation = Selection.VATTaxation;
	EndIf;
	
	Return VATTaxation;
	
EndFunction // VATTaxation()

////////////////////////////////////////////////////////////////////////////////
// Information panel

// Receives required data for output to the list information panel.
//
Function InfoPanelGetData(CICurrentAttribute, InfPanelParameters) Export
	
	CIFieldList = "";
	QueryText = "";
	
	Query = New Query;
	QueryOrder = 0;
	If InfPanelParameters.Property("Counterparty") Then
		
		CIFieldList = "Phone,E_mail,Fax,RealAddress,LegAddress,MailAddress,ShippingAddress,OtherInformation";
		GenerateQueryTextCounterpartiesInfoPanel(QueryText);
		
		QueryOrder = QueryOrder + 1;
		InfPanelParameters.Counterparty = QueryOrder;
		
		Query.SetParameter("Counterparty", CICurrentAttribute);
		
		If InfPanelParameters.Property("MutualSettlements") Then
			
			CIFieldList = CIFieldList + ",Debt,OurDebt";
			GenerateQueryTextMutualSettlementsInfoPanel(QueryText);
			
			QueryOrder = QueryOrder + 1;
			InfPanelParameters.MutualSettlements = QueryOrder;
			
			MutualSettlementsParameters = InformationPanelGetParametersOfMutualSettlements();
			Query.SetParameter("CompaniesList", MutualSettlementsParameters.CompaniesList);
			Query.SetParameter("ListTypesOfCalculations", MutualSettlementsParameters.ListTypesOfCalculations);
			
		EndIf;
		
		If InfPanelParameters.Property("DiscountCard") Then
			CIFieldList = CIFieldList + ",DiscountPercentByDiscountCard,SalesAmountOnDiscountCard,PeriodPresentation";
		EndIf;
		
	EndIf;
	
	If InfPanelParameters.Property("ContactPerson") Then
		
		CIFieldList = ?(IsBlankString(CIFieldList), "CLPhone,ClEmail", CIFieldList + ",CLPhone,ClEmail");
		GenerateQueryTextContactsInfoPanel(QueryText);
		
		QueryOrder = QueryOrder + 1;
		InfPanelParameters.ContactPerson = QueryOrder;
		
		If TypeOf(CICurrentAttribute) = Type("CatalogRef.Counterparties") Then
			Query.SetParameter("ContactPerson", CommonUse.GetAttributeValue(CICurrentAttribute, "ContactPerson"));
		Else
			Query.SetParameter("ContactPerson", CICurrentAttribute);
		EndIf;
		
	EndIf;
	
	Query.Text = QueryText;
	
	IPData = New Structure(CIFieldList);
	
	Result = Query.ExecuteBatch();
	
	If InfPanelParameters.Property("Counterparty") Then
		
		CISelection = Result[InfPanelParameters.Counterparty - 1].Select();
		IPData = GetDataCounterpartyInfoPanel(CISelection, IPData);
		
		If InfPanelParameters.Property("MutualSettlements") Then
			
			DebtsSelection = Result[InfPanelParameters.MutualSettlements - 1].Select();
			IPData = GetFillDataSettlementsInfoPanel(DebtsSelection, IPData);
			
		EndIf;
		
		If InfPanelParameters.Property("DiscountCard") Then
			
			AdditionalParameters = New Structure("GetSalesAmount, Amount, PeriodPresentation", True, 0, "");
			DiscountPercentByDiscountCard = CalculateDiscountPercentByDiscountCard(CurrentDate(), InfPanelParameters.DiscountCard, AdditionalParameters);
			IPData = GetFillDataDiscountPercentByDiscountCardInfPanel(DiscountPercentByDiscountCard, AdditionalParameters.Amount, AdditionalParameters.PeriodPresentation, IPData);
			
		EndIf;
		
	EndIf;
	
	If InfPanelParameters.Property("ContactPerson") Then
		CISelection = Result[InfPanelParameters.ContactPerson - 1].Select();
		IPData = GetDataContactPersonInfoPanel(CISelection, IPData);
	EndIf;
	
	Return IPData;
	
EndFunction // InfoPanelGetData()

// Procedure generates query text by counterparty CI.
//
Procedure GenerateQueryTextCounterpartiesInfoPanel(QueryText)
	
	QueryText = QueryText +
	"SELECT
	|	CIKinds.Ref AS CIKind,
	|	ISNULL(CICounterparty.Presentation, """") AS CIPresentation
	|FROM
	|	Catalog.ContactInformationKinds AS CIKinds
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS CICounterparty
	|		ON (CICounterparty.Ref = &Counterparty)
	|			AND CIKinds.Ref = CICounterparty.Kind
	|WHERE
	|	CIKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogCounterparties)
	|	AND CIKinds.Predefined
	|
	|ORDER BY
	|	CICounterparty.LineNumber";
	
EndProcedure // GenerateQueryTextCounterpartiesInfPanel()

// Procedure generates query text by contact person CI.
//
Procedure GenerateQueryTextContactsInfoPanel(QueryText)
	
	If Not IsBlankString(QueryText) Then
		QueryText = QueryText +
		";
		|////////////////////////////////////////////////////////////////////////////////
		|";
	EndIf;
	
	QueryText = QueryText +
	"SELECT
	|	CIKinds.Ref AS CIKind,
	|	ISNULL(CIContactPersons.Presentation, """") AS CIPresentation
	|FROM
	|	Catalog.ContactInformationKinds AS CIKinds
	|		LEFT JOIN Catalog.ContactPersons.ContactInformation AS CIContactPersons
	|		ON (CIContactPersons.Ref = &ContactPerson)
	|			AND CIKinds.Ref = CIContactPersons.Kind
	|WHERE
	|	CIKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogContactPersons)
	|	AND CIKinds.Predefined";
	
EndProcedure // GenerateQueryTextContactPersonInfPanel()

// Procedure generates query text by the counterparty netting.
//
Procedure GenerateQueryTextMutualSettlementsInfoPanel(QueryText)
	
	QueryText = QueryText +
	";
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText +
	"SELECT
	|	CASE
	|		WHEN AccountsPayableBalances.AmountBalance < 0
	|				AND AccountsReceivableBalances.AmountBalance > 0
	|			THEN -1 * BankAccountsPayableBalances.AmountBalance + AccountsReceivableBalances.AmountBalance
	|		WHEN AccountsPayableBalances.AmountBalance < 0
	|			THEN -AccountsPayableBalances.AmountBalance
	|		WHEN AccountsReceivableBalances.AmountBalance > 0
	|			THEN AccountsReceivableBalances.AmountBalance
	|		ELSE 0
	|	END AS CounterpartyDebt,
	|	CASE
	|		WHEN AccountsPayableBalances.AmountBalance > 0
	|				AND AccountsReceivableBalances.AmountBalance < 0
	|			THEN -1 * BankAccountsReceivableBalances.AmountBalance + AccountsPayableBalances.AmountBalance
	|		WHEN AccountsPayableBalances.AmountBalance > 0
	|			THEN AccountsPayableBalances.AmountBalance
	|		WHEN AccountsReceivableBalances.AmountBalance < 0
	|			THEN -AccountsReceivableBalances.AmountBalance
	|		ELSE 0
	|	END AS OurDebt
	|FROM
	|	AccumulationRegister.AccountsPayable.Balance(
	|			,
	|			Company IN (&CompaniesList)
	|				AND SettlementsType IN (&ListTypesOfCalculations)
	|				AND Counterparty = &Counterparty) AS AccountsPayableBalances,
	|	AccumulationRegister.AccountsReceivable.Balance(
	|			,
	|			Company IN (&CompaniesList)
	|				AND SettlementsType IN (&ListTypesOfCalculations)
	|				AND Counterparty = &Counterparty) AS AccountsReceivableBalances";
	
EndProcedure // GenerateQueryTextNettingInfPanel()

// Function returns required parameters for netting calculation in inf. panels.
//
Function InformationPanelGetParametersOfMutualSettlements()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Companies.Ref AS Company
	|FROM
	|	Catalog.Companies AS Companies";
	
	QueryResult = Query.Execute().Unload();
	CompaniesArray = QueryResult.UnloadColumn("Company");
	
	CalculationsTypesArray = New Array;
	CalculationsTypesArray.Add(Enums.SettlementsTypes.Advance);
	CalculationsTypesArray.Add(Enums.SettlementsTypes.Debt);
	
	Return New Structure("CompaniesList,CalculationsTypesList", CompaniesArray, CalculationsTypesArray);
	
EndFunction // InformationPanelGetNettingParameters()

// Receives required data about counterparty CI.
//
Function GetDataCounterpartyInfoPanel(CISelection, IPData)
	
	While CISelection.Next() Do
		
		CIPresentation = TrimAll(CISelection.CIPresentation);
		If CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.CounterpartyPhone") Then
			IPData.Phone = ?(IsBlankString(IPData.Phone), CIPresentation, IPData.Phone + ", "+ CIPresentation);
		ElsIf CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.CounterpartyEmail") Then
			IPData.E_mail = ?(IsBlankString(IPData.E_mail), CIPresentation, IPData.E_mail + ", "+ CIPresentation);
		ElsIf CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.CounterpartyFax") Then
			IPData.Fax = ?(IsBlankString(IPData.Fax), CIPresentation, IPData.Fax + ", "+ CIPresentation);
		ElsIf CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.CounterpartyActualAddress") Then
			IPData.RealAddress = ?(IsBlankString(IPData.RealAddress), CIPresentation, IPData.RealAddress + Chars.LF + CIPresentation);
		ElsIf CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.CounterpartyLegalAddress") Then
			IPData.LegAddress = ?(IsBlankString(IPData.LegAddress), CIPresentation, IPData.LegAddress + Chars.LF + CIPresentation);
		ElsIf CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.CounterpartyPostalAddress") Then
			IPData.MailAddress = ?(IsBlankString(IPData.MailAddress), CIPresentation, IPData.MailAddress + Chars.LF + CIPresentation);
		ElsIf CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.CounterpartyDeliveryAddress") Then
			IPData.ShippingAddress = ?(IsBlankString(IPData.ShippingAddress), CIPresentation, IPData.ShippingAddress + Chars.LF + CIPresentation);
		ElsIf CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.CounterpartyOtherInformation") Then
			IPData.OtherInformation = ?(IsBlankString(IPData.OtherInformation), CIPresentation, IPData.OtherInformation + Chars.LF + CIPresentation);
		EndIf;
		
	EndDo;
	
	Return IPData;
	
EndFunction // GetDataCounterpartyInfoPanel()

// Receives required data about contact person CI.
//
Function GetDataContactPersonInfoPanel(CISelection, IPData)
	
	While CISelection.Next() Do
		
		CIPresentation = TrimAll(CISelection.CIPresentation);
		If CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.ContactPersonPhone") Then
			IPData.CLPhone = ?(IsBlankString(IPData.CLPhone), CIPresentation, IPData.CLPhone + ", "+ CIPresentation);
		ElsIf CISelection.CIKind = PredefinedValue("Catalog.ContactInformationKinds.ContactPersonEmail") Then
			IPData.ClEmail = ?(IsBlankString(IPData.ClEmail), CIPresentation, IPData.ClEmail + ", "+ CIPresentation);
		EndIf;
		
	EndDo;
	
	Return IPData;
	
EndFunction // GetDataContactPersonInfoPanel()

// Receives necessary data about counterparty netting.
//
Function GetFillDataSettlementsInfoPanel(DebtsSelection, IPData)
	
	DebtsSelection.Next();
	
	IPData.Debt = DebtsSelection.CounterpartyDebt;
	IPData.OurDebt = DebtsSelection.OurDebt;
	
	Return IPData;
	
EndFunction // GetFillDataNettingInfPanel()

// Receives required data on the discount percentage by a counterparty discount card.
//
Function GetFillDataDiscountPercentByDiscountCardInfPanel(DiscountPercentByDiscountCard, SalesAmountOnDiscountCard, PeriodPresentation, IPData)
	
	IPData.DiscountPercentByDiscountCard = DiscountPercentByDiscountCard;
	IPData.SalesAmountOnDiscountCard = SalesAmountOnDiscountCard;
	IPData.PeriodPresentation = PeriodPresentation;
		
	Return IPData;
	
EndFunction // GetFillDataNettingInfPanel()

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS FOR WORK WITH TULL TEXT SEARCH

// Function defines whether search index for the Counterparties catalog is relevant.
//
Function SearchIndexUpdateAutomatically() Export
	
	If FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable Then
		
		Return ((CurrentDate() - FullTextSearch.UpdateDate()) < 2*60*60);
		
	EndIf;
	
	Return False;
	
EndFunction // SearchIndexUpdateAutomatically()

// Function returns full text search result.
//
Function FindCounterpartiesFulltextSearch(Form) Export
	
	Form.Items.List.Representation = TableRepresentation.List;
	
	BasesTable = Form.FormAttributeToValue("Bases");
	
	// Get search results
	ErrorText = FindCounterparties(Form.FulltextSearchString, BasesTable);
	If ErrorText = Undefined Then
		
		UpdateChoiceList(Form.Items.FulltextSearchString.ChoiceList, Form.FulltextSearchString, 100);
		
		Save("FindHistoryOfCounterparties", Form.Items.FulltextSearchString.ChoiceList);
		
		// Return the basis table.
		Form.ValueToFormAttribute(BasesTable, "Bases");
		
		// Set filter by found counterparties list
		CommonUseClientServer.SetFilterItem(
			Form.List.Filter,
			"Search",
			BasesTable.UnloadColumn("Counterparty"),
			DataCompositionComparisonType.InList,, True
		);
		
		Form.Items.FulltextSearchString.BackColor = StyleColors.FieldBackColor;
		Return Undefined;
		
	EndIf;
	
	CommonUseClientServer.SetFilterItem(
		Form.List.Filter,
		"Search",
		Catalogs.Counterparties.EmptyRef(),
		DataCompositionComparisonType.Equal,, True
	);
	
	Form.Items.FulltextSearchString.BackColor = StyleColors.EventRefusal;
	
	Return ErrorText;
	
EndFunction // FindCounterpartiesFulltextSearch()

// Executes advanced counterparties search.
//
Function FindCounterparties(SearchString, CounterpartiesList)
	
	// Customize search parameters
	SearchArea = New Array;
	PortionSize = 100;
	SearchStringExtended = ?(IsBlankString(SearchString), SearchString, SearchString + "*");
	SearchList = FullTextSearch.CreateList(SearchStringExtended, PortionSize);
	SearchArea.Add(Metadata.Catalogs.Counterparties);
	SearchArea.Add(Metadata.Catalogs.ContactPersons);
	SearchArea.Add(Metadata.Catalogs.Individuals);
	SearchArea.Add(Metadata.Catalogs.CounterpartyContracts);
	SearchArea.Add(Metadata.Catalogs.BankAccounts);
	SearchList.SearchArea = SearchArea;
	
	SearchList.FirstPart();
	
	// Return if search is not effective.
	If SearchList.TooManyResults() Then
		Return NStr("en='Too many results. Refine your search criteria.';ru='Слишком много результатов, уточните запрос.';vi='Có rất nhiều kết quả, hãy làm rõ truy vấn.'");
	EndIf;

	If SearchList.TotalCount() = 0 Then
		Return NStr("en='No results found';ru='Ничего не найдено';vi='Không tìm thấy gì '");
	EndIf;
	
	ItemCount = SearchList.TotalCount();
	
	//generate found counterparties list.
	CounterpartiesList.Clear();
	StartPosition = 0;
	EndPosition = ?(ItemCount > PortionSize, PortionSize, ItemCount) - 1;
	IsNextPortion = True;
	
	//Process DRR results by portions
	While IsNextPortion Do
		
		For CountElements = 0 To EndPosition Do
			
			// Generate result item
			Item = SearchList.Get(CountElements);
			ItemRef = Item.Value.Ref;
			Basis = Item.Metadata.ObjectPresentation + " """ +
			Item.Presentation + """ - " + Item.Description;
			
			// Counterparties
			If Item.Metadata = Metadata.Catalogs.Counterparties Then
				
				Counterparty = Item.Value;
				Basis = NStr("en='Found: Counterparty - ';ru='Найдено: Контрагент - ';vi='Tìm thấy: Đối tác -'") + Item.Description;
				
			// Contact persons
			ElsIf Item.Metadata = Metadata.Catalogs.ContactPersons Then
				
				Counterparty = Item.Value.Owner;
				BasisTemplate = NStr("en='Found: Contact person ""%1"" - %2';ru='Найдено: Контактное лицо ""%1"" - %2';vi='Tìm thấy: Người liên hệ ""%1"" - %2'");
				Basis = StringFunctionsClientServer.SubstituteParametersInString(BasisTemplate, Item.Value, Item.Description);
				
			// Individuals
			ElsIf Item.Metadata = Metadata.Catalogs.Individuals Then
				
				FoundCounterpartiesTable = GetCounterpartiesByIndividual(Item.Value);
				If FoundCounterpartiesTable <> Undefined Then
					
					For Each TableRow IN FoundCounterpartiesTable Do
						BasisTemplate = NStr("en='Found: The ""%1"" individual of the ""%2"" contact person - %3';ru='Найдено: Физическое лицо ""%1"" контактного лица ""%2"" - %3';vi='Đã tìm thấy: Người liên hệ ""%1"" của người liên hệ ""%2"" - %3'");
						Basis = StringFunctionsClientServer.SubstituteParametersInString(BasisTemplate, Item.Value, TableRow.Presentation, Item.Description);
						If Not AddCounterpartyToListOfFoundByFulltextSearch(CounterpartiesList, TableRow.Counterparty, Basis, ItemRef) Then
							Return NStr("en='Too many results. Refine your search criteria.';ru='Слишком много результатов, уточните запрос.';vi='Có rất nhiều kết quả, hãy làm rõ truy vấn.'");
						EndIf;
					EndDo;
					
				EndIf;
				
			// Contracts
			ElsIf Item.Metadata = Metadata.Catalogs.CounterpartyContracts Then
				
				Counterparty = Item.Value.Owner;
				BasisTemplate =  NStr("en='Found: Contract ""%1"" - %2';ru='Найдено: Договор ""%1"" - %2';vi='Tìm thấy: Hợp đồng ""%1"" - %2'");
				Basis = StringFunctionsClientServer.SubstituteParametersInString(BasisTemplate, Item.Value, Item.Description);
				
			// Bank accounts
			ElsIf Item.Metadata = Metadata.Catalogs.BankAccounts Then
				
				Counterparty = Item.Value.Owner;
				BasisTemplate =  NStr("en='Found: Bank account ""%1"" - %2';ru='Найдено: Банковский счет ""%1"" - %2';vi='Tìm thấy: Tài khoản ngân hàng ""%1"" - %2'");
				Basis = StringFunctionsClientServer.SubstituteParametersInString(BasisTemplate, Item.Value, Item.Description);
				
			ElsIf Not ValueIsFilled(Item.Value.Counterparty) Then
				
				Continue;
				Counterparty = Item.Value.Counterparty;
				
			EndIf;
			
			If Not Item.Metadata = Metadata.Catalogs.Individuals Then
				If Not AddCounterpartyToListOfFoundByFulltextSearch(CounterpartiesList, Counterparty, Basis, ItemRef) Then
					Return NStr("en='Too many results. Refine your search criteria.';ru='Слишком много результатов, уточните запрос.';vi='Có rất nhiều kết quả, hãy làm rõ truy vấn.'");
				EndIf;
			EndIf;
			
		EndDo;
		
		StartPosition = StartPosition + PortionSize;
		IsNextPortion = (StartPosition < ItemCount - 1);
		If IsNextPortion Then
			EndPosition = 
			?(ItemCount > StartPosition + PortionSize, PortionSize,
			ItemCount - StartPosition) - 1;
			SearchList.NextPart();
		EndIf;
	EndDo;
	
	If CounterpartiesList.Count() = 0 Then
		Return NStr("en='No results found';ru='Ничего не найдено';vi='Không tìm thấy gì '");
	EndIf;
	
	Return Undefined;
	
EndFunction // FindCounterparties()

// Receives an array of counterparties by an individual;
// the array contains counterparties for which an individual is specified as a contact
// person and all counterparties for which an individual is specified as a counterparty.
//
// Parameters
// Ind - Catalog.Individuals - individual for which search is executed
//
// Returns:
// Array - array of counterparties found by individual.
//
Function GetCounterpartiesByIndividual(Ind)
	
	If Not ValueIsFilled(Ind) Then
		Return New Array;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	ContactPersons.Owner AS Counterparty,
	|	ContactPersons.Ref,
	|	ContactPersons.Presentation
	|FROM
	|	Catalog.ContactPersons AS ContactPersons
	|WHERE
	|	ContactPersons.Ind = &Ind";
	
	Query.SetParameter("Ind",Ind);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Return Result.Unload();
	
EndFunction // GetCounterpartyByIndividual()

// The function adds counterparties found by full-text search to the list.
//
Function AddCounterpartyToListOfFoundByFulltextSearch(CounterpartiesList, Counterparty, Basis, ItemRef)
	
	// Add item if there is no counterparty in the list of found ones yet.
	FoundString = CounterpartiesList.Find(Counterparty, "Counterparty");
	If FoundString = Undefined Then
		
		//Limit return counterparties quantity
		If CounterpartiesList.Count() > 100 Then
			Return False;
		Else 
			Record = CounterpartiesList.Add();
			Record.Counterparty = Counterparty;
			Record.Basis = Basis;
			Record.Ref = ItemRef;
		EndIf;
		
	Else
		
		If (TypeOf(FoundString.Ref) = Type("CatalogRef.ContactPersons")
			OR TypeOf(FoundString.Ref) = Type("CatalogRef.Individuals")
			OR TypeOf(FoundString.Ref) = Type("CatalogRef.CounterpartyContracts")
			OR TypeOf(FoundString.Ref) = Type("CatalogRef.BankAccounts"))
			AND TypeOf(ItemRef) = Type("CatalogRef.Counterparties") Then
		
			FoundString.Counterparty = Counterparty;
			FoundString.Basis = Basis;
			FoundString.Ref = ItemRef;
		
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction // AddCounterpartyToFoundByFulltextSearchList()

// Updates fulltext search index.
//
Procedure RefreshFullTextSearchIndex() Export
	
	SetPrivilegedMode(True);
	FullTextSearch.UpdateIndex();
	
EndProcedure // UpdatehFullTextSearchIndex()

// Procedure imports counterparties search history.
//
Procedure Import(SettingName, ChoiceList) Export
	
	FindHistory = CommonUse.CommonSettingsStorageImport(SettingName,);
	If FindHistory <> Undefined Then
		ChoiceList.LoadValues(FindHistory);
	EndIf;
	
EndProcedure // Import()

// Procedure saves counterparties search history.
//
Procedure Save(SettingName, ChoiceList)
	
	CommonUse.CommonSettingsStorageSave(SettingName, , ChoiceList.UnloadValues());
	
EndProcedure // Save()

// Procedure updates search selection list.
//
Procedure UpdateChoiceList(ChoiceList, SearchString, ChoiceListSize = 1000)
	
	// Delete item from search history if any
	FoundListItemNumber = ChoiceList.FindByValue(SearchString);
	While FoundListItemNumber <> Undefined Do
		ChoiceList.Delete(FoundListItemNumber);
		FoundListItemNumber = ChoiceList.FindByValue(SearchString);
	EndDo;
	
	// And put it in the first place
	ChoiceList.Insert(0, SearchString);
	While ChoiceList.Count() > ChoiceListSize Do
		ChoiceList.Delete(ChoiceList.Count() - 1);
	EndDo;
	
EndProcedure // RefreshChoiceList()

////////////////////////////////////////////////////////////////////////////////
// POSTING MANAGEMENT

// Initializes additional properties to post a document.
//
Procedure InitializeAdditionalPropertiesForPosting(DocumentRef, StructureAdditionalProperties) Export
	
	// IN the "AdditionalProperties" structure, properties are created with the "TablesForMovements" "ForPosting" "AccountingPolicy" keys.
	
	// "TablesForMovements" - structure that will contain values table with data for movings execution.
	StructureAdditionalProperties.Insert("TableForRegisterRecords", New Structure);
	
	// "ForPosting" - structure that contains the document properties and attributes required for posting.
	StructureAdditionalProperties.Insert("ForPosting", New Structure);
	
	// Structure containing the key with the "TemporaryTablesManager" name in which value temporary tables manager is stored.
	// Contains key for each temporary table (temporary table name) and value (shows that there are records in the temporary table).
	StructureAdditionalProperties.ForPosting.Insert("StructureTemporaryTables", New Structure("TempTablesManager", New TempTablesManager));
	StructureAdditionalProperties.ForPosting.Insert("DocumentMetadata", DocumentRef.Metadata());
	
	// "AccountingPolicy" - structure that contains all values of the
	// accounting policy parameters for the document time and by the organization selected in the document or by a company (if accounts are kept by a company).
	StructureAdditionalProperties.Insert("AccountingPolicy", New Structure);
	
	// Query that receives document data.
	Query = New Query(
	"SELECT
	|	_Document_.Ref AS Ref,
	|	_Document_.Number AS Number,
	|	_Document_.Date AS Date,
	|   " + ?(StructureAdditionalProperties.ForPosting.DocumentMetadata.Attributes.Find("Company") <> Undefined, "_Document_.Company" , "VALUE(Catalog.Companies.EmptyRef)") + " AS Company,
	|	_Document_.PointInTime AS PointInTime,
	|	_Document_.Presentation AS Presentation
	|FROM
	|	Document." + StructureAdditionalProperties.ForPosting.DocumentMetadata.Name + " AS
	|_Document_
	|	WHERE _Document_.Ref = &DocumentRef");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	QueryResult = Query.Execute();
	
	// Generate keys containing document data.
	For Each Column IN QueryResult.Columns Do
		
		StructureAdditionalProperties.ForPosting.Insert(Column.Name);
		
	EndDo;
	
	QueryResultSelection = QueryResult.Select();
	QueryResultSelection.Next();
	
	// Fill in values for keys containing document data.
	FillPropertyValues(StructureAdditionalProperties.ForPosting, QueryResultSelection);
	
	// Define and set point value for which document control should be executed.
	StructureAdditionalProperties.ForPosting.Insert("ControlTime", Date('00010101'));
	StructureAdditionalProperties.ForPosting.Insert("ControlPeriod", Date("39991231"));
		
	// Company setting in case of entering accounting by the company.
	StructureAdditionalProperties.ForPosting.Company = SmallBusinessServer.GetCompany(StructureAdditionalProperties.ForPosting.Company);
	
	// Query receiving accounting policy data.
	Query = New Query(
	"SELECT
	|	Constants.FunctionalOptionAccountingByProjects AS ProjectManagement,
	|	Constants.FunctionalOptionAccountingByCells AS AccountingByCells,
	|	Constants.FunctionalOptionAccountingCashMethodIncomeAndExpenses AS IncomeAndExpensesAccountingCashMethod,
	|	Constants.FunctionalOptionUseBatches AS UseBatches,
	|	Constants.FunctionalOptionUseCharacteristics AS UseCharacteristics,
	|	Constants.FunctionalOptionUseTechOperations AS UseTechOperations,
	|	Constants.UseSerialNumbers AS UseSerialNumbers,
	|	&UseProductionStages AS UseProductionStages,
	|	Constants.FunctionalOptionAccountingCCD AS AccountingCCD,
	|	Constants.SerialNumbersBalanceControl AS SerialNumbersBalance
	|FROM
	|	Constants AS Constants");
	
	Query.SetParameter("UseProductionStages", UseProductionStages());
	QueryResult = Query.Execute();
	
	// Generate keys containing accounting policy data.
	For Each Column IN QueryResult.Columns Do
		
		StructureAdditionalProperties.AccountingPolicy.Insert(Column.Name);
		
	EndDo;
	
	QueryResultSelection = QueryResult.Select();
	QueryResultSelection.Next();
	
	// Fill out values of the keys that contain the accounting policy data.
	FillPropertyValues(StructureAdditionalProperties.AccountingPolicy, QueryResultSelection);
	
EndProcedure // InitializeAdditionalPropertiesForPosting()

// Generates register names array on which there are document movements.
//
Function GetNamesArrayOfUsedRegisters(Recorder, DocumentMetadata)
	
	RegisterArray = New Array;
	QueryText = "";
	TableCounter = 0;
	DoCounter = 0;
	RegistersTotalAmount = DocumentMetadata.RegisterRecords.Count();
	
	For Each RegisterRecord in DocumentMetadata.RegisterRecords Do
		
		If TableCounter > 0 Then
			
			QueryText = QueryText + "
			|UNION ALL
			|";
			
		EndIf;
		
		TableCounter = TableCounter + 1;
		DoCounter = DoCounter + 1;
		
		QueryText = QueryText + 
		"SELECT TOP 1
		|""" + RegisterRecord.Name + """ AS RegisterName
		|
		|FROM " + RegisterRecord.FullName() + "
		|
		|WHERE Recorder = &Recorder
		|";
		
		If TableCounter = 256 OR DoCounter = RegistersTotalAmount Then
			
			Query = New Query(QueryText);
			Query.SetParameter("Recorder", Recorder);
			
			QueryText  = "";
			TableCounter = 0;
			
			If RegisterArray.Count() = 0 Then
				
				RegisterArray = Query.Execute().Unload().UnloadColumn("RegisterName");
				
			Else
				
				Selection = Query.Execute().Select();
				
				While Selection.Next() Do
					
					RegisterArray.Add(Selection.RegisterName);
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return RegisterArray;
	
EndFunction // GetUsedRegistersNamesArray()

// Prepares document records sets.
//
Procedure PrepareRecordSetsForRecording(ObjectStructure) Export
	
	For Each RecordSet in ObjectStructure.RegisterRecords Do
		
		If TypeOf(RecordSet) = Type("KeyAndValue") Then
			
			RecordSet = RecordSet.Value;
			
		EndIf;
		
		If RecordSet.Count() > 0 Then
			
			RecordSet.Clear();
			
		EndIf;
		
	EndDo;
	
	ArrayOfNamesOfRegisters = GetNamesArrayOfUsedRegisters(ObjectStructure.Ref, ObjectStructure.AdditionalProperties.ForPosting.DocumentMetadata);
	
	For Each RegisterName in ArrayOfNamesOfRegisters Do
		
		ObjectStructure.RegisterRecords[RegisterName].Write = True;
		
	EndDo;
	
EndProcedure

// Writes document records sets.
//
Procedure WriteRecordSets(ObjectStructure) Export
	
	For Each RecordSet in ObjectStructure.RegisterRecords Do
		
		If TypeOf(RecordSet) = Type("KeyAndValue") Then
			
			RecordSet = RecordSet.Value;
			
		EndIf;
		
		If RecordSet.Write Then
			
			If Not RecordSet.AdditionalProperties.Property("ForPosting") Then
				
				RecordSet.AdditionalProperties.Insert("ForPosting", New Structure);
				
			EndIf;
			
			If Not RecordSet.AdditionalProperties.ForPosting.Property("StructureTemporaryTables") Then
				
				RecordSet.AdditionalProperties.ForPosting.Insert("StructureTemporaryTables", ObjectStructure.AdditionalProperties.ForPosting.StructureTemporaryTables);
				
			EndIf;
			
			RecordSet.Write();
			RecordSet.Write = False;
			
		Else
			
			RecordSetMetadata = RecordSet.Metadata();
			If CommonUse.ThisIsAccumulationRegister(RecordSetMetadata)
				And ThereAreProcedureCreateAnEmptyTemporaryTableUpdate(RecordSetMetadata.FullName()) Then
				
				ObjectManager = CommonUse.ObjectManagerByFullName(RecordSetMetadata.FullName());
				ObjectManager.CreateEmptyTemporaryTableChange(ObjectStructure.AdditionalProperties);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ThereAreProcedureCreateAnEmptyTemporaryTableUpdate(FullNameOfRegister)
	
	RegistersWithTheProcedure = New Array;
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.FixedAssets.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.CashAssets.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.CashInCashRegisters.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.IncomeAndExpensesUndistributed.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.IncomeAndExpensesRetained.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.ProductionOrders.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.CustomerOrders.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.PurchaseOrders.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.Inventory.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.InventoryByCCD.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.InventoryForWarehouses.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.InventoryFromWarehouses.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.InventoryInWarehouses.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.InventoryTransferred.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.InventoryReceived.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.InventoryDemand.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.OrdersPlacement.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.TaxesSettlements.FullName());
 	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.PayrollPayments.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.AdvanceHolderPayments.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.AccountsReceivable.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.AccountsPayable.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.RetailAmountAccounting.FullName());
	RegistersWithTheProcedure.Add(Metadata.AccumulationRegisters.SerialNumbers.FullName());
	
	Return RegistersWithTheProcedure.Find(FullNameOfRegister) <> Undefined;
	
EndFunction

// Checks whether it is possible to clear the UseSerialNumbers option.
//
Function CancelRemoveFunctionalOptionUseSerialNumbers() Export
	
	ErrorText = "";
	AreRecords = False;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	SerialNumbers.SerialNumber
	|FROM
	|	AccumulationRegister.SerialNumbers AS SerialNumbers
	|WHERE
	|	SerialNumbers.SerialNumber <> VALUE(Catalog.SerialNumbers.EmptyRef)";
	
	QueryResult = Query.Execute();
	If NOT QueryResult.IsEmpty() Then
		AreRecords = True;
	EndIf;
	
	If AreRecords Then
		
		ErrorText = NStr("en='In the base there are balance serial number! The flag removal is prohibited!';ru='В базе есть остатки по серийным номерам! Снятие флага запрещено!';vi='Trong cơ sở dữ liệu có số dư theo số Sê-ri! Cấm bỏ dấu hộp kiểm!'");
		
	EndIf;
	
	Return ErrorText;
	
EndFunction

//////////////////////////////////////////////////////////////////////////////// 
// REGISTERS MOVEMENTS GENERATING PROCEDURES

// Function returns the ControlBalancesDuringOnPosting constant value.
// 
Function RunBalanceControl() Export
	
	Return Constants.ControlBalancesOnPosting.Get();
	
EndFunction // RunBalanceControl()

// Moves accumulation register CashAssets.
//
Procedure ReflectCashAssets(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableCashAssets = AdditionalProperties.TableForRegisterRecords.TableCashAssets;
	
	If Cancel
	 OR TableCashAssets.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsCashAssets = RegisterRecords.CashAssets;
	RegisterRecordsCashAssets.Write = True;
	RegisterRecordsCashAssets.Load(TableCashAssets);
	
EndProcedure

// Moves accumulation register AdvanceHoldersPayments.
//
Procedure ReflectAdvanceHolderPayments(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableSettlementsWithAdvanceHolders = AdditionalProperties.TableForRegisterRecords.TableSettlementsWithAdvanceHolders;
	
	If Cancel
	 OR TableSettlementsWithAdvanceHolders.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsAdvanceHolderPayments = RegisterRecords.AdvanceHolderPayments;
	RegisterRecordsAdvanceHolderPayments.Write = True;
	RegisterRecordsAdvanceHolderPayments.Load(TableSettlementsWithAdvanceHolders);
	
EndProcedure // ExecuteExpenseByCalculationsWithAdvanceHolders()

// Moves accumulation register CounterpartiesSettlements.
//
Procedure ReflectAccountsReceivable(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableAccountsReceivable = AdditionalProperties.TableForRegisterRecords.TableAccountsReceivable;
	
	If Cancel
	 OR TableAccountsReceivable.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsAccountsReceivable = RegisterRecords.AccountsReceivable;
	RegisterRecordsAccountsReceivable.Write = True;
	RegisterRecordsAccountsReceivable.Load(TableAccountsReceivable);
	
EndProcedure

// Moves accumulation register CounterpartiesSettlements.
//
Procedure ReflectAccountsPayable(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableAccountsPayable = AdditionalProperties.TableForRegisterRecords.TableAccountsPayable;
	
	If Cancel
	 OR TableAccountsPayable.Count() = 0 Then
		Return;
	EndIf;
	
	VendorsPaymentsRegistration = RegisterRecords.AccountsPayable;
	VendorsPaymentsRegistration.Write = True;
	VendorsPaymentsRegistration.Load(TableAccountsPayable);
	
EndProcedure

// Moves accumulation register Payment schedule.
//
// Parameters:
//  DocumentObject - Current
//  document Denial - Boolean - Check box of canceling document posting.
//
Procedure ReflectPaymentCalendar(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TablePaymentCalendar = AdditionalProperties.TableForRegisterRecords.TablePaymentCalendar;
	
	If Cancel
	 OR TablePaymentCalendar.Count() = 0 Then
		Return;
	EndIf;
	
	PaymentCalendarRegistration = RegisterRecords.PaymentCalendar;
	PaymentCalendarRegistration.Write = True;
	PaymentCalendarRegistration.Load(TablePaymentCalendar);
	
EndProcedure // ReflectPaymentCalendar()

// Moves accumulation register Accounts payment.
//
// Parameters:
//  DocumentObject - Current
//  document Denial - Boolean - Check box of canceling document posting.
//
Procedure ReflectInvoicesAndOrdersPayment(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInvoicesAndOrdersPayment = AdditionalProperties.TableForRegisterRecords.TableInvoicesAndOrdersPayment;
	
	If Cancel
	 OR TableInvoicesAndOrdersPayment.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsInvoicesAndOrdersPayment = RegisterRecords.InvoicesAndOrdersPayment;
	RegisterRecordsInvoicesAndOrdersPayment.Write = True;
	RegisterRecordsInvoicesAndOrdersPayment.Load(TableInvoicesAndOrdersPayment);
	
EndProcedure // ReflectInvoicesAndOrdersPayment()

// Procedure moves IncomingsAndExpensesPettyCashMethodaccumulation register.
//
// Parameters:
// DocumentObject - Current
// document Denial - Boolean - Shows that you cancelled document posting.
//
Procedure ReflectIncomeAndExpensesCashMethod(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableIncomeAndExpensesCashMethod = AdditionalProperties.TableForRegisterRecords.TableIncomeAndExpensesCashMethod;
	
	If Cancel
	 OR TableIncomeAndExpensesCashMethod.Count() = 0 Then
		Return;
	EndIf;
	
	IncomeAndExpensesCashMethod = RegisterRecords.IncomeAndExpensesCashMethod;
	IncomeAndExpensesCashMethod.Write = True;
	IncomeAndExpensesCashMethod.Load(TableIncomeAndExpensesCashMethod);
	
EndProcedure // ReflectIncomeAndExpensesCashMethod()

// Procedure moves the IncomeAndExpensesUndistributed accumulation register.
//
// Parameters:
// DocumentObject - Current
// document Denial - Boolean - Shows that you cancelled document posting.
//
Procedure ReflectIncomeAndExpensesUndistributed(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableIncomeAndExpensesUndistributed = AdditionalProperties.TableForRegisterRecords.TableIncomeAndExpensesUndistributed;
	
	If Cancel
	 OR TableIncomeAndExpensesUndistributed.Count() = 0 Then
		Return;
	EndIf;
	
	IncomeAndExpensesUndistributed = RegisterRecords.IncomeAndExpensesUndistributed;
	IncomeAndExpensesUndistributed.Write = True;
	IncomeAndExpensesUndistributed.Load(TableIncomeAndExpensesUndistributed);
	
EndProcedure // ReflectIncomeAndExpensesUndistributed()

// Procedure moves IncomeAndExpensesDelayed accumulation register.
//
// Parameters:
// DocumentObject - Current
// document Denial - Boolean - Shows that you cancelled document posting.
//
Procedure ReflectIncomeAndExpensesRetained(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableIncomeAndExpensesRetained = AdditionalProperties.TableForRegisterRecords.TableIncomeAndExpensesRetained;
	
	If Cancel
	 OR TableIncomeAndExpensesRetained.Count() = 0 Then
		Return;
	EndIf;
	
	IncomeAndExpensesRetained = RegisterRecords.IncomeAndExpensesRetained;
	IncomeAndExpensesRetained.Write = True;
	IncomeAndExpensesRetained.Load(TableIncomeAndExpensesRetained);
	
EndProcedure // ReflectIncomeAndExpensesRetained()

// Moves accumulation register DeductionsAndAccrual.
//
Procedure ReflectAccrualsAndDeductions(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableAccrualsAndDeductions = AdditionalProperties.TableForRegisterRecords.TableAccrualsAndDeductions;
	
	If Cancel
	 OR TableAccrualsAndDeductions.Count() = 0 Then
		Return;
	EndIf;
	
	RegistrationAccrualsAndDeductions = RegisterRecords.AccrualsAndDeductions;
	RegistrationAccrualsAndDeductions.Write = True;
	RegistrationAccrualsAndDeductions.Load(TableAccrualsAndDeductions);
	
EndProcedure

// Moves accumulation register PayrollPayments.
//
Procedure ReflectPayrollPayments(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TablePayrollPayments = AdditionalProperties.TableForRegisterRecords.TablePayrollPayments;
	
	If Cancel
	 OR TablePayrollPayments.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsPayrollPayments = RegisterRecords.PayrollPayments;
	RegisterRecordsPayrollPayments.Write = True;
	RegisterRecordsPayrollPayments.Load(TablePayrollPayments);
	
EndProcedure

// Moves information register PlannedAccrualsAndDeductions.
//
Procedure ReflectAccrualsAndDeductionsPlan(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableAccrualsAndDeductionsPlan = AdditionalProperties.TableForRegisterRecords.TableAccrualsAndDeductionsPlan;
	
	If Cancel
	 OR TableAccrualsAndDeductionsPlan.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsPlannedAccrualsAndDeductions = RegisterRecords.AccrualsAndDeductionsPlan;
	RegisterRecordsPlannedAccrualsAndDeductions.Write = True;
	RegisterRecordsPlannedAccrualsAndDeductions.Load(TableAccrualsAndDeductionsPlan);
	
EndProcedure

// Moves information register Employees.
//
Procedure ReflectEmployees(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableEmployees = AdditionalProperties.TableForRegisterRecords.TableEmployees;
	
	If Cancel
	 OR TableEmployees.Count() = 0 Then
		Return;
	EndIf;
	
	EmployeeRecords = RegisterRecords.Employees;
	EmployeeRecords.Write = True;
	EmployeeRecords.Load(TableEmployees);
	
EndProcedure

// Moves accumulation register Time sheet.
//
Procedure ReflectTimesheet(AdditionalProperties, RegisterRecords, Cancel) Export
	
	ScheduleTable = AdditionalProperties.TableForRegisterRecords.ScheduleTable;
	
	If Cancel
	 OR ScheduleTable.Count() = 0 Then
		Return;
	EndIf;
	
	ScheduleRecords = RegisterRecords.Timesheet;
	ScheduleRecords.Write = True;
	ScheduleRecords.Load(ScheduleTable);
	
EndProcedure

// Moves accumulation register IncomingsAndExpenses.
//
Procedure ReflectIncomeAndExpenses(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableIncomeAndExpenses = AdditionalProperties.TableForRegisterRecords.TableIncomeAndExpenses;
	
	If Cancel
	 OR TableIncomeAndExpenses.Count() = 0 Then
		Return;
	EndIf;
	
	IncomeAndExpencesRegistering = RegisterRecords.IncomeAndExpenses;
	IncomeAndExpencesRegistering.Write = True;
	IncomeAndExpencesRegistering.Load(TableIncomeAndExpenses);
	
EndProcedure

// Moves accumulation register AmountAccountingInRetail.
//
Procedure ReflectRetailAmountAccounting(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableRetailAmountAccounting = AdditionalProperties.TableForRegisterRecords.TableRetailAmountAccounting;
	
	If Cancel
	 OR TableRetailAmountAccounting.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsRetailAmountAccounting = RegisterRecords.RetailAmountAccounting;
	RegisterRecordsRetailAmountAccounting.Write = True;
	RegisterRecordsRetailAmountAccounting.Load(TableRetailAmountAccounting);
	
EndProcedure // ReflectRetailAmountAccounting()

// Moves accumulation register CalculationsOnTaxes.
//
Procedure ReflectTaxesSettlements(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableTaxAccounting = AdditionalProperties.TableForRegisterRecords.TableTaxAccounting;
	
	If Cancel
	 OR TableTaxAccounting.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsTaxesSettlements = RegisterRecords.TaxesSettlements;
	RegisterRecordsTaxesSettlements.Write = True;
	RegisterRecordsTaxesSettlements.Load(TableTaxAccounting);
	
EndProcedure

// Moves accumulation register InventoryForWarehouses.
//
Procedure ReflectInventoryForWarehouses(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryForWarehouses = AdditionalProperties.TableForRegisterRecords.TableInventoryForWarehouses;
	
	If Cancel
	 OR TableInventoryForWarehouses.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsInventoryForWarehouses = RegisterRecords.InventoryForWarehouses;
	RegisterRecordsInventoryForWarehouses.Write = True;
	RegisterRecordsInventoryForWarehouses.Load(TableInventoryForWarehouses);
	
EndProcedure

// Moves accumulation register InventoryExpenseFromWarehouses.
//
Procedure ReflectInventoryForExpenseFromWarehouses(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryForExpenseFromWarehouses = AdditionalProperties.TableForRegisterRecords.TableInventoryForExpenseFromWarehouses;
	
	If Cancel
	 OR TableInventoryForExpenseFromWarehouses.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsInventoryFromWarehouses = RegisterRecords.InventoryFromWarehouses;
	RegisterRecordsInventoryFromWarehouses.Write = True;
	RegisterRecordsInventoryFromWarehouses.Load(TableInventoryForExpenseFromWarehouses);
	
EndProcedure

// Moves accumulation register InventoryOnWarehouses.
//
Procedure ReflectInventoryInWarehouses(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryInWarehouses = AdditionalProperties.TableForRegisterRecords.TableInventoryInWarehouses;
	
	If Cancel
	 OR TableInventoryInWarehouses.Count() = 0 Then
		Return;
	EndIf;
	
	WarehouseInventoryRegistering = RegisterRecords.InventoryInWarehouses;
	WarehouseInventoryRegistering.Write = True;
	WarehouseInventoryRegistering.Load(TableInventoryInWarehouses);
	
EndProcedure // ReflectInventoryInWarehouses()

// Moves accumulation register CashAssetsInCRRReceipt.
//
Procedure ReflectCashAssetsInCashRegisters(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableCashInCashRegisters = AdditionalProperties.TableForRegisterRecords.TableCashInCashRegisters;
	
	If Cancel
	 OR TableCashInCashRegisters.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsCashInCashRegisters = RegisterRecords.CashInCashRegisters;
	RegisterRecordsCashInCashRegisters.Write = True;
	RegisterRecordsCashInCashRegisters.Load(TableCashInCashRegisters);
	
EndProcedure // ReflectCashAssetsInCashRegisters()

// Moves accumulation register Inventory.
//
Procedure ReflectInventory(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventory = AdditionalProperties.TableForRegisterRecords.TableInventory;
	
	If Cancel
	 OR TableInventory.Count() = 0 Then
		Return;
	EndIf;
	
	InventoryRecords = RegisterRecords.Inventory;
	InventoryRecords.Write = True;
	InventoryRecords.Load(TableInventory);
	
EndProcedure

// Moves on the register Sales targets.
//
Procedure ReflectSalesTargets(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableSalesTargets = AdditionalProperties.TableForRegisterRecords.TableSalesTargets;
	
	If Cancel
	 OR TableSalesTargets.Count() = 0 Then
		Return;
	EndIf;
	
	SalesTargetsRecords = RegisterRecords.SalesTargets;
	SalesTargetsRecords.Write = True;
	SalesTargetsRecords.Load(TableSalesTargets);
	
EndProcedure // ReflectSalesTargets()

// Moves on the register CashAssetsForecast.
//
Procedure ReflectCashAssetsForecast(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableCashAssetsForecast = AdditionalProperties.TableForRegisterRecords.TableCashAssetsForecast;
	
	If Cancel
	 OR TableCashAssetsForecast.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsBudgetCashAssetsForecast = RegisterRecords.CashAssetsForecast;
	RegisterRecordsBudgetCashAssetsForecast.Write = True;
	RegisterRecordsBudgetCashAssetsForecast.Load(TableCashAssetsForecast);
	
EndProcedure // ReflectCashAssetsForecast()

// Moves accumulation register IncomeAndExpensesForecast.
//
Procedure ReflectIncomeAndExpensesForecast(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableIncomeAndExpensesForecast = AdditionalProperties.TableForRegisterRecords.TableIncomeAndExpensesForecast;
	
	If Cancel
	 OR TableIncomeAndExpensesForecast.Count() = 0 Then
		Return;
	EndIf;
	
	RegesteringIncomeAndExpencesForecast = RegisterRecords.IncomeAndExpensesForecast;
	RegesteringIncomeAndExpencesForecast.Write = True;
	RegesteringIncomeAndExpencesForecast.Load(TableIncomeAndExpensesForecast);
	
EndProcedure

// Moves on the register FinancialResultForecast.
//
Procedure ReflectFinancialResultForecast(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableFinancialResultForecast = AdditionalProperties.TableForRegisterRecords.TableFinancialResultForecast;
	
	If Cancel
	 OR TableFinancialResultForecast.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsFinancialResultForecast = RegisterRecords.FinancialResultForecast;
	RegisterRecordsFinancialResultForecast.Write = True;
	RegisterRecordsFinancialResultForecast.Load(TableFinancialResultForecast);
	
EndProcedure // ReflectFinancialResultForecast()

// Moves on the register Purchases.
//
Procedure ReflectPurchasing(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TablePurchasing = AdditionalProperties.TableForRegisterRecords.TablePurchasing;
	
	If Cancel
	 OR TablePurchasing.Count() = 0 Then
		Return;
	EndIf;
	
	PurchaseRecord = RegisterRecords.Purchases;
	PurchaseRecord.Write = True;
	PurchaseRecord.Load(TablePurchasing);
	
EndProcedure // ReflectPurchasing()

// Moves on the register InventoryTransferred.
//
Procedure ReflectInventoryTransferred(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryTransferred = AdditionalProperties.TableForRegisterRecords.TableInventoryTransferred;
	
	If Cancel
	 OR TableInventoryTransferred.Count() = 0 Then
		Return;
	EndIf;
	
	InventoryTransferredRegestering = RegisterRecords.InventoryTransferred;
	InventoryTransferredRegestering.Write = True;
	InventoryTransferredRegestering.Load(TableInventoryTransferred);
	
EndProcedure // ReflectInventoryTransferred()

// Moves on the register Inventory received.
//
Procedure ReflectInventoryAccepted(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryReceived = AdditionalProperties.TableForRegisterRecords.TableInventoryReceived;
	
	If Cancel
	 OR TableInventoryReceived.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsInventoryReceived = RegisterRecords.InventoryReceived;
	RegisterRecordsInventoryReceived.Write = True;
	RegisterRecordsInventoryReceived.Load(TableInventoryReceived);
	
EndProcedure // ReflectInventoryAccepted()

// Moves on register Orders placement.
//
Procedure ReflectOrdersPlacement(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableOrdersPlacement = AdditionalProperties.TableForRegisterRecords.TableOrdersPlacement;
	
	If Cancel
	 OR TableOrdersPlacement.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsOrdersPlacement = RegisterRecords.OrdersPlacement;
	RegisterRecordsOrdersPlacement.Write = True;
	RegisterRecordsOrdersPlacement.Load(TableOrdersPlacement);
	
EndProcedure // ReflectOrdersPlacement()

// Moves on the register Sales.
//
Procedure ReflectSales(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableSales = AdditionalProperties.TableForRegisterRecords.TableSales;
	
	If Cancel
	 OR TableSales.Count() = 0 Then
		Return;
	EndIf;
	
	SalesRecord = RegisterRecords.Sales;
	SalesRecord.Write = True;
	SalesRecord.Load(TableSales);
	
EndProcedure // ReflectSales()

// Moves on the register Customer orders.
//
Procedure ReflectCustomerOrders(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableCustomerOrders = AdditionalProperties.TableForRegisterRecords.TableCustomerOrders;
	
	If Cancel
	 OR TableCustomerOrders.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsCustomerOrders = RegisterRecords.CustomerOrders;
	RegisterRecordsCustomerOrders.Write = True;
	RegisterRecordsCustomerOrders.Load(TableCustomerOrders);
	
EndProcedure // ReflectCustomerOrders()

// Moves on the register InventoryTransferSchedule.
//
Procedure ReflectInventoryTransferSchedule(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryTransferSchedule = AdditionalProperties.TableForRegisterRecords.TableInventoryTransferSchedule;
	
	If Cancel
	 OR TableInventoryTransferSchedule.Count() = 0 Then
		Return;
	EndIf;
	
	RegesteringSchedeuleInventoryMovement = RegisterRecords.InventoryTransferSchedule;
	RegesteringSchedeuleInventoryMovement.Write = True;
	RegesteringSchedeuleInventoryMovement.Load(TableInventoryTransferSchedule);
	
EndProcedure // ReflectInventoryTransferSchedule()

// Moves on the register ProductionOrders.
//
Procedure ReflectProductionOrders(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableProductionOrders = AdditionalProperties.TableForRegisterRecords.TableProductionOrders;
	
	If Cancel 
	 OR TableProductionOrders.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsProductionOrders = RegisterRecords.ProductionOrders;
	RegisterRecordsProductionOrders.Write = True;
	RegisterRecordsProductionOrders.Load(TableProductionOrders);
	
EndProcedure // ReflectProductionOrders()

// Moves on the register InventoryDemand.
//
Procedure ReflectInventoryDemand(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryDemand = AdditionalProperties.TableForRegisterRecords.TableInventoryDemand;
	
	If Cancel 
	 OR TableInventoryDemand.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsInventoryDemand = RegisterRecords.InventoryDemand;
	RegisterRecordsInventoryDemand.Write = True;
	RegisterRecordsInventoryDemand.Load(TableInventoryDemand);
	
EndProcedure // ReflectInventoryDemand()

// Moves on the register Purchase orders.
//
Procedure ReflectPurchaseOrders(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TablePurchaseOrders = AdditionalProperties.TableForRegisterRecords.TablePurchaseOrders;
	
	If Cancel
	 OR TablePurchaseOrders.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsPurchaseOrders = RegisterRecords.PurchaseOrders;
	RegisterRecordsPurchaseOrders.Write = True;
	RegisterRecordsPurchaseOrders.Load(TablePurchaseOrders);
	
EndProcedure // ReflectPurchaseOrders()

// Moves on the register Purchase orders.
//
Procedure ReflectFixedAssetsOutput(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableFixedAssetsOutput = AdditionalProperties.TableForRegisterRecords.TableFixedAssetsOutput;
	
	If Cancel
	 OR TableFixedAssetsOutput.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsFixedAssetsProduction = RegisterRecords.FixedAssetsOutput;
	RegisterRecordsFixedAssetsProduction.Write = True;
	RegisterRecordsFixedAssetsProduction.Load(TableFixedAssetsOutput);
	
EndProcedure // ReflectFixedAssetsOutput()

// Moves information register FixedAssetsStates.
//
Procedure ReflectFixedAssetStatuses(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableFixedAssetsStates = AdditionalProperties.TableForRegisterRecords.TableFixedAssetsStates;
	
	If Cancel
	 OR TableFixedAssetsStates.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsStateOfFixedAssets = RegisterRecords.FixedAssetsStates;
	RegisterRecordsStateOfFixedAssets.Write = True;
	RegisterRecordsStateOfFixedAssets.Load(TableFixedAssetsStates);
	
EndProcedure

// Moves the InitialInformationDepreciationParameters information register.
//
Procedure ReflectFixedAssetsParameters(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableFixedAssetsParameters = AdditionalProperties.TableForRegisterRecords.TableFixedAssetsParameters;
	
	If Cancel
	 OR TableFixedAssetsParameters.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsFixedAssetsParameters = RegisterRecords.FixedAssetsParameters;
	RegisterRecordsFixedAssetsParameters.Write = True;
	RegisterRecordsFixedAssetsParameters.Load(TableFixedAssetsParameters);
	
EndProcedure

// Moves information register MonthClosingError.
//
Procedure ReflectMonthEndErrors(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableMonthEndErrors = AdditionalProperties.TableForRegisterRecords.TableMonthEndErrors;
	
	If Cancel
	 OR TableMonthEndErrors.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsMonthEndErrors = RegisterRecords.MonthEndErrors;
	RegisterRecordsMonthEndErrors.Write = True;
	RegisterRecordsMonthEndErrors.Load(TableMonthEndErrors);
	
EndProcedure

// Moves accumulation register CapitalAssetsDepreciation
//
Procedure ReflectFixedAssets(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableFixedAssets = AdditionalProperties.TableForRegisterRecords.TableFixedAssets;
	
	If Cancel
	 OR TableFixedAssets.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsFixedAssets = RegisterRecords.FixedAssets;
	RegisterRecordsFixedAssets.Write = True;
	RegisterRecordsFixedAssets.Load(TableFixedAssets);
	
EndProcedure

// Moves on the register WorkOrders.
//
Procedure ReflectWorkOrders(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableWorkOrders = AdditionalProperties.TableForRegisterRecords.TableWorkOrders;
	
	If Cancel
	 OR TableWorkOrders.Count() = 0 Then
		Return;
	EndIf;
	
	RegisteringsWorkOrders = RegisterRecords.WorkOrders;
	RegisteringsWorkOrders.Write = True;
	RegisteringsWorkOrders.Load(TableWorkOrders);
	
EndProcedure // ShowWorksInProgress()

// Moves on the register JobSheets.
//
Procedure ReflectJobSheets(AdditionalProperties, RegisterRecords, Cancel) Export
	
	jobSheetTable = AdditionalProperties.TableForRegisterRecords.jobSheetTable;
	
	If Cancel
	 OR jobSheetTable.Count() = 0 Then
		Return;
	EndIf;
	
	RegisteringJobSheet = RegisterRecords.JobSheets;
	RegisteringJobSheet.Write = True;
	RegisteringJobSheet.Load(jobSheetTable);
	
EndProcedure // ShowJobsInProgress()

// Moves on the register ProductRelease.
//
Procedure ReflectProductRelease(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableProductRelease = AdditionalProperties.TableForRegisterRecords.TableProductRelease;
	
	If Cancel
	 OR TableProductRelease.Count() = 0 Then
		Return;
	EndIf;
	
	RegistersProductionTurnout = RegisterRecords.ProductRelease;
	RegistersProductionTurnout.Write = True;
	RegistersProductionTurnout.Load(TableProductRelease);
	
EndProcedure // ReflectProductRelease()

// Moves accumulation register CapitalAssetsDepreciation
//
Procedure ReflectInventoryByCCD(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableInventoryByCCD = AdditionalProperties.TableForRegisterRecords.TableInventoryByCCD;
	
	If Cancel
	 OR TableInventoryByCCD.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsInventoryByCCD = RegisterRecords.InventoryByCCD;
	RegisterRecordsInventoryByCCD.Write = True;
	RegisterRecordsInventoryByCCD.Load(TableInventoryByCCD);
	
EndProcedure

// Moves accumulation register BankCharges.
//
Procedure ReflectBankCharges(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableBankCharges = AdditionalProperties.TableForRegisterRecords.TableBankCharges;
	
	If Cancel
	 OR TableBankCharges.Count() = 0 Then
		Return;
	EndIf;
	
	BankChargesRegistering = RegisterRecords.BankCharges;
	BankChargesRegistering.Write = True;
	BankChargesRegistering.Load(TableBankCharges);
	
EndProcedure

// Moves accounting register Management.
//
Procedure ReflectManagerial(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableManagerial = AdditionalProperties.TableForRegisterRecords.TableManagerial;
	
	If Cancel
	 OR TableManagerial.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterAdministratives = RegisterRecords.Managerial;
	RegisterAdministratives.Write = True;
	
	For Each RowTableManagerial IN TableManagerial Do
		RegisterAdministrative = RegisterAdministratives.Add();
		FillPropertyValues(RegisterAdministrative, RowTableManagerial);
	EndDo;
	
EndProcedure

Procedure ReflectProductionStages(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableProductionStages = AdditionalProperties.TableForRegisterRecords.TableProductionStages;
	
	If Cancel
		OR TableProductionStages.Count() = 0 Then
		Return;
	EndIf;
	
	RegistersProductionStages = RegisterRecords.ProductionStages;
	RegistersProductionStages.Write = True;
	RegistersProductionStages.Load(TableProductionStages);
	
EndProcedure

// Выполняет движения по регистру РасписаниеЗагрузкиРесурсов.
Procedure ReflectEnterpriseResources(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableCompanyResources = AdditionalProperties.TableForRegisterRecords.TableCompanyResources;
	
	If Cancel
	 Or TableCompanyResources.Count() = 0 Then
		Return;
	EndIf;
	
	RecordsCompanyResources = RegisterRecords.ScheduleLoadingResources;
	RecordsCompanyResources.Write = True;
	RecordsCompanyResources.Load(TableCompanyResources);
	
EndProcedure

#Region DiscountCards

// Moves on the register SalesByDiscountCards.
//
Procedure ReflectSalesByDiscountCard(AdditionalProperties, RegisterRecords, Cancel) Export
	
	SaleByDiscountCardTable = AdditionalProperties.TableForRegisterRecords.SaleByDiscountCardTable;
	
	If Cancel
	 OR SaleByDiscountCardTable.Count() = 0 Then
		Return;
	EndIf;
	
	SalesByDiscountCardMovements = RegisterRecords.SalesByDiscountCards;
	SalesByDiscountCardMovements.Write = True;
	SalesByDiscountCardMovements.Load(SaleByDiscountCardTable);
	
EndProcedure // ReflectSales()

#EndRegion

#Region AutomaticDiscounts

// Moves on the register ProvidedAutomaticDiscounts.
//
Procedure FlipAutomaticDiscountsApplied(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableAutomaticDiscountsApplied = AdditionalProperties.TableForRegisterRecords.TableAutomaticDiscountsApplied;
	
	If Cancel
	 OR TableAutomaticDiscountsApplied.Count() = 0 Then
		Return;
	EndIf;
	
	MovementsProvidedAutomaticDiscounts = RegisterRecords.AutomaticDiscountsApplied;
	MovementsProvidedAutomaticDiscounts.Write = True;
	MovementsProvidedAutomaticDiscounts.Load(TableAutomaticDiscountsApplied);
	
EndProcedure // ReflectSales()

#EndRegion

#Region WorkWithSerialNumbers

Procedure ReflectTheSerialNumbersOfTheGuarantee(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableSerialNumbersGuarantees = AdditionalProperties.TableForRegisterRecords.TableSerialNumbersGuarantees;
	
	If Cancel
	 OR TableSerialNumbersGuarantees.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsSerialNumbersGuarantees = RegisterRecords.SerialNumbersGuarantees;
	RegisterRecordsSerialNumbersGuarantees.Write = True;
	RegisterRecordsSerialNumbersGuarantees.Load(TableSerialNumbersGuarantees);
	
EndProcedure

Procedure ReflectTheSerialNumbersBalance(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableSerialNumbersBalance = AdditionalProperties.TableForRegisterRecords.TableSerialNumbersBalance;
	
	If Cancel
	 OR TableSerialNumbersBalance.Count() = 0 Then
		Return;
	EndIf;
	
	RegisterRecordsSerialNumbersBalance = RegisterRecords.SerialNumbers;
	RegisterRecordsSerialNumbersBalance.Write = True;
	RegisterRecordsSerialNumbersBalance.Load(TableSerialNumbersBalance);
	
EndProcedure // ReflectSales()

#EndRegion

///////////////////////////////////////////////////////////////////////////////////////////////////
// PRICING SUBSYSTEM PROCEDURES AND FUNCTIONS

// Returns currencies rates to date.
//
// Parameters:
//  Currency       - CatalogRef.Currencies - Currency (catalog item
//  "Currencies") CourseDate    - Date - date for which a rate should be received.
//
// Returns: 
//  Structure, contains:
//   ExchangeRate        - Number - exchange
//   rate, Multiplicity   - Number - currency frequency.
//
Function GetCurrencyRates(CurrencyBeg, CurrencyEnd, ExchangeRateDate) Export
	
	StructureBeg = InformationRegisters.CurrencyRates.GetLast(ExchangeRateDate, New Structure("Currency", CurrencyBeg));
	StructureEnd = InformationRegisters.CurrencyRates.GetLast(ExchangeRateDate, New Structure("Currency", CurrencyEnd));
	
	StructureEnd.ExchangeRate = ?(
		StructureEnd.ExchangeRate = 0,
		1,
		StructureEnd.ExchangeRate
	);
	StructureEnd.Multiplicity = ?(
		StructureEnd.Multiplicity = 0,
		1,
		StructureEnd.Multiplicity
	);
	StructureEnd.Insert("InitRate", ?(StructureBeg.ExchangeRate      = 0, 1, StructureBeg.ExchangeRate));
	StructureEnd.Insert("RepetitionBeg", ?(StructureBeg.Multiplicity = 0, 1, StructureBeg.Multiplicity));
	
	Return StructureEnd;
	
EndFunction // GetCurrencyRates()

// Returns currencies rates to date.
//
// Parameters:
//  Currency       - CatalogRef.Currencies - Currency (catalog item
//  "Currencies") CourseDate    - Date - date for which a rate should be received.
//
// Returns: 
//  Structure, contains:
//   ExchangeRate - Number - the exchange rate.
//   Multiplicity - Number - the exchange rate multiplier.
//
Function GetExchangeRates(CurrencyBeg, CurrencyEnd, ExchangeRateDate) Export
	
	StructureBeg = InformationRegisters.CurrencyRates.GetLast(ExchangeRateDate, New Structure("Currency", CurrencyBeg));
	StructureEnd = InformationRegisters.CurrencyRates.GetLast(ExchangeRateDate, New Structure("Currency", CurrencyEnd));
	
	StructureEnd.ExchangeRate = ?(
		StructureEnd.ExchangeRate = 0,
		1,
		StructureEnd.ExchangeRate
	);
	StructureEnd.Multiplicity = ?(
		StructureEnd.Multiplicity = 0,
		1,
		StructureEnd.Multiplicity
	);
	StructureEnd.Insert("InitRate", ?(StructureBeg.ExchangeRate      = 0, 1, StructureBeg.ExchangeRate));
	StructureEnd.Insert("RepetitionBeg", ?(StructureBeg.Multiplicity = 0, 1, StructureBeg.Multiplicity));
	
	Return StructureEnd;
	
EndFunction

Function RecalculateFromCurrencyToAccountingCurrency(AmountCur, CurrencyContract, ExchangeRateDate) Export
	
	Amount = 0;
	
	If ValueIsFilled(CurrencyContract) Then
		
		Currency = ?(TypeOf(CurrencyContract) = Type("CatalogRef.CounterpartyContracts"), CurrencyContract.SettlementsCurrency, CurrencyContract);
		PresentationCurrency = Constants.AccountingCurrency.Get();
		ExchangeRatesStructure = GetExchangeRates(Currency, PresentationCurrency, ExchangeRateDate);
		
		Amount = RecalculateFromCurrencyToCurrency(
					AmountCur,
					ExchangeRatesStructure.InitRate,
					ExchangeRatesStructure.ExchangeRate,
					ExchangeRatesStructure.RepetitionBeg,
					ExchangeRatesStructure.Multiplicity);
		
	EndIf;
	
	Return Amount;
	
EndFunction

// Function recalculates the amount from one currency to another
//
// Parameters:      
// Amount         - Number - amount that should be recalculated.
// 	InitRate       - Number - currency rate from which you should recalculate.
// 	FinRate       - Number - currency rate to which you should recalculate.
// 	RepetitionBeg  - Number - multiplicity from which you
// should recalculate (by default = 1).
// 	RepetitionEnd  - Number - multiplicity in which
// it is required to recalculate (by default =1)
//
// Returns: 
//  Number - amount recalculated to another currency.
//
Function RecalculateFromCurrencyToCurrency(Amount, InitRate, FinRate,	RepetitionBeg = 1, RepetitionEnd = 1) Export
	
	If (InitRate = FinRate) AND (RepetitionBeg = RepetitionEnd) Then
		Return Amount;
	EndIf;
	
	If InitRate = 0 OR FinRate = 0 OR RepetitionBeg = 0 OR RepetitionEnd = 0 Then
		Message = New UserMessage();
		Message.Text = NStr("en='Zero exchange rate is found. Conversion is not executed.';ru='Обнаружен нулевой курс валюты. Пересчет не выполнен.';vi='Đã tìm thấy tỷ giá ngoại tệ bằng 0. Chưa thực hiện tính lại.'");
		Message.Message();
		Return Amount;
	EndIf;
	
	RecalculatedSumm = Round((Amount * InitRate * RepetitionEnd) / (FinRate * RepetitionBeg), 2);
	
	Return RecalculatedSumm;
	
EndFunction // RecalculateFromCurrencyToCurrency()

// Rounds a number according to a specified order.
//
// Parameters:
//  Number        - Number required
//  to be rounded RoundingOrder - Enums.RoundingMethods - round
//  order RoundUpward - Boolean - rounding upward.
//
// Returns:
//  Number        - rounding result.
//
Function RoundPrice(Number, RoundRule, RoundUp) Export
	
	Var Result; // Returned result.
	
	// Transform order of numbers rounding.
	// If null order value is passed, then round to cents. 
	If Not ValueIsFilled(RoundRule) Then
		RoundingOrder = Enums.RoundingMethods.Round0_01; 
	Else
		RoundingOrder = RoundRule;
	EndIf;
	Order = Number(String(RoundingOrder));
	
	// calculate quantity of intervals included in number
	QuantityInterval	= Number / Order;
	
	// calculate an integer quantity of intervals.
	NumberOfEntireIntervals = Int(QuantityInterval);
	
	If QuantityInterval = NumberOfEntireIntervals Then
		
		// Numbers are divided integrally. No need to round.
		Result	= Number;
	Else
		If RoundUp Then
			
			// During 0.05 rounding 0.371 must be rounded to 0.4
			Result = Order * (NumberOfEntireIntervals + 1);
		Else
			
			// During 0.05 rounding 0.371 must round to 0.35
			// and 0.376 to 0.4
			Result = Order * Round(QuantityInterval, 0, RoundMode.Round15as20);
		EndIf; 
	EndIf;
	
	Return Result;
	
EndFunction // RoundPrice()

// Calculates VAT amount on the basis of amount and taxation check boxes.
//
// Parameters:
//  Amount        - Number - VAT
//  amount AmountIncludesVAT - Boolean - shows that VAT is
//  included in the VATRate amount.    - CatalogRef.VATRates - ref to VAT rate.
//
// Returns:
//  Number        - recalculated VAT amount.
//
Function RecalculateAmountOnVATFlagsChange(Amount, AmountIncludesVAT, VATRate) Export
	
	Rate = VATRate.Rate;
	
	If AmountIncludesVAT Then
		
		Amount = (Amount * (100 + Rate)) / 100;
		
	Else
		
		Amount = (Amount * 100) / (100 + Rate);
		
	EndIf;
	
	Return Amount;
	
EndFunction // RecalculateAmountOnVATCheckBoxesChange()

// Recalculate the price of the tabular section of the document after making changes in the "Prices and currency" form.
//
// Parameters:
//  AttributesStructure - Attribute structure, which necessary
//  when recalculation DocumentTabularSection - FormDataStructure, it
//                 contains the tabular document part.
//
Procedure GetTabularSectionPricesByPriceKind(DataStructure, DocumentTabularSection) Export
	
	// Discounts.
	If DataStructure.Property("DiscountMarkupKind") 
		AND ValueIsFilled(DataStructure.DiscountMarkupKind) Then
		
		DataStructure.DiscountMarkupPercent = DataStructure.DiscountMarkupKind.Percent;
		
	EndIf;	
	
	// Discount card.
	If DataStructure.Property("DiscountPercentByDiscountCard") 
		AND ValueIsFilled(DataStructure.DiscountPercentByDiscountCard) Then
		
		DataStructure.DiscountMarkupPercent = DataStructure.DiscountMarkupPercent + DataStructure.DiscountPercentByDiscountCard;
		
	EndIf;
	
	// 1. Generate document table.
	TempTablesManager = New TempTablesManager;
	
	ProductsAndServicesTable = New ValueTable;
	
	Array = New Array;
	
	// ProductsAndServices.
	Array.Add(Type("CatalogRef.ProductsAndServices"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("ProductsAndServices", TypeDescription);
	
	// Characteristic.
	Array.Add(Type("CatalogRef.ProductsAndServicesCharacteristics"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("Characteristic", TypeDescription);
	
	// VATRates.
	Array.Add(Type("CatalogRef.VATRates"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("VATRate", TypeDescription);	
	
	// MeasurementUnit.
	Array.Add(Type("CatalogRef.UOM"));
	Array.Add(Type("CatalogRef.UOMClassifier"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("MeasurementUnit", TypeDescription);	
	
	// Ratio.
	Array.Add(Type("Number"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("Factor", TypeDescription);
	
	For Each TSRow IN DocumentTabularSection Do
		
		NewRow = ProductsAndServicesTable.Add();
		NewRow.ProductsAndServices	 = TSRow.ProductsAndServices;
		NewRow.Characteristic	 = TSRow.Characteristic;
		NewRow.MeasurementUnit = TSRow.MeasurementUnit;
		If TypeOf(TSRow) = Type("Structure")
		   AND TSRow.Property("VATRate") Then
			NewRow.VATRate		 = TSRow.VATRate;
		EndIf;
		
		If TypeOf(TSRow.MeasurementUnit) = Type("CatalogRef.UOMClassifier") Then
			NewRow.Factor = 1;
		Else
			NewRow.Factor = TSRow.MeasurementUnit.Factor;
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	ProductsAndServicesTable.ProductsAndServices,
	|	ProductsAndServicesTable.Characteristic,
	|	ProductsAndServicesTable.MeasurementUnit,
	|	ProductsAndServicesTable.VATRate,
	|	ProductsAndServicesTable.Factor
	|INTO TemporaryProductsAndServicesTable
	|FROM
	|	&ProductsAndServicesTable AS ProductsAndServicesTable";
	
	Query.SetParameter("ProductsAndServicesTable", ProductsAndServicesTable);
	Query.Execute();
	
	// 2. We will fill prices.
	If DataStructure.PriceKind.CalculatesDynamically Then
		DynamicPriceKind = True;
		PriceKindParameter = DataStructure.PriceKind.PricesBaseKind;
		Markup = DataStructure.PriceKind.Percent;
		RoundingOrder = DataStructure.PriceKind.RoundingOrder;
		RoundUp = DataStructure.PriceKind.RoundUp;
	Else
		DynamicPriceKind = False;
		PriceKindParameter = DataStructure.PriceKind;	
	EndIf;	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = 
	"SELECT
	|	ProductsAndServicesTable.ProductsAndServices AS ProductsAndServices,
	|	ProductsAndServicesTable.Characteristic AS Characteristic,
	|	ProductsAndServicesTable.MeasurementUnit AS MeasurementUnit,
	|	ProductsAndServicesTable.VATRate AS VATRate,
	|	ProductsAndServicesPricesSliceLast.PriceKind.PriceCurrency AS ProductsAndServicesPricesCurrency,
	|	ProductsAndServicesPricesSliceLast.PriceKind.PriceIncludesVAT AS PriceIncludesVAT,
	|	ProductsAndServicesPricesSliceLast.PriceKind.RoundingOrder AS RoundingOrder,
	|	ProductsAndServicesPricesSliceLast.PriceKind.RoundUp AS RoundUp,
	|	ISNULL(ProductsAndServicesPricesSliceLast.Price * RateCurrencyTypePrices.ExchangeRate * DocumentCurrencyRate.Multiplicity / (DocumentCurrencyRate.ExchangeRate * RateCurrencyTypePrices.Multiplicity) * ISNULL(ProductsAndServicesTable.Factor, 1) / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1), 0) AS Price
	|FROM
	|	TemporaryProductsAndServicesTable AS ProductsAndServicesTable
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&ProcessingDate, PriceKind = &PriceKind) AS ProductsAndServicesPricesSliceLast
	|		ON ProductsAndServicesTable.ProductsAndServices = ProductsAndServicesPricesSliceLast.ProductsAndServices
	|			AND ProductsAndServicesTable.Characteristic = ProductsAndServicesPricesSliceLast.Characteristic
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, ) AS RateCurrencyTypePrices
	|		ON (ProductsAndServicesPricesSliceLast.PriceKind.PriceCurrency = RateCurrencyTypePrices.Currency),
	|	InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, Currency = &DocumentCurrency) AS DocumentCurrencyRate
	|WHERE
	|	ProductsAndServicesPricesSliceLast.Actuality";
		
	Query.SetParameter("ProcessingDate",	 DataStructure.Date);
	Query.SetParameter("PriceKind",			 PriceKindParameter);
	Query.SetParameter("DocumentCurrency", DataStructure.DocumentCurrency);
	
	PricesTable = Query.Execute().Unload();
	For Each TabularSectionRow IN DocumentTabularSection Do
		
		SearchStructure = New Structure;
		SearchStructure.Insert("ProductsAndServices",	 TabularSectionRow.ProductsAndServices);
		SearchStructure.Insert("Characteristic",	 TabularSectionRow.Characteristic);
		SearchStructure.Insert("MeasurementUnit", TabularSectionRow.MeasurementUnit);
		If TypeOf(TSRow) = Type("Structure")
		   AND TabularSectionRow.Property("VATRate") Then
			SearchStructure.Insert("VATRate", TabularSectionRow.VATRate);
		EndIf;
		
		SearchResult = PricesTable.FindRows(SearchStructure);
		If SearchResult.Count() > 0 Then
			
			Price = SearchResult[0].Price;
			If Price = 0 Then
				TabularSectionRow.Price = Price;
			Else
				
				// Dynamically calculate the price
				If DynamicPriceKind Then
					
					Price = Price * (1 + Markup / 100);
					
				Else	
					
					RoundingOrder = SearchResult[0].RoundingOrder;
					RoundUp = SearchResult[0].RoundUp;
					
				EndIf; 
				
				If DataStructure.Property("AmountIncludesVAT") 
				   AND ((DataStructure.AmountIncludesVAT AND Not SearchResult[0].PriceIncludesVAT) 
				   OR (NOT DataStructure.AmountIncludesVAT AND SearchResult[0].PriceIncludesVAT)) Then
					Price = RecalculateAmountOnVATFlagsChange(Price, DataStructure.AmountIncludesVAT, TabularSectionRow.VATRate);
				EndIf;
					
				TabularSectionRow.Price = RoundPrice(Price, RoundingOrder, RoundUp);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	TempTablesManager.Close();
	
EndProcedure // GetTabularSectionPricesByPriceKind()

// Recalculate the price of the tabular section of the document after making changes in the "Prices and currency" form.
//
// Parameters:
//  AttributesStructure - Attribute structure, which necessary
//  when recalculation DocumentTabularSection - FormDataStructure, it
//                 contains the tabular document part.
//
Procedure GetPricesTabularSectionByCounterpartyPriceKind(DataStructure, DocumentTabularSection) Export
	
	// 1. Generate document table.
	TempTablesManager = New TempTablesManager;
	
	ProductsAndServicesTable = New ValueTable;
	
	Array = New Array;
	
	// ProductsAndServices.
	Array.Add(Type("CatalogRef.ProductsAndServices"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("ProductsAndServices", TypeDescription);
	
	// Characteristic.
	Array.Add(Type("CatalogRef.ProductsAndServicesCharacteristics"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("Characteristic", TypeDescription);
	
	// VATRates.
	Array.Add(Type("CatalogRef.VATRates"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("VATRate", TypeDescription);	
	
	// MeasurementUnit.
	Array.Add(Type("CatalogRef.UOM"));
	Array.Add(Type("CatalogRef.UOMClassifier"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("MeasurementUnit", TypeDescription);	
	
	// Ratio.
	Array.Add(Type("Number"));
	TypeDescription = New TypeDescription(Array, ,);
	Array.Clear();
	
	ProductsAndServicesTable.Columns.Add("Factor", TypeDescription);
	
	For Each TSRow IN DocumentTabularSection Do
		
		NewRow = ProductsAndServicesTable.Add();
		NewRow.ProductsAndServices	 = TSRow.ProductsAndServices;
		NewRow.Characteristic	 = TSRow.Characteristic;
		NewRow.MeasurementUnit = TSRow.MeasurementUnit;
		NewRow.VATRate		 = TSRow.VATRate;
		
		If TypeOf(TSRow.MeasurementUnit) = Type("CatalogRef.UOMClassifier") Then
			NewRow.Factor = 1;
		Else
			NewRow.Factor = TSRow.MeasurementUnit.Factor;
		EndIf;
		
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	ProductsAndServicesTable.ProductsAndServices,
	|	ProductsAndServicesTable.Characteristic,
	|	ProductsAndServicesTable.MeasurementUnit,
	|	ProductsAndServicesTable.VATRate,
	|	ProductsAndServicesTable.Factor
	|INTO TemporaryProductsAndServicesTable
	|FROM
	|	&ProductsAndServicesTable AS ProductsAndServicesTable";
	
	Query.SetParameter("ProductsAndServicesTable", ProductsAndServicesTable);
	Query.Execute();
	
	// 2. We will fill prices.
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = 
	"SELECT
	|	ProductsAndServicesTable.ProductsAndServices AS ProductsAndServices,
	|	ProductsAndServicesTable.Characteristic AS Characteristic,
	|	ProductsAndServicesTable.MeasurementUnit AS MeasurementUnit,
	|	ProductsAndServicesTable.VATRate AS VATRate,
	|	CounterpartyProductsAndServicesPricesSliceLast.CounterpartyPriceKind.PriceCurrency AS ProductsAndServicesPricesCurrency,
	|	CounterpartyProductsAndServicesPricesSliceLast.CounterpartyPriceKind.PriceIncludesVAT AS PriceIncludesVAT,
	|	ISNULL(CounterpartyProductsAndServicesPricesSliceLast.Price * RateCurrencyTypePrices.ExchangeRate * DocumentCurrencyRate.Multiplicity / (DocumentCurrencyRate.ExchangeRate * RateCurrencyTypePrices.Multiplicity) * ISNULL(ProductsAndServicesTable.Factor, 1) / ISNULL(CounterpartyProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1), 0) AS Price
	|FROM
	|	TemporaryProductsAndServicesTable AS ProductsAndServicesTable
	|		LEFT JOIN InformationRegister.CounterpartyProductsAndServicesPrices.SliceLast(&ProcessingDate, CounterpartyPriceKind = &CounterpartyPriceKind) AS CounterpartyProductsAndServicesPricesSliceLast
	|		ON ProductsAndServicesTable.ProductsAndServices = CounterpartyProductsAndServicesPricesSliceLast.ProductsAndServices
	|			AND ProductsAndServicesTable.Characteristic = CounterpartyProductsAndServicesPricesSliceLast.Characteristic
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, ) AS RateCurrencyTypePrices
	|		ON (CounterpartyProductsAndServicesPricesSliceLast.CounterpartyPriceKind.PriceCurrency = RateCurrencyTypePrices.Currency),
	|	InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, Currency = &DocumentCurrency) AS DocumentCurrencyRate
	|WHERE
	|	CounterpartyProductsAndServicesPricesSliceLast.Actuality";
		
	Query.SetParameter("ProcessingDate", 		DataStructure.Date);
	Query.SetParameter("CounterpartyPriceKind",	DataStructure.CounterpartyPriceKind);
	Query.SetParameter("DocumentCurrency", 	DataStructure.DocumentCurrency);
	
	PricesTable = Query.Execute().Unload();
	For Each TabularSectionRow IN DocumentTabularSection Do
		
		SearchStructure = New Structure;
		SearchStructure.Insert("ProductsAndServices",	 TabularSectionRow.ProductsAndServices);
		SearchStructure.Insert("Characteristic",	 TabularSectionRow.Characteristic);
		SearchStructure.Insert("MeasurementUnit", TabularSectionRow.MeasurementUnit);
		SearchStructure.Insert("VATRate",		 TabularSectionRow.VATRate);
		
		SearchResult = PricesTable.FindRows(SearchStructure);
		If SearchResult.Count() > 0 Then
			
			Price = SearchResult[0].Price;
			If Price = 0 Then
				TabularSectionRow.Price = Price;
			Else
				
				// Consider: amount includes VAT.
				If (DataStructure.AmountIncludesVAT AND Not SearchResult[0].PriceIncludesVAT) 
					OR (NOT DataStructure.AmountIncludesVAT AND SearchResult[0].PriceIncludesVAT) Then
					Price = RecalculateAmountOnVATFlagsChange(Price, DataStructure.AmountIncludesVAT, TabularSectionRow.VATRate);
				EndIf;
				
				TabularSectionRow.Price = Price;
				
			EndIf;
		EndIf;
		
	EndDo;
	
	TempTablesManager.Close();
	
EndProcedure // GetTabularSectionPricesByPriceKind()

// Recalculates document after changes in "Prices and currency" form.
//
// Returns:
//  Number        - Obtained price of products and services by the pricelist.
//
Function GetProductsAndServicesPriceByPriceKind(DataStructure) Export
	
	If DataStructure.PriceKind.CalculatesDynamically Then
		DynamicPriceKind = True;
		PriceKindParameter = DataStructure.PriceKind.PricesBaseKind;
		Markup = DataStructure.PriceKind.Percent;
		RoundingOrder = DataStructure.PriceKind.RoundingOrder;
		RoundUp = DataStructure.PriceKind.RoundUp;
	Else
		DynamicPriceKind = False;
		PriceKindParameter = DataStructure.PriceKind;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsAndServicesPricesSliceLast.PriceKind.PriceCurrency AS ProductsAndServicesPricesCurrency,
	|	ProductsAndServicesPricesSliceLast.PriceKind.PriceIncludesVAT AS PriceIncludesVAT,
	|	ProductsAndServicesPricesSliceLast.PriceKind.RoundingOrder AS RoundingOrder,
	|	ProductsAndServicesPricesSliceLast.PriceKind.RoundUp AS RoundUp,
	|	ISNULL(ProductsAndServicesPricesSliceLast.Price * RateCurrencyTypePrices.ExchangeRate * DocumentCurrencyRate.Multiplicity / (DocumentCurrencyRate.ExchangeRate * RateCurrencyTypePrices.Multiplicity) * ISNULL(&Factor, 1) / ISNULL(ProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1), 0) AS Price
	|FROM
	|	InformationRegister.ProductsAndServicesPrices.SliceLast(
	|			&ProcessingDate,
	|			ProductsAndServices = &ProductsAndServices
	|				AND Characteristic = &Characteristic
	|				AND PriceKind = &PriceKind) AS ProductsAndServicesPricesSliceLast
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, ) AS RateCurrencyTypePrices
	|		ON ProductsAndServicesPricesSliceLast.PriceKind.PriceCurrency = RateCurrencyTypePrices.Currency,
	|	InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, Currency = &DocumentCurrency) AS DocumentCurrencyRate
	|WHERE
	|	ProductsAndServicesPricesSliceLast.Actuality";
	
	Query.SetParameter("ProcessingDate",	 DataStructure.ProcessingDate);
	Query.SetParameter("ProductsAndServices",	 DataStructure.ProductsAndServices);
	Query.SetParameter("Characteristic",  DataStructure.Characteristic);
	Query.SetParameter("Factor",	 DataStructure.Factor);
	Query.SetParameter("DocumentCurrency", DataStructure.DocumentCurrency);
	Query.SetParameter("PriceKind",			 PriceKindParameter);
	
	Selection = Query.Execute().Select();
	
	Price = 0;
	While Selection.Next() Do
		
		Price = Selection.Price;
		
		// Dynamically calculate the price
		If DynamicPriceKind Then
			
			Price = Price * (1 + Markup / 100);
			
		Else
			
			RoundingOrder = Selection.RoundingOrder;
			RoundUp = Selection.RoundUp;
			
		EndIf;
		
		If DataStructure.Property("AmountIncludesVAT")
			AND ((DataStructure.AmountIncludesVAT AND Not Selection.PriceIncludesVAT)
			OR (NOT DataStructure.AmountIncludesVAT AND Selection.PriceIncludesVAT)) Then
			Price = RecalculateAmountOnVATFlagsChange(Price, DataStructure.AmountIncludesVAT, DataStructure.VATRate);
		EndIf;
		
		Price = RoundPrice(Price, RoundingOrder, RoundUp);
		
	EndDo;
	
	Return Price;
	
EndFunction // GetProductsAndServicesPriceByPriceKind()

// Recalculates document after changes in "Prices and currency" form.
//
// Returns:
//  Number        - Obtained price of products and services by the pricelist.
//
Function GetPriceProductsAndServicesByCounterpartyPriceKind(DataStructure) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CounterpartyProductsAndServicesPricesSliceLast.CounterpartyPriceKind.PriceCurrency AS ProductsAndServicesPricesCurrency,
	|	CounterpartyProductsAndServicesPricesSliceLast.CounterpartyPriceKind.PriceIncludesVAT AS PriceIncludesVAT,
	|	ISNULL(CounterpartyProductsAndServicesPricesSliceLast.Price * RateCurrencyTypePrices.ExchangeRate * DocumentCurrencyRate.Multiplicity / (DocumentCurrencyRate.ExchangeRate * RateCurrencyTypePrices.Multiplicity) * ISNULL(&Factor, 1) / ISNULL(CounterpartyProductsAndServicesPricesSliceLast.MeasurementUnit.Factor, 1), 0) AS Price
	|FROM
	|	InformationRegister.CounterpartyProductsAndServicesPrices.SliceLast(
	|			&ProcessingDate,
	|			ProductsAndServices = &ProductsAndServices
	|				AND Characteristic = &Characteristic
	|				AND CounterpartyPriceKind = &CounterpartyPriceKind) AS CounterpartyProductsAndServicesPricesSliceLast
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, ) AS RateCurrencyTypePrices
	|		ON CounterpartyProductsAndServicesPricesSliceLast.CounterpartyPriceKind.PriceCurrency = RateCurrencyTypePrices.Currency,
	|	InformationRegister.CurrencyRates.SliceLast(&ProcessingDate, Currency = &DocumentCurrency) AS DocumentCurrencyRate
	|WHERE
	|	CounterpartyProductsAndServicesPricesSliceLast.Actuality";
	
	Query.SetParameter("ProcessingDate",	 	DataStructure.ProcessingDate);
	Query.SetParameter("ProductsAndServices",	 	DataStructure.ProductsAndServices);
	Query.SetParameter("Characteristic",  	DataStructure.Characteristic);
	Query.SetParameter("Factor",	 	DataStructure.Factor);
	Query.SetParameter("DocumentCurrency", 	DataStructure.DocumentCurrency);
	Query.SetParameter("CounterpartyPriceKind",	DataStructure.CounterpartyPriceKind);
	
	Selection = Query.Execute().Select();
	
	Price = 0;
	While Selection.Next() Do
		
		Price = Selection.Price;
		
		// Consider: amount includes VAT.
		If (DataStructure.AmountIncludesVAT AND Not Selection.PriceIncludesVAT)
		 OR (NOT DataStructure.AmountIncludesVAT AND Selection.PriceIncludesVAT) Then
			Price = RecalculateAmountOnVATFlagsChange(Price, DataStructure.AmountIncludesVAT, DataStructure.VATRate);
		EndIf;
		
	EndDo;
	
	Return Price;
	
EndFunction // GetProductsAndServicesPriceByPriceKind()

// Get working time standard.
//
// Returns:
//  Number        - Obtained price of products and services by the pricelist.
//
Function GetWorkTimeRate(DataStructure) Export
	
	Query = New Query("SELECT
						  |	SliceLastTimeStandards.Norm
						  |FROM
						  |	InformationRegister.WorkTimeStandards.SliceLast(
						  |			&ProcessingDate,
						  |			ProductsAndServices = &ProductsAndServices
						  |				AND Characteristic = &Characteristic
						  |				AND (NOT ProductsAndServices.FixedCost)) AS SliceLastTimeStandards");	
						  
	Query.SetParameter("ProductsAndServices", DataStructure.ProductsAndServices);
	Query.SetParameter("Characteristic", DataStructure.Characteristic);
	Query.SetParameter("ProcessingDate", DataStructure.ProcessingDate);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Return Selection.Norm;		
	EndDo;
	
	Return 1;
	
EndFunction // GetProductsAndServicesPriceByPriceKind()

// Receives data set: Amount, VAT amount.
//
Function GetTabularSectionRowSum(DataStructure) Export
	
	DataStructure.Amount = DataStructure.Quantity * DataStructure.Price;
	
	If DataStructure.Property("DiscountMarkupPercent") OR DataStructure.Property("DiscountCard") Then
		
		If DataStructure.DiscountMarkupPercent = 100 Then
			
			DataStructure.Amount = 0;
			
		ElsIf DataStructure.DiscountMarkupPercent <> 0 Then
			
			DataStructure.Amount = DataStructure.Amount * (1 - DataStructure.DiscountMarkupPercent / 100);
			
		EndIf;
		
	EndIf;
	
	If DataStructure.Property("VATAmount") Then
		
		VATRate = SmallBusinessReUse.GetVATRateValue(DataStructure.VATRate);
		DataStructure.VATAmount = ?(DataStructure.AmountIncludesVAT, DataStructure.Amount - (DataStructure.Amount) / ((VATRate + 100) / 100), DataStructure.Amount * VATRate / 100);
		DataStructure.Total = DataStructure.Amount + ?(DataStructure.AmountIncludesVAT, 0, DataStructure.VATAmount);
		
	EndIf;
	
	Return DataStructure;
	
EndFunction // GetTabularSectionRowAmount()

#Region DiscountCards

// Function returns a structure with the start date and accumulation period
// end by discount card and also the period text presentation.
//
Function GetProgressiveDiscountsCalculationPeriodByDiscountCard(DiscountDate, DiscountCard) Export

	If Not ValueIsFilled(DiscountDate) Then
		DiscountDate = CurrentDate();
	EndIf;
	
	PeriodPresentation = "";
	If DiscountCard.Owner.PeriodKind = Enums.PeriodKindsForProgressiveDiscounts.EntirePeriod Then
		BeginOfPeriod = '00010101';
		EndOfPeriod = '00010101';
		PeriodPresentation = "for all time";
	ElsIf DiscountCard.Owner.PeriodKind = Enums.PeriodKindsForProgressiveDiscounts.Current Then
		If DiscountCard.Owner.Periodicity = Enums.Periodicity.Year Then
			BeginOfPeriod = BegOfYear(DiscountDate);
			PeriodPresentation = "for the current year";
		ElsIf DiscountCard.Owner.Periodicity = Enums.Periodicity.Quarter Then
			BeginOfPeriod = BegOfQuarter(DiscountDate);
			PeriodPresentation = "for the current quarter";
		ElsIf DiscountCard.Owner.Periodicity = Enums.Periodicity.Month Then
			BeginOfPeriod = BegOfMonth(DiscountDate);
			PeriodPresentation = "for the current month";
		EndIf;
		EndOfPeriod = EndOfDay(DiscountDate);
	ElsIf DiscountCard.Owner.PeriodKind = Enums.PeriodKindsForProgressiveDiscounts.Past Then
		If DiscountCard.Owner.Periodicity = Enums.Periodicity.Year Then
			DatePrePeriod = AddMonth(DiscountDate, -12);
			BeginOfPeriod = BegOfYear(DatePrePeriod);
			EndOfPeriod = EndOfYear(DatePrePeriod);
			PeriodPresentation = "for the past year";
		ElsIf DiscountCard.Owner.Periodicity = Enums.Periodicity.Quarter Then
			DatePrePeriod = AddMonth(DiscountDate, -3);
			BeginOfPeriod = BegOfQuarter(DatePrePeriod);
			EndOfPeriod = EndOfQuarter(DatePrePeriod);
			PeriodPresentation = "for the past year quarter";
		ElsIf DiscountCard.Owner.Periodicity = Enums.Periodicity.Month Then
			DatePrePeriod = AddMonth(DiscountDate, -1);
			BeginOfPeriod = BegOfMonth(DatePrePeriod);
			EndOfPeriod = EndOfMonth(DatePrePeriod);
			PeriodPresentation = "for the past month";
		EndIf;
	ElsIf DiscountCard.Owner.PeriodKind = Enums.PeriodKindsForProgressiveDiscounts.Last Then
		If DiscountCard.Owner.Periodicity = Enums.Periodicity.Year Then
			DatePrePeriod = AddMonth(DiscountDate, -12);
			PeriodPresentation = "for the past year";
		ElsIf DiscountCard.Owner.Periodicity = Enums.Periodicity.Quarter Then
			DatePrePeriod = AddMonth(DiscountDate, -3);
			PeriodPresentation = "for the last quarter";
		ElsIf DiscountCard.Owner.Periodicity = Enums.Periodicity.Month Then
			DatePrePeriod = AddMonth(DiscountDate, -1);
			PeriodPresentation = "for the last month";
		EndIf;		
		BeginOfPeriod = BegOfDay(DatePrePeriod);
		EndOfPeriod = BegOfDay(DiscountDate) - 1; // Previous day end.
	Else
		BeginOfPeriod = '00010101';
		EndOfPeriod = '00010101';
		PeriodPresentation = "";
	EndIf;
	
	Return New Structure("BeginOfPeriod, EndOfPeriod, PeriodPresentation", BeginOfPeriod, EndOfPeriod, PeriodPresentation);

EndFunction // GetProgressiveDiscountsCalculationPeriodByDiscountCard()

// Returns the discount percent by discount card.
//
// Parameters:
//  DiscountCard - CatalogRef.DiscountCards - Ref on discount card.
//
// Returns: 
//   Number - discount percent.
//
Function CalculateDiscountPercentByDiscountCard(Val DiscountDate, DiscountCard, AdditionalParameters = Undefined) Export
	
	Var BeginOfPeriod, EndOfPeriod;
	
	If Not ValueIsFilled(DiscountDate) Then
		DiscountDate = CurrentDate();
	EndIf;
	
	If DiscountCard.Owner.DiscountKindForDiscountCards = Enums.DiscountKindsForDiscountCards.FixedDiscount Then
		
		If AdditionalParameters <> Undefined AND AdditionalParameters.GetSalesAmount Then
			AccumulationPeriod = GetProgressiveDiscountsCalculationPeriodByDiscountCard(DiscountDate, DiscountCard.Ref);

			AdditionalParameters.Insert("PeriodPresentation", AccumulationPeriod.PeriodPresentation);
			
			Query = New Query("SELECT
			                      |	ISNULL(SUM(RegSales.AmountTurnover), 0) AS AmountTurnover
			                      |FROM
			                      |	AccumulationRegister.SalesByDiscountCards.Turnovers(&DateBeg, &DateEnd, , DiscountCard = &DiscountCard) AS RegSales");

			Query.SetParameter("DateBeg", AccumulationPeriod.BeginOfPeriod);
			Query.SetParameter("DateEnd", AccumulationPeriod.EndOfPeriod);
			Query.SetParameter("DiscountCard", DiscountCard.Ref);
	        
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				AdditionalParameters.Amount = Selection.AmountTurnover;
			Else
				AdditionalParameters.Amount = 0;
			EndIf;		
		
		EndIf;
		
		Return DiscountCard.Owner.Discount;
		
	Else
		
		AccumulationPeriod = GetProgressiveDiscountsCalculationPeriodByDiscountCard(DiscountDate, DiscountCard.Ref);
		
		Query = New Query("SELECT ALLOWED
		                      |	Thresholds.Discount AS Discount,
		                      |	Thresholds.LowerBound AS LowerBound
		                      |INTO TU_Thresholds
		                      |FROM
		                      |	Catalog.DiscountCardKinds.ProgressiveDiscountLimits AS Thresholds
		                      |WHERE
		                      |	Thresholds.Ref = &KindDiscountCard
		                      |;
		                      |
		                      |////////////////////////////////////////////////////////////////////////////////
		                      |SELECT ALLOWED
		                      |	RegThresholds.Discount AS Discount
		                      |FROM
		                      |	(SELECT
		                      |		ISNULL(SUM(RegSales.AmountTurnover), 0) AS AmountTurnover
		                      |	FROM
		                      |		AccumulationRegister.SalesByDiscountCards.Turnovers(&DateBeg, &DateEnd, , DiscountCard = &DiscountCard) AS RegSales) AS RegSales
		                      |		INNER JOIN (SELECT
		                      |			Thresholds.LowerBound AS LowerBound,
		                      |			Thresholds.Discount AS Discount
		                      |		FROM
		                      |			TU_Thresholds AS Thresholds) AS RegThresholds
		                      |		ON (RegThresholds.LowerBound <= RegSales.AmountTurnover)
		                      |		INNER JOIN (SELECT
		                      |			MAX(RegThresholds.LowerBound) AS LowerBound
		                      |		FROM
		                      |			(SELECT
		                      |				ISNULL(SUM(RegSales.AmountTurnover), 0) AS AmountTurnover
		                      |			FROM
		                      |				AccumulationRegister.SalesByDiscountCards.Turnovers(&DateBeg, &DateEnd, , DiscountCard = &DiscountCard) AS RegSales) AS RegSales
		                      |				INNER JOIN (SELECT
		                      |					Thresholds.LowerBound AS LowerBound
		                      |				FROM
		                      |					TU_Thresholds AS Thresholds) AS RegThresholds
		                      |				ON (RegThresholds.LowerBound <= RegSales.AmountTurnover)) AS RegMaxThresholds
		                      |		ON (RegMaxThresholds.LowerBound = RegThresholds.LowerBound)");

		Query.SetParameter("DateBeg", AccumulationPeriod.BeginOfPeriod);
		Query.SetParameter("DateEnd", AccumulationPeriod.EndOfPeriod);
		Query.SetParameter("DiscountCard", DiscountCard.Ref);
        Query.SetParameter("KindDiscountCard", DiscountCard.Owner);

		If AdditionalParameters <> Undefined AND AdditionalParameters.GetSalesAmount Then
			AdditionalParameters.Insert("PeriodPresentation", AccumulationPeriod.PeriodPresentation);
			
			Query.Text = Query.Text + ";
			                              |////////////////////////////////////////////////////////////////////////////////
			                              |SELECT
			                              |	SalesByDiscountCardsTurnovers.AmountTurnover
			                              |FROM
			                              |	AccumulationRegister.SalesByDiscountCards.Turnovers(&DateBeg, &DateEnd, , DiscountCard = &DiscountCard) AS SalesByDiscountCardsTurnovers";
			MResults = Query.ExecuteBatch();
			
			Selection = MResults[1].Select();
			If Selection.Next() Then
				CumulativeDiscountPercent = Selection.Discount;
			Else
				CumulativeDiscountPercent = 0;
			EndIf;		
			
			SelectionByAmountOfSales = MResults[2].Select();
			If SelectionByAmountOfSales.Next() Then
				AdditionalParameters.Amount = SelectionByAmountOfSales.AmountTurnover;
			Else
				AdditionalParameters.Amount = 0;
			EndIf;
			
			Return CumulativeDiscountPercent;

		Else
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				CumulativeDiscountPercent = Selection.Discount;
			Else
				CumulativeDiscountPercent = 0;
			EndIf;		
				
			Return CumulativeDiscountPercent;
		EndIf;
		
	EndIf;
	
EndFunction

// Returns the discount percent by the discount / markup kind.
//
// Parameters:
//  DataStructure - Structure - Structure of attributes required during recalculation
//
// Returns: 
//   Number - discount percent.
//
Function GetDiscountPercentByDiscountMarkupKind(DiscountMarkupKind) Export
	
	Return DiscountMarkupKind.Percent;
	
EndFunction

#EndRegion

// Fills the connection key of the
//document table or data processor
Procedure FillConnectionKey(TabularSection, TabularSectionRow, ConnectionAttributeName, TempConnectionKey = 0) Export
	
	If NOT ValueIsFilled(TabularSectionRow[ConnectionAttributeName]) Then
		If TempConnectionKey = 0 Then
			For Each TSRow In TabularSection Do
				If TempConnectionKey < TSRow[ConnectionAttributeName] Then
					TempConnectionKey = TSRow[ConnectionAttributeName];
				EndIf;
			EndDo;
		EndIf;
		TabularSectionRow[ConnectionAttributeName] = TempConnectionKey + 1;
	EndIf;
	
EndProcedure

// Удаляет строки по ключу связи в таблице документа или обработки
//
Procedure DeleteConnectionKeyRows(TabularSection, TabularSectionRow, ConnectionAttributeName = "ConnectionKey") Экспорт
	
	If TabularSectionRow = Неопределено Then
		Return;
	EndIf;
	
	SearchStructure = Новый Структура;
	SearchStructure.Insert(ConnectionAttributeName, TabularSectionRow[ConnectionAttributeName]);
	
	DeletedRows = TabularSection.НайтиСтроки(SearchStructure);
	Для каждого TableRow Из DeletedRows Цикл
		
		TabularSection.Удалить(TableRow);
		
	КонецЦикла;
	
EndProcedure

// Возвращает массив найденных строк по заданному ключу связи
Function ConnectionKeyRows(TabularSection, ConnectionKey, ConnectionAttributeName = "ConnectionKey") Экспорт
	
	СтруктураОтбора = Новый Структура;
	СтруктураОтбора.Insert(ConnectionAttributeName, ConnectionKey);
	Return TabularSection.НайтиСтроки(СтруктураОтбора);
	
EndFunction

// Процедура создает новый ключ связи для таблиц.
//
// Параметры:
//  ФормаДокумента - УправляемаяФорма, содержит форму документа, реквизиты
//                 которой обрабатываются процедурой.
//
Функция NewConnectionKey(DocumentForm) Экспорт

	ValueList = Новый СписокЗначений;
	
	TabularSection = DocumentForm.Object[DocumentForm.TabularSectionName];
	Для каждого TSRow Из TabularSection Цикл
        ValueList.Add(TSRow.ConnectionKey);
	КонецЦикла;

    If ValueList.Count() = 0 Then
		ConnectionKey = 1;
	Иначе
		ValueList.SortByValue();
		ConnectionKey = ValueList.Get(ValueList.Count() - 1).Value + 1;
	EndIf;

	Return ConnectionKey;

КонецФункции //  СоздатьНовыйКлючСвязи()

/////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS GENERATING MESSAGES TEXTS ON POSTING ERRORS

// Generates petty cash presentation row.
//
// Parameters:
//  ProductsAndServicesPresentation - String - ProductsAndServices presentation.
//  ProductAccountingKindPresentation - String - kind of ProductsAndServices presentation.
//  CharacteristicPresentation - String - characteristic presentation.
//  SeriesPresentation - String - series presentation.
//  StagePresentation - String - call presentation.
//
// Returns:
//  String - ref with the products and services presentation.
//
Function CashBankAccountPresentation(BankAccountCashPresentation,
										   CashAssetsTypeRepresentation = "",
										   CurrencyPresentation = "") Export
	
	PresentationString = TrimAll(BankAccountCashPresentation);
	
	If ValueIsFilled(CashAssetsTypeRepresentation)Then
		PresentationString = PresentationString + ", " + TrimAll(CashAssetsTypeRepresentation);
	EndIf;
	
	If ValueIsFilled(CurrencyPresentation)Then
		PresentationString = PresentationString + ", " + TrimAll(CurrencyPresentation);
	EndIf;
	
	Return PresentationString;
	
EndFunction // ProductsAndServicesPresentation()

// Generates a string of products and services presentation considering characteristics and series.
//
// Parameters:
//  ProductsAndServicesPresentation - String - ProductsAndServices presentation.
//  CharacteristicPresentation - String - characteristic presentation.
//  BatchPresentation - String - batch presentation.
//
// Returns:
//  String - ref with the products and services presentation.
//
Function PresentationOfProductsAndServices(ProductsAndServicesPresentation,
	                              CharacteristicPresentation  = "",
	                              BatchPresentation          = "",
								  CustomerOrderPresentation = "") Export
	
	PresentationString = TrimAll(ProductsAndServicesPresentation);
	
	If ValueIsFilled(CharacteristicPresentation)Then
		PresentationString = PresentationString + " / " + TrimAll(CharacteristicPresentation);
	EndIf;
	
	If  ValueIsFilled(BatchPresentation) Then
		PresentationString = PresentationString + " / " + TrimAll(BatchPresentation);
	EndIf;
	
	If ValueIsFilled(CustomerOrderPresentation) Then
		PresentationString = PresentationString + " / " + TrimAll(CustomerOrderPresentation);
	EndIf;
	
	Return PresentationString;
	
EndFunction // ProductsAndServicesPresentation()

// Generates counterparty presentation row.
//
// Parameters:
//  ProductsAndServicesPresentation - String - ProductsAndServices presentation.
//  ProductAccountingKindPresentation - String - kind of ProductsAndServices presentation.
//  CharacteristicPresentation - String - characteristic presentation.
//  SeriesPresentation - String - series presentation.
//  StagePresentation - String - call presentation.
//
// Returns:
//  String - ref with the products and services presentation.
//
Function CounterpartyPresentation(CounterpartyPresentation,
	                             ContractPresentation = "",
	                             DocumentPresentation = "",
	                             OrderPresentation = "",
	                             CalculationTypesPresentation = "") Export
	
	PresentationString = TrimAll(CounterpartyPresentation);
	
	If ValueIsFilled(ContractPresentation)Then
		PresentationString = PresentationString + ", " + TrimAll(ContractPresentation);
	EndIf;
	
	If ValueIsFilled(DocumentPresentation)Then
		PresentationString = PresentationString + ", " + TrimAll(DocumentPresentation);
	EndIf;
	
	If ValueIsFilled(OrderPresentation)Then
		PresentationString = PresentationString + ", " + TrimAll(OrderPresentation);
	EndIf;
	
	If ValueIsFilled(CalculationTypesPresentation)Then
		PresentationString = PresentationString + ", " + TrimAll(CalculationTypesPresentation);
	EndIf;
	
	Return PresentationString;
	
EndFunction // CounterpartyPresentation()

// Generates a structural unit presentation row.
//
// Parameters:
//  ProductsAndServicesPresentation - String - ProductsAndServices presentation.
//  ProductAccountingKindPresentation - String - kind of ProductsAndServices presentation.
//  CharacteristicPresentation - String - characteristic presentation.
//  SeriesPresentation - String - series presentation.
//  StagePresentation - String - call presentation.
//
// Returns:
//  String - ref with the products and services presentation.
//
Function PresentationOfStructuralUnit(StructuralUnitPresentation,
	                             PresentationCell = "") Export
	
	PresentationString = TrimAll(StructuralUnitPresentation);
	
	If ValueIsFilled(PresentationCell) Then
		PresentationString = PresentationString + " (" + PresentationCell + ")";
	EndIf;
	
	Return PresentationString;
	
EndFunction // StructuralUnitPresentation()

// Generates petty cash presentation row.
//
// Parameters:
//  ProductsAndServicesPresentation - String - ProductsAndServices presentation.
//  ProductAccountingKindPresentation - String - kind of ProductsAndServices presentation.
//  CharacteristicPresentation - String - characteristic presentation.
//  SeriesPresentation - String - series presentation.
//  StagePresentation - String - call presentation.
//
// Returns:
//  String - ref with the products and services presentation.
//
Function PresentationOfAccountablePerson(AdvanceHolderPresentation,
	                       			  CurrencyPresentation = "",
									  DocumentPresentation = "") Export
	
	PresentationString = TrimAll(AdvanceHolderPresentation);
	
	If ValueIsFilled(CurrencyPresentation)Then
		PresentationString = PresentationString + ", " + TrimAll(CurrencyPresentation);
	EndIf;
	
	If ValueIsFilled(DocumentPresentation)Then
		PresentationString = PresentationString + ", " + TrimAll(DocumentPresentation);
	EndIf;    
	
	Return PresentationString;
	
EndFunction // ProductsAndServicesPresentation()

// The function returns individual passport details
// as a string used in print forms.
//
// Parameters
//  DataStructure - Structure - ref to Ind and date
//                 
// Returns:
//   Row      - String containing passport data
//
Function GetPassportDataAsString(DataStructure) Export

	If Not ValueIsFilled(DataStructure.Ind) Then
		Return NStr("en='There is no data on the identity card.';ru='Отсутствуют данные об удостоверении личности.';vi='Không có dữ liệu về giấy tờ tùy thân.'");
	EndIf; 
	
	Query = New Query("SELECT
	                      |	IndividualsDocumentsSliceLast.DocumentKind,
	                      |	IndividualsDocumentsSliceLast.Series,
	                      |	IndividualsDocumentsSliceLast.Number,
	                      |	IndividualsDocumentsSliceLast.WhoIssued,
	                      |	IndividualsDocumentsSliceLast.DepartmentCode,
	                      |	IndividualsDocumentsSliceLast.IssueDate AS IssueDate
	                      |FROM
	                      |	InformationRegister.IndividualsDocuments.SliceLast(
	                      |			&ToDate,
	                      |			Ind = &Ind
	                      |				AND IsIdentityDocument) AS IndividualsDocumentsSliceLast");
	
	Query.SetParameter("ToDate", DataStructure.Date);
	Query.SetParameter("Ind", DataStructure.Ind);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return NStr("en='There is no data on the identity card.';ru='Отсутствуют данные об удостоверении личности.';vi='Không có dữ liệu về giấy tờ tùy thân.'");
	Else
		PassportData = QueryResult.Unload()[0];
		DocumentKind       = PassportData.DocumentKind;
		Series              = PassportData.Series;
		Number              = PassportData.Number;
		IssueDate         = PassportData.IssueDate;
		WhoIssued           = PassportData.WhoIssued;
		NumberUnits = PassportData.DepartmentCode;
		
		If Not (NOT ValueIsFilled(IssueDate)
			AND Not ValueIsFilled(DocumentKind)
			AND Not ValueIsFilled(Series + Number + WhoIssued + NumberUnits)) Then

			PersonalDataList = NStr("en='%DocumentKind% Series: %Series%, No. %Number%, Issued: %DateIssued%, %IssuedBy%; department No. %DepartmentNumber%';ru='%DocumentKind% Серия: %Series%, № %Number%, Выдан: %IssueDate% года, %WhoIssued%; № подр. %NumberUnits%';vi='%DocumentKind% Sê-ri: %Series%, № %Number%, Được cấp: %IssueDate%, %WhoIssued%; số bộ phận. %NumberUnits%'");
			
			PersonalDataList = StrReplace(PersonalDataList, "%DocumentKind%", ?(DocumentKind.IsEmpty(),"","" + DocumentKind + ", "));
			PersonalDataList = StrReplace(PersonalDataList, "%Series%", Series);
			PersonalDataList = StrReplace(PersonalDataList, "%Number%", Number);
			PersonalDataList = StrReplace(PersonalDataList, "%IssueDate%", Format(IssueDate,"DLF=DD"));
			PersonalDataList = StrReplace(PersonalDataList, "%WhoIssued%", WhoIssued);
			PersonalDataList = StrReplace(PersonalDataList, "%NumberUnits%", NumberUnits);
			
			Return PersonalDataList;

		Else
			Return NStr("en='There is no data on the identity card.';ru='Отсутствуют данные об удостоверении личности.';vi='Không có dữ liệu về giấy tờ tùy thân.'");
		EndIf;
	EndIf;

EndFunction // GetPassportDataAsString()

// Function returns structural units type presentation.
//
Function GetStructuralUnitTypePresentation(StructuralUnitType)
	
	If StructuralUnitType = Enums.StructuralUnitsTypes.Department Then
		StructuralUnitTypePresentation = NStr("en = 'to department'; vi = 'đến bộ phận:'");
	ElsIf StructuralUnitType = Enums.StructuralUnitsTypes.Retail
		OR StructuralUnitType = Enums.StructuralUnitsTypes.RetailAccrualAccounting Then
		StructuralUnitTypePresentation = NStr("en = 'in retail warehouse'; vi = 'trong kho bán lẻ:'");
	Else
		StructuralUnitTypePresentation = NStr("en='at warehouse';vi='trong kho';");
	EndIf;
	
	Return StructuralUnitTypePresentation
	
EndFunction // GetStructuralUnitTypePresentation()

///////////////////////////////////////////////////////////////////////////////////////////////////
// PROCEDURE OF POSTING ERRORS MESSAGES ISSUING.

// The procedure informs of errors that occurred when posting by register Inventory in warehouses.
//
Procedure ShowMessageAboutPostingToInventoryInWarehousesRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleTemplate = ErrorTitle + Chars.LF + NStr("en='There is not enough inventory %StructuralUnitType% %StructuralUnitPresentation%';ru='Не хватает запасов %StructuralUnitType% %StructuralUnitPresentation%';vi='Không đủ vật tư %StructuralUnitType% %StructuralUnitPresentation%'");
	
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %Quantity% %MeasurementUnit%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %Quantity% %MeasurementUnit%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %Quantity% %MeasurementUnit%'");
		
	TitleInDetailsShow = True;
	AccountingBySeveralWarehouses = Constants.FunctionalOptionAccountingByMultipleWarehouses.Get();
	AccountingBySeveralDepartments = Constants.FunctionalOptionAccountingByMultipleDepartments.Get();
	While RecordsSelection.Next() Do
		
		If TitleInDetailsShow Then
			If (NOT AccountingBySeveralWarehouses AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse)
				OR (NOT AccountingBySeveralDepartments AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Department)Then
				PresentationOfStructuralUnit = "";
			Else
				PresentationOfStructuralUnit = PresentationOfStructuralUnit(RecordsSelection.StructuralUnitPresentation, RecordsSelection.PresentationCell);
			EndIf;
			MessageTitleText = StrReplace(MessageTitleTemplate, "%StructuralUnitPresentation%", PresentationOfStructuralUnit);
			MessageTitleText = StrReplace(MessageTitleText, "%StructuralUnitType%", GetStructuralUnitTypePresentation(RecordsSelection.StructuralUnitType));
			ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
			TitleInDetailsShow = False;
		EndIf;
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceInventoryInWarehouses));
		MessageText = StrReplace(MessageText, "%Quantity%", String(-RecordsSelection.QuantityBalanceInventoryInWarehouses));
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ReportErrorsPostingByRegisterInventoryInWarehouses()

// Procedure reports errors occurred while posting by the
// Inventory on warehouses register for the structural units list.
//
Procedure ShowMessageAboutPostingToInventoryInWarehousesRegisterErrorsAsList(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Insufficient inventory';ru='Не хватает запасов';vi='Không đủ vật tư'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"%StructuralUnitType% %StructuralUnitPresentation%"
"balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %Quantity% %MeasurementUnit%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"%StructuralUnitType% %StructuralUnitPresentation%"
"остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %Quantity% %MeasurementUnit%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"%StructuralUnitType% %StructuralUnitPresentation%"
"số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %Quantity% %MeasurementUnit%'");
		
	AccountingBySeveralWarehouses = Constants.FunctionalOptionAccountingByMultipleWarehouses.Get();
	AccountingBySeveralDepartments = Constants.FunctionalOptionAccountingByMultipleDepartments.Get();
	While RecordsSelection.Next() Do
		
		If (NOT AccountingBySeveralWarehouses AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse)
			OR (NOT AccountingBySeveralDepartments AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Department)Then
			PresentationOfStructuralUnit = "";
		Else
			PresentationOfStructuralUnit = PresentationOfStructuralUnit(RecordsSelection.StructuralUnitPresentation, RecordsSelection.PresentationCell);
		EndIf;
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%StructuralUnitType%", GetStructuralUnitTypePresentation(RecordsSelection.StructuralUnitType));
		MessageText = StrReplace(MessageText, "%StructuralUnitPresentation%", PresentationOfStructuralUnit);
		MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceInventoryInWarehouses));
		MessageText = StrReplace(MessageText, "%Quantity%", String(-RecordsSelection.QuantityBalanceInventoryInWarehouses));
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ReportErrorsPostingByRegisterInventoryInWarehousesAsList()

// The procedure informs of errors that occurred when posting by register Inventory.
//
Procedure ShowMessageAboutPostingToInventoryRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleTemplate = ErrorTitle + Chars.LF + NStr("en='There is not enough balance on inventory and expenses %StructuralUnitType% %StructuralUnitPresentation%';ru='Не хватает остатка по учету запасов и затрат %StructuralUnitType% %StructuralUnitPresentation%';vi='Không đủ số dư theo kế toán vật tư và chi phí %StructuralUnitType% %StructuralUnitPresentation%'");
	
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %QuantityAndReserve% %MeasurementUnit%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %QuantityAndReserve% %MeasurementUnit%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %QuantityAndReserve% %MeasurementUnit%'");
	
	TitleInDetailsShow = True;
	AccountingBySeveralWarehouses = Constants.FunctionalOptionAccountingByMultipleWarehouses.Get();
	AccountingBySeveralDepartments = Constants.FunctionalOptionAccountingByMultipleDepartments.Get();
	While RecordsSelection.Next() Do
		
		If TitleInDetailsShow Then
			If (NOT AccountingBySeveralWarehouses AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse)
				OR (NOT AccountingBySeveralDepartments AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Department)Then
				PresentationOfStructuralUnit = "";
			Else
				PresentationOfStructuralUnit = TrimAll(RecordsSelection.StructuralUnitPresentation);
			EndIf;
			MessageTitleText = StrReplace(MessageTitleTemplate, "%StructuralUnitPresentation%", PresentationOfStructuralUnit);
			MessageTitleText = StrReplace(MessageTitleText, "%StructuralUnitType%", GetStructuralUnitTypePresentation(RecordsSelection.StructuralUnitType));
			ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
			TitleInDetailsShow = False;
		EndIf;
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		If IsBlankString(RecordsSelection.CustomerOrderPresentation) Then
			MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceInventory));
			MessageText = StrReplace(MessageText, "%QuantityAndReserve%", String(-RecordsSelection.QuantityBalanceInventory));
		Else
			MessageText = StrReplace(MessageText, "%BalanceQuantity%", "reserve " + String(RecordsSelection.BalanceInventory));
			MessageText = StrReplace(MessageText, "%QuantityAndReserve%", "reserve " + String(-RecordsSelection.QuantityBalanceInventory));
		EndIf;
		
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ReportErrorsPostingByRegisterInventory()

// The procedure informs of posting errors
// by the Reserves register for a structural unit list.
//
Procedure ShowMessageAboutPostingToInventoryRegisterErrorsAsList(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Balance by accounting of inventories and expenses is missing';ru='Не хватает остатка по учету запасов и затрат';vi='Không đủ hàng tồn theo kế toán vật tư và chi phí'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"%StructuralUnitType%  %StructuralUnitPresentation%,"
"balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %QuantityAndReserve% %MeasurementUnit%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"%StructuralUnitType% %StructuralUnitPresentation%,"
"остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %QuantityAndReserve% %MeasurementUnit%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"%StructuralUnitType% %StructuralUnitPresentation%,"
"số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %QuantityAndReserve% %MeasurementUnit%'");
		
	AccountingBySeveralWarehouses = Constants.FunctionalOptionAccountingByMultipleWarehouses.Get();
	AccountingBySeveralDepartments = Constants.FunctionalOptionAccountingByMultipleDepartments.Get();
	While RecordsSelection.Next() Do
		
		If (NOT AccountingBySeveralWarehouses AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse)
			OR (NOT AccountingBySeveralDepartments AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Department)Then
			PresentationOfStructuralUnit = "";
		Else
			PresentationOfStructuralUnit = TrimAll(RecordsSelection.StructuralUnitPresentation);
		EndIf;
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%StructuralUnitPresentation%", PresentationOfStructuralUnit);
		MessageText = StrReplace(MessageText, "%StructuralUnitType%", GetStructuralUnitTypePresentation(RecordsSelection.StructuralUnitType));
		
		If IsBlankString(RecordsSelection.CustomerOrderPresentation) Then
			MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceInventory));
			MessageText = StrReplace(MessageText, "%QuantityAndReserve%", String(-RecordsSelection.QuantityBalanceInventory));
		Else
			MessageText = StrReplace(MessageText, "%BalanceQuantity%", "reserve " + String(RecordsSelection.BalanceInventory));
			MessageText = StrReplace(MessageText, "%QuantityAndReserve%", "reserve " + String(-RecordsSelection.QuantityBalanceInventory));
		EndIf;
		
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ReportErrorsPostingByRegisterInventoryAsList()

// The procedure informs of errors that occurred when posting by register Inventory transferred.
//
Procedure ShowMessageAboutPostingToInventoryTransferredRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleTemplate = ErrorTitle + Chars.LF + NStr("en='There is not enough inventory transferred to a third party counterparty %CounterpartyPresentation%';ru='Не хватает запасов, переданных стороннему контрагенту %CounterpartyPresentation%';vi='Không đủ vật tư đã chuyển giao cho đối tác bên ngoài %CounterpartyPresentation%'");
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,'");
	
	TitleInDetailsShow = True;
	AccountingCurrency = Constants.AccountingCurrency.Get();
	While RecordsSelection.Next() Do
		
		If TitleInDetailsShow Then
			MessageTitleText = StrReplace(MessageTitleTemplate, "%CounterpartyPresentation%", TrimAll(RecordsSelection.CounterpartyPresentation));
			ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
			TitleInDetailsShow = False;
		EndIf;
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		If RecordsSelection.QuantityBalanceInventoryTransferred <> 0 Then
			
			TextOfMessageQuantity = NStr("en='balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %Quantity% %MeasurementUnit%';ru='остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %Quantity% %MeasurementUnit%';vi='số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %Quantity% %MeasurementUnit%'");
			
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%BalanceQuantity%", String(RecordsSelection.BalanceInventoryTransferred));
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%Quantity%", String(-RecordsSelection.QuantityBalanceInventoryTransferred));
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
			
			MessageText = MessageText + Chars.LF + TextOfMessageQuantity;
			
		EndIf;
		
		If RecordsSelection.SettlementsAmountBalanceInventoryTransferred <> 0 Then
			
			TextOfMessageAmount = NStr("en='Accounting amount:"
"balance %AmountBalance% %Currency%,"
"not enough %Amount% %Currency%';ru='Сумма расчетов:"
"остаток %AmountBalance% %Currency%,"
"недостаточно %Amount% %Currency%';vi='Số tiền hạch toán:"
"số dư %AmountBalance% %Currency%,"
"không đủ %Amount% %Currency%'");
			
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%AmountBalance%", String(RecordsSelection.SettlementsAmountInventoryTransferred));
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%Amount%", String(-RecordsSelection.SettlementsAmountBalanceInventoryTransferred));
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%Currency%", String(AccountingCurrency));
			
			MessageText = MessageText + Chars.LF + TextOfMessageAmount;
			
		EndIf;
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToInventoryTransferredRegisterErrors()

// Procedure reports errors occurred while posting by
// the Inventory register passed for the third party counterparties list.
//
Procedure ShowMessageAboutPostingToInventoryTransferredRegisterErrorsAsList(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Insufficient inventory transferred to the external counterparty';ru='Не хватает запасов, переданных стороннему контрагенту';vi='Không đủ vật tư, đã chuyển giao cho đối tác khác'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"counterparty %CounterpartyPresentation%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"контрагент %CounterpartyPresentation%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"đối tác %CounterpartyPresentation%'");
	AccountingCurrency = Constants.AccountingCurrency.Get();
	While RecordsSelection.Next() Do
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%CounterpartyPresentation%", TrimAll(RecordsSelection.CounterpartyPresentation));
		
		If RecordsSelection.QuantityBalanceInventoryTransferred <> 0 Then
			
			TextOfMessageQuantity = NStr("en='balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %Quantity% %MeasurementUnit%';ru='остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %Quantity% %MeasurementUnit%';vi='số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %Quantity% %MeasurementUnit%'");
			
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%BalanceQuantity%", String(RecordsSelection.BalanceInventoryTransferred));
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%Quantity%", String(-RecordsSelection.QuantityBalanceInventoryTransferred));
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
			
			MessageText = MessageText + Chars.LF + TextOfMessageQuantity;
			
		EndIf;
		
		If RecordsSelection.SettlementsAmountBalanceInventoryTransferred <> 0 Then
			
			TextOfMessageAmount = NStr("en='Accounting amount: "
"balance %AmountBalance% %Currency%,"
"not enough %Amount% %Currency%';ru='Сумма расчетов:"
"остаток %AmountBalance% %Currency%,"
"недостаточно %Amount% %Currency%';vi='Số tiền hạch toán:"
"số dư %AmountBalance% %Currency%,"
"không đủ %Amount% %Currency%'");
			
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%AmountBalance%", String(RecordsSelection.SettlementsAmountInventoryTransferred));
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%Amount%", String(-RecordsSelection.SettlementsAmountBalanceInventoryTransferred));
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%Currency%", String(AccountingCurrency));
			
			MessageText = MessageText + Chars.LF + TextOfMessageAmount;
			
		EndIf;
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToInventoryTransferredRegisterErrorsAsList()

// The procedure informs of errors that occurred when posting by register Inventory received.
//
Procedure ShowMessageAboutPostingToInventoryReceivedRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleTemplate = ErrorTitle + Chars.LF + NStr("en='There is not enough inventory received from a third party counterparty %CounterpartyPresentation%';ru='Не хватает запасов, поступивших от стороннего контрагента %CounterpartyPresentation%';vi='Không đủ vật tư đã tiếp nhận từ đối tác bên ngoài %CounterpartyPresentation%'");
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,'");
	
	TitleInDetailsShow = True;
	AccountingCurrency = Constants.AccountingCurrency.Get();
	While RecordsSelection.Next() Do
		
		If TitleInDetailsShow Then
			MessageTitleText = StrReplace(MessageTitleTemplate, "%CounterpartyPresentation%", TrimAll(RecordsSelection.CounterpartyPresentation));
			ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
			TitleInDetailsShow = False;
		EndIf;
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		If RecordsSelection.QuantityBalanceInventoryReceived <> 0 Then
			
			TextOfMessageQuantity = NStr("en='balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %Quantity% %MeasurementUnit%';ru='остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %Quantity% %MeasurementUnit%';vi='số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %Quantity% %MeasurementUnit%'");
			
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%BalanceQuantity%", String(RecordsSelection.BalanceInventoryReceived));
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%Quantity%", String(-RecordsSelection.QuantityBalanceInventoryReceived));
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
			
			MessageText = MessageText + Chars.LF + TextOfMessageQuantity;
			
		EndIf;
		
		If RecordsSelection.SettlementsAmountBalanceInventoryReceived <> 0 Then
			
			TextOfMessageAmount = NStr("en='Accounting amount: "
"balance %AmountBalance% %Currency%, "
"not enough %Amount% %Currency%';ru='Сумма расчетов:"
"остаток %AmountBalance% %Currency%,"
"недостаточно %Amount% %Currency%';vi='Số tiền hạch toán:"
"số dư %AmountBalance% %Currency%,"
"không đủ %Amount% %Currency%'");
			
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%AmountBalance%", String(RecordsSelection.SettlementsAmountInventoryReceived));
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%Amount%", String(-RecordsSelection.SettlementsAmountBalanceInventoryReceived));
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%Currency%", String(AccountingCurrency));
			
			MessageText = MessageText + Chars.LF + TextOfMessageAmount;
			
		EndIf;
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToInventoryReceivedRegisterErrors()

// The procedure informs of errors that occurred when posting by register Inventory received.
//
Procedure ShowMessageAboutPostingToInventoryReceivedRegisterErrorsAsList(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Insufficient inventory received from the external counterparty';ru='Не хватает запасов, поступивших от стороннего контрагента';vi='Không đủ vật tư, đã tiếp nhận từ đối tác khác'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%, "
"counterparty %CounterpartyPresentation%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"контрагент %CounterpartyPresentation%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"đối tác %CounterpartyPresentation%'");
		
	AccountingCurrency = Constants.AccountingCurrency.Get();
	While RecordsSelection.Next() Do
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%CounterpartyPresentation%", TrimAll(RecordsSelection.CounterpartyPresentation));
		
		If RecordsSelection.QuantityBalanceInventoryReceived <> 0 Then
			
			TextOfMessageQuantity = NStr("en='balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %Quantity% %MeasurementUnit%';ru='остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %Quantity% %MeasurementUnit%';vi='số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %Quantity% %MeasurementUnit%'");
			
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%BalanceQuantity%", String(RecordsSelection.BalanceInventoryReceived));
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%Quantity%", String(-RecordsSelection.QuantityBalanceInventoryReceived));
			TextOfMessageQuantity = StrReplace(TextOfMessageQuantity, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
			
			MessageText = MessageText + Chars.LF + TextOfMessageQuantity;
			
		EndIf;
		
		If RecordsSelection.SettlementsAmountBalanceInventoryReceived <> 0 Then
			
			TextOfMessageAmount = NStr("en='Accounting amount: "
"balance %AmountBalance% %Currency%, "
"not enough %Amount% %Currency%';ru='Сумма расчетов:"
"остаток %AmountBalance% %Currency%,"
"недостаточно %Amount% %Currency%';vi='Số tiền hạch toán:"
"số dư %AmountBalance% %Currency%,"
"không đủ %Amount% %Currency%'");
			
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%AmountBalance%", String(RecordsSelection.SettlementsAmountInventoryReceived));
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%Amount%", String(-RecordsSelection.SettlementsAmountBalanceInventoryReceived));
			TextOfMessageAmount = StrReplace(TextOfMessageAmount, "%Currency%", String(AccountingCurrency));
			
			MessageText = MessageText + Chars.LF + TextOfMessageAmount;
			
		EndIf;
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ReportErrorsPostingByRegisterInventoryReceivedAsList()

// The procedure informs of errors that occurred when posting by register Inventory by CCD.
//
Procedure ShowMessageAboutPostingToInventoryByCCDRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Insufficient inventory by CCD';ru='Не хватает запасов в разрезе ГТД';vi='Không đủ vật tư theo từng tờ khai hải quan'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
		
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"balance %BalanceQuantity% %MeasurementUnit%,"
"not enough %Quantity% %MeasurementUnit%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"остаток %BalanceQuantity% %MeasurementUnit%,"
"недостаточно %Quantity% %MeasurementUnit%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"số dư %BalanceQuantity% %MeasurementUnit%,"
"không đủ %Quantity% %MeasurementUnit%'");
		
	While RecordsSelection.Next() Do
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		PresentationOfProductsAndServices = PresentationOfProductsAndServices + " / """ + TrimAll(RecordsSelection.CCDNoPresentation) + """";
		PresentationOfProductsAndServices = PresentationOfProductsAndServices + " / """ + TrimAll(RecordsSelection.CountryOfOriginPresentation) + """";
		
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceInventoryByCCD));
		MessageText = StrReplace(MessageText, "%Quantity%", String(-RecordsSelection.QuantityBalanceInventoryByCCD));
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToInventoryByCCDRegisterErrors()

// The procedure informs of errors that occurred when posting by register Customer orders.
//
Procedure ShowMessageAboutPostingToCustomerOrdersRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Registered more than specified in the customer order';ru='Оформлено больше, чем указано в заказе покупателя';vi='Đã lập lớn hơn đã chỉ ra trong đơn hàng của khách'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"balance by order %BalanceQuantity% %MeasurementUnit%, "
"exceeds by %Quantity% %MeasurementUnit%. %CustomerOrder%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"остаток по заказу %BalanceQuantity% %MeasurementUnit%,"
"превышает на %Quantity% %MeasurementUnit%. %CustomerOrder%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"số dư theo đơn hàng %BalanceQuantity% %MeasurementUnit%,"
"vượt quá %Quantity% %MeasurementUnit%. %CustomerOrder%'");
		
	While RecordsSelection.Next() Do
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceCustomerOrders));
		MessageText = StrReplace(MessageText, "%Quantity%", String(-RecordsSelection.QuantityBalanceCustomerOrders));
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		MessageText = StrReplace(MessageText, "%CustomerOrder%", TrimAll(RecordsSelection.OrderPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToCustomerOrdersRegisterErrors()

// The procedure informs of errors that occurred when posting by register Purchase orders.
//
Procedure ShowMessageAboutPostingToPurchaseOrdersRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Registered more than specified in the purchase order';ru='Оформлено больше, чем указано в заказе поставщику';vi='Đã lập lớn hơn đã chỉ ra trong đơn hàng đặt nhà cung cấp'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
		
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"balance by order %BalanceQuantity% %MeasurementUnit%, "
"exceeds by %Quantity% %MeasurementUnit%"
"%PurchaseOrder%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"остаток по заказу %BalanceQuantity% %MeasurementUnit%,"
"превышает на %Quantity% %MeasurementUnit%"
"%PurchaseOrder%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"số dư theo đơn hàng %BalanceQuantity% %MeasurementUnit%,"
"vượt quá %Quantity% %MeasurementUnit%"
"%PurchaseOrder%'");
		
	While RecordsSelection.Next() Do
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalancePurchaseOrders));
		MessageText = StrReplace(MessageText, "%Quantity%", String(-RecordsSelection.QuantityBalancePurchaseOrders));
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		MessageText = StrReplace(MessageText, "%PurchaseOrder%", TrimAll(RecordsSelection.PurchaseOrderPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToPurchaseOrdersRegisterErrors()

// The procedure informs of errors that occurred when posting by register Production orders.
//
Procedure ShowMessageAboutPostingToProductionOrdersRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Registered more than specified in the production order';ru='Оформлено больше, чем указано в заказе на производство';vi='Đã lập lớn hơn đã chỉ ra trong đơn hàng sản xuất'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
		
	MessagePattern = NStr("Номенклатура: %ProductsAndServicesCharacteristicsBatch%,
		|остаток по заказу %BalanceQuantity% %MeasurementUnit%,
		|превышает на %Quantity% %MeasurementUnit%
		|%ProductionOrder%'; en='Products and services: %ProductsAndServicesCharacteristicsBatch%,
		|balance by order %BalanceQuantity% %MeasurementUnit%, 
		|exceeds by %Quantity% %MeasurementUnit%
		|%ProductionOrder%'");
		
	While RecordsSelection.Next() Do
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceProductionOrders));
		MessageText = StrReplace(MessageText, "%Quantity%", String(-RecordsSelection.QuantityBalanceProductionOrders));
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		MessageText = StrReplace(MessageText, "%ProductionOrder%", TrimAll(RecordsSelection.ProductionOrderPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToProductionOrdersRegisterErrors()

// The procedure informs of errors that occurred when posting by register Inventory demand.
//
Procedure ShowMessageAboutPostingToInventoryDemandRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Registered more than the inventory demand';ru='Оформлено больше, чем есть потребность в запасах';vi='Đã lập lớn hơn nhu cầu vật tư'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	MessagePattern = NStr("en='Products and services: %ProductsAndServicesCharacteristicsBatch%,"
"demand %BalanceQuantity% %MeasurementUnit%,"
"exceeds by %Quantity% %MeasurementUnit%"
"%CustomerOrder%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"потребность %BalanceQuantity% %MeasurementUnit%,"
"превышает на %Quantity% %MeasurementUnit%"
"%CustomerOrder%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"yêu cầu %BalanceQuantity% %MeasurementUnit%,"
"vượt quá %Quantity% %MeasurementUnit%"
"%CustomerOrder%'");
		
	While RecordsSelection.Next() Do
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceInventoryDemand));
		MessageText = StrReplace(MessageText, "%Quantity%", String(-RecordsSelection.QuantityBalanceInventoryDemand));
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		MessageText = StrReplace(MessageText, "%CustomerOrder%", TrimAll(RecordsSelection.CustomerOrderPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToInventoryDemandRegisterErrors()

// The procedure informs of errors that occurred when posting by register Orders placement.
//
Procedure ShowMessageAboutPostingToOrdersPlacementRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Registered more than inventories placed in the orders';ru='Оформлено больше, чем размещено запасов в заказах';vi='Đã lập lớn hơn sắp xếp vật tư trong các đơn hàng'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
		
	MessagePattern = NStr("en='ProductsAndServices: %ProductsAndServicesCharacteristicsBatch%,"
"placed %BalanceQuantity% %MeasurementUnit%"
"in %SupplySource%,"
"exceeds by %Quantity% %MeasurementUnit%"
"by %CustomerOrder%';ru='Номенклатура: %ProductsAndServicesCharacteristicsBatch%,"
"размещено %BalanceQuantity% %MeasurementUnit%"
"в %SupplySource%,"
"превышает на %Quantity% %MeasurementUnit%"
"по %CustomerOrder%';vi='Mặt hàng: %ProductsAndServicesCharacteristicsBatch%,"
"sắp xếp %BalanceQuantity% %MeasurementUnit%"
"vào %SupplySource%,"
"vượt quá %Quantity% %MeasurementUnit%"
"theo %CustomerOrder%'");
		
	While RecordsSelection.Next() Do
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", PresentationOfProductsAndServices);
		
		MessageText = StrReplace(MessageText, "%BalanceQuantity%", String(RecordsSelection.BalanceOrdersPlacement));
		MessageText = StrReplace(MessageText, "%Quantity%", String(-RecordsSelection.QuantityBalanceOrdersPlacement));
		MessageText = StrReplace(MessageText, "%MeasurementUnit%", TrimAll(RecordsSelection.MeasurementUnitPresentation));
		MessageText = StrReplace(MessageText, "%CustomerOrder%", TrimAll(RecordsSelection.CustomerOrderPresentation));
		MessageText = StrReplace(MessageText, "%ProcurementSource%", TrimAll(RecordsSelection.SupplySourcePresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToOrdersPlacementRegisterErrors()

// The procedure informs of errors that occurred when posting by register Cash assets.
//
Procedure ShowMessageAboutPostingToCashAssetsRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Not enough funds';ru='Не хватает денежных средств';vi='Không đủ vốn bằng tiền'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	MessagePattern = NStr("en='%PettyCashAccount%: %PettyCashAccountPresentation%,"
"balance %AmountBalance% %Currency%,"
"not enough %Amount% %Currency%';ru='%PettyCashAccount%: %PettyCashAccountPresentation%,"
"остаток %AmountBalance% %Currency%,"
"недостаточно %Amount% %Currency%';vi='%PettyCashAccount%: %PettyCashAccountPresentation%,"
"số dư %AmountBalance% %Currency%,"
"không đủ %Amount% %Currency%'");
		
	While RecordsSelection.Next() Do
		
		PettyCashAccountPresentation = CashBankAccountPresentation(RecordsSelection.BankAccountCashPresentation);
		MessageText = StrReplace(MessagePattern, "%PettyCashAccountPresentation%", PettyCashAccountPresentation);
		
		If RecordsSelection.CashAssetsType = Enums.CashAssetTypes.Noncash Then
			
			MessageText = StrReplace(MessageText, "%PettyCashAccount%", "Account");
			
		Else
			
			MessageText = StrReplace(MessageText, "%PettyCashAccount%", "PettyCash");
			
		EndIf;
		
		MessageText = StrReplace(MessageText, "%AmountBalance%", String(RecordsSelection.BalanceCashAssets));
		MessageText = StrReplace(MessageText, "%Amount%", String(-RecordsSelection.AmountCurBalance));
		MessageText = StrReplace(MessageText, "%Currency%", TrimAll(RecordsSelection.CurrencyPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToCashAssetsRegisterErrors()

// The procedure informs of errors that occurred when posting by register Cash in cash registers.
//
Procedure ErrorMessageOfPostingOnRegisterOfCashAtCashRegisters(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Not enough funds in cash register';ru='Не хватает денежных средств в кассе ККМ';vi='Không đủ vốn bằng tiền trong quầy thu ngân'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	MessagePattern = NStr("en='Cash register: %CRPettyCashPresentation%,"
"balance %AmountBalance% %Currency%,"
"not enough %Amount% %Currency%';ru='Касса ККМ: %CRPettyCashPresentation%,"
"остаток %AmountBalance% %Currency%,"
"недостаточно %Amount% %Currency%';vi='Quầy thu ngân: %CRPettyCashPresentation%,"
"số dư %AmountBalance% %Currency%,"
"không đủ %Amount% %Currency%'"
	);
		
	While RecordsSelection.Next() Do
		
		CRPresentation = CashBankAccountPresentation(RecordsSelection.CashCRDescription);
		MessageText = StrReplace(MessagePattern, "%CashRegisterPresentation%", CRPresentation);
		MessageText = StrReplace(MessageText, "%AmountBalance%", String(RecordsSelection.BalanceCashAssets));
		MessageText = StrReplace(MessageText, "%Amount%", String(-RecordsSelection.AmountCurBalance));
		MessageText = StrReplace(MessageText, "%Currency%", TrimAll(RecordsSelection.CurrencyPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ErrorMessageOfPostingOnRegisterOfCashAtCashRegisters()

// The procedure informs of errors that occurred when posting by register Advance holder payments.
//
Procedure ShowMessageAboutPostingToAdvanceHolderPaymentsRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Settlements with advance holder will be negative';ru='Расчеты с подотчетным лицом станут отрицательными';vi='Hạch toán với người nhận tạm ứng trở thành âm'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	MessagePattern = NStr("en='%AdvanceHolderPresentation%,"
"Balance cash assets issued to advance holder: %AdvanceHolderBalance% %CurrencyPresentation%';ru='%AdvanceHolderPresentation%,"
"Остаток выданных подотчетному лицу денежных средств: %AdvanceHolderBalance% %CurrencyPresentation%';vi='%AdvanceHolderPresentation%,"
"Số dư đã chi cho người nhận tạm ứng: %AdvanceHolderBalance% %CurrencyPresentation%'");
		
	While RecordsSelection.Next() Do
		
		PresentationOfAccountablePerson = PresentationOfAccountablePerson(RecordsSelection.EmployeePresentation, RecordsSelection.CurrencyPresentation, RecordsSelection.DocumentPresentation);
		MessageText = StrReplace(MessagePattern, "%AdvanceHolderPresentation%", PresentationOfAccountablePerson);
		
		MessageText = StrReplace(MessageText, "%AdvanceHolderBalance%", String(RecordsSelection.AccountablePersonBalance));
		MessageText = StrReplace(MessageText, "%CurrencyPresentation%", TrimAll(RecordsSelection.CurrencyPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToAdvanceHolderPaymentsRegisterErrors()

// The procedure informs of errors that occurred when posting by register Accounts payable.
//
Procedure ShowMessageAboutPostingToAccountsPayableRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Cannot record settlements with suppliers';ru='Нет возможности зафиксировать расчеты с поставщиками';vi='Không thể ghi nhận hạch toán với nhà cung cấp'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
	
	While RecordsSelection.Next() Do
		
		If RecordsSelection.RegisterRecordsOfCashDocuments Then
			
			If RecordsSelection.SettlementsType = Enums.SettlementsTypes.Debt Then
				MessageText = NStr("en='%CounterpartyPresentation% - debt balance to the vendor by the calculation document is less than the paid amount."
"Posted amount payable: %SumCurOnWrite% %CurrencyPresentation%."
"Debt before the balance provider: %RemainingDebtAmount% %CurrencyPresentation%.';ru='%CounterpartyPresentation% - остаток задолженности перед поставщиком по документу расчетов меньше оплаченной суммы."
"Разнесенная сумма платежа: %SumCurOnWrite% %CurrencyPresentation%."
"Остаток задолженности перед поставщиком: %RemainingDebtAmount% %CurrencyPresentation%.';vi='%CounterpartyPresentation% - số dư công nợ phải trả cho nhà cung cấp theo chứng từ hạch toán nhỏ hơn số dư đã trả."
"Số tiền thanh toán chênh lệch: %SumCurOnWrite% %CurrencyPresentation%."
"Số dư công nợ phải trả cho nhà cung cấp: %RemainingDebtAmount% %CurrencyPresentation%.'"
				);
				MessageText = StrReplace(MessageText, "%SumCurOnWrite%", String(RecordsSelection.SumCurOnWrite));
				MessageText = StrReplace(MessageText, "%RemainingDebtAmount%", String(RecordsSelection.DebtBalanceAmount));
			EndIf;
			
			If RecordsSelection.SettlementsType = Enums.SettlementsTypes.Advance Then
				If RecordsSelection.AmountOfOutstandingAdvances = 0 Then
					MessageText = NStr("en='%CounterpartyPresentation% - paid advances to the supplier under the document are already set off completely in the trade documents.';ru='%CounterpartyPresentation% - выданные по документу авансы поставщику уже полностью зачтены в товарных документах.';vi='%CounterpartyPresentation% - đã khấu trừ toàn bộ khoản ứng trước đã chi theo chứng từ cho nhà cung cấp trong các chứng từ thương mại.'"
					);
				Else
					MessageText = NStr("en='%CounterpartyPresentation% - advances issued to vendor by document are already partially accounted in the  trade documents."
"Balance of non-offset advances: %OutstandingAdvancesAmount% %CurrencyPresentation%.';ru='%CounterpartyPresentation% - выданные по документу авансы поставщику уже частично зачтены в товарных документах."
"Остаток незачтенных авансов: %OutstandingAdvancesAmount% %CurrencyPresentation%.';vi='%CounterpartyPresentation% - khoản ứng trước đã chi cho nhà cung cấp theo chứng từ đã được khấu trừ một phần trong các chứng từ thương mại."
"Số dư ứng trước chưa khấu trừ: %OutstandingAdvancesAmount% %CurrencyPresentation%.'"
					);
					MessageText = StrReplace(MessageText, "%UnpaidAdvancesAmount%", String(RecordsSelection.AmountOfOutstandingAdvances));
				EndIf;
			EndIf;
			
		Else
			
			If RecordsSelection.SettlementsType = Enums.SettlementsTypes.Debt Then
				If RecordsSelection.AmountOfOutstandingDebt = 0 Then
					MessageText = NStr("en='%CounterpartyPresentation% - debt to supplier under the document is already paid completely.';ru='%CounterpartyPresentation% - задолженность перед поставщиком по документу уже полностью оплачена.';vi='%CounterpartyPresentation% - đã thanh toán toàn bộ công nợ phải trả nhà cung cấp theo chứng từ.'"
					);
				Else
					MessageText = NStr("en='%CounterpartyPresentation% - vendor debt by the document is partially paid off."
"Balance of unpaid debt amount: %UnpaidDebtAmount% %CurrencyPresentation%.';ru='%CounterpartyPresentation% - задолженность перед поставщиком по документу уже частично оплачена."
"Остаток непогашенной суммы задолженности: %UnpaidDebtAmount% %CurrencyPresentation%.';vi='%CounterpartyPresentation% - công nợ phải trả nhà cung cấp theo chứng từ đã thanh toán một phần."
"Số dư công nợ chưa trả: %UnpaidDebtAmount% %CurrencyPresentation%.'"
					);
					MessageText = StrReplace(MessageText, "%UnpaidDebtAmount%", String(RecordsSelection.AmountOfOutstandingDebt));
				EndIf;
			EndIf;
			If RecordsSelection.SettlementsType = Enums.SettlementsTypes.Advance Then
				MessageText = NStr("en='%CounterpartyPresentation% - accounted advances amount can not be more than the balance of advances issued to vendor."
"Accounted amount: %CurrAmountOnWrite %CurrencyPresentation%"
"Issued advances balance: %IssuedAdvancesAmount% %CurrencyPresentation%.';ru='%CounterpartyPresentation% - зачитываемая сумма авансов не может быть больше остатка выданных авансов поставщику."
"Зачитываемая сумма: %CurrAmountOnWrite% %CurrencyPresentation%"
"Остаток выданных авансов: %IssuedAdvancesAmount% %CurrencyPresentation%.';vi='%CounterpartyPresentation% - số tiền ứng trước được khấu trừ không thể lớn hơn số dư ứng trước đã chi cho nhà cung cấp."
"Số tiền được khấu trừ: %CurrAmountOnWrite% %CurrencyPresentation%"
"Số dư khoản ứng trước đã chi: %IssuedAdvancesAmount% %CurrencyPresentation%.'"
				);
				MessageText = StrReplace(MessageText, "%SumCurOnWrite%", String(RecordsSelection.SumCurOnWrite));
				MessageText = StrReplace(MessageText, "%IssuedAdvancesAmount%", String(RecordsSelection.AdvanceAmountsPaid));
			EndIf;
			
		EndIf;
		
		MessageText = StrReplace(MessageText, "%CounterpartyPresentation%", CounterpartyPresentation(RecordsSelection.CounterpartyPresentation, RecordsSelection.ContractPresentation, RecordsSelection.DocumentPresentation, RecordsSelection.OrderPresentation, RecordsSelection.CalculationsTypesPresentation));
		MessageText = StrReplace(MessageText, "%CurrencyPresentation%", TrimAll(RecordsSelection.CurrencyPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToAccountsPayableRegisterErrors()

// The procedure informs of errors that occurred when posting by register Accounts receivable.
//
Procedure ShowMessageAboutPostingToAccountsReceivableRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Cannot record settlements with customers';ru='Нет возможности зафиксировать расчеты с покупателями';vi='Không thể ghi nhận hạch toán với người mua'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
		
	While RecordsSelection.Next() Do
		
		If RecordsSelection.RegisterRecordsOfCashDocuments Then
			
			If RecordsSelection.SettlementsType = Enums.SettlementsTypes.Debt Then
				MessageText = NStr("en='%CounterpartyPresentation% - balance customer debt by calculations document is less than posted payment amount."
"Posted amount payable: %SumCurOnWrite% %CurrencyPresentation%."
"Remaining customer debt: %RemainingDebtAmount% %CurrencyPresentation%.';ru='%CounterpartyPresentation% - остаток задолженность покупателя по документу расчетов меньше разнесенной суммы платежа."
"Разнесенная сумма платежа: %SumCurOnWrite% %CurrencyPresentation%."
"Остаток задолженности покупателя: %RemainingDebtAmount% %CurrencyPresentation%.';vi='%CounterpartyPresentation% - số dư công nợ của khách hàng theo chứng từ hạch toán nhỏ hơn số tiền chênh lệch thanh toán."
"Số tiền thanh toán chênh lệch: %SumCurOnWrite% %CurrencyPresentation%."
"Số dư công nợ của khách hàng: %RemainingDebtAmount% %CurrencyPresentation%.'"
				);
				MessageText = StrReplace(MessageText, "%SumCurOnWrite%", String(RecordsSelection.SumCurOnWrite));
				MessageText = StrReplace(MessageText, "%RemainingDebtAmount%", String(RecordsSelection.DebtBalanceAmount));
			EndIf;
			
			If RecordsSelection.SettlementsType = Enums.SettlementsTypes.Advance Then
				If RecordsSelection.AmountOfOutstandingAdvances = 0 Then
					MessageText = NStr("en='%CounterpartyPresentation% - received by the document advances from the customer are already set off completely in the trade documents.';ru='%CounterpartyPresentation% - полученные по документу авансы от покупателя уже полностью зачтены в товарных документах.';vi='%CounterpartyPresentation% - đã khấu trừ toàn bộ khoản ứng trước đã nhận theo chứng từ từ khách hàng trong các chứng từ thương mại.'"
					);
				Else
					MessageText = NStr("en='%CounterpartyPresentation% - advances received by the document from the customer are partially accounted in the trade documents."
"Balance of non-offset advances: %UnpaidAdvancesAmount% %CurrencyPresentation%.';ru='%CounterpartyPresentation% - полученные по документу авансы от покупателя уже частично зачтены в товарных документах."
"Остаток незачтенных авансов: %UnpaidAdvancesAmount% %CurrencyPresentation%.';vi='%CounterpartyPresentation% - khoản ứng trước đã nhận từ khách hàng theo chứng từ đã được khấu trừ một phần trong các chứng từ thương mại."
"Số dư ứng trước chưa khấu trừ: %UnpaidAdvancesAmount% %CurrencyPresentation%.'"
					);
					MessageText = StrReplace(MessageText, "%UnpaidAdvancesAmount%", String(RecordsSelection.AmountOfOutstandingAdvances));
				EndIf;
			EndIf;
			
		Else
			
			If RecordsSelection.SettlementsType = Enums.SettlementsTypes.Debt Then
				If RecordsSelection.AmountOfOutstandingDebt = 0 Then
					MessageText = NStr("en='%CounterpartyPresentation% - customer debt on the document has already been paid off.';ru='%CounterpartyPresentation% - задолженность покупателя по документу уже полностью оплачена.';vi='%CounterpartyPresentation% - công nợ của khách hàng theo chứng từ đã thanh toán đầy đủ.'"
					);
				Else
					MessageText = NStr("en='%CounterpartyPresentation% - customer debt on the document has been partially paid off."
"Balance of unpaid debt amount: %UnpaidDebtAmount% %CurrencyPresentation%.';ru='%CounterpartyPresentation% - задолженность покупателя по документу уже частично оплачена."
"Остаток непогашенной суммы задолженности: %UnpaidDebtAmount% %CurrencyPresentation%.';vi='%CounterpartyPresentation% - công nợ của khách hàng theo chứng từ đã được thanh toán một phần."
"Số dư công nợ chưa trả: %UnpaidDebtAmount% %CurrencyPresentation%.'"
					);
					MessageText = StrReplace(MessageText, "%UnpaidDebtAmount%", String(RecordsSelection.AmountOfOutstandingDebt));
				EndIf;
			EndIf;
			
			If RecordsSelection.SettlementsType = Enums.SettlementsTypes.Advance Then
				MessageText = NStr("en='%CounterpartyPresentation% - accounted advances amount can not be more than balance of advances received from customer."
"Accounted amount: %SumCurOnWrite %CurrencyPresentation% "
"Received advances balance: %ReceivedAdvancesAmount% %CurrencyPresentation%.';ru='%CounterpartyPresentation% - зачитываемая сумма авансов не может быть больше остатка полученных авансов от покупателя."
"Зачитываемая сумма: %SumCurOnWrite% %CurrencyPresentation%"
"Остаток полученных авансов: %ReceivedAdvancesAmount% %CurrencyPresentation%.';vi='%CounterpartyPresentation% - số tiền tạm ứng được khấu trừ không thể lớn hơn số dư khoản ứng trước đã nhận từ khách hàng."
"Số tiền được khấu trừ: %SumCurOnWrite% %CurrencyPresentation%"
"Số dư khoản ứng trước đã nhận: %ReceivedAdvancesAmount% %CurrencyPresentation%.'"
				);
				MessageText = StrReplace(MessageText, "%SumCurOnWrite%", String(RecordsSelection.SumCurOnWrite));
				MessageText = StrReplace(MessageText, "%ReceivedAdvancesAmount%", String(RecordsSelection.AdvanceAmountsReceived));
			EndIf;
			
		EndIf;
		
		MessageText = StrReplace(MessageText, "%CounterpartyPresentation%", CounterpartyPresentation(RecordsSelection.CounterpartyPresentation, RecordsSelection.ContractPresentation, RecordsSelection.DocumentPresentation, RecordsSelection.OrderPresentation, RecordsSelection.CalculationsTypesPresentation));
		MessageText = StrReplace(MessageText, "%CurrencyPresentation%", TrimAll(RecordsSelection.CurrencyPresentation));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ShowMessageAboutPostingToAccountsReceivableRegisterErrors()

// The procedure informs of errors that occurred when posting by register Fixed assets.
//
Procedure ShowMessageAboutPostingToFixedAssetsRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleText = ErrorTitle + Chars.LF + NStr("en='Property might have already been written off or transferred';ru='Возможно имущество уже списано или передано';vi='Có thể tài sản cố định đã được ghi giảm hoặc chuyển giao'");
	ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
		
	MessagePattern = NStr("en='Property: %ProductsAndServicesCharacteristicsBatch%,"
"depreciated property cost: %Cost%';ru='Имущество: %ProductsAndServicesCharacteristicsBatch%,"
"остаточная стоимость имущества: %Cost%';vi='Tài sản: %ProductsAndServicesCharacteristicsBatch%,"
"giá trị còn lại của tài sản: %Cost%'");
		
	While RecordsSelection.Next() Do
		
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicsBatch%", TrimAll(RecordsSelection.FixedAssetPresentation));
		
		MessageText = StrReplace(MessageText, "%Cost%", String(RecordsSelection.DepreciatedCost));
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ReportErrorsPostingByRegisterFixedAssets()

// The procedure informs of errors that occurred when posting by register Retail amount accounting.
//
Procedure ShowMessageAboutPostingToRetailAmountAccountingRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleTemplate = ErrorTitle + Chars.LF + NStr("en='The debt of retail outlet %StructuralUnitPresentation% is already paid';ru='Задолженность розничной точки %StructuralUnitPresentation% уже погашена';vi='Đã thanh toán công nợ của điểm bán lẻ %StructuralUnitPresentation%'");
	
	MessagePattern = NStr("en='Debt balance (amount accounting): %BalanceInRetail% %CurrencyPresentation%';ru='Остаток задолженности (суммовой учет): %BalanceInRetail% %CurrencyPresentation%';vi='Số dư công nợ (kế toán giá trị): %BalanceInRetail% %CurrencyPresentation%'");
	
	TitleInDetailsShow = True;
	While RecordsSelection.Next() Do
		
		If TitleInDetailsShow Then
			MessageTitleText = StrReplace(MessageTitleTemplate, "%StructuralUnitPresentation%", TrimAll(RecordsSelection.StructuralUnitPresentation));
			ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
			TitleInDetailsShow = False;
		EndIf;
		
		MessageText = StrReplace(MessagePattern, "%BalanceInRetail%", String(RecordsSelection.BalanceInRetail)); 
		MessageText = StrReplace(MessageText, "%CurrencyPresentation%", TrimAll(RecordsSelection.CurrencyPresentation)); 
		
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure // ReportErrorsPostingByRegisterAmountAccountingInRetail()

// Procedure reports errors by the register Serial numbers.
//
Procedure ShowMessageAboutPostingSerialNumbersRegisterErrors(DocObject, RecordsSelection, Cancel) Export
	
	ErrorTitle = NStr("en='Error:';ru='Ошибка:';vi='Lỗi:'");
	MessageTitleTemplate = ErrorTitle + Chars.LF + NStr("en='Not enough serial numbers %StructuralUnitType% %StructuralUnitPresentation%';ru='Не хватает серийных номеров %StructuralUnitType% %StructuralUnitPresentation%';vi='Không đủ số sê-ri %StructuralUnitType% %StructuralUnitPresentation%'");
	
	MessagePattern = NStr("en='Product:"
"%ProductsAndServicesCharacteristicBatch%, serial number %SerialNumber%';ru='Номенклатура: %ProductsAndServicesCharacteristicBatch%,"
"серийный номер %SerialNumber%';vi='Mặt hàng: %ProductsAndServicesCharacteristicBatch%,"
"số sê-ri %SerialNumber%'");
		
	TitleInDetailsShow = True;
	AccountingBySeveralWarehouses = Constants.FunctionalOptionAccountingByMultipleWarehouses.Get();
	AccountingBySeveralDivisions = Constants.FunctionalOptionAccountingByMultipleDepartments.Get();
	While RecordsSelection.Next() Do
		
		If TitleInDetailsShow Then
			If (NOT AccountingBySeveralWarehouses AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Warehouse)
				OR (NOT AccountingBySeveralDivisions AND RecordsSelection.StructuralUnitType = Enums.StructuralUnitsTypes.Department)Then
				PresentationOfStructuralUnit = "";
			Else
				If WorkWithProductsClientServer.IsObjectAttribute("PresentationCell" , RecordsSelection) Then
					PresentationOfStructuralUnit = PresentationOfStructuralUnit(RecordsSelection.StructuralUnitPresentation, RecordsSelection.PresentationCell);
				Else
					PresentationOfStructuralUnit = PresentationOfStructuralUnit(RecordsSelection.StructuralUnitPresentation);
				EndIf; 
				
			EndIf;
			MessageTitleText = StrReplace(MessageTitleTemplate, "%StructuralUnitPresentation%", PresentationOfStructuralUnit);
			MessageTitleText = StrReplace(MessageTitleText, "%StructuralUnitType%", GetStructuralUnitTypePresentation(RecordsSelection.StructuralUnitType));
			ShowMessageAboutError(DocObject, MessageTitleText, , , , Cancel);
			TitleInDetailsShow = False;
		EndIf;
		
		PresentationOfProductsAndServices = PresentationOfProductsAndServices(RecordsSelection.ProductsAndServicesPresentation, RecordsSelection.CharacteristicPresentation, RecordsSelection.BatchPresentation);
		MessageText = StrReplace(MessagePattern, "%ProductsAndServicesCharacteristicBatch%", PresentationOfProductsAndServices);
		MessageText = StrReplace(MessageText, "%SerialNumber%", String(RecordsSelection.SerialNumberPresentation));
		ShowMessageAboutError(DocObject, MessageText, , , , Cancel);
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SSM SUBSYSTEMS PROCEDURES AND FUNCTIONS

&AtServer
// Procedure adds formula parameters to the structure.
//
Procedure AddParametersToStructure(FormulaString, ParametersStructure, Cancel = False) Export

	Formula = FormulaString;
	
	OperandStart = Find(Formula, "[");
	OperandEnd = Find(Formula, "]");
     
	IsOperand = True;
	While IsOperand Do
     
		If OperandStart <> 0 AND OperandEnd <> 0 Then
			
            ID = TrimAll(Mid(Formula, OperandStart+1, OperandEnd - OperandStart - 1));
            Formula = Right(Formula, StrLen(Formula) - OperandEnd);   
			
			Try
				If Not ParametersStructure.Property(ID) Then
					ParametersStructure.Insert(ID);
				EndIf;
			Except
			    Break;
				Cancel = True;
			EndTry 
			 
		EndIf;     
          
		OperandStart = Find(Formula, "[");
		OperandEnd = Find(Formula, "]");
          
		If Not (OperandStart <> 0 AND OperandEnd <> 0) Then
			IsOperand = False;
        EndIf;     
               
	EndDo;	

EndProcedure

// Function returns parameter value
//
Function CalculateParameterValue(ParametersStructure, CalculationParameter, ErrorText = "") Export
	
	// 1. Create query
	Query = New Query;
	Query.Text = CalculationParameter.Query;
	
	// 2. Control of all query parameters filling
	For Each QueryParameter IN CalculationParameter.QueryParameters Do
		
		If ValueIsFilled(QueryParameter.Value) Then
			
			Query.SetParameter(StrReplace(QueryParameter.Name, ".", ""), QueryParameter.Value);
			
		Else
			
			If ParametersStructure.Property(StrReplace(QueryParameter.Name, ".", "")) Then
				
				PeriodString = CalculationParameter.DataFilterPeriods.Find(StrReplace(QueryParameter.Name, ".", ""), "BoundaryDateName");
				If PeriodString <> Undefined  Then
					
					If PeriodString.PeriodShift <> 0 Then
						NewPeriod = AddInterval(ParametersStructure[StrReplace(QueryParameter.Name, ".", "")], PeriodString.ShiftPeriod, PeriodString.PeriodShift);
						Query.SetParameter(StrReplace(QueryParameter.Name, ".", ""), NewPeriod);
					Else
						Query.SetParameter(StrReplace(QueryParameter.Name, ".", ""), ParametersStructure[StrReplace(QueryParameter.Name, ".", "")]);
					EndIf;
					
				Else
					
					Query.SetParameter(StrReplace(QueryParameter.Name, ".", ""), ParametersStructure[StrReplace(QueryParameter.Name, ".", "")]);
					
				EndIf; 
				
			ElsIf ValueIsFilled(TypeOf(QueryParameter.Value)) Then
				
				Query.SetParameter(StrReplace(QueryParameter.Name, ".", ""), QueryParameter.Value);
				
			Else
				
				Message = New UserMessage();
				Message.Text = NStr("en='Parameter value query is not specified ';ru='Не задано значение параметра запроса ';vi='Chưa chỉ ra giá trị tham số truy vấn'") + QueryParameter.Name + ErrorText;
				Message.Message();
				
				Return 0;
			EndIf;
			
		EndIf; 
		
	EndDo; 
	
	// 4. Query execution
	QueryResult = Query.Execute().Unload();
	If QueryResult.Count() = 0 Then
		
		Return 0;
		
	Else
		
		Return QueryResult[0][0];
		
	EndIf;
	
EndFunction // CalculateParameterValue()

// Function adds interval to date
//
// Parameters:
//     Periodicity (Enum.Periodicity)     - planning periodicity by script.
//     DateInPeriod (Date)                                   - custom
//     date Shift (number)                                   - defines the direction and quantity of periods where date is moved
//
// Returns:
//     Date remote from the original by the specified periods quantity 
//
Function AddInterval(PeriodDate, Periodicity, Shift) Export

     If Shift = 0 Then
          NewPeriodData = PeriodDate;
          
     ElsIf Periodicity = Enums.Periodicity.Day Then
          NewPeriodData = BegOfDay(PeriodDate + Shift * 24 * 3600);
          
     ElsIf Periodicity = Enums.Periodicity.Week Then
          NewPeriodData = BegOfWeek(PeriodDate + Shift * 7 * 24 * 3600);
          
     ElsIf Periodicity = Enums.Periodicity.Month Then
          NewPeriodData = AddMonth(PeriodDate, Shift);
          
     ElsIf Periodicity = Enums.Periodicity.Quarter Then
          NewPeriodData = AddMonth(PeriodDate, Shift * 3);
          
     ElsIf Periodicity = Enums.Periodicity.Year Then
          NewPeriodData = AddMonth(PeriodDate, Shift * 12);
          
     Else
          NewPeriodData=BegOfDay(PeriodDate) + Shift * 24 * 3600;
          
     EndIf;

     Return NewPeriodData;

EndFunction // AddInterval()

// Receives default expenses invoice of accrual type.
//
// Parameters:
//  DataStructure - Structure containing object attributes
//                 that should be received and filled in
//                 with attributes that are required for receipt.
//
Procedure GetAccrualKindGLExpenseAccount(DataStructure) Export
	
	AccrualDeductionKind = DataStructure.AccrualDeductionKind;
	GLExpenseAccount = AccrualDeductionKind.GLExpenseAccount;
	
	If AccrualDeductionKind.Type = Enums.AccrualAndDeductionTypes.Tax Then
		
		GLExpenseAccount = AccrualDeductionKind.TaxKind.GLAccount;
		
		If GLExpenseAccount.TypeOfAccount <> Enums.GLAccountsTypes.Creditors Then
			
			GLExpenseAccount = ChartsOfAccounts.Managerial.EmptyRef();
			
		EndIf;
		
	ElsIf AccrualDeductionKind.Type = Enums.AccrualAndDeductionTypes.Accrual Then
		
		If ValueIsFilled(DataStructure.StructuralUnit) Then
			
			TypeOfAccount = GLExpenseAccount.TypeOfAccount;
			If DataStructure.StructuralUnit.StructuralUnitType = Enums.StructuralUnitsTypes.Department
				AND Not (TypeOfAccount = Enums.GLAccountsTypes.IndirectExpenses
					OR TypeOfAccount = Enums.GLAccountsTypes.Expenses
					OR TypeOfAccount = Enums.GLAccountsTypes.OtherCurrentAssets
					OR TypeOfAccount = Enums.GLAccountsTypes.IndirectExpenses
					OR TypeOfAccount = Enums.GLAccountsTypes.UnfinishedProduction
					OR TypeOfAccount = Enums.GLAccountsTypes.OtherCurrentAssets) Then
				
				GLExpenseAccount = ChartsOfAccounts.Managerial.EmptyRef();
				
			EndIf;
			
		EndIf;
		
	ElsIf AccrualDeductionKind.Type = Enums.AccrualAndDeductionTypes.Deduction Then
		
		GLExpenseAccount = ChartsOfAccounts.Managerial.OtherIncome;
		
	EndIf;
	
	DataStructure.GLExpenseAccount = GLExpenseAccount;
	DataStructure.TypeOfAccount = GLExpenseAccount.TypeOfAccount;
	
EndProcedure

// Function generates a last name, name and patronymic as a string.
//
// Parameters
//  Surname      - last name of ind. bodies
//  Name          - name ind. bodies
//  Patronymic     - patronymic ind. bodies
//  DescriptionFullShort    - Boolean - If True (by default), then
//                 the individual presentation includes a last name and initials if False - surname
//                 or name and patronymic.
//
// Return value
// Surname, name, patronymic as one string.
//
Function GetSurnameNamePatronymic(Surname = " ", Name = " ", Patronymic = " ", NameAndSurnameShort = True) Export
	
	
	
	If NameAndSurnameShort Then
		Return ?(NOT IsBlankString(Surname), Surname + ?(NOT IsBlankString(Name)," " + Left(Name,1) + "." + 
				?(NOT IsBlankString(Patronymic) , 
				Left(Patronymic,1)+".", ""), ""), "");
	Else
		Return ?(NOT IsBlankString(Surname), Surname + ?(NOT IsBlankString(Name)," " + Name + 
				?(NOT IsBlankString(Patronymic) , " " + Patronymic, ""), ""), "");
	EndIf;

EndFunction // GetSurnameNamePatronymic()

// Function selects first word in a sentence
Function SelectWord(SourceLine) Export
	
	Buffer = TrimL(SourceLine);
	LastSpacePosition = Find(Buffer, " ");

	If LastSpacePosition = 0 Then
		SourceLine = "";
		Return Buffer;
	EndIf;
	
	MarkedWord = TrimAll(Left(Buffer, LastSpacePosition));
	SourceLine = Mid(SourceLine, LastSpacePosition + 1);
	
	Return MarkedWord;
	
EndFunction

// Function defines whether calculation method or accrual kind was input earlier
//
// IdentifierValue (Row) - Identifier attribute value of the CalculationParameters catalog item
//
Function SettlementsParameterExist(IdentifierValue) Export
	
	If IsBlankString(IdentifierValue)Then
		
		Return False;
		
	EndIf;
	
	Return Not Catalogs.CalculationsParameters.FindByAttribute("ID", IdentifierValue) = Catalogs.CalculationsParameters.EmptyRef();
	
EndFunction // SettlementsParameterExist()

//Function determines whether the initial filling of the AccrualAndDeductionKinds catalog is executed
//
//
Function AccrualAndDeductionKindsInitialFillingPerformed() Export
	
	Query = New Query("Select * From Catalog.AccrualAndDeductionKinds AS AAndDKinds WHERE NOT AAndDKinds.Predefined");
	
	QueryResult = Query.Execute();
	Return Not QueryResult.IsEmpty();
	
EndFunction // AccrualAndDeductionKindsInitialFillingExecuted()

///////////////////////////////////////////////////////////////////////////////// 
// TRANSACTIONS MIRROR PROCEDURES AND FUNCTIONS

// Generates transactions table structure.
//
Procedure GenerateTransactionsTable(DocumentRef, StructureAdditionalProperties) Export
	
	TableManagerial = New ValueTable;
	
	TableManagerial.Columns.Add("LineNumber");
	TableManagerial.Columns.Add("Period");
	TableManagerial.Columns.Add("Company");
	TableManagerial.Columns.Add("PlanningPeriod");
	TableManagerial.Columns.Add("AccountDr");
	TableManagerial.Columns.Add("CurrencyDr");
	TableManagerial.Columns.Add("AmountCurDr");
	TableManagerial.Columns.Add("AccountCr");
	TableManagerial.Columns.Add("CurrencyCr");
	TableManagerial.Columns.Add("AmountCurCr");
	TableManagerial.Columns.Add("Amount");
	TableManagerial.Columns.Add("Content");
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableManagerial", TableManagerial);
	
EndProcedure // GenerateTransactionsTable()

///////////////////////////////////////////////////////////////////////////////// 
// EXPLOSION PROCEDURES AND FUNCTIONS

// Generate structure with definite fields content for explosion.
//
// Parameters:
//  No.
//
// Returns:
//  Structure - structure with defined fields content
// for explosion.
//
Function GenerateContentStructure() Export
	
	Structure = New Structure();
	
	// Current node description fields.
	Structure.Insert("ProductsAndServices");
	Structure.Insert("Characteristic");
	Structure.Insert("MeasurementUnit");
	Structure.Insert("Quantity");
	Structure.Insert("AccountingPrice");
	Structure.Insert("Cost");
	Structure.Insert("ProductsQuantity");
	Structure.Insert("Specification");
	
	Structure.Insert("ContentRowType");
	Structure.Insert("TableOperations");
	
	// Auxiliary data.
	Structure.Insert("Object");
	Structure.Insert("ProcessingDate", '00010101');
	Structure.Insert("Level");
	Structure.Insert("PriceKind");
	
	Return Structure;
	
EndFunction // GenerateContentStructure()

// Function returns operations table.
//
// Parameters:
//  ContentStructure - Content structure
//
// Returns:
//  Values table with operations.
//
Function GetSpecificationOperations(ContentStructure)
	
	Query = New Query; 
	Query.Text =
	"SELECT
	|	OperationSpecification.Operation AS Operation,
	|	OperationSpecification.TimeNorm / OperationSpecification.ProductsQuantity AS TimeNorm,
	|	OperationSpecification.TimeNorm / OperationSpecification.ProductsQuantity * &Quantity AS Duration,
	|	ISNULL(ProductsAndServicesPricesSliceLast.Price, 0) AS AccountingPrice,
	|	ISNULL(ProductsAndServicesPricesSliceLast.Price, 0) * (1 / OperationSpecification.ProductsQuantity) * &Quantity AS Cost
	|FROM
	|	Catalog.Specifications.Operations AS OperationSpecification
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&ProcessingDate, PriceKind = &PriceKind) AS ProductsAndServicesPricesSliceLast
	|		ON OperationSpecification.Operation = ProductsAndServicesPricesSliceLast.ProductsAndServices
	|WHERE
	|	OperationSpecification.Ref = &Specification
	|	AND Not OperationSpecification.Ref.DeletionMark";
		
	Query.SetParameter("Specification",  ContentStructure.Specification);
	Query.SetParameter("Quantity",	   ContentStructure.Quantity);
	Query.SetParameter("ProcessingDate", ContentStructure.ProcessingDate);
	Query.SetParameter("PriceKind",        ContentStructure.PriceKind);
	
	Return Query.Execute().Unload();
	
EndFunction // GetSpecificationOperations()

// Function returns operations table with norms.
//
// Parameters:
//  ContentStructure - TTManager
//  content structure - TempTablesManager - temporary
// 			   tables by the document
//
// Returns:
//  QueryResultSelection.
//
Function GetSpecificationContent(ContentStructure)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SpecificationsContent.ContentRowType AS ContentRowType,
	|	SpecificationsContent.ProductsAndServices AS ProductsAndServices,
	|	SpecificationsContent.Characteristic AS Characteristic,
	|	SpecificationsContent.MeasurementUnit AS MeasurementUnit,
	|	SpecificationsContent.Specification AS Specification,
	|	ISNULL(SpecificationsContent.Quantity, 0) * &Quantity AS Quantity,
	|	ISNULL(SpecificationsContent.ProductsQuantity, 0) AS ProductsQuantity,
	|	ISNULL(ProductsAndServicesPricesSliceLast.Price, 0) AS AccountingPrice,
	|	0 AS Cost
	|FROM
	|	Catalog.Specifications.Content AS SpecificationsContent
	|		LEFT JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(&ProcessingDate, PriceKind = &PriceKind) AS ProductsAndServicesPricesSliceLast
	|		ON SpecificationsContent.ProductsAndServices = ProductsAndServicesPricesSliceLast.ProductsAndServices
	|			AND SpecificationsContent.Characteristic = ProductsAndServicesPricesSliceLast.Characteristic
	|WHERE
	|	SpecificationsContent.Ref = &Specification
	|	AND (NOT SpecificationsContent.Ref.DeletionMark)";
	
	Query.SetParameter("Specification",  ContentStructure.Specification);
	Query.SetParameter("Quantity",	   ContentStructure.Quantity);
	Query.SetParameter("ProcessingDate", ContentStructure.ProcessingDate);
	Query.SetParameter("PriceKind",        ContentStructure.PriceKind);
		
	Return Query.Execute().Select();
	
EndFunction // GetSpecificationContent()

// Procedure adds new node to products and services stack for explosion.
//
// Parameters:
//  ContentStructure - Structure
// of the ProductsAndServices content - ValuesTable
// products and services stack StackProductsAndServicesStackLogins - ValuesTable NewRowStack
// products and services logons stack - ValueTableRow - String
// stack CurRow     - ValueTableRow - current row.
//
Procedure AddNode(ContentStructure, StackProductsAndServices, StackProductsAndServicesStackEntries, NewRowStack, CurRow)
	
	NewRowStack = StackProductsAndServices.Add();
	NewRowStack.ProductsAndServices	= CurRow.ProductsAndServices;
	NewRowStack.Characteristic = CurRow.Characteristic;
	NewRowStack.Specification	= CurRow.Specification;
	NewRowStack.Level		= CurRow.Level;
	
	// Inserted stack initialization.
	StackProductsAndServicesStackEntries = StackProductsAndServicesStackEntries.CopyColumns();
	NewRowStack.StackEntries = StackProductsAndServicesStackEntries;
	
	// Fill out the content structure.
	ContentStructure.ContentRowType		= CurRow.ContentRowType;
	ContentStructure.ProductsAndServices			= CurRow.ProductsAndServices;
	ContentStructure.Characteristic			= CurRow.Characteristic;
	ContentStructure.MeasurementUnit		= CurRow.MeasurementUnit;
	ContentStructure.Quantity				= CurRow.Quantity / ?(CurRow.ProductsQuantity <> 0, CurRow.ProductsQuantity, 1);
	ContentStructure.ProductsQuantity	= CurRow.ProductsQuantity;
	ContentStructure.Level				= NewRowStack.Level;
	ContentStructure.AccountingPrice			= CurRow.AccountingPrice;
	ContentStructure.Cost				= ContentStructure.Quantity * CurRow.AccountingPrice;
		
	If CurRow.Specification.DeletionMark Then
		ContentStructure.Specification = Catalogs.Specifications.EmptyRef();
	Else
		ContentStructure.Specification = CurRow.Specification;
	EndIf;
		
	ContentStructure.TableOperations = GetSpecificationOperations(ContentStructure);
	
EndProcedure // AddNode()

// Explodes the node.
//
// Parameters:
//  ContentStructure - Structure that describes
// processed node ContentTable - ValuesList
// of the OpertionsTable content - ValueTable of operations.
//  
Procedure RunDenoding(ContentStructure, ContentTable, TableOfOperations) Export
	
	CompositionNewString = ContentTable.Add();
	CompositionNewString.ProductsAndServices		= ContentStructure.ProductsAndServices;
	CompositionNewString.Characteristic	= ContentStructure.Characteristic;
	CompositionNewString.MeasurementUnit	= ContentStructure.MeasurementUnit;
	CompositionNewString.Quantity		= ContentStructure.Quantity;
	CompositionNewString.Level			= ContentStructure.Level;
	CompositionNewString.Node				= False;
	CompositionNewString.AccountingPrice		= ContentStructure.AccountingPrice;
	CompositionNewString.Cost		= ContentStructure.Cost;
	
	If ContentStructure.ContentRowType = Enums.SpecificationContentRowTypes.Node
	 OR ContentStructure.ContentRowType = Enums.SpecificationContentRowTypes.Assembly
	 OR ContentStructure.Level = 0 Then
			
		CompositionNewString.Node			= True;
	 
	 	OperationsString = TableOfOperations.Add();
		OperationsString.ProductsAndServices		= ContentStructure.ProductsAndServices;
		OperationsString.Characteristic	= ContentStructure.Characteristic;
		OperationsString.TimeNorm		= ContentStructure.Quantity;
		OperationsString.Level			= ContentStructure.Level;
		OperationsString.Node				= True;
		
	EndIf;
		
	For Each TSRow IN ContentStructure.TableOperations Do
			
		OperationsString = TableOfOperations.Add();
		OperationsString.ProductsAndServices	= TSRow.Operation;
		OperationsString.TimeNorm = TSRow.TimeNorm;
		OperationsString.Level		= ContentStructure.Level + 1;
		OperationsString.Duration = TSRow.Duration;
		OperationsString.AccountingPrice	= TSRow.AccountingPrice;
		OperationsString.Cost	= TSRow.Cost;
		OperationsString.Node			= False;
	
	EndDo;
		
EndProcedure // RunExplosion()	

// Explosion procedure.
//
// Parameters:
//  ContentStructure - Structure that describes
// processed
// node Object ContentTable - ValuesList
// of the OpertionsTable content - ValueTable of operations.
//  
Procedure Denoding(ContentStructure, ContentTable, TableOfOperations) Export
	
	// Initialization of products and services stack.
	StackProductsAndServices = New ValueTable();
	StackProductsAndServices.Columns.Add("ProductsAndServices");
	StackProductsAndServices.Columns.Add("Characteristic");
	StackProductsAndServices.Columns.Add("Specification");
	StackProductsAndServices.Columns.Add("Level");
	
	StackProductsAndServices.Columns.Add("StackEntries");
	
	StackProductsAndServices.Indexes.Add("ProductsAndServices, Characteristic, Specification");
	
	// Entries table initialization.
	StackProductsAndServicesStackEntries = New ValueTable();
	StackProductsAndServicesStackEntries.Columns.Add("ContentRowType");
	StackProductsAndServicesStackEntries.Columns.Add("ProductsAndServices");
	StackProductsAndServicesStackEntries.Columns.Add("Characteristic");
	StackProductsAndServicesStackEntries.Columns.Add("MeasurementUnit");
	StackProductsAndServicesStackEntries.Columns.Add("Quantity");
	StackProductsAndServicesStackEntries.Columns.Add("ProductsQuantity");
	StackProductsAndServicesStackEntries.Columns.Add("Specification");
	StackProductsAndServicesStackEntries.Columns.Add("Level");
	StackProductsAndServicesStackEntries.Columns.Add("AccountingPrice");
	StackProductsAndServicesStackEntries.Columns.Add("Cost");
	
	ContentStructure.TableOperations = GetSpecificationOperations(ContentStructure);
	
	ContentStructure.Level = 0;
	
	// Initial filling of the stack.
	NewRowStack = StackProductsAndServices.Add();
	NewRowStack.ProductsAndServices	= ContentStructure.ProductsAndServices;
	NewRowStack.Characteristic	= ContentStructure.Characteristic;
	NewRowStack.Specification	= ContentStructure.Specification;
	NewRowStack.Level		= ContentStructure.Level;
	
	NewRowStack.StackEntries		= StackProductsAndServicesStackEntries;
	
	RunDenoding(ContentStructure, ContentTable, TableOfOperations);
	
	// Until we have what to explode.
	While StackProductsAndServices.Count() <> 0 Do
		
		ProductsAndServicesSelection = GetSpecificationContent(ContentStructure);
		
		While ProductsAndServicesSelection.Next() Do
			
			If Not ValueIsFilled(ProductsAndServicesSelection.ProductsAndServices) Then
				Continue;
			EndIf;
			
			// Check the recursive input.
			SearchStructure = New Structure;
			SearchStructure.Insert("ProductsAndServices",	ProductsAndServicesSelection.ProductsAndServices);
			SearchStructure.Insert("Characteristic",	ProductsAndServicesSelection.Characteristic);
			SearchStructure.Insert("Specification",	ProductsAndServicesSelection.Specification);
			
			RecursiveEntryStrings = StackProductsAndServices.FindRows(SearchStructure);
			
			If RecursiveEntryStrings.Count() <> 0 Then
				
				For Each EntAttributeString IN RecursiveEntryStrings Do
					
					MessageText = NStr("en='Recursive item inclusion is found';ru='Обнаружено рекурсивное вхождение элемента';vi='Tìm thấy mục lọt vào có tính đệ quy của phần tử'")+" "+ProductsAndServicesSelection.ProductsAndServices+" "+NStr("en='to item';ru='в элемент';vi='vào phần tử'")+" "+ContentStructure.ProductsAndServices+"!";
					ShowMessageAboutError(ContentStructure.Object, MessageText);
					
				EndDo;
				
				Continue;
				
			EndIf;
			
			// Adding new nodes.
			NewStringEnter = StackProductsAndServicesStackEntries.Add();
			NewStringEnter.ContentRowType	= ProductsAndServicesSelection.ContentRowType;
			NewStringEnter.ProductsAndServices		= ProductsAndServicesSelection.ProductsAndServices;
			NewStringEnter.Characteristic		= ProductsAndServicesSelection.Characteristic;
			NewStringEnter.MeasurementUnit	= ProductsAndServicesSelection.MeasurementUnit;
			
			RateUnitDimensions			= ?(TypeOf(ContentStructure.MeasurementUnit) = Type("CatalogRef.UOM"),
														ContentStructure.MeasurementUnit.Factor,
														1);
														
			NewStringEnter.Quantity			= ProductsAndServicesSelection.Quantity * RateUnitDimensions;
			NewStringEnter.ProductsQuantity = ProductsAndServicesSelection.ProductsQuantity;
			NewStringEnter.Specification		= ProductsAndServicesSelection.Specification;
			NewStringEnter.Level				= NewRowStack.Level + 1;
			NewStringEnter.AccountingPrice			= Number(ProductsAndServicesSelection.AccountingPrice);
			NewStringEnter.Cost			= Number(ProductsAndServicesSelection.Cost) * RateUnitDimensions;
			
		EndDo; // ProductsAndServicesSelection
		
		// Branch end or not?
		If StackProductsAndServicesStackEntries.Count() = 0 Then
			
			// Delete products and services that do not contain continuation from stack.
			StackProductsAndServices.Delete(NewRowStack);
			
			ReadinessFlag = True;
			While StackProductsAndServices.Count() <> 0 AND ReadinessFlag Do
				
				// Receive the previous products and services stack row.
				PreStringProductsAndServicesStack = StackProductsAndServices.Get(StackProductsAndServices.Count() - 1);
				
				// Delete entries from the stack.
				PreStringProductsAndServicesStack.StackEntries.Delete(0);
					
				If PreStringProductsAndServicesStack.StackEntries.Count() = 0 Then
					
					// If login stack is empty, delete row from products and services stack.
					StackProductsAndServices.Delete(PreStringProductsAndServicesStack);
					
				Else // explode the following products and services from the logins stack.
					
					ReadinessFlag = False;
					
					CurRow = PreStringProductsAndServicesStack.StackEntries.Get(0);
					
					AddNode(ContentStructure, StackProductsAndServices, StackProductsAndServicesStackEntries, NewRowStack, CurRow);
					RunDenoding(ContentStructure, ContentTable, TableOfOperations);
					
				EndIf;
				
			EndDo;
			
		Else // add nodes
			
			CurRow = StackProductsAndServicesStackEntries.Get(0);
			
			AddNode(ContentStructure, StackProductsAndServices, StackProductsAndServicesStackEntries, NewRowStack, CurRow);
			RunDenoding(ContentStructure, ContentTable, TableOfOperations);
			
		EndIf;
		
	EndDo; // StackProductsAndServices
	
EndProcedure // Denoding() 

///////////////////////////////////////////////////////////////////////////////// 
// PROCEDURES AND FUNCTIONS OF PRINTING FORMS GENERATING

// Procedure fills in full name by the employee name.
//
Procedure SurnameInitialsByName(Initials, Description) Export
	
	If IsBlankString(Description) Then
		
		Return;
		
	EndIf;
	
	SubstringArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(Description, " ");
	Surname		= SubstringArray[0];
	Name 		= ?(SubstringArray.Count() > 1, SubstringArray[1], "");
	Patronymic	= ?(SubstringArray.Count() > 2, SubstringArray[2], "");
	
	Initials = SmallBusinessServer.GetSurnameNamePatronymic(Surname, Name, Patronymic, False);
	
EndProcedure // InitialsEmployeeName()

// Function returns products and services presentation for printing.
//
Function GetProductsAndServicesPresentationForPrinting(ProductsAndServices, Characteristic = Undefined, SKU = "", SerialNumbers = "")  Export

	AddCharacteristics = "";
	If Constants.FunctionalOptionUseCharacteristics.Get() AND ValueIsFilled(Characteristic) Then
		AddCharacteristics = AddCharacteristics + " (" + TrimAll(Characteristic) + ")";
	EndIf;
	
	ProductsAndServicesSKUInContent = Constants.ProductsAndServicesSKUInContent.Get();
	If ProductsAndServicesSKUInContent Then
		
		StringSKU = TrimAll(SKU);
		If ValueIsFilled(StringSKU) Then
			
			StringSKU = ", " + StringSKU;
			
		EndIf;
		
	Else
		
		StringSKU = "";
		
	EndIf;
	
	TextInBrackets = "";
	If AddCharacteristics <> "" AND SerialNumbers <> "" Then
		TextInBrackets =  " (" + AddCharacteristics + " " + SerialNumbers + ")";
	ElsIf AddCharacteristics <> "" Then
		TextInBrackets =  " (" + AddCharacteristics + ")";
	ElsIf SerialNumbers <> "" Then
		TextInBrackets = " (" + SerialNumbers + ")";
	EndIf;
	
	If TextInBrackets <> "" OR ValueIsFilled(StringSKU) Then
		Return TrimAll(ProductsAndServices) + TextInBrackets + StringSKU;
	Else
		Return TrimAll(ProductsAndServices);
	EndIf;

EndFunction // GetProductsAndServicesPresentationForPrinting()

// The function returns a set of data about an individual as a structure, The set of data includes full name, position in the organization, passport data etc..
//
// Parameters:
//  Company  - CatalogRef.Companies - company
//                 by which a position and
//  department of the employee is determined Individual      - CatalogRef.Individuals - individual
//                 on which CutoffDate data set
//  is returned    - Date - date on which
//  the DescriptionFullNameShort data is read    - Boolean - If True (by default), then
//                 the individual presentation includes a last name and initials if False - surname
//                 or name and patronymic.
//
// Returns:
//  Structure    - Structure with data set about individual:
//                 "LastName",
//                 "Name"
//                 "Patronymic"
//                 "Presentation (Full name)"
//                 "Department"
//                 "DocumentKind"
//                 "DocumentSeries"
//                 "DocumentNumber"
//                 "DocumentDateIssued"
//                 "DocumentIssuedBy"
//                 "DocumentDepartmentCode".
//
Function IndData(Company, Ind, CutoffDate, NameAndSurnameShort = True) Export
	
	PersonalQuery = New Query();
	PersonalQuery.SetParameter("CutoffDate", CutoffDate);
	PersonalQuery.SetParameter("Company", SmallBusinessServer.GetCompany(Company));
	PersonalQuery.SetParameter("Ind", Ind);
	PersonalQuery.Text =
	"SELECT
	|	IndividualsDescriptionFullSliceLast.Surname,
	|	IndividualsDescriptionFullSliceLast.Name,
	|	IndividualsDescriptionFullSliceLast.Patronymic,
	|	Employees.Department,
	|	Employees.EmployeeCode,
	|	Employees.Position,
	|	IndividualsDocumentsSliceLast.DocumentKind AS DocumentKind1,
	|	IndividualsDocumentsSliceLast.Series AS DocumentSeries,
	|	IndividualsDocumentsSliceLast.Number AS DocumentNumber,
	|	IndividualsDocumentsSliceLast.IssueDate AS DocumentIssueDate,
	|	IndividualsDocumentsSliceLast.WhoIssued AS DocumentWhoIssued,
	|	IndividualsDocumentsSliceLast.DepartmentCode AS DocumentCodeDepartments
	|FROM
	|	(SELECT
	|		Individuals.Ref AS Ind
	|	FROM
	|		Catalog.Individuals AS Individuals
	|	WHERE
	|		Individuals.Ref = &Ind) AS NatPerson
	|		LEFT JOIN InformationRegister.IndividualsDescriptionFull.SliceLast(&CutoffDate, Ind = &Ind) AS IndividualsDescriptionFullSliceLast
	|		ON NatPerson.Ind = IndividualsDescriptionFullSliceLast.Ind
	|		LEFT JOIN InformationRegister.IndividualsDocuments.SliceLast(
	|				&CutoffDate,
	|				Ind = &Ind
	|					AND IsIdentityDocument) AS IndividualsDocumentsSliceLast
	|		ON NatPerson.Ind = IndividualsDocumentsSliceLast.Ind
	|		LEFT JOIN (SELECT TOP 1
	|			Employees.Employee.Code AS EmployeeCode,
	|			Employees.Employee.Ind AS Ind,
	|			Employees.Position AS Position,
	|			Employees.StructuralUnit AS Department
	|		FROM
	|			InformationRegister.Employees.SliceLast(
	|					&CutoffDate,
	|					Employee.Ind = &Ind
	|						AND Company = &Company) AS Employees
	|		WHERE
	|			Employees.StructuralUnit <> VALUE(Catalog.StructuralUnits.EmptyRef)
		
	|		ORDER BY
	|			Employees.Employee.OccupationType.Order DESC) AS Employees
	|		ON NatPerson.Ind = Employees.Ind";
	
	Data = PersonalQuery.Execute().Select();
	Data.Next();
	
	Result = New Structure("Surname, Name, Patronymic, Presentation, EmployeeCode, Position, Department, DocumentKind, DocumentSeries, DocumentNumber, DocumentIssueDate, DocumentWhoIssued, DocumentDepartmentCode, DocumentPresentation");

	FillPropertyValues(Result, Data);

	Result.Presentation = GetSurnameNamePatronymic(Data.Surname, Data.Name, Data.Patronymic, NameAndSurnameShort);
	Result.DocumentPresentation = GetNatPersonDocumentPresentation(Data);
	
	Return Result;
	
EndFunction // IndData()

// The function returns info on the company responsible
// employees and their positions.
//
// Parameters:
//  Company - Compound
//                 type: CatalogRef.Companies,
//                 CatalogRef.PettyCashes, CatalogRef.StoragePlaces  organizational unit
//                 for which it is
//  reqired to get information about responsible people CutoffDate    - Date - date on which data is read.
//
// Returns:
//  Structure    - Structure with info on the
//                 structural unit individuals.
//
Function OrganizationalUnitsResponsiblePersons(OrganizationalUnit, CutoffDate) Export
	
	Result = New Structure("ManagerDescriptionFull, ChiefAccountantDescriptionFull, CashierDescriptionFull, WarehouseManDescriptionFull");
	
	// Refs
	Result.Insert("Head");
	Result.Insert("ChiefAccountant");
	Result.Insert("Cashier");
	Result.Insert("WarehouseMan");
	
	// Full name presentation
	Result.Insert("HeadDescriptionFull");
	Result.Insert("ChiefAccountantNameAndSurname");
	Result.Insert("CashierNameAndSurname");
	Result.Insert("WarehouseManSNP");
	
	// Positions presentation (ref)
	Result.Insert("HeadPositionRefs");
	Result.Insert("ChiefAccountantPositionRef");
	Result.Insert("CashierPositionRefs");
	Result.Insert("WarehouseManPositionRef");
	
	// Position presentation
	Result.Insert("HeadPosition");
	Result.Insert("ChiefAccountantPosition");
	Result.Insert("CashierPosition");
	Result.Insert("WarehouseMan_Position");
	
	If OrganizationalUnit <> Undefined Then
	
		Query = New Query;
		Query.SetParameter("CutoffDate", CutoffDate);
		Query.SetParameter("OrganizationalUnit", OrganizationalUnit);
		
		Query.Text = 
		"SELECT
		|	ResponsiblePersonsSliceLast.Company AS OrganizationalUnit,
		|	ResponsiblePersonsSliceLast.ResponsiblePersonType AS ResponsiblePersonType,
		|	ResponsiblePersonsSliceLast.Employee AS Employee,
		|	CASE
		|		WHEN IndividualsDescriptionFullSliceLast.Ind IS NULL 
		|			THEN ResponsiblePersonsSliceLast.Employee.Description
		|		ELSE IndividualsDescriptionFullSliceLast.Surname + "" "" + IndividualsDescriptionFullSliceLast.Name + "" "" + IndividualsDescriptionFullSliceLast.Patronymic + "" ""
		|	END AS Individual,
		|	ResponsiblePersonsSliceLast.Position AS Position,
		|	ResponsiblePersonsSliceLast.Position.Description AS AppointmentName
		|FROM
		|	InformationRegister.ResponsiblePersons.SliceLast(&CutoffDate, Company = &OrganizationalUnit) AS ResponsiblePersonsSliceLast
		|		LEFT JOIN InformationRegister.IndividualsDescriptionFull.SliceLast AS IndividualsDescriptionFullSliceLast
		|		ON ResponsiblePersonsSliceLast.Employee.Ind = IndividualsDescriptionFullSliceLast.Ind";
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			If Selection.ResponsiblePersonType 	= Enums.ResponsiblePersonTypes.Head Then
				
				Result.Head					= Selection.Employee;
				Result.HeadDescriptionFull				= Selection.Individual;
				Result.HeadPositionRefs	= Selection.Position;
				Result.HeadPosition			= Selection.AppointmentName;
				
			ElsIf Selection.ResponsiblePersonType = Enums.ResponsiblePersonTypes.ChiefAccountant Then
				
				Result.ChiefAccountant				= Selection.Employee;
				Result.ChiefAccountantNameAndSurname 		= Selection.Individual;
				Result.ChiefAccountantPositionRef = Selection.Position;
				Result.ChiefAccountantPosition		= Selection.AppointmentName;
				
			ElsIf Selection.ResponsiblePersonType = Enums.ResponsiblePersonTypes.Cashier Then
				
				Result.Cashier						= Selection.Employee;
				Result.CashierNameAndSurname					= Selection.Individual;
				Result.CashierPositionRefs 		= Selection.Position;
				Result.CashierPosition				= Selection.AppointmentName;
				
			ElsIf Selection.ResponsiblePersonType = Enums.ResponsiblePersonTypes.WarehouseMan Then
				
				Result.WarehouseMan						= Selection.Employee;
				Result.WarehouseManSNP					= Selection.Individual;
				Result.WarehouseManPositionRef		= Selection.Position;
				Result.WarehouseMan_Position			= Selection.AppointmentName;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result
	
EndFunction // OrganizationalUnitResponsiblePerson()

// Receive a presentation of the identity document.
//
// Parameters
//  IndData - Collection of bodies data. bodies (structure, table row
//                 ...) containing values: DokumentKind,
//                 DokumentSeries, DokumentNumber, IssuedateDokument, DocumentWhoIssued.  
//
// Returns:
//   String      - Identity papers presentation.
//
Function GetNatPersonDocumentPresentation(IndData) Export

	Return String(IndData.DocumentKind1) + " Series " +
			IndData.DocumentSeries       + ", number " +
			IndData.DocumentNumber       + ", issued " +
			Format(IndData.DocumentIssueDate, "DF=dd.MM.yyyy")  + " " +
			IndData.DocumentWhoIssued;

EndFunction // GetDocumentPresentationIndividuals()

// Procedure is designed to convert document number.
//
// Parameters:
//  Document     - (DocumentRef), document which number
//                 should be received for printing.
//
// Return value.
//  String       - document number for printing
//
Function GetNumberForPrinting(DocumentNumber, Prefix) Export

	If Not ValueIsFilled(DocumentNumber) Then 
		Return 0;
	EndIf;

	Number = TrimAll(DocumentNumber);
	
	// delete prefix from the document number
	If Find(Number, Prefix)=1 Then 
		Number = Mid(Number, StrLen(Prefix)+1);
	EndIf;
	
	ExchangePrefix = "";
			
	If GetFunctionalOption("UseDataSynchronization")
		AND ValueIsFilled(Constants.DistributedInformationBaseNodePrefix.Get()) Then		
		ExchangePrefix = TrimAll(Constants.DistributedInformationBaseNodePrefix.Get());		
	EndIf;
	
	// delete prefix from the document number
	If Find(Number, ExchangePrefix)=1 Then 
		Number = Mid(Number, StrLen(ExchangePrefix)+1);
	EndIf;
	
	// also "minus" may be in front
	If Left(Number, 1) = "-" Then
		Number = Mid(Number, 2);
	EndIf;
	
	// delete leading nulls
	While Left(Number, 1)="0" Do
		Number = Mid(Number, 2);
	EndDo;

	Return Number;

EndFunction // GetNumberForPrinting()

Function GetNumberForPrintingConsideringDocumentDate(DocumentDate, DocumentNumber, Prefix) Export
	
	If DocumentDate < Date('20110101') Then
		
		Return SmallBusinessServer.GetNumberForPrinting(DocumentNumber, Prefix);
		
	Else
		
		Return ObjectPrefixationClientServer.GetNumberForPrinting(DocumentNumber, True, True);
		
	EndIf;
	
EndFunction

// Returns the data structure with the consolidated counterparty description.
//
// Parameters: 
//  ListInformation - values list with parameters values
//   of InformationList company is
//  generated by the InfoAboutLegalEntityIndividual function List         - company desired parameters
//  list WithPrefix     - Shows whether to output company parameter prefix or not
//
// Returns:
//  String - company specifier / counterparty / individuals.
//
Function CompaniesDescriptionFull(ListInformation, List = "", WithPrefix = True) Export

	If IsBlankString(List) Then
		List = "FullDescr,TIN,LegalAddress,PhoneNumbers,Fax,AccountNo,Bank,SWIFT,CorrAccount";
	EndIf; 

	Result = "";

	AccordanceOfParameters = New Map();
	AccordanceOfParameters.Insert("FullDescr",			" ");
	AccordanceOfParameters.Insert("TIN",				" MST ");
	AccordanceOfParameters.Insert("RegistrationNumber",	" ");
	AccordanceOfParameters.Insert("LegalAddress",		" ");
	AccordanceOfParameters.Insert("PostalAddress",		" ");
	AccordanceOfParameters.Insert("PhoneNumbers",		" tel.: ");
	AccordanceOfParameters.Insert("Fax",				" fax: ");
	AccordanceOfParameters.Insert("AccountNo",			" số tài khoản ");
	AccordanceOfParameters.Insert("Bank",				" tại ngân hàng ");
	AccordanceOfParameters.Insert("SWIFT",				" SWIFT ");
	AccordanceOfParameters.Insert("CorrAccount",		" corr. account ");

	List          = List + ?(Right(List, 1) = ",", "", ",");
	NumberOfParameters = StrOccurrenceCount(List, ",");

	For Counter = 1 to NumberOfParameters Do

		CommaPos = Find(List, ",");

		If CommaPos > 0  Then
			ParameterName = Left(List, CommaPos - 1);
			List = Mid(List, CommaPos + 1, StrLen(List));
			
			Try
				AdditionString = "";
				ListInformation.Property(ParameterName, AdditionString);
				
				If IsBlankString(AdditionString) Then
					Continue;
				EndIf;
				
				Prefix = AccordanceOfParameters[TrimAll(ParameterName)];
				If Not IsBlankString(Result)  Then
					Result = Result + ", ";
				EndIf; 

				Result = Result + ?(WithPrefix = True, Prefix, "") + AdditionString;

			Except

				Message = New UserMessage();
				Message.Text = NStr("en='Failed to define the value of Company parameter ';ru='Не удалось определить значение параметра организации: ';vi='Không thể xác định giá trị tham số tổ chức:'") + ParameterName;
				Message.Message();

			EndTry;

		EndIf; 

	EndDo;

	Return TrimAll(Result);

EndFunction // CompanyDescription()

// Standard formatting function of quantity writing.
//
// Parameters:
//  Count   - number that you want to format.
//
// Returns:
//  Properly formatted string presentation of the quantity.
//
Function QuantityInWords(Count) Export

	IntegralPart   = Int(Count);
	FractionalPart = Round(Count - IntegralPart, 3);

	If FractionalPart = Round(FractionalPart,0) Then
		ProtocolParameters = ", , , , , , , , 0";
   	ElsIf FractionalPart = Round(FractionalPart, 1) Then
		ProtocolParameters = "integer, integer, integer, F, tenth, tenth, tenth, M, 1";
   	ElsIf FractionalPart = Round(FractionalPart, 2) Then
		ProtocolParameters = "integer, integer, integer, F, hundredth, hundredth, hundredth, M, 2";
   	Else
		ProtocolParameters = "integer, integer, integer, F, thousandth, thousandth, thousandth, M, 3";
    EndIf;

	Return NumberInWords(Count, ,ProtocolParameters);

EndFunction // QuantityInWords()

// Function generates information about the specified LegEntInd. Details include -
// name, address, phone number, bank connection.
//
// Parameters: 
//  LegalEntityIndividual    - company or individual for
//                 whom
//  info is collected PeriodDate  - date on which information about
//  LegEntInd ForIndividualOnlyInitials is selected - For ind. bodies output only name and
//                 patonymic initials
//
// Returns:
//  Information - collected info.
//
Function InfoAboutLegalEntityIndividual(LegalEntityIndividual, PeriodDate, ForIndividualOnlyInitials = True, BankAccount = Undefined) Export

	Information	= New Structure("Presentation, FullDescr, TIN, RegistrationNumber, PhoneNumbers, Fax, LegalAddress, Bank, SWIFT, CorrAccount, CorrespondentText, AccountNo, BankAddress, Email");
	Query		= New Query;
	Data		= Undefined;

	If Not ValueIsFilled(LegalEntityIndividual) Then
		Return Information;
	EndIf;

	If BankAccount = Undefined OR BankAccount.IsEmpty() Then
		CurrentBankAccount = LegalEntityIndividual.BankAccountByDefault;
	Else
		CurrentBankAccount = BankAccount;
	EndIf;
	
	// Select main information about counterparty LegalEntityIndividual.MainBankAccount.Empty
	If CurrentBankAccount.AccountsBank.IsEmpty() Then
		BankAttributeName = "Bank";
	Else
		BankAttributeName = "AccountsBank";
	EndIf;
	
	If TypeOf(LegalEntityIndividual) = Type("CatalogRef.Companies") Then
		CatalogName = "Companies";
	ElsIf TypeOf(LegalEntityIndividual) = Type("CatalogRef.Counterparties") Then
		CatalogName = "Counterparties";
	Else
		Return Information;
	EndIf;

	Query.SetParameter("ParLegEntInd",      LegalEntityIndividual);
	Query.SetParameter("ParBankAccount",	CurrentBankAccount);

	Query.Text = 
	"SELECT
	|	Companies.Presentation AS Description,
	|	Companies.DescriptionFull AS FullDescr,
	|	Companies.TIN,
	|	Companies.RegistrationNumber,";
	
	If Not ValueIsFilled(CurrentBankAccount) Then
	
		Query.Text = Query.Text + "
		|	""""                          AS AccountNo,
		|	""""                          AS CorrespondentText,
		|	""""                          AS Bank,
		|	""""                          AS SWIFT,
		|	""""                          AS CorrAccount,
		|	""""                          AS BankAddress
		|FROM
		|	Catalog."+CatalogName+" AS Companies
		|WHERE Companies.Ref = &ParLegEntInd";
	
	Else
	
		Query.Text = Query.Text + "
		|	BankAccounts.AccountNo							AS AccountNo,
		|	BankAccounts.CorrespondentText					AS CorrespondentText,
		|	BankAccounts."+BankAttributeName+"				AS Bank, 
		|	BankAccounts."+BankAttributeName+".Code			AS SWIFT,
		|	BankAccounts."+BankAttributeName+".CorrAccount	AS CorrAccount, 
		|	BankAccounts."+BankAttributeName+".Address		AS BankAddress
		|FROM 
		|	Catalog."+CatalogName+" AS Companies, 
		|	Catalog.BankAccounts AS BankAccounts
		|
		|WHERE
		|	Companies.Ref			= &ParLegEntInd
		|	AND BankAccounts.Ref	= &ParBankAccount";
		
	EndIf;
	
	Data = Query.Execute().Select();
	Data.Next();

	Information.Insert("FullDescr", Data.FullDescr);

	If Data <> Undefined Then

		If TypeOf(LegalEntityIndividual) = Type("CatalogRef.Companies") Then
			
			Phone		= Catalogs.ContactInformationKinds.CompanyPhone;
			Fax			= Catalogs.ContactInformationKinds.CompanyFax;
			LegAddress	= Catalogs.ContactInformationKinds.CompanyLegalAddress;
			RealAddress	= Catalogs.ContactInformationKinds.CompanyActualAddress;
			PostAddress	= Catalogs.ContactInformationKinds.CompanyPostalAddress;
			Email		= Catalogs.ContactInformationKinds.CompanyEmail;
			
		ElsIf TypeOf(LegalEntityIndividual) = Type("CatalogRef.Individuals") Then
			
			Phone		= Catalogs.ContactInformationKinds.IndividualPhone;
			Fax			= Catalogs.ContactInformationKinds.EmptyRef();
			LegAddress	= Catalogs.ContactInformationKinds.IndividualPostalAddress;
			RealAddress	= Catalogs.ContactInformationKinds.IndividualActualAddress;
			PostAddress	= Catalogs.ContactInformationKinds.IndividualPostalAddress;
			Email		= Catalogs.ContactInformationKinds.IndividualEmail;
			
		ElsIf TypeOf(LegalEntityIndividual) = Type("CatalogRef.Counterparties") Then
			
			Phone		= Catalogs.ContactInformationKinds.CounterpartyPhone;
			Fax			= Catalogs.ContactInformationKinds.CounterpartyFax;
			LegAddress	= Catalogs.ContactInformationKinds.CounterpartyLegalAddress;
			RealAddress	= Catalogs.ContactInformationKinds.CounterpartyActualAddress;
			PostAddress	= Catalogs.ContactInformationKinds.CounterpartyPostalAddress;
			Email		= Catalogs.ContactInformationKinds.CounterpartyEmail;
			
		Else
			
			Phone		= Catalogs.ContactInformationKinds.EmptyRef();
			Fax			= Catalogs.ContactInformationKinds.EmptyRef();
			LegAddress	= Catalogs.ContactInformationKinds.EmptyRef();
			RealAddress	= Catalogs.ContactInformationKinds.EmptyRef();
			PostAddress	= Catalogs.ContactInformationKinds.EmptyRef();
			Email		= Undefined;
			
		EndIf;
		
		Information.Insert("Presentation",			Data.Description);
		Information.Insert("TIN",					Data.TIN);
		Information.Insert("RegistrationNumber",	Data.RegistrationNumber);
		Information.Insert("PhoneNumbers",			GetContactInformation(LegalEntityIndividual, Phone));
		Information.Insert("Fax",					GetContactInformation(LegalEntityIndividual, Fax));
		Information.Insert("AccountNo",				Data.AccountNo);
		Information.Insert("Bank",					Data.Bank);
		Information.Insert("SWIFT",					Data.SWIFT);
		Information.Insert("BankAddress",			Data.BankAddress);
		Information.Insert("CorrAccount",			Data.CorrAccount);
		Information.Insert("CorrespondentText",		Data.CorrespondentText);
		Information.Insert("LegalAddress",			GetContactInformation(LegalEntityIndividual, LegAddress));
		Information.Insert("ActualAddress",			GetContactInformation(LegalEntityIndividual, RealAddress));
		Information.Insert("MailAddress",			GetContactInformation(LegalEntityIndividual, PostAddress));
		
		If ValueIsFilled(Email) Then
			
			Information.Insert("Email", GetContactInformation(LegalEntityIndividual, Email));
			
		EndIf;
		
		If Not ValueIsFilled(Information.FullDescr) Then
			
			Information.FullDescr = Information.Presentation;
			
		EndIf;

	EndIf;

	Return Information;

EndFunction // InfoAboutLegalEntityIndividual()

// The function finds an actual address value in contact information.
//
// Parameters:
//  Object       - CatalogRef, contact
//  information object AddressType    - contact information type.
//
// Returned
//  value String - found address presentation.
//                                          
Function GetContactInformation(ContactInformationObject, InformationKind) Export
	
	If TypeOf(ContactInformationObject) = Type("CatalogRef.Companies") Then
		
		SourceTable = "Companies";
		
	ElsIf TypeOf(ContactInformationObject) = Type("CatalogRef.Individuals") Then
		
		SourceTable = "Individuals";
		
	ElsIf TypeOf(ContactInformationObject) = Type("CatalogRef.Counterparties") Then
		
		SourceTable = "Counterparties";
		
	Else 
		
		Return "";
		
	EndIf;
	
	Query = New Query;
	
	Query.SetParameter("Object", ContactInformationObject);
	Query.SetParameter("Kind",	InformationKind);
	
	Query.Text = "SELECT 
	|	ContactInformation.Presentation
	|FROM
	|	Catalog." + SourceTable + ".ContactInformation
	|AS
	|ContactInformation WHERE ContactInformation.Kind
	|	= &Kind And ContactInformation.Ref = &Object";

	QueryResult = Query.Execute();
	
	Return ?(QueryResult.IsEmpty(), "", QueryResult.Unload()[0].Presentation);

EndFunction // GetAddressFromContactInformation()

// Standard for this configuration function of amounts formatting
//
// Parameters: 
//  Amount        - number that should be
// formatted Currency       - reference to the item of currencies catalog, if
//                 set, then NZ currency presentation will
//  be added to the resulting string           - String that presents the
//  zero value of NGS number          - character-separator of groups of number integral part.
//
// Returns:
//  Properly formatted string representation of the amount.
//
Function AmountsFormat(Amount, Currency = Undefined, NZ = "", NGS = "") Export

	FormatString = "ND=15;NFD=2" +
					?(NOT ValueIsFilled(NZ), "", ";" + "NZ=" + NZ) +
					?(NOT ValueIsFilled(NGS),"", ";" + "NGS=" + NGS);

	ResultString = TrimL(Format(Amount, FormatString));
	
	If ValueIsFilled(Currency) Then
		ResultString = ResultString + " " + TrimR(Currency);
	EndIf;

	Return ResultString;

EndFunction // AmountsFormat()

// Function generates amount presentation with signature in the specified currency.
//
// Returns:
//  String - amount in writing.
//
Function GenerateAmountInWords(Amount, Currency) Export

	If Currency.InWordParametersInHomeLanguage = "" Then
		Return AmountsFormat(Amount);
	Else
		Return NumberInWords(Amount, , Currency.InWordParametersInHomeLanguage);
	EndIf;

EndFunction // GenerateAmountInWords()

// Generates bank payment document amount.
//
// Parameters:
//  Amount        - Number - attribute that
//  should be formatted OutputAmountWithoutKopeks - Boolean - check box of amount presentation without kopeks.
//
// Return
//  value Formatted string.
//
Function FormatPaymentDocumentSUM(Amount, DisplayAmountWithoutCents = False) Export
	
	Result  = Amount;
	IntegralPart = Int(Amount);
	
	If Result = IntegralPart Then
		If DisplayAmountWithoutCents Then
			Result = Format(Result, "NFD=2; NDS='='; NG=0");
			Result = Left(Result, Find(Result, "="));
		Else
			Result = Format(Result, "NFD=2; NDS='-'; NG=0");
		EndIf;
	Else
		Result = Format(Result, "NFD=2; NDS='-'; NG=0");
	EndIf;
	
	Return Result;
	
EndFunction // FormatPaymentDocumentAmount()

// Formats amount in writing of banking payment document.
//
// Parameters:
//  Amount        - Number - attribute that should be
// presented in writing Currency       - CatalogRef.Currencies - currency in which
//                 amount
//  should be OutputAmoutWithoutKopek - Boolean - check box of amount presentation without kopeks.
//
// Return
//  value Formatted string.
//
Function FormatPaymentDocumentAmountInWords(Amount, Currency, DisplayAmountWithoutCents = False) Export
	
	Result     = Amount;
	IntegralPart    = Int(Amount);
	FormatString  = "L=en_EN; FS=False";
	SubjectParam = Currency.InWordParametersInHomeLanguage;
	
	If Result = IntegralPart Then
		If DisplayAmountWithoutCents Then
			Result = NumberInWords(Result, FormatString, SubjectParam);
			Result = Left(Result, Find(Result, "0") - 1);
		Else
			Result = NumberInWords(Result, FormatString, SubjectParam);
		EndIf;
	Else
		Result = NumberInWords(Result, FormatString, SubjectParam);
	EndIf;
	
	Return Result;
	
EndFunction // FormatPaymentDocumentAmountInWording()

// Sets the Long operation state for an item form of the tabular document type
//
Procedure StateDocumentsTableLongOperation(FormItem, StatusText = "") Export
	
	StatePresentation = FormItem.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	StatePresentation.Picture = PictureLib.LongOperation48;
	StatePresentation.Text = StatusText;
	
EndProcedure // TabularDocumentsLongOperationState()

// Sets the Long operation state for an item form of the tabular document type
//
Procedure NotActualSpreadsheetDocumentState(FormItem, StatusText = "") Export
	
	StatePresentation = FormItem.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	StatePresentation.Picture = New Picture;
	StatePresentation.Text = StatusText;
	
EndProcedure // TabularDocumentsLongOperationState()

// Sets the Long operation state for an item form of the tabular document type
//
Procedure SpreadsheetDocumentStateActual(FormItem) Export
	
	StatePresentation = FormItem.StatePresentation;
	StatePresentation.Visible = False;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	StatePresentation.Picture = New Picture;
	StatePresentation.Text = "";
	
EndProcedure // TabularDocumentsLongOperationState()

// Checks if the pass table documents fit in the printing page.
//
// Parameters
//  TabDocument       - Tabular
//  document DisplayedAreas - Array of checked tables or
//  tabular document ResultOnError - Which result to return if an error occurs
//
// Returns:
//   Boolean   - whether the sent documents fit in or not
//
Function SpreadsheetDocumentFitsPage(Spreadsheet, AreasToPut, ResultOnError = True)

	Try
		Return Spreadsheet.CheckPut(AreasToPut);
	Except
		ErrorDescription = ErrorInfo();
		WriteLogEvent(
			NSTr("ru = 'Невозможно получить информацию о текущем принтере (возможно, в системе не установлено ни одного принтера)';
				|vi = 'Không thể nhận thông tin về máy in hiện tại (có thể, trong hệ thống chưa thiết lập máy in nào)';
				|en = 'Cannot get information about the current printer (maybe, no printers are installed in the application)'"),
			EventLogLevel.Error,,, ErrorDescription.Definition);
		Return ResultOnError;
	EndTry;

EndFunction // CheckTabularDocumentOutput()

// Count sheets quantity in document
//
Function CheckAccountsInvoicePagePut(Spreadsheet, AreaCurRows, IsLastRow, Template, NumberWorksheet, InvoiceNumber) Export
	
	// Check whether it is possible to output tabular document
	RowWithFooter = New Array;
	RowWithFooter.Add(AreaCurRows);
	If IsLastRow Then
		// If it is the last string, then total and footer should fit
		RowWithFooter.Add(Template.GetArea("Total"));
		RowWithFooter.Add(Template.GetArea("Footer"));
	EndIf;
	
	CheckResult = SpreadsheetDocumentFitsPage(Spreadsheet, RowWithFooter);
	
	If Not CheckResult Then
		// Output separator and table title on the new page
		
		NumberWorksheet = NumberWorksheet + 1;
		
		AreaSheetsNumbering = Template.GetArea("NumberingOfSheets");
		AreaSheetsNumbering.Parameters.Number = InvoiceNumber;
		AreaSheetsNumbering.Parameters.NumberWorksheet = NumberWorksheet;
		
		Spreadsheet.PutHorizontalPageBreak();
		
		Spreadsheet.Put(AreaSheetsNumbering);
		Spreadsheet.Put(Template.GetArea("TableTitle"));
		
	EndIf;
	
	Return CheckResult;
	
EndFunction // CheckAccountsInvoicePagePut()

// Check if UTD printing is correct
//
//
Procedure ValidateOperationKind(CommandParameter, Errors) Export
	
	Counter = 0;
	
	While Counter <= CommandParameter.Count()-1 Do
		
		DocumentRef = CommandParameter[Counter];
		
		If DocumentRef.Date < Date('20130101') Then 
			
			MessageText = NStr("en='__________________"
"Printing of the universal transmission document is available from January 1, 2013. "
"For the %1 document the print form is not generated.';ru='__________________"
"Печать универсального передаточного документа доступна c 1 января 2013. "
"Для документа %1 печатная форма не сформирована.';vi='__________________"
"Được phép in chứng từ chuyển giao tổng hợp từ ngày 01/01/2013. "
"Đối với chứng từ %1 mẫu in chưa được lập.'");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, DocumentRef);
			CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
			
			CommandParameter.Delete(Counter);
			
		ElsIf TypeOf(DocumentRef) = Type("DocumentRef.CustomerOrder")
			AND DocumentRef.OperationKind <> Enums.OperationKindsCustomerOrder.WorkOrder Then
			
			MessageText = NStr("en='Unable to print universal transfer document %1 as action is available only for the work orders!';ru='Нельзя напечатать универсальный передаточный документ "
"%1, "
"т.к. действие доступно только для заказ-нарядов!';vi='Không thể in chứng từ chuyển nhượng tổng hợp"
"%1,"
"bởi vì thao tác in chỉ dùng cho đơn hàng trọn gói!'");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, DocumentRef);
			CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
			
			CommandParameter.Delete(Counter);
			
		ElsIf Not ValueIsFilled(DocumentRef.Counterparty) Then 
			
			MessageText = NStr("en='__________________"
"To print universal transfer document, you should fill in counterparty. "
"For the %1 document the print form is not generated.';ru='__________________"
"Для печати универсального передаточного документа необходимо заполнить контрагента. "
"Для документа %1 печатная форма не сформирована.';vi='__________________"
"Để in chứng từ chuyển tổng hợp cần điền đối tác. "
"Đối với chứng từ %1 mẫu in chưa được lập.'");
			
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, DocumentRef);
			CommonUseClientServer.AddUserError(Errors, , MessageText, Undefined);
			
			CommandParameter.Delete(Counter);
			
		Else
			
			Counter = Counter + 1;
			
		EndIf;
		
	EndDo;
	
EndProcedure // ValidateOperationKind()

// Function prepares data for printing labels and price tags.
//
// Returns:
//   Address   - data structure address in the temporary storage
//
Function PreparePriceTagsAndLabelsPrintingFromDocumentsDataStructure(DocumentArray, IsPriceTags) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReceiptOfProductsServicesProducts.ProductsAndServices AS ProductsAndServices,
	|	ReceiptOfProductsServicesProducts.Characteristic AS Characteristic,
	|	ReceiptOfProductsServicesProducts.Batch AS Batch,
	|	SUM(ReceiptOfProductsServicesProducts.Quantity) AS Quantity
	|FROM
	|	Document.SupplierInvoice.Inventory AS ReceiptOfProductsServicesProducts
	|WHERE
	|	ReceiptOfProductsServicesProducts.Ref IN(&DocumentArray)
	|
	|GROUP BY
	|	ReceiptOfProductsServicesProducts.ProductsAndServices,
	|	ReceiptOfProductsServicesProducts.Characteristic,
	|	ReceiptOfProductsServicesProducts.Batch
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryTransferInventory.ProductsAndServices,
	|	InventoryTransferInventory.Characteristic,
	|	InventoryTransferInventory.Batch,
	|	SUM(InventoryTransferInventory.Quantity)
	|FROM
	|	Document.InventoryTransfer.Inventory AS InventoryTransferInventory
	|WHERE
	|	InventoryTransferInventory.Ref IN(&DocumentArray)
	|
	|GROUP BY
	|	InventoryTransferInventory.ProductsAndServices,
	|	InventoryTransferInventory.Characteristic,
	|	InventoryTransferInventory.Batch
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ReceiptOfGoodsAndServices.Company AS Company,
	|	ReceiptOfGoodsAndServices.StructuralUnit AS StructuralUnit,
	|	ReceiptOfGoodsAndServices.StructuralUnit.RetailPriceKind AS PriceKind
	|FROM
	|	Document.SupplierInvoice AS ReceiptOfGoodsAndServices
	|WHERE
	|	ReceiptOfGoodsAndServices.Ref IN(&DocumentArray)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	InventoryTransfer.Company,
	|	InventoryTransfer.StructuralUnitPayee,
	|	InventoryTransfer.StructuralUnitPayee.RetailPriceKind
	|FROM
	|	Document.InventoryTransfer AS InventoryTransfer
	|WHERE
	|	InventoryTransfer.Ref IN(&DocumentArray)";
	
	Query.SetParameter("DocumentArray", DocumentArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	TableAttributesDocuments	= ResultsArray[1].Unload();
	CompaniesArray			= DataProcessors.PrintLabelsAndTags.GroupValueTableByAttribute(TableAttributesDocuments, "Company").UnloadColumn(0);
	WarehousesArray				= DataProcessors.PrintLabelsAndTags.GroupValueTableByAttribute(TableAttributesDocuments, "StructuralUnit").UnloadColumn(0);
	PriceKindsArray				= DataProcessors.PrintLabelsAndTags.GroupValueTableByAttribute(TableAttributesDocuments, "PriceKind").UnloadColumn(0);
	
	// Prepare actions structure for labels and price tags printing processor
	ActionsStructure = New Structure;
	ActionsStructure.Insert("FillCompany", ?(CompaniesArray.Count() = 1,CompaniesArray[0], Undefined));
	ActionsStructure.Insert("FillWarehouse", ?(WarehousesArray.Count() = 1,WarehousesArray[0], WarehousesArray));
	ActionsStructure.Insert("FillKindPrices", ?(PriceKindsArray.Count() = 1,PriceKindsArray[0], Undefined));
	ActionsStructure.Insert("ShowColumnNumberOfDocument", True);
	ActionsStructure.Insert("SetPrintModeFromDocument");
	If IsPriceTags Then
		
		ActionsStructure.Insert("SetMode", "TagsPrinting");
		ActionsStructure.Insert("FillOutPriceTagsQuantityOnDocument");
		
	Else
		
		ActionsStructure.Insert("SetMode", "LabelsPrinting");
		ActionsStructure.Insert("FillLabelsQuantityByDocument");
		
	EndIf;
	ActionsStructure.Insert("FillProductsTable");
	
	// Data preparation for filling tabular section of labels and price tags printing processor
	ResultStructure = New Structure;
	ResultStructure.Insert("Inventory", ResultsArray[0].Unload());
	ResultStructure.Insert("ActionsStructure", ActionsStructure);
	
	Return PutToTempStorage(ResultStructure);
	
EndFunction // PreparePriceTagsAndLabelsPrintingFromDocumentsDataStructure()

// Function returns passed document contract.
//
Function GetContractDocument(Document) Export
	
	Return Document.Contract;
	
EndFunction // GetContractDocument

// Возвращает ссылку на Организацию, указанную в первом документе параметра команды.
//
// Parameters:
//  CommandParameter	 - Array - массив ссылок на документы для печати.
// 
// Returns:
//  СправочникСсылка.Организация - организация, для которой вызывается печатная форма.
//  В случае если печать вызывается для форм разных организаций - возвращается пустая ссылка.
//
Function CompanyFromCommandParameter(CommandParameter) Export
	
	Result = Catalogs.Companies.EmptyRef();
	
	If TypeOf(CommandParameter) <> Type("Array") Then
		Return Result;
	EndIf;
	
	If Not ValueIsFilled(CommandParameter) Then
		Return Result;
	EndIf;
	
	For Each CurParameter In CommandParameter Do
		
		If TypeOf(CommandParameter[0]) <> TypeOf(CurParameter) Then
			Return Result;
		EndIf;
		
		If Not CommonUse.ReferenceTypeValue(CurParameter) Then
			Return Result;
		EndIf;
		
		If Not CommonUse.IsObjectAttribute("Company", CurParameter.Metadata()) Then
			Return Result;
		EndIf;
		
	EndDo;
	
	ObjectAttributeValues = CommonUse.ObjectsAttributeValue(CommandParameter, "Company");
	
	For Each KeyAndValue In ObjectAttributeValues Do
		If Not ValueIsFilled(Result) Then
			Result = KeyAndValue.Value;
		EndIf;
		If Result <> KeyAndValue.Value Then
			Return Catalogs.Companies.EmptyRef();
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////// 
// PROCEDURES AND FUNCTIONS FOR WORK WITH CUSTOMER INVOICE NOTES

// Fills in attribute by CCD number.
//
Procedure FillDateByCCDNumber(CCDCode, CCDRegistrationDate) Export
	
	CCDRegistrationDate = Date(0001, 01, 01);
	
	FirstDelimiterPosition	= Find(CCDCode, "/");
	DateCCD						= Right(CCDCode, StrLen(CCDCode) - FirstDelimiterPosition);
	SecondDelimiterPosition	= Find(DateCCD, "/");
	DateCCD						= Left(DateCCD, SecondDelimiterPosition - 1);
	
	If StrLen(DateCCD) = 6 Then
		
		DateDay	= Left(DateCCD, 2);
		DateMonth	= Mid(DateCCD, 3, 2);
		DateYear		= Mid(DateCCD, 5, 2);
		
		Try
			
			DateYear				= ?(Number(DateYear) >= 30, "19" + DateYear, "20" + DateYear);
			CCDRegistrationDate	= Date(DateYear, DateMonth, DateDay);
			
		Except
		EndTry;
		
	EndIf;
	
EndProcedure // FillDateByCCDNumber()


///////////////////////////////////////////////////////////////////////////////// 
// PROCEDURES AND FUNCTIONS FOR WORK WITH WORK CALENDAR

// Function returns row number in the
//  tabular document field for Events output by its date (beginning or end)
//
// Parameters
//  Hours - String,
//  hours dates Minutes - String, minutes
//  dates Date - Date, date current value
//  for definition Start - Boolean, shows that period has
//  begun or ended ComparisonDate - Date, date that is compared to the source date value
//
// Returns:
//   Number - String number in the tabular document field
//
Function ReturnLineNumber(Hours, Minutes, Date, Begin, DateComparison) Export
	
	If IsBlankString(Hours) Then
		Hours = 0;
	Else
		Hours = Number(Hours);
	EndIf; 
	
	If IsBlankString(Minutes) Then
		Minutes = 0;
	Else
		Minutes = Number(Minutes);
	EndIf; 
	
	If Begin Then
		If Date < BegOfDay(DateComparison) Then
			Return 1;
		Else
			If Minutes < 30 Then
				If Minutes = 0 Then
					If Hours = 0 Then
						Return 1;
					Else
						Return (Hours * 2 + 1);
					EndIf; 
				Else
					Return (Hours * 2 + 1);
				EndIf; 
			Else
				If Hours = 23 Then
					Return 48;
				Else
					Return (Hours * 2 + 2);
				EndIf; 
			EndIf;
		EndIf; 
	Else
		If Date > EndOfDay(DateComparison) Then
			Return 48;
		Else
			If Minutes = 0 Then
				If Hours = 0 Then
					Return 1;
				Else
					Return (Hours * 2);
				EndIf; 
			ElsIf Minutes <= 30 Then
				Return (Hours * 2 + 1);
			Else
				If Hours = 23 Then
					Return 48;
				Else
					Return (Hours * 2 + 2);
				EndIf; 
			EndIf;
		EndIf; 
	EndIf;
	
EndFunction

// Function returns weekday name by its number
//
// Parameters
//  WeekDayNumber - Day, number of the week day
//
// Returns:
//   String, weekday name
//
Function DefineWeekday(WeekDayNumber) Export
	
	If WeekDayNumber = 1 Then
		Return "Mo";
	ElsIf WeekDayNumber = 2 Then
		Return "Tu";
	ElsIf WeekDayNumber = 3 Then
		Return "We";
	ElsIf WeekDayNumber = 4 Then
		Return "Th";
	ElsIf WeekDayNumber = 5 Then
		Return "Fr";
	ElsIf WeekDayNumber = 6 Then
		Return "Sa";
	Else
		Return "Su";
	EndIf;
	
EndFunction

// Function defines the next date after the current
//  one depending on the set number of days in the week for displaying in the calendar
//
// Parameters
//  CurrentDate - Date, current date
//
// Returns:
//   Date - next date
//
Function DefineNextDate(CurrentDate, NumberOfWeekDays) Export
	
	If NumberOfWeekDays = "7" Then
		Return CurrentDate + 60*60*24;
	ElsIf NumberOfWeekDays = "6" Then
		If WeekDay(CurrentDate) = 6 Then
			Return CurrentDate + 60*60*24*2;
		Else
			Return CurrentDate + 60*60*24;
		EndIf; 
	ElsIf NumberOfWeekDays = "5" Then
		If WeekDay(CurrentDate) = 5 Then
			Return CurrentDate + 60*60*24*3;
		ElsIf WeekDay(CurrentDate) = 6 Then
			Return CurrentDate + 60*60*24*2;
		Else
			Return CurrentDate + 60*60*24;
		EndIf; 
	EndIf; 
	
EndFunction // DefineNextDate()

///////////////////////////////////////////////////////////////////////////////// 
// PROCEDURES AND FUNCTIONS FOR WORK WITH SELECTION

// The procedure sets (resets) filter settings for the specified user
// 
Procedure SetStandardFilterSettings(CurrentUser) Export
	
	If Not ValueIsFilled(CurrentUser) Then
		
		CommonUseClientServer.MessageToUser(
		NStr("en='User for whom default selection settings are set is not specified.';ru='Неуказан пользователь, для которого устанавливаются настройки подбора по умолчанию.';vi='Chưa chỉ ra người sử dụng mà có thiết lập tùy chỉnh chọn theo mặc định.'")
		);
		
		Return;
		
	EndIf;
	
	PickSettingsByDefault = PickSettingsByDefault();
	
	For Each Setting IN PickSettingsByDefault Do
		
		SetUserSetting(Setting.Value, Setting.Key, CurrentUser);
		
	EndDo;
	
EndProcedure // SetStandardSelectionSettings()

// Returns default settings match.
//
Function PickSettingsByDefault()
	
	PickSettingsByDefault = New Map;
	
	PickSettingsByDefault.Insert("FilterGroup", 				Catalogs.ProductsAndServices.EmptyRef());
	PickSettingsByDefault.Insert("KeepCurrentHierarchy", 	False);
	PickSettingsByDefault.Insert("RequestQuantityAndPrice",	False);
	PickSettingsByDefault.Insert("ShowBalance", 			True);
	PickSettingsByDefault.Insert("ShowReserve", 			False);
	PickSettingsByDefault.Insert("ShowAvailableBalance",	False);
	PickSettingsByDefault.Insert("ShowPrices", 				True);
	PickSettingsByDefault.Insert("OutputBalancesMethod", 		Enums.BalancesOutputMethodInSelection.InTable);
	PickSettingsByDefault.Insert("UseNewSelectionMechanism", True);
	PickSettingsByDefault.Insert("OutputAdviceGoBackToProductsAndServices", True);
	PickSettingsByDefault.Insert("OutputBoardUsePreviousPick", True);
	PickSettingsByDefault.Insert("CouncilServicesOutputInReceiptDocuments", True);
	
	Return PickSettingsByDefault;
	
EndFunction // DefaultFilterSettings()

// Procedure initializes the setting
// of custom selection settings Relevant for new users
//
Procedure SettingUserPickSettingsOnWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load = True Then
		
		Return;
		
	EndIf;
	
	UserRef = Source.Ref;
	
	If Not ValueIsFilled(UserRef) Then
		
		UserRef = Source.GetNewObjectRef();
		
		If Not ValueIsFilled(UserRef) Then 
			
			UserRef = Catalogs.Users.GetRef();
			Source.SetNewObjectRef(UserRef);
			
		EndIf;
		
	EndIf;
	
	SetStandardFilterSettings(UserRef);
	
EndProcedure // PickUserSettingsOnWriteSetting()

///////////////////////////////////////////////////////////////////////////////// 
// EMAILS SENDING PROCEDURES AND FUNCTIONS

// The procedure fills out email sending parameters when printing documents.
// Parameters match parameters passed to procedure Printing of documents managers modules.
Procedure FillSendingParameters(SendingParameters, ObjectsArray, PrintFormsCollection) Export
	
	If TypeOf(ObjectsArray) = Type("Array") Then
		
		Recipients = New ValueList;
		MetadataTypesContainingPartnersEmails = SmallBusinessContactInformationServer.GetTypesOfMetadataContainingAffiliateEmail();
		
		For Each ArrayObject IN ObjectsArray Do
			
			If Not ValueIsFilled(ArrayObject) Then 
				
				Continue; 
				
			ElsIf TypeOf(ArrayObject) = Type("CatalogRef.Counterparties") Then 
				
				// It is for printing from catalogs, for example, price lists from Catalogs.Counterparties
				StructureValuesToValuesList(Recipients, New Structure("Counterparty", ArrayObject));
				Continue;
				
			EndIf;
			
			ObjectMetadata = ArrayObject.Metadata();
			
			AttributesNamesContainedEmail = New Array;
			
			// Check all attributes of the passed object.
			For Each MetadataItem IN ObjectMetadata.Attributes Do
				
				ObjectContainsEmail(MetadataItem, MetadataTypesContainingPartnersEmails, AttributesNamesContainedEmail);
				
			EndDo;
			
			If AttributesNamesContainedEmail.Count() > 0 Then
				
				StructureValuesToValuesList(
					Recipients,
					CommonUse.ObjectAttributesValues(ArrayObject, AttributesNamesContainedEmail)
					);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	SendingParameters.Recipient = SmallBusinessContactInformationServer.PrepareRecipientsEmailAddresses(Recipients, True);
	
	AvailableAccounts = EmailOperations.AvailableAccounts(True);
	SendingParameters.Insert("Sender", ?(AvailableAccounts.Count() > 0, AvailableAccounts[0].Ref, Undefined));
	
	FillSubjectSendingText(SendingParameters, ObjectsArray, PrintFormsCollection);
	
EndProcedure //FillSendingParameters()

// Initiate receiving of available email
// accounts Parameters:
// ForSending - Boolean - If True is set, then only those records will be chosen from
// which you can send ForReceiving emails   - Boolean - If True is set, then only those records will be chosen by
// which you can receive emails EnableSystemAccount - Boolean - enable system account if it is available
//
// Returns:
// AvailableAccounts - ValueTable - With columns:
//    Ref       - CatalogRef.EmailAccounts - Ref to
//    the Name account - String - Name of
//    the Address account        - String - Email address
//
Function GetAvailableAccount(val ForSending = Undefined, val ForReceiving  = Undefined, val IncludingSystemEmailAccount = True) Export

	AvailableAccounts = EmailOperations.AvailableAccounts(ForSending, ForReceiving, IncludingSystemEmailAccount);
	
	Return ?(AvailableAccounts.Count() > 0, AvailableAccounts[0].Ref, Undefined);
	
EndFunction

// Adds metadata name containing email to array.
//
Procedure ObjectContainsEmail(AttributeObjectMetadata, MetadataTypesContainingPartnersEmails, AttributesNamesContainedEmail)
	
	If Not MetadataTypesContainingPartnersEmails.FindByValue(AttributeObjectMetadata.Type) = Undefined Then
		
		AttributesNamesContainedEmail.Add(AttributeObjectMetadata.Name);
		
	EndIf;
	
EndProcedure //ObjectContainsEmail()

// Procedure fills in theme and text of email sending parameters while printing documents.
// Parameters match parameters passed to procedure Printing of documents managers modules.
Procedure FillSubjectSendingText(SendingParameters, ObjectsArray, PrintFormsCollection)
	
	Subject  = "";
	Text = "";
	
	DocumentTitlePresentation = "";
	PresentationForWhom = "";
	PresentationFromWhom = "";
	
	PrintedDocuments = ObjectsArray.Count() > 0 AND CommonUse.ObjectKindByRef(ObjectsArray[0]) = "Document";
	
	If PrintedDocuments Then
		If ObjectsArray.Count() = 1 Then
			DocumentTitlePresentation = GenerateDocumentTitle(ObjectsArray[0]);
		Else
			DocumentTitlePresentation = "Documents: ";
			For Each ObjectForPrinting IN ObjectsArray Do
				DocumentTitlePresentation = DocumentTitlePresentation + ?(DocumentTitlePresentation = "Documents: ", "", "; ")
					+ GenerateDocumentTitle(ObjectForPrinting);
			EndDo;
		EndIf;
	EndIf;
	
	TypesStructurePrintObjects = ArrangeListByTypesOfObjects(ObjectsArray);
	
	CompanyByLetter = GetGeneralAttributeValue(TypesStructurePrintObjects, "Company", TypeDescriptionFromRow("Companies"));
	CounterpartyByEmail  = GetGeneralAttributeValue(TypesStructurePrintObjects, "Counterparty",  TypeDescriptionFromRow("Counterparties"));
	
	If ValueIsFilled(CounterpartyByEmail) Then
		PresentationForWhom = "for " + GetParticipantPresentation(CounterpartyByEmail);
	EndIf;
	
	If ValueIsFilled(CompanyByLetter) Then
		PresentationFromWhom = "from " + GetParticipantPresentation(CompanyByLetter);
	EndIf;
	
	AllowedSubjectLength = Metadata.Documents.Event.Attributes.Subject.Type.StringQualifiers.Length;
	If StrLen(DocumentTitlePresentation + PresentationForWhom + PresentationFromWhom) > AllowedSubjectLength Then
		PresentationFromWhom = "";
	EndIf;
	If StrLen(DocumentTitlePresentation + PresentationForWhom + PresentationFromWhom) > AllowedSubjectLength Then
		PresentationForWhom = "";
	EndIf;
	If StrLen(DocumentTitlePresentation + PresentationForWhom + PresentationFromWhom) > AllowedSubjectLength Then
		DocumentTitlePresentation = "";
		If PrintedDocuments Then
			DocumentTitlePresentation = "Documents: ";
			For Each KeyAndValue IN TypesStructurePrintObjects Do
				DocumentTitlePresentation = DocumentTitlePresentation + ?(DocumentTitlePresentation = "Documents: ", "", "; ")
					+ ?(IsBlankString(KeyAndValue.Key.ListPresentation), KeyAndValue.Key.Synonym, KeyAndValue.Key.ListPresentation);
			EndDo;
		EndIf;
	EndIf;
	
	Subject = StringFunctionsClientServer.SubstituteParametersInString(NStr("en='%1 %2 %3';ru='%1 %2 %3';vi='%1 %2 %3'"),
		DocumentTitlePresentation,
		PresentationForWhom,
		PresentationFromWhom
		);
		
	If Not (SendingParameters.Property("Subject") AND ValueIsFilled(SendingParameters.Subject)) Then
		SendingParameters.Insert("Subject", CutDoubleSpaces(Subject));
	EndIf;
	
	If Not (SendingParameters.Property("Text") AND ValueIsFilled(SendingParameters.Text)) Then
		SendingParameters.Insert("Text", CutDoubleSpaces(Text));
	EndIf;
	
EndProcedure

// The function receives a value of the main print attribute for the email participants.
//
// Parameters:
//  Ref	 - CatalogRef.Counterparties, CatalogRef.Companies	 - Ref to a participant for whom
// it is required to get a presentation Return value:
//  String - presentation value
Function GetParticipantPresentation(Ref)
	
	If Not ValueIsFilled(Ref) Then
		Return "";
	EndIf;
	
	ObjectAttributesNames = New Map;
	
	ObjectAttributesNames.Insert(Type("CatalogRef.Counterparties"), "DescriptionFull");
	ObjectAttributesNames.Insert(Type("CatalogRef.Companies"), "Description");
	
	Return CommonUse.ObjectAttributeValue(Ref, ObjectAttributesNames[TypeOf(Ref)]);
	
EndFunction 

// Function replaces double spaces with ordinary ones.
//
// Parameters:
//  SourceLine	 - String
// Return value:
//  String - String without double spaces
Function CutDoubleSpaces(SourceLine)

	While Find(SourceLine, "  ") > 0  Do
	
		SourceLine = StrReplace(SourceLine, "  ", " ");
	
	EndDo; 
	
	Return TrimR(SourceLine);

EndFunction 

// Function generates document title presentation.
//
// Returns:
//  String - document presentation as number and date in brief format
Function GenerateDocumentTitle(DocumentRef)

	If Not ValueIsFilled(DocumentRef) Then
		Return "";
	Else
		Return DocumentRef.Metadata().Synonym + " No "
			+ ObjectPrefixationClientServer.GetNumberForPrinting(DocumentRef.Number, True, True)
			+ " dated " + Format(DocumentRef.Date, "DF=dd MMMM yyyy'") + " g.";
	EndIf;

EndFunction // GenerateDocumentTitle()

// Function returns reference types description by the incoming row.
//
// Parameters:
//  DescriptionStringTypes	 - String	 - String with catalog names
// separated by commas Return value:
//  TypeDescription
Function TypeDescriptionFromRow(DescriptionStringTypes)

	StructureAvailableTypes 	= New Structure(DescriptionStringTypes);
	ArrayAvailableTypes 		= New Array;
	
	For Each StructureItem IN StructureAvailableTypes Do
		
		ArrayAvailableTypes.Add(Type("CatalogRef."+StructureItem.Key));
		
	EndDo; 
	
	Return New TypeDescription(ArrayAvailableTypes);
	
EndFunction 

// Function breaks values list into match by values types.
//
// Parameters:
//  ObjectsArray - <ValuesList> - objects list of the different kind
//
// Returns:
//   Map   - match where Key = type Metadata, Value = array of objects of this type
Function ArrangeListByTypesOfObjects(ObjectList)
	
	TypesStructure = New Map;
	
	For Each Object IN ObjectList Do
		
		DocumentMetadata = Object.Metadata();
		
		If TypesStructure.Get(DocumentMetadata) = Undefined Then
			DocumentArray = New Array;
			TypesStructure.Insert(DocumentMetadata, DocumentArray);
		EndIf;
		
		TypesStructure[DocumentMetadata].Add(Object);
		
	EndDo;
	
	Return TypesStructure;
	
EndFunction

// Returns a reference to the attribute value that must be the same in all the list documents. 
// If an attribute value differs in the list documents, Undefined is returned
//
// Parameters:
//  PrintObjects  - <ValuesList> - documents list in which you should look for counterparty
//
// Returns:
//   <CatalogRef>, Undefined - ref-attribute value that is in all documents, Undefined - else
//
Function GetGeneralAttributeValue(TypesStructure, AttributeName, AllowedTypeDescription)
	Var QueryText;
	
	Query = New Query;
	
	TextQueryByDocument = "
	|	%DocumentName%.%AttributeName% AS %AttributeName%
	|FROM
	|	Document.%DocumentName% AS %DocumentName%
	|WHERE
	|	%DocumentName%.Ref IN(&DocumentsList%DocumentName%)";
	
	TextQueryByDocument = StrReplace(TextQueryByDocument, "%AttributeName%", AttributeName);
	
	For Each KeyAndValue IN TypesStructure Do
		
		If IsDocumentAttribute(AttributeName, KeyAndValue.Key) Then
			
			DocumentName = KeyAndValue.Key.Name;
			
			If ValueIsFilled(QueryText) Then
				
				QueryText = QueryText+"
				|UNION
				|
				|SELECT DISTINCT";
				
			Else
				
				QueryText = "SELECT ALLOWED DISTINCT";
				
			EndIf;
			
			QueryText = QueryText + StrReplace(TextQueryByDocument, "%DocumentName%", DocumentName);
			
			Query.SetParameter("DocumentsList"+DocumentName, KeyAndValue.Value);
			
		EndIf; 
		
	EndDo; 
	
	If IsBlankString(QueryText) Then
	
		Return Undefined;
	
	EndIf; 
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		
		If Selection.Count() = 1 Then
			
			If Selection.Next() Then
				Return AllowedTypeDescription.AdjustValue(Selection[AttributeName]);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction 

//////////////////////////////////////////////////////////////////////////////// 
// General module CommonUse does not support "Server call" any more.
// Corrections and support of a new behavior
//

// Replaces
// call CommonUse.ObjectAttributeValue from the CertificateSettingsTest() procedure of the EDCertificates catalog form
//
Function ReadAttributeValue_UserPassword_RememberCertificatePassword_Imprint_Ref(ObjectOrRef) Export
	
	Return CommonUse.ObjectAttributesValues(
		ObjectOrRef, 
		"UserPassword, RememberCertificatePassword, Thumbprint, Ref"
		);
	
EndFunction // ReadAttributeValue_CatalogCertificatesEPItemForm()

// Replaces
// call CommonUse.ObjectAttributeValue from the CommandProcessor() procedure of the  AgreementSettingsTest command of the EDUsageAgreements catalog
//
Function ReadAttributeValue_CatalogEDUsageAgreements_CommandAgreementSettingsTest(ObjectOrRef) Export
	
	Return CommonUse.ObjectAttributesValues(
		ObjectOrRef,
		"Ref, AgreementStatus, EDExchangeMethod, IncomingDocumentsResource, SubscriberCertificate, CompanyCertificateForDcryption"
		);
		
EndFunction // ReadAttributeValue_CatalogCertificatesEPItemForm()

// Replaces
// call CommonUse.ObjectAttributeValue from the Add() procedure of the Price-list processor form
//
Function ReadAttributeValue_Owner(ObjectOrRef) Export
	
	Return CommonUse.ObjectAttributeValue(ObjectOrRef, "Owner");
	
EndFunction // ReadAttributeValue_ProcessorPriceListProcessorForm()

// Replaces
// call CommonUse.ObjectAttributeValue from the TreeSubordinateEDSelection() procedure of the EDTree form of the ElectronicDocuments processor
//
Function ReadAttributeValue_Agreement(ObjectOrRef) Export
	
	Return CommonUse.ObjectAttributeValue(ObjectOrRef, "Agreement");
	
EndFunction // ReadAttributeValue_Agreement()

// Replaces
// call CommonUse.ObjectAttributeValue from the CertificatePassword() procedure of the ItemFormViaOEDF form of the EDUsageAgreements catalog
//
Function ReadAttributeValue_SubscriberCertificate(ObjectOrRef) Export
	
	Return CommonUse.ObjectAttributeValue(ObjectOrRef, "SubscriberCertificate");
	
EndFunction // ReadAttributeValue_Agreement()

// Replaces
// call CommonUse.ObjectAttributeValue from the CertificatePassword() procedure of the ItemFormViaOEDF form of the EDUsageAgreements catalog
//
Function ReadAttributeValue_RememberCertificatePassword(ObjectOrRef) Export
	
	Return CommonUse.ObjectAttributeValue(ObjectOrRef, "RememberCertificatePassword");
	
EndFunction // ReadAttributeValue_Agreement()

// Replaces
// call CommonUse.ObjectAttributeValue from the CertificatePassword() procedure of the ItemFormViaOEDF form of the EDUsageAgreements catalog
//
Function ReadAttributeValue_UserPassword(ObjectOrRef) Export
	
	Return CommonUse.ObjectAttributeValue(ObjectOrRef, "UserPassword");
	
EndFunction // ReadAttributeValue_Agreement()

// Replaces
// call CommonUse.ObjectAttributeValue from the ProcessEDDecline()procedure of the EDViewForm form of the EDAttachedFiles catalog
//
Function ReadAttributeValue_EDExchangeMethod(ObjectOrRef) Export
	
	Return CommonUse.ObjectAttributeValue(ObjectOrRef, "EDExchangeMethod");
	
EndFunction // ReadAttributeValue_Agreement()

///////////////////////////////////////////////////////////////////////////////// 
// PROCEDURES AND FUNCTIONS EXCHANGE RATES DIFFERENCE

// Function returns a flag showing that rate differences are required.
//
Function GetNeedToCalculateExchangeDifferences(TempTablesManager, PaymentsTemporaryTableName)
	
	CalculateCurrencyDifference = Constants.FunctionalCurrencyTransactionsAccounting.Get();
	
	If CalculateCurrencyDifference Then
		QueryText =
		"SELECT DISTINCT
		|	TableAccounts.Currency AS Currency
		|FROM
		|	%TemporaryTableSettlements% AS TableAccounts
		|WHERE
		|	TableAccounts.Currency <> &AccountingCurrency";
		QueryText = StrReplace(QueryText, "%TemporaryTableSettlements%", PaymentsTemporaryTableName);
		Query = New Query();
		Query.Text = QueryText;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("AccountingCurrency", Constants.AccountingCurrency.Get());
		CalculateCurrencyDifference = Not Query.Execute().IsEmpty();
	EndIf;
	
	If CalculateCurrencyDifference Then
		ExchangeRateDifferencesCalculationFrequency = Constants.ExchangeRateDifferencesCalculationFrequency.Get();
		If ExchangeRateDifferencesCalculationFrequency = Enums.ExchangeRateDifferencesCalculationFrequency.DuringOpertionExecution Then
			CalculateCurrencyDifference = True;
		Else
			CalculateCurrencyDifference = False;
		EndIf;
	EndIf;
	
	Return CalculateCurrencyDifference;
	
EndFunction // GetNeedToCalculateExchangeRatesDifference()

// Function returns query text for exchange rates differences calculation.
//
Function GetQueryTextExchangeRatesDifferencesAccountsPayable(TempTablesManager, WithAdvanceOffset, QueryNumber) Export
	
	CalculateCurrencyDifference = GetNeedToCalculateExchangeDifferences(TempTablesManager, "TemporaryTableAccountsPayable");
	
	If Not CalculateCurrencyDifference Then
		
		QueryNumber = 1;
		
		QueryText =
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.Order AS Order,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	0 AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableOfExchangeRateDifferencesAccountsPayable
		|FROM
		|	TemporaryTableAccountsPayable AS TableAccounts
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentTable.Date AS Period,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Counterparty AS Counterparty,
		|	DocumentTable.Contract AS Contract,
		|	DocumentTable.Document AS Document,
		|	DocumentTable.Order AS Order,
		|	DocumentTable.SettlementsType AS SettlementsType,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	DocumentTable.ContentOfAccountingRecord
		|FROM
		|	TemporaryTableAccountsPayable AS DocumentTable
		|
		|ORDER BY
		|	DocumentTable.ContentOfAccountingRecord,
		|	Document,
		|	Order,
		|	RecordType";
	
	ElsIf WithAdvanceOffset Then
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	AccountsBalances.Company AS Company,
		|	AccountsBalances.Counterparty AS Counterparty,
		|	AccountsBalances.Contract AS Contract,
		|	AccountsBalances.Contract.SettlementsCurrency AS SettlementsCurrency,
		|	AccountsBalances.Document AS Document,
		|	AccountsBalances.Order AS Order,
		|	AccountsBalances.SettlementsType AS SettlementsType,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountVendorSettlements
		|		ELSE AccountsBalances.Counterparty.VendorAdvancesGLAccount
		|	END AS GLAccount,
		|	SUM(AccountsBalances.AmountBalance) AS AmountBalance,
		|	SUM(AccountsBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.Counterparty AS Counterparty,
		|		TemporaryTable.Contract AS Contract,
		|		TemporaryTable.Document AS Document,
		|		TemporaryTable.Order AS Order,
		|		TemporaryTable.SettlementsType AS SettlementsType,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableAccountsPayable AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.Counterparty,
		|		TableBalances.Contract,
		|		TableBalances.Document,
		|		TableBalances.Order,
		|		TableBalances.SettlementsType,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.AccountsPayable.Balance(
		|				&PointInTime,
		|				(Company, Counterparty, Contract, Document, Order, SettlementsType) In
		|					(SELECT DISTINCT
		|						TemporaryTableAccountsPayable.Company,
		|						TemporaryTableAccountsPayable.Counterparty,
		|						TemporaryTableAccountsPayable.Contract,
		|						TemporaryTableAccountsPayable.Document,
		|						TemporaryTableAccountsPayable.Order,
		|						TemporaryTableAccountsPayable.SettlementsType
		|					FROM
		|						TemporaryTableAccountsPayable)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.Counterparty,
		|		DocumentRegisterRecords.Contract,
		|		DocumentRegisterRecords.Document,
		|		DocumentRegisterRecords.Order,
		|		DocumentRegisterRecords.SettlementsType,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.AccountsPayable AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AccountsBalances
		|
		|GROUP BY
		|	AccountsBalances.Company,
		|	AccountsBalances.Counterparty,
		|	AccountsBalances.Contract,
		|	AccountsBalances.Document,
		|	AccountsBalances.Order,
		|	AccountsBalances.SettlementsType,
		|	AccountsBalances.Contract.SettlementsCurrency,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountVendorSettlements
		|		ELSE AccountsBalances.Counterparty.VendorAdvancesGLAccount
		|	END
		|
		|INDEX BY
		|	Company,
		|	Counterparty,
		|	Contract,
		|	SettlementsCurrency,
		|	Document,
		|	Order,
		|	SettlementsType,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.DoOperationsByDocuments AS DoOperationsByDocuments,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.Order AS Order,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableOfExchangeRateDifferencesAccountsPayablePrelimenary
		|FROM
		|	TemporaryTableAccountsPayable AS TableAccounts
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableAccounts.Company = TableBalances.Company
		|			AND TableAccounts.Counterparty = TableBalances.Counterparty
		|			AND TableAccounts.Contract = TableBalances.Contract
		|			AND TableAccounts.Document = TableBalances.Document
		|			AND TableAccounts.Order = TableBalances.Order
		|			AND TableAccounts.SettlementsType = TableBalances.SettlementsType
		|			AND TableAccounts.Currency = TableBalances.SettlementsCurrency
		|			AND TableAccounts.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTableAccountsPayable.Contract.SettlementsCurrency
		|					FROM
		|						TemporaryTableAccountsPayable)) AS CalculationCurrencyRatesSliceLast
		|		ON TableAccounts.Currency = CalculationCurrencyRatesSliceLast.Currency
		|WHERE
		|	(TableBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) = 0)
		|	AND (ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordTable.Period AS Period,
		|	RegisterRecordTable.RecordType AS RecordType,
		|	RegisterRecordTable.Company AS Company,
		|	RegisterRecordTable.Counterparty AS Counterparty,
		|	RegisterRecordTable.Contract AS Contract,
		|	RegisterRecordTable.Document AS Document,
		|	RegisterRecordTable.Order AS Order,
		|	RegisterRecordTable.SettlementsType AS SettlementsType,
		|	RegisterRecordTable.Currency AS Currency,
		|	SUM(RegisterRecordTable.Amount) AS Amount,
		|	SUM(RegisterRecordTable.AmountCur) AS AmountCur,
		|	RegisterRecordTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	(SELECT
		|		DocumentTable.Date AS Period,
		|		DocumentTable.RecordType AS RecordType,
		|		DocumentTable.Company AS Company,
		|		DocumentTable.Counterparty AS Counterparty,
		|		DocumentTable.Contract AS Contract,
		|		DocumentTable.Document AS Document,
		|		DocumentTable.Order AS Order,
		|		DocumentTable.SettlementsType AS SettlementsType,
		|		DocumentTable.Currency AS Currency,
		|		DocumentTable.Amount AS Amount,
		|		DocumentTable.AmountCur AS AmountCur,
		|		DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|	FROM
		|		TemporaryTableAccountsPayable AS DocumentTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		DocumentTable.Document,
		|		DocumentTable.Order,
		|		DocumentTable.SettlementsType,
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&ExchangeDifference AS String(100))
		|	FROM
		|		TemporaryTableOfExchangeRateDifferencesAccountsPayablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		DocumentTable.Document,
		|		DocumentTable.Order,
		|		DocumentTable.SettlementsType,
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&AdvanceCredit AS String(100))
		|	FROM
		|		TemporaryTableOfExchangeRateDifferencesAccountsPayablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Expense),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.Order,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&AdvanceCredit AS String(100))
		|	FROM
		|		TemporaryTableOfExchangeRateDifferencesAccountsPayablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.Order,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&ExchangeDifference AS String(100))
		|	FROM
		|		TemporaryTableOfExchangeRateDifferencesAccountsPayablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS RegisterRecordTable
		|
		|GROUP BY
		|	RegisterRecordTable.Period,
		|	RegisterRecordTable.Company,
		|	RegisterRecordTable.Counterparty,
		|	RegisterRecordTable.Contract,
		|	RegisterRecordTable.Document,
		|	RegisterRecordTable.Order,
		|	RegisterRecordTable.SettlementsType,
		|	RegisterRecordTable.Currency,
		|	RegisterRecordTable.ContentOfAccountingRecord,
		|	RegisterRecordTable.RecordType
		|
		|HAVING
		|	(SUM(RegisterRecordTable.Amount) >= 0.005
		|		OR SUM(RegisterRecordTable.Amount) <= -0.005
		|		OR SUM(RegisterRecordTable.AmountCur) >= 0.005
		|		OR SUM(RegisterRecordTable.AmountCur) <= -0.005)
		|
		|ORDER BY
		|	ContentOfAccountingRecord,
		|	Document,
		|	Order,
		|	RecordType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableCurrencyDifferences.Company AS Company,
		|	TableCurrencyDifferences.Counterparty AS Counterparty,
		|	TableCurrencyDifferences.DoOperationsByDocuments AS DoOperationsByDocuments,
		|	TableCurrencyDifferences.Contract AS Contract,
		|	TableCurrencyDifferences.Document AS Document,
		|	TableCurrencyDifferences.Order AS Order,
		|	TableCurrencyDifferences.SettlementsType AS SettlementsType,
		|	SUM(TableCurrencyDifferences.AmountOfExchangeDifferences) AS AmountOfExchangeDifferences,
		|	TableCurrencyDifferences.Currency AS Currency,
		|	TableCurrencyDifferences.GLAccount AS GLAccount
		|INTO TemporaryTableOfExchangeRateDifferencesAccountsPayable
		|FROM
		|	(SELECT
		|		DocumentTable.Date AS Date,
		|		DocumentTable.Company AS Company,
		|		DocumentTable.Counterparty AS Counterparty,
		|		DocumentTable.DoOperationsByDocuments AS DoOperationsByDocuments,
		|		DocumentTable.Contract AS Contract,
		|		DocumentTable.Document AS Document,
		|		DocumentTable.Order AS Order,
		|		DocumentTable.SettlementsType AS SettlementsType,
		|		DocumentTable.Currency AS Currency,
		|		DocumentTable.GLAccount AS GLAccount,
		|		DocumentTable.AmountOfExchangeDifferences AS AmountOfExchangeDifferences
		|	FROM
		|		TemporaryTableOfExchangeRateDifferencesAccountsPayablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.DoOperationsByDocuments,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.Order,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.Counterparty.GLAccountVendorSettlements,
		|		DocumentTable.AmountOfExchangeDifferences
		|	FROM
		|		TemporaryTableOfExchangeRateDifferencesAccountsPayablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS TableCurrencyDifferences
		|
		|GROUP BY
		|	TableCurrencyDifferences.Company,
		|	TableCurrencyDifferences.Counterparty,
		|	TableCurrencyDifferences.DoOperationsByDocuments,
		|	TableCurrencyDifferences.Contract,
		|	TableCurrencyDifferences.Document,
		|	TableCurrencyDifferences.Order,
		|	TableCurrencyDifferences.SettlementsType,
		|	TableCurrencyDifferences.Currency,
		|	TableCurrencyDifferences.GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableOfExchangeRateDifferencesAccountsPayablePrelimenary";
		
	Else
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	AccountsBalances.Company AS Company,
		|	AccountsBalances.Counterparty AS Counterparty,
		|	AccountsBalances.Contract AS Contract,
		|	AccountsBalances.Contract.SettlementsCurrency AS SettlementsCurrency,
		|	AccountsBalances.Document AS Document,
		|	AccountsBalances.Order AS Order,
		|	AccountsBalances.SettlementsType AS SettlementsType,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountVendorSettlements
		|		ELSE AccountsBalances.Counterparty.VendorAdvancesGLAccount
		|	END AS GLAccount,
		|	SUM(AccountsBalances.AmountBalance) AS AmountBalance,
		|	SUM(AccountsBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.Counterparty AS Counterparty,
		|		TemporaryTable.Contract AS Contract,
		|		TemporaryTable.Document AS Document,
		|		TemporaryTable.Order AS Order,
		|		TemporaryTable.SettlementsType AS SettlementsType,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableAccountsPayable AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.Counterparty,
		|		TableBalances.Contract,
		|		TableBalances.Document,
		|		TableBalances.Order,
		|		TableBalances.SettlementsType,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.AccountsPayable.Balance(
		|				&PointInTime,
		|				(Company, Counterparty, Contract, Document, Order, SettlementsType) In
		|					(SELECT DISTINCT
		|						TemporaryTableAccountsPayable.Company,
		|						TemporaryTableAccountsPayable.Counterparty,
		|						TemporaryTableAccountsPayable.Contract,
		|						TemporaryTableAccountsPayable.Document,
		|						TemporaryTableAccountsPayable.Order,
		|						TemporaryTableAccountsPayable.SettlementsType
		|					FROM
		|						TemporaryTableAccountsPayable)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.Counterparty,
		|		DocumentRegisterRecords.Contract,
		|		DocumentRegisterRecords.Document,
		|		DocumentRegisterRecords.Order,
		|		DocumentRegisterRecords.SettlementsType,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.AccountsPayable AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AccountsBalances
		|
		|GROUP BY
		|	AccountsBalances.Company,
		|	AccountsBalances.Counterparty,
		|	AccountsBalances.Contract,
		|	AccountsBalances.Document,
		|	AccountsBalances.Order,
		|	AccountsBalances.SettlementsType,
		|	AccountsBalances.Contract.SettlementsCurrency,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountVendorSettlements
		|		ELSE AccountsBalances.Counterparty.VendorAdvancesGLAccount
		|	END
		|
		|INDEX BY
		|	Company,
		|	Counterparty,
		|	Contract,
		|	SettlementsCurrency,
		|	Document,
		|	Order,
		|	SettlementsType,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.Order AS Order,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableOfExchangeRateDifferencesAccountsPayable
		|FROM
		|	TemporaryTableAccountsPayable AS TableAccounts
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableAccounts.Company = TableBalances.Company
		|			AND TableAccounts.Counterparty = TableBalances.Counterparty
		|			AND TableAccounts.Contract = TableBalances.Contract
		|			AND TableAccounts.Document = TableBalances.Document
		|			AND TableAccounts.Order = TableBalances.Order
		|			AND TableAccounts.SettlementsType = TableBalances.SettlementsType
		|			AND TableAccounts.Currency = TableBalances.SettlementsCurrency
		|			AND TableAccounts.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTableAccountsPayable.Currency
		|					FROM
		|						TemporaryTableAccountsPayable)) AS CalculationCurrencyRatesSliceLast
		|		ON TableAccounts.Currency = CalculationCurrencyRatesSliceLast.Currency
		|WHERE
		|	TableAccounts.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	AND (ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Orders,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Counterparty AS Counterparty,
		|	DocumentTable.Contract AS Contract,
		|	DocumentTable.Document AS Document,
		|	DocumentTable.Order AS Order,
		|	DocumentTable.SettlementsType AS SettlementsType,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	DocumentTable.ContentOfAccountingRecord
		|FROM
		|	TemporaryTableAccountsPayable AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	DocumentTable.LineNumber,
		|	DocumentTable.Date,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.Company,
		|	DocumentTable.Counterparty,
		|	DocumentTable.Contract,
		|	DocumentTable.Document,
		|	DocumentTable.Order,
		|	DocumentTable.SettlementsType,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN DocumentTable.AmountOfExchangeDifferences
		|		ELSE -DocumentTable.AmountOfExchangeDifferences
		|	END,
		|	0,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	&ExchangeDifference
		|FROM
		|	TemporaryTableOfExchangeRateDifferencesAccountsPayable AS DocumentTable
		|
		|ORDER BY
		|	Orders,
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
		
	EndIf;
	
	Return QueryText;
	
EndFunction // GetQueryTextExchangeRateDifferncesAccountsPayable()

// Function returns query text for exchange rates differences calculation.
//
Function GetQueryTextCurrencyExchangeRateAccountsReceivable(TempTablesManager, WithAdvanceOffset, QueryNumber) Export
	
	CalculateCurrencyDifference = GetNeedToCalculateExchangeDifferences(TempTablesManager, "TemporaryTableAccountsReceivable");
	
	If Not CalculateCurrencyDifference Then
		
		QueryNumber = 1;
		
		QueryText =
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.Order AS Order,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	0 AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateDifferencesAccountsReceivable
		|FROM
		|	TemporaryTableAccountsReceivable AS TableAccounts
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentTable.Date AS Period,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Counterparty AS Counterparty,
		|	DocumentTable.Contract AS Contract,
		|	DocumentTable.Document AS Document,
		|	DocumentTable.Order AS Order,
		|	DocumentTable.SettlementsType AS SettlementsType,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	DocumentTable.ContentOfAccountingRecord
		|FROM
		|	TemporaryTableAccountsReceivable AS DocumentTable
		|
		|ORDER BY
		|	DocumentTable.ContentOfAccountingRecord,
		|	Document,
		|	Order,
		|	RecordType";
	
	ElsIf WithAdvanceOffset Then
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	AccountsBalances.Company AS Company,
		|	AccountsBalances.Counterparty AS Counterparty,
		|	AccountsBalances.Contract AS Contract,
		|	AccountsBalances.Contract.SettlementsCurrency AS SettlementsCurrency,
		|	AccountsBalances.Document AS Document,
		|	AccountsBalances.Order AS Order,
		|	AccountsBalances.SettlementsType AS SettlementsType,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountCustomerSettlements
		|		ELSE AccountsBalances.Counterparty.CustomerAdvancesGLAccount
		|	END AS GLAccount,
		|	SUM(AccountsBalances.AmountBalance) AS AmountBalance,
		|	SUM(AccountsBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.Counterparty AS Counterparty,
		|		TemporaryTable.Contract AS Contract,
		|		TemporaryTable.Document AS Document,
		|		TemporaryTable.Order AS Order,
		|		TemporaryTable.SettlementsType AS SettlementsType,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableAccountsReceivable AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.Counterparty,
		|		TableBalances.Contract,
		|		TableBalances.Document,
		|		TableBalances.Order,
		|		TableBalances.SettlementsType,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.AccountsReceivable.Balance(
		|				&PointInTime,
		|				(Company, Counterparty, Contract, Document, Order, SettlementsType) In
		|					(SELECT DISTINCT
		|						TemporaryTableAccountsReceivable.Company,
		|						TemporaryTableAccountsReceivable.Counterparty,
		|						TemporaryTableAccountsReceivable.Contract,
		|						TemporaryTableAccountsReceivable.Document,
		|						TemporaryTableAccountsReceivable.Order,
		|						TemporaryTableAccountsReceivable.SettlementsType
		|					FROM
		|						TemporaryTableAccountsReceivable)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.Counterparty,
		|		DocumentRegisterRecords.Contract,
		|		DocumentRegisterRecords.Document,
		|		DocumentRegisterRecords.Order,
		|		DocumentRegisterRecords.SettlementsType,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.AccountsReceivable AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AccountsBalances
		|
		|GROUP BY
		|	AccountsBalances.Company,
		|	AccountsBalances.Counterparty,
		|	AccountsBalances.Contract,
		|	AccountsBalances.Document,
		|	AccountsBalances.Order,
		|	AccountsBalances.SettlementsType,
		|	AccountsBalances.Contract.SettlementsCurrency,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountCustomerSettlements
		|		ELSE AccountsBalances.Counterparty.CustomerAdvancesGLAccount
		|	END
		|
		|INDEX BY
		|	Company,
		|	Counterparty,
		|	Contract,
		|	SettlementsCurrency,
		|	Document,
		|	Order,
		|	SettlementsType,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.DoOperationsByDocuments AS DoOperationsByDocuments,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.Order AS Order,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateDifferencesAccountsReceivablePrelimenary
		|FROM
		|	TemporaryTableAccountsReceivable AS TableAccounts
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableAccounts.Company = TableBalances.Company
		|			AND TableAccounts.Counterparty = TableBalances.Counterparty
		|			AND TableAccounts.Contract = TableBalances.Contract
		|			AND TableAccounts.Document = TableBalances.Document
		|			AND TableAccounts.Order = TableBalances.Order
		|			AND TableAccounts.SettlementsType = TableBalances.SettlementsType
		|			AND TableAccounts.Currency = TableBalances.SettlementsCurrency
		|			AND TableAccounts.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTableAccountsReceivable.Contract.SettlementsCurrency
		|					FROM
		|						TemporaryTableAccountsReceivable)) AS CalculationCurrencyRatesSliceLast
		|		ON TableAccounts.Currency = CalculationCurrencyRatesSliceLast.Currency
		|WHERE
		|	(TableBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) = 0)
		|	AND (ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordTable.Period AS Period,
		|	RegisterRecordTable.RecordType AS RecordType,
		|	RegisterRecordTable.Company AS Company,
		|	RegisterRecordTable.Counterparty AS Counterparty,
		|	RegisterRecordTable.Contract AS Contract,
		|	RegisterRecordTable.Document AS Document,
		|	RegisterRecordTable.Order AS Order,
		|	RegisterRecordTable.SettlementsType AS SettlementsType,
		|	RegisterRecordTable.Currency AS Currency,
		|	SUM(RegisterRecordTable.Amount) AS Amount,
		|	SUM(RegisterRecordTable.AmountCur) AS AmountCur,
		|	RegisterRecordTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	(SELECT
		|		DocumentTable.Date AS Period,
		|		DocumentTable.RecordType AS RecordType,
		|		DocumentTable.Company AS Company,
		|		DocumentTable.Counterparty AS Counterparty,
		|		DocumentTable.Contract AS Contract,
		|		DocumentTable.Document AS Document,
		|		DocumentTable.Order AS Order,
		|		DocumentTable.SettlementsType AS SettlementsType,
		|		DocumentTable.Currency AS Currency,
		|		DocumentTable.Amount AS Amount,
		|		DocumentTable.AmountCur AS AmountCur,
		|		DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|	FROM
		|		TemporaryTableAccountsReceivable AS DocumentTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		DocumentTable.Document,
		|		DocumentTable.Order,
		|		DocumentTable.SettlementsType,
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&ExchangeDifference AS String(100))
		|	FROM
		|		TemporaryTableExchangeRateDifferencesAccountsReceivablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		DocumentTable.Document,
		|		DocumentTable.Order,
		|		DocumentTable.SettlementsType,
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&AdvanceCredit AS String(100))
		|	FROM
		|		TemporaryTableExchangeRateDifferencesAccountsReceivablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Expense),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.Order,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&AdvanceCredit AS String(100))
		|	FROM
		|		TemporaryTableExchangeRateDifferencesAccountsReceivablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.Order,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&ExchangeDifference AS String(100))
		|	FROM
		|		TemporaryTableExchangeRateDifferencesAccountsReceivablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS RegisterRecordTable
		|
		|GROUP BY
		|	RegisterRecordTable.Period,
		|	RegisterRecordTable.Company,
		|	RegisterRecordTable.Counterparty,
		|	RegisterRecordTable.Contract,
		|	RegisterRecordTable.Document,
		|	RegisterRecordTable.Order,
		|	RegisterRecordTable.SettlementsType,
		|	RegisterRecordTable.Currency,
		|	RegisterRecordTable.ContentOfAccountingRecord,
		|	RegisterRecordTable.RecordType
		|
		|HAVING
		|	(SUM(RegisterRecordTable.Amount) >= 0.005
		|		OR SUM(RegisterRecordTable.Amount) <= -0.005
		|		OR SUM(RegisterRecordTable.AmountCur) >= 0.005
		|		OR SUM(RegisterRecordTable.AmountCur) <= -0.005)
		|
		|ORDER BY
		|	ContentOfAccountingRecord,
		|	Document,
		|	Order,
		|	RecordType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableCurrencyDifferences.Company AS Company,
		|	TableCurrencyDifferences.Counterparty AS Counterparty,
		|	TableCurrencyDifferences.DoOperationsByDocuments AS DoOperationsByDocuments,
		|	TableCurrencyDifferences.Contract AS Contract,
		|	TableCurrencyDifferences.Document AS Document,
		|	TableCurrencyDifferences.Order AS Order,
		|	TableCurrencyDifferences.SettlementsType AS SettlementsType,
		|	SUM(TableCurrencyDifferences.AmountOfExchangeDifferences) AS AmountOfExchangeDifferences,
		|	TableCurrencyDifferences.Currency AS Currency,
		|	TableCurrencyDifferences.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateDifferencesAccountsReceivable
		|FROM
		|	(SELECT
		|		DocumentTable.Date AS Date,
		|		DocumentTable.Company AS Company,
		|		DocumentTable.Counterparty AS Counterparty,
		|		DocumentTable.DoOperationsByDocuments AS DoOperationsByDocuments,
		|		DocumentTable.Contract AS Contract,
		|		DocumentTable.Document AS Document,
		|		DocumentTable.Order AS Order,
		|		DocumentTable.SettlementsType AS SettlementsType,
		|		DocumentTable.Currency AS Currency,
		|		DocumentTable.GLAccount AS GLAccount,
		|		DocumentTable.AmountOfExchangeDifferences AS AmountOfExchangeDifferences
		|	FROM
		|		TemporaryTableExchangeRateDifferencesAccountsReceivablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.DoOperationsByDocuments,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.Order,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.Counterparty.GLAccountCustomerSettlements,
		|		DocumentTable.AmountOfExchangeDifferences
		|	FROM
		|		TemporaryTableExchangeRateDifferencesAccountsReceivablePrelimenary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS TableCurrencyDifferences
		|
		|GROUP BY
		|	TableCurrencyDifferences.Company,
		|	TableCurrencyDifferences.Counterparty,
		|	TableCurrencyDifferences.DoOperationsByDocuments,
		|	TableCurrencyDifferences.Contract,
		|	TableCurrencyDifferences.Document,
		|	TableCurrencyDifferences.Order,
		|	TableCurrencyDifferences.SettlementsType,
		|	TableCurrencyDifferences.Currency,
		|	TableCurrencyDifferences.GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableExchangeRateDifferencesAccountsReceivablePrelimenary";
		
	Else
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	AccountsBalances.Company AS Company,
		|	AccountsBalances.Counterparty AS Counterparty,
		|	AccountsBalances.Contract AS Contract,
		|	AccountsBalances.Contract.SettlementsCurrency AS SettlementsCurrency,
		|	AccountsBalances.Document AS Document,
		|	AccountsBalances.Order AS Order,
		|	AccountsBalances.SettlementsType AS SettlementsType,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountCustomerSettlements
		|		ELSE AccountsBalances.Counterparty.CustomerAdvancesGLAccount
		|	END AS GLAccount,
		|	SUM(AccountsBalances.AmountBalance) AS AmountBalance,
		|	SUM(AccountsBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.Counterparty AS Counterparty,
		|		TemporaryTable.Contract AS Contract,
		|		TemporaryTable.Document AS Document,
		|		TemporaryTable.Order AS Order,
		|		TemporaryTable.SettlementsType AS SettlementsType,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableAccountsReceivable AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.Counterparty,
		|		TableBalances.Contract,
		|		TableBalances.Document,
		|		TableBalances.Order,
		|		TableBalances.SettlementsType,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.AccountsReceivable.Balance(
		|				&PointInTime,
		|				(Company, Counterparty, Contract, Document, Order, SettlementsType) In
		|					(SELECT DISTINCT
		|						TemporaryTableAccountsReceivable.Company,
		|						TemporaryTableAccountsReceivable.Counterparty,
		|						TemporaryTableAccountsReceivable.Contract,
		|						TemporaryTableAccountsReceivable.Document,
		|						TemporaryTableAccountsReceivable.Order,
		|						TemporaryTableAccountsReceivable.SettlementsType
		|					FROM
		|						TemporaryTableAccountsReceivable)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.Counterparty,
		|		DocumentRegisterRecords.Contract,
		|		DocumentRegisterRecords.Document,
		|		DocumentRegisterRecords.Order,
		|		DocumentRegisterRecords.SettlementsType,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.AccountsReceivable AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AccountsBalances
		|
		|GROUP BY
		|	AccountsBalances.Company,
		|	AccountsBalances.Counterparty,
		|	AccountsBalances.Contract,
		|	AccountsBalances.Document,
		|	AccountsBalances.Order,
		|	AccountsBalances.SettlementsType,
		|	AccountsBalances.Contract.SettlementsCurrency,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountCustomerSettlements
		|		ELSE AccountsBalances.Counterparty.CustomerAdvancesGLAccount
		|	END
		|
		|INDEX BY
		|	Company,
		|	Counterparty,
		|	Contract,
		|	SettlementsCurrency,
		|	Document,
		|	Order,
		|	SettlementsType,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.Order AS Order,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateDifferencesAccountsReceivable
		|FROM
		|	TemporaryTableAccountsReceivable AS TableAccounts
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableAccounts.Company = TableBalances.Company
		|			AND TableAccounts.Counterparty = TableBalances.Counterparty
		|			AND TableAccounts.Contract = TableBalances.Contract
		|			AND TableAccounts.Document = TableBalances.Document
		|			AND TableAccounts.Order = TableBalances.Order
		|			AND TableAccounts.SettlementsType = TableBalances.SettlementsType
		|			AND TableAccounts.Currency = TableBalances.SettlementsCurrency
		|			AND TableAccounts.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTableAccountsReceivable.Currency
		|					FROM
		|						TemporaryTableAccountsReceivable)) AS CalculationCurrencyRatesSliceLast
		|		ON TableAccounts.Currency = CalculationCurrencyRatesSliceLast.Currency
		|WHERE
		|	TableAccounts.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	AND (ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Counterparty AS Counterparty,
		|	DocumentTable.Contract AS Contract,
		|	DocumentTable.Document AS Document,
		|	DocumentTable.Order AS Order,
		|	DocumentTable.SettlementsType AS SettlementsType,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	DocumentTable.ContentOfAccountingRecord
		|FROM
		|	TemporaryTableAccountsReceivable AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	DocumentTable.LineNumber,
		|	DocumentTable.Date,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.Company,
		|	DocumentTable.Counterparty,
		|	DocumentTable.Contract,
		|	DocumentTable.Document,
		|	DocumentTable.Order,
		|	DocumentTable.SettlementsType,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN DocumentTable.AmountOfExchangeDifferences
		|		ELSE -DocumentTable.AmountOfExchangeDifferences
		|	END,
		|	0,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	&ExchangeDifference
		|FROM
		|	TemporaryTableExchangeRateDifferencesAccountsReceivable AS DocumentTable
		|
		|ORDER BY
		|	Order,
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
		
	EndIf;
	
	Return QueryText;
	
EndFunction // GetQueryTextExchangeRateDifferncesAccountsReceivable()

// Function returns query text for exchange rates differences calculation.
//
Function GetQueryTextExchangeRateDifferencesCashAssets(TempTablesManager, QueryNumber) Export
	
	CalculateCurrencyDifference = GetNeedToCalculateExchangeDifferences(TempTablesManager, "TemporaryTableCashAssets");
	
	If CalculateCurrencyDifference Then
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	FundsBalance.Company AS Company,
		|	FundsBalance.CashAssetsType AS CashAssetsType,
		|	FundsBalance.BankAccountPettyCash AS BankAccountPettyCash,
		|	FundsBalance.Currency AS Currency,
		|	FundsBalance.BankAccountPettyCash.GLAccount AS GLAccount,
		|	SUM(FundsBalance.AmountBalance) AS AmountBalance,
		|	SUM(FundsBalance.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.CashAssetsType AS CashAssetsType,
		|		TemporaryTable.BankAccountPettyCash AS BankAccountPettyCash,
		|		TemporaryTable.Currency AS Currency,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableCashAssets AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.CashAssetsType,
		|		TableBalances.BankAccountPettyCash,
		|		TableBalances.Currency,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.CashAssets.Balance(
		|				&PointInTime,
		|				(Company, CashAssetsType, BankAccountPettyCash, Currency) In
		|					(SELECT DISTINCT
		|						TemporaryTableCashAssets.Company,
		|						TemporaryTableCashAssets.CashAssetsType,
		|						TemporaryTableCashAssets.BankAccountPettyCash,
		|						TemporaryTableCashAssets.Currency
		|					FROM
		|						TemporaryTableCashAssets)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.CashAssetsType,
		|		DocumentRegisterRecords.BankAccountPettyCash,
		|		DocumentRegisterRecords.Currency,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.CashAssets AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS FundsBalance
		|
		|GROUP BY
		|	FundsBalance.Company,
		|	FundsBalance.CashAssetsType,
		|	FundsBalance.BankAccountPettyCash,
		|	FundsBalance.Currency,
		|	FundsBalance.BankAccountPettyCash.GLAccount
		|
		|INDEX BY
		|	Company,
		|	CashAssetsType,
		|	BankAccountPettyCash,
		|	Currency,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableCashAssets.Company AS Company,
		|	TableCashAssets.CashAssetsType AS CashAssetsType,
		|	TableCashAssets.BankAccountPettyCash AS BankAccountPettyCash,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableCashAssets.Currency AS Currency,
		|	TableCashAssets.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateLossesBanking
		|FROM
		|	TemporaryTableCashAssets AS TableCashAssets
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableCashAssets.Company = TableBalances.Company
		|			AND TableCashAssets.CashAssetsType = TableBalances.CashAssetsType
		|			AND TableCashAssets.BankAccountPettyCash = TableBalances.BankAccountPettyCash
		|			AND TableCashAssets.Currency = TableBalances.Currency
		|			AND TableCashAssets.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTableCashAssets.Currency
		|					FROM
		|						TemporaryTableCashAssets)) AS CurrencyCurrencyRatesBankAccountPettyCashSliceLast
		|		ON TableCashAssets.Currency = CurrencyCurrencyRatesBankAccountPettyCashSliceLast.Currency
		|WHERE
		|	(ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.CashAssetsType AS CashAssetsType,
		|	DocumentTable.Item AS Item,
		|	DocumentTable.BankAccountPettyCash AS BankAccountPettyCash,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount AS GLAccount,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTableCashAssets AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	DocumentTable.LineNumber,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.Date,
		|	DocumentTable.Company,
		|	DocumentTable.CashAssetsType,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(Catalog.CashFlowItems.PositiveExchangeDifference)
		|		ELSE VALUE(Catalog.CashFlowItems.NegativeExchangeDifference)
		|	END,
		|	DocumentTable.BankAccountPettyCash,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN DocumentTable.AmountOfExchangeDifferences
		|		ELSE -DocumentTable.AmountOfExchangeDifferences
		|	END,
		|	0,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	&ExchangeDifference
		|FROM
		|	TemporaryTableExchangeRateLossesBanking AS DocumentTable
		|
		|ORDER BY
		|	ContentOfAccountingRecord,
		|	RecordType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
		
	Else
		
		QueryNumber = 1;
		
		QueryText =
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableCashAssets.Company AS Company,
		|	TableCashAssets.CashAssetsType AS CashAssetsType,
		|	TableCashAssets.BankAccountPettyCash AS BankAccountPettyCash,
		|	0 AS AmountOfExchangeDifferences,
		|	TableCashAssets.Currency AS Currency,
		|	TableCashAssets.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateLossesBanking
		|FROM
		|	TemporaryTableCashAssets AS TableCashAssets
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.CashAssetsType AS CashAssetsType,
		|	DocumentTable.Item AS Item,
		|	DocumentTable.BankAccountPettyCash AS BankAccountPettyCash,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount AS GLAccount,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTableCashAssets AS DocumentTable
		|
		|ORDER BY
		|	ContentOfAccountingRecord,
		|	RecordType";
	
	EndIf;
	
	Return QueryText;
	
EndFunction // GetQueryTextExchangeRateDifferncesCashAssets()

// Function returns query text for exchange rates differences calculation.
//
Function GetQueryTextExchangeRateDifferencesCashInCashRegisters(TempTablesManager, QueryNumber) Export
	
	CalculateCurrencyDifference = GetNeedToCalculateExchangeDifferences(TempTablesManager, "TemporaryTableCashAssetsInRetailCashes");
	
	If CalculateCurrencyDifference Then
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	FundsBalance.Company AS Company,
		|	FundsBalance.CashCR AS CashCR,
		|	FundsBalance.CashCR.GLAccount AS GLAccount,
		|	FundsBalance.Currency AS Currency,
		|	SUM(FundsBalance.AmountBalance) AS AmountBalance,
		|	SUM(FundsBalance.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.CashCR AS CashCR,
		|		TemporaryTable.Currency AS Currency,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableCashAssetsInRetailCashes AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.CashCR,
		|		TableBalances.CashCR.CashCurrency,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.CashInCashRegisters.Balance(
		|				&PointInTime,
		|				(Company, CashCR) In
		|					(SELECT DISTINCT
		|						TemporaryTableCashAssetsInRetailCashes.Company,
		|						TemporaryTableCashAssetsInRetailCashes.CashCR
		|					FROM
		|						TemporaryTableCashAssetsInRetailCashes)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.CashCR,
		|		DocumentRegisterRecords.CashCR.CashCurrency,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.CashInCashRegisters AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS FundsBalance
		|
		|GROUP BY
		|	FundsBalance.Company,
		|	FundsBalance.CashCR,
		|	FundsBalance.Currency,
		|	FundsBalance.CashCR.GLAccount
		|
		|INDEX BY
		|	Company,
		|	CashCR,
		|	Currency,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableCashAssets.Company AS Company,
		|	TableCashAssets.CashCR AS CashCR,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableCashAssets.Currency AS Currency,
		|	TableCashAssets.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateLossesCashAssetsInRetailCashes
		|FROM
		|	TemporaryTableCashAssetsInRetailCashes AS TableCashAssets
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableCashAssets.Company = TableBalances.Company
		|			AND TableCashAssets.CashCR = TableBalances.CashCR
		|			AND TableCashAssets.Currency = TableBalances.Currency
		|			AND TableCashAssets.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTableCashAssetsInRetailCashes.Currency
		|					FROM
		|						TemporaryTableCashAssetsInRetailCashes)) AS CurrencyCurrencyRatesBankAccountPettyCashSliceLast
		|		ON TableCashAssets.Currency = CurrencyCurrencyRatesBankAccountPettyCashSliceLast.Currency
		|WHERE
		|	(ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyCurrencyRatesBankAccountPettyCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.CashCR AS CashCR,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTableCashAssetsInRetailCashes AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	DocumentTable.LineNumber,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.Date,
		|	DocumentTable.Company,
		|	DocumentTable.Currency,
		|	DocumentTable.CashCR,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN DocumentTable.AmountOfExchangeDifferences
		|		ELSE -DocumentTable.AmountOfExchangeDifferences
		|	END,
		|	0,
		|	&ExchangeDifference
		|FROM
		|	TemporaryTableExchangeRateLossesCashAssetsInRetailCashes AS DocumentTable
		|
		|ORDER BY
		|	ContentOfAccountingRecord,
		|	RecordType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
	
	Else
		
		QueryNumber = 1;
		
		QueryText =
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableCashAssets.Company AS Company,
		|	TableCashAssets.CashCR AS CashCR,
		|	0 AS AmountOfExchangeDifferences,
		|	TableCashAssets.Currency AS Currency,
		|	TableCashAssets.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateLossesCashAssetsInRetailCashes
		|FROM
		|	TemporaryTableCashAssetsInRetailCashes AS TableCashAssets
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.CashCR AS CashCR,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTableCashAssetsInRetailCashes AS DocumentTable
		|
		|ORDER BY
		|	ContentOfAccountingRecord,
		|	RecordType";
	
	EndIf;
	
	Return QueryText;
	
EndFunction // GetQueryTextExchangeRateDifferencesCashInCRPettyCash()

// Function returns query text for exchange rates differences calculation.
//
Function GetQueryTextCurrencyExchangeRateAdvanceHolderPayments(TempTablesManager, QueryNumber) Export
	
	CalculateCurrencyDifference = GetNeedToCalculateExchangeDifferences(TempTablesManager, "TemporaryTableAdvanceHolderPayments");
	
	If CalculateCurrencyDifference Then
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	AccountsBalances.Company AS Company,
		|	AccountsBalances.Employee AS Employee,
		|	AccountsBalances.Currency AS Currency,
		|	AccountsBalances.Document AS Document,
		|	AccountsBalances.Employee.AdvanceHoldersGLAccount AS GLAccount,
		|	SUM(AccountsBalances.AmountBalance) AS AmountBalance,
		|	SUM(AccountsBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.Employee AS Employee,
		|		TemporaryTable.Currency AS Currency,
		|		TemporaryTable.Document AS Document,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableAdvanceHolderPayments AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.Employee,
		|		TableBalances.Currency,
		|		TableBalances.Document,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.AdvanceHolderPayments.Balance(
		|				&PointInTime,
		|				(Company, Employee, Currency, Document) In
		|					(SELECT DISTINCT
		|						TemporaryTableAdvanceHolderPayments.Company,
		|						TemporaryTableAdvanceHolderPayments.Employee,
		|						TemporaryTableAdvanceHolderPayments.Currency,
		|						TemporaryTableAdvanceHolderPayments.Document
		|					FROM
		|						TemporaryTableAdvanceHolderPayments)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.Employee,
		|		DocumentRegisterRecords.Currency,
		|		DocumentRegisterRecords.Document,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.AdvanceHolderPayments AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AccountsBalances
		|
		|GROUP BY
		|	AccountsBalances.Company,
		|	AccountsBalances.Employee,
		|	AccountsBalances.Currency,
		|	AccountsBalances.Document,
		|	AccountsBalances.Employee.AdvanceHoldersGLAccount
		|
		|INDEX BY
		|	Company,
		|	Employee,
		|	Currency,
		|	Document,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Employee AS Employee,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.Document AS Document,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeDifferencesCalculationWithAdvanceHolder
		|FROM
		|	TemporaryTableAdvanceHolderPayments AS TableAccounts
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableAccounts.Company = TableBalances.Company
		|			AND TableAccounts.Employee = TableBalances.Employee
		|			AND TableAccounts.Currency = TableBalances.Currency
		|			AND TableAccounts.Document = TableBalances.Document
		|			AND TableAccounts.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTableAdvanceHolderPayments.Currency
		|					FROM
		|						TemporaryTableAdvanceHolderPayments)) AS CalculationCurrencyRatesSliceLast
		|		ON TableAccounts.Currency = CalculationCurrencyRatesSliceLast.Currency
		|WHERE
		|	(ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Document AS Document,
		|	DocumentTable.Employee AS Employee,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount AS GLAccount,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTableAdvanceHolderPayments AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	DocumentTable.LineNumber,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.Document,
		|	DocumentTable.Employee,
		|	DocumentTable.Date,
		|	DocumentTable.Company,
		|	DocumentTable.Currency,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN DocumentTable.AmountOfExchangeDifferences
		|		ELSE -DocumentTable.AmountOfExchangeDifferences
		|	END,
		|	0,
		|	DocumentTable.GLAccount,
		|	&ExchangeDifference
		|FROM
		|	TemporaryTableExchangeDifferencesCalculationWithAdvanceHolder AS DocumentTable
		|
		|ORDER BY
		|	Order,
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
		
	Else
		
		QueryNumber = 1;
		
		QueryText =
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Employee AS Employee,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.Document AS Document,
		|	0 AS AmountOfExchangeDifferences,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeDifferencesCalculationWithAdvanceHolder
		|FROM
		|	TemporaryTableAdvanceHolderPayments AS TableAccounts
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Document AS Document,
		|	DocumentTable.Employee AS Employee,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount AS GLAccount,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTableAdvanceHolderPayments AS DocumentTable
		|
		|ORDER BY
		|	Order,
		|	LineNumber";
		
	EndIf;
	
	Return QueryText;
	
EndFunction // GetQueryTextExchangeRateDifferencesAdvanceHolderPayments()

// Function returns query text for exchange rates differences calculation.
//
Function GetQueryTextExchangeRateDifferencesPayrollPayments(TempTablesManager, QueryNumber) Export
	
	CalculateCurrencyDifference = GetNeedToCalculateExchangeDifferences(TempTablesManager, "TemporaryTablePayrollPayments");
	
	If CalculateCurrencyDifference Then
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	AccountsBalances.Company AS Company,
		|	AccountsBalances.StructuralUnit AS StructuralUnit,
		|	AccountsBalances.Employee AS Employee,
		|	AccountsBalances.Currency AS Currency,
		|	AccountsBalances.RegistrationPeriod AS RegistrationPeriod,
		|	AccountsBalances.Employee.SettlementsHumanResourcesGLAccount AS GLAccount,
		|	SUM(AccountsBalances.AmountBalance) AS AmountBalance,
		|	SUM(AccountsBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.StructuralUnit AS StructuralUnit,
		|		TemporaryTable.Employee AS Employee,
		|		TemporaryTable.Currency AS Currency,
		|		TemporaryTable.RegistrationPeriod AS RegistrationPeriod,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTablePayrollPayments AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.StructuralUnit,
		|		TableBalances.Employee,
		|		TableBalances.Currency,
		|		TableBalances.RegistrationPeriod,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.PayrollPayments.Balance(
		|				&PointInTime,
		|				(Company, StructuralUnit, Employee, Currency, RegistrationPeriod) In
		|					(SELECT DISTINCT
		|						TemporaryTablePayrollPayments.Company,
		|						TemporaryTablePayrollPayments.StructuralUnit,
		|						TemporaryTablePayrollPayments.Employee,
		|						TemporaryTablePayrollPayments.Currency,
		|						TemporaryTablePayrollPayments.RegistrationPeriod
		|					FROM
		|						TemporaryTablePayrollPayments)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.StructuralUnit,
		|		DocumentRegisterRecords.Employee,
		|		DocumentRegisterRecords.Currency,
		|		DocumentRegisterRecords.RegistrationPeriod,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.PayrollPayments AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AccountsBalances
		|
		|GROUP BY
		|	AccountsBalances.Company,
		|	AccountsBalances.StructuralUnit,
		|	AccountsBalances.Employee,
		|	AccountsBalances.Currency,
		|	AccountsBalances.RegistrationPeriod,
		|	AccountsBalances.Employee.SettlementsHumanResourcesGLAccount
		|
		|INDEX BY
		|	Company,
		|	StructuralUnit,
		|	Employee,
		|	Currency,
		|	RegistrationPeriod,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.StructuralUnit AS StructuralUnit,
		|	TableAccounts.Employee AS Employee,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.RegistrationPeriod AS RegistrationPeriod,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeDifferencesPayrollPayments
		|FROM
		|	TemporaryTablePayrollPayments AS TableAccounts
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableAccounts.Company = TableBalances.Company
		|			AND TableAccounts.StructuralUnit = TableBalances.StructuralUnit
		|			AND TableAccounts.Employee = TableBalances.Employee
		|			AND TableAccounts.Currency = TableBalances.Currency
		|			AND TableAccounts.RegistrationPeriod = TableBalances.RegistrationPeriod
		|			AND TableAccounts.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTablePayrollPayments.Currency
		|					FROM
		|						TemporaryTablePayrollPayments)) AS CalculationCurrencyRatesSliceLast
		|		ON TableAccounts.Currency = CalculationCurrencyRatesSliceLast.Currency
		|WHERE
		|	(ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.StructuralUnit AS StructuralUnit,
		|	DocumentTable.Employee AS Employee,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.RegistrationPeriod AS RegistrationPeriod,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount AS GLAccount,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTablePayrollPayments AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	DocumentTable.LineNumber,
		|	DocumentTable.Date,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.Company,
		|	DocumentTable.StructuralUnit,
		|	DocumentTable.Employee,
		|	DocumentTable.Currency,
		|	DocumentTable.RegistrationPeriod,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN DocumentTable.AmountOfExchangeDifferences
		|		ELSE -DocumentTable.AmountOfExchangeDifferences
		|	END,
		|	0,
		|	DocumentTable.GLAccount,
		|	&ExchangeDifference
		|FROM
		|	TemporaryTableExchangeDifferencesPayrollPayments AS DocumentTable
		|
		|ORDER BY
		|	Order,
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
	
	Else
		
		QueryNumber = 1;
		
		QueryText =
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.StructuralUnit AS StructuralUnit,
		|	TableAccounts.Employee AS Employee,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.RegistrationPeriod AS RegistrationPeriod,
		|	0 AS AmountOfExchangeDifferences,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeDifferencesPayrollPayments
		|FROM
		|	TemporaryTablePayrollPayments AS TableAccounts
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.StructuralUnit AS StructuralUnit,
		|	DocumentTable.Employee AS Employee,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.RegistrationPeriod AS RegistrationPeriod,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount AS GLAccount,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTablePayrollPayments AS DocumentTable
		|
		|ORDER BY
		|	Order,
		|	LineNumber";
		
	EndIf;
	
	Return QueryText;
	
EndFunction // GetQueryTextExchangeRateDifferncesPayrollPayments()

// Function returns query text for exchange rates differences calculation.
//
Function GetQueryTextExchangeRateDifferencesRetailAmountAccounting(TempTablesManager, QueryNumber) Export
	
	CalculateCurrencyDifference = GetNeedToCalculateExchangeDifferences(TempTablesManager, "TemporaryTableRetailAmountAccounting");
	
	If CalculateCurrencyDifference Then
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	RetailAmountAccountingBalances.Company AS Company,
		|	RetailAmountAccountingBalances.StructuralUnit AS StructuralUnit,
		|	RetailAmountAccountingBalances.GLAccount AS GLAccount,
		|	RetailAmountAccountingBalances.Currency AS Currency,
		|	SUM(RetailAmountAccountingBalances.AmountBalance) AS AmountBalance,
		|	SUM(RetailAmountAccountingBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.StructuralUnit AS StructuralUnit,
		|		TemporaryTable.Currency AS Currency,
		|		TemporaryTable.GLAccount AS GLAccount,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableRetailAmountAccounting AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalances.Company,
		|		TableBalances.StructuralUnit,
		|		TableBalances.Currency,
		|		TableBalances.StructuralUnit.GLAccountInRetail,
		|		ISNULL(TableBalances.AmountBalance, 0),
		|		ISNULL(TableBalances.AmountCurBalance, 0)
		|	FROM
		|		AccumulationRegister.RetailAmountAccounting.Balance(
		|				&PointInTime,
		|				(Company, StructuralUnit, Currency) In
		|					(SELECT DISTINCT
		|						TemporaryTableRetailAmountAccounting.Company,
		|						TemporaryTableRetailAmountAccounting.StructuralUnit,
		|						TemporaryTableRetailAmountAccounting.Currency
		|					FROM
		|						TemporaryTableRetailAmountAccounting)) AS TableBalances
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.StructuralUnit,
		|		DocumentRegisterRecords.Currency,
		|		DocumentRegisterRecords.StructuralUnit.GLAccountInRetail,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.RetailAmountAccounting AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS RetailAmountAccountingBalances
		|
		|GROUP BY
		|	RetailAmountAccountingBalances.Company,
		|	RetailAmountAccountingBalances.StructuralUnit,
		|	RetailAmountAccountingBalances.Currency,
		|	RetailAmountAccountingBalances.GLAccount
		|
		|INDEX BY
		|	Company,
		|	StructuralUnit,
		|	Currency,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableRetailAmountAccounting.Company AS Company,
		|	TableRetailAmountAccounting.StructuralUnit AS StructuralUnit,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyExchangeRateCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyExchangeRateCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableRetailAmountAccounting.Currency AS Currency,
		|	TableRetailAmountAccounting.GLAccount AS GLAccount
		|INTO TemporaryTableCurrencyExchangeRateDifferencesRetailAmountAccounting
		|FROM
		|	TemporaryTableRetailAmountAccounting AS TableRetailAmountAccounting
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableRetailAmountAccounting.Company = TableBalances.Company
		|			AND TableRetailAmountAccounting.StructuralUnit = TableBalances.StructuralUnit
		|			AND TableRetailAmountAccounting.Currency = TableBalances.Currency
		|			AND TableRetailAmountAccounting.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency In
		|					(SELECT DISTINCT
		|						TemporaryTableRetailAmountAccounting.Currency
		|					FROM
		|						TemporaryTableRetailAmountAccounting)) AS CurrencyExchangeRateCashSliceLast
		|		ON TableRetailAmountAccounting.Currency = CurrencyExchangeRateCashSliceLast.Currency
		|WHERE
		|	(ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyExchangeRateCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyExchangeRateCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyExchangeRateCashSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CurrencyExchangeRateCashSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.StructuralUnit AS StructuralUnit,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.Cost AS Cost,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTableRetailAmountAccounting AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	DocumentTable.LineNumber,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.Date,
		|	DocumentTable.Company,
		|	DocumentTable.StructuralUnit,
		|	DocumentTable.Currency,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN DocumentTable.AmountOfExchangeDifferences
		|		ELSE -DocumentTable.AmountOfExchangeDifferences
		|	END,
		|	0,
		|	0,
		|	&ExchangeDifference
		|FROM
		|	TemporaryTableCurrencyExchangeRateDifferencesRetailAmountAccounting AS DocumentTable
		|
		|ORDER BY
		|	Order,
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
		
	Else
		
		QueryNumber = 1;
		
		QueryText =
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableRetailAmountAccounting.Company AS Company,
		|	TableRetailAmountAccounting.StructuralUnit AS StructuralUnit,
		|	0 AS AmountOfExchangeDifferences,
		|	TableRetailAmountAccounting.Currency AS Currency,
		|	TableRetailAmountAccounting.GLAccount AS GLAccount
		|INTO TemporaryTableCurrencyExchangeRateDifferencesRetailAmountAccounting
		|FROM
		|	TemporaryTableRetailAmountAccounting AS TableRetailAmountAccounting
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.StructuralUnit AS StructuralUnit,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.Cost AS Cost,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	TemporaryTableRetailAmountAccounting AS DocumentTable
		|
		|ORDER BY
		|	Order,
		|	LineNumber";
		
	EndIf;
	
	Return QueryText;
	
EndFunction // GetQueryTextExchangeRateDifferncesRetailAmountAccounting()

///////////////////////////////////////////////////////////////////////////////// 
// SSL SUBSYSTEM HELPER PROCEDURES AND FUNCTIONS

// Function clears separated data created during the first start.
// Used before the data import from service.
//
Function ClearDataInDatabase() Export
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Raise(NStr("en='Insufficient rights to perform the operation';ru='Недостаточно прав для выполнения операции';vi='Không đủ quyền để thực hiện giao dịch'"));
	EndIf;
	
	SetPrivilegedMode(True);
	
	Try
		CommonUse.LockInfobase();
	Except
		Message = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Cannot set the exclusive mode (%1)';ru='Не удалось установить монопольный режим (%1)';vi='Không thể thiết lập chế độ đơn trị (%1)'"),
			BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	BeginTransaction();
	Try
		
		CommonAttributeMD = Metadata.CommonAttributes.DataAreaBasicData;
		
		// Traverse all metadata
		
		// Constants
		For Each MetadataConstants IN Metadata.Constants Do
			If Not CommonUse.IsSeparatedMetadataObject(MetadataConstants, CommonUseReUse.MainDataSeparator()) Then
				Continue;
			EndIf;
			
			ValueManager = Constants[MetadataConstants.Name].CreateValueManager();
			ValueManager.DataExchange.Load = True;
			ValueManager.Value = MetadataConstants.Type.AdjustValue();
			ValueManager.Write();
		EndDo;
		
		// Reference types
		
		ObjectKinds = New Array;
		ObjectKinds.Add("Catalogs");
		ObjectKinds.Add("Documents");
		ObjectKinds.Add("ChartsOfCharacteristicTypes");
		ObjectKinds.Add("ChartsOfAccounts");
		ObjectKinds.Add("ChartsOfCalculationTypes");
		ObjectKinds.Add("BusinessProcesses");
		ObjectKinds.Add("Tasks");
		
		For Each ObjectKind IN ObjectKinds Do
			MetadataCollection = Metadata[ObjectKind];
			For Each ObjectMD IN MetadataCollection Do
				If Not CommonUse.IsSeparatedMetadataObject(ObjectMD, CommonUseReUse.MainDataSeparator()) Then
					Continue;
				EndIf;
				
				Query = New Query;
				Query.Text =
				"SELECT
				|	_XMLExport_Table.Ref AS Ref
				|FROM
				|	" + ObjectMD.FullName() + " AS _XMLExport_Table";
				If ObjectKind = "Catalogs"
					OR ObjectKind = "ChartsOfCharacteristicTypes"
					OR ObjectKind = "ChartsOfAccounts"
					OR ObjectKind = "ChartsOfCalculationTypes" Then
					
					Query.Text = Query.Text + "
					|WHERE
					|	_XMLExport_Table.Predefined = FALSE";
				EndIf;
				
				QueryResult = Query.Execute();
				Selection = QueryResult.Select();
				While Selection.Next() Do
					Delete = New ObjectDeletion(Selection.Ref);
					Delete.DataExchange.Load = True;
					Delete.Write();
				EndDo;
			EndDo;
		EndDo;
		
		// Registers in addition to the independent information and sequence registers
		TableKinds = New Array;
		TableKinds.Add("AccumulationRegisters");
		TableKinds.Add("CalculationRegisters");
		TableKinds.Add("AccountingRegisters");
		TableKinds.Add("InformationRegisters");
		TableKinds.Add("Sequences");
		For Each TableKind IN TableKinds Do
			MetadataCollection = Metadata[TableKind];
			KindManager = Eval(TableKind);
			For Each RegisterMD IN MetadataCollection Do
				
				If Not CommonUse.IsSeparatedMetadataObject(RegisterMD, CommonUseReUse.MainDataSeparator()) Then
					Continue;
				EndIf;
				
				If TableKind = "InformationRegisters"
					AND RegisterMD.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
					
					Continue;
				EndIf;
				
				TypeManager = KindManager[RegisterMD.Name];
				
				Query = New Query;
				Query.Text =
				"SELECT DISTINCT
				|	_XMLExport_Table.Recorder AS Recorder
				|FROM
				|	" + RegisterMD.FullName() + " AS _XMLExport_Table";
				QueryResult = Query.Execute();
				Selection = QueryResult.Select();
				While Selection.Next() Do
					RecordSet = TypeManager.CreateRecordSet();
					RecordSet.Filter.Recorder.Set(Selection.Recorder);
					RecordSet.DataExchange.Load = True;
					RecordSet.Write();
				EndDo;
			EndDo;
		EndDo;
		
		// Independent information registers
		For Each RegisterMD IN Metadata.InformationRegisters Do
			
			If Not CommonUse.IsSeparatedMetadataObject(RegisterMD, CommonUseReUse.MainDataSeparator()) Then
				Continue;
			EndIf;
			
			If RegisterMD.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
				
				Continue;
			EndIf;
			
			TypeManager = InformationRegisters[RegisterMD.Name];
			
			RecordSet = TypeManager.CreateRecordSet();
			RecordSet.DataExchange.Load = True;
			RecordSet.Write();
		EndDo;
		
		// Exchange plans
		
		For Each ExchangePlanMD IN Metadata.ExchangePlans Do
			
			If Not CommonUse.IsSeparatedMetadataObject(ExchangePlanMD, CommonUseReUse.MainDataSeparator()) Then
				Continue;
			EndIf;
			
			TypeManager = ExchangePlans[ExchangePlanMD.Name];
			
			Query = New Query;
			Query.Text =
			"SELECT
			|	_XMLExport_Table.Ref AS Ref
			|FROM
			|	" + ExchangePlanMD.FullName() + " AS
			|_XMLExport_Table
			|	WHERE _XMLExport_Table.Ref <> &ThisNode";
			Query.SetParameter("ThisNode", TypeManager.ThisNode());
			QueryResult = Query.Execute();
			Selection = QueryResult.Select();
			While Selection.Next() Do
				Delete = New ObjectDeletion(Selection.Ref);
				Delete.DataExchange.Load = True;
				Delete.Write();
			EndDo;
		EndDo;
		
		CommitTransaction();
		
		CommonUse.UnlockInfobase();
		
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("en='Data Deletion';ru='Удаление данных';vi='Xóa dữ liệu'"), 
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Return True;
	
EndFunction // ClearDataInDatabase()

///////////////////////////////////////////////////////////////////////////////// 
// EXCHANGE PROCEDURES WITH BANKS

// Procedure fills in payment decryption for expense.
//
Procedure FillPaymentDetailsExpense(CurrentObject, SubsidiaryCompany = Undefined, DefaultVATRate = Undefined, ExchangeRate = Undefined, Multiplicity = Undefined, Contract = Undefined) Export
	
	If SubsidiaryCompany = Undefined Then
		SubsidiaryCompany = SmallBusinessServer.GetCompany(CurrentObject.Company);
	EndIf;
	
	If ExchangeRate = Undefined
	   AND Multiplicity = Undefined Then
		StructureByCurrency = InformationRegisters.CurrencyRates.GetLast(CurrentObject.Date, New Structure("Currency", CurrentObject.CashCurrency));
		ExchangeRate = ?(
			StructureByCurrency.ExchangeRate = 0,
			1,
			StructureByCurrency.ExchangeRate
		);
		Multiplicity = ?(
			StructureByCurrency.ExchangeRate = 0,
			1,
			StructureByCurrency.Multiplicity
		);
	EndIf;
	
	If DefaultVATRate = Undefined Then
		If CurrentObject.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
			DefaultVATRate = CurrentObject.Company.DefaultVATRate;
		ElsIf CurrentObject.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then
			DefaultVATRate = SmallBusinessReUse.GetVATRateWithoutVAT();
		Else
			DefaultVATRate = SmallBusinessReUse.GetVATRateZero();
		EndIf;
	EndIf;
	
	// Filling default payment details.
	Query = New Query;
	Query.Text =
	
	"SELECT
	|	AccountsPayableBalances.Company AS Company,
	|	AccountsPayableBalances.Counterparty AS Counterparty,
	|	AccountsPayableBalances.Contract AS Contract,
	|	CASE
	|		WHEN AccountsPayableBalances.Counterparty.DoOperationsByDocuments
	|			THEN AccountsPayableBalances.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	CASE
	|		WHEN AccountsPayableBalances.Counterparty.DoOperationsByOrders
	|			THEN AccountsPayableBalances.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END AS Order,
	|	AccountsPayableBalances.SettlementsType AS SettlementsType,
	|	SUM(AccountsPayableBalances.AmountBalance) AS AmountBalance,
	|	SUM(AccountsPayableBalances.AmountCurBalance) AS AmountCurBalance,
	|	AccountsPayableBalances.Document.Date AS DocumentDate,
	|	SUM(CAST(AccountsPayableBalances.AmountCurBalance * SettlementsCurrencyRates.ExchangeRate * CurrencyRatesOfDocument.Multiplicity / (CurrencyRatesOfDocument.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2))) AS AmountCurrDocument,
	|	CurrencyRatesOfDocument.ExchangeRate AS CashAssetsRate,
	|	CurrencyRatesOfDocument.Multiplicity AS CashMultiplicity,
	|	SettlementsCurrencyRates.ExchangeRate AS ExchangeRate,
	|	SettlementsCurrencyRates.Multiplicity AS Multiplicity
	|FROM
	|	(SELECT
	|		AccountsPayableBalances.Company AS Company,
	|		AccountsPayableBalances.Counterparty AS Counterparty,
	|		AccountsPayableBalances.Contract AS Contract,
	|		AccountsPayableBalances.Document AS Document,
	|		AccountsPayableBalances.Order AS Order,
	|		AccountsPayableBalances.SettlementsType AS SettlementsType,
	|		ISNULL(AccountsPayableBalances.AmountBalance, 0) AS AmountBalance,
	|		ISNULL(AccountsPayableBalances.AmountCurBalance, 0) AS AmountCurBalance
	|	FROM
	|		AccumulationRegister.AccountsPayable.Balance(
	|				,
	|				Company = &Company
	|					AND Counterparty = &Counterparty
	|					// TextOfContractSelection
	|					AND SettlementsType = VALUE(Enum.SettlementsTypes.Debt)) AS AccountsPayableBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsVendorSettlements.Company,
	|		DocumentRegisterRecordsVendorSettlements.Counterparty,
	|		DocumentRegisterRecordsVendorSettlements.Contract,
	|		DocumentRegisterRecordsVendorSettlements.Document,
	|		DocumentRegisterRecordsVendorSettlements.Order,
	|		DocumentRegisterRecordsVendorSettlements.SettlementsType,
	|		CASE
	|			WHEN DocumentRegisterRecordsVendorSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ISNULL(DocumentRegisterRecordsVendorSettlements.Amount, 0)
	|			ELSE ISNULL(DocumentRegisterRecordsVendorSettlements.Amount, 0)
	|		END,
	|		CASE
	|			WHEN DocumentRegisterRecordsVendorSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ISNULL(DocumentRegisterRecordsVendorSettlements.AmountCur, 0)
	|			ELSE ISNULL(DocumentRegisterRecordsVendorSettlements.AmountCur, 0)
	|		END
	|	FROM
	|		AccumulationRegister.AccountsPayable AS DocumentRegisterRecordsVendorSettlements
	|	WHERE
	|		DocumentRegisterRecordsVendorSettlements.Recorder = &Ref
	|		AND DocumentRegisterRecordsVendorSettlements.Period <= &Period
	|		AND DocumentRegisterRecordsVendorSettlements.Company = &Company
	|		AND DocumentRegisterRecordsVendorSettlements.Counterparty = &Counterparty
	|		AND DocumentRegisterRecordsVendorSettlements.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)) AS AccountsPayableBalances
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&Period, Currency = &Currency) AS CurrencyRatesOfDocument
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&Period, ) AS SettlementsCurrencyRates
	|		ON AccountsPayableBalances.Contract.SettlementsCurrency = SettlementsCurrencyRates.Currency
	|WHERE
	|	AccountsPayableBalances.AmountCurBalance > 0
	|
	|GROUP BY
	|	AccountsPayableBalances.Company,
	|	AccountsPayableBalances.Counterparty,
	|	AccountsPayableBalances.Contract,
	|	AccountsPayableBalances.Document,
	|	AccountsPayableBalances.Order,
	|	AccountsPayableBalances.SettlementsType,
	|	AccountsPayableBalances.Document.Date,
	|	CurrencyRatesOfDocument.ExchangeRate,
	|	CurrencyRatesOfDocument.Multiplicity,
	|	SettlementsCurrencyRates.ExchangeRate,
	|	SettlementsCurrencyRates.Multiplicity,
	|	CASE
	|		WHEN AccountsPayableBalances.Counterparty.DoOperationsByDocuments
	|			THEN AccountsPayableBalances.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN AccountsPayableBalances.Counterparty.DoOperationsByOrders
	|			THEN AccountsPayableBalances.Order
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END
	|
	|ORDER BY
	|	DocumentDate";
		
	Query.SetParameter("Company", SubsidiaryCompany);
	Query.SetParameter("Counterparty", CurrentObject.Counterparty);
	Query.SetParameter("Period", CurrentObject.Date);
	Query.SetParameter("Currency", CurrentObject.CashCurrency);
	Query.SetParameter("Ref", CurrentObject.Ref);
	
	If ValueIsFilled(Contract)
		AND TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts") Then
		Query.Text = StrReplace(Query.Text, "// TextOfContractSelection", "AND Contract = &Contract");
		Query.SetParameter("Contract", Contract);
		ContractByDefault = Contract; // if there is no debt, then advance will be assigned to this contract
	Else
		NeedFilterByContracts = SmallBusinessReUse.CounterpartyContractsControlNeeded();
		ContractTypesList = Catalogs.CounterpartyContracts.GetContractKindsListForDocument(CurrentObject.Ref, CurrentObject.OperationKind);
		If NeedFilterByContracts
		   AND CurrentObject.Counterparty.DoOperationsByContracts Then
			Query.Text = StrReplace(Query.Text, "// TextOfContractSelection", "And Contract.ContractType IN (&ContractTypesList)");
			Query.SetParameter("ContractTypesList", ContractTypesList);
		EndIf;
		ContractByDefault = Catalogs.CounterpartyContracts.GetDefaultContractByCompanyContractKind(
			CurrentObject.Counterparty,
			CurrentObject.Company,
			ContractTypesList
		); // if there is no debt, then advance will be assigned to this contract
	EndIf;
		
	StructureContractCurrencyRateByDefault = InformationRegisters.CurrencyRates.GetLast(
		CurrentObject.Date,
		New Structure("Currency", ContractByDefault.SettlementsCurrency)
	);
	
	SelectionOfQueryResult = Query.Execute().Select();
	
	CurrentObject.PaymentDetails.Clear();
	
	AmountLeftToDistribute = CurrentObject.DocumentAmount;
	
	While AmountLeftToDistribute > 0 Do
		
		NewRow = CurrentObject.PaymentDetails.Add();
		
		If SelectionOfQueryResult.Next() Then
			
			FillPropertyValues(NewRow, SelectionOfQueryResult);
			
			If SelectionOfQueryResult.AmountCurrDocument <= AmountLeftToDistribute Then // balance amount is less or equal than it is necessary to distribute
				
				NewRow.SettlementsAmount = SelectionOfQueryResult.AmountCurBalance;
				NewRow.PaymentAmount = SelectionOfQueryResult.AmountCurrDocument;
				NewRow.VATRate = DefaultVATRate;
				NewRow.VATAmount = NewRow.PaymentAmount - (NewRow.PaymentAmount) / ((DefaultVATRate.Rate + 100) / 100);
				AmountLeftToDistribute = AmountLeftToDistribute - SelectionOfQueryResult.AmountCurrDocument;
				
			Else // Balance amount is greater than it is necessary to distribute
				
				NewRow.SettlementsAmount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
					AmountLeftToDistribute,
					SelectionOfQueryResult.CashAssetsRate,
					SelectionOfQueryResult.ExchangeRate,
					SelectionOfQueryResult.CashMultiplicity,
					SelectionOfQueryResult.Multiplicity
				);
				NewRow.PaymentAmount = AmountLeftToDistribute;
				NewRow.VATRate = DefaultVATRate;
				NewRow.VATAmount = NewRow.PaymentAmount - (NewRow.PaymentAmount) / ((DefaultVATRate.Rate + 100) / 100);
				AmountLeftToDistribute = 0;
				
			EndIf;
			
		Else
			
			NewRow.Contract = ContractByDefault;
			NewRow.ExchangeRate = ?(
				StructureContractCurrencyRateByDefault.ExchangeRate = 0,
				1,
				StructureContractCurrencyRateByDefault.ExchangeRate
			);
			NewRow.Multiplicity = ?(
				StructureContractCurrencyRateByDefault.Multiplicity = 0,
				1,
				StructureContractCurrencyRateByDefault.Multiplicity
			);
			NewRow.SettlementsAmount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				AmountLeftToDistribute,
				ExchangeRate,
				NewRow.ExchangeRate,
				Multiplicity,
				NewRow.Multiplicity
			);
			NewRow.AdvanceFlag = True;
			NewRow.PaymentAmount = AmountLeftToDistribute;
			NewRow.VATRate = DefaultVATRate;
			NewRow.VATAmount = NewRow.PaymentAmount - (NewRow.PaymentAmount) / ((DefaultVATRate.Rate + 100) / 100);
			AmountLeftToDistribute = 0;
			
		EndIf;
		
	EndDo;
	
	If CurrentObject.PaymentDetails.Count() = 0 Then
		CurrentObject.PaymentDetails.Add();
		CurrentObject.PaymentDetails[0].PaymentAmount = CurrentObject.DocumentAmount;
	EndIf;
	
	PaymentAmount = CurrentObject.PaymentDetails.Total("PaymentAmount");
	
EndProcedure // FillPaymentDetailsExpenseDecryption()

// Procedure fills in payment decryption for receipt.
//
Procedure FillPaymentDetailsReceipt(CurrentObject, SubsidiaryCompany = Undefined, DefaultVATRate = Undefined, ExchangeRate = Undefined, Multiplicity = Undefined, Contract = Undefined) Export
	
	If SubsidiaryCompany = Undefined Then
		SubsidiaryCompany = SmallBusinessServer.GetCompany(CurrentObject.Company);
	EndIf;
	
	If ExchangeRate = Undefined
	   AND Multiplicity = Undefined Then
		StructureByCurrency = InformationRegisters.CurrencyRates.GetLast(CurrentObject.Date, New Structure("Currency", CurrentObject.CashCurrency));
		ExchangeRate = ?(
			StructureByCurrency.ExchangeRate = 0,
			1,
			StructureByCurrency.ExchangeRate
		);
		Multiplicity = ?(
			StructureByCurrency.ExchangeRate = 0,
			1,
			StructureByCurrency.Multiplicity
		);
	EndIf;
	
	If DefaultVATRate = Undefined Then
		If CurrentObject.VATTaxation = Enums.VATTaxationTypes.TaxableByVAT Then
			DefaultVATRate = CurrentObject.Company.DefaultVATRate;
		ElsIf CurrentObject.VATTaxation = Enums.VATTaxationTypes.NotTaxableByVAT Then
			DefaultVATRate = SmallBusinessReUse.GetVATRateWithoutVAT();
		Else
			DefaultVATRate = SmallBusinessReUse.GetVATRateZero();
		EndIf;
	EndIf;
	
	// Filling default payment details.
	Query = New Query;
	Query.Text =
	
	"SELECT
	|	AccountsReceivableBalances.Company AS Company,
	|	AccountsReceivableBalances.Counterparty AS Counterparty,
	|	AccountsReceivableBalances.Contract AS Contract,
	|	CASE
	|		WHEN AccountsReceivableBalances.Counterparty.DoOperationsByDocuments
	|			THEN AccountsReceivableBalances.Document
	|		ELSE UNDEFINED
	|	END AS Document,
	|	CASE
	|		WHEN AccountsReceivableBalances.Counterparty.DoOperationsByOrders
	|			THEN AccountsReceivableBalances.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END AS Order,
	|	AccountsReceivableBalances.SettlementsType AS SettlementsType,
	|	SUM(AccountsReceivableBalances.AmountBalance) AS AmountBalance,
	|	SUM(AccountsReceivableBalances.AmountCurBalance) AS AmountCurBalance,
	|	AccountsReceivableBalances.Document.Date AS DocumentDate,
	|	SUM(CAST(AccountsReceivableBalances.AmountCurBalance * SettlementsCurrencyRates.ExchangeRate * CurrencyRatesOfDocument.Multiplicity / (CurrencyRatesOfDocument.ExchangeRate * SettlementsCurrencyRates.Multiplicity) AS NUMBER(15, 2))) AS AmountCurrDocument,
	|	CurrencyRatesOfDocument.ExchangeRate AS CashAssetsRate,
	|	CurrencyRatesOfDocument.Multiplicity AS CashMultiplicity,
	|	SettlementsCurrencyRates.ExchangeRate AS ExchangeRate,
	|	SettlementsCurrencyRates.Multiplicity AS Multiplicity
	|FROM
	|	(SELECT
	|		AccountsReceivableBalances.Company AS Company,
	|		AccountsReceivableBalances.Counterparty AS Counterparty,
	|		AccountsReceivableBalances.Contract AS Contract,
	|		AccountsReceivableBalances.Document AS Document,
	|		AccountsReceivableBalances.Order AS Order,
	|		AccountsReceivableBalances.SettlementsType AS SettlementsType,
	|		ISNULL(AccountsReceivableBalances.AmountBalance, 0) AS AmountBalance,
	|		ISNULL(AccountsReceivableBalances.AmountCurBalance, 0) AS AmountCurBalance
	|	FROM
	|		AccumulationRegister.AccountsReceivable.Balance(
	|				,
	|				Company = &Company
	|					AND Counterparty = &Counterparty
	|					// TextOfContractSelection
	|					AND SettlementsType = VALUE(Enum.SettlementsTypes.Debt)) AS AccountsReceivableBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecordsAccountsReceivable.Company,
	|		DocumentRegisterRecordsAccountsReceivable.Counterparty,
	|		DocumentRegisterRecordsAccountsReceivable.Contract,
	|		DocumentRegisterRecordsAccountsReceivable.Document,
	|		DocumentRegisterRecordsAccountsReceivable.Order,
	|		DocumentRegisterRecordsAccountsReceivable.SettlementsType,
	|		CASE
	|			WHEN DocumentRegisterRecordsAccountsReceivable.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ISNULL(DocumentRegisterRecordsAccountsReceivable.Amount, 0)
	|			ELSE ISNULL(DocumentRegisterRecordsAccountsReceivable.Amount, 0)
	|		END,
	|		CASE
	|			WHEN DocumentRegisterRecordsAccountsReceivable.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ISNULL(DocumentRegisterRecordsAccountsReceivable.AmountCur, 0)
	|			ELSE ISNULL(DocumentRegisterRecordsAccountsReceivable.AmountCur, 0)
	|		END
	|	FROM
	|		AccumulationRegister.AccountsReceivable AS DocumentRegisterRecordsAccountsReceivable
	|	WHERE
	|		DocumentRegisterRecordsAccountsReceivable.Recorder = &Ref
	|		AND DocumentRegisterRecordsAccountsReceivable.Period <= &Period
	|		AND DocumentRegisterRecordsAccountsReceivable.Company = &Company
	|		AND DocumentRegisterRecordsAccountsReceivable.Counterparty = &Counterparty
	|		AND DocumentRegisterRecordsAccountsReceivable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)) AS AccountsReceivableBalances
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&Period, Currency = &Currency) AS CurrencyRatesOfDocument
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(&Period, ) AS SettlementsCurrencyRates
	|		ON AccountsReceivableBalances.Contract.SettlementsCurrency = SettlementsCurrencyRates.Currency
	|WHERE
	|	AccountsReceivableBalances.AmountCurBalance > 0
	|
	|GROUP BY
	|	AccountsReceivableBalances.Company,
	|	AccountsReceivableBalances.Counterparty,
	|	AccountsReceivableBalances.Contract,
	|	AccountsReceivableBalances.Document,
	|	AccountsReceivableBalances.Order,
	|	AccountsReceivableBalances.SettlementsType,
	|	AccountsReceivableBalances.Document.Date,
	|	CurrencyRatesOfDocument.ExchangeRate,
	|	CurrencyRatesOfDocument.Multiplicity,
	|	SettlementsCurrencyRates.ExchangeRate,
	|	SettlementsCurrencyRates.Multiplicity,
	|	CASE
	|		WHEN AccountsReceivableBalances.Counterparty.DoOperationsByDocuments
	|			THEN AccountsReceivableBalances.Document
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN AccountsReceivableBalances.Counterparty.DoOperationsByOrders
	|			THEN AccountsReceivableBalances.Order
	|		ELSE VALUE(Document.CustomerOrder.EmptyRef)
	|	END
	|
	|ORDER BY
	|	DocumentDate";
		
	Query.SetParameter("Company", SubsidiaryCompany);
	Query.SetParameter("Counterparty", CurrentObject.Counterparty);
	Query.SetParameter("Period", CurrentObject.Date);
	Query.SetParameter("Currency", CurrentObject.CashCurrency);
	Query.SetParameter("Ref", CurrentObject.Ref);
	
	If ValueIsFilled(Contract)
		AND TypeOf(Contract) = Type("CatalogRef.CounterpartyContracts") Then
		Query.Text = StrReplace(Query.Text, "// TextOfContractSelection", "AND Contract = &Contract");
		Query.SetParameter("Contract", Contract);
		ContractByDefault = Contract;
	Else
		NeedFilterByContracts = SmallBusinessReUse.CounterpartyContractsControlNeeded();
		ContractTypesList = Catalogs.CounterpartyContracts.GetContractKindsListForDocument(CurrentObject.Ref, CurrentObject.OperationKind);
		If NeedFilterByContracts
		   AND CurrentObject.Counterparty.DoOperationsByContracts Then
			Query.Text = StrReplace(Query.Text, "// TextOfContractSelection", "And Contract.ContractType IN (&ContractTypesList)");
			Query.SetParameter("ContractTypesList", ContractTypesList);
		EndIf;
		ContractByDefault = Catalogs.CounterpartyContracts.GetDefaultContractByCompanyContractKind(
			CurrentObject.Counterparty,
			CurrentObject.Company,
			ContractTypesList
		); // if there is no debt, then advance will be assigned to this contract
	EndIf;
	
	StructureContractCurrencyRateByDefault = InformationRegisters.CurrencyRates.GetLast(
		CurrentObject.Date,
		New Structure("Currency", ContractByDefault.SettlementsCurrency)
	);
	
	SelectionOfQueryResult = Query.Execute().Select();
	
	CurrentObject.PaymentDetails.Clear();
	
	AmountLeftToDistribute = CurrentObject.DocumentAmount;
	
	While AmountLeftToDistribute > 0 Do
		
		NewRow = CurrentObject.PaymentDetails.Add();
		
		If SelectionOfQueryResult.Next() Then
			
			FillPropertyValues(NewRow, SelectionOfQueryResult);
			
			If SelectionOfQueryResult.AmountCurrDocument <= AmountLeftToDistribute Then // balance amount is less or equal than it is necessary to distribute
				
				NewRow.SettlementsAmount = SelectionOfQueryResult.AmountCurBalance;
				NewRow.PaymentAmount = SelectionOfQueryResult.AmountCurrDocument;
				NewRow.VATRate = DefaultVATRate;
				NewRow.VATAmount = NewRow.PaymentAmount - (NewRow.PaymentAmount) / ((DefaultVATRate.Rate + 100) / 100);
				AmountLeftToDistribute = AmountLeftToDistribute - SelectionOfQueryResult.AmountCurrDocument;
				
			Else // Balance amount is greater than it is necessary to distribute
				
				NewRow.SettlementsAmount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
					AmountLeftToDistribute,
					SelectionOfQueryResult.CashAssetsRate,
					SelectionOfQueryResult.ExchangeRate,
					SelectionOfQueryResult.CashMultiplicity,
					SelectionOfQueryResult.Multiplicity
				);
				NewRow.PaymentAmount = AmountLeftToDistribute;
				NewRow.VATRate = DefaultVATRate;
				NewRow.VATAmount = NewRow.PaymentAmount - (NewRow.PaymentAmount) / ((DefaultVATRate.Rate + 100) / 100);
				AmountLeftToDistribute = 0;
				
			EndIf;
			
		Else
			
			NewRow.Contract = ContractByDefault;
			NewRow.ExchangeRate = ?(
				StructureContractCurrencyRateByDefault.ExchangeRate = 0,
				1,
				StructureContractCurrencyRateByDefault.ExchangeRate
			);
			NewRow.Multiplicity = ?(
				StructureContractCurrencyRateByDefault.Multiplicity = 0,
				1,
				StructureContractCurrencyRateByDefault.Multiplicity
			);
			NewRow.SettlementsAmount = SmallBusinessServer.RecalculateFromCurrencyToCurrency(
				AmountLeftToDistribute,
				ExchangeRate,
				NewRow.ExchangeRate,
				Multiplicity,
				NewRow.Multiplicity
			);
			NewRow.AdvanceFlag = True;
			NewRow.PaymentAmount = AmountLeftToDistribute;
			NewRow.VATRate = DefaultVATRate;
			NewRow.VATAmount = NewRow.PaymentAmount - (NewRow.PaymentAmount) / ((DefaultVATRate.Rate + 100) / 100);
			AmountLeftToDistribute = 0;
			
		EndIf;
		
	EndDo;
	
	If CurrentObject.PaymentDetails.Count() = 0 Then
		CurrentObject.PaymentDetails.Add();
		CurrentObject.PaymentDetails[0].PaymentAmount = CurrentObject.DocumentAmount;
	EndIf;
	
	PaymentAmount = CurrentObject.PaymentDetails.Total("PaymentAmount");
	
EndProcedure // FillPaymentDecryptionReceipt()

// Imports the form settings.
//
&AtServer
Function LoadSettingsFilesDisposition(BankAccount = Undefined) Export
	
	Settings = SystemSettingsStorage.Load("DataProcessor.ClientBank.Form.DefaultForm/" + ?(ValueIsFilled(BankAccount), GetURL(BankAccount), "BankAccountIsNotSpecified") , "ExportingInSberbank");
	
	If Settings <> Undefined Then
		
		ReturnStructure = New Structure("ExportFile, ImportFile");
		ReturnStructure.ExportFile = Settings.Get("ExportFile");
		ReturnStructure.ImportFile = Settings.Get("ImportFile");
		Return ReturnStructure
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction // ImportExchangeWithBanksFormSettings()

///////////////////////////////////////////////////////////////////////////////// 
// BUSINESS CALENDARS PROCEDURES AND FUNCTIONS

// Function returns Calendars catalog item If item is not found, Undefined is returned.
// 
Function GetCalendarByProductionCalendaRF() Export
	
	BusinessCalendarRF = CalendarSchedules.BusinessCalendarOfRussiaFederation();
	If BusinessCalendarRF = Undefined Then
		
		WriteLogEvent(NStr("en='Cannot fill in the work schedule data for the company according to the RF production calendar.';ru='Неудалось заполнить данные граффиков работы для организации на основании производственного календаря РФ.';vi='Không thể điền dữ liệu lịch biểu làm việc đối với doanh nghiệp trên cơ sở lịch sản xuất Việt Nam.'"), 
			EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
		
		Return Undefined;
		
	EndIf;
	
	Query = New Query(
	"SELECT
	|	Calendars.Ref AS Calendar
	|FROM
	|	Catalog.Calendars AS Calendars
	|WHERE
	|	Calendars.BusinessCalendar = &BusinessCalendarRF");
	
	Query.SetParameter("BusinessCalendarRF", BusinessCalendarRF);
	SelectionOfQueryResult = Query.Execute().Select();
	
	// Deliberately cancel recursion in case there is no work schedule
	Return ?(SelectionOfQueryResult.Next(),
					SelectionOfQueryResult.Calendar,
					Undefined);
	
EndFunction // GetCalendarByProductionCalendaRF()

// Old. Saved to support compatibility.
// Function reads calendar data from register
//
// Parameters
// Calendar		- Refs to the
// current catalog item YearNumber		- Year number for which it is required to read the calendar
//
// Return
// value Array		- array in which dates included in the calendar are stored
//
Function ReadScheduleDataFromRegister(Calendar, YearNumber) Export
	
	Query = New Query;
	Query.SetParameter("Calendar",	Calendar);
	Query.SetParameter("CurrentYear",	YearNumber);
	Query.Text =
	"SELECT
	|	CalendarSchedules.ScheduleDate AS CalendarDate
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|WHERE
	|	CalendarSchedules.Calendar = &Calendar
	|	AND CalendarSchedules.Year = &CurrentYear
	|	AND CalendarSchedules.DayIncludedInSchedule";
	
	Return Query.Execute().Unload().UnloadColumn("CalendarDate");
	
EndFunction

///////////////////////////////////////////////////////////////////////////////// 
// PROCEDURES AND FUNCTIONS OF COUNTERPARTIES CONTACT INFORMATION PRINTING

// The function returns a request result by contact info kinds that can be used for printing.
//
Function GetAvailableForPrintingCIKinds() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ContactInformationKinds.Ref AS CIKind,
		|	ContactInformationKinds.Description AS Description,
		|	ContactInformationKinds.ToolTip AS ToolTip,
		|	1 AS CIOwnerIndex,
		|	ContactInformationKinds.AdditionalOrderingAttribute AS AdditionalOrderingAttribute
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	ContactInformationKinds.Parent = &CICatalogCounterparties
		|	AND ContactInformationKinds.IsFolder = FALSE
		|	AND ContactInformationKinds.DeletionMark = FALSE
		|
		|UNION ALL
		|
		|SELECT
		|	ContactInformationKinds.Ref,
		|	ContactInformationKinds.Description,
		|	ContactInformationKinds.ToolTip,
		|	2,
		|	ContactInformationKinds.AdditionalOrderingAttribute
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	ContactInformationKinds.Parent = &CICatalogContactPersons
		|	AND ContactInformationKinds.IsFolder = FALSE
		|	AND ContactInformationKinds.DeletionMark = FALSE
		|
		|UNION ALL
		|
		|SELECT
		|	ContactInformationKinds.Ref,
		|	ContactInformationKinds.Description,
		|	ContactInformationKinds.ToolTip,
		|	3,
		|	ContactInformationKinds.AdditionalOrderingAttribute
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	ContactInformationKinds.Parent = &CICatalogIndividuals
		|	AND ContactInformationKinds.IsFolder = FALSE
		|	AND ContactInformationKinds.DeletionMark = FALSE
		|	AND ContactInformationKinds.Type = &TypePhone
		|
		|ORDER BY
		|	CIOwnerIndex,
		|	AdditionalOrderingAttribute";
	
	Query.SetParameter("CICatalogCounterparties", Catalogs.ContactInformationKinds.CatalogCounterparties);	
	Query.SetParameter("CICatalogContactPersons", Catalogs.ContactInformationKinds.CatalogContactPersons);	
	Query.SetParameter("CICatalogIndividuals", Catalogs.ContactInformationKinds.CatalogIndividuals);	
	Query.SetParameter("TypePhone", Enums.ContactInformationTypes.Phone);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return QueryResult;
	
EndFunction

// The function sets an initial value of the contact information kind use.
//
// Parameters:
//  CIKind	 - Catalog.ContactInformationKinds	 - Check contact
// information kind Return value:
//  Boolean - Contact information kind is printed by default
Function SetPrintDefaultCIKind(CIKind) Export
	
	If CIKind = Catalogs.ContactInformationKinds.CounterpartyPostalAddress 
		Or CIKind = Catalogs.ContactInformationKinds.CounterpartyFax
		Or CIKind = Catalogs.ContactInformationKinds.CounterpartyOtherInformation
		Then
			Return False;
	EndIf;
	
	Return CIKind.Predefined;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////// 
// MANAGER MONITOR PROCEDURES AND FUNCTIONS

// Function creates report settings linker and overrides specified parameters and filters.
//
// Parameters:
//  ReportProperties			 - Structure	 - keys: "ReportName" - report name as specified in the configurator, "VariantKeys" (optional) - ParametersAndFilters
//  report variant name	 - Array - structures array for specifying changing parameters and filters. Structure keys:
// 								"FieldName" (mandatory) - parameter name or data layout field by which
// 								the filter is set, "RightValue" (mandatory) - selected value of
// 								parameter or filter , "SettingKind" (optional) - defines a container for placing parameter or filter, options:
// 								"Settings" "FixedSettings", other structure keys are optional and they specify the filter item properties.
// Returns:
//  DataCompositionSettingsComposer - linker of settings with changed parameters and filters.
Function GetOverriddenSettingsComposer(ReportProperties, ParametersAndSelections) Export
	Var ReportName, VariantKey;
	
	ReportProperties.Property("ReportName", ReportName);
	ReportProperties.Property("VariantKey", VariantKey);
	
	DataCompositionSchema = Reports[ReportName].GetTemplate("MainDataCompositionSchema");
	
	If VariantKey <> Undefined AND Not IsBlankString(VariantKey) Then
		DesiredReportOption = DataCompositionSchema.SettingVariants.Find(VariantKey);
		If DesiredReportOption <> Undefined Then
			Settings = DesiredReportOption.Settings;
		EndIf;
	EndIf;
	
	If Settings = Undefined Then
		Settings = DataCompositionSchema.DefaultSettings;
	EndIf;
	
	DataCompositionSettingsComposer = New DataCompositionSettingsComposer;
	DataCompositionSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	DataCompositionSettingsComposer.LoadSettings(Settings);
	
	For Each ParameterFilter IN ParametersAndSelections Do
		
		If ParameterFilter.Property("SettingKind") Then
			If ParameterFilter.SettingKind = "Settings" Then
				Container = DataCompositionSettingsComposer.Settings;
			ElsIf ParameterFilter.SettingKind = "FixedSettings" Then
				Container = DataCompositionSettingsComposer.FixedSettings;
			EndIf;
		Else
			Container = DataCompositionSettingsComposer.Settings;
		EndIf;
		
		FoundParameter = Container.DataParameters.FindParameterValue(New DataCompositionParameter(ParameterFilter.FieldName));
		If FoundParameter <> Undefined Then
			Container.DataParameters.SetParameterValue(FoundParameter.Parameter, ParameterFilter.RightValue);
		EndIf;
		
		FoundFilters = CommonUseClientServer.FindFilterItemsAndGroups(Container.Filter, ParameterFilter.FieldName);
		For Each FoundFilter IN FoundFilters Do
			
			If TypeOf(FoundFilter) <> Type("DataCompositionFilterItem") Then
				Continue;
			EndIf;
			
			FillPropertyValues(FoundFilter, ParameterFilter);
			
			If Not ParameterFilter.Property("ComparisonType") Then
				FoundFilter.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
			If Not ParameterFilter.Property("Use") Then
				FoundFilter.Use = True;
			EndIf;
			If Not ParameterFilter.Property("ViewMode") Then
				FoundFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
			EndIf;
			
		EndDo;
		
		If FoundFilters.Count() = 0 AND FoundParameter = Undefined Then
			AddedItem = CommonUseClientServer.AddCompositionItem(Container.Filter, ParameterFilter.FieldName, DataCompositionComparisonType.Equal);
			FillPropertyValues(AddedItem, ParameterFilter);
		EndIf;
		
	EndDo;
	
	Return DataCompositionSettingsComposer;
	
EndFunction // GetUserSettings()

// Function returns colors used for monitors.
//
// Parameters:
//  ColorName - String - Color name
Function ColorForMonitors(ColorName) Export
	
	Color = New Color();
	
	If ColorName = "Green" Then
		Color = New Color(25, 204, 25);
	ElsIf ColorName = "Dark-green" Then
		Color = New Color(29, 150, 66);
	ElsIf ColorName = "Yellow" Then
		Color = New Color(254, 225, 1);
	ElsIf ColorName = "Orange" Then
		Color = WebColors.Orange;
	ElsIf ColorName = "Coral" Then
		Color = WebColors.Coral;
	ElsIf ColorName = "Red" Then
		Color = New Color(208, 42, 53);
	ElsIf ColorName = "Magenta" Then
		Color = WebColors.Magenta;
	ElsIf ColorName = "Blue" Then
		Color = WebColors.DeepSkyBlue;
	ElsIf ColorName = "Light-gray" Then
		Color = WebColors.Gainsboro;
	ElsIf ColorName = "Gray" Then
		Color = WebColors.Gray;
	EndIf;
	
	Return Color;
	
EndFunction

// Function returns the resulting formatted string.
//
// Parameters:
//  RowItems - Structures array with the "Row" key
//    and the output row value, the other keys match the formatted row designer parameters
//
Function BuildFormattedString(RowItems) Export
	
	String = "";
	Font = Undefined;
	TextColor = Undefined;
	BackColor = Undefined;
	FormattedStringsArray = New Array;
	
	For Each Item IN RowItems Do
		Item.Property("String", String);
		Item.Property("Font", Font);
		Item.Property("TextColor", TextColor);
		Item.Property("BackColor", BackColor);
		FormattedStringsArray.Add(New FormattedString(String, Font, TextColor, BackColor)); 
	EndDo;
	
	Return New FormattedString(FormattedStringsArray);
	
EndFunction

// The function creates a title as a formatted string for item widget headers.
//
// Parameters:
//  SourceAmount - Number - value from which
// title is generated Return value:
//  FormattedString - Title string
Function GenerateTitle(val SourceAmount) Export
	
	FormattedAmount = Format(SourceAmount, "NFD=2; NGS=' '; NZ=—; NG=3,0");
	Delimiter = Find(FormattedAmount, ",");
	RowPositionThousands = Left(FormattedAmount, Delimiter-4);
	RowDigitUnits = Mid(FormattedAmount, Delimiter-3);
	
	RowItems = New Array;
	RowItems.Add(New Structure("String, Font", RowPositionThousands, New Font(StyleFonts.ExtraLargeTextFont)));
	RowItems.Add(New Structure("String, Font", RowDigitUnits, New Font(StyleFonts.NormalTextFont)));
	
	Return BuildFormattedString(RowItems);
	
EndFunction

///////////////////////////////////////////////////////////////////////////////// 
// DESKTOP MANAGEMENT PROCEDURES AND FUNCTIONS

//Determines a default desktop depending on the user access rights.
//
Procedure ConfigureUserDesktop(SettingsModified = False) Export
	
	RunMode = CommonUseReUse.ApplicationRunningMode();
	If RunMode.SaaS
		AND RunMode.ThisIsSystemAdministrator Then
		Return;
	EndIf;
	
	HomePageSettings = CommonUse.SystemSettingsStorageImport("Common/HomePageSettings","");
	
	If HomePageSettings = Undefined Then
		
		HomePageSettings = New HomePageSettings;
		FormsContent = HomePageSettings.GetForms();
		
		If IsInRole("FullRights") Then
			
			FoundItem = FormsContent.LeftColumn.Find("CommonForm.BeforeBeginningWorkWithSystemForm");
			If FoundItem = Undefined
				OR Not (Constants.InitialSettingCompanyDetailsFilled.Get()
					AND Constants.InitialSettingOpeningBalancesFilled.Get()) Then
				Return;
			EndIf;
			
			FormsContent.LeftColumn.Delete(FoundItem);
			FormsContent.LeftColumn.Add("DataProcessor.ManagerMonitors.Form.ManagerMonitors");
			
		ElsIf IsInRole("AddChangeSalesSubsystem") Then
			FormsContent.LeftColumn.Add("DocumentJournal.SalesDocuments.ListForm");
		ElsIf IsInRole("AddChangePurchasesSubsystem") Then
			FormsContent.LeftColumn.Add("DocumentJournal.PurchaseDocuments.ListForm");
		ElsIf IsInRole("AddChangeProductionSubsystem") Then
			FormsContent.LeftColumn.Add("DocumentJournal.ProductionDocuments.ListForm");
		ElsIf IsInRole("AddChangePayrollSubsystem") Then
			FormsContent.LeftColumn.Add("DocumentJournal.PayrollDocuments.ListForm");
		ElsIf IsInRole("AddChangeBankSubsystem") Then
			FormsContent.LeftColumn.Add("DocumentJournal.BankDocuments.ListForm");
		EndIf;
		
		HomePageSettings.SetForms(FormsContent);
		CommonUse.SystemSettingsStorageSave("Common/HomePageSettings","", HomePageSettings);
		
		SettingsModified = True;
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////// 
// WORK WITH OBJECT QUERY SCHEMA

// Function - Find the field of query schema available table
//
// Parameters:
//  AvailableTable - AvailableTableQuerySchema	 - table where search
//  FieldName is executed			 - String - search field
//  name FieldType			 - Type - possible values "QuerySchemaAvailableField", "QuerySchemaAvailableInsertedTable".
//  					If parameter is specified, then search is executed only by
// fields of the specified Return value type:
//  QuerySchemaAvailableField,QuerySchemaAvailableNestedTable - found field
Function FindAvailableTableQuerySchemaField(AvailableTable, FieldName, FieldType = Undefined) Export
	
	Result = Undefined;
	
	For Each Field IN AvailableTable.Fields Do
		If Field.Name = FieldName AND (FieldType = Undefined Or (TypeOf(Field) = FieldType)) Then
			Result = Field;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Function - Find query schema source
//
// Parameters:
//  Sources		 - SourcesQuerySchema 	 - sources where TableAlias
//  search is executed. - String	 - TableType
//  desired table alias		 - Type - possible values "QuerySchemaTable", "QuerySchemaInsertedQuery", "TemporaryQuerySchemaTableDescription".
//  					If the parameter is defined, then search is performed only
// by the sources of the specified type Return value:
//  QuerySchemaSource - source is found
Function FindQuerySchemaSource(Sources, TablePseudonym, TableType = Undefined) Export
	
	Result = Undefined;
	
	For Each Source IN Sources Do
		If Source.Source.Alias = TablePseudonym AND (TableType = Undefined Or (TypeOf(Source.Source) = TableType)) Then
			Result = Source;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function GetFunctionalOptionValue(Name) Export
	
	Return GetFunctionalOption(Name);
	
EndFunction // GetFunctionalOptionValue()

#Region OtherSettlements
	
// Moves accumulation register SettlementsWithOtherCounterparties.
//
Procedure ReflectSettlementsWithOtherCounterparties(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableSettlementsWithOtherCounterparties = AdditionalProperties.TableForRegisterRecords.TableSettlementsWithOtherCounterparties;
	
	If Cancel
	 OR TableSettlementsWithOtherCounterparties.Count() = 0 Then
		Return;
	EndIf;
	
	SettlementsWithOtherCounterpartiesRegistering = RegisterRecords.SettlementsWithOtherCounterparties;
	SettlementsWithOtherCounterpartiesRegistering.Write = True;
	SettlementsWithOtherCounterpartiesRegistering.Load(TableSettlementsWithOtherCounterparties);
	
EndProcedure

Function GetQueryTextExchangeRateDifferencesAccountingForOtherOperations(TempTablesManager, QueryNumber) Export
	
	QueryNumber = 2;
	
	QueryText =
	"SELECT
	|	AcccountsBalances.Company AS Company,
	|	AcccountsBalances.Counterparty AS Counterparty,
	|	AcccountsBalances.Contract AS Contract,
	|	AcccountsBalances.GLAccount AS GLAccount,
	|	SUM(AcccountsBalances.AmountBalance) AS AmountBalance,
	|	SUM(AcccountsBalances.AmountCurBalance) AS AmountCurBalance
	|INTO TemporaryTableBalancesAfterPosting
	|FROM
	|	(SELECT
	|		TemporaryTable.Company AS Company,
	|		TemporaryTable.Counterparty AS Counterparty,
	|		TemporaryTable.Contract AS Contract,
	|		TemporaryTable.GLAccount AS GLAccount,
	|		TemporaryTable.AmountForBalance AS AmountBalance,
	|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
	|	FROM
	|		TemporaryTableOtherSettlements AS TemporaryTable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableBalances.Company,
	|		TableBalances.Counterparty,
	|		TableBalances.Contract,
	|		TableBalances.GLAccount,
	|		ISNULL(TableBalances.AmountBalance, 0),
	|		ISNULL(TableBalances.AmountCurBalance, 0)
	|	FROM
	|		AccumulationRegister.SettlementsWithOtherCounterparties.Balance(
	|				&PointInTime,
	|				(Company, Counterparty, Contract, GLAccount) IN
	|					(SELECT DISTINCT
	|						TemporaryTableOtherSettlements.Company,
	|						TemporaryTableOtherSettlements.Counterparty,
	|						TemporaryTableOtherSettlements.Contract,
	|						TemporaryTableOtherSettlements.GLAccount
	|					FROM
	|						TemporaryTableOtherSettlements)) AS TableBalances
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentRegisterRecords.Company,
	|		DocumentRegisterRecords.Counterparty,
	|		DocumentRegisterRecords.Contract,
	|		DocumentRegisterRecords.GLAccount,
	|		CASE
	|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
	|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
	|		END,
	|		CASE
	|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
	|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
	|		END
	|	FROM
	|		AccumulationRegister.SettlementsWithOtherCounterparties AS DocumentRegisterRecords
	|	WHERE
	|		DocumentRegisterRecords.Recorder = &Ref
	|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AcccountsBalances
	|
	|GROUP BY
	|	AcccountsBalances.Company,
	|	AcccountsBalances.Counterparty,
	|	AcccountsBalances.Contract,
	|	AcccountsBalances.GLAccount
	|
	|INDEX BY
	|	Company,
	|	Counterparty,
	|	Contract,
	|	GLAccount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	1 AS LineNumber,
	|	&ControlPeriod AS Date,
	|	TableAccounts.Company AS Company,
	|	TableAccounts.Counterparty AS Counterparty,
	|	TableAccounts.Contract AS Contract,
	|	TableAccounts.GLAccount AS GLAccount,
	|	ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyRatesAccountsSliceLast.ExchangeRate * CurrencyRatesSliceLast.Multiplicity / (CurrencyRatesSliceLast.ExchangeRate * CurrencyRatesAccountsSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS ExchangeRateDifferenceAmount,
	|	TableAccounts.Currency AS Currency
	|INTO ExchangeDifferencesTemporaryTableOtherSettlements
	|FROM
	|	TemporaryTableOtherSettlements AS TableAccounts
	|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
	|		ON TableAccounts.Company = TableBalances.Company
	|			AND TableAccounts.Counterparty = TableBalances.Counterparty
	|			AND TableAccounts.Contract = TableBalances.Contract
	|			AND TableAccounts.GLAccount = TableBalances.GLAccount
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency IN
	|					(SELECT
	|						ConstantDefaultCurrency.Value
	|					FROM
	|						Constant.AccountingCurrency AS ConstantDefaultCurrency)) AS CurrencyRatesSliceLast
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
	|				&PointInTime,
	|				Currency IN
	|					(SELECT DISTINCT
	|						TemporaryTableOtherSettlements.Currency
	|					FROM
	|						TemporaryTableOtherSettlements)) AS CurrencyRatesAccountsSliceLast
	|		ON TableAccounts.Contract.SettlementsCurrency = CurrencyRatesAccountsSliceLast.Currency
	|WHERE
	|	(ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyRatesAccountsSliceLast.ExchangeRate * CurrencyRatesSliceLast.Multiplicity / (CurrencyRatesSliceLast.ExchangeRate * CurrencyRatesAccountsSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
	|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CurrencyRatesAccountsSliceLast.ExchangeRate * CurrencyRatesSliceLast.Multiplicity / (CurrencyRatesSliceLast.ExchangeRate * CurrencyRatesAccountsSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS Order,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Date AS Period,
	|	DocumentTable.RecordType AS RecordType,
	|	DocumentTable.Company AS Company,
	|	DocumentTable.Counterparty AS Counterparty,
	|	DocumentTable.Contract AS Contract,
	|	DocumentTable.GLAccount AS GLAccount,
	|	DocumentTable.Amount AS Amount,
	|	DocumentTable.AmountCur AS AmountCur,
	|	DocumentTable.Currency,
	|	DocumentTable.ContentOfAccountingRecord,
	|	DocumentTable.Comment
	|FROM
	|	TemporaryTableOtherSettlements AS DocumentTable
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	DocumentTable.LineNumber,
	|	DocumentTable.Date,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	DocumentTable.Company,
	|	DocumentTable.Counterparty,
	|	DocumentTable.Contract,
	|	DocumentTable.GLAccount,
	|	CASE
	|		WHEN DocumentTable.ExchangeRateDifferenceAmount > 0
	|			THEN DocumentTable.ExchangeRateDifferenceAmount
	|		ELSE -DocumentTable.ExchangeRateDifferenceAmount
	|	END,
	|	0,
	|	DocumentTable.Currency,
	|	&ExchangeRateDifference,
	|	""""
	|FROM
	|	ExchangeDifferencesTemporaryTableOtherSettlements AS DocumentTable
	|
	|ORDER BY
	|	Order,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryTableBalancesAfterPosting";
		
	Return QueryText;
	
EndFunction // GetQueryTextExchangeDifferenceAccountingForOtherOperations()

// Generates records of the LoanSettlements accumulation register.
//
Procedure ReflectLoanSettlements(AdditionalProperties, RegisterRecords, Cancel) Export
	
	TableLoanSettlements = AdditionalProperties.TableForRegisterRecords.TableLoanSettlements;
	
	If Cancel
	 OR TableLoanSettlements.Count() = 0 Then
		Return;
	EndIf;
	
	RecordsLoanSettlements = RegisterRecords.LoanSettlements;
	RecordsLoanSettlements.Write = True;
	RecordsLoanSettlements.Load(TableLoanSettlements);
	
EndProcedure

// Generates records of the LoanRepaymentSchedule information register.
//
Procedure RecordLoanRepaymentSchedule(AdditionalProperties, Records, Cancel) Export
	
	TableLoanRepaymentSchedule = AdditionalProperties.TableForRegisterRecords.TableLoanRepaymentSchedule;
	
	If Cancel
	 OR TableLoanRepaymentSchedule.Count() = 0 Then
		Return;
	EndIf;
	
	RecordsLoanRepaymentSchedule = Records.LoanRepaymentSchedule;
	RecordsLoanRepaymentSchedule.Write = True;
	RecordsLoanRepaymentSchedule.Load(TableLoanRepaymentSchedule);
	
EndProcedure

// Function returns query text to calculate exchange rate differences.
//
Function GetQueryTextExchangeRateDifferencesLoanSettlements(TemporaryTableManager, QueryNumber, IsBusinessUnit = False) Export
	
	CalculateExchangeRateDifferences = GetNeedToCalculateExchangeDifferences(TemporaryTableManager, "TemporaryTableLoanSettlements");
	
	If CalculateExchangeRateDifferences Then
		
		QueryNumber = 3;
		
		QueryText = 
		"SELECT
		|	SettlementsBalance.LoanKind AS LoanKind,
		|	SettlementsBalance.Counterparty AS Counterparty,
		|	SettlementsBalance.Company AS Company,
		|	SettlementsBalance.LoanContract AS LoanContract,
		|	SUM(SettlementsBalance.PrincipalDebtBalance) AS PrincipalDebtBalance,
		|	SUM(SettlementsBalance.PrincipalDebtCurBalance) AS PrincipalDebtCurBalance,
		|	SUM(SettlementsBalance.InterestBalance) AS InterestBalance,
		|	SUM(SettlementsBalance.InterestCurBalance) AS InterestCurBalance,
		|	SUM(SettlementsBalance.CommissionBalance) AS CommissionBalance,
		|	SUM(SettlementsBalance.CommissionCurBalance) AS CommissionCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.LoanKind AS LoanKind,
		|		TemporaryTable.Counterparty AS Counterparty,
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.LoanContract AS LoanContract,
		|		TemporaryTable.PrincipalDebtForBalance AS PrincipalDebtBalance,
		|		TemporaryTable.PrincipalDebtCurForBalance AS PrincipalDebtCurBalance,
		|		TemporaryTable.InterestForBalance AS InterestBalance,
		|		TemporaryTable.InterestCurForBalance AS InterestCurBalance,
		|		TemporaryTable.CommissionForBalance AS CommissionBalance,
		|		TemporaryTable.CommissionCurForBalance AS CommissionCurBalance
		|	FROM
		|		TemporaryTableLoanSettlements AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableBalance.LoanKind,
		|		TableBalance.Counterparty,
		|		TableBalance.Company,
		|		TableBalance.LoanContract,
		|		ISNULL(TableBalance.PrincipalDebtBalance, 0),
		|		ISNULL(TableBalance.PrincipalDebtCurBalance, 0),
		|		ISNULL(TableBalance.InterestBalance, 0),
		|		ISNULL(TableBalance.InterestCurBalance, 0),
		|		ISNULL(TableBalance.CommissionBalance, 0),
		|		ISNULL(TableBalance.CommissionCurBalance, 0)
		|	FROM
		|		AccumulationRegister.LoanSettlements.Balance(
		|				&PointInTime,
		|				(Company, Counterparty, LoanContract, LoanKind) IN
		|					(SELECT DISTINCT
		|						TemporaryTableLoanSettlements.Company,
		|						TemporaryTableLoanSettlements.Counterparty,
		|						TemporaryTableLoanSettlements.LoanContract,
		|						TemporaryTableLoanSettlements.LoanKind
		|					FROM
		|						TemporaryTableLoanSettlements)) AS TableBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRecords.LoanKind,
		|		DocumentRecords.Counterparty,
		|		DocumentRecords.Company,
		|		DocumentRecords.LoanContract,
		|		CASE
		|			WHEN DocumentRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRecords.PrincipalDebt, 0)
		|			ELSE ISNULL(DocumentRecords.PrincipalDebt, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRecords.PrincipalDebtCur, 0)
		|			ELSE ISNULL(DocumentRecords.PrincipalDebtCur, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRecords.Interest, 0)
		|			ELSE ISNULL(DocumentRecords.Interest, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRecords.InterestCur, 0)
		|			ELSE ISNULL(DocumentRecords.InterestCur, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRecords.Commission, 0)
		|			ELSE ISNULL(DocumentRecords.Commission, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRecords.CommissionCur, 0)
		|			ELSE ISNULL(DocumentRecords.CommissionCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.LoanSettlements AS DocumentRecords
		|	WHERE
		|		DocumentRecords.Recorder = &Ref
		|		AND DocumentRecords.Period <= &ControlPeriod) AS SettlementsBalance
		|
		|GROUP BY
		|	SettlementsBalance.Company,
		|	SettlementsBalance.Counterparty,
		|	SettlementsBalance.LoanKind,
		|	SettlementsBalance.LoanContract
		|
		|INDEX BY
		|	Company,
		|	Counterparty,
		|	LoanKind,
		|	LoanContract
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableSettlements.Company AS Company,
		|	TableSettlements.Counterparty AS Counterparty,
		|	TableSettlements.LoanKind AS LoanKind,
		|	TableSettlements.Currency AS Currency,
		|	CAST(TableSettlements.LoanContract AS Document.LoanContract) AS LoanContract,
		|	TableSettlements.GLAccount AS GLAccount,
		|	ISNULL(TableBalance.PrincipalDebtCurBalance, 0) * SettlementExchangeRatesLastSlice.ExchangeRate * AccountingExchangeRatesLastSlice.Multiplicity / (AccountingExchangeRatesLastSlice.ExchangeRate * SettlementExchangeRatesLastSlice.Multiplicity) - ISNULL(TableBalance.PrincipalDebtBalance, 0) AS ExchangeRateDifferenceAmountPrincipalDebt,
		|	ISNULL(TableBalance.InterestCurBalance, 0) * SettlementExchangeRatesLastSlice.ExchangeRate * AccountingExchangeRatesLastSlice.Multiplicity / (AccountingExchangeRatesLastSlice.ExchangeRate * SettlementExchangeRatesLastSlice.Multiplicity) - ISNULL(TableBalance.InterestBalance, 0) AS ExchangeRateDifferenceAmountInterest,
		|	ISNULL(TableBalance.CommissionCurBalance, 0) * SettlementExchangeRatesLastSlice.ExchangeRate * AccountingExchangeRatesLastSlice.Multiplicity / (AccountingExchangeRatesLastSlice.ExchangeRate * SettlementExchangeRatesLastSlice.Multiplicity) - ISNULL(TableBalance.CommissionBalance, 0) AS ExchangeRateDifferenceAmountCommission
		|INTO TemporaryTableOfExchangeRateDifferences
		|FROM
		|	TemporaryTableLoanSettlements AS TableSettlements
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalance
		|		ON TableSettlements.Company = TableBalance.Company
		|			AND TableSettlements.Counterparty = TableBalance.Counterparty
		|			AND TableSettlements.LoanKind = TableBalance.LoanKind
		|			AND TableSettlements.LoanContract = TableBalance.LoanContract
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency IN
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingExchangeRatesLastSlice
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency IN
		|					(SELECT DISTINCT
		|						TemporaryTableLoanSettlements.Currency
		|					FROM
		|						TemporaryTableLoanSettlements)) AS SettlementExchangeRatesLastSlice
		|		ON TableSettlements.LoanContract.SettlementsCurrency = SettlementExchangeRatesLastSlice.Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemporaryTableOfExchangeRateDifferences.LineNumber AS LineNumber,
		|	TemporaryTableOfExchangeRateDifferences.Date AS Date,
		|	TemporaryTableOfExchangeRateDifferences.Company AS Company,
		|	TemporaryTableOfExchangeRateDifferences.Counterparty AS Counterparty,
		|	TemporaryTableOfExchangeRateDifferences.LoanKind AS LoanKind,
		|	TemporaryTableOfExchangeRateDifferences.Currency AS Currency,
		|	TemporaryTableOfExchangeRateDifferences.LoanContract AS LoanContract,
		|	TemporaryTableOfExchangeRateDifferences.GLAccount AS GLAccount,
		|	TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountPrincipalDebt AS ExchangeRateDifferenceAmountPrincipalDebt,
		|	0 AS ExchangeRateDifferenceAmountInterest,
		|	0 AS ExchangeRateDifferenceAmountCommission,
		|	TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountPrincipalDebt AS ExchangeRateDifferenceAmount
		|INTO TemporaryTableExchangeRateDifferencesLoanSettlements
		|FROM
		|	TemporaryTableOfExchangeRateDifferences AS TemporaryTableOfExchangeRateDifferences
		|WHERE
		|	(TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountPrincipalDebt >= 0.005
		|			OR TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountPrincipalDebt <= -0.005)
		|
		|UNION ALL
		|
		|SELECT
		|	TemporaryTableOfExchangeRateDifferences.LineNumber,
		|	TemporaryTableOfExchangeRateDifferences.Date,
		|	TemporaryTableOfExchangeRateDifferences.Company,
		|	TemporaryTableOfExchangeRateDifferences.Counterparty,
		|	TemporaryTableOfExchangeRateDifferences.LoanKind,
		|	TemporaryTableOfExchangeRateDifferences.Currency,
		|	TemporaryTableOfExchangeRateDifferences.LoanContract,
		|	TemporaryTableOfExchangeRateDifferences.GLAccount,
		|	0,
		|	TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountInterest,
		|	0,
		|	TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountInterest
		|FROM
		|	TemporaryTableOfExchangeRateDifferences AS TemporaryTableOfExchangeRateDifferences
		|WHERE
		|	(TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountInterest >= 0.005
		|			OR TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountInterest <= -0.005)
		|
		|UNION ALL
		|
		|SELECT
		|	TemporaryTableOfExchangeRateDifferences.LineNumber,
		|	TemporaryTableOfExchangeRateDifferences.Date,
		|	TemporaryTableOfExchangeRateDifferences.Company,
		|	TemporaryTableOfExchangeRateDifferences.Counterparty,
		|	TemporaryTableOfExchangeRateDifferences.LoanKind,
		|	TemporaryTableOfExchangeRateDifferences.Currency,
		|	TemporaryTableOfExchangeRateDifferences.LoanContract,
		|	TemporaryTableOfExchangeRateDifferences.GLAccount,
		|	0,
		|	0,
		|	TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountCommission,
		|	TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountCommission
		|FROM
		|	TemporaryTableOfExchangeRateDifferences AS TemporaryTableOfExchangeRateDifferences
		|WHERE
		|	(TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountCommission >= 0.005
		|			OR TemporaryTableOfExchangeRateDifferences.ExchangeRateDifferenceAmountCommission <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order1,
		|	1 AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.LoanContract AS LoanContract,
		|	DocumentTable.LoanKind AS LoanKind,
		|	DocumentTable.Counterparty AS Counterparty,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.LoanContract.SettlementsCurrency AS Currency,
		|	DocumentTable.PrincipalCharged AS PrincipalCharged,
		|	DocumentTable.PrincipalChargedCur AS PrincipalChargedCur,
		|	DocumentTable.Interest AS Interest,
		|	DocumentTable.InterestCur AS InterestCur,
		|	DocumentTable.Commission AS Commission,
		|	DocumentTable.CommissionCur AS CommissionCur,
		|	DocumentTable.PrincipalCharged + DocumentTable.Interest + DocumentTable.Commission AS Amount,
		|	DocumentTable.PrincipalChargedCur + DocumentTable.InterestCur + DocumentTable.CommissionCur AS AmountCur,
		|	DocumentTable.GLAccount AS GLAccount,
		|	CAST(DocumentTable.ContentOfAccountingRecord AS STRING(100)) AS ContentOfAccountingRecord,
		|	DocumentTable.DeductedFromSalary AS DeductedFromSalary,
		|	"""" AS BusinessUnit
		|FROM
		|	TemporaryTableLoanSettlements AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	1,
		|	CASE
		|		WHEN DocumentTable.ExchangeRateDifferenceAmountPrincipalDebt > 0
		|				OR DocumentTable.ExchangeRateDifferenceAmountInterest > 0
		|				OR DocumentTable.ExchangeRateDifferenceAmountCommission > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.LoanContract,
		|	DocumentTable.LoanKind,
		|	DocumentTable.Counterparty,
		|	DocumentTable.Date,
		|	DocumentTable.Company,
		|	DocumentTable.LoanContract.SettlementsCurrency,
		|	CASE
		|		WHEN DocumentTable.ExchangeRateDifferenceAmountPrincipalDebt > 0
		|			THEN DocumentTable.ExchangeRateDifferenceAmountPrincipalDebt
		|		ELSE -DocumentTable.ExchangeRateDifferenceAmountPrincipalDebt
		|	END,
		|	0,
		|	CASE
		|		WHEN DocumentTable.ExchangeRateDifferenceAmountInterest > 0
		|			THEN DocumentTable.ExchangeRateDifferenceAmountInterest
		|		ELSE -DocumentTable.ExchangeRateDifferenceAmountInterest
		|	END,
		|	0,
		|	CASE
		|		WHEN DocumentTable.ExchangeRateDifferenceAmountCommission > 0
		|			THEN DocumentTable.ExchangeRateDifferenceAmountCommission
		|		ELSE -DocumentTable.ExchangeRateDifferenceAmountCommission
		|	END,
		|	0,
		|	CASE
		|		WHEN DocumentTable.ExchangeRateDifferenceAmountPrincipalDebt > 0
		|			THEN DocumentTable.ExchangeRateDifferenceAmountPrincipalDebt
		|		ELSE -DocumentTable.ExchangeRateDifferenceAmountPrincipalDebt
		|	END + CASE
		|		WHEN DocumentTable.ExchangeRateDifferenceAmountInterest > 0
		|			THEN DocumentTable.ExchangeRateDifferenceAmountInterest
		|		ELSE -DocumentTable.ExchangeRateDifferenceAmountInterest
		|	END + CASE
		|		WHEN DocumentTable.ExchangeRateDifferenceAmountCommission > 0
		|			THEN DocumentTable.ExchangeRateDifferenceAmountCommission
		|		ELSE -DocumentTable.ExchangeRateDifferenceAmountCommission
		|	END,
		|	0,
		|	DocumentTable.GLAccount,
		|	&ExchangeRateDifference,
		|	FALSE,
		|	UNDEFINED
		|FROM
		|	TemporaryTableExchangeRateDifferencesLoanSettlements AS DocumentTable
		|
		|ORDER BY
		|	Order1,
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
		
	Else
		
		QueryNumber = 1;
		
		QueryText = 
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableSettlements.Company AS Company,
		|	TableSettlements.Counterparty AS Counterparty,
		|	TableSettlements.LoanKind AS LoanKind,
		|	TableSettlements.LoanContract AS LoanContract,
		|	0 AS ExchangeRateDifferenceAmount,
		|	TableSettlements.Currency AS Currency,
		|	TableSettlements.GLAccount AS GLAccount
		|INTO TemporaryTableExchangeRateDifferencesLoanSettlements
		|FROM
		|	TemporaryTableLoanSettlements AS TableSettlements
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order1,
		|	1 AS LineNumber,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.LoanContract AS LoanContract,
		|	DocumentTable.LoanKind AS LoanKind,
		|	DocumentTable.Counterparty AS Counterparty,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.PrincipalDebt AS PrincipalDebt,
		|	DocumentTable.PrincipalDebtCur AS PrincipalDebtCur,
		|	DocumentTable.Interest AS Interest,
		|	DocumentTable.InterestCur AS InterestCur,
		|	DocumentTable.Commission AS Commission,
		|	DocumentTable.CommissionCur AS CommissionCur,
		|	DocumentTable.GLAccount AS GLAccount,
		|	DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord,
		|	DocumentTable.DeductedFromSalary AS DeductedFromSalary,
		|	DocumentTable.PrincipalDebtCur + DocumentTable.InterestCur + DocumentTable.CommissionCur AS AmountCur,
		|	DocumentTable.PrincipalDebt + DocumentTable.Interest + DocumentTable.Commission AS Amount,
		|	"""" AS BusinessArea
		|FROM
		|	TemporaryTableLoanSettlements AS DocumentTable
		|
		|ORDER BY
		|	Order1,
		|	LineNumber";
		
	EndIf;
	
	If IsBusinessUnit
		Then QueryText = StrReplace(QueryText, """"" AS BusinessUnit", "DocumentTable.BusinessUnit AS BusinessUnit");
	EndIf;
	
	Return QueryText;
	
EndFunction  //ReceiveQueryTextExchangeRateDifferencesLoanSettlements()

// Writes changes in the passed object of the reference type.
// For update counters.
//
// Parameters:
//   Object                            - Arbitrary - written object of the reference type. For example, CatalogObject.
//   RegisterOnNodesExchangePlans - Boolean       - enables registration on the exchange plans nodes when recording the object.
//   EnableBusinessLogic              - Boolean       - activates business logic when recording the object.
//
Procedure WriteObject(Val Object, Val RegisterOnNodesExchangePlans = Undefined, 
	Val EnableBusinessLogic = False) Export
	
	If RegisterOnNodesExchangePlans = Undefined AND Object.IsNew() Then
		RegisterOnNodesExchangePlans = True;
	Else
		RegisterOnNodesExchangePlans = False;
	EndIf;
	
	Object.DataExchange.Load = Not EnableBusinessLogic;
	If Not RegisterOnNodesExchangePlans Then
		Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		Object.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	Object.Write();
	
EndProcedure

// Function returns the formating date by language for printing.
// 1C - CHIENTN - 27-12-2018
Function GetFormatingDateByLanguageForPrinting(Date)  Export    
	UserLanguage = CurrentLanguage().LanguageCode;
	If UserLanguage = "vi" Then
		Return Format(Date, "DF='""Ngày"" dd ""tháng"" MM ""năm"" yyyy'");
	Else
		Return Format(Date, "DLF=DD");
	EndIf;
EndFunction // GetFormatingDateByLanguageForPrinting

Function MainWarehouse() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	StructuralUnits.Ref AS Warehouse,
	|	0 AS Order
	|FROM
	|	Catalog.StructuralUnits AS StructuralUnits
	|WHERE
	|	StructuralUnits.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT  TOP 1
	|	StructuralUnits.Ref,
	|	1
	|FROM
	|	Catalog.StructuralUnits AS StructuralUnits
	|WHERE
	|	StructuralUnits.Ref <> &Ref
	|	AND StructuralUnits.DeletionMark = FALSE
	|	AND StructuralUnits.StructuralUnitType = &StructuralUnitType
	|
	|ORDER BY
	|	Order";
	Query.SetParameter("Ref", Catalogs.StructuralUnits.MainWarehouse);
	Query.SetParameter("StructuralUnitType", Enums.StructuralUnitsTypes.Warehouse);
	Result = Query.Execute();
	Selection = Result.Select();
	
	Warehouse = Undefined;
	If Selection.Next() Then
		Warehouse = Selection.Warehouse;
	EndIf;
	
	Return Warehouse;
	
EndFunction

Function GetQueryTextExchangeRateDifferencesSettlementsWithOtherCounterparties(TempTablesManager, WithAdvanceOffset, QueryNumber) Export
	
	CalculateCurrencyDifference = GetNeedToCalculateExchangeRatesDifference(TempTablesManager, "TemporaryTableSettlementsWithOtherCounterparties");
	
	If Not CalculateCurrencyDifference Then
		
		QueryNumber = 1;
		
		QueryText =
		"SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.DocOrder AS DocOrder,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	0 AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterparties
		|FROM
		|	TemporaryTableSettlementsWithOtherCounterparties AS TableAccounts
		|WHERE
		|	FALSE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentTable.Date AS Period,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Counterparty AS Counterparty,
		|	DocumentTable.Contract AS Contract,
		|	DocumentTable.Document AS Document,
		|	DocumentTable.DocOrder AS DocOrder,
		|	DocumentTable.SettlementsType AS SettlementsType,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	DocumentTable.ContentOfAccountingRecord
		|FROM
		|	TemporaryTableSettlementsWithOtherCounterparties AS DocumentTable
		|
		|ORDER BY
		|	DocumentTable.ContentOfAccountingRecord,
		|	Document,
		|	DocOrder,
		|	RecordType";
	
	ElsIf WithAdvanceOffset Then
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	AccountsBalances.Company AS Company,
		|	AccountsBalances.Counterparty AS Counterparty,
		|	AccountsBalances.Contract AS Contract,
		|	AccountsBalances.Contract.SettlementsCurrency AS SettlementsCurrency,
		|	AccountsBalances.Document AS Document,
		|	AccountsBalances.DocOrder AS DocOrder,
		|	AccountsBalances.SettlementsType AS SettlementsType,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountVendorSettlements
		|		ELSE AccountsBalances.Counterparty.VendorAdvancesGLAccount
		|	END AS GLAccount,
		|	SUM(AccountsBalances.AmountBalance) AS AmountBalance,
		|	SUM(AccountsBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.Counterparty AS Counterparty,
		|		TemporaryTable.Contract AS Contract,
		|		TemporaryTable.Document AS Document,
		|		TemporaryTable.DocOrder AS DocOrder,
		|		TemporaryTable.SettlementsType AS SettlementsType,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableSettlementsWithOtherCounterparties AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.Counterparty,
		|		DocumentRegisterRecords.Contract,
		|		DocumentRegisterRecords.Document,
		|		DocumentRegisterRecords.DocOrder,
		|		DocumentRegisterRecords.SettlementsType,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.AccountsPayable AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AccountsBalances
		|
		|GROUP BY
		|	AccountsBalances.Company,
		|	AccountsBalances.Counterparty,
		|	AccountsBalances.Contract,
		|	AccountsBalances.Document,
		|	AccountsBalances.DocOrder,
		|	AccountsBalances.SettlementsType,
		|	AccountsBalances.Contract.SettlementsCurrency,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountVendorSettlements
		|		ELSE AccountsBalances.Counterparty.VendorAdvancesGLAccount
		|	END
		|
		|INDEX BY
		|	Company,
		|	Counterparty,
		|	Contract,
		|	SettlementsCurrency,
		|	Document,
		|	DocOrder,
		|	SettlementsType,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.DoOperationsByDocuments AS DoOperationsByDocuments,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.DocOrder AS DocOrder,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterpartiesPreliminary
		|FROM
		|	TemporaryTableSettlementsWithOtherCounterparties AS TableAccounts
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableAccounts.Company = TableBalances.Company
		|			AND TableAccounts.Counterparty = TableBalances.Counterparty
		|			AND TableAccounts.Contract = TableBalances.Contract
		|			AND TableAccounts.Document = TableBalances.Document
		|			AND TableAccounts.DocOrder = TableBalances.DocOrder
		|			AND TableAccounts.SettlementsType = TableBalances.SettlementsType
		|			AND TableAccounts.Currency = TableBalances.SettlementsCurrency
		|			AND TableAccounts.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency IN
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency IN
		|					(SELECT DISTINCT
		|						ВременнаяТаблицаРасчетыСПрочимиКонтрагентами.Contract.SettlementsCurrency
		|					FROM
		|						TemporaryTableSettlementsWithOtherCounterparties)) AS CalculationCurrencyRatesSliceLast
		|		ON TableAccounts.Currency = CalculationCurrencyRatesSliceLast.Currency
		|WHERE
		|	(TableBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) = 0)
		|	AND (ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecordTable.Period AS Period,
		|	RegisterRecordTable.RecordType AS RecordType,
		|	RegisterRecordTable.Company AS Company,
		|	RegisterRecordTable.Counterparty AS Counterparty,
		|	RegisterRecordTable.Contract AS Contract,
		|	RegisterRecordTable.Document AS Document,
		|	RegisterRecordTable.DocOrder AS DocOrder,
		|	RegisterRecordTable.SettlementsType AS SettlementsType,
		|	RegisterRecordTable.Currency AS Currency,
		|	SUM(RegisterRecordTable.Amount) AS Amount,
		|	SUM(RegisterRecordTable.AmountCur) AS AmountCur,
		|	RegisterRecordTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|FROM
		|	(SELECT
		|		DocumentTable.Date AS Period,
		|		DocumentTable.RecordType AS RecordType,
		|		DocumentTable.Company AS Company,
		|		DocumentTable.Counterparty AS Counterparty,
		|		DocumentTable.Contract AS Contract,
		|		DocumentTable.Document AS Document,
		|		DocumentTable.DocOrder AS DocOrder,
		|		DocumentTable.SettlementsType AS SettlementsType,
		|		DocumentTable.Currency AS Currency,
		|		DocumentTable.Amount AS Amount,
		|		DocumentTable.AmountCur AS AmountCur,
		|		DocumentTable.ContentOfAccountingRecord AS ContentOfAccountingRecord
		|	FROM
		|		TemporaryTableSettlementsWithOtherCounterparties AS DocumentTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		DocumentTable.Document,
		|		DocumentTable.DocOrder,
		|		DocumentTable.SettlementsType,
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&ExchangeDifference AS STRING(100))
		|	FROM
		|		TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterpartiesPreliminary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		DocumentTable.Document,
		|		DocumentTable.DocOrder,
		|		DocumentTable.SettlementsType,
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&AdvanceCredit AS STRING(100))
		|	FROM
		|		TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterpartiesPreliminary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Expense),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.DocOrder,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&AdvanceCredit AS STRING(100))
		|	FROM
		|		TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterpartiesPreliminary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		VALUE(AccumulationRecordType.Receipt),
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.DocOrder,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.AmountOfExchangeDifferences,
		|		0,
		|		CAST(&ExchangeDifference AS STRING(100))
		|	FROM
		|		TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterpartiesPreliminary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS RegisterRecordTable
		|
		|GROUP BY
		|	RegisterRecordTable.Period,
		|	RegisterRecordTable.Company,
		|	RegisterRecordTable.Counterparty,
		|	RegisterRecordTable.Contract,
		|	RegisterRecordTable.Document,
		|	RegisterRecordTable.DocOrder,
		|	RegisterRecordTable.SettlementsType,
		|	RegisterRecordTable.Currency,
		|	RegisterRecordTable.ContentOfAccountingRecord,
		|	RegisterRecordTable.RecordType
		|
		|HAVING
		|	(SUM(RegisterRecordTable.Amount) >= 0.005
		|		OR SUM(RegisterRecordTable.Amount) <= -0.005
		|		OR SUM(RegisterRecordTable.AmountCur) >= 0.005
		|		OR SUM(RegisterRecordTable.AmountCur) <= -0.005)
		|
		|ORDER BY
		|	ContentOfAccountingRecord,
		|	Document,
		|	DocOrder,
		|	RecordType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableCurrencyDifferences.Company AS Company,
		|	TableCurrencyDifferences.Counterparty AS Counterparty,
		|	TableCurrencyDifferences.DoOperationsByDocuments AS DoOperationsByDocuments,
		|	TableCurrencyDifferences.Contract AS Contract,
		|	TableCurrencyDifferences.Document AS Document,
		|	TableCurrencyDifferences.DocOrder AS DocOrder,
		|	TableCurrencyDifferences.SettlementsType AS SettlementsType,
		|	SUM(TableCurrencyDifferences.AmountOfExchangeDifferences) AS AmountOfExchangeDifferences,
		|	TableCurrencyDifferences.Currency AS Currency,
		|	TableCurrencyDifferences.GLAccount AS GLAccount
		|INTO TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterparties
		|FROM
		|	(SELECT
		|		DocumentTable.Date AS Date,
		|		DocumentTable.Company AS Company,
		|		DocumentTable.Counterparty AS Counterparty,
		|		DocumentTable.DoOperationsByDocuments AS DoOperationsByDocuments,
		|		DocumentTable.Contract AS Contract,
		|		DocumentTable.Document AS Document,
		|		DocumentTable.DocOrder AS DocOrder,
		|		DocumentTable.SettlementsType AS SettlementsType,
		|		DocumentTable.Currency AS Currency,
		|		DocumentTable.GLAccount AS GLAccount,
		|		DocumentTable.AmountOfExchangeDifferences AS AmountOfExchangeDifferences
		|	FROM
		|		TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterpartiesPreliminary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentTable.Date,
		|		DocumentTable.Company,
		|		DocumentTable.Counterparty,
		|		DocumentTable.DoOperationsByDocuments,
		|		DocumentTable.Contract,
		|		CASE
		|			WHEN DocumentTable.DoOperationsByDocuments
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		DocumentTable.DocOrder,
		|		VALUE(Enum.SettlementsTypes.Debt),
		|		DocumentTable.Currency,
		|		DocumentTable.Counterparty.GLAccountVendorSettlements,
		|		DocumentTable.AmountOfExchangeDifferences
		|	FROM
		|		TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterpartiesPreliminary AS DocumentTable
		|	WHERE
		|		DocumentTable.SettlementsType = VALUE(Enum.SettlementsTypes.Advance)) AS TableCurrencyDifferences
		|
		|GROUP BY
		|	TableCurrencyDifferences.Company,
		|	TableCurrencyDifferences.Counterparty,
		|	TableCurrencyDifferences.DoOperationsByDocuments,
		|	TableCurrencyDifferences.Contract,
		|	TableCurrencyDifferences.Document,
		|	TableCurrencyDifferences.DocOrder,
		|	TableCurrencyDifferences.SettlementsType,
		|	TableCurrencyDifferences.Currency,
		|	TableCurrencyDifferences.GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterpartiesPreliminary";
		
	Else
		
		QueryNumber = 2;
		
		QueryText =
		"SELECT
		|	AccountsBalances.Company AS Company,
		|	AccountsBalances.Counterparty AS Counterparty,
		|	AccountsBalances.Contract AS Contract,
		|	AccountsBalances.Contract.SettlementsCurrency AS SettlementsCurrency,
		|	AccountsBalances.Document AS Document,
		|	AccountsBalances.DocOrder AS DocOrder,
		|	AccountsBalances.SettlementsType AS SettlementsType,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountVendorSettlements
		|		ELSE AccountsBalances.Counterparty.VendorAdvancesGLAccount
		|	END AS GLAccount,
		|	SUM(AccountsBalances.AmountBalance) AS AmountBalance,
		|	SUM(AccountsBalances.AmountCurBalance) AS AmountCurBalance
		|INTO TemporaryTableBalancesAfterPosting
		|FROM
		|	(SELECT
		|		TemporaryTable.Company AS Company,
		|		TemporaryTable.Counterparty AS Counterparty,
		|		TemporaryTable.Contract AS Contract,
		|		TemporaryTable.Document AS Document,
		|		TemporaryTable.DocOrder AS DocOrder,
		|		TemporaryTable.SettlementsType AS SettlementsType,
		|		TemporaryTable.AmountForBalance AS AmountBalance,
		|		TemporaryTable.AmountCurForBalance AS AmountCurBalance
		|	FROM
		|		TemporaryTableSettlementsWithOtherCounterparties AS TemporaryTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentRegisterRecords.Company,
		|		DocumentRegisterRecords.Counterparty,
		|		DocumentRegisterRecords.Contract,
		|		DocumentRegisterRecords.Document,
		|		DocumentRegisterRecords.DocOrder,
		|		DocumentRegisterRecords.SettlementsType,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.Amount, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.Amount, 0)
		|		END,
		|		CASE
		|			WHEN DocumentRegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|			ELSE ISNULL(DocumentRegisterRecords.AmountCur, 0)
		|		END
		|	FROM
		|		AccumulationRegister.AccountsPayable AS DocumentRegisterRecords
		|	WHERE
		|		DocumentRegisterRecords.Recorder = &Ref
		|		AND DocumentRegisterRecords.Period <= &ControlPeriod) AS AccountsBalances
		|
		|GROUP BY
		|	AccountsBalances.Company,
		|	AccountsBalances.Counterparty,
		|	AccountsBalances.Contract,
		|	AccountsBalances.Document,
		|	AccountsBalances.DocOrder,
		|	AccountsBalances.SettlementsType,
		|	AccountsBalances.Contract.SettlementsCurrency,
		|	CASE
		|		WHEN AccountsBalances.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|			THEN AccountsBalances.Counterparty.GLAccountVendorSettlements
		|		ELSE AccountsBalances.Counterparty.VendorAdvancesGLAccount
		|	END
		|
		|INDEX BY
		|	Company,
		|	Counterparty,
		|	Contract,
		|	SettlementsCurrency,
		|	Document,
		|	DocOrder,
		|	SettlementsType,
		|	GLAccount
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	1 AS LineNumber,
		|	&ControlPeriod AS Date,
		|	TableAccounts.Company AS Company,
		|	TableAccounts.Counterparty AS Counterparty,
		|	TableAccounts.Contract AS Contract,
		|	TableAccounts.Document AS Document,
		|	TableAccounts.DocOrder AS DocOrder,
		|	TableAccounts.SettlementsType AS SettlementsType,
		|	ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) AS AmountOfExchangeDifferences,
		|	TableAccounts.Currency AS Currency,
		|	TableAccounts.GLAccount AS GLAccount
		|INTO TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterparties
		|FROM
		|	TemporaryTableSettlementsWithOtherCounterparties AS TableAccounts
		|		LEFT JOIN TemporaryTableBalancesAfterPosting AS TableBalances
		|		ON TableAccounts.Company = TableBalances.Company
		|			AND TableAccounts.Counterparty = TableBalances.Counterparty
		|			AND TableAccounts.Contract = TableBalances.Contract
		|			AND TableAccounts.Document = TableBalances.Document
		|			AND TableAccounts.DocOrder = TableBalances.DocOrder
		|			AND TableAccounts.SettlementsType = TableBalances.SettlementsType
		|			AND TableAccounts.Currency = TableBalances.SettlementsCurrency
		|			AND TableAccounts.GLAccount = TableBalances.GLAccount
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency IN
		|					(SELECT
		|						ConstantAccountingCurrency.Value
		|					FROM
		|						Constant.AccountingCurrency AS ConstantAccountingCurrency)) AS AccountingCurrencyRatesSliceLast
		|		ON (TRUE)
		|		LEFT JOIN InformationRegister.CurrencyRates.SliceLast(
		|				&PointInTime,
		|				Currency IN
		|					(SELECT DISTINCT
		|						ВременнаяТаблицаРасчетыСПрочимиКонтрагентами.Currency
		|					FROM
		|						TemporaryTableSettlementsWithOtherCounterparties)) AS CalculationCurrencyRatesSliceLast
		|		ON TableAccounts.Currency = CalculationCurrencyRatesSliceLast.Currency
		|WHERE
		|	TableAccounts.SettlementsType = VALUE(Enum.SettlementsTypes.Debt)
		|	AND (ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) >= 0.005
		|			OR ISNULL(TableBalances.AmountCurBalance, 0) * CalculationCurrencyRatesSliceLast.ExchangeRate * AccountingCurrencyRatesSliceLast.Multiplicity / (AccountingCurrencyRatesSliceLast.ExchangeRate * CalculationCurrencyRatesSliceLast.Multiplicity) - ISNULL(TableBalances.AmountBalance, 0) <= -0.005)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Order,
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.Date AS Period,
		|	DocumentTable.RecordType AS RecordType,
		|	DocumentTable.Company AS Company,
		|	DocumentTable.Counterparty AS Counterparty,
		|	DocumentTable.Contract AS Contract,
		|	DocumentTable.Document AS Document,
		|	DocumentTable.DocOrder AS DocOrder,
		|	DocumentTable.SettlementsType AS SettlementsType,
		|	DocumentTable.Amount AS Amount,
		|	DocumentTable.AmountCur AS AmountCur,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	DocumentTable.ContentOfAccountingRecord
		|FROM
		|	TemporaryTableSettlementsWithOtherCounterparties AS DocumentTable
		|
		|UNION ALL
		|
		|SELECT
		|	2,
		|	DocumentTable.LineNumber,
		|	DocumentTable.Date,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DocumentTable.Company,
		|	DocumentTable.Counterparty,
		|	DocumentTable.Contract,
		|	DocumentTable.Document,
		|	DocumentTable.DocOrder,
		|	DocumentTable.SettlementsType,
		|	CASE
		|		WHEN DocumentTable.AmountOfExchangeDifferences > 0
		|			THEN DocumentTable.AmountOfExchangeDifferences
		|		ELSE -DocumentTable.AmountOfExchangeDifferences
		|	END,
		|	0,
		|	DocumentTable.GLAccount,
		|	DocumentTable.Currency,
		|	&ExchangeDifference
		|FROM
		|	TemporaryTableCurrencyExchangeRateDifferencesSettlementsWithOtherCounterparties AS DocumentTable
		|
		|ORDER BY
		|	Order,
		|	LineNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTableBalancesAfterPosting";
		
	EndIf;
	
	Return QueryText;
	
EndFunction // ПолучитьТекстЗапросаКурсовыеРазницыРасчетыСПоставщиками()
#EndRegion

Function UseProductionStages() Export
	
	If GetFunctionalOption("UseSubsystemProduction") Then
		If GetFunctionalOption("UseProductionStages") Then
			Return True;
		Else
			Return False;
		EndIf;
	Else
		Return False;
	EndIf;
	
EndFunction

Функция RoundingTable() Экспорт
	
	Result = Новый ТаблицаЗначений;
	Result.Columns.Add("Method", Новый TypeDescription("EnumRef.RoundingMethods"));
	Result.Columns.Add("Value", Новый TypeDescription("Number", Новый КвалификаторыЧисла(15, 2)));
	Для каждого Value Из Metadata.Enums.RoundingMethods.EnumValues Цикл
		Str = Result.Add();
		Str.Method = Enums.RoundingMethods[Value.Name];
		Str.Value = Number(String(Str.Method));
	КонецЦикла;
	
	Return Result;
	
КонецФункции

// Функция - Ссылка на двоичные данные файла.
//
// Параметры:
//  ПрисоединенныйФайл - СправочникСсылка - ссылка на справочник с именем "*ПрисоединенныеФайлы".
//  ИдентификаторФормы - УникальныйИдентификатор - идентификатор формы, который
//                       используется при получении двоичных данных файла.
// 
// Возвращаемое значение:
//   - Строка - адрес во временном хранилище; 
//   - Неопределено, если не удалось получить данные.
//
Function RefToFileBinaryData(ПрисоединенныйФайл, ИдентификаторФормы) Экспорт
	
	УстановитьПривилегированныйРежим(Истина);
	Попытка
		
		//ДополнительныеПараметры = FileOperationsClientServer.ПараметрыДанныхФайла();
		//ДополнительныеПараметры.ИдентификаторФормы = ИдентификаторФормы;
		
		Возврат AttachedFiles.GetFileData(ПрисоединенныйФайл, ИдентификаторФормы).FileBinaryDataRef;
		
	Исключение
		Возврат Неопределено;
	КонецПопытки;
	
EndFunction // СсылкаНаДвоичныеДанныеФайла()

#Region Billing

// Проверяет, возможно ли проведение указанной позиции в рамках договора обслуживания.
//
// Parameters:
//  Contract						 - CatalogRef.CounterpartyContracts - Договор обслуживания, по которому производится продажа.
//  ServiceContractObject	 - CatalogRef.ProductsAndServices, ChartOfAccountsRef.Managerial - Объект договора обслуживания, который проверяется.
//  CHARACTERISTIC				 - CatalogRef.ProductsAndServicesCharacteristics - Характерситика проверяемой номенклатуры.
//                                 (по умолчанию = Неопределено)
// 
// Returns:
//   - Boolean
//
Function SoldProductsAndServicesByServiceContractAllowed(Contract, ServiceContractObject, CHARACTERISTIC = Undefined) Export
	
	If Not GetFunctionalOption("UseBilling") Then
		Return True;
	EndIf;
	
	If Not Contract.IsServiceContract Then
		Return True;
	EndIf;
	
	TariffPlan = Contract.ServiceContractTariffPlan;
	
	If TypeOf(ServiceContractObject) = Type("CatalogRef.ProductsAndServices") Then
		
		If CHARACTERISTIC = Undefined Then
			CHARACTERISTIC = Catalogs.ProductsAndServicesCharacteristics.EmptyRef();
		EndIf;
		Rows = TariffPlan.ProductsAndServicesAccounting.FindRows(
			New Structure("ProductsAndServices,CHARACTERISTIC", ServiceContractObject, CHARACTERISTIC)
		);
		
		UnplannedItemsProhibit = TariffPlan.UnplannedItemsProhibit;
		
	ElsIf TypeOf(ServiceContractObject) = Type("ChartOfAccountsRef.Managerial") Then
		
		Rows = TariffPlan.CostAccounting.FindRows(
			New Structure("CostsItem", ServiceContractObject)
		);
		
		UnplannedItemsProhibit = TariffPlan.UnplannedCostsProhibit;
		
	Else
		Return False;
	EndIf;
	
	If Rows.Count() <> 0 Then
		// Позиция явно запланирована к оказанию.
		Return True;
	EndIf;
	
	// Это незапланированная позиция.
	
	If UnplannedItemsProhibit Then
		// Установлен запрет на проведение незапланированных позиций.
		Return False;
	EndIf;
	
	// Запрет на проведение незапланированных позиций не установлен.
	Return True;
	
EndFunction

// Выполняет движения по регистру ВыполнениеДоговоровОбслуживания.
//
Procedure ReflectServiceContractExecution(AdditionalProperties, RegisterRecords, Cancel) Export
	
	If Not AdditionalProperties.TableForRegisterRecords.Property("TableServiceContractExecution") Then
		Return;
	EndIf;
	
	TableServiceContractExecution = AdditionalProperties.TableForRegisterRecords.TableServiceContractExecution;
	
	If Cancel Or TableServiceContractExecution.Count() = 0 Then
		Return
	EndIf;
	
	RegisterRecordsServiceContractsExecution = RegisterRecords.ServiceContractsExecution;
	RegisterRecordsServiceContractsExecution.Write = True;
	RegisterRecordsServiceContractsExecution.Load(TableServiceContractExecution);
	
EndProcedure

#EndRegion

#Region PrintManagement

// Процедура переопределяет отображение подменю "Печать" в формах
//
// Parameters:
//  FormGroupPrint	 - FormGroup	 - элемент формы, содержащий команды печати
//
Procedure SetPrintSubmenuDisplay(FormGroupPrint) Export
	
	FormGroupPrint.Type			= FormGroupType.Popup;
	FormGroupPrint.Representation	= ButtonRepresentation.Picture;
	FormGroupPrint.Picture		= PictureLib.Print;
	FormGroupPrint.ToolTip		= NStr("en='Печать с предварительным просмотром';ru='Печать с предварительным просмотром';vi='In với bản xem trước'");
	FormGroupPrint.Title		= NStr("en='Печать';ru='Печать';vi='In'");
	
EndProcedure

// Функция проверяет возможность выполнения команды печати в серверном контексте
//
// Parameters:
//  DetailsPrintCommands	 - ValueTableRow - See PrintManagement.СоздатьКоллекциюКомандПечати(); MessageTemplatesInternal.DefinePrintFormsList();
// 
// Returns:
//  Boolean - истина означает, что для команды печати определен вывод в табличный документ с использованием процедуры Печать() в модуле менеджера печати
//
Function CommandPrintsInServerContext(Val DetailsPrintCommands, ColumnCommandID = Undefined) Export
	
	If DetailsPrintCommands.Presentation = NStr("en='Настраиваемый комплект документов';ru='Настраиваемый комплект документов';vi='Bộ chứng từ có thể tùy chỉnh'") Then
		Return False;
	EndIf;
	
	If ColumnCommandID = Undefined Then
		ColumnCommandID = "ID";
	EndIf;
	
	ExceptionCommands = New Array;
	ExceptionCommands.Add("ContractForm");
	ExceptionCommands.Add("envelope");
	ExceptionCommands.Add("LabelsPrintingFromReceivedInventoryPosting");
	ExceptionCommands.Add("PrintPriceTagsFromReceivedInventoryPosting");
	ExceptionCommands.Add("LabelsPrintingFromGoodsMovement");
	ExceptionCommands.Add("PriceTagsPrintingFromGoodsMovement");
	ExceptionCommands.Add("LabelsPrintingFromSupplierInvoice");
	ExceptionCommands.Add("PriceTagsPrintingFromSupplierInvoice");
	ExceptionCommands.Add("PrintLabelsFromCustomerInvoice");
	ExceptionCommands.Add("PrintPriceTagsFromCustomerInvoice");
	ExceptionCommands.Add("LabelsPrintingFromCustomerOrder");
	ExceptionCommands.Add("PrintPriceTagsFromCustomerOrder");
	ExceptionCommands.Add("UniversalTransferDocument");
	ExceptionCommands.Add("UniversalTransferDocumentFacsimile");
	ExceptionCommands.Add("UniversalCorrectiveDocument");
	ExceptionCommands.Add("PrintLabelsFromInventoryAssembly");
	ExceptionCommands.Add("CN");
	
	Return ExceptionCommands.Find(DetailsPrintCommands[ColumnCommandID]) = Undefined;
	
EndFunction

#EndRegion

#Region EmailSendingProceduresAndFunctions

// Функция исплользуется для заполнения отправителей письма, как с печатными формами, так и без них.
// Функция возвращает ПодготовитьЭлектронныеАдресаПолучателей.
Function GetPreparedRecipientsEmailAddresses(ObjectsArray) Export
	
	Recipients = New ValueList;
	
	If TypeOf(ObjectsArray) = Type("Array") Or TypeOf(ObjectsArray) = Type("FixedArray") Then
		
		MetadataTypesContainingPartnersEmails = SmallBusinessContactInformationServer.GetTypesOfMetadataContainingAffiliateEmail();
		
		For Each ArrayObject In ObjectsArray Do
			
			If Not ValueIsFilled(ArrayObject) Then 
				
				Continue; 
				
			ElsIf TypeOf(ArrayObject) = Type("CatalogRef.Counterparties") Then 
				
				// Актуально для печати из справочника, например, прайс-лист из Справочники.Контрагенты
				StructureValuesToValuesList(Recipients, New Structure("Counterparty", ArrayObject));
				Continue;
				
			ElsIf TypeOf(ArrayObject) = Type("CatalogRef.CounterpartyContracts") Then
				
				StructureValuesToValuesList(Recipients, New Structure("Counterparty", ArrayObject.Owner));
				Continue;
				
			EndIf;
			
			ObjectMetadata = ArrayObject.Metadata();
			
			AttributesNamesContainedEmail = New Array;
			
			// Проверим все реквизиты переданного объекта
			For Each MetadataItem In ObjectMetadata.Attributes Do
				
				ObjectContainsEmail(MetadataItem, MetadataTypesContainingPartnersEmails, AttributesNamesContainedEmail);
				
			EndDo;
			
			If AttributesNamesContainedEmail.Count() > 0 Then
				
				StructureValuesToValuesList(
					Recipients,
					CommonUse.ObjectAttributesValues(ArrayObject, AttributesNamesContainedEmail)
					);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return SmallBusinessContactInformationServer.PrepareRecipientsEmailAddresses(Recipients, True);
	
EndFunction //ПолучитьПодготовленныеЭлектронныеАдресаПолучателей()

#EndRegion

Function GenerateBatchQueryTemplate() Export
	
	QueryText =
	Chars.LF +
	";
	|
	|////////////////////////////////////////////////////////////////////////////////"
	+ Chars.LF;
	
	Return QueryText;

	
EndFunction

// Function returns a flag showing that rate differences are required.
//
Function GetNeedToCalculateExchangeRatesDifference(TempTablesManager, PaymentsTemporaryTableName)
	
	CalculateCurrencyDifference = Constants.FunctionalCurrencyTransactionsAccounting.Get();
	
	If CalculateCurrencyDifference Then
		QueryText =
		"SELECT DISTINCT
		|	TableAccounts.Currency AS Currency
		|FROM
		|	%TemporaryTableSettlements% AS TableAccounts
		|WHERE
		|	TableAccounts.Currency <> &AccountingCurrency";
		QueryText = StrReplace(QueryText, "%TemporaryTableSettlements%", PaymentsTemporaryTableName);
		Query = New Query();
		Query.Text = QueryText;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("AccountingCurrency", Constants.AccountingCurrency.Get());
		CalculateCurrencyDifference = Not Query.Execute().IsEmpty();
	EndIf;
	
	If CalculateCurrencyDifference Then
		ExchangeRateDifferencesCalculationFrequency = Constants.ExchangeRateDifferencesCalculationFrequency.Get();
		If ExchangeRateDifferencesCalculationFrequency = Enums.ExchangeRateDifferencesCalculationFrequency.DuringOpertionExecution Then
			CalculateCurrencyDifference = True;
		Else
			CalculateCurrencyDifference = False;
		EndIf;
	EndIf;
	
	Return CalculateCurrencyDifference;
	
EndFunction // ПолучитьНеобходимостьРасчетаКурсовыхРазниц()

Procedure GenerateTableInventoryByCCD(DocumentRef, StructureAdditionalProperties, Expense = False) Export
	
	Query = New Query;
	Query.TempTablesManager = StructureAdditionalProperties.ForPosting.StructureTemporaryTables.TempTablesManager;
	Query.SetParameter("Expense", Expense);
	
	Query.Text =
	"SELECT
	|	MIN(TemporaryTableInventory.LineNumber) AS LineNumber,
	|	CASE
	|		WHEN &Expense
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	TemporaryTableInventory.Period AS Period,
	|	TemporaryTableInventory.Company AS Company,
	|	TemporaryTableInventory.ProductsAndServices AS ProductsAndServices,
	|	TemporaryTableInventory.Characteristic AS Characteristic,
	|	TemporaryTableInventory.Batch AS Batch,
	|	TemporaryTableInventory.CCDNo AS CCDNo,
	|	TemporaryTableInventory.CountryOfOrigin AS CountryOfOrigin,
	|	SUM(TemporaryTableInventory.Quantity) AS Quantity
	|FROM
	|	TemporaryTableInventory AS TemporaryTableInventory
	|WHERE
	|	TemporaryTableInventory.CountryOfOrigin <> VALUE(Catalog.WorldCountries.Russia)
	|	AND TemporaryTableInventory.CountryOfOrigin <> VALUE(Catalog.WorldCountries.EmptyRef)
	|	AND TemporaryTableInventory.CCDNo <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|
	|GROUP BY
	|	TemporaryTableInventory.Period,
	|	TemporaryTableInventory.Company,
	|	TemporaryTableInventory.ProductsAndServices,
	|	TemporaryTableInventory.Characteristic,
	|	TemporaryTableInventory.Batch,
	|	TemporaryTableInventory.CCDNo,
	|	TemporaryTableInventory.CountryOfOrigin";
	
	QueryResult = Query.Execute();
	
	StructureAdditionalProperties.TableForRegisterRecords.Insert("TableInventoryByCCD", QueryResult.Unload());
	
EndProcedure

