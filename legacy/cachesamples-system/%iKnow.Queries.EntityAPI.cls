/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
///  Main Query class for retrieving Entities.
Class %iKnow.Queries.EntityAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

/// <p>Returns the entity string value corresponding to the specified entity ID, if any.</p>
ClassMethod GetValue(domainid As %Integer, entityid As %Integer, vSrcId As %Integer = 0, Output pSC As %Status) As %String
{
	set pSC = $$$OK
	$$$IKCHECKPRIVREADR(pSC,"")
	set tEntValue = ""
	try {
		set tEntValue = ..GetValueInternal(domainid, entityid, vSrcId)
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tEntValue
}

/// Returns the string value of the stem identified by <var>pStemUniId</var>
ClassMethod GetStemValue(pDomainId As %Integer, pStemUniId As %Integer, vSrcId As %Integer = 0, Output pSC As %Status) As %String
{
	set pSC = $$$OK
	$$$IKCHECKPRIVREADR(pSC,"")
	set tStemValue = ""
	try {
		set tStemValue = ..GetValueInternal(pDomainId, pStemUniId, vSrcId, 1)
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tStemValue
}

/// Internal version of <method>GetValue</method>, skipping security checks.
ClassMethod GetValueInternal(pDomainId As %Integer, pEntUniId As %Integer, vSrcId As %Integer = 0, pUseStem As %Boolean = 0) As %String [ Internal ]
{
	if pUseStem {
		quit:vSrcId $get(^IRIS.IKV.StemUniId(pDomainId, $zabs(vSrcId), pEntUniId))
		quit $get(^IRIS.IK.StemUniId(pDomainId, pEntUniId))
	} else {
		quit:vSrcId $get(^IRIS.IKV.EntUniId(pDomainId, $zabs(vSrcId), pEntUniId))
		quit $get(^IRIS.IK.EntUniId(pDomainId, pEntUniId))
	}
}

/// Retrieves all entities corresponding to a certain stem identified by <var>pStemUniId</var> in an array: pResult(tEntUniId)="".
ClassMethod GetByStemArray(ByRef pResult, pDomainId As %Integer, pStemUniId As %Integer, vSrcId As %Integer = 0, pLanguageId As %Integer = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	
	if $$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0 {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	}
	
	set gEntUniActual = $$$IKVGLOBNAME(pDomainId,"StemUniToEntUni",vSrcId)
	
	merge tActuals = @gEntUniActual@(pStemUniId)
	set tEntUniId = ""
	for {
		set tEntUniId = $order(tActuals(tEntUniId), 1, tLangBits)
		quit:tEntUniId=""
		
		continue:pLanguageId&&'$bit(tLangBits,pLanguageId)
		
		$$$IKQADDRESULT(pResult,tEntUniId,"")
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

Parameter GetByStemRT = "EntUniId:%Integer,EntityValue:%String";

/// Retrieves all entities corresponding to a certain stem identified by <var>pStemUniId</var>.
ClassMethod GetByStem(ByRef pResult, pDomainId As %Integer, pStemUniId As %Integer, vSrcId As %Integer = 0, pLanguage As %String = "") As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	
	set tSC = ..GetByStemArray(.tArray, pDomainId, pStemUniId, vSrcId, $lf($$$IKLANGUAGES,pLanguage))
	quit:$$$ISERR(tSC)
	
	set tEntUniId = ""
	for {
		set tEntUniId = $order(tArray(tEntUniId))
		quit:tEntUniId=""
		
		$$$IKQADDRESULT(pResult,$i(tCount),$lb(tEntUniId,..GetValueInternal(pDomainId,tEntUniId,vSrcId)))
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

/// Returns the stemmed form of the supplied string <var>pString</var>. 
/// If <var>pDomainId</var> is non-null, any domain-level configuration settings will be used
/// for the stemming operation.
ClassMethod GetStem(pDomainId As %Integer = "", pString As %String, pLanguage As %String = "", Output pSC As %Status = {$$$OK}) As %String
{
	set pSC = $$$OK, tStemmed = ""
	try {
		
		// first check if we already know this entity's stem from before
		if pDomainId'="" {
			set tEntUniId = ..GetIdInternal(pDomainId, .pString,, 0)
			if tEntUniId {
				set tStemUniId = ..GetStemIdByEntityId(pDomainId, tEntUniId,, $lf($$$IKLANGUAGES,pLanguage))
				if tStemUniId {
					set tStemmed = ..GetValueInternal(pDomainId, tStemUniId,, 1)
					quit
				}
			}
		}
		
		set tSC = ##class(%iKnow.Stemmer).GetByDomain(+pDomainId, .tStemmer)
		quit:$$$ISERR(tSC)
		if '$isobject(tStemmer) {
			set tSC = ##class(%iKnow.Stemmer).GetDefault($s(pLanguage="":"en", 1:pLanguage), .tStemmer)
			quit:$$$ISERR(tSC)
		}
		
		set tStemmed = tStemmer.StemAny(pString, pLanguage)
		
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tStemmed
}

/// Returns the representation form for the given stem and language 
ClassMethod GetStemRepresentationForm(pDomainId As %Integer, pStemUniId As %Integer, pLanguage As %String = "en", vSrcId As %Integer = 0, Output pSC As %Status = {$$$OK}) As %String
{
	set pSC = $$$OK, tRepForm = ""
	try {
		set tLangId = $lf($$$IKLANGUAGES,pLanguage)
		if 'tLangId {
			set pSC = $$$ERROR($$$IKLanguageDoesNotExist,pLanguage)
			quit
		}
		
		if (vSrcId) {
			set tRepFormEntId = $g(^IRIS.IKV.StemUniRep(+pDomainId,$zabs(vSrcId),+pStemUniId,+tLangId))
			set:tRepFormEntId tRepForm = ..GetValueInternal(pDomainId,tRepFormEntId,vSrcId)
		} else {
			set tRepFormEntId = $g(^IRIS.IK.StemUniRep(+pDomainId,+pStemUniId,+tLangId))
			set:tRepFormEntId tRepForm = ..GetValueInternal(pDomainId,tRepFormEntId)
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tRepForm
}

/// Returns the first stem ID found for the supplied entity.
ClassMethod GetStemIdByEntityId(pDomainId As %Integer, pEntUniId As %Integer, vSrcId As %Integer = 0, pLanguage As %Integer = 0) As %Integer [ Internal ]
{
	set gEntUniBase = $$$IKVGLOBNAME(pDomainId,"EntUniToStemUni",vSrcId)
	set tStemUniId = ""
	for {
		set tStemUniId = $order(@gEntUniBase@(pEntUniId, tStemUniId), 1, tLangBits)
		quit:tStemUniId=""
		continue:pLanguage&&'$bit(tLangBits,pLanguage)
		quit
	}
	quit tStemUniId
}

ClassMethod GetRepresentationFormId(pDomainId As %Integer, pStemUniId As %Integer, vSrcId As %Integer = 0, pLanguageId As %Integer = 0) As %Integer [ Internal ]
{
	if vSrcId {
		if pLanguageId && $d(^IRIS.IKV.StemUniRep(pDomainId, $zabs(vSrcId), pStemUniId, pLanguageId), tRepUniId) {
			quit tRepUniId
		} elseif $order(^IRIS.IKV.StemUniRep(pDomainId, $zabs(vSrcId), pStemUniId, ""), 1, tRepUniId) {
			quit tRepUniId
		} else {
			quit ""
		}
	} else {
		if pLanguageId && $d(^IRIS.IK.StemUniRep(pDomainId, pStemUniId, pLanguageId), tRepUniId) {
			quit tRepUniId
		} elseif $order(^IRIS.IK.StemUniRep(pDomainId, pStemUniId, ""), 1, tRepUniId) {
			quit tRepUniId
		} else {
			quit ""
		}
	}
}

///  <p>Returns the entity ID corresponding to the specified entity value, if any.</p>
///  <p>When specifying a Virtual Source ID, it will treat the entity as a virtual one, 
///  in the context of that vSrcId.</p>
ClassMethod GetId(domainid As %Integer, entityvalue As %String, vSrcId As %Integer = 0) As %Integer
{
	$$$IKCHECKPRIVREADR(sc,-1)
	quit ..GetIdInternal(domainid, .entityvalue, vSrcId, 0)
}

/// Internal version of <method>GetId</method>.
/// <var>stripPunctuation</var> should be set to 0 when called for user-supplied input (e.g. from <method>GetId</method>)
ClassMethod GetIdInternal(domainid As %Integer, ByRef entityvalue As %String, vSrcId As %Integer = 0, stripPunctuation As %Integer = 1) As %Integer [ Internal ]
{
	set vSrcId = $zabs(vSrcId)
	if (entityvalue = "") {
		quit 0
	} 
	// BDB977 - normalize without stripping punctuation
	set tEntityValue = $$$IKNORMALIZEDP(entityvalue,domainid,stripPunctuation)
	if ($length(tEntityValue) <= $$$IKHASHSIZE) {
		quit $s(vSrcId:$get(^IRIS.IKV.EntUni(domainid, vSrcId, " " _ tEntityValue)), 1:$get(^IRIS.IK.EntUni(domainid, " " _ tEntityValue)))
	} else {
		set hash = $zcrc(tEntityValue,7)
		set glob = $s(vSrcId:"^IRIS.IKV.EntUniHash("_domainid_","_vSrcId_")", 1:"^IRIS.IK.EntUniHash("_domainid_")")
		set globInv = $s(vSrcId:"^IRIS.IKV.EntUniId("_domainid_","_vSrcId_")", 1:"^IRIS.IK.EntUniId("_domainid_")")
		set candidate = ""
		for {
			set candidate = $order(@glob@(hash,candidate))
			quit:candidate=""
			quit:$g(@globInv@(candidate))=tEntityValue
		}
		quit candidate
	}
}

///  <p>Returns the stem ID corresponding to the specified stem value, if any.</p>
///  <p>When specifying a Virtual Source ID, it will treat the stem as a virtual one, 
///  in the context of that vSrcId.</p>
ClassMethod GetStemId(pDomainId As %Integer, pStemValue As %String, vSrcId As %Integer = 0) As %Integer
{
	$$$IKCHECKPRIVREADR(sc,-1)
	quit ..GetStemIdInternal(pDomainId, .pStemValue, vSrcId, 0)
}

/// Internal version of <method>GetStemId</method>.
/// <var>pStripPunctuation</var> should be set to 0 when called for user-supplied input (e.g. from <method>GetStemId</method>)
ClassMethod GetStemIdInternal(pDomainId As %Integer, ByRef pStemValue As %String, vSrcId As %Integer = 0, pStripPunctuation As %Boolean = 1) As %Integer [ Internal ]
{
	set vSrcId = $zabs(vSrcId)
	if (pStemValue = "") {
		quit 0
	} 
	// BDB977 - normalize without stripping punctuation
	set tStemValue = $$$IKNORMALIZEDP(pStemValue,pDomainId,pStripPunctuation)
	if ($length(tStemValue) <= $$$IKHASHSIZE) {
		quit $s(vSrcId:$get(^IRIS.IKV.StemUni(pDomainId, vSrcId, " " _ tStemValue)), 1:$get(^IRIS.IK.StemUni(pDomainId, " " _ tStemValue)))
	} else {
		set hash = $zcrc(tStemValue,7)
		set glob = $s(vSrcId:"^IRIS.IKV.StemUniHash("_pDomainId_","_vSrcId_")", 1:"^IRIS.IK.StemUniHash("_pDomainId_")")
		set globInv = $s(vSrcId:"^IRIS.IKV.StemUniId("_pDomainId_","_vSrcId_")", 1:"^IRIS.IK.StemUniId("_pDomainId_")")
		set candidate = ""
		for {
			set candidate = $order(@glob@(hash,candidate))
			quit:candidate=""
			quit:$g(@globInv@(candidate))=tStemValue
		}
		quit candidate
	}
}

///  <p>Returns the frequency of the entity corresponding to the supplied <var>entUniId</var>, occurring
///  in a concept role (if <var>enttype</var> = $$$ENTTYPECONCEPT), a relationship role (if
///  <var>enttype</var> = $$$ENTTYPERELATION) or both (<var>enttype</var> = $$$ENTTYPEANY).</p>
///  <p>When specifying a Virtual Source ID, the frequency within the virtual source will be returned.</p>
ClassMethod GetFrequency(domainId As %Integer, entUniId As %Integer, enttype As %Integer = {$$$ENTTYPEANY}, vSrcId As %Integer = 0, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKCHECKPRIVREADR(sc,-1)
	
	if (vSrcId) {
		set details = $g(^IRIS.IKV.EntUniDetails(+domainId,+$zabs(vSrcId),+entUniId))
	} else {
		if (filter'="") {
			$$$IKQFILTEROBJECTR(domainId,filter,sc,-1)
			quit:'$isobject(filter) -1
			quit filter.GetFilteredEntityFrequency(entUniId, enttype)
		} else {
			$$$IKQBCHECKR(domainId,$$$IKBENTUNIDET,sc,-1)
			set details = $g(^IRIS.IK.EntUniDetails(+domainId,+entUniId))
		}
	}
	quit:details="" -1
	
	quit +$case(enttype, $$$ENTTYPECONCEPT:$lg(details,1), $$$ENTTYPERELATION:$lg(details,2), $$$ENTTYPEANY:$lg(details,1)+$lg(details,2))
}

///  <p>Returns the frequency of the stem corresponding to the supplied <var>pStemUniId</var>, occurring
///  in a concept role (if <var>pEntType</var> = $$$ENTTYPECONCEPT), a relationship role (if
///  <var>pEntType</var> = $$$ENTTYPERELATION) or both (<var>pEntType</var> = $$$ENTTYPEANY).</p>
///  <p>When specifying a Virtual Source ID, the frequency within the virtual source will be returned.</p>
ClassMethod GetStemFrequency(pDomainId As %Integer, pStemUniId As %Integer, pEntType As %Integer = {$$$ENTTYPEANY}, vSrcId As %Integer = 0, pFilter As %iKnow.Filters.Filter = "", Output pSC As %Status = {$$$OK}) As %Integer
{
	$$$IKCHECKPRIVREADR(pSC,-1)
	
	// BDB600 - check if this is a domain with stemmed forms
	if ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0) {
		set pSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit -1
	}
	
	if (vSrcId) {
		set details = $g(^IRIS.IKV.StemUniDetails(+pDomainId,+$zabs(vSrcId),+pStemUniId))
	} else {
		if (pFilter'="") {
			$$$IKQFILTEROBJECTR(pDomainId,pFilter,pSC,-1)
			quit:'$isobject(pFilter) -1
			quit pFilter.GetFilteredStemFrequency(pStemUniId, pEntType)
		} else {
			$$$IKQBCHECKR(pDomainId,$$$IKBSTEMUNIDET,pSC,-1)
			set details = $g(^IRIS.IK.StemUniDetails(+pDomainId,+pStemUniId))
		}
	}
	quit:details="" -1
	
	quit +$case(pEntType, $$$ENTTYPECONCEPT:$lg(details,1), $$$ENTTYPERELATION:$lg(details,2), $$$ENTTYPEANY:$lg(details,1)+$lg(details,2))
}

///  <p>Returns the spread of the entity corresponding to the supplied <var>entUniId</var>, occurring
///  in a concept role (if <var>enttype</var> = $$$ENTTYPECONCEPT), a relationship role (if
///  <var>enttype</var> = $$$ENTTYPERELATION) or both (<var>enttype</var> = $$$ENTTYPEANY).</p>
ClassMethod GetSpread(domainId As %Integer, entUniId As %Integer, enttype As %Integer = {$$$ENTTYPEANY}, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKCHECKPRIVREADR(sc,-1)
	
	if (filter'="") {
		$$$IKQFILTEROBJECTR(domainId,filter,sc,-1)
		quit:'$isobject(filter) -1
		quit filter.GetFilteredEntitySpread(entUniId, enttype)
	}
	
	$$$IKQBCHECKR(domainId,$$$IKBENTUNIDET,sc,-1)
	set details = $g(^IRIS.IK.EntUniDetails(+domainId,+entUniId))
	quit:details="" -1
	
	quit +$lg(details, $case(enttype, $$$ENTTYPECONCEPT:4, $$$ENTTYPERELATION:5, $$$ENTTYPEANY:3))
}

///  <p>Returns the spread of the stem corresponding to the supplied <var>pStemUniId</var>, occurring
///  in a concept role (if <var>pEntType</var> = $$$ENTTYPECONCEPT), a relationship role (if
///  <var>pEntType</var> = $$$ENTTYPERELATION) or both (<var>pEntType</var> = $$$ENTTYPEANY).</p>
ClassMethod GetStemSpread(pDomainId As %Integer, pStemUniId As %Integer, pEntType As %Integer = {$$$ENTTYPEANY}, pFilter As %iKnow.Filters.Filter = "", Output pSC As %Status = {$$$OK}) As %Integer
{
	$$$IKCHECKPRIVREADR(pSC,-1)
	
	// BDB600 - check if this is a domain with stemmed forms
	if ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0) {
		set pSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit -1
	}
	
	if (pFilter'="") {
		$$$IKQFILTEROBJECTR(pDomainId,pFilter,pSC,-1)
		quit:'$isobject(pFilter) -1
		quit pFilter.GetFilteredStemSpread(pStemUniId, pEntType)
	}
	
	$$$IKQBCHECKR(pDomainId,$$$IKBSTEMUNIDET,pSC,-1)
	set details = $g(^IRIS.IK.StemUniDetails(+pDomainId,+pStemUniId))
	quit:details="" -1
	
	quit +$lg(details, $case(pEntType, $$$ENTTYPECONCEPT:4, $$$ENTTYPERELATION:5, $$$ENTTYPEANY:3))
}

/// <p>Returns the literal value for a particular <i>Part ID</i>, as it
/// occurred in the original text.</p>
ClassMethod GetLiteral(pDomainId As %Integer, pPartId As %Integer, vSrcId As %Integer = 0) As %String
{
	$$$IKCHECKPRIVREADR(pSC,"")
	if (vSrcId) {
		set entOcc = $g(^IRIS.IKV.EntOccId(+pDomainId,$zabs(vSrcId),+pPartId))
	} else {
		set entOcc = $g(^IRIS.IK.EntOccId(+pDomainId,+pPartId))
	}
	quit:entOcc="" -1
	quit ##class(%iKnow.Queries.SentenceAPI).GetPartLiteral(pDomainId,$li(entOcc,3),$li(entOcc,4),vSrcId)
}

///  <p>Returned column summary for <method>GetSimilar</method>.</p>
Parameter GetSimilarRT = "entUniId:%Integer,entity:%String,frequency:%Integer,spread:%Integer";

///  <p>This method will return all entities in the specified domain that are "similar" to the 
///  supplied <var>part</var> string. Similarity is defined using the <var>mode</var> parameter. The default setting
///  ($$$USEPARTS), will retrieve all clusters containing at least one word starting with the supplied
///  string, whereas $$$USENGRAMS will search for any character sequence within the whole entity.
///  With mode = $$$USEWORDS, the behavior is the same as $$$USEPARTS but the supplied <var>part</var>
///  needs to occur as a whole word in the retrieved clusters.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <var>filter</var>
///  parameter to restrict the result to those CRCs occurring in any source satisfying the filter
///  criteria. When using a filter, the <var>filtermode</var> parameter will control whether or not the
///  frequency and spread of returned records should be recalculated and whether results should be
///  resorted along these recalculated numbers.</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetSimilar(ByRef result, domainid As %Integer, part As %String, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, mode As %Integer = {$$$USEDOMAINDEFAULT}, skipListIds As %List = "", pEntRole As %Integer = {$$$ENTTYPEANY}, pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.GetEntitiesTrack,^||%IK.GetEntitiesFSort",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:$g(part)=""
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	} 

	// normalize to lowercase and strip whitespace
	// BDB977 - don't strip punctuation
	set part = $$$IKNORMALIZEDP(part,domainid,0)

	// define sort type
	set sorttype = $$$SORTFIELD(domainid)

	$$$IKBUILDSKIPLIST(domainid,skipListIds,0,pUseStems)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)

	if (mode=$$$USEDOMAINDEFAULT) {
		set mode = $s($$$GETPARAM(domainid,$$$IKPENABLENGRAMS,0):$$$USENGRAMS, 1:$$$USEPARTS)
	}
	if (mode '= $$$USEPARTS) && (mode '= $$$USENGRAMS) && (mode '= $$$USEWORDS) {
		set tSC = $$$ERROR($$$InvalidArgument)
		quit
	}

	// BDB422 - check $$$IKPENABLENGRAMS if not yet in a buildflags version
	if (mode=$$$USENGRAMS) && $$$IKVERSIONBEFORE(domainid,$$$IKVERSIONOPTIONALGLOBALS) && '$$$ENABLENGRAMS(domainid)  {
		set tSC = $$$ERROR($$$IKNgramNotEnabled)
		quit
	}
	
	// BDB354 - check build flags
	if (mode=$$$USENGRAMS) {
		// BDB422 - $$$IKPENABLENGRAMS overrides build flags!
		set tGlobs = $s($$$ENABLENGRAMS(domainid):"", 1:$lb($s(pUseStems:$$$IKBSTEMNGRAMS, 1:$$$IKBNGRAMS)))
	} else {
		set tGlobs = $lb($s(pUseStems:$$$IKBSTEMPARTS, 1:$$$IKBPARTS))
	}
	set:'$isobject(filter)||'$$$CHECKFILTERFREQ(filter,filtermode)||'$$$CHECKFILTERSPREAD(filter,filtermode) tGlobs = tGlobs _ $lb($$$IKBENTUNIDET)
	$$$IKQBCHECKX(domainid,tGlobs,tSC)
	
	if pUseStems {
		set globName = $case(mode, $$$USENGRAMS:"^IRIS.IK.StemNgrams", :"^IRIS.IK.StemParts")
	} else {
		set globName = $case(mode, $$$USENGRAMS:"^IRIS.IK.EntNgrams", :"^IRIS.IK.EntParts")
	}
	
	// if the supplied filter is very selective, we'll apply the filter before looking up
	// entities in the right bucket
	// COST (per result): 
	//		- filter first = Cost(IsFiltered) + [FilterSelectivity] * Cost(RandomRead,EntUniId)
	//		- read entity first = Cost(RandomRead,EntUniId) + [StringSelectivity] * Cost(IsFiltered)
	//			with approx [StringSelectivity] = ([TotEntCount]/[BucketCount]) / ([x] ** ($length(part)-3))
	//			with x expressing the number of possible characters (20 should be OK as an approximate)
	if $isobject(filter) {
		set bucketCount = 5000 // approximation
		// cut off at 50 to avoid MAXNUMBER errors, as it will be high enough by far!
		set tLengthPower = ($length(part)-3), tLengthPower = $s(tLengthPower>50:50, 1:tLengthPower)
		set stringSelectivity = (..GetMaxId(domainid,$$$IKFENTUNI)/bucketCount) / (20 ** tLengthPower)
		set applyFilterFirst = (filter.Selectivity < (1 + (stringSelectivity-1) * $$$IKCFILTER(filter) / $$$IKCRAND("EntUniId")))
	} else {
		set applyFilterFirst = 0
	}
	
	// find the NGram bucket we need to look into
	set partBucket = " " _ $extract(part, 1, 3)

	// for post-filter resorting, we have to track how many entries
	// are certainly inside the desired page
	set entriesWithinPage = 0
	
	// BDB411 - if part length < 3, we'll need to loop over all buckets and resort to be correct
	set tReSort = $$$CHECKFILTERSORT(filter,filtermode)
	set:($l(part)<3) usePaging = 0, tReSort = 1
	
	// start right before the bucket we'll look into
	set bucket = $order(@globName@(domainid,partBucket),-1)
	for {
		// find the next bucket that still starts with our partBucket
		set bucket = $order(@globName@(domainid, bucket))
		quit:bucket=""
		quit:$extract(bucket,1,$l(partBucket))'=partBucket
	
		set sort = ""
		for {
			// loop through the sorted entries in the bucket
			set sort = $order(@globName@(domainid, bucket, sort))
			quit:'sort
			
			// when the value for sort changes, we have to verify how many entries
			// are certainly within the desired page boundary
			if (usePaging && $$$CHECKFILTERSORT(filter,filtermode)) {
				set entriesWithinPage = 0
				set sortCheck = ""
				for {
					set sortCheck = $order(^||%IK.GetEntitiesFSort(sortCheck))
					quit:sortCheck=""
			
					// sort order is negative, so sortCheck < sort means this entry
					// in the current result list is certainly in the final results as
					// sort can only increase
					quit:sortCheck>=sort 
			
					set entriesWithinPage = entriesWithinPage + 1
				}
			}

			set entId = ""
			for {
				set entId = $order(@globName@(domainid, bucket, sort, entId))
				quit:entId=""
			
				continue:$$$IKISSKIPLISTED(entId) // BDB600 TODO?
				
				continue:applyFilterFirst&&'filter.IsFiltered(entId,$$$IKFENTUNI)
		
				//$$$IKQTIC("fetchEntValue")
				set entity = $s(pUseStems:^IRIS.IK.StemUniId(domainid, entId), 1:^IRIS.IK.EntUniId(domainid, entId))
				//$$$IKQTOC("fetchEntValue")
				
				// BDB567 - simplified similarity checking
				if (mode = $$$USEPARTS) {
					continue:'$find(" "_entity," "_part)
				} elseif (mode = $$$USEWORDS) {
					continue:'$find(" "_entity_" "," "_part_" ")
				} elseif (mode = $$$USENGRAMS) {
					continue:'$find(entity,part)
				}
					
				// check if we've already returned this entity
				continue:$data(^||%IK.GetEntitiesTrack(entId))
				set ^||%IK.GetEntitiesTrack(entId) = ""
		
				// check if the entity satisfies the filter
				set filteredSpread = 0
				set filteredFreq = 0
				if ($isobject(filter)) {
					continue:'applyFilterFirst&&'filter.IsFiltered(entId,$$$IKFENTUNI) // BDB600 TODO?
					if ($$$CHECKFILTERFREQ(filter,filtermode)) {
						//$$$IKQTIC("FilterFreq")
						set filteredFreq = filter.GetFilteredEntityFrequency(entId, pEntRole) // BDB600 TODO?
						//$$$IKQTOC("FilterFreq")
						continue:'filteredFreq
					}
					if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
						//$$$IKQTIC("FilterSpread")
						set filteredSpread = filter.GetFilteredEntitySpread(entId, pEntRole) // BDB600 TODO?
						//$$$IKQTOC("FilterSpread")
						continue:'filteredSpread
					}
				}
			
			
				// if we're looking for any role, check if it fits in the paging window
				if (pEntRole=$$$ENTTYPEANY) {
					set count = count + 1
					$$$IKCHECKPAGINGSORT(usePaging,first,last,count,filter,filtermode,entriesWithinPage)
				}
				
				
				// retrieve and "correct" frequency info
				set details = ""
				if ($$$CHECKFILTERFREQ(filter,filtermode)) {
					set finalFreq = filteredFreq
				} else {
					set details = $s(pUseStems:^IRIS.IK.StemUniDetails(domainid, entId), 1:^IRIS.IK.EntUniDetails(domainid, entId))
					if (pEntRole=$$$ENTTYPEANY) {
						set finalFreq = $lg(details,1)+$lg(details,2)
					} elseif (pEntRole=$$$ENTTYPECONCEPT) {
						set finalFreq = $lg(details,1)
					} elseif (pEntRole=$$$ENTTYPERELATION) {
						set finalFreq = $lg(details,2)
					}
				}
				if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
					set finalSpread = filteredSpread
				} else {
					set:details="" details = $s(pUseStems:^IRIS.IK.StemUniDetails(domainid, entId), 1:^IRIS.IK.EntUniDetails(domainid, entId))
					set finalSpread = $list(details, $case(pEntRole, $$$ENTTYPEANY:3, $$$ENTTYPECONCEPT:4, $$$ENTTYPERELATION:5))
				}
				continue:'finalFreq
				
				// if we're looking for a specific role, we can only check the paging window
				// after ensuring the spread and freq are > 0
				if (pEntRole'=$$$ENTTYPEANY) {
					set count = count + 1
					$$$IKCHECKPAGINGSORT(usePaging,first,last,count,filter,filtermode,entriesWithinPage)
				}
		
				// build the suggestion data 
				set suggestion =  $lb(+entId, 
										..GetValueInternal(domainid, entId,, pUseStems),
										finalFreq,			// freq
										finalSpread			// spread
									)
							
				// store the suggestion in the appropriate global
				if tReSort {
					
					// derive sort attribute
					if (sorttype=$$$SORTBYFREQUENCY) {
						set sortOrder = -finalFreq
					} elseif (sorttype = $$$SORTBYSPREAD) {
						set sortOrder = -finalSpread
					}
			
					// update entriesWithinPage if the current entry is certainly within
					// the end result page, which is the case if the filtered sort order
					// is already smaller then the best possible unfiltered sort order
					// we're looking at
					if (usePaging) {
						if (sortOrder < sort) {
							set entriesWithinPage = entriesWithinPage + 1
						}
					}
			
					// store suggestion in utility global
					set ^||%IK.GetEntitiesFSort(sortOrder, $i(^||%IK.GetEntitiesFSort)) = suggestion
			
					$$$IKCHECKPAGING(usePaging,0,last,entriesWithinPage)
			
				} else {
					$$$IKQADDRESULT(result,count,suggestion)
				}	
				$$$IKCHECKPAGINGSORT(usePaging,0,last,count,filter,filtermode,entriesWithinPage)
			}
			$$$IKCHECKPAGINGSORT(usePaging,0,last,count,filter,filtermode,entriesWithinPage)
		}
	}

	// if applicable, resort the results
	if (tReSort) {
		set tSC = ..CopyFromTempSortGlobal(.result,"^||%IK.GetEntitiesFSort",(page*pagesize)>0,first,last)
		quit:$$$ISERR(tSC)
	}
	
	$$$IKQENDCATCH(result,"^||%IK.GetEntitiesTrack,^||%IK.GetEntitiesFSort",tSC)
}

