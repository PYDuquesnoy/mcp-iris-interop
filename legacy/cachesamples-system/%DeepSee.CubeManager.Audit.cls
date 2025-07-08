/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class retrieves and stores information about the use of the analytics items on the system.
Class %DeepSee.CubeManager.Audit Extends %Persistent [ System = 4 ]
{

/// UserID initiating the audit event
Property UserID As %String;

/// Time the audit event occurred
Property AuditTime As %String;

/// Dashboard that fired the AuditCode
Property Dashboard As %String;

/// This Method does the work of recording audit information collected in the context
/// of ^DeepSee.AuditCode. See the documentation for the use cases of this global.
ClassMethod AuditCode()
{
		set tEvent = ##class(%DeepSee.CubeManager.Audit).%New()
		set tEvent.UserID = $USERNAME
		set tEvent.AuditTime = $h
		set tEvent.Dashboard = %dsDashboard
		set tSC = tEvent.%Save()
		
		/*
		set file = "c:\temp\dump.log"
		o file:"WNS"
		u file
		w
		zw %application
		zw %page
		zw %request
		zw %response
		zw %session
		c file
		*/
}

Storage Default
{
<Data name="AuditDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>UserID</Value>
</Value>
<Value name="3">
<Value>AuditTime</Value>
</Value>
<Value name="4">
<Value>Dashboard</Value>
</Value>
</Data>
<DataLocation>^DeepSee.CubeManager.AuditD</DataLocation>
<DefaultData>AuditDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^DeepSee.CubeManager.AuditD</IdLocation>
<IndexLocation>^DeepSee.CubeManager.AuditI</IndexLocation>
<StreamLocation>^DeepSee.CubeManager.AuditS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
