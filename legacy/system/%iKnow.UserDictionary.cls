/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p>This class represents User Dictionaries, used to rewrite fragments of input data
/// specific to a particular use case.</p>
/// <p>When creating a User Dictionary, you can pass initial values for the following properties
/// to its <method>%New</method> method:
/// <ol>
/// 	<li><property>Name</property> (required)</li>
/// 	<li><property>Description</property></li>
/// </ol>
/// Check the respective property descriptions for more details.</p>
Class %iKnow.UserDictionary Extends %Persistent [ Deprecated, StorageStrategy = SqlStorage, System = 4 ]
{

Property Id As %Integer [ Final, ReadOnly ];

Property Name As %String [ Final, ReadOnly ];

Property Description As %String [ Final ];

/// This property is used for transient versions only
Property IsTransient As %Boolean [ InitialExpression = 0, Internal, Private, Transient ];

Index PKINDEX On Id [ IdKey, PrimaryKey, Unique ];

Index NameIndex On Name [ Unique ];

Property Normalizer As %iKnow.Configuration [ Internal, Private, Transient ];

Method NormalizerGet() As %iKnow.Configuration [ Internal, ServerOnly = 1 ]
{
	if i%Normalizer = $$$NULLOREF {
		set i%Normalizer = ##class(%iKnow.Configuration).CreateTransientConfig()
	}
	quit i%Normalizer
}

Method NextEntry(pKey As %Integer) As %Integer [ Internal ]
{
	if '..IsTransient {
		quit $order(^IRIS.IK.Sys.UserDictEntry(i%Id, pKey))
	} else {
		quit $order(^||%IK.UserDict(pKey))
	}
}

Method GetEntry(pKey As %Integer) As %List [ Internal ]
{
	if '..IsTransient {
		quit:'$d(^IRIS.IK.Sys.UserDictEntry(i%Id, +pKey), tData) ""
	} else {
		quit:'$d(^||%IK.UserDict(+pKey), tData) ""
	}
	
	// make sure any attribute tokens we pass to the engine are normalized
	set tToken = $li(tData,1)
	if $e(tToken)="@" {
		set tNormalized = ..Normalizer.Normalize($e(tToken,2,*))
		
		// if there's nothing to normalize, Normalize() may return ""
		set:tNormalized'="" tToken = "@"_tNormalized 
	}
	quit $lb($zconvert(tToken,"O","UTF8"), $zconvert($li(tData,2),"O","UTF8"), $zconvert($lg(tData,3),"O","UTF8"))
}

/// <p>Returns a User Dictionary object by name. First, this method checks if <var>pName</var> 
/// is a name used by any saved User Dictionary object. If none found, it is used as a file
/// path for the legacy file-based User Dictionaries. If there is no file at this path,
/// "" is returned.</p>
/// <p><b>Note</b>: file-based User Dictionaries are deprecated. Please use object-based ones
/// by using <method>%New</method>, <method>%Save</method> and <method>AddEntry</method>.</p>
ClassMethod OpenByName(pName As %String) As %iKnow.UserDictionary
{
	set tSC = $$$OK
	try {
		set tUserDict = ..NameIndexOpen(pName)
		set:(tUserDict="") tUserDict = ..CreateFromFile(pName)
	} catch (ex) {
		set tUserDict = ""
	}
	quit $s($$$ISERR(tSC):"", 1:tUserDict)
}

/// Creates a UserDictionary instance based on a file containing comma-separated from/to
/// pairs on each line. The instance produced by this classmethod is transient and cannot
/// be saved through %Save()
ClassMethod CreateFromFile(pPath As %String) As %iKnow.UserDictionary [ Internal ]
{
	set tSC = $$$OK
	try {
		set tUserDict = ..CreateTransient(pPath)
	
		set tFile = ##class(%Stream.FileCharacter).%New()
		set tFile.Filename = pPath
		if ('tFile.FileBinarySize()) {
			set tUserDict = ""
			quit
		}
		// We need an indexer with a loaded language for token normalization, to be in sync with the KB model.
		// We load "en", but any language would do (except for Japanese), since normalization is (mostly) language independent.
		// Better would be to specify a language for the user dictionary, but this is currently not (yet) the case. 
		Set objIDX=##class(%iKnow.Indexer).%New()
		Set kb=##class(%iKnow.KB.Knowledgebase).GetByName("en")
		Set tSC = objIDX.LoadKnowledgebase("en",kb)
		If 'tSC do $System.status.DisplayError(tSC) halt

		while 'tFile.AtEnd {
			set tLine = tFile.ReadLine(,.tSC)
			quit:$$$ISERR(tSC)
			
			// BDB463: skip empty input
			continue:$piece(tLine,",",1)=""
			continue:(($extract(tLine)="/")&&($extract(tLine,2)="*")) // starting with comment

			Set Key=$piece(tLine,",",1)	// Key & Value encoding here is 16bit Unicode
			Set Value=$piece(tLine,",",2)
			Set Meta=$piece(tLine,",",3) // Metadata is new, and firstly used for UDCertainty
			
			If $Extract(Key)="@" { // Lexrep -> Label annotator, lexrep must be normalized !
				Set Lexrep=$Extract(Key,2,*)
				Set normalizedLexrep=""
				Set tSC=objIDX.Normalize(Lexrep,.normalizedLexrep,"en")
				If 'tSC do $System.status.DisplayError(tSC) halt
				Set Key="@"_normalizedLexrep
			}
			set ^||%IK.UserDict($i(^||%IK.UserDict)) = $lb(Key, Value, Meta)
		}
		Set tSC=objIDX.UnloadKnowledgebase("en") // This is needed for genIknow, if not unloaded, the chosen language is "en"
		Kill objIDX // we only temporarily need the indexer, for lexrep normalization.
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tUserDict = ""
	}
	quit $s($$$ISERR(tSC):"", 1:tUserDict)
}

