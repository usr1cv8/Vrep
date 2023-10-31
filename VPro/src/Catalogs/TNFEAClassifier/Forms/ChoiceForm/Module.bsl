#Region ListFormTableEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, cancel, Copy, Parent, Var_Group, Parameter)
	
	cancel = True;
	
	CurData = Items.List.CurrentData;
	AdditionalParameters = New Structure;
	If Copy Then
		FillingValues = New Structure;
		FillingValues.Insert("Code", Item.CurrentData.Code);
		FillingValues.Insert("Description", Item.CurrentData.Description);
		AdditionalParameters.Insert("FillingValues", FillingValues);
	EndIf;
	
	Notification = New NotifyDescription("QuestionCompletion", ThisObject, AdditionalParameters);
	
	QuestionText = NStr("en='Есть возможность подобрать товарную номенклатуру ВЭД из классификатора."
"Подобрать?';ru='Есть возможность подобрать товарную номенклатуру ВЭД из классификатора."
"Подобрать?';vi='Có thể chọn một mục hàng hóa ngoài hoạt động kinh doanh từ bảng mã hiệu."
"Chọn?'");
	
	ShowQueryBox(Notification, QuestionText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure QuestionCompletion(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		PickFromTemplate(Undefined);
	Else
		OpenForm("Catalog.TNFEAClassifier.Form.ItemForm", AdditionalParameters, ThisForm);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure PickFromTemplate(Command)
	
	OpenForm("Catalog.TNFEAClassifier.Form.AddItemsToClassifier", , ThisForm, , , , ,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion