
#Region FormEventsHandlers

// Процедура - обработчик события ПриСозданииНаСервере.
//
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//ОтчетыУНФ.ПриСозданииНаСервереФормыСвязанногоОбъекта(ThisObject);
	
	//// СтандартныеПодсистемы.ПодключаемыеКоманды
	//AttachableCommands.OnCreateAtServer(ThisObject);
	//// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
	Object.MultiplicityPlanning = ?(Parameters.Key.IsEmpty(), Items.MultiplicityPlanning.ChoiceList[0].Value, Object.MultiplicityPlanning);
	
	If Parameters.Property("ResourceKind") Then
		ResourceKind = Parameters.ResourceKind;
	EndIf;
	
	ДобавитьПросмотрИзображений();
	
EndProcedure // ПриСозданииНаСервере()

&AtClient
Procedure OnOpen(Cancel)
	
	#If WebClient Then
		ThisIsWebClient = True;
	#Else
		ThisIsWebClient = False;
	#EndIf
	
	//// СтандартныеПодсистемы.ПодключаемыеКоманды
	//AttachableCommandsClient.НачатьОбновлениеКоманд(ThisObject);
	//// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
	ОбновитьРасшифровкуКратности();
	
EndProcedure // ПриОткрытии()

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(ResourceKind) Then
		RecordSet = InformationRegisters.EnterpriseResourcesKinds.CreateRecordSet();
		RecordSet.Filter.EnterpriseResource.Set(CurrentObject.Ref);
		RecordSet.Filter.EnterpriseResourceKind.Set(ResourceKind);
		
		NewRecord = RecordSet.Add();
		NewRecord.EnterpriseResourceKind = ResourceKind;
		NewRecord.EnterpriseResource = CurrentObject.Ref;
		RecordSet.Write();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Record_KeyResources");
	
EndProcedure // ПослеЗаписи()

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	//// СтандартныеПодсистемы.ПодключаемыеКоманды
	//AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	//// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
EndProcedure

&AtClient
Procedure MultiplicityPlanningTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	MultiplicityPlanning = Object.MultiplicityPlanning;
	
	Object.MultiplicityPlanning = ?(Direction>0, MultiplicityPlanning+5, MultiplicityPlanning-5);
	
	ОбновитьРасшифровкуКратности();
	
EndProcedure

&AtClient
Procedure MultiplicityPlanningOnChange(Item)
	
	RemainderOfDivision = Object.MultiplicityPlanning%5;
	
	If Not RemainderOfDivision%5 = 0 Then
			Object.MultiplicityPlanning = Object.MultiplicityPlanning + (5-RemainderOfDivision);
	EndIf;
	
	ОбновитьРасшифровкуКратности();
	
EndProcedure

&AtClient
Procedure ОбновитьРасшифровкуКратности()
	
	If Not ThisForm.ReadOnly Then
		Object.MultiplicityPlanning = ?(Object.MultiplicityPlanning > 1440, 1440, Object.MultiplicityPlanning);
	EndIf;
	
	If Object.MultiplicityPlanning >= 60 And Object.MultiplicityPlanning < 1440 Then
		
		HoursCount = Int(Object.MultiplicityPlanning/60);
		MinutesCount = Object.MultiplicityPlanning - HoursCount*60;
		
		Items.ДекорацияПодсказкаВремени.Title = "("+String(HoursCount)+ " h. "+ String(MinutesCount)+ " min."+")";
		
	ElsIf Object.MultiplicityPlanning >= 1440 Then
		
		DaysNumber = Int(Object.MultiplicityPlanning/1440);
		HoursCount = Int((Object.MultiplicityPlanning - (DaysNumber*1440))/60);
		MinutesCount = Object.MultiplicityPlanning - (DaysNumber*1440+HoursCount*60);
		
		Items.ДекорацияПодсказкаВремени.Title = "("+String(DaysNumber)+" d. " + String(HoursCount)+ " h. "+ String(MinutesCount)+ " min."+")";
		
	Else
		Items.ДекорацияПодсказкаВремени.Title = "";
	EndIf
	
EndProcedure

