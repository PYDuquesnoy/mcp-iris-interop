/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides a way to assemble data that can be
/// conveniently passed between the web client and the server.
/// A <class>dataSet</class> object can contain 0-dimensional
/// (scalar) data, 1-dimensional (list), 2-dimensional, or
/// 3-dimensional data, as specified by its <property>dimensions</property>
/// property.
Class %ZEN.Auxiliary.dataSet Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// Number of dimensions within the dataSet.
Property dimensions As %ZEN.Datatype.integer(MAXVAL = 3, MINVAL = 0, XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Size, indexed by dimension number, of each dimension.
Property %size As %ZEN.Datatype.integer(MINVAL = 1, XMLPROJECTION = "NONE") [ MultiDimensional, Private ];

/// Array of data values within the dataSet.
Property %data As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ MultiDimensional, Private ];

/// Set of captions used as labels along the various
/// dimensions of the dataSet.<br>
/// The array of labels is indexed by dimension number and position
/// within the dimension.
Property %labels As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ MultiDimensional, Private ];

/// Array of serialized data values going to and coming from the client.
Property clientData As %ZEN.Datatype.list(XMLPROJECTION = "NONE", ZENSETTING = 0);

/// Array of serialized label values going to and coming from the client.
Property clientLabels As %ZEN.Datatype.list(XMLPROJECTION = "NONE", ZENSETTING = 0);

/// Array of serialized dimension size values going to and coming from the client.
Property clientSize As %ZEN.Datatype.list(XMLPROJECTION = "NONE", ZENSETTING = 0);

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..dimensions = +$G(initvalue)
	Quit $$$OK
}

/// Set the number of dimensions within the dataSet.
/// Changing the number of dimensions deletes the contents of the
/// dataSet.
Method %SetDimensions(dims As %Integer)
{
	Quit:(dims<0)||(dims>3)
	Do:dims'=..dimensions ..%Clear()
	Set ..dimensions = dims
}

/// Get the number of dimensions within the dataSet.
Method %GetDimensions() As %Integer [ CodeMode = expression ]
{
..dimensions
}

/// Delete data currently in the dataSet.
Method %Clear()
{
	Kill ..%data,..%size,..%labels
}

/// Get the value of a label at position <var>n</var> 
/// in dimension <var>dim</var> within the dataSet.
Method %GetLabel(n As %Integer = 1, dim As %Integer = 1) As %String [ CodeMode = expression ]
{
$G(..%labels(dim,n))
}

/// Return current size of a dimension.
Method %GetDimSize(dim As %Integer = 1) As %Integer [ CodeMode = expression ]
{
+$G(..%size(dim),1)
}

/// Set the value of a label at position <var>n</var> 
/// in dimension <var>dim</var> within the dataSet.
Method %SetLabel(pLabel As %String, n As %Integer = 1, dim As %Integer = 1)
{
	#; adjust size, if needed
	Set:n>+$G(..%size(dim)) ..%size(dim)=n

	Set ..%labels(dim,n) = pLabel
	
	#; force client change
	Do ..%ForceClientRender()
}

/// Get the value of a cell within the dataSet.
Method %GetValue(d1 As %Integer = 1, d2 As %Integer = 1, d3 As %Integer = 1) As %String [ CodeMode = expression ]
{
$Case(..dimensions,0:$G(..%data),1:$G(..%data(d1)),2:$G(..%data(d1,d2)),3:$G(..%data(d1,d2,d3)))
}

