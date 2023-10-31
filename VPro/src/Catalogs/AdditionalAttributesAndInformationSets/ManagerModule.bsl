#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ProgramInterface

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ГрупповоеИзменениеОбъектов

// Возвращает реквизиты объекта, которые разрешается редактировать
// с помощью обработки группового изменения реквизитов.
//
// Returns:
//  Array - список имен реквизитов объекта.
Function EditedAttributesInGroupDataProcessing() Export
	
	EditableAttributes = New Array;
	
	Return EditableAttributes;
	
EndFunction

// End StandardSubsystems.ГрупповоеИзменениеОбъектов

#EndRegion

#EndRegion

#EndIf

#Region EventsHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	Fields.Add("PredefinedSetName");
	Fields.Add("Description");
	Fields.Add("Ref");
	Fields.Add("Parent");
	
	StandardProcessing = False;
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	If CurrentLanguage() = Metadata.DefaultLanguage Then
		Return;
	EndIf;
	
	If ValueIsFilled(Data.Parent) Then
		Return;
	EndIf;
	
	If ValueIsFilled(Data.PredefinedSetName) Then
		SetName = Data.PredefinedSetName;
	Else
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		SetName = CommonUse.ObjectAttributeValue(Data.Ref, "PredefinedDataName");
#Else
		SetName = "";
#EndIf
	EndIf;
	Presentation = UpperLevelSetPresentation(SetName, Data);
	
	StandardProcessing = False;
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ServiceProgramInterface

