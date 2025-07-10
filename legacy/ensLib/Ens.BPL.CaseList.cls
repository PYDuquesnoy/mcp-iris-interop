/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a list collection of Case Nodes
Class Ens.BPL.CaseList Extends Ens.BPL.NodeList [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "Ens.BPL.CaseNode";

}