&AtClient
Procedure ДекорацияПрокруткаИзображенийВправоНажатие(Item)
	
	СдвигИзображения(1);
	
EndProcedure

&AtClient
Procedure ДекорацияПрокруткаИзображенийВлевоНажатие(Item)
	
	СдвигИзображения(-1);
	
EndProcedure

&AtClient
Procedure ИспользоватьГрафикРесурсаПриИзменении(Item)

	
	
EndProcedure

#EndRegion

#Region Image

// Процедура - обработчик события Нажатие поля АдресКартинки.
//
&AtClient
Procedure Подключаемый_АдресКартинкиНажатие(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ТекущееИзображение >= 0 Then
		ViewAttachedFile();
	Else
		LockFormDataForEdit();
		AddImageAtClient();
	EndIf;
	
EndProcedure // АдресКартинкиНажатие()

&AtServer
Function ОтображатьФайлНаФорме(AttachedFile, ПроверятьПометкуУдаления = True)
	
	ДопустимыеРасширения = New Array;
	ДопустимыеРасширения.Add("png");
	ДопустимыеРасширения.Add("jpeg");
	ДопустимыеРасширения.Add("jpg");
	
	FileProperties = CommonUse.ObjectAttributesValues(AttachedFile, "FileOwner,DeletionMark,Extension");
	
	If ПроверятьПометкуУдаления And FileProperties.DeletionMark
		Or FileProperties.FileOwner <> Object.Ref
		Or ДопустимыеРасширения.Find(FileProperties.Extension) = Undefined Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Вызывается при изменении присоединенного файла.
//
&AtServer
Procedure ОбновитьПросмотрИзображений(Val ИзмененныеФайлы = Undefined)
	
	ОбновитьПросмотрИзображений = (ИзмененныеФайлы = Undefined);
	
	If ИзмененныеФайлы <> Undefined Then
		If TypeOf(ИзмененныеФайлы) <> Type("Array") Then
			ИзмененныеФайлы = CommonUseClientServer.ValueInArray(ИзмененныеФайлы);
		EndIf;
		
		For Each File In ИзмененныеФайлы Do
			ОбновитьПросмотрИзображений = ОтображатьФайлНаФорме(File, False);
			If ОбновитьПросмотрИзображений Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not ОбновитьПросмотрИзображений Then
		Return;
	EndIf;
	
	ИзмененоОсновноеИзображение = False;
	If ValueIsFilled(Object.PictureFile)
		And CommonUse.ObjectAttributeValue(Object.PictureFile, "DeletionMark") Then
		Object.PictureFile = Undefined;
		Modified = True;
	EndIf;
	
	ДобавитьПросмотрИзображений();
	СдвигИзображения(0);
	
EndProcedure

// Выводит на форму картинки из присоединенных файлов.
//
&AtServer
Procedure ДобавитьПросмотрИзображений()
	
	Images.Clear();
	
	// Присоединенный файл записанный в Объект.ФайлКартинки показываем первым.
	If Not Object.PictureFile.IsEmpty() Then
		BinaryDataImages = AttachedFiles.FileBinaryDataRef(Object.PictureFile, UUID);
		If BinaryDataImages <> Undefined Then
			NewRow = Images.Insert(0);
			NewRow.Ref = Object.PictureFile;
			NewRow.Address = BinaryDataImages;
		EndIf;
	EndIf;
	
	// После присоединенного файла из Объект.ФайлКартинки показываем все остальные подходящие.
	Files = New Array;
	AttachedFiles.GetAttachedFilesToObject(Object.Ref, Files);
	For Each File In Files Do
		
		If Not ОтображатьФайлНаФорме(File)
			Or File = Object.PictureFile Then
			Continue;
		EndIf;
		BinaryDataImages = SmallBusinessServer.RefToFileBinaryData(File, UUID);
		If BinaryDataImages = Undefined Then
			Continue;
		EndIf;
		
		NewRow = Images.Add();
		NewRow.Ref = File;
		NewRow.Address = BinaryDataImages;
	EndDo;
	
	КоличествоИзображений = Items.Image.ChildItems.Count();
	ОтображаемоеИзображение = Items.Image.ChildItems[КоличествоИзображений - 1];
	ОтображаемоеИзображение.NonselectedPictureText = Items.PictureURL.NonselectedPictureText;
	If Images.Count() = 0 Then
		ТекущееИзображение = -1;
		ОтображаемоеИзображение.Border = New Border(ControlBorderType.Single);
	Else
		ТекущееИзображение = 0;
		ОтображаемоеИзображение.Border = New Border(ControlBorderType.WithoutBorder);
	EndIf;
	
	УстановитьПрокруткуИзображения();
	ИзображениеВидимостьКоманднойПанели();
	
EndProcedure

// Показывает соседнее с текущим изображение.
// 
// Parameters:
//  Direction - Number - Если = -1 - сдивиг влево; Если = 1 - сдвиг вправо.
//
&AtServer
Procedure СдвигИзображения(Direction)
	
	ItemNumber = ТекущееИзображение + Direction;
	If ItemNumber < 0 Or ItemNumber >= Images.Count() Then
		Return;
	EndIf;
	
	DataPath = StrTemplate("Images[%1].Address", ItemNumber);
	
	КоличествоИзображений = Items.Image.ChildItems.Count();
	If КоличествоИзображений = 1 Then
		ПредыдущееИзображение = Items.PictureURL;
		НовоеИзображениеНомер = 1;
	Else
		ПредыдущееИзображение = Items.Image.ChildItems[КоличествоИзображений - 1];
		НовоеИзображениеНомер = Number(StrReplace(ПредыдущееИзображение.Name, "PictureURL", "")) + 1;
	EndIf;
	
	НовоеИзображение = Items.Add("PictureURL" + НовоеИзображениеНомер, Type("FormField"), Items.Image);
	FillPropertyValues(НовоеИзображение, Items.PictureURL,, "Visible,Border,DataPath");
	НовоеИзображение.Border = New Border(ControlBorderType.WithoutBorder);
	НовоеИзображение.DataPath = DataPath;
	НовоеИзображение.SetAction("Click", "Подключаемый_АдресКартинкиНажатие");
	ТекущееИзображение = ItemNumber;
	
	Items.Move(ПредыдущееИзображение.ContextMenu.ChildItems["PictureURLContextMenuViewImage"],
	                     НовоеИзображение.ContextMenu);
	Items.Move(ПредыдущееИзображение.ContextMenu.ChildItems["АдресКартинкиКонтекстноеМенюУдалитьИзображение"],
	                     НовоеИзображение.ContextMenu, НовоеИзображение.ContextMenu.ChildItems[0]);
	Items.Move(ПредыдущееИзображение.ContextMenu.ChildItems["АдресКартинкиКонтекстноеМенюУстановитьИзображениеОсновным"],
	                     НовоеИзображение.ContextMenu, НовоеИзображение.ContextMenu.ChildItems[0]);
	Items.Move(ПредыдущееИзображение.ContextMenu.ChildItems["PictureURLContextMenuAddImage"],
	                     НовоеИзображение.ContextMenu, НовоеИзображение.ContextMenu.ChildItems[0]);
	
	If КоличествоИзображений = 1 Then
		ПредыдущееИзображение.Visible = False;
	Else
		Items.Delete(ПредыдущееИзображение);
	EndIf;
	УстановитьПрокруткуИзображения();
	ИзображениеВидимостьКоманднойПанели();
	
EndProcedure

// Процедура просмотра картинки
//
&AtClient
Procedure ViewAttachedFile()
	
	ClearMessages();
	
	File = Images[ТекущееИзображение].Ref;
	FileData = GetFileData(File, UUID);
	AttachedFilesClient.OpenFile(FileData);
	
EndProcedure // ПросмотретьПрисоединенныйФайл()

&AtClient
Procedure AddImage(Command)
	
	AddImageAtClient();
	
EndProcedure

// Устанавливает основным выбранное изображение (будет показываться первым).
//
&AtClient
Procedure УстановитьИзображениеОсновным(Command)
	
	If ТекущееИзображение < 0 Then
		Return;
	EndIf;
	
	УстановитьИзображениеОсновнымСервер(Images[ТекущееИзображение].Ref);
	
EndProcedure

&AtClient
Procedure УдалитьИзображение(Command)
	
	AttachedFile = Images[ТекущееИзображение].Ref;
	If Not ValueIsFilled(AttachedFile) Then
		Return;
	EndIf;
	
	ПометитьНаУдалениеПрисоединенныйФайл(AttachedFile);
	
	NotifyChanged(AttachedFile);
	Notify("Write_File", New Structure, AttachedFile);
	
EndProcedure

&AtClient
Procedure ViewImage(Command)
	
	ViewAttachedFile();
	
EndProcedure // ПросмотретьИзображение()

&AtServer
Procedure ПометитьНаУдалениеПрисоединенныйФайл(AttachedFile)
	
	If Not ValueIsFilled(AttachedFile) Then
		Return;
	EndIf;
	
	AttachedFileObject = AttachedFile.GetObject();
	AttachedFileObject.SetDeletionMark(True);
	AttachedFileObject.Write();
	
EndProcedure

&AtClient
Procedure AddImageAtClient()
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QuestionText = NStr("en='Для выбора изображения необходимо записать объект. Записать?';ru='Для выбора изображения необходимо записать объект. Записать?';vi='Để chọn hình ảnh, cần ghi lại đối tượng. Ghi lại?'");
		Response = Undefined;
		
		ShowQueryBox(New NotifyDescription("AddImageAtClientEnd", ThisObject), QuestionText, QuestionDialogMode.YesNo);
		
	Else
		
		AddImageAtClientFragment();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddImageAtClientEnd(Result, AdditionalParameters) Export
	
	Response = Result;
	
	If Response = DialogReturnCode.Yes Then
		Write();
	Else
		Return;
	EndIf;
	
	AddImageAtClientFragment();
	
EndProcedure

&AtClient
Procedure AddImageAtClientFragment()
	
	Var FileID, Filter;
	
	If ValueIsFilled(Object.Ref) Then
		
		FileID = New UUID;
		
		Filter = NStr("ru = 'All pictures (*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf)|*.bmp;*.gif;*.png;*.jpeg;*.dib;*.rle;*.tif;*.jpg;*.ico;*.wmf;*.emf"
		+ "All files(*.*)|*.*"
		+ "Format bmp(*.bmp*;*.dib;*.rle)|*.bmp;*.dib;*.rle"
		+ "Format GIF(*.gif*)|*.gif"
		+ "Format JPEG(*.jpeg;*.jpg)|*.jpeg;*.jpg"
		+ "Format PNG(*.png*)|*.png"
		+ "Format TIFF(*.tif)|*.tif"
		+ "Format icon(*.ico)|*.ico"
		+ "Format metafile(*.wmf;*.emf)|*.wmf;*.emf'");
		
		AttachedFilesClient.AddFiles(Object.Ref, FileID, Filter);
		
	EndIf;
	
EndProcedure // ДобавитьИзображениеНаКлиенте()

// Устанавливает видимость и доступность кнопок перелистывания изображения.
//
&AtServer
Procedure УстановитьПрокруткуИзображения()
	
	If Images.Count() <= 1 Then
		Items.ДекорацияПрокруткаИзображенийВлево.Visible = False;
		Items.ДекорацияПрокруткаИзображенийВправо.Visible = False;
		Items.ДекорацияПрокруткаИзображенийВлевоОтступ.Visible = True;
		Items.ДекорацияПрокруткаИзображенийВправоОтступ.Visible = True;
		Return;
	Else
		Items.ДекорацияПрокруткаИзображенийВлево.Visible = True;
		Items.ДекорацияПрокруткаИзображенийВправо.Visible = True;
		Items.ДекорацияПрокруткаИзображенийВлевоОтступ.Visible = False;
		Items.ДекорацияПрокруткаИзображенийВправоОтступ.Visible = False;
	EndIf;
	
	If ТекущееИзображение = 0 Then
		Items.ДекорацияПрокруткаИзображенийВлево.Enabled = False;
		Items.ДекорацияПрокруткаИзображенийВправо.Enabled = True;
	ElsIf ТекущееИзображение = Images.Count() - 1 Then
		Items.ДекорацияПрокруткаИзображенийВлево.Enabled = True;
		Items.ДекорацияПрокруткаИзображенийВправо.Enabled = False;
	Else
		Items.ДекорацияПрокруткаИзображенийВлево.Enabled = True;
		Items.ДекорацияПрокруткаИзображенийВправо.Enabled = True
	EndIf;
	
	ЭлементАдресКартинки = Items.Find("АдресКартинки1");
	If ЭлементАдресКартинки <> Undefined Then
		CurrentItem = ЭлементАдресКартинки;
	EndIf;
	
EndProcedure

// Устанавливает видимость кнопок контекстного меню изображения.
//
&AtServer
Procedure ИзображениеВидимостьКоманднойПанели()
	
	ЕстьИзображения = Images.Count();
	Items.АдресКартинкиКонтекстноеМенюУстановитьИзображениеОсновным.Visible = ЕстьИзображения;
	Items.АдресКартинкиКонтекстноеМенюУдалитьИзображение.Visible = ЕстьИзображения;
	Items.PictureURLContextMenuViewImage.Visible = ЕстьИзображения;
	ЭтоОсновноеИзображение = False;
	If ЕстьИзображения Then
		ЭтоОсновноеИзображение = (Images[ТекущееИзображение].Ref = Object.PictureFile);
	EndIf;
	
	Items.АдресКартинкиКонтекстноеМенюУстановитьИзображениеОсновным.Check = ЭтоОсновноеИзображение;
	
EndProcedure

&AtServer
Procedure УстановитьИзображениеОсновнымСервер(AttachedFile)
	
	PictureFile = Undefined;
	
	If TypeOf(AttachedFile) = Type("Array") Then
		For Each Item In AttachedFile Do
			If ОтображатьФайлНаФорме(Item, False) Then
				PictureFile = Item;
				Break;
			EndIf;
		EndDo;
	ElsIf ОтображатьФайлНаФорме(AttachedFile, False) Then
		PictureFile = AttachedFile;
	EndIf;
	
	If PictureFile = Undefined Or Object.PictureFile = PictureFile Then
		Object.PictureFile = Undefined;
	Else
		Object.PictureFile = PictureFile;
	EndIf;
	
	Modified = True;
	
	ИзображениеВидимостьКоманднойПанели();
	
EndProcedure

// Функция возвращает данные файла
//
&AtServerNoContext
Function GetFileData(PictureFile, UUID)
	
	Return AttachedFiles.GetFileData(PictureFile, UUID);
	
EndFunction // ПолучитьДанныеФайла()

#EndRegion

#Region LibrariesHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_RunCommand(Command)
	//AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_RunCommandAtServer(Context, Result) Export
	//AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	//AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtClient
Procedure ResourceValueOnChange(Item)
	
	If TypeOf(Object.ResourceValue) = Type("CatalogRef.Teams") Then
		Items.ИспользоватьГрафикРесурса.Enabled = False;
		Object.UseEmployeeGraph = False;
	ElsIf TypeOf(Object.ResourceValue) = Type("CatalogRef.Employees") Then
		Items.ИспользоватьГрафикРесурса.Enabled = True;
	Else
		Items.ИспользоватьГрафикРесурса.Enabled = False;
		Object.UseEmployeeGraph = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_File" Then
		
		If Parameter.Property("FileOwner") And Parameter.FileOwner = Object.Ref
			Or Not Parameter.Property("FileOwner") Then
			
			ОбновитьПросмотрИзображений(Source);
			
			If Parameter.Property("IsNew") And Parameter.IsNew
				And Not ValueIsFilled(Object.PictureFile) Then
				
				If TypeOf(Source) = Type("Array") Then
					ИзображениеДляПроверки = Source[0];
				Else
					ИзображениеДляПроверки = Source;
				EndIf;
				Rows = Images.FindRows(New Structure("Ref", ИзображениеДляПроверки));
				If Rows.Count() <> 0 Then
					УстановитьИзображениеОсновнымСервер(ИзображениеДляПроверки);
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

// Конец СтандартныеПодсистемы.ПодключаемыеКоманды

#EndRegion
