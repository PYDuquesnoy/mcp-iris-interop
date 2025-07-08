/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// Utility class.
/// Defines an entry within a DeepSee query test.
Class %DeepSee.TestSpec Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 3 ]
{

Parameter XMLIGNORENULL = 1;

Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/queryTest";

/// Name of this test (name of the XData that defined it).
Property name As %String(MAXLEN = 255, XMLPROJECTION = "none");

/// The test query.
Property query As %String(MAXLEN = 32000);

/// Expected total sum of all cells within the query.
Property totalSum As %Double;

}
