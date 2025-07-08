/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents an interface to an instance of OpenAM Enterprise
/// Identity Web Services hosted by an application server.
Class %SYS.OpenAM.IdentityServices Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Parameter VERSION [ Internal ] = 1;

Parameter SOURCECONTROL [ Internal ] = {"Revision path: $Id: //iris/2025.1.0/databases/sys/cls/SYS/OpenAM/IdentityServices.xml#1 $"_$c(13,10)_"Last Change:   $DateTime: 2025/01/31 13:48:15 $"_$c(13,10)_"Changelist #:  $Change: 7556155 $"};

Index NameIndex On Name [ IdKey ];

/// Name of this instance.
Property Name As %String [ Required ];

/// DNS name of
/// the application server hosting OpenAM Enterprise Identity Web Services.
Property Server As %String [ InitialExpression = "localhost", Required ];

/// TCP port that
/// the application server hosting OpenAM Enterprise Identity Web Services
/// is listening on.
Property Port As %Integer [ InitialExpression = 8080, Required ];

/// Path to OpenAM Identity Services on
/// the application server hosting OpenAM Enterprise Identity Web Services.
Property Path As %String [ InitialExpression = "/opensso/identityservices", Required ];

/// SSL client configuration to use when connecting to
/// the application server hosting OpenAM Enterprise Identity Web Services.
/// (optional)
Property SSLConfiguration As %String;

/// Security token obtained on successful authentication.
Property Token As %Net.OpenAM.tns.token(XMLPROJECTION = "NONE") [ Internal, Transient ];

/// Version number of the record. <br>
/// Used for Export/Import.<br>
Property Version As %Decimal(SCALE = 1) [ Internal ];

/// Authenticate the Username and Password, obtaining an internal transient security token if successful.
Method Authenticate(Username As %String, Password As %String) As %Boolean
{
	Set port=##class(%Net.OpenAM.IdentityServicesImplPort).%New()
	If $l(..SSLConfiguration) {
		Set port.SSLConfiguration = ..SSLConfiguration
		Set port.Location="https://"_..Server_":"_..Port_..Path_"/IdentityServices"
	} Else {
		Set port.Location="http://"_..Server_":"_..Port_..Path_"/IdentityServices"
	}
	Set ..Token=""
	Set $zt="Fail"
	Set ..Token=port.authenticate(Username, Password)
	Quit 1
Fail
	Set $zt=""
	Quit 0
}

