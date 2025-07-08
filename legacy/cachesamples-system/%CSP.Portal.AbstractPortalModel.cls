/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for models that are used in the portal by subclasses of <class>%CSP.Portal.SourceControl.Base</class>.
Class %CSP.Portal.AbstractPortalModel [ Abstract, System = 3 ]
{

/// The most recent time that the underlying class definition was changed.
Property Timestamp As %TimeStamp(XMLPROJECTION = "NONE") [ Transient ];

/// Flag to indicate whether the current object should be handled in ReadOnly mode.
/// A value of 1 indicates that the class could not be locked.
/// A value of 2 indicates that the source control framework indicated that the document is ReadOnly.
Property ReadOnly As %Integer(XMLPROJECTION = "NONE") [ InitialExpression = 0, Transient ];

}
