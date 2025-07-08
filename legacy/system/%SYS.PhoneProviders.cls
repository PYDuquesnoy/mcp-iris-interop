/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

Class %SYS.PhoneProviders Extends (%Persistent, %XML.Adaptor, %SYSTEM.Help) [ System = 4 ]
{

Index NameIndex On Name [ IdKey ];

Parameter EMSSERVICE [ Internal ] = "Users";

Parameter VERSION [ Internal ] = 1;

Parameter SOURCECONTROL [ Internal ] = {"Revision path: $Id: //iris/2025.1.0/databases/sys/cls/SYS/PhoneProviders.xml#1 $"_$c(13,10)_"Last Change:   $DateTime: 2025/01/31 13:48:15 $"_$c(13,10)_"Changelist #:  $Change: 7556155 $"};

/// Business name
Property Name As %String [ Required ];

/// DNS name of SMTP-to-SMS gateway
Property SMSGateway As %String [ Required ];

/// Version number of the record. <br>
/// Used for Export/Import.<br>
Property Version As %Decimal(SCALE = 1) [ Internal ];

/// PhoneProvider exists.<br>
/// This method checks for the existence of a PhoneProvider in the security database.<br>
/// Parameters:<br>
/// Name - Name of the PhoneProvider to check existence of<br>
/// Return values:<br>
/// If Value of the method = 0 (PhoneProvider does not exist, or some error occured)<br>
/// PhoneProvider = Null<br>
/// Status = PhoneProvider "x" does not exist, or other error message<br><br>
/// If Value of the method = 1 (PhoneProvider exists)<br>
/// PhoneProvider = Object handle to PhoneProvider<br>
/// Status = $$$OK<br>
ClassMethod Exists(Name As %String, ByRef PhoneProvider As %ObjectHandle, ByRef Status As %Status) As %Boolean
{
 s $zt="Error"
 k PhoneProvider
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 s PhoneProvider=..%OpenId(Name,,.Status)
 ;s PhoneProvider=..%OpenId($zcvt(Name,"L"),,.Status)
 i $$$ISOK(Status) q 1
 i $p($SYSTEM.Status.GetErrorCodes(Status),",")=$$$ERRORCODE($$$LoadObjectNotFound) s Status=$$$ERROR($$$ProviderDoesNotExist,Name)
 q 0
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 q 0
}

/// This method exports PhoneProvider records to a file in xml format.<br>
/// Parameters:<br>
/// Filename -  Output file name<br>
/// NumExported (byref) -  Returns number of records exported.<br>
/// PhoneProviders - Comma separated list of PhoneProviders to export, "*" = All<br>
ClassMethod Export(FileName As %String = "PhoneProvidersExport.xml", ByRef NumExported As %Integer, PhoneProviders As %String = "*") As %Status
{
 s $zt="Error"
 s NumExported=0
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 #; Create a list query to get all the PhoneProvider objects.
 s Rset=##class(%ResultSet).%New("%SYS.PhoneProviders:List")
 i '$IsObject(Rset) q %objlasterror
 s Rset.RuntimeMode=1
 #; Create and initialize a %XML.Writer object
 Set writer=##class(%XML.Writer).%New()
 s sc=writer.OutputToFile(FileName)
 i $$$ISERR(sc) goto Cleanup
 s writer.Charset="UTF-8"
 s writer.Indent=1
 s sc=writer.RootElement("PhoneProvidersExport")
 i $$$ISERR(sc) goto Cleanup
 d Rset.Execute()
 ;d Rset.Execute(PhoneProviders)
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
 s String=$$$FormatMsg($$$PhoneProvidersMsg,"ExportNum",NumExported,FileName)
 Do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NamePhoneProvidersChange,String,$$$GetMsg($$$PhoneProvidersMsg,"Export"))
Cleanup
 i $d(writer) d writer.EndDocument()
 i $d(sc),'$$$ISOK(sc) q sc
 q $$$OK
Error s $zt=""
 i $d(writer) d writer.EndDocument()
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod Get(PhoneProvider As %String, ByRef Properties As %String) As %Status
{
 s $zt="Error"
#;We allow any user to access this, so no check for Admin Secure
 k Properties
 i '..Exists(PhoneProvider,.Provider,.Status) q Status
 s Status=..GetProperties(Provider,.Properties)
 q Status
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Get a PhoneProvider's properties.<br>
/// Gets a PhoneProviders's properties from the security database.<br>
/// Parameters:<br>
/// PhoneProvider - Object handle to a PhoneProviders record<br>
/// Return values:<br>
/// Properties - See the Get method for more information on properties returned
ClassMethod GetProperties(PhoneProvider As %ObjectHandle, ByRef Properties As %String) As %Status
{
 s $zt="Error"
 k Properties
 s Properties("SMSGateway")=PhoneProvider.SMSGateway
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Import PhoneProvider records from an xml file.<br>
/// Parameters:<br>
/// FileName - Filename to import PhoneProvider records from<br>
/// NumImported (byref) - Returns number of records imported<br>
/// Flags - Control import<br>
/// Bit 0 - Do not import records, just return count<br>
/// Note: On failure, no records will be imported<br>
ClassMethod Import(FileName As %String = "PhoneProvidersExport.xml", ByRef NumImported As %Integer, Flags As %Integer = 0) As %Status
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
 Do reader.Correlate("PhoneProviders","%SYS.PhoneProviders")
 While reader.Next(.Object,.sc) {
	i $$$ISERR(sc) q 
#;Phone providers without version numbers are compatible from several versions ago, so set to version 1.	
    i Object.Version="" s Object.Version=1
    i Object.Version>..#VERSION {
		s sc=$$$ERROR($$$IncompatibleImportVersion1,"%SYS.PhoneProviders",Object.Version,..#VERSION)
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
 	s String=$$$FormatMsg($$$PhoneProvidersMsg,"ImportNum",NumImported,FileName)
 	Do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NamePhoneProvidersChange,String,$$$GetMsg($$$PhoneProvidersMsg,"Import"))
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

ClassMethod Initialize() As %Status [ Internal, ProcedureBlock = 0 ]
{
 Set $zt="InitializeError"
 New
 If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 Set Status=$$$OK
 For i=1:1 {
	Set Line=$Text(INITPROVIDERS+i)
	Set Name=$ZSTRIP($TR($Piece(Line,";",3),"""",""),"<>W")
	If ..%ExistsId(Name) Continue
	If Name="EndList" Set Status=$$$OK Quit
	Set pro=##class(%SYS.PhoneProviders).%New()
	Set pro.Name=Name
	Set pro.SMSGateway=$ZSTRIP($TR($Piece(Line,";",4),"""",""),"<>W")
	Set Status=pro.%Save()
	If '$$$ISOK(Status) Quit
 }
 Quit Status

InitializeError s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)

INITPROVIDERS ;Name                 SMSGateway
 ##lit(;;) "Alltel"        ##lit(;) "message.alltel.com"
 ##lit(;;) "AT&T Wireless" ##lit(;) "txt.att.net"
 ##lit(;;) "Cellular One"  ##lit(;) "mobile.celloneusa.com"
 ##lit(;;) "Nextel"        ##lit(;) "messaging.nextel.com"
 ##lit(;;) "Sprint PCS"    ##lit(;) "messaging.sprintpcs.com"
 ##lit(;;) "T-Mobile"      ##lit(;) "tmomail.net"
 ##lit(;;) "Verizon"       ##lit(;) "vtext.com"
 ##lit(;;) EndList
}

/// The following methods added to make the UI API consistent between %SYS and EMS
ClassMethod Create(Name As %String, ByRef Properties As %String) As %Status
{
 s $zt="ERROR"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 i ..Exists(Name,.PhoneProvider,.Status) q $$$ERROR($$$ElementAlreadyExists,"PhoneProvider",Name)
 s PhoneProvider=..%New()
 i '$IsObject(PhoneProvider) Quit %objlasterror
 s PhoneProvider.Name=Name
 If $D(Properties("SMSGateway")) s PhoneProvider.SMSGateway=Properties("SMSGateway")
 s Status=PhoneProvider.%Save()
 q Status
ERROR s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod Delete(Name As %String) As %Status
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 i '..Exists(Name,.PhoneProvider,.Status) q Status
 s Status=PhoneProvider.%Delete(PhoneProvider.%Oid())
 q Status
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Modify a PhoneProvider.<br>
/// Modify an existing PhoneProvider's properties in the security database.<br>
/// Parameters:<br>
/// Name - Name of the PhoneProvider to modify<br>
/// Properties - Array of properties to modify.<br>
/// See the Get() method for a description of the Properties parameter.<br>
/// If a specific property is not passed in the properties array, 
/// the value is not modified.<br>
ClassMethod Modify(Name As %String, ByRef Properties As %String) As %Status
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 i '..Exists(Name,.PhoneProvider,.Status) q Status
 s Status=$$$OK
 i $d(Properties("SMSGateway")),(Properties("SMSGateway")'=PhoneProvider.SMSGateway) s PhoneProvider.SMSGateway=Properties("SMSGateway")
 s Status=PhoneProvider.%Save()
 q Status
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod StartEMS() As %Status [ Internal ]
{
	s $zt="Error"
	q $$$OK
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
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
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Caller of %Save must have %Admin_Secure:U. 
Method %OnBeforeSave(insert As %Boolean) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	new $NAMESPACE
	set $NAMESPACE="%SYS"
 	;i ##class(EMS.Instance).Restricted($this) Q $$$ERROR($$$EMSRestrictedOnClient,$CLASSNAME())

	set String="", CRLF=$c(13,10)
	set CurrentValues=$$$GetMsg($$$AuditMsg,"CurrentValues")_CRLF, padlen=30, Pad=$j("",padlen) // padlen may need to be increased if the localizations in SystemMessages end up being long.
	if (insert) {
		s i%Version=..#VERSION
		set id=i%Name // Must use Name since %Id() isn't valid during an insert
		set Msg=$$$FormatMsg($$$AuditMsg,"CreateHeader",$$$GetMsg($$$PhoneProvidersMsg,"PhoneProviders"), id)
			// Leave "String" empty, we give no details on Create actions
	} else {
		set id=..%Id()
		set Msg=$$$FormatMsg($$$AuditMsg,"ModifyHeader",$$$GetMsg($$$PhoneProvidersMsg,"PhoneProviders"), id)
			set Changes=""
	}

	for Property="Name", "SMSGateway" {
		set newValue=$property($this,Property)
		set CurrentValues=CurrentValues_$e($$$GetMsg($$$PhoneProvidersMsg, Property_"C")_Pad,1,padlen)_newValue_CRLF

		if ('insert&&$method($this, Property_"IsModified")) {
			// Construct changes block
			set oldValue=$method($this, Property_"GetStored", id)
			set Changes=Changes_$$$FormatMsg($$$AuditMsg,"Modified",Property)_CRLF
			set Changes=Changes_$$$FormatMsg($$$AuditMsg,"NewValue",newValue)_CRLF
			set Changes=Changes_$$$FormatMsg($$$AuditMsg,"OldValue",oldValue)_CRLF
		}
	}

	if (insert) {
			set String=CurrentValues
	} else {
			set String=Changes_CRLF_"--------------------------------------------------"_CRLF_CurrentValues
	}
	do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NamePhoneProvidersChange,String,Msg)
	Quit $$$OK
}

/// Caller of %Delete must have %Admin_Secure:U. 
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	new $NAMESPACE
	set $NAMESPACE="%SYS"
 	;i ##class(EMS.Instance).Restricted($this) Q $$$ERROR($$$EMSRestrictedOnClient,$CLASSNAME())
	set PhoneProvider=..%Open(oid,,.Status)
	if '$$$ISOK(Status) q Status

	new SQLCODE
	&sql(SELECT COUNT(*) INTO :count FROM Security.Users WHERE PhoneProvider = :PhoneProvider.Name)
	if (SQLCODE'=0) {
		return $$$ERROR($$$CannotVerifyPhoneProviderUnused, SQLCODE)
	}
	if (count'=0) {
		return $$$ERROR($$$PhoneProviderInUse, PhoneProvider.Name)
	}

	set Msg=$$$FormatMsg($$$AuditMsg,"DeleteHeader",$$$GetMsg($$$PhoneProvidersMsg,"PhoneProviders"), PhoneProvider.Name)
	do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NamePhoneProvidersChange,"",Msg)
	Quit $$$OK
}

/// Caller of %DeleteId must have %Admin_Secure:U. 
ClassMethod %OnDeleteId(oid As %ObjectIdentity) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	Quit $$$OK
}

Query List() As %SQLQuery(ROWSPEC = "Name:%String,SMSGateway:%String")
{
SELECT Name,SMSGateway FROM PhoneProviders
 ORDER BY Name
}

Storage Default
{
<Data name="PhoneProvidersDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SMSGateway</Value>
</Value>
<Value name="3">
<Value>Version</Value>
</Value>
</Data>
<DataLocation>^|$$$SecurityMapPhoneProviders|SYS("Security","PhoneProvidersD")</DataLocation>
<DefaultData>ServicesDefaultData</DefaultData>
<ExtentSize>100</ExtentSize>
<IdLocation>^|$$$SecurityMapPhoneProviders|SYS("Security","PhoneProvidersD")</IdLocation>
<IndexLocation>^|$$$SecurityMapPhoneProviders|SYS("Security","PhoneProvidersI")</IndexLocation>
<StreamLocation>^|$$$SecurityMapPhoneProviders|SYS("Security","PhoneProvidersS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