/// Internal method used by <class>%iKnow.DeepSee.Dimensions.SimilarEntities</class>
ClassMethod GetSimilarBits(pGlobalName As %String, pDomainId As %Integer, pString As %String, pFilter As %iKnow.Filters.Filter = "", pMode As %Integer = {$$$USEDOMAINDEFAULT}, pSkipListIds As %List = "", pUseStems As %Boolean = 0) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(pGlobalName,"^||%IKQ.Similar",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	
	// first get plain-indexed results
	set tSC = ..GetSimilarIds("^||%IKQ.Similar", pDomainId, pString,, pMode, pSkipListIds, pUseStems)
	quit:$$$ISERR(tSC)
	
	// convert to bitstring
	set tEntUniId = "", tPrevOff=0, tBits=""
	for {
		set tEntUniId = $order(^||%IKQ.Similar(tEntUniId))
		quit:tEntUniId=""
		
		$$$IKBITOFFPOS(tEntUniId,tOff,tPos)
		
		if (tOff '= tPrevOff) {
			set:tPrevOff @pGlobalName@(tPrevOff) = $bitlogic(tBits)
			set tPrevOff=tOff, tBits = ""
		}
		set $bit(tBits,tPos)=1
	}
	set:tPrevOff @pGlobalName@(tPrevOff) = $bitlogic(tBits)
	
	// apply filter, if any
	if $isobject(pFilter) {
		set tSC = pFilter.MergeBits(pGlobalName, $$$IKFENTUNI)
		quit:$$$ISERR(tSC)
	}
	
	$$$IKQENDCATCH(pGlobalName,"^||%IKQ.Similar",tSC)
}

/// Note: this method always returns all results and only writes to a global (no return var)
ClassMethod GetSimilarIds(pGlobalName As %String, pDomainId As %Integer, pString As %String, pFilter As %iKnow.Filters.Filter = "", pMode As %Integer = {$$$USEDOMAINDEFAULT}, pSkipListIds As %List = "", pEntRole As %Integer = {$$$ENTTYPEANY}, pUseStems As %Boolean = 0) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(pGlobalName,"^||%IK.Candidates",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	$$$IKBUILDSKIPLIST(pDomainId,pSkipListIds,0,pUseStems)
	quit:$g(pString)=""

	// normalize to lowercase and strip whitespace
	// BDB977 - don't strip punctuation
	set pString = $$$IKNORMALIZEDP(pString,pDomainId,0)
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	} 
	
	if (pMode=$$$USEDOMAINDEFAULT) {
		set pMode = $s($$$GETPARAM(pDomainId,$$$IKPENABLENGRAMS,0):$$$USENGRAMS, 1:$$$USEPARTS)
	}
	if (pMode '= $$$USEPARTS) && (pMode '= $$$USENGRAMS) && (pMode '= $$$USEWORDS) {
		set tSC = $$$ERROR($$$InvalidArgument)
		quit
	}

	// BDB422 - check $$$IKPENABLENGRAMS if not yet in a buildflags version
	if (pMode=$$$USENGRAMS) && $$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONOPTIONALGLOBALS) && '$$$ENABLENGRAMS(pDomainId)  {
		set tSC = $$$ERROR($$$IKNgramNotEnabled)
		quit
	}
	
	// BDB354 - check build flags
	if (pMode=$$$USENGRAMS) {
		// BDB422 - if $$$IKPENABLENGRAMS is set, it overrides the build flags
		if '$$$ENABLENGRAMS(pDomainId) {
			$$$IKQBCHECKX(pDomainId,$lb($s(pUseStems:$$$IKBSTEMNGRAMS, 1:$$$IKBNGRAMS)),tSC)
		}
	} else {
		$$$IKQBCHECKX(pDomainId,$lb($s(pUseStems:$$$IKBSTEMPARTS, 1:$$$IKBPARTS)),tSC)
	}
	
	set gParts = "^IRIS.IK."_$s(pUseStems:"Stem", 1:"Ent")_$case(pMode, $$$USENGRAMS:"Ngrams", :"Parts")_"("_pDomainId_")"
	set gUniDetails = "^IRIS.IK."_$s(pUseStems:"Stem", 1:"Ent")_"UniDetails("_pDomainId_")"
	
	// find the NGram bucket we need to look into
	set tPartBucket = " " _ $extract(pString, 1, 3)

	// start right before the bucket we'll look into
	set tBucket = $order(@gParts@(tPartBucket),-1)
	for {
		// find the next bucket that still starts with our partBucket
		set tBucket = $order(@gParts@(tBucket))
		quit:tBucket=""
		quit:$extract(tBucket,1,$l(tPartBucket))'=tPartBucket
	
		set tSort = ""
		for {
			set tSort = $order(@gParts@(tBucket, tSort))
			quit:'tSort
			
			set tEntUniId = ""
			for {
				set tEntUniId = $order(@gParts@(tBucket, tSort, tEntUniId))
				quit:tEntUniId=""
				continue:$$$IKISSKIPLISTED(tEntUniId)
				merge ^||%IK.Candidates(tEntUniId) = @gParts@(tBucket, tSort, tEntUniId)
			}
		}
	}
	
	$$$IKSORTBEGIN(@pGlobalName)
	set tEntUniId = "", tPrevOff=0, tBits=""
	for {
		set tEntUniId = $order(^||%IK.Candidates(tEntUniId))
		quit:tEntUniId=""
		
		set tEntUni = $s(pUseStems:^IRIS.IK.StemUniId(pDomainId, tEntUniId), 1:^IRIS.IK.EntUniId(pDomainId, tEntUniId))
		
		if (pMode = $$$USEPARTS) {
			continue:'$find(" "_tEntUni," "_pString)
		} elseif (pMode = $$$USEWORDS) {
			continue:'$find(" "_tEntUni_" "," "_pString_" ")
		} elseif (pMode = $$$USENGRAMS) {
			continue:'$find(tEntUni,pString)
		}
	
		// BDB527 - refine checks based on role
		if (pEntRole=$$$ENTTYPEANY) {
			continue:$isobject(pFilter)&&'pFilter.IsFiltered(tEntUniId,$$$IKFENTUNI) // BDB600 TODO?
		} elseif $isobject(pFilter) && 'pFilter.GetFilteredEntityFrequency(tEntUniId, pEntRole) { // BDB600 TODO?
			continue
		} elseif '$lg(@gUniDetails@(tEntUniId),1+pEntRole) {
			continue
		}
		
		set @pGlobalName@(tEntUniId) = ""
	}
	set x = $sortend(@pGlobalName)
	
	$$$IKQENDCATCH(pGlobalName,"^||%IK.Candidates",tSC)
}

///  <p>Returned column summary for <method>GetSimilarCounts</method>.</p>
Parameter GetSimilarCountsRT = "distinctEntities:%Integer,totalFrequency:%Integer,totalSpread:%Integer";

///  <p>This method returns aggregated details on the entities similar to a supplied text fragment <var>part</var>.
///  The returned list contains the total number of distinct entities similar to <var>part</var> appearing
///  in sources satisfying the supplied <var>filter</var> (if defined), their total aggregated frequency 
///  (with respect to <var>filter</var>, if defined) and the total number of sources containing at least one of 
///  these "similar" entities (again, respecting <var>filter</var>, if defined).</p>
///  <p>See also <method>GetSimilar</method> for a description of the other parameters.</p>
///  <p>Setting the <var>entType</var> parameter to $$$ENTTYPECONCEPT or $$$ENTTYPERELATION will
///  restrict the result to only include entity occurrences of the specified type in the returned
///  number of distinct entities and aggregated frequency. If an entity occurs as both a concept
///  and a relationship (typically in &lt;1% of cases), it contributes to the aggregated spread
///  regardless of <var>entType</var>.</p>
ClassMethod GetSimilarCounts(domainid As %Integer, part As %String, filter As %iKnow.Filters.Filter = "", mode As %Integer = {$$$USEDOMAINDEFAULT}, skipListIds As %List = "", Output sc As %Status = {$$$OK}, entType As %Integer = {$$$ENTTYPEANY}, pUseStems As %Boolean = 0) As %List
{
	$$$IKQBEGINR("^||%IK.GetSimilarCounts,^||%IKQ.GetSimilar",sc,"")
	$$$IKQFILTEROBJECTR(domainid,filter,sc,"")
	set distinctEntities=0, totalFrequency=0, totalSpread=0
	
	$$$IKQBCHECKX(domainid,$$$IKBENTUNISRC,sc)
	
	// start from the results of GetSimilarIds()
	set sc = ..GetSimilarIds("^||%IKQ.GetSimilar", domainid, part, filter, mode, skipListIds, pUseStems)
	quit:$$$ISERR(sc) ""
	
	set tFilterFirst = $isobject(filter) && (filter.Selectivity<0.05)
	
	set tEntUniId = ""
	for {
		set tEntUniId = $order(^||%IKQ.GetSimilar(tEntUniId),1,d)
		quit:tEntUniId=""
		
		set tEntOccOff = "", tEntUniFreq = 0
		for {
			if tFilterFirst {
				set tEntOccOff = filter.GetNextEntityOccurrenceFilterOffset(tEntOccOff, .tBits)
			} elseif pUseStems {
				set tEntOccOff = $order(^IRIS.IK.StemUniToOccBit(domainid,tEntUniId,tEntOccOff),1,tBits)
			} else {
				set tEntOccOff = $order(^IRIS.IK.EntUniToOccBit(domainid,tEntUniId,tEntOccOff),1,tBits)
			}
			quit:tEntOccOff=""
			if tFilterFirst {
				if pUseStems {
					set tBits = $bitlogic(tBits & ^IRIS.IK.StemUniToOccBit(domainid,tEntUniId,tEntOccOff))
				} else {
					set tBits = $bitlogic(tBits & ^IRIS.IK.EntUniToOccBit(domainid,tEntUniId,tEntOccOff))
				}
			}
			set:$isobject(filter)&&'tFilterFirst tFilterBits = filter.GetEntityOccurrenceFilter(tEntOccOff), tBits = $bitlogic(tBits & tFilterBits)
			if (entType'=$$$ENTTYPEANY) {
				set tEntTypeBits0 = $g(^IRIS.IK.EntTypeToOccBit(domainid,0,tEntOccOff)),
					tEntTypeBits1 = $g(^IRIS.IK.EntTypeToOccBit(domainid,1,tEntOccOff))
				set tBits = $s(entType=$$$ENTTYPECONCEPT:$bitlogic(tBits & ~tEntTypeBits0 & ~tEntTypeBits1), 1:$bitlogic(tBits & tEntTypeBits0 & ~tEntTypeBits1))
			}
			set tEntUniFreq = tEntUniFreq + $bitcount(tBits,1)
		}
		set:tEntUniFreq distinctEntities = distinctEntities + 1, totalFrequency = totalFrequency+tEntUniFreq
	}
	
	set entId = ""
	for {
		set entId = $order(^||%IKQ.GetSimilar(entId))
		quit:entId=""
		
		set srcOff = ""
		for {
			if pUseStems {
				set srcOff = $order(^IRIS.IK.StemUniToSrcBit(domainid, entId, srcOff), 1, srcBits)
			} else {
				set srcOff = $order(^IRIS.IK.EntUniToSrcBit(domainid, entId, srcOff), 1, srcBits)
			}
			quit:srcOff=""
			
			set ^||%IK.GetSimilarCounts(srcOff) = $bitlogic(srcBits | ^||%IK.GetSimilarCounts(srcOff))
		}
	}
	
	// now gather the results in ^||%IK.GetSimilarCounts to recalc spread
	set off=""
	for {
		set off = $order(^||%IK.GetSimilarCounts(off),1,srcBits)
		quit:off=""
	
		if $isobject(filter) {
			set filterBits = filter.GetSourceFilter(off)
			set srcBits = $bitlogic(srcBits & filterBits)
		}
		set totalSpread = totalSpread + $bitcount(srcBits,1)
	}
	
	$$$IKQEND("^||%IK.GetSimilarCounts,^||%IKQ.GetSimilar",$lb(distinctEntities,totalFrequency,totalSpread))
}

///  <p>Returned column summary for <method>GetTop</method>.</p>
Parameter GetTopRT = "entUniId:%Integer,entity:%String,frequency:%Integer,spread:%Integer";

