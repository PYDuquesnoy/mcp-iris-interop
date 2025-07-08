/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

Class %iKnow.NativeSupport.UserDictionary Extends (HandlesErrors, %iKnow.Native.NativeKnowledgebase) [ Deprecated, System = 4 ]
{

Property Name As %String;

Property Hash As %String;

Property AcronymCount As %Integer;

Property Acronyms As %String [ MultiDimensional ];

Property InputFilterCount As %Integer;

Property InputFilters As %String [ MultiDimensional ];

Property Lexreps As %String [ MultiDimensional ];

/// UD labels available are hard-coded
Property Labels As %List [ InitialExpression = {##class(%iKnow.KB.Label).SpecialLabelList()} ];

ClassMethod Create(name As %String, ud As %iKnow.UserDictionary) As UserDictionary
{
	Set obj = ..%New()
	Set obj.Name = name
	Set obj.Hash = "UserDictionaryBareHash"
	Set obj.AcronymCount = 0
	Set obj.InputFilterCount = 0
	Set key = ud.NextEntry(0)
	While (key) {
		Set list = ud.GetEntry(key)
		Do obj.AddEntry(list)
		Do obj.AddToHash(list)
		Set key = ud.NextEntry(key)
	}
	Quit obj
}

ClassMethod Err(msg As %String = "Invalid user dictionary entry.") [ Private ]
{
	Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$IKCaughtError,"%iKnow.NativeSupport.UserDictionary", msg))
}

Method AddEntry(entry As %List) [ Private ]
{
	If $LL(entry) >= 2 {
		Set arg1 = $LI(entry, 1)
		Set arg2 = $LI(entry, 2)
		Set arg3 = ""
		If $LL(entry) > 2 Set arg3 = $LI(entry, 3) //new: metadata
		If $E(arg1,1) = "@" Do ..AddLexrep($E(arg1,2,*),arg2,arg3) Quit
		If $E($LI(entry,2)) = "\" { 
		  If $E(arg1,1) = "\" Set arg1 = $E(arg1,2,*) //Remove escape character if present
		  Do ..AddAcronym(arg1, arg2) Quit
		}
		Do ..AddInputFilter(arg1, arg2) Quit
	}
	Do ..Err()
}

Method AddLexrep(tokens As %String, labels As %String, meta As %String)
{
	//Lexreps have to be 1-indexed because the Next/Get loop uses 0
	//as a sentinal
	Set idx = $G(..Lexreps,0) + 1
	//Use the format of the %iKnow.Lexrep deobfuscated, serialized object
	Set ..Lexreps(idx) = $LB(,tokens,labels, meta)
	Set ..Lexreps = $G(..Lexreps,0) + 1
}

Method AddAcronym(original As %String, command As %String) [ Private ]
{
	Set end = $SELECT(command = "\end":1,command = "\noend":0,1:..Err())
	Set ..AcronymCount = ..AcronymCount + 1
	Set ..Acronyms(..AcronymCount) = $LB("",original,end)
}

Method AddInputFilter(original As %String, replacement As %String) [ Private ]
{
	//The user dictionary code in FileUserDictionary.cpp suggests
	//a case sensitive mode was intended to eventually be supported, and
	//would take 3-entry values. But the third was ignored and we'll ignore it
	//here.
	Set ..InputFilterCount = ..InputFilterCount + 1
	Set ..InputFilters(..InputFilterCount) = $LB("",original,replacement)
}

Method AddToHash(string As %String) [ Private ]
{
	Set ..Hash = $SYSTEM.Encryption.Base64Encode($SYSTEM.Encryption.SHA1Hash(..Hash _ string))
}

Method GetName() As %Binary
{
		Quit ..Name
}

Method GetHash() As %String
{
		Quit ..Hash
}

Method AcronymCount() As %Integer
{
		Quit ..AcronymCount
}

Method GetAcronym(key As %Integer) As %Binary
{
		Quit ..Acronyms(key)
}

Method NextAcronym(key As %Integer) As %Integer
{
		Quit $O(..Acronyms(key))
}

Method ConceptFilterCount() As %Integer
{
		Quit 0
}

Method GetConceptFilter(key As %Integer) As %Binary
{
		Quit ""
}

Method NextConceptFilter(key As %Integer) As %Integer
{
		Quit 0
}

