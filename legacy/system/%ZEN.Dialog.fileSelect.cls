/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog page displays a file selection window
/// listing directories and files on the <em>server</em>.
/// This is intended for use within server portal pages.<br/>
/// To use this dialog, the current user must hold USE privileges on 
/// one of the following resources:<br/>
/// %Admin_Manage,%Admin_Operate,%Admin_Secure,%Development <br/>
/// For an production-enabled namespace, resource %Ens_ViewFileSystem is required.
/// <h3>How to Use This Dialog </h3>
/// <ul>The following arguments maybe passed in:
/// <li><b>Dir:</b> This is the default directory path and optionally with a filename. It is encouraged that you provide a default directory and filename whenever possible.
/// Alternatively you can pass in the filename using a separate argument <b>File</b></li>
/// <li><b>showdirectoryonly:</b> 1 or 0. If 1, then the dialog will show directories only. Default is 0.</li>
/// <li><b>wildcard:</b> a wildcard for "Type of files" to filter the files. Examples:*.xml, *.txt, *.log, etc. Default is *.*, i.e if nothing passed in then files of all types are shown.</li>
/// <li><b>extfilter:</b> only display files whose extension appears in the list. Values should be specified in the same format as <b>wildcard</b>. If this parameter is specified <b>wildcard</b> is ignored. 
/// This will remove the option to display all files (*) and files with no extension will never be displayed. Note that on UNIX platforms the extensions are case sensitive. 
/// To display files with the extension .TXT or .txt, you should use 'extfilter=*.txt;*.TXT'.</li>
/// </ul>
/// <h4>Example invoking the fileSelect dialog to open in a popup window:</h4>
/// <Example>
/// 	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.cls?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=600,height=700');
/// </Example>
/// <p>If <b>Dir</b> is null, then the manager directory is used when the dialog is opened. If <b>Dir</b> contains a partial directory, then the last valid level
/// of directory, if can be found, is used. If <b>Dir</b> contains a filename or a partical name without a directory then the manager directory is used
/// for the filename. When OK is pressed, whatever is shown in the <b>File name</b> field is returned to the calling page.
/// </p>
/// <p>
/// If you are opening the dialog as a popup window such as shown in the above example, then you should have an onPopupAction method defined on the calling page.
/// In the following example, a Zen control "FileName" is defined on your calling page, and upon returning from the fileSelect dialog by clicking "OK",
/// the returned value will be set into your Zen control "FileName":
/// <Example>
/// ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
/// {
/// 	if (action == "ok") {
/// 		if (popupName == "FileSelect") zen("FileName").setValue(value);
/// 	}
/// }
/// </Example>
/// </p>
/// <p>ISC Developers: Please use caution when modifying logic in this class. Your change needs to be tested in Windows, Unix, and VMS for all cases.
/// </p>
Class %ZEN.Dialog.fileSelect Extends %CSP.Portal.standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter VALIDATEXML = 0;

/// Whether to show directory only or with files
Property showdirectoryonly As %ZEN.Datatype.string(ZENURL = "showdirectoryonly");

/// Original Directory path and/or filename passed in. If null is passed in, then manager directory will be used.
Property DirFile As %ZEN.Datatype.string(ZENURL = "Dir");

/// Composed Default Directory path. After much checking, this is the final default directory that is used as default.
Property DefaultDirectory As %ZEN.Datatype.string;

/// Original File name passed in (optional)
Property FileName As %ZEN.Datatype.string(ZENURL = "File");

Property ExtFilter As %ZEN.Datatype.string(ZENURL = "extfilter");

Property isWINDOWS As %Boolean [ InitialExpression = "0" ];

Property isVMS As %Boolean [ InitialExpression = "0" ];

