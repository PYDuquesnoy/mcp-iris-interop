/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.MsgRouter.SegmentedRoutingEngine Extends EnsLib.MsgRouter.VDocRoutingEngine [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// we need this property for EvaluateRules to get access to the Segments
Property Segment As EnsLib.EDI.Segment [ Transient ];

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
