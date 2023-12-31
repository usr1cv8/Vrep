#Region CommonUseProceduresAndFunctions

// The procedure updates the name if the user did not change it manually.
//
&AtClient
Procedure UpdateAutoNaming(Refresh = True, SetModified = False)
	
	If Not ValueIsFilled(Object.Description) OR (Refresh AND UsedAutoDescription AND Not DescriptionChangedByUser) Then
		Object.Description = FormAutoNamingAtClient();
		UsedAutoDescription = True;
		
		If SetModified Then
			Modified = True;
		EndIf;
	EndIf;
	
EndProcedure

// The function returns generated auto naming.
//
&AtClient
Function FormAutoNamingAtClient()
	
	Items.Description.ChoiceList.Clear();
	
	DescriptionString = "";
	
	If Object.AssignmentMethod = AssignmentMethodPercent Then
		
		DescriptionString = "" + Object.DiscountMarkupValue + NStr("en='%';ru='%';vi='%'");
		
	ElsIf Object.AssignmentMethod = AssignmentMethodAmount Then
		
		DescriptionString = "" + Object.DiscountMarkupValue + " " + Object.AssignmentCurrency;
		
	EndIf;
	
	Items.Description.ChoiceList.Add(DescriptionString);
	
	If Object.ConditionsOfAssignment.Count() = 1 Then
		DescriptionString = DescriptionString + " ("+Object.ConditionsOfAssignment[0].AssignmentCondition+")";
		Items.Description.ChoiceList.Add(DescriptionString);
	ElsIf Object.ConditionsOfAssignment.Count() > 1 Then
		
		ConditionsNumber = Object.ConditionsOfAssignment.Count();
		
		If ConditionsNumber >= 2 Then
			DescriptionString = DescriptionString + " " +NStr("en='(several conditions)';ru='(несколько условий)';vi='(nhiều điều kiện)'");
			Items.Description.ChoiceList.Add(DescriptionString);
		EndIf;
		
	ElsIf Object.ConditionsOfAssignment.Count() = 0 Then
		DescriptionString = DescriptionString + " " + NStr("en='without conditions';ru='без условий';vi='không có điều kiện'");
		Items.Description.ChoiceList.Add(DescriptionString);
	EndIf;
	
	AmountInDocument = (Object.AssignmentMethod = AssignmentMethodAmount AND Object.AssignmentArea = AreaInDocument);
	If Object.ProductsAndServicesGroupsPriceGroups.Count() > 0 AND Not AmountInDocument Then
		DescriptionString = DescriptionString + NStr("en=', with specification';ru=', с уточнением';vi=', có làm rõ'");
		Items.Description.ChoiceList.Add(DescriptionString);
	EndIf;
	
	If (Object.DiscountRecipientsCounterparties.Count() > 0 AND Object.Purpose <> PurposeRetail) 
		OR (Object.DiscountRecipientsWarehouses.Count() > 0 AND Object.Purpose <> PurposeWholesale) Then
		DescriptionString = DescriptionString + NStr("en=', recipients are specified';ru=', указаны получатели';vi=', với một số người nhận'");
		Items.Description.ChoiceList.Add(DescriptionString);
	EndIf;
	
	If Object.TimeByDaysOfWeek.Count() > 0 Then
		DescriptionString = DescriptionString + NStr("en=', on schedule';ru=', по расписанию';vi=', theo lịch biểu'");
		Items.Description.ChoiceList.Add(DescriptionString);
	EndIf;
	
	Return DescriptionString;

EndFunction

