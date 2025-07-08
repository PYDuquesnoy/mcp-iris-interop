/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Perform an Integrity Check for all databases. The task will create an output log file, 
/// parse the log for errors and report failures in messages.log (which will send email if it's configured).
Class %SYS.Task.IntegrityCheck Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "IntegrityCheck";

/// The directory where the Integrity Check logs will be kept.
/// Note that the logs here can be automatically purged using the KeepDays property
Property Directory As %String [ InitialExpression = {$zu(12)} ];

/// The file name to be used for the log. Leaving this blank will cause the file name
/// to be automatically generated in the the format INTEGRIT-YYYYMMDD_sec.LOG. Files
/// which are generated in this format can be automatically purged using the KeepDays property.
Property Filename As %String;

/// Number of days to keep files before puring - 0 means never purge
Property KeepDays As %Integer [ InitialExpression = 0 ];

ClassMethod DirectoryIsValid(Directory As %String) As %Status [ Internal ]
{
	If '##class(%Library.File).DirectoryExists(Directory) Quit $$$ERROR($$$GeneralError,"Directory does not exist")
	Quit $$$OK
}

/// Execute $$CheckList^Integrity() for all databases. Create an output log file, check for errors
/// and report failure in messages.log. Purge old INTEGRIT-*.LOG files if KeepDays is set.
Method OnTask() As %Status
{
#;We must run in %SYS
	Set $namespace="%SYS"
	Set rc=$$CheckList^Integrity()
	
	Set file=..Filename
	If file="" Set h=$h,file="INTEGRIT-"_$zd(+h,8)_"_"_$p(h,",",2)_".LOG"
	Set file=##class(%Library.File).NormalizeDirectory(..Directory)_file
	
	Open file:"WNSE":2 i '$t q $$$ERROR($$$FileCanNotOpen,file)
	Use file
	Write $$$TextHTML("File Name: "),$ZCVT(file,"O","HTML"),!!
	Write $$$TextHTML("Database Integrity Check - Report Created ")_$zdt($h),!
	Write $$$TextHTML("System"),": ",$zu(110)," ",$$$TextHTML("Configuration"),": ",$P($zu(86),"*",2),!
	Write $ZV,!!
	Set errors = $$RetryErrors^Integrity(,1)
	If errors="0,0" {
		Write $$$TextHTML("No Errors were found."),!
	} else {
		Write $$$TextHTML("************** Details Of Errors Found **************"),!
		Do Display^Integrity(,1,0)
		s sev=##class(%Monitor.Manager).AlertLevel()
		d ##class(%SYS.System).WriteToConsoleLog("Errors found, See output in "_file,1,sev)
	}
	Write !!,$$$TextHTML("Full Listing of Databases Checked"),!!
	
	Do Display^Integrity(,0,1)
	Close file
	Kill ^IRIS.TempIntegrity(+$j),^IRIS.TempIntegrityOutput(+$j)
#;purge old files if KeepDays is set, only purge files in the format INTEGRIT-*.LOG
	i ..KeepDays>0,..Directory]"" {
		s Files="INTEGRIT-*.LOG",today=+$h
 		s rs=##class(%ResultSet).%New("%File:FileSet")
 		d rs.Execute(..Directory,Files)
 		while rs.%Next() {
  			s myfile=$g(rs.Data("Name"))
  			s filedate=$p($p(myfile,"INTEGRIT-",2),"_",1)
  			s intdate=$zdh(filedate,8) ;got the date in internal format
  			if today-intdate>..KeepDays d ##class(%File).Delete(myfile)
 		}
 	}
	Quit $$$OK
}

}