Method LexrepCount() As %Integer
{
		Quit $G(..Lexreps,0)
}

Method GetLexrep(key As %Integer) As %Binary
{
		Quit ..Lexreps(key)
}

Method NextLexrep(key As %Integer) As %Integer
{
		Quit $SELECT(key + 1 <= ..LexrepCount(): key + 1, 1:0)
}

Method PropertyCount() As %Integer
{
		Quit 0
}

Method GetProperty(key As %Integer) As %Binary
{
		Quit ""
}

Method NextProperty(key As %Integer) As %Integer
{
		Quit 0
}

Method MetadataCount() As %Integer
{
		Quit 0
}

Method GetMetadata(key As %Integer) As %Binary
{
		Quit ""
}

Method NextMetadata(key As %Integer) As %Integer
{
		Quit 0
}

Method LabelCount() As %Integer
{
		Quit $LL(..Labels)
}

Method GetLabel(key As %Integer) As %Binary
{
		Quit ##class(%iKnow.KB.Label).LabelListFromString($LI(..Labels, key))
}

Method NextLabel(key As %Integer) As %Integer
{
		Quit $SELECT(key + 1 <= ..LabelCount():key + 1, 1:0)
}

Method GetConceptLabel() As %Binary
{
		Quit ""
}

Method GetRelationLabel() As %Binary
{
		Quit ""
}

Method GetUnknownLabel() As %Binary
{
		Quit ""
}

Method GetPunctuationLabel() As %Binary
{
		Quit ""
}

Method GetSentenceBeginLabel() As %Binary
{
		Quit ""
}

Method GetSentenceEndLabel() As %Binary
{
		Quit ""
}

Method GetJoinLabel() As %Binary
{
		Quit ""
}

Method GetJoinReverseLabel() As %Binary
{
	Quit ""
}

Method PreprocessFilterCount() As %Integer
{
		Quit 0
}

Method GetPreprocessFilter(key As %Integer) As %Binary
{
		Quit ""
}

Method NextPreprocessFilter(key As %Integer) As %Integer
{
		Quit 0
}

Method RuleCount() As %Integer
{
		Quit 0
}

Method GetRule(key As %Integer) As %Binary
{
		Quit ""
}

Method NextRule(key As %Integer) As %Integer
{
		Quit 0
}

Method InputFilterCount() As %Integer
{
	Quit ..InputFilterCount
}

Method GetInputFilter(key As %Integer) As %Binary
{
	Quit ..InputFilters(key)
}

Method NextInputFilter(key As %Integer) As %Integer
{
	Quit $ORDER(..InputFilters(key))
}

Method GetCapitalAllLabel() As %Binary
{
	Quit ""
}

Method GetCapitalInitialLabel() As %Binary
{
	Quit ""
}

Method GetCapitalMixedLabel() As %Binary
{
	Quit ""
}

Method GetSubjectLabel() As %Binary
{
	Quit ""
}

Method GetObjectLabel() As %Binary
{
	Quit ""
}

Method GetPrimaryRelationLabel() As %Binary
{
	Quit ""
}

Method GetNonSemanticLabel() As %Binary
{
	Quit ""
}

Method GetRegex(key As %Integer) As %Binary
{
	Quit ""
}

Method NextRegex(key As %Integer) As %Integer
{
	Quit 0
}

Method RegexCount() As %Integer
{
	Quit 0
}

Method GetNumericLabel() As %Binary
{
	Quit ""
}

Method GetAlphaBeticLabel() As %Binary
{
	Quit ""
}

Method GetSpaceLabel() As %Binary
{
	Quit ""
}

Method GetKatakanaLabel() As %Binary
{
	Quit ""
}

/// Close the table currently being read
Method CloseTable() [ Language = cpp ]
{
}

/// Fetch at most <param>max</param> rows as a $LIST from the previously started table
Method FetchRows(max As %Integer) As %Binary
{
	Quit ""
}

Method IsDynamic() As %Integer
{
	Quit 0
}

Method PhaseCount() As %Integer
{
	Quit 0
}

/// Indicate that the next fetch should start pulling values from the
/// named table for dynamic loading.
Method ReadTable(name As %Binary, phase As %Integer)
{
}

/// Returns true if the currently reading table has exhausted its rows
Method TableAtEnd() As %Integer
{
}

}