// The function returns generated auto naming.
//
&AtServer
Function FormAutoNamingAtServer()
	
	Items.Description.ChoiceList.Clear();
	
	DescriptionString = "";
	
	If Object.AssignmentMethod = AssignmentMethodPercent Then
		
		DescriptionString = "" + Object.DiscountMarkupValue + NStr("en='%';ru='%';vi='%'");
		
	ElsIf Object.AssignmentMethod = AssignmentMethodAmount Then
		
		DescriptionString = "" + Object.DiscountMarkupValue + " " + Object.AssignmentCurrency;
		
	EndIf;
	
	Items.Description.ChoiceList.Add(DescriptionString);
	
	If Object.ConditionsOfAssignment.Count() = 1 Then
		
		DescriptionString = DescriptionString + " ("+Object.ConditionsOfAssignment[0].AssignmentCondition+")";
		Items.Description.ChoiceList.Add(DescriptionString);
		
	ElsIf Object.ConditionsOfAssignment.Count() > 1 Then
		
		ConditionsNumber = Object.ConditionsOfAssignment.Count();
		
		If ConditionsNumber >= 2 Then
			DescriptionString = DescriptionString + " " +NStr("en='(several conditions)';ru='(несколько условий)';vi='(nhiều điều kiện)'");
			Items.Description.ChoiceList.Add(DescriptionString);
		EndIf;
		
	ElsIf Object.ConditionsOfAssignment.Count() = 0 Then
		
		DescriptionString = DescriptionString + " " + NStr("en='without conditions';ru='без условий';vi='không có điều kiện'");
		Items.Description.ChoiceList.Add(DescriptionString);
		
	EndIf;
	
	AmountInDocument = (Object.AssignmentMethod = AssignmentMethodAmount AND Object.AssignmentArea = AreaInDocument);
	If Object.ProductsAndServicesGroupsPriceGroups.Count() > 0 AND Not AmountInDocument Then
		DescriptionString = DescriptionString + NStr("en=', with specification';ru=', с уточнением';vi=', có làm rõ'");
		Items.Description.ChoiceList.Add(DescriptionString);
	EndIf;
	
	If (Object.DiscountRecipientsCounterparties.Count() > 0 AND Object.Purpose <> PurposeRetail) 
		OR (Object.DiscountRecipientsWarehouses.Count() > 0 AND Object.Purpose <> PurposeWholesale) Then
		DescriptionString = DescriptionString + NStr("en=', recipients are specified';ru=', указаны получатели';vi=', với một số người nhận'");
		Items.Description.ChoiceList.Add(DescriptionString);
	EndIf;
	
	If Object.TimeByDaysOfWeek.Count() > 0 Then
		DescriptionString = DescriptionString + NStr("en=', on schedule';ru=', по расписанию';vi=', theo lịch biểu'");
		Items.Description.ChoiceList.Add(DescriptionString);
	EndIf;
	
	Return DescriptionString;

EndFunction

// The function returns an option for shared use of automatic discounts which is relevant to the current discount.
//
&AtServerNoContext
Function GetSharedUsageCurrentOption(Parent)

	If Parent.IsEmpty() Then
		Return Constants.DiscountsMarkupsSharedUsageOptions.Get();
	Else
		Return Parent.SharedUsageVariant;
	EndIf;

EndFunction // GetJointApplicationCurrentOption()

#EndRegion

#Region ProceduresFormEventsHandlers

// Procedure - OnCreateAtServer event handler.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// To reduce the number of non-contextual calls to server.
	AssignmentMethodPercent = Enums.DiscountsMarkupsProvidingWays.Percent;
	AssignmentMethodAmount = Enums.DiscountsMarkupsProvidingWays.Amount;
	RestrictionByProductsAndServicesVariant = Enums.DiscountRestrictionVariantsByProductsAndServices.ByProductsAndServices;
	RestrictionVariantByProductsAndServicesGroups = Enums.DiscountRestrictionVariantsByProductsAndServices.ByProductsAndServicesCategories;
	VariantRestrictionByPriceGroups = Enums.DiscountRestrictionVariantsByProductsAndServices.ByPriceGroups;
	PurposeRetail = Enums.AssignAutomaticDiscounts.Retail;
	PurposeWholesale = Enums.AssignAutomaticDiscounts.Wholesale;
	AreaInDocument = Enums.DiscountMarkupRestrictionAreasVariants.InDocument;
	
	AllowedEditDocumentPrices = SmallBusinessAccessManagementReUse.AllowedEditDocumentPrices();
	ThisForm.ReadOnly = Not AllowedEditDocumentPrices;
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.Description = FormAutoNamingAtServer();
	Else
		FormAutoNamingAtServer();
	EndIf;
	
	For Each NameVariant IN Items.Description.ChoiceList Do
		If Object.Description = NameVariant.Value Then
			UsedAutoDescription = True;
			Break;
		EndIf;
	EndDo;
	
	// Define visible of attribute for additional sorting.
	If Object.AdditionalOrderingAttribute > 0 Then
		Items.AdditionalOrderingAttribute.Visible = True;
	Else
		If Object.Parent.IsEmpty() Then
			SharedUsageCurOption = Constants.DiscountsMarkupsSharedUsageOptions.Get();
		Else
			SharedUsageCurOption = Object.Parent.SharedUsageVariant;
		EndIf;
		
		Items.AdditionalOrderingAttribute.Visible = (SharedUsageCurOption = Enums.DiscountsMarkupsSharedUsageOptions.Exclusion 
														OR SharedUsageCurOption = Enums.DiscountsMarkupsSharedUsageOptions.Multiplication);
	EndIf;
	
	RestrictionByProductsAndServicesVariantBeforeChange = Object.RestrictionByProductsAndServicesVariant;
	Items.DecorationParentSharedUsageVariant.Title = String(Object.Parent.SharedUsageVariant);
	Items.DecorationParentSharedUsageVariant.Visible = Not Object.Parent.IsEmpty();
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupAdditional, Object.Comment);
	
	VisibleManagementAtServer();
	
