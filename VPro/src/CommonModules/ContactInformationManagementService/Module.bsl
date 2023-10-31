////////////////////////////////////////////////////////////////////////////////////////////////////
// The Contact information subsystem.
// 
////////////////////////////////////////////////////////////////////////////////////////////////////

#Region ServiceProgramInterface

// Returns enumeration value type of the contact information kind.
//
//  Parameters:
//    InformationKind - CatalogRef.ContactInformationTypes, Structure - data source.
//
Function TypeKindContactInformation(Val InformationKind) Export
	Result = Undefined;
	
	Type = TypeOf(InformationKind);
	If Type = Type("EnumRef.ContactInformationTypes") Then
		Result = InformationKind;
	ElsIf Type = Type("CatalogRef.ContactInformationKinds") Then
		Result = InformationKind.Type;
	ElsIf InformationKind <> Undefined Then
		Data = New Structure("Type");
		FillPropertyValues(Data, InformationKind);
		Result = Data.Type;
	EndIf;
	
	Return Result;
EndFunction

// Define the list of catalogs available for import using the Import data from file subsystem.
//
// Parameters:
//  Handlers - ValueTable - list of catalogs, to which the data can be imported.
//      * FullName          - String - full name of the catalog (as in the metadata).
//      * Presentation      - String - presentation of the catalog in the selection list.
//      *AppliedImport - Boolean - if True, then the catalog uses its own
//                                      importing algorithm and the functions are defined in the catalog manager module.
//
Procedure OnDetermineCatalogsForDataImport(ImportedCatalogs) Export
	
	// Import to countries classifier is denied.
	TableRow = ImportedCatalogs.Find(Metadata.Catalogs.WorldCountries.FullName(), "FullName");
	If TableRow <> Undefined Then 
		ImportedCatalogs.Delete(TableRow);
	EndIf;
	
EndProcedure

// Define metadata objects in the managers modules of which
// the ability to edit attributes is restricted using the GetLockedOjectAttributes export function.
//
// Parameters:
//   Objects - Map - specify the full name of the metadata
//                            object as a key connected to the Deny editing objects attributes subsystem. 
//                            As a value - empty row.
//
Procedure OnDetermineObjectsWithLockedAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.ContactInformationKinds.FullName(), "");
	
EndProcedure

// Define metadata objects in which modules managers it is restricted to edit attributes on bulk edit.
//
// Parameters:
//   Objects - Map - as a key specify the full name
//                            of the metadata object that is connected to the "Group object change" subsystem. 
//                            Additionally, names of export functions can be listed in the value:
//                            "UneditableAttributesInGroupProcessing",
//                            "EditableAttributesInGroupProcessing".
//                            Each name shall begin with a new row.
//                            If an empty row is specified, then both functions are defined in the manager module.
//
Procedure WhenDefiningObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.ContactInformationKinds.FullName(), "NotEditableInGroupProcessingAttributes");
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

#Region InfobaseUpdate

// Adds the update procedure-handlers necessary for the subsystem.
//
// Parameters:
//  Handlers - ValueTable - see NewUpdateHandlersTable
//                                  function description of InfobaseUpdate common module.
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	// Countries of the world separation
	If CommonUseReUse.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.Version    = "2.1.4.8";
		Handler.Procedure = "ContactInformationManagementService.SeparatedCountriesReferencePreparation";
		Handler.ExclusiveMode = True;
		Handler.SharedData      = True;
		
		Handler = Handlers.Add();
		Handler.Version    = "2.1.4.8";
		Handler.Procedure = "ContactInformationManagementService.UpdateBySeparatedCountriesReference";
		Handler.ExclusiveMode = True;
		Handler.SharedData      = False;
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version    = "2.2.3.34";
	Handler.Procedure = "ContactInformationManagementService.UpdateExistingCountries";
	Handler.PerformModes = "Exclusive";
	Handler.SharedData      = False;
	Handler.InitialFilling = True;
	
EndProcedure

