
#Region InternalProceduresAndFunctions

// Только для внутреннего использования.
//
Function PredefinedPropertySets() Export
	
	Return Catalogs.AdditionalAttributesAndInformationSets.PredefinedPropertySets();
	
EndFunction

// Только для внутреннего использования.
//
Function PropertySetDescriptions() Export
	
	Return PropertiesManagementService.PropertySetDescriptions();
	
EndFunction

#EndRegion