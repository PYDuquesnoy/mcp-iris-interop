/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.MsgFilter.SavedSearchBase Extends %XML.Adaptor [ Abstract, System = 4 ]
{

/// Name of the search, which is used as the ID key.
Property Name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// Reference to the Filter object used to construct the eventual query.
Property Filter As EnsPortal.MsgFilter.Filter;

/// Username of the user responsible for creating the saved search. It is not exposed to XML, 
/// so is only populated when the object is created.
Property %CreatedBy As %String(MAXLEN = 128, XMLPROJECTION = "NONE") [ InitialExpression = {$username}, ReadOnly ];

/// Time (in UTC) at which the search was first created. Not exposed to XML.
Property %TimeCreated As Ens.DataType.UTC(XMLPROJECTION = "NONE") [ InitialExpression = {$$$timeUTC}, ReadOnly ];

/// Time (in UTC) when the search was last modified. Not exposed to XML.
Property %TimeModified As Ens.DataType.UTC(XMLPROJECTION = "NONE") [ InitialExpression = {$$$timeUTC}, ReadOnly ];

/// Username of the user who last modified the search. Not exposed to XML.
Property %ModifiedBy As %String(MAXLEN = 128, XMLPROJECTION = "NONE") [ InitialExpression = {$username}, ReadOnly ];

/// Sub Classes can override and implement restrictions.
Query ListPermanent() As %ExtentSQLQuery(CONTAINID = 1) [ SqlProc ]
{
}

}
