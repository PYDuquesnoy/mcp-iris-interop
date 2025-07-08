/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This task is schedule to run daily after the journal switch (by default At Midnight)
/// The default purge is 2 months (62 days) but can be changed by setting KeepDays to another
/// value in the System Managment Portal.
Class %SYS.Task.PurgeAudit Extends %SYS.Task.Definition [ System = 4 ]
{

Parameter TaskName = "PurgeAudit";

/// Default purge of 2 months
Property KeepDays As %Integer [ InitialExpression = 62 ];

/// Validate KeepDays value
ClassMethod KeepDaysIsValid(KeepDays As %Integer) As %Status
{
	If +KeepDays'=KeepDays || (KeepDays<0) Quit $$$ERROR($$$TASKAuditKeepDaysInvalid)
	Quit $$$OK
}

/// Default purge code 
Method OnTask() As %Status
{
#;We must run in %SYS
	d $zu(5,"%SYS")
	Set dttm=$h,dttm=+dttm-(..KeepDays)_","_$p(dttm,",",2)
	Quit ##class(%SYS.Audit).Delete("","",$zdatetime(dttm,3))
}

}
