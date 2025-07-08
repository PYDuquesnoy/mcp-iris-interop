/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKPublic, %IKInclude)

/// <p>This class represents the parameters controlling the match score calculation resulting from
/// the iKnow Smart Matching process driven from the <class>%iKnow.Matching.MatchingAPI</class>.</p>
/// <p>A Matching Profile can be linked to a domain, or just exist "namespace-wide", when
/// setting the <property>DomainId</property> property to 0. In the latter case, the profile
/// is typically referred to with a negative value for its <property>ProfileId</property>.</p>
/// <p>Use <method>GetProfile</method> to retrieve or instantiate a profile object.</p>
Class %iKnow.Matching.MatchingProfile Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

/// The domain ID this Matching Profile is associated with. When 0, this profile can be
/// used across the namespace.
Property DomainId As %Integer [ ReadOnly ];

/// The ID of this profile. This will be a negative number for namespace-wide profiles (which
/// have <property>DomainId</property> = 0).
Property ProfileId As %Integer [ ReadOnly ];

/// A name for this profile. This name should be unique within the domain (case-insensitive)
/// and cannot contain colons.
/// For backwards compatibility, empty names are permitted, but these profiles cannot be
/// retrieved with <method>GetProfileByName</method>
Property Name As %String(MAXLEN = 150) [ ReadOnly ];

/// The entity-level score of scattered entity matches will be multiplied by this modifier.
/// For example when matching the entity "blue big car" against the term "big blue car",
/// The initial score of 1 (as all words in the entity are matched) will be multiplied
/// with <property>ScatteredMatchMultiplier</property>
Property ScatteredMatchMultiplier As %Numeric [ InitialExpression = 0.75 ];

/// The entity-level score of relationship entities will be multiplied by this modifier.
Property RelationshipScoreMultiplier As %Numeric [ InitialExpression = 0.5 ];

/// The entity-level score of path-relevant entities will be multiplied by this modifier.
Property PathRelevantScoreMultiplier As %Numeric [ InitialExpression = 0.33 ];

/// When calculating an aggregate match score for a CRC, path or sentence, the "length" of
/// the matched section is compared to the total "length" of the CRC, path or sentence.
/// This "length" is calculated taking a value of 1 for each concept and a value of 
/// <property>RelationshipLengthMultiplier</property> for each relationship. Therefore,
/// setting this property to a lower value will decrease the weight of relationship
/// entities in calculating this ratio.
Property RelationshipLengthMultiplier As %Numeric [ InitialExpression = 0.2 ];

/// This multiplier is applied to the aggregate match score for a CRC, path or sentence
/// if the matched entities appear in a different order than in the dictionary term.
Property DisorderMultiplier As %Numeric [ InitialExpression = 0.7 ];

/// This is the lower threshold for match scores. Matches having a total score less than
/// <property>MinimalMatchScore</property> will not be stored or returned.
Property MinimalMatchScore As %Numeric [ InitialExpression = 0.33 ];

/// The total score of a path-level match is multiplied by this number.
Property PathTotalMultiplier As %Numeric [ InitialExpression = 1 ];

/// The total score of a CRC-level match is multiplied by this number.
Property CrcTotalMultiplier As %Numeric [ InitialExpression = 1 ];

/// The total score of a sentence-level match is multiplied by this number.
Property SentTotalMultiplier As %Numeric [ InitialExpression = 1 ];

/// If a dictionary term consists of more elements than <property>MaxTermLengthForCrc</property>,
/// it will not be considered a candidate for a CRC-level match. Typically these terms
/// should match at the path level.
Property MaxTermLengthForCrc As %Integer [ InitialExpression = 3, Internal ];

/// If a dictionary term consists of less elements than <property>MinTermLengthForPath</property>,
/// it will not be considered a candidate for a path-level match. Typically these terms
/// should match at the CRC level.
Property MinTermLengthForPath As %Integer [ InitialExpression = 4, Internal ];

/// If a dictionary term consists of less elements than <property>MinTermLengthForSent</property>,
/// it will not be considered a candidate for a sentence-level match. Typically these terms
/// should match at the CRC level.
Property MinTermLengthForSent As %Integer [ InitialExpression = 4, Internal ];

