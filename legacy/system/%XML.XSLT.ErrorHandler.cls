/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.XSLT.ErrorHandler">Performing XSLT Transformations</a>.</p>
/// Handles errors encountered during transformation
Class %XML.XSLT.ErrorHandler Extends %RegisteredObject [ System = 3 ]
{

Method error(pMessage As %String)
{
	Write !,pMessage
}

Method fatalError(pMessage As %String)
{
	Write !,pMessage
}

Method warning(pMessage As %String)
{
	Write !,pMessage
}

Method message(pMessage As %String)
{
	Write !,pMessage
}

}
