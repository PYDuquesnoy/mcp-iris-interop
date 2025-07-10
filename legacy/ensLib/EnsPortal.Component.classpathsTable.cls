/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// A composite control containing the HTML to build out an 'add file' button and a table which displays each file in the ClassPath as a separate row
Class EnsPortal.Component.classpathsTable Extends %ZEN.Component.composite [ System = 4 ]
{

Parameter USECOMMONDIRECTORY = 1;

Parameter DOMAIN = "Ensemble";

Property wildcard As %ZEN.Datatype.string [ InitialExpression = "*" ];

Property classpaths As %String(MAXLEN = "");

Property currFile As %Integer [ InitialExpression = 0 ];

Property currFileName As %String;

Property inFileSelect As %Boolean [ InitialExpression = 0 ];

Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
<vgroup>
<html id="htmlClasspaths"  seed=""/>
</vgroup>
</composite>
}

/// Get the contents of the CLASSPATH table
Method GetContents() As %String [ ZenMethod ]
{
	#dim tCount,i As %Integer = 0
	#dim tPaths,tOnePath As %String = ""
	#dim tEditable As %Boolean = 0
	#dim tHTML As %String = ""
	#dim tWidth As %Integer = 350
	
	If '..readOnly {
		Set tHTML = "<image id=""addBtn"" style=""vertical-align:middle;padding-top:5px;padding-left:10px;"" src=""deepsee/ds_plus_16.gif"" title="""_$$$Text("Add a file")_""" onclick=""zenPage.getComponentById('"_..id_"').addFile();""/>" _
			"<span id=""addFileTxt"" class=""zenLabel settingLabel"" style=""vertical-align:middle;padding-top:5px;padding-left:5px;"">"_$$$Text("Add File")_"</span>"
	}
	Set tHTML = tHTML_"<table class=""propListTable"" style=""padding-top:6px;padding-left:2px;max-width:380px;"" border=""0"" cellspacing=""0"">"

	Set tPaths = ..classpaths
	If (""'=tPaths) {
		Set tCount = $L(tPaths,"|")
	} ElseIf (..currFile = 1) {
		Set tCount = 1
	}

	If (tCount > 0) {
		If '..readOnly {
			#; subtract icon widths from tWidth to get appropriate width for text
			Set tWidth = tWidth - (..CanViewFileSystem() * 16) ; add icon visible
			 	- (((..currFile > 0) && (tCount > 1)) * 34) ; modify icon visible for some row
			 	- 18 ; delete icon
		}
		For i=1:1:tCount {
			Set tOnePath = $P(tPaths,"|",i)
			Set tEditable = ('..readOnly && (..currFile = i))
			Set tHTML = tHTML _ 
					"<tr class='"_$Select((i#2):"rowOdd",1:"rowEven")_"'>"
			If '..readOnly {
				Set tHTML = tHTML _ 
					"<td nowrap>" _
					"<image id=""delete_"_i_""" title='"_$$$Text("Remove this file from the list")_"' src=""deepsee/close_a_16.gif"" alt=""Delete"" onclick=""zenPage.getComponentById('"_..id_"').deleteFile("_i_");zenPage.getComponentById('"_..id_"').setModified();zenPage.getComponentById('"_..id_"').refreshClasspaths();""/>" _
					"</td>" _
					"<td nowrap>" _
					"<image id=""modify_"_i_""" "_$S(tEditable:"hidden='true'",1:"")_" title='"_$$$Text("Modify this file path")_"' src=""deepsee/notepad_16.png"" alt=""Edit"" onclick=""zenPage.getComponentById('"_..id_"').switchCurrFile("_i_");""/>" _
					"</td>"
				If ..CanViewFileSystem() {
					Set tHTML = tHTML _
						"<td nowrap>" _
						"<image id=""add_"_i_""" "_$S('tEditable:"hidden='true'",1:"")_" title='"_$$$Text("Browse for file")_"' alt=""Browse"" src=""portal/files_48.gif"" style=""width:20px;height:20px;"" onclick=""zenPage.getComponentById('"_..id_"').showFileSelect(this.value)"" />" _
						"</td>"
				}
			}
			Set tHTML = tHTML _
				"<td id=""filename_"_i_""" style=""width:"_tWidth_"px;font-size:8pt;font-weight:normal;word-break:break-all;"" "_$S(tEditable:"hidden='true' ",1:"")_">"_$zcvt(tOnePath,"O","HTML")_"</td>"
			If '..readOnly {
				Set tHTML = tHTML _
				"<td id=""txt_filename_"_i_""" style=""padding-left:3px;"" "_$S('tEditable:"hidden='true'",1:"")_"><input type=""text"" style=""width:"_tWidth_"px;"" onblur=""zenPage.getComponentById('"_..id_"').switchCurrFile(0,this.value);"" value='"_$zcvt(tOnePath,"O","HTML")_"'/></td>"
			}
			Set tHTML = tHTML_"</tr>"
		}
	} ElseIf ..readOnly {
		Set tHTML = tHTML_"<tr class='rowOdd'><td id=""filename"" style=""width:350px;"">&nbsp;</td></tr>"
	}
	Set tHTML = tHTML _ "</table>"
	
	Quit tHTML
}

