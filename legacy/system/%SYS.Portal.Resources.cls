/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// This class will allow a user to associate resources with pages in the
/// system management portal.
Class %SYS.Portal.Resources Extends (%Persistent, %XML.Adaptor, %SYSTEM.Help) [ Inheritance = right, System = 4 ]
{

Index PageIndex On Page [ IdKey ];

/// Page identifier.<br>
Property Page As %String(MAXLEN = 256) [ Internal, Required ];

/// Resource for the page.<br>
Property Resource As %String(MAXLEN = 64) [ Internal, Required ];

/// Return the resource for the URL-encoded page specified in <var>Page</var>.
ClassMethod %GetCustomResource(Page As %String) As %String [ Internal ]
{
 s Page=..NormalizePage(Page)
 i Page="" q ""
 s Obj=..%OpenId(Page)
 i Obj="" q ""
 q Obj.Resource
}

/// Return the list of custom resources used by the portal.<br>
/// Parameters:<br><br>
/// <var>Resources</var> (ByRef) - Array of Resources used by the portal.<br>
/// Resources(Resource)=""
ClassMethod %GetCustomResourceList(ByRef Resources As %String) As %Status [ Internal ]
{
 s $zt="Error"
 k Resources
 Set Rset = ##class(%ResultSet).%New("%SYS.Portal.Resources:List")
 i '$$$ISOK(Rset) q %objlasterror
 s Status=Rset.Execute()
 i '$$$ISOK(Status) q Status
 While Rset.Next() {
	s Resources(Rset.Data("Resource"))=""
 }
 q $$$OK 
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Remove the custom resource for the URL-encoded page specified in <var>Page</var>.
ClassMethod %RemoveCustomResource(Page As %String) As %Status [ Internal ]
{
 s $zt="Error"
 i '$system.Security.Check($$$AdminSecureResourceName,$$$PermUseName) Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
 i '##class(%CSP.Portal.Utils).%IsPortalPage(Page,.tNormPage) Quit $$$ERROR($$$CSPPageNotFound)
 i tNormPage="" q $$$OK
 s Obj=..%OpenId(tNormPage)
 i Obj="" q $$$OK
 s Status=Obj.%Delete(Obj.%Oid())
 q Status
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Assign the resource specified in <var>Resource</var> to the URL-encoded page supplied in <var>Resource</var>.<br>
/// Parameters:<br><br>
/// <var>Page</var> - Identifier of the page to set the resource for. (Note: this should be in URL-encoded form.)<br>
/// <var>Resource</var> - Resource associated with the page.<br>
/// If <var>Resource</var> is passed as a null String, then the custom resource is removed.
ClassMethod %SetCustomResource(Page As %String, Resource As %String) As %Status [ Internal ]
{
 s $zt="Error"
 If '$system.Security.Check($$$AdminSecureResourceName,$$$PermUseName) Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
 i '##class(%CSP.Portal.Utils).%IsPortalPage(Page,.tNormPage) Quit $$$ERROR($$$CSPPageNotFound)
 i Resource="" {
 	s Status=..%RemoveCustomResource(Page)
 	q Status
 }
 i ..%ExistsId(tNormPage) s Obj=..%OpenId(tNormPage)
 e  s Obj=..%New()
 i Obj="" q %objlasterror
 s Obj.Page=tNormPage
 s Obj.Resource=Resource
 s Status=Obj.%Save()
 q Status
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Normalize a CSP or Zen link to the underlying class name.
/// Returns "" if the target page can't be resolved to a class, with the proviso that 
/// the method will return "" in many cases where the underlying class is not in the portal.<br/>
/// This method uses $zconvert(<var>Page</var>,"I","URL"), so <var>Page</var> should be supplied in URL-encoded form.
/// In most cases, this will be the same as the classname, but in others, such as %DeepSee classes, the URL-encoded form is required.
ClassMethod NormalizePage(Page As %String = "") As %String [ Internal ]
{
	Set tClassname = ""
	Try {
		If Page = "" Quit
		#; Ensure we have sufficient permissions to determine whether the class exists
		$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
		Set tPage = $piece(Page,"?",1)
		Set tPage = $piece(tPage,"#",1)
		Set tPage = $zcvt(tPage,"I","URL")
		If $IsObject($get(%request)) && (%request.URLPrefix '= "") && ($extract(tPage,1,$length(%request.URLPrefix)) = %request.URLPrefix) {
			Set tPage = $extract(tPage,$length(%request.URLPrefix)+1,*)
		}
		Set tLen = $length(tPage,".")
		Set tExt = $zcvt($piece(tPage,".",tLen),"L")
		Set tIsClass = $case(tExt, "csp": 0, "cls": 1, "zen": 1, : 1)
		If tIsClass {
			If (tExt = "cls") || (tExt = "zen") {
				Set tPage = $piece(tPage,".",1,tLen-1)
			}
			Set tPage = $piece(tPage,"/",$length(tPage,"/"))
			If $extract(tPage)="_" Set $extract(tPage)="%"
			Set tPage = $$$NormalizeClassname(tPage)
			Set tPackage = $p(tPage,".",1)
			Do  // Introduce DO frame for possible NEW $namespace - we may need to change into ENSLIB for Ensemble classes
			.	If ((tPackage = "EnsPortal") || (tPackage = "EnsLib") || (tPackage = "Ens")) && ##class(%Library.EnsembleMgr).IsEnsembleInstalled() && '##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
			.		New $namespace
			.		Set $namespace = ##class(%Library.EnsembleMgr).GetENSLIB(1)
			.	}
			.	If ##class(%Dictionary.CompiledClass).%ExistsId(tPage) {
			.		Set tClassname = tPage
			.	} 
			.	If ((tClassname="") && ($system.CLS.DumpContext(tPage)'="")) {
			.		Set tClassname = tPage
			.	}
		}
		Else {
			If $length(tPage,"/") > 1 {
				Set tStartPos = 1+($extract(tPage,1)="/")
				Set tApp = $zcvt($piece(tPage,"/",tStartPos,tStartPos+1),"L")
				// We are only concerned about pages in /csp/sys/*
				If tApp = "csp/sys" {
					Set tSubApp = $zcvt($piece(tPage,"/",tStartPos+2,$length(tPage,"/")-1),"L")
					Set tAdd = $case(tSubApp, "bi": 1, "exp": 1, "mgr": 1, "op": 1, "sec": 1, : 0)
					Set tPackage = "%cspapp."_$select(tAdd: tSubApp_".", 1: "")
					Set tPage = $piece(tPage,"/",$length(tPage,"/"))
					Set tPage = $piece(tPage,".",1,$length(tPage,".")-1)
					If tPage '= "" {
						Set tFullClass = tPackage _ $zcvt(tPage,"L")
						If ##class(%Dictionary.CompiledClass).%ExistsId(tFullClass) {
							Set tClassname = tFullClass
						}
						ElseIf ($system.CLS.DumpContext(tFullClass)'="") {
							Set tClassname = tFullClass
						}
					}
				}
			}
			Else { // It's a local link, so we can get the value via $system.CSP.GetClassName()
				Set tClassname = $system.CSP.GetClassName(tPage)
			}
		}
	}
	Catch ex {
		Set tClassname = ""
	}
	Quit tClassname
}

/// Export Custom Resource records to a file in XML format. The user must
/// have USE permissions on the %Admin_Secure resource to perform the export.<br>
/// Parameters:
/// <ul><li><var>Filename</var> - Output file name.</li>
/// <li><var>NumExported</var> (ByRef) - Returns the number of records exported.</li>
/// <li><var>Pages</var> - Mask for the pages to return. See the <query>List</query>
/// query for details on the format.</li>
/// <li><var>Resources</var> - Mask for the resources to return. See the <query>List</query>
/// query for details on the format.</li></ul>
ClassMethod Export(FileName As %String = "CustomPortalResourcesExport.xml", ByRef NumExported As %Integer, Pages As %String = "*", Resources As %String = "*") As %Status
{
	Set tStatus = $$$OK
	Set NumExported = 0
	Try {
		If '$system.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
			Set tStatus = $$$ERROR($$$InsufficientPrivilegeForOperation)
			Quit
		}
		Kill %objlasterror
		Set tRS = ##class(%Library.ResultSet).%New("%SYS.Portal.Resources:List")
		If '$IsObject(tRS) {
			Set tStatus = $select($get(%objlasterror) '= "": %objlasterror, 1: $$$ERROR($$$QueryCannotInstantiate,"%SYS.Portal.Resources:List"))
			Quit
		}
		Set tRS.RuntimeMode = 1
		Set tWriter = ##class(%XML.Writer).%New()
		Set tStatus = tWriter.OutputToFile(FileName)
		If $$$ISERR(tStatus) Quit
		Set tWriter.Charset = "UTF-8"
		Set tWriter.Indent = 1
		Set tStatus = tWriter.RootElement("CustomPortalResourcesExport")
		If $$$ISERR(tStatus) Quit
		Set tStatus = tRS.Execute(Pages,Resources)
		If $$$ISERR(tStatus) Quit
		While tRS.Next() {
			Set tObject = ..%OpenId(tRS.Get("Page"),,.tStatus)
			If $$$ISERR(tStatus) Quit
			Set tStatus = tWriter.Object(tObject)
			If $$$ISERR(tStatus) Quit
			Set NumExported = NumExported + 1
		}
		If $$$ISERR(tStatus) Quit
		Set tStatus = tWriter.EndRootElement()
		If $$$ISERR(tStatus) Quit
		Set tStatus = tWriter.EndDocument()
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) && $data(tWriter) Do tWriter.EndDocument()
	Quit tStatus
}