/// Use this parameter to add an additional requirement on the number of concepts from the
/// Dictionary Term that should be matched for an aggregate match to be considered.
/// A value of 1 (100%) implies all concepts should be matched. A value of at least 0.51 for example 
/// means both concepts in a CRC should match. A value of 0 (default) does not impose additional
/// restrictions. 
Property MinMatchedConceptFraction As %Numeric [ InitialExpression = 0 ];

/// Use this parameter to modify the score of matched entities which are part of a negation. 
/// Typically, this value will be either 1, ignoring the fact an entity is part of a negation,
/// or 0, which will make the algorithm skip these entities. Other positive numeric values are
/// also accepted and just modify the entity-level score for the affected entities, causing them
/// to be considered partial matches.
Property NegationMultiplier As %Numeric [ InitialExpression = 1 ];

Index PKINDEX On (DomainId, ProfileId) [ IdKey, PrimaryKey, Unique ];

/// <p>Utility method to instantiate a Matching Profile. If passed a negative integer for 
/// <var>pProfileId</var>, it will look for a namespace-wide Matching Profile (which means
/// <property>DomainId</property> is 0), otherwise it will take look in the domain
/// specified through <var>pDomainId</var>. If <var>pProfileId</var> is empty, the default
/// profile for this domain will be returned.</p>
/// <p>This is the recommended way of instantiating a
/// <class>%iKnow.Matching.MatchingProfile</class> object.</p>
ClassMethod GetProfile(pDomainId As %Integer = 0, pProfileId As %Integer = "", pSC As %Status = {$$$OK}) As %iKnow.Matching.MatchingProfile
{
	set pSC = $$$OK, tProfile = ""
	try {
		if 'pProfileId {
			set tDefault = $$$GETPARAMNODEF(pDomainId,$$$IKPMATDEFAULTPROFILE)
			if tDefault'="" {
				set tProfile = ..GetProfileByName(pDomainId, tDefault)
				if '$isobject(tProfile) { set pSC = $$$ERROR($$$IKMatProfileDoesNotExist, tDefault, pDomainId)  quit }
			} else {
				set tProfile = ..%New(pDomainId)
			}
		} elseif (pProfileId>0) {
			set tProfile = ..PKINDEXOpen(pDomainId, pProfileId)
		} else {
			set tProfile = ..PKINDEXOpen(0, $zabs(pProfileId))
		}
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tProfile
}

