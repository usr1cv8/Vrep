
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CommonUseClientServer.SetDynamicListParameter(
		List,
		"PresentationAdditionalInformation",
		NStr("en='Find out more';ru='Дополнительные сведения';vi='Thông tin bổ sung'"),
		True);
	
	CommonUseClientServer.SetDynamicListParameter(
		List,
		"PresentationAdditionalAttributes",
		NStr("en='Additional attributes';ru='Дополнительные реквизиты';vi='Mục tin bổ sung'"),
		True);
	
	// Группировка свойств по наборам.
	DataGrouping = List.SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DataGrouping.UserSettingID = "GroupPropertiesBySuite";
	DataGrouping.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	GroupFields = DataGrouping.GroupFields;
	
	DataGroupItem = GroupFields.Items.Add(Type("DataCompositionGroupField"));
	DataGroupItem.Field = New DataCompositionField("PropertySetGrouping");
	DataGroupItem.Use = True;
	
EndProcedure

#EndRegion
