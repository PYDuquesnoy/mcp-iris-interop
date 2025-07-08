/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a Matching Profile to use for matching sources against dictionaries.
/// See also <class>%iKnow.Matching.MatchingProfile</class>.
Class %iKnow.Model.matchingProfile Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "profile";

/// Link to the &lt;matching&gt; element this profile belongs to.
Relationship matching As %iKnow.Model.matching(XMLPROJECTION = "none") [ Cardinality = one, Inverse = profiles ];

Property name As %String(MAXLEN = 50, XMLPROJECTION = "ATTRIBUTE");

/// The entity-level score of scattered entity matches will be multiplied by this modifier.
/// For example when matching the entity "blue big car" against the term "big blue car",
/// The initial score of 1 (as all words in the entity are matched) will be multiplied
/// with <property>ScatteredMatchMultiplier</property>
Property scatteredMatchMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0.75 ];

/// The entity-level score of relationship entities will be multiplied by this modifier.
Property relationshipScoreMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0.5 ];

/// The entity-level score of path-relevant entities will be multiplied by this modifier.
Property pathRelevantScoreMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0.33 ];

/// When calculating an aggregate match score for a CRC, path or sentence, the "length" of
/// the matched section is compared to the total "length" of the CRC, path or sentence.
/// This "length" is calculated taking a value of 1 for each concept and a value of 
/// <property>RelationshipLengthMultiplier</property> for each relationship. Therefore,
/// setting this property to a lower value will decrease the weight of relationship
/// entities in calculating this ratio.
Property relationshipLengthMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0.2 ];

/// This multiplier is applied to the aggegate match score for a CRC, path or sentence
/// if the matched entities appear in a different order than in the dictionary term.
Property disorderMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0.7 ];

/// This is the lower threshold for match scores. Matches having a total score less than
/// <property>MinimalMatchScore</property> will not be stored or returned.
Property minimalMatchScore As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0.33 ];

/// The total score of a path-level match is multiplied by this number.
Property pathTotalMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

/// The total score of a CRC-level match is multiplied by this number.
Property crcTotalMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

/// The total score of a sentence-level match is multiplied by this number.
Property sentTotalMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

/// Use this parameter to add an additional requirement on the number of concepts from the
/// Dictionary Term that should be matched for an aggregate match to be considered.
/// A value of 1 (100%) implies all concepts should be matched. A value of at least 0.51 for example 
/// means both concepts in a CRC should match. A value of 0 (default) does not impose additional
/// restrictions. 
Property minMatchedConceptFraction As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

/// Use this parameter to modify the score of matched entities which are part of a negation. 
/// Typically, this value will be either 1, ignoring the fact an entity is part of a negation,
/// or 0, which will make the algorithm skip these entities. Other positive numeric values are
/// also accepted and just modify the entity-level score for the affected entities, causing them
/// to be considered partial matches.
Property negationMultiplier As %Numeric(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

/// If set to 1, this element is ignored when compiling, validating and building the domain
Property disabled As %Boolean(XMLPROJECTION = "attribute");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		if (..name="") {
			set tSC = $$$ERROR($$$GeneralError, "Matching profile name is a required attribute")
			quit
		}
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
