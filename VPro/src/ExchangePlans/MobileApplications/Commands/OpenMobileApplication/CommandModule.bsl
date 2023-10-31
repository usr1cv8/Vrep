
&AtClient
Procedure ОбработкаКоманды(ПараметрКоманды, ПараметрыВыполненияКоманды)
	
	If ЕстьПланыОбмена() Then
		ОткрытьФорму("ExchangePlan.MobileApplications.ListForm",
			,
			,
			ПараметрКоманды,
			ПараметрыВыполненияКоманды.Окно
		);
	Else
		ОткрытьФорму("ExchangePlan.MobileApplications.Form.ConnectionForm",
			,
			,
			ПараметрКоманды,
			ПараметрыВыполненияКоманды.Окно
		);
	EndIf;
	
EndProcedure

&AtServer
Функция ЕстьПланыОбмена()
	
	ВыборкаПлановОбмена = ПланыОбмена.MobileApplications.Выбрать();
	ВыборкаПлановОбмена.Следующий();
	If ВыборкаПлановОбмена.Следующий() Then
		Return True;
	Else
		Return False;
	EndIf;
	
КонецФункции