/// Is the user permitted to access the fileSelect popup.
Method CanViewFileSystem() As %Boolean [ ZenMethod ]
{
	Quit $system.Security.Check("%Ens_ViewFileSystem","USE")
}

Method deleteFile(pNumber) As %Boolean [ ZenMethod ]
{
	#dim tPaths As %String = ..classpaths
	#dim tLenBefore As %Integer = 0
	
	If ""'=tPaths {
		Set tCount = $L(tPaths,"|")
		If tCount >= pNumber {
			If pNumber > 1 {
				Set tLenBefore = $L($P(tPaths,"|",1,pNumber-1))
				Set $P(tPaths,"|",pNumber)=""
				Set tPaths = ($E(tPaths,1,tLenBefore)_$S(tCount'=pNumber:$E(tPaths,tLenBefore+2,*),1:""))
			} ElseIf tCount > 1 {
				Set tPaths = $P(tPaths,"|",2,*)
			} Else {
				Set tPaths = ""
			}
			
			Set ..classpaths = tPaths	
		}
	}
	#; may not necessarily be the case
	If (pNumber = ..currFile) {
		Set ..currFile = 0
	}
	
	Quit 1
}

ClientMethod addFile() [ Language = javascript ]
{
	var paths = this.classpaths;
	if ((""!=paths) && (paths.slice(-1)!="|")) {
		paths = (paths + "|")
		this.classpaths = paths;
	}
	this.switchCurrFile(paths.split("|").length);
}

/// Refresh the table which displays the extra CLASSPATHS to use
ClientMethod refreshClasspaths() [ Language = javascript ]
{
	var html = this.getChildById("htmlClasspaths");
	if (html) {
	} else {
		var html = zenPage.createComponent('html');
		html.setProperty('id',this.id+".htmlClasspaths");	
		this.addChild(html);
	}

	var content = this.GetContents();
	html.content = content;
	
	// test if we have not been rendered yet
	if (this.getEnclosingDiv() == null) return;
		
	comp = zenPage.getComponentById(this.id);
	if ((comp != null)) {
		comp.refreshContents();
	}
	return;
}

/// Set a particular filepath to be editable
ClientMethod setCurrFile(switchTo) [ Language = javascript ]
{
	this.currFile = switchTo;
	this.refreshClasspaths();
}

/// Call on Production Config page's settingChanged() so that it recognizes this change
ClientMethod setModified() [ Language = javascript ]
{
	var form = this.getForm();
	zenPage.settingChanged(this.index,(form ? form.index : ''));
}

/// If there is a filepath being edited, save that first before making another filepath editable
/// Then set the new filepath to be editable
ClientMethod switchCurrFile(switchTo, value) [ Language = javascript ]
{
	var current = this.currFile;
	if (current != switchTo) {
		if ((current > 0) && (value != null)) {
			var x = this.saveFile(current,value);
		}
		
		this.setModified();
	}
	this.setCurrFile(switchTo);

	return;
}

Method saveFile(pNumber As %Integer, pValue As %String = "") As %Boolean [ ZenMethod ]
{
	#dim tPaths As %String = ..classpaths
	
	If ""'=pValue {
		Set $P(tPaths,"|",pNumber) = pValue
		
		Set ..classpaths = tPaths	
						
	} Else {
		Do ..deleteFile(pNumber)
	}
	
	Quit 1
}

