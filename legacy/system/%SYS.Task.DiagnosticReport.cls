/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Task provided by the WRC to automate the collection of reports, and to automate them being sent to the WRC for achival and configuration history
Class %SYS.Task.DiagnosticReport Extends (%SYS.Task.Definition, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter TaskName = "DiagnosticReport";

Parameter XMLNAME = "ProfilerData";

/// if this field is filled, then the files are left in the local Archive  
Property ArchiveDirectory As %String(XMLPROJECTION = "NONE");

/// flag to indicate if this should be Advanced Report; default is to collect a Basic report
Property AdvancedReport As %Boolean [ InitialExpression = 0 ];

/// used to populate the "From:" field in the email generated to send the Diagnostic Report 
Property EmailCC As %String(XMLPROJECTION = "NONE");

/// used to populate the "From:" field in the email generated to send the Diagnostic Report 
Property EmailFrom As %String(XMLPROJECTION = "NONE") [ InitialExpression = "DefaultDiagnosticReport@InterSystems.com" ];

/// used to populate the "Reply-To:" field in the email generated to send the Diagnostic Report 
Property EmailReplyTo As %String(XMLPROJECTION = "NONE");

/// name of SMTP server to use for sending Diagnostic Report; if this is blank, the Diagnostic Report will not be sent to InterSystems
Property SMTPServer As %String(XMLPROJECTION = "NONE");

/// name of SMTP Authenticated User
Property SMTPUser As %String(XMLPROJECTION = "NONE");

/// password of SMTP Authenitcated User
Property SMTPPass As %SYS.Task.Password(XMLPROJECTION = "NONE");

/// port for SMTP server
Property SMTPPort As %String(XMLPROJECTION = "NONE") [ InitialExpression = 25 ];

/// ssl/tls configuration for SMTP server
Property SMTPSSLConfiguration As %String(XMLPROJECTION = "NONE");

/// When making an SSL/TLS connection, check that the server identity in the server certificate matches the name of the system we are connecting to.
Property SMTPSSLCheckServerIdentity As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = 1 ];

/// If true then the STARTTLS extension to SMTP (RFC 3207) should be used to authenticate 
/// to the SMTP server on the normal SMTP port.
Property SMTPUseSTARTTLS As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// flag to indicate if Diagnostic Report should be emailed to the WRC when collected and not associated with a WRC issue#
Property WRCHealthCheckEnabled As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// WRC Issue Number to be included in subject; NOTE: This is cleared after a Diagnostic Report is sent with this in the Subject line, and needs to be reinitilized through the System Management Portal
Property WRCIssueNumber As %Integer(XMLPROJECTION = "NONE");

/// if there are any Adhocs applies as changed files only, which didn't update the $ZV string, they should be listed here
Property zInfoAdhocNotListedInZV As %String(XMLNAME = "AdhocNotListedInZV");

/// manual field indicating the types of backups used on this InterSystems IRIS instance
Property zInfoBackupType As %String(XMLNAME = "BackupType");

/// manual field indicating the type and quantity of CPU(s) used on this system
Property zInfoCPUDetails As %String(XMLNAME = "CPUDetails");

/// manual field indicating the type of hardware that this system is running on
Property zInfoHardwareType As %String(MAXLEN = 500, XMLNAME = "HardwareType");

/// manual property indicates what the primary use is for this InterSystems IRIS instance: Development, Testing, QA or Production
Property zInfoPrimaryPurpose As %String(DISPLAYLIST = ",Development,Testing,Quality Assurance,Production,", VALUELIST = ",Dev,Test,QA,Prod,", XMLNAME = "PrimaryPurpose");

/// total physical memory on the machine
Property zInfoTotalPhysicalMemory As %String(XMLNAME = "TotalPhysicalMemory");

/// any special notes that the customer wants included with the Diagnostic Report 
Property zzInfoNotesFromCustomer As %String(MAXLEN = 500, XMLNAME = "NotesFromCustomer");

ClassMethod ArchiveDirectoryIsValid(ArchiveDirectory As %String) As %Status
{
	If (ArchiveDirectory'="") {
		If '##class(%Library.File).DirectoryExists(ArchiveDirectory) Quit $$$ERROR($$$GeneralError,"Directory does not exist")
	}
	Quit $$$OK
}

