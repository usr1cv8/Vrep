#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ServiceProceduresAndFunctions

// Returns query text for printing price list (price group)
//
Function GetQueryTextForPrintingPriceListPriceGroup()
	
	Return 
	"SELECT
	|	CASE
	|		WHEN &OutputCode = VALUE(Enum.YesNo.Yes)
	|			THEN ProductsAndServicesPricesSliceLast.ProductsAndServices.Code
	|		ELSE ProductsAndServicesPricesSliceLast.ProductsAndServices.SKU
	|	END AS SKUCode,
	|	CASE
	|		WHEN &OutputFullDescr = VALUE(Enum.YesNo.Yes)
	|			THEN ProductsAndServicesPricesSliceLast.ProductsAndServices.DescriptionFull
	|		ELSE ProductsAndServicesPricesSliceLast.ProductsAndServices.Description
	|	END AS PresentationOfProductsAndServices,
	|	ProductsAndServicesPricesSliceLast.ProductsAndServices AS ProductsAndServices,
	|	ProductsAndServicesPricesSliceLast.Characteristic AS Characteristic,
	|	ProductsAndServicesPricesSliceLast.MeasurementUnit AS MeasurementUnit,
	|	ProductsAndServicesPricesSliceLast.Price AS Price,
	|	ProductsAndServicesPricesSliceLast.ProductsAndServices.PriceGroup AS PriceGroup
	|FROM
	|	InformationRegister.ProductsAndServicesPrices.SliceLast(
	|			&Period,
	|			Actuality
	|				AND PriceKind = &PriceKind) AS ProductsAndServicesPricesSliceLast
	|
	|ORDER BY
	|	ProductsAndServicesPricesSliceLast.ProductsAndServices.Description,
	|	Characteristic,
	|	SKUCode
	|TOTALS BY
	|	PriceGroup";
	
EndFunction // GetQueryTextForPriceListPrinting()

// Returns query text for printing price list (products and services hierarchy)
//
Function GetQueryTextForPrintingPriceListProductsAndServicesHierarchy()
	
	Return 
	"SELECT
	|	CatalogProductsAndServices.Ref AS ProductsAndServices,
	|	CASE
	|		WHEN &OutputCode = VALUE(Enum.YesNo.Yes)
	|			THEN CatalogProductsAndServices.Code
	|		ELSE CatalogProductsAndServices.SKU
	|	END AS SKUCode,
	|	CASE
	|		WHEN &OutputFullDescr = VALUE(Enum.YesNo.Yes)
	|			THEN CatalogProductsAndServices.DescriptionFull
	|		ELSE CatalogProductsAndServices.Description
	|	END AS PresentationOfProductsAndServices,
	|	CatalogProductsAndServices.Parent AS Parent,
	|	CatalogProductsAndServices.IsFolder AS IsFolder,
	|	ProductsAndServicesPricesSliceLast.Characteristic AS Characteristic,
	|	ProductsAndServicesPricesSliceLast.MeasurementUnit AS MeasurementUnit,
	|	ProductsAndServicesPricesSliceLast.Price AS Price
	|FROM
	|	Catalog.ProductsAndServices AS CatalogProductsAndServices
	|		Full JOIN InformationRegister.ProductsAndServicesPrices.SliceLast(
	|				&Period,
	|				Actuality
	|					AND PriceKind = &PriceKind) AS ProductsAndServicesPricesSliceLast
	|		ON CatalogProductsAndServices.Ref = ProductsAndServicesPricesSliceLast.ProductsAndServices
	|
	|ORDER BY
	|	CatalogProductsAndServices.Ref HIERARCHY,
	|	ProductsAndServicesPricesSliceLast.ProductsAndServices.Description,
	|	Characteristic,
	|	SKUCode";
	
EndFunction // GetQueryTextForPriceListPrinting()

