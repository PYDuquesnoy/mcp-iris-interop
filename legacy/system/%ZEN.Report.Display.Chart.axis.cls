/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for <class>xaxis</class> and <class>yaxis</class>.  
Class %ZEN.Report.Display.Chart.axis Extends %ZEN.Report.Display.node [ Abstract, Deprecated, System = 4 ]
{

/// Minimum value along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property minValue As %ZEN.Datatype.float;

/// Maximum value along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property maxValue As %ZEN.Datatype.float;

/// When minValue is automatically calculated this displacement is added to minValue
Property minValueDisplacement As %ZEN.Datatype.float;

/// When minValue is automatically calculated this displacement is added to minValue
Property maxValueDisplacement As %ZEN.Datatype.float;

/// Optional title to display along this axis.
Property title As %ZEN.Datatype.caption;

/// Base value for this axis. For charts with filled regions
/// (such as bar or area plots), this specifies where the base
/// of the filled region should be plotted.<br>
/// If this is missing (""), then the base value will be the bottom of the plot area.
Property baseValue As %ZEN.Datatype.float;

/// Major units along this axis. This specifies how major gridlines will be spaced along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property majorUnits As %ZEN.Datatype.float(MINVAL = 0);

/// Minor units along this axis. This specifies how minor gridlines will be spaced along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property minorUnits As %ZEN.Datatype.float(MINVAL = 0);

/// Label units along this axis. This specifies how labels will be spaced along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property labelUnits As %ZEN.Datatype.float(MINVAL = 0);

/// Number of degrees that labels for this axis should be rotated.
Property labelAngle As %ZEN.Datatype.float [ InitialExpression = 0 ];

/// Specifies whether gridlines should be displayed for each major unit.
Property majorGridLines As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Specifies whether gridlines should be displayed for each minor unit.
Property minorGridLines As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: style used for labels along this axis.
Property labelStyle As %ZEN.Datatype.style;

/// textAnchor value
Property textAnchor As %ZEN.Datatype.string [ InitialExpression = "middle" ];

/// Optional: comma-delimited list of label values of category axes.
/// If left blank, the category number is used.
Property labelValues As %ZEN.Datatype.csv;

/// Optional: Group used to get label values of category axes.
/// If left blank, the category number is used.
Property labelGroup As %ZEN.Datatype.string;

/// Optional: Value used to get label values of category axes from Group.
/// If left blank, the category number is used.
Property labelValue As %ZEN.Datatype.string;

/// Optional: style used for major grid lines along this axis.
Property majorGridStyle As %ZEN.Datatype.style;

/// Optional: style used for minor grid lines along this axis.
Property minorGridStyle As %ZEN.Datatype.style;

Property labelDisplacement As %ZEN.Datatype.float [ InitialExpression = 0 ];

}
