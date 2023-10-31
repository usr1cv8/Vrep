
#Region ProgramInterface

Procedure PropertiesTableRefreshAdditionalAttributeDependencies(Form, Object = Undefined) Export
	
	Modified = True;
	
	If Not Form.Properties_UseProperties Then
		Return;
	EndIf;
	
	If Object = Undefined Then
		ObjectDescription = Form.Object;
	Else
		ObjectDescription = Object;
	EndIf;
	
	For Each DependentAttributeDescription In Form.Properties_DependentAdditionalAttributesDescription Do
		
		If DependentAttributeDescription.AccessibilityCondition <> Undefined Then
			
			If Not DependentAttributeDescription.Available Then
				Continue;
			EndIf;
			
			ParameterValues = DependentAttributeDescription.AccessibilityCondition.ParameterValues;
			Result = Eval(DependentAttributeDescription.AccessibilityCondition.ConditionCode);
			
			Rows = Form.Properties_TablePropertiesAndValues.FindRows(New Structure("Property", DependentAttributeDescription.Property));
			For Each Str In Rows Do
				Str.Available = Result;
			EndDo;
			
		EndIf;
		
		If DependentAttributeDescription.VisibilityCondition <> Undefined Then
			
			If Not DependentAttributeDescription.Visible Then
				Continue;
			EndIf;
			
			ParameterValues = DependentAttributeDescription.VisibilityCondition.ParameterValues;
			Result = Eval(DependentAttributeDescription.VisibilityCondition.ConditionCode);
			
			Rows = Form.Properties_TablePropertiesAndValues.FindRows(New Structure("Property", DependentAttributeDescription.Property));
			For Each Str In Rows Do
				Str.Visible = Result;
			EndDo;
			
		EndIf;
		
		If DependentAttributeDescription.RequiredFillingCondition <> Undefined Then
			
			If Not DependentAttributeDescription.FillObligatory Then
				Continue;
			EndIf;
			
			ParameterValues = DependentAttributeDescription.RequiredFillingCondition.ParameterValues;
			Result = Eval(DependentAttributeDescription.RequiredFillingCondition.ConditionCode);
			
			Rows = Form.Properties_TablePropertiesAndValues.FindRows(New Structure("Property", DependentAttributeDescription.Property));
			For Each Str In Rows Do
				Str.FillObligatory = Result;
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PropertiesTableBeforeDelete(Item, Cancel, Modified) Export
	
	Cancel = True;
	Item.CurrentData.Value = Item.CurrentData.PropertyValueType.AdjustValue(Undefined);
	Modified = True;
	
EndProcedure // PropertiesTableBeforeDelete()

Procedure PropertiesTable(Cancel) Export
	
	Cancel = True;
	
EndProcedure

#EndRegion