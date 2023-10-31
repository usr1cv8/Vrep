

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	// Serial numbers
	If WorkWithSerialNumbers.UseSerialNumbersBalance() = True Then
	
		For Each StringInventory In Inventory Do
			If StringInventory.ProductsAndServices.UseSerialNumbers Then
				FilterSerialNumbers = New Structure("ConnectionKey", StringInventory.ConnectionKey);
				FilterSerialNumbers = SerialNumbers.FindRows(FilterSerialNumbers);
				
				If TypeOf(StringInventory.MeasurementUnit)=Type("CatalogRef.UOM") Then
				    Ratio = StringInventory.MeasurementUnit.Ratio;
				Else
					Ratio = 1;
				EndIf;
				
				RowInventoryQuantity = StringInventory.Quantity * Ratio;
				
				If FilterSerialNumbers.Count() <> RowInventoryQuantity Then
					MessageText = NStr("en='The quantity of serial numbers differs from the quantity of units in line %Number%.';ru='Число серийных номеров отличается от количества единиц в строке %Number%.';vi='Số lượng sê-ri khác với số lượng đơn vị tính tại dòng %Number%.'");
					MessageText = MessageText + NStr("en='Serial numbers - %QuantityOfNumbers%, need %QuantityInRow%';ru=' Серийных номеров - %QuantityOfNumbers%, нужно %QuantityInRow%';vi=' Số sê-ri - %QuantityOfNumbers%, cần %QuantityInRow%'");
					MessageText = StrReplace(MessageText, "%Number%", StringInventory.LineNumber);
					MessageText = StrReplace(MessageText, "%QuantityOfNumbers%", FilterSerialNumbers.Count());
					MessageText = StrReplace(MessageText, "%QuantityInRow%", RowInventoryQuantity);
					
					Message = New UserMessage();
					Message.Text = MessageText;
					Message.Message();
					
				EndIf;
			EndIf; 
		EndDo;
	
	EndIf;
EndProcedure


Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	FillStructuralUnitsTypes();
	
EndProcedure

Procedure FillStructuralUnitsTypes() Export
		
	StructuralUnitType = CommonUse.ObjectAttributeValue(StructuralUnit, "StructuralUnitType");
	
EndProcedure
