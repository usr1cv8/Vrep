#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

// Function returns the list of the "key" attributes names.
//
Function GetObjectAttributesBeingLocked() Export
	
	Result = New Array;
	Result.Add("ProductsAndServicesType");
	
	Return Result;
	
EndFunction // GetLockedObjectAttributes()

// Returns the list of
// attributes allowed to be changed with the help of the group change data processor.
//
Function EditedAttributesInGroupDataProcessing() Export
	
	EditableAttributes = New Array;
	
	EditableAttributes.Add("ProductsAndServicesType");
	EditableAttributes.Add("EstimationMethod");
	EditableAttributes.Add("VATRate");
	EditableAttributes.Add("BusinessActivity");
	EditableAttributes.Add("Warehouse");
	EditableAttributes.Add("Cell");
	EditableAttributes.Add("InventoryGLAccount");
	EditableAttributes.Add("ExpensesGLAccount");
	EditableAttributes.Add("ProductsAndServicesCategory");
	EditableAttributes.Add("PriceGroup");
	EditableAttributes.Add("CountryOfOrigin");
	EditableAttributes.Add("ReplenishmentMethod");
	EditableAttributes.Add("ReplenishmentDeadline");
	EditableAttributes.Add("Vendor");

	
	Return EditableAttributes;
	
EndFunction

// Returns the basic sale price for the specified items by the specified price kind.
//
// Products and services (Catalog.ProductsAndServices) - products and services which price shall be calculated (obligatory for filling);
// PriceKind (Catalog.PriceKinds or Undefined) - If Undefined, we calculate the basic price kind using Catalogs.PriceKinds.GetBasicSalePriceKind() method;
//
Function GetMainSalePrice(PriceKind, ProductsAndServices, MeasurementUnit = Undefined) Export
	
	If Not ValueIsFilled(ProductsAndServices) 
		OR Not AccessRight("Read", Metadata.InformationRegisters.ProductsAndServicesPrices) Then
		
		Return 0;
		
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	ProductsAndServicesPricesSliceLast.Price AS MainSalePrice
	|FROM
	|	InformationRegister.ProductsAndServicesPrices.SliceLast(
	|			,
	|			PriceKind = &PriceKind
	|				AND ProductsAndServices = &ProductsAndServices
	|				AND Characteristic = VALUE(Catalog.ProductsAndServicesCharacteristics.EmptyRef)
	|				AND Actuality
	|				AND &ParameterMeasurementUnit) AS ProductsAndServicesPricesSliceLast");
	
	Query.SetParameter("PriceKind", 
		?(ValueIsFilled(PriceKind), PriceKind, Catalogs.PriceKinds.GetMainKindOfSalePrices())
		);
	
	Query.SetParameter("ProductsAndServices", 
		ProductsAndServices
		);
		
	If ValueIsFilled(MeasurementUnit) Then
		
		Query.Text = StrReplace(Query.Text, "&ParameterMeasurementUnit", "MeasurementUnit = &MeasurementUnit");
		Query.SetParameter("MeasurementUnit", MeasurementUnit);
		
	Else
		
		Query.Text = StrReplace(Query.Text, "&ParameterMeasurementUnit", "TRUE");
		
	EndIf;
	
	Selection = Query.Execute().Select();
	
	Return ?(Selection.Next(), Selection.MainSalePrice, 0);
	
EndFunction //GetBasicSalePrice()

#EndRegion

#Region DataLoadFromFile

// Sets data import from file parameters
//
// Parameters:
//     Parameters - Structure - Parameters list. Fields: 
//         * Title - String - Window title 
//         * MandatoryColumns - Array - List of columns names mandatory for filling
//         * DataTypeColumns - Map, Key - Column name, Value - Data type description 
//
Procedure DefineDataLoadFromFileParameters(Parameters) Export
	
	Parameters.Title = "ProductsAndServices";
	
	TypeDescriptionBarcode =  New TypeDescription("String",,,, New StringQualifiers(13));
	SKUTypeDescription =  New TypeDescription("String",,,, New StringQualifiers(25));
	TypeDescriptionName =  New TypeDescription("String",,,, New StringQualifiers(100));
	Parameters.DataTypeColumns.Insert("Barcode", TypeDescriptionBarcode);
	Parameters.DataTypeColumns.Insert("Description", TypeDescriptionName);

EndProcedure