/// Import Custom Resource records from an XML file. The user must have
/// USE permissions on the %Admin_Secure resource to perform the import.<br>
/// Parameters:
/// <ul><li><var>FileName</var> - Filename to import Custom Resource records from.</li>
/// <li><var>NumImported</var> (ByRef) - Returns the number of records imported.</li>
/// <li><var>InvalidRecords
/// <li><var>Flags</var> - Control whether to import the records in the file.
/// The supported bit flags at present are:
/// <ul><li>Bit 0 - Do not import records, just return the count.</li>
/// <li>Bit 1 - Do not require that the resource exists.</ul></li></ul>
/// Note: On failure, no records will be imported.
ClassMethod Import(FileName As %String = "ResourcesExport.xml", ByRef NumImported As %Integer, Flags As %Integer = 0) As %Status
{
	Set tStatus = $$$OK
	Set NumImported = 0
	Set tInitTLevel = $TLevel
 	Try {
	 	If '$system.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		 	Set tStatus = $$$ERROR($$$InsufficientPrivilegeForOperation)
		 	Quit
	 	}
	 	Set tReader=##class(%XML.Reader).%New()
 		Set tStatus = tReader.OpenFile(FileName)
		If $$$ISERR(tStatus) Quit
		Do tReader.Correlate("Resources","%SYS.Portal.Resources")
		TSTART
		While tReader.Next(.tObject,.tStatus) {
			If $$$ISERR(tStatus) Quit
			If $zb(Flags,1,1) {
				Set NumImported = NumImported + 1
			}
			Else {
				#; Check that resource exists
				If ('$zb(Flags,2,1)) && '$$$SecurityResourcesExists(tObject.Resource,tDummy) {
					Set tStatus = $$$ERROR($$$ResourceDoesNotExist,tObject.Resource)
					Quit
				}
				Set tStatus = ..%SetCustomResource($zconvert(tObject.Page,"O","URL"),tObject.Resource)
				If $$$ISERR(tStatus) Quit
				Set NumImported = NumImported + 1
			}
		}
		If $$$ISERR(tStatus) Quit
		TCOMMIT
 	}
 	Catch ex {
	 	Set tStatus = ex.AsStatus()
 	}
 	Try {
 		While tInitTLevel < $TLevel {
	 		TROLLBACK 1
 		}
 	}
 	Catch ex {
	 	Set tStatus = $$$ADDSC(tStatus,ex.AsStatus())
 	}
 	Quit tStatus
}

