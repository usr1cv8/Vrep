#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Allows to predefine the exchange plan settings specified by default.
// For values of the default settings, see DataExchangeServer.DefaultExchangePlanSettings
// 
// Parameters:
// Settings - Structure - Contains default settings
//
// Example:
//	Settings.WarnAboutExchangeRulesVersionsMismatch = False;
Procedure DefineSettings(Settings, SettingID) Export
	
	If SettingID = ""  Then
		Settings.ExchangeSettingsVariants.Add("Accounting3");//, Nstr("en='1C:Enterprise Accounting';ru='Обмен с 1С:Бухгалтерия Предприятия';vi='Trao đổi 1C: Kế toán 3.3'")
		Settings.ExchangeSettingsVariants.Add("Accounting4");
	EndIf;
	
	If SettingID = "Accounting3" Then
		Settings.CommandTitleForCreationOfNewDataExchange = Nstr("en='1C:Enterprise Accounting';ru='1С:Бухгалтерия Предприятия';vi='1C: Kế toán 3.3'");
		Settings.ExchangeCreationAssistantTitle = Nstr("en='1C:Enterprise Accounting';ru='1С:Бухгалтерия Предприятия';vi='1C: Kế toán 3.3'");
		Settings.CorrespondentConfigurationName = Nstr("en='1C:Enterprise Accounting';ru='1С:Бухгалтерия Предприятия';vi='1C: Kế toán 3.3'");
	EndIf;
	If SettingID = "Accounting4" Then
		Settings.CommandTitleForCreationOfNewDataExchange =  Nstr("en='1C:Finance && Accounting';ru='1C:Finance && Accounting';vi='1C:Finance && Accounting'"); // command title
		Settings.ExchangeCreationAssistantTitle = Nstr("en='1C:Finance & Accounting';ru='1C:Finance & Accounting';vi='1C:Finance & Accounting'");
		Settings.CorrespondentConfigurationName = Nstr("en='1C:Finance & Accounting';ru='1C:Finance & Accounting';vi='1C:Finance & Accounting'");
	EndIf;
EndProcedure // DefineSettings()

// Returns the name of default settings file.
// the settings of an exchange for a receiver will be exported to this file;
// This value must be the same in the source exchange plan and receiver.
// 
// Parameters:
//  No.
// 
// Returns:
//  String, 255 - name of the default file for export settings of the data exchange
//
Function SettingsFilenameForReceiver() Export
	
	Return "Exchange settings for CM-Acc";
	
EndFunction

// Returns the structure of filters on exchange plan node with default values.
// Settings structure repeats the attributes content of header and exchange plan tabular sections;
// Structure items similar in key and value are used for
// header attributes. Structures containing arrays of
// tabular sections values of exchange plan parts are used for tabular sections.
// 
// Parameters:
//  No.
// 
// Returns:
//  SettingsStructure - Structure - structure of filters on the exchange plan node
// 
Function FilterSettingsAtNode(CorrespondentVersion, FormName, SettingID) Export
	
	StructureTabularSectionsOfDocumentKinds = New Structure;
	StructureTabularSectionsOfDocumentKinds.Insert("DocumentType", New Array);
	StructureTabularSectionsOfDocumentKinds.Insert("MetadataObjectName", New Array);
	StructureTabularSectionsOfDocumentKinds.Insert("Presentation", New Array);
	
	CounterpartyTabularSectionStructure = New Structure;
	CounterpartyTabularSectionStructure.Insert("Company", New Array);
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("DocumentsDumpStartDate", BegOfYear(CurrentDate()));
	SettingsStructure.Insert("UseDocumentTypesFilter", False);
	SettingsStructure.Insert("UseCompaniesFilter", False);
	SettingsStructure.Insert("ManualExchange", False);
	SettingsStructure.Insert("DocumentKinds", StructureTabularSectionsOfDocumentKinds);
	SettingsStructure.Insert("Companies", CounterpartyTabularSectionStructure);
	
	Return SettingsStructure;
	
EndFunction

// Returns the default values structure for a node;
// Structure of the settings repeats the content of exchange plan header attributes;
// For the header attributes structure items similar by key and the structure item value are used.
// 
// Parameters:
//  No.
// 
// Returns:
//  SettingsStructure - Structure - structure of default values on the exchange plan node
// 
Function DefaultValuesAtNode(CorrespondentVersion, FormName, SettingID) Export
	
	Return New Structure;
	
EndFunction