EndProcedure

// Procedure - event handler NotificationProcessing.
//
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "AssignmentCondition_Record" Then
		UpdateAutoNaming(True, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForFormAppearanceManagement

// The procedure controls the visible of items depending on restriction option, method and area of discount application.
//
&AtServer
Procedure VisibleManagementAtServer()

	If Object.RestrictionByProductsAndServicesVariant.IsEmpty() Then
		Object.RestrictionByProductsAndServicesVariant = RestrictionByProductsAndServicesVariant;
	EndIf;
	
	AmountInDocument = (Object.AssignmentMethod = AssignmentMethodAmount 
						AND Object.AssignmentArea = AreaInDocument);
		
	Items.Clarification.Visible = Not AmountInDocument;
	If Object.RestrictionByProductsAndServicesVariant = RestrictionByProductsAndServicesVariant Then
		Items.ProductsAndServicesGroupsPriceGroupsClarificationValue.Title = NStr("en='Products and services';ru='Номенклатура';vi='Mặt hàng'");
		Items.ProductsAndServicesGroupsPriceGroupsClarificationValue.TypeRestriction = New TypeDescription("CatalogRef.ProductsAndServices");
		
		Items.DecorationHelpClarification.Title = NStr("en='Fill in the refinements if it is required to apply discount amount to certain products or product groups which is different from the main amount. If the list is not completed, basic discount will be used for all products and services.';ru='Заполните уточнения, если требуется, чтобы у определённых товаров или групп товаров значение скидки отличалось от основного значения. Если список не заполнен, то для всех позиций номенклатуры используется основное значение скидки.';vi='Hãy điền thông tin làm rõ nếu như cần áp dụng giảm giá cho một số mặt hàng hoặc nhóm mặt hàng mà khác với giá trị chính. Nếu chưa điền danh sách này thì đối với tất cả mặt hàng sẽ áp dụng chiết khấu chính.'");
		
		Items.ProductsAndServicesGroupsPriceGroupsCharacteristic.Visible = True;
	ElsIf Object.RestrictionByProductsAndServicesVariant = RestrictionVariantByProductsAndServicesGroups Then
		Items.ProductsAndServicesGroupsPriceGroupsClarificationValue.TypeRestriction = New TypeDescription("CatalogRef.ProductsAndServicesCategories");
		Items.ProductsAndServicesGroupsPriceGroupsClarificationValue.Title = NStr("en='Products and services category';ru='Категория номенклатуры';vi='Nhóm mặt hàng'");
		
		Items.DecorationHelpClarification.Title = NStr("en='Fill in the refinements if it is required to apply discount amount to certain products and services groups which is different from the main amount. If the list is not completed, basic discount will be used for all products and services groups.';ru='Заполните уточнения, если требуется, чтобы у товаров определённых категорий значение скидки отличалось от основного значения. Если список не заполнен, то для всех категорий используется основное значение скидки.';vi='Hãy điền thông tin làm rõ nếu như cần áp dụng giảm giá số tiền cho một số nhóm mặt hàng mà khác với giá trị chính. Nếu chưa điền danh sách này thì đối với tất cả các mặt hàng sẽ áp dụng mức chiết khấu chính.'");
		
		Items.ProductsAndServicesGroupsPriceGroupsCharacteristic.Visible = False;
	ElsIf Object.RestrictionByProductsAndServicesVariant = VariantRestrictionByPriceGroups Then
		Items.ProductsAndServicesGroupsPriceGroupsClarificationValue.Title = NStr("en='Price group';ru='Ценовая группа';vi='Nhóm giá'");
		Items.ProductsAndServicesGroupsPriceGroupsClarificationValue.TypeRestriction = New TypeDescription("CatalogRef.PriceGroups");
		
		Items.DecorationHelpClarification.Title = NStr("en='Fill in the refinement if it is required to assign discount amount to the products of certain price groups which is different from the main amount. If the list is not completed, then basic discount will be applied for all price groups.';ru='Заполните уточнения, если требуется, чтобы у товаров определённых ценовых групп значение скидки отличалось от основного значения. Если список не заполнен, то для всех ценовых групп используется основное значение скидки.';vi='Hãy điền thông tin làm rõ nếu cần áp dụng giảm giá cho sản phẩm thuộc một số nhóm giá mà khác với giá trị chính. Nếu chưa điền danh sách này thì sẽ áp dụng mức giảm giá chính cho tất cả các nhóm giá.'");
		
		Items.ProductsAndServicesGroupsPriceGroupsCharacteristic.Visible = False;
	EndIf;
	
	Items.AssignmentCurrency.Visible = (Object.AssignmentMethod = AssignmentMethodAmount);
	
	RecipientsVisibleSetupAtServer();
	
EndProcedure

#EndRegion

#Region ProceduresElementFormEventsHandlers

// Procedure - event handler OnChange item RestrictionByProductsAndServicesOption.
//
&AtClient
Procedure RestrictionByProductsAndServicesVariantOnChange(Item)
	
	If Object.ProductsAndServicesGroupsPriceGroups.Count() > 0 Then
		Description = New NotifyDescription("RestrictionByProductsAndServicesOptionOnChangeConclusion", ThisObject);
		ShowQueryBox(Description, NStr("en='Table of refinements will be cleared. Continue?';ru='Таблица уточнений будет очищена. Продолжить?';vi='Bảng thông tin làm rõ sẽ bị xóa. Tiếp tục?'"), QuestionDialogMode.YesNo,,DialogReturnCode.No,"Change refining option");
	Else
		RestrictionByProductsAndServicesVariantBeforeChange = Object.RestrictionByProductsAndServicesVariant;
		VisibleManagementAtServer();
	EndIf;
	
EndProcedure

// Procedure - events handler OnChange item RestrictionByProductsAndServicesOption (conclusion after response to the question about deletion of lines in SP).
//
&AtClient
Procedure RestrictionByProductsAndServicesOptionOnChangeConclusion(ResponseResult, AdditionalParameters) Export

	If ResponseResult <> DialogReturnCode.Yes Then
		Object.RestrictionByProductsAndServicesVariant = RestrictionByProductsAndServicesVariantBeforeChange;
		Return;
	EndIf;
	
	Object.ProductsAndServicesGroupsPriceGroups.Clear();
	RestrictionByProductsAndServicesVariantBeforeChange = Object.RestrictionByProductsAndServicesVariant;
	VisibleManagementAtServer();
	
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - event handler OnChange item ProvisionMethod.
//
&AtClient
Procedure AssignmentMethodOnChange(Item)
	
	VisibleManagementAtServer();
	Object.DiscountMarkupValue = 0;
	
	ShowClarificationsPage = False;
	For Each CurrentRow IN Object.ProductsAndServicesGroupsPriceGroups Do
	
		CurrentRow.DiscountMarkupValue = 0;
		ShowClarificationsPage = True;
		
	EndDo;
	
	If ShowClarificationsPage Then
		
		Items.Pages.CurrentPage = Items.GroupClarificationsRestrictionsAndSchedule;
		Items.PagesClarificationsAndRestrictions.CurrentPage = Items.Clarification;
		
		AmountInDocument = (Object.AssignmentMethod = AssignmentMethodAmount 
							AND Object.AssignmentArea = AreaInDocument);
							
		If Not AmountInDocument Then
			CommonUseClientServer.MessageToUser("Discounts are cleared!");
		EndIf;
		
	EndIf;
	
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - event  handler OnChange item ProvisionArea.
//
&AtClient
Procedure AssignmentAreaOnChange(Item)
	
	VisibleManagementAtServer();
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - event handler OnChange item Name.
//
&AtClient
Procedure DescriptionOnChange(Item)
	
	DescriptionChangedByUser = True;
	
EndProcedure

// Procedure - event handler OnChange item DiscountMarkupValue.
//
&AtClient
Procedure DiscountMarkupValueOnChange(Item)
	
	If Object.AssignmentMethod = AssignmentMethodPercent Then
		If Object.DiscountMarkupValue > 100 Then
			MessageText = NStr("en='Discount percent should not exceed 100%';ru='Процент скидки должен быть не более 100%';vi='Phần trăm chiết khấu cần nhỏ hơn 100%'");
			CommonUseClientServer.MessageToUser(MessageText, 
																,
																"DiscountMarkupValue",
																"Object");
			Object.DiscountMarkupValue = 0;
		EndIf;
	EndIf;
	UpdateAutoNaming(True);

EndProcedure

// Procedure - event handler OnChange Parent item.
//
&AtClient
Procedure ParentOnChange(Item)
	
	ParentOnChangeAtServer();
	
EndProcedure

// Server part of procedure ParentOnChange.
//
&AtServer
Procedure ParentOnChangeAtServer()
	
	SharedUsageCurOption = GetSharedUsageCurrentOption(Object.Parent);
	
	Items.AdditionalOrderingAttribute.Visible = (Object.AdditionalOrderingAttribute > 0 OR SharedUsageCurOption = PredefinedValue("Enum.DiscountsMarkupsSharedUsageOptions.Exclusion") 
													OR SharedUsageCurOption = PredefinedValue("Enum.DiscountsMarkupsSharedUsageOptions.Multiplication"));
	
	Items.DecorationParentSharedUsageVariant.Title = String(SharedUsageCurOption);
	Items.DecorationParentSharedUsageVariant.Visible = Not Object.Parent.IsEmpty();
	
EndProcedure

// Procedure - event handler OnChange item Purpose.
//
&AtClient
Procedure PurposeOnChange(Item)
	
	RecipientsVisibleSetupAtServer();
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - OnChange event handler of the Comment input field.
//
&AtClient
Procedure CommentOnChange(Item)
	
	AttachIdleHandler("Attachable_SetPictureForComment", 0.5, True);
	
EndProcedure // CommentOnChange()

&AtClient
Procedure Attachable_SetPictureForComment()
	
	SmallBusinessClientServer.SetPictureForComment(Items.GroupAdditional, Object.Comment);
	
EndProcedure

#EndRegion

#Region ProceduresSpreadsheetPartEventsHandlers

// Procedure - events handler OnChange item form AssignmentCondition.
//
&AtClient
Procedure AssignmentConditionsOnChange(Item)
	
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - events handler OnChange form SP TimeByWeekDays.
//
&AtClient
Procedure TimeByDaysOfWeekOnChange(Item)
	
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - event handler OnChange form SP DiscountRecipientsCounterparties.
//
&AtClient
Procedure DiscountRecipientsOnChange(Item)
	
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - events handler OnChange form SP DiscountRecipientsWarehouses.
//
&AtClient
Procedure DiscountRecipientsWarehousesOnChange(Item)
	
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - events handler OnChange column DiscountAmount in ProductsAndServicesGroupsPriceGroups form SP.
//
&AtClient
Procedure ProductsAndServicesGroupsPriceGroupsDiscountMarkupValueOnChange(Item)
	
	CurrentRow = Items.ProductsAndServicesGroupsPriceGroups.CurrentData;
	If CurrentRow <> Undefined Then
		If Object.AssignmentMethod = AssignmentMethodPercent Then
			If CurrentRow.DiscountMarkupValue > 100 Then
				MessageText = NStr("en='Discount percent should not exceed 100%';ru='Процент скидки должен быть не более 100%';vi='Phần trăm chiết khấu cần nhỏ hơn 100%'");
				CommonUseClientServer.MessageToUser(MessageText, 
																	,
																	"ProductsAndServicesGroupsPriceGroups["+(CurrentRow.LineNumber-1)+"].DiscountMarkupValue",
																	"Object");
				CurrentRow.DiscountMarkupValue = 0;
			EndIf;
		EndIf;
	EndIf;
	
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - event handler OnChange form SP ProductsAndServicesGroupsPriceGroups.
//
&AtClient
Procedure ProductsAndServicesGroupsPriceGroupsOnChange(Item)
	
	UpdateAutoNaming(True);
	
EndProcedure

// Procedure - events handler OnStartEdit form SP TimeByWeekDays.
//
&AtClient
Procedure TimeByDaysOfWeekOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Item.CurrentData.Selected = True;
		Item.CurrentData.BeginTime = '00010101000000';
		Item.CurrentData.EndTime = '00010101235959';
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForFormAppearanceManagement

// The procedure controls visible of form items depending on the automatic discount assignment.
//
&AtServer
Procedure RecipientsVisibleSetupAtServer()

	If Object.Purpose = PurposeRetail Then
		Items.GroupCounterparties.Visible = False;
		Items.WarehouseGroups.Visible = True;
		Items.GroupsWarehousesAndCounterparties.PagesRepresentation = FormPagesRepresentation.None;
		
		Items.DecorationHelpRecipients.Title = NStr("en='Complete the list of warehouses if discount (extra charge) will be provided only in certain warehouses."
"If the list is not completed, the discount (extra charge) will be applied in all warehouses.';ru='Заполните список складов, если скидка (наценка) будет предоставляться только на определённых складах."
"Если список не заполнен, то скидка (наценка) будет предоставляться на всех складах.';vi='Hãy điền giá trị kho bãi, nếu áp dụng chiết khấu (phụ thu) chỉ tại các kho cụ thể."
"Nếu chưa điền danh sách thì sẽ áp dụng chiết khấu (phụ thu) tại tất cả các kho.'");
	ElsIf Object.Purpose = PurposeWholesale Then
		Items.GroupCounterparties.Visible = True;
		Items.WarehouseGroups.Visible = False;
		Items.GroupsWarehousesAndCounterparties.PagesRepresentation = FormPagesRepresentation.None;
		
		Items.DecorationHelpRecipients.Title = NStr("en='Complete the list of counterparties if the discount (extra charge) will be provided only to a certain list of counterparties."
"If the list is not completed, the discount (extra charge) will be provided to all counterparties.';ru='Заполните список контрагентов, если скидка (наценка) будет предоставляться только определённому списку контрагентов."
"Если список не заполнен, то скидка (наценка) будет предоставляться всем контрагентам.';vi='Hãy điền danh sách đối tác, nếu sẽ điền chiết khấu (phụ thu) chỉ dành cho danh sách đối tác đã xác định."
"Nếu chưa điền danh sách thì sẽ áp dụng chiết khấu (phụ thu) cho tất cả đối tác. '");
	Else
		Items.GroupCounterparties.Visible = True;
		Items.WarehouseGroups.Visible = True;
		Items.GroupsWarehousesAndCounterparties.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		
		Items.DecorationHelpRecipients.Title = NStr("en='Complete the list of counterparties or warehouses if the discount (extra charge) will be provided only to a specific list of counterparties (wholesale)"
"or in certain warehouses (retail). If the list of counterparties (warehouses) is not completed, the discount (extra charge) will be provided to all counterparties (in all warehouses).';ru='Заполните список контрагентов или складов, если скидка (наценка) будет предоставляться только определённому списку контрагентов (опт)"
"или на определённых складах (розница). Если список контрагентов (складов) не заполнен, то скидка (наценка) будет предоставляться всем контрагентам (на всех складах).';vi='Hãy điền danh sách đối tác hoặc chiết khấu, nếu áp dụng chiết khấu (phụ thu) chỉ với danh sách đối tác cụ thể (bán buôn)"
"hoặc tại các kho cụ thể (bán lẻ). Nếu chưa điền danh sách đối tác (kho bãi) thì sẽ áp dụng chiết khấu (phụ thu) đối với tất cả đối tác (tại tất cả các kho).'");
	EndIf;

EndProcedure

#EndRegion