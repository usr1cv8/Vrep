#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region ServiceProgramInterface

// Placement settings in the report panel.
//
// Parameters:
//   Settings - Collection - Used for the description of report
//       settings and variants, see description to ReportsVariants.ConfigurationReportVariantsSettingTree().
//   ReportSettings - ValueTreeRow - Placement settings of all report variants.
//      See "Attributes for change" of the ReportsVariants function.ConfigurationReportVariantsSetupTree().
//
// Description:
//  See ReportsVariantsOverridable.SetReportsVariants().
//
// Auxiliary methods:
//   VariantSettings = ReportsVariants.VariantDesc(Settings, ReportSettings, "<VariantName>");
//   ReportsVariants.SetOutputModeInReportPanels
//   False (Settings, ReportSettings,True/False); Repor//t supports only this mode.
//
Procedure ConfigureReportsVariants(Settings, ReportSettings) Export
	ModuleReportsVariants = CommonUse.CommonModule("ReportsVariants");
	ReportSettings.Enabled = False;
	
	Properties = ChangeProhibitionDatesServiceReUse.SectionsProperties();
	If Properties.ShowSections AND Not Properties.AllSectionsWithoutObjects Then
		VariantName = "ProhibitionDateChangeBySectionsObjectsForUsers";
		VariantDesc =
			NStr("en='Displays no-edit dates"
"for users grouped by sections with objects.';ru='Выводит даты"
"запрета изменения для пользователей, сгруппированные по разделам с объектами.';vi='Hiển thị ngày"
"cấm thay đổi đối với người sử dụng mà được gom nhóm theo phần hành có các đối tượng.'");
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		VariantName = "ChangeProhibitionDatesBySectionsForUsers";
		VariantDesc =
			NStr("en='Displays no-edit dates"
"for users grouped by sections.';ru='Выводит даты"
"запрета изменения для пользователей, сгруппированные по разделам.';vi='Hiển thị ngày"
"cấm thay đổi đối với người sử dụng mà được gom nhóm theo phần hành."
"'");
	Else
		VariantName = "ChangeProhibitionDatesByObjectsForUsers";
		VariantDesc =
			NStr("en='Displays no-edit dates"
"for users grouped by objects.';ru='Выводит даты"
"запрета изменения для пользователей, сгруппированные по объектам.';vi='Hiển thị ngày"
"cấm thay đổi đối với người sử dụng mà được gom nhóm theo đối tượng.'");
	EndIf;
	VariantSettings = ModuleReportsVariants.VariantDesc(Settings, ReportSettings, VariantName);
	VariantSettings.Enabled  = True;
	VariantSettings.Description = VariantDesc;
	
	If Properties.ShowSections AND Not Properties.AllSectionsWithoutObjects Then
		VariantName = "ChangeProhibitionDatesByUsers";
		VariantDesc =
			NStr("en='Displays no-edit dates for sections"
"with objects grouped by users.';ru='Выводит даты запрета изменения"
"для разделов с объектами, сгруппированные по пользователям.';vi='Hiển thị ngày cấm thay đổi"
"đối với các phần hành có đối tượng mà được gom nhóm theo người sử dụng.'");
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		VariantName = "ChangeProhibitionDatesByUsersWithoutObjects";
		VariantDesc =
			NStr("en='Displays no-edit dates"
"for sections grouped by users.';ru='Выводит даты"
"запрета изменения для разделов, сгруппированные по пользователям.';vi='Hiển thị ngày"
"cấm thay đổi đối với các phần hành mà được gom nhóm theo người sử dụng.'");
	Else
		VariantName = "ChangeProhibitionDatesByUsersWithoutSections";
		VariantDesc =
			NStr("en='Displays no-edit dates"
"for objects grouped by users.';ru='Выводит даты"
"запрета изменения для объектов, сгруппированные по пользователям.';vi='Hiển thị ngày"
"cấm thay đổi đối với các đối tượng mà được gom nhóm theo người sử dụng.'");
	EndIf;
	VariantSettings = ModuleReportsVariants.VariantDesc(Settings, ReportSettings, VariantName);
	VariantSettings.Enabled  = True;
	VariantSettings.Description = VariantDesc;
EndProcedure

#EndRegion

#EndIf
