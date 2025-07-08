/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a cube-to-cube relationship within a DeepSee cube.
Class %DeepSee.Model.relationship Extends (%DeepSee.Model.node, %DeepSee.Model.source) [ System = 3 ]
{

/// Cube that this relationship belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = relationships ];

/// (Logical) Name of the cube this relationship refers to.
Property relatedCube As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Name of the inverse relationship within the related cube.
Property inverse As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Cardinality of this relationship.<br/>
/// If "one", then this relationship refers to one fact 
/// within the related cube.<br/>
/// If "many", then this relationship refers to many facts 
/// within the related cube.<br/>
Property cardinality As %DeepSee.Datatype.string(VALUELIST = ",one,many", XMLPROJECTION = "attribute");

/// Optional. If defined, this is used as the display value for
/// any records that have no related item.<br/>
/// The <var>nullReplacement</var> property for the entire cube is ignored by relationships.<br/>
/// If not defined, then missing members will not be listed by queries.<br/>
Property nullReplacement As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// If defined, this is an MDX expression identifying another level/relationship within this cube
/// that this relationship depends on, e.g., "[Outlet].[H1].[City]"<br/>
/// This causes the following changes to this cube.<br/>
/// <ol>
/// <li>An additional index is created based on the "master" level's fact and this relationship's fact.</li>
/// <li>When the set of members for this level is produced it is filtered using this index.</li>
/// </ol>
Property dependsOn As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// Define a stable fact number for this relatinonship
Property factNumber As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Test if this relationship's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
		If ('..disabled) {
			Set tHasSource = (..sourceExpression'="") || (..sourceProperty'="")

			// n.b., we cannot validate the other side of the relationship at this point
			If (..name="") {
				Set tSC = $$$ERROR($$$GeneralError,"Relationship must have a name")
				Quit
			}
			If (..relatedCube="") {
				Set tSC = $$$ERROR($$$GeneralError,"Relationship must specify a related cube: " _ ..name)
				Quit
			}
			If (..cardinality="") {
				Set tSC = $$$ERROR($$$GeneralError,"Relationship must specify cardinality: " _ ..name)
				Quit
			}
			If ((..inverse="")&&('tHasSource)) {
				Set tSC = $$$ERROR($$$GeneralError,"Non-stored side of relationship must specify an inverse name: " _ ..name)
				Quit
			}
			If ((..dependsOn'="")&&('tHasSource)) {
				Set tSC = $$$ERROR($$$GeneralError,"Non-stored side of relationship cannot define dependsOn: " _ ..name)
				Quit
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