// Updates the description content
// of predefined sets in additional attributes and data parameters.
// 
// Parameters:
//  HasChanges - Boolean (return value) - if there
//               is a record, True is set, otherwise, it is not changed.
//
Procedure RefreshContentOfPredefinedSets(HasChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	PredefinedSets = PredefinedPropertySets();
	
	Block = New DataLock;
	LockItem = Block.Add("Constant.AdditionalAttributesAndInformationParameters");
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		Parameters = StandardSubsystemsServer.ApplicationWorkParameters(
			"AdditionalAttributesAndInformationParameters");
		
		HasDeleted = False;
		Saved = Undefined;
		
		If Parameters.Property("PredefinedSetsOfAdditionalDetailsAndInformation") Then
			Saved = Parameters.PredefinedSetsOfAdditionalDetailsAndInformation;
			
			If Not PredefinedSetsMatch(PredefinedSets, Saved, HasDeleted) Then
				Saved = Undefined;
			EndIf;
		EndIf;
		
		If Saved = Undefined Then
			HasChanges = True;
			StandardSubsystemsServer.SetApplicationPerformenceParameter(
				"AdditionalAttributesAndInformationParameters",
				"PredefinedSetsOfAdditionalDetailsAndInformation",
				PredefinedSets);
		EndIf;
		
		StandardSubsystemsServer.ConfirmUpdatingApplicationWorkParameter(
			"AdditionalAttributesAndInformationParameters",
			"PredefinedSetsOfAdditionalDetailsAndInformation");
		
		StandardSubsystemsServer.AddChangesToApplicationPerformenceParameters(
			"AdditionalAttributesAndInformationParameters",
			"PredefinedSetsOfAdditionalDetailsAndInformation",
			New FixedStructure("HasDeleted", HasDeleted));
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure


Procedure ProcessPropertySetsForNewVersionUpdgrade(Parameters) Export
	
	PredefinedPropertySets = PropertiesManagementReUse.PredefinedPropertySets();
	ProblemObjects = 0;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TheSets.Ref AS Ref,
		|	TheSets.PredefinedDataName AS PredefinedDataName,
		|	TheSets.AdditionalAttributes.(
		|		Property AS Property
		|	) AS AdditionalAttributes,
		|	TheSets.AdditionalInformation.(
		|		Property AS Property
		|	) AS AdditionalInformation,
		|	TheSets.Parent AS Parent,
		|	TheSets.IsFolder AS IsFolder
		|FROM
		|	Catalog.AdditionalAttributesAndInformationSets AS TheSets
		|WHERE
		|	TheSets.Predefined = TRUE";
	Result = Query.Execute().Unload();
	
	For Each UpdatedSet In Result Do
		
		BeginTransaction();
		Try
			If Not ValueIsFilled(UpdatedSet.PredefinedDataName) Then
				RollbackTransaction();
				Continue;
			EndIf;
			If Not StrStartsWith(UpdatedSet.PredefinedDataName, "Delete") Then
				RollbackTransaction();
				Continue;
			EndIf;
			If UpdatedSet.AdditionalAttributes.Count() = 0
				And UpdatedSet.AdditionalInformation.Count() = 0 Then
				RollbackTransaction();
				Continue;
			EndIf;
			SetName = Mid(UpdatedSet.PredefinedDataName, 8, StrLen(UpdatedSet.PredefinedDataName) - 7);
			NewSetDescription = PredefinedPropertySets.Get(SetName);
			If NewSetDescription = Undefined Then
				RollbackTransaction();
				Continue;
			EndIf;
			NewSet = NewSetDescription.Ref;
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.AdditionalAttributesAndInformationSets");
			LockItem.SetValue("Ref", NewSet);
			Block.Lock();
			
			// Заполнение нового набора.
			NewObjectSet = NewSet.GetObject();
			If UpdatedSet.IsFolder <> NewObjectSet.IsFolder Then
				RollbackTransaction();
				Continue;
			EndIf;
			For Each RowAttribute In UpdatedSet.AdditionalAttributes Do
				NewRowAttributes = NewObjectSet.AdditionalAttributes.Add();
				FillPropertyValues(NewRowAttributes, RowAttribute);
				NewRowAttributes.PredefinedSetName = NewObjectSet.PredefinedSetName;
			EndDo;
			For Each RowInformation In UpdatedSet.AdditionalInformation Do
				NewRowInformation = NewObjectSet.AdditionalInformation.Add();
				FillPropertyValues(NewRowInformation, RowInformation);
				NewRowInformation.PredefinedSetName = NewObjectSet.PredefinedSetName;
			EndDo;
			
			If Not UpdatedSet.IsFolder Then
				CountAttributes = Format(NewObjectSet.AdditionalAttributes.FindRows(
					New Structure("DeletionMark", False)).Count(), "NG=");
				CountInformation   = Format(NewObjectSet.AdditionalInformation.FindRows(
					New Structure("DeletionMark", False)).Count(), "NG=");
				
				NewObjectSet.CountAttributes = CountAttributes;
				NewObjectSet.CountInformation   = CountInformation;
			EndIf;
			
			InfobaseUpdate.WriteObject(NewObjectSet);
			
			// Очистка старого набора.
			ObsoleteObjectSet = UpdatedSet.Ref.GetObject();
			ObsoleteObjectSet.AdditionalAttributes.Clear();
			ObsoleteObjectSet.AdditionalInformation.Clear();
			ObsoleteObjectSet.Used = False;
			
			InfobaseUpdate.WriteObject(ObsoleteObjectSet);
			
			If UpdatedSet.IsFolder Then
				Query = New Query;
				Query.SetParameter("Parent", UpdatedSet.Ref);
				Query.Text = 
					"SELECT
					|	AdditionalAttributesAndInformationSets.Ref AS Ref
					|FROM
					|	Catalog.AdditionalAttributesAndInformationSets AS AdditionalAttributesAndInformationSets
					|WHERE
					|	AdditionalAttributesAndInformationSets.Parent = &Parent
					|	AND AdditionalAttributesAndInformationSets.Predefined = FALSE";
				TransferredSets = Query.Execute().Unload();
				For Each Row In TransferredSets Do
					ObjectSet = Row.Ref.GetObject();
					ObjectSet.Parent = NewSet;
					InfobaseUpdate.WriteObject(ObjectSet);
				EndDo;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ProblemObjects = ProblemObjects + 1;
			
			TextOfMessage = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='A percentage of properties could not be processed for:"
"%2';ru='Не удалось обработать набор свойств: %1 по причине:"
"%2';vi='Không thể xử lý tập hợp thuộc tính: %1 do:"
"%2'"), 
					UpdatedSet.Ref, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogMonitorEvent(), EventLogLevel.Warning,
				Metadata.Catalogs.AdditionalAttributesAndInformationSets, UpdatedSet.Ref, TextOfMessage);
		EndTry;
		
	EndDo;
	
	If ProblemObjects <> 0 Then
		TextOfMessage = NStr("en='Procedure To processThe RequirementsThe Trans-outForetheration has ended with an error. Not all property sets have been updated.';ru='Процедура ОбработатьНаборыСвойствДляПереходаНаНовуюВерсию завершилась с ошибкой. Не все наборы свойств удалось обновить.';vi='Thủ tục ОбработатьНаборыСвойствДляПереходаНаНовуюВерсию đã kết thúc bị lỗi. Không phải tất cả tập hợp thuộc tính đều được cập nhật thành công.'");
		Raise TextOfMessage;
	EndIf;
	
	Parameters.DataProcessorCompleted = True;
	