///  <p>This method returns the most frequently occurring entities in the specified domain.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <var>filter</var>
///  parameter to restrict the result to those CRCs occurring in any source satisfying the filter
///  criteria. When using a filter, the <var>filtermode</var> parameter will control whether or not the
///  frequency and spread of returned records should be recalculated and whether results should be
///  resorted along these recalculated numbers.</p>
///  <p>Through the <var>enttype</var> parameter, the method can be instructed to return either concepts
///  ($$$ENTTYPECONCEPT) or relations ($$$ENTTYPERELATION). When looking for top concepts, those shorter
///  than 3 characters are skipped.</p>
///  <p>Returned values are either sorted by descending frequency (with <var>sorttype</var>
///  $$$SORTBYFREQUENCY), spread (with <var>sorttype</var> $$$SORTBYSPREAD) or the
///  domain default (with <var>sorttype</var> $$$SORTBYDOMAINDEFAULT).</p>
///  <p>If a Virtual Source ID is provided, only the entities in that virtual source will be considered,
///  filters are ignored and the sort type will always be $$$SORTBYFREQUENCY.</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetTop(ByRef result, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, enttype As %Integer = {$$$ENTTYPECONCEPT}, vSrcId As %Integer = 0, skipListIds As %List = "", pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.GetTopEntitiesFSort,^||%IK.GetTopEntitiesEOBits,^||%IK.EntUniSort",tSC)
	if vSrcId && (domainid=0) {} else { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	$$$IKCHECKSORTTYPEX(domainid,sorttype,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD),tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	$$$IKBUILDSKIPLIST(domainid,skipListIds,vSrcId,pUseStems)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	} 
	
	set enttype = +enttype
	if (enttype'=$$$ENTTYPECONCEPT) && (enttype'=$$$ENTTYPERELATION) {
		set tSC = $$$ERROR($$$InvalidArgument, "enttype")
		quit
	}
	set:vSrcId filter=""
	set minConceptLength = $$$GETPARAM(domainid,$$$IKPMINTOPCONCEPTLENGTH,$$$IKPDEFMINTOPCONCEPTLENGTH)
	
	// filtering options:
	// 	- entUniFreq: loop through domain-wide EntUniFreq global and check each entry against the filter
	//			cost = 
	//  - localEntUniFreq: build a new EntUniFreq for the filtered sources using the domain-wide freqs and loop through
	//  - flattenFirst: go through all EOs satisfying the filter and recalc freq/spread on the fly
	if $isobject(filter) {
		if (filter.Selectivity && usePaging) {
			// basic global reads from entUniFreq
			$$$IKCADD("entUniFreq",page*pagesize*(1/filter.Selectivity)*$$$IKCSEQ("EntUniFreq"))
			$$$IKCADD("localEntUniFreq", page*pagesize)
			
			// localEntUniFreq build
			$$$IKCADD("localEntUniFreq", filter.FilteredSourceCount*..GetMaxOffset(domainid,$$$IKFENTUNI)*$$$IKCSEQ("SrcToEntUniBit"))
			
			// recalculation
			set entsToRecalc = $s($$$CHECKFILTERSORT(filter,filtermode):page*pagesize, 1:pagesize)
			if $$$CHECKFILTERFREQ(filter,filtermode) { $$$IKCADD("entUniFreq", entsToRecalc*$$$IKCFILTERFREQ(filtermode)) }
			if $$$CHECKFILTERFREQ(filter,filtermode) { $$$IKCADD("localEntUniFreq", entsToRecalc*$$$IKCFILTERFREQ(filtermode)) }
			if $$$CHECKFILTERSPREAD(filter,filtermode) { $$$IKCADD("entUniFreq", entsToRecalc*$$$IKCFILTERSPREAD(filtermode)) }
			if $$$CHECKFILTERSPREAD(filter,filtermode) { $$$IKCADD("localEntUniFreq", entsToRecalc*$$$IKCFILTERSPREAD(filtermode)) }
		}
		
		$$$IKCADD("flattenFirst", filter.FilteredSourceCount*$$$IKCSEQ("SrcDetails"))
		$$$IKCADD("flattenFirst", ..GetMaxId(domainid,$$$IKFENTOCC)*filter.Selectivity*$$$IKCSEQ("EntOccId"))
	} else {
		$$$IKCADD("entUniFreq",0)
	} 
	$$$IKCLOWEST(tLowestCostPath)
	
	
	//Below path selection is based on experiments recorded in confluence page called iKnow+Performance+Metrics
	//If the option is $$$FILTERFREQANDSORT) or $$$FILTERALLANDSORT,some critiria would be applied based on our internal experiments.
	//+HSU191
	if $isobject(filter){
		set filterSize = filter.FilteredSourceCountGet()
		set domainSize = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(domainid)
		set ratio = (filterSize + 0.001) / (domainSize + 0.001)
		set topK = page * pagesize
		set threshold = $ZSQR(topK) / ratio
		
		if (filtermode = $$$FILTERFREQANDSORT) ||(filtermode = $$$FILTERALLANDSORT)
		{
			if topK > 100{
				set correctPath = "flattenFirst"
			}
			elseif domainSize <= 1000000{
				set correctPath = "entUniFreq"
			}
			else{
				// 13 is the magic number based on the experiments.
				if threshold >= 13 {
					set correctPath = "flattenFirst"
				}
				else{
					set correctPath = "entUniFreq"
				}
			}
			set tLowestCostPath = correctPath
		}
	}
	//-HSU191
	
	if 'vSrcId {
		set tGlobs = $select(tLowestCostPath="localEntUniFreq":$s(pUseStems:$$$IKBSTEMUNIDET, 1:$$$IKBENTUNIDET),
								tLowestCostPath="entUniFreq":$s(pUseStems:$s(sorttype=$$$SORTBYFREQUENCY:$$$IKBSTEMUNIFREQ, 1:$$$IKBSTEMUNISPREAD),
									1:$s(sorttype=$$$SORTBYFREQUENCY:$$$IKBENTUNIFREQ, 1:$$$IKBENTUNISPREAD)), 
									1:"")
		set:tGlobs'="" tGlobs=$lb(tGlobs)
		set:'$isobject(filter)||'$$$CHECKFILTERFREQ(filter,filtermode)||'$$$CHECKFILTERSPREAD(filter,filtermode) tGlobs = tGlobs _ $lb($s(pUseStems:$$$IKBSTEMUNIDET, 1:$$$IKBENTUNIDET))
		$$$IKQBCHECKX(domainid,tGlobs,tSC)
	}
	
	set entUniDetailsGlo = $$$IKVGLOBNAME(domainid,$s(pUseStems:"StemUniDetails", 1:"EntUniDetails"),vSrcId)
	set entUniIdGlo = $$$IKVGLOBNAME(domainid,$s(pUseStems:"StemUniId", 1:"EntUniId"),vSrcId)
	
	if (tLowestCostPath = "flattenFirst") {
		
		// "flatten" first by gathering ALL entities for this filter
		if ($$$CHECKFILTERSORT(filter,filtermode)) {
			set tSC = ..GetByFilterInternal("^||%IK.GetTopEntitiesFSort", domainid, filter, filtermode, enttype, skipListIds, sorttype, pUseStems, 1)
		} else {
			set tSC = ..GetByFilterInternal(.result, domainid, filter, filtermode, enttype, skipListIds, -1, pUseStems, 1)
			
			// BDB347 - fix paging issue with "flattenFirst" code path
			if (usePaging) {
				for i = 0:1:first-1 {
					if $g(result)'="" { kill @result@(i) } else { kill result(i) }
				}
				set end = $s($g(result)'="":$order(@result@(""),-1), 1:$order(result(""),-1))
				for i = last+1:1:end {
					if $g(result)'="" { kill @result@(i) } else { kill result(i) }
				}
			}
		}
		quit:$$$ISERR(tSC)
		
	} else {
		
		// for highly selective filters, build a shortlist of entities to look at
		set tFilterType = $s(pUseStems:$$$IKFSTEMUNI, 1:$$$IKFENTUNI)
		if (tLowestCostPath="localEntUniFreq") {
			//$$$IKQTIC("BuildLocalSortedGlob")
			$$$IKSORTBEGIN(^||%IK.EntUniSort)
		
			// start building a shortlist by looping through the EUs satisfying the filter
			set offset = ""
			for {
				set offset = filter.GetNextFilterOffset(tFilterType, offset, .entUniBits)
				quit:offset=""
			
				set pos = 0
				for {
					set pos = $bitfind(entUniBits, 1, pos+1)
					quit:'pos
				
					$$$IKGETIDOFFPOS(entUniId,offset,pos)
				
					continue:'entUniId
					continue:$$$IKISSKIPLISTED(entUniId)
				
					set details = $g(@entUniDetailsGlo@(entUniId))
					if (sorttype = $$$SORTBYFREQUENCY) {
						set sortVal = $lg(details, $case(enttype, $$$ENTTYPECONCEPT:1, $$$ENTTYPERELATION:2))
					} else { 
						set sortVal = $lg(details, $case(enttype, $$$ENTTYPECONCEPT:4, $$$ENTTYPERELATION:5))
					}
					continue:'sortVal
				
					set ^||%IK.EntUniSort(-sortVal, entUniId) = ""
				}
			}
		
			set tSCx = $sortend(^||%IK.EntUniSort)
			set entUniSortGlo = "^||%IK.EntUniSort"
			//$$$IKQTOC("BuildLocalSortedGlob")
		} else {
		
			// derive proper sorting global
			if (vSrcId) {
				$$$CHECKVSRCIDEXISTSX(domainid,vSrcId,tSC)
				set entUniSortGlo = "^IRIS.IKV."_$s(pUseStems:"Stem", 1:"Ent")_"UniIdFreq("_domainid_","_vSrcId_","_enttype_")"
				set filter="", filtermode = 0, sorttype = $$$SORTBYFREQUENCY
			} else {
				if '$lf($lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD),sorttype) { set tSC = $$$ERROR($$$InvalidArgument, "sorttype")  quit }
				set entUniSortGlo = "^IRIS.IK."_$s(pUseStems:"Stem", 1:"Ent")_"UniId"_$s(sorttype=$$$SORTBYFREQUENCY:"Freq", 1:"Spread")_"("_domainid_","_enttype_")"
			}
		}
	
		// for post-filter resorting, we have to track how many entries
		// are certainly inside the desired page
		set entriesWithinPage = 0

		// loop through the appropriate top sorted global
		set sortOrder = ""
		for {
			set sortOrder = $order(@entUniSortGlo@(sortOrder))
			quit:'+sortOrder

		
			// when the value for sortOrder changes, we have to verify how many entries
			// are certainly within the desired page boundary
			if (usePaging && $$$CHECKFILTERSORT(filter,filtermode)) {
				set entriesWithinPage = 0
				set sortCheck = ""
				for {
					set sortCheck = $order(^||%IK.GetTopEntitiesFSort(sortCheck))
					quit:sortCheck=""
		
					// sort order is negative, so sortCheck < sortOrder means this entry
					// in the current result list is certainly in the final results as
					// sortOrder can only increase
					if (sortCheck < sortOrder) {
						set ii = ""
						for{
							set ii = $o(^||%IK.GetTopEntitiesFSort(sortCheck,ii))
							quit:'ii
							set entriesWithinPage = entriesWithinPage + 1
						}
					} else {
						quit
					}
				}
				if (entriesWithinPage > last) {
					quit
				}
			}

			// loop through the entities at this sortOrder
			set entId = ""
			for {
				set entId = $order(@entUniSortGlo@(sortOrder, entId))
				quit:entId=""
	
				continue:$$$IKISSKIPLISTED(entId)
	
				// skip short concepts (configured through $$$IKPMINTOPCONCEPTLENGTH)
				continue:(enttype=$$$ENTTYPECONCEPT)&&($length(@entUniIdGlo@(entId))<minConceptLength)
	
				// check if the entity satisfies the filter and recalc freq/spread if required
				set filteredSpread = 0
				set filteredFreq = 0
				if ($isobject(filter)) {
					
					if $$$CHECKFILTERFREQ(filter,filtermode) {
						//$$$IKQTIC("FilterFreq")
						if pUseStems {
							set filteredFreq = filter.GetFilteredStemFrequency(entId, enttype)
						} else {
							set filteredFreq = filter.GetFilteredEntityFrequency(entId, enttype)
						}
						//$$$IKQTOC("FilterFreq")
						continue:'filteredFreq
					}
					if $$$CHECKFILTERSPREAD(filter,filtermode) {
						//$$$IKQTIC("FilterSpread")
						if pUseStems {
							set filteredSpread = filter.GetFilteredStemSpread(entId, enttype)
						} else {
							set filteredSpread = filter.GetFilteredEntitySpread(entId, enttype)
						}
						//$$$IKQTOC("FilterSpread")
						continue:'filteredSpread
					}
					if $$$CHECKFILTERONLY(filtermode) {
						// first try IsFiltered() and only then use enttype if we're sure
						// the entity appears at least once
						continue:'filter.IsFiltered(entId, tFilterType)
						if pUseStems {
							continue:'filter.GetFilteredStemFrequency(entId, enttype)
						} else {
							continue:'filter.GetFilteredEntityFrequency(entId, enttype)
						}
					}
				}
	
				// this is a valid entry, so increase count
				set count = count + 1
	
				// check if we're in the paging window
				$$$IKCHECKPAGINGSORT(usePaging,first,last,count,filter,filtermode,entriesWithinPage)
				
				// retrieve and "correct" frequency info
				if (vSrcId) {
					set details = @entUniDetailsGlo@(entId)
					set freq = $lg(details, $select(enttype=$$$ENTTYPECONCEPT:1, enttype=$$$ENTTYPERELATION:2))
					set spread = 1
				} else {
					set details = ""
					if ($$$CHECKFILTERFREQ(filter,filtermode)) {
						set freq = filteredFreq
					} else {
						set details = @entUniDetailsGlo@(entId)
						set freq = $lg(details, $select(enttype=$$$ENTTYPECONCEPT:1, enttype=$$$ENTTYPERELATION:2))
					}
					if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
						set spread = filteredSpread
					} else {
						set:details="" details = @entUniDetailsGlo@(entId)
						set spread = $lg(details, $select(enttype=$$$ENTTYPECONCEPT:4, enttype=$$$ENTTYPERELATION:5))
					}
				}
	
				// build the topEntity data 
				set tEntValue = ..GetValueInternal(domainid,entId,vSrcId,pUseStems)
				set topEntity =  $lb(+entId, tEntValue, freq, spread)
							
				// store the topEntity in the appropriate global
				if ($$$CHECKFILTERSORT(filter,filtermode)) {
			
					// derive sort attribute
					if (sorttype=$$$SORTBYFREQUENCY) {
						set topSortOrder = -freq
					} elseif (sorttype = $$$SORTBYSPREAD) {
						set topSortOrder = -spread
					}
		
					// update entriesWithinPage if the current entry is certainly within
					// the end result page, which is the case if the filtered sort order
					// is already smaller then the best possible unfiltered sort order
					// we're looking at
					if (usePaging) {
						if (topSortOrder < sortOrder) {
							set entriesWithinPage = entriesWithinPage + 1
						}
					}
	
					// store topEntity in utility global
					set ^||%IK.GetTopEntitiesFSort(topSortOrder, $i(^||%IK.GetTopEntitiesFSort)) = topEntity
		
					$$$IKCHECKPAGING(usePaging,0,last,entriesWithinPage)
		
				} else {
		
					$$$IKQADDRESULT(result,count,topEntity)
			
				}
										
			}
			$$$IKCHECKPAGINGSORT(usePaging,0,last,count,filter,filtermode,entriesWithinPage)
		}
	}
	
	// if applicable, resort the results
	$$$IKQRESORTRESULT(filter,filtermode,result,"^||%IK.GetTopEntitiesFSort",usePaging,first,last,tSC)
	
	$$$IKCLEANSKIPLIST
	$$$IKQENDCATCH(result,"^||%IK.GetTopEntitiesFSort,^||%IK.GetTopEntitiesEOBits,^||%IK.EntUniSort",tSC)
}

///  <p>Returned column summary for <method>GetByFilter</method>.</p>
Parameter GetByFilterRT = "entUniId:%Integer,entity:%String,frequency:%Integer,spread:%Integer";

///  <p>Returns all entities appearing in any source satisfying the supplied <var>filter</var> 
///  objects criteria, with their frequencies and spread recalculated to comply with the filter
///  depending on the value of <var>filtermode</var>, but the result is NOT re-sorted, regardless
///  of the value for <var>filtermode</var> (use <method>GetTop</method> if you want sorted results).</p>
///  <p>Depending on the value of <var>enttype</var> parameter, this method will only return concepts
///  ($$$ENTTYPECONCEPT, default), relations ($$$ENTTYPERELATION) or both ($$$ENTTYPEANY).</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetByFilter(ByRef result, domainid As %Integer, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, enttype As %Integer = {$$$ENTTYPECONCEPT}, skipListIds As %List = "", pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	$$$IKBUILDSKIPLIST(domainid,skipListIds,0,pUseStems)
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	} 
	
	set tSC = ..GetByFilterInternal(.result, domainid, filter, filtermode, enttype, skipListIds, -1, pUseStems)
	
	$$$IKQENDCATCH(result,"",tSC)
}

///  sortIndex = -1 means regular output, otherwise an additional first subscript will be introduced
///  to sort by frequency ($$$SORTBYFREQUENCY) or spread ($$$SORTBYSPREAD): result(-sort, entUniId)
///  WARNING: for internal use only, no input checking is performed and Skiplists must have been set up!
ClassMethod GetByFilterInternal(ByRef result, domainid As %Integer, filter As %iKnow.Filters.Filter, filtermode As %Integer = {$$$FILTERONLY}, enttype As %Integer = {$$$ENTTYPECONCEPT}, skipListIds As %List = "", sortIndex As %Integer = -1, pUseStems As %Boolean = 0, pTopConcepts As %Boolean = 0) As %Status [ Internal ]
{
	$$$IKQCLEARPPGS("^||%IK.Ents,^||%IK.EntsSpread")
	quit:'$isobject(filter) $$$OK
	set type = $case(enttype, $$$ENTTYPEANY:$$$IKFENTUNI, $$$ENTTYPECONCEPT:$$$IKFENTOCCC, $$$ENTTYPERELATION:$$$IKFENTOCCR)
	quit:$$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) ..GetByFilterInternal20121(.result, domainid, filter, filtermode, enttype, skipListIds, sortIndex)
	
	set tSC = $$$OK
	if ('$$$CHECKFILTERFREQ(filter,filtermode) || '$$$CHECKFILTERSPREAD(filter,filtermode)) {
		$$$IKQBCHECKR(domainid,$s(pUseStems:$$$IKBSTEMUNIDET, 1:$$$IKBENTUNIDET),tSC,tSC)
	}
	
	// BDB793
	if pTopConcepts {
		set tMinLength = $$$GETPARAM(domainid,$$$IKPMINTOPCONCEPTLENGTH,$$$IKPDEFMINTOPCONCEPTLENGTH)
	}
	
	set gEntSrcDetails = "^IRIS.IK."_$s(pUseStems:"Stem", 1:"Ent")_"SrcDetails"
	set gEntUniDetails = "^IRIS.IK."_$s(pUseStems:"Stem", 1:"Ent")_"UniDetails"
		
	set srcOffset = ""
	for {
		set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
		quit:srcOffset=""
		
		set srcPos = 0
		for {
			set srcPos = $bitfind(srcBits,1,srcPos+1)
			quit:srcPos=0
			
			$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
			
			set entUniId = ""
			for {
				set entUniId = $order(@gEntSrcDetails@(domainid, srcId, entUniId),1,details)
				quit:entUniId=""
				continue:$$$IKISSKIPLISTED(entUniId)
			
				set conceptFreq = $lg(details,1), relFreq = $lg(details,2)
				if (enttype=$$$ENTTYPECONCEPT) {
					continue:'conceptFreq
					set freq = conceptFreq
				} elseif (enttype=$$$ENTTYPERELATION) {
					continue:'relFreq
					set freq = relFreq
				} else {
					set freq = relFreq + conceptFreq
				}
			
				set:$$$CHECKFILTERONLY(filtermode) ^||%IK.Ents(entUniId) = ""
				set:$$$CHECKFILTERFREQ(filter,filtermode) x = $i(^||%IK.Ents(entUniId), freq)
				set:$$$CHECKFILTERSPREAD(filter,filtermode) x = $i(^||%IK.EntsSpread(entUniId))
			}
		}
	}
	
	set entUniId = "", i=0, globName = $s($$$CHECKFILTERFREQ(filter,filtermode)||$$$CHECKFILTERONLY(filtermode):"^||%IK.Ents", 1:"^||%IK.EntsSpread")
	for {
		set entUniId = $order(@globName@(entUniId),1,freq)
		quit:entUniId=""
		
		if ('$$$CHECKFILTERFREQ(filter,filtermode) || '$$$CHECKFILTERSPREAD(filter,filtermode)) {
			set details = @gEntUniDetails@(domainid, entUniId)
		}
		
		if ($$$CHECKFILTERFREQ(filter,filtermode)) {
			do filter.SaveFilteredFrequency($s(pUseStems:-type, 1:type), entUniId, freq)
		} else {
			set freq = $case(enttype, $$$ENTTYPECONCEPT:$li(details,1), $$$ENTTYPERELATION:$li(details,2), $$$ENTTYPEANY:$li(details,1)+$li(details,2))
		}
		if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
			set spread = ^||%IK.EntsSpread(entUniId)
			do filter.SaveFilteredSpread($s(pUseStems:-type, 1:type), entUniId, spread)
		} else {
			set spread = $li(details, $case(enttype, $$$ENTTYPECONCEPT:4, $$$ENTTYPERELATION:5, $$$ENTTYPEANY:3))
		}
		
		set tEntValue = ..GetValueInternal(domainid, entUniId, 0, pUseStems)
		
		// BDB793
		continue:pTopConcepts&&($l(tEntValue)<tMinLength)
		
		if (sortIndex<0) {
			$$$IKQADDRESULT(result,$i(i),$lb(+entUniId,tEntValue,freq,spread))
		} else {
			set sort = $case(sortIndex, $$$SORTBYFREQUENCY:freq, $$$SORTBYSPREAD:spread)
			if ($g(result)="") {
				set result(-sort, entUniId) = $lb(+entUniId,tEntValue,freq,spread)
			} else {
				set @result@(-sort, entUniId) = $lb(+entUniId,tEntValue,freq,spread)
			}
		}
	}
	$$$IKQCLEARPPGS("^||%IK.Ents,^||%IK.EntsSpread")
	quit $$$OK
}

