/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SQL.Util.TuneTableStats Extends (%XML.Adaptor, %Library.RegisteredObject) [ System = 4 ]
{

/// Name of the schema
Property schema As %String(MAXLEN = 127);

/// Name of the base table
Property table As %String(MAXLEN = 127);

/// EXTENTSIZE base table
Property extentsize As %Library.BigInt;

Relationship fields As %SQL.Util.TuneTableStatsFields [ Cardinality = children, Inverse = table ];

Relationship maps As %SQL.Util.TuneTableStatsMaps [ Cardinality = children, Inverse = table ];

}