EndProcedure



#EndRegion

#EndIf

#Region InternalProceduresAndFunctions

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Function PredefinedPropertySets() Export
	
	SetTree = New ValueTree;
	SetTree.Columns.Add("Name");
	SetTree.Columns.Add("IsFolder", New TypeDescription("Boolean"));
	SetTree.Columns.Add("Used");
	SetTree.Columns.Add("ID");
	StandardSubsystemsIntegration.OnGetPredefinedPropertySets(SetTree);
	PropertiesManagementOverridable.OnGetPredefinedPropertySets(SetTree);
	
	PropertySetDescriptions = PropertiesManagementService.PropertySetDescriptions();
	Descriptions = PropertySetDescriptions[CurrentLanguage().LanguageCode];
	
	PropertiesSets = New Map;
	For Each Set In SetTree.Rows Do
		PropertiesSet = PropertiesSet(PropertiesSets, Set);
		For Each ChildSet In Set.Rows Do
			ChildSetProperties = PropertiesSet(PropertiesSets, ChildSet, PropertiesSet.Ref, Descriptions);
			PropertiesSet.ChildSets.Insert(ChildSet.Name, ChildSetProperties);
		EndDo;
		PropertiesSet.ChildSets = New FixedMap(PropertiesSet.ChildSets);
		PropertiesSets[PropertiesSet.Name] = New FixedStructure(PropertiesSets[PropertiesSet.Name]);
		PropertiesSets[PropertiesSet.Ref] = New FixedStructure(PropertiesSets[PropertiesSet.Ref]);
	EndDo;
	
	Return New FixedMap(PropertiesSets);
	
EndFunction

Function PredefinedSetsMatch(NewSets, OldSets, HasDeleted)
	
	PredefinedSetsMatch =
		NewSets.Count() = OldSets.Count();
	
	For Each Set IN OldSets Do
		If NewSets.Get(Set.Key) = Undefined Then
			PredefinedSetsMatch = False;
			HasDeleted = True;
			Break;
		ElsIf Set.Value <> NewSets.Get(Set.Key) Then
			PredefinedSetsMatch = False;
		EndIf;
	EndDo;
	
	Return PredefinedSetsMatch;
	
EndFunction