ClassMethod GetByFilterInternal20121(ByRef result, domainid As %Integer, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, enttype As %Integer = {$$$ENTTYPECONCEPT}, skipListIds As %List = "", sortIndex As %Integer = -1) As %Status [ Internal ]
{
	$$$IKQCLEARPPGS("^||%IK.Ents,^||%IK.EntRanges,^||%IK.EntsForSrc,^||%IK.EntsSpread")
	set type = $case(enttype, $$$ENTTYPEANY:$$$IKFENTUNI, $$$ENTTYPECONCEPT:$$$IKFENTOCCC, $$$ENTTYPERELATION:$$$IKFENTOCCR)
	
	$$$IKSORTBEGIN(^||%IK.EntRanges)
	set srcOffset = ""
	for {
		set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
		quit:srcOffset=""
		
		set srcPos = 0
		for {
			set srcPos = $bitfind(srcBits,1,srcPos+1)
			quit:srcPos=0
			
			$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
			set srcDetails = $g(^IRIS.IK.SrcDetails(domainid,srcId))
			continue:srcDetails=""
			
			set eoBase = $li(srcDetails,3)
			set eoCount = $li(srcDetails,4)
			set eoFrom = eoBase+1, eoTo = eoBase+eoCount
			set ^||%IK.EntRanges(eoFrom) = eoTo
		}
	}
	set x = $sortend(^||%IK.EntRanges)
	
	set eoFrom = ""
	for {
		set eoFrom = $order(^||%IK.EntRanges(eoFrom), 1, eoTo)
		quit:eoFrom=""
		
		kill ^||%IK.EntsForSrc
		for entOccId = eoFrom:1:eoTo {
			set eo = ^IRIS.IK.EntOccId(domainid,entOccId)
			set entUniId = $li(eo,1), role = $li(eo,2)
			
			continue:$$$IKISSKIPLISTED(entUniId)
			
			if (enttype'=$$$ENTTYPEANY) {
				continue:(enttype'=role)
			}
			
			set:$$$CHECKFILTERONLY(filtermode) ^||%IK.Ents(entUniId) = ""
			set:$$$CHECKFILTERFREQ(filter,filtermode) x = $i(^||%IK.Ents(entUniId))
			set:$$$CHECKFILTERSPREAD(filter,filtermode) x = $i(^||%IK.EntsForSrc(entUniId))
		}
		
		if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
			set entUniId = ""
			for {
				set entUniId = $order(^||%IK.EntsForSrc(entUniId))
				quit:entUniId=""
			
				set x = $i(^||%IK.EntsSpread(entUniId))
			}
		}
	}
		
	set entUniId = "", i=0, globName = $s($$$CHECKFILTERFREQ(filter,filtermode)||$$$CHECKFILTERONLY(filtermode):"^||%IK.Ents", 1:"^||%IK.EntsSpread")
	for {
		set entUniId = $order(@globName@(entUniId),1,freq)
		quit:entUniId=""
		
		if ('$$$CHECKFILTERFREQ(filter,filtermode) || '$$$CHECKFILTERSPREAD(filter,filtermode)) {
			set details = ^IRIS.IK.EntUniDetails(domainid, entUniId)
		}
		
		if ($$$CHECKFILTERFREQ(filter,filtermode)) {
			do filter.SaveFilteredFrequency(type, entUniId, freq)
		} else {
			set freq = $li(details,1)
		}
		if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
			set spread = ^||%IK.EntsSpread(entUniId)
			do filter.SaveFilteredSpread(type, entUniId, spread)
		} else {
			set spread = $li(details,2)
		}
		
		set data = $lb(+entUniId, ..GetValueInternal(domainid,entUniId), freq, spread)
		if (sortIndex<0) {
			$$$IKQADDRESULT(result,$i(i),data)
		} else {
			set sort = $case(sortIndex, $$$SORTBYFREQUENCY:freq, $$$SORTBYSPREAD:spread)
			if ($g(result)="") {
				set result(-sort, entUniId) = data
			} else {
				set @result@(-sort, entUniId) = data
			}
		}
	}
	
	$$$IKQCLEARPPGS("^||%IK.Ents,^||%IK.EntRanges,^||%IK.EntsForSrc,^||%IK.EntsSpread")
	quit $$$OK
}

///  <p>Returned column summary for <method>GetBySource</method>.</p>
Parameter GetBySourceRT = "entUniId:%Integer,entity:%String,frequency:%Integer,spread:%Integer";

///  <p>Returns the unique entities appearing in the sources specified.</p>
///  <p>To get the unique entities of a virtual source, only a single virtual source can be supplied using
///  its negative ID value.</p>
ClassMethod GetBySource(ByRef result, domainid As %Integer, sourceidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, enttype As %Integer = {$$$ENTTYPEANY}, skipListIds As %List = "", pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.EntsBySrc,^||%IK.EntsBySrcSpread",tSC)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	if (sourceidlist="") { set tSC = $$$ERROR($$$InvalidArgument)  quit }
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	} 
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// check if looking for a virtual source
	if ($li(sourceidlist)<0) && ($ll(sourceidlist)=1) {
		set vSrcId = -$li(sourceidlist,1)
		$$$IKBUILDSKIPLIST(domainid,skipListIds,vSrcId,pUseStems)
		$$$CHECKVSRCIDEXISTSX(domainid,vSrcId,tSC)
		
		set gEntUniDetails = "^IRIS.IKV."_$s(pUseStems:"Stem", 1:"Ent")_"UniDetails"
			
		set entUniId = ""
		for {
			set entUniId = $order(@gEntUniDetails@(domainid, vSrcId, entUniId), 1, details)
			quit:entUniId=""
			
			continue:$$$IKISSKIPLISTED(entUniId)
			
			set tFreq = $case(enttype, $$$ENTTYPECONCEPT:$lg(details,1), $$$ENTTYPERELATION:$lg(details,2), :$lg(details,1)+$lg(details,2))
			continue:'tFreq
			
			set count=$i(count)
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			set tEntValue = ..GetValueInternal(domainid, entUniId, vSrcId, pUseStems)
			$$$IKQADDRESULT(result,count,$lb(+entUniId, tEntValue, tFreq, 1))
		}
		quit
	}
	
	$$$IKBUILDSKIPLIST(domainid,skipListIds,0,pUseStems)
	
	set tVersion20121 = $$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122)
	
	set ptr=0, srcId=0
	while $listnext(sourceidlist,ptr,srcId) {
		continue:srcId=""
		quit:srcId<0 // vSrcId where we don't want them, exit
		
		if tVersion20121 {
		
			// for v1, we'll build the list for the real sources based on ^IRIS.IK.EntOccId
			set srcDetails = $g(^IRIS.IK.SrcDetails(domainid, srcId))
			continue:srcDetails=""
			set eoFrom = $li(srcDetails,3)+1
			set eoTo = $li(srcDetails,3)+$li(srcDetails,4)
		
			for eoId = eoFrom:1:eoTo { 
				set eo = ^IRIS.IK.EntOccId(domainid, eoId)
				
				set tEntType = $li(eo,2)
				continue:tEntType=$$$ENTTYPENONREL // BDB577
				continue:(enttype'=$$$ENTTYPEANY)&&(tEntType'=enttype)
			
				set euId = $li(eo,1)
				continue:$$$IKISSKIPLISTED(euId)
				
				set x = $i(tEntsBySrc(euId))
				set tEntsBySrcSpread(euId,srcId)=""
			}
			
		} else {
			
			// in v2 and beyond, we can use ^IRIS.IK.EntSrcDetails
			if (pUseStems) {
				merge tEntSrcDetails = ^IRIS.IK.StemSrcDetails(domainid,srcId)
			} else {
				merge tEntSrcDetails = ^IRIS.IK.EntSrcDetails(domainid,srcId)
			}
			set entUniId = ""
			for {
				set entUniId = $order(tEntSrcDetails(entUniId),1,details)
				quit:entUniId=""
				continue:$$$IKISSKIPLISTED(entUniId)
				
				set freq = $case(enttype, $$$ENTTYPEANY:$li(details,1)+$li(details,2), $$$ENTTYPECONCEPT:$li(details,1), $$$ENTTYPERELATION:$li(details,2))
				set x = $i(tEntsBySrc(entUniId),freq)
				set x = $i(tEntsBySrcSpread(entUniId))
			}
		}
	}
	
	// if we ran into a negative srcId, return error
	if (srcId<0) { set tSC = $$$ERROR($$$IKOnlyOneVSrcSupported)  quit }

	// now build the result set
	set euId=""
	for {
		set euId = $order(tEntsBySrc(euId),1,freq)
		quit:euId=""
		continue:'freq
	
		set count = $i(count)
		$$$IKCHECKPAGING(usePaging,first,last,count)
	
		if tVersion20121 {
			set srcId = "", spread=0
			for {
				set srcId = $order(tEntsBySrcSpread(euId,srcId))
				quit:srcId=""
				set spread = $i(spread)
			}
		} else {
			set spread = tEntsBySrcSpread(euId)
		}
	
		set tEntValue = ..GetValueInternal(domainid, euId, 0, pUseStems)
		$$$IKQADDRESULT(result,count,$lb(+euId, tEntValue, freq, spread))
	}

	$$$IKCLEANSKIPLIST
	$$$IKQENDCATCH(result,"^||%IK.EntsBySrc,^||%IK.EntsBySrcSpread",tSC)
}

///  <p>Returns the total number of distinct entities for this domain, optionally filtered to a set of
///  sources satisfying the <class>%iKnow.Filters.Filter</class> object supplied through <var>filter</var>.
///  Depending on the value of <var>includeZeroFrequency</var>, entities not appearing in any source (but
///  registered in the domain for other purposes) are included or excluded from the result.</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}, skipListIds As %List = "", includeZeroFrequency As %Boolean = 0, pUseStems As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	set total = 0
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)=0) {
		set sc = $$$ERROR($$$IKStemmingNotEnabled)
		quit -1
	} 
	
	if ($isobject(filter)) {
		$$$IKBUILDSKIPLISTBIT(domainid,skipListIds,pUseStems)
		set tFilterType = $s(pUseStems:$$$IKFSTEMUNI, 1:$$$IKFENTUNI)
		set entOffset = ""
		for {
			set entOffset = filter.GetNextFilterOffset(tFilterType, entOffset, .entBits)
			quit:entOffset=""
			
			set x = $i(total, $bitcount($bitlogic(entBits & ~$$$IKSKIPLISTBITS(entOffset)), 1))
		}
		
	} elseif (includeZeroFrequency) {
		
		$$$IKBUILDSKIPLIST(domainid,skipListIds,0,pUseStems)
		
		set entId = "", gEntUniDetails = "^IRIS.IK."_$s(pUseStems:"Stem",1:"Ent")_"UniDetails"
		for {
			set entId = $order(@gEntUniDetails@(domainid, entId))
			quit:entId=""
			continue:$$$IKISSKIPLISTED(entId)
			
			set x = $i(total)
		}
		
	} elseif $$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) {
		
		$$$IKBUILDSKIPLIST(domainid,skipListIds,0,pUseStems)
		
		set entId = ""
		for {
			set entId = $order(^IRIS.IK.EntUniDetails(domainid, entId),1,details)
			quit:entId=""
			continue:$$$IKISSKIPLISTED(entId)
			continue:'$li(details,3)
			
			set x = $i(total)
		}
	} else {
		$$$IKBUILDSKIPLISTBIT(domainid,skipListIds,pUseStems)
		
		set entOff = "", gEntUniDetails = "^IRIS.IK."_$s(pUseStems:"Stem",1:"Ent")_"UniExistsBit"
		for {
			set entOff = $order(@gEntUniDetails@(domainid, entOff), 1, entBits)
			quit:entOff=""
			
			set x = $i(total, $bitcount($bitlogic(entBits & ~$$$IKSKIPLISTBITS(entOff)),1))
		}
	}
	
	$$$IKCLEANSKIPLIST
	quit total
}

///  <p>Returns the total number of distinct entities for a given list of sources. The count returned either
///  represents the entities appearing in either (with <var>setop</var> $$$UNION) or all (with <var>setop</var>
///  $$$INTERSECT) of the supplied sources. Using <var>enttype</var>, the returned count is
///  filtered to just entities ($$$ENTTYPECONCEPT), relations ($$$ENTTYPERELATION). The default
///  is unfiltered ($$$ENTTYPEANY).</p>
///  <p>To get the unique entities of a virtual source, only a single virtual source can be supplied using
///  its negative ID value (otherwise, -1 is returned).</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %List, setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, skipListIds As %List = "", enttype As %Integer = {$$$ENTTYPEANY}, pUseStems As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("^||%IK.GetTotEntitiesBit",sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)=0) {
		set sc = $$$ERROR($$$IKStemmingNotEnabled)
		quit -1
	} 
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	// simple implementation if we're looking at a virtual source
	if $li(sourceidlist)<0,$ll(sourceidlist)=1 {
		set vSrcId = -$li(sourceidlist,1)
		$$$CHECKVSRCIDEXISTSR(domainid,vSrcId,sc,-1)
		if (skipListIds="") && (enttype=$$$ENTTYPEANY) {
			
			if pUseStems {
				quit $o(^IRIS.IKV.StemUniId(domainid, vSrcId, ""),-1)
			} else {
				quit $o(^IRIS.IKV.EntUniId(domainid, vSrcId, ""),-1)
			}
			
		} else {
			
			$$$IKBUILDSKIPLIST(domainid,skipListIds,vSrcId,pUseStems)
			set vEntUniId = "", count = 0, gEntUniDetails = "^IRIS.IKV."_$s(pUseStems:"Stem",1:"Ent")_"UniDetails"
			for {
				set vEntUniId = $order(@gEntUniDetails@(domainid, vSrcId, vEntUniId),1,tData)
				quit:vEntUniId=""
				continue:$$$IKISSKIPLISTED(vEntUniId)
				if (enttype=$$$ENTTYPEANY) {
					set count = count+1
				} else {
					set count = count + ($li(tData,$s(enttype=$$$ENTTYPECONCEPT:1, 1:2))>0)
				}
			}
			quit count
			
		}
	}
	
	$$$IKBUILDSKIPLISTBIT(domainid,skipListIds,pUseStems)
	
	if (enttype=$$$ENTTYPEANY) {
		$$$IKQBCHECKX(domainid,$lb($s(pUseStems:$$$IKBSRCSTEMUNI, 1:$$$IKBSRCENTUNI)),sc)
	}
	
	// join ^IRIS.IK.SrcToEntUniBit entries for the sources in the list
	for i = 1:1:$listlength(sourceidlist) {
		
		set srcId = $list(sourceidlist, i)
		quit:srcId<0
		continue:'+srcId
		
		if (enttype=$$$ENTTYPEANY) {
			set entOffset = "", gSrcToEntUni = "^IRIS.IK.SrcTo"_$s(pUseStems:"Stem",1:"Ent")_"UniBit"
			for  {
				set entOffset = $order(@gSrcToEntUni@(domainid, srcId, entOffset), 1, entBits)
				quit:entOffset=""
				
				// merge with ^||%IK.GetTotEntitiesBit contents
				if (i = 1) {
					set ^||%IK.GetTotEntitiesBit(entOffset) = entBits
				} else {
					if (setop = $$$UNION) {
						set ^||%IK.GetTotEntitiesBit(entOffset) = $bitlogic(entBits | ^||%IK.GetTotEntitiesBit(entOffset))
					} elseif (setop = $$$INTERSECT) {
						set ^||%IK.GetTotEntitiesBit(entOffset) = $bitlogic(entBits & ^||%IK.GetTotEntitiesBit(entOffset))
					}
				}
			}
		} else {
			
			set tSrcDetails = $g(^IRIS.IK.SrcDetails(domainid,srcId))
			set tPartId = $lg(tSrcDetails,3), tMaxPartId = tPartId+$lg(tSrcDetails,4)
			for {
				set tPartId = $order(^IRIS.IK.EntOccId(domainid,tPartId),1,tEntOcc)
				quit:tPartId=""
				quit:tPartId>tMaxPartId
				
				set tEntType = $lg(tEntOcc,2)
				continue:tEntType=$$$ENTTYPENONREL
				continue:(enttype'=$$$ENTTYPEANY)&&(enttype'=tEntType)
				
				set tEntities($li(tEntOcc,$s(pUseStems:10,1:1)))=""
			}
			
		}
	}
	
	// if we ran into a negative srcId, return error
	if (srcId<0) {
		set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
		quit -1
	}
	
	// now count the remaining 1s
	set total = 0
	if (enttype=$$$ENTTYPEANY) {
		set entOffset = ""
		for {
			set entOffset = $order(^||%IK.GetTotEntitiesBit(entOffset), 1, entBits)
			quit:entOffset=""
			
			set entBits = $bitlogic(entBits & ~$$$IKSKIPLISTBITS(entOffset))
			set total = total + $bitcount(entBits, 1)
		}
	} else {
		set tEntUniId=""
		for {
			set tEntUniId = $order(tEntities(tEntUniId))
			quit:tEntUniId=""
			set total = total+1
		}
	}
	
	$$$IKQEND("^||%IK.GetTotEntitiesBit",total)
}

///  <p>Returns the total number of entity occurrences for the given list of sources. Use negative source
///  IDs to refer to virtual sources.</p>
ClassMethod GetOccurrenceCountBySource(domainid As %Integer, sourceidlist As %List, Output sc As %Status = {$$$OK}, enttype As %Integer = {$$$ENTTYPEANY}) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	
	set tVersionTables = $$$IKVERSIONATLEAST(domainid,$$$IKVERSIONTABLES)
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	set total = 0, ptr = 0
	while $listnext(sourceidlist, ptr, srcId) {
		continue:'+srcId
		$$$CHECKASRCIDEXISTSX(domainid,srcId,srcDetails,vSrcId,sc)
		
		if (enttype = $$$ENTTYPEANY) && 'tVersionTables {
			set total = total + $lg(srcDetails,4)
		} else {
			
			set gEntOccId = $$$IKVGLOBNAME(domainid,"EntOccId",vSrcId)
			set tFrom = $lg(srcDetails,3)+1, tTo = tFrom+$lg(srcDetails,4)-1
			for tPartId = tFrom:1:tTo {
				set tEntOcc = @gEntOccId@(tPartId)
				set tEntType = $lg(tEntOcc,2)
				continue:tEntType=$$$ENTTYPENONREL
				set:(enttype=$$$ENTTYPEANY)||(enttype=tEntType) x = $i(total)
			}
			
		}
	}
	quit:$$$ISERR(sc) -1
	
	quit total
}

///  <p>Returns the total number of entity occurrences in a domain.</p>
ClassMethod GetOccurrenceCountByDomain(pDomainId As %Integer, pFilter As %iKnow.Filters.Filter = "", pEntType As %Integer = {$$$ENTTYPEANY}, Output pSC As %Status = {$$$OK}) As %Integer
{
	$$$IKQBEGINR("",pSC,-1)
	$$$CHECKDOMAINEXISTSR(pDomainId,pSC,-1)
	$$$IKQFILTEROBJECT(pDomainId,pFilter)
	
	set tTotal=0
	
	if $isobject(pFilter) {
		
		set tType = $case(pEntType, $$$ENTTYPEANY:$$$IKFENTOCC, $$$ENTTYPECONCEPT:$$$IKFENTOCCC, $$$ENTTYPERELATION:$$$IKFENTOCCR)
		set tOff = ""
		for {
			set tOff = pFilter.GetNextFilterOffset(tType, tOff, .tBits)
			quit:tOff=""
			
			set x = $i(tTotal,$bitcount(tBits,1))
		}
		
	} elseif (pEntType = $$$ENTTYPEANY) && $$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONTABLES) {
		
		set tSrcId = ""
		for {
			set tSrcId = $order(^IRIS.IK.SrcDetails(pDomainId, tSrcId), 1, tSrcDetails)
			quit:tSrcId=""
			
			set x = $i(tTotal, $lg(tSrcDetails,4))
		}
		
	} else {
		
		set tPartId = ""
		for {
			set tPartId = $order(^IRIS.IK.EntOccId(pDomainId, tPartId), 1, tEntOcc)
			quit:tPartId=""
			
			set tEntType = $li(tEntOcc,2)
			continue:tEntType=$$$ENTTYPENONREL
			continue:(pEntType'=$$$ENTTYPEANY)&&(tEntType'=pEntType)
			set tTotal = tTotal+1
		}
	}
	
	quit tTotal
}

///  <p>Returned column summary for <method>GetRelated</method>.</p>
Parameter GetRelatedRT = "entUniId:%Integer,entity:%String,frequency:%Integer,spread:%Integer";

///  <p>This method will return all entities occurring in a direct relationship with at least on (if <var>setop</var> = $$$UNION)
///  or all (if <var>setop</var> = $$$INTERSECT) of the entities in the supplied <var>entitylist</var>, anywhere within
///  the supplied domain.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <var>filter</var>
///  parameter to restrict the result to those CRCs occurring in any source satisfying the filter
///  criteria. When using a filter, the <var>filtermode</var> parameter will control whether or not the
///  frequency and spread of returned records should be recalculated and whether results should be
///  resorted along these recalculated numbers.</p>
///  <p>Through the <var>positionstomatch</var> parameter, the user can specify whether the entities returned should be
///  occurring on the Head side ($$$USEPOSH), the Tail side ($$$USEPOST) or either ($$$USEPOSHT, default) 
///  side of the relationship.</p>
///  <p>The <var>aggregationtype</var> parameter lets you choose how to aggregate the frequency and spread of results
///  related to multiple entries in the input <var>entitylist</var>.</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
/// <p>Note: this method only returns entities that appear in direct relationships with the seed
/// entity. For the broader context of entities, including indirect relationships (still within
/// a single path), please refer to <class>%iKnow.Semantics.ProximityAPI</class>
ClassMethod GetRelated(ByRef result, domainid As %Integer, entitylist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, aggregationtype As %Integer = {$$$AGGSUM}, setop As %Integer = {$$$UNION}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, skipListIds As %List = "") As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entitylist="" $$$OK
	
	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean array
	set tSC = ..TranslateEntityList(domainid, entitylist, .entIdList)
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetRelatedInternal
	quit ..GetRelatedInternal(.result, domainid, .entIdList, page, pagesize, filter, filtermode, positionstomatch, aggregationtype, setop, sorttype, skipListIds)
}

///  <p>Returned column summary for <method>GetRelatedById</method>.</p>
Parameter GetRelatedByIdRT = "entUniId:%Integer,entity:%String,frequency:%Integer,spread:%Integer";