// Returns the list of
// attributes allowed to be changed with the help of the group change data processor.
//
Function EditedAttributesInGroupDataProcessing() Export
	
	EditableAttributes = New Array;
	
	EditableAttributes.Add("AccessGroup");
	EditableAttributes.Add("CreationDate");
	EditableAttributes.Add("Customer");
	EditableAttributes.Add("Supplier");
	EditableAttributes.Add("OtherRelationship");
	EditableAttributes.Add("Responsible");
	EditableAttributes.Add("CustomerAcquisitionChannel");
	EditableAttributes.Add("GLAccountCustomerSettlements");
	EditableAttributes.Add("CustomerAdvancesGLAccount");
	EditableAttributes.Add("GLAccountVendorSettlements");
	EditableAttributes.Add("VendorAdvancesGLAccount");
	
	Return EditableAttributes;
	
EndFunction

// Function receives selling price main kind from the user settings.
//
Function GetMainKindOfSalePrices() Export
	
	PriceKindSales = SmallBusinessReUse.GetValueByDefaultUser(UsersClientServer.AuthorizedUser(), "MainPriceKindSales");
	
	Return ?(ValueIsFilled(PriceKindSales), PriceKindSales, Catalogs.PriceKinds.Wholesale);
	
EndFunction// FillKindPrices()

// Function receives default selling prices kind for the specified counterparty.
//
// Price receipt method:
// 1. Counterparty -> Main contract -> Prices kind;
// 2. User settings -> Selling prices main kind;
// 3. Predefined prices kind: Producer price;
//	
Function GetDefaultPriceKind(Counterparty) Export
	
	If ValueIsFilled(Counterparty) 
		AND ValueIsFilled(Counterparty.ContractByDefault)
		AND ValueIsFilled(Counterparty.ContractByDefault.PriceKind) Then
		
		Return Counterparty.ContractByDefault.PriceKind;
		
	Else
		
		Return GetMainKindOfSalePrices();
		
	EndIf;
	
EndFunction

// Function receives company for the specified counterparty.
//
// Company receipt method:
// 1. Counterparty -> Main contract -> Company; (if on. data
// synchronization) 2. User settings -> Main company;
// 3. Predefined item: Main company;
//
Function GetDefaultCompany(Counterparty)
	
	// ATTENTION! Not to be confused with "SmallBusinessServer.GetCompany"
	
	If GetFunctionalOption("UseDataSynchronization")
		AND ValueIsFilled(Counterparty) 
		AND ValueIsFilled(Counterparty.ContractByDefault)
		AND ValueIsFilled(Counterparty.ContractByDefault.Company) Then
		
		Return Counterparty.ContractByDefault.Company;
		
	Else
		
		MainCompany = SmallBusinessReUse.GetValueByDefaultUser(UsersClientServer.AuthorizedUser(), "MainCompany");
		
		Return ?(ValueIsFilled(MainCompany), MainCompany, Catalogs.Companies.MainCompany);
		
	EndIf;

	
EndFunction //GetCompanyByDefault()

// Function returns the list of the "key" attributes names.
//
Function GetObjectAttributesBeingLocked() Export
	
	Result = New Array;
	
	Return Result;
	
EndFunction // GetLockedObjectAttributes()

#EndRegion

#Region CheckingDuplicates

//Function determines whether there are duplicates in counterparty.
// TIN - Checked counterparty TIN, Type - String(12)
// Ref - Checked counterparty itself, Type - CatalogRef.Counterparties
Function CheckCatalogDuplicatesCounterpartiesByTIN(Val TIN, ExcludingRef = Undefined, CheckOnWrite = False) Export
	
	Duplicates = New Array;
	
	Query = New Query;
	//If you write item, then check for
	//duplicates in register. Operation is executed only if there
	//is BeforeWrite object event IN the interactive
	//duplicates check it is not applied as exclusive locks are set to the register.
	If CheckOnWrite Then
		Duplicates = HasRecordsInDuplicatesRegister(TIN, ExcludingRef);
	EndIf;
	
	//If nothing is found in the duplicates register while writing item or while online check, execute duplicates search by the Counterparties catalog
	If Duplicates.Count() = 0 Then
		
		Query.Text = 	"SELECT
		               	|	Counterparties.Ref
		               	|FROM
		               	|	Catalog.Counterparties AS Counterparties
		               	|WHERE
		               	|	Not Counterparties.IsFolder
		               	|	AND Not Counterparties.Ref = &Ref
		               	|	AND Counterparties.TIN = &TIN";
		
		Query.SetParameter("TIN", TrimAll(TIN));
		Query.SetParameter("Ref", ExcludingRef);
		
		DuplicatesSelection = Query.Execute().Select();
		
		While DuplicatesSelection.Next() Do
			Duplicates.Add(DuplicatesSelection.Ref);
		EndDo;
		
	EndIf;
	
	Return Duplicates;
	
