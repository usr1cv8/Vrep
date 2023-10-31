
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Установим настройки формы для случая открытия в режиме выбора
	Items.List.ChoiceMode = Parameters.ChoiceMode;
	Items.List.MultipleChoice = ?(Parameters.CloseOnChoice = Undefined, False, Not Parameters.CloseOnChoice);
	If Parameters.ChoiceMode Then
		PurposeUseKey = "PickupSelection";
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	Else
		PurposeUseKey = "List";
	EndIf;
	
EndProcedure

#EndRegion