///  <p>Returns the entities directly related to a supplied list of entity IDs.</p>
///  <p>See <method>GetRelated</method> for a description of the parameters.</p>
ClassMethod GetRelatedById(ByRef result, domainid As %Integer, entityidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, aggregationtype As %Integer = {$$$AGGSUM}, setop As %Integer = {$$$UNION}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, skipListIds As %List = "") As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entityidlist="" $$$OK
	
	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// unravel the entitylist into a clean %List
	set tSC = ..TranslateEntityIdList(domainid, entityidlist, .cleanEntIdList)
	quit:$$$ISERR(tSC)
	
	// forward to GetRelatedInternal
	quit ..GetRelatedInternal(.result, domainid, .cleanEntIdList, page, pagesize, filter, filtermode, positionstomatch, aggregationtype, setop, sorttype, skipListIds)
}

ClassMethod GetRelatedInternal(ByRef result, domainid As %Integer, ByRef entIdList, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, filtermode As %Integer, positionstomatch As %Integer, aggregationtype As %Integer, setop As %Integer, sorttype As %Integer, skipListIds As %List) As %Status [ Internal ]
{
	quit:$$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) ..GetRelatedInternal20121(.result, domainid, .entIdList, page, pagesize, filter, filtermode, positionstomatch, aggregationtype, setop, sorttype, skipListIds)
	
	$$$IKQBEGINTRY(result,"^||%IK.GetRelSort,^||%IK.GetRelTrack,^||%IK.GetRelCands,^||%IK.HeadBits,^||%IK.TailBits",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	$$$IKCHECKSORTTYPEX(domainid,sorttype,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD),tSC)
	quit:'entIdList
	
	$$$IKBUILDSKIPLIST(domainid,skipListIds,0,0)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// define sort type
	if (sorttype="") || (sorttype = $$$SORTBYDOMAINDEFAULT) {
		set sorttype = $$$SORTFIELD(domainid)
	}
	
	// TODO: cost calculation, evt build local ccSortGlo
	
	// available approaches:
	//	- go through CcCombiFreq and verify if pos is met
	//  - if pos=USEPOSH or USEPOST, go through CcEntUniFreq instead
	
	
	set ccSortGlo = "^IRIS.IK.CcEntCombi"_$s(sorttype=$$$SORTBYFREQUENCY:"Freq", 1:"Spread")_"("_domainid_")"
	
	// simplified access path for simple input
	if (entIdList=1) {
		
		set tGlobs = $lb($s(sorttype=$$$SORTBYFREQUENCY:$$$IKBCCENTFREQ, 1:$$$IKBCCENTSPREAD))
		set:'$$$CHECKFILTERFREQ(filter,filtermode)||'$$$CHECKFILTERSPREAD(filter,filtermode) tGlobs = tGlobs _ $lb($$$IKBCCUNIDET)
		$$$IKQBCHECKX(domainid,tGlobs,tSC)
		
		set entId = $order(entIdList(""))
		quit:'entId
		
		set entriesWithinPage = 0
		
		// loop through sortOrders
		set sortOrder=""
		for {
			set sortOrder = $order(@ccSortGlo@(entId, sortOrder))
			quit:'+sortOrder
			
			// if we're resorting, check if we can already stop because the next sortOrder
			// would already fall out of the paging window given the results in 
			// ^||%IK.GetRelSort
			if $$$CHECKFILTERSORT(filter,filtermode) {
				$$$IKQENTRIESWITHINPAGE(^||%IK.GetRelSort,sortOrder,usePaging,last,entriesWithinPage)
			}
			
			// loop through CCs for this sortOrder
			set ccId = ""
			for {
				set ccId = $order(@ccSortGlo@(entId, sortOrder, ccId),1,otherEntId)
				quit:ccId=""
				
				set entIdIsHead = (otherEntId>0)
				set entIdIsTail = (otherEntId<0) || (otherEntId=-entId)
				
				set posMatched = ($$$CHECKPOSM(positionstomatch) && entIdIsHead)
				set posMatched = posMatched + ($$$CHECKPOSS(positionstomatch) && entIdIsTail)
				continue:'posMatched
				
				set otherEntId = $zabs(otherEntId)
				continue:$$$IKISSKIPLISTED(otherEntId)
				continue:$d(^||%IK.GetRelTrack(otherEntId))
				set ^||%IK.GetRelTrack(otherEntId) = ""
				
				if $$$CHECKPOSM(positionstomatch) && $$$CHECKPOSS(positionstomatch) {
					set ikfType = $$$IKFCCCOMBI
				} else {
					set ikfType = $$$IKFCCUNI
				}
				
				if $isobject(filter) {
					continue:'filter.IsFiltered(ccId, ikfType)
				}
				
				set x = $i(count)
				$$$IKCHECKPAGINGSORT(usePaging,first,last,count,filter,filtermode,entriesWithinPage)
				
				set details = $lb(0,0)
				if '$$$CHECKFILTERFREQ(filter,filtermode) || '$$$CHECKFILTERFREQ(filter,filtermode) {
					set details = ^IRIS.IK.CcUniDet(domainid, ccId)
					if (ikfType=$$$IKFCCCOMBI) && (entId'=otherEntId) {
						set otherCcId = +##class(%iKnow.Queries.CcAPI).GetInverse(domainid, ccId)
						if (otherCcId) {
							set otherDetails = ^IRIS.IK.CcUniDet(domainid, otherCcId)
							set details = $lb($li(details,1)+$li(otherDetails,1),$li(details,2)+$li(otherDetails,2))
						}
					}
				}
				
				if $$$CHECKFILTERFREQ(filter,filtermode) {
					set $li(details,1) = filter.GetFilteredCcFrequency(ccId, ikfType)
				}
				if $$$CHECKFILTERSPREAD(filter,filtermode) {
					set $li(details,2) = filter.GetFilteredCcSpread(ccId, ikfType)
				}
	
				// build the result data 
				set tEntValue = ..GetValueInternal(domainid, otherEntId, 0)
				set entry =  $lb(otherEntId, tEntValue) _ details
				
				if $$$CHECKFILTERSORT(filter,filtermode) {
					set entryOrder = -$li(details, $s((sorttype=$$$SORTBYFREQUENCY):1, 1:2))
					$$$IKQADDRESULTSORT(^||%IK.GetRelSort,entryOrder,entry)	
					if (usePaging) {
						if (entryOrder<sortOrder) { set entriesWithinPage = entriesWithinPage+1 }
						quit:entriesWithinPage>last
					}
				} else {
					$$$IKQADDRESULT(result,count,entry)
				}
			}
		}
		
	} else {
		
		// as more elegant approaches trying to start from CcEntCombiFreq would require a lot
		// of additional random reads along the way, it's probably simplest and safest to go
		// with a brute-force approach
		
		set tGlobs = $lb($$$IKBCCUNIMAP)
		set:'$$$CHECKFILTERFREQ(filter,filtermode)||'$$$CHECKFILTERFREQ(filter,filtermode) tGlobs = tGlobs _ $lb($$$IKBCCUNIDET)
		$$$IKQBCHECKX(domainid,tGlobs,tSC)
		
		set globsFrom("M") = "EntUniMToCcUniBit", globsFrom("S") = "EntUniSToCcUniBit"
		set globsTo("M") = "^||%IK.HeadBits", globsTo("S") = "^||%IK.TailBits"
	
		for mode = "M","S" {
		
			if (mode="M") {
				continue:'$$$CHECKPOSM(positionstomatch)
			} else {
				continue:'$$$CHECKPOSS(positionstomatch)
			}
		
			// now loop through all supplied entIds
			set entId = ""
			for {
				set entId = $order(entIdList(entId))
				quit:entId=""
			
				set gloFrom = "^IRIS.IK."_globsFrom(mode)_"("_domainid_","_entId_")"
				$$$IKMERGEBITSOR(gloFrom,globsTo(mode))
			}
	
			// now we'll have to filter these CCs and translate them to entities
			set off=""
			for {
				set off = $order(@globsTo(mode)@(off), 1, ccBits)
				quit:off=""
		
				if $isobject(filter) {
					set filterBits = filter.GetCcUniqueFilter(off)
					set ccBits = $bitlogic(ccBits & filterBits)
				}
	
				set pos = 0
				for {
					set pos = $bitfind(ccBits, 1, pos+1)
					quit:pos=0
		
					$$$IKGETIDOFFPOS(ccId,off,pos)
				
					set cc = ^IRIS.IK.CcUniId(domainid, ccId)
					set entId = $li(cc, $s(mode="M":1, 1:2))
					set otherEntId = $li(cc, $s(mode="M":2, 1:1))
				
					continue:$$$IKISSKIPLISTED(otherEntId)
				
					set ^||%IK.GetRelCands(otherEntId) = $g(^||%IK.GetRelCands(otherEntId))_$lb($lb(entId,ccId))
				}
			}
		}
	
		// now loop over the candidates, gather their frequencies and store in ^||%IK.GetRelSort
		set otherEntId = ""
		for {
			set otherEntId = $order(^||%IK.GetRelCands(otherEntId), 1, ccList)
			quit:otherEntId=""
			
			set aggFreq=0, aggSpread=0, ptr=0
			kill ents
			while $listnext(ccList,ptr,ccData) {
				set entId = $li(ccData,1), ccId = $li(ccData,2)
				
				if '$$$CHECKFILTERFREQ(filter,filtermode) || '$$$CHECKFILTERSPREAD(filter,filtermode) {
					set ccDetails = $g(^IRIS.IK.CcUniDet(domainid, ccId))
				}
				
				set freq = $s($$$CHECKFILTERFREQ(filter,filtermode):filter.GetFilteredCcFrequency(ccId, $$$IKFCCUNI), 1:$lg(ccDetails,1))
				set spread = $s($$$CHECKFILTERSPREAD(filter,filtermode):filter.GetFilteredCcSpread(ccId, $$$IKFCCUNI), 1:$lg(ccDetails,2))
				
				set:'$d(ents(entId)) ents(entId) = $i(ents)
				if (aggregationtype=$$$AGGMIN) {
					set aggFreq = $s(ents=1:freq, aggFreq<freq:aggFreq, 1:freq)
					set aggSpread = $s(ents=1:spread, aggSpread<spread:aggSpread, 1:spread)
				} elseif (aggregationtype=$$$AGGMAX) {
					set aggFreq = $s(ents=1:freq, aggFreq>freq:aggFreq, 1:freq)
					set aggSpread = $s(ents=1:spread, aggSpread>spread:aggSpread, 1:spread)
				} else {
					set aggFreq = aggFreq + freq
					set aggSpread = aggSpread + spread
				}
			}
			
			continue:(setop=$$$INTERSECT)&&(ents<entIdList)
			
			if (aggregationtype = $$$AGGAVG) {
				set aggFreq = aggFreq / entIdList, aggSpread = aggSpread / entIdList
			}
			
			set sort = -$s(sorttype=$$$SORTBYFREQUENCY:aggFreq, 1:aggSpread)
			set tEntValue = ..GetValueInternal(domainid, otherEntId, 0)
			$$$IKQADDRESULTSORT(^||%IK.GetRelSort,sort,$lb(+otherEntId, tEntValue, aggFreq, aggSpread))
		}
	}
	
	// finally, we'll have to re-sort the intermediate results in ^||%IK.GetRelEntIntSort as 
	// the sort order depends on positionstomatch and eventual filters 
	set tSC = ..CopyFromTempSortGlobal(.result, "^||%IK.GetRelSort", usePaging, first, last)
	quit:$$$ISERR(tSC)
	
	$$$IKCLEANSKIPLIST
	$$$IKQENDCATCH(result,"^||%IK.GetRelSort,^||%IK.GetRelTrack,^||%IK.GetRelCands,^||%IK.HeadBits,^||%IK.TailBits",tSC)
}

