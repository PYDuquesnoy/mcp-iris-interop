/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee.CA

/// This class provides a base class for implementation for different Cluster Analysis algorithms. 
/// It defines storage for clustering models and provides methods to retrieve information about data and clustering.
/// <p>
/// Cluster analysis or clustering is the assignment of a set of observations into subsets 
/// (called clusters) so that observations in the same cluster are similar in some sense.
///  Clustering is a method of unsupervised learning, and a common technique for statistical 
/// data analysis used in many fields, including machine learning, data mining, pattern recognition, 
/// image analysis, information retrieval, and bioinformatics.
/// <p>
/// By Default model data is stored in ^IRIS.Temp globals.
Class %DeepSee.extensions.clusters.AbstractModel Extends %RegisteredObject [ System = 4 ]
{

Property Dim As %Integer;

Property DSName As %String;

/// Whether to normalize distance across multiple dimensions. If set to 1 (default) then
/// distance is normalized by variances.
Property Normalize As %Boolean [ InitialExpression = 1 ];

/// The power to use in calculation of dissimilarity. Default is Euclidean distance (P=2). 
/// Specify 1 for Manhattan Distance or 100 for Chebyshev distance (max between coordinates).
Property P As %Double [ InitialExpression = 2 ];

Property Verbose As %Boolean [ InitialExpression = 1 ];

/// Checks whether a model for a dataset with the name given by <var>dataset</var> argument already exists.
ClassMethod Exists(dataset As %String) As %Boolean
{
	Quit ($d($$$DSData(dataset))>0)
}

/// Deletes a model for a dataset with the name given by <var>dataset</var> argument.
ClassMethod Delete(dataset As %String) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		k $$$DSData(dataset)
		k $$$DSCostMatrix(dataset)
		k $$$DSCluster(dataset)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}	
	Quit sc
}

ClassMethod Check(dataset As %String, exists As %Boolean) As %Status [ Internal ]
{
	#dim doesExist As %Boolean
	
	set doesExist = ..Exists(dataset)
	Quit:(exists=doesExist) $$$OK
	
	Quit:doesExist $$$ERROR($$$GeneralError,"Dataset "_dataset_" already exists")
	Quit $$$ERROR($$$GeneralError,"Dataset "_dataset_" does not exist")
}

/// Checks whether the model is ready for an analysis to be executed. This is dependent on a 
/// specific algorithm and therefore this method is overriden by subclasses.
Method IsPrepared() As %Boolean
{
	Quit ..Exists(..DSName)
}

/// Kills all the data associated with this model.
Method Reset()
{
	k $$$MyData
	k $$$CostMatrix
	k $$$MyCluster
}

/// Sets the data to be associated with this model. The method takes 3 arguments:
/// <ul>
/// <li> <var>rs</var> - is a result set that provides the data. The first column returned by the result set 
/// is assumed to be a unique Id of teh record. It is not used in any clustering algorithms but can be retrieved 
/// by the application to identify the record. It can be a database %ID or any other value that 
/// makes sense to the application. Other columns provide numerical values for the coordinates of the record 
/// that are used by clustering algorithms.
/// Result Set must contain at least <var>dim</var> + 1 columns.
/// <li> <var>dim</var> - The dimensionality of the model, i.e. the number of the coordinates 
/// consumed by clustering algorithm.
/// <li> <var>nullReplacement</var> - Optional, of specified this is a numeric replacement for empty values. 
/// </ul>
Method SetData(rs As %IResultSet, dim As %Integer, nullReplacement As %Double = -1) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim i,n	As %Integer
	#dim id As %RawString
	#dim s1, s2
	
	do ..Reset()
	
	set ..Dim = dim
	set $$$Dim = dim
	set $$$Count = 0
	
	For i=1:1:dim {
		set s1(i) = 0
		set s2(i) = 0
		set $$$DimName(i) = rs.%GetMetadata().columns.GetAt(i+1).colName
	}
	
	While(rs.%Next()) {
		set $$$Count = $i($$$Count)
		set id = rs.%GetData(1)
		set $$$GetId($$$Count) = id
		set $$$ById(id) = $$$Count
		For i=1:1:dim {
			#dim x = rs.%GetData(i + 1)
			set:x="" x = nullReplacement
			set $$$Data($$$Count,i) = x
			
			set s1(i) = s1(i) + x
			set s2(i) = s2(i) + (x * x)
		}
	}
	
	do rs.%Close()
	
	set n = $$$Count
	if (n < 2) {
		set sc = $$$ERROR($$$GeneralError,"Too few members in the dataset")
		Quit sc
	}
	
	For i=1:1:dim {
		#dim m = s1(i)/n
		
		set $$$Var(i) = (s2(i) - (s1(i) * m)) / (n - 1)
	}
	
	Quit sc
}