/// This method is responsible for executing the task
/// At the scheduled time, the Task Manager
/// - creates an instance of this object,
/// - Sets any property values using the stored "Settings" for the task,
/// - and invokes this method to execute the task.
Method OnTask() As %Status
{
	/*	
	/		12/22/06 	BFS - finalized all logic for inclusion in YSD1603, and added SMTP authentication
	*/
	If ..ArchiveDirectory'="" {
		Set Status = ##class(%SYS.Task.DiagnosticReport).ArchiveDirectoryIsValid(..ArchiveDirectory) 
		If 'Status Quit Status
	}
	If ..AdvancedReport {
		Set LogType = "Advanced"	
	}
	Else {
		Set LogType = "Basic"	
	}
	Set Status = $$INT^SystemCheck(LogType,..ArchiveDirectory)
	If +Status=0 Quit $$$ERROR($$$GeneralError,$P(Status,"|",2))
	Set FullFile = $P(Status,"|",2)
	// DiagnosticReport on VMS returns a trailing ";" in the filename which needs to be removed
	Set FullFile = $P(FullFile,";",1)

	Set FullFile1 = $P(Status,"|",3)
	// DiagnosticReport on VMS returns a trailing ";" in the filename which needs to be removed
	Set FullFile1 = $P(FullFile1,";",1)

	Set FullFile2 = $P(Status,"|",4)
	// DiagnosticReport on VMS returns a trailing ";" in the filename which needs to be removed
	Set FullFile2 = $P(FullFile2,";",1)
	
	// send if they have filled in the required information for Sending the report to the WRC
	If ..SMTPServer '= "",..EmailFrom '= ""  {
		Set s=##class(%Net.SMTP).%New()
		Set AuthUser=$ZSTRIP(..SMTPUser,"<>W")
		Set objAuth=""
		If AuthUser]"" {
			#; use default authentication list
			set objAuth=##class(%Net.Authenticator).%New() 
			Set objAuth.UserName=AuthUser
			Set objAuth.Password=..SMTPPass
		}
		If objAuth set s.authenticator=objAuth
		Set s.smtpserver=..SMTPServer
		Set s.port=..SMTPPort
        Set s.SSLConfiguration=..SMTPSSLConfiguration
        Set s.SSLCheckServerIdentity=+..SMTPSSLCheckServerIdentity
        Set s.UseSTARTTLS=+..SMTPUseSTARTTLS
		Set m = ##class(%Net.MailMessage).%New()
		Set m.From = ..EmailFrom
		Set m.ReplyTo = ..EmailReplyTo
		Set m.Subject = "Automated sending of "_FullFile
		Set m.Charset="iso-8859-1"
		If ..WRCIssueNumber '="" {
			Do m.To.Insert("support@intersystems.com")
			Set m.Subject = "Diagnostic Report for WRC"_..WRCIssueNumber
		}
		Do m.To.Insert("WRCHealthCheck@intersystems.com")
		If ..EmailCC'="" {
			for i=1:1:$L(..EmailCC,",") {
				Do m.Cc.Insert($P(..EmailCC,",",i))
			}	
		}
		Set Status = ..XMLExportToString(.body,,",indent")
		Set Status = m.TextData.Write(body)
		If $$$ISERR(Status) Quit $$$ERROR($$$GeneralError,Status)
		Set dir = ##class(%File).GetDirectory(FullFile)
		Set file = ##class(%File).GetFilename(FullFile)
		Set Status = m.AttachFile(dir,file,0,"iso-8859-1")
		If $$$ISERR(Status) Quit $$$ERROR($$$GeneralError,Status)
		if FullFile1'="" {
			Set dir = ##class(%File).GetDirectory(FullFile1)
			Set file = ##class(%File).GetFilename(FullFile1)
			Set Status = m.AttachFile(dir,file,0,"iso-8859-1")
			If $$$ISERR(Status) Quit $$$ERROR($$$GeneralError,Status)
		}
		if FullFile2'="" {
			Set dir = ##class(%File).GetDirectory(FullFile2)
			Set file = ##class(%File).GetFilename(FullFile2)
			Set Status = m.AttachFile(dir,file,0,"iso-8859-1")
			If $$$ISERR(Status) Quit $$$ERROR($$$GeneralError,Status)
		}
		Set Status = s.Send(m)
		If $$$ISERR(Status) Quit $$$ERROR($$$GeneralError,Status)
	}
	//if the customer hasn't defined an Archive Directory, but they are automatically creating reports on a schedule, then delete the file
	If ..ArchiveDirectory="",..WRCHealthCheckEnabled {
		Set Status = ##class(%File).Delete(FullFile)
	}
	//clear out the WRCIssue number so the customer will need to manually enter it again
	If ..WRCIssueNumber'="" {
		Set ..WRCIssueNumber = ""
		Set ..AdvancedReport = 0
	}
	Quit $$$OK
}

}