ClassMethod GetRelatedInternal20121(ByRef result, domainid As %Integer, ByRef entIdList, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, filtermode As %Integer, positionstomatch As %Integer, aggregationtype As %Integer, setop As %Integer, sorttype As %Integer, skipListIds As %List) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.GetRelEntIntSort,^||%IK.GetRelEntIntCrc,^||%IK.GetRelEntIntBit,^||%IK.GetRelEntIntAgg",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	$$$IKCHECKSORTTYPEX(domainid,sorttype,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD),tSC)
	quit:'$d(entIdList)
	
	set dedup = 0
	
	$$$IKBUILDSKIPLIST(domainid,skipListIds,0,0)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// define sort type
	if (sorttype="") || (sorttype = $$$SORTBYDOMAINDEFAULT) {
		set sorttype = $$$SORTFIELD(domainid)
	}
	
	// If we have only a single input element, we can use ^IRIS.IK.CcCombiFreq/Spread, but we'll have 
	// to take care to not stop looking too early as the sorted results in those globals are
	// for positionstomatch=$$$USEPOSHT and no filter, but can go down in other cases, so we'll
	// have to re-sort at the end and be careful with paging
	if ($order(entIdList("")) = $order(entIdList(""),-1)) {
		
		set entId = $order(entIdList(""))
		quit:'entId
		
		set entriesWithinPage = 0
		
		// loop through sortOrders
		set sortOrder=""
		for {
			if (sorttype = $$$SORTBYFREQUENCY) {
				set sortOrder = $order(^IRIS.IK.CcCombiFreq(domainid, entId, sortOrder))
			} elseif (sorttype = $$$SORTBYSPREAD) {
				set sortOrder = $order(^IRIS.IK.CcCombiSpread(domainid, entId, sortOrder))
			}
			quit:'+sortOrder
			
			// if we're paging, check if we can already stop because the next sortOrder
			// would already fall out of the paging window given the results in 
			// ^||%IK.GetRelEntIntSort
			if (usePaging) {
				set entriesWithinPage = 0
				set sortCheck = ""
				for {
					set sortCheck = $order(^||%IK.GetRelEntIntSort(sortCheck))
					quit:sortCheck=""
					
					// sort order is negative, so sortCheck < sortOrder means this entry
					// in the current result list is certainly in the final results as
					// sortOrder can only increase
					if (sortCheck < sortOrder) {
						set entriesWithinPage = entriesWithinPage + 1
					} else {
						quit
					}
				}
				if (entriesWithinPage > last) { quit }	
			}
			
			// loop through CC spouse for this sortOrder
			set otherEntId = ""
			for {
				if (sorttype = $$$SORTBYFREQUENCY) {
					set otherEntId = $order(^IRIS.IK.CcCombiFreq(domainid, entId, sortOrder, otherEntId))
				} elseif (sorttype = $$$SORTBYSPREAD) {
					set otherEntId = $order(^IRIS.IK.CcCombiSpread(domainid, entId, sortOrder, otherEntId))
				}
				quit:otherEntId=""
				continue:otherEntId=0
				
				continue:$$$IKISSKIPLISTED(otherEntId)
				
				// retrieve position-based frequency details
				if (positionstomatch = $$$USEPOSH) {
					set positionDetailsM = $get(^IRIS.IK.CcUniDetails(domainid, entId, otherEntId), $lb(0, 0))
					if ($list(positionDetailsM, 1) = 0) {
						continue
					} else {
						set details = positionDetailsM
					}
				} elseif (positionstomatch = $$$USEPOST) {
					set positionDetailsS = $get(^IRIS.IK.CcUniDetails(domainid, otherEntId, entId), $lb(0, 0))
					if ($list(positionDetailsS, 1) = 0) {
						continue
					} else {
						set details = positionDetailsS
					}
				} elseif ((positionstomatch = $$$USEPOSHT) || (positionstomatch = $$$USEPOSALL)) {
					if (entId<otherEntId) {
						set details = $get(^IRIS.IK.CcCombiDetails(domainid, entId, otherEntId), $lb(0,0))
					} else {
						set details = $get(^IRIS.IK.CcCombiDetails(domainid, otherEntId, entId), $lb(0,0))
					}
					continue:'$li(details,1)
				}
					
				// check if the related entity satisfies the filter through the 
				// corresponding CRCs, as those are the only ones linked to a source
				set filteredSpread = 0
				set filteredFreq = 0
				set filterInclude = 0
				if ($isobject(filter)) {
					
					// we'll build crc bitstrings based on ^IRIS.IK.EntUniToCrcX and store them in
					// ^||%IK.GetRelEntIntCrc, first for $$$USEPOSH and then for $$$USEPOST
					kill ^||%IK.GetRelEntIntCrc
					if ($$$CHECKPOSM(positionstomatch)) {
						set crcOffset = ""
						for {
							set crcOffset = $order(^IRIS.IK.EntUniMToCrcUniBit(domainid, entId, crcOffset), 1, crcbits)
							quit:crcOffset=""
							
							set ^||%IK.GetRelEntIntCrc(crcOffset) = $bitlogic(crcbits & ^IRIS.IK.EntUniSToCrcUniBit(domainid, otherEntId, crcOffset))
						}
					}
					if ($$$CHECKPOSS(positionstomatch)) {
						set crcOffset = ""
						for {
							set crcOffset = $order(^IRIS.IK.EntUniMToCrcUniBit(domainid, otherEntId, crcOffset), 1, crcbits)
							quit:crcOffset=""
							
							set crcbits = $bitlogic(crcbits & ^IRIS.IK.EntUniSToCrcUniBit(domainid, entId, crcOffset))
							set ^||%IK.GetRelEntIntCrc(crcOffset) = $bitlogic(crcbits | ^||%IK.GetRelEntIntCrc(crcOffset))
						}
					}
					
					// if filtering without recalc, we'll just check whether there's any hit
					// based on ^||%IK.GetRelEntIntCrc and CRC filters
					if ($$$CHECKFILTERONLY(filtermode)) {
						set crcOffset = ""
						for {
							set crcOffset = $order(^||%IK.GetRelEntIntCrc(crcOffset), 1, crcBits)
							quit:crcOffset=""
							
							set crcFilter = filter.GetCRCUniqueFilter(crcOffset)
							if ($bitfind($bitlogic(crcBits & crcFilter), 1) > 0) {
								set filterInclude = 1
								quit
							}
						}
					}
					
					// if we need to recalculate spread, we have to work from the sources
					// to the crcs, as the other direction would require duplicate src tracking
					if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
						
						// loop through the sources matching the base filter
						set srcOffset = ""
						for {
							set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
							quit:srcOffset=""
							
							// first do a quick filter of all the sources containing both entities
							set srcBits = $bitlogic(srcBits & ^IRIS.IK.EntUniToSrcBit(domainid, entId, srcOffset))
							set srcBits = $bitlogic(srcBits & ^IRIS.IK.EntUniToSrcBit(domainid, otherEntId, srcOffset))
							
							// now loop through the remaining documents
							set srcPos = 0
							for {
								set srcPos = $bitfind(srcBits, 1, srcPos+1)
								quit:srcPos=0
								
								$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
								
								// now check whether this doc has a hit
								set crcOffset = ""
								for {
									set crcOffset = $order(^||%IK.GetRelEntIntCrc(crcOffset), 1, crcBits)
									quit:crcOffset=""
									
									if ($bitfind($bitlogic(crcBits & ^IRIS.IK.SrcToCrcUniBit(domainid, srcId, crcOffset)), 1) > 0) {
										set filteredSpread = filteredSpread + 1
										quit
									}
								}
							}
						}
						
					}
					
					// for recalculating frequencies, we'll have to go through the list of
					// matching crcs and count occurrences satisfying CRC Occ filters
					if ($$$CHECKFILTERFREQ(filter,filtermode)) {
						set crcOffset = ""
						for {
							set crcOffset = $order(^||%IK.GetRelEntIntCrc(crcOffset), 1, crcBits)
							quit:crcOffset=""
							
							set crcPos = 0
							for {
								set crcPos = $bitfind(crcBits, 1, crcPos+1)
								quit:crcPos=0
								
								$$$IKGETIDOFFPOS(crcId,crcOffset,crcPos)
								
								set crcOccOffset = ""
								for {
									set crcOccOffset = filter.GetNextCRCOccurrenceFilterOffset(crcOccOffset, .crcOccBits)
									quit:crcOccOffset=""
									
									set crcOccBits = $bitlogic(crcOccBits & ^IRIS.IK.CrcUniToOccBit(domainid, crcId, crcOccOffset))
									set filteredFreq = filteredFreq + $bitcount(crcOccBits, 1)
								}
							}
						}
					}
					
					if 'filterInclude, 'filteredFreq, 'filteredSpread {
						continue
					}
					
					kill ^||%IK.GetRelEntIntCrc
					
					// now update this related entities details with the filtered results
					if ($$$CHECKFILTERFREQ(filter,filtermode)) {
						set $list(details, 1) = filteredFreq
					}
					if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
						set $list(details, 2) = filteredSpread
					}
				}
				
				// we do not have to check for duplicates as we have only one entId we started 
				// from and hence no overlap possible
				// same goes for setop
				
				// add the related entity to the temp result set
				if (sorttype = $$$SORTBYFREQUENCY) {
					set thisSortOrder = -$list(details, 1)
				} elseif (sorttype = $$$SORTBYSPREAD) {
					set thisSortOrder = -$list(details, 2)
				}
				set ^||%IK.GetRelEntIntSort(thisSortOrder, $i(dedup)) = $lb(+otherEntId, ^IRIS.IK.EntUniId(domainid, otherEntId), $list(details, 1), $list(details, 2))
				
				
				// update entriesWithinPage and check if we're done
				if (usePaging && (thisSortOrder < sortOrder)) {
					set entriesWithinPage = entriesWithinPage + 1
					if (entriesWithinPage >= last) {
						quit
					}
				}
			}
		}
		
	} else {
		
		
		// if there's more than one input entity we need to match, we cannot optimize the
		// algorithm too much through using pre-sorted globals, as the sort order of result
		// entities should be aggregated across matching input entities. Only for aggtype=MAX
		// the idea of tracking how many entities are already in the paging window would
		// work correctly, but we'll try a sub-optimal approach that works for all aggtypes,
		// running through all possible results, then aggregating and finally resorting them
		
		// loop over the supplied list
		set entId = ""
		set i = 0
		for {
			set entId = $order(entIdList(entId))
			quit:entId=""
			
			set i = i+1
			set entIdCount = i
			
			// merge the bitstrings for this entId as a head into ^||%IK.GetRelEntIntBit
			if ($$$CHECKPOSM(positionstomatch)) {
				set offset = ""
				for {
					set offset = $order(^IRIS.IK.EntUniMToEntUniSBit(domainid, entId, offset), 1, bitstring)
					quit:offset=""
					
					// if this is the first entId, we just add the bitstrings
					if (i = 1) {
						
						set ^||%IK.GetRelEntIntBit(offset, "M") = bitstring
						
					} else {
						
						// otherwise, we'll have to match the supplied bitstring against
						// what's already stored, taking into account the required setop
						set storedbits = $get(^||%IK.GetRelEntIntBit(offset, "M"), "")
						if (setop = $$$UNION) {
							set ^||%IK.GetRelEntIntBit(offset, "M") = $bitlogic(bitstring | storedbits)
						} elseif (setop = $$$INTERSECT) {
							set ^||%IK.GetRelEntIntBit(offset, "M") = $bitlogic(bitstring & storedbits)
						}
					}
				}
			}
			
			// now do the same for this entId as a tail
			if ($$$CHECKPOSS(positionstomatch)) {
				set offset = ""
				for {
					set offset = $order(^IRIS.IK.EntUniSToEntUniMBit(domainid, entId, offset), 1, bitstring)
					quit:offset=""
					
					// if this is the first entId, we just add the bitstrings
					if (i = 1) {
						
						set ^||%IK.GetRelEntIntBit(offset, "S") = bitstring
						
					} else {
						
						// otherwise, we'll have to match the supplied bitstring against
						// what's already stored, taking into account the required setop
						set storedbits = $get(^||%IK.GetRelEntIntBit(offset, "S"), "")
						if (setop = $$$UNION) {
							set ^||%IK.GetRelEntIntBit(offset, "S") = $bitlogic(bitstring | storedbits)
						} elseif (setop = $$$INTERSECT) {
							set ^||%IK.GetRelEntIntBit(offset, "S") = $bitlogic(bitstring & storedbits)
						}
					}
				}
			}
		}
		
		// now that we have the list of entities in bitstring format, loop through them,
		// aggregate the frequencies and store in ^||%IK.GetRelEntIntAgg
		$$$IKSORTBEGIN(^||%IK.GetRelEntIntSort)
		set offset = ""
		for {
			set offset = $order(^||%IK.GetRelEntIntBit(offset))
			quit:offset=""
			
			// first merge S and M bitstrings
			set mergedbits = $bitlogic(^||%IK.GetRelEntIntBit(offset, "M") | ^||%IK.GetRelEntIntBit(offset, "S"))
			
			// now loop through the bits and store the corresponding entity info
			set pos = 0
			for {
				set pos = $bitfind(mergedbits, 1, pos+1)
				quit:pos=0
				
				$$$IKGETIDOFFPOS(relEntId,offset,pos)
				
				continue:$$$IKISSKIPLISTED(relEntId)
				
				// skip if it was already in the supplied list
				if ($data(entIdList(relEntId))) {
					continue
				}
				
				// also skip the empty string entries
				continue:relEntId=0
				
				// now loop through the initial Ids and aggregate freq/spread
				set aggData = $lb(0, 0)
				set avgCount = 0
				set entId = ""
				set i = 0
				for {
					set entId = $order(entIdList(entId))
					quit:entId=""
					
					set i = i+1
				
					// retrieve CC info for matched CC positions
					set ccDetails = $lb(0, 0)
					
					// if we're not filtering both spread and freq, we can get the default
					// values by combining the results in ^IRIS.IK.CcUniDetails
					if ($$$CHECKFILTERFREQ(filter,filtermode) = 0) {
						
						// retrieve the ones for the M and S positions
						set ccDetailsM = $lb(0, 0)
						set ccDetailsS = $lb(0, 0)
						if $$$CHECKPOSM(positionstomatch), $d(^IRIS.IK.CcUniDetails(domainid, entId, relEntId), ccDetailsM) {}
						if $$$CHECKPOSS(positionstomatch), $d(^IRIS.IK.CcUniDetails(domainid, relEntId, entId), ccDetailsS) {}
						
						// just add the two together because they represent the same related entity
						set ccDetails = $lb($list(ccDetailsM, 1) + $list(ccDetailsS, 1), $list(ccDetailsM, 2) + $list(ccDetailsS, 2))
					}
						
					// check if the related entity satisfies the filter through the 
					// corresponding CRCs, as those are the only ones linked to a source
					set filteredSpread = 0
					set filteredFreq = 0
					set filterInclude = 0
					if ($isobject(filter)) {
						
						// we'll build crc bitstrings based on ^IRIS.IK.EntUniToCrcX and store them in
						// ^||%IK.GetRelEntIntCrc, first for $$$USEPOSH and then for $$$USEPOST
						kill ^||%IK.GetRelEntIntCrc
						if ($$$CHECKPOSM(positionstomatch)) {
							set crcOffset = ""
							for {
								set crcOffset = $order(^IRIS.IK.EntUniMToCrcUniBit(domainid, entId, crcOffset), 1, crcbits)
								quit:crcOffset=""
								
								set ^||%IK.GetRelEntIntCrc(crcOffset) = $bitlogic(crcbits & ^IRIS.IK.EntUniSToCrcUniBit(domainid, relEntId, crcOffset))
							}
						}
						if ($$$CHECKPOSS(positionstomatch)) {
							set crcOffset = ""
							for {
								set crcOffset = $order(^IRIS.IK.EntUniMToCrcUniBit(domainid, relEntId, crcOffset), 1, crcbits)
								quit:crcOffset=""
								
								set crcbits = $bitlogic(crcbits & ^IRIS.IK.EntUniSToCrcUniBit(domainid, entId, crcOffset))
								set ^||%IK.GetRelEntIntCrc(crcOffset) = $bitlogic(crcbits | ^||%IK.GetRelEntIntCrc(crcOffset))
							}
						}
						
						// if filtering without recalc, we'll just check whether there's any hit
						// based on ^||%IK.GetRelEntIntCrc and CRC Uni filters
						if ($$$CHECKFILTERONLY(filtermode)) {
							set crcOffset = ""
							for {
								set crcOffset = $order(^||%IK.GetRelEntIntCrc(crcOffset), 1, crcBits)
								quit:crcOffset=""
								
								set filterBits = filter.GetCRCUniqueFilter(crcOffset)
								if ($bitfind($bitlogic(crcBits & filterBits), 1) > 0) {
									set filterInclude = 1
									quit
								}
							}
						}
						
						// if we need to recalculate spread, we have to work from the sources
						// to the crcs, as the other direction would require duplicate src tracking
						if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
							
							// loop through the sources matching the base filter
							set srcOffset = ""
							for {
								set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
								quit:srcOffset=""
								
								// first do a quick filter of all the sources containing both entities
								set srcBits = $bitlogic(srcBits & ^IRIS.IK.EntUniToSrcBit(domainid, entId, srcOffset))
								set srcBits = $bitlogic(srcBits & ^IRIS.IK.EntUniToSrcBit(domainid, relEntId, srcOffset))
								
								// now loop through the remaining documents
								set srcPos = 0
								for {
									set srcPos = $bitfind(srcBits, 1, srcPos+1)
									quit:srcPos=0
									
									$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
									
									// now check whether this doc has a hit
									set crcOffset = ""
									for {
										set crcOffset = $order(^||%IK.GetRelEntIntCrc(crcOffset), 1, crcBits)
										quit:crcOffset=""
										
										if ($bitfind($bitlogic(crcBits & ^IRIS.IK.SrcToCrcUniBit(domainid, srcId, crcOffset)), 1) > 0) {
											set filteredSpread = filteredSpread + 1
											quit
										}
									}
								}
							}
							
						}
						
						// for recalculating frequencies, we'll have to go through the list of
						// matching crcs and count occurrences satisfying CRC Occ filters
						if ($$$CHECKFILTERFREQ(filter,filtermode)) {
							set crcOffset = ""
							for {
								set crcOffset = $order(^||%IK.GetRelEntIntCrc(crcOffset), 1, crcBits)
								quit:crcOffset=""
								
								set crcPos = 0
								for {
									set crcPos = $bitfind(crcBits, 1, crcPos+1)
									quit:crcPos=0
									
									$$$IKGETIDOFFPOS(crcId,crcOffset,crcPos)
									
									set crcOccOffset = ""
									for {
										set crcOccOffset = filter.GetNextCRCOccurrenceFilterOffset(crcOccOffset, .crcOccBits)
										quit:crcOccOffset=""
										
										set crcOccBits = $bitlogic(crcOccBits & ^IRIS.IK.CrcUniToOccBit(domainid, crcId, crcOccOffset))
										set filteredFreq = filteredFreq + $bitcount(crcOccBits, 1)
									}
								}
							}
						}
						
						if 'filterInclude, 'filteredFreq, 'filteredSpread {
							continue
						}
						
						kill ^||%IK.GetRelEntIntCrc
						
						// now update this related entities details with the filtered results
						if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
							set $list(ccDetails, 2) = filteredSpread
						}
						if ($$$CHECKFILTERFREQ(filter,filtermode)) {
							set $list(ccDetails, 1) = filteredFreq
						}
					}
					
					// now perform the required aggregation or just store if this is the first pass
					if (i = 1) {
						set aggData = ccDetails
					} elseif (aggregationtype = $$$AGGSUM) {
						set $list(aggData, 1) = $list(aggData, 1) + $list(ccDetails, 1)
						set $list(aggData, 2) = $list(aggData, 2) + $list(ccDetails, 2)
					} elseif (aggregationtype = $$$AGGAVG) {
						set $list(aggData, 1) = $list(aggData, 1) + $list(ccDetails, 1)
						set $list(aggData, 2) = $list(aggData, 2) + $list(ccDetails, 2)
						
						// now track ccs that have a score to know how we should divide
						if ($list(aggData, 1) > 0) {
							set avgCount = avgCount + 1
						}
						
						// divide if this is the last entry
						if (i = entIdCount) {
							set $list(aggData, 1) = $list(aggData, 1) / avgCount
							set $list(aggData, 2) = $list(aggData, 2) / avgCount
						}
					} elseif (aggregationtype = $$$AGGMIN) {
						if ($list(aggData, 1) > $list(ccDetails, 1)) {
							set $list(aggData, 1) =  $list(ccDetails, 1)
						}
						if ($list(aggData, 2) > $list(ccDetails, 2)) {
							set $list(aggData, 2) =  $list(ccDetails, 2)
						}
					} elseif (aggregationtype = $$$AGGMAX) {
						if ($list(aggData, 1) < $list(ccDetails, 1)) {
							set $list(aggData, 1) =  $list(ccDetails, 1)
						}
						if ($list(aggData, 2) < $list(ccDetails, 2)) {
							set $list(aggData, 2) =  $list(ccDetails, 2)
						}
					} 
							
				}
				
				// store the result in the sortable global
				set sortOrder = -$list(aggData, $select(sorttype=$$$SORTBYFREQUENCY:1,sorttype=$$$SORTBYSPREAD:2))
				set ^||%IK.GetRelEntIntSort(sortOrder, $i(^||%IK.GetRelEntIntSort)) = $lb(+relEntId, ^IRIS.IK.EntUniId(domainid, relEntId), $list(aggData, 1), $list(aggData, 2))
			}
		}
		
		// now perform the sort
		set ret = $sortend(^||%IK.GetRelEntIntSort)
	}
	
	
	// finally, we'll have to re-sort the intermediate results in ^||%IK.GetRelEntIntSort as 
	// the sort order depends on positionstomatch and eventual filters
	set tSC = ..CopyFromTempSortGlobal(.result, "^||%IK.GetRelEntIntSort", usePaging, first, last)
	quit:$$$ISERR(tSC)
	
	$$$IKCLEANSKIPLIST
	$$$IKQENDCATCH(result,"^||%IK.GetRelEntIntSort,^||%IK.GetRelEntIntCrc,^||%IK.GetRelEntIntBit,^||%IK.GetRelEntIntAgg",tSC)
}

///  <p>Returns the number of related entities for a given list of entities.</p>
///  <p>See <method>GetRelated</method> for a description of the parameters.</p>
ClassMethod GetRelatedCount(domainid As %Integer, entitylist As %List, filter As %iKnow.Filters.Filter = "", positionstomatch As %Integer = {$$$USEPOSHT}, setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pIncludeActualForms As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:$g(entitylist)="" 0
	
	if pIncludeActualForms { $$$CHECKSTEMMING(domainid) }

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// translate & clean entity list
	set sc = ..TranslateEntityList(domainid, entitylist, .cleanEntIdList,,, pIncludeActualForms)
	quit:$$$ISERR(sc) -1
	
	quit ..GetRelatedCountInternal(domainid, .cleanEntIdList, filter, positionstomatch, setop, .sc)
}

///  <p>Returns the number of related entities for a given list of entity ids.</p>
///  <p>See <method>GetRelated</method> for a description of the parameters.</p>
ClassMethod GetRelatedCountById(domainid As %Integer, entityidlist As %List, filter As %iKnow.Filters.Filter = "", positionstomatch As %Integer = {$$$USEPOSHT}, setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pIncludeActualForms As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:$g(entityidlist)="" 0

	if pIncludeActualForms { $$$CHECKSTEMMING(domainid) }
	
	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// translate & clean entity list
	set sc = ..TranslateEntityIdList(domainid, entityidlist, .cleanEntIdList,,, pIncludeActualForms)
	quit:$$$ISERR(sc) -1
	
	quit ..GetRelatedCountInternal(domainid, .cleanEntIdList, filter, positionstomatch, setop, .sc)
}

ClassMethod GetRelatedCountInternal(domainid As %Integer, ByRef entityIdList, filter As %iKnow.Filters.Filter, positionstomatch As %Integer, setop As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	quit:$$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) ..GetRelatedCountInternal20121(domainid, .entityIdList, filter, positionstomatch, setop)
	
	$$$IKQBEGINR("^||%IK.HeadBits,^||%IK.TailBits,^||%IK.HeadCCBits,^||%IK.TailCCBits,^||%IK.GetRelCountIntersect",sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	quit:'$d(entityIdList) 0

	$$$IKQBCHECKX(domainid,$lb($$$IKBCCUNIMAP,$$$IKBCCUNIALL),sc)
	
	// if empty, return 0
	if ($order(entityIdList("")) = "") {
		quit 0
	}
	
	if ($isobject(filter)) {
		set globsFrom("M") = "EntUniMToCcUniBit", globsFrom("S") = "EntUniSToCcUniBit"
		set globsTo("M") = "^||%IK.HeadCCBits", globsTo("S") = "^||%IK.TailCCBits"
	} else {
		set globsFrom("M") = "EntUniMToEntUniSBit", globsFrom("S") = "EntUniSToEntUniMBit"
		set globsTo("M") = "^||%IK.HeadBits", globsTo("S") = "^||%IK.TailBits"
	}
	
	// used to track whether we should count the entities in entityIdList as well
	//kill includeStartingEnts
	
	for mode = "M","S" {
		
		if (mode="M") {
			continue:'$$$CHECKPOSM(positionstomatch)
		} else {
			continue:'$$$CHECKPOSS(positionstomatch)
		}
		
		// now loop through all entIds
		set entId = ""
		for {
			set entId = $order(entityIdList(entId))
			quit:entId=""
			
			set gloFrom = "^IRIS.IK."_globsFrom(mode)_"("_domainid_","_entId_")"
			//$$$IKMERGEBITSOR(gloFrom,globsTo(mode))
			set off=""
			for {
				set off=$order(@gloFrom@(off),1,bits)
				quit:off=""
				
				set @globsTo(mode)@(off) = $bitlogic(bits | @globsTo(mode)@(off))
			
				// if not filtering, we'll need to track more details to enable $$$INTERSECT
				if '$isobject(filter) && (setop=$$$INTERSECT) {
					set pos=0
					for {
						set pos = $bitfind(bits,1,pos+1)
						quit:'pos 
						$$$IKGETIDOFFPOS(otherEntId,off,pos)
						set:'$d(^||%IK.GetRelCountIntersect(otherEntId,entId)) ^||%IK.GetRelCountIntersect(otherEntId,entId) = $i(^||%IK.GetRelCountIntersect(otherEntId))
					}
				}
			}
		}
	
		// if filtering, we'll have to filter these CCs and translate them to entities
		if ($isobject(filter)) {
			set off="", prevEntOff=0, entBits="", prevEntId=0
			for {
				set off = filter.GetNextCcUniqueFilterOffset(off, .filterBits)
				quit:off=""
				
				set ccBits = $g(@globsTo(mode)@(off))
				set ccBits = $bitlogic(ccBits & filterBits)
				
				set pos = 0
				for {
					set pos = $bitfind(ccBits, 1, pos+1)
					quit:pos=0
					
					$$$IKGETIDOFFPOS(ccId,off,pos)
					set cc = ^IRIS.IK.CcUniId(domainid, ccId)
					
					set entId = $li(cc, $s(mode="M":1, 1:2))
					set otherEntId = $li(cc, $s(mode="M":2, 1:1))
					//set:$d(entityIdList(otherEntId)) includeStartingEnts(otherEntId) = ""
					
					$$$IKBITOFFPOS(otherEntId,entOff,entPos)
					
					if (entOff'=prevEntOff) {
						set:prevEntOff ^||%IK.HeadBits(prevEntOff) = entBits
						set entBits = $g(^||%IK.HeadBits(entOff)), prevEntOff=entOff
					}
					set $bit(entBits,entPos) = 1
					
					if (setop=$$$INTERSECT) {
						set:'$d(^||%IK.GetRelCountIntersect(otherEntId,entId)) ^||%IK.GetRelCountIntersect(otherEntId,entId) = $i(^||%IK.GetRelCountIntersect(otherEntId))
					}
				}
				set:prevEntOff ^||%IK.HeadBits(prevEntOff) = entBits
			}
		}
	}
	
	// now merge everything into ^||%IK.HeadBits if not done while filtering
	if '$isobject(filter) && ($$$CHECKPOSS(positionstomatch)) {
		$$$IKMERGEBITSOR("^||%IK.TailBits","^||%IK.HeadBits")
	}
	
	if (setop = $$$UNION) {
		// and now count bits
		set off="", total=0
		for {
			set off = $order(^||%IK.HeadBits(off),1,bits)
			quit:off=""
			set total = total + $bitcount(bits,1)
		}
	} else {
		// substract those not meeting the $$$INTERSECT criteria
		set otherEntId="", total=0
		for {
			set otherEntId = $o(^||%IK.GetRelCountIntersect(otherEntId),1,entHitCount)
			quit:otherEntId=""
			
			set:(entHitCount=entityIdList) total = total+1
		}
	}
	
	$$$IKQEND("^||%IK.HeadBits,^||%IK.TailBits,^||%IK.HeadCCBits,^||%IK.TailCCBits,^||%IK.GetRelCountIntersect",total)
}

