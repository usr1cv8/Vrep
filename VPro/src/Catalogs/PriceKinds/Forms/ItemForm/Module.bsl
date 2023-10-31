////////////////////////////////////////////////////////////////////////////////
// GENERAL PURPOSE PROCEDURES AND FUNCTIONS

&AtServer
// Procedure controls the visible of items.
//
Procedure SetItemsVisible()
	
	If PriceCalculationMethod = "CalculatedDynamically" Then
		
		Items.PricesBaseKind.Visible = True;
		Items.PricesBaseKind.AutoChoiceIncomplete = True;
		Items.PricesBaseKind.AutoMarkIncomplete = True;
		Items.Percent.Visible = True;
		
		Items.PriceCalculationMethod.ToolTip = NStr("en='Prices are not stored."
"The prices in the documents are recalculated automatically relative to the basic price.';ru='Цены не хранятся. Цены в документах пересчитываются автоматически относительно базовой цены.';vi='Chưa lưu đơn giá."
"Đơn giá được tự động tính lại tỷ lệ với đơn giá cơ sở.'");
		
		Object.CalculatesDynamically = True;
		
		Object.PriceCurrency 		= ?(ValueIsFilled(Object.PricesBaseKind), Object.PricesBaseKind.PriceCurrency, Catalogs.Currencies.EmptyRef());
		Object.PriceIncludesVAT 	= ?(ValueIsFilled(Object.PricesBaseKind), Object.PricesBaseKind.PriceIncludesVAT, False);
		
	ElsIf PriceCalculationMethod = "Calculated" Then
	
		Items.PricesBaseKind.Visible = True;
		Items.PricesBaseKind.AutoChoiceIncomplete = True;
		Items.PricesBaseKind.AutoMarkIncomplete = True;
		Items.Percent.Visible = True;
		
		Items.PriceCalculationMethod.ToolTip = NStr("en='Prices are assigned and stored for each products and services item."
"Prices can be calculated relative to the basic price with the help of the prices forming mechanism.';ru='Цены применяются и хранятся для каждой позиции товаров и услуг."
"Цены могут быть рассчитаны относительно базовой цены с помощью механизма формирования цен.';vi='Đơn giá được áp dụng và được lưu đối với mỗi mục hàng hóa và dịch vụ."
"Đơn giá có thể được tính toán tỷ lệ với đơn giá cơ sở bằng cơ chế thiết lập giá.'");
		
		Object.CalculatesDynamically = False;
		
	Else
	
		Items.PricesBaseKind.Visible = False;
		Items.PricesBaseKind.AutoChoiceIncomplete = False;
		Items.PricesBaseKind.AutoMarkIncomplete = False;
		Items.Percent.Visible = False;
		
		Object.PricesBaseKind = Undefined;
		Object.Percent = 0;
		
		Items.PriceCalculationMethod.ToolTip =  NStr("en='Prices are assigned and stored for each products and services item. "
"On the basis of this price kind other price kinds can be calculated.';ru='Цены применяются и хранятся для каждой позиции товаров и услуг."
"На основе этого вида цен могут быть рассчитаны другие виды цен.';vi='Đơn giá được áp dụng và được lưu đối với mỗi mục hàng hóa và dịch vụ."
"Dựa trên dạng giá này, có thể tính toán các dạng giá khác.'");
		
		Object.CalculatesDynamically = False;
		
	EndIf;
	
	Items.PriceCurrency.Enabled 		= Not (PriceCalculationMethod = "CalculatedDynamically");
	Items.PriceIncludesVAT.Enabled 	= Not (PriceCalculationMethod = "CalculatedDynamically");
	
EndProcedure

&AtServerNoContext
// Procedure receives detailed data
// from the basic price, used only if
// the current item has dynamic kind
//
Function GetBasePriceData(PricesBaseKind)
	
	Return New Structure("PriceCurrency, PriceIncludesVAT", 
			?(ValueIsFilled(PricesBaseKind), PricesBaseKind.PriceCurrency, Catalogs.Currencies.EmptyRef()), 
			?(ValueIsFilled(PricesBaseKind), PricesBaseKind.PriceIncludesVAT, False));
	
EndFunction // GetBasePriceData()


////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - FORM EVENT HANDLERS

&AtServer
// Procedure - event handler OnCreateAtServer of the form.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Object.PriceCurrency) Then
		
		Object.PriceCurrency = Constants.NationalCurrency.Get();
		
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		If Object.CalculatesDynamically Then
			PriceCalculationMethod = "CalculatedDynamically";
		Else
			If Not ValueIsFilled(Object.PricesBaseKind) Then
				PriceCalculationMethod = "Manually";
			Else
				PriceCalculationMethod = "Calculated";
			EndIf;
		EndIf;
	Else
	    PriceCalculationMethod = "Manually";
		Object.CalculatesDynamically = False;
	EndIf; 
	
	SetItemsVisible();
	
	Example = 987654.321;
	FormattedExample = Format(Example, Object.PriceFormat);
	
	// Price accessibility setup for editing.
	AllowedEditDocumentPrices = SmallBusinessAccessManagementReUse.AllowedEditDocumentPrices();
	
	ThisForm.ReadOnly = Not AllowedEditDocumentPrices;
	
	// StandardSubsystems.AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AdditionalReportsAndDataProcessors
	
	// StandardSubsystems.Printing
	PrintManagement.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.Printing
	
