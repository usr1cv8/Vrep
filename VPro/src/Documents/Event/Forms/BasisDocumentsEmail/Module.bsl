#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AddressInBasisDocumentsStorage = Parameters.AddressInBasisDocumentsStorage;
	BasisDocuments.Load(GetFromTempStorage(AddressInBasisDocumentsStorage));
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OK(Command)
	
	Cancel = False;
	
	CheckFillOfFormAttributes(Cancel);
	
	If Not Cancel Then
		WriteBasisDocumentsToStorage();
		Close(DialogReturnCode.OK);
	EndIf;

EndProcedure

#EndRegion

#Region CommonUseProceduresAndFunctions

// Procedure checks the correctness of the form attributes filling.
//
&AtClient
Procedure CheckFillOfFormAttributes(Cancel)
	
	// Attributes filling check.
	LineNumber = 0;
		
	For Each RowDocumentsBases IN BasisDocuments Do
		LineNumber = LineNumber + 1;
		If Not ValueIsFilled(RowDocumentsBases.BasisDocument) Then
			Message = New UserMessage();
			Message.Text = NStr("en='Column ""Basis document"" is not filled in line ';ru='Не заполнена колонка ""Документ основание"" в строке ';vi='Chưa điền cột ""Chứng từ cơ sở"" trong dòng'")
				+ String(LineNumber)
				+ NStr("en=' of list ""Basis documents"".';ru=' списка ""Документы основания""..';vi=' danh sách ""Chứng từ cơ sở""..'");
			Message.Field = "Document";
			Message.Message();
			Cancel = True;
		EndIf;
	EndDo;
	
EndProcedure // CheckFillFormAttributes()

// The procedure places pick-up results in the storage.
//
&AtServer
Procedure WriteBasisDocumentsToStorage()
	
	BasisDocumentsInStorage = BasisDocuments.Unload(, "BasisDocument");
	PutToTempStorage(BasisDocumentsInStorage, AddressInBasisDocumentsStorage);
	
EndProcedure // WritePickToStorage()

#EndRegion
