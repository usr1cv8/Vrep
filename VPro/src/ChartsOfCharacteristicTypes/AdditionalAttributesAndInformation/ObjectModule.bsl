#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure OnCopy(CopiedObject)
	
	Title = "";
	Name       = "";
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If PropertiesManagementService.ValueTypeContainsPropertiesValues(ValueType) Then
		
		Query = New Query;
		Query.SetParameter("ValueOwner", Ref);
		Query.Text =
		"SELECT
		|	Properties.Ref AS Ref,
		|	Properties.ValueType AS ValueType
		|FROM
		|	ChartOfCharacteristicTypes.AdditionalAttributesAndInformation AS Properties
		|WHERE
		|	Properties.AdditionalValuesOwner = &ValueOwner";
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			NewValueType = Undefined;
			
			If ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
			   AND Not Selection.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
				
				NewValueType = New TypeDescription(
					Selection.ValueType,
					"CatalogRef.ObjectsPropertiesValues",
					"CatalogRef.ObjectsPropertiesValuesHierarchy");
				
			ElsIf ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy"))
			        AND Not Selection.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValuesHierarchy")) Then
				
				NewValueType = New TypeDescription(
					Selection.ValueType,
					"CatalogRef.ObjectsPropertiesValuesHierarchy",
					"CatalogRef.ObjectsPropertiesValues");
				
			EndIf;
			
			If NewValueType <> Undefined Then
				Block = New DataLock;
				LockItem = Block.Add("ChartOfCharacteristicTypes.AdditionalAttributesAndInformation");
				LockItem.SetValue("Ref", Selection.Ref);
				Block.Lock();
				
				CurrentObject = Selection.Ref.GetObject();
				CurrentObject.ValueType = NewValueType;
				CurrentObject.DataExchange.Load = True;
				CurrentObject.Write();
			EndIf;
		EndDo;
	EndIf;
	
	// Проверка, что изменение пометки удаления произведено не из списка.
	// Наборы дополнительных реквизитов и сведений.
	PropertiesOfObject = CommonUse.ObjectAttributesValues(Ref, "DeletionMark");
	Query = New Query;
	Query.Text =
		"SELECT
		|	TheSets.Ref AS Ref
		|FROM
		|	%1 КАК Properties
		|		LEFT JOIN Catalog.AdditionalAttributesAndInformationSets AS TheSets
		|		ON (Properties.Ref = TheSets.Ref)
		|WHERE
		|	Properties.Property = &Property
		|	AND Properties.DeletionMark <> &DeletionMark"; // ava1c КАК Свойства --> КАК Properties
	If ThisIsAdditionalInformation Then
		TableName = "Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation";
	Else
		TableName = "Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes";
	EndIf;
	Query.Text = StringFunctionsClientServer.SubstituteParametersInString(Query.Text, TableName);
	Query.SetParameter("Property", Ref);
	Query.SetParameter("DeletionMark", PropertiesOfObject.DeletionMark);
	
	Result = Query.Execute().Unload();
	
	For Each ResultRow In Result Do
		PropertiesSetObject = ResultRow.Ref.GetObject();
		If ThisIsAdditionalInformation Then
			FillPropertyValues(PropertiesSetObject.AdditionalInformation.Find(Ref, "Property"), PropertiesOfObject);
		Else
			FillPropertyValues(PropertiesSetObject.AdditionalAttributes.Find(Ref, "Property"), PropertiesOfObject);
		EndIf;
		
		PropertiesSetObject.Write();
	EndDo;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Property", Ref);
	Query.Text =
	"SELECT
	|	PropertiesSets.Ref AS Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets.AdditionalAttributes AS PropertiesSets
	|WHERE
	|	PropertiesSets.Property = &Property
	|
	|UNION ALL
	|
	|SELECT
	|	PropertiesSets.Ref
	|FROM
	|	Catalog.AdditionalAttributesAndInformationSets.AdditionalInformation AS PropertiesSets
	|WHERE
	|	PropertiesSets.Property = &Property";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Block = New DataLock;
		LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
		LockItem.SetValue("Ref", Selection.Ref);
		Block.Lock();
		
		CurrentObject = Selection.Ref.GetObject();
		// Delete  additional attributes.
		IndexOf = CurrentObject.AdditionalAttributes.Count()-1;
		While IndexOf >= 0 Do
			If CurrentObject.AdditionalAttributes[IndexOf].Property = Ref Then
				CurrentObject.AdditionalAttributes.Delete(IndexOf);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		// Delete additional info.
		IndexOf = CurrentObject.AdditionalInformation.Count()-1;
		While IndexOf >= 0 Do
			If CurrentObject.AdditionalInformation[IndexOf].Property = Ref Then
				CurrentObject.AdditionalInformation.Delete(IndexOf);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		If CurrentObject.Modified() Then
			CurrentObject.DataExchange.Load = True;
			CurrentObject.Write();
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region ServiceProgramInterface

Procedure OnReadPresentationsAtServer() Export
EndProcedure

#EndRegion

#Else
Raise NStr("en='Invalid object call at client.';ru='Недопустимый вызов объекта на клиенте.';vi='Không thể gọi ra đối tượng trên Client.'");
#EndIf