// Returns the string describing the restrictions of data migration for user.
// Applied developer based on set filters on the node should generate a row of restrictions description convenient for a user.
// 
// Parameters:
//  FilterSettingsAtNode - Structure - structure of filters on
//                                       node of an exchange plan received using the FiltersSettingsOnNode() function.
// 
// Returns:
//  String, Unlimited. - String of restrictions description of the data migration for a user
//
Function DataTransferRestrictionsDescriptionFull(FilterSettingsAtNode, CorrespondentVersion, SettingID) Export
	
	TextDescription = NStr("en='All reference information is automatically registered for sending;';ru='Вся нормативно-справочная информация автоматически регистрируется к отправке;';vi='Tất cả thông tin tra cứu được tự động ghi nhận để gửi:'");
	
	If FilterSettingsAtNode.ManualExchange Then
		
		TextDescription = NStr("en='User individually selects and registers the documents for sending;';ru='Пользователь самостоятельно отбирает и регистрирует документы к отправке;';vi='Người sử dụng tự lọc và ghi nhận chứng từ cần gửi:'");
		
	Else
		
		If FilterSettingsAtNode.UseDocumentTypesFilter Then
			TextDescription = TextDescription + Chars.LF + NStr("en='Document are automatically registered for sending:';ru='Документы автоматически регистрируются к отправке:';vi='Chứng từ được tự động ghi nhận để gửi:'");
		Else
			TextDescription = TextDescription + Chars.LF + NStr("en='All the documents are automatically registered for sending:';ru='Все документы автоматически регистрируются к отправке:';vi='Tất cả chứng từ được tự động ghi nhận để gửi:'");
		EndIf;
		
		If ValueIsFilled(FilterSettingsAtNode.DocumentsDumpStartDate) Then
			TextDescription = TextDescription + Chars.LF + NStr("en='from %StartDate%';ru='начиная с %ДатаНачала%';vi='từ %StartDate%'");
			TextDescription = StrReplace(TextDescription,"%StartDate%", Format(FilterSettingsAtNode.DocumentsDumpStartDate, "DF=dd.MM.yyyy"));
		EndIf;
		
		If FilterSettingsAtNode.UseCompaniesFilter Then
			CollectionValues = FilterSettingsAtNode.Companies.Company;
			PresentationCollections = ShortPresentationOfCollectionsOfValues(CollectionValues);
			TextDescription = TextDescription + Chars.LF + NStr("en='with filter by companies: %CollectionPresentation%';ru='с отбором по организациям: %ПредставлениеКоллекции%';vi='có lọc theo doanh nghiệp: %CollectionPresentation%'");
			TextDescription = StrReplace(TextDescription, "%CollectionPresentation%", PresentationCollections);
		Else
			TextDescription = TextDescription + Chars.LF + NStr("en='By all companies';ru='по всем организациям';vi='theo tất cả doanh nghiệp'");
		EndIf;
		
		If FilterSettingsAtNode.UseDocumentTypesFilter Then
			CollectionValues = FilterSettingsAtNode.DocumentKinds.Presentation;
			PresentationCollections = ShortPresentationOfCollectionsOfValues(CollectionValues);
			TextDescription = TextDescription + Chars.LF + NStr("en='with filter by document kinds: %CollectionPresentation%';ru='с отбором по видам документов: %ПредставлениеКоллекции%';vi='có bộ lọc theo dạng chứng từ: %CollectionPresentation%'");
			TextDescription = StrReplace(TextDescription, "%CollectionPresentation%", PresentationCollections);
		EndIf;
		
	EndIf;
	
	Return TextDescription;
	
EndFunction

// Returns the string of default values description for user.
// Application developer creates a user-friendly description string based on the default node values.
// 
// Parameters:
//  DefaultValuesAtNode - Structure - structure of default values on the
//                                       exchange plan node received using the DefaultValuesOnNode() function.
// 
// Returns:
//  String, Unlimited. - description string for default values user
//
Function ValuesDescriptionFullByDefault(DefaultValuesAtNode, CorrespondentVersion, SettingID) Export
	
	Return "";
	
EndFunction

// Returns the command presentation of a new data exchange creation.
//
// Returns:
//  String, Unlimited - presentation of a command displayed in the user interface.
//
// ForExample:
// Return NStr("en='Create exchange in the distributed infobase';ru='Создать обмен в распределенной информационной базе';vi='Tạo trao đổi trong cơ sở thông tin phân tán'");
//
Function CommandTitleForCreationOfNewDataExchange() Export
	
	Return NStr("en='Create data exchange with 1C:Accounting Enterprise 8 3.0 configuration';ru='Создать обмен с конфигурацией ""1C: Бухгалтерия предприятия 8, ред. 3.0""';vi='Tạo trao đổi với cấu hình ""1C:Kế toán doanh nghiệp 8, phiên bản ""'");
	
EndFunction

// Defines if the assistant of creating new exchange plan nodes is used.
//
// Returns:
//  Boolean - shows that assistant is used.
//
Function UseDataExchangeCreationAssistant() Export
	
	Return True;
	
EndFunction

