
&AtClient
Procedure Rename(Command)
	ThisForm.Close(VariantName);
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	VariantName = Parameters.VariantName;
EndProcedure
