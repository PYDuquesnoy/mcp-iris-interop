/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include ftdefs

Class %ML.FeatureGetter Extends FT.FeatureGetter [ Language = objectscript ]
{

/// Returns a $LIST of key-value pairs for a feature
/// Where each key-value pair has the format $LISTBUILD(key,value,type)
/// <ul>
/// <li>where type=0 if value is a STRING in which case we keep the most recent
/// value,
/// <li>where type=1 if value is a BOOLEAN value {0 or 1} in which case we OR with previous values,
/// <li>where type=2 if value is a SUM number in which case we do a summation with previous values, and
/// <li>where type=3 if value is a MAX number in which case we keep maximum value of the current and previous values.
/// </ul></Description>
/// <p>
/// The method may be supplied by a <b>FT.FeatureGetter</b> subclass.  It is
/// called by the Feature Tracker Collector about once per hour in order to
/// collect the Feature values that might change over time.  Therefore, in case
/// of crash of the InterSystems IRIS instance we
/// will lose no more than one hour of Feature Tracker information.
/// <p>
/// This method is also called immediately after a call on the
/// <b><method>GetBegin</method></b> method and just before a call on the
/// <b><method>GetEnd</method></b> method.
/// 
ClassMethod GetInfo() As %List [ Internal ]
{
	#dim info As %Library.List
	#dim code,count As %Integer
	#dim key As %String

	set info=""
	try {
		do FTKeysSetup^%apiSQL()
		set key=""
		for  {
			set key=$o($system.Context.SQL().FTKeys(key),1,code) quit:key=""
			set count=$$$FTSREADVAL(code)
			set info=info_$lb($lb(key,count,$$$FTINTTYPE))
		}
	}
	catch ex {
		set info=""
	}
	RETURN info
}

/// The class method <b>Reset</b> is called whenever Feature Collection
/// desires a <b>FT.FeatureGetter</b> object to reinitialize its tracker state and
/// to start collecting feature information as if no previous information
/// had been collected.  After all the <b>Reset</b> methods have been called then
/// the local client data base of previous Feature Tracker keys and values will
/// be killed.  The kill of the local client data base is immediately followed by a
/// call to the <b><method>GetBegin</method></b> method and then calls to the
/// <b><method>GetInfo</method></b> method will immediately begin and
/// will be made during every following hour.
/// These method calls will repopulate the client data base of feature
/// key-value pairs.
/// <p>
/// The <b>Reset</b> method must be supplied by the <b>FT.FeatureGetter</b> subclass
/// if any of the Feature keys defined by the subclass need to be reset
/// to their initial states after the previous Feature Tracker values were sent home
/// to the InterSystems server.  <b>Reset</b> is called after each successful
/// transfer of Feature information to the InterSystems server.  This occurs
/// about once per week.
/// <p>
/// Any <b>FT.FeatureGetter</b> object that just produces a type=0
/// string of configuration
/// information and which does not need its internal state to be reset can avoid
/// overriding the <b>Reset</b> class method and can instead default to using
/// the <b>Reset</b> class method from the abstract <b>FT.FeatureGetter</b> class.
/// <p>
/// A call on a <b>Reset()</b> class method returns a <b><class>%Status</class></b>
/// value.  This return status should contain an error value if the
/// <b>FT.FeatureGetter</b> object needs to reset its internal collection state but
/// the <b>Reset</b> method discovers that it is unable to do so.
/// 
ClassMethod Reset() As %Status [ Internal ]
{
	#dim code As %Integer
	#dim ex As %Exception.General
	#dim key As %String
	#dim sc As %Status

	set sc = $$$OK
	try {
		do FTKeysSetup^%apiSQL()
		set key=""
		for  {
			set key=$o($system.Context.SQL().FTKeys(key),1,code) quit:key=""
			do $$$FTCLEAR(code)
		}
	}
	catch ex {
		set sc = ex.AsStatus()
	}
	RETURN sc
}

}