// Undivided exclusive handler helps to copy countries from the null area.
// Saves a reference and data areas list - recipients.
//
Procedure PreparationStandardDividedCountriesOfWorld() Export
	
	// Base version control
	ModelRegisterName = "DeleteWorldCountries";
	If Metadata.InformationRegisters.Find(ModelRegisterName) = Undefined Then
		Return;
	EndIf;
	
	If Not CommonUse.SubsystemExists("StandardSubsystems.SaaS") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// Request for data from the null area, create a reference accurate to reference.
	CommonUse.SetSessionSeparation(True, 0);
	Query = New Query("
		|SELECT 
		|	Catalog.Ref             AS Ref,
		|	Catalog.Code                AS Code,
		|	Catalog.Description       AS Description,
		|	Catalog.AlphaCode2          AS AlphaCode2,
		|	Catalog.AlphaCode3          AS AlphaCode3, 
		|	Catalog.DescriptionFull AS DescriptionFull
		|FROM
		|	Catalog.WorldCountries AS Catalog
		|");
	Prototype = Query.Execute().Unload();
	
	CommonUse.SetSessionSeparation(False);
	
	// Write reference
	Set = InformationRegisters[ModelRegisterName].CreateRecordSet();
	Set.Add().Value = New ValueStorage(Prototype, New Deflation(9));
	InfobaseUpdate.WriteData(Set);
	
EndProcedure

// Separated  handler to copy countries from the null area.
// Use the reference prepared in the previous step.
//
Procedure RefreshEnabledMatchesSeparatedByCountries() Export
	
	// Base version control
	ModelRegisterName = "DeleteWorldCountries";
	If Metadata.InformationRegisters.Find(ModelRegisterName) = Undefined Then
		Return;
	EndIf;
	
	// Find reference for the current area.
	Query = New Query("
		|SELECT
		|	Prototype.Value
		|FROM
		|	InformationRegister.DeleteWorldCountries AS Prototype
		|WHERE
		|	Prototype.DataArea = 0
		|");
	Result = Query.Execute().Select();
	If Not Result.Next() Then
		Return;
	EndIf;
	Prototype = Result.Value.Get();
	
	Query = New Query("
		|SELECT
		|	Data.Ref             AS Ref,
		|	Data.Code                AS Code,
		|	Data.Description       AS Description,
		|	Data.AlphaCode2          AS AlphaCode2,
		|	Data.AlphaCode3          AS AlphaCode3, 
		|	Data.DescriptionFull AS DescriptionFull
		|INTO
		|	Prototype
		|FROM
		|	&Data AS Data
		|INDEX BY
		|	Ref
		|;///////////////////////////////////////////////////////////////////
		|SELECT 
		|	Prototype.Ref             AS Ref,
		|	Prototype.Code                AS Code,
		|	Prototype.Description       AS Description,
		|	Prototype.AlphaCode2          AS AlphaCode2,
		|	Prototype.AlphaCode3          AS AlphaCode3, 
		|	Prototype.DescriptionFull AS DescriptionFull
		|FROM
		|	Prototype AS Prototype
		|LEFT JOIN
		|	Catalog.WorldCountries AS WorldCountries
		|ON
		|	WorldCountries.Ref = Prototype.Ref
		|WHERE
		|	WorldCountries.Ref IS NULL
		|");
	Query.SetParameter("Data", Prototype);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Country = Catalogs.WorldCountries.CreateItem();
		Country.SetNewObjectRef(Selection.Ref);
		FillPropertyValues(Country, Selection, , "Ref");
		InfobaseUpdate.WriteData(Country);
	EndDo;
	
EndProcedure

// Compulsorily import all countries from the classifier.
//
Procedure ImportWorldCountries() Export
	Catalogs.WorldCountries.UpdateWorldCountriesByClassifier(True);
EndProcedure

// Update only existing items of countries by a classifier.
Procedure UpdateExistingCountries() Export
	
	Catalogs.WorldCountries.UpdateWorldCountriesByClassifier();
	
EndProcedure

#EndRegion

#Region InteractionWithAddressClassifier

// Returns a list of all states of an address classifier.
//
// Returns:
//   ValueTable - contains columns.:
//      * RFTerritorialEntityCode - Number                   - State code.
//      * Identifier - UUID - State identifier.
//      * Presentation - String                  - State description and abbreviation.
//      * Imported     - Boolean                  - True if the classifier by this state is imported.
//      * VersionDate    - Date                    - UTC version of the imported data.
//   Undefined    - if there is no subsystem of an address classifier.
// 
Function AllStates() Export
	
	Return Undefined;
	
EndFunction

//  Returns state name by its code.
//
//  Parameters:
//      Code - String, Number - state code.
//
// Returns:
//      String - full name of state with abbreviation.
//      Undefined - if there is no subsystem of address classifier.
// 
Function StateOfCode(Val Code)
	
	//Address classifier is not available
	Return Undefined;
	
EndFunction

#EndRegion

#Region CommonServiceProceduresAndFunctions

// Updates the fields of contact information from ValuesTable (for example, object of another catalog kind).
//
// Parameters:
//    Source - ValueTable - values table with contact information.
//    Receiver - ManagedForm - object form. where a contact information should be passed.
//
Procedure FillContactInformation(Source, Receiver) Export
	ContactInformationFieldsCollection = Receiver.ContactInformationAdditionalAttributeInfo;
	
	For Each ItemContactInformationFieldsCollection In ContactInformationFieldsCollection Do
		
		StringVKI = Source.Find(ItemContactInformationFieldsCollection.Type, "Kind");
		If StringVKI <> Undefined Then
			Receiver[ItemContactInformationFieldsCollection.AttributeName] = StringVKI.Presentation;
			ItemContactInformationFieldsCollection.FieldsValues          = ContactInformationManagementClientServer.ConvertStringToFieldList(StringVKI.FieldsValues);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns en empty address structure.
//
// Returns:
//    Structure - address description, keys - fields names, field values.
//
Function GetEmptyAddressStructure() Export
	
	Return ContactInformationManagementClientServer.AddressFieldsStructure();
	
EndFunction

// Get values of an address field.
// 
// Parameters:
//    FieldValueString - String - address fields values.
//    FieldName             - String - field name. For example, Region.
// 
// Returns:
//  String - field value.
//
Function GetAddressFieldValue(FieldValueString, FieldName) Export
	
	FieldPosition = Find(FieldValueString, FieldName);
	Value = "";
	If FieldPosition <> 0 Then
		FieldsValues = Right(FieldValueString, StrLen(FieldValueString) - FieldPosition - StrLen(FieldName));
		LFPosition = Find(FieldsValues, Chars.LF);
		Value = Mid(FieldsValues, 0 ,LFPosition - 1);
	EndIf;
	Return Value;
	
EndFunction

// Receives values of an address field.
//
// Parameters:
//    FieldValueString - String - fields values row.
//    FieldName             - String - field name.
//
// Returns - String - contact information value.
//
Function GetContactInformationValue(FieldValueString, FieldName) Export
	
	FieldPosition = Find(FieldValueString, FieldName);
	Value = "";
	If FieldPosition <> 0 Then
		FieldsValues = Right(FieldValueString, StrLen(FieldValueString) - FieldPosition - StrLen(FieldName));
		LFPosition   = Find(FieldsValues, Chars.LF);
		Value    = Mid(FieldsValues, 0 , LFPosition - 1);
	EndIf;
	
	Return Value;
	
EndFunction

Function EventLogMonitorEvent() Export
	
	Return NStr("en='Contact information';ru='Контактная информация';vi='Thông tin liên hệ'", CommonUseClientServer.MainLanguageCode());
	
EndFunction

// Converts XML to XDTO object of contact information.
//
//  Parameters:
//      Text            - String - XML row of a contact information.
//      ExpectedKind     - CatalogRef.ContactInformationTypes, EnumRef.ContactInformationTypes,
//      Structure ConversionResult - Structure - if it is specified, then the information is written to properties:
//        * ErrorText - String - reading errors description. In this case the return value
// of the function will be of a correct type but unfilled.
//
// Returns:
//      XDTODataObject - contact information corresponding to the ContactInformation XDTO-pack.
//   
Function ContactInformationFromXML(Val Text, Val ExpectedKind = Undefined, ConvertingResult = Undefined) Export
	
	ExpectedType = TypeKindContactInformation(ExpectedKind);
	
	EnumerationAddress                 = Enums.ContactInformationTypes.Address;
	EnumEmailAddress = Enums.ContactInformationTypes.EmailAddress;
	EnumerationWebPage           = Enums.ContactInformationTypes.WebPage;
	EnumerationPhone               = Enums.ContactInformationTypes.Phone;
	EnumFax                  = Enums.ContactInformationTypes.Fax;
	EnumerationAnother                = Enums.ContactInformationTypes.Other;
	
	TargetNamespace = ContactInformationManagementClientServerReUse.TargetNamespace();
	If ContactInformationClientServer.IsXMLString(Text) Then
		XMLReader = New XMLReader;
		XMLReader.SetString(Text);
		
		ErrorText = Undefined;
		Try
			Result = XDTOFactory.ReadXML(XMLReader, XDTOFactory.Type(TargetNamespace, "ContactInformation"));
		Except
			// Incorrect XML format
			WriteLogEvent(EventLogMonitorEvent(),
				EventLogLevel.Error, , Text, DetailErrorDescription(ErrorInfo()));
			
			If TypeOf(ExpectedKind) = Type("CatalogRef.ContactInformationKinds") Then
				ErrorText = StrReplace(NStr("en='Incorrect XML format of contact information for ""%1"". Field values were cleared.';ru='Некорректный формат XML контактной информации для ""%1"", значения полей были очищены.';vi='Thông tin liên hệ có định dạng XML không chính xác đối với ""%1"", giá trị của trường đã bị xóa.'"),
					"%1", String(ExpectedKind));
			Else
				ErrorText = NStr("en='Incorrect XML format of contact information. Field values were cleared.';ru='Некорректный формат XML контактной информации, значения полей были очищены.';vi='Thông tin liên hệ có định dạng XML không chính xác, giá trị các trường đã bị xóa.'");
			EndIf;
		EndTry;
		
		If ErrorText = Undefined Then
			// Control types match.
			IsFoundType = ?(Result.Content = Undefined, Undefined, Result.Content.Type());
			If ExpectedType = EnumerationAddress AND IsFoundType <> XDTOFactory.Type(TargetNamespace, "Address") Then
				ErrorText = NStr("en='An error occurred when deserializing the contact information, address is expected';ru='Ошибка десериализации контактной информации, ожидается адрес';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính địa chỉ'");
			ElsIf ExpectedType = EnumEmailAddress AND IsFoundType <> XDTOFactory.Type(TargetNamespace, "Email") Then
				ErrorText = NStr("en='An error occurred when deserializing the contact information, email address is expected';ru='Ошибка десериализации контактной информации, ожидается адрес электронной почты';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính địa chỉ email'");
			ElsIf ExpectedType = EnumerationWebPage AND IsFoundType <> XDTOFactory.Type(TargetNamespace, "WebSite") Then
				ErrorText = NStr("en='An error occurred when deserializing the contact information, web page is expected';ru='Ошибка десериализации контактной информации, ожидается веб-страница';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính trang web'");
			ElsIf ExpectedType = EnumerationPhone AND IsFoundType <> XDTOFactory.Type(TargetNamespace, "PhoneNumber") Then
				ErrorText = NStr("en='An error occurred when deserializing the contact information, phone number is expected';ru='Ошибка десериализации контактной информации, ожидается телефон';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính điện thoại'");
			ElsIf ExpectedType = EnumFax AND IsFoundType <> XDTOFactory.Type(TargetNamespace, "FaxNumber") Then
				ErrorText = NStr("en='An error occurred when deserializing the contact information, phone number is expected';ru='Ошибка десериализации контактной информации, ожидается телефон';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính điện thoại'");
			ElsIf ExpectedType = EnumerationAnother AND IsFoundType <> XDTOFactory.Type(TargetNamespace, "Other") Then
				ErrorText = NStr("en='Contact information deserialization error. Other data is expected.';ru='Ошибка десериализации контактной информации, ожидается ""другое""';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính ""khác""'");
			EndIf;
		EndIf;
		
		If ErrorText = Undefined Then
			// Read successfully
			Return Result;
		EndIf;
		
		// Check a mistake and return an extended information.
		If ConvertingResult = Undefined Then
			Raise ErrorText;
		ElsIf TypeOf(ConvertingResult) <> Type("Structure") Then
			ConvertingResult = New Structure;
		EndIf;
		ConvertingResult.Insert("ErrorText", ErrorText);
		
		// An empty object will be returned.
		Text = "";
	EndIf;
	
	If TypeOf(Text) = Type("ValueList") Then
		Presentation = "";
		IsNew = Text.Count() = 0;
	Else
		Presentation = String(Text);
		IsNew = IsBlankString(Text);
	EndIf;
	
	Result = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "ContactInformation"));
	
	// Parsing
	If ExpectedType = EnumerationAddress Then
		If IsNew Then
			Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "Address"));
		Else
			Result = XMLBXDTOAddress(Text, Presentation, ExpectedType);
		EndIf;
		
	ElsIf ExpectedType = EnumerationPhone Then
		If IsNew Then
			Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "PhoneNumber"));
		Else
			Result = DeserializationPhone(Text, Presentation, ExpectedType)
		EndIf;
		
	ElsIf ExpectedType = EnumFax Then
		If IsNew Then
			Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "FaxNumber"));
		Else
			Result = DeserializingFax(Text, Presentation, ExpectedType)
		EndIf;
		
	ElsIf ExpectedType = EnumEmailAddress Then
		If IsNew Then
			Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "Email"));
		Else
			Result = DeserializationOfOtherContactInformation(Text, Presentation, ExpectedType)
		EndIf;
		
	ElsIf ExpectedType = EnumerationWebPage Then
		If IsNew Then
			Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "WebSite"));
		Else
			Result = DeserializationOfOtherContactInformation(Text, Presentation, ExpectedType)
		EndIf;
		
	ElsIf ExpectedType = EnumerationAnother Then
		If IsNew Then
			Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "Other"));
		Else
			Result = DeserializationOfOtherContactInformation(Text, Presentation, ExpectedType)    
		EndIf;
		
	Else
		Raise NStr("en='An error occurred while deserializing contact information, the expected type is not specified';ru='Ошибка десериализации контактной информации, не указан ожидаемый тип';vi='Lỗi trình tự của thông tin liên hệ, chưa chỉ ra kiểu mong muốn'");
	EndIf;
	
	Return Result;