/// Set the value of a cell within the dataSet.
/// Updates dimension size as needed.
Method %SetValue(pValue As %String, d1 As %Integer = 1, d2 As %Integer = 1, d3 As %Integer = 1)
{
	#; force client change
	Do ..%ForceClientRender()

	Goto $Case(..dimensions,0:Dim0,1:Dim1,2:Dim2,3:Dim3)
	Quit
Dim0 Set ..%data=pValue
	Quit
Dim1 Set ..%data(d1)=pValue Set:d1>+$G(..%size(1)) ..%size(1)=d1
	Quit
Dim2 Set ..%data(d1,d2)=pValue Set:d1>+$G(..%size(1)) ..%size(1)=d1 Set:d2>+$G(..%size(2)) ..%size(2)=d2
	Quit
Dim3 Set ..%data(d1,d2,d3)=pValue Set:d1>+$G(..%size(1)) ..%size(1)=d1 Set:d2>+$G(..%size(2)) ..%size(2)=d2 Set:d3>+$G(..%size(3)) ..%size(3)=d3
	Quit
}

/// Copy the contents of this dataSet into a local
/// array.
Method %GetArray(Output pArray)
{
	Kill pArray
	Merge pArray = ..%data
}

/// Set the contents of this dataSet from a local
/// array. The local array must have the same dimensionality
/// as the dataSet and must have the correct number and
/// type of subscripts.<br>
/// The caller is also responsible for supplying the sizes of
/// each dimension.
Method %SetArray(ByRef pArray, s1 As %Integer = 1, s2 As %Integer = 1, s3 As %Integer = 1)
{
	Kill ..%data,..%size
	Merge ..%data = pArray

	#; reset the sizes of the dimensions
	Set:..dimensions>=1 ..%size(1) = s1
	Set:..dimensions>=2 ..%size(2) = s2
	Set:..dimensions>=3 ..%size(3) = s3

	#; force client change
	Do ..%ForceClientRender()
}

/// Print out contents of this dataSet to the current device.
Method %Print()
{
	Goto $Case(..dimensions,0:Dim0,1:Dim1,2:Dim2,3:Dim3)
	Quit
Dim0
	Write ..%GetValue(),!
	Quit
Dim1
	For d1 = 1:1:+$G(..%size(1),1) {
		Write d1,?5,..%GetValue(d1),!
	}
	Quit
Dim2
	For d1 = 1:1:+$G(..%size(1),1) {
		Write d1,?5
		For d2 = 1:1:+$G(..%size(2),1) {
			Write $S(d2=1:"",1:","),..%GetValue(d1,d2)
		}
		Write !
	}
	Quit
Dim3
	For d3 = 1:1:+$G(..%size(3),1) {
		Write d3,?5,"-------------------",!
		For d1 = 1:1:+$G(..%size(1),1) {
			Write d1,?5
			For d2 = 1:1:+$G(..%size(2),1) {
				Write $S(d2=1:"",1:","),..%GetValue(d1,d2,d3)
			}
			Write !
		}
	}
	Quit
}

/// Make sure client data is prepared.
Method %OnObjectSynch() As %Status
{
	Quit ..%SerializeData()
}

/// Deserialize additional values from the client.
Method %OnZENDeserialize() As %Status
{
	#; convert client properties to server representation
	#; size
	For n=1:1:$L(..clientSize,$C(5)) {
		Set ..%size(n) = +$P(..clientSize,$C(5),n)
	}
	#; labels
	Set p = 1
	For dim = 1:1:..dimensions {
		For n = 1:1:+$G(..%size(dim),1) {
			Set ..%labels(dim,n) = $P(..clientLabels,$C(5),p)
			Set p=p+1
		}
	}

	#; data
	Goto $Case(..dimensions,0:Dim0,1:Dim1,2:Dim2,3:Dim3)
	Goto Done
Dim0
	Set ..%data = ..clientData
	Goto Done
Dim1
	For d1 = 1:1:+$G(..%size(1),1) {
		Set ..%data(d1) = $P(..clientData,$C(5),d1)
	}
	Goto Done
Dim2
	Set p = 1
	For d2 = 1:1:+$G(..%size(2),1) {
		For d1 = 1:1:+$G(..%size(1),1) {
			Set ..%data(d1,d2) = $P(..clientData,$C(5),p)
			Set p = p + 1
		}
	}
	Goto Done
Dim3
	Set p = 1
	For d3 = 1:1:+$G(..%size(3),1) {
		For d2 = 1:1:+$G(..%size(2),1) {
			For d1 = 1:1:+$G(..%size(1),1) {
				Set ..%data(d1,d2,d3) = $P(..clientData,$C(5),p)
				Set p = p + 1
			}
		}
	}
	Goto Done
Done
	Quit $$$OK
}