Function PropertiesSet(PropertiesSets, Set, Parent = Undefined, Descriptions = Undefined)
	
	ErrorTitle =
		NStr("en='Error in the Procedure Of The Pre-determinedProstitions"
"General Module ManagementThe Re-determined.';ru='Ошибка в процедуре ПриСозданииПредопределенныхНаборовСвойств"
"общего модуля УправлениеСвойствамиПереопределяемый.';vi='Lỗi trong thủ tục ПриСозданииПредопределенныхНаборовСвойств của mô-đun chung УправлениеСвойствамиПереопределяемый.'")
		+ Chars.LF
		+ Chars.LF;
	
	If Not ValueIsFilled(Set.Name) Then
		Raise ErrorTitle + NStr("en='The name of the property set is not filled.';ru='Имя набора свойств не заполнено.';vi='Chưa điền tên tập hợp thuộc tính.'");
	EndIf;
	
	If PropertiesSets.Get(Set.Name) <> Undefined Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='The name of the ""%1"" property set has already been determined.';ru='Имя набора свойств ""%1"" уже определено.';vi='Đã xác định tên của tập hợp thuộc tính ""%1"".'"),
			Set.Name);
	EndIf;
	
	If Not ValueIsFilled(Set.ID) Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='The ""%1"" property set ID is not filled.';ru='Идентификатор набора свойств ""%1"" не заполнен.';vi='Chưa điền tên (ID) tập hợp thuộc tính ""%1"".'"),
			Set.Name);
	EndIf;
	
	If Not CommonUseReUse.CanUseSeparatedData() Then
		SetReference = Set.ID;
	Else
		SetReference = GetRef(Set.ID);
	EndIf;
	
	If PropertiesSets.Get(SetReference) <> Undefined Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Property set ""%1"" ID"
"""%2"" is already used for the ""%3"" set.';ru='Идентификатор ""%1"" набора свойств"
"""%2"" уже используется для набора ""%3"".';vi='Tên (ID) ""%1"" của tập hợp thuộc tính ""%2"" đã được sử dụng cho tập hợp ""%3"".'"),
			Set.ID, Set.Name, PropertiesSets.Get(SetReference).Name);
	EndIf;
	
	PropertiesSet = New Structure;
	PropertiesSet.Insert("Name", Set.Name);
	PropertiesSet.Insert("IsFolder", Set.IsFolder);
	PropertiesSet.Insert("Used", Set.Used);
	PropertiesSet.Insert("Ref", SetReference);
	PropertiesSet.Insert("Parent", Parent);
	PropertiesSet.Insert("ChildSets", ?(Parent = Undefined, New Map, Undefined));
	If Descriptions = Undefined Then
		PropertiesSet.Insert("Description", UpperLevelSetPresentation(Set.Name));
	Else
		PropertiesSet.Insert("Description", Descriptions[Set.Name]);
	EndIf;
	
	If Parent <> Undefined Then
		PropertiesSet = New FixedStructure(PropertiesSet);
	EndIf;
	PropertiesSets.Insert(PropertiesSet.Name,    PropertiesSet);
	PropertiesSets.Insert(PropertiesSet.Ref, PropertiesSet);
	
	Return PropertiesSet;
	
EndFunction

#EndIf

// АПК:361-выкл нет обращения к серверному коду.
Function UpperLevelSetPresentation(PredefinedName, PropertiesSet = Undefined)
	
	Presentation = "";
	Position = StrFind(PredefinedName, "_");
	FirstPartOfTheName =  Left(PredefinedName, Position - 1);
	SecondPartOfName = Right(PredefinedName, StrLen(PredefinedName) - Position);
	
	FullName = FirstPartOfTheName + "." + SecondPartOfName;
	
	MetadataObject = Metadata.FindByFullName(FullName);
	If MetadataObject = Undefined Then
		Return Presentation;
	EndIf;
	
	If ValueIsFilled(MetadataObject.ListPresentation) Then
		Presentation = MetadataObject.ListPresentation;
	ElsIf ValueIsFilled(MetadataObject.Synonym) Then
		Presentation = MetadataObject.Synonym;
	ElsIf PropertiesSet <> Undefined Then
		Presentation = PropertiesSet.Description;
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion