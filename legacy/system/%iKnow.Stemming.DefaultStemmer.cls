/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class encapsulates logic to instantiate, use and amend stemmers for different languages.
/// Plugin selection behavior per language is as follows: if a valid Hunspell affix and dictionary file is found in
/// the /dev/hunspell subdirectory of your installation location (either named [language code]_*.aff
/// or in a subdirectory named after the language code), a <class>HunspellStemmer</class>
/// object will be instantiated to treat stemming requests for that language. If no such library is
/// found, the corresponding <class>TextStemmer</class> will be instantiated.</p>
/// <p>If the <method>StemWord</method> method is invoked for a particular language, this class will
/// first look up the supplied string in the list of exceptions. If no exceptions are found (either
/// default exceptions supplied with iKnow or custom exceptions in the <class>Rule</class> table
/// for this namespace), the StemWord method of the instantiated Stemmer plugin object will be
/// invoked. If the plugin supports returning multiple results, these will be filtered and only the
/// first result satisfying the corresponding rules (stored in the iKnow language model or the 
/// <class>Rule</class>) will be returned.</p>
Class %iKnow.Stemming.DefaultStemmer Extends %iKnow.Stemmer [ Deprecated, System = 4 ]
{

/// Array of language-specific stemmers in use by this default stemmer
Property Stemmers [ Internal, MultiDimensional, Private ];

/// Default language to use when not specified in calls to <method>Stem</method>
Property DefaultLanguage As %String [ InitialExpression = "en" ];

/// Array of stemming rules to apply, indexed by language
/// (sub-index levels specific to stemming plugin type)
Property Rules [ Internal, MultiDimensional ];

/// Internal method to retrieve a stemmer object for <var>pLanguage</var>, initializing
/// one if it does not exist yet.
Method GetStemmerObject(pLanguage As %String) As %iKnow.Stemmer [ Internal ]
{
	set tSC = $$$OK, tStemmer=""
	try {
	
		quit:$d(..Stemmers(pLanguage), tStemmer)
		
		set tSC = ..InitializeLanguage(pLanguage)
		quit:$$$ISERR(tSC)
		
		set tStemmer = ..Stemmers(pLanguage)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// THROW error back!
	if $$$ISERR(tSC) { $$$ThrowStatus(tSC) }
	
	quit tStemmer
}

/// Initializes the default stemmer object for a particular language
Method InitializeLanguage(pLanguage As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		// if particular languages require particular stemmers to be loaded, this is where
		// such a decision should be made. Currently, we just try to locate hunspell libraries
		// for pLanguage and use %Text otherwise.
		
				
		// first try to instantiate a Hunspell stemmer by looking into the
		// INSTALL_DIR/dev/hunspell folder
		set tSeparator = $s($$$isWINDOWS:"\",$$$isUNIX:"/",$$$isVMS:"")
		set tDirectory = $System.Util.InstallDirectory()
		set:$e(tDirectory,*)'=tSeparator tDirectory = tDirectory_tSeparator
		set tDirectory = tDirectory_"dev"_tSeparator_"hunspell"_tSeparator
		
		// first check "/dev/hunspell/[langcode]/*.aff"
		set tResultSet = ##class(%ResultSet).%New("%Library.File:FileSet")
		set tSC = tResultSet.Execute(tDirectory, pLanguage_tSeparator_"*.aff")
		quit:$$$ISERR(tSC)
		set tHasFile = tResultSet.%Next()
		if 'tHasFile { // also check "/dev/hunspell/[langcode]*.aff"
			set tSC = tResultSet.Execute(tDirectory, pLanguage_"*.aff")
			quit:$$$ISERR(tSC)
			set tHasFile = tResultSet.%Next()
		}
		if (tHasFile) {
			set tAffixFile = tResultSet.%Get("Name")
			set tDictFile = $piece(tAffixFile,".",1,*-1)_".dic"
			set tStemmerConfig = ##class(%iKnow.Stemming.HunspellConfig).%New("temp")
			set tStemmerConfig.AffixFile = tAffixFile, tStemmerConfig.DictionaryFile = tDictFile
			set tSC = tStemmerConfig.CreateStemmerObject(.tStemmer)
			quit:$$$ISERR(tSC)
			set tStemmerConfig="", tPlugin = "Hunspell"
		}
		
		
		else { 
			// if no hunspell dictionary was found, try %Text fallback
			set tStemmer = ##class(%iKnow.Stemming.TextStemmer).%New(pLanguage)
			set tPlugin = "%Text"
		}
		
		if '$isobject(tStemmer) {
			set tSC = $$$ERROR($$$GeneralError, "Unable to instantiate stemmer for language '"_pLanguage_"'")
			quit
		}
		
		set ..Stemmers(pLanguage) = tStemmer
		
		
		// load applicable rules
		set tSC = ..LoadRules(pLanguage, tPlugin)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Forwards to specialized implementations, according to the plugin being used
Method StemWord(pToken As %String, pLanguage As %String = "", pLexType As %Integer = {$$$ENTTYPECONCEPT}, pEntity As %String = "") As %String [ Internal ]
{
	
	quit:pToken="" ""
	quit:pLanguage=" " // If the KB's metadata does not specify a language code, the default is a space. In that case, do *not* stem.
	set:pLanguage="" pLanguage = ..DefaultLanguage
	
	// load stemmer object, which implies loading rules (incl exceptions!)
	set tStemmer = ..GetStemmerObject(pLanguage)
	
	
	// first check exceptions
	set tIsException = $s($l(pToken)<$$$IKHASHSIZE:$d(i%Rules(pLanguage, $$$IKSTEMEXCEPTION, +pLexType, pToken), tStem), 1:0)
	if (tIsException>1) && (pEntity'="") { 
		// try advanced exceptions: 
		//		..Rules(pLanguage, $$$IKSTEMEXCEPTION, pLexType, pToken, i) = $lb([piece], [stem])
		//		if ([piece] occurs in [pEntity]) => return [stem]
		set tEntity = " "_$tr(pEntity,"-,.;:!?_","        ")_" "
		set i="", tFound=0
		for {
			set i = $order(i%Rules(pLanguage,$$$IKSTEMEXCEPTION,+pLexType,pToken,i), 1, tStemInfo)
			quit:i=""
			if ($f(tEntity, " "_$lg(tStemInfo,1)_" ")) {
				set tFound = 1, tStem = $lg(tStemInfo,2)
				quit
			}
		}
		quit:tFound tStem
	}
	// check if we found a simple word-based exception (if no rules fired)
	quit:(tIsException#2)&&($g(tStem)'="") tStem
	
	// if not an exception, delegate to plugin
	if tStemmer.%IsA("%iKnow.Stemming.HunspellStemmer") {
		
		// delegate to Hunspell-specific treatment
		quit ..StemWordHunspell(tStemmer, pToken, pLanguage, pLexType, pEntity)
		
	} else {
		
		// no customizations for non-hunspell stemmer objects
		quit tStemmer.StemWord(pToken, pLanguage, pLexType, pEntity)
		
	}
}

/// Starting point for advanced resolution of hunspell stemming results.
/// Stems <var>pToken</var> using <var>pStemmer</var> by testing it first in the capitalization
/// supplied initially and then with initcaps and all-caps in case no stem was found.
/// Relays to <method>StemWordHunspellRules</method> for the actual stemming.
Method StemWordHunspell(pStemmer As %iKnow.Stemming.HunspellStemmer, pToken As %String, pLanguage As %String, pLexType As %Integer = {$$$ENTTYPECONCEPT}, pEntity As %String = "") As %String [ Private ]
{
	set tStem = ..StemWordHunspellRules(pStemmer, pToken, pLanguage, pLexType, pEntity, .tHasMatch)
	
	// BDB540: test different capitalization options if the original does not return a hit
	// (and if it wasn't simply refused through rules
	if 'tHasMatch {
		// if the supplied capitalization does not work, try initcaps
		set tStem = ..StemWordHunspellRules(pStemmer, $$$UPPER($e(pToken))_$$$LOWER($e(pToken,2,*)), pLanguage, pLexType, pEntity, .tHasMatch)
	
		// if still no hit found, try all-upercase
		set:'tHasMatch tStem = ..StemWordHunspellRules(pStemmer, $$$UPPER(pToken), pLanguage, pLexType, pEntity)
		
		// if the input was all-lowercase, ensure the result is too
		set:tHasMatch&&($$$LOWER(pToken)=pToken) tStem = $$$LOWER(tStem)
	}
	
	// BDB599: avoid stripping off prefixes
	if tHasMatch {
		set tPos = $find(pToken, tStem)
		if (tPos) {
			set tPrefix = $e(pToken,1,tPos-$l(tStem)-1)
			set tStem = tPrefix_tStem
		}
	}
	
	quit tStem
}

/// For a given token, goes through all the results presented by Hunspell and then decides
/// which option to return (if any at all), based on the rules returned by
/// <method>GetHunspellRules</method>, using context information such as <var>pLexType</var>
Method StemWordHunspellRules(pStemmer As %iKnow.Stemming.HunspellStemmer, pToken As %String, pLanguage As %String, pLexType As %Integer = {$$$ENTTYPECONCEPT}, pEntity As %String = "", Output pHasMatch As %Boolean) As %String [ Private ]
{
	// fetch language-specific rules to override hunspell stemming result or
	// choose between multiple returned results
	merge tRules = ..Rules(pLanguage)
	if $d(tRules) {
		
		// retrieve all results
		do pStemmer.Analyze(pToken, .tResult)
		//zw tResult
		
		// return if no matches 
		set pHasMatch = ''tResult
		quit:'pHasMatch ""
		
		set tMaxEndLength = $g(tRules($$$IKSTEMENDING,"MaxLength"),0)
		set tMinEndLength = $g(tRules($$$IKSTEMENDING,"MinLength"),1)
		set tStem=""
		for i = 1:1:tResult {
			//w !,"checking ",tResult(i,"st")
			
			// check affix-based rules
			if $d(tResult(i,"fl"),tAffixCode) {
				continue:(pLexType=$$$ENTTYPECONCEPT)&&$d(tRules($$$IKSTEMAFFIX, $$$IKSTEMNOCONCEPT, tAffixCode))
				continue:(pLexType=$$$ENTTYPERELATION)&&$d(tRules($$$IKSTEMAFFIX, $$$IKSTEMNORELATION, tAffixCode))
			}
			
			// check ending-based rules
			if (tMaxEndLength) {
				set tEnding = $$$LOWER($e(tResult(i, "st"), *-tMaxEndLength+1, *))
				set tRulesPass = 1
				for j = tMaxEndLength:-1:tMinEndLength {
					quit:tEnding=""
					
					// check rules					
					if (pLexType=$$$ENTTYPECONCEPT) && $d(tRules($$$IKSTEMENDING, $$$IKSTEMNOCONCEPT, tEnding)) {
						//write !,tResult(i,"st")," ends with ",tEnding,", so no concept!"
						set tRulesPass = 0
						quit
					}
					if (pLexType=$$$ENTTYPERELATION)&&$d(tRules($$$IKSTEMENDING, $$$IKSTEMNORELATION, tEnding)) {
						//write !,tResult(i,"st")," ends with ",tEnding,", so no relation!"
						set tRulesPass = 0
						quit
					}
					
					// shorten ending
					set tEnding = $e(tEnding,2,*)
				}
				
				// skip if rules don't pass
				continue:'tRulesPass
			}
			
			// all rules passed, so use this stem
			set tStem = tResult(i, "st")
			quit
		}
		quit tStem
		
		
	} else {
		
		// if no rules specified, just use default StemWord()
		set tStem = pStemmer.StemWord(pToken)
		set pHasMatch = (tStem'="")
		quit tStem
	}
}

/// Retrieves a set of rules to customize or overrule plugin output, based on default rules 
/// returned by <method>GetDefaultRules</method> and the content of the <class>%iKnow.Stemming.Rule</class>
/// table.
/// Any result retrieved by a plugin will have to pass these rules (where applicable) or it
/// will not be returned. Note that this may result in no results to be passed back at all!
Method LoadRules(pLanguage As %String, pPlugin As %String) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		// load default rules
		kill tRules, i%Rules(pLanguage)
		merge tRaw = ^%iKnow("SR", pLanguage, $$$IKSTEMPLUGINALL)
		
		set tPlugin = $case(pPlugin, "Hunspell":$$$IKSTEMPLUGINHUNSPELL, :-1)
		merge:tPlugin>0 tRaw = ^%iKnow("SR", pLanguage, tPlugin)
		
		// BDB584 - decode UTF8
		set tType=""
		for {
			set tType = $order(tRaw(tType))
			quit:tType=""
			
			set tSpec=""
			for {
				set tSpec=$order(tRaw(tType,tSpec))
				quit:tSpec=""
				
				set tValue=""
				for {
					set tValue=$order(tRaw(tType,tSpec,tValue))
					quit:tValue=""
					
					if $d(tRaw(tType,tSpec,tValue),tReplace)#10 {
						set tRules(tType,tSpec,$zconvert(tValue,"I","UTF8")) = $zconvert(tReplace,"I","UTF8")
					}
					
					set tIndex=""
					for {
						set tIndex = $order(tRaw(tType,tSpec,tValue,tIndex),1,tData)
						quit:tIndex=""
						
						set tData = $lb($zconvert($lg(tData,1),"I","UTF8"),$zconvert($lg(tData,2),"I","UTF8"))
						set tRules(tType,tSpec,$zconvert(tValue,"I","UTF8"),tIndex) = tData
					}
				}
			}
		}
		
		// load custom rules and exceptions from %iKnow.Stemming.Rule
		set tStatement = ##class(%SQL.Statement).%New()
		&sql(DECLARE cRules CURSOR FOR 
				SELECT Type, Spec, Value, Replace, Entity
				INTO :tType, :tSpec, :tValue, :tReplace, :tEntity
				FROM %iKnow_Stemming.Rule 
				WHERE LanguageCode = :pLanguage AND Plugin IN ('All', :pPlugin)
		)
		
		&sql(OPEN cRules)
		if SQLCODE {
			set tSC = $system.Error.FromSQLCode(SQLCODE).AsStatus()
		} else {
		for {
			&sql(FETCH cRules)
			quit:SQLCODE
			
			set tType = $case(tType, "Exception":$$$IKSTEMEXCEPTION, "Ending":$$$IKSTEMENDING, "Affix":$$$IKSTEMAFFIX, :-1)
			set tSpec = $case(tSpec, "NoConcept":$$$IKSTEMNOCONCEPT, "NoRelation":$$$IKSTEMNORELATION, "Concept":$$$ENTTYPECONCEPT, "Relation":$$$ENTTYPERELATION, :tSpec)
			
			if (tType = $$$IKSTEMEXCEPTION) && (tEntity'="") {
				set tIndex = $o(tRules($$$IKSTEMEXCEPTION, tSpec, tValue,""),-1)+1
				set tRules($$$IKSTEMEXCEPTION, tSpec, tValue, tIndex) = $lb(tEntity, tReplace)
			} else {
				set tRules(tType, tSpec, tValue) = tReplace
			}
		}
		if (SQLCODE'=100) {
			set tSC = $system.Error.FromSQLCode(SQLCODE).AsStatus()
		}
		&sql(CLOSE cRules)
		if SQLCODE<0 s tSC = $$$ADDSC(tSC,$system.Error.FromSQLCode(SQLCODE).AsStatus())
		}
		quit:$$$ISERR(tSC)
		
		
		// derive min and max ending length
		set tRule="", tMaxLen="", tMinLen=""
		for {
			set tRule = $order(tRules($$$IKSTEMENDING, tRule))
			quit:tRule=""
			
			set tValue=""
			for {
				set tValue = $order(tRules($$$IKSTEMENDING, tRule, tValue))
				quit:tValue=""
				set tLength = $length(tValue)
				set:(tLength>tMaxLen) tMaxLen = tLength
				set:(tMinLen="")||(tLength<tMinLen) tMinLen = tLength
			}
		}
		set:tMaxLen tRules($$$IKSTEMENDING,"MaxLength") = tMaxLen
		set:tMinLen tRules($$$IKSTEMENDING,"MinLength") = tMinLen
		
		// store
		merge i%Rules(pLanguage) = tRules
			
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnNew(pDefaultLanguage As %String) As %Status [ Private, ServerOnly = 1 ]
{
	set pDefaultLanguage = $zstrip(pDefaultLanguage,"*W")
	if (pDefaultLanguage="*") || (pDefaultLanguage="") {
		quit $$$OK
	} else {
		set tCount = $l(pDefaultLanguage,","), tSC = $$$OK
		for i = 1:1:tCount {
			set tLanguage = $piece(pDefaultLanguage,",",i)
			set:i=1 ..DefaultLanguage = tLanguage
			set tSC = ..InitializeLanguage(tLanguage)
			quit:$$$ISERR(tSC)
		}
		quit tSC
	}
}

/// Reloads underlying stemmer implementations and rules
Method Reload() As %Status
{
	kill ..Stemmers
	kill ..Rules
	quit ##super()
}

}
