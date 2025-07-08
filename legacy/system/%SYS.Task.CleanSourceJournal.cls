/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This task removes entries in the source journal global that are older
/// than the configured value.<br>
/// It is normally run nightly.
Class %SYS.Task.CleanSourceJournal Extends %SYS.Task.Definition
{

Parameter TaskName = "CleanSourceJournal";

/// Default purge of 2 months
Property KeepDays As %Integer [ InitialExpression = 60 ];

/// Validate KeepDays value
ClassMethod KeepDaysIsValid(KeepDays As %Integer) As %Status
{
	If +KeepDays'=KeepDays || (KeepDays<0) Quit $$$ERROR($$$TASKAuditKeepDaysInvalid)
	Quit $$$OK
}

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "settings" for the task, and then
/// invokes this method to execute the task.<br>
Method OnTask() As %Status
{
	#dim ex as %Exception.SystemException
	
#;Set bound for cleaning
	set bound=$H-..KeepDays
#;Code framework copied from ErrorPurge of Config.Startup
	set Rset=##class(%ResultSet).%New("Config.Databases:List")
	do Rset.Execute()
	set RetStatus=$$$OK
	while Rset.Next() {
#;Only local DBs
		if Rset.Data("Server")'="" continue
		set Dir=Rset.Data("Directory")
		set DBObj=##class(SYS.Database).%OpenId(Dir,,.Status) 
		if '$$$ISOK(Status) {
			set RetStatus=$$$ADDSC(RetStatus,Status)
			continue
		}
#;Only mounted ones
		if 'DBObj.Mounted continue
#;No Read only ones
		if DBObj.ReadOnly continue
		set nsp="^^"_Dir
		if $$GetGlobalPermission^%SYS.SECURITY(nsp,$Name($$$DocJrnGblName),,0)'["WRITE" continue
#;Only purge mirrored databases if primary
		if DBObj.Mirrored,'$System.Mirror.IsPrimary() continue
#;Clean old nodes
		try {
#;If the GetModified REST api has never been used, no use keeping the journal
			if '$D($$$DocJrnGbl(nsp)("hash")) {
				if $D($$$DocJrnGbl(nsp)("id")) {
					kill $$$DocJrnGbl(nsp)("id")
					set $$$DocJrnGbl(nsp)=0
				}
				continue
			}
#;If there are no dates, Atelier is not used so can kill everything
			set date=0,maxid=9999999
#;The 0 node may not have a date so initialize 'date' to the first real date
			set id=$O($$$DocJrnGbl(nsp)("id",0),1,date)
#;Kill all old id nodes
			set id=""
			for {
				set id=$O($$$DocJrnGbl(nsp)("id",id),1,date) quit:id=""
				if date>=bound quit
				kill ^(id)
				set maxid=id
			}
#;Kill hash nodes that refer to the killed ids
			set hash=""
			for {
				set hash=$O($$$DocJrnGbl(nsp)("hash",hash),1,id) quit:hash=""
				if id<=maxid kill ^(hash)
			}
		} catch ex {
			set RetStatus=$$$ADDSC(RetStatus,ex.AsStatus())
		}
	}
	quit RetStatus
}

}
