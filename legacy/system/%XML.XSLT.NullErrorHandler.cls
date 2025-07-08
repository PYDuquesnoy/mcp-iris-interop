/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides an error handler which does nothing
Class %XML.XSLT.NullErrorHandler Extends %XML.XSLT.ErrorHandler
{

/// Do Nothing
Method error(pMessage As %String)
{
}

/// Do Nothing
Method fatalError(pMessage As %String)
{
}

/// Do Nothing
Method warning(pMessage As %String)
{
}

}