/// User clicked the Browse button.
/// Helper method to wrap the main selectFile() function in the containing page.
ClientMethod showFileSelect(filename) [ Language = javascript ]
{
	if (!this.CanViewFileSystem()) {
		alert($$$TextJS("You are not permitted to perform this action"));
		return false;
	}
	if (zenPage && (typeof zenPage.selectFile == 'function')) {
		if ((filename != null) && (filename != "")) {
			this.currFileName = filename;
		} else {
			this.currFileName = this.GetDefaultDir();
		}
		this.inFileSelect = 1;
		zenPage.selectFile(this.index);
	}
}

ClientMethod getForm() [ Language = javascript ]
{
	var form = null;
	var parent = this.parent;
	while (parent) {
		if (parent.isOfType('form') || parent.isOfType('loginForm')) {
			form = parent;
			break;
		}
		parent = parent.parent;
	}
	return form;
}

ClassMethod GetPathsToDisplay(pClasspaths = "") As %String [ ZenMethod ]
{
	#dim tClasspaths As %String = pClasspaths
	#dim tDelimiter As %String = $S($system.Version.GetOS()="Windows":";",1:":")
	
	Set tClasspaths = $TR(tClasspaths,tDelimiter,"|")
	Set tClasspaths = $TR(tClasspaths,"||","|")
	For i=1:1:$L(tClasspaths,"|") {
		Set $P(tClasspaths,"|",i) = ..UseIRISHost($P(tClasspaths,"|",i))
	}
	
	Quit tClasspaths
}

ClassMethod UseIRISHost(pFilename) As %String [ ZenMethod ]
{
	#dim tFilename As %String = pFilename
	#dim tInstall = $E($system.Util.InstallDirectory(),1,*-1)
	
	If ($E($zcvt(tFilename,"L"),1,$L(tInstall)) = tInstall) {
		Set tFilename = ("$$IRISHOME"_$E(tFilename,$L(tInstall)+1,*))
	}

	Quit tFilename
}

ClassMethod GetFullFilepath(pFilename) As %String [ ZenMethod ]
{
	#dim tFilename As %String = pFilename
	
	Set:(tFilename?1"$$IRISHOME"1P.E) tFilename = $E($system.Util.InstallDirectory(),1,*-1)_$E(tFilename,11,*)
	
	Quit tFilename
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "ClasspathDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set:($E(pPathname,"*")="|") pPathname=$E(pPathname,1,*-1)
	If (""'=pPathname) {
		Set tOneFile = $P(pPathname,"|",*)
		Set tOneFile = ..GetFullFilepath(tOneFile)
		Set ^EnsPortal.Settings($USERNAME, "ClasspathDir") = ##class(%File).GetDirectory(tOneFile, 1)
	}
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
	case 'disabled':
		this.readOnly = value;
		this.refreshClasspaths();
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Return the value of a named property (i.e. a setting).<br>
/// Returns null if this is not a property of this object.<br>
/// <var>key</var> is an optional argument used for properties
/// (such as collections) that may need a key to find a specific value.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
		return this.readOnly;
		break;
	case 'value':
		return this.getValue();
		// no break;
	default:
		// dispatch
		return this.invokeSuper('getProperty',arguments);
	}
}

/// Client-side method to set the value associated with this control.
/// <var>value2</var> is an optional, second parameter used by some controls
/// (such as <class>dataCombo</class>).
ClientMethod setValue(value, value2) [ Final, Language = javascript ]
{
	if (this.currFile && (this.currFile > 0)) {
		this.SetDefaultDir(value);
		filename = this.UseIRISHost(value);
		this.saveFile(this.currFile,filename);
		this.refreshClasspaths();
	} else if (this.classpaths == "") {
		this.classpaths = this.GetPathsToDisplay(value);
		this.refreshClasspaths();
	}
}

ClientMethod getValue() [ Final, Language = javascript ]
{
	if (this.inFileSelect) {
		this.inFileSelect = 0;
		return this.currFileName;
	} else {
		return this.classpaths;
	}
}

/// Create children on client side so we can use them immediately. Note that the server may substitute fresh code-generated objects later.
ClientMethod createChildren(form) [ Language = javascript ]
{
	var html = zenPage.createComponent('html');
	html.setProperty('id',this.id+".htmlClasspaths");
	
	// override refreshContents() to ensure we don't call back to the server
	html.refreshContents = function() {
		var div = this.getEnclosingDiv();
		if (div) div.innerHTML = this.content;
	};
	
	this.addChild(html);

	this.childrenCreated = true;

	return '';
}

}
