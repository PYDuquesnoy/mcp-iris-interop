/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A header class that records raw Adapter Inputs and Outputs
Class Ens.Util.IOLogStream Extends Ens.Util.IOLog [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Property InObject As %GlobalBinaryStream;

Property OutObject As %GlobalBinaryStream;

Method IsEmpty() As %Boolean
{
	Quit ""=..%Id()&&(0=..InObject.Size)&&(0=..OutObject.Size)
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
