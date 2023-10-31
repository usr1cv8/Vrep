#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure OnCopy(CopiedObject)
	
	// Billing
	ServiceContractBusinessActivity = Undefined;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("CatalogRef.Counterparties") Then
		
		FillByCounterparty(FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		FillByStructure(FillingData);
		
	EndIf;
	
	FillByDefault();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Prices kind.
	If ValueIsFilled(DiscountMarkupKind) Then
		CheckedAttributes.Add("PriceKind");
	EndIf;
	
	// Billing
	If IsServiceContract Then
		CheckedAttributes.Add("PriceKind");
		CheckedAttributes.Add("ServiceContractStartDate");
		CheckedAttributes.Add("ServiceContractTariffPlan");
		CheckedAttributes.Add("ServiceContractPeriodicity");
	EndIf;
		
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If DeletionMark Then
		
		CounterpartyAttributesValues = CommonUse.ObjectAttributesValues(Owner, "DeletionMark, ContractByDefault");
		
		If Not CounterpartyAttributesValues.DeletionMark And CounterpartyAttributesValues.ContractByDefault = Ref Then
			MessageText = NStr("en='The counterparty contract, established as the main, can not be marked for deletion.';ru='Договор контрагента, установленный в качестве основного, не может быть помечен на удаление.';vi='Không thể đặt dấu xóa hợp đồng đối tác được thiết lập là hợp đồng chính.'");
			CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		EndIf;
		
	EndIf;
	
	Query = New Query(
	"SELECT
	|	CounterpartyContracts.Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.Ref <> &Ref
	|	AND CounterpartyContracts.Owner = &Owner
	|	AND Not CounterpartyContracts.Owner.DoOperationsByContracts");
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Owner", Owner);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		MessageText = NStr("en='Contracts are not accounted for the counterparty.';ru='Для контрагента не ведется учет по договорам.';vi='Đối với đối tác không tiến hành kế toán theo hợp đồng.'");
		SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			MessageText,
			,
			,
			,
			Cancel
		);
	EndIf;
	
	// Billing
	If IsServiceContract And IsNew()
		Or IsServiceContract And Not IsNew() And Not Ref.IsServiceContract Then
		
		UseBusinessActivities = Constants.BillingKeepExpensesAccountingByServiceContracts.Get();
		If UseBusinessActivities Then
			ServiceContractBusinessActivity = 
				Catalogs.CounterpartyContracts.CreateBusinessActivityForServiceContract(Owner, Description);
		EndIf;
	EndIf;
		
	If ValueIsFilled(Ref) Then
		AdditionalProperties.Insert("DeletionMark", Ref.DeletionMark);
	EndIf;
	
EndProcedure

#EndRegion

#Region FillingProcedures

Procedure FillByCounterparty(FillingData)
	
	AttributesValues	= CommonUse.ObjectAttributesValues(FillingData, "Customer,Supplier,OtherRelationship, BankAccountByDefault");
	
	CompanyByDefault = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "MainCompany");
	If Not ValueIsFilled(CompanyByDefault) Then
		CompanyByDefault = Catalogs.Companies.MainCompany;
	EndIf;
	
	Description				= NStr("en='Main contract';ru='Основной договор';vi='Hợp đồng chính'");
	SettlementsCurrency		= Constants.NationalCurrency.Get();
	Company					= CompanyByDefault;
	ContractKind			= Enums.ContractKinds.WithCustomer;
	CashFlowItem			= Catalogs.CashFlowItems.PaymentFromCustomers;
	If AttributesValues.Supplier And Not AttributesValues.Customer Then
		ContractKind		= Enums.ContractKinds.WithVendor;
		CashFlowItem		= Catalogs.CashFlowItems.PaymentToVendor;
	ElsIf AttributesValues.OtherRelationship And Not AttributesValues.Customer And Not AttributesValues.Supplier Then
		ContractKind		= Enums.ContractKinds.Other;
		CashFlowItem		= Catalogs.CashFlowItems.Other;
	EndIf;
	PriceKind				= Catalogs.PriceKinds.GetMainKindOfSalePrices();
	Owner					= FillingData;
	VendorPaymentDueDate	= Constants.VendorPaymentDueDate.Get();
	CustomerPaymentDueDate	= Constants.CustomerPaymentDueDate.Get(); 
	CounterpartyBankAccount	= AttributesValues.BankAccountByDefault;
	Status					= Enums.CounterpartyContractStatuses.Active;
	
	If Not IsFolder And AdditionalProperties.Property("NewPriceKind") Then
		
		CounterpartyPriceKind = Catalogs.CounterpartyPriceKind.GetRef();
		AdditionalProperties.NewPriceKind = CounterpartyPriceKind;
		
	EndIf;

EndProcedure

Procedure FillByStructure(FillingData)

	If FillingData.Property("Owner") And ValueIsFilled(FillingData.Owner) Then
		
		FillByCounterparty(FillingData.Owner);
		
	EndIf;
	

EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

Procedure FillByDefault()
	
	If IsFolder Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Responsible) Then
		Responsible = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "MainResponsible");
	EndIf;
	
	If Not ValueIsFilled(Department) Then
		Department = SmallBusinessReUse.GetValueByDefaultUser(Users.CurrentUser(), "MainDepartment");
		If Not ValueIsFilled(Department) Then
			Department	= Catalogs.StructuralUnits.MainDepartment;	
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(BusinessActivity) Then
		BusinessActivity	= Catalogs.BusinessActivities.MainActivity;	
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// Billing
	If IsServiceContract Then
		If ValueIsFilled(ServiceContractBusinessActivity) Then
			// Если договор помечается (снимается пометка) на удаление, так же помечаем и связанное с ним направление деятельности.
			If AdditionalProperties.Property("DeletionMark") Then
				If AdditionalProperties.DeletionMark = False And DeletionMark = True
					Or AdditionalProperties.DeletionMark = True And DeletionMark = False Then
					
					BusinessActivityObject = ServiceContractBusinessActivity.GetObject();
					BusinessActivityObject.DeletionMark = DeletionMark;
					BusinessActivityObject.Write();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
		
	If Not IsFolder And AdditionalProperties.Property("NewPriceKind") Then
		
		PriceKindObject = Catalogs.CounterpartyPriceKind.CreateItem();
		PriceKindObject.Fill(Ref);
		PriceKindObject.SetNewObjectRef(AdditionalProperties.NewPriceKind);
		
		PriceKindObject.Write();
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