/// Called just before we serve property values to the client.
Method %OnDrawObjectProperties() As %Status
{
	#; convert data to serialized array for client
	Quit ..%SerializeData()
}

/// Convert internal arrays to a serialized strings for use on the client.
Method %SerializeData(pDelim As %String = {$C(5)}) As %Status
{
	Set tSC = $$$OK
	Set tData = ""
	Set tLabels = ""
	For dim = 1:1:..dimensions {
		For n = 1:1:+$G(..%size(dim),1) {
			Set tLabels = tLabels_$S((n*dim)=1:"",1:pDelim)_..%GetLabel(n,dim)
		}
	}

	Goto $Case(..dimensions,0:Dim0,1:Dim1,2:Dim2,3:Dim3)
	Quit tSC
Dim0
	Set ..clientData = ..%GetValue()
	Set ..clientLabels = ..%GetLabel()
	Set ..clientSize = ""
	Quit tSC
Dim1
	For d1 = 1:1:+$G(..%size(1),1) {
		Set tData = tData_$S(d1=1:"",1:pDelim)_..%GetValue(d1)
	}
	Set ..clientData = tData
	Set ..clientLabels = tLabels
	Set ..clientSize = +$G(..%size(1),1)
	Quit tSC
Dim2
	For d2 = 1:1:+$G(..%size(2),1) {
		For d1 = 1:1:+$G(..%size(1),1) {
			Set tData = tData_$S((d2*d1)=1:"",1:pDelim)_..%GetValue(d1,d2)
		}
	}
	Set ..clientData = tData
	Set ..clientLabels = tLabels
	Set ..clientSize = +$G(..%size(1),1) _ pDelim _ +$G(..%size(2),1)
	Quit tSC
Dim3
	For d3 = 1:1:+$G(..%size(3),1) {
		For d2 = 1:1:+$G(..%size(2),1) {
			For d1 = 1:1:+$G(..%size(1),1) {
				Set tData = tData_$S((d3*d2*d1)=1:"",1:pDelim)_..%GetValue(d1,d2,d3)
			}
		}
	}
	Set ..clientData = tData
	Set ..clientLabels = tLabels
	Set ..clientSize = +$G(..%size(1),1) _ pDelim _ +$G(..%size(2),1) _ pDelim _ +$G(..%size(3),1)
	Quit tSC
}

/// Clear contents of this dataSet.
ClientMethod clear() [ Language = javascript ]
{
	var cells;
	switch (this.dimensions) {
	case 0:
		cells = 1;
		break;
	case 1:
		cells = parseInt(this.clientSize[0],10);
		break;
	case 2:
		cells = parseInt(this.clientSize[1],10) * parseInt(this.clientSize[0],10);
		break;
	case 3:
		cells = parseInt(this.clientSize[2],10) * parseInt(this.clientSize[1],10) * parseInt(this.clientSize[0],10);
		break;
	}

	for (var n = 0; n < this.clientData.length; n++) {
		this.clientData[n] = '';
	}
}

