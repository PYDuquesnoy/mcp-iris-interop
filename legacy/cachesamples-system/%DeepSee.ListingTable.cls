/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for all DeepSee listing tables.<br/>
/// Listing tables are used to hold the set of fact IDs when drilling through
/// a cube to generate a listing.
Class %DeepSee.ListingTable Extends %Persistent [ Abstract, NoExtent, SqlRowIdName = _DSListingId, System = 3 ]
{

/// Name of the cube that created this listing table.
Parameter CUBENAME As STRING;

/// Turn off extent management for listing tables.
Parameter MANAGEDEXTENT = 0;

Index ID On (queryKey, sourceId) [ IdKey ];

/// Key for the DRILLTHROUGH query that populated this record.
Property queryKey As %String(MAXLEN = 255) [ SqlFieldName = _DSqueryKey ];

/// Id in the source data table.
Property sourceId As %String(MAXLEN = 255) [ SqlFieldName = _DSsourceId ];

}
