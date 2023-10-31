#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

Procedure OnDefineReportSettings(ReportSettings, VariantsSettings) Export
	
	ReportSettings.ShowChartSettingsOnReportForm = False;
	ReportSettings.UseComparison = True;
	ReportSettings.UsePeriodicity = True;
	ReportSettings.Insert("PeriodMode", "ForPeriod");
	
	VariantsSettings["Main"].Tags = NStr("en='Sales,Billings,Regular services';ru='Продажи,Биллинг,Регулярные услуги';vi='Bán hàng, Tự động lập yêu cầu thanh toán, Dịch vụ thông thường'");
	VariantsSettings["Main"].Recommended = True;
	VariantsSettings["Main"].FunctionalOption = "UseBilling";
	
	AddRelatedFieldsDescriptions(VariantsSettings);
	
	If Constants.BillingKeepExpensesAccountingByServiceContracts.Get() Then
		SelectedFieldKD = SettingsComposer.Settings.Selection.Items.Insert(0, Type("DataCompositionSelectedField"));
		SelectedFieldKD.Field = New DataCompositionField("AmountExpenses");
		SelectedFieldKD.Use = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventsHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing) Export
	
	ServiceContracts = New ValueList;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CounterpartyContracts.Ref AS Ref
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.IsServiceContract
	|	AND NOT CounterpartyContracts.DeletionMark";
	SELECTION = Query.Execute().Select();
	While SELECTION.Next() Do
		ServiceContracts.Add(SELECTION.Ref);
	EndDo;
	
	SmallBusinessReports.SetReportParameterByDefault(SettingsComposer.Settings, "AccountingCurrency", SmallBusinessReUse.GetAccountCurrency());
	SmallBusinessReports.SetReportParameterByDefault(SettingsComposer.Settings, "ServiceContracts", ServiceContracts);
	SmallBusinessReports.AddCurrencyCharToFieldsHeaders(DataCompositionSchema, "AmountExpenses,AmountInvoiced,InCounterpartyDebtCur,DeCounterpartyDebtCur");
	SmallBusinessReports.OnResultComposition(SettingsComposer, DataCompositionSchema, ResultDocument, DetailsData, StandardProcessing);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Procedure AddRelatedFieldsDescriptions(VariantsSettings)
	
	VariantStructure = VariantsSettings["Main"];
	SmallBusinessReports.AddBindingDetails(VariantStructure.LinkedFields, "ServiceContract", "Catalog.CounterpartyContracts",,, True);
	SmallBusinessReports.AddBindingDetails(VariantStructure.LinkedFields, "Counterparty", "Catalog.Counterparties",,, True);
	
EndProcedure

Function FindGroupingByDataCompositionFieldRecursively(DCSettingsStructureItemsCollection, DCField)
	
	For Each DCGroup In DCSettingsStructureItemsCollection Do
		For Each DCGroupingField In DCGroup.GroupFields.Items Do
			If DCGroupingField.Field = DCField Then
				Return DCGroup;
			EndIf;
		EndDo;
		FoundDCGroup = FindGroupingByDataCompositionFieldRecursively(DCGroup.Structure, DCField);
		If FoundDCGroup <> Undefined Then
			Return FoundDCGroup;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

IsCMReport = True;

#EndIf