EndFunction

// Converts a row to XDTO address contact information.
//
//  Parameters:
//      FieldsValues - String - serialized information, fields values.
//      Presentation - String - junior-senior presentation used to try parsing
//                               if FieldValues is empty.
//      ExpectedType  - EnumRef.ContactInformationTypes - optional type for control.
//
//  Returns:
//      XDTODataObject  - contact information.
//
Function XMLBXDTOAddress(Val FieldsValues, Val Presentation = "", Val ExpectedType = Undefined) Export
	
	ValueType = TypeOf(FieldsValues);
	ParseOnFields = (ValueType = Type("ValueList") Or ValueType = Type("Structure") 
		Or (ValueType = Type("String") AND Not IsBlankString(FieldsValues)));
	If ParseOnFields Then
		// Disassemble from fields values.
		Return AddressDeserializationCommon(FieldsValues, Presentation, ExpectedType);
	EndIf;
	
	//Address classifier is not available
	
	// Empty object with a presentation.
	TargetNamespace = ContactInformationManagementClientServerReUse.TargetNamespace();
	Result = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "ContactInformation"));
	Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "Address"));
	Result.Presentation = Presentation;
	Return Result;
	
EndFunction

// Converts a row to XDTO phone contact information.
//
//      FieldsValues - String - serialized information, fields values.
//      Presentation - String - junior-senior presentation used to try parsing
//                               if FieldValues is empty.
//      ExpectedType  - EnumRef.ContactInformationTypes - optional type for control.
//
//  Returns:
//      XDTODataObject  - contact information.
//
Function DeserializationPhone(FieldsValues, Presentation = "", ExpectedType = Undefined) Export
	Return DeserializationPhoneFax(FieldsValues, Presentation, ExpectedType);