/// Allow a process with %Admin_Secure:U, but not %DB_IRISSYS:RW, to save an OpenAMIdentityServices object.
/// (A process with %DB_IRISSYS:RW can use %Save.)
Method Save() As %Status
{
	s $zt="Error"
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	n $namespace Do $zu(5,"%SYS")
	Set sc=..%Save()
	Quit sc
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Require %AdminSecure:U
Method %OnBeforeSave(insert As %Boolean) As %Status [ Internal, Private ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	i insert s i%Version=..#VERSION
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called after 
/// the object's data has been successfully written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnAfterSave(insert As %Boolean) As %Status [ Internal, Private ]
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary ; verified 9/26/16 STC
 n $namespace
 d $zu(5,"%SYS")
 ;s Status=##Class(EMS.Groups).RecordChange($$$EMSOpenAMIdentityServicesBit)
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Caller of %Delete must have %Admin_Secure:U. 
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	n $namespace
	d $zu(5,"%SYS")
	;s Status=##Class(EMS.Groups).RecordChange($$$EMSOpenAMIdentityServicesBit)
	;i '$$$ISOK(Status) q Status
	Quit $$$OK
}

ClassMethod StartEMS() As %Status [ Internal ]
{
	s $zt="Error"
	Quit $$$OK
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Allow a process with %Admin_Secure:U, but not %DB_IRISSYS:RW, to delete an OpenAMIdentityServices object.
/// (A process with %DB_IRISSYS:RW can use %Save.)
ClassMethod DeleteId(Name As %String) As %Status
{
	s $zt="Error"
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	n $namespace Do $zu(5,"%SYS")
	Set sc=..%DeleteId(Name)
	Quit sc
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Test whether this instance is correctly configured to use OpenAM Identity Web Services.
Method Test() As %Boolean
{
	Set req=##class(%Net.HttpRequest).%New()
	Set req.Server=..Server
	Set req.Port=..Port
	Set req.SSLConfiguration=..SSLConfiguration
	Set $zt="Fail"
	Do req.Get(..Path)
	If req.HttpResponse.StatusCode=200 Quit 1
Fail
	Set $zt=""
	Quit 0
}

/// OpenAMIdentityService exists.<br>
/// This method checks for the existence of a OpenAMIdentityService in the security database.<br>
/// Parameters:<br>
/// Name - Name of the OpenAMIdentityService to check existence of<br>
/// Return values:<br>
/// If Value of the method = 0 (OpenAMIdentityService does not exist, or some error occured)<br>
/// OpenAMIdentityService = Null<br>
/// Status = OpenAMIdentityService "x" does not exist, or other error message<br><br>
/// If Value of the method = 1 (OpenAMIdentityService exists)<br>
/// OpenAMIdentityService = Object handle to OpenAMIdentityService<br>
/// Status = $$$OK<br>
ClassMethod Exists(Name As %String, ByRef OpenAMIdentityService As %ObjectHandle, ByRef Status As %Status) As %Boolean
{
 s $zt="Error"
 k OpenAMIdentityService
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 s OpenAMIdentityService=..%OpenId(Name,,.Status)
 ;s OpenAMIdentityService=..%OpenId($zcvt(Name,"L"),,.Status)
 i $$$ISOK(Status) q 1
 i $p($SYSTEM.Status.GetErrorCodes(Status),",")=$$$ERRORCODE($$$LoadObjectNotFound) s Status=$$$ERROR($$$ProviderDoesNotExist,Name)
 q 0
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 q 0
}

/// This method exports OpenAMIdentityService records to a file in xml format.<br>
/// Parameters:<br>
/// Filename -  Output file name<br>
/// NumExported (byref) -  Returns number of records exported.<br>
/// OpenAMIdentityServices - Comma separated list of OpenAMIdentityServices to export, "*" = All<br>
ClassMethod Export(FileName As %String = "OpenAMIdentityServicesExport.xml", ByRef NumExported As %Integer, OpenAMIdentityServices As %String = "*") As %Status
{
 s $zt="Error"
 s NumExported=0
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 #; Create a list query to get all the OpenAMIdentityService objects.
 s Rset=##class(%ResultSet).%New("%SYS.OpenAM.IdentityServices:List")
 i '$IsObject(Rset) q %objlasterror
 s Rset.RuntimeMode=1
 #; Create and initialize a %XML.Writer object
 Set writer=##class(%XML.Writer).%New()
 s sc=writer.OutputToFile(FileName)
 i $$$ISERR(sc) goto Cleanup
 s writer.Charset="UTF-8"
 s writer.Indent=1
 s sc=writer.RootElement("OpenAMIdentityServicesExport")
 i $$$ISERR(sc) goto Cleanup
 d Rset.Execute()
 ;d Rset.Execute(OpenAMIdentityServices)
 While Rset.Next() {
	i '..Exists(Rset.Data("Name"),.oref,.sc) goto Cleanup
	#;Perform the export using the object Id.
    set sc=writer.Object(oref)
    If $$$ISERR(sc) goto Cleanup
	s NumExported=NumExported+1
 }
 s sc=writer.EndRootElement()
 i $$$ISERR(sc) goto Cleanup
 s sc=writer.EndDocument() k writer
 s String=$$$FormatMsg($$$OpenAMIdentityServicesMsg,"ExportNum",NumExported,FileName)
 Do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameOpenAMIdentityServicesChange,String,$$$GetMsg($$$OpenAMIdentityServicesMsg,"Export"))
Cleanup
 i $d(writer) d writer.EndDocument()
 i $d(sc),'$$$ISOK(sc) q sc
 q $$$OK
Error s $zt=""
 i $d(writer) d writer.EndDocument()
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Get a OpenAMIdentityService's properties.<br>
/// Gets a OpenAMIdentityServices's properties from the security database.<br>
/// Parameters:<br>
/// OpenAMIdentityService - Object handle to a OpenAMIdentityServices record<br>
/// Return values:<br>
/// Properties - See the Get method for more information on properties returned
ClassMethod GetProperties(OpenAMIdentityService As %ObjectHandle, ByRef Properties As %String) As %Status
{
 s $zt="Error"
 k Properties
 s Properties("Server")=OpenAMIdentityService.Server
 s Properties("Port")=OpenAMIdentityService.Port
 s Properties("Path")=OpenAMIdentityService.Path
 s Properties("SSLConfiguration")=OpenAMIdentityService.SSLConfiguration
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Import OpenAMIdentityService records from an xml file.<br>
/// Parameters:<br>
/// FileName - Filename to import OpenAMIdentityService records from<br>
/// NumImported (byref) - Returns number of records imported<br>
/// Flags - Control import<br>
/// Bit 0 - Do not import records, just return count<br>
/// Note: On failure, no records will be imported<br>
ClassMethod Import(FileName As %String = "OpenAMIdentityServicesExport.xml", ByRef NumImported As %Integer, Flags As %Integer = 0) As %Status
{
 s $zt="Error"
 s NumImported=0
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 #; Create and initialize an %XML.Reader object
 i '$zb(Flags,1,1) {
 	TSTART
 	s TSTART=1
 }
 s reader=##class(%XML.Reader).%New()
#;If called from Security.System:ImportAll(), the filename will be in $list format
#;Piece 1 - Original file imported from, used in audit record
#;Piece 2 - Converted temp file imported from
#;$lb("c:\iris\mgr\export.xml","c:\iris\mgr\temp\udhiue")
 i $listvalid(FileName) {
	 s File=$li(FileName,2)
	 s FileName=$li(FileName,1)
 } else {
	 s File=FileName
 }
 s sc=reader.OpenFile(File)
 i $$$ISERR(sc) goto Rollback
 Do reader.Correlate("IdentityServices","%SYS.OpenAM.IdentityServices")
 While reader.Next(.Object,.sc) {
	i $$$ISERR(sc) q 
#;OpenAIM without version numbers are compatible from several versions ago, so set to version 1.	
    i Object.Version="" s Object.Version=1
    i Object.Version>..#VERSION {
		s sc=$$$ERROR($$$IncompatibleImportVersion1,"%SYS.OpenAM.IdentityServices",Object.Version,..#VERSION)
		q  
    }
#;Add code here to perform conversion if versions don't match
    i Object.Version'=..#VERSION {
    }
	i $zb(Flags,1,1) {
		s NumImported=NumImported+1
		Continue
	}
    s tf=..Exists(Object.Name,,.sc)
    i 'tf {
	    s sc=Object.%Save() 
	    i $$$ISERR(sc) q
    } else {
	   #; set up properties and call Modify to update existing resource
	   s sc=..GetProperties(Object,.Properties)
	   i $$$ISERR(sc) q
	   s sc=..Modify(Object.Name,.Properties)
       i $$$ISERR(sc) q
    }
    s NumImported=NumImported+1
 }
 i $$$ISERR(sc) goto Rollback
 i $d(TSTART) {
	TCOMMIT
	k TSTART
 }
 i '$zb(Flags,1,1) {
 	s String=$$$FormatMsg($$$OpenAMIdentityServicesMsg,"ImportNum",NumImported,FileName)
 	Do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameOpenAMIdentityServicesChange,String,$$$GetMsg($$$OpenAMIdentityServicesMsg,"Import"))
 }
 s sc=$$$OK
