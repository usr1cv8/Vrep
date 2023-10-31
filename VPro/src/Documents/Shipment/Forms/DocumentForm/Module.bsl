
&AtClient
Procedure GetMap(Command)
	
	If Modified Then
		
		Message = New UserMessage;
		Message.Text = "Save the document";
		Message.Message();
		
		Return;
		
	EndIf;
	
	GetMapAtServer();
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure GetMapAtServer()
	
	// 1. Looking for coordinates
	
	structureCoordinates = GoogleMap.GetCoordinatesByAddress(Object.DeliveryAddress);
	
	// 2. Getting a map picture
	
	DeliveryMap = GoogleMap.GetMapPicture(structureCoordinates);
	
	RefMapPicture = PutToTempStorage(DeliveryMap, UUID);
	
EndProcedure
