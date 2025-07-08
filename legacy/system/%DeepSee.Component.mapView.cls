/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized Zen component that displays a google map.<br/>
/// Use the height and width attributes to control the size of the map container.
Class %DeepSee.Component.mapView Extends (%ZEN.Component.component, %ZEN.Component.dataView) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

Parameter INCLUDEFILES As COSEXPRESSION = """script:https://maps.googleapis.com/maps/api/js?""_..%GetUrlAPIKey()";

/// Initial latitude (as a decimal number).
Property latitude As %ZEN.Datatype.float [ InitialExpression = 42.36 ];

/// Initial longitude (as a decimal number).
Property longitude As %ZEN.Datatype.float [ InitialExpression = 288.92 ];

/// Initial zoom level (0 shows entire globe).
Property zoom As %ZEN.Datatype.integer [ InitialExpression = 12 ];

/// Initial map display.
Property mapType As %ZEN.Datatype.string(VALUELIST = ",ROADMAP,SATELLITE,HYBRID,TERRAIN") [ InitialExpression = "ROADMAP" ];

/// If true, then the markers on this map are draggable.
Property markersDraggable As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Name of property in data source that provides the latitude value for a marker.
Property latitudeProperty As %ZEN.Datatype.string [ InitialExpression = "Latitude" ];

/// Name of property in data source that provides the longitude value for a marker.
Property longitudeProperty As %ZEN.Datatype.string [ InitialExpression = "Longitude" ];

/// Optional. Flag used by DeepSee widget to indicate that this map is only used for geolistings.
Property isListing As %ZEN.Datatype.boolean [ InitialExpression = 0, Internal ];

/// onclickmarker event handler:
/// If defined, this event is fired when
/// the user clicks on a marker within the map.
Property onclickmarker As %ZEN.Datatype.eventHandler;

/// Define a set of property value to be displayed within the default "info box"
/// when the user clicks on a map marker.
/// This only uses a relevant subset of the properties in the scoreCardColumn class.
/// Currently only the <var>label</var>, <var>dataValue</var>, <var>style</var>,
/// <var>format</var>, and <var>align</var> properties are used.
Property infoProperties As list Of %DeepSee.Component.SVG.scoreCardColumn(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Client-side method to render control.
ClientMethod renderContents() [ Language = javascript ]
{
	this._mapObject = null;
	var mapDiv = this.getEnclosingDiv();

	// test if we have not been rendered yet
	if (mapDiv == null) return;

	// make sure our div has some area
	var width = isNaN(parseFloat(this.width)) ? 200 : parseFloat(this.width);
	var height = isNaN(parseFloat(this.height)) ? 200 : parseFloat(this.height);
	if ('' == this.enclosingStyle) {
		mapDiv.style.width = width + 'px';
		mapDiv.style.height = height + 'px';
	}

	// get data from controller, if present.
	this.acquireData();

	// create map
	this.initMap(mapDiv);

	// add markers 
	this.syncMarkers();
}

/// Initialize the map
ClientMethod initMap(mapDiv) [ Language = javascript ]
{
	if (('undefined' == typeof google)||('undefined' == typeof google.maps)) {
		mapDiv.innerHTML = $$$Text('Unable to load google map api.');
		return;
	}

	var mapTypeId = this.getMapTypeId(this.mapType);
	var mapLatlng = new google.maps.LatLng(parseFloat(this.latitude), parseFloat(this.longitude));
	
	var mapOptions = {
		zoom: parseInt(this.zoom,10),
		center: mapLatlng,
		mapTypeId: mapTypeId
	}
	var map = new google.maps.Map(mapDiv, mapOptions);
	this._mapObject = map;
	
	// array of markers
	this._markers = [];

	// add listeners
	var code = new Function('zenPage.getComponent('+this.index+').zoomChangedHandler();');
	google.maps.event.addListener(map, 'zoom_changed', code);

	var code = new Function('zenPage.getComponent('+this.index+').dragendHandler();');
	google.maps.event.addListener(map, 'dragend', code);
}

/// Callback for zoom-changed event.
ClientMethod zoomChangedHandler() [ Internal, Language = javascript ]
{
	var map = this.getMapObject();
	if (map) {
		this.zoom = map.getZoom();
	}
}

/// Callback for map dragend event.
ClientMethod dragendHandler() [ Internal, Language = javascript ]
{
	var map = this.getMapObject();
	if (map) {
		var latLng = map.getCenter();
		this.latitude = latLng.lat();
		this.longitude = latLng.lng();
	}
}

/// Return the google map API object used by the map view.
ClientMethod getMapObject() [ Language = javascript ]
{
	return this._mapObject;
}

/// Given the name of a map type, convert to a map type id.
ClientMethod getMapTypeId(type) [ Language = javascript ]
{
	if (('undefined' == typeof google)||('undefined' == typeof google.maps)) {
		return '';
	}

	var mapType = google.maps.MapTypeId.ROADMAP;
	switch (type) {
	case 'HYBRID':
		mapType = google.maps.MapTypeId.HYBRID;
		break;
	case 'SATELLITE':
		mapType = google.maps.MapTypeId.SATELLITE;
		break;
	case 'TERRAIN':
		mapType = google.maps.MapTypeId.TERRAIN;
		break;
	case 'ROADMAP':
	default:
		break;
	}

	return mapType;
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var mapDiv = this.getEnclosingDiv();
	width = width > 10 ? width : 0;
	mapDiv.style.width = width-10 + 'px';
	mapDiv.style.height = height + 'px';

	var map = this.getMapObject();
	if (map) {
		// JMD1367: preserve center
		var center = map.getCenter();
		google.maps.event.trigger(map,'resize');
		map.setCenter(center);
	}
}

/// Adjust the map to show all the current markers
ClientMethod adjustMapBounds() [ Language = javascript ]
{
	var map = this.getMapObject();
	if (map) {
		if (this._markers && this._markers.length) {
			var latlngbounds = new google.maps.LatLngBounds();
			for (var n = 0; n < this._markers.length; n++) {
				var marker = this._markers[n];
				if (marker) {
					latlngbounds.extend(marker.getPosition());
				}
			}
			map.setCenter(latlngbounds.getCenter());
			map.fitBounds(latlngbounds);
		}
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var map = this.getMapObject();

	switch(property) {
	case 'latitude':
	case 'longitude':
		this[property] = value;
		if (map) {
			var mapLatlng = new google.maps.LatLng(parseFloat(this.latitude), parseFloat(this.longitude));
			map.panTo(mapLatlng);
		}
		break;

	case 'zoom':
		this[property] = value;
		if (map) {
			map.setZoom(parseInt(this.zoom,10));
		}
		break;

	case 'markersDraggable':
		this[property] = value ? true : false;
		this.syncMarkers();
		break;

	case 'mapType':
		this[property] = value;
		if (map) {
			var mapTypeId = this.getMapTypeId(this.mapType);
			map.setMapTypeId(mapTypeId);
		}
		break;

	case 'onclickmarker':
		this[property] = value;
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Notification that the dataController associated with this dataView has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2, data3) [ Language = javascript ]
{
	switch(reason) {
	case 'dataChange':
	case 'modelChange':
		// some change in dataController

		// special check for geolisting
		var controller = this.getController();
		if (controller.listingType && controller.listingType == 'map') {
			this.showGeoMarkers();
			return;
		}
		this.acquireData();
		this.syncMarkers();
		break;
	case 'seriesChange':
		break;
	}
}

/// Return the dataSet object associated with this view.
ClientMethod getDataSet() [ Language = javascript ]
{
	var controller = this.getController();
	return (controller ? controller : this.dataSet);
}

/// Add a marker to the map at given coordinates.<br/>
/// <var>id</var> is a user-defined identifier associated with the marker.<br/>
/// Returns the marker object.
ClientMethod addMarker(id, latitude, longitude, title) [ Language = javascript ]
{
	var marker = null;
	var map = this.getMapObject();
	if (map && !isNaN(parseFloat(latitude)) && !isNaN(parseFloat(longitude))) {
		var mapLatlng = new google.maps.LatLng(parseFloat(latitude), parseFloat(longitude));
		marker = new google.maps.Marker({
			position: mapLatlng,
			map: map,
			draggable: this.markersDraggable,
			title:title.toString()});

		// add to list
		var index = this._markers.length;
		this._markers[index] = marker;
		marker._id = id;
		marker._index = index;

		// add event handler(s)
		if (this.markersDraggable) {
			var code = new Function('zenPage.getComponent('+this.index+').markerDragEndHandler("'+index+'");');
			google.maps.event.addListener(marker, 'dragend', code);
		}

		var code = new Function('zenPage.getComponent('+this.index+').markerClickHandler("'+index+'");');
		google.maps.event.addListener(marker, 'click', code);
	}
	return marker;
}

/// Find marker in marker list by index # (0-based).
ClientMethod getMarker(index) [ Internal, Language = javascript ]
{
	return this._markers ? this._markers[index] : null;
}

/// Callback for marker dragend event.
ClientMethod markerDragEndHandler(index) [ Internal, Language = javascript ]
{
	var map = this.getMapObject();
	if (map) {
		var marker = this.getMarker(index);
		if (marker) {
			this.createInfoWindow(marker,'Marker moved to:<br/>' + marker.getPosition());
		}
	}
}

/// Callback for marker click event.
ClientMethod markerClickHandler(index) [ Internal, Language = javascript ]
{
	var map = this.getMapObject();
	if (map) {
		var marker = this.getMarker(index);
		if (marker) {
			if (this.onclickmarker!='') {
				zenInvokeCallbackMethod(this.onclickmarker,this,'onclickmarker','marker',marker);
			}
			else if (this.infoProperties.length > 0) {
				// JMD950: show infoBox based on property values
				// JMD1367: use id and not index
				var content = this.getInfoPropContent(marker._id);
				if (content) {
					this.createInfoWindow(marker,content);
				}
			}
		}
	}
}

/// Create and show an info window for a given marker.
ClientMethod createInfoWindow(marker, content) [ Internal, Language = javascript ]
{
	var map = this.getMapObject();
	if (map && marker) {
		// keep track of the infoWindow and only allow one at a time
		if (this._currInfoWindow) {
			this._currInfoWindow.close();
			delete this._currInfoWindow;
		}
		var infoWindow = new google.maps.InfoWindow({content: content});
		infoWindow.open(map,marker);
		this._currInfoWindow = infoWindow;
	}
}

/// Using the infoProperties defined for this map, construct and return the
/// HTML to display the properties within an infoBox.
ClientMethod getInfoPropContent(index) [ Internal, Language = javascript ]
{
	// JMD950
	var html = [];
	var msg = '';	

	var controller = this.getController();
	if (null == controller) {
		msg = $$$Text('Not connected');
	}
	else if (controller.modelError) {
		msg = controller.modelError;
	}
	if (msg!='') {
		html[html.length] = 'Error:<br/>' + msg;
		return html.join('');
	}

	html[html.length] = '<table cellpadding="0" border="0" cellspacing="0" style="font-family:arial;font-size:12px;color:#404040;">';
	for (var n = 0; n < this.infoProperties.length; n++) {
		var info = this.infoProperties[n];

		var label = info.label;
		var value = info.dataValue ? controller.getDataByName(info.dataValue, index) : '';
		if ( (!isNaN(value)) && (!isNaN(parseFloat(value))) ) { // JSL4416 add test for value being non-numeric
			var format = (''===info.format) ? '#,#' : info.format;
			var value = zenFormatNumber(value,format);
		}

		var style = info.style ? info.style : '';
		var align = info.align ? info.align : 'right';

		html[html.length] = '<tr>';

		html[html.length] = '<th style="text-align: '+align+';padding:2px;">';
		html[html.length] = zenEscapeXML(label);
		html[html.length] = '</th>';

		html[html.length] = '<td style="text-align: right;padding:2px;'+style+'">';
		html[html.length] = zenEscapeXML(value);
		html[html.length] = '</td>';

		html[html.length] = '</tr>';
	}

	html[html.length] = '</table>';

	return html.join('');
}

/// Remove a marker from the map.
/// <var>marker</var> is the marker to remove.
ClientMethod removeMarker(marker) [ Language = javascript ]
{
	try {
		marker.setMap(null);
	}
	catch(ex) {
		// swallow google error!
	}
}

/// Internal method: acquire data for this view and store a copy in a local cache.
ClientMethod acquireData() [ Internal, Language = javascript ]
{
	var controller = this.getController();
	if (null == controller) {
		// try to connect to dataController
		this.connectToController();
		controller = this.getController();
	}

	// array of marker data
	this._markerData = [];

	if (controller && !this.isListing) {
		// get data from controller (make sure data is loaded)
		var dims = controller.getDimensions();
		
		if ((this.latitudeProperty == '')||(this.longitudeProperty == '')) {
			return;
		}

		// are we connected to a pivot table?
		var invert = controller.getSelectedRange;
		if (!invert) {
			var seriesSize = controller.getDimSize(1);
			var seriesCount = controller.getDimSize(2);
			var labelDim = 2;
			var latCol = -1;
			var longCol = -1;
			// find long and lat columns
			for (var p = 0; p < seriesSize; p++) {
				var pname = controller.getPropertyName(p);
				if (pname == this.latitudeProperty) {
					latCol = p;
				}
				if (pname == this.longitudeProperty) {
					longCol = p;
				}
			}
		}
		else {
			var seriesSize = controller.getDimSize(2);
			var seriesCount = controller.getDimSize(1);
			var labelDim = 1;
		}

		// each series corresponds to a marker
		for (var n = 0; n < seriesCount; n++) {
			var sname = controller.getLabel(n,labelDim);
			if (!invert) {
				if (latCol<0 || longCol<0) {
					break;
				}
				var lat = controller.getData(latCol,n);
				var long = controller.getData(longCol,n);
			}
			else {
				var lat = controller.getDataByName(this.latitudeProperty,n);
				var long = controller.getDataByName(this.longitudeProperty,n);
			}
			
			if (!isNaN(parseFloat(lat)) && !isNaN(parseFloat(long))) {
				this._markerData[this._markerData.length] = {
					index: n,
					title: sname,
					latitude: lat,
					longitude: long
				};
			}
		}
	}
}

/// Internal method: sync markers to data from controller.
ClientMethod syncMarkers() [ Internal, Language = javascript ]
{
	var controller = this.getController();
	if (null == controller) {
		return;
	}

	this.clearMarkers();

	if (this._markerData) {
		for (var n = 0; n < this._markerData.length; n++) {
			var md = this._markerData[n];
			if (md) {
				this.addMarker(md.index,md.latitude,md.longitude,md.title);
			}
		}
	}

	// JMD1367
	this.adjustMapBounds();
}

/// Internal method: clear markers from map.
ClientMethod clearMarkers() [ Internal, Language = javascript ]
{
	try {
		// kill old markers
		if (this._markers) {
			for (var n = 0; n < this._markers.length; n++) {
				this.removeMarker(this._markers[n]);
			}
		}
		this._markers = [];
	}
	catch(ex) {
		alert('Error in mapView.clearMarkers ' + ex.message);
	}
}

/// Invoke the google geocoder api to lookup an address string and move the map to view it.
/// Applications that call this are responsible for adhering to the google geocoder api terms of use.
ClientMethod panToAddress(address) [ Language = javascript ]
{
	if (('undefined' == typeof google)||('undefined' == typeof google.maps)) {
		return '';
	}

	var callback = new Function('results','status','zenPage.getComponent('+this.index+').geocodeAddressHandler(results,status)');
	var geocoder = new google.maps.Geocoder();
	geocoder.geocode({ 'address': address}, callback);
}

/// Callback for geocoder API.
ClientMethod geocodeAddressHandler(results, status) [ Internal, Language = javascript ]
{
	if (status == google.maps.GeocoderStatus.OK) {
		var map = this.getMapObject();
		if (map) {
			map.setCenter(results[0].geometry.location);
		}
	}
	else {
		alert("Address not found: " + status);
	}
}

/// Show set of markers for a geolisting.
ClientMethod showGeoMarkers() [ Internal, Language = javascript ]
{
	var maxPoints = 10000;
	var numPoints = 0;

	this.clearMarkers();
	var controller = this.getController();
	var data = controller.getContent();
	if (data && data.listingRows) {
		// pivot has a property called listing rows which contains the results of the listing query
		// first gather all rows in the listings and group by location
		var points = {};

		for (n = 0; n < data.listingRows.length; n++) {
			var row = data.listingRows[n];
			if ('undefined' != typeof row.Latitude && 'undefined' != typeof row.Longitude) {
				if (!isNaN(parseFloat(row.Latitude))&&!isNaN(parseFloat(row.Longitude))) {
					var addr = row.Latitude+','+row.Longitude;
					if (points[addr]) {
						points[addr][points[addr].length] = n;
					}
					else {
						points[addr] = [n];
					}
				}
			}
		}

		for (var addr in points) {
			var count = points[addr].length;
			var n = points[addr][0];
			var row = data.listingRows[n];
			this.addMarker(n,parseFloat(row.Latitude),parseFloat(row.Longitude),$$$FormatText($$$Text('%1 item(s)'),count));
			numPoints++;
			if (numPoints>maxPoints) {
				break;
			}
		}
	}
	
	// JMD1367
	this.adjustMapBounds();
}

/// Load the GoogleMaps API key stored in the namespace settings.
ClassMethod %GetUrlAPIKey() As %String [ Internal, Private ]
{
	// Method added by DTB472
	Set tMapsKey = $G(^DeepSee.UserPortalSettings("GoogleMapsKey"))
	Set tUrlKey = $Case(tMapsKey,"":"",:"key="_$zcvt(tMapsKey,"O","URL")_"&")

	Quit tUrlKey
}

}
