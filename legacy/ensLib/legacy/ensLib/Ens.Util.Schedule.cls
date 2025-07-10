/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// A persistent named schedule spec string
Class Ens.Util.Schedule Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLNAME = "schedule";

Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

Parameter DOMAIN = "Ensemble";

Property Name As %String;

Property Description As %String(MAXLEN = 256);

Property ScheduleSpec As %String(MAXLEN = "");

Property %ScheduleSpecModified As %Boolean [ InitialExpression = 0, Private, Transient ];

Property %DeployablePreModified As %Boolean [ InitialExpression = 0, Private, Transient ];

Index Name On Name [ IdKey ];

/// Indicates whether this system default setting can be exported for deployment.
Property Deployable As %Boolean [ InitialExpression = 0 ];

ClassMethod Evaluate(pScheduleSpec As %String, pODBCDateTime As %String = "") As %String
{
	Set:pODBCDateTime'["T" pODBCDateTime=$TR(pODBCDateTime," ","T")
	Set:(pODBCDateTime'["T")||($E(pODBCDateTime)="T")&&(pODBCDateTime[":") pODBCDateTime=$P($ZDT($H,3)," ")_$S(pODBCDateTime'["T":"T",1:"")_pODBCDateTime
	If "@"=$E(pScheduleSpec) {
		Set tSpec="", tName=$E(pScheduleSpec,2,*)
		&sql(Select ScheduleSpec Into :tSpec From Ens_Util.Schedule Where Name=:tName)
		If SQLCODE=100 {
			Set tSC=##class(Ens.Rule.RuleSet).EvaluateRulesEx(tName,0,pODBCDateTime,"Schedule.Evaluate",.tRetVal,.tReason)
			Quit:$$$ISERR(tSC) ""
			Quit tRetVal
		}
		Quit:SQLCODE ""
		#; we looked it up successfully
		Set pScheduleSpec=tSpec
	}
	Quit:""=pScheduleSpec 1
	Set tSC=##class(Ens.ScheduleHandler).ParseScheduleSpec(pScheduleSpec, .tCurrentState, .tNextEventDateTime, .tNextEventAction, pODBCDateTime)
	Quit:$$$ISERR(tSC) 0
	Quit (tCurrentState="START")
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called before 
/// any data is written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	If ('insert) && (..ScheduleSpecGetStored(..%Id()) '= ..ScheduleSpec) {
		Set ..%ScheduleSpecModified = 1
	}
	If ('insert) {Set ..%DeployablePreModified = ..DeployableGetStored(..%Id())}
	Quit $$$OK
}

/// If production is running apply any appropriate new schedules
/// Update the timestamp for the settings whenever an entry is added or updated that is deployable.
Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK, tSC1 = $$$OK
	If ('insert) && ..%ScheduleSpecModified && ##class(Ens.Director).IsProductionRunning(){
		Set tUpdateSchedule = 0
		Set tConfigName = ""
		For {
			Set tConfigName = $order($$$ConfigRoot(tConfigName))
			Quit:(tConfigName = "")
			If $zconvert($get($$$ConfigSchedule(tConfigName)),"U") = ("@"_$zconvert(..Name,"U")) {
				Set tUpdateSchedule = 1
				Quit
			}
		}
		If tUpdateSchedule {
			#; Job off since any open transactions will be closed and event warning logged.
			Job ##class(Ens.ScheduleService).CallScheduleService()::5
			If '$Test {Set tSC = $$$ERROR($$$EnsErrGeneral,"Timed out trying to job off process to notify Scheduler")}
		}
	}
	If (..Deployable) {
		Do ..updateTimestamp(1)
	} ElseIf ('insert&&'..Deployable&&..%DeployablePreModified) {
		Do ..updateTimestamp(1)
		Try {
			&SQL(Select TOP 1 ID INTO :tFirstDeployable FROM Ens_Util.Schedule WHERE Deployable=1)
			If (SQLCODE '= 0),(SQLCODE '= 100) {
				Set tSC1 = $$$ERROR($$$EnsErrGeneral,$SYSTEM.SQL.SQLCODE(SQLCODE))
			} ElseIf (SQLCODE=100) {
				Kill ^Ens.Configuration("esd",$Classname(),"time")
			}
		} Catch e {Set tSC1=e.AsStatus()}
	
	}
	Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	Quit tSC
}

