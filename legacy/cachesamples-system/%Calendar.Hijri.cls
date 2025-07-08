/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A %Calendar.Hijri object contains a sequence of monthly lunar observations
/// that can be installed into an InterSystems IRIS process so that the $ZDATE[TIME][H](x,20,...)
/// and $ZDATE[TIME][H](x,21,...) functions use those observations when
/// computing Hijri dates.
/// <p>
/// Evaluating ##class(%Calendar.Hijri).%New(Name,Year,DateH,Months)
/// produces a new Hijri Observation Calendar object with the
/// the calendar name specified by the argument Name.  The argument
/// Year is the Hijri year number for the year containing the first 12 lunar
/// observations.  The argument DateH contains a ObjectScript $HOROLOG date
/// value specifying the first day of the first Hijri year containing
/// observational data.  The String Months contains the observations starting
/// from the first month of Hijri year Year.  If the length of Months string
/// argument is not a multiple 12 then extra observations will be added to fill
/// out to the end of the last year.  These extra months will attempt to
/// bring the last day of the Observed calendar years closer to the
/// Tabular calendar.  These supplied months can be changed in the future
/// after the actual observations are available.
/// A character in the string Months must be "0" if there is a lunar
/// observation which ends the corresponding month on the 29th day.
/// The character in the string Months must be "1" if there is no
/// lunar observation on the 29th day of the month and that month instead
/// has 30 days.  No characters other than "0" and "1" are permitted in
/// the Months string.
/// <p>
/// Note the description of the Delta property which keeps track of the difference
/// between the Observational Calendar and the Tabular Calendar.  When a %Calendar.Hijri
/// is created (by the %New method) or is modified (by the AddObservation method),
/// there is a restriction that the the difference between the Observed Calendar dates
/// and the corresponding Tabular Calendar dates cannot be greater than 5 days apart.  Such a
/// difference between the Observed Calendar and the Tabular Calendar indicates
/// an error in the observational data that is trying to become part of the %Calendar.Hijri
/// object.  An attempt to have a difference that is more than 5 days earlier or more
/// than 5 days later means the new object will not be created or that an existing
/// object will not be modified.
/// <p>
/// Users of the %Calendar.Hijri Class are encouraged to suggest
/// improvements to InterSystems that could be added to this Class
/// 
Class %Calendar.Hijri Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// Parameter #MaxYear specifies the maximum number of Hijri years
/// containing observations that can be loaded into an InterSystems IRIS process.
Parameter MaxYear = 2000;

/// Parameter #EarlyDate is smallest (most negative) DateH value than
/// can be passed to ##class(%Calendar.Hijri).%New(Name,Year,DateH,Months)
/// when creating a new %Calendar.Hijri object.  It is 5 days earlier
/// than AH date 1 1 0001 in the Tabular Hijri calendar.  Note that the
/// Tabular calendar will not handle DateH values earlier than -445031.
/// 
Parameter EarlyDate = -445036;

/// Property CalendarName contains the unique name of the
/// %Calendar.Hijri object.  The CalendarName in the ID key used
/// to locate a particular %Calendar.Hijri object by evaluating
/// ##class(%Calendar.Hijri).OpenId(CalendarName)
Property CalendarName As %String [ ReadOnly, Required ];

Index CalendarNameIndex On CalendarName [ IdKey, Unique ];

/// Property BeginYear is the AH year containing the first observation
Property BeginYear As %Integer [ ReadOnly, Required ];

/// Property BeginDateH is the $HOROLOG format date corresponding
/// to first day of the first year containing lunar observations.
Property BeginDateH As %Date [ ReadOnly, Required ];

/// Property Months is a string of "1"s and "0"s where each
/// character specifies the
/// lunar observation for the corresponding month.  The length
/// of the string Months is (EndYear - BeginYear) * 12.
/// <p>
/// The character "0" indicates a 29 day month; the character "1"
/// indicates a 30 day month.
/// 
Property Months As %String [ ReadOnly, Required ];

