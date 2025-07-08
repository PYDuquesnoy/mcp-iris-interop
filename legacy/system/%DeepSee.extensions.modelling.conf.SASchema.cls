/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.conf.SASchema Extends %Studio.SASchemaClass [ System = 3 ]
{

/// This is the namespace value used to identify this SA schema.
/// This corresponds to the XMLNamespace keyword of a Studio XData block.
Parameter XMLNAMESPACE = "http://www.intersystems.com/deepsee/modelling";

/// This is comma-separated list of the classes whose xml elements
/// can be used as the root level element of a document.
Parameter ROOTCLASSES As STRING = "%DeepSee.extensions.modelling.conf.Call:Call,%DeepSee.extensions.modelling.conf.LDA:LDA,%DeepSee.extensions.modelling.conf.LoadMetric:LoadMetric,%DeepSee.extensions.modelling.conf.Model:Model,%DeepSee.extensions.modelling.conf.PCA:PCA,%DeepSee.extensions.modelling.conf.Report:Report,%DeepSee.extensions.modelling.conf.Sequence:Sequence,%DeepSee.extensions.modelling.conf.Table:Table,%DeepSee.extensions.modelling.conf.NaiveBayes:NaiveBayes,%DeepSee.extensions.modelling.conf.PMML:PMML";

}