// Returns a custom form for creation of the initial base image.
// This form will be opened when an exchange setting is complete using the assistant.
// For exchange plans not DIB function returns an empty row
//
// Returns:
//  String, Unlimited - form name
//
// ForExample:
// Return "ExchangePlan._DemoDistributedInfobase.Form.InitialImageCreationForm";
//
Function FormNameOfCreatingInitialImage() Export
	
	Return "";
	
EndFunction

// Returns an array of used messages transports for this exchange plan
//
// 1. For example if an exchange plan supports only two messages
// transports  FILE and FTP, then the body of the function should be defined in the following way:
//
// Result = New Array;
// Result.Add(Enums.ExchangeMessagesTransportKinds.FILE);
// Result.Add(Enums.ExchangeMessagesTransportKinds.FTP);
// Return Result;
//
// 2. For example if an exchange plan supports all messages
// transports defined in the configuration, then function body should be defined in the following way:
//
// Return DaraExchangeServer.AllConfigurationExchangeMessagesTransports();
//
// Returns:
//  Array - array contains values of the ExchangeMessagesTransportKinds enumeration
//
Function UsedTransportsOfExchangeMessages() Export
	
	Result = New Array;
	Result.Add(Enums.ExchangeMessagesTransportKinds.WS);
	Result.Add(Enums.ExchangeMessagesTransportKinds.FILE);
	Result.Add(Enums.ExchangeMessagesTransportKinds.FTP);
	
	Return Result;
	
EndFunction

Function CommonNodeData(CorrespondentVersion, FormName) Export
	
	Return "DocumentsDumpStartDate , Companies, ExportModeOnDemand, ManualExchange";
	
EndFunction

Procedure AccountingSettingsCheckHandler(Cancel, Recipient, Message) Export
	
	
EndProcedure

Function ExchangePlanUsedSaaS() Export
	
	Return True;
	
EndFunction

Function AccountingSettingsSetupComment() Export
	
	Return "";
	
EndFunction

// Returns the string with brief description of data exchange displayed on the first page of Data exhange creation assistant.
// 
// Used starting from SSL 2.1.2
//
Function BriefInformationOnExchange(SettingID) Export
	
	ExplanationText = NStr("en='	Enables data synchronization between the applications of 1C:Small business, ed. 1.5 and 1C:Accounting 8, ed. 3.0. From Small Business application to Accounting Enterprise application all catalogs and necessary documents are transferred; from Accounting Enterprise application to Small Business application catalogs and documents of cash management are transferred. For more information click on the Detailed Description link.';ru='	Позволяет синхронизировать данные между приложениями 1С:Управление небольшой фирмой, ред. 1.5 и 1С:Бухгалтерия предприятия 8, ред. 3.0. Из приложения Управление небольшой фирмой в приложение Бухгалтерия предприятия переносятся справочники и все необходимые документы, а из приложения Бухгалтерия предприятия в приложение Управление небольшой фирмой - справочники и документы учета денежных средств. Для получения более подробной информации нажмите на ссылку Подробное описание.';vi='	Cho phép đồng bộ hóa dữ liệu giữa các ứng dụng của 1C:Quản lý doanh nghiệp, phiên bản 1.5 và Kế toán doanh nghiệp, phiên bản 3.3. Sẽ chuyển danh mục và tất cả chứng từ cần thiết từ ứng dụng 1C:Quản lý doanh nghiệp sang Kế toán doanh nghiệp, còn sẽ chuyển danh mục và chứng từ ghi nhận vốn bằng tiền từ giải pháp Kế toán doanh nghiệp sang giải pháp 1C:Quản lý doanh nghiệp. Để nhận thông tin chi tiết hơn, hãy nhấn vào tham chiếu Mô tả chi tiết.'");
	
	Return ExplanationText;
	
EndFunction // BriefInformationOnExchange()

// Returns the reference to web page or full path to a form inside the configuration in a string
// 
Function DetailedInformationAboutExchange(SettingID) Export
	
	If GetFunctionalOption("SaaS") Then
		PathToExchangeInformation = "";
	Else
		PathToExchangeInformation = "ExchangePlan.ExchangeCompanyManagementAccounting.Form.ExchangeDetailedInformationForm";
	EndIf;
	
	Return PathToExchangeInformation;
	
EndFunction

// Procedure gets additional data used during setting an exchange in the correspondent base.
//
//  Parameters:
// AdditionalData - Structure. Additional data that
// will be used in the correspondent base during the exchange setting.
// Only values supporting XDTO-serialization are applied as structure values.
//
Procedure GetMoreDataForCorrespondent(AdditionalInformation) Export
	
EndProcedure

// Returns the name of configurations family. 
// Used to support exchanges with configurations changes in service.
//
Function SourceConfigurationName() Export
	
	Return "SmallBusiness";
	
EndFunction // SourceConfigurationName()

