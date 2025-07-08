/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>This class contains utility methods to manage the word list used by the decompounding algorithm.
/// Decompounding is about identifying the words making up a compound term, such as the words
/// "thunder" and "storm" in the compound term "thunderstorms". It is used primarily
/// for search purposes, allowing you to find records containing compounds of the search terms too.
/// Lanugages like German, where compounding happens often, require decompounding support for 
/// a good search experience.</p>
/// <h2>Training the decompounder</h2>
/// <p>The decompounding algorithm supplied here requires a list of candidate words it will try to
/// recognize in to-be-decompounded terms. These candidate words can be added through <i>training</i>
/// the algorithm using any of the following methods, which accept free text that will be cut into
/// candidate terms and then stripped of any recognizable compounds:</p>
/// <ul>
/// <li><method>AppendTrainingDataFromQuery</method> loads candidate words from a query result set</li>
/// <li><method>AppendTrainingDataFromFiles</method> loads candidate words from plaintext files</li>
/// <li><method>AppendTrainingDataFromDomain</method> loads candidate words from an iKnow domain</li>
/// </ul>
/// <p>Alternatively, individual words can be added and removed through the <method>AddWord</method>
/// and <method>RemoveWord</method> methods. 
/// Words that should never be separated (returned as a single word) can be registered through 
/// the <method>NeverSeparate</method>.</p>
/// <h2>Invoking the decompounder</h2>
/// <p>Decompounding is used by iFind indices who have their INDEXOPTION set to 2 (see also
/// <class>%iFind.Index.Basic</class>). When subsequently adding records to such an indexed table,
/// all words will be checked for compounding and additional index structures will be populated
/// to allow retrieving records based on the compounding words.</p>
/// <p>The algorithm can also be invoked directly through a <class>%iKnow.Stemmer</class> object,
/// should there be any requirement to find the compounding words of a given term (ie for debug purposes).</p>
/// <example language="COS"> // simple training
///  do ##class(%iKnow.Stemming.DecompoundUtils).AddWord("en", "thunder")
///  do ##class(%iKnow.Stemming.DecompoundUtils).AddWord("en", "storm")
///  // invoke decompounder
///  write ##class(%iKnow.Stemmer).GetDefault("en", .tStemmer)
///  write tStemmer.Decompound("thunderstorms", .tWords)
///  zwrite tWords</example>
Class %iKnow.Stemming.DecompoundUtils [ Deprecated, System = 4 ]
{

/// Loads per-language decompounding properties defined at the system level, appended with 
/// any <method>NeverSeparate</method> annotations saved for the current namespace.
ClassMethod GetLanguageProperties(pLanguage As %String, Output pProps) [ Internal ]
{
	kill pProps
	
	// set top node to Language ID
	set pProps = +##class(%iFind.Filer.Basic).GetLanguageId(pLanguage)
	
	// BDB593 - set required parameters for unknown languages
	set pProps("MinWordLength") = 3
	set pProps("MaxWordLength") = 30
	set pProps("DontSplitCaps") = 1
	
	// load system-based properties from storage
	merge tPropsRaw = ^%iKnow("DC",pLanguage)
	set tType = ""
	for {
		set tType = $order(tPropsRaw(tType),1,tValue)
		quit:tType=""
		
		if $isvalidnum(tType) {
			// unpack lists
			set ptr=0, tMaxLength = 0
			while $listnext(tValue,ptr,tElement) {
				continue:tElement=""
				
				// BDB584 - decode system global contents
				set tElement = $zconvert(tElement,"I","UTF8")
				
				set pProps(tType,tElement)=""
				
				// track max length for select types
				if (tType=$$$IKDCConnector) || (tType=$$$IKDCPrefix) {
					set tLength = $l(tElement)
					set:tLength>tMaxLength tMaxLength = tLength
				}
			}
			set pProps(tType,tElement)=tMaxLength
		} else {
			set pProps(tType) = tValue
		}
	}
	kill tPropsRaw
	
	// also load elements added through NeverSeparate()
	merge pProps("NoSplit") = ^IRIS.IS.Words(pProps,$$$IKSDCNEVERSEPARATE)
}

/// Drops ALL training data for a given language. Use with care.
ClassMethod ClearTrainingData(pLanguage As %String) As %Status
{
	do ..GetLanguageProperties(pLanguage, .tProps)
	kill ^IRIS.IS.Words(tProps)
	quit $$$OK
}

/// <p>Appends word frequency information drawn from the *.txt files in <var>pDirectory</var> to 
/// the word dictionary for decompounding in this namespace.
/// Multiple calls to this method (for different directories) will append to the existing info. 
/// Use <method>ClearTrainingData</method> if you want to drop all existing data.</p>
/// <p>When <var>pClean</var>=1, the generated word list will automatically be cleaned after 
/// loading the new data through a call to <method>CleanWordList</method>. You may use
/// <var>pClean</var>=0 and only call <method>CleanWordList</method> after appending training
/// data from multiple sources, but it should be called once before decompounding any new
/// words through the <class>%iKnow.Stemmer</class> object.</p>
ClassMethod AppendTrainingDataFromFiles(pDirectory As %String = "", pLanguage As %String = "en", pClean As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		do ..GetLanguageProperties(pLanguage, .tProps)
		
		set tRS = ##class(%ResultSet).%New("%Library.File:FileSet")
		set tSC = tRS.%Execute(pDirectory, "*.txt")
		quit:$$$ISERR(tSC)
		
		kill ^||%IK.Words
		
		set tFile = ##class(%Stream.FileCharacter).%New()
		while tRS.%Next() {
			set tSC = tFile.LinkToFile(tRS.%Get("Name"))
			quit:$$$ISERR(tSC)
			
			while 'tFile.AtEnd {
				set tLine = tFile.ReadLine()
				
				set tSC = ..GenerateWords(tLine, .tProps, tProps("DontSplitCaps"))
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set tSC = ..SaveWords(tProps, pVerbose)
		quit:$$$ISERR(tSC)
		
		set:pClean tSC = ..CleanWordList(pLanguage, pVerbose)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IK.Words
	quit tSC
}

/// <p>Appends word frequency information drawn from the first column of the supplied %ResultSet to 
/// the word dictionary for decompounding in this namespace.
/// Multiple calls to this method (for different resultsets) will append to the existing info. 
/// Use <method>ClearTrainingData</method> if you want to drop all existing data.</p>
/// <p>When <var>pClean</var>=1, the generated word list will automatically be cleaned after 
/// loading the new data through a call to <method>CleanWordList</method>. You may use
/// <var>pClean</var>=0 and only call <method>CleanWordList</method> after appending training
/// data from multiple sources, but it should be called once before decompounding any new
/// words through the <class>%iKnow.Stemmer</class> object.</p>
ClassMethod AppendTrainingDataFromQuery(pResultSet As %ResultSet, pLanguage As %String = "en", pClean As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		do ..GetLanguageProperties(pLanguage, .tProps)
		
		kill ^||%IK.Words
		
		while pResultSet.%Next() {
			set tText = pResultSet.%GetData(1)
			set tSC = ..GenerateWords(tText, .tProps, tProps("DontSplitCaps"))
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set tSC = ..SaveWords(tProps, pVerbose)
		quit:$$$ISERR(tSC)
		
		set:pClean tSC = ..CleanWordList(pLanguage, pVerbose)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IK.Words
	quit tSC
}

/// <p>Appends word frequency information drawn from an existing iKnow domain to 
/// the word dictionary for decompounding in this namespace. When <var>pEntType</var>=$$$ENTTYPEANY
/// (default), the full sentence values (with literal info) will be used to derive words. To restrict
/// this to concepts or relations only, use $$$ENTTYPECONCEPT resp. $$$ENTTYPERELATION.</p>
/// <p>Multiple calls to this method (for different resultsets) will append to the existing info. 
/// Use <method>ClearTrainingData</method> if you want to drop all existing data.</p>
/// <p>When <var>pClean</var>=1, the generated word list will automatically be cleaned after 
/// loading the new data through a call to <method>CleanWordList</method>. You may use
/// <var>pClean</var>=0 and only call <method>CleanWordList</method> after appending training
/// data from multiple sources, but it should be called once before decompounding any new
/// words through the <class>%iKnow.Stemmer</class> object.</p>
ClassMethod AppendTrainingDataFromDomain(pDomainName As %String, pLanguage As %String = "en", pEntType As %Integer = {$$$ENTTYPEANY}, pClean As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		set tDomainId = $system.iKnow.GetDomainId(pDomainName)
		if 'tDomainId {
			set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)
			quit
		}
		
		do ..GetLanguageProperties(pLanguage, .tProps)
		
		kill ^||%IK.Words
		
		// if we don't have to care about caps and target a certain entity type, we can
		// get this info straight from entity globals
		set tBuildFlags = ##class(%iKnow.Domain).%OpenId(tDomainId).BuildFlags
		if ('tProps("DontSplitCaps") && (pEntType'=$$$ENTTYPEANY) && $a(tBuildFlags,$$$IKBENTUNIDET)) {
			set tEntUniId = ""
			for {
				set tEntUniId = $order(^IRIS.IK.EntUniDetails(tDomainId,tEntUniId), 1, tDetails)
				quit:tEntUniId=""
				
				set tFreq = $lg(tDetails,$case(pEntType, $$$ENTTYPECONCEPT:1, $$$ENTTYPERELATION:2))
				continue:'tFreq
				
				set tEntity = ^IRIS.IK.EntUniId(tDomainId, tEntUniId)
				set tSC = ..GenerateWords(tEntity, .tProps, 0, tFreq)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
		} else {
			
			set tSentId = ""
			for {
				set tSentId = $order(^IRIS.IK.SentId(tDomainId, tSentId))
				quit:tSentId=""
				
				set tSC = ##class(%iKnow.Queries.SentenceAPI).GetParts(.tParts, tDomainId, tSentId)
				quit:$$$ISERR(tSC)
				
				set i = ""
				for {
					set i = $order(tParts(i), 1, tPart)
					quit:i=""
					
					if (pEntType'=$$$ENTTYPEANY) {
						continue:$lg(tPart,4)'=pEntType
					}
					
					set tLiteral = $lg(tPart,3)
					
					set tSC = ..GenerateWords(tLiteral, .tProps, tProps("DontSplitCaps"))
					quit:$$$ISERR(tSC)
				}
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		
		set tSC = ..SaveWords(tProps, pVerbose)
		quit:$$$ISERR(tSC)
		
		set:pClean tSC = ..CleanWordList(pLanguage, pVerbose)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IK.Words
	quit tSC
}

/// Queues words in a PPG ^||%IK.Words, to be saved by <method>SaveWords</method>
ClassMethod GenerateWords(pText As %String = "", ByRef pLangProps, pTrackCaps As %Boolean = 0, pFreq As %Integer = 1) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tMinWordLength = pLangProps("MinWordLength")
		set tMaxWordLength = pLangProps("MaxWordLength")

		set pText = ..CleanText(pText, pTrackCaps)
		
		set tPos=0, tLen = $l(pText), tFirstWord = 1
		while 1 {
			set tNewPos = $find(pText," ",tPos)
			set tWord = $s(tNewPos:$e(pText,tPos,tNewPos-2), 1:$e(pText,tPos,*))
			
			if pTrackCaps && (tWord=".") { 
				
				// track sentence start in DontSplitCaps mode
				set tFirstWord = 1
				
			} elseif (tWord'="") {
				
				set tWordLen = $s(tNewPos:tNewPos-tPos, 1:tLen-tPos+1)
				if (tWordLen>=tMinWordLength) && (tWordLen<=tMaxWordLength) 
						&& '$d(pLangProps("NoSplit", tWord)) && '$isvalidnum(tWord) {
					
					// in DontSplitCaps mode, track if this word contains capitals and is NOT
					// at the start of a sentence
					if (pTrackCaps) {
						
						set tLower = $$$LOWER(tWord), tHasCaps = (tWord'=tLower)
						set x = $i(^||%IK.Words(tLower, (tHasCaps && 'tFirstWord)), pFreq)
						
					} else {
						set x = $i(^||%IK.Words(tWord, 0), pFreq)
					}
					
					set x = $i(^||%IK.Words, pFreq)
				}
				set tFirstWord = 0
			}
			quit:'tNewPos
			set tPos=tNewPos
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Saves the words queued in ^||%IK.Words by <method>GenerateWords</method>
ClassMethod SaveWords(pLangId As %Integer, pVerbose As %Boolean = 0) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tWord="", tWordCount=0, tNewCount = 0
		for {
			set tWord = $order(^||%IK.Words(tWord))
			quit:tWord=""
			continue:tWord=$$$IKSDCNEVERSEPARATE
			
			set tWithCaps = $g(^||%IK.Words(tWord,1))
			set tNoCaps = $g(^||%IK.Words(tWord,0))
			set tCurrent = $g(^IRIS.IS.Words(pLangId,tWord))
			
			set tWordCount = tWordCount+1
			set:'tCurrent tNewCount = tNewCount+1
			
			if (tNoCaps>=tWithCaps) { // mostly nocaps in new training data
				
				if (tCurrent<0) && ($zabs(tCurrent)>tNoCaps) { // but current is caps and bigger!
					set ^IRIS.IS.Words(pLangId,tWord) = tCurrent - tNoCaps - tWithCaps
				} else { // current is nocaps or smaller
					set ^IRIS.IS.Words(pLangId,tWord) = $zabs(tCurrent) + tNoCaps + tWithCaps
				}
			} else { // mostly caps in new training data
			
				if (tCurrent>0) && ($zabs(tCurrent)>tWithCaps) { // but current is nocaps and bigger
					set ^IRIS.IS.Words(pLangId,tWord) = tCurrent + tNoCaps + tWithCaps
				} else { // current is caps or smaller
					set ^IRIS.IS.Words(pLangId,tWord) = -$zabs(tCurrent) - tNoCaps - tWithCaps
				}
			}
		}
		
		write:pVerbose !,"Saved ",tWordCount," words (",tNewCount," new, ",$g(^||%IK.Words,0)," total occurrences)"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Adds a word to the compound dictionary for the supplied language. The supplied word will be
/// treated as a valid compound element the algorithm will no longer try to split in smaller
/// elements. Optionally supply a positive integer frequency value to increase its weight when
/// multiple options are available.</p>
/// <p>If <var>pWord</var> is also present in the list of strings never to split off through a 
/// call to <method>NeverSeparate</method>, it will be removed from that list.</p>
/// <p>When performing a lot of manual updates, it is recommended to set <var>pClean</var>=0 and
/// only run the <method>CleanWords</method> method once after all additions, to verify if these new
/// additions indicate particular existing words should be removed as they turn out to be compounds
/// themselves.</p>
ClassMethod AddWord(pLanguage As %String, pWord As %String, pFrequency As %Integer = 1, pClean As %Boolean = 1, pVerbose As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		quit:pWord=$$$IKSDCNEVERSEPARATE
		do ..GetLanguageProperties(pLanguage, .tProps)
		
		if (pWord="") || ($l(pWord)>$$$IKHASHSIZE) || 'pFrequency {
			set tSC = $$$ERROR($$$InvalidArgument)
			quit
		}
		
		kill ^IRIS.IS.Words(tProps,$$$IKSDCNEVERSEPARATE,pWord)
		set tFreq = -$zabs($g(^IRIS.IS.Words(tProps,pWord)))-$zabs(pFrequency)
		set ^IRIS.IS.Words(tProps,pWord) = tFreq
		set x = $i(^IRIS.IS.Words(tProps), $zabs(pFrequency))
		w:pVerbose !,"Saving word '",pWord,"' with frequency ",$zabs(tFreq),!
		
		set:pClean tSC = ..CleanWordList(pLanguage, pVerbose,, pWord)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Removes a word from the compound dictionary for the supplied language. This word will no longer
/// be treated as a valid compound element. Use this to clear the list of eventual composite words
/// added previously.
ClassMethod RemoveWord(pLanguage As %String, pWord As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:pWord=$$$IKSDCNEVERSEPARATE
		do ..GetLanguageProperties(pLanguage, .tProps)
		
		if (pWord="") || ($l(pWord)>$$$IKHASHSIZE) {
			set tSC = $$$ERROR($$$InvalidArgument)
			quit
		}
		
		quit:'$d(^IRIS.IS.Words(tProps,pWord),tFreq)
		kill ^IRIS.IS.Words(tProps,pWord)
		set x = $i(^IRIS.IS.Words(tProps), -$zabs(tFreq))
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Marks <var>pString</var> as a character sequence that should never be split off and
/// therefore never be returned as a compound element of its own.
/// If this string was also part of the compound dictionary as a candidate, it will be removed
/// automatically as if calling <method>RemoveWord</method>
ClassMethod NeverSeparate(pLanguage As %String, pString As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:pString=$$$IKSDCNEVERSEPARATE
		
		set tSC = ..RemoveWord(pLanguage, pString)
		quit:$$$ISERR(tSC)
		
		do ..GetLanguageProperties(pLanguage, .tProps)
		
		if (pString="") || ($l(pString)>$$$IKHASHSIZE) {
			set tSC = $$$ERROR($$$InvalidArgument)
			quit
		}
		
		set ^IRIS.IS.Words(tProps,$$$IKSDCNEVERSEPARATE,pString) = 0
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod CleanText(pText As %String, pKeepCaseAndSent As %Boolean = 0) As %String [ Internal ]
{
	if pKeepCaseAndSent {
		set pText = $translate(pText,".!?,;-/()[]{}<>*$&@£%=+~\'""", "...                                ")
		set pText = $zstrip(pText,"*PC",," .")
		set pText = $replace(pText,".", " . ")
	} else {
		set pText = $translate(pText,".!?,;-/()[]{}<>*$&@£%=+~\'""", "                                ")
		set pText = $$$LOWER($zstrip(pText,"*PC",," "))
	}
	quit pText
}

/// Clears any identifiable compounds from the current decompound dictionary for <var>pLanguage</var>.
/// This method should be run at least once between appending data to the training set through any
/// of the Append* methods in this class and using the Decompound() method in a <class>%iKnow.Stemmer</class>
/// object.
ClassMethod CleanWordList(pLanguage As %String = "en", pVerbose As %Boolean = 0, pOutputFile As %String = "", pFilter As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		write:pVerbose !,"Cleaning current word list for language '",pLanguage,"'"
		do ..GetLanguageProperties(pLanguage, .tProps)
		
		set tSC = ##class(%iKnow.Stemmer).GetDefault(pLanguage, .tStemmer)
		quit:$$$ISERR(tSC)
		
		if pOutputFile'="" {
			set tFile = ##class(%Stream.FileCharacter).%New()
			set tSC = tFile.LinkToFile(pOutputFile)
			quit:$$$ISERR(tSC)
      		do tFile.Write($CHAR(239)_$CHAR(187)_$CHAR(191)) // utf8 BOM
			set tFile.TranslateTable = "UTF8"
		}
		
		set tWord = "", tTotal=0, tDropped=0
		for {
			set tWord = $order(^IRIS.IS.Words(tProps,tWord),1,tWordFreq)
			quit:tWord=""
			continue:tWord=$$$IKSDCNEVERSEPARATE
			
			if (pFilter'="") {
				continue:'$find(tWord,pFilter)
			}
			
			set tTotal = tTotal+1
			set tSC = tStemmer.DecompoundInternal(tWord, .tCompounds, .tProps,, 0, 1)
			quit:$$$ISERR(tSC)
			
			if $d(tCompounds, tCount) && (tCount>1) {
				set tCompFreqs = "", tCompWords = ""
				
				// get rid of compound entries
				kill ^IRIS.IS.Words(tProps,tWord)
				set tDropped=tDropped+1
				
				if (pVerbose>1) || (pOutputFile'="") {
					for i = 1:1:tCount {
						s tCompWords = tCompWords_$s(i=1:"", 1:" ")_$lg(tCompounds(i),1)
						s tCompFreqs = tCompFreqs_$s(i=1:"", 1:" ")_$lg(tCompounds(i),2)
					}
				}
				
				w:pVerbose>1 !,"Dropping '",tWord,"' (",tWordFreq,") >> "_tCompWords_" ("_tCompFreqs_")"
				
				if (pOutputFile'="") {
					set tSC = tFile.WriteLine(tWord_";"_tWordFreq_";"_tCompWords_";"_tCompFreqs)
					quit:$$$ISERR(tSC)
				}
			}
		}
		quit:$$$ISERR(tSC)
		
		if (pOutputFile'="") {
			set tSC = tFile.%Save()
			quit:$$$ISERR(tSC)
		}
		
		w:pVerbose !,"Dropped ",tDropped," compound words out of ",tTotal," in dictionary",!
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod ConvertHiraganaNumbers(pString As %String) As %String [ Internal ]
{
	set tString = ""
	for i = 1:1 {
		set tToken = $a(pString,i)
		quit:tToken<0
		if (tToken>=$zhex("FF10")) && (tToken<=$zhex("FF19")) {
			set $e(pString,i) = (tToken-$zhex("FF10"))
		}
	}
	quit pString
}

ClassMethod IsKatakana(pString As %String) As %Boolean [ Internal ]
{
	set tIsKatakana = 1
	for i = 1:1 {
		set tToken = $ascii(pString,i)
		quit:tToken<0 // end of string
		if (tToken<=$zhex("309F")) || (tToken>=$zhex("30FF")) {
			set tIsKatakana = 0
			quit
		}
	}
	quit tIsKatakana
}

/// Loads default stemming properties from the KB files. 
/// FOR INTERNAL USE ONLY.
/// DO NOT INVOKE THIS METHOD.
ClassMethod LoadDefaultPropertiesCSV(pPath As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill tProps
		
		set tFile = ##class(%Stream.FileCharacter).%New()
		set tFile.Filename = pPath
		do tFile.Rewind()
		
		while 'tFile.AtEnd {
			set tLine = $zstrip($piece(tFile.ReadLine(),"//",1),"<>W")
			continue:tLine=""
			
			// BDB584
			set tLine = $zconvert(tLine,"O","UTF8")
			
			set tLanguage = $piece(tLine,";",1)
			set tType = $piece(tLine,";",2)
			set tValue = $piece(tLine,";",3)
			
			set tType = $case(tType, "Connector":$$$IKDCConnector, "NoSplit":$$$IKDCNoSplit, "NoSplitEnd":$$$IKDCNoSplitEnd, "Prefix":$$$IKDCPrefix, "Suffix":$$$IKDCSuffix, "Hyphen":$$$IKDCHyphen, "NotFirstChar":$$$IKDCNotFirstChar, :tType)
			
			if $isvalidnum(tType) {
				set tProps(tLanguage, tType) = $g(tProps(tLanguage,tType))_$lb(tValue)
			} else {
				set tProps(tLanguage, tType) = tValue
			}
		}
		
		kill ^%iKnow("DC")
		merge ^%iKnow("DC") = tProps
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
