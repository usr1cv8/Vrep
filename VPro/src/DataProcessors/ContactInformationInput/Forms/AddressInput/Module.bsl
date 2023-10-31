// The form is parameterized as follows:
//
//      Title           - String  - form title.
//      FieldValues     - String  - serialized contact information value, or empty string used
//                                  to enter new contact information value.
//      Presentation    - String  - address presentation (used only when working with old data).
//      ContactInformationKind    - CatalogRef.ContactInformationKinds, Structure - description of
//                                  data to be edited.
//      Comment         - String  - comment to be placed in the Comment field, optional.
//
//      ReturnValueList - Boolean - flag specifying that the returned ContactInformation value 
//                                  has ValueList type (for compatibility purposes), optional.
//
//  Selection result:
//      Structure with the following fields:
//          * ContactInformation  - String  - contact information XML string.
//          * Presentation        - String  - presentation.
//          * Comment             - String  - comment.
//          * EnteredInFreeFormat - Boolean - input flag.
//
// -------------------------------------------------------------------------------------------------

#Region FormEventHandlers
 
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("OpenByScenario") Then
		Raise NStr("en='The data processor cannot be opened manually';vi='Không thể mở bộ xử lý dữ liệu theo cách thủ công'");
	EndIf;
	
	Parameters.Property("ReturnValueList", ReturnValueList);
	
	// Internal initialization
	MasterFieldBackgroundColor = StyleColors.MasterFieldBackground;
	FormBackColor              = StyleColors.FormBackColor;
	ValidFieldColor            = New Color;   // (243, 255, 243)
	AutoColor                  = New Color;
	
	HomeCountry = Constants.HomeCountry.Get();
	
	ContactInformationKind = ContactInformationManagement.ContactInformationKindStructure(Parameters.ContactInformationKind);
	ContactInformationKind.Insert("Ref", Parameters.ContactInformationKind);
	
	// Title
	If IsBlankString(Parameters.Title) Then
		If TypeOf(ContactInformationKind)=Type("CatalogRef.ContactInformationKinds") Then
			Title = String(ContactInformationKind);
			// Otherwise, keeping the title specified in the form
		EndIf;
	Else
		Title = Parameters.Title;
	EndIf;
	
	//Address classifier is not available
	CanImportClassifier    = False;
	HasClassifier          = False;
	
	HideObsoleteAddresses  = ContactInformationKind.HideObsoleteAddresses;
	
	DomesticAddressOnly = ContactInformationKind.DomesticAddressOnly;
	ContactInformationType = ContactInformationKind.Type;
		
	// Attempting to fill data based on parameter values
	If ContactInformationClientServer.IsXMLString(Parameters.FieldValues) 
		And ContactInformationType=Enums.ContactInformationTypes.Address
	Then
		ReadResults = New Structure;
		XDTOContactInfo = ContactInformationInternal.ContactInformationDeserialization(Parameters.FieldValues, ContactInformationType, ReadResults);
		If ReadResults.Property("ErrorText") Then
			// Recognition errors. A warning must be displayed when opening the form
			WarningTextOnOpen = ReadResults.ErrorText;
			XDTOContactInfo.Presentation = Parameters.Presentation;
			XDTOContactInfo.Content.Country = String(HomeCountry);
		EndIf;
	Else
		XDTOContactInfo = ContactInformationInternal.AddressDeserialization(Parameters.FieldValues, Parameters.Presentation, );
	EndIf;
	
	If Parameters.Comment<>Undefined Then
		// Creating a new comment to prevent comment import from contact information
		ContactInformationInternal.ContactInformationComment(XDTOContactInfo, Parameters.Comment);
	EndIf;
	
	ContactInformationAttibuteValues(ThisObject, XDTOContactInfo);
	If ValueIsFilled(Country) Then
		// Record is found in the country catalog
		InitialCountryPresentation = "";
		
	ElsIf IsBlankString(CountryCode) Then
		// Record is found in the classifier but not in the country catalog. Create a catalog record?
		InitialCountryPresentation = TrimAll(XDTOContactInfo.Content.Country);
		
	Else
		// Record is found neither in the classifier nor in the country catalog
		InitialCountryPresentation = TrimAll(XDTOContactInfo.Content.Country);
		
	EndIf;
	
	If DomesticAddressOnly Then
		Items.Country.Enabled = False;
		If Not Country = HomeCountry Then
			Country = HomeCountry;
			CountryCode = HomeCountry.Code;
			Modified = True;
		EndIf;
	EndIf;
	
	// All addresses are domestic by default
	If ValueIsFilled(Country) Then
		CountryCode = Country.Code;
	Else
		If IsBlankString(InitialCountryPresentation) Then
			Country     = HomeCountry;
			CountryCode = HomeCountry.Code;
		Else 
			// Failed to determine country, but this address is definitely not domestic
			If IsBlankString(WarningTextOnOpen) Then
				WarningFieldOnOpen = "Country";
			EndIf;
			WarningTextOnOpen = WarningTextOnOpen
				+ StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en='Country ""%1"" is not found in the world country catalog.';vi='Không tìm thấy quốc gia ""%1"" trong danh sách các quốc gia trên thế giới.'"), InitialCountryPresentation
				);
		EndIf;
	EndIf;
		
	If CommonUseClientServer.ThisIsWebClient() Then
		CanImportClassifier = False;
	EndIf;
	
	// Displaying presentation by default
	Items.AddressPresentationComment.CurrentPage = Items.AddressPagePresentation;
		
	SetFormUsageKey();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetCommentIcon();
	
	CountryChangeProcessingClient();
	AddressPresentationInputState(AllowAddressInputInFreeFormat, False);
	
	If Not IsBlankString(WarningTextOnOpen) Then
		AttachIdleHandler("Attachable_WarningAfterFormOpen", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	Notification = New NotifyDescription("ConfirmAndClose", ThisObject);
	CommonUseClient.ShowFormClosingConfirmation(Notification, Cancel);
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure CountryOnChange(Item)
	CountryChangeProcessingClient();
	
	Context = FormContextClient();
	FillAddressPresentation(Context);
	FormContextClient(Context);
	
#If WebClient Or MobileClient Then
	// Addressing platform specifics
	Item.UpdateEditText();
#EndIf

	// Always displaying presentation
	Items.AddressPresentationComment.CurrentPage = Items.AddressPagePresentation;
EndProcedure

&AtClient
Procedure CountryClear(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure CountryAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	If Waiting = 0 Then
		// Generating the quick selection list
		If IsBlankString(Text) Then
			ChoiceData = New ValueList;
		EndIf;
		Return;
	EndIf;

EndProcedure

&AtClient
Procedure CountryTextInputEnd(Item, Text, ChoiceData, StandardProcessing)
	
#If WebClient Or MobileClient Then
	// Addressing platform specifics
	StandardProcessing = False;
	ChoiceData         = New ValueList;
	ChoiceData.Add(Country);
	Return;
#EndIf

EndProcedure

&AtClient
Procedure CountryChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	ContactInformationManagementClient.WorldCountryChoiceProcessing(Item, SelectedValue, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PostalCodeOnChange(Item)
		
	Modified = True;
	
EndProcedure

&AtClient
Procedure CommentOnChange(Item)
	
	SetCommentIcon();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OKCommand(Command)
	
	ConfirmAndClose();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Modified = False;
	Close();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure SetCommentIcon()
	
	If IsBlankString(Comment) Then
		Items.AddressPageComment.Picture = New Picture;
	Else
		Items.AddressPageComment.Picture = PictureLib.Comment;
	EndIf;
		
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	// If the data was not modified, emulating Cancel command
	
	If Modified Then
		// Address value is modified 
		
		Context = FormContextClient();
		Result = FlagUpdateSelectionResults(Context, ReturnValueList);
		
		// Reading contact information kind flags again
		ContactInformationKind = Context.ContactInformationKind;
		
		If Result.FillErrors.Count()>0 Then
			NotifyFillErrors(Result.FillErrors, False);
			Return;
		EndIf;
		
		Result = Result.ChoiceData;
		
		ClearModifiedOnChoice();
#If WebClient Or MobileClient Then
		CloseFlag = CloseOnChoice;
		CloseOnChoice = False;
		NotifyChoice(Result);
		CloseOnChoice = CloseFlag;
#Else
		NotifyChoice(Result);
#EndIf
		SaveFormState();
		
	ElsIf Comment <> CommentCopy Then
		// Only the comment is modified, attempting to revert
		Result = CommentChoiceOnlyResult(Parameters.FieldValues, Parameters.Presentation, Comment);
		Result = Result.ChoiceData;
		
		ClearModifiedOnChoice();
#If WebClient Or MobileClient Then
		CloseFlag = CloseOnChoice;
		CloseOnChoice = False;
		NotifyChoice(Result);
		CloseOnChoice = CloseFlag;
#Else
		NotifyChoice(Result);
#EndIf
		SaveFormState();
		
	Else
		Result = Undefined;
	EndIf;
	
	If (ModalMode Or CloseOnChoice) And IsOpen() Then
		ClearModifiedOnChoice();
		SaveFormState();
		Close(Result);
	EndIf;

EndProcedure

&AtClient
Procedure SaveFormState()
	SetFormUsageKey();
	SavedInSettingsDataModified = True;
EndProcedure

&AtClient
Procedure ClearModifiedOnChoice()
	Modified    = False;
	CommentCopy = Comment;
EndProcedure

&AtClient
Procedure Attachable_WarningAfterFormOpen()
	CommonUseClientServer.MessageToUser(WarningTextOnOpen,, WarningFieldOnOpen);
EndProcedure

&AtServerNoContext
Function FlagUpdateSelectionResults(Context, ReturnValueList = False)
	// Updating some flags
	FlagsValue = ContactInformationManagement.ContactInformationKindStructure(Context.ContactInformationKind.Ref);
	
	Context.ContactInformationKind.DomesticAddressOnly = FlagsValue.DomesticAddressOnly;
	Context.ContactInformationKind.ProhibitInvalidEntry   = FlagsValue.ProhibitInvalidEntry;
	Context.ContactInformationKind.CheckValidity          = FlagsValue.CheckValidity;

	Return ChoiceResult(Context, ReturnValueList);
	
EndFunction

&AtServerNoContext
Function ChoiceResult(Context, ReturnValueList = False)
	XDTOInformation = ContactInformationByAttributeValues(Context);
	Result          = New Structure("ChoiceData, FillErrors");
	
	If ReturnValueList Then
		ChoiceData = ContactInformationInternal.ContactInformationToOldStructure(XDTOInformation);
		ChoiceData = ChoiceData.FieldValues;
		
	//ElsIf Context.Country = Context.HomeCountry And IsBlankString(XDTOInformation.Presentation) Then
		//ChoiceData = "";
		
	Else
		ChoiceData = ContactInformationInternal.ContactInformationSerialization(XDTOInformation);
		
	EndIf;
	
	Result.ChoiceData = New Structure("ContactInformation, Presentation, Comment, EnteredInFreeFormat",
		ChoiceData,
		XDTOInformation.Presentation,
		XDTOInformation.Comment,
		ContactInformationInternal.AddressEnteredInFreeFormat(XDTOInformation));
	
	Result.FillErrors = ContactInformationInternal.AddressFillErrors(
		XDTOInformation.Content,
		Context.ContactInformationKind);
	
	// Suppressing line breaks in the separately returned presentation
	Result.ChoiceData.Presentation = TrimAll(StrReplace(Result.ChoiceData.Presentation, Chars.LF, " "));
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function FillErrorList(Context, NotifyAboutNoErrors)
	XDTOInformation = ContactInformationByAttributeValues(Context);
	
	// Getting value list: XPath is the error text
	Result = ContactInformationInternal.AddressFillErrors(
		XDTOInformation.Content, Context.ContactInformationKind
	);
	
	If Result.Count() = 0 // No errors
		And NotifyAboutNoErrors // It is necessary to notify user that no errors occurred.
		//  Additionally, checking if the address is empty.
		And (Not ContactInformationInternal.XDTOContactInformationFilled(XDTOInformation))
	Then
		Result.Add("/", NStr("en='The address is empty.';vi='Địa chỉ trống.'"));
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function CommentChoiceOnlyResult(ContactInfo, Presentation, Comment)
	
	If IsBlankString(ContactInfo) Then
		NewContactInfo = ContactInformationInternal.AddressDeserialization("");
		// Modifying NewContactInfo value
		ContactInformationInternal.ContactInformationComment(NewContactInfo, Comment);
		NewContactInfo = ContactInformationInternal.ContactInformationSerialization(NewContactInfo);
		AddressEnteredInFreeFormat = False;
		
	ElsIf ContactInformationClientServer.IsXMLContactInformation(ContactInfo) Then
		// Making a copy
		NewContactInfo = ContactInfo;
		// Modifying NewContactInfo value
		ContactInformationInternal.ContactInformationComment(NewContactInfo, Comment);
		AddressEnteredInFreeFormat = ContactInformationInternal.AddressEnteredInFreeFormat(ContactInfo);
		
	Else
		NewContactInfo = ContactInfo;
		AddressEnteredInFreeFormat = False;
	EndIf;
	
	Result = New Structure("ChoiceData, FillErrors", New Structure, New ValueList);
	Result.ChoiceData.Insert("ContactInformation", NewContactInfo);
	Result.ChoiceData.Insert("Presentation", Presentation);
	Result.ChoiceData.Insert("Comment", Comment);
	Result.ChoiceData.Insert("EnteredInFreeFormat", AddressEnteredInFreeFormat);
	Return Result;
EndFunction

&AtClient
Procedure CountryChangeProcessingClient()
	
	IsDomesticAddress = Country = HomeCountry;
		
EndProcedure

&AtServerNoContext
Procedure FillAddressPresentation(Context, XDTOContactInfo=Undefined)
	
	// Country code is mandatory
	If TypeOf(Context.Country)=Type("CatalogRef.WorldCountries") Then
		Context.CountryCode = Context.Country.Code
	Else
		Context.CountryCode = "";
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ContactInformationAttibuteValues(Context, InformationToEdit)
	
	AddressData = InformationToEdit.Content;
	
	// Common attributes
	Context.AddressPresentation = InformationToEdit.Presentation;
	Context.Comment             = InformationToEdit.Comment;
	
	// Comment copy used to identify data modifications
	Context.CommentCopy = Context.Comment;
	
	// Country by description
	CountryDescription = TrimAll(AddressData.Country);
	If IsBlankString(CountryDescription) Then
		Context.Country = Catalogs.WorldCountries.EmptyRef();
	Else
		ReferenceToUSA = Constants.HomeCountry.Get();
		If Upper(CountryDescription) = Upper(TrimAll(ReferenceToUSA.Description)) Then
			Context.Country     = ReferenceToUSA;
			Context.CountryCode = ReferenceToUSA.Code;
		Else
			CountryData = Catalogs.WorldCountries.WorldCountryData(, CountryDescription);
			If CountryData=Undefined Then
				// Country data is found neither in the country catalog nor in the classifier
				Context.Country     = Undefined;
				Context.CountryCode = Undefined;
			Else
				Context.Country     = CountryData.Ref;
				Context.CountryCode = CountryData.Code;
			EndIf;
		EndIf;
	EndIf;
	
	CalculatedPresentation = ContactInformationInternal.GenerateContactInformationPresentation(
		InformationToEdit, Context.ContactInformationKind);
		
	Context.PostalCode = ContactInformationInternal.AddressPostalCode(AddressData);
	Context.AddressLine1 = ContactInformationInternal.AddressAddressLine1(AddressData);
	Context.AddressLine2 = ContactInformationInternal.AddressAddressLine2(AddressData);
	Context.City = ContactInformationInternal.AddressCity(AddressData);
	Context.State = ContactInformationInternal.AddressState(AddressData);
		
	// If the passed presentation is not identical to the calculated presentation, the address is considered to be modified
	If Not Context.AllowAddressInputInFreeFormat And Not AddressPresentationsIdentical(Context.AddressPresentation, CalculatedPresentation) Then
		Context.Modified = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ContactInformationByAttributeValues(Context)	
	
	Namespace = ContactInformationClientServerCached.Namespace();
	
	Result = XDTOFactory.Create( XDTOFactory.Type(Namespace, "ContactInformation") );
	Result.Comment = Context.Comment;
	
	Result.Content = XDTOFactory.Create( XDTOFactory.Type(Namespace, "Address") );
	Address = Result.Content;
	
	Address.AddressLine1 = TrimAll(Context.AddressLine1);
	Address.AddressLine2 = TrimAll(Context.AddressLine2);
	Address.City = TrimAll(Context.City);
	Address.State = TrimAll(Context.State);
	Address.PostalCode = TrimAll(Context.PostalCode);
	Address.Country = String(Context.Country);
	Result.Presentation = ContactInformationInternal.AddressPresentation(Address, Context.ContactInformationKind);
	
	If Upper(Context.Country)=Upper(Context.HomeCountry.Description) Then
		Address.Content = XDTOFactory.Create( XDTOFactory.Type(Namespace, "AddressUS") );
		AddressUS = Address.Content;
	EndIf;
	
	Return Result;
	
	//////////////////////
	
	//Address.Country = String(Context.Country);
	//If Upper(Context.Country)<>Upper(Context.HomeCountry.Description) Then
	//	Address.Content = Context.ForeignAddressPresentation;
	//	Result.Presentation = ContactInformationInternal.AddressPresentation(Address, Context.ContactInformationKind);
	//	Return Result;
	//EndIf;
	//
	//Address.Content = XDTOFactory.Create( XDTOFactory.Type(Namespace, "AddressUS") );
	//AddressUS = Address.Content;
	//
	//// Settlement
	//If Context.SettlementClassifierCode>0 Then
	//	ContactInformationInternal.SetAddressSettlementByPostalCode(
	//		AddressUS, Context.SettlementClassifierCode);
	//	// Adding (probably not empty) data
	//	For Each KeyValue In Context.SettlementDetails Do
	//		SettlementPart = KeyValue.Value;
	//		CurrentValue = ContactInformationInternal.PropertyByXPathValue(AddressUS, SettlementPart.XPath);
	//		If IsBlankString(CurrentValue) And (Not IsBlankString(SettlementPart.Value)) Then
	//			ContactInformationInternal.SetPropertyByXPath(AddressUS, SettlementPart.XPath, SettlementPart.Value);
	//		EndIf;
	//	EndDo;
	//Else
	//	NoDetailedData = True;
	//	For Each KeyValue In Context.SettlementDetails Do
	//		SettlementPart = KeyValue.Value;
	//		If Not IsBlankString(SettlementPart.Value) Then
	//			NoDetailedData = False;
	//		EndIf;
	//		ContactInformationInternal.SetPropertyByXPath(AddressUS, SettlementPart.XPath, SettlementPart.Value);
	//	EndDo;
	//	If NoDetailedData Then
	//		AddressUS.Settlement = Context.Settlement;
	//	EndIf;
	//EndIf;
	//
	//If Context.StreetClassifierCode>0 Then
	//	ContactInformationInternal.SetAddressStreetByPostalCode(AddressUS, Context.StreetClassifierCode);
	//Else
	//	AddressUS.Street = Context.Street;
	//EndIf;
	//
	//// Buildings
	//TypeValueTable = Type("ValueTable");
	//If TypeOf(Context.AdditionalBuildings)=TypeValueTable Then
	//	BuildingTable = Context.AdditionalBuildings.Copy();
	//Else
	//	BuildingTable = FormDataToValue(Context.AdditionalBuildings, TypeValueTable);
	//EndIf;
	//
	//// Postal code
	//ContactInformationInternal.AddressPostalCode(AddressUS, Context.PostalCode);
	//
	//// Presentation and address input in free format
	//ExpectedPresentation = ContactInformationInternal.AddressPresentation(Address, Context.ContactInformationKind);
	//EnteredPresentation = TrimAll(Context.AddressPresentation);
	//If Context.AllowAddressInputInFreeFormat And Context.AddressPresentationChanged Then
	//	If AddressPresentationsIdentical(EnteredPresentation, ExpectedPresentation) Then
	//		Result.Presentation = ExpectedPresentation;
	//		AddressUS.Unset("Address_by_document");
	//	Else
	//		Result.Presentation           = EnteredPresentation;
	//		AddressUS.Address_to_document = EnteredPresentation;
	//	EndIf;
	//Else
	//	AddressUS.Unset("Address_by_document");
	//	Result.Presentation = ExpectedPresentation;
	//EndIf;
	//
	//Return Result;
EndFunction

&AtServer
Procedure DeleteItemGroup(Group)
	While Group.ChildItems.Count()>0 Do
		Item = Group.ChildItems[0];
		If TypeOf(Item)=Type("FormGroup") Then
			DeleteItemGroup(Item);
		EndIf;
		Items.Delete(Item);
	EndDo;
	Items.Delete(Group);
EndProcedure

&AtClient
Procedure NotifyFillErrors(ErrorList, NotifyAboutNoErrors)
	
	ClearMessages();
	
	ErrorsCount = ErrorList.Count();
	If ErrorsCount = 0 And NotifyAboutNoErrors Then
		// No errors
		ShowMessageBox(, NStr("en='The entered address is valid.';vi='Địa chỉ đã nhập là hợp lệ.'"));
		Return;
	ElsIf ErrorsCount = 1 Then
		ErrorLocation = ErrorList[0].Value;
		If IsBlankString(ErrorLocation) Or ErrorLocation = "/" Then
			// The address contains a single error not bound to a specific field
			ShowMessageBox(, ErrorList[0].Presentation);
			Return;
		EndIf;
	EndIf;
	
	// Sending the field-bound list to user
	For Each Item In ErrorList Do
		CommonUseClientServer.MessageToUser(
			Item.Presentation,,,PathToFormDataByXPath(Item.Value)
		);
	EndDo;
		
EndProcedure

&AtClient
Function PathToFormDataByXPath(XPath) 
	
	If XPath = "Region" Then
		Return "Settlement";
		
	ElsIf XPath = ContactInformationClientServerCached.CountyXPath() Then
		Return "Settlement";
		
	ElsIf XPath = "City" Then
		Return "Settlement";
		
	ElsIf XPath = "District" Then
		Return "Settlement";
		
	ElsIf XPath = "Settlement" Then
		Return "Settlement";
		
	ElsIf XPath = "Street" Then
		Return "Street";
		
	ElsIf XPath = ContactInformationClientServerCached.PostalCodeXPath() Then
		Return "PostalCode";
		
	EndIf;
	
	// Building options
	For Each ListItem In Items.BuildingType.ChoiceList Do
		If XPath = ContactInformationClientServerCached.AdditionalAddressingObjectNumberXPath(ListItem.Value) Then
			Return "Building";
		EndIf;
	EndDo;
	
	// Unit options
	For Each ListItem In Items.DELETE.ChoiceList Do
		If XPath = ContactInformationClientServerCached.AdditionalAddressingObjectNumberXPath(ListItem.Value) Then
			Return "Unit";
		EndIf;
	EndDo;
		
	// Not found
	Return "";
EndFunction

&AtServer
Procedure SetFormUsageKey()
	WindowOptionsKey = String(Country);
	
	Quantity = 0;
	For Each Row In AdditionalBuildings Do
		If Not IsBlankString(Row.Value) Then
			Quantity = Quantity + 1;
		EndIf;
	EndDo;
	WindowOptionsKey = WindowOptionsKey + "/" + Format(Quantity, "NZ=; NG=");
	
	
	WindowOptionsKey = WindowOptionsKey + "/" + Format(Quantity, "NZ=; NG=");
EndProcedure

////////////////////////////////////////////////////////////////////////////////////////////////////

// Transforming Form attributes <-> Structure
&AtClient
Function FormContextClient(NewData=Undefined)
	
	AttributeList = "
		|ContactInformationKind,
		|AddressLine1,
		|AddressLine2,
		|City,
		|State,
		|PostalCode,
		|Country, 
		|CountryCode,
		|Comment,
		|HomeCountry
		|";
	
	CollectionList = "";
	
	If NewData = Undefined Then
		// Reading
		Result = New Structure(AttributeList);
		FillPropertyValues(Result, ThisObject, AttributeList);
		Return Result;
	EndIf;
	
	FillPropertyValues(ThisObject, NewData, AttributeList);
	
	Return NewData;
	
EndFunction

// Allows or denies free-format input for items
//
// Parameters:
//    - Mode                 - Boolean - if True, address presentation can be edited; 
//                                       if False, it cannot be edited.
//    - GeneratePresentation - Boolean - optional flag. Set by default.
//
&AtClient
Procedure AddressPresentationInputState(Mode, GeneratePresentation=True)
	//Item = Items.AddressPresentation;
	//
	//Item.TextEdit = Mode;
	//If Mode Then
	//	Item.TextEdit = True;
	//	Item.BackColor = AutoColor;
	//Else
	//	Item.TextEdit = False;
	//	Item.BackColor = FormBackColor;
	//	
	//	If GeneratePresentation Then
	//		Context = FormContextClient();
	//		FillAddressPresentation(Context);
	//		FormContextClient(Context);
	//	EndIf;
	//EndIf;
	//
	//// Other input fields
	//InputGroupStatus(Items.AddressCountry, Not Mode);
	//InputGroupStatus(Items.AddressType, Not Mode);
	//
	//// Mode mark
	////Items.EnterAddressInFreeFormat.Check           = Mode;
	////Items.EnterAddressInFreeFormatAllActions.Check = Mode;
	//
	//Items.AddressPresentationContextMenuEnterAddressInFreeFormat.Check = Mode;
	//
	//// Addresses entered manually cannot be validated
	////If Country = HomeCountry Then
	////	Items.CheckAddressFilled.Enabled = Not Mode;
	////EndIf;
	//
	//// Country remains a control field
	//If Items.Country.Enabled Then
	//	Items.Country.BackColor = MasterFieldBackgroundColor;
	//EndIf;
	//
	//// Setting presentation title and the current input item to ensure correct mode indication
	//If Mode Then
	//	Items.AddressPresentation.TitleLocation = FormItemTitleLocation.Top;
	//	Items.AddressPresentation.Title         = NStr("en='Address in free format';vi='Địa chỉ ở định dạng tự do'");
	//	
	//	Items.AddressCountry.Representation     = UsualGroupRepresentation.None;
	//	
	//	CurrentItem = Items.AddressPresentation;
	//Else 
	//	Items.AddressPresentation.TitleLocation = FormItemTitleLocation.None;
	//	Items.AddressPresentation.Title         = "";
	//	
	//	Items.AddressCountry.Representation     = UsualGroupRepresentation.NormalSeparation;
	//	
	//	CurrentItem = Items.Settlement;
	//EndIf;
	
EndProcedure

// Specifies whether the group items are accessible.
//
// Parameters:
//    - Group - FormGroup - Item container.
//    - Mode  - Boolean   - Item accessibility flag. If True, access is allowed; if False, not allowed.
//
&AtClient
Procedure InputGroupStatus(Group, Mode)
	
	For Each Item In Group.ChildItems Do
		ItemType = TypeOf(Item);
		If ItemType = Type("FormGroup") Then
			If Item <> Items.ForeignAddress Then
				InputGroupStatus(Item, Mode);
			EndIf;
			
		ElsIf ItemType = Type("FormButton") Then
			If Item = Items.AddObject Then
				//PARTIALLY_DELETED
				//Item.Enabled = Mode And CanAddAdditionalObjects();
			Else
				Item.Enabled = Mode;
			EndIf;
			
		ElsIf ItemType = Type("FormField") And Item.Type = FormFieldType.InputField Then
			If Item <> Items.AddressPresentation Then
				Item.ReadOnly = Not Mode;
				Item.BackColor = ?(Mode, AutoColor, FormBackColor);
			EndIf;
			
		Else 
			Item.Enabled = Mode;
			
		EndIf;
	EndDo;

EndProcedure

// Comparing if two presentations are equivalent
&AtServerNoContext
Function AddressPresentationsIdentical(Val Presentation1, Val Presentation2, Val IgnoreNumberSign=False)
	Return PresentationHash(Presentation1, IgnoreNumberSign)=PresentationHash(Presentation2, IgnoreNumberSign);
EndFunction

&AtServerNoContext
Function PresentationHash(Val Presentation, Val IgnoreNumberSign=False)
	Result = StrReplace(Presentation, Chars.LF, "");
	Result = StrReplace(Result, " ", "");
	If IgnoreNumberSign Then
		Result = StrReplace(Result, "#", "");
	EndIf;
	Return Upper(Result);
EndFunction

&AtClient
Procedure AddressLine1OnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure AddressLine2OnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure CityOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure StateOnChange(Item)
	
	Modified = True;
	
EndProcedure


#EndRegion