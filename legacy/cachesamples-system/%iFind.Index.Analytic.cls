/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology on which this index type is based is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail. The <class>%iKnow.Index.Basic</class> and <class>%iKnow.Index.Minimal</class>
/// index types remain fully supported.</p>
/// <p>This index class is a more advanced version of <class>%iFind.Index.Semantic</class>, leveraging
/// even more output of the iKnow engine. In addition to the core semantic information (entities and 
/// attributes), this index type will also save path, proximity and dominance information.</p>
/// 
/// <p>If the <parameter>IFINDMAPPINGS</parameter> index is set to 1 (the default for this type of
/// index), the following additional SQL projections will be generated:</p>
/// <ul>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_Path</b>: stores the entities making up a path
/// in each record as individual rows. See also <class>%iFind.Index.AbstractPath</class>.</li>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_PathVal</b>: stores the entities making up a path
/// in each record as a list. See also <class>%iFind.Index.AbstractPathVal</class>.</li>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_Prox</b>: stores the proximity score for each pair of
/// entities in each record. See also <class>%iFind.Index.AbstractProximity</class>.</li>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_Dom</b>: stores the dominance information for each
/// entity in each record. See also <class>%iFind.Index.AbstractDominance</class>.</li>
/// </ul>
/// 
/// <p>For a detailed description of the other configuration and query options, see the class reference
/// for <class>%iFind.Index.Basic</class> and <class>%iFind.Index.Semantic</class>.</p>
Class %iFind.Index.Analytic Extends %iFind.Index.Semantic [ Deprecated, EmbeddedClass = %iFind.Find.Analytic, System = 2 ]
{

Parameter FILER [ Internal ] = "%iFind.Filer.Analytic";

/// <p>This parameter is deprecated in favor of the <parameter>IFINDMAPPINGS</parameter> flag.
/// A nonzero value for this parameter will be interpreted in the same way as having set 
/// <parameter>IFINDMAPPINGS</parameter> to 1.</p>
Parameter IFINDADVANCED As INTEGER [ Constraint = "0,1,2", Deprecated, Internal ] = 0;

Parameter RANKERCLASS As STRING = "%iFind.Rank.Analytic";

Parameter IFINDMAPPINGS As BOOLEAN = 1;

}