/// Update size of dataSet to new dimensions and size.
ClientMethod redim(dims, sz1, sz2, sz3) [ Language = javascript ]
{
	zenASSERT(dims>=0&&dims<=3,'dims is out of range',arguments);
	sz1 = (null==sz1 || parseInt(sz1,10) < 1) ? 1 : parseInt(sz1,10);
	sz2 = (null==sz2 || parseInt(sz2,10) < 1) ? 1 : parseInt(sz2,10);
	sz3 = (null==sz3 || parseInt(sz3,10) < 1) ? 1 : parseInt(sz3,10);

	var newData = new Array();
	var newSize = new Array();
	var newLabels = new Array();
	
	// copy old data into new array
	switch (dims) {
	case 0:
		newData[0] = this.getData(1,1,1);
		break;
	case 1:
		for (var d1=0; d1<sz1; d1++) {
			newData[d1] = this.getData(d1);
		}
		newSize[0] = sz1;
		break;
	case 2:
		for (var d2=0; d2<sz2; d2++) {
			for (var d1=0; d1<sz1; d1++) {
				newData[(d2*sz1)+d1] = this.getData(d1,d2);
			}
		}
		newSize[0] = sz1;
		newSize[1] = sz2;
		break;
	case 3:
		for (var d3=0; d3<sz3; d3++) {
			for (var d2=0; d2<sz2; d2++) {
				for (var d1=0; d1<sz1; d1++) {
					newData[(d3*sz2*sz1)+(d2*sz1)+d1] = this.getData(d1,d2,d3);
				}
			}
		}
		newSize[0] = sz1;
		newSize[1] = sz2;
		newSize[2] = sz3;
		break;
	}

	// copy labels
	var lbl = 0;
	if (dims > 0) {
		for (var n=0; n<sz1; n++) {
			newLabels[lbl++] = this.getLabel(n,1);
		}
	}
	if (dims > 1) {
		for (var n=0; n<sz2; n++) {
			newLabels[lbl++] = this.getLabel(n,2);
		}
	}
	if (dims > 2) {
		for (var n=0; n<sz3; n++) {
			newLabels[lbl++] = this.getLabel(n,3);
		}
	}

	// use new values
	this.dimensions = dims;
	this.clientData = newData;
	this.clientSize = newSize;
	this.clientLabels = newLabels;
}

/// Swap the contents of 2 "slices" of the dataSet within
/// the specified dimension.<br>
/// For example, swap the contents of 2 rows within a 2D dataSet.
/// If <var>labels</var> is true, then swap labels as well.
ClientMethod swap(dim, item1, item2, labels) [ Language = javascript ]
{
	zenASSERT(dim>=1&&dim<=this.dimensions,'dim must be between 1 and the current number of dimensions',arguments);
	var temp;

	// test for out-of-range request	
	if (item1 < 0 || item2 < 0 || 
		item1 >= this.getDimSize(dim) || item2 >= this.getDimSize(dim)) {
		return;
	}

	switch (this.dimensions) {
	case 1:
		temp = this.getData(item1);
		this.setData(this.getData(item2),item1);
		this.setData(temp,item2);
		if (labels) {
			temp = this.getLabel(item1,dim);
			this.setLabel(this.getLabel(item2,dim),item1);
			this.setLabel(temp,item2,dim);
		}
		break;
	case 2:
		// loop according to value of dim
		switch (dim) {
		case 1:
			var size = this.getDimSize(2);
			for (var n = 0; n < size; n++) {
				temp = this.getData(item1,n);
				this.setData(this.getData(item2,n),item1,n);
				this.setData(temp,item2,n);
			}
			break;
		case 2:
			var size = this.getDimSize(1);
			for (var n = 0; n < size; n++) {
				temp = this.getData(n,item1);
				this.setData(this.getData(n,item2),n,item1);
				this.setData(temp,n,item2);
			}
			break;
		}
		if (labels) {
			temp = this.getLabel(item1,dim);
			this.setLabel(this.getLabel(item2,dim),item1,dim);
			this.setLabel(temp,item2,dim);
		}

		break;
	case 3:
		// loop according to value of dim
		switch (dim) {
		case 1:
			var pages = this.getDimSize(3);
			var size = this.getDimSize(2);
			for (var pg = 0; pg < pages; pg++) {
				for (var n = 0; n < size; n++) {
					temp = this.getData(item1,n,pg);
					this.setData(this.getData(item2,n,pg),item1,n,pg);
					this.setData(temp,item2,n,pg);
				}
			}
			break;
		case 2:
			var pages = this.getDimSize(3);
			var size = this.getDimSize(1);
			for (var pg = 0; pg < pages; pg++) {
				for (var n = 0; n < size; n++) {
					temp = this.getData(n,item1,pg);
					this.setData(this.getData(n,item2,pg),n,item1,pg);
					this.setData(temp,n,item2,pg);
				}
			}
			break;
		case 3:
			var pages = this.getDimSize(2);
			var size = this.getDimSize(1);
			for (var pg = 0; pg < pages; pg++) {
				for (var n = 0; n < size; n++) {
					temp = this.getData(n,pg,item1);
					this.setData(this.getData(n,pg,item2),n,pg,item1);
					this.setData(temp,n,pg,item2);
				}
			}
			break;
		}
		if (labels) {
			temp = this.getLabel(item1,dim);
			this.setLabel(this.getLabel(item2,dim),item1,dim);
			this.setLabel(temp,item2,dim);
		}
		break;
	}
}