ClassMethod CreateTransient(pName As %String = "") As %iKnow.UserDictionary [ Internal ]
{
	set tSC = $$$OK
	try {
		set:pName="" pName = $random(99999999)
		set tUserDict = ..%New(pName)
		set tUserDict.IsTransient = 1
		kill ^||%IK.UserDict
	} catch (ex) {
		set tUserDict = ""
	}
	quit $s($$$ISERR(tSC):"", 1:tUserDict)
}

Method %OnNew(pName As %String, pDescription As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVADMINX(tSC)
		$$$IKCHECKNOTNULLX(pName,tSC)
		$$$IKCHECKSTRINGLENGTHX(pName,tSC)
		
		// check for name uniqueness right away, as it's a read-only propery
		// and the index is only validated after %OnBeforeSave() otherwise
		if ..NameIndexExists(pName) {
			set tSC = $$$ERROR($$$IKUserDictWithNameExists, pName)
			quit
		}
		
        set i%Name = pName
        set i%Description = pDescription
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVADMIN
	quit:..IsTransient $$$ERROR($$$GeneralError, "Cannot save transient UserDict")
	
	set tSC = $$$OK
	try {
		
		if (insert) {
			
	        // if OK, fetch new ID and populate properties
    	    set i%Id = $i(^IRIS.IK.Sys.UserDictD)
    	    
		} else {
		
			set tSC = ..CheckIfManaged($this)
			quit:$$$ISERR(tSC)
			
		}
        
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Removes all entries from this user dictionary (only relevant for non-transient ones)
Method ClearEntries() As %Status
{
	$$$IKCHECKPRIVADMIN
	set tSC = $$$OK
	try {
		set tSC = ..CheckIfManaged($this)
		quit:$$$ISERR(tSC)
		
		if ..IsTransient {
			kill ^||%IK.UserDict
		} else {
			kill ^IRIS.IK.Sys.UserDictEntry(..Id)
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVADMIN
	set tSC = $$$OK
	try {
		set tUserDict = ..%Open(oid)
		if '$isobject(tUserDict) { set tSC = $$$ERROR($$$IKNoUserDictWithId, oid)  quit  }
		
		set tSC = ..CheckIfManaged(tUserDict)
		quit:$$$ISERR(tSC)
		
		kill ^IRIS.IK.Sys.UserDictEntry(tUserDict.Id)
		
		set tUserDict=""
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  <p>Adds a single entry to this User Dictionary at <var>position</var>. If <var>position</var> <= 0 (default=0),
///  it is added at the bottom of the list, otherwise at the requested position, shifting
///  existing entries down if it was already taken.</p>
///  <p>These changes are saved automatically. There is no need to call <method>%Save</method></p>
Method AddEntry(pRewriteFrom As %String, pRewriteTo As %String, ByRef pPosition As %Integer = 0) As %Status
{
	$$$IKCHECKPRIVADMIN
	quit:..%IsModified()&&'..IsTransient $$$ERROR($$$IKObjectModified, "User Dictionary")
	
	set tSC = $$$OK, tTLevel = $tlevel
	try {
		$$$IKCHECKNOTNULLX(pRewriteFrom,tSC)
		$$$IKCHECKNOTNULLX(pRewriteTo,tSC)
		
		set tSC = ..CheckIfManaged($this)
		quit:$$$ISERR(tSC)
		
		if ('..IsTransient) {
			$$$IKLOCKX(..Id,^IRIS.IK.Sys.UserDictD,tSC)
		}
		
		tstart
		
		set gUserDictEntry = $s(..IsTransient:"^||%IK.UserDict", 1:$name(^IRIS.IK.Sys.UserDictEntry(..Id)))
		
		// if no position supplied, just take the next free slot
		if (pPosition<=0) {
			set pPosition = $o(@gUserDictEntry@(""),-1)+1
		}
	
		// shift all positions < position backwards if it was already taken
		if $d(@gUserDictEntry@(pPosition),tData) {
			kill ^||%IK.UserDictEntry
			set tPos = pPosition
			for {
				set ^||%IK.UserDictEntry(tPos+1) = tData
				kill @gUserDictEntry@(tPos)
				set tPos = tPos+1
				quit:'$data(@gUserDictEntry@(tPos),tData)
			}
			merge @gUserDictEntry = ^||%IK.UserDictEntry
			kill ^||%IK.UserDictEntry
		}
	
		set @gUserDictEntry@(pPosition) = $lb(pRewriteFrom, pRewriteTo)
		
		tcommit
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel) 1
	
	if ('..IsTransient) {
		$$$IKUNLOCK(..Id,^IRIS.IK.Sys.UserDictD)
	}
	
	quit tSC
}

Method AddNegationTerm(pWord As %String, Output pPosition As %Integer) As %Status
{
	quit ..AddAttribute(pWord, "UDNegation", .pPosition)
}

Method AddPositiveSentimentTerm(pWord As %String, Output pPosition As %Integer) As %Status
{
	quit ..AddAttribute(pWord, "UDPosSentiment", .pPosition)
}

Method AddNegativeSentimentTerm(pWord As %String, Output pPosition As %Integer) As %Status
{
	quit ..AddAttribute(pWord, "UDNegSentiment", .pPosition)
}

Method AddNumber(pWord As %String, Output pPosition As %Integer) As %Status
{
	quit ..AddAttribute(pWord, "UDNumber", .pPosition)
}

Method AddTime(pWord As %String, Output pPosition As %Integer) As %Status
{
	quit ..AddAttribute(pWord, "UDTime", .pPosition)
}

Method AddUnit(pWord As %String, Output pPosition As %Integer) As %Status
{
	quit ..AddAttribute(pWord, "UDUnit", .pPosition)
}

/// Use <var>pLevel</var> to specify the level of certainty for this term (1-9).
/// A value of 1 implies a very uncertain statement, a value of 9 a very certain one.
Method AddCertaintyTerm(pWord As %String, pLevel As %Integer = 9, Output pPosition) As %Status
{
	quit ..AddAttribute(pWord, "UDCertainty", .pPosition, "c="_pLevel)
}

Method AddSentenceEnd(pToken As %String, Output pPosition) As %Status
{
	quit ..AddEntry(pToken, "\end", .pPosition)
}

Method AddSentenceNoEnd(pToken As %String, Output pPosition) As %Status
{
	quit ..AddEntry(pToken, "\noend", .pPosition)
}

Method AddConcept(pWord As %String, Output pPosition) As %Status
{
	quit ..AddAttribute(pWord, "UDConcept", .pPosition)
}

Method AddRelation(pWord As %String, Output pPosition) As %Status
{
	quit ..AddAttribute(pWord, "UDRelation", .pPosition)
}

Method AddNonRelevant(pWord As %String, Output pPosition) As %Status
{
	quit ..AddAttribute(pWord, "UDNonRelevant", .pPosition)
}

/// <p>Generic method to add attribute marker terms. See the attribute-specific helper methods
/// for practical entry points that avoid keyword typos:</p>
/// <ul>
/// <li><method>AddNegationTerm</method></li>
/// <li><method>AddPositiveSentimentTerm</method></li>
/// <li><method>AddNegativeSentimentTerm</method></li>
/// <li><method>AddCertaintyTerm</method></li>
/// <li><method>AddNumber</method></li>
/// <li><method>AddTime</method></li>
/// <li><method>AddUnit</method></li>
/// </ul>
/// <p>Supported metadata can be passed using <var>pMetadata</var></p>
/// <example>
///  set meta = "c=9"   // certainty level
///  do userDictionary.AddAttribute("absolutely", "UDCertainty",, meta)
/// </example>
Method AddAttribute(pWord As %String, pAttribute As %String = "UDNegation", Output pPosition, pMetadata As %String = "") As %Status [ Internal ]
{
	$$$IKCHECKPRIVADMIN
	quit:..%IsModified()&&'..IsTransient $$$ERROR($$$IKObjectModified, "User Dictionary")
	
	set tSC = $$$OK, tTLevel = $tlevel
	try {
		$$$IKCHECKNOTNULLX(pWord,tSC)
		
		set tSC = ..CheckIfManaged($this)
		quit:$$$ISERR(tSC)
		
		if ('..IsTransient) {
			$$$IKLOCKX(..Id,^IRIS.IK.Sys.UserDictD,tSC)
		}
		
		tstart
		
		set gUserDictEntry = $s(..IsTransient:"^||%IK.UserDict", 1:$name(^IRIS.IK.Sys.UserDictEntry(..Id)))
		
		set pPosition = $o(@gUserDictEntry@(""),-1)+1
	
		// shift all positions < position backwards if it was already taken
		if $d(@gUserDictEntry@(pPosition),tData) {
			kill ^||%IK.UserDictEntry
			set tPos = pPosition
			for {
				set ^||%IK.UserDictEntry(tPos+1) = tData
				kill @gUserDictEntry@(tPos)
				set tPos = tPos+1
				quit:'$data(@gUserDictEntry@(tPos),tData)
			}
			merge @gUserDictEntry = ^||%IK.UserDictEntry
			kill ^||%IK.UserDictEntry
		}
		
		// DP-406858 - capture "fake" UD labels used to allow entering \end and \noend easily
		// in domain defs and architect
		if (pAttribute="UDSentenceEnd") {
			set @gUserDictEntry@(pPosition) = $lb(pWord, "\end")
		} elseif (pAttribute="UDSentenceNoEnd") {
			set @gUserDictEntry@(pPosition) = $lb(pWord, "\noend")
		} else {
			
			// DP-406858 - just treat metadata as a string
			set @gUserDictEntry@(pPosition) = $lb("@"_pWord, pAttribute, pMetadata)
			
		}
		
		tcommit
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel) 1
	
	if ('..IsTransient) {
		$$$IKUNLOCK(..Id,^IRIS.IK.Sys.UserDictD)
	}
	
	quit tSC
}

///  <p>Removes the User Dictionary entry registered at <var>position</var>. This method will
///  not impact the order or position of any remaining entries.</p>
///  <p>These changes are saved automatically. There is no need to call <method>%Save</method></p>
Method RemoveEntry(pPosition As %Integer) As %Status
{
	$$$IKCHECKPRIVADMIN
	quit:..%IsModified()&&'..IsTransient $$$ERROR($$$IKObjectModified, "User Dictionary")
	
	set tSC = ..CheckIfManaged($this)
	quit:$$$ISERR(tSC) tSC
		
	if (..IsTransient) {
		kill ^||%IK.UserDict(..Id, pPosition)
	} else {
		kill ^IRIS.IK.Sys.UserDictEntry(..Id, pPosition)
	}
	quit $$$OK
}

///  <p>Returns the contents of this User Dictionary in the form pResult(position) = $lb(rewriteFrom, rewriteTo [, metadata]).</p>
Method GetEntries(ByRef pResult) As %Status
{
	$$$IKCHECKPRIVREAD
	quit:..%IsModified()&&'..IsTransient $$$ERROR($$$IKObjectModified, "User Dictionary")
	
	set tSC = $$$OK
	try {
			
		if (..IsTransient) {
			merge pResult = ^||%IK.UserDict
		} else {
			merge pResult = ^IRIS.IK.Sys.UserDictEntry(..Id)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Checks if the supplied User Dictionary instance is managed
ClassMethod CheckIfManaged(pUserDict As %iKnow.UserDictionary) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		// transient UDs are never managed
		quit:pUserDict.IsTransient
		
		set tManager = ""
		for {
			set tManager = $order(^IRIS.IK.Sys.Definition(tManager))
			quit:tManager=""
			quit:$d(^IRIS.IK.Sys.Definition(tManager,"userdict",pUserDict.Id))
		}
		quit:tManager=""
		$$$IKCHECKMGRX("User Dictionary",pUserDict.Name,tManager,tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %ConstructClone(deep As %Boolean = 0, ByRef cloned As %String, location As %String) As %RegisteredObject [ ServerOnly = 0 ]
{
	quit "" // not supported!
}

ClassMethod %DeleteExtent(concurrency As %Integer = -1, ByRef deletecount, ByRef instancecount, pInitializeExtent As %Integer = 1) As %Status [ ServerOnly = 0 ]
{
	quit $$$ERROR($$$MethodNotImplemented,"%iKnow.Configuration:%DeleteExtent")
}

ClassMethod %KillExtentData(killstreams As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
	quit $$$ERROR($$$MethodNotImplemented,"%iKnow.Configuration:%KillExtentData")
}

Storage SqlStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="Description">
<Piece>2</Piece>
</Data>
<Data name="Name">
<Piece>1</Piece>
</Data>
<Global>^IRIS.IK.Sys.UserDictD</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{Id}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="NameIndex">
<Data name="Id"/>
<Global>^IRIS.IK.Sys.UserDictI</Global>
<RowIdSpec name="1">
<Expression>{Id}</Expression>
<Field>Id</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>$$$UPPER({Name})</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Sys.UserDictS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