Method dist(i As %Integer, j As %Integer) As %Double [ Internal ]
{
	Quit ..Distance(i, j, ..P, ..Normalize)
}

/// Returns the dissimilarity measure between two data points of the model. The method takes 4 arguments:
/// <ul>
/// <li> <var>i</var>, <var>j</var> - Ordinal number of the data points in the model
/// <li> <var>p</var> - Optional, if specified the power for a Minkowski distance. Default is Euclidean distance (p=2). 
/// Specify 1 for Manhattan Distance or 100 for Chebyshev distance (max between coordinates).
/// <li> <var>normalize</var> - whether to normalize coordinates by their variances 
/// </ul>
Method Distance(i As %Integer, j As %Integer, p As %Double = 2, normalize As %Boolean = 1) As %Double
{
	Quit:$$$Dim=1 $zabs($$$Data(i,1) - $$$Data(j,1))
	
	#dim z1, z2
	#dim k As %Integer
	for k=1:1:$$$Dim {
		set z1(k) = $$$Data(i,k)
		set z2(k) = $$$Data(j,k)
	}
	
	Quit ..Distance12(.z1, .z2, p, normalize)
}

/// Returns the dissimilarity measure between a data points of the model and a point with given coordinates. 
/// The method takes 4 arguments:
/// <ul>
/// <li> <var>i</var> - The ordinal number of the data point in the model
/// <li> <var>z</var> - The multidimensional coordinates of the second point: z(1), z(2), ..., z(dim)
/// <li> <var>p</var> - Optional, if specified the power for a Minkowski distance. Default is Euclidean distance (p=2). 
/// Specify 1 for Manhattan Distance or 100 for Chebyshev distance (max between coordinates).
/// <li> <var>normalize</var> - whether to normalize coordinates by their variances 
/// </ul>
Method Distance1(i As %Integer, ByRef z, p As %Double = 2, normalize As %Boolean = 1) As %Double
{
	Quit:$$$Dim=1 $zabs($$$Data(i,1) - z(1))

	#dim z1
	#dim k As %Integer
	for k=1:1:$$$Dim {
		set z1(k) = $$$Data(i,k)
	}
	
	Quit ..Distance12(.z1, .z, p, normalize)
}

/// Returns the dissimilarity measure between two points with given coordinates. 
/// The method takes 4 arguments:
/// <ul>
/// <li> <var>z1</var>, <var>z2</var> - The multidimensional coordinates of the points: z1(1), z1(2), ..., z1(dim)
/// <li> <var>p</var> - Optional, if specified the power for a Minkowski distance. Default is Euclidean distance (p=2). 
/// Specify 1 for Manhattan Distance or 100 for Chebyshev distance (max between coordinates).
/// <li> <var>normalize</var> - whether to normalize coordinates by their variances 
/// </ul>
Method Distance12(ByRef z1, ByRef z2, p As %Double = 2, normalize As %Boolean = 1) As %Double
{
	Quit:$$$Dim=1 $zabs(z1(1) - z2(1))

	#dim k, dim As %Integer
	#dim x,s As %Double
	
	set dim = $$$Dim
	
	set s = 0
	for k = 1:1:dim {
		Continue:$$$Var(k)=0
		
		set x = z1(k) - z2(k)
		if (p = 1) {
			set x = $zabs(x)
			set:normalize x = x / $zsqr($$$Var(k))
		} elseif (p = 2) {
			set x = (x * x)
			set:normalize x = x / $$$Var(k)
		} elseif (p>99) {
			set x = $zabs(x)
			set:normalize x = x / $zsqr($$$Var(k))
			set:($zabs(x)>s) s = $zabs(x)
			Continue
		} else {
			set x = $zpower(x,p)
		}
		
		set s = s + x
	}

	if (p = 1) {
		Quit s
	} elseif (p = 2) {
		Quit $zsqr(s)
	} elseif (p>99) {
		Quit s
	} else {
		Quit $zpower(s,(1/p))
	}
}