/// Insert a new "slice" into the dataSet within
/// the specified dimension just before item <var>index</var> (0-based).<br/>
/// If <var>index</var> is -1, then insert at the end.
ClientMethod insert(dim, index) [ Language = javascript ]
{
	zenASSERT(dim>=1&&dim<=this.dimensions,'dim must be between 1 and the current number of dimensions',arguments);
	var temp;

	// test for out-of-range request	
	if (index >= this.getDimSize(dim)) {
		return;
	}

	// add new slice
	// slide over data
	switch (dim) {
	case 1:
		this.redim(this.getDimensions(),this.getDimSize(1)+1,this.getDimSize(2),this.getDimSize(3));
		break;
	case 2:
		this.redim(this.getDimensions(),this.getDimSize(1),this.getDimSize(2)+1,this.getDimSize(3));
		break;
	case 3:
		this.redim(this.getDimensions(),this.getDimSize(1),this.getDimSize(2),this.getDimSize(3)+1);
		break;
	}

	if (index<0) {
		return;
	}

	// slide over labels
	for (var n = this.getDimSize(dim)-1; n > index; n--) {
		this.setLabel(this.getLabel(n-1,dim),n,dim);
	}
	this.setLabel('',index,dim);

	// slide over data
	switch (this.dimensions) {
	case 1:
		for (var n = this.getDimSize(1)-1; n > index; n--) {
			this.setData(this.getData(n-1),n);
		}
		break;
	case 2:
		// loop according to value of dim
		switch (dim) {
		case 1:
			var size = this.getDimSize(2);
			for (var k = 0; k < size; k++) {
				for (var n = this.getDimSize(1)-1; n > index; n--) {
					this.setData(this.getData(n-1,k),n,k);
				}
				this.setData('',index,k);
			}
			break;
		case 2:
			var size = this.getDimSize(1);
			for (var k = 0; k < size; k++) {
				for (var n = this.getDimSize(2)-1; n > index; n--) {
					this.setData(this.getData(k,n-1),k,n);
				}
				this.setData('',k,index);
			}
			break;
		}
		break;
	case 3:
		// loop according to value of dim
		switch (dim) {
		case 1:
			var pages = this.getDimSize(3);
			var size = this.getDimSize(2);
			for (var pg = 0; pg < pages; pg++) {
				for (var k = 0; k < size; k++) {
					for (var n = this.getDimSize(1)-1; n > index; n--) {
						this.setData(this.getData(n-1,k,pg),n,k,pg);
					}
					this.setData('',index,k,pg);
				}
			}
			break;
		case 2:
			var pages = this.getDimSize(3);
			var size = this.getDimSize(1);
			for (var pg = 0; pg < pages; pg++) {
				for (var k = 0; k < size; k++) {
					for (var n = this.getDimSize(2)-1; n > index; n--) {
						this.setData(this.getData(k,n-1,pg),k,n,pg);
					}
					this.setData('',k,index,pg);
				}
			}
			break;
		case 3:
			var pages = this.getDimSize(2);
			var size = this.getDimSize(1);
			for (var pg = 0; pg < pages; pg++) {
				for (var k = 0; k < size; k++) {
					for (var n = this.getDimSize(3)-1; n > index; n--) {
						this.setData(this.getData(k,pg,n-1),k,pg,n);
					}
					this.setData('',k,pg,index);
				}
			}
			break;
		}
		break;
	}
}

