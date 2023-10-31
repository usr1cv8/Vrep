#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then


#Region EventsHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Or Not ValueIsFilled(Parent) Then
		For Each AdditionalAttribute In AdditionalAttributes Do
			If AdditionalAttribute.PredefinedSetName <> PredefinedSetName Then
				AdditionalAttribute.PredefinedSetName = PredefinedSetName;
			EndIf;
		EndDo;
		
		For Each AdditionalInformationItem In AdditionalInformation Do
			If AdditionalInformationItem.PredefinedSetName <> PredefinedSetName Then
				AdditionalInformationItem.PredefinedSetName = PredefinedSetName;
			EndIf;
		EndDo;
	EndIf;
	
	If Not IsFolder Then
		// Удаление дублей и пустых строк.
		SelectedProperties = New Map;
		PropertiesToDelete = New Array;
		
		// Дополнительные реквизиты.
		For Each AdditionalAttribute In AdditionalAttributes Do
			
			If AdditionalAttribute.Property.IsEmpty()
			 Or SelectedProperties.Get(AdditionalAttribute.Property) <> Undefined Then
				
				PropertiesToDelete.Add(AdditionalAttribute);
			Else
				SelectedProperties.Insert(AdditionalAttribute.Property, True);
			EndIf;
		EndDo;
		
		For Each PropertyToDelete In PropertiesToDelete Do
			AdditionalAttributes.Delete(PropertyToDelete);
		EndDo;
		
		SelectedProperties.Clear();
		PropertiesToDelete.Clear();
		
		// Дополнительные сведения.
		For Each AdditionalInformationItem In AdditionalInformation Do
			
			If AdditionalInformationItem.Property.IsEmpty()
			 Or SelectedProperties.Get(AdditionalInformationItem.Property) <> Undefined Then
				
				PropertiesToDelete.Add(AdditionalInformationItem);
			Else
				SelectedProperties.Insert(AdditionalInformationItem.Property, True);
			EndIf;
		EndDo;
		
		For Each PropertyToDelete In PropertiesToDelete Do
			AdditionalInformation.Delete(PropertyToDelete);
		EndDo;
		
		// Вычисление количества свойств не помеченных на удаление.
		CountAttributes = Format(AdditionalAttributes.FindRows(
			New Structure("DeletionMark", False)).Count(), "NG=");
		
		CountInformation   = Format(AdditionalInformation.FindRows(
			New Structure("DeletionMark", False)).Count(), "NG=");
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then
		// Обновление состава верхней группы для использования при настройке
		// состава полей динамического списка и его настройки (отборы, ...).
		If ValueIsFilled(Parent) Then
			PropertiesManagementService.CheckRefreshContentFoldersProperties(Parent);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en='Invalid object call at client.';ru='Недопустимый вызов объекта на клиенте.';vi='Không thể gọi ra đối tượng trên Client.'");
#EndIf