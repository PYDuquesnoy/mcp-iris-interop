/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// ML Configuration Definitions for AutoML provider
/// %SYS.ML.Configuration.Type=0 for AutoML
/// 
Class %SYS.ML.AutoML.Configuration Extends %SYS.ML.Configuration
{

Storage Default
{
<Data name="AutoMLDefaultData">
<Subscript>"AutoML"</Subscript>
</Data>
<DefaultData>AutoMLDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