//////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR EXCHANGE THROUGH EXTERNAL CONNECTION

// Returns the filters structure on the exchange plan node of correspondent base with set default values;
// Structure of the settings repeats the content of header attributes and tabular sections of an exchange plan of a correspondent base;
// Structure items similar in key and value are used for
// header attributes. Structures containing arrays of
// tabular sections values of exchange plan parts are used for tabular sections.
// 
// Parameters:
//  No.
// 
// Returns:
//  SettingsStructure - Structure - structure of filters on the exchange plan node of a correspondent base
// 
Function CorrespondentInfobaseNodeFilterSetup(CorrespondentVersion, FormName, SettingID) Export
	
	CounterpartyTabularSectionStructure = New Structure;
	CounterpartyTabularSectionStructure.Insert("Company", New Array);
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("DocumentsDumpStartDate",      BegOfYear(CurrentDate()));
	SettingsStructure.Insert("UseCompaniesFilter",   False);
	SettingsStructure.Insert("Companies",                       CounterpartyTabularSectionStructure);
	
	Return SettingsStructure;
	
EndFunction

// Returns the default values structure for a correspondent base node;
// Settings structure repeats the attributes content of exchange plan header of a correspondent base;
// For the header attributes structure items similar by key and the structure item value are used.
// 
// Parameters:
//  No.
// 
// Returns:
//  SettingsStructure - Structure - structure of default values on the exchange plan node of a correspondent base
//
Function CorrespondentInfobaseNodeDefaultValues(CorrespondentVersion, FormName, SettingID) Export
	
	SettingsStructure = New Structure;
	
	If Not CommonUseReUse.DataSeparationEnabled() Then
		
		SettingsStructure.Insert("CostsItem",                     "");
		SettingsStructure.Insert("CostsItem_Key",                "");
		SettingsStructure.Insert("OtherIncomeCostsItem",      "");
		SettingsStructure.Insert("OtherIncomeCostsItem_Key", "");
		SettingsStructure.Insert("ServiceRewards",           "");
		SettingsStructure.Insert("ServiceRewards_Key",      "");
		SettingsStructure.Insert("CostsReflectionMethod",          "");
		SettingsStructure.Insert("CostsReflectionMethod_Key",     "");
		
	EndIf;
	
	Return SettingsStructure;
	
EndFunction

// Returns a description string of migration restrictions of the data for a correspondent base that is displayed to the user;
// Application developer creates a user-friendly restrictions description string based on the set filters in the correspondent base node.
// 
// Parameters:
//  FilterSettingsAtNode - Structure - structure of filters on the node
//                                       of the exchange plan of a correspondent base received using the FiltersSettingOnCorrespondentBaseNode() function.
// 
// Returns:
//  String, Unlimited. - String of restrictions description of the data migration for a user
//
Function CorrespondentInfobaseDataTransferRestrictionDetails(FilterSettingsAtNode, CorrespondentVersion, SettingID) Export
	
	Return "";
	
EndFunction

