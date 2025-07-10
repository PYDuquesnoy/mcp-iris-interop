/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Abstract Document used to server SVG-editor documents into Studio<br>
/// Subclasses need to provide:<br>
/// RegisterExtension Projection<br>
/// Save method<br>
/// Exists method<br>
/// EDITORURL parameter<br>
/// DOCUMENTCLASS parameter<br> 
Class Ens.Util.AbstractDocument Extends %Studio.AbstractDocument [ Abstract, System = 4 ]
{

/// URL to use to get actual editor for Studio to display.
Parameter EDITORURL;

/// If set, name of superclass used for documents of this type.<br>
/// For example, Ens.DataTransformDTL
Parameter DOCUMENTCLASS;

/// File extension used for this document (e.g., .dtl)
Parameter EXTENSION;

/// Use Ensemble domain for localization
Parameter DOMAIN = "Ensemble";

/// Return the corresponding class name for this document
ClassMethod GetClassName(pName As %String) As %String [ CodeMode = expression ]
{
$P(pName,".",1,$L(pName,".")-1)
}

/// Check to see that the file type matches
ClassMethod HasExtension(name As %String, ext As %String) As %Boolean [ CodeMode = expression ]
{
($ZCVT($E(name,$L(name)-$L(ext)+1,*),"L")=$ZCVT(ext,"L"))
}

/// Return URL for Studio to use to load editor.
Method Load() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tURL = ..GetCSPApp() _ ..GetURL(..Name)
		Do ..Clear()
		Do ..Code.WriteLine(tURL)
	}
	Catch ex {
		Write !,"Error opening document: ",..Name," ",ex.DisplayString()
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Lock the class definition for the document.
Method Lock(flags As %String) As %Status
{
	If ..Locked Set ..Locked=..Locked+1 Quit $$$OK
	Set tClassname = ..GetClassName(..Name)
	Lock +^oddDEF(tClassname):0
	If '$Test Quit $$$ERROR($$$CanNotLockRoutineInfo,tClassname)
	Set ..Locked=1
	Quit $$$OK
}

/// Lock the class definition for a document by name.
ClassMethod LockName(name As %String) As %Status
{
	Set tClassname = ..GetClassName(name)
	Lock +^oddDEF(tClassname):0
	If '$Test Quit $$$ERROR($$$CanNotLockRoutineInfo,tClassname)
	Quit $$$OK
}

/// Unlock the class definition for the document.
Method Unlock(flags As %String) As %Status
{
	If '..Locked Quit $$$OK
	Set tClassname = ..GetClassName(..Name)
	If ..Locked>1 Set ..Locked=..Locked-1 Quit $$$OK
	Lock -^oddDEF(tClassname)
	Set ..Locked=0
	Quit $$$OK
}

/// Unlock the class definition for a document by name.
ClassMethod UnlockName(name As %String) As %Status
{
	Set tClassname = ..GetClassName(name)
	Lock -^oddDEF(tClassname)
	Quit $$$OK
}

ClassMethod GetURL(pName As %String) As %String
{
	Quit ..#EDITORURL
}

ClassMethod GetCSPApp() As %String [ Private ]
{
	// Determine the CSP application for the management portal, otherwise use the default
	Set cspApp = ##class(%Library.EnsembleMgr).DetermineMgmtURLForNamespace($namespace,0)
	If cspApp = "" {
		Set cspApp = $system.CSP.GetDefaultApp($namespace)
		If cspApp '= "" {
			Set cspApp = cspApp _ "/"
		}
		Else {
			Set cspApp= "/csp/"_$ZCVT($namespace,"L")_"/"
		}
	}
	Quit cspApp
}

/// Return 1 if the given document exists and 0 if it does not.<br>
/// Subclass should override this behavior.
ClassMethod Exists(name As %String) As %Boolean
{
	Set tExists = 0
	Try {
		Set tClass = ..GetClassName(name)
		Set tExists = ##class(%Dictionary.ClassDefinition).%ExistsId(tClass)
	}
	Catch ex {
		Set tExists = 0
	}
	
	Quit tExists
}

