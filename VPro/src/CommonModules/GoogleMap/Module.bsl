Function GoogleMapAPIKey()
	
	Return Constants.GoogleMapAPIKey.Get();
	
EndFunction
	
Function GetCoordinatesByAddress(Address) Export
	
	structureResult = New Structure;
	
	structureResult.Insert("longitude", 0);
	
	structureResult.Insert("latitude", 0);
	
	HTTPConnection = New HTTPConnection("maps.googleapis.com", , , , , , New OpenSSLSecureConnection());
	
	RequestText = "maps/api/geocode/json?address=" + Address + "&key=" + GoogleMapAPIKey();
	
	HTTPRequest = New HTTPRequest(RequestText);
	
	Try
		
		Answer = HTTPConnection.Get(HTTPRequest);
		
	Except
	
		Message("Error determining the coordinates!", MessageStatus.Attention);
		
		Return structureResult;
		
	EndTry;
	
	JSONReader = New JSONReader();
	
	JSONReader.SetString(Answer.GetBodyAsString());
	
	Result = ReadJSON(JSONReader);
	
	JSONReader.Close();
	
	If Result.status = "OK" Then
		
		structureResult.latitude = Result.results[0].geometry.location.lat;
		
		structureResult.longitude = Result.results[0].geometry.location.lng;
		
	EndIf;
	
	Return structureResult;

EndFunction

Function GetMapPicture(structureCoordinates) Export
	
	HTTPConnection = New HTTPConnection("maps.googleapis.com");
	
	RequestText = GetPathToMapImage(structureCoordinates);
	
	HTTPRequest = New HTTPRequest(RequestText);
	
	Try
		
		Answer = HTTPConnection.Get(HTTPRequest);
		
	Except
		
		Message("Attention! Error receiving map!", MessageStatus.Attention);
		
		Return New Picture;
		
	EndTry;
	
	If Answer.StatusCode = 200 Then
		
		BinaryData = Answer.GetBodyAsBinaryData();
		
		Picture = new Picture(BinaryData);
		
	Else
		
		Picture = New Picture;
		
	EndIf;
	
	Return Picture;
	
EndFunction

Function GetPathToMapImage(structureCoordinates)
	//TODO: Implementation
EndFunction

	

