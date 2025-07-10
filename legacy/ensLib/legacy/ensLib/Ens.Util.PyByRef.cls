/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Helper to return additional values from Embedded Python methods to ObjectScript methods
/// Instead of a ByRef argument
/// An instance of Ens.Util.PyByRef is created
/// <example>
/// set status=##class(Ens.Util.PyByRef).%New()
/// </example>
/// Within the Python method set the property "Value" to for example a status code
/// <example>
/// status.value=iris.cls("%SYSTEM.Status").ERROR(5001,"Some Error")
/// </example>
/// In the calling code, retrieve the content from "Value" property.
/// <example>
/// if $$$ISERR(status.value) ...
/// </example>
Class Ens.Util.PyByRef Extends %Library.RegisteredObject
{

Property value As %RawString;

}
