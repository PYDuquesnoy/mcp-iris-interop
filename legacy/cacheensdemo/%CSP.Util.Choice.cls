/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
Class %CSP.Util.Choice Extends %String [ System = 4 ]
{

/// Full name of class containing the query.
Parameter QUERYCLASS;

/// Name of query.
Parameter QUERYNAME;

/// Name of column containing the caption;
Parameter CAPTIONCOLUMN;

/// Name of column containing the value.
/// If not present, CAPTIONCOLUMN is used.
Parameter VALUECOLUMN;

/// Optional value for first query parameter.
Parameter P1;

/// Optional value for second query parameter.
/// Assumes there is a value for P1.
Parameter P2;

/// Optional value for third query parameter.
/// Assumes there is a value for P1 and P2.
Parameter P3;

}
