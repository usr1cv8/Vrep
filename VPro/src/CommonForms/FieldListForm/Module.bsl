
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("Mode", Mode) Or Not Parameters.Property("SchemaURL") Or Not Parameters.Property("SettingsAddress") Then
		Cancel = True;
		Return;
	EndIf;
	Parameters.Property("ExistingFields", ExistingFields);
	CloseOnChoice = True;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(Parameters.SchemaURL));
	Composer.LoadSettings(GetFromTempStorage(Parameters.SettingsAddress));
	
	SetConditionalAppearance();
	
	Fields.GetItems().Clear();
	If Mode="GroupFields" Then
		Title = NStr("en='Group fields';ru='Поля группировки';vi='Các trường gom nhóm'");
		AddGroupFields();
	ElsIf Mode="FieldSelection" Then
		Title = NStr("en='Selection fields';ru='Поля отбора';vi='Các trường chọn'");
		AddFilters();
	EndIf;
	
	If Parameters.Property("Title") Then
		Title = Parameters.Title;
	EndIf; 
	
EndProcedure

#EndRegion 

#Region FormItemEventsHandlers

&AtClient
Procedure FieldsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("NotifyAboutSelectionDelay", 0.1, True);
	
EndProcedure

&AtClient
Procedure NotifyAboutSelectionDelay()
	
	Str = Items.Fields.CurrentData;
	If Str=Undefined Or Str.NotSelect Then
		Return;
	EndIf; 
	NotifyChoice(Str.Field);
	
EndProcedure

#EndRegion 

#Region FormCommandsHandlers

&AtClient
Procedure Select(Command)
	
	Str = Items.Fields.CurrentData;
	If Str=Undefined Or Str.NotSelect Then
		Return;
	EndIf; 
	NotifyChoice(Str.Field);
	
EndProcedure

#EndRegion 

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Fields");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Fields.NotSelect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleDataColor);

EndProcedure

&AtServer
Procedure AddGroupFields()
	
	AvailableFields = Composer.Settings.GroupAvailableFields.Items;
	PreviousFieldName = ""; 
	For Each Field In AvailableFields Do
		If Field.Folder Or Field.Resource Then
			Continue;
		EndIf; 
		FieldName = String(Field.Field);
		If FieldName=PreviousFieldName Then
			Continue;
		EndIf; 
		If FieldName="DynamicPeriod" Then
			Continue;
		EndIf; 
		AttributesList = New ValueList;
		PreviousAttributeName = "";
		For Each Attribute In Field.Items Do
			If Attribute.Folder Then
				// Табличная часть
				Continue;
			EndIf; 
			AttributeName = TrimAll(String(Attribute.Field));
			If AttributeName=PreviousAttributeName Then
				Continue;
			EndIf; 
			If Not ExistingFields.FindByValue(AttributeName)=Undefined Then
				Continue;
			EndIf;
			If Not AttributesList.FindByValue(AttributeName)=Undefined Then
				Continue;
			EndIf; 
			AttributesList.Add(AttributeName, Attribute.Title);
			PreviousAttributeName = AttributeName;
		EndDo;
		InExisting = Not ExistingFields.FindByValue(FieldName)=Undefined;
		If InExisting And AttributesList.Count()=0 Then
			Continue;
		EndIf;
		StrField = Fields.GetItems().Add();
		StrField.Field = FieldName;
		StrField.Presentation = Field.Title;
		PreviousFieldName = FieldName;
		For Each ListElement In AttributesList Do
			StrAttribute = StrField.GetItems().Add();
			StrAttribute.Field = ListElement.Value;
			StrAttribute.Presentation = TextAfterDot(ListElement.Presentation, Field.Title);
			StrAttribute.Picture = 1;
		EndDo; 
		If InExisting Then
			StrField.NotSelect = True;
		EndIf;
		StrField.Picture = ?(StrField.NotSelect, 0, ?(Field.Resource, 2, 1))
	EndDo; 
	
EndProcedure

&AtServer
Procedure AddFilters()
	
	For Each Field In Composer.Settings.FilterAvailableFields.Items Do
		If Field.Folder Then
			Continue;
		EndIf;
		FieldName = String(Field.Field);
		If FieldName="DynamicPeriod" Then
			Continue;
		EndIf; 
		If TextAfterDot(FieldName)="Ref" Then
			Continue;
		EndIf; 
		InExisting = Not ExistingFields.FindByValue(FieldName)=Undefined;
		StrField = Fields.GetItems().Add();
		StrField.Field = FieldName;
		StrField.Presentation = Field.Title;
		SkipNested = False;
		If Field.ValueType.Types().Count()=1 And Enums.AllRefsType().ContainsType(Field.ValueType.Types().Get(0)) Then
			SkipNested = True;
		EndIf; 
		If Not SkipNested Then
			For Each Attribute In Field.Items Do
				AttributeName = TrimAll(String(Attribute.Field));
				If TextAfterDot(AttributeName, FieldName)="Ref" Then
					Continue;
				EndIf; 
				If Not ExistingFields.FindByValue(AttributeName)=Undefined Then
					Continue;
				EndIf;
				If Attribute.Folder And Right(AttributeName, 5)=".Tags" Then
					Continue;
				EndIf; 
				StrAttribute = StrField.GetItems().Add();
				StrAttribute.Field = AttributeName;
				StrAttribute.Presentation = StrReplace(Attribute.Title, Field.Title+".", "");
				If Attribute.Folder Then
					StrAttribute.Picture = 0;
					StrAttribute.NotSelect = True;
					For Each TSAttribute In Attribute.Items Do
						TSAttributeName = TrimAll(String(TSAttribute.Field));
						If Not ExistingFields.FindByValue(TSAttributeName)=Undefined Then
							Continue;
						EndIf; 
						If TextAfterDot(TSAttributeName, AttributeName)="Ref" Then
							Continue;
						EndIf; 
						StrTSAttribute = StrAttribute.GetItems().Add();
						StrTSAttribute.Field = TSAttributeName;
						StrTSAttribute.Presentation = StrReplace(TSAttribute.Title, Attribute.Title+".", "");
						StrTSAttribute.Picture = 1;
					EndDo; 
				Else
					StrAttribute.Picture = 1;
				EndIf;  
			EndDo; 
		EndIf; 
		If InExisting And StrField.GetItems().Count() = 0 Then
			Fields.GetItems().Delete(StrField);
			Continue;
		ElsIf InExisting Then
			StrField.NotSelect = True;
		EndIf;
		ComboBox = Composer.Settings.SelectionAvailableFields.FindField(Field.Field);
		StrField.Picture = ?(StrField.NotSelect, 0, ?(Not ComboBox=Undefined And ComboBox.Resource, 2, 1))
	EndDo; 
	
EndProcedure

&AtServer
Function TextAfterDot(Val Text, Val TextParent = "")
	
	If IsBlankString(TextParent) Then
		Return Text;
	EndIf; 
	Return StrReplace(Text, TextParent+".", "");
	
EndFunction

#EndRegion
 

 