/// Returns the number of clusters in the model.
Method GetNumberOfClusters() As %Integer
{
	Quit $g($$$NClstrs,0)
}

/// Returns the number of all data points in the model.
Method GetCount() As %Integer
{
	Quit $$$Count
}

/// Returns the unque Id of the point with the ordinal number specified by <var>i</var>. 
/// The unique Id is as has been assigned in <METHOD>SetData</METHOD> method
Method GetId(i As %Integer) As %String
{
	Quit $$$GetId(i)
}

/// Returns the ordinal number of the point with the given ID <var>id</var>. 
/// The unique <var>id</var> must correspond to the one assigned in <METHOD>SetData</METHOD> method
Method ById(id As %RawString) As %Integer
{
	Quit $g($$$ById(id))
}

Method GetData(i As %Integer, j As %Integer) As %String
{
	Quit $$$Data(i,j)
}

/// Returns the dimensionality of the model.
Method GetDimensions() As %Integer
{
	Quit $$$Dim
}

/// Returns the cluster ordinal for a given point. Point is identified by its ordinal number.
Method GetCluster(point As %Integer) As %Integer
{
	Quit $$$GetCluster(point)
}

/// Returns the dissimilarity measure as used by this clustering algorithm 
/// between two data points of the model. Points are identified by their ordinal numbers.
Method GetCost(i As %Integer, j As %Integer) As %Integer
{
	Quit $$$GetCost(i,j)
}

/// Iterates over all the data points assigned to a given cluster. 
/// Cluster is identified by its ordinal number <var>k</var>
Method iterateCluster(k As %Integer, ByRef i As %Integer, Output id As %String, Output coordinates)
{
	#dim n As %Integer
	set i = $o($$$Cluster(k,i),1,n)
	Quit:i=""
	
	#dim j As %Integer
	
	set id = $$$GetId(n)
	set coordinates = $$$Dim
	for j=1:1:$$$Dim {
		set coordinates(j) = $$$Data(n,j)
	}
}

