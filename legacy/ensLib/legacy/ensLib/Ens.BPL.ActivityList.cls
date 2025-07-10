/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class groups activities together, and is used wherever more than one activity
/// needs to be defined
Class Ens.BPL.ActivityList Extends Ens.BPL.NodeList [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the user documentation for this Activity
Property Annotation As %String(MAXLEN = "");

/// The type (class name) of the elements stored in the collection.
Parameter ELEMENTTYPE = "Ens.BPL.Activity";

/// This generates the common XML attributes for this Activity
Method GenerateXML(pStream As %BinaryStream) As %Status
{
	If ..Annotation'="" {
		Do pStream.Write("<annotation><![CDATA[")
		Do pStream.Write(..Annotation)
		Do pStream.WriteLine("]]></annotation>")
	}
	
	Quit ##super(pStream)
}

}
