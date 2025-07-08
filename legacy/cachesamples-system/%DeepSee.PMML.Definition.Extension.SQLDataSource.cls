/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Extension.SQLDataSource Extends DataSource [ System = 3 ]
{

Parameter XMLNAME = "X-SQLDataSource";

Property SQL As %String(MAXLEN = 20000, XMLNAME = "X-SQL", XMLPROJECTION = "ELEMENT");

}
