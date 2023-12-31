#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

// Function returns the structure with the parameters of selection processor
//
// It is used for caching
//
Procedure InformationAboutDocumentStructure(ParametersStructure) Export
	
	ParametersStructure = New Structure;
	
	For Each DataProcessorAttribute IN Metadata.DataProcessors.PickingSales.Attributes Do
		
		ParametersStructure.Insert(DataProcessorAttribute.Name);
		
	EndDo;
	
EndProcedure // SelectionParametersStructure()

// Returns the structure of the mandatory parameters
//
Function MandatoryParametersStructure()
	
	Return New Structure("Date, Company, ProductsAndServicesType, OwnerFormUUID", "Date", "Company", "Products and services type", "Unique identifier of the owner form");
	
EndFunction // MandatoryParametersStructure()

// Check a minimum level parameters filling
//
Procedure CheckParametersFilling(SelectionParameters, Cancel) Export
	Var Errors;
	
	MandatoryParametersStructure = MandatoryParametersStructure();
	
	For Each StructureItem IN MandatoryParametersStructure Do
		
		ValueParameters = Undefined;
		If Not SelectionParameters.Property(StructureItem.Key, ValueParameters) Then
			
			ErrorText = NStr("en='Required parameter (%1) required for opening of products and services selection form is missing.';ru='Отсутствует обязательный параметр (%1), необходимый для открытия формы подбора номенклатуры.';vi='Không có tham số bắt buộc (%1), cần để mở biểu mẫu chọn mặt hàng.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersInString(ErrorText, StructureItem.Value);
			
			CommonUseClientServer.AddUserError(Errors, , ErrorText, Undefined);
			
		ElsIf Not ValueIsFilled(ValueParameters) Then
			
			ErrorText = NStr("en='Required parameter (%1) required for opening of products and services selection form is filled in incorrectly.';ru='Неверно заполнен обязательный параметр (%1), необходимый для открытия формы подбора номенклатуры.';vi='Đã điền sai tham số bắt buộc (%1), cần thiết để mở biểu mẫu chọn mặt hàng.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersInString(ErrorText, StructureItem.Value);
			
			CommonUseClientServer.AddUserError(Errors, , ErrorText, Undefined);
			
		EndIf;
		
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors, Cancel);
	
EndProcedure // CheckParametersFilling()

// Function returns a full name of the selection form 
//
Function ChoiceFormFullName() Export
	
	Return "DataProcessor.PickingSales.Form.CartPriceBalanceReserveCharacteristic";
	
EndFunction // ChoiceFormFullName()

#EndRegion

#EndIf