/// Remove a "slice" from the dataSet within
/// the specified dimension at position <var>index</var> (0-based).<br/>
ClientMethod remove(dim, index) [ Language = javascript ]
{
	zenASSERT(dim>=1&&dim<=this.dimensions,'dim must be between 1 and the current number of dimensions',arguments);
	var temp;

	// test for out-of-range request	
	if (index >= this.getDimSize(dim)) {
		return;
	}

	// slide over data
	if (index>=0) {
		// slide over labels
		for (var n = index; n < this.getDimSize(dim)-1; n++) {
			this.setLabel(this.getLabel(n+1,dim),n,dim);
		}

		// slide over data
		switch (this.dimensions) {
		case 1:
			for (var n = index; n < this.getDimSize(1)-1; n++) {
				this.setData(this.getData(n+1),n);
			}
			break;
		case 2:
			// loop according to value of dim
			switch (dim) {
			case 1:
				var size = this.getDimSize(2);
				for (var k = 0; k < size; k++) {
					for (var n = index; n < this.getDimSize(1)-1; n++) {
						this.setData(this.getData(n+1,k),n,k);
					}
				}
				break;
			case 2:
				var size = this.getDimSize(1);
				for (var k = 0; k < size; k++) {
					for (var n = index; n < this.getDimSize(2)-1; n++) {
						this.setData(this.getData(k,n+1),k,n);
					}
				}
				break;
			}
			break;
		case 3:
			// loop according to value of dim
			switch (dim) {
			case 1:
				var pages = this.getDimSize(3);
				var size = this.getDimSize(2);
				for (var pg = 0; pg < pages; pg++) {
					for (var k = 0; k < size; k++) {
						for (var n = index; n < this.getDimSize(1)-1; n++) {
							this.setData(this.getData(n+1,k,pg),n,k,pg);
						}
					}
				}
				break;
			case 2:
				var pages = this.getDimSize(3);
				var size = this.getDimSize(1);
				for (var pg = 0; pg < pages; pg++) {
					for (var k = 0; k < size; k++) {
						for (var n = index; n < this.getDimSize(2)-1; n++) {
							this.setData(this.getData(k,n+1,pg),k,n,pg);
						}
					}
				}
				break;
			case 3:
				var pages = this.getDimSize(2);
				var size = this.getDimSize(1);
				for (var pg = 0; pg < pages; pg++) {
					for (var k = 0; k < size; k++) {
						for (var n = index; n < this.getDimSize(3)-1; n++) {
							this.setData(this.getData(k,pg,n+1),k,pg,n);
						}
					}
				}
				break;
			}
			break;
		}
	}

	// remove slice at end
	if (this.getDimSize(dim)>0) {
		switch (dim) {
		case 1:
			this.redim(this.getDimensions(),this.getDimSize(1)-1,this.getDimSize(2),this.getDimSize(3));
			break;
		case 2:
			this.redim(this.getDimensions(),this.getDimSize(1),this.getDimSize(2)-1,this.getDimSize(3));
			break;
		case 3:
			this.redim(this.getDimensions(),this.getDimSize(1),this.getDimSize(2),this.getDimSize(3)-1);
			break;
		}
	}
}

/// Return the number of dimensions in the dataSet.
ClientMethod getDimensions() [ Language = javascript ]
{
	return this.dimensions;
}

/// Return the number of items in the specified dimension
/// (dim is 1,2, or 3).
ClientMethod getDimSize(dim) [ Language = javascript ]
{
	zenASSERT(dim>=1&&dim<=3,'dim must be between 1 and 3',arguments);
	var sz = (null==this.clientSize[dim-1]) ? 1 : parseInt(this.clientSize[dim-1],10);
	return (null == sz) ? 1 : sz;
}

