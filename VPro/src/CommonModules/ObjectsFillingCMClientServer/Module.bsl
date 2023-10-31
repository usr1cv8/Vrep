
#Region ServiceProgramInterface

// Заполняет реквизит строки табличной части по шапке. 
// 
// Parameters:
//  TSRow - FormDataStructure - Строка табличной части для заполнения.
//  DocumentObject - ДанныеФормы - Обрабатываемый документ.
//  FieldName - String - Имя заполняемого поля.
//  PositionFieldName - String - Имя поля текущего положения реквизита.
// 
Procedure FillRowByHeader(Val TSRow, Val DocumentObject, FieldName, PositionFieldName) Export
	
	If DocumentObject[PositionFieldName]=PredefinedValue("Enum.AttributePositionOnForm.InTabularSection") Then
		Return;
	EndIf; 
	
	TSRow[FieldName] = DocumentObject[FieldName];
	
EndProcedure

#EndRegion



 