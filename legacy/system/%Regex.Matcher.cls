/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, Regex)

/// The Class <b><CLASS>%Regex.Matcher</CLASS></b> creates an object that does pattern matching
/// using regular expressions.  The regular expressions come
/// from the International Components for Unicode (ICU).  The ICU
/// maintains web pages at <a href="https://icu.unicode.org" target="_blank"><b>https://icu.unicode.org</b></a>.
/// <p>
/// The definition and features of the ICU regular expression package
/// can be found in <a href="https://unicode-org.github.io/icu/userguide/strings/regexp.html" target="_blank"><b>https://unicode-org.github.io/icu/userguide/strings/regexp.html</b></a>.
/// <p>
/// On most platforms, installing InterSystems IRIS will also install an appropiate version
/// of the ICU libraries.  On platforms that do not have an ICU library
/// available, evaluating any regular expression function or method will result
/// in an &lt;UNIMPLEMENTED&gt; error.
/// <p>
/// A %Regex.Matcher object can be created by evaluating
/// <br><b>##class(%Regex.Matcher).%New(pattern)</b> or
/// <br><b>##class(%Regex.Matcher).%New(pattern,text)</b>.
/// <br> The first parameter to <b><method>%New</method></b> becomes the inital value
/// of the property <b><property>Pattern</property></b>.  The optional, second parameter
/// to <b><method>%New</method></b> become the inital value of the property <b><property>Text</property></b>.  Setting
/// property <b><property>Pattern</property></b> to a regular expression pattern string
/// causes that regular expression pattern to be compiled into a
/// Matcher object where it can be used to do multiple matching operations
/// without being recompiled.  The property <b><property>Text</property></b> contains the
/// subject text string that is searched by a regular expressions match.
/// Note that an empty string is considered to be an illegal regular
/// expression so the first parameter to <b><method>%New</method></b> cannot be missing nor be the
/// empty string.
/// <p>
/// If <b>x</b> is a <b><CLASS>%Regex.Matcher</CLASS></b> object then the built-in method 
/// <b><method>%ConstructClone</method></b> can be used to copy <b>x</b>
/// ( <b>Set xnew = x.%ConstructClone()</b> ) .  The state of the most recent
/// match and any error value in the <b><property>Status</property></b> property are not
/// cloned.  The <b><method>%ConstructClone</method></b> method can be faster than creating
/// a new Matcher with the same Pattern.  The <b><method>%ConstructClone</method></b> method
/// can just copy instructions for the matching engine rather than
/// recompiling the original pattern string.
/// On 8-bit systems <b><method>%ConstructClone</method></b> can just copy the Unicode versions
/// of the Pattern and Text properties without need to do the
/// character-by-character conversion from the NLS 8-bit character set
/// into Unicode.
/// <p>
/// None of the methods or operations in the <b><CLASS>%Regex.Matcher</CLASS></b> package return
/// a <b><class>%Status</class></b> value.
/// When an error is detected, these operations always throw the system
/// exception thrown by the kernel code that interfaces to the ICU library.
/// If a program wants to recover from a regular expression error then it is
/// recommended that the code doing regular expression operations be surrounded
/// with a <b>TRY {...}</b> block and that the error recovery be done in the
/// corresponding <b>CATCH {...}</b> block.  Note that a <b>TRY</b> block imposes no
/// run-time performance overhead in situations where no error occurs.
/// <p>
/// The methods and operations in a <b><CLASS>%Regex.Matcher</CLASS></b> object will catch any
/// &lt;REGULAR EXPRESSION&gt; system error and will generate a <b><class>%Status</class></b> value
/// that may better describe that error.  That <b><class>%Status</class></b> value will be stored
/// in the <b><property>Status</property></b> property of the <b><CLASS>%Regex.Matcher</CLASS></b> object and in the
/// variable <b><var>%objlasterror</var></b>.  After saving the <b><class>%Status</class></b> value, the
/// original unmodified
/// &lt;REGULAR EXPRESSION&gt; system exception will be rethrown.  You may
/// examine that <b><class>%Status</class></b> value by executing the following InterSystems IRIS Object
/// Script command:<br>
/// <b>do $system.Status.DisplayError(%objlasterror)</b>
/// <p>
/// Some other system errors, like &lt;STRING STACK&gt;, are passed through
/// the <b><CLASS>%Regex.Matcher</CLASS></b> methods
/// without modification.
/// <p>
/// Note that some ICU operation errors are not considered errors by the
/// <b><CLASS>%Regex.Matcher</CLASS></b> package.  Examples are evaluating the <b><property>Start</property></b>
/// and <b><property>End</property></b> properties when the previous matching operation failed.  In
/// these cases <b><property>Start</property></b> and <b><property>End</property></b> have value -2 as a character
/// position rather than throwing an error.
/// <p>
/// Examples:
/// <p>
/// Regular expression that finds titles M., Mr., Mrs. and Ms. in a string: "\bMr?s?\."
/// <br>
/// "\b" matches a break at the beginning (or ending) of a word<br>
/// "M" matches an upper-case letter-M<br>
/// "r?" matches 0 or 1 occurences of a lower-case letter-r<br>
/// "s?" matches 0 or 1 occurences of a lower-case letter-s<br>
/// "\." matches a period character<br>
/// <pre>
/// USER>set matcher=##class(%Regex.Matcher).%New("\bMr?s?\.")                             
/// USER>set matcher.Text="Mrs. Sally Jones, Mr. Mike McMurry, Ms. Amy Johnson, M. Maurice LaFrance"
/// USER>while matcher.Locate() {write "Found ",matcher.Group," at position ",matcher.Start,!}      
/// Found Mrs. at position 1
/// Found Mr. at position 19
/// Found Ms. at position 37
/// Found M. at position 54
/// USER>write matcher.ReplaceAll("Dr.")
/// Dr. Sally Jones, Dr. Mike McMurry, Dr. Amy Johnson, Dr. Maurice LaFrance
/// USER>write matcher.ReplaceFirst("Dr.")
/// Dr. Sally Jones, Mr. Mike McMurry, Ms. Amy Johnson, M. Maurice LaFrance
/// </pre>
/// <br><p>
/// Regular expression that matches phone numbers of the form "(aaa) bbb-cccc"
/// or of the form "aaa-bbb-ccc":  (\((\d{3})\)\s*|\b(\d{3})-)(\d{3})-(\d{4})\b
/// <br><br>
/// (\((\d{3})\)\s*|\b(\d{3})-) matches either
/// prefix "(aaa) " or prefix "aaa-".  The outer
/// parentheses capture this entire prefix as Group(1) and limits the range of
/// the two prefix subpatterns in alternation by the | operator.<br>
/// <br>
/// \((\d{3})\)\s* matches prefix "(aaa) "<br>
/// \( and \) and \s* match "(" and ")" and zero or more spaces, respectively<br>
/// \d{3} matches exactly 3 digits<br>
/// (\d{3}) the parentheses capture these 3 digits as Group(2)<br>
/// <br>
/// \b(\d{3})- matches prefix "aaa-"<br>
/// \b this "break" allows no other digit or letter immediately before the 3 digits<br>
/// (\d{3}) captures these 3 digits as Group(3)<br>
/// <br>
/// (\d{3})- matches "bbb-" and captures these 3 digits as Group(4)<br>
/// <br>
/// (\d{4}) matches "cccc" and captures these 4 digits as Group(5)<br>
/// <br>
/// \b this final "break" makes sure the match is not immediately followed
/// by another digit or a letter<br>
/// <br><pre>
/// ListPhones(s,a) PUBLIC {
///     ; a is a reference variable.  On return
///     ; a contains the number of phone numbers in string s
///     ; a(i) contains just the digits of the i'th phone number
///     kill a
///     set a = 0
///     set m=##class(%Regex.Matcher).%New("(\((\d{3})\)\s*|\b(\d{3})-)(\d{3})-(\d{4})\b")
///     set m.Text = s
///     while m.Locate() {
///         ; Get first three digits from Group(2) or Group(3)
///         if m.Start(2)>0 { set n=m.Group(2) }
///         else { set n=m.Group(3) }
///         ; Concatenate middle 3 digits and final 4 digits
///         set n = n_m.Group(4) _ m.Group(5)
///         ; Insert digit string into array a
///         set a($increment(a)) = n
///     }
/// }
/// 
/// ListPhones2(s,a) PUBLIC {
///     ; a is a reference variable.  On return
///     ; a contains the number of phone numbers in string s
///     ; a(i) is i'th phone number formatted as "(aaa)bbb-cccc"
///     ; Note, no blank after "(aaa)"
///     kill a
///     set a = 0
///     set m=##class(%Regex.Matcher).%New("(\((\d{3})\)\s*|\b(\d{3})-)(\d{3})-(\d{4})\b")
///     set m.Text = s
///     while m.Locate() {
///         ; Digits are concatentation of Capture groups 2,3,4,5
///         ; One of group 2 or 3 is the empty string when group is not used
///         set a($increment(a)) = m.SubstituteIn("($2$3)$4-$5")
///     }
/// }
/// 
/// USER>write ^t2
/// Call 617-555-1212 about item number 61773-333-4569
/// USER>do ListPhones^ListPhones(^t2,.a)
/// USER>zwrite a
/// a=1
/// a(1)=617555121
/// 
/// USER>write ^t3
/// Phone (212) 334-5397, (321)770-2121 and 603-646-0110
/// USER>do ListPhones^ListPhones(^t3,.a)
/// USER>zwrite a
/// a=3
/// a(1)=2123345397
/// a(2)=3217702121
/// a(3)=6036460110
/// 
/// USER>write ^t3
/// Phone (212) 334-5397, (321)770-2121 and 603-646-0110
/// USER>do ListPhones2^ListPhones(^t3,.a)
/// USER>zwrite a                         
/// a=3
/// a(1)="(212)334-5397"
/// a(2)="(321)770-2121"
/// a(3)="(603)646-0110"
/// </pre><br>
/// 
Class %Regex.Matcher Extends (%RegisteredObject, %SYSTEM.Help) [ Final ]
{

/// The property <b>Pattern</b> is the string representation of the regular
/// expression of the Matcher.  Assigning to <b>Pattern</b> resets all saved
/// state concerning the last matching operation.
/// <p>
/// On an installation using an NLS 8-bit character set different from Latin-1
/// then you you must be careful with patterns using a character class of
/// the form [x-y] where x or y are national usage characters not in Latin-1.
/// All regular expression matching is done in Unicode so characters x and y
/// are converted Unicode.  The character class [x-y] reprsents all characters
/// between the Unicode translations of x and y and not the NLS 8-bit characters
/// between x and y.
/// 
Property Pattern As %String;

/// RegexId is an internal value that is mapped to the regular expression
/// matcher object supported by the ICU libraries.
/// 
Property RegexId [ Internal, Private ];

/// The property <b>Text</b> is the string to which the regular expression
/// will be applied.  Assigning to <b>Text</b> resets all saved state resulting
/// from the most recent match operation.  On installations using an 8-bit
/// character code, the internal representation of <b>Text</b> is converted to
/// Unicode.  Therefore, on an installation using 8-bit characters the maximum
/// length of the <b>Text</b> property is only half the maximum string length
/// supported by that installation.
/// 
Property Text As %String;

/// TextBuffer is used only on 8-bit systems.  It is a copy of Text as
/// Unicode bytes.
/// 
Property TextBuffer As %String [ Internal, Private ];

/// The property <b>Start</b> without a subscript contains the character
/// position in property <b><property>Text</property></b> of the first character of the string found by
/// the last match.  If the matched string is the empty string then
/// <b>Start</b> is the character position one beyond where the empty
/// string was located (and the property <b>Start</b> equals the
/// property <b><property>End</property></b>.)
/// <p>
/// The value of <b>Start(i)</b> when subscripted with an integer <b>i</b>
/// between 1 and <b><property>GroupCount</property></b> is the character position
/// of the first character of the last string successfully captured by
/// capture group <b>i</b>.  If the captured string is the empty string then
/// <b>Start(i)</b> is the character position one beyond where the empty
/// string that was captured (and the property <b>Start(i)</b> equals the
/// property <b><property>End</property>(i)</b>.)
/// <p>
/// The value of <b>Start(i)</b> is -1 if capture group <b>i</b> did not
/// participate in the last match.  The values of <b>Start</b> and
/// <b>Start(i)</b> are -2 if the last match attempt failed.
/// <p>
/// Note: In addition to integer subscripts between 1 and <b><property>GroupCount</property></b>,
/// the value of <b>Start(0)</b> is identical to the value of <b>Start</b>
/// without a subscript.  When the property <b>Start(...)</b> is
/// subscripted with values not described above then the attempt
/// to evaluate the property <b>Start(...)</b> is undefined.
/// 
Property Start As %Integer [ MultiDimensional, ReadOnly ];

/// The property <b>End</b> without a subscript contains the character
/// position in property <b><property>Text</property></b> one beyond of the final character of the
/// string found by the last match.
/// <p>
/// The value of <b>End(i)</b> when subscripted with an integer <b>i</b>
/// between 1 and <b><property>GroupCount</property></b> is the character position one beyond the
/// of the last character of the last string successfully captured by
/// capture group <b>i</b>.
/// <p>
/// The value of <b>End(i)</b> is -1 if capture group <b>i</b> did not
/// participate in the last match.  The values of <b>End</b> and
/// <b>End(i)</b> are -2 if the last match attempt failed.
/// <p>
/// Note: In addition to integer subscripts between 1 and <b><property>GroupCount</property></b>,
/// the value of <b>End(0)</b> is identical to the value of <b>End</b>
/// without a subscript.  When the property <b>End(...)</b> is
/// subscripted with values not described above then the attempt
/// to evaluate the property <b>End(...)</b> is undefined.
/// 
Property End As %Integer [ MultiDimensional, ReadOnly ];

/// The property <b>Group</b> without a subscript contains the
/// string found by the last match.
/// <p>
/// The value of <b>Group(i)</b> when subscripted with an integer <b>i</b>
/// between 1 and <b><property>GroupCount</property></b> is the last string successfully captured by
/// capture group <b>i</b>.
/// <p>
/// If the last match operation was unsuccessful or if the specified capture
/// group was not used during the last match operation then <b>Group</b>
/// and <b>Group(i)</b> contain the empty string.  Note that <b><property>End</property></b> and
/// <b><property>End</property>(i)</b> have negative values when the last match operation did not
/// use the specified capture group or did not succeed in matching.
/// <p>
/// Note: In addition to integer subscripts between 1 and <b><property>GroupCount</property></b>,
/// the value of <b>Group(0)</b> is identical to the value of <b>Group</b>
/// without a subscript.  When the property <b>Group(...)</b> is
/// subscripted with values not described above then the attempt
/// to evaluate the property <b>Group(...)</b> is undefined.
/// 
Property Group As %String [ MultiDimensional, ReadOnly ];

/// The property <b>HitEnd</b> is true if the most recent matching
/// operation touched the end of property <b><property>Text</property></b> at any point
/// during its processing. In this case, appending additional input
/// characters to the <b><property>Text</property></b> property could change the result of that
/// match attempt.
/// 
Property HitEnd As %Boolean [ Calculated, ReadOnly ];

/// PreviousMatchEnd is the End value of the previous match.  It has
/// value -1 if there is no current match and value 1 if there
/// is a current match but no previous match.
/// 
Property PreviousMatchEnd As %Integer [ Private ];

/// The property <b>GroupCount</b> contains the number of capturing groups
/// in the regular expression <b><property>Pattern</property></b>.
/// 
Property GroupCount As %Integer [ ReadOnly ];

/// This property is DEPRECATED and is always the empty string.<p>
/// The property <b>RequiredPrefix</b> contains a string which, if nonempty, is
/// a sequence of characters which must occur at the start of any string which
/// matches the <b><property>Pattern</property></b>.  A nonempty <b>RequiredPrefix</b>
/// can be used to search a long string for a favorable position to start a Regular
/// Expression matching operation.
/// <p>
/// In many cases the heuristics used by the ICU library to determine the
/// <b>RequiredPrefix</b> do not include all possible characters of such a
/// prefix.  When a prefix cannot be determined, <b>RequiredPrefix</b> will contain
/// the empty string.  <b>RequiredPrefix</b> will also contain the empty string
/// if the ICU library used by InterSystems IRIS does not support the RequiredPrefix feature.
/// 
Property RequiredPrefix As %String [ Deprecated, Internal, ReadOnly ];

/// The property <b>OperationLimit</b> provides a way to limit the time taken
/// by a regular expression match. The default value for <b>OperationLimit</b>
/// is 0 which indicates that there is no limit. Setting <b>OperationLimit</b>
/// to a positive integer will cause a match operation to signal a TimeOut
/// error after the specified number of clusters of steps by the match engine.
/// <p>
/// Correspondence with actual processor time will depend on the speed
/// of the processor and the details of the specific pattern, but cluster size
/// is chosen such each cluster's execution time will
/// typically be on the order of milliseconds.
/// 
Property OperationLimit As %Integer;

/// The property <b>Status</b> contains a <b><class>%Status</class></b> value which may provide more
/// information about the last System exception thrown
/// by this object.  It is initially <b>$$$OK</b>.  Its value remains
/// unchanged by any successful operation.  The <b>Status</b> property is
/// changed only when an error is thrown the kernel functions implementing
/// <class>%Regex.Matcher</class> or by a COS <b>Set</b> assignment to the
/// <b>Status</b> property done by the user.
/// 
Property Status As %Status;

/// Creates %Regex application exception from system exception
Method Error(excep As %Exception.AbstractException) As %ObjectHandle [ Internal, Private ]
{
	If (excep.%IsA("%Exception.SystemException")&&(excep.Code=$$$ERREGEX)) {
		Set ErrorCode=$$$REUErrorCode
		if ErrorCode=$$$REuIndexError { 
			Set ..Status=$$$ERROR($$$REmIndexMessage)
		} elseif (ErrorCode>=$$$REuFirstError)&&(ErrorCode<=$$$REuLastError) {
			Set ..Status=$$$ERROR(ErrorCode-$$$REuFirstError+$$$REmFirstMessage)
		} elseif ErrorCode=$$$REuIllegalArgError {
			Set ..Status=$$$ERROR($$$REmIllegalArgMessage)
		} else {
			Set ..Status=$$$ERROR($$$RegexICU,ErrorCode,$ZHEX(ErrorCode))
		}
#; Do not violate convention that InterSystems code never throws Status Exceptions
#;		Set excep=##class(%Exception.StatusException).CreateFromStatus(..Status)
	} Else {
		Set ..Status=excep.AsStatus()
	}
	Quit excep
}

/// The class method %New creates a new Matcher.
/// <p>
/// The argument pattern contains the regular expression. The property
/// Pattern is set to the value of this argument
/// <p>
/// The argument text is optional. If defined, it contains the new
/// value of the property Text, which is the string to which the regular
/// expression Pattern will be applied.
/// 
Method %OnNew(pattern As %String = "", text As %String = "") As %Status [ Internal, Private ]
{
#; Do not violate convention that InterSystems code never throws Status Exceptions
#;	Throw:$get(pattern,"")="" ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$RegexNoPattern))
	Try {
		Set i%Status=$$$OK
		Set i%Pattern = pattern_"", i%RegexId = $$$REopen(i%Pattern)
		Set i%GroupCount=-1, i%OperationLimit = 0, i%PreviousMatchEnd=-1
		Set i%RequiredPrefix=$$$ReqPreUnevaluated
		Set ..Text=text
	} Catch excep { Throw ..Error(excep) }
	Quit $$$OK
}

/// The %OnClose() method frees the URegularExpression handle stored
/// in i%RegexID when a %Regex.Matcher object is deleted.
/// 
Method %OnClose() As %Status [ Internal, Private ]
{
	Do:i%RegexId $$$REclose(i%RegexId)
	Quit $$$OK
}

/// The <b>PatternSet</b> method implements <b>Set</b> assignments to the
/// <b><property>Pattern</property></b> property.
/// 
Method PatternSet(pattern As %String) As %Status
{
	Try {
		Do:i%RegexId $$$REclose(i%RegexId)
		Set i%RegexId=0
		Set i%Pattern = pattern_"", i%RegexId = $$$REopen(i%Pattern)
		Set i%GroupCount=-1, i%PreviousMatchEnd=-1
		Set i%RequiredPrefix=$$$ReqPreUnevaluated
		Do:'$Length(i%TextBuffer) $$$REsetText(i%RegexId, i%Text)
		Do:$Length(i%TextBuffer) $$$REsetText8(i%RegexId, i%TextBuffer)
		Do:i%OperationLimit $$$REsetTimeLimit(i%RegexId, i%OperationLimit)
	} Catch excep { Throw ..Error(excep) }
	Quit $$$OK
}

/// The <b>TextSet</b> method implements <b>Set</b> assignments to the
/// <b><property>Text</property></b> property.
/// 
Method TextSet(text As %String) As %Status
{
	Try {
		Set i%Text = text_"", i%PreviousMatchEnd=-1
		Set i%TextBuffer = $$$REsetText(i%RegexId, i%Text)
		Do:$Length(i%TextBuffer) $$$REsetText8(i%RegexId, i%TextBuffer)
	} Catch excep { Throw ..Error(excep) }
	Quit $$$OK
}

/// The <b>StartGet</b> method implements the <b><property>Start</property></b> property.
/// 
Method StartGet(group As %Integer = 0) As %Integer
{
	Try {
		Set result=$$$REstart(..RegexId, +group)
	} Catch excep { Throw ..Error(excep) }
	Quit result
}

/// The <b>EndGet</b> method implements the <b><property>End</property></b> property.
/// 
Method EndGet(group As %Integer = 0) As %Integer
{
	Try {
		Set result=$$$REend(..RegexId, +group)
	} Catch excep { Throw ..Error(excep) }
	Quit result
}

/// The <b>GroupGet</b> method implements the <b><property>Group</property></b> property.
/// 
Method GroupGet(group As %Integer = 0) As %String
{
	Try {
		Set group=+group
		Set result=$Extract(..Text,$$$REstart(..RegexId,group),$$$REend(..RegexId,group)-1)
	} Catch excep { Throw ..Error(excep) }
	Quit result
}

/// The <b>HitEndGet</b> method implements the <b><property>HitEnd</property></b> property.
/// 
Method HitEndGet() As %Boolean
{
	Try {
		Set result=$$$REhitEnd(..RegexId)
	} Catch excep { Throw ..Error(excep) }
	Quit result
}

/// The <b>GroupCountGet</b> method implements the <b><property>GroupCount</property></b> property.
/// 
Method GroupCountGet() As %Integer
{
	Try {
		Set:i%GroupCount=-1 i%GroupCount = $$$REgroupCount(..RegexId)
	} Catch excep { Throw ..Error(excep) }
	Quit i%GroupCount
}

/// The <b>RequiredPrefixGet</b> method implements the <b><property>RequiredPrefix</property></b>
/// property.
Method RequiredPrefixGet() As %String
{
	Quit ""
}

/// The <b>OperationLimitSet</b> method implements the side effects of doing a <b>Set</b>
/// assignment to change the value of the <b><property>OperationLimit</property></b> property.
/// 
Method OperationLimitSet(limit) As %Status
{
	Try {
		Set i%OperationLimit=+limit
		Do $$$REsetTimeLimit(..RegexId, i%OperationLimit)
	} Catch excep { Throw ..Error(excep) }
	Quit $$$OK
}

/// The class method <b>LastStatus</b> returns the <class>%Status</class>
/// value containing additional details about the most recent &lt;REGULAR EXPRESSION&gt;
/// system error.  If a <b><class>%Regex.Matcher</class></b> object encounters
/// a &lt;REGULAR EXPRESSION&gt;
/// error then this status is already available in the <b><property>Status</property></b>
/// property of the object.  Executing<br>
/// Do $SYSTEM.Status.DisplayError(##class(%Regex.Matcher).LastStatus())
/// <br>is useful when debugging a &lt;REGULAR EXPRESSION&gt; error following a call
/// on <b>$MATCH</b>, <b>$LOCATE</b> or <b>##class(%Regex.Matcher).%New</b>(x) where a
/// <b><class>%Regex.Matcher</class></b> oref value is not available.
/// 
ClassMethod LastStatus() As %Status
{
	Set ErrorCode=$$$REUErrorCode
	Quit:'ErrorCode $$$OK
	if ErrorCode=$$$REuIndexError { 
		Quit $$$ERROR($$$REmIndexMessage)
	} elseif (ErrorCode>=$$$REuFirstError)&&(ErrorCode<=$$$REuLastError) {
		Quit $$$ERROR(ErrorCode-$$$REuFirstError+$$$REmFirstMessage)
	} elseif ErrorCode=$$$REuIllegalArgError {
		Quit $$$ERROR($$$REmIllegalArgMessage)
	} else {
		Quit $$$ERROR($$$RegexICU,ErrorCode,$ZHEX(ErrorCode))
	}
}

/// The method <b>Match</b> returns true if the entire string <b><property>Text</property></b> is
/// matched by <b><property>Pattern</property></b>; it returns false if it does not match.
/// <p>
/// The argument <b><var>text</var></b> is optional. If the argument <b><var>text</var></b> is defined
/// then the property <b><property>Text</property></b> is set to its value before the match is
/// executed.
/// 
Method Match(text As %String) As %Boolean
{
	Try {
		Set:$d(text) ..Text=text
		Set result = $$$REmatches(..RegexId, 0)
		Set i%PreviousMatchEnd = $Select(result:1,1:-1)
	} Catch excep {
		// Work around ICU bug by recreating ICU object after a match error
		Set ..Pattern=i%Pattern
		Throw ..Error(excep) }
	Quit result
}

/// The method <b>LookingAt</b> attempts to find a match in the property
/// <b><property>Text</property></b> that must start at a particular character position. The match
/// need not extend to the end of <b><property>Text</property></b>.
/// <p>
/// The argument <b><var>position</var></b> gives starting character position of the
/// attempted match.
/// <p>
/// <b>LookingAt</b> returns 1 if the match is found; 0 otherwise.
Method LookingAt(position As %Integer = 1) As %Boolean
{
	Try {
		Set i%PreviousMatchEnd = 1
		Set result = $$$RElookingAt(..RegexId,+position)
		Set:'result i%PreviousMatchEnd = -1
	} Catch excep {
		// Work around ICU bug by recreating ICU object after a match error
		Set ..Pattern=i%Pattern
		Throw ..Error(excep) }
	Quit result
}

/// The method <b>Locate</b> finds a match for the regular expression
/// <b><property>Pattern</property></b> in the text string <b><property>Text</property></b>.
/// <p>
/// If the optional argument <b><var>position</var></b> is defined as an integer 1 or greater
/// then the search for a match begins at that character position of <b><property>Text</property></b>.
/// <p>
/// If the argument <b><var>position</var></b> is not defined then the search for the
/// match begins the character position following the previous match.
/// <p>
/// <b>Locate</b> returns 1 if the match is found; 0 otherwise.
Method Locate(position As %Integer) As %Boolean
{
	Try {
		If $Data(position) {
			Set i%PreviousMatchEnd = +position
			Set result = $$$REfind(..RegexId,+position)
		} Else {
			Set i%PreviousMatchEnd = $Select(i%PreviousMatchEnd>=0:..End(0),1:1)
			Set result = $$$REfindNext(..RegexId)
		}
		Set:'result i%PreviousMatchEnd = -1
	} Catch excep {
		// Work around ICU bug by recreating ICU object after a match error
		Set ..Pattern=i%Pattern
		Throw ..Error(excep) }
	Quit result
}

/// The method <b>ResetPosition</b> resets any saved state from the previous
/// match. It also causes the next call to the method <method>Locate</method> without
/// an argument to begin at the specified character position.
/// <p>
/// The argument <b><var>position</var></b> is the character position from which the
/// next call to <method>Locate</method> without an argument will begin match
/// attempts.
/// 
Method ResetPosition(position As %Integer = 1)
{
	Try {
		Set i%PreviousMatchEnd=-1
		Do $$$REreset(..RegexId,+position)
	} Catch excep { Throw ..Error(excep) }
	Quit $$$OK
}

/// The method <b>ReplaceAll</b> returns a modified copy of the property
/// <b><property>Text</property></b>. It replaces every substring of
/// <b><property>Text</property></b> that matches the
/// <b><property>Pattern</property></b> with a replacement string. Portions
/// of <b><property>Text</property></b> that are
/// not matched are copied without change. The value of <b>ReplaceAll</b>
/// is the resulting string.  The property <b><property>Text</property></b>
/// is not modified.
/// <p>
/// The argument <b><var>replacement</var></b> supplies the string to replace each
/// matched region. The replacement string may contain references
/// to capture groups which take the form of <b>$1</b>, <b>$2</b>, etc.  The
/// replacement string may reference the entire matched region
/// with <b>$0</b>.
/// 
Method ReplaceAll(replacement As %String) As %String
{
	Try {
		Set i%PreviousMatchEnd=-1
		Set result=$$$REreplaceAll(..RegexId, replacement)
	} Catch excep {
		// Work around ICU bug by recreating ICU object after a match error
		Set ..Pattern=i%Pattern
		Throw ..Error(excep) }
	Quit result
}

/// The method <b>ReplaceFirst</b> returns a modified copy of the property
/// <b><property>Text</property></b>. It replaces the first substring
/// of <b><property>Text</property></b> that matches the
/// <b><property>Pattern</property></b> with a replacement string. Portions
/// of <b><property>Text</property></b> that are
/// not matched are copied without change. The value of <b>ReplaceFirst</b>
/// is the resulting string.  The property <b><property>Text</property></b> is not modified.
/// <p>
/// The argument <b><var>replacement</var></b> supplies the string to replace the
/// matched region. The replacement string may contain references
/// to capture groups which take the form of <b>$1</b>, <b>$2</b>, etc.  The
/// replacement string may reference the entire matched region
/// with <b>$0</b>.
/// 
Method ReplaceFirst(replacement As %String) As %String
{
	Try {
		Set i%PreviousMatchEnd=-1
		Set result=$$$REreplaceFirst(..RegexId, replacement)
	} Catch excep {
		// Work around ICU bug by recreating ICU object after a match error
		Set ..Pattern=i%Pattern
		Throw ..Error(excep) }
	Quit result
}

/// The method <b>SubstituteIn</b> returns the string that
/// results from substituting capturing groups from the most
/// recent regular expression match into
/// components of the argument <b><property>Text</property></b>.
/// This method is undefined if the most recent
/// regular expression match operation was not successful.
/// <p>
/// This method can be used as a low level step in regular expression replacement.
/// It does not modify the property <b><property>Text</property></b>. For example, the method
/// ..<method>ReplaceFirst</method> is equivalent to:
/// <p><b>
/// <pre>
/// Quit:'..Locate(1) ..Text
/// Quit $Extract(..Text,1,..Start-1)_..SubstituteIn(x)_
///          $Extract(..Text,..End,*)
/// </pre></b><p>
/// The argument <b><var>Text</var></b> supplies the string that will be modified by the
/// matched region and then returned. The string may contain references
/// to capture groups which take the form of <b>$1</b>, <b>$2</b>, etc.  The
/// string may reference the entire matched region with <b>$0</b>.
/// 
Method SubstituteIn(text As %String) As %String
{
	Quit:i%PreviousMatchEnd<0 ""
	Try {
		Set result=$$$REappendReplacement(..RegexId,text,..Start-i%PreviousMatchEnd)
	} Catch excep {
		// Work around ICU bug by recreating ICU object after a match error
		Set ..Pattern=i%Pattern
		Throw ..Error(excep) }
	Quit result
}

/// The method SplitIntoList separates the Text string into fields. 
/// Matches by the regular expression Pattern identifies delimiters
/// that separate the fields. The contents of Text between the matches
/// become fields. The return value of the method is a $LIST where
/// each List element is a field.
/// 
Method SplitIntoList() As %List [ Internal, Private ]
{
	Do $$$REunimplemented
}

/// The method SplitIntoArray separates the Text string into fields. 
/// Matches by the regular expression Pattern identifies delimiters
/// that separate the fields. The contents of Text between the matches
/// become fields. The return value of the method is an integer which
/// is a count of the number fields.
/// <p>
/// The argument array is a reference to a local variable which is
/// an array to contain the values of the fields. array(1) is
/// assigned the first field, array(2) is assigned the second field,
/// etc.
/// 
Method SplitIntoArray(ByRef array) As %Integer [ Internal, Private ]
{
	Do $$$REunimplemented
}

/// The <b>%OnConstructClone</b> method clones the ICU library specific values
/// in a <class>%Regex.Matcher</class> object.  It also resets the <b><property>Status</property></b>
/// and the state of the last match attempt.
/// 
Method %OnConstructClone(obj As Matcher, deep As %Boolean, ByRef cloned As %String) As %Status [ Internal, Private ]
{
	Try {
		Set i%RegexId=0
		Set i%PreviousMatchEnd=-1,i%Status=$$$OK
		Set i%RegexId = $$$REclone(obj.RegexId)
		Do:'$Length(i%TextBuffer) $$$REsetText(i%RegexId, i%Text)
		Do:$Length(i%TextBuffer) $$$REsetText8(i%RegexId, i%TextBuffer)
		Do:i%OperationLimit $$$REsetTimeLimit(i%RegexId,i%OperationLimit)
	} Catch excep {
		// If result.RegexId allocated then free it on error
		Do:i%RegexId $$$REclose(i%RegexId)
		Set i%RegexId = 0
	    Throw ..Error(excep)
	}
	Quit $$$OK
}

}