/// Looks up a Matching Profile by name in the domain identified by <var>pDomainId</var> (or
/// in the set of cross-domain profiles if <var>pDomainId</var> = 0).
/// <var>pName</var> should be a nonempty string and can be prepended with the domain ID to
/// look into (overriding the value of <var>pDomainId</var>), separated by a colon. This
/// allows configuration settings to refer to a particular Matching Profile with a single
/// string. Matching Profiles without a name cannot be looked up through this method and 
/// should be looked up by ID using <method>GetProfile</method> instead.
ClassMethod GetProfileByName(pDomainId As %Integer = 0, pName As %String, pSC As %Status = {$$$OK}) As %iKnow.Matching.MatchingProfile
{
	set pSC = $$$OK, tProfile = ""
	try {
		if (pName="") {
			set pSC = $$$ERROR($$$InvalidArgument)
			quit
		}
		
		if ($f(pName,":")>0) {
			set pDomainId = +$piece(pName,":",1)
			set pName = $piece(pName,":",2)
		}
		
		if (pDomainId > 0) {
			$$$CHECKDOMAINEXISTSX(pDomainId,pSC)
		}
		
		// we do not have a dedicated index structure for profiles, so just loop
		// through the ones registered for this domain
		set tProfileId = "", tName = $$$UPPER(pName)
		for {
			set tProfileId = $order(^IRIS.IK.Mat.Profile(pDomainId, tProfileId), 1, tData)
			quit:tProfileId=""
			quit:$$$UPPER($lg(tData,12))=tName
		}
		quit:'tProfileId
		
		set tProfile = ..PKINDEXOpen(pDomainId, tProfileId)
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tProfile
}

/// Creates a new Matching Profile instance in domain <var>pDomainId</var> (set to 0 to use
/// the profile across domains) named <var>pName</var>. The name is optional but if specified,
/// should be unique within the domain (or within the cross-domain profiles) and cannot
/// contain colon characters.
Method %OnNew(pDomainId As %Integer = 0, pName As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVWRITE
	
	set tSC = $$$OK
	try {
		
		if (pDomainId > 0) {
			$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		}
		
		if (pName '= "") {
			
			if ($find(pName,":")) {
				set tSC = $$$ERROR($$$IKIllegalMatProfileName, pName)
				quit
			}
			
			set i = "", tName = $$$UPPER(pName)
			for {
				set i = $order(^IRIS.IK.Mat.Profile(+pDomainId, i), 1, tData)
				quit:i=""
				
				if ($$$UPPER($lg(tData, 12))=tName) {
					set tSC = $$$ERROR($$$IKMatProfileExists, pName)
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		
		set i%DomainId = +pDomainId
		set i%ProfileId = $i(^IRIS.IK.Mat.Profile(pDomainId))
		set i%Name = pName
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method ProfileIdGet() As %Integer [ Internal, ServerOnly = 1 ]
{
	quit i%ProfileId * $s(i%DomainId>0:1, 1:-1)
}

/// Copies all non-ReadOnly property values of the supplied Matching Profile object
/// to the current object. This excludes <property>ProfileId</property>,
/// <property>DomainId</property> and <property>Name</property>.
Method ApplyProperties(pOtherProfile As %iKnow.Matching.MatchingProfile) As %Status
{
	set tSC = $$$OK
	try {
		set tClass = ##class(%Dictionary.ClassDefinition).%OpenId("%iKnow.Matching.MatchingProfile")
		for i = 1:1:tClass.Properties.Count() {
			set tProp = tClass.Properties.GetAt(i)
			continue:tProp.ReadOnly
			set $property(##this, tProp.Name) = $property(pOtherProfile, tProp.Name)
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVWRITE
	
	if (..DomainId) { $$$IKCHECKDOMMGR(..DomainId) }
	quit $$$OK
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVWRITE
	
	set tSC = $$$OK
	try {
		set tProfile = ..%Open(oid)
		if tProfile="" { set tSC = $$$ERROR($$$GeneralError, "Unkown profile: "_oid)  quit }
		
		if (tProfile.DomainId) { $$$IKCHECKDOMMGRX(tProfile.DomainId,tSC) }
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method NegationMultiplierGet() As %Numeric [ Internal, ServerOnly = 1 ]
{
	// backwards compatibility
	set tValue = i%NegationMultiplier
	quit $s(tValue="":1, 1:tValue)
}

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="CrcTotalMultiplier">
<Piece>7</Piece>
</Data>
<Data name="DisorderMultiplier">
<Piece>3</Piece>
</Data>
<Data name="MaxTermLengthForCrc">
<Piece>9</Piece>
</Data>
<Data name="MinMatchedConceptFraction">
<Piece>13</Piece>
</Data>
<Data name="MinTermLengthForPath">
<Piece>10</Piece>
</Data>
<Data name="MinTermLengthForSent">
<Piece>11</Piece>
</Data>
<Data name="MinimalMatchScore">
<Piece>4</Piece>
</Data>
<Data name="Name">
<Piece>12</Piece>
</Data>
<Data name="NegationMultiplier">
<Piece>14</Piece>
</Data>
<Data name="PathRelevantScoreMultiplier">
<Piece>15</Piece>
</Data>
<Data name="PathTotalMultiplier">
<Piece>6</Piece>
</Data>
<Data name="RelationshipLengthMultiplier">
<Piece>5</Piece>
</Data>
<Data name="RelationshipScoreMultiplier">
<Piece>2</Piece>
</Data>
<Data name="ScatteredMatchMultiplier">
<Piece>1</Piece>
</Data>
<Data name="SentTotalMultiplier">
<Piece>8</Piece>
</Data>
<Global>^IRIS.IK.Mat.Profile</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{ProfileId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.Mat.ProfileS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