ClassMethod GetRelatedCountInternal20121(domainid As %Integer, ByRef entityIdList, filter As %iKnow.Filters.Filter, positionstomatch As %Integer, setop As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	$$$IKQBEGINR("^||%IK.GetTotRelEntBit",sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	
	// loop through the supplied entities
	set entId = ""
	set i = 0
	for {
		set entId = $order(entityIdList(entId))
		quit:entId=""
		
		set i = i+1
		
		// loop through ^IRIS.IK.EntUniMToEntUniS and merge resulting EntUniId bitstrings
		if ($$$CHECKPOSM(positionstomatch)) {
			set offset = ""
			for {
				set offset = $order(^IRIS.IK.EntUniMToEntUniSBit(domainid, entId, offset), 1, entbits)
				quit:offset=""
				
				// retrieve what's already out there
				set mergedbits = $get(^||%IK.GetTotRelEntBit(offset, "M"), "")
				
				// if nothing is stored so far, use entbits directly
				if (mergedbits = "") {
					set mergedbits = entbits
				} else {
					
					// otherwise, merge based on set operator
					if (setop = $$$UNION) {
						set mergedbits = $bitlogic(mergedbits | entbits)
					} elseif (setop = $$$INTERSECT) {
						set mergedbits = $bitlogic(mergedbits & entbits)
					}
				}
				
				// now check if for the surviving entities, a corresponding CRC
				// exists within a source satisfying the filter
				if ($isobject(filter)) {
					
					// we have to loop through the entities, checking for each one
					// if they satisfy the filter individually
					set entPos = 0
					for {
						set entPos = $bitfind(mergedbits, 1, entPos + 1)
						quit:entPos=0
						
						$$$IKGETIDOFFPOS(relEntId,offset,entPos)
						
						// now check for valid CRCs by combining CRC filter with
						// ^IRIS.IK.EntUniToCrcUniM and ^IRIS.IK.EntUniToCrcUniS
						set hasFilteredCrc = 0
						set crcOffset = ""
						for {
							set crcOffset = filter.GetNextCRCUniqueFilterOffset(crcOffset, .crcbits)
							quit:crcOffset=""
							
							set crcbits = $bitlogic(crcbits & ^IRIS.IK.EntUniMToCrcUniBit(domainid, entId, crcOffset))
							set crcbits = $bitlogic(crcbits & ^IRIS.IK.EntUniSToCrcUniBit(domainid, relEntId, crcOffset))
							
							// if at least one crc is found, we're fine
							if ($bitfind(crcbits, 1) > 0) {
								set hasFilteredCrc = 1
								quit
							}
						}
						// if nothing found, blank the bit
						if (hasFilteredCrc = 0) {
							set $bit(mergedbits, entPos) = 0
						}
					}
				}
				
				set ^||%IK.GetTotRelEntBit(offset, "M") = mergedbits
			}
		}
		
		// loop through ^IRIS.IK.EntUniSToEntUniM and merge resulting EntUniId bitstrings
		if ($$$CHECKPOSS(positionstomatch)) {
			set offset = ""
			for {
				set offset = $order(^IRIS.IK.EntUniSToEntUniMBit(domainid, entId, offset), 1, entbits)
				quit:offset=""
				
				// retrieve what's already out there
				set mergedbits = $get(^||%IK.GetTotRelEntBit(offset, "S"), "")
				
				// if nothing is stored so far, use entbits directly
				if (mergedbits = "") {
					set mergedbits = entbits
				} else {
					
					// otherwise, merge based on set operator
					if (setop = $$$UNION) {
						set mergedbits = $bitlogic(mergedbits | entbits)
					} elseif (setop = $$$INTERSECT) {
						set mergedbits = $bitlogic(mergedbits & entbits)
					}
				}
				
				// now check if for the surviving entities, a corresponding CRC
				// exists within a source satisfying the filter
				if ($isobject(filter)) {
					
					// we have to loop through the entities, checking for each one
					// if they satisfy the filter individually
					set entPos = 0
					for {
						set entPos = $bitfind(mergedbits, 1, entPos + 1)
						quit:entPos=0
						
						$$$IKGETIDOFFPOS(relEntId,offset,entPos)
						
						// now check for valid CRCs by combining CRC filter with
						// ^IRIS.IK.EntUniToCrcUniM and ^IRIS.IK.EntUniToCrcUniS
						set hasFilteredCrc = 0
						set crcOffset = ""
						for {
							set crcOffset = filter.GetNextCRCUniqueFilterOffset(crcOffset, .crcbits)
							quit:crcOffset=""
							
							set crcbits = $bitlogic(crcbits & ^IRIS.IK.EntUniMToCrcUniBit(domainid, relEntId, crcOffset))
							set crcbits = $bitlogic(crcbits & ^IRIS.IK.EntUniSToCrcUniBit(domainid, entId, crcOffset))
							
							// if at least one crc is found, we're fine
							if ($bitfind(crcbits, 1) > 0) {
								set hasFilteredCrc = 1
								quit
							}
						}
						// if nothing found, blank the bit
						if (hasFilteredCrc = 0) {
							set $bit(mergedbits, entPos) = 0
						}
					}
				}
				
				set ^||%IK.GetTotRelEntBit(offset, "S") = mergedbits
			}
		}
	} 
	
	// now loop through the generated bitstrings and count 1s after merging Head 
	// and Tail positions
	set total = 0
	set offset = 0
	for {
		set offset = $order(^||%IK.GetTotRelEntBit(offset))
		quit:offset=""
		
		set mergedBits = $bitlogic(^||%IK.GetTotRelEntBit(offset, "M") | ^||%IK.GetTotRelEntBit(offset, "S"))
		
		set total = total + $bitcount(mergedBits, 1)
		
	}
	
	$$$IKQEND("^||%IK.GetTotRelEntBit",total)
}

///  <p>Returned column summary for <method>GetNewBySource</method>.</p>
Parameter GetNewBySourceRT = "entUniId:%Integer,entity:%String,freqInNew:%Integer,freqInOld:%Integer,relFreqInNew:%Numeric,relFreqInOld:%Numeric";

///  <p>Retrieves the significant entities in a list of sources supplied through <var>sourceidlist</var>,
///  as compared to the other sources in the domain (optionally filtered through a
///  <class>%iKnow.Filters.Filter</class> object specified through <var>filter</var>).</p>
///  <p>The following <var>algorithm</var> values are currently available:</p>
///  <ul>
///  		<li>$$$NEWENTSIMPLE - takes no parameters</li>
///  </ul>
///  <p>To get the significant entities of a virtual source compared to the non-virtual ones in the
///  domain, only a single virtual source can be supplied using its negative ID value.</p>
///  <p>Through the <var>enttype</var> parameter, the method can be instructed to return either concepts
///  ($$$ENTTYPECONCEPT) or relations ($$$ENTTYPERELATION).</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetNewBySource(ByRef result, domainid As %Integer, sourceidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", entType As %Integer = {$$$ENTTYPECONCEPT}, algorithm As %String = {$$$NEWENTSIMPLE}, algorithmParams As %List = "", skipListIds As %List = "", pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.NewEnts, ^||%IK.NewEntsFreq, ^||%IK.NewEntsSpread",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	$$$IKENSURELISTNUM(sourceidlist)
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	} 
	
	if (algorithm'=$$$NEWENTSIMPLE) { set tSC = $$$ERROR($$$NotImplemented, "unknown algorithm: "_algorithm)  quit }
	
	set minFreqInNew = 1
	
	// first build an overview of what's in the new sources
	
	// if looking for a virtual source, treat it separately
	set vSrcId=0
	if $li(sourceidlist)<0,$ll(sourceidlist)=1 {
	    set vSrcId = -$li(sourceidlist)
	    $$$CHECKVSRCIDEXISTSX(domainid,vSrcId,tSC)
	}
	
	$$$IKBUILDSKIPLIST(domainid,skipListIds,vSrcId,pUseStems)
	
	if $isobject(filter) {
		$$$IKQBCHECKX(domainid,$lb($$$IKBENTUNISRC,$$$IKBENTUNIBIT),tSC)
	} elseif (domainid) {
		$$$IKQBCHECKX(domainid,$lb($$$IKBENTUNIDET),tSC)
	}
	
	// if not, go through the list and build ^||%IK.NewEntsFreq and ^||%IK.NewEntsSpread
	if ('vSrcId) {
		set ptr=0, srcId=0
		while $listnext(sourceidlist,ptr,srcId) {
			quit:srcId<0
			set srcDetails = ^IRIS.IK.SrcDetails(domainid, srcId)
			set eoFrom = $li(srcDetails,3)+1
			set eoTo = $li(srcDetails,3)+$li(srcDetails,4)
			for eoId = eoFrom:1:eoTo {
				set eo = ^IRIS.IK.EntOccId(domainid,eoId)
				continue:$lg(eo,2)=$$$ENTTYPENONREL // BDB577
				continue:$lg(eo,2)=$$$ENTTYPEPATHREL // BDB721
				set entUniId = $lg(eo,$s(pUseStems:10,1:1))
				continue:'entUniId
				continue:$$$IKISSKIPLISTED(entUniId)
				set ^||%IK.NewEntsFreq(entUniId) = $g(^||%IK.NewEntsFreq(entUniId)) + ((entType=$$$ENTTYPEANY)||(entType=$li(eo,2)))
				set ^||%IK.NewEntsSpread(entUniId,srcId) = ""
			}
		}
		if (srcId<0) {
			set tSC = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit
		}
	}
	
	set vEntUniDetails = "^IRIS.IKV."_$s(pUseStems:"Stem",1:"Ent")_"UniDetails"
	set gEntUniDetails = "^IRIS.IK."_$s(pUseStems:"Stem",1:"Ent")_"UniDetails"
	
	// now loop through these intermediary results and build ^||%IK.NewEnts
	set entUniId=""
	for {
		if ('vSrcId) {
			set entUniId = $order(^||%IK.NewEntsFreq(entUniId),1,freqInNew)
			quit:entUniId=""
			set realEntUniId=entUniId
		} else {
			set entUniId = $order(@vEntUniDetails@(domainid, vSrcId, entUniId),1,entDetails)
			quit:entUniId=""
			continue:$$$IKISSKIPLISTED(entUniId)
			set freqInNew = $case(entType, $$$ENTTYPEANY:$li(entDetails,1)+$li(entDetails,2), $$$ENTTYPECONCEPT:$li(entDetails,1), $$$ENTTYPERELATION:$li(entDetails,2))
			set realEntUniId = +$lg(entDetails,3)
		}
		
		continue:minFreqInNew>freqInNew
		
		// calculate spread from ^||%IK.NewEntsSpread
		if ('vSrcId) {
			set srcId = "", spreadInNew=0
			for {
				set srcId = $order(^||%IK.NewEntsSpread(entUniId,srcId))
				quit:srcId=""
				set spreadInNew = spreadInNew+1
			}
		} else {
			set spreadInNew=1
		}
	
		// calculate frequency and spread in the old sources
		set freqInOld=0, spreadInOld=0
		if (realEntUniId) {
			if ($isobject(filter)) {
				if pUseStems {
					set freqInOld = filter.GetFilteredStemFrequency(realEntUniId)
					set spreadInOld = filter.GetFilteredStemSpread(realEntUniId)
				} else {
					set freqInOld = filter.GetFilteredEntityFrequency(realEntUniId)
					set spreadInOld = filter.GetFilteredEntitySpread(realEntUniId)
				}
			} else {
				set entDetails = @gEntUniDetails@(domainid,realEntUniId)
				set freqInOld = $li(entDetails,$s(entType=$$$ENTTYPECONCEPT:1,1:2))-$s(vSrcId:0,1:freqInNew)
				set spreadInOld = $li(entDetails,$s(entType=$$$ENTTYPECONCEPT:4,1:5))-$s(vSrcId:0,1:spreadInNew)
			}
		}
	
		// now store the results in a sorted ^||%IK.NewEnts
		set relFreqInNew = (freqInNew/spreadInNew)
		set relFreqInOld = $s(spreadInOld:(freqInOld/spreadInOld),1:0)
		set ^||%IK.NewEnts(-(relFreqInNew-relFreqInOld),entUniId) = $lb(+entUniId, ..GetValueInternal(domainid,entUniId,vSrcId,pUseStems), freqInNew, spreadInNew, +$justify(relFreqInNew,0,4), +$justify(relFreqInOld,0,4))
	}
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	set tSC = ..CopyFromTempSortGlobal(.result, "^||%IK.NewEnts", usePaging, first, last)
	quit:$$$ISERR(tSC)
	
	$$$IKCLEANSKIPLIST
	$$$IKQENDCATCH(result,"^||%IK.NewEnts, ^||%IK.NewEntsFreq, ^||%IK.NewEntsSpread",tSC)
}

/// translate a list of entities to EntUniIds, removing inexistent entities and duplicates
/// 	pForms values for domains with stemming:
/// 		- 0 does no translation
/// 		- 1 includes other actual forms stemming to the same stem as the supplied entities
/// 		- 2 returns a two-level array with stems at level 1 and entities at level 2 (ids([stemUniId],[entUniId])
ClassMethod TranslateEntityList(domainid As %Integer, entitylist As %List, Output ids, vSrcId As %Integer = 0, Output unMatchedCount As %Integer, pForms As %Integer = 0) As %Status [ Internal ]
{
	kill ids
	set ids=0, unMatchedCount = 0, tSC = $$$OK
	
	set gEntUniActual = $$$IKVGLOBNAME(domainid,"StemUniToEntUni",vSrcId)
	
	set ptr = 0
	while $listnext(entitylist, ptr, entity) {
		continue:entity=""
		set entId = ..GetIdInternal(domainid, .entity, vSrcId)
		if 'entId && 'pForms { set unMatchedCount=unMatchedCount+1 continue }
		
		// BDB600
		if 'pForms {
			
			// no stemming transformations
			set:'$d(ids(entId)) ids(entId) = "", ids=ids+1
			
		} elseif pForms=1 {
			
			// add this entity 
			if (entId) {
				set:'$d(ids(entId)) ids(entId) = "", ids=ids+1
				set stemId = ..GetStemIdByEntityId(domainid, entId, vSrcId)
			} else {
				set stem = ..GetStem(domainid, entity,, .tSC)
				quit:$$$ISERR(tSC)
				set stemId = $s(stem="":0, 1:..GetStemId(domainid,stem,vSrcId))
				if 'stemId { set unMatchedCount=unMatchedCount+1 continue }
			}
			
			// add corresponding actuals
			if stemId {
				set tActualEntId = ""
				for {
					set tActualEntId = $order(@gEntUniActual@(stemId, tActualEntId))
					quit:tActualEntId=""
					set:'$d(ids(tActualEntId)) ids(tActualEntId) = "", ids=ids+1
				}
			}
			
		} elseif pForms=2 {
			
			// fetch base form
			if (entId) {
				continue:$d(ents(entId))
				set ents(entId) = ""
				set stemId = ..GetStemIdByEntityId(domainid, entId, vSrcId)
			} else {
				set stem = ..GetStem(domainid, entity,, .tSC)
				quit:$$$ISERR(tSC)
				set stemId = $s(stem="":0, 1:..GetStemId(domainid,stem,vSrcId))
				if 'stemId { set unMatchedCount=unMatchedCount+1 continue }
			}
			set ids=ids+1
			merge ids(stemId) = @gEntUniActual@(stemId)
			
		}
	}
	
	quit tSC
}

///  clean a list of EntUniIds from duplicates and inexistent ids
/// 	pForms values:
/// 		- 0 does no translation
/// 		- 1 includes other actual forms stemming to the same stem as the supplied entities
/// 		- 2 returns a two-level array with stems at level 1 and entities at level 2 (ids([stemUniId],[entUniId])
ClassMethod TranslateEntityIdList(domainid As %Integer, entIdList As %List, Output ids, vSrcId As %Integer = 0, Output unMatchedCount As %Integer, pForms As %Integer = 0) As %Status [ Internal ]
{
	kill ids
	set ids=0, unMatchedCount = 0
	
	set entUniIdGlo = $$$IKVGLOBNAME(domainid,"EntUniId",vSrcId)
	set gEntUniActual = $$$IKVGLOBNAME(domainid,"StemUniToEntUni",vSrcId)
		
	set ptr = 0
	while $listnext(entIdList, ptr, entId) {
		continue:entId=""
		if '$data(@entUniIdGlo@(entId)) { set unMatchedCount = unMatchedCount+1 continue }

		// BDB600
		if 'pForms {
			
			// no stemming transformations
			set:'$d(ids(entId)) ids(entId) = "", ids=ids+1
			
		} elseif pForms=1 {
			
			// add this entity 
			set:'$d(ids(entId)) ids(entId) = "", ids=ids+1
			
			// fetch base form
			set stemId = ..GetStemIdByEntityId(domainid, entId, vSrcId)
			
			// add corresponding actuals
			if stemId {
				set tActualEntId = ""
				for {
					set tActualEntId = $order(@gEntUniActual@(stemId, tActualEntId))
					quit:tActualEntId=""
					set:'$d(ids(tActualEntId)) ids(tActualEntId) = "", ids=ids+1
				}
			}
			
		} elseif pForms=2 {
			
			// fetch base form
			set stemId = +..GetStemIdByEntityId(domainid, entId, vSrcId)
			merge ids(stemId) = @gEntUniActual@(stemId)
			
		}
	}
	
	quit $$$OK
}

Parameter GetTopGroupsRT [ Internal ] = "string:%String,similarCount:%Integer,totFreq:%Integer,totSpread:%Integer";

ClassMethod GetTopGroups(ByRef result, domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, filter As %iKnow.Filters.Filter = "", skipListIds As %List = "", language As %String = "en", entType As %Integer = {$$$ENTTYPECONCEPT}, pUseStems As %Boolean = 0) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IKQ.Top,^||%IKQ.Words,^||%IKQ.Sort,^||%IK.SkipListStandardized",tSC)
	
	// first grab the normal top concepts for large enough a window
	set tSC = ..GetTop("^||%IKQ.Top", domainId, 1, page*pageSize*3, filter, $$$FILTERFREQANDSORT,, entType,, skipListIds, pUseStems)
	quit:$$$ISERR(tSC)
	
	set textClass = "%Text."_$case(language, "en":"English", "fr":"French", "de":"German", "es":"Spanish", "pt":"Portuguese","ja":"Japanese", "it":"Italian", :"Text")
	$$$IKBUILDSKIPLIST(domainId,skipListIds,0,pUseStems)
	
	// we'll loop through the skiplists manually as we need to use the same standardization and
	// need to save them in another place as they'll be killed by the nested ..GetSimilarCounts calls
	set tEntUniId = ""
	for {
		set tEntUniId = $order(^||%IK.SkipLists(tEntUniId))
		quit:tEntUniId=""
		
		set tStandardized = $e($classmethod(textClass, "Standardize", ..GetValueInternal(domainId,tEntUniId,,pUseStems)),2,*-1)
		continue:tStandardized=""
		continue:$length(tStandardized)>$$$IKHASHSIZE
		set ^||%IK.SkipListStandardized(tStandardized)=""
	}
	
	// now loop through them and get similar counts for each word
	set i = ""
	for {
		set i = $order(^||%IKQ.Top(i), 1, tData)
		quit:i=""
		
		set tString = $li(tData,2), tLen = $length(tString," ")
		for j = 1:1:tLen {
			set tWord = $piece(tString," ",j)
			set tWordS = $e($classmethod(textClass, "Standardize", tWord), 2, *-1)
			continue:tWordS=""
			continue:$length(tWordS)>$$$IKHASHSIZE
			continue:$isvalidnum(tWordS)
			continue:$d(^||%IKQ.Words(tWordS))
			continue:$d(^||%IK.SkipListStandardized(tWordS))
			set tCounts = ..GetSimilarCounts(domainId, tWordS, filter,,, .tSC, entType, pUseStems)
			quit:$$$ISERR(tSC)
			continue:tCounts=""
			set ^||%IKQ.Words(tWordS) = tCounts _ $lb(tWord)
		}
		quit:$$$ISERR(tSC)
	}
	quit:$$$ISERR(tSC)
	
	$$$IKSORTBEGIN(^||%IKQ.Sort)
	set tWord = ""
	for {
		set tWord = $order(^||%IKQ.Words(tWord),1,tData)
		quit:tWord=""
		
		set tSort = $li(tData,2)
		set ^||%IKQ.Sort(-tSort,tWord) = $li(tData,4,4)_$li(tData,1,3)
	}
	set x = $sortend(^||%IKQ.Sort)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,count)
	set tSC = ..CopyFromTempSortGlobal(.result,"^||%IKQ.Sort",usePaging,first,last)
	quit:$$$ISERR(tSC)
	
	$$$IKQENDCATCH(result,"^||%IKQ.Top,^||%IKQ.Words,^||%IKQ.Sort,^||%IK.SkipListStandardized",tSC)
}

Parameter GetOccurrenceAttributesRT = "attTypeId:%Integer,attType:%String,level:%Integer,wordPositions:%String,properties:%String";