// Matches imported data to data in IB.
//
// Parameters:
//   ExportableData - ValueTable - values table with the imported data:
//     * MatchedObject   - CatalogRef - Ref to mapped object. Filled in inside the procedure
//     * <other columns> - Arbitrary  - Columns content corresponds to the "LoadFromFile" layout
//
Procedure MapImportedDataFromFile(ExportableData) Export
	
	Query = New Query;
	Query.Text = "SELECT
	               |	ExportableData.Barcode AS Barcode,
	               |	ExportableData.Description AS Description,
	               |	ExportableData.SKU AS SKU,
	               |	ExportableData.ID AS ID
	               |INTO ExportableData
	               |FROM
	               |	&ExportableData AS ExportableData
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	ProductsAndServicesBarcodes.Barcode AS Barcode,
	               |	ProductsAndServicesBarcodes.ProductsAndServices.Ref AS ProductsAndServicesRef,
	               |	ExportableData.ID AS ID
	               |INTO ProductsAndServicesByBarcodes
	               |FROM
	               |	ExportableData AS ExportableData
	               |		LEFT JOIN InformationRegister.ProductsAndServicesBarcodes AS ProductsAndServicesBarcodes
	               |		ON (ProductsAndServicesBarcodes.Barcode LIKE ExportableData.Barcode)
	               |WHERE
	               |	Not ProductsAndServicesBarcodes.ProductsAndServices.Ref IS NULL 
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	ProductsAndServices.Ref AS ProductsAndServicesRef,
	               |	ExportableData.ID AS ID
	               |INTO ProductsAndServicesSKU
	               |FROM
	               |	ExportableData AS ExportableData
	               |		LEFT JOIN Catalog.ProductsAndServices AS ProductsAndServices
	               |			LEFT JOIN ProductsAndServicesByBarcodes AS ProductsAndServicesByBarcodes
	               |			ON (NOT ProductsAndServicesByBarcodes.ProductsAndServicesRef = ProductsAndServices.Ref)
	               |		ON (ProductsAndServices.SKU LIKE ExportableData.SKU)
	               |			AND ((CAST(ProductsAndServices.SKU AS String(25))) <> """")
	               |			AND (NOT ProductsAndServices.SKU IS NULL )
	               |WHERE
	               |	Not ProductsAndServices.Ref IS NULL 
	               |
	               |GROUP BY
	               |	ProductsAndServices.Ref,
	               |	ExportableData.ID
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	ProductsAndServices.Ref AS Ref,
	               |	ExportableData.ID AS ID,
	               |	ProductsAndServices.ProductsAndServicesType AS ProductsAndServicesType
	               |FROM
	               |	ExportableData AS ExportableData
	               |		LEFT JOIN Catalog.ProductsAndServices AS ProductsAndServices
	               |			LEFT JOIN ProductsAndServicesByBarcodes AS ProductsAndServicesByBarcodes
	               |			ON (NOT ProductsAndServicesByBarcodes.ProductsAndServicesRef = ProductsAndServices.Ref)
	               |			LEFT JOIN ProductsAndServicesSKU AS ProductsAndServicesSKU
	               |			ON (NOT ProductsAndServicesSKU.ProductsAndServicesRef = ProductsAndServices.Ref)
	               |		ON (ProductsAndServices.Description LIKE ExportableData.Description)
	               |WHERE
	               |	Not ProductsAndServices.Ref IS NULL 
	               |
	               |GROUP BY
	               |	ProductsAndServices.Ref,
	               |	ExportableData.ID
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	ProductsAndServicesByBarcodes.ProductsAndServicesRef,
	               |	ProductsAndServicesByBarcodes.ID,
	               |	ProductsAndServicesByBarcodes.ProductsAndServicesRef.ProductsAndServicesType AS ProductsAndServicesType
	               |FROM
	               |	ProductsAndServicesByBarcodes AS ProductsAndServicesByBarcodes
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	ProductsAndServicesSKU.ProductsAndServicesRef,
	               |	ProductsAndServicesSKU.ID,
	               |	ProductsAndServicesSKU.ProductsAndServicesRef.ProductsAndServicesType AS ProductsAndServicesType
	               |FROM
	               |	ProductsAndServicesSKU AS ProductsAndServicesSKU";
	 
	Query.SetParameter("ExportableData", ExportableData);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Filter = New Structure("ID", SelectionDetailRecords.ID);
		FoundStrings = ExportableData.FindRows(Filter);
		If FoundStrings.Count() > 0 Then
			For IndexOf = 0 To FoundStrings.Count() -1 Do
				If ValueIsFilled(FoundStrings[IndexOf].ProductsAndServicesType) Then 
					ProductsAndServicesType = Undefined;
					For Each ProductsAndServicesTypeMetadata IN Enums.ProductsAndServicesTypes.EmptyRef().Metadata().EnumValues Do
						If ProductsAndServicesTypeMetadata.Name = FoundStrings[IndexOf].ProductsAndServicesType Then
							ProductsAndServicesType = Enums.ProductsAndServicesTypes[ProductsAndServicesTypeMetadata.Name];
							Break;
						EndIf;
					EndDo;
					
					If ProductsAndServicesType <> Undefined AND SelectionDetailRecords.ProductsAndServicesType = ProductsAndServicesType Then
						FoundStrings[IndexOf].MappingObject = SelectionDetailRecords.Ref;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Function ValueCatalog(CatalogName, ImportedValue, DefaultValue = Undefined)
	
	Result = ?(ValueIsFilled(ImportedValue), 
		Catalogs[CatalogName].FindByDescription(ImportedValue), DefaultValue);
	If Not ValueIsFilled(Result) Then
		Return DefaultValue;
	EndIf;
	
	Return Result;

EndFunction

Function EnumValue(EnumerationName, ImportedValue, DefaultValue = Undefined)
	
	For Each EnumsVariant IN Enums[EnumerationName] Do
		If String(EnumsVariant) = ImportedValue Then
			Return EnumsVariant;
		EndIf;
	EndDo;
	
	Result = Metadata.Enums[EnumerationName].EnumValues.Find(ImportedValue);
	If Result <> Undefined Then
		Return Enums[EnumerationName][Result.Name];
	EndIf;
	
	Return DefaultValue;

EndFunction

Function ValueAccount(ImportedValue, DefaultValue)
	
	If ValueIsFilled(ImportedValue) Then
		Result = ChartsOfAccounts.Managerial.FindByCode(ImportedValue);
		If Not ValueIsFilled(Result) Then
			Result = ChartsOfAccounts.Managerial.FindByDescription(ImportedValue);
		EndIf;
	Else
		Return DefaultValue;
	EndIf;
	
	If ValueIsFilled(Result) Then
		Return Result;
	EndIf;
	
	Return DefaultValue;
	
EndFunction

// Data import from the file
//
// Parameters:
//   ExportableData - ValuesTable with columns:
//     * MatchedObject       - CatalogRef - Ref to the matched object
//     * StringMatchResult   - String     - Update status, possible options: Created, Updated, Skipped
//     * ErrorDescription    - String     - decryption of data import error
//     * Identifier          - Number     - String unique number 
//     * <other columns>     - Arbitrary  - Imported file strings according to the layout
// ImportParameters    - Structure    - Import parameters 
//     * CreateNew     - Boolean      - It is required to create catalog new items
//     * ZeroExisting  - Boolean      - Whether it is required to update catalog items
// Denial              - Boolean       - Cancel import
Procedure LoadFromFile(ExportableData, ImportParameters, Cancel) Export
	
	SpecificationIsImported = ?(ExportableData.Columns.Find("Specification") <> Undefined, True, False);
	ReplenishmentMethodIsImported = ?(ExportableData.Columns.Find("ReplenishmentMethod")<> Undefined, True, False);
	BusinessActivityIsImported = ?(ExportableData.Columns.Find("BusinessActivity")<> Undefined, True, False);
	
	For Each TableRow IN ExportableData Do
		Try
			If Not ValueIsFilled(TableRow.MappingObject) Then
				If ImportParameters.CreateNew Then 
					BeginTransaction();
					CatalogItem = Catalogs.ProductsAndServices.CreateItem();
					
					CatalogItem.Fill(TableRow);
					TableRow.MappingObject = CatalogItem;
					TableRow.RowMatchResult = "Created";
				Else
					TableRow.RowMatchResult = "Skipped";
					Continue;
				EndIf;
			Else
				If Not ImportParameters.UpdateExisting Then 
					TableRow.RowMatchResult = "Skipped";
					Continue;
				EndIf;
				
				BeginTransaction();
				Block = New DataLock;
				LockItem = Block.Add("Catalog.ProductsAndServices");
				LockItem.SetValue("Ref", TableRow.MappingObject);
				
				CatalogItem = TableRow.MappingObject.GetObject();
				
				TableRow.RowMatchResult = "Updated";
				
				If CatalogItem = Undefined Then
					MessageText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='Products and services with name ""%1"" do not exist.';ru='Номенклатура с наименованием ""%1"" не существует.';vi='Mặt hàng với tên gọi ""%1"" không tồn tại.'"), TableRow.Description);
					Raise MessageText;
				EndIf;
			EndIf;
			
			CatalogItem.Description = TableRow.Description;
			
			If ValueIsFilled(TableRow.CountryOfOrigin) Then
				CatalogItem.CountryOfOrigin = Catalogs.WorldCountries.FindByDescription(TableRow.CountryOfOrigin);
			EndIf;
			
			Parent = Catalogs.ProductsAndServices.FindByDescription(TableRow.Parent, True);
			If Not IsBlankString(TableRow.Parent) Then
				If Parent = Undefined
					OR Parent.IsFolder = False
					OR Parent.IsEmpty() = True Then
					Parent = Catalogs.ProductsAndServices.CreateFolder();
					Parent.Description = TableRow.Parent;
					Parent.Write();
				EndIf;
				
				CatalogItem.Parent = Parent.Ref;
			EndIf;
			
			// functional option
			If ReplenishmentMethodIsImported Then
				CatalogItem.ReplenishmentMethod = EnumValue("InventoryReplenishmentMethods", TableRow.ReplenishmentMethod, 
					Enums.InventoryReplenishmentMethods.Purchase);
				EndIf;
				
			If BusinessActivityIsImported Then
				CatalogItem.BusinessActivity =  ValueCatalog("BusinessActivities", TableRow.BusinessActivity, Catalogs.BusinessActivities.MainActivity);
			EndIf;
			
			CatalogItem.Warehouse               = ValueCatalog("StructuralUnits", TableRow.Warehouse, Catalogs.StructuralUnits.MainWarehouse);
			CatalogItem.PriceGroup        = ValueCatalog("PriceGroups", TableRow.PriceGroup, Catalogs.PriceGroups.EmptyRef());
			CatalogItem.ProductsAndServicesType      = EnumValue("ProductsAndServicesTypes", TableRow.ProductsAndServicesType);
			CatalogItem.VATRate            = ?(Constants.FunctionalOptionUseVAT.Get(),ValueCatalog("VATRates", TableRow.VATRate, Catalogs.Companies.MainCompany.DefaultVATRate),Catalogs.Companies.MainCompany.DefaultVATRate);
			CatalogItem.Vendor            = ValueCatalog("Counterparties", TableRow.Vendor);
			CatalogItem.ProductsAndServicesCategory = ValueCatalog("ProductsAndServicesCategories", TableRow.ProductsAndServicesCategory, Catalogs.ProductsAndServicesCategories.WithoutCategory);
			CatalogItem.EstimationMethod          = EnumValue("InventoryValuationMethods", TableRow.EstimationMethod,  Enums.InventoryValuationMethods.ByAverage);
			CatalogItem.DescriptionFull   = ?(ValueIsFilled(TableRow.DescriptionFull), TableRow.DescriptionFull, TableRow.Description);
			
			// Unit of measure
			MeasurementUnit = ValueCatalog("UOMClassifier", TableRow.MeasurementUnit, Undefined);
			If Not ValueIsFilled(MeasurementUnit) Then
				MeasurementUnit = Catalogs.UOM.FindByDescription(TableRow.MeasurementUnit, False, , CatalogItem.Ref);
				If Not ValueIsFilled(MeasurementUnit) Then
					MeasurementUnit = Catalogs.UOMClassifier.pcs
				EndIf;
			EndIf;
			CatalogItem.MeasurementUnit = MeasurementUnit;
			
			CatalogItem.SKU = TableRow.SKU;
			CatalogItem.Comment = TableRow.Definition;
			
			CatalogItem.InventoryGLAccount = ValueAccount(TableRow.InventoryGLAccount, ChartsOfAccounts.Managerial.RawMaterialsAndMaterials);
			CatalogItem.ExpensesGLAccount =  ValueAccount(TableRow.ExpensesGLAccount, ChartsOfAccounts.Managerial.IndirectExpenses);
			
			If CatalogItem.CheckFilling() Then 
				CatalogItem.Write();
				TableRow.MappingObject = CatalogItem.Ref;
				
				// Add bar code
				If ValueIsFilled(TableRow.Barcode) Then
					ProductsAndServicesBarcode = InformationRegisters.ProductsAndServicesBarcodes.CreateRecordManager();
					ProductsAndServicesBarcode.Barcode = TableRow.Barcode;
					ProductsAndServicesBarcode.Period = CurrentDate();
					ProductsAndServicesBarcode.ProductsAndServices = CatalogItem.Ref;
					ProductsAndServicesBarcode.Write();
				EndIf;
				
				CommitTransaction();
				Continue;
			Else
				RollbackTransaction();
				TableRow.RowMatchResult = "Skipped";
				
				UserMessages = GetUserMessages(True);
				If UserMessages.Count()>0 Then 
					MessagesText = "";
					For Each UserMessage IN UserMessages Do
						MessagesText  = MessagesText + UserMessage.Text + Chars.LF;
					EndDo;
					TableRow.ErrorDescription = MessagesText;
				EndIf;
			EndIf;
			
		Except
			Cause = BriefErrorDescription(ErrorInfo());
			RollbackTransaction();
			TableRow.RowMatchResult = "Skipped";
			TableRow.ErrorDescription = "Unable to write as the data is incorrect.";
		EndTry;
	EndDo;
EndProcedure

#EndRegion

#Region PrintInterface

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see the fields content in the PrintManagement.CreatePrintCommandsCollection function
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

#EndRegion

#EndIf