XData Style
{
<style type="text/css">

.imageLink {
	border-top: 1px solid white;
	border-left: 1px solid white;
	border-bottom: 1px solid darkgray;
	border-right: 1px solid darkgray;
	cursor: pointer;
	margin-left: 3px;
}

#view {
	width: 90%;
	height: 380px;
	overflow: auto;
	border: 1px solid black;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-left:6px;">
<form name="Content">
<spacer height="10"/>
<hgroup cellVAlign="middle" labelPosition="left">
<combobox id="Lookin" label="Look in:" name="Lookin" size="64" onchange="zenPage.changeDrive(zenThis);" />
<spacer width="5"/>
<image src='/csp/sys/images/up1lvl.jpg' title="Go up one level" onclick="zenPage.upOneLevel();"/>
<image src="/csp/sys/images/vw-list.jpg" title="Show files in List mode" onclick="zenPage.changeView('list');"/>
<image src="/csp/sys/images/vw-details.jpg" title="Show files in Details" onclick="zenPage.changeView('details');"/>
</hgroup>
<spacer height="5"/>
<dynaView id="view" 
	viewType="list"
	OnGetViewContents="GetViewContents"
	rows="15"
	onselect="zenPage.itemSelected(zenThis);"
	onclick="zenPage.itemClicked(zenThis);"
	onclickHeader="zenPage.changeSortOrder(zenThis);"
	 >	
	<parameter paramName="Dir" value="" />
	<parameter paramName="wildcard" value="*" />
	<parameter paramName="showdirectoryonly" value="0" />	 
	<parameter paramName="sortby" value="Type" />
	<parameter paramName="sortOrder" value="1"/>
</dynaView>
<spacer height="4" />
<vgroup cellVAlign="bottom" labelPosition="top">
<text name="FileName" id="FileName" label="File name:" size="87" />
<label id="FileError" labelClass="rednote" label="File must have a valid extension" hidden="true"/>
</vgroup>
<spacer height="4" />
<hgroup cellVAlign="bottom" labelPosition="top">
<combobox name="FileType" id="FileType" label="File of type:" 
onchange="zenPage.changeFileType();" dropdownWidth="400px" 
editable="true" unrestricted="true" size="50"
/>

</hgroup>
</form>

</pane>
}

