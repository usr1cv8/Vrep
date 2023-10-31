Function ProfilePresentation(Profile) Export
	
	If Profile = Enums.MobileApplicationProfiles.Owner Then
		Return "Owner";
	ElsIf Profile = Enums.MobileApplicationProfiles.SalesRepresentative Then
		Return "SalesRepresentative";
	ElsIf Profile = Enums.MobileApplicationProfiles.ServiceEngineer Then
		Return "ServiceEngineer";
	ElsIf Profile = Enums.MobileApplicationProfiles.Seller Then
		Return "Seller";
	ElsIf Profile = Enums.MobileApplicationProfiles.DetailedSetting Then
		Return "DetailedSetting";
	EndIf;
	
EndFunction