/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class has been deprecated; use <class>%SYS.Task.Config</class> instead.
Class %SYSTEM.TaskConfig Extends (%Persistent, %SYS.Task.Config) [ Deprecated, Inheritance = right, System = 4 ]
{

Storage Default
{
<Data name="ConfigDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Data</Value>
</Value>
<Value name="3">
<Value>ParamName</Value>
</Value>
</Data>
<DataLocation>^|"^^"_$ZU(12)|SYS("Task","ConfigD")</DataLocation>
<DefaultData>ConfigDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^|"^^"_$ZU(12)|SYS("Task","ConfigD")</IdLocation>
<IndexLocation>^|"^^"_$ZU(12)|SYS("Task","ConfigI")</IndexLocation>
<StreamLocation>^|"^^"_$ZU(12)|SYS("Task","ConfigS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