/// Zen page notification of an HTTP request.
ClassMethod %OnPreHTTP() As %Boolean [ Internal, ServerOnly = 1 ]
{
	// test if user has resources
	If ($System.Security.Check("%Admin_Manage","USE")||
		$System.Security.Check("%Admin_Operate","USE")||
		$System.Security.Check("%Admin_Secure","USE")||
		$System.Security.Check("%Development","USE")||
		(##class(%Library.EnsembleMgr).IsEnsembleNamespace()&&$system.Security.Check("%Ens_ViewFileSystem","USE"))||
		$System.Security.Check("%DeepSee_Admin","USE")		// DTB412
		) {
		Quit 1
	}
	Quit 0
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If %page.showdirectoryonly = 1 Quit $$$TextHTML("Directory Selection Dialog")
	Quit $$$TextHTML("File Selection Dialog")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	If %page.showdirectoryonly = 1 Quit $$$TextHTML("Select a directory from the choices below.")
	Quit $$$TextHTML("Select a file from the choices below.")
}

/// User selected a different directory from "Lookin" drop-down. If FileName is available, add to the newly selected directory.
ClientMethod changeDrive(thisobj) [ Language = javascript ]
{
	var name = thisobj.getValue();
    var view = this.getComponentById("view");
	view.setProperty("parameters","Dir", name);
	view.refreshContents(true);
	if (this.FileName != "") {
		if (this.isVMS) {
			if (name.indexOf(":") == name.length-1) {
				name = name + "[000000]";
			}
		}
		name = name + this.FileName;
	}
	this.getComponentById("FileName").setProperty("value",name);
}

ClientMethod changeSortOrder(value) [ Language = javascript ]
{
	var sortby;
	switch(value) {
		case $$$Text("Name"):
			sortby = "Name";
			break;
		case $$$Text("Type"):
			sortby = "Type";
			break;
		case $$$Text("Size"):
			sortby = "Size";
			break;
		case $$$Text("Last Modified"):
			sortby = "DateModified";
			break;
		default:
			sortby = "Type";
			break;
	}
	var view = this.getComponentById("view");
	var parms = view.getProperty("parameters")
	var old = parms.sortby.value;
	if (old == sortby) {
		var order = parms.sortOrder.value;
		view.setProperty("parameters","sortOrder",-order);
	} else {
		view.setProperty("parameters","sortby",sortby);
		view.setProperty("parameters","sortOrder",1);
	}
	view.refreshContents(true);
}

ClientMethod reloadLookin(driveobj, tvalue) [ Language = javascript ]
{
	driveobj.resetOptions();
	var wildcard = zen("FileType").getValue();
	zenPage.RebuildLookin(tvalue,wildcard);
}

/// changeView
ClientMethod changeView(viewtype) [ Language = javascript ]
{
	var view = this.getComponentById("view");
	view.setProperty('viewType',viewtype);
	view.refreshContents(true);
}

/// up one level
ClientMethod upOneLevel() [ Language = javascript ]
{
	try {
		var viewobj = this.getComponentById("view");
		var driveobj = zenPage.getComponentById("Lookin");
		var drive = driveobj.getValue(); //this is the value in the Lookin drop-down
		var len = driveobj.options.length;
		var lastdrive = "";
		var lastdriveindex = "";
		var thisdrive = "";
		for (var r = 0; r < len; r++) {
			thisdrive = driveobj.options[r].value;
			if (thisdrive == drive) {
				break;
			} else {
				lastdriveindex = r;
				lastdrive = thisdrive;
			}
		}
		if (parseInt(lastdriveindex) > -1) {
			//check if this is already at the top level
			var istop = false;
		    istop = drive.substr(0,lastdrive.length)!=lastdrive;
			if (istop == false) {
				driveobj.setValue(lastdrive);
				viewobj.setProperty("parameters","Dir", lastdrive);
				viewobj.refreshContents(true);
				// If File is passed in, then add it to the directory selected.
				if (this.isVMS) {
					if (lastdrive.indexOf(":") == lastdrive.length-1) {
						lastdrive = lastdrive + "[000000]";
					}
				}
				if (this.FileName != "") {
					lastdrive = lastdrive + this.FileName;
				}
				this.getComponentById("FileName").setProperty("value",lastdrive);
			}
		}
		return;
	}
	catch (ex) {
		zenExceptionHandler(ex,arguments,'Error in upOneLevel');
	}
}

/// This method refreshes the contents with the current file type and directory/file name
ClientMethod changeFileType() [ Language = javascript ]
{
	var filename = this.getComponentById("FileName").getValue();
	var filetype = this.getComponentById("FileType").getValue();
	var view = this.getComponentById("view");
	view.setProperty("parameters","Dir", filename);
	view.setProperty("parameters","wildcard", filetype);
	view.refreshContents(true);
}

/// Examine if user hit the Return key. If yes, start the search.
/// This method handles all keydown events on the window. 
ClientMethod onkeydownHandler(evt) [ Language = javascript ]
{
	//Works for both IE and NS (fancy that!)
	try {
		if (13 == evt.keyCode) {
			// find out if this is a valid directory because we need to update the Look in
			var filename = this.getComponentById("FileName").getValue();
			var dir = this.GetDirectory(filename);
			if (dir != "") {
				var driveobj = zenPage.getComponentById("Lookin");
				this.reloadLookin(driveobj,dir);
			}
		}
		return true;
	}
	catch (ex) {
	}
}

/// Build file and directory list
Method GetViewContents(ByRef pParms As %String, Output pContents As %String, ByRef pHeader As %String) As %Status
{
	Set pHeader(1) = $$$Text("Name")
	Set pHeader(2) = $$$Text("Type")
	Set pHeader(3) = $$$Text("Size")
	Set pHeader(4) = $$$Text("Last Modified")

	Set CloseImage = ..%Link("/csp/sys/images/closed.gif")
	Set FileImage = ..%Link("/csp/sys/images/note06.jpg")
	Set FILEOBJ = ##class(%ResultSet).%New("%File:FileSet")
	Set Dir = $G(pParms("Dir"))
	Set:Dir="" Dir = ..DefaultDirectory
	If Dir = "" Return $$$OK // This should only happen if no directories are allowed
	Set wildcard = $G(%request.Data("wildcard",1))
	If wildcard = "" Set wildcard = $G(pParms("wildcard"),"*")
	If $$$isVMS,wildcard = "*" Set wildcard = "*.*"
	Set showdirectoryonly = $G(%request.Data("showdirectoryonly",1))
	If showdirectoryonly = "" Set showdirectoryonly = $G(pParms("showdirectoryonly"),0)
	Set sortby = $G(pParms("sortby"),"Type")	// in this application "sortby" is always set to Type so that directories are shown on top
	Set includedirs = 1							// in this application we always include directories
	Set drive = ##class(%File).NormalizeDirectory(Dir)
	Set tSC = FILEOBJ.%Execute(drive,wildcard,sortby,includedirs)
	Set sortOrder = $S(+$G(pParms("sortOrder"))=-1:-1,1:1)
	Set n = 0
	While FILEOBJ.%Next() {
		#; A flag should be passed in to indicate whether we should show Files or just Directories
		Continue:(showdirectoryonly = 1)&&(FILEOBJ.Get("Type") '= "D")
			Set file = FILEOBJ.GetData(1)
			Set type = FILEOBJ.Get("Type")
			Set filename = FILEOBJ.Get("ItemName")
			If type = "D" {
				Set icon = CloseImage
				Set file = ##class(%File).NormalizeDirectory(file)
			#; caption, icon, type
			Set tDirs($S(sortby'="DateModified":$I(n),1:FILEOBJ.Get("DateModified")_" "_$I(n))) = $LB(filename,file_"^"_type,icon,type,FILEOBJ.Get("Size"),FILEOBJ.Get("DateModified"))
			} Else {
				Set icon =FileImage		
			#; caption, icon, type
			Set tFiles($I(n)) = $LB(filename,file_"^"_type,icon,type,FILEOBJ.Get("Size"),FILEOBJ.Get("DateModified"))	
			}
	}
	Set n = 0
	Set idx = ""
	For {
		Set idx = $O(tDirs(idx),sortOrder,tVal) Quit:""=idx
		Set pContents($I(n)) = tVal
		}
	For {
		Set idx = $O(tFiles(idx),sortOrder,tVal) Quit:""=idx
		Set pContents($I(n)) = tVal
	}
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	//
	// Load "Look in" drop-down and FileName
	// 
	Set tCombo = ..%GetComponentById("Lookin")
	Set showdirectoryonly = +..showdirectoryonly
	#; You may pass in a partial directory or file name
	Set Dir = ..DirFile
	Set FileName = ..FileName
	#; Find the directory portion of Dir passed in (this may include a filename). If that doesn't exist then use $zu(12)
	If FileName = "",Dir '= "" Set Dir = ..GetDirectory(Dir)
	If Dir = "" Set Dir = ##class(%File).ManagerDirectory() Set:..FileName="" FileName = ..DirFile

	Do ..BuildDrive(.drives, .Dir, .lastexistingdir)
	
	#; When Dir is the only parameter passed in (without "File"), which is the case most times, parse out the filename from the path
	If FileName = "" {
		#; If it contains a Filename, then parse it out	
		If lastexistingdir '= "" {
			Set FileName = ##class(%File).GetFilename($piece(..DirFile,lastexistingdir,2))
		#; The following case means the user entered only a filename
		} Else {
			Set FileName = Dir
		}
	}
	#; Set it to ..FileName so it can be carried over to other directories
	If showdirectoryonly = 0,..FileName = "",FileName '= "" Set ..FileName = FileName

	#; Set the composed directory for later use
	Set ..DefaultDirectory = Dir

	#; Set default Dir into File name field
	Set ..%GetComponentById("FileName").value = $S('showdirectoryonly&(FileName'=""):##class(%File).NormalizeFilename(FileName,Dir),1:Dir)

	Set drivename = $O(drives(""))
	If $$$isVMS {
		While drivename '= "" {
			Kill driveindex
			If drivename?1.N Set driveindex = drivename,drivename = drives(driveindex)
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do tCombo.options.Insert(tOption)
			Do ..%AddComponent(tOption)
			Set tOption.text = drivename
			Set tOption.value = drivename
			Set tOption.style = "font-size:12px;"
			If $G(driveindex) Set drivename = $O(drives(driveindex))
			Else  Set drivename = $O(drives(drivename))
		}	
	} Else {
		While drivename '= "" {
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do tCombo.options.Insert(tOption)
			Do ..%AddComponent(tOption)
			Set tOption.text = drivename
			Set tOption.value = drivename
			Set tOption.style = "font-size:12px;" 
			Set drivename = $O(drives(drivename))
		}
	}
	// Set "Look in" default
	Set tCombo.value =  $select(Dir="":"", 1:##class(%File).NormalizeDirectory(Dir))
	//
	//Load "File of type" drop-down:
	//
	Kill tCombo,drives
	
	set extLabels("*.xml") = $$$Text("XML Files (*.xml)")
	set extLabels("*.goq") = $$$Text("Binary Global Output Files (*.goq)")
	set extLabels("*.xml;*.goq") = $$$Text("Locale Files (*.xml;*.goq)")
	set extLabels("*.go;*.gsa;*.gbl;*.gof") = $$$Text("Global Save Files (*.go;*.gsa;*.gbl;*.gof)")
	set extLabels("*.ro;*.rsa;*.rtn;*.mac") = $$$Text("Routine Save Files (*.ro;*.rsa;*.rtn;*.mac)")
	set extLabels("*.exe") = $$$Text("Application Files (*.exe)")
	set extLabels("*.jar") = $$$Text("Java Archive Files (*.jar)")
	set extLabels("*.class") = $$$Text("Java Class Files (*.class)")
	set extLabels("*.dll") = $$$Text("Dynamic Link Library Files (*.dll)")
	set extLabels("*.bat;*.cmd") = $$$Text("Batch Files (*.bat;*.cmd)")
	set extLabels("*.csv") = $$$Text("Comma Separated Value Files (*.csv)")
	set extLabels("*.txt") = $$$Text("Text Files (*.txt)")
	set extLabels("*.pdf") = $$$Text("PDF Files (*.pdf)")
	set extLabels("*.html") = $$$Text("HTML Files (*.html)")
	set extLabels("*.log") = $$$Text("Log Files (*.log)")
	set extLabels("*.xsd") = $$$Text("XML Schema Files (*.xsd)")
	set extLabels("*.wsdl") = $$$Text("WSDL Files (*.wsdl)")
	set extLabels("*.cer") = $$$Text("*.cer")
	set extLabels("*.pem") = $$$Text("*.pem")
	set extLabels("*.key") = $$$Text("*.key")
	set extLabels("*") = $$$Text("All Files (*)")
	
	If ..ExtFilter'="" {
		Set extfilter = ..ExtFilter
		Set (valueList,displayList) = ""
		For i=1:1:$L(extfilter,",") {
			Set type = $P(extfilter,",",i)
			Set trans = $G(extLabels($zcvt(type,"L")),$G(extLabels($P(type,";",1)),type))
			Set displayList = displayList_$S(displayList="":"",1:",")_trans
			Set valueList = valueList_$S(valueList="":"",1:",")_type
		}
		Set default = $P(valueList,",",1)
		If $L(extfilter,",")>1 {
			Set displayList = displayList_","_"All ("_$Replace(extfilter,",",";")_")"
			Set valueList = valueList_","_$Replace(valueList,",",";")
		}
		// User cannot edit filter text
		Set fileTypeEditable = 0
	} Else {
		Set wildcard = $G(%request.Data("wildcard",1),"*")
		If $$$isVMS,wildcard = "*" Set wildcard = "*.*"
		#; Handle cases where the wildcard may contain multiple:
		#; if wildcard passed in does not matching the types array then show as is so the result matches what the Type say.
		Set default = ""
		Set ind = 1
		Set trans(ind) = extLabels("*")
		Set types(ind) = $S($$$isVMS:"*.*",1:"*")
		Set lwildcard = $ZCVT(wildcard,"L")
		If lwildcard = "*.xml;*.goq" {
			Set types($i(ind)) = "*.xml"
			Set trans(ind) = extLabels(types(ind))
			Set types($i(ind)) = "*.goq"
			Set trans(ind) = extLabels(types(ind))
			Set types($i(ind)) = "*.xml;*.goq"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)
		} ElseIf lwildcard [ "go" {
			Set types($i(ind)) = "*.go;*.gsa;*.gbl;*.gof"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)
		} ElseIf lwildcard [ ".ro" {
			Set types($i(ind)) = "*.ro;*.rsa;*.rtn;*.mac"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)	
		} ElseIf lwildcard ["exe" {
			Set types($i(ind)) = "*.exe"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)
		} ElseIf lwildcard [ "jar" {
			Set types($i(ind)) = "*.jar"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)
		} ElseIf ((lwildcard ["cer") || (lwildcard [ "pem")) {
			Set types($i(ind)) = "*.cer"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)		
			Set types($i(ind)) = "*.pem"
			Set trans(ind) = extLabels(types(ind))
		} ElseIf ((lwildcard ["key") || (lwildcard [ "pem")) {
			Set types($i(ind)) = "*.key"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)		
			Set types($i(ind)) = "*.pem"
			Set trans(ind) = extLabels(types(ind))
		} ElseIf lwildcard ["*.class" {
			Set types($i(ind)) = "*.class"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)		
		} ElseIf lwildcard ["*.dll" {
			Set types($i(ind)) = "*.dll"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)
		} ElseIf ((lwildcard ["*.bat") || (lwildcard [ "*.cmd")) {
			Set types($i(ind)) = "*.bat;*.cmd"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)
		} ElseIf lwildcard [ "*.csv" {
			Set types($i(ind)) = "*.csv"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)
			Set types($i(ind)) = "*.txt"
			Set trans(ind) = extLabels(types(ind))
		} ElseIf lwildcard ["*.pdf" {
			Set types($i(ind)) = "*.pdf"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)		
		} ElseIf lwildcard ["*.html" {
			Set types($i(ind)) = "*.html"
			Set trans(ind) = extLabels(types(ind))
			Set default = types(ind)		
		} Else {
			#; For All files, we also include the following types so the list will have some choices in addition to the All files.
			Set types($i(ind)) = "*.log" If lwildcard="*.log" Set default = types(ind)
			Set trans(ind) = extLabels(types(ind))
			Set types($i(ind)) = "*.txt" If lwildcard="*.txt" Set default = types(ind)
			Set trans(ind) = extLabels(types(ind))
			Set types($i(ind)) = "*.xml" If lwildcard="*.xml" Set default = types(ind)
			Set trans(ind) = extLabels(types(ind))
			Set types($i(ind)) = "*.xsd" If lwildcard="*.xsd" Set default = types(ind)
			Set trans(ind) = extLabels(types(ind))
			Set types($i(ind)) = "*.wsdl" If lwildcard="*.wsdl" Set default = types(ind)
			Set trans(ind) = extLabels(types(ind))
		}
		If ((wildcard = "*") || (wildcard = "*.*")) Set default = types(1)
		#; if we cannot find the type from the list then add it to the end and show as is
		If default = "" Set ind=ind+1,types(ind) = wildcard,trans(ind) = wildcard,default = wildcard
		Set (valueList,displayList) = ""
		Set ind = $O(types(""))
		While ind '= "" {
			Set valueList = valueList _ $S(valueList'="":",",1:"") _types(ind)
			Set displayList = displayList _ $S(displayList'="":",",1:"") _ trans(ind)
			Set ind = $O(types(ind))
		}
		
		Set fileTypeEditable = 1
	}
	Set tCombo = ..%GetComponentById("FileType")
	Set tCombo.valueList = valueList
	Set tCombo.displayList = displayList
	set tCombo.editable = fileTypeEditable
	// Set "File type" default
	Set tCombo.value = default
	// If it is show directory only, then do not show the File Type drop-down and update parameter
	If showdirectoryonly = 1 {
		Set ..%GetComponentById("FileType").hidden = 1
		Set p = ..%GetComponentById("view").parameters.GetAt("showdirectoryonly")
		Set p.value = 1   // set the parameter that is passed in to the view's parameter
		Set ..%GetComponentById("FileName").label = $$$Text("Directory:")
	}
	// Update other parameters
	Set p = ..%GetComponentById("view").parameters.GetAt("wildcard")
	Set p.value = default
	Set %page.isWINDOWS = $$$isWINDOWS
	Set %page.isVMS = $$$isVMS
	Quit $$$OK
}

/// This method builds the list of drives for the "look in" window. It will contain
/// the available drives (mount points), or the user-configured set of available directories.
/// In addition, it will contain the set of parent directories for the specified directory. 
Method BuildDrive(Output drives As %String, ByRef drive As %String, Output lastexistingdir As %String)
{
	// first check if we are restriced to specific directories
	Set restrictDirs = ##class(%CSP.Portal.Utils).GetAllowedDirectories(.drives)
	If 'restrictDirs {
		// just use the drives (or mount points) defined by the OS
		Set tRS = ##class(%ResultSet).%New("%File:DriveList")
		Do tRS.Execute(1)
		While tRS.Next() {
			Set dir = tRS.GetData(1)
			If $$$isWINDOWS {
				Set dir = $zconvert(dir,"U")
			} Else {
				Set dir = ##class(%File).NormalizeDirectory(dir)
			}
			If +$zu(140,13,dir) > 0 {
				Set drives(dir) = ""
			}
		}
		Kill tRS
		If $O(drives(""))="",$$$isUNIX Set drives("/") = ""
	}

	// now add the paths for this directory's parent directories
	If $$$isVMS { // VMS does code does not support restricted directories
		If drive [ ":[000000]" Set drive = $P(drive,":",1)_":",lastexistingdir = drive
		Set tRS = ##class(%ResultSet).%New("%File:ParseDirectory")
		Do tRS.Execute(drive)
		Set p = 0
		While tRS.Next() {
			Set tName = tRS.GetData(1)
			Set tDirectory = tRS.GetData(3)
			Set p = p + 1
			If tRS.GetData(2) = 1 Kill drives(tName)
			If ##class(%File).DirectoryExists(tDirectory) Set drives(p) = $S(tRS.GetData(2)'=1:tDirectory,1:tName),lastexistingdir = drives(p)			
		}
	} Else {
		Set rootDir = ..FindRoot(##class(%File).NormalizeDirectory(drive), .drives)
		If rootDir="" { // the user specified a directory that is not allowed
			Set (rootDir,drive) = $order(drives("")) 
		}
		Set lastexistingdir = drive

		Set tRS = ##class(%ResultSet).%New("%File:ParseDirectory")
		Do tRS.Execute(drive)
		While tRS.Next() {
			Set tName = tRS.GetData(1)
			If tRS.GetData(2) = 1 Kill drives(##class(%File).NormalizeDirectory(tName))
			Set tDirectory = tRS.GetData(3)
			If restrictDirs && ((rootDir="") || ($extract(tDirectory,1,$length(rootDir))'=rootDir)) Continue
			If ##class(%File).DirectoryExists(tDirectory) {
				Set drives(tDirectory) = "",lastexistingdir = tDirectory
			}
		}
		If '##class(%File).DirectoryExists(drive) Set drive = lastexistingdir
	}
}

/// Given a file path, return the matching root path, or "" if it is invalid.
/// The values must be normalized prior to calling, otherwise this will be
/// vulnerable to directory traversal attacks, and because Windows file paths
/// are case insensitive.
Method FindRoot(path As %String, ByRef roots As %String) As %String [ Private ]
{
	Set dir = ""
	For {
		Set dir = $order(roots(dir))
		If dir="" Quit
		If $extract(path,1,$length(dir))=dir {
			Return dir
		}
	}
 	Return ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return encodeURIComponent(this.getComponentById('FileName').getValue());
}

/// User clicked an item. 
/// We put it in the File name field. User can OK it or [Enter] to drill down.
ClientMethod itemClicked(viewobj) [ Language = javascript ]
{
	// "d" is the value you currently clicked, it contains two piece delimited by "^":
	// 1) the whole path and file name
	// 2) the file type
	var d = viewobj.getProperty('value');
	var thisitem = d.split("^");
	var tvalue = thisitem[0];
	if (thisitem[1] == "D" && this.FileName != "") tvalue = tvalue + this.FileName;
	zenPage.getComponentById("FileName").setValue(tvalue);
}

/// User has selected a new item (double click).
ClientMethod itemSelected(viewobj) [ Language = javascript ]
{
	var driveobj = zenPage.getComponentById("Lookin");
	var d = viewobj.getProperty('value'); //this is the value you currently clicked	
	var thisitem = d.split("^");
	var tvalue = thisitem[0];
	if (thisitem[1] == "D") {
		// If it's a Direcotry then reset Look in drop-down box, and reload view
		this.reloadLookin(driveobj,tvalue);
	} else {
		// If it's a File then set it to the File textfield and go for OK
		zenPage.getComponentById("FileName").setValue(tvalue);
		zenPage.dialogFinish();
	}
}

/// Construct new directory given the Look in directory and selected directory from the middle frame
ClassMethod GetSubDir(LookinDir, Dir) As %String [ ZenMethod ]
{
	Set tDir = ##class(%File).SubDirectoryName(LookinDir,Dir)
	Set Dir = ##class(%File).NormalizeDirectory(tDir)
	Quit Dir
}

/// Construct new directory given the Look in directory and selected directory from the middle frame
Method RebuildLookin(Dir, wildcard) [ ZenMethod ]
{
	Do ..BuildDrive(.drives, .Dir, .lastexistingdir)

	Set tCombo = %page.%GetComponentById("Lookin")
	
	Set drivename = $O(drives(""))
	If $$$isVMS {
		While drivename '= "" {
			Kill driveindex
			If drivename?1.N Set driveindex = drivename,drivename = drives(driveindex)
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do tCombo.options.Insert(tOption)
			Do ..%AddComponent(tOption)
			Set tOption.text = drivename
			Set tOption.value = drivename
			Set tOption.style = "font-size:12px;"
			If $G(driveindex) Set drivename = $O(drives(driveindex))
			Else  Set drivename = $O(drives(drivename))
		}	
	} Else {
		While drivename '= "" {
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do tCombo.options.Insert(tOption)
			Do ..%AddComponent(tOption)
			Set tOption.text = drivename
			Set tOption.value = drivename
			Set tOption.style = "font-size:12px;"
			Set drivename = $O(drives(drivename))
		}
	}

	#; Set "Look in" default
	Set tDir = $select(Dir="":"", 1:##class(%File).NormalizeDirectory(Dir))
	Set tCombo.value =  tDir
	Set tCombo.originalValue =  tDir
	#; Set "FileName" value, with the user entered Filename if it exists.
	Set %page.%GetComponentById("FileName").value = $S(%page.FileName="":tDir,1:##class(%File).NormalizeFilename(%page.FileName,tDir))
	#; Refresh Content
	&javascript<
		var viewobj = zenPage.getComponentById("view");
		viewobj.setProperty("parameters","Dir", "#($ZCVT(Dir,"O","JS"))#");
		viewobj.setProperty("parameters","wildcard", "#($ZCVT(wildcard,"O","JS"))#");
		viewobj.refreshContents();
	>
	Quit
}

/// Check if user entered directory exists. Return a valid directory.
Method GetDirectory(Dir As %String) As %String [ ZenMethod ]
{
	Quit ##class(%Library.File).GetDirectory(Dir,1)
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
/// Check FileName value. If user entered a path, then return as is.<br>
/// If user enters something but not including a path, then add selected path in front of it.<br>
/// It is possible that user is entering a sub directory or file, therefore as a curtersey we add the path for them.<br>
/// In addition, if user enters a filename without a file extension, then we add the filetype choice from the drop-down.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var file = zenPage.getComponentById("FileName").getValue();
		if (file.length > 0) {
			var path = zenPage.getComponentById("Lookin").getValue();
			var filetype = "";
			if (!this.showdirectoryonly) filetype = this.getComponentById("FileType").getValue();
			var tvalue = file;
			// if no directory is entered, attach path here to the file name
			if (!this.hasdelimiter(file)) {
				if (file.indexOf(":") > -1) {
					file = this.CheckRootDir(file);
				}
				if (this.showdirectoryonly == true) {
					tvalue = this.GetSubDir(path, file);
				} else {
					//YSD2250 tvalue = path + file;
					tvalue = this.GetDirFile(path,file,filetype);
				}
			} else {
				tvalue = this.CheckPath(path,file,filetype);
			}
			zenPage.getComponentById("FileName").setValue(tvalue);
			
			if (this.ExtFilter) {
				var ext = tvalue.split('.');
				ext = ext[ext.length-1];
				var filter = this.ExtFilter.replace(/;/g,',').split(',');
				var found = false;

				for (var i=0; i<filter.length; ++i) {
					if (ext == filter[i].slice(2)) {
						found = true;
					}
				}
				
				if (!found) {
					zen("FileName").focus();
					zen("FileError").setHidden(false);
					return false;
				}
				
				zen("FileError").setHidden(true);
			}
			
			try {
				/// if the caller is from a CSP page, the CSP page must have a update method for us to return back to.
				if (window.parent && window.parent.opener && window.parent.opener.update) {
					window.parent.opener.update(tvalue);
				}
			} catch (e) { 
				/* ignore DOM security error if we can't access window.parent.opener */
				if ( !(e instanceof DOMException) || (e.code!==DOMException.SECURITY_ERR) ) {
					throw e;
				}
			}
		}
		return true;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

ClientMethod hasdelimiter(file) [ Language = javascript ]
{
	if (file.indexOf("\\") > -1) return true;
	if (file.indexOf("/") > -1) return true;
	if (file.indexOf("[") > -1) return true;
	return false;
}

/// ****** The Following Methods are Called from UtilFile*.csp Also ******<br>
/// If user enters a directory but without drive, we add the drive here. This overrides the "Look in" directory.
/// For Windows and VMS only.
ClassMethod CheckPath(Path As %String, File As %String, FileType As %String) As %String [ ZenMethod ]
{
	//Strip off blanks on both side of the entered directory/file name
	Set File = $ZStrip(File,"<>W")
	If $$$isWINDOWS {
		If File '[ ":",File["\",$E(File,1,2)'="\\" {
			Set File = $P(Path,":",1)_":"_$S($E(File)="\":"",1:"\")_File
		}
	} ElseIf $$$isVMS {
		Set pDrive = $P(File,":",1)
		Set p2 = $P(File,":",2)
		If p2="",$E(pDrive)="[" {
			Set pDir = $P($P(File,"[",2),"]",1)
			If pDir = "" Set pDir = "[000000]"
			If pDir '= "" {
				Set File = $P(Path,":",1)_":["_pDir_"]"_$P(File,"]",2)
			}
		}
	}
	Set File = ..CheckFileExt(File,FileType)
	Quit File
}

/// Check if user entered filename ends with ":". If yes, then we should add "/" or [000000] to make valid drive.<br>
/// For Windows: If user enters : without \ then we add it here.<br>
/// For VMS: If user enters : without any [directory] then add [000000] here.<br>
/// If we don't do this then directory would be invalid.
ClassMethod CheckRootDir(File As %String) As %String [ ZenMethod ]
{
	//Strip off blanks on both side of the entered directory/file name
	Set File = $ZStrip(File,"<>W")	
	If $E(File,$L(File)) = ":" {
		If $$$isWINDOWS Set File = File_"\"			// win
		If $$$isUNIX Set File = File_"/"			// unix
		If $$$isVMS Set File = File_"[000000]"		// vms
		Quit File
	} Else {
		If $$$isWINDOWS Set File = $P(File,":")_":\"_$P(File,":",2)			// win
	}
	//If user entered a filename without root directory, add it here. Otherwise file is invalid.
	If $$$isVMS {
		Set p2 = $P(File,":",2)
		If p2'="",p2'["[" Set File = $P(File,":",1)_":["_p2_"]" Quit File
	}
	Quit File
}

/// Construct new new file name, if it does not have dir yet
ClassMethod GetDirFile(LookinDir, File, FileType) As %String [ ZenMethod ]
{
	If ##class(%File).GetDirectory(File) = "" {
		Set File = ##class(%File).NormalizeFilename(File, LookinDir)
	}
	If FileType '= "" Set File = ..CheckFileExt(File,FileType)
	Quit File
}

/// Check if file has extension. If not, add it.
ClassMethod CheckFileExt(File, FileType) As %String [ ZenMethod ]
{
	Set Filename = ##class(%File).GetFilename(File)
	#; If user did not enter any file name then don't append extension
	If Filename = "" Quit File
	#; If the last character is dot then add the extension
	If $E(Filename,$L(Filename)) = "." Quit File_$P($P(FileType,".",2),";",1)
	#; If user entered any type of extension, return as is because what user entered could be different than the filetype.
	If Filename [ "." Quit File
	#; If user entered a filename without extension, add it
	If FileType [ "*.ro" Quit File_".ro"
	If FileType [ "*.go" Quit File_".go"
	#; If there is no extension then return file as is
	If $P($P(FileType,".",2),";",1) = "" Quit File
	Quit File_"."_$P($P(FileType,".",2),";",1)
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	this.onresizeHandler();
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var view = zen('view');
	if (view) {
		var viewDiv = view.getEnclosingDiv();
		if (viewDiv) {
			// restrict width of view div to avoid unnecessary scrolling
			var wd = zenGetWindowWidth() - 40;
			if (wd < 100) wd = 100;
			viewDiv.style.width = wd + 'px';
		}
	}
}

}
