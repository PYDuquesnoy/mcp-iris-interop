/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SQL.Util.TuneTableStatsFields Extends (%XML.Adaptor, %Library.RegisteredObject) [ System = 4 ]
{

Relationship table As %SQL.Util.TuneTableStats [ Cardinality = parent, Inverse = fields ];

/// Field name
Property name As %String(MAXLEN = 127);

/// Selectivity
Property selectivity As %String;

/// Outlier Selectivity
Property outlierselectivity As %String(MAXLEN = 32767);

/// Average Field Size
Property averagefieldsize As %Numeric;

/// Histogram
Property histogram As %String(MAXLEN = 32767);

}
