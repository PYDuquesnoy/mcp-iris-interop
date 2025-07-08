/// Stores information about time durations.
Class Cinema.Duration Extends %Library.Integer
{

/// Converts the value of <var>%val</var>, which is in logical integer format, into a display string. 
/// The formatting is based on the value of the FORMAT parameter.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Integer) As %String
{
 Quit (%val \ 60) _ "h" _ (%val# 60) _ "m"
}

}