/// List pages and associated resources. Note: the <strong>Page</strong> column lists the normalized page name.<br>
/// Use the <var>Pages</var> and <var>Resources</var> arguments to restrict the list. The possible inputs for each
/// argument is a comma-separated string with the following rules:
/// <ul>
/// <li>"*" - match all records.</li>
/// <li>"String,String1" - match all records that match an element in the string</li>
/// <li>"String*" - match all records starting with "String"</li>
/// <li>"String,String1*,String2" - match any record equal to "String" or "String2", or starting with "String1"</li></ul>
/// Note: This query may change in future versions.
Query List(Pages As %String = "*", Resources As %String = "*") As %Query(ROWSPEC = "Page:%String,Resource:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Pages As %String = "*", Resources As %String = "*") As %Status [ Internal ]
{
 s $zt="Error"
 &SQL(DECLARE ResourcesListCursor CURSOR for 
	SELECT Page,Resource
	FROM Resources
 	WHERE (%SYSTEM.Util_CheckName(:Pages,Page)=1)
 	AND   (%SYSTEM.Util_CheckName(:Resources,Resource)=1)
	ORDER BY Page,Resource)
 &SQL(OPEN ResourcesListCursor)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 Quit $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListExecute ]
{
 &SQL(FETCH ResourcesListCursor
	INTO :Page,:Resource)
 if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
 If SQLCODE=100 {
	Set Row="",AtEnd=1
 } Else {
	Set Row=$LB(Page,Resource)
	Set AtEnd=0
 }
 Quit $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListExecute ]
{
	&SQL(CLOSE ResourcesListCursor)
	if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
	Quit $$$OK
}

Storage Default
{
<Data name="UsersDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Resource</Value>
</Value>
</Data>
<DataLocation>^|"^^"_$zu(12)|SYS("Portal","ResourcesD")</DataLocation>
<DefaultData>UsersDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^|"^^"_$zu(12)|SYS("Portal","ResourcesD")</IdLocation>
<IndexLocation>^|"^^"_$zu(12)|SYS("Portal","ResourcesI")</IndexLocation>
<StreamLocation>^|"^^"_$zu(12)|SYS("Portal","ResourcesS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