/// Convenience method.
/// Writes all data points assigned to a given cluster to the default output device. 
/// Cluster is identified by its ordinal number <var>k</var>
Method printCluster(k As %Integer)
{
	#dim i, j As %Integer
	#dim id As %String
	#dim x
	
	w "Cluster "_k_":", !
	set i = ""
	Do {
		do ..iterateCluster(k, .i, .id, .x)
		Quit:i=""
		w i_": "_id_" ("
		for j=1:1:x {
			w x(j)
			w:j<x ","
		}	
		w ")", !
	} While(i'="")
}

/// Returns the coordinates for the centroid for a given cluster. 
/// Cluster is identified by its ordinal number <var>k</var>.
/// <br>
/// Coordinates are returned as multidimensional value: z(1), z(2), ..., z(dim)
Method GetCentroid(k As %Integer, Output z)
{
	#dim n, i, j, dim As %Integer
	#dim id As %String
	#dim x

	set dim = $$$Dim
	set n = 0
	for j=1:1:dim {
		set z(j) = 0
	}
	set i = ""
	Do {
		do ..iterateCluster(k, .i, .id, .x)
		Quit:i=""
		set n = $i(n)
		for j=1:1:x {
			set z(j) = z(j) + x(j)
		}	
	} While(i'="")

	for j=1:1:dim {
		set z(j) = z(j) / n
	}
	
	set z = $$$Dim
}

/// Returns the coordinates for the centroid for the whole dataset. 
/// <br>
/// Coordinates are returned as multidimensional value: z(1), z(2), ..., z(dim)
Method GlobalCentroid(Output z)
{
	#dim n, i, j, dim As %Integer
	#dim id As %String

	set dim = $$$Dim
	set n = $$$Count
	for j=1:1:dim {
		set z(j) = 0
	}

	for i = 1:1:n {	
		for j=1:1:dim {
			set z(j) = z(j) + $$$Data(i,j)
		}	
	}

	for j=1:1:dim {
		set z(j) = z(j) / n
	}

	set z = $$$Dim
}

Method SubsetCentroid(key As %String, Output z)
{
	#dim n, i, j, dim As %Integer
	#dim id As %String

	set dim = $$$Dim
	set n = $$$SubsetCount(key)
	for j=1:1:dim {
		set z(j) = 0
	}

	set i = 0
	While(i'="") {
		set i = $$$SubsetNext(key, i)
		Quit:i=""
		for j=1:1:dim {
			set z(j) = z(j) + $$$Data(i,j)
		}	
	}	

	for j=1:1:dim {
		set z(j) = z(j) / n
	}

	set z = $$$Dim
}

/// Returns the number of data points assigned to a given cluster. 
/// Cluster is identified by its ordinal number <var>k</var>.
Method GetClusterSize(k As %Integer)
{
	Quit $$$ClusterSize(k)
}

/// Convenience method.
/// Writes all data points in the dataset to the default output device. 
Method printAll()
{
	#dim i, j, n, c, dim As %Integer
	#dim id As %String
	
	set n = $$$Count
	set dim = $$$Dim
	
	for i=1:1:n {
		set c  = $$$GetCluster(i)
		set id = $$$GetId(i)
		w i_": "_id_"->"_c_" ("
		for j=1:1:dim {
			w $$$Data(i,j)
			w:j<dim ","
		}	
		w ")", !
	}
}

/// Returns the realtive cost of a given cluster relative to a medoid point <var>m</var>. 
/// Cluster is identified by its ordinal number <var>k</var>.
/// Point <var>m</var> is identified by its ordinal number.
Method RelativeClusterCost(k As %Integer, m As %Integer) As %Double
{
	#dim i, j As %Integer
	#dim d, s As %Double
	
	set j = $o($$$Cluster(k,""),1,i)
	set s = 0
	While(j'="") {
		if (i'=m) {
			set d = $$$GetCost(m,i)
			set s = s + d
		}
		set j = $o($$$Cluster(k,j),1,i)
	}
	
	Quit s
}

/// Returns an object that can calculate an index used in Cluster Validation 
/// and determining the optimal number of clusters. This method returns Calinski-Harabasz index.
Method GetCalinskiHarabaszIndex(normalize As %Integer = -1) As CalinskiHarabasz
{
	set:normalize<0 normalize = ..Normalize
	set ch = ##class(CalinskiHarabasz).%New()
	set ch.normalize = normalize
	set ch.Model = $this
	Quit ch
}

/// Returns an object that can calculate an index used in Cluster Validation 
/// and determining the optimal number of clusters. 
/// This method returns Average Silhouette Width index.
Method GetASWIndex() As ASW
{
	set asw = ##class(ASW).%New()
	set asw.Model = $this
	Quit asw
}

/// Returns an object that can calculate an index used in Cluster Validation 
/// and determining the optimal number of clusters. 
/// This method returns Pearson-Gamma index which is a correlation coefficient 
/// between distance between two points and a binary function whether they 
/// belong to the same cluster. This index is useful when clustering is used 
/// for dimension reduction i.e. the process of reducing the number of 
/// random variables under consideration
Method GetPearsonGammaIndex() As PearsonGamma
{
	set pg = ##class(PearsonGamma).%New()
	set pg.Model = $this
	Quit pg
}

ClassMethod time(ByRef ts) As %Double [ Internal ]
{
	#dim t, zts
	set t = $p($zts,",",2) - $p(ts,",",2)
	set ts = $zts
	Quit t
}

Method randomSubset(size As %Integer, ByRef sc As %Status) As %Integer
{
	#dim ex As %Exception.AbstractException
	#dim n, i, j, key As %Integer
	#dim ds As %String
	
	set sc = $$$OK

	set key = $p($h,",",1)_$p($h,",",2)
	Try {
		set n = $$$Count
		set i = 1
		While(i<=size) {
			set j = $r(n) + 1
			if ($d($$$Subset(key,j))'=0) {
				Continue
			}
			set $$$Subset(key,j) = i
			set i = $i(i)
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}	
	set $$$SubsetCount(key) = size

	Quit key
}

Method GeneratePMML(Output pPMML As %DeepSee.PMML.Definition.PMML, ByRef pClusterNames) As %Status
{
	set tSC = $$$OK
	try {
		set pPMML = ##class(%DeepSee.PMML.Definition.PMML).%Create("4.1",,$classname())
		
		set tModel = ##class(%DeepSee.PMML.Definition.Models.ClusteringModel).%New()
		set tModel.modelName = $piece($classname(),".",*)
		set tModel.functionName = "classification"
		set tModel.modelClass = "centerBased"
		set tModel.numberOfClusters = ..GetNumberOfClusters()
		set tModel.MiningSchema = ##class(%DeepSee.PMML.Definition.MiningSchema).%New()
		set tModel.ComparisonMeasure = ##class(%DeepSee.PMML.Definition.Models.Clustering.ComparisonMeasure).%New()
		set tModel.ComparisonMeasure.Metric = $classmethod("%DeepSee.PMML.Definition.Models.Clustering."_$case(..P, 1:"cityBlock", 2:"euclidean", 100:"chebychev"), "%New")
		set tModel.ComparisonMeasure.kind = "distance"
		do pPMML.Models.Insert(tModel)
		
		// generate data dictionary
		for i = 1:1:..GetDimensions() {
			set tDataField = ##class(%DeepSee.PMML.Definition.DataField).%New()
			set (tDataField.name,tFieldNames(i)) = $g($$$DimName(i),"T"_$translate($justify(i,3)," ",0))
			set tDataField.optype = "continuous"
			set tDataField.dataType = "double"
			do pPMML.DataDictionary.DataFields.Insert(tDataField)
			
			set tMiningField = ##class(%DeepSee.PMML.Definition.MiningField).%New()
			set tMiningField.name = tFieldNames(i)
			do tModel.MiningSchema.MiningFields.Insert(tMiningField)
			
			set tClusterField = ##class(%DeepSee.PMML.Definition.Models.Clustering.ClusteringField).%New()
			set tClusterField.field = tFieldNames(i)
			set tClusterField.compareFunction = "absDiff"
			do tModel.Fields.Insert(tClusterField)
		}
		
		//set tDataField = ##class(%DeepSee.PMML.Definition.DataField).%New()
		//set tDataField.name = 
		
		// generate output
		set tModel.Output = ##class(%DeepSee.PMML.Definition.Output).%New()
		set tOutputField = ##class(%DeepSee.PMML.Definition.OutputField).%New()
		set tOutputField.name = "ClusterID"
		set tOutputField.feature = "predictedValue"
		set tOutputField.displayName = "Cluster ID"
		do tModel.Output.OutputFields.Insert(tOutputField)
		set tOutputField = ##class(%DeepSee.PMML.Definition.OutputField).%New()
		set tOutputField.name = "ClusterName"
		set tOutputField.feature = "predictedDisplayValue"
		set tOutputField.displayName = "Cluster Name"
		do tModel.Output.OutputFields.Insert(tOutputField)
		
		// add clusters
		for i = 1:1:..GetNumberOfClusters() {
			set tCluster = ##class(%DeepSee.PMML.Definition.Models.Clustering.Cluster).%New()
			set tCluster.id = i
			set tCluster.name = $g(pClusterNames(i), "Cluster"_i)
			set tCluster.size = ..GetClusterSize(i)
			do ..GetCentroid(i, .tCoords)
			set tCoordsString = ""
			for j = 1:1:tCoords {
				set tCoordsString = tCoordsString _ $s(j=1:"", 1:" ") _ tCoords(j)
			}
			set tCluster.Coordinates = ##class(%DeepSee.PMML.Definition.Util.Array).%New()
			set tCluster.Coordinates.type = "real"
			set tCluster.Coordinates.Values = tCoordsString
			do tModel.Clusters.Insert(tCluster)
			
			set tOutputField = ##class(%DeepSee.PMML.Definition.OutputField).%New()
			set tOutputField.name = "DistanceCluster"_i
			set tOutputField.feature = "clusterAffinity"
			set tOutputField.displayName = "Distance to cluster "_i
			set tOutputField.value = i
			do tModel.Output.OutputFields.Insert(tOutputField)
		}
		
		set pPMML.DataDictionary.numberOfFields = pPMML.DataDictionary.DataFields.Count()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
