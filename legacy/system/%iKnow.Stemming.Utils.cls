/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// This class contains utility methods to manage stemming disambiguation rules.
Class %iKnow.Stemming.Utils [ Deprecated, System = 4 ]
{

/// Adds an exception to override stemming behavior for a specific language.
/// The rule applies when stemming tokens that are exactly equal to <var>pValue</var> in entities
/// with role = <var>pRole</var>. If <var>pEntity</var> is supplied (advanced), the entity being stemmed should
/// should contain this string before the rule will be enforced.
ClassMethod AddException(pLanguage As %String, pValue As %String, pStem As %String, pRole As %Integer = {$$$ENTTYPECONCEPT}, pEntity As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		
		set tRule = ##class(%iKnow.Stemming.Rule).%New()
		set tRule.LanguageCode = pLanguage
		set tRule.Plugin = "All"
		set tRule.Type = "Exception"
		set tRule.Spec = $case(pRole, $$$ENTTYPECONCEPT:"Concept", $$$ENTTYPERELATION:"Relation")
		set tRule.Value = pValue
		set tRule.Replace = pStem
		set tRule.Entity = pEntity
		set tSC = tRule.%Save()
		quit:$$$ISERR(tSC)
		
		// update existing stemmers, to the extent we can find them
		for tLang = pLanguage, "*" {
			set tSC = ($system.Context.iFind()).GetStemmer(tLang, .tStemmer)
			quit:$$$ISERR(tSC)
			
			continue:'tStemmer.%IsA("%iKnow.Stemming.DefaultStemmer")
			
			set tSC = tStemmer.Reload()
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Loads default stemming disambiguation rules from the KB files
ClassMethod LoadDefaultRulesCSV(pPath As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill tRules
		
		set tFile = ##class(%Stream.FileCharacter).%New()
		set tFile.Filename = pPath
		do tFile.Rewind()
		
		while 'tFile.AtEnd {
			set tLine = $zstrip($piece(tFile.ReadLine(),"//",1),"<>W")
			continue:tLine=""
			
			// BDB584
			set tLine = $zconvert(tLine,"O","UTF8")
			
			set tLanguage = $piece(tLine,";",1)
			set tPlugin = $case($piece(tLine,";",2), "All":$$$IKSTEMPLUGINALL, "Hunspell":$$$IKSTEMPLUGINHUNSPELL, :-1)
			set tType = $case($piece(tLine,";",3), "Exception":$$$IKSTEMEXCEPTION, "Ending":$$$IKSTEMENDING, "Affix":$$$IKSTEMAFFIX, :-1)
			set tSpec = $case($piece(tLine,";",4), "NoConcept":$$$IKSTEMNOCONCEPT, "NoRelation":$$$IKSTEMNORELATION, "Concept":$$$ENTTYPECONCEPT, "Relation":$$$ENTTYPERELATION, :-1)
			set tValue = $piece(tLine,";",5)
			set tReplace = $piece(tLine,";",6)
			set tEntity = $piece(tLine,";",7)
			
			if (tType = $$$IKSTEMEXCEPTION) && (tEntity'="") {
				set tIndex = $order(tRules(tLanguage, tPlugin, $$$IKSTEMEXCEPTION, tSpec, tValue, ""), -1)+1
				set tRules(tLanguage, tPlugin, $$$IKSTEMEXCEPTION, tSpec, tValue, tIndex) = $lb(tEntity, tReplace)
			} else {
				set tRules(tLanguage, tPlugin, tType, tSpec, tValue) = tReplace
			}
		}
		
		kill ^%iKnow("SR")
		merge ^%iKnow("SR") = tRules
		
		/*// cleanup
		k b,x,i,e,ee,c  
		f i=0,1 { 
			s e="" f { s e=$o(^%iKnow("SR","ru",1,1,i,e)) q:e=""  s b($reverse(e))=$lb(i,e) }
		} 
		s e="" f { s e=$o(b(e),1,x) q:e=""  continue:$ld(x,3)  s ee=e,c=0,r=0 
			f { s ee=$o(b(ee),1,d) q:ee=""  q:$e(ee,1,$l(e))'=e  if ($lg(d,1)=0) { s c=c+1 } else { s r=r+1 } } 
			if ('c)||('r) { s ee=e f { s ee=$o(b(ee)) q:ee=""  q:$e(ee,1,$l(e))'=e  s $li(b(ee),3)="OBSOLETE >> ["_$reverse(e)_"]" } } 
		}
		s i="" f { s i =$o(b(i),1,d) q:i=""  s c($li(d,2))=d }
		*/
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
