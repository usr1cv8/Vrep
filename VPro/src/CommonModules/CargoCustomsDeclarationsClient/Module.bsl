////////////////////////////////////////////////////////////////////////////////
// Подсистема "Базовая функциональность".
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

#EndRegion

#Region ServiceProgramInterface

Function SelectDateFromCCDNumber(CCDCode) Export
	
	ReceivedDate = Date(1, 1, 1);
	
	FirstDelimiterPosition	= StrFind(CCDCode, "/");
	DateCCD						= Right(CCDCode, StrLen(CCDCode) - FirstDelimiterPosition);
	SecondDelimiterPosition	= StrFind(DateCCD, "/");
	DateCCD						= Left(DateCCD, SecondDelimiterPosition - 1);
	
	If StrLen(DateCCD) = 6 Then
		
		DateDay	= Left(DateCCD, 2);
		DateMonth	= Mid(DateCCD, 3, 2);
		DateYear		= Mid(DateCCD, 5, 2);
		
		Try
			
			DateYear			= ?(Number(DateYear) >= 30, "19" + DateYear, "20" + DateYear);
			ReceivedDate	= Date(DateYear, DateMonth, DateDay);
			
		Except
		EndTry;
		
	EndIf;
	
	Return ReceivedDate;
	
EndFunction

#EndRegion