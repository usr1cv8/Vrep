////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateAfterAddTNFEA" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ТАБЛИЦЫ ФОРМЫ <Список>

&AtClient
Procedure ListBeforeAddRow(Item, cancel, Copy, Parent, Var_Group)
	
//	cancel = True;
//	
//	Text = NStr("en='Есть возможность подобрать товарную номенклатуру ВЭД из классификатора."
//"Подобрать?';ru='Есть возможность подобрать товарную номенклатуру ВЭД из классификатора."
//"Подобрать?';vi='Có thể chọn một mục hàng hóa ngoài hoạt động kinh doanh từ bảng mã hiệu."
//"Chọn?'");
//	
//	AdditionalParameters = New Structure;
//	If Copy Then
//		FillingValues = New Structure;
//		FillingValues.Insert("Code", Item.CurrentData.Code);
//		FillingValues.Insert("Description", Item.CurrentData.Description);
//		AdditionalParameters.Insert("FillingValues", FillingValues);
//	EndIf;
//	
//	Notification = New NotifyDescription("QuestionPickTNFEACompletion", ThisObject, AdditionalParameters);
//	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД ФОРМЫ

//&AtClient
//Procedure PickFromTemplate(Command)
//	
//	OpenForm("Catalog.TNFEAClassifier.Form.AddItemsToClassifier", , ThisForm);
//	
//EndProcedure

////////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

//&AtClient
//Procedure QuestionPickTNFEACompletion(Result, AdditionalParameters) Export
//	
//	If Result = DialogReturnCode.Yes Then
//		PickFromTemplate(Undefined);
//	Else
//		OpenForm("Catalog.TNFEAClassifier.Form.ItemForm", AdditionalParameters, ThisForm);
//	EndIf;
//	
//EndProcedure