/// <p>Returns all attributes for a given part. Any named attribute properties are also
/// included through sub-nodes (not available through SQL or SOAP): 
/// <blockquote>pResult(<i>rowNumber</i>, <i>propertyName</i>) = <i>propertyValue</i></blockquote></p>
/// <p>The returned <var>wordPositions</var> only extend to the last attributed word position
/// (there might be more words within the entity).</p>
ClassMethod GetOccurrenceAttributes(ByRef pResult, pDomainId As %Integer, pPartId As %Integer, vSrcId As %Integer = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	if vSrcId && (pDomainId=0) {} else { $$$CHECKDOMAINEXISTSX(pDomainId,tSC) }
	$$$IKCHECKVERSIONATLEASTX(pDomainId,$$$IKVERSIONATTRIBUTES,tSC)
	if (vSrcId) { $$$CHECKVSRCIDEXISTSX(pDomainId,vSrcId,tSC) }
	
	set gEntOccId = $$$IKVGLOBNAME(pDomainId,"EntOccId",vSrcId)
	set gAttPath = $$$IKVGLOBNAME(pDomainId,"Att.Path",vSrcId)
	set gAttSent = $$$IKVGLOBNAME(pDomainId,"Att.Sent",vSrcId)
	set gAttEntOcc = $$$IKVGLOBNAME(pDomainId,"Att.EntOcc",vSrcId)
	
	set tEntOcc = $g(@gEntOccId@(+pPartId))
	quit:tEntOcc=""
	
	
	// add path-level attributes
	set tPathId = $lg(tEntOcc, 8)
	if (tPathId) {
		set tAttTypeId = "", tPosInPath = $lg(tEntOcc, 9)
		for {
			set tAttTypeId = $order(@gAttPath@(tPathId, tAttTypeId))
			quit:tAttTypeId=""
			
			set tAtt=""
			set tStartPos = $order(@gAttPath@(tPathId, tAttTypeId, tPosInPath+1), -1, tAtt)
			continue:tStartPos=""
			continue:(tStartPos+$li(tAtt,1)-1)<tPosInPath
			
			set tAttName = $$$IKATTTYPENAME(tAttTypeId)
			set tSpan = +$lg(tAtt,1), tProps = $li(tAtt,2,*)
			$$$IKQADDRESULT(pResult,$i(tCount),$lb(+tAttTypeId,tAttName,$$$IKATTLVLPATH,"",$lts(tProps,,1)))
			
			set tSC = ##class(%iKnow.Queries.EntityAPI).BuildAttributePropArray(tAttTypeId,tProps,.tPropArray)
			quit:$$$ISERR(tSC)
			$$$IKQMERGERESULT(pResult,tCount,tPropArray)
		}
		quit:$$$ISERR(tSC)
	}
	
	// and sentence-level attributes
	set tSentId = $lg(tEntOcc, 3), tPosInSent = $lg(tEntOcc, 4)
	set tAttTypeId = ""
	for {
		set tAttTypeId = $order(@gAttSent@(tSentId, tAttTypeId))
		quit:tAttTypeId=""
		
		set tAtt=""
		set tStartPos = $order(@gAttSent@(tSentId, tAttTypeId, tPosInSent+1), -1, tAtt)
		continue:tStartPos=""
		continue:(tStartPos+$li(tAtt,1)-1)<tPosInSent
		
		set tAttName = $$$IKATTTYPENAME(tAttTypeId)
		set tSpan = +$lg(tAtt,1)
		$$$IKATTWORDPOS($lg(tAtt,tPosInSent-tStartPos+2),tWordPos)
		continue:tWordPos="0" // skip if no words are actually attributed
		set tProps = $li(tAtt,tSpan+2,*)
		$$$IKQADDRESULT(pResult,$i(tCount),$lb(+tAttTypeId,tAttName,$$$IKATTLVLSENT,tWordPos,$lts(tProps,,1)))
		
		set tSC = ##class(%iKnow.Queries.EntityAPI).BuildAttributePropArray(tAttTypeId,tProps,.tPropArray)
		quit:$$$ISERR(tSC)
		$$$IKQMERGERESULT(pResult,tCount,tPropArray)
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

/// Checks if a given entity occurrence has the requested attribute <var>pAttTypeId</var>. 
ClassMethod IsAttributed(pDomainId As %Integer, pEntOccId As %Integer, pAttTypeId As %Integer, vSrcId As %Integer = 0, Output pSC As %Status = {$$$OK}) As %Boolean
{
	$$$IKCHECKPRIVREADR(pSC,0)
	if vSrcId && (pDomainId=0) {} else { $$$CHECKDOMAINEXISTSR(pDomainId,pSC,0) }
	$$$IKCHECKVERSIONATLEASTR(pDomainId,$$$IKVERSIONATTRIBUTES,pSC,0)
	if (vSrcId) { $$$CHECKVSRCIDEXISTSR(pDomainId,vSrcId,pSC,0) }
	
	quit ..IsAttributedInternal(pDomainId, pEntOccId, pAttTypeId,, vSrcId)
}

ClassMethod IsAttributedInternal(pDomainId As %Integer, pEntOccId As %Integer, pAttTypeId As %Integer, pEntOccInfo As %List = "", vSrcId As %Integer = 0, pLevel As %Integer = {$$$IKATTLVLANY}) As %Boolean [ Internal ]
{
	set gEntOccId = $$$IKVGLOBNAME(pDomainId,"EntOccId",vSrcId)
	set gAttPath = $$$IKVGLOBNAME(pDomainId,"Att.Path",vSrcId)
	set gAttSent = $$$IKVGLOBNAME(pDomainId,"Att.Sent",vSrcId)
	//set gAttEntOcc = $$$IKVGLOBNAME(pDomainId,"Att.EntOcc",vSrcId)
	
	if (pEntOccInfo="") {
		set pEntOccInfo = $g(@gEntOccId@(pEntOccId))
		quit:pEntOccInfo="" 0
	}
	
	//quit:$d(@gAttEntOcc@(pEntOccId, pAttTypeId)) 1
	
	// check path attributes
	if (pLevel = $$$IKATTLVLANY) || (pLevel = $$$IKATTLVLPATH) {
		set tPathId = $lg(pEntOccInfo,8)
		if (tPathId) {
			set tPathPos = $lg(pEntOccInfo,9)
			set tAttStartPos = $order(@gAttPath@(tPathId,pAttTypeId,tPathPos+1),-1,tAttInfo)
			if (tAttStartPos'="") {
				quit (tPathPos <= (tAttStartPos+$lg(tAttInfo,1)-1))
			}
		}
	}
	
	// check sentence attributes
	if (pLevel = $$$IKATTLVLANY) || (pLevel = $$$IKATTLVLSENT) {
		set tSentId = $lg(pEntOccInfo,3), tSentPos = $lg(pEntOccInfo,4)
		set tAttStartPos = $order(@gAttSent@(tSentId,pAttTypeId,tSentPos+1),-1,tAttInfo)
		if (tAttStartPos'="") {
			if (tSentPos <= (tAttStartPos+$lg(tAttInfo,1)-1)) {
				// if there is a sentence attribute for this position, check whether any
				// words in this entity occurrence are tagged
				quit ($lg(tAttInfo,tSentPos-tAttStartPos+2)'="")
			}
		}
	}
	quit 0
}

Parameter GetTopBM25RT = "entUniId:%Integer,entityValue:%String,bm25:%Numeric";

/// Returns the top entities for a given domain (optionally filtered through <var>pFilter</var>)
/// calculated using a metric based on the Okapi BM25 standard, which combines an entity's frequency 
/// with its Inverse Document Frequency, taking into account document length.
ClassMethod GetTopBM25(ByRef pResult, pDomainId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pEntType As %Integer = {$$$ENTTYPECONCEPT}, pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"^||%IK.EntSpread,^||%IK.EntBM25,^||%IK.EntSorted",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	$$$IKQRCCHECK(pDomainId,pFilter,"GetTopBM25",$lb(pDomainId,,,pFilter,pEntType),pPage,pPageSize,pResult)
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	}
	
	/*
	b = 0.75 (smoothing)
	k1 = 1.6 (tuning)

	BM25(tf) = termFreq [* (k1 + 1)] / (k1 * ((1-b) + b * docLength / avgDocLength) + termFreq) * [RSJ|IDF]
	IDF = log( (DC - spread + 0.5) / (spread + 0.5) )
	*/

	set b = 0.75, k1 = 1.6
	set tDocCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, pFilter)
	quit:'tDocCount
	set tEntOccCount = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceCountByDomain(pDomainId, pFilter, pEntType)
	quit:'tEntOccCount
	set tAvgDocLength = tEntOccCount / tDocCount

	set tSrcId = "", gEntSrcDetails = "^IRIS.IK."_$s(pUseStems:"Stem",1:"Ent")_"SrcDetails"
	for {
		set tSrcId = $s($isobject(pFilter):pFilter.GetNextSrcId(tSrcId), 1:$order(@gEntSrcDetails@(pDomainId,tSrcId)))
		quit:tSrcId=""
		
		kill tSrcEnts
		merge tSrcEnts = @gEntSrcDetails@(pDomainId, tSrcId)
		
		// first traverse to get document length
		set tDocLength = 0
		set tEntUniId = ""
		for {
			set tEntUniId = $order(tSrcEnts(tEntUniId), 1, tDetails)
			quit:tEntUniId=""
			
			set tFrequency = $case(pEntType, $$$ENTTYPEANY:$lg(tDetails,1)+$lg(tDetails,2), $$$ENTTYPECONCEPT:$lg(tDetails,1), $$$ENTTYPERELATION:$lg(tDetails,2))
			set x = $i(tDocLength, tFrequency)
		}
		
		// now go through the list again to calculate the per-source contribution to BM25 and spread 
		set tEntUniId = ""
		for {
			set tEntUniId = $order(tSrcEnts(tEntUniId), 1, tDetails)
			quit:tEntUniId=""
			
			set tFrequency = $case(pEntType, $$$ENTTYPEANY:$lg(tDetails,1)+$lg(tDetails,2), $$$ENTTYPECONCEPT:$lg(tDetails,1), $$$ENTTYPERELATION:$lg(tDetails,2))
			continue:'tFrequency
			set x = $i(^||%IK.EntSpread(tEntUniId))
			
			set tBM25 = tFrequency / (k1 * ((1-b) + b * (tDocLength / tAvgDocLength)) + tFrequency)
			set x = $i(^||%IK.EntBM25(tEntUniId), tBM25)
		}
	}

	kill ^||%IK.EntSorted
	set tEntUniId = ""
	for {
		set tEntUniId = $order(^||%IK.EntSpread(tEntUniId), 1, tSpread)
		quit:tEntUniId=""
		
		set tIDF = $zlog((tDocCount - tSpread + 0.5) / (tSpread + 0.5))
		set ^||%IK.EntSorted(-tIDF * ^||%IK.EntBM25(tEntUniId), tEntUniId) = ""
	}
	
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	set tBM25 = ""
	for {
		set tBM25 = $order(^||%IK.EntSorted(tBM25))
		quit:tBM25=""
		
		set tEntUniId = ""
		for {
			set tEntUniId = $order(^||%IK.EntSorted(tBM25, tEntUniId))
			quit:tEntUniId=""
			
			set tCount = tCount + 1
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			
			set tEntValue = ..GetValueInternal(pDomainId, tEntUniId, 0, pUseStems)
			$$$IKQADDRESULT(pResult,tCount,$lb(+tEntUniId, tEntValue, -$justify(tBM25, 0, 4)))
			 
		}
		$$$IKCHECKPAGING(tUsePaging,0,tLast,tCount)
	}


	$$$IKQRCSTORE(pDomainId,pFilter,"GetTopBM25",$lb(pDomainId,,,pFilter,pEntType),pPage,pPageSize,pResult,tSC)

	$$$IKQENDCATCH(pResult,"^||%IK.EntSpread,^||%IK.EntBM25,^||%IK.EntSorted",tSC)
}

Parameter GetTopTFIDFRT = "entUniId:%Integer,entityValue:%String,TFIDF:%Numeric";

/// Returns the top entities for a given domain (optionally filtered through <var>pFilter</var>)
/// by multiplying their Term Frequency with their Inverse Document Frequency:
/// IDF(e) = $zlog( [ SourceCount - spread(e) + 0.5 ] / [ spread(e) + 0.5 ] )
ClassMethod GetTopTFIDF(ByRef pResult, pDomainId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pEntType As %Integer = {$$$ENTTYPECONCEPT}, pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"^||%IK.EntSpread,^||%IK.EntFreq,^||%IK.EntSorted",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	$$$IKQRCCHECK(pDomainId,pFilter,"GetTopTFIDF",$lb(pDomainId,,,pFilter,pEntType),pPage,pPageSize,pResult)
	
	// BDB600 - check if this is a domain with stemmed forms
	if pUseStems && ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	}
	
	set tDocCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, pFilter)
	quit:'tDocCount
	
	set gEntSrcDetails = "^IRIS.IK."_$s(pUseStems:"Stem",1:"Ent")_"SrcDetails"
	
	if $isobject(pFilter) {
		set tSrcId = ""
		for {
			set tSrcId = pFilter.GetNextSrcId(tSrcId)
			quit:tSrcId=""
			
			kill tSrcEnts
			merge tSrcEnts = @gEntSrcDetails@(pDomainId, tSrcId)
			
			set tEntUniId = ""
			for {
				set tEntUniId = $order(tSrcEnts(tEntUniId), 1, tDetails)
				quit:tEntUniId=""
				
				set tFrequency = $case(pEntType, $$$ENTTYPEANY:$lg(tDetails,1)+$lg(tDetails,2), $$$ENTTYPECONCEPT:$lg(tDetails,1), $$$ENTTYPERELATION:$lg(tDetails,2))
				continue:'tFrequency
				set x = $i(^||%IK.EntSpread(tEntUniId))
				set x = $i(^||%IK.EntFreq(tEntUniId), tFrequency)
			}
		}
	}

	kill ^||%IK.EntSorted
	set tEntUniId = "", gEntUniDetails = "^IRIS.IK."_$s(pUseStems:"Stem",1:"Ent")_"UniDetails"
	for {
		if $isobject(pFilter) {
			set tEntUniId = $order(^||%IK.EntSpread(tEntUniId), 1, tSpread)
			quit:tEntUniId=""
			set tFreq = ^||%IK.EntFreq(tEntUniId)
		} else {
			set tEntUniId = $order(@gEntUniDetails@(pDomainId, tEntUniId), 1, tEntDetails)
			quit:tEntUniId=""
			set tSpread = +$lg(tEntDetails, $case(pEntType, $$$ENTTYPEANY:3, $$$ENTTYPECONCEPT:4, $$$ENTTYPERELATION:5))
			set tFreq = $case(pEntType, $$$ENTTYPEANY:$lg(tEntDetails,1)+$lg(tEntDetails,2), $$$ENTTYPECONCEPT:$lg(tEntDetails,1), $$$ENTTYPERELATION:$lg(tEntDetails,2))
			continue:'tSpread
		}
		
		set tTFIDF = tFreq * $zlog((tDocCount - tSpread + 0.5) / (tSpread + 0.5))
		set ^||%IK.EntSorted(-tTFIDF, tEntUniId) = ""
	}
	
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	set tTFIDF = ""
	for {
		set tTFIDF = $order(^||%IK.EntSorted(tTFIDF))
		quit:tTFIDF=""
		
		set tEntUniId = ""
		for {
			set tEntUniId = $order(^||%IK.EntSorted(tTFIDF, tEntUniId))
			quit:tEntUniId=""
			
			set tCount = tCount + 1
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			
			set tEntValue = ..GetValueInternal(pDomainId, tEntUniId, 0, pUseStems)
			$$$IKQADDRESULT(pResult,tCount,$lb(+tEntUniId, tEntValue, -$justify(tTFIDF, 0, 4)))
			 
		}
		$$$IKCHECKPAGING(tUsePaging,0,tLast,tCount)
	}


	$$$IKQRCSTORE(pDomainId,pFilter,"GetTopTFIDF",$lb(pDomainId,,,pFilter,pEntType),pPage,pPageSize,pResult,tSC)

	$$$IKQENDCATCH(pResult,"^||%IK.EntSpread,^||%IK.EntSorted",tSC)
}

ClassMethod GetNBProbabilityInternal(pDomainId As %Integer, pEntUniId As %Integer, pFilter As %iKnow.Filters.Filter, pReferenceSetFilter As %iKnow.Filters.Filter = "", Output pSC As %Status, pUseStems As %Boolean = 0) As %Double [ Internal ]
{
	set pSC = $$$OK, tProbability = ""
	try {
		//$$$CHECKDOMAINEXISTSX(pDomainId,pSC)
		//$$$IKQFILTEROBJECTX(pDomainId,pFilter,pSC)
		//$$$IKQFILTEROBJECTX(pDomainId,pTrainingSet,pSC)
		//$$$IKQBCHECKX(pDomainId,$lb($$$IKBENTUNIDET),pSC)
		
		set tHasTrainingSet = $isobject(pReferenceSetFilter)
		if tHasTrainingSet {
			set tGroupFilter = ##class(%iKnow.Filters.GroupFilter).%New(pDomainId,$$$GROUPFILTERAND)
			set pSC = tGroupFilter.AddSubFilter(pFilter)
			quit:$$$ISERR(pSC)
			set pSC = tGroupFilter.AddSubFilter(pReferenceSetFilter)
			quit:$$$ISERR(pSC)
			set pFilter = tGroupFilter
		}
		
		set tProbability = 0
		if pUseStems {
			set tDetails = $g(^IRIS.IK.StemUniDetails(pDomainId, pEntUniId))
			set tTotalSpread = $s(tHasTrainingSet:pReferenceSetFilter.GetFilteredStemSpread(pEntUniId), 1:$lg(tDetails,3))
			quit:'tTotalSpread
			set tFilterSpread = pFilter.GetFilteredStemSpread(pEntUniId)
			quit:'tFilterSpread
		} else {
			set tDetails = $g(^IRIS.IK.EntUniDetails(pDomainId, pEntUniId))
			set tTotalSpread = $s(tHasTrainingSet:pReferenceSetFilter.GetFilteredEntitySpread(pEntUniId), 1:$lg(tDetails,3))
			quit:'tTotalSpread
			set tFilterSpread = pFilter.GetFilteredEntitySpread(pEntUniId)
			quit:'tFilterSpread
		}
		
		set tFilteredSourceCount = pFilter.FilteredSourceCount
		set tNotFilteredSourceCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, pReferenceSetFilter) - tFilteredSourceCount
		if 'tNotFilteredSourceCount { set tProbability = 1 quit }
		
		set tProbability = (tFilterSpread/tFilteredSourceCount) / ((tFilterSpread/tFilteredSourceCount) + ((tTotalSpread-tFilterSpread)/tNotFilteredSourceCount))
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tProbability
}

Parameter GetOccurrencesByIdRT = "EntOccId:%Integer,EntUniId:%Integer,Type:%Integer,SentenceId:%Integer,SourceId:%Integer,IsAttributed:%Integer";

/// <p>Returns all occurrences for any of the given unique entities in <var>pEntUniIds</var>,
/// including whether the attribute <var>pAttributeId</var> is applicable to this occurrence.</p>
/// <p>If this domain is configured for stemming using $$$IKPSTEMMING, any actual entities corresponding
/// to <var>pEntUniIds</var> elements will be returned.</p>
ClassMethod GetOccurrencesById(ByRef pResult, pDomainId As %Integer, pEntUniIds As %List, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pAttributeId As %Integer = {$$$IKATTNEGATION}, vSrcId As %Integer = 0, pIncludeActualForms As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"^||%IK.EntOccIds",tSC)
	$$$IKCHECKPRIVREADX(tSC)
	if vSrcId && (pDomainId=0) {} else { $$$CHECKDOMAINEXISTSX(pDomainId,tSC) }
	if pIncludeActualForms { $$$CHECKSTEMMINGX(pDomainId,tSC) }
	
	if 'vSrcId {
		$$$IKQBCHECKX(pDomainId,$lb($$$IKBENTUNIBIT),tSC)
	}
	
	$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	
	$$$IKENSURELISTNUM(pEntUniIds)
	set tSC = ..TranslateEntityIdList(pDomainId,pEntUniIds,.tEntIds,vSrcId,, ''pIncludeActualForms)
	quit:$$$ISERR(tSC)
	
	if 'vSrcId {
		set tEntUniId = ""
		for {
			set tEntUniId = $order(tEntIds(tEntUniId))
			quit:tEntUniId=""
			set tGlobName = $name(^IRIS.IK.EntUniToOccBit(pDomainId,tEntUniId))
			$$$IKMERGEBITSOR(tGlobName,"^||%IK.EntOccIds")
		}
		set:$isobject(pFilter) tSC = pFilter.MergeBits("^||%IK.EntOccIds",$$$IKFENTOCC)
		quit:$$$ISERR(tSC)
		
		set tOffset=""
		for {
			set tOffset = $order(^||%IK.EntOccIds(tOffset), 1, tEntOccBits)
			quit:tOffset=""
			
			set tPos = 0
			for {
				set tPos = $bitfind(tEntOccBits, 1, tPos+1)
				quit:'tPos
				
				$$$IKGETIDOFFPOS(tEntOccId,tOffset,tPos)
				
				set tEntOcc = ^IRIS.IK.EntOccId(pDomainId,tEntOccId)
				set tSentId = $li(tEntOcc,3)
				set tSourceId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(pDomainId, tSentId)
				
				set tIsAttributed = $s(pAttributeId:..IsAttributedInternal(pDomainId, tEntOccId, pAttributeId, tEntOcc), 1:"")
				
				set tCount = tCount+1
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,$lb(+tEntOccId, $li(tEntOcc,1), $li(tEntOcc,2), tSentId, tSourceId, tIsAttributed))
			}
			$$$IKCHECKPAGING(tUsePaging,0,tLast,tCount)
		}
		
	} else {
		
		$$$CHECKVSRCIDEXISTSX(pDomainId,vSrcId,tSC)
		
		set tEntOccId = ""
		for {
			set tEntOccId = $order(^IRIS.IKV.EntOccId(pDomainId, vSrcId, tEntOccId), 1, tEntOcc)
			quit:tEntOccId=""
			
			set tEntUniId = $lg(tEntOcc,1)
			continue:'tEntUniId
			continue:'$d(tEntIds(tEntUniId))
			
			set tIsAttributed = $s(pAttributeId:..IsAttributedInternal(pDomainId, tEntOccId, pAttributeId, tEntOcc, vSrcId), 1:"")
			
			set tCount = tCount+1
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			$$$IKQADDRESULT(pResult,tCount,$lb(+tEntOccId, tEntUniId, $li(tEntOcc,2), tSentId, vSrcId, tIsAttributed))
		}
	}
	
	$$$IKQENDCATCH(pResult,"^||%IK.EntOccIds",tSC)
}

ClassMethod GetLevenshteinDistance(pString1 As %String, pString2 As %String, Output pSC As %Status, pDomainId As %Integer = "") As %Double [ Internal ]
{
	set pSC = $$$OK
	set pString1 = $$$IKNORMALIZED(pString1,pDomainId)
	set pString2 = $$$IKNORMALIZED(pString2,pDomainId)
	
	//HSU033
	set pString1 = $replace(pString1," ","$")
	set pString2 = $replace(pString2," ","$")
	
	quit:pString1=pString2 0
	set tDistance=0
	set pSC = ##class(%DeepSee.extensions.utils.StringMatchUtils).compareMonoGrams(pString1, pString2, .tDistance)
	
	quit $s($$$ISERR(pSC):"", 1:tDistance)
}

/// Given an attribute type (ID) and a list of stored properties, build a key/value array
/// with the right names for each position.
ClassMethod BuildAttributePropArray(pAttributeTypeId As %Integer, pPropList As %List, Output pPropArray) As %Status [ Internal ]
{
	kill pPropArray
	set tSC = $$$OK
	try {
		if (pAttributeTypeId = $$$IKATTCERTAINTY) {
			
			set:$ld(pPropList,1,propValue)&&(propValue'="") pPropArray("level") = propValue
			
		} elseif (pAttributeTypeId = $$$IKATTMEASURE) {
			
			set ptr=0
			
			// first four are fixed
			goto:'$listnext(pPropList,ptr,propValue) done
			set:$g(propValue)'="" pPropArray("value") = propValue
			goto:'$listnext(pPropList,ptr,propValue) done
			set:$g(propValue)'="" pPropArray("unit") = propValue
			goto:'$listnext(pPropList,ptr,propValue) done
			set:$g(propValue)'="" pPropArray("qualifier") = propValue
			goto:'$listnext(pPropList,ptr,propValue) done
			set:$g(propValue)'="" pPropArray("isRange") = propValue
			
			// then it's an unbounded sequence of "value - unit - qualifier" triples
			for n = "second", "third", "fourth", "fifth", "sixth", "seventh", "eigth", "ninth", "tenth", "manyth" {
				quit:'$listnext(pPropList,ptr,propValue)
				set:$g(propValue)'="" pPropArray(n_"Value") = propValue
				quit:'$listnext(pPropList,ptr,propValue)
				set:$g(propValue)'="" pPropArray(n_"Unit") = propValue
				quit:'$listnext(pPropList,ptr,propValue)
				set:$g(propValue)'="" pPropArray(n_"Qualifier") = propValue
			}
done
			
		} else {
			// no properties for other attributes
		} 
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// backward compatibility support for $$$IKATTTYPEPROPS macro.
/// Use <method>BuildAttributeProps</method> for any new development
ClassMethod AttributePropNames(pAttributeTypeId As %Integer, pCount As %Integer = 10) As %List [ Deprecated, Internal ]
{
	set tList = ""
	for i = 1:1:pCount {
		set tList = tList_$lb(i)
	}
	do ..BuildAttributePropArray(pAttributeTypeId, tList, .tArray)
	set k = "", tPropNames = ""
	for {
		set k = $order(tArray(k),1,v)
		quit:k=""
		set tPropNames = tPropNames_$lb(k)
	}
	quit tPropNames
}

}