/// Compile this document
Method CompileDocument(flags As %String) As %Status
{
	Set tSC = $$$OK
	If (..#DOCUMENTCLASS'="") {
		If $get($$$qualifierGetValue(flags,"displaylog")) Write !,$$$FormatText($$$Text("Compiling document '%1'"),..Name)
		Set tSC = $System.OBJ.Compile(..GetClassName(..Name),.flags,,1)
	}
	Quit tSC
}

/// Delete the class that corresponds to document <var>name</var>.
/// Subclass should override this behavior for non-class based editors.
ClassMethod Delete(name As %String) As %Status
{
	Set tSC = $$$OK
	If (..#DOCUMENTCLASS'="") {
		Set tSC = $System.OBJ.Delete(..GetClassName(name))
	}
	Quit tSC
}

/// Return the timestamp of routine 'name' in %TimeStamp format. This is used to determine if the routine has
/// been updated on the server and so needs reloading from Studio. So the format should be $zdatetime($horolog,3),
/// or "" if the routine does not exist.<br>
/// Subclass should override this behavior for non-class based editors.
ClassMethod TimeStamp(name As %String) As %TimeStamp
{
	If (..#DOCUMENTCLASS'="") {
		// strip off extension; find TimeChanged for class
		Set cls = ..GetClassName(name)
		Quit $ZDT($$$defClassKeyGet(cls,$$$cCLASStimechanged),3)
	}
	Else {
		Quit ""
	}
}

/// Subclass should override this query for non-class based editors.
Query List(Directory As %String, Flat As %Boolean, System As %Boolean) As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer,directory:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Directory As %String, Flat As %Boolean, System As %Boolean) As %Status
{
	Set qHandle = ""
	If Directory'="" Quit $$$OK
	
	// get list of classes
	Set tRS = ##class(%Library.ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")

	Do tRS.Execute(..#DOCUMENTCLASS)
	While (tRS.Next()) {
		Set qHandle("Classes",tRS.Data("Name")) = ""
	}
	
	Quit $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ListExecute ]
{
	Set qHandle = $O(qHandle("Classes",qHandle))
	If (qHandle '= "") {
		
		Set tTime = $ZDT($$$defClassKeyGet(qHandle,$$$cCLASStimechanged),3)
		Set Row = $LB(qHandle _ ..#EXTENSION,tTime,,"")
		Set AtEnd = 0
	}
	Else {
		Set Row = ""
		Set AtEnd = 1
	}
	Quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListExecute ]
{
	Quit $$$OK
}

/// Return other document types that this is related to.
/// Passed a name and you return a comma separated list of the other documents it is related to
/// or "" if it is not related to anything<br>
/// Subclass should override this behavior for non-class based editors.
ClassMethod GetOther(Name As %String) As %String
{
	If (..#DOCUMENTCLASS="") {
		// no related item
		Quit ""
	}
	
	Set result = "",tCls=..GetClassName(Name)
	
	// This changes with MAK1867
	If ..HasExtension(Name,..#EXTENSION),$$$defClassDefined(tCls),..Exists(Name) {
		Set:result'="" result=result_","
		Set result = result _ tCls _ ".cls"
	}
	
	Quit result
}

/// Make the XML export export the class instead of this studio document which is only the XData.
ClassMethod TranslateExportName(name As %String, ByRef items As %String) As %Status
{
	Kill items(name)
	Set items($piece(name,".",1,$length(name,".")-1)_".cls")=""
	Quit $$$OK
}

/// Return true if this is mapped from a database other than the default routine database and zero otherwise.
/// Also set the source database in <var>sourcedb</var>.
ClassMethod IsMapped(name As %String, ByRef sourcedb As %String) As %Boolean
{
	Set className = ..GetClassName(name)_".CLS"
	Return ##class(%RoutineMgr).IsMapped(className,.sourcedb)
}

}
