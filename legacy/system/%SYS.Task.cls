/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines an API to schedule tasks to run in the background.
/// <br><br>
Class %SYS.Task Extends %SYS.TaskSuper [ System = 4 ]
{

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
