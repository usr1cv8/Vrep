#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure PresentationFieldsReceiveDataProcessor(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Date");
	Fields.Add("EventType");
	
EndProcedure

Procedure PresentationReceiveDataProcessor(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	Presentation = NStr("en='Event: ';vi='Sự kiện: ';") + Data.EventType + NStr("en=' dated ';vi='  '") + Format(Data.Date, "DF=dd.MM.yyyy");
	
EndProcedure

Procedure FormGetProcessing(FormKind, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormKind <> "DocumentForm"
		AND FormKind <> "ObjectForm" Then
		Return;
	EndIf;
	
	EventType = Undefined; 
	
	If Parameters.Property("Key") AND ValueIsFilled(Parameters.Key) Then
		EventType	= CommonUse.ObjectAttributeValue(Parameters.Key, "EventType");
	EndIf;
	
	// If the document is copied that we get event type from copied document.
	If Not ValueIsFilled(EventType) Then
		If Parameters.Property("CopyingValue")
			AND ValueIsFilled(Parameters.CopyingValue) Then
			EventType = CommonUse.ObjectAttributeValue(Parameters.CopyingValue, "EventType");
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(EventType) Then
		If Parameters.Property("FillingValues") 
			AND TypeOf(Parameters.FillingValues) = Type("Structure") Then
			If Parameters.FillingValues.Property("EventType") Then
				EventType	= Parameters.FillingValues.EventType;
			EndIf;
		EndIf;
	EndIf;
	
	StandardProcessing = False;
	EventForms = GetOperationKindMapToForms();
	SelectedForm = EventForms[EventType];
	If SelectedForm = Undefined Then
		SelectedForm = "DocumentForm";
	EndIf;

EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

Function GetOperationKindMapToForms() Export

	EventForms = New Map;
	EventForms.Insert(Enums.EventTypes.Email, 			"EmailForm");
	EventForms.Insert(Enums.EventTypes.SMS,				"MessagesSMSForm");
	EventForms.Insert(Enums.EventTypes.PhoneCall,		"EventForm");
	EventForms.Insert(Enums.EventTypes.PersonalMeeting,	"EventForm");
	EventForms.Insert(Enums.EventTypes.Other,			"EventForm");
	EventForms.Insert(Enums.EventTypes.Record,			"FormEventCounterpartyRecord");
	
	Return EventForms;

EndFunction 

#EndRegion

#Region PrintInterface

// Fills in the list of printing commands.
// 
// Parameters:
//   PrintCommands - ValueTable - see fields' content in the PrintManagement.CreatePrintCommandsCollection function.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

#EndRegion

#Region Interface

Function GetHowToContact(Contact, IsEmail = False) Export
	
	Result = "";
	
	Contacts = New Array;
	Contacts.Add(Contact);
	
	TypesCI = New Array;
	TypesCI.Add(Enums.ContactInformationTypes.EmailAddress);
	If Not IsEmail Then
		TypesCI.Add(Enums.ContactInformationTypes.Phone);
	EndIf;
	
	TableCI = ContactInformationManagement.ObjectsContactInformation(Contacts, TypesCI);
	TableCI.Sort("Type DESC");
	For Each RowCI In TableCI Do
		Result = "" + Result + ?(Result = "", "", ", ") + RowCI.Presentation;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region EmailSB

Function SubjectWithResponsePrefix(Subject, Command) Export
	
	If Command = EmailSBClientServer.CommandReply() Then
		
		If StrStartWith(Upper(Subject), "RE:") Then
			Return Subject;
		EndIf;
		
		Return StrTemplate("Re: %1", Subject);
		
	ElsIf Command = EmailSBClientServer.CommandForward() Then
		
		If StrStartWith(Upper(Subject), "Fw:") Then
			Return Subject;
		EndIf;
		
		Return StrTemplate("Fw: %1", Subject);
		
	Else
		
		Return Subject;
		
	EndIf;
	
EndFunction
	
#EndRegion

#Region WorkWithCalendar

// Функция определяет пиктограмму для элемента записи календаря
//
// Параметры:
//  Событие	 - ДокументСсылка.Событие	 - событие, для записи календаря которого подбирается картинка
// 
// Возвращаемое значение:
//  Картинка - пиктограмма записи календаря
//
Function CalendarRecordPicture(Event) Экспорт
	
	EventType = CommonUse.ObjectAttributeValue(Event, "EventType");
	СоответствиеТиповКартинкам = MapEventTypesPictures();
	Picture = СоответствиеТиповКартинкам[EventType];
	If Picture = Undefined Then
		Picture = New Picture;
	EndIf;
	
	Return Picture;
	
EndFunction

// Функция определяет цвет текста для элемента записи календаря
//
// Параметры:
//  Событие	 - ДокументСсылка.Событие	 - событие, для записи календаря которого подбирается цвет
// 
// Возвращаемое значение:
//  Цвет - цвет текста записи календаря
//
Function CalendarRecorTextColor(Event) Export
	
	StateColor = Event.State.Color.Get();
	If StateColor = Undefined Then
		StateColor = New Color;
	EndIf;
	
	Return StateColor;
	
EndFunction

// Процедура заполняет таблицу описаний расширенного ввода записи календаря
//
// Параметры:
//  ТаблицаОписаний	 - ТаблицаЗначений	 - описание колонок см. Справочник.ЗаписиКалендаряСотрудника.ПриЗаполненииРасширенногоВводаЗаписиКалендаря()
//
Процедура OnFillingExtendedInputCalendarRecorder(DescriptionTable) Export
	
	NewRow = DescriptionTable.Add();
	NewRow.FormName = "Document.Event.Form.EventForm";
	NewRow.FormParameters = New Structure("FillValue", New Structure("EventType", Enums.EventTypes.PersonalMeeting));
	NewRow.Presentation = NStr("en='Event: Meeting';ru='Событие: Личная встреча';vi='Sự kiện: Họp'");
	
	NewRow = DescriptionTable.Add();
	NewRow.FormName = "Document.Event.Form.EventForm";
	NewRow.FormParameters = New Structure("FillValue", New Structure("EventType", Enums.EventTypes.PhoneCall));
	NewRow.Presentation = NStr("en='Event: Phone call';ru='Событие: Телефонный звонок';vi='Sự kiện: Cuộc gọi điện thoại'");
	
	NewRow = DescriptionTable.Add();
	NewRow.FormName = "Document.Event.Form.EventForm";
	NewRow.FormParameters = New Structure("FillValue", New Structure("EventType", Enums.EventTypes.Other));
	NewRow.Presentation = NStr("en='Event: Other';ru='Событие: Прочее';vi='Sự kiện: Khác'");
	
КонецПроцедуры

#EndRegion

Function MapEventTypesPictures() Export
	
	MapEventTypesPictures = New Map;
	MapEventTypesPictures.Вставить(Enums.EventTypes.PersonalMeeting, PictureLib.ContactInformationAddress);
	MapEventTypesPictures.Вставить(Enums.EventTypes.Other, PictureLib.ContactInformationOther);
	MapEventTypesPictures.Вставить(Enums.EventTypes.SMS, PictureLib.ContactInformationPhone);
	MapEventTypesPictures.Вставить(Enums.EventTypes.PhoneCall, PictureLib.ContactInformationPhone);
	MapEventTypesPictures.Вставить(Enums.EventTypes.Email, PictureLib.ContactInformationEmail);
	MapEventTypesPictures.Вставить(Enums.EventTypes.Record, PictureLib.ТипСобытияЗапись);
	
	Return MapEventTypesPictures;
	
EndFunction


#EndIf