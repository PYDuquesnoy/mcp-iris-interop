/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class has been deprecated; please use <class>%SYS.Task</class> instead.
/// 
Class %SYSTEM.Task Extends (%SYS.TaskSuper, Help) [ Deprecated, Inheritance = right, System = 4 ]
{

Parameter XMLTYPE = "SYSTEMTask";

Storage Default
{
<Data name="TaskDefaultData1">
<Subscript>"1"</Subscript>
<Value name="1">
<Value>SuspendOnError</Value>
</Value>
<Value name="2">
<Value>SuspendTerminated</Value>
</Value>
</Data>
<DefaultData>TaskDefaultData1</DefaultData>
<ExtentSize>100000</ExtentSize>
<Type>%Storage.Persistent</Type>
}

}