EndFunction

// Converts a row to XDTO Fax contact information.
//
//      FieldsValues - String - serialized information, fields values.
//      Presentation - String - junior-senior presentation used to try parsing
//                               if FieldValues is empty.
//      ExpectedType  - EnumRef.ContactInformationTypes - optional type for control.
//
//  Returns:
//      XDTODataObject  - contact information.
//
Function DeserializingFax(FieldsValues, Presentation = "", ExpectedType = Undefined) Export
	Return DeserializationPhoneFax(FieldsValues, Presentation, ExpectedType);
EndFunction

// Converts a row to XDTO other contact information.
//
// Parameters:
//   FieldsValues - String - serialized information, fields values.
//   Presentation - String - junior-senior presentation used to try parsing if FieldValues is empty.
//   ExpectedType  - EnumRef.ContactInformationTypes - optional type for control.
//
// Returns:
//   XDTODataObject  - contact information.
//
Function DeserializationOfOtherContactInformation(FieldsValues, Presentation = "", ExpectedType = Undefined) Export
	
	If ContactInformationClientServer.IsXMLString(FieldsValues) Then
		// General format of a contact information.
		Return ContactInformationFromXML(FieldsValues, ExpectedType);
	EndIf;
	
	TargetNamespace = ContactInformationManagementClientServerReUse.TargetNamespace();
	Result = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "ContactInformation"));
	Result.Presentation = Presentation;
	
	If ExpectedType = Enums.ContactInformationTypes.EmailAddress Then
		Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "Email"));
		
	ElsIf ExpectedType = Enums.ContactInformationTypes.WebPage Then
		Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "WebSite"));
		
	ElsIf ExpectedType = Enums.ContactInformationTypes.Other Then
		Result.Content = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "Other"));
		
	ElsIf ExpectedType <> Undefined Then
		Raise NStr("en='An error occurred when deserializing the contact information, another type is expected';ru='Ошибка десериализации контактной информации, ожидается другой тип';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính kiểu khác'");
		
	EndIf;
	
	Result.Content.Value = Presentation;
	
	Return Result;
	
EndFunction

//  Returns the check box showing that a passed address - Russian.
//
//  Parameters:
//      XDTOAddress - XDTODataObject - Contact information or XDTO addresses.
//
//  Returns:
//      Boolean - checking result.
//
Function ItsRussianAddress(XDTOAddress) Export
	Return RussianAddress(XDTOAddress) <> Undefined;
EndFunction

//  Returns an extracted XDTO of Russian address or Undefined for a foreign address.
//
//  Parameters:
//      InformationObject - XDTODataObject - Contact information or XDTO addresses.
//
//  Returns:
//      XDTODataObject - Russian address.
//      Undefined - there is no Russian address.
//
Function RussianAddress(InformationObject) Export
	Result = Undefined;
	XDTOType   = Type("XDTODataObject");
	
	If TypeOf(InformationObject) = XDTOType Then
		TargetNamespace = ContactInformationManagementClientServerReUse.TargetNamespace();
		
		If InformationObject.Type() = XDTOFactory.Type(TargetNamespace, "ContactInformation") Then
			Address = InformationObject.Content;
		Else
			Address = InformationObject;
		EndIf;
		
		If TypeOf(Address) = XDTOType AND Address.Type() = XDTOFactory.Type(TargetNamespace, "Address") Then
			Address = Address.Content;
		EndIf;
		
		If TypeOf(Address) = XDTOType AND Address.Type() = XDTOFactory.Type(TargetNamespace, "AddressRF") Then
			Result = Address;
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

// Returns values of the 90(additional item) and 91(subordinate) levels from the address.
//
Function AdditionalItemsValues(Val XDTOAddress) Export
	
	Result = New Structure("AdditionalItem, SubordinateItem");
	
	AddressRF = RussianAddress(XDTOAddress);
	If AddressRF = Undefined Then
		Return Result;
	EndIf;
	
	
	AdditionalAddressItem = FindAdditionalAddressItem(AddressRF);

	Result.AdditionalItem = AdditionalAddressItem;
	Result.SubordinateItem = AdditionalAddressItem(AddressRF, ContactInformationManagementClientServerReUse.AddressingAdditionalObjectXPath(91));
	
	Return Result;
	
EndFunction

//  Reads and sets address postal code.
//
//  Parameters:
//      XDTOAddress     - XDTODataObject - Contact information or XDTO addresses.
//      NewValue - String     - set value.
//
//  Returns:
//      String - postal index.
//
Function PostalIndexOfAddresses(XDTOAddress, NewValue = Undefined) Export
	
	AddressRF = RussianAddress(XDTOAddress);
	If AddressRF = Undefined Then
		Return Undefined;
	EndIf;
	
	If NewValue = Undefined Then
		// Read
		Result = AddressRF.Get( ContactInformationManagementClientServerReUse.XMailPathIndex() );
		If Result <> Undefined Then
			Result = Result.Value;
		EndIf;
		Return Result;
	EndIf;
	
	// Record
	CodeIndex = ContactInformationManagementClientServerReUse.SerializationCodePostalIndex();
	
	WriteIndex = AddressRF.Get(ContactInformationManagementClientServerReUse.XMailPathIndex());
	If WriteIndex = Undefined Then
		WriteIndex = AddressRF.AddEMailAddress.Add( XDTOFactory.Create(XDTOAddress.AddEMailAddress.OwningProperty.Type) );
		WriteIndex.TypeAdrEl = CodeIndex;
	EndIf;
	
	WriteIndex.Value = NewValue;
	Return NewValue;
