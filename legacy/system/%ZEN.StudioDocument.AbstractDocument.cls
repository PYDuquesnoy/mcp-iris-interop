/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract Document used to serve ZEN-editor documents into Studio<br>
/// In order to create a new Studio Abstract Document, you need to create
/// a subclass of this class and provide the following:
/// <ul>
/// <li>A class Projection named <var>RegisterExtension</var>.<br>
/// For example:<br>
/// Projection RegisterExtension As %Projection.StudioDocument(DocumentExtension = "BPL");
/// </li>
/// <li>A value for the <parameter>EDITORURL</parameter> parameter.<br>
/// This is the URL of the page that provides the actual editor UI.</li>
/// <li>If needed, a value for the <parameter>DOCUMENTCLASS</parameter> parameter.</li> 
/// <li>An override of the <method>Save</method> method.</li>
/// <li>An override of the <method>Exists</method> method.</li>
/// </ul>
Class %ZEN.StudioDocument.AbstractDocument Extends %Studio.AbstractDocument [ Abstract, Deprecated, System = 3 ]
{

/// URL of the editor Studio will display within its HTML pane.
Parameter EDITORURL As STRING;

/// Description Studio will display for this document.<br>
/// If <parameter>DOMAIN</parameter> is defined this will be localized.
Parameter DESCRIPTION As STRING;

/// If set, name of superclass used for documents of this type.<br>
/// For example, "Ens.DataTransformDTL"
Parameter DOCUMENTCLASS As STRING;

/// If true, the built-in document list logic will include abstract classes
/// otherwise they are ignored.
Parameter LISTABSTRACT As BOOLEAN = 0;

/// File extension used for this document (e.g., ".dtl")
Parameter EXTENSION As STRING;

/// Return the corresponding class name for this document
ClassMethod GetClassName(pName As %String) As %String [ CodeMode = expression ]
{
$P(pName,".",1,$L(pName,".")-1)
}

/// Return URL for Studio to use to load editor.
Method Load() As %Status
{
	Set $ZT="Trap",tSC=$$$OK

	Do {
		// get URL and send it to Studio
		If (..#EDITORURL="") {
			// assert: this should not happen
			Set href = "No editor defined for this document!"
		}
		ElseIf ('..Exists(..Name)) {
			// new document
			Set href = "/csp/" _ $namespace _ "/" _ ..#EDITORURL
		}
		Else {
			Set href = "/csp/" _ $namespace _ "/" _ ..#EDITORURL _ "?DOC="_$ZCVT(..Name,"O","URL")
		}

		Do ..Clear()
		Do ..Code.WriteLine(href)

	} While(0)

Exit
	Quit tSC
Trap
	Set $ZT=""
	Write !,"Error opening document: ",..Name," ",$ZE
	Goto Exit
}

/// Return 1 if the given document exists and 0 if it does not.<br>
/// Subclass can override this behavior.
ClassMethod Exists(pName As %String) As %Boolean
{
	Set $ZT="Trap",tExists=0

	Do {
		#; strip off extension
		Set tClass = ..GetClassName(pName)

		If ((..#DOCUMENTCLASS'="") && $$$comClassDefined(tClass)) {
			If (+..#LISTABSTRACT || '+$$$comClassKeyGet(tClass,$$$cCLASSabstract)) {
				If ($zobjclassmethod(tClass,"%IsA",..#DOCUMENTCLASS)) {
					Set tExists = 1
				}
			}
		}

	} While(0)

Exit
	Quit tExists
Trap
	Set $ZT="",tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

/// Compile this document
Method Compile(flags As %String) As %Status
{
	If (..#DOCUMENTCLASS'="") {
		Write !,"Compiling document ",..Name
		Do $System.OBJ.Compile(..GetClassName(..Name),flags)
	}
	Quit $$$OK
}

/// Delete the class that corresponds to document <var>name</var>.
/// Subclass should override this behavior for non-class based editors.
ClassMethod Delete(name As %String) As %Status
{
	If (..#DOCUMENTCLASS'="") {
		Do $System.OBJ.Delete(..GetClassName(name))
	}
	Quit $$$OK
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
Query List(Directory As %String, Flat As %Boolean, System As %Boolean) As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer,directory:%String")
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Directory As %String, Flat As %Boolean, System As %Boolean) As %Status
{
	Set qHandle = ""
	If Directory'="" Quit $$$OK
	
	#; get list of classes, stash them in qHandle
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")

	Do tRS.%Execute(..#DOCUMENTCLASS)
	While (tRS.%Next()) {
		Set tClass = tRS.Data("Name")
		If ('+..#LISTABSTRACT) {
			#; skip abstract classes
			Set tAbstract = +$$$comClassKeyGet(tClass,$$$cCLASSabstract)
			If (tAbstract) Continue
		}
		If ('System) {
			#; skip system classes
			Set tSystem = +$$$comClassKeyGet(tClass,$$$cCLASSsystem)
			If (tSystem) Continue
		}
		Set qHandle("Classes",tClass) = ""
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
	#; make sure name has the right extension
	Set tExt = $ZCVT($P(Name,".",$L(Name,".")),"U")
	Set tDocType = $ZCVT($P(..#EXTENSION,".",$L(..#EXTENSION,".")),"U")
	If (tExt '= tDocType) {
		Quit ""
	}

	If (..#DOCUMENTCLASS="") {
		#; no related item
		Quit ""
	}
	
	#; return corresponding class name for this document
	Quit ..GetClassName(Name) _ ".cls"
}

ClassMethod LocalizeDescription(ext As %String, ByRef Description As %String(MAXLEN=500)) As %Status [ CodeMode = objectgenerator ]
{
#define quote(%val) $zutil(144,1,%val)

	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Set DOMAIN = $G(%parameter("DOMAIN"))
	Set DESCRIPTION = $G(%parameter("DESCRIPTION"))

	If (DESCRIPTION '= "") {
		If (DOMAIN '= "") {
			Do %code.WriteLine(" Set Description = $$$Text(" _ $$$quote(DESCRIPTION) _ ")")
		}
		Else {
			Do %code.WriteLine(" Set Description = " _ $$$quote(DESCRIPTION))
		}
	}
	Do %code.WriteLine(" Quit $$$OK")
	Quit $$$OK
}

}