/// Delete the deployable contents of the Schedule specifications table which are projected as one Studio document.<br/>
/// If <var>pIDsToKeep</var> array is passed in where the subscript is the settings id then those schedules will not be deleted.<br/>
ClassMethod %ClearStudioDocuments(ByRef pIDsToKeep As %String = "")
{
	Set tSC=$$$OK
	Try {
		&SQL(DECLARE C1 CURSOR FOR
	 		SELECT ID INTO :tID FROM Ens_Util.Schedule 
	 		WHERE Deployable=1
	 	)
	 	&SQL(OPEN C1)
		&SQL(FETCH C1)
	 	While (SQLCODE=0) { 
	 		If '$D(pIDsToKeep(tID)) {Set tSC = ##class(Ens.Util.Schedule).%DeleteId(tID) Quit:$$$ISERR(tSC)}
			&SQL(FETCH C1)
		}
		Set:(tSC&&(SQLCODE'=100)) tSC = $$$ERROR($$$EnsErrGeneral,$SYSTEM.SQL.SQLCODE(SQLCODE))
		&SQL(CLOSE C1)
	} Catch e {Set tSC = e.AsStatus()}
    Quit tSC
}

/// Import Schedule Specification data from the xml file <var>pFileName</var>.<br/>
/// Lookup data is in the form:
/// <example lang="xml">
/// <scheduleSpec>
/// <schedule>
/// <Name>InterfaceSixtyFour</Name>
/// <Description>This controls the service </Description>
/// <ScheduleSpec>START:WEEK-*-01T07:00:00,STOP:WEEK-*-05T17:00:00</ScheduleSpec>
/// <Deployable>true</Deployable>
/// </schedule>
/// </scheduleSpec>
/// </example>
ClassMethod %Import(pFileName As %String = "", Output pCount As %Integer, ByRef pIDsImported As %String = "") As %Status
{
	Set tSC = $$$OK
	Set pCount = 0
	Set reader = ##class(%XML.Reader).%New()
	If $IsObject(pFileName) {
		Set tSC = reader.OpenStream(pFileName) Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tSC = reader.OpenFile(pFileName) Quit:$$$ISERR(tSC) tSC
	}
	Do reader.Correlate("schedule",$classname())
	While (reader.Next(.schedule,.tSC)) {
		Quit:$$$ISERR(tSC)
		If ..%ExistsId(schedule.Name) {
			// modify
			Set tExistingschedule = ..%OpenId(schedule.Name)
			Set tDifferent = 0
			Set tDifferent = ((tExistingschedule.Deployable '= schedule.Deployable)||(tExistingschedule.Description '= schedule.Description)||(tExistingschedule.ScheduleSpec '= schedule.ScheduleSpec))
			If tDifferent {
				Set tExistingschedule.Deployable = schedule.Deployable
				Set tExistingschedule.Description = schedule.Description
				Set tExistingschedule.ScheduleSpec = schedule.ScheduleSpec
				Set tSC = tExistingschedule.%Save()
			}
			#; Remember ID of existing whether changes or not
			Set tID = tExistingschedule.%Id()
		} Else {
			Set tSC = schedule.%Save()
			Set tID = schedule.%Id()
		}
		Quit:$$$ISERR(tSC)
		Set pCount = pCount + 1
		#; Record IDs imported whether new or pre-existing
		Set pIDsImported(tID)=""
	}
	Quit tSC
}

/// Import method for rows projected in studio document and then remove those that weren't imported after.
ClassMethod %ImportStudioDocuments(pStream As %String = "") As %Status
{
	Set tSC = ..%Import(pStream,.tCount,.tIDsImported)
	Quit:$$$ISERR(tSC) tSC
	Set:(tCount>0) tSC = ..%ClearStudioDocuments(.tIDsImported)
	Quit tSC
}

/// Export Schedule Specifications to file <var>pFileName</var>.
/// If <var>pDeployable</var> is not defined, then export both Deployable and non Deployable Schedule settings. This is the default<br/>
/// If <var>pDeployable</var> is set to True, then only export Schedule settings that are marked as Deployable. <br/>
/// If <var>pDeployable</var> is set to False, then only export Schedule settings that are marked as not Deployable. <br/>
ClassMethod %Export(pFileName As %String = "", pDeployable As %Boolean = "") As %Status
{
	Set tSC = $$$OK
	Set io = $IO
	Set tHaveOne=0
	Try {
		&SQL(DECLARE C2 CURSOR FOR
		 		SELECT ID INTO :tID FROM Ens_Util.Schedule 
		 		WHERE ((:pDeployable IS NOT NULL AND DEPLOYABLE = :pDeployable) OR (:pDeployable IS NULL))
		 	)
		&SQL(OPEN C2)
		&SQL(FETCH C2)
		While (SQLCODE=0) { 
			If 'tHaveOne {
				If $IsObject(pFileName) {
					Set tStream=pFileName
				} ElseIf (pFileName '= "") {
					Set tStream=##class(%IO.FileStream).%New()
					Do tStream.Open(pFileName,"NEW",,"UTF-8",.tSC)
				} Else {
					Set tStream=##class(%IO.DeviceStream).AttachNew(,.tSC)
				}
				Quit:$$$ISERR(tSC)
				Do tStream.WriteLine("<?xml version=""1.0""?>")
				Do tStream.WriteLine("<scheduleSpec>")
				Set tHaveOne=1	
			}
			Set tSchedule = ..%OpenId(tID)
			If $IsObject(tSchedule) {
				Do tSchedule.XMLExportToStream(tStream)
				Do tStream.WriteLine("")
			}
			&SQL(FETCH C2)
		}
		Set:(SQLCODE'=100) tSC = $$$ERROR($$$EnsErrGeneral,$SYSTEM.SQL.SQLCODE(SQLCODE))
		&SQL(CLOSE C2)
		Do:tHaveOne tStream.WriteLine("</scheduleSpec>")
	} Catch e {Set tSC = e.AsStatus()}
	Quit tSC
}

/// Export Default Settings that are deployable to stream <var>pStream</var>.
ClassMethod %ExportStudioDocuments(pStream As %String = "") As %Status
{
	Quit ..%Export(pStream,1)
}

/// Update the timestamp whenever a deployable row is removed from a table.
ClassMethod %OnAfterDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		&SQL(Select TOP 1 ID INTO :tFirstDeployable FROM Ens_Util.Schedule WHERE Deployable=1)
		If (SQLCODE '= 0),(SQLCODE '= 100) {
			Set tSC = $$$ERROR($$$EnsErrGeneral,$SYSTEM.SQL.SQLCODE(SQLCODE))
		} Else {
			If ($G(tFirstDeployable)'="") {
				Do ..updateTimestamp(1)
			} Else {
				Kill ^Ens.Configuration("esd",$Classname(),"time")
			}
		}
	} Catch e {Set tSC=e.AsStatus()}
	Quit tSC
}

/// Helper method for updating the timestamp of a settings table.
ClassMethod updateTimestamp(pDeployable As %Boolean) [ Internal ]
{
	Set:($G(pDeployable)=1) ^Ens.Configuration("esd",$Classname(),"time")=$ZTS
}

/// Helper method for getting the timestamp of a settings table.
ClassMethod getTimestamp() As %TimeStamp [ Internal ]
{
	Quit $G(^Ens.Configuration("esd",$Classname(),"time"))
}

/// Update the timestamp for the settings whenever an entry is added or updated that is deployable.
Trigger OnModify [ Event = INSERT/UPDATE, Time = AFTER ]
{
	Do ..updateTimestamp({Deployable})
}

/// Update the timestamp whenever a deployable row is removed from a table. 
Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
	Try {
		&SQL(Select TOP 1 ID INTO :tFirstDeployable FROM Ens_Util.Schedule WHERE Deployable=1)
		If ((SQLCODE = 0) || (SQLCODE = 100)) {
			If ($G(tFirstDeployable)'="") {
				Do ..updateTimestamp({Deployable})
			} Else {
				Kill ^Ens.Configuration("esd",$Classname(),"time")
			}
		}
	} Catch e {}
}

Storage Default
{
<Data name="ScheduleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>ScheduleSpec</Value>
</Value>
<Value name="4">
<Value>Deployable</Value>
</Value>
</Data>
<DataLocation>^Ens.Util.ScheduleD</DataLocation>
<DefaultData>ScheduleDefaultData</DefaultData>
<IdLocation>^Ens.Util.ScheduleD</IdLocation>
<IndexLocation>^Ens.Util.ScheduleI</IndexLocation>
<StreamLocation>^Ens.Util.ScheduleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
