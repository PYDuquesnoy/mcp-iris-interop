/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// See <CLASS>%Text.Text</CLASS>
/// <p>
/// The <CLASS>%Text.English</CLASS> class implements the English language-specific stemming algorithm
/// and initializes the language-specific list of noise words.</p>
/// 
Class %Text.English Extends %Text.Text [ System = 4 ]
{

Parameter DICTIONARY = 2;

Parameter SOURCELANGUAGE = "en";

Parameter NOISEWORDS100 = "the of and a to in is you that it he for was on are as with his they at be this from I have or by one had not but what all were when we there can an your which their said if do will each about how up out them then she many some so these would other into has more her two like him see time could no make than first been its who now my made over did down only way find use may long little very after called just where most know get through back";

Parameter NOISEWORDS200 = "much before go good new write our used me man too any day same right look also around another came come work three word must because does part even place well such here take why things help put years different away again off went old number great tell men say small every found still between name should Mr Mrs home big give set own under read last never us left end along while might next below saw something thought both few those always looked show often together asked don going want people water words air line sound large house";

Parameter NOISEWORDS300 = "world school important until 1 form food keep children feet land side without boy once animals life enough took sometimes four head above kind began almost live page got earth need far hand high year mother light parts country father let night following 2 picture being study second eyes soon times story boys since white days ever paper hard near sentence better best across during today others however sure means knew its try told young miles sun ways thing whole hear example heard several change answer room against top turned 3 learn point city play toward five using himself usually";

Parameter NOISEBIGRAMS100 = "thousand dollar,last night,twenti five,half hour,five hundr,hundr fifti,next morn,feet high,never heard,sundai school,hundr dollar,never mind,don want,hundr mile,never seen,hundr feet,human be,pretti soon,few dai,four hundr,those dai,those peopl,never saw,hundr thousand,per cent,human race,young ladi,look upon,hundr yard,half dozen,young fellow,ever seen,young girl,yes sir,four hour,twenti four,sever time,ten thousand,ever sinc,don care,five minute,fell upon,don think,ten dai,thousand feet,sure enough,six hundr,ever saw,thirti five,ten minute,should think,didn want,col seller,four five,five thousand,ask question,let alone,thousand mile,five mile,ever mark,whole thing,pilot hous,five six,everi night,differ between,hundr ago,half past,both side,yrs ever,middl ag,ever heard,next letter,don mind,noth els,few minute,without doubt,scienc health,don mean,fifteen minute,anybodi els,week ago,women children,dear sir,anyth els,shall never,left hand,everi thing,sai don,never got,human nature,half mile,don believ,centuri ago,never thought,last year,sort thing,six month,poor thing,next moment";

Parameter NOISEBIGRAMS200 = "poor fellow,five dollar,sai myself,feet above,worth while,sincere your,four dai,month ago,thou art,mother church,gener grant,letter written,fifti mile,keep still,wait till,someth els,low voic,seven hundr,run across,never anyth,ladi gentlemen,everi year,dai ago,ain got,ain go,ten mile,six feet,hour half,fifti dollar,eight hundr,don don,shook head,own hand,onc twice,never never,mont blanc,feet deep,without know,side side,sever dai,last moment,hour ago,think think,feet wide,don ever,depend upon,twenti minute,thou shalt,thing done,talk talk,rest upon,mile below,left behind,god bless,five feet,face face,six seven,four thousand,five cent,dai later,thousand time,quarter mile,hand upon,found himself,boi girl,read book,quarri farm,last week,gener thing,eye upon,clock morn,noth left,father peter,year year,ten twelv,nobodi ever,hour hour,haven got,four time,fifteen hundr,don rememb,didn anyth,stood still,somebodi els,poor creature,hundr time,forti five,young peopl,yes yes,whole world,twenti seven";

Parameter NOISEBIGRAMS300 = "four feet,upon head,everybodi els,etc etc,done done,don anyth,thou hast,thing ever,six thousand,set forth,odd end,month later,hundr twenti,hour later,fifti thousand,didn seem,care noth,yet never,till got,ten dollar,own self,never let,minute later,fifti ago,far wide,everi bodi,confer upon,call mind";

/// The main part of the stemming algorithm starts here. b is a buffer
///    holding a word to be stemmed. The letters are in b[k0], b[k0+1] ...
///    ending at b[k]. k is readjusted downwards as the stemming progresses. 
/// 
///    Note that only lower case sequences are stemmed. Forcing to lower case
///    should be done before stem(...) is called.
///    
///    See: http://www.tartarus.org/~martin/PorterStemmer/c.txt
/// 
ClassMethod stemWord(ByRef b As %String) As %String
{
	
	s k = $l(b)
	quit:k<=2 b				; don't stem if the word has length 1 or 2
	s hadTrailingY = $s($e(b,k)="y":1,1:0)
	d ..step1ab(.b, .k)
	d ..step1c(.b, .k)
	d ..step2(.b, .k)
	d ..step3(.b, .k)
	d ..step4(.b, .k)
	d ..step5(.b, .k, hadTrailingY)
	s b=$e(b,1,k)
	quit b
}

/// gets rid of plurals and -ed or -ing.
ClassMethod step1ab(ByRef b As %String, ByRef k As %Integer)
{
	s j=0
	if ($e(b,k) = "s")
    {  if (..ends(b, k, 4, "sses", .j)) { set k = k-2 }
       elseif (..ends(b, k, 3, "ies", .j)) { d ..setto(.b, "i", j, .k) }
       elseif (($e(b,k-1) '= "s") && (k > 3) && (b '= "does")) { s k=k-1 }
    }
    if (..ends(b, k, 3, "eed", .j)) 
    { 
       s:(..m(b, j) > 0) k=k-1 
    } 
    elseif ((..ends(b, k, 2, "ed", .j) || ..ends(b, k, 3, "ing", .j)) && ..vowelInStem(b, j))
    {  s k = j
       if (..ends(b, k, 2, "at", .j)) { d ..setto(.b, "ate", j, .k) }
       elseif (..ends(b, k, 2, "bl", .j)) { d ..setto(.b, "ble", j, .k) }
       elseif (..ends(b, k, 2, "iz", .j)) { d ..setto(.b, "ize", j, .k) }
       elseif (..doublec(b, k)) {  s k=k-1,ch=$e(b,k) s:("lsz"[ch) k=k+1 }
       // elseif (..cvc(b, k)) { d ..setto(.b, "e", .j, .k) }	; departure (see following line)
       elseif (..m(b, j) = 1 && ..cvc(b, k)) { d ..setto(.b, "e", .j, .k) }
   }
}

/// turns terminal y to i when there is another vowel in the stem.
ClassMethod step1c(ByRef b As %String, ByRef k As %String)
{
	s j=""
	s:(..ends(b, k, 1, "y", .j) && ..vowelInStem(b, j)) $e(b,k) = "i"
}

/// maps double suffixes to single ones. so -ization ( = -ize plus -ation) maps to -ize etc. 
/// note that the string before the suffix must give  m() > 0.
ClassMethod step2(ByRef b As %String, ByRef k As %Integer)
{
	s ch=$e(b,k-1),j=""
	if ch="a"
	{ if (..ends(b, k, 7, "ational", .j)) { d ..r(.b, "ate", j, .k ) quit }
      if (..ends(b, k, 6, "tional", .j)) { d ..r(.b, "tion", j, .k) quit }
	}
    elseif ch="c"
    { if (..ends(b, k, 4, "enci", .j)) { d ..r(.b, "ence", j, .k) quit }
      if (..ends(b, k, 4, "anci", .j)) { d ..r(.b, "ance", j, .k) quit }
    }
    elseif ch="e"
    { if (..ends(b, k, 4, "izer", .j)) { d ..r(.b, "ize", j, .k) quit }
    }
    elseif ch="l"
    { if (..ends(b, k, 3, "bli", .j)) { d ..r(.b, "ble", j, .k) quit } /*-DEPARTURE-*/
      /* To match the published algorithm, replace this line with 
      if (..ends(b, k, 4, "abli", .j)) { d ..r(.b, "able", j, .k) quit } */
      if (..ends(b, k, 4, "alli", .j)) { d ..r(.b, "al", j, .k) quit }
      if (..ends(b, k, 5, "entli", .j)) { d ..r(.b, "ent", j, .k) quit }
      if (..ends(b, k, 3, "eli", .j)) { d ..r(.b, "e", j, .k) quit }
      if (..ends(b, k, 5, "ousli", .j)) { d ..r(.b, "ous", j, .k) quit }
    }
    elseif ch="o"
    { if (..ends(b, k, 7, "ization", .j)) { d ..r(.b, "ize", j, .k) quit }
      if (..ends(b, k, 5, "ation", .j)) { d ..r(.b, "ate", j, .k) quit }
      if (..ends(b, k, 4, "ator", .j)) { d ..r(.b, "ate", j, .k) quit }
    }
    elseif ch="s"
    { if (..ends(b, k, 5, "alism", .j)) { d ..r(.b, "al", j, .k) quit }
      if (..ends(b, k, 7, "iveness", .j)) { d ..r(.b, "ive", j, .k) quit }
      if (..ends(b, k, 7, "fulness", .j)) { d ..r(.b, "ful", j, .k) quit }
      if (..ends(b, k, 7, "ousness", .j)) { d ..r(.b, "ous", j, .k) quit }
    }
    elseif ch="t"
    { if (..ends(b, k, 5, "aliti", .j)) { d ..r(.b, "al", j, .k) quit }
      if (..ends(b, k, 5, "iviti", .j)) { d ..r(.b, "ive", j, .k) quit }
      if (..ends(b, k, 6, "biliti", .j)) { d ..r(.b, "ble", j, .k) quit }
    }
    elseif ch="g"
    { if (..ends(b, k, 4, "logi", .j)) { d ..r(.b, "log", j, .k) quit } /*-DEPARTURE-*/
      /* To match the published algorithm, delete this line */
    }
    quit
}

/// Replace -ic-, -full, -ness etc. similar strategy to step2.
/// 
ClassMethod step3(ByRef b As %String, ByRef k As %Integer)
{
    set ch=$e(b,k),j=""
	if ch="e"
	{ if (..ends(b, k, 5, "icate", .j)) { d ..r(.b, "ic", j, .k) quit }
      if (..ends(b, k, 5, "ative", .j)) { d ..r(.b, "", j, .k) quit }
      if (..ends(b, k, 5, "alize", .j)) { d ..r(.b, "al", j, .k) quit }
	}
    elseif ch="i"
	{ if (..ends(b, k, 5, "iciti", .j)) { d ..r(.b, "ic", j, .k) quit }
	}
    elseif ch="l"
	{ if (..ends(b, k, 4, "ical", .j)) { d ..r(.b, "ic", j, .k) quit }
      if (..ends(b, k, 3, "ful", .j)) { d ..r(.b, "", j, .k) quit }
	}
    elseif ch="s"
	{ if (..ends(b, k, 4, "ness", .j)) { d ..r(.b, "", j, .k) quit }
	}
}

/// Take off -ant, -ence etc., in context <c>vcvc<v>.
ClassMethod step4(ByRef b As %String, ByRef k As %Integer)
{
	set ch=$e(b,k-1),j=""
    if ch="a"
    { quit:('(..ends(b, k, 2, "al", .j)))
    }
    elseif ch="c"
    { quit:('(..ends(b, k, 4, "ance", .j)) &&
            '(..ends(b, k, 4, "ence", .j)))
    }
    elseif ch="e"
    { quit:('(..ends(b, k, 2, "er", .j)))
    }
    elseif ch="i"
    { quit:('(..ends(b, k, 2, "ic", .j)))
    }
    elseif ch="l"
    { quit:('(..ends(b, k, 4, "able", .j)) &&
            '(..ends(b, k, 4, "ible", .j)))
      i ..doublec(b, j) s j = j-1				; departure
    }
    elseif ch="n"
    { quit:('(..ends(b, k, 3, "ant", .j)) &&
            '(..ends(b, k, 5, "ement", .j)) &&
            '(..ends(b, k, 4, "ment", .j)) &&
            '(..ends(b, k, 3, "ent", .j)))
    }
    elseif ch="o"
    { quit:('(..ends(b, k, 3, "ion", .j) && (($e(b,j) = "s") || ($e(b,j) = "t"))) &&
            '(..ends(b, k, 2, "ou"))) ; takes care of -ous
    }
    elseif ch="s"
    { quit:('(..ends(b, k, 3, "ism", .j)))
    }
    elseif ch="t"
    { quit:('(..ends(b, k, 3, "ate", .j)) &&
            '(..ends(b, k, 3, "iti", .j)))
    }
    elseif ch="u"
    { quit:('(..ends(b, k, 3, "ous", .j)))
    }
    elseif ch="v"
    { quit:('(..ends(b, k, 3, "ive", .j)))
    }
    elseif ch="z"
    { quit:('(..ends(b, k, 3, "ize", .j)))
    }
    else
    { quit
    }
    s:(..m(b, j) > 1) k = j
    quit
}

/// Remove a final -e if m() > 1, and change -ll to -l if m() > 1.
ClassMethod step5(ByRef b As %String, ByRef k As %Integer, hadTrailingY As %Boolean)
{
   set ch=$e(b, k),j = k
    if ch = "e"
    { s a = ..m(b, j)
      if ((a > 1) || (a = 1) && '..cvc(b, k-1)) s k = k-1
    }
    ; elseif ch = "i" && (hadTrailingY || ((k>2) && ..doublec(b, k-1)) || ("c"[$e(b,k-1))) ; departure
    ; { s $e(b,k) = "y" ; departure
    ; }
    elseif (ch = "l" && ..doublec(b, k) && (..m(b, j) > 1)) 
    { s k = k-1
    }
    quit
}

/// Returns TRUE if character is a consonant, else returns FALSE
ClassMethod cons(b As %String, pos As %String) As %Boolean
{
    set c = $e(b,pos)
    QUIT:("aeiou"[c) ""
    if "y"[c QUIT $s(pos=1:1,1:..cons(b,pos-1))
    while (pos>1) { q:"y"'[c  s pos=pos-1,c=$e(b,pos) }
    QUIT 1
}

///  cvc(i) is TRUE <=> i-2,i-1,i has the form consonant - vowel - consonant
///    and also if the second c is not w,x or y. this is used when trying to
///    restore an e at the end of a short word. e.g.
/// 
///       cav(e), lov(e), hop(e), crim(e), but
///       snow, box, tray.
/// 
ClassMethod cvc(b As %String, i As %Integer) As %Boolean
{
  quit:((i < 3) || ('..cons(b,i)) || ..cons(b,i-1) || ('..cons(b,i-2))) ""
  set c = $e(b,i)
  quit:("wxy"[c) ""
  quit 1
}

ClassMethod doublec(b As %String, j As %Integer) As %Boolean
{
  quit:(j < 2) ""
  quit:($e(b,j) '= $e(b,j-1)) ""
  quit ..cons(b, j)
}

/// m() measures the number of consonant sequences between positions k0=1 and j. 
///    if c is a consonant sequence and v a vowel sequence, and <..> indicates arbitrary
///    presence,
/// 
///       <c><v>       gives 0
///       <c>vc<v>     gives 1
///       <c>vcvc<v>   gives 2
///       <c>vcvcvc<v> gives 3
///       ....
/// 
ClassMethod m(b As %String, j As %Integer) As %Integer
{
    set n=0,i=1
    quit:j=0 0
    for { quit:('..cons(b,i))||($i(i)>j) }
    quit:i>j n
    s i=i+1
    for 
    { for { quit:..cons(b,i)||($i(i)>j) }
      quit:i>j
      s i=i+1,n=n+1
      for { quit:'..cons(b,i)||($i(i)>j) }
      quit:(i>j)||($i(i)>j)
    }
    quit n
}

ClassMethod r(ByRef b As %String, s As %String, j As %Integer, ByRef k As %Integer)
{
 do:(..m(b, j)>0) ..setto(.b, s, j, .k)
}

ClassMethod vowelInStem(b As %String, j As %Integer) As %Boolean
{
  set vowelFound=""
  for i=1:1:j { i '..cons(b,i) { s vowelFound=1 quit }}
  quit vowelFound
}

Storage Default
{
<Type>%Storage.Serial</Type>
}

}