EndFunction

// Reads an additional address item by its path.
//
//  Parameters:
//      XDTOAddress     - XDTODataObject - Contact information or XDTO addresses.
//      ItemXPath -  String - Path to item.
//
//  Returns:
//      String - field item.
Function AdditionalAddressItem(XDTOAddress, ItemXPath) Export
	
	AddressRF = RussianAddress(XDTOAddress);
	If AddressRF = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = AddressRF.Get(ItemXPath);
	If Result <> Undefined Then
		Return Result.Value;
	EndIf;
	
	Return Result;
EndFunction

// Returns additional addresses.
//
Function FindAdditionalAddressItem(AddressRF) Export
	AdditionalAddressItem = Undefined;
	
	AdditionalAddressItem = AdditionalAddressItem(AddressRF, ContactInformationManagementClientServerReUse.AddressingAdditionalObjectXPath(90, "SNT"));
	If AdditionalAddressItem = Undefined Then
		AdditionalAddressItem = AdditionalAddressItem(AddressRF, ContactInformationManagementClientServerReUse.AddressingAdditionalObjectXPath(90, "GSK"));
	EndIf;
	If AdditionalAddressItem = Undefined Then
		AdditionalAddressItem = AdditionalAddressItem(AddressRF, ContactInformationManagementClientServerReUse.AddressingAdditionalObjectXPath(90, "TER"));
	EndIf;
	If AdditionalAddressItem = Undefined Then
		AdditionalAddressItem = AdditionalAddressItem(AddressRF, ContactInformationManagementClientServerReUse.AddressingAdditionalObjectXPath(90));
	EndIf;
	
	Return AdditionalAddressItem;

EndFunction

// Local exceptions during an address check.
//
Function ExcludeTestHomeInAddress(Val AddressRF)
	Result = False;
	
	// In Zelenograd a block without house/ownership can be specified.
	If Upper(TrimAll(AddressRF.RFTerritorialEntity)) = NStr("en='MOSCOW';ru='МОСКВА Г';vi='TP. MATXCOVA'") AND Upper(TrimAll(AddressRF.City)) = NStr("en='ZELENOGRAD';ru='ЗЕЛЕНОГРАД Г';vi='TP. ZELENOGRAD'") Then
		Result = True;
	EndIf;
		
	Return Result;
EndFunction

// Local exceptions during an address check.
//
Function CheckOutStreetsInAddress(Val AddressRF)
	Result = False;
	
	// Do not check the streets in Zelenograd.
	If Upper(TrimAll(AddressRF.RFTerritorialEntity)) = NStr("en='MOSCOW';ru='МОСКВА Г';vi='TP. MATXCOVA'") AND Upper(TrimAll(AddressRF.City)) = NStr("en='ZELENOGRAD';ru='ЗЕЛЕНОГРАД Г';vi='TP. ZELENOGRAD'") Then
		Result = True;
	EndIf;
	
	// Additional items of the address may be without streets.
	AdditionalItems = AdditionalItemsValues(AddressRF);
	If ValueIsFilled(AdditionalItems.AdditionalItem) Then
		Result = True;
	EndIf;
		
	Return Result;
EndFunction

//  Returns an array of states names - federal cities.
Function CityNamesFederalValues() Export
	
	Result = New Array;
	Result.Add("MOSCOW C");
	Result.Add("SAINT-PETERSBURG C");
	Result.Add("SEVASTOPOL C");
	Result.Add("BAIKONUR C");
	
	Return Result;
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctionsForCompatibility

Function GroupOfErrorsOfAddress(ErrorType, Message)
	Return New Structure("ErrorType, Message, Fields", ErrorType, Message, New Array);
EndFunction

Procedure AddErrorFillAddresses(Group, FieldName = "", Message = "", FieldEssence = "")
	Group.Fields.Add(New Structure("FieldName, Message, FieldEssence", FieldName, Message, FieldEssence));
EndProcedure

// Values table constructor.
//
Function ValueTable(ListColumns, ListOfIndexes = "")
	ResultTable = New ValueTable;
	
	For Each KeyValue In (New Structure(ListColumns)) Do
		ResultTable.Columns.Add(KeyValue.Key);
	EndDo;
	
	RowsIndex = StrReplace(ListOfIndexes, "|", Chars.LF);
	For PostalCodeNumber = 1 To StrLineCount(RowsIndex) Do
		IndexColumns = TrimAll(StrGetLine(RowsIndex, PostalCodeNumber));
		For Each KeyValue In (New Structure(IndexColumns)) Do
			ResultTable.Indexes.Add(KeyValue.Key);
		EndDo;
	EndDo;
	
	Return ResultTable;
EndFunction

// Inner for serialization.
Function AddressDeserializationCommon(Val FieldsValues, Val Presentation, Val ExpectedType = Undefined)
	
	If ContactInformationClientServer.IsXMLString(FieldsValues) Then
		// General format of a contact information.
		Return ContactInformationFromXML(FieldsValues, ExpectedType);
	EndIf;
	
	If ExpectedType <> Undefined Then
		If ExpectedType <> Enums.ContactInformationTypes.Address Then
			Raise NStr("en='An error occurred when deserializing the contact information, address is expected';ru='Ошибка десериализации контактной информации, ожидается адрес';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính địa chỉ'");
		EndIf;
	EndIf;
	
	// An old format through rows delimiter and equality.
	TargetNamespace = ContactInformationManagementClientServerReUse.TargetNamespace();
	
	Result = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "ContactInformation"));
	
	Result.Comment = "";
	Result.Content      = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "Address"));
	
	AddressRussian = True;
	NameOfRussia  = Upper(Catalogs.WorldCountries.Russia.Description);
	
	ItemApartment = Undefined;
	ItemBlock   = Undefined;
	ItemHouse      = Undefined;
	
	// Russian
	AddressRF = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "AddressRF"));
	
	// Common content
	Address = Result.Content;
	
	TypeValuesFields = TypeOf(FieldsValues);
	If TypeValuesFields = Type("ValueList") Then
		FieldList = FieldsValues;
	ElsIf TypeValuesFields = Type("Structure") Then
		FieldList = ContactInformationManagementClientServer.ConvertStringToFieldList(
			ContactInformationManagementClientServer.FieldsRow(FieldsValues, False));
	Else
		// Already converted to a row
		FieldList = ContactInformationManagementClientServer.ConvertStringToFieldList(FieldsValues);
	EndIf;
	
	ApartmentTypeUndefined = True;
	BlockTypeUndefined  = True;
	HouseTypeIsNotDefined     = True;
	PresentationField      = "";
	
	For Each ItemOfList In FieldList Do
		FieldName = Upper(ItemOfList.Presentation);
		
		If FieldName="INDEX" Then
			ItemIndex = CreateItemAdditionalAddress(AddressRF);
			ItemIndex.TypeAdrEl = ContactInformationManagementClientServerReUse.SerializationCodePostalIndex();
			ItemIndex.Value = ItemOfList.Value;
			
		ElsIf FieldName = "COUNTRY" Then
			Address.Country = ItemOfList.Value;
			If Upper(ItemOfList.Value) <> NameOfRussia Then
				AddressRussian = False;
			EndIf;
			
		ElsIf FieldName = "COUNTRYCODE" Then
			;
			
		ElsIf FieldName = "StateCode" Then
			AddressRF.RFTerritorialEntity = StateOfCode(ItemOfList.Value);
			
		ElsIf FieldName = "REGION" Then
			AddressRF.RFTerritorialEntity = ItemOfList.Value;
			
		ElsIf FieldName = "district" Then
			If AddressRF.PrRayMO = Undefined Then
				AddressRF.PrRayMO = XDTOFactory.Create( AddressRF.Type().Properties.Get("PrRayMO").Type )
			EndIf;
			AddressRF.PrRayMO.Region = ItemOfList.Value;
			
		ElsIf FieldName = "CITY" Then
			AddressRF.City = ItemOfList.Value;
			
		ElsIf FieldName = "Settlement" Then
			AddressRF.Settlement = ItemOfList.Value;
			
		ElsIf FieldName = "Street" Then
			AddressRF.Street = ItemOfList.Value;
			
		ElsIf FieldName = "HOUSETYPE" Then
			If ItemHouse = Undefined Then
				ItemHouse = CreateItemAdditionalAddressNumber(AddressRF);
			EndIf;
			ItemHouse.Type = ContactInformationManagementClientServerReUse.AddressingObjectSerializationCode(ItemOfList.Value);
			HouseTypeIsNotDefined = False;
			
		ElsIf FieldName = "HOUSE" Then
			If ItemHouse = Undefined Then
				ItemHouse = CreateItemAdditionalAddressNumber(AddressRF);
			EndIf;
			ItemHouse.Value = ItemOfList.Value;
			
		ElsIf FieldName = "BLOCKTYPE" Then
			If ItemBlock = Undefined Then
				ItemBlock = CreateItemAdditionalAddressNumber(AddressRF);
			EndIf;
			ItemBlock.Type = ContactInformationManagementClientServerReUse.AddressingObjectSerializationCode(ItemOfList.Value);
			BlockTypeUndefined = False;
			
		ElsIf FieldName = "Section" Then
			If ItemBlock = Undefined Then
				ItemBlock = CreateItemAdditionalAddressNumber(AddressRF);
			EndIf;
			ItemBlock.Value = ItemOfList.Value;
			
		ElsIf FieldName = "ApartmentType" Then
			If ItemApartment = Undefined Then
				ItemApartment = CreateItemAdditionalAddressNumber(AddressRF);
			EndIf;
			ItemApartment.Type = ContactInformationManagementClientServerReUse.AddressingObjectSerializationCode(ItemOfList.Value);
			ApartmentTypeUndefined = False;
			
		ElsIf FieldName = "APARTMENT" Then
			If ItemApartment = Undefined Then
				ItemApartment = CreateItemAdditionalAddressNumber(AddressRF);
			EndIf;
			ItemApartment.Value = ItemOfList.Value;
			
		ElsIf FieldName = "PRESENTATION" Then
			PresentationField = TrimAll(ItemOfList.Value);
			
		EndIf;
		
	EndDo;
	
	// Defaults
	If HouseTypeIsNotDefined AND ItemHouse <> Undefined Then
		ItemHouse.Type = ContactInformationManagementClientServerReUse.AddressingObjectSerializationCode("House");
	EndIf;
	
	If BlockTypeUndefined AND ItemBlock <> Undefined Then
		ItemBlock.Type = ContactInformationManagementClientServerReUse.AddressingObjectSerializationCode("Block");
	EndIf;
	
	If ApartmentTypeUndefined AND ItemApartment <> Undefined Then
		ItemApartment.Type = ContactInformationManagementClientServerReUse.AddressingObjectSerializationCode("Apartment");
	EndIf;
	
	// Presentation with priorities.
	If Not IsBlankString(Presentation) Then
		Result.Presentation = Presentation;
	Else
		Result.Presentation = PresentationField;
	EndIf;
	
	Address.Content = ?(AddressRussian, AddressRF, Result.Presentation);
	
	Return Result;
EndFunction

// Parameters: Owner - XDTOObject, Undefined
//
Function HasFilledPropertiesXDTOContactInformation(Val Owner)
	
	If Owner = Undefined Then
		Return False;
	EndIf;
	
	// List of the ignored on comparing properties of the current owner - specifications of contact information.
	Ignored = New Map;
	
	TargetNamespace = ContactInformationManagementClientServerReUse.TargetNamespace();
	OwnerType     = Owner.Type();
	
	If OwnerType = XDTOFactory.Type(TargetNamespace, "Address") Then
		// Country does not affect the filling in if the remainings are empty. Ignore.
		Ignored.Insert(Owner.Properties().Get("Country"), True);
		
	ElsIf OwnerType = XDTOFactory.Type(TargetNamespace, "AddressRF") Then
		// Ignore list with empty values and possibly not empty types.
		List = Owner.GetList("AddEMailAddress");
		If List <> Undefined Then
			For Each ListProperty In List Do
				If IsBlankString(ListProperty.Value) Then
					Ignored.Insert(ListProperty, True);
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	For Each Property In Owner.Properties() Do
		
		If Not Owner.IsSet(Property) Or Ignored[Property] <> Undefined Then
			Continue;
		EndIf;
		
		If Property.UpperBound > 1 Or Property.UpperBound < 0 Then
			List = Owner.GetList(Property);
			
			If List <> Undefined Then
				For Each ItemOfList In List Do
					If Ignored[ItemOfList] = Undefined 
						AND HasFilledPropertiesXDTOContactInformation(ItemOfList) 
					Then
						Return True;
					EndIf;
				EndDo;
			EndIf;
			
			Continue;
		EndIf;
		
		Value = Owner.Get(Property);
		If TypeOf(Value) = Type("XDTODataObject") Then
			If HasFilledPropertiesXDTOContactInformation(Value) Then
				Return True;
			EndIf;
			
		ElsIf Not IsBlankString(Value) Then
			Return True;
			
		EndIf;
		
	EndDo;
		
	Return False;
