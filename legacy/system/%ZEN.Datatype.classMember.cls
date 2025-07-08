/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is used to represent a member of a server-side class name
/// (such as a property or method).
Class %ZEN.Datatype.classMember Extends datatype [ Deprecated, System = 3 ]
{

/// This indicated what type of class member this datatype
/// is used for.
Parameter MEMBERTYPE As STRING [ Constraint = ",PROPERTY,METHOD,QUERY,INDEX,XDATA,SQLCOLUMN", Flags = ENUM ];

Parameter XMLPROJECTION = "attribute";

Parameter MAXLEN = 64;

}