/// Get the label at position n (0-based) in the given
/// dimension (1,2, or 3).
ClientMethod getLabel(n, dim) [ Language = javascript ]
{
	var label = '';
	
	switch(dim) {
	case 0:
		label = this.clientLabels[0];
		break;
	case 1:
		var sz1 = parseInt(this.clientSize[0],10);
		label = (n<0||n>=sz1)?'':this.clientLabels[n];
		break;
	case 2:
		var sz1 = parseInt(this.clientSize[0],10);
		var sz2 = parseInt(this.clientSize[1],10);
		label = (n<0||n>=sz2)?'':this.clientLabels[sz1+n];
		break;
	case 3:
		var sz1 = parseInt(this.clientSize[0],10);
		var sz2 = parseInt(this.clientSize[1],10);
		var sz3 = parseInt(this.clientSize[2],10);
		label = (n<0||n>=sz3)?'':this.clientLabels[sz2+sz1+n];
		break;
	}

	return (null == label) ? '' : label;
}

/// Return the data contained in the specified location.
/// Location is 0-based;
ClientMethod getData(d1, d2, d3) [ Language = javascript ]
{
	var data = '';

	switch(this.dimensions) {
	case 0:
		data = this.clientData[0];
		break;
	case 1:
		var sz1 = parseInt(this.clientSize[0],10);
		data = (d1<0||d1>=sz1||d2>0||d3>0)?'':this.clientData[d1];
		break;
	case 2:
		var sz1 = parseInt(this.clientSize[0],10);
		var sz2 = parseInt(this.clientSize[1],10);
		data = (d1<0||d1>=sz1||d2<0||d2>=sz2||d3>0)?'':this.clientData[(d2*sz1)+d1];
		break;
	case 3:
		var sz1 = parseInt(this.clientSize[0],10);
		var sz2 = parseInt(this.clientSize[1],10);
		var sz3 = parseInt(this.clientSize[2],10);
		data = (d1<0||d1>=sz1||d2<0||d2>=sz2||d3<0||d3>=sz3)?'':this.clientData[(d3*sz2*sz1)+(d2*sz1)+d1];
		break;
	}

	return (null == data) ? '' : data;
}

/// Set the value of the label at position n (0-based) in the given
/// dimension (1,2, or 3).
ClientMethod setLabel(label, n, dim) [ Language = javascript ]
{
	var sz1 = parseInt(this.clientSize[0],10);
	var sz2 = parseInt(this.clientSize[1],10);
	var sz3 = parseInt(this.clientSize[2],10);

	switch(dim) {
	case 0:
		this.clientLabels[0] = label;
		break;
	case 1:
		if (n>=0&&n<sz1) {
			this.clientLabels[n] = label;
		}
		break;
	case 2:
		if (n>=0&&n<sz2) {
			this.clientLabels[sz1+n] = label;
		}
		break;
	case 3:
		if (n>=0&&n<sz3) {
			this.clientLabels[sz2+sz1+n] = label;
		}
		break;
	}

	return (null == label) ? '' : label;
}

/// Set the data contained in the specified location.
/// Location is 0-based;
ClientMethod setData(value, d1, d2, d3) [ Language = javascript ]
{
	var sz1 = parseInt(this.clientSize[0],10);
	var sz2 = parseInt(this.clientSize[1],10);
	var sz3 = parseInt(this.clientSize[2],10);

	switch(this.dimensions) {
	case 0:
		this.clientData[0] = value;
		break;
	case 1:
		if (d1>=0 && d1 < sz1) {
			this.clientData[d1] = value;
		}
		break;
	case 2:
		if (d1>=0 && d1 < sz1 && d2>=0 && d2 < sz2) {
			this.clientData[(d2*sz1)+d1] = value;
		}
		break;
	case 3:
		if (d1>=0 && d1 < sz1 && d2>=0 && d2 < sz2 && d3>=0 && d3 < sz3) {
			this.clientData[(d3*sz2*sz1)+(d2*sz1)+d1] = value;
		}
		break;
	}
}

}
