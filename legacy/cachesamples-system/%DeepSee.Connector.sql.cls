/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Sql node used within a DeepSee DataConnector SourceQuery definition.<br/>
Class %DeepSee.Connector.sql Extends abstractNode [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/connector/query";

Parameter XMLINCLUDEINGROUP = 1;

/// SQL query.
Property content As %ZEN.Datatype.sql(XMLPROJECTION = "content");

}
