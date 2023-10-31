
Procedure SetProfileForUser(User, Profile) Export
	
	RecordManager = CreateRecordManager();
	RecordManager.User = User;
	If TypeOf(Profile) = Type("String") Then
		RecordManager.Profile = Enums.MobileApplicationProfiles[Profile];
	Else
		RecordManager.Profile = Profile;
	EndIf;
	RecordManager.Write(True);
	
EndProcedure 

Function UserProfile(User) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MobileUserProfiles.Profile
		|FROM
		|	InformationRegister.MobileUserProfiles AS MobileUserProfiles
		|WHERE
		|	MobileUserProfiles.User = &User";
	Query.SetParameter("User", User);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Profile;
	Else
		Return "";
	EndIf;
	
EndFunction