EndFunction

Procedure InsertBuildingUnit(XDTOAddress, Type, Value)
	If IsBlankString(Value) Then
		Return;
	EndIf;
	
	Record = XDTOAddress.Get(ContactInformationManagementClientServerReUse.XNumberOfAdditionalObjectPathAddressing(Type) );
	If Record = Undefined Then
		Record = XDTOAddress.AddEMailAddress.Add( XDTOFactory.Create(XDTOAddress.AddEMailAddress.OwningProperty.Type) );
		Record.Number = XDTOFactory.Create(Record.Properties().Get("Number").Type);
		Record.Number.Value = Value;
		
		TypeCode = ContactInformationManagementClientServerReUse.AddressingObjectSerializationCode(Type);
		If TypeCode = Undefined Then
			TypeCode = Type;
		EndIf;
		Record.Number.Type = TypeCode
	Else        
		Record.Value = Value;
	EndIf;
	
EndProcedure

Function CreateItemAdditionalAddressNumber(AddressRF)
	AddEMailAddress = CreateItemAdditionalAddress(AddressRF);
	AddEMailAddress.Number = XDTOFactory.Create(AddEMailAddress.Type().Properties.Get("Number").Type);
	Return AddEMailAddress.Number;
EndFunction

Function CreateItemAdditionalAddress(AddressRF)
	ItemAdditionalAddressProperty = AddressRF.AddEMailAddress.OwningProperty;
	ItemAdditionalAssress = XDTOFactory.Create(ItemAdditionalAddressProperty.Type);
	AddressRF.AddEMailAddress.Add(ItemAdditionalAssress);
	Return ItemAdditionalAssress;
EndFunction

Function PrRayMO(AddressRF)
	If AddressRF.PrRayMO <> Undefined Then
		Return AddressRF.PrRayMO;
	EndIf;
	
	AddressRF.PrRayMO = XDTOFactory.Create( AddressRF.Properties().Get("PrRayMO").Type );
	Return AddressRF.PrRayMO;
EndFunction

Function DeserializationPhoneFax(FieldsValues, Presentation = "", ExpectedType = Undefined)
	
	If ContactInformationClientServer.IsXMLString(FieldsValues) Then
		// General format of a contact information.
		Return ContactInformationFromXML(FieldsValues, ExpectedType);
	EndIf;
	
	TargetNamespace = ContactInformationManagementClientServerReUse.TargetNamespace();
	
	If ExpectedType = Enums.ContactInformationTypes.Phone Then
		Data = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "PhoneNumber"));
		
	ElsIf ExpectedType=Enums.ContactInformationTypes.Fax Then
		Data = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "FaxNumber"));
		
	ElsIf ExpectedType=Undefined Then
		// Count as phone
		Data = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "PhoneNumber"));
		
	Else
		Raise NStr("en='An error occurred when deserializing the contact information, phone number or fax is expected';ru='Ошибка десериализации контактной информации, ожидается телефон или факс';vi='Lỗi cơ cấu hóa thông tin liên hệ, dự tính điện thoại hoặc fax'");
	EndIf;
	
	Result = XDTOFactory.Create(XDTOFactory.Type(TargetNamespace, "ContactInformation"));
	Result.Content        = Data;
	
	// From the key-value pairs
	ValueListFields = Undefined;
	If TypeOf(FieldsValues)=Type("ValueList") Then
		ValueListFields = FieldsValues;
	ElsIf Not IsBlankString(FieldsValues) Then
		ValueListFields = ContactInformationManagementClientServer.ConvertStringToFieldList(FieldsValues);
	EndIf;
	
	PresentationField = "";
	If ValueListFields <> Undefined Then
		For Each FieldValue In ValueListFields Do
			Field = Upper(FieldValue.Presentation);
			
			If Field = "COUNTRYCODE" Then
				Data.CountryCode = FieldValue.Value;
				
			ElsIf Field = "CITYCODE" Then
				Data.CityCode = FieldValue.Value;
				
			ElsIf Field = "PHONENUMBER" Then
				Data.Number = FieldValue.Value;
				
			ElsIf Field = "Supplementary" Then
				Data.Supplementary = FieldValue.Value;
				
			ElsIf Field = "PRESENTATION" Then
				PresentationField = TrimAll(FieldValue.Value);
				
			EndIf;
			
		EndDo;
		
		// Presentation with priorities.
		If Not IsBlankString(Presentation) Then
			Result.Presentation = Presentation;
		Else
			Result.Presentation = PresentationField;
		EndIf;
		
		Return Result;
	EndIf;
	
	// Disassemble from presentation.
	
	// Digits groups separated by characters - not in figures: county, city, number, extension. 
	// The additional includes nonblank characters on the left and right.
	Position = 1;
	Data.CountryCode  = FindSubstringOfDigits(Presentation, Position);
	BeginCity = Position;
	
	Data.CityCode  = FindSubstringOfDigits(Presentation, Position);
	Data.Number      = FindSubstringOfDigits(Presentation, Position, " -");
	
	Supplementary = TrimAll(Mid(Presentation, Position));
	If Left(Supplementary, 1) = "," Then
		Supplementary = TrimL(Mid(Supplementary, 2));
	EndIf;
	If Upper(Left(Supplementary, 3 ))= "EXT" Then
		Supplementary = TrimL(Mid(Supplementary, 4));
	EndIf;
	If Upper(Left(Supplementary, 1 ))= "." Then
		Supplementary = TrimL(Mid(Supplementary, 2));
	EndIf;
	Data.Supplementary = TrimAll(Supplementary);
	
	// Correct possible errors.
	If IsBlankString(Data.Number) Then
		If Left(TrimL(Presentation),1)="+" Then
			// There was an attempt to explicitly specify country code, leave the country.
			Data.CityCode  = "";
			Data.Number      = ReduceDigits(Mid(Presentation, BeginCity));
			Data.Supplementary = "";
		Else
			Data.CountryCode  = "";
			Data.CityCode  = "";
			Data.Number      = Presentation;
			Data.Supplementary = "";
		EndIf;
	EndIf;
	
	Result.Presentation = Presentation;
	Return Result;