// Returns a string of default values description for a correspondent base that is displayed to a user;
// Application developer creates a user-friendly description string based on the default values in the correspondent base node.
// 
// Parameters:
//  DefaultValuesAtNode - Structure - structure of default values on the exchange plan
//                                       node of the correspondent base received using the DefaultValuesOnCorrespondentBaseNode() function.
// 
// Returns:
//  String, Unlimited. - description string for default values user
//
Function CorrespondentInfobaseDefaultValueDetails(DefaultValuesAtNode, CorrespondentVersion, SettingID) Export
	
	TextDescription = "";
	
	If Not CommonUseReUse.DataSeparationEnabled() Then
		
		TextDescription = NStr("en='Main cost item for the lookup into documents by default: %Value%';ru='Основная статья затрат для подстановки в документы по умолчанию: %Значение%';vi='Dạng chi phí chính để điền vào chứng từ theo mặc định: %Value%'");
		If ValueIsFilled(DefaultValuesAtNode.CostsItem) Then
			TextDescription = StrReplace(TextDescription, "%Value%", String(DefaultValuesAtNode.CostsItem));
		Else
			TextDescription = StrReplace(TextDescription, "%Value%", NStr("en='not specified';ru='не указан';vi='chưa chỉ ra'"));
		EndIf;
		
		TextDescription = TextDescription + Chars.LF + Chars.LF + NStr("en='Main item of other income and expenses to insert into documents by default: %Value%';ru='Основная статья прочих доходов и расходов для подстановки в документы по умолчанию: %Значение%';vi='Dạng thu nhập và chi phí chính để điền vào các chứng từ theo mặc định: %Value%'");
		If ValueIsFilled(DefaultValuesAtNode.OtherIncomeCostsItem) Then
			TextDescription = StrReplace(TextDescription, "%Value%", String(DefaultValuesAtNode.OtherIncomeCostsItem));
		Else
			TextDescription = StrReplace(TextDescription, "%Value%", NStr("en='not specified';ru='не указан';vi='chưa chỉ ra'"));
		EndIf;
		
		TextDescription = TextDescription + Chars.LF + Chars.LF + NStr("en='Commission service to insert into the Report document to the default principal: %Value%';ru='Услуга по комиссионному вознаграждению для подстановки в документ Отчет комитенту по умолчанию: %Значение%';vi='Dịch vụ hoa hồng ký gửi để điền vào chứng từ Bảng kê dành cho người đặt ký gửi theo mặc định: %Value%'");
		If ValueIsFilled(DefaultValuesAtNode.ServiceRewards) Then
			TextDescription = StrReplace(TextDescription, "%Value%", String(DefaultValuesAtNode.ServiceRewards));
		Else
			TextDescription = StrReplace(TextDescription, "%Value%", NStr("en='not specified';ru='не указан';vi='chưa chỉ ra'"));
		EndIf;
		
		TextDescription = TextDescription + Chars.LF + Chars.LF + NStr("en='Expense recording method to populate the Material commissioning document: %Value%';ru='Способ отражения расходов для заполнения документа Передача материалов в эксплуатацию: %Значение%';vi='Phương pháp phản ánh chi phí để điền chứng từ Chuyển nguyên vật liệu vào sử dụng: %Value%'");
		If ValueIsFilled(DefaultValuesAtNode.CostsReflectionMethod) Then
			TextDescription = StrReplace(TextDescription, "%Value%", String(DefaultValuesAtNode.CostsReflectionMethod));
		Else
			TextDescription = StrReplace(TextDescription, "%Value%", NStr("en='Not specified';ru='Не указан';vi='Chưa chỉ ra'"));
		EndIf;
		
	EndIf;
	
	Return TextDescription;

EndFunction

Function CorrespondentInfobaseAccountingSettingsSetupComment(CorrespondentVersion) Export
	
	Return "";
	
EndFunction

// Function returns the name of data export processor
//
Function DumpProcessingName() Export
	
	Return "ExportHandlersToEnterpriseAccounting30";
	
EndFunction // ExportProcessorName()

// Function returns the name of data import processor
//
Function ImportProcessingName() Export
	
	Return "ImportHandlersFromEnterpriseAccounting30";
	
EndFunction // ImportProcessorName()

// Function should return:
// True if the correspondent supports the exchange scenario in which the current IB works in local mode, while correspondent works in service model. 
// 
// False - if such exchange scenario is not supported.
//
Function CorrespondentSaaS() Export
	
	Return Not True;
	
EndFunction // CorrespondentSaaS()

////////////////////////////////////////////////////////////////////////////////
// OTHER PROCEDURES AND FUNCTIONS.

// Initializes export mode for all nodes when necessary
//
Procedure InitializeExportModeOnDemand() Export
	
	Query = New Query("SELECT
	                      |	PSU.Ref
	                      |FROM
	                      |	ExchangePlan.ExchangeCompanyManagementAccounting AS PSU
	                      |WHERE
	                      |	PSU.Ref <> &ThisNode
	                      |	AND CASE
	                      |			WHEN PSU.ExportModeOnDemand <> VALUE(Enum.ExchangeObjectsExportModes.ExportIfNecessary)
	                      |				THEN TRUE
	                      |			ELSE FALSE
	                      |		END = TRUE");
						  
	Query.SetParameter("ThisNode", ExchangePlans.ExchangeCompanyManagementAccounting.ThisNode());	
	
	NodesSelection = Query.Execute().Select();
	While NodesSelection.Next() Do
		
		ExchangePlanNodeObject = NodesSelection.Ref.GetObject();
		ExchangePlanNodeObject.ExportModeOnDemand = Enums.ExchangeObjectsExportModes.ExportIfNecessary;
		ExchangePlanNodeObject.AdditionalProperties.Insert("Import");
		ExchangePlanNodeObject.Write();
		
		InformationRegisters.NodesCommonDataChange.RecordChanges(ExchangePlanNodeObject.Ref);
		
	EndDo;
	
EndProcedure

//Returns the work script of
//the interactive match assistant NotSend, InteractiveDocumentsSynchronization, InteractiveCatalogsSynchronization or any empty row
Function InitializeScriptJobsAssistantInteractiveExchange(InfobaseNode) Export
	
	If InfobaseNode.ManualExchange Then
		
		Return "OnlineSynchronizationDocuments";
		
	EndIf;
	
EndFunction

// Returns shortened string presentation of values collection
// 
// Parameters:
//  Collection 						- array or list of values.
//  MaximumCountElements - number, maximum number of items included into the presentation.
//
// Returns:
//  Row.
//
Function ShortPresentationOfCollectionsOfValues(Collection, MaximumCountElements = 3) Export
	
	PresentationRow = "";
	
	ValueCount			 = Collection.Count();
	QuantityOfOutputElements = min(ValueCount, MaximumCountElements);
	
	If QuantityOfOutputElements = 0 Then
		
		Return "";
		
	Else
		
		For ValuesNumber = 1 To QuantityOfOutputElements Do
			
			PresentationRow = PresentationRow + Collection.Get(ValuesNumber - 1) + ", ";	
			
		EndDo;
		
		PresentationRow = Left(PresentationRow, StrLen(PresentationRow) - 2);
		If ValueCount > QuantityOfOutputElements Then
			PresentationRow = PresentationRow + ", ... ";
		EndIf;
		
	EndIf;
	
	Return PresentationRow;
	
EndFunction

// Specifies the array of nodes on which the object will be registered
//
Function IdentifyArrayOfRecipients(Exporting, Object, Recipients) Export
	
	SetPrivilegedMode(True);
	
	If Exporting Then
		Return Recipients;
	EndIf;
	
	If Object.AdditionalProperties.Property("NodesForRegistration")
		AND TypeOf(Object.AdditionalProperties.NodesForRegistration) = Type("Array") Then
		
		Recipients = Object.AdditionalProperties.NodesForRegistration;
		
		Return Recipients;
	EndIf;
	
	ExcludingNodesArray = New Array;
	
	For Each Node IN Recipients Do
		
		If Node.ManualExchange Then
			
			ExcludingNodesArray.Add(Node);
			
		ElsIf Node.UseDocumentTypesFilter Then
			
			If Node.DocumentKinds.Find(Object.Metadata().Name, "MetadataObjectName") = Undefined Then
				ExcludingNodesArray.Add(Node);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Recipients = CommonUseClientServer.ReduceArray(Recipients, ExcludingNodesArray);
	
	Return Recipients;
	
EndFunction

// Registers the documents associated with passed document by the reference.
//
Procedure RegisterRelatedDocuments(Exporting, Object, ORR, Recipients) Export
	
	SetPrivilegedMode(True);
	
	If Exporting
		OR Object = Undefined Then
		Return;
	EndIf;
	
	ArrayOfRegisteredDocuments = Undefined;
	Object.AdditionalProperties.Property("RegisteredDocuments", ArrayOfRegisteredDocuments);
	If TypeOf(ArrayOfRegisteredDocuments) <> Type("Array") Then
		ArrayOfRegisteredDocuments = New Array;
	EndIf;
	
	If ArrayOfRegisteredDocuments.Find(Object.Ref) = Undefined Then
		ArrayOfRegisteredDocuments.Add(Object.Ref);
	EndIf;
	
	NodeArrayForRegistration = New Array;
	For Each RecipientNode IN Recipients Do
		If RecipientNode.UseDocumentTypesFilter
			OR RecipientNode.ManualExchange Then
			NodeArrayForRegistration.Add(RecipientNode);
		EndIf;
	EndDo;
	
	If NodeArrayForRegistration.Count() = 0 Then
		Return;
	EndIf;
	
	RelatedDocuments = New ValueTable;
	RelatedDocuments.Columns.Add("Document");
	
	If TypeOf(Object) = Type("DocumentObject.ExpenseReport") Then
		
		For Each TabularSectionRow IN Object.AdvancesPaid Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
		For Each TabularSectionRow IN Object.Payments Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.AcceptanceCertificate") Then
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.AdditionalCosts") Then
		
		For Each TabularSectionRow IN Object.Inventory Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.ReceiptDocument;
		EndDo;
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.CustomerOrder")
		AND Object.OperationKind = Enums.OperationKindsCustomerOrder.JobOrder Then
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.AgentReport") Then
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.ReportToPrincipal") Then
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.ProcessingReport") Then
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.SubcontractorReport") Then
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.CashReceipt") Then
		
		For Each TabularSectionRow IN Object.PaymentDetails Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.PaymentReceipt") Then
		
		For Each TabularSectionRow IN Object.PaymentDetails Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.SupplierInvoice") Then
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.CashPayment") Then
		
		For Each TabularSectionRow IN Object.PaymentDetails Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.CustomerInvoice") Then
		
		For Each TabularSectionRow IN Object.Prepayment Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.PaymentExpense") Then
		
		For Each TabularSectionRow IN Object.PaymentDetails Do
			NewRow = RelatedDocuments.Add();
			NewRow.Document = TabularSectionRow.Document;
		EndDo;
		
	EndIf;
	
	RelatedDocuments.GroupBy("Document");
	If RelatedDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	For Each TableRow IN RelatedDocuments Do
		
		If Not ValueIsFilled(TableRow.Document) Then
			Continue;
		EndIf;
		
		DocumentObject = TableRow.Document.GetObject();
		If DocumentObject = Undefined Then
			Continue;
		EndIf;
		
		If ArrayOfRegisteredDocuments.Find(DocumentObject.Ref) <> Undefined Then
			Continue;
		EndIf;
		
		DocumentObject.AdditionalProperties.Insert("NodesForRegistration", NodeArrayForRegistration);
		DocumentObject.AdditionalProperties.Insert("RegisteredDocuments", ArrayOfRegisteredDocuments);
		DataExchangeEvents.ExecuteRegistrationRulesForObject(DocumentObject, ORR.ExchangePlanName, Undefined);
		
	EndDo;
	
EndProcedure

//Returns startup mode in case of
//interactive activation of synchronization Return
//values AutomaticSynchronization Or InteractiveSynchronization On the basis of these values either interactive exchange assistant or automatic exchange is started
Function RunModeSynchronizationData(InfobaseNode) Export
	
	If InfobaseNode.ManualExchange Then
		
		Return "InteractiveSynchronization";
		
	Else
		
		Return "AutomaticSynchronization";
		
	EndIf;
	
EndFunction

//Returns the restrictions values of exchange plan nodes objects for interactive
//registration for exchange Structure:
//AllDocuments, AllCatalogs, DetailedFilter Detailed filter or undefined, or array of metadata objects included into node structure (full name of metadata is specified)
Function AddGroupsRestrictions(InfobaseNode) Export
	//Example of standard return
	Return New Structure("AllDocuments, AllCatalogs, DetailedFilter", False, False, Undefined);
EndFunction

Function RulesTemplateName() Export
	Return "ExchangeRules";
EndFunction

Function RulesTemplateNameCorrespondent() Export
	
	Return "CorrespondentExchangeRules";
	
EndFunction

Function RulesTemplateNameRegistration() Export
	
	Return "RegistrationRules";
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

// Handler of the event during connection to the correspondent.
// Event appears if the connection to correspondent is successful and configuration
// version of correspondent during exchange setting using assistant through
// a direct connection is received or if a correspondent is connected through the Internet.
// IN the handler, you can analyze
// correspondent version and if an exchange setting is not supported by a correspondent of a specified version, then call an exception.
//
//  Parameters:
// CorrespondentVersion (read only) - String - version of a correspondent configuration, for example, 2.1.5.1.
//
Procedure OnConnectingToCorrespondent(CorrespondentVersion) Export
	
EndProcedure

// Handler of the event during sending data of a node-sender.
// Event occurs during sending the data of node-sender from the
// current base to the correspondent before placing the data to exchange messages.
// You can change the sent data or deny sending the node data in the handler.
//
//  Parameters:
// Sender - ExchangePlanObject - exchange plan node from the name of which data is sent.
// Ignore - Boolean - shows that the node data export is denied.
//                         If you set the True value of
//                         this parameter in the handler, the data of node will not be sent. Default value - False.
//
Procedure OnDataSendingSender(Sender, Ignore) Export
	
EndProcedure

// Handler of the event during receiving data of a node-sender.
// Event appears during receiving
// data of a node-sender when node data is read from an exchange message but not written to the infobase.
// You can change the received data or deny receiving the node data in the handler.
//
//  Parameters:
// Sender - ExchangePlanObject - exchange plan node from the name of which data is received.
// Ignore - Boolean - shows that the node data receipt is denied.
//                         If you set the True value of
//                         this parameter in the handler, the data of node will not be received. Default value - False.
//
Procedure OnSendersDataGet(Sender, Ignore) Export
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Overridable setting of export addon

// It is intended to set variants of online export setting by the node script.
// For setting you need to set parameters properties values to the required values.
//
// Parameters:
//     Recipient - ExchangePlanRef - Node for which
//     the Parameters setting is executed  - Structure        - Parameters for change. Contains fields:
//
//         VariantNoneAdds - Structure     - settings of the "Do not add" typical variant.
//                                                Contains fields:
//             Use - Boolean - flag showing the permission to use variant. True by default.
//             Order       - Number  - order of a variant placement on the assistant form, downward. Default 1.
//             Title     - String - allows to predefine the name of a typical variant.
//             Explanation     - String - allows to predefine a text of a variant explanation for a user.
//
//         VariantAllDocuments - Structure      - settings of the "Add all documents for the period" typical variant.
//                                                Contains fields:
//             Use - Boolean - flag showing the permission to use variant. True by default.
//             Order       - Number  - order of a variant placement on the assistant form, downward. Default 2.
//             Title     - String - allows to predefine the name of a typical variant.
//             Explanation     - String - allows to predefine a text of a variant explanation for a user.
//
//         VariantArbitraryFilter - Structure - settings of the Add data with arbitrary selection typical variant.
//                                                Contains fields:
//             Use - Boolean - flag showing the permission to use variant. True by default.
//             Order       - Number  - order of a variant placement on the assistant form, downward. Default 3.
//             Title     - String - allows to predefine the name of a typical variant.
//             Explanation     - String - allows to predefine a text of a variant explanation for a user.
//
//         VariantAdditionally - Structure     - additional variant settings by the node script.
//                                                Contains fields:
//             Use            - Boolean            - flag showing the permission to use variant. False by default.
//             Order                  - Number             - order of a variant placement on the assistant form, downward. Default 4.
//             Title                - String            - variant name for displaying on the form.
//             FormNameFilter           - String            - Name of the form called for settings editing.
//             FormCommandTitle    - String            - Title for a rendering a settings form opening command in the form.
//             UsePeriodFilter - Boolean            - check box showing that a common filter by a period is required. False by default.
//             FilterPeriod             - StandardPeriod - value of common filter period offered by default.
//
//             Filter                    - ValueTable   - contains strings with detailed description of the filters by the node script.
//                                                            Contains columns:
//                 FullMetadataName - String                - full name of registered object metadata whose filter is described by the row.
//                                                               For example, Document._DemoProductsReceipt. You  can use the
// AllDocuments  and  AllCatalogs  special  values      for  filtering  all  documents  and  all  catalogs  being  registered  on  the  Recipient  node.
//                 PeriodSelection        - Boolean                - flag showing that this string describes the filter with the common period.
//                 Period              - StandardPeriod     - value of common filter period for row metadata line offered by default.
//                 Filter               - DataCompositionFilter - default filter. Selection fields are generated according to
//                                                               the general rules of generating layout fields. For example, to specify
//                                                               a filter by the Company document attribute, you need to use the Ref.Company field
//
Procedure CustomizeInteractiveExporting(Recipient, Parameters) Export
	
	//
	// Usage example in demo SSL 2.1.5.12 (SW._DemoExchangeWithStandardSubsystemsLibrary)
	//
	
EndProcedure

// Returns filter presentation for an addition variant of
// export by a node script. See description of VarianAdditionally in the SetInteractiveExport procedure
//
// Parameters:
//     Recipient - ExchangePlanRef - Node for which the presentation
//     of the Parameters filter is determined  - Structure        - Filter characteristics. Contains fields:
//         UsePeriodFilter - Boolean            - flag showing that you are required to use a common filter by period.
//         FilterPeriod             - StandardPeriod - value of general filter period.
//         Filter                    - ValueTable   - contains strings with detailed description of the filters by the node script.
//                                                        Contains columns:
//                 FullMetadataName - String                - full name of registered object metadata whose filter is described by the row.
//                                                               For example, Document._DemoProductsReceipt. The AllDocuments and
// AllCatalogs special values can be used for filtering all documents and all catalogs being registered on the
// Receiver node.
//                 PeriodSelection        - Boolean                - flag showing that this string describes the filter with the common period.
//                 Period              - StandardPeriod     - value of a common filter period for a row metadata.
//                 Filter               - DataCompositionFilter - filter fields. Selection fields are generated according to
//                                                               the general rules of generating layout fields. For example, to specify
//                                                               a filter by the Company document attribute, the Ref.Company field will be used
//
// Returns: 
//     String - filter description
//
Function FilterPresentationInteractiveExportings(Recipient, Parameters) Export
	
	//
	// Usage example in demo SSL 2.1.5.12 (SW._DemoExchangeWithStandardSubsystemsLibrary)
	//
	
EndFunction

Procedure FillCorrespondenceBaseName(CorrBases) Export
	
	CorrBases.Add("Accounting3", Nstr("en='1C:Enterprise Accounting';ru='Обмен с 1С:Бухгалтерия Предприятия';vi='Trao đổi 1C: Kế toán 3.3'"));
	CorrBases.Add("Accounting4", Nstr("en='1C:Finance & Accounting';ru='Обмен с 1C:Finance & Accounting';vi=' Trao đổi 1C:Finance & Accounting'"));

	//SubsystemExchangePlans.Add(Metadata.ExchangePlans.ExchangeCompanyManagementAccounting.Name, Nstr("en='1C:Enterprise Accounting';ru='Обмен с 1С:Бухгалтерия Предприятия';vi='Trao đổi 1C: Kế toán 3.3'"));
	//SubsystemExchangePlans.Add(Metadata.ExchangePlans.ExchangeCompanyManagementAccounting.Name, Nstr("en='1C:Vietnam Accounting';ru='Обмен с 1С:Бухгалтерия Вьетнама';vi='Trao đổi với Kế toán 3.3'"));
//	SubsystemExchangePlans.Add(Metadata.ExchangePlans.ExchangeCompanyManagementAccounting40);

	
	
EndProcedure

#EndIf