EndFunction

// Procedure returns duplicates array by records in the register
//Contractor duplicates availability Input receives input VAT and reference to the counterparty
Function HasRecordsInDuplicatesRegister(TIN, ExcludingRef = Undefined) Export
	
	Duplicates = New Array;
	
	Query = New Query;
	
	Query.SetParameter("Ref", ExcludingRef);
	Query.SetParameter("TIN", TrimAll(TIN));
	
	Query.Text = 
	"SELECT
	|	CounterpartyDuplicatesExist.Counterparty AS Ref
	|FROM
	|	InformationRegister.CounterpartyDuplicatesExist AS CounterpartyDuplicatesExist
	|WHERE
	|	Not CounterpartyDuplicatesExist.Counterparty = &Ref
	|	AND CounterpartyDuplicatesExist.TIN = &TIN";
	
	QueryResult = Query.Execute();
	
	DuplicatesSelection = QueryResult.Select();
	
	While DuplicatesSelection.Next() Do
		Duplicates.Add(DuplicatesSelection.Ref);
	EndDo;
	
	Return Duplicates;
	
EndFunction

// Procedure moves in the
// Ref duplicates register - ref to item of
// the CounterpartyByTIN catalog - Written counterparty
// TIN - ShouldBeDeleted
Procedure ExecuteRegisterRecordsOnRegisterTakes(Ref, TIN = "", NeedToDelete) Export
	
	RecordManager = InformationRegisters.CounterpartyDuplicatesExist.CreateRecordManager();
	
	RecordManager.Counterparty = Ref;
	RecordManager.TIN        = TIN;
	
	RecordManager.Read();
	
	WriteExist = RecordManager.Selected();
	
	If NeedToDelete AND WriteExist Then
		RecordManager.Delete();
	ElsIf Not NeedToDelete AND Not WriteExist Then
		
		RecordManager.Counterparty = Ref;
		RecordManager.TIN        = TIN;
		
		RecordManager.Active = True;
		RecordManager.Write(True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DataLoadFromFile

// Sets data import from file parameters
//
// Parameters:
//     Parameters - Structure - Parameters list. Fields: 
//         * Title - String - Window
// title * MandatoryColumns - Array - List of columns names mandatory
//         for filling * DataTypeColumns - Map, Key - Column name, Value - Data type description 
//
Procedure DefineDataLoadFromFileParameters(Parameters) Export
	
	Parameters.Title = "Counterparties";
	
	TINTypeDescription =  New TypeDescription("String",,,, New StringQualifiers(13));
	TypeDescriptionName =  New TypeDescription("String",,,, New StringQualifiers(100));
	Parameters.DataTypeColumns.Insert("TIN", TINTypeDescription);
	Parameters.DataTypeColumns.Insert("Description", TypeDescriptionName);

EndProcedure

// Matches imported data to data in IB.
//
// Parameters:
//   ExportableData - ValueTable - values table with the imported data:
//     * MatchedObject - CatalogRef - Ref to mapped object. Filled in
//     inside the procedure * <other columns>     - Arbitrary - Columns content corresponds to the "LoadFromFile" layout
//
Procedure MapImportedDataFromFile(ExportableData) Export

	Query = New Query;
	Query.Text = "SELECT
	               |	CASE
	               |		WHEN Counter.TIN IS NULL 
	               |				OR Counter.TIN LIKE """"
	               |			THEN ""0""
	               |		ELSE Counter.TIN
	               |	END AS TIN,
	               |	Counter.ID AS ID,
	               |	Counter.Description AS Description
	               |INTO Counter
	               |FROM
	               |	&Counter AS Counter
	               |
	               |INDEX BY
	               |	TIN,
	               |	ID,
	               |	Description
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Counterparties.Ref AS Ref,
	               |	Counterparties.TIN,
	               |	Counter.ID
	               |INTO CounterpartiesTIN
	               |FROM
	               |	Counter AS Counter
	               |		LEFT JOIN Catalog.Counterparties AS Counterparties
	               |		ON Counter.TIN = Counterparties.TIN
	               |WHERE
	               |	Not Counterparties.TIN IS NULL 
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Counter.ID AS ID,
	               |	Counter.Description AS Description
	               |INTO CounterpartiesName
	               |FROM
	               |	Counter AS Counter
	               |		LEFT JOIN CounterpartiesTIN AS CounterpartiesTIN
	               |		ON Counter.TIN = CounterpartiesTIN.TIN
	               |WHERE
	               |	CounterpartiesTIN.TIN IS NULL 
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Counterparties.Ref AS Ref,
	               |	CounterpartiesName.ID
	               |FROM
	               |	CounterpartiesName AS CounterpartiesName
	               |		LEFT JOIN Catalog.Counterparties AS Counterparties
	               |		ON CounterpartiesName.Description = Counterparties.Description
	               |WHERE
	               |	Not Counterparties.Ref IS NULL 
	               |	AND Counterparties.DeletionMark = FALSE
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	CounterpartiesTIN.Ref,
	               |	CounterpartiesTIN.ID
	               |FROM
	               |	CounterpartiesTIN AS CounterpartiesTIN";

	Query.SetParameter("Counter", ExportableData);
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do 
		 Filter = New Structure("ID", QueryResult.ID);
		 Rows=ExportableData.FindRows(Filter);
		 For Each String in Rows Do 
			 String.MappingObject = QueryResult.Ref;
		 EndDo;
	EndDo;

EndProcedure

// Data import from the file
//
// Parameters:
//   ExportableData - ValuesTable with columns:
//     * MatchedObject         - CatalogRef - Ref to
//     the matched object * StringMatchResult - String       - Update status, possible options: Created, Updated, Skipped
// * ErrorDescription               - String       - decryption of
//     data import error * Identifier                - Number        - String unique
// number * <other columns>             - Arbitrary - Imported file strings according to
// the ImportParameters layout                  - Structure    - Import
//     parameters * CreateNew               - Boolean       - It is required to create
//     catalog new items * ZeroExisting        - Boolean       - Whether it is
// required to update Denial catalog items                              - Boolean       - Cancel import
Procedure LoadFromFile(ExportableData, ExportParameters, Cancel) Export
	
	UseAccessGroup = ?(ExportableData.Columns.Find("AccessGroup") <> Undefined, True, False);
	
	For Each TableRow IN ExportableData Do
		Try
			
			If Not ValueIsFilled(TableRow.MappingObject) Then 
				If ExportParameters.CreateNew Then 
					BeginTransaction();
					CatalogItem = Catalogs.Counterparties.CreateItem();
					CatalogItem.Fill(TableRow);
					TableRow.MappingObject = CatalogItem;
					TableRow.RowMatchResult = "Created";
				Else
					TableRow.RowMatchResult = "Skipped";
					Continue;
				EndIf;
			Else
				If Not ExportParameters.UpdateExisting Then 
					TableRow.RowMatchResult = "Skipped";
					Continue;
				EndIf;
				
				BeginTransaction();
				Block = New DataLock;
				LockItem = Block.Add("Catalog.Counterparties");
				LockItem.SetValue("Ref", TableRow.MappingObject);
				
				CatalogItem = TableRow.MappingObject.GetObject();
				
				TableRow.RowMatchResult = "Updated";
				
				If CatalogItem = Undefined Then
					MessageText = StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='Counterparty with the %1 name does not exists.';ru='Контрагента с наименованием %1 не существует.';vi='Đối tác có tên gọi %1 không tồn tại.'"), TableRow.Description);
					Raise MessageText;
				EndIf;
			EndIf;
			
			If UseAccessGroup Then
				CatalogItem.AccessGroup = Catalogs.CounterpartiesAccessGroups.FindByDescription(TableRow.AccessGroup, False);
			EndIf;
			
			FillPropertyValues(CatalogItem, TableRow);
			If ValueIsFilled(TableRow.Parent) Then
				Group = Catalogs.Counterparties.FindByDescription(TableRow.Parent);
				If Group.IsEmpty() Then
					NewFolder = Catalogs.Counterparties.CreateFolder();
					NewFolder.Description = TableRow.Parent;
					NewFolder.Write();
					CatalogItem.Parent = NewFolder.Ref;
				Else
					CatalogItem.Parent = Group;
				EndIf;
				
			EndIf;
			
			If ValueIsFilled(TableRow.LegalEntityIndividual) Then
				If Lower(Enums.CounterpartyKinds.Individual) = Lower(TableRow.LegalEntityIndividual) Then
					CatalogItem.LegalEntityIndividual = Enums.CounterpartyKinds.Individual;
				Else
					CatalogItem.LegalEntityIndividual = Enums.CounterpartyKinds.LegalEntity;
				EndIf;
			Else
				CatalogItem.LegalEntityIndividual = Enums.CounterpartyKinds.LegalEntity;
			EndIf;
			
			If CatalogItem.CheckFilling() Then 
				CatalogItem.Write();
				TableRow.MappingObject = CatalogItem.Ref;
				CommitTransaction();
				Continue;
			Else
				RollbackTransaction();
				TableRow.RowMatchResult = "Skipped";
				
				UserMessages = GetUserMessages(True);
				If UserMessages.Count() > 0 Then
					MessagesText = "";
					For Each UserMessage IN UserMessages Do
						MessagesText = MessagesText + UserMessage.Text + Chars.LF;
					EndDo;
					TableRow.ErrorDescription = messagesText;
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

Procedure FillAreaParameters(AreaName, ParameterValues, PrintingStructure, OutputLogo = False)
	
	Var AreaProductsAndServices, AreaCharacteristic, AreaPrice;
	
	PrintingStructure.AreaStructure.Property("Area" + AreaName + "ProductsAndServices",		AreaProductsAndServices);
	PrintingStructure.AreaStructure.Property("Area" + AreaName + "Characteristic",	AreaCharacteristic);
	PrintingStructure.AreaStructure.Property("Area" + AreaName + "Price",				AreaPrice);
	
	AreaProductsAndServices.Parameters.Fill(ParameterValues);
	
	If OutputLogo Then
		
		AreaProductsAndServices.Drawings.Logo.Picture = ParameterValues.Picture;
		
	EndIf;
	
	PrintingStructure.SpreadsheetDocument.Put(AreaProductsAndServices);
	
	If PrintingStructure.UseCharacteristics Then
		
		AreaCharacteristic.Parameters.Fill(ParameterValues);
		PrintingStructure.SpreadsheetDocument.Join(AreaCharacteristic);
		
	EndIf;
	
	AreaPrice.Parameters.Fill(ParameterValues);
	PrintingStructure.SpreadsheetDocument.Join(AreaPrice);
	
EndProcedure

Procedure FillPriceListTitle(AreaName, PrintingStructure)
	
	ParameterValues = New Structure;
	ParameterValues.Insert("Title", "PRICE-SHEET");
	
	FillAreaParameters(AreaName, ParameterValues, PrintingStructure);
	
EndProcedure

Procedure FillPriceListSender(PrintingStructure)
	
	CompanyByDefault = GetDefaultCompany(PrintingStructure.Counterparty);
	
	InfoAboutSender = SmallBusinessServer.InfoAboutLegalEntityIndividual(CompanyByDefault, CurrentSessionDate());
	
	ParameterValues = 
		New Structure("Sender, SenderAddress, SenderPhone, SenderFax, SenderEmail",
			InfoAboutSender.Presentation,
			InfoAboutSender.ActualAddress,
			InfoAboutSender.PhoneNumbers,
			InfoAboutSender.Fax,
			InfoAboutSender.Email
			);
			
	OutputLogo = False;
	AreaName 		= "SenderWithoutLogo";
	
	If ValueIsFilled(CompanyByDefault.LogoFile) Then
		
		PictureData = AttachedFiles.GetFileBinaryData(CompanyByDefault.LogoFile);
		If ValueIsFilled(PictureData) Then
			
			OutputLogo = True;
			AreaName		= "SenderWithLogo";
			ParameterValues.Insert("Picture", New Picture(PictureData));
			
		EndIf;
		
	EndIf;
	
	FillAreaParameters(AreaName, ParameterValues, PrintingStructure, OutputLogo);
	
EndProcedure

Procedure FillFormedPriceList(AreaName, PrintingStructure)
	
	ParameterValues = 
		New Structure("Formed",
			"Formed " + Format(CurrentSessionDate(),"DF=dd.MM.yyyy")
			);
	
	FillAreaParameters(AreaName, ParameterValues, PrintingStructure);
	
EndProcedure

Procedure FillPriceListHeader(AreaName, PrintingStructure)
	
	PriceKind = GetDefaultPriceKind(PrintingStructure.Counterparty);
	
	ParameterValues = 
		New Structure("SKUCode, PricesKind, Price",
			?(Constants.PriceListShowCode.Get() = Enums.YesNo.Yes, "Code", "SKU"),
			PriceKind,
			"Price (" + PriceKind.PriceCurrency + ")"
			);
	
	FillAreaParameters(AreaName, ParameterValues, PrintingStructure);
	
EndProcedure

Procedure FillPriceListDetailsPriceGroup(PrintingStructure)
	
	Query = New Query(GetQueryTextForPrintingPriceListPriceGroup());
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("PriceKind", GetDefaultPriceKind(PrintingStructure.Counterparty));
	Query.SetParameter("OutputCode", Constants.PriceListShowCode.Get());
	Query.SetParameter("OutputFullDescr", Constants.PriceListShowFullDescr.Get());
	
	ParameterValues = 
		New Structure("PriceGroup, SKUCode, PresentationOfProductsAndServices, ProductsAndServices, Characteristic, MeasurementUnit, Price");
	
	SelectionPriceGroups = Query.Execute().Select(QueryResultIteration.ByGroupsWithHierarchy);
	While SelectionPriceGroups.Next() Do
		
		FillPropertyValues(ParameterValues, SelectionPriceGroups);
		FillAreaParameters("PriceGroup", ParameterValues, PrintingStructure);
		
		SelectionDetails = SelectionPriceGroups.Select();
		While SelectionDetails.Next() Do
			
			FillPropertyValues(ParameterValues, SelectionDetails);
			FillAreaParameters("Details", ParameterValues, PrintingStructure);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure FillPriceListDetailsProductsAndServicesHierarchy(PrintingStructure, Selection, OutputProductsAndServicesWithoutParent = False)
	
	ParameterValues = 
		New Structure("PriceGroup, SKUCode, PresentationOfProductsAndServices, ProductsAndServices, Characteristic, MeasurementUnit, Price");
	
	If OutputProductsAndServicesWithoutParent Then
		
		ParameterValues.PriceGroup = NStr("en='<...>';ru='<...>';vi='<...>'");
		FillAreaParameters("PriceGroup", ParameterValues, PrintingStructure);
		OutputEmptyParent = False;
		PrintingStructure.SpreadsheetDocument.StartRowGroup();
		
	EndIf;
	
	While Selection.Next() Do
		
		// Difficult conditions in the "If" operator are required for products and services to be output without parent to the price list
		If Selection.IsFolder 
			AND Not OutputProductsAndServicesWithoutParent Then
			
			ParameterValues.PriceGroup = Selection.ProductsAndServices;
			FillAreaParameters("PriceGroup", ParameterValues, PrintingStructure);
			
			PrintingStructure.SpreadsheetDocument.StartRowGroup();
			FillPriceListDetailsProductsAndServicesHierarchy(PrintingStructure, Selection.Select(QueryResultIteration.ByGroupsWithHierarchy));
			PrintingStructure.SpreadsheetDocument.EndRowGroup();
			
		ElsIf Not Selection.IsFolder 
			AND (OutputProductsAndServicesWithoutParent 
				OR ValueIsFilled(Selection.Parent)) Then
			
			FillPropertyValues(ParameterValues, Selection);
			FillAreaParameters("Details", ParameterValues, PrintingStructure);
			
		EndIf;
		
	EndDo;
	
	If OutputProductsAndServicesWithoutParent Then
		
		PrintingStructure.SpreadsheetDocument.EndRowGroup();
		Selection.Reset();
		FillPriceListDetailsProductsAndServicesHierarchy(PrintingStructure, Selection);
		
	EndIf;
	
EndProcedure

Procedure SelectPriceistDataProductsAndServicesHierarchy(PrintingStructure)
	
	Query = New Query(GetQueryTextForPrintingPriceListProductsAndServicesHierarchy());
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("PriceKind", GetDefaultPriceKind(PrintingStructure.Counterparty));
	Query.SetParameter("OutputCode", Constants.PriceListShowCode.Get());
	Query.SetParameter("OutputFullDescr", Constants.PriceListShowFullDescr.Get());
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		FillPriceListDetailsProductsAndServicesHierarchy(PrintingStructure, QueryResult.Select(QueryResultIteration.ByGroupsWithHierarchy), True);
		
	EndIf;
	
EndProcedure

// Function returns template areas structure to generate price list
//
Function FillTemplateAreaStructure(Template)
	
	AreaStructure = New Structure;
	
	AreaStructure.Insert("AreaGapProductsAndServices",			Template.GetArea("Indent|ProductsAndServices"));
	AreaStructure.Insert("AreaGapCharacteristic",		Template.GetArea("Indent|Characteristic"));
	AreaStructure.Insert("AreaGapPrice",					Template.GetArea("Indent|Price"));
	
	AreaStructure.Insert("AreaTitleProductsAndServices",		Template.GetArea("Title|ProductsAndServices"));
	AreaStructure.Insert("AreaTitleCharacteristic",	Template.GetArea("Title|Characteristic"));
	AreaStructure.Insert("AreaTitlePrice",				Template.GetArea("Title|Price"));
	
	AreaStructure.Insert("AreaSenderWithoutLogoProductsAndServices",		Template.GetArea("SenderWithoutLogo|ProductsAndServices"));
	AreaStructure.Insert("AreaSenderWithoutLogoCharacteristic",	Template.GetArea("SenderWithoutLogo|Characteristic"));
	AreaStructure.Insert("AreaSenderWithoutLogoPrice",				Template.GetArea("SenderWithoutLogo|Price"));
	
	AreaStructure.Insert("AreaSenderWithLogoProductsAndServices",		Template.GetArea("SenderWithLogo|ProductsAndServices"));
	AreaStructure.Insert("AreaSenderWithLogoCharacteristic",	Template.GetArea("SenderWithLogo|Characteristic"));
	AreaStructure.Insert("AreaSenderWithLogoPrice",				Template.GetArea("SenderWithLogo|Price"));
	
	AreaStructure.Insert("AreaFormedProductsAndServices",	Template.GetArea("Formed|ProductsAndServices"));
	AreaStructure.Insert("AreaFormedCharacteristic",	Template.GetArea("Formed|Characteristic"));
	AreaStructure.Insert("AreaFormedPrice",			Template.GetArea("Formed|Price"));
	
	AreaStructure.Insert("AreaTableHeaderProductsAndServices",	Template.GetArea("TableHeader|ProductsAndServices"));
	AreaStructure.Insert("AreaTableHeaderCharacteristic",	Template.GetArea("TableHeader|Characteristic"));
	AreaStructure.Insert("AreaTableHeaderPrice",			Template.GetArea("TableHeader|Price"));
	
	AreaStructure.Insert("AreaPriceGroupProductsAndServices",	Template.GetArea("PriceGroup|ProductsAndServices"));
	AreaStructure.Insert("AreaPriceGroupCharacteristic",Template.GetArea("PriceGroup|Characteristic"));
	AreaStructure.Insert("AreaPriceGroupPrice",			Template.GetArea("PriceGroup|Price"));
	
	AreaStructure.Insert("AreaDetailsProductsAndServices",			Template.GetArea("Details|ProductsAndServices"));
	AreaStructure.Insert("AreaDetailsCharacteristic",		Template.GetArea("Details|Characteristic"));
	AreaStructure.Insert("AreaDetailsPrice",					Template.GetArea("Details|Price"));
	
	Return AreaStructure;
	
EndFunction //FillTemplateAreaStructure()

// Price list generating procedure
//
Function GeneratePriceList(ObjectsArray, PrintObjects)
	
	UseItemHierarchy = Constants.PriceListUseProductsAndServicesHierarchy.Get();
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_PriceList";
	SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_PriceList";
	
	AreaStructure = FillTemplateAreaStructure(PrintManagement.PrintedFormsTemplate("Catalog.Counterparties.PF_MXL_PriceList"));
	
	FirstLineNumber = SpreadsheetDocument.TableHeight + 1;
	
	UseCharacteristics = GetFunctionalOption("UseCharacteristics");
	
	PrintingStructure =
		New Structure("SpreadSheetDocument, AreaStructure, Counterparty, UseCharacteristics",
			SpreadsheetDocument,
			AreaStructure,
			ObjectsArray,
			UseCharacteristics);
			
	NameSectionSender = ?(ValueIsFilled(GetDefaultCompany(PrintingStructure.Counterparty).LogoFile), "SenderWithLogo", "SenderWithoutLogo");
			
	//Fill in price list section by section
	FillPriceListTitle("Title", PrintingStructure);
	FillPriceListSender(PrintingStructure); // section is determined dynamically
	FillFormedPriceList("Formed", PrintingStructure);
	FillPriceListHeader("TableHeader", PrintingStructure);
	
	If UseItemHierarchy Then
		
		SelectPriceistDataProductsAndServicesHierarchy(PrintingStructure); // Output areas "Products and services group" and "Details"
		
	Else
		
		FillPriceListDetailsPriceGroup(PrintingStructure); // Output "PriceGroup" and "Details" areas
		
	EndIf;
	
	PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstLineNumber, PrintObjects, ObjectsArray.Ref);
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction // GeneratePriceList()

// Function calls procedure of printing price list for counterparty
// 
//
Function PrintForm(ObjectsArray, PrintObjects)
	
	Return GeneratePriceList(ObjectsArray[0], PrintObjects);
	
EndFunction // PrintForm()

// Generate printed forms of objects
//
// Incoming:
// TemplateNames    - String    - Names of layouts separated
// by commas ObjectsArray  - Array    - Array of refs to objects that
// need to be printed PrintParameters - Structure - Structure of additional printing parameters
//
// Outgoing:
// PrintFormsCollection - Values table - Generated
// table documents OutputParameters       - Structure        - Parameters of generated table documents
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "PriceList") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PriceList", "Price list", PrintForm(ObjectsArray, PrintObjects));
		
	EndIf;
	
	// Fill in price list receivers
	Recipients = New ValueList;
	Recipients.Add(ObjectsArray[0]);
	
	ArrayOfRecipients = New Array;
	ArrayOfRecipients.Add(ObjectsArray[0]);
	
	OutputParameters.SendingParameters.Recipient = Recipients;
	OutputParameters.SendingParameters.Subject = "Price list """ + GetDefaultCompany(ObjectsArray[0]).Description + """ from " + CurrentSessionDate() + ". Generated " + UsersClientServer.AuthorizedUser() + ".";
	SmallBusinessServer.FillSendingParameters(OutputParameters.SendingParameters, ArrayOfRecipients, PrintFormsCollection);
	
EndProcedure // Print()

// Fills in Customer order printing commands list
// 
// Parameters:
//   PrintCommands - ValueTable - see fields' content in the PrintManagement.CreatePrintCommandsCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

#EndRegion

#EndIf