/// Property EndYear is the AH year following the year with
/// the last string of observations.
Property EndYear As %Integer [ ReadOnly, Transient ];

/// Delta is a string of characters indicating the difference
/// between the Observed calendar and the Tabular calendar on
/// the first day of every year.  The character "F" indicates a delta
/// of 0; the characters "A"..."E" indicate deltas of -5..-1;
/// and the characters "G"..."K" indicates deltas of +1..+5.
/// The length of the string Delta is EndYear - BeginYear + 1.
/// The first character of Delta indicates the difference between
/// $ZDATE("1 1 "_..BeginYear,21)-$ZDATE("1 1 "_.BeginYear,19)
/// I.e., the difference between the Calendar with lunar observations
/// and the Tabular Calendar on the first year containing
/// observations.  On first day of each year, the delta
/// between Observed Calendar minus the Tabluar Calendar must be in
/// the range -5 .. +5.  The last character of the string Delta
/// indicates the difference between the Observed Calendar minus the
/// Tabular Calendar on the first day of year ..EndYear.
/// 
Property Delta As %String [ ReadOnly, Transient ];

Method %OnNew(Name As %String, Year As %Integer, DateH As %Date, Months As %String) As %Status [ Internal, Private, ServerOnly = 1 ]
{
  Try {
    Set Year=+Year,DateH=+DateH
    If Year<=0||(Year>..#MaxYear)  Return $$$ERROR($$$GeneralError,"Illegal Year value, "_Year)
    // Compute difference Observed - Tabular and check for legal
    Set TabDateH = $ZDATEH("1 1 "_Year,19,,,,,..#EarlyDate),Delta=DateH-TabDateH
    Do TestDelta
    // Compute and test ending Year value
    Set N=($Length(Months)+11)\12
    If N<=0 Return $$$ERROR($$$GeneralError,"Month string is empty")
    Set i%EndYear=Year+N
    If ..EndYear>(..#MaxYear+1) Return $$$ERROR($$$GeneralError,"Illegal ending Year value "_(..EndYear-1))
    // Place Data in Calendar object    
    Set i%CalendarName = Name,i%BeginYear=Year,i%BeginDateH=DateH,i%Months=Months
    // Scan through all the months in eacy year.
    // Check that first of each year has legal Delta (ObservedDateH - TabularDateH)
    Set Month=0,EndM=""
    While Year<..EndYear {
        Set T=Delta  ;; T keeps track of Delta month by month (accurate and used only in last year)
        For Month=Month+1:1:Month+12 {
            Set X=$Extract(Months,Month)
            If X="0" { Set:Month#2 T=T-1}
            // Add in the number of 30 day months in the Observed Year
            ElseIf X="1" { Set Delta = Delta+1  Set:'(Month#2) T=T+1 }
            ElseIf X="" {
                // Handle missing months by moving towards the Tabular calendar
                If T>0 { Set EndM=EndM_"0" Set:Month#2 T=T-1 }
                ElseIf T<0 { Set EndM=EndM_"1",Delta=Delta+1  Set:'(Month#2) T=T+1 }
                Else { Set X=$Select(Month#2:"1",Month#12=0&&..IsLeap(Year):"1",1:"0"),EndM=EndM_X  Set:X="1" Delta=Delta+1 }
            } Else {  Return $$$ERROR($$$GeneralError,"Illegal Month String Character, "_X) }
        }
        // Recompute and Test Delta at end of year
        Set Delta=Delta+(12*29)+TabDateH,Year=Year+1
        Set TabDateH=$ZDATEH("1 1 "_Year,19,,,,,..#EarlyDate)
        Set Delta=Delta-TabDateH
        Do TestDelta
    }
    // Append any added Months to the end of the Months string
    Set:$Length(EndM) i%Months=Months_EndM
    Return $$$OK
  } Catch (ex) {
    Return ex.AsStatus()
  }
    
TestDelta
    If Delta<-5||(Delta>5) {
        Throw ##class(%Exception.StatusException).CreateFromStatus(
            $$$ERROR($$$GeneralError,"Difference between Observed-Tabular too large at year "_Year)
        )
    }
    // Append Delta value onto Delta property
    Set i%Delta=..Delta_$Char($Ascii("F")+Delta)
    Quit
}

Method %OnOpen() As %Status [ Internal, Private, ServerOnly = 1 ]
{
    // Compute ..EndYear and ..Delta when loading object
    // into memory.
    Set i%EndYear=..BeginYear+($Length(..Months)\12)
    Set Year=..BeginYear,Month=0
    Set TabDateH = $ZDATEH("1 1 "_Year,19,,,,,..#EarlyDate),Delta=..BeginDateH-TabDateH
    Set i%Delta=$Char($Ascii("F")+Delta)
    While Year < ..EndYear {
        For Month=Month+1:1:Month+12 {
            Set X=$Extract(..Months,Month)
            If X="1" { Set Delta = Delta+1 }
        }
        // Recompute Delta at end of year
        Set Delta=Delta+(12*29)+TabDateH,Year=Year+1
        Set TabDateH=$ZDATEH("1 1 "_Year,19,,,,,..#EarlyDate)
        Set Delta=Delta-TabDateH
        Set i%Delta=..Delta_$Char($Ascii("F")+Delta)
    }
    Return $$$OK
}

/// The IsLeap(Year) Class Method returns 1 if Year is a Tabular
/// Leap Year; otherwise it returns 0.
ClassMethod IsLeap(Year As %Integer) As %Boolean
{
    Quit $ZDATEH("1 1 "_(Year+1),19,,,,,..#EarlyDate)-$ZDATEH("1 1 "_Year,19,,,,,..#EarlyDate)-354
}

/// The Method InstallCalendar installs the Observed Calendar
/// contained in the %Calendar.Hijri object into the process
/// for use by the $ZDATE[TIME][H](x,mode,...) functions, where
/// mode is one of 20 or 21.
/// 
Method InstallCalendar() As %Status
{
    Set MaskString="",Month=0,EndMonth=(..EndYear-..BeginYear)*12
    While Month<EndMonth {
        Set Mask=0
        For Month=Month+1:1:Month+6 {
            If $Extract(..Months,Month)="1" { Set Mask=Mask+64 }
            Set Mask=Mask\2
        }
        Set MaskString=MaskString_$NConvert(Mask,"U1")      
    }
    Do $ZU(118,1,..BeginYear,$Ascii($Extract(..Delta))-$Ascii("F"),MaskString)
    Quit $$$OK
}

/// The RemoveCalendar() Class Method removes any lunar observations
/// installed in the process so the $ZDATE[TIME][H] functions
/// using date formats 20 and 21 default
/// to using the Tabular Hijri Calendar instead of using lunar
/// Observations to control the Hijri Calendar.
ClassMethod RemoveCalendar()
{
    Do $ZU(118,0)
    Quit $$$OK
}

/// The method AddObservation will modify a lunar observation in the last year
/// of the %Calendar.Hijri object.  If necessary, an additional year of observations will
/// be added to the object when the observation is in the year following the
/// last year of observations.  The additional year will be constructed to sync the
/// Observed Calendar with the Tabular Calendar before adding the new Observation.
/// <p>
/// If the new Observation is being made to a month before Month 12 then AddNewObservation
/// method will attempt to modify an observation in a month following the new Observation
/// so that the Observed - Tabular difference at the end of the year is not changed.
/// <p>
/// You must have installed all the observations for the months of the last year before
/// you use AddObservation to add an observations for a new, additional ending year.  After
/// a new year is added to the table of observations, the only way to modify any preceding
/// year to to call ##class(%Calendar.Hijri).%New(Name,Year,DateH,Months) to in create a new object
/// containing the modified observations.  (Hint:  If you want to keep the same name as an
/// existing object then you must delete the existing object before creating a new object
/// with the same name.)
/// <p>
/// Note: AddObservation just modifies the in-process copy of the Calendar.  You must use
/// the %Save method to save the modification back to your namespace.  Also, AddObservation
/// does not "install" your change into the process.  You must use the InstallCalendar
/// method to have the $ZDATE[TIME][H](x,20,...) or $ZDATE[TIME][H](x,21,...) functions
/// start using the new observation.
/// 
Method AddObservation(Month As %Integer, Year As %Integer, Observation As %Integer) As %Status
{
    If Month<1 || (Month>12) || (Year<(..EndYear-1)) || (Year>..EndYear) {
        Return $$$ERROR($$$GeneralError,"Illegal Month/Year")
    }
    Set Observation=$Select(+Observation:"1",1:"0")
    If Year=..EndYear {
        // Must add additional year to end of observations
        // Handle new months by moving towards the Tabular calendar
        // After adding an additional Year we will be in sync with Tabular Calendar
	// Cannot go beyond #MaxYear
	if Year>..#MaxYear Return $$$ERROR($$$GeneralError,"Illegal ending Year value "_Year)
        Set Delta=$Ascii($Extract(..Delta,*))-$Ascii("F"),EndM="10101010101"_$Select(..IsLeap(Year):"1",1:"0")
        For i=1:2:13 {
            If Delta>0 { Set $Extract(EndM,i)="0",Delta=Delta-1}
            Elseif Delta<0 { Set $Extract(EndM,i+1)="1",Delta=Delta+1 }
            Else { Quit }
        }
        Set i%Months=..Months_EndM,i%EndYear=..EndYear+1,i%Delta=..Delta_"F"
    }
    Set i=$Length(..Months)-12+Month
    // If we not changing the stored observation then just return
    If $Extract(..Months,i)=Observation { Return $$$OK }
    // Change observation in a copy
    Set Months=..Months
    Set $Extract(Months,i)=Observation
    // Scan for future month with same obersvation
    // and reverse it (and we are done since no change in end-of-year delta
    For i=i+1:1:$Length(..Months) {
        if $Extract(Months,i)=Observation {
            Set $Extract(Months,i)=$Select(Observation="0":"1",1:"0")
            Set i%Months=Months
            Return $$$OK
        }
    }
    // Could not adjust for change; we must adjust Delta
    Set Delta=$Ascii($Extract(..Delta,*))-$Ascii("F")
    If Observation="0" {
        Set Delta=Delta-1
        If Delta<-5 { Goto DeltaError }
    } Else {
        Set Delta=Delta+1
        If Delta>5 { Goto DeltaError }
    }
    Set i%Months=Months
    Set i%Delta=$Extract(..Delta,1,*-1)_$Char($Ascii("F")+Delta)
    Return $$$OK
    
DeltaError
    // Delta out of range at beginning of ..EndYear
    // Undo storing of the Obseration into Month
    Set $Extract(i%Months,*-(12-Month))=$Select(Observation="1":"0",1:"1")
    Return $$$ERROR($$$GeneralError,"Difference between Observed-Tabular too large at year "_..EndYear)
}

Storage Default
{
<Data name="HijriDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>BeginYear</Value>
</Value>
<Value name="3">
<Value>BeginDateH</Value>
</Value>
<Value name="4">
<Value>Months</Value>
</Value>
</Data>
<DataLocation>^Calendar.HijriD</DataLocation>
<DefaultData>HijriDefaultData</DefaultData>
<IdLocation>^Calendar.HijriD</IdLocation>
<IndexLocation>^Calendar.HijriI</IndexLocation>
<StreamLocation>^Calendar.HijriS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
