/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Privides all the parameters that a parameter needs to
/// contain if it is to project correctly into an MV
/// data file.
/// 
/// An MV projection is actually the projection of the dictionary
/// elements 
Class %MV.PropertyParameters [ ServerOnly = 1, System = 3 ]
{

/// The name of the dictionary element in MV terms (DICT name)
/// As the MV DICT elements can have just about any character in them, we
/// cannot merely use the name of the property. However, if this is the
/// empty string then the property name is assumed. 
/// 
Parameter MVNAME As STRING;

/// The Type of Dictionary element that this represents. Types are
/// D       (Uses MVITYPE if present, MVTOLOGICAL and MVCONVERSION are not allowed)
/// A or S  (Uses MVTOLOGICAL and MVCONVERSION if present. MVITYPE not allowed)
/// 
Parameter MVTYPE As STRING = "D";

/// The heading string that is printed at the top of the column of a CMQL listing
/// 
Parameter MVHEADING As STRING;

/// The ASSOC Parameter of an MV dictionary element
/// 
Parameter MVASSOCIATION As STRING;

/// The attribute code (usually the attribute number within a record in the
/// MV file, but can be 0 if a F correlative or A correlative is in force
/// so you cannot rely on this as any real indicator of the value position
/// you must calculate the value using the entire record and the $MVOCONV()
/// function.
/// 
Parameter MVATTRIBUTE As INTEGER;

/// Right or Left or other type of justification of this column
/// 
Parameter MVJUSTIFICATION As STRING;

/// The format code for an MV dictionary element
/// 
Parameter MVFORMAT As STRING;

/// The display width of an MV dictionary element (width of column used in
/// formatted output.
/// 
Parameter MVWIDTH As STRING;

/// The conversion code used to generate data from the raw data of a
/// record. This code is used in COS code as follows:
///  Set d = $MVCONV("RawValue", MVTODISPLAY
/// 
/// Note that if an MVITYPE is present, then neither an MVTODISPLAY
/// nor a MVTOLOGICAL can be present. You either use an MVITYPE or you use
/// MVTODISPLAY AND MVTOLOGICAL. The MVTYPE parameter being "D" indicates that 
/// this is the Prime/UniVerse format and uses Itypes, not MVTODISPLAY
/// and MVTOLOGICAL
/// 
Parameter MVTODISPLAY As STRING;

/// The code for attribute 8 of a dictionary element. This generates the
/// data which is selected against or displayed.
/// 
/// Note that if an MVITYPE is present, then neither an MVTODISPLAY
/// nor a MVTOLOGICAL can be present. You either use an MVITYPE or you use
/// MVTODISPLAY AND MVTOLOGICAL. The MVTYPE parameter being "D" indicates that 
/// this is the Prime/UniVerse format and uses Itypes, not MVTODISPLAY
/// and MVTOLOGICAL
/// 
Parameter MVTOLOGICAL As STRING;

/// The code for the I type of a dictionary element. This generates the
/// data which is selected against or displayed. This is compiled and included 
/// in the class as the calc Method for this property.
/// 
/// Note that if an MVITYPE is present, then neither an MVCONVERSION
/// nor a MVTOLOGICAL can be present. You either use an MVITYPE or you use
/// MVCONVERSION and MVTOLOGICAL. The MVTYPE parameter being "D" indicates that 
/// this is the Prime/UniVerse format and uses Itypes, not MVCONVERSION
/// and MVTOLOGICAL
/// 
Parameter MVITYPE As STRING;

/// Set this parameter to True if it should be projected
/// back to the DICT of the file that the containing class projects
/// to, ot False if this definition is used by the class (for SQL, XML
/// etc) only.
/// 
Parameter MVPROJECTED As BOOLEAN = 1;

/// If set then this is the name of the subvalues SQL table projected by the compiler.
/// Each row in the table corresponds to one subvalue. If more than one property has the same
/// value for MVSVASSOCIATION then the SQL table will contain associated values as individual
/// columns. MVSVASSOCIATION cannot use the same name as MVASSOCIATION.
Parameter MVSVASSOCIATION As STRING;

/// This parameter is used by CREATE.INDEX and PROTOCLASS to track the creation and
/// use of properties. It is also used by DELETE.INDEX to determine if this property 
/// should be deleted if the index is deleted. Remove this parameter if you want to take manual
/// control of the property.
/// 
Parameter MVAUTO As STRING;

}