EndProcedure

&AtServer
// Procedure-handler of the BeforeWriteAtServer event.
//
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(Object.Ref) Then
		
		Query = New Query(
		"SELECT
		|	StructuralUnits.Ref AS StructuralUnit
		|FROM
		|	Catalog.StructuralUnits AS StructuralUnits
		|WHERE
		|	StructuralUnits.RetailPriceKind = &RetailPriceKind"
		);
		
		Query.SetParameter("RetailPriceKind", CurrentObject.Ref);
		QueryExecutionResult = Query.Execute();
		
		If Not QueryExecutionResult.IsEmpty()
			AND Not CurrentObject.PriceCurrency = Constants.NationalCurrency.Get() Then
			
			MessageText = NStr("en='Current price kind is used in retail structural units, that is why only national currency can be used for it.';ru='Текущий вид цен используется в розничных структурных единицах, по этому для него можно использовать только национальную валюту.';vi='Dạng hiện tại của đơn giá được sử dụng trong các đơn vị theo cấu trúc bán lẻ theo đó chỉ có thể sử dụng nội tệ.'");
			CommonUseClientServer.MessageToUser(MessageText, , "Object.PriceCurrency", , Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure // BeforeWriteAtServer()

&AtClient
// BeforeRecord event handler procedure.
//
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// StandardSubsystems.PerformanceEstimation
	PerformanceEstimationClientServer.StartTimeMeasurement("CatalogPriceKindWrite");
	// StandardSubsystems.PerformanceEstimation
	
EndProcedure //BeforeWrite()


////////////////////////////////////////////////////////////////////////////////
// PROCEDURE - EVENT HANDLERS OF FORM ATTRIBUTES

&AtClient
// Procedure - event handler OnChange of the PriceCalculationMethod input field.
//
Procedure PriceCalculationMethodOnChange(Item)
	
	SetItemsVisible();	
	
EndProcedure

&AtClient
// Procedure - setting prices format.
//
Procedure Set(Command)
	
	Assistant = New FormatStringWizard(Object.PriceFormat);
	Assistant.AvailableTypes = New TypeDescription("Number");
	Assistant.Show(New NotifyDescription("SetEnd",ThisForm));
	
EndProcedure

&AtClient
Procedure SetEnd(Text,Parameters) Export

	If Text=Undefined Then
		Return;
	EndIf;
	
	Object.PriceFormat = Text;
	FormattedExample = Format(Example, Object.PriceFormat);

EndProcedure

&AtClient
// Procedure - event handler OnChange of the Example input field.
//
Procedure ExampleOnChange(Item)
	
	FormattedExample = Format(Example, Object.PriceFormat);
	
EndProcedure

&AtClient
// Procedure event handler OnChange of the "BasePriceKind"
//
// It makes sence only for dynamic price types, as currency and the value of the parameter are taken from the base PriceIncludesVAT
//
Procedure PricesBaseKindOnChange(Item)
	
	BasePriceData 		= GetBasePriceData(Object.PricesBaseKind);
	
	Object.PriceCurrency 		= BasePriceData.PriceCurrency;
	Object.PriceIncludesVAT 	= BasePriceData.PriceIncludesVAT;
	
EndProcedure // PricesBaseKindOnChange()

#Region LibrariesHandlers

// StandardSubsystems.AdditionalReportsAndDataProcessors
&AtClient
Procedure Attachable_ExecuteAssignedCommand(Command)
	If Not AdditionalReportsAndDataProcessorsClient.ExecuteAllocatedCommandAtClient(ThisForm, Command.Name) Then
		ExecutionResult = Undefined;
		AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(Command.Name, ExecutionResult);
		AdditionalReportsAndDataProcessorsClient.ShowCommandExecutionResult(ThisForm, ExecutionResult);
	EndIf;
EndProcedure

&AtServer
Procedure AdditionalReportsAndProcessingsExecuteAllocatedCommandAtServer(ItemName, ExecutionResult)
	AdditionalReportsAndDataProcessors.ExecuteAllocatedCommandAtServer(ThisForm, ItemName, ExecutionResult);
EndProcedure
// End StandardSubsystems.AdditionalReportsAndDataProcessors

// StandardSubsystems.Printing
&AtClient
Procedure Attachable_ExecutePrintCommand(Command)
	PrintManagementClient.ExecuteConnectedPrintCommand(Command, ThisObject, Object);
EndProcedure
// End StandardSubsystems.Printing

#EndRegion