Exit
 q sc
Rollback
 i $d(TSTART) {
	TROLLBACK 1
	k TSTART
 }
 s NumImported=0
 g Exit
Error s $zt=""
 s sc=$$$ERROR($$$ObjectScriptError,$ze)
 g Rollback
}

/// Modify a OpenAMIdentityService.<br>
/// Modify an existing OpenAMIdentityService's properties in the security database.<br>
/// Parameters:<br>
/// Name - Name of the OpenAMIdentityService to modify<br>
/// Properties - Array of properties to modify.<br>
/// See the Get() method for a description of the Properties parameter.<br>
/// If a specific property is not passed in the properties array, 
/// the value is not modified.<br>
ClassMethod Modify(Name As %String, ByRef Properties As %String) As %Status
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 i '..Exists(Name,.OpenAMIdentityService,.Status) q Status
 s Status=$$$OK
 i $d(Properties("Server")),(Properties("Server")'=OpenAMIdentityService.Server) s OpenAMIdentityService.Server=Properties("Server")
 i $d(Properties("Port")),(Properties("Port")'=OpenAMIdentityService.Port) s OpenAMIdentityService.Port=Properties("Port")
 i $d(Properties("Path")),(Properties("Path")'=OpenAMIdentityService.Path) s OpenAMIdentityService.Path=Properties("Path")
 i $d(Properties("SSLConfiguration")),(Properties("SSLConfiguration")'=OpenAMIdentityService.SSLConfiguration) s OpenAMIdentityService.SSLConfiguration=Properties("SSLConfiguration")
 s Status=OpenAMIdentityService.%Save()
 q Status
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Upload all OpenAMIdentityServices from Enterprise Management System to requesting client.
ClassMethod Upload(GUID As %String, ByRef Data As %List) As %Status [ Internal ]
{
	s $zt="error"
	;i $D(GUID) s Status=##Class(EMS.Groups).ActivateByGUID(GUID) if '$$$ISOK(Status) q Status
	s row=0,ref=$o($$$SecurityGlobal("OpenAMIdentityServicesD",""),1,data)
	while ref'="" {
		s row=row+1,$List(Data,row)=$lb(ref,data)
		s ref=$o($$$SecurityGlobal("OpenAMIdentityServicesD",ref),1,data)
	}
	;i $D(GUID) d ##Class(EMS.Groups).Inactivate()
	Quit $$$OK
error	;
	s $zt=""
	k Data
	;i $D(GUID) d ##Class(EMS.Groups).Inactivate()
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

Query List() As %SQLQuery
{
SELECT Name,Server,Port,Path,SSLConfiguration FROM IdentityServices
 ORDER BY Name
}

Storage Default
{
<Data name="IdentityServicesDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Server</Value>
</Value>
<Value name="3">
<Value>Port</Value>
</Value>
<Value name="4">
<Value>Path</Value>
</Value>
<Value name="5">
<Value>SSLConfiguration</Value>
</Value>
<Value name="6">
<Value>Version</Value>
</Value>
</Data>
<DataLocation>^|$$$SecurityMapOpenAMIdentityServices|SYS("Security","OpenAMIdentityServicesD")</DataLocation>
<DefaultData>ServicesDefaultData</DefaultData>
<ExtentSize>100</ExtentSize>
<IdLocation>^|$$$SecurityMapOpenAMIdentityServices|SYS("Security","OpenAMIdentityServicesD")</IdLocation>
<IndexLocation>^|$$$SecurityMapOpenAMIdentityServices|SYS("Security","OpenAMIdentityServicesI")</IndexLocation>
<StreamLocation>^|$$$SecurityMapOpenAMIdentityServices|SYS("Security","OpenAMIdentityServicesS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
