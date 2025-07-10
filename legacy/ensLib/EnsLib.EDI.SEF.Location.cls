/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.SEF.Location Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the Transaction Set ID
Property Set As %String;

/// This holds the ordinal number of segment reference within transaction set
Property SegOrd As %Integer;

/// This holds the segment tag, applicable to dictionary segment only
Property SegTag As %String;

/// This holds the element id, applicable to dictionary segment only
Property EleID As %String;

/// This holds the item (element/composite) ordinal
Property EleOrd As %Integer;

/// This holds the sub-element ordinal (optional)
Property SubEleOrd As %Integer;

}
