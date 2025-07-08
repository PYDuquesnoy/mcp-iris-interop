/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a skiplist, containing entities to be left out of processing
Class %iKnow.Model.skiplist Extends %iKnow.Model.node [ Deprecated, System = 4 ]
{

Relationship domain As %iKnow.Model.domain(XMLPROJECTION = "none") [ Cardinality = one, Inverse = skiplists ];

/// Name of the skiplist
Property name As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property description As %String(XMLPROJECTION = "ATTRIBUTE");

Property entries As list Of %String(XMLNAME = "entry", XMLPROJECTION = "ELEMENT");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..name="") { 
			set tSC = $$$ERROR($$$GeneralError, "Skiplist name is a required field")
			quit
		} else {
			set tBLId = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(pDomainId, ..name)
			set tBLObj = ##class(%iKnow.Objects.SkipList).PKINDEXOpen(pDomainId, tBLId)
			if $isobject(tBLObj) {
				set tDefClass = ^IRIS.IK.Sys.Params(pDomainId,$$$IKPDEFINITIONCLASS)
				if tDefClass'=tBLObj.ManagerClass {
					set tSC = $$$ERROR($$$IKSkipListExists, ..name)
					quit
				}
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
