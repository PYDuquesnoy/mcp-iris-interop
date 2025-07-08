/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implementation of extensibility elements added after main type definition<br><br>
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %XML.ElementExtension Extends (%RegisteredObject, %XML.Adaptor) [ System = 3 ]
{

Parameter XMLMAPPING = "sequence";

Parameter XMLFORMAT = "literal";

Property extension As list Of %XML.String(XMLPROJECTION = "any");

}
