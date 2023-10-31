
// Function returns the flag that allows to edit the prices in documents for the user with the Sales profile enabled. 
//
Function AllowedEditDocumentPrices() Export

	Return IsInRole("FullRights") 
		OR IsInRole("EditDocumentPrices")
		OR Not IsInRole("AddChangeSalesSubsystem");
	
EndFunction

Function InfobaseUserWithFullAccess() Export

	Return IsInRole("FullRights");

EndFunction

// Функция возвращает признак, определяющий наличие права текущего пользователя к объекту метаданных
//
// Parameters:
//  Right			 - String	 - проверяемое право
//  MetadataObjectID - CatalogRef.MetadataObjectIDs, CatalogRef.ExtensionObjectIDs - идентификатор проверяемого объекта
// 
// Returns:
//  Boolean - право доступа текущего пользователя к объекту метаданных
//
Function HasAccessRight(Right, MetadataObjectID) Export
	
	Return AccessRight(Right, CommonUse.MetadataObjectByID(MetadataObjectID));
	
EndFunction