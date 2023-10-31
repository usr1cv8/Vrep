
#Region ProgramInterface

// Процедура заполняет список выбора времени.
// Parameters:
//  FormInputField  - элемент-владелец списка,
//  Interval        - интервал, с которым необходимо заполнить список, по умолчанию час.
Procedure ЗаполнитьСписокВыбораВремени(FormInputField, Interval = 3600, Begin = '00010101080000', End = '00010101200000') Export
	
	TimeList = FormInputField.ChoiceList;
	TimeList.Clear();
	
	ListTime = BegOfHour(Begin);
	
	While BegOfHour(ListTime) <= BegOfHour(End) Do
		
		If Not ValueIsFilled(ListTime) Then
			TimePresentation = "00:00";
		Else
			TimePresentation = Format(ListTime,"DF=ЧЧ:мм");
		EndIf;
		
		TimeList.Add(ListTime, TimePresentation);
		
		ListTime = ListTime + Interval;
		
	EndDo;
	
EndProcedure

Function ПроверитьКорректностьАдресаЭлектроннойПочты(Address) Export
	
	ErrorText = "";
	CheckResult = CommonUseClientServer.ParseStringWithPostalAddresses(Address, False);
	
	For Each ПроверенныйАдрес In CheckResult Do
		If Not ValueIsFilled(ПроверенныйАдрес.Address)
			Or Not CommonUseClientServer.EmailAddressMeetsRequirements(ПроверенныйАдрес.Address) Then
			
			ErrorText = NStr("en='The email address you specified is incorrect.';ru='Указан некорректный адрес электронной почты.';vi='Địa chỉ email nhập không đúng.'");
			Break;
		EndIf;
	EndDo;
	
	Return ErrorText;
	
EndFunction

#EndRegion
