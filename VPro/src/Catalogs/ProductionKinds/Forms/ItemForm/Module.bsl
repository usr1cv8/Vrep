
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure StagesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	If Not Clone Then
		
		Cancel = True;
		
		OpeninigAttr = New Structure;
		OpeninigAttr.Insert("ChoiceMode", True);
		OpeninigAttr.Insert("MultipleChoice", True);
		
		ОткрытьФорму("Catalog.ProductionStages.ChoiceForm", OpeninigAttr, Items.Stages, , , , , FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	For Each Stage In SelectedValue Do
		
		DataStructure = New Structure();
		DataStructure.Insert("Stage", Stage);
		ExistRows = Object.Stages.FindRows(DataStructure);
		If ExistRows.Count()<>0 Then
			Continue;
		EndIf; 
		
		NewRow = Object.Stages.Add();
		NewRow.Stage = Stage;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure StagesDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	ForbiddenChangeOrder = False;
	
	CurrentRow = Object.Stages.FindByID(DragParameters.Value);
	If CurrentRow <> Undefined
		And CurrentRow.Stage = PredefinedValue("Catalog.ProductionStages.ProductionComplete") Then
		ForbiddenChangeOrder = True;
	EndIf;
	
	If Not ForbiddenChangeOrder And Row <> Undefined Then
		DragRow = Object.Stages.FindByID(Row);
		If DragRow <> Undefined
			And DragRow.Stage = PredefinedValue("Catalog.ProductionStages.ProductionComplete") Then
			ForbiddenChangeOrder = True;
		EndIf;
	EndIf;
	
	If ForbiddenChangeOrder Then
		StandardProcessing = False;
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	CommonUseClient.ShowCommentEditingForm(Item.EditText, ThisObject, "Object.Comment");
EndProcedure

#EndRegion 

#Region CommandFormHandlers

&AtClient
Procedure SelectStages(Command)
	
	OpenParameters = New Structure;
	OpenParameters.Insert("ChoiceMode", True);
	OpenParameters.Insert("CloseOnChoice", False);
	OpenParameters.Insert("MultipleChoice", True);
	If Items.Stages.CurrentData <> Undefined  И ValueIsFilled(Items.Stages.CurrentData.Stage) Then
		OpenParameters.Insert("CurrentRow", Items.Stages.CurrentData.Stage);
	EndIf;
	OpenForm("Catalog.ProductionStages.ChoiceForm", OpenParameters, Items.Stages, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	CurrentRow = Items.Stages.CurrentData;
	If CurrentRow=Undefined Then
		Return;
	EndIf;
	Index = Object.Stages.Index(CurrentRow);
	If CurrentRow.Stage = PredefinedValue("Catalog.ProductionStages.ProductionComplete") OR Index=0 Then
		Return;
	EndIf; 
	
	Object.Stages.Move(Index, -1);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	CurrentRow = Items.Stages.CurrentData;
	If CurrentRow = Undefined Then
		Return;
	EndIF;
	Index = Object.Stages.Index(CurrentRow);
	If Index>=Object.Stages.Количество()-2 Then
		Return;
	EndIf;
	
	Object.Stages.Move(Index, 1);
	
EndProcedure

#EndRegion

#Region ManageFormOutside

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	NewConditionalAppearance = ConditionalAppearance.Items.Add();
	WorkWithForm.AddDataCompositionFilterItem(NewConditionalAppearance.Filter, "Object.Stages.Stage", Catalogs.ProductionStages.ProductionComplete);
	WorkWithForm.AddConditionalAppearanceField(NewConditionalAppearance, Items.StagesStage.Name);
	WorkWithForm.AddConditionalAppearanceElement(NewConditionalAppearance, "Font", New Font(New Font, , , True));
	
EndProcedure

#EndRegion
