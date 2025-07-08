/// This class is part of the DeepSee Patients sample, whose purpose is to provide
/// sample data for use with DeepSee. 
/// <p>
/// An allergy has multiple pieces of information,
/// which you can use separately or in combination to create dimensions, depending
/// on what you want to see.
Class DeepSee.Study.PatientAllergy1 Extends %Persistent
{

/// Patient who has this allergy
Property Patient As DeepSee.Study.Patient;

/// A substance to which the patient is allergic.
Property Allergen As DeepSee.Study.Allergen;

/// Severity of this allergic reaction.
Property Severity As DeepSee.Study.AllergySeverity;

/// Doctor who recorded this allergic reaction.
Property DiagnosedBy As DeepSee.Study.Doctor;

ClassMethod CreateOne(patient As DeepSee.Study.Patient, allergen As DeepSee.Study.Allergen = "", severity As DeepSee.Study.AllergySeverity = "", diagnosedBy As DeepSee.Study.Doctor = "") As %Status
{
	set new=..%New()
	set new.Patient=patient
	if (allergen'="") {
		set new.Allergen=allergen
	}
	if (severity'="") {
		set new.Severity=severity
	}
	if (diagnosedBy'="") {
		set new.DiagnosedBy=diagnosedBy
	}
	set status=new.%Save()
	quit status
}

Storage Default
{
<Data name="PatientAllergy1DefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Allergen</Value>
</Value>
<Value name="3">
<Value>Severity</Value>
</Value>
<Value name="4">
<Value>DiagnosedBy</Value>
</Value>
<Value name="5">
<Value>Patient</Value>
</Value>
</Data>
<DataLocation>^DeepSee.Study.PatientAllergy1D</DataLocation>
<DefaultData>PatientAllergy1DefaultData</DefaultData>
<IdLocation>^DeepSee.Study.PatientAllergy1D</IdLocation>
<IndexLocation>^DeepSee.Study.PatientAllergy1I</IndexLocation>
<StreamLocation>^DeepSee.Study.PatientAllergy1S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