EndFunction  

// Returns the first subrow from digits in the row. The BeginningPosition parameter is substituted for the first non-digit.
//
Function FindSubstringOfDigits(Text, BeginningPosition = Undefined, PermissibleExceptDigits = "")
	
	If BeginningPosition = Undefined Then
		BeginningPosition = 1;
	EndIf;
	
	Result = "";
	PositionEnd = StrLen(Text);
	SearchBeginning  = True;
	
	While BeginningPosition <= PositionEnd Do
		Char = Mid(Text, BeginningPosition, 1);
		IsDigit = Char >= "0" AND Char <= "9";
		
		If SearchBeginning Then
			If IsDigit Then
				Result = Result + Char;
				SearchBeginning = False;
			EndIf;
		Else
			If IsDigit Or Find(PermissibleExceptDigits, Char) > 0 Then
				Result = Result + Char;    
			Else
				Break;
			EndIf;
		EndIf;
		
		BeginningPosition = BeginningPosition + 1;
	EndDo;
	
	// Remove possible pending delimiters left.
	Return ReduceDigits(Result, PermissibleExceptDigits, False);
	
EndFunction

Function ReduceDigits(Text, PermissibleExceptDigits = "", Direction = True)
	
	Length = StrLen(Text);
	If Direction Then
		// Abbreviation left
		IndexOf = 1;
		End  = 1 + Length;
		Step    = 1;
	Else
		// Abbreviation right    
		IndexOf = Length;
		End  = 0;
		Step    = -1;
	EndIf;
	
	While IndexOf <> End Do
		Char = Mid(Text, IndexOf, 1);
		IsDigit = (Char >= "0" AND Char <= "9") Or Find(PermissibleExceptDigits, Char) = 0;
		If IsDigit Then
			Break;
		EndIf;
		IndexOf = IndexOf + Step;
	EndDo;
	
	If Direction Then
		// Abbreviation left
		Return Right(Text, Length - IndexOf + 1);
	EndIf;
	
	// Abbreviation right
	Return Left(Text, IndexOf);
	
EndFunction

// Receive deep property of an object.
//
Function GetXDTOObjectAttribute(XDTOObject, XPath) Export
	
	// Do not wait for line break to XPath.
	PropertiesString = StrReplace(StrReplace(XPath, "/", Chars.LF), Chars.LF + Chars.LF, "/");
	
	NumberOfProperties = StrLineCount(PropertiesString);
	If NumberOfProperties = 1 Then
		Result = XDTOObject.Get(PropertiesString);
		If TypeOf(Result) = Type("XDTODataObject") Then 
			Return Result.Value;
		EndIf;
		Return Result;
	EndIf;
	
	Result = ?(NumberOfProperties = 0, Undefined, XDTOObject);
	For IndexOf = 1 To NumberOfProperties Do
		Result = Result.Get(StrGetLine(PropertiesString, IndexOf));
		If Result = Undefined Then 
			Break;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Sets in XDTO address a value according to XPath.
//
Procedure SetXDTOObjectAttribute(XDTODataObject, PathXPath, Value) Export
	
	If Value = Undefined Then
		Return;
	EndIf;
	
	// XPath parts
	PartsWays  = StrReplace(PathXPath, "/", Chars.LF);
	PathParts = StrLineCount(PartsWays);
	
	LeadingObject = XDTODataObject;
	Object        = XDTODataObject;
	
	For Position = 1 To PathParts Do
		PathPart = StrGetLine(PartsWays, Position);
		If PathParts = 1 Then
			Break;
		EndIf;
		
		Property = Object.Properties().Get(PathPart);
		If Not Object.IsSet(Property) Then
			Object.Set(Property, XDTOFactory.Create(Property.Type));
		EndIf;
		LeadingObject = Object;
		Object        = Object[PathPart];
	EndDo;
	
	If Object <> Undefined Then
		
		If Find(PathPart, "AddEMailAddress") = 0 Then
			Object[PathPart] =  Value;
		Else
			XPathPathCode = Mid(PathPart, 20, 8);
			FieldValue = Object.AddEMailAddress.Add(XDTOFactory.Create(Object.AddEMailAddress.OwningProperty.Type));
			FieldValue.TypeAdrEl = XPathPathCode;
			FieldValue.Value = Value;
		EndIf;
		
	ElsIf LeadingObject <> Undefined Then
		LeadingObject[PathPart] =  Value;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctionsBySXSLTWork

//  Returns a flag showing whether it is an XML text
//
//  Parameters:
//      Text - String - checked text.
//
// Returns:
//      Boolean - checking result.
//
Function ItIsXMLString(Text)
	
	Return TypeOf(Text) = Type("String") AND Left(TrimL(Text),1) = "<";
	
EndFunction

// Deserializer of types known to platform.
Function ValueFromXMLString(Val Text)
	
	XMLReader = New XMLReader;
	XMLReader.SetString(Text);
	Return XDTOSerializer.ReadXML(XMLReader);
	
EndFunction

// Serializer of types known to platform.
Function ValueToXMLString(Val Value)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString(New XMLWriterSettings(, , False, False, ""));
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
	// Platform serializer helps to write a line break to the attributes value.
	Return StrReplace(XMLWriter.Close(), Chars.LF, "&#10;");
	
EndFunction

// To work with attributes containing line breaks.
//
// Parameters:
//     Text - String - Corrected XML row.
//
// Returns:
//     String - Normalized row.
//
Function MultipageXMLRow(Val Text)
	
	Return StrReplace(Text, Chars.LF, "&#10;");
	
EndFunction

// Prepares the structure to include it in the XML text removing special characters.
//
// Parameters:
//     Text - String - Corrected XML row.
//
// Returns:
//     String - Normalized row.
//
Function NormalizedXMLRow(Val Text)
	
	Result = StrReplace(Text,     """", "&quot;");
	Result = StrReplace(Result, "&",  "&amp;");
	Result = StrReplace(Result, "'",  "&apos;");
	Result = StrReplace(Result, "<",  "&lt;");
	Result = StrReplace(Result, ">",  "&gt;");
	Return MultipageXMLRow(Result);
	
EndFunction


#EndRegion

#EndRegion
