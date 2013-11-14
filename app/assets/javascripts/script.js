$(document).ready(function() {
    // Basic structure fo Chart.js
	var dataObj = {
		labels : [],
		datasets : []
	};
	var hardcodedColors = [
							["rgba(51,204,255,0.3)","rgba(51,102,255,1)"],
							["rgba(122,255,175,0.3)","rgba(0,255,102,1)"],
							["rgba(255,175,122,0.3)","rgba(255,102,0,1)"],
							["rgba(255,0,153,0.3)","rgba(255,122,202,1)"],
							["rgba(175,122,255,0.3)","rgba(102,0,255,1)"],
						  ];
    var r; // for release name
	// Additional crossbrowser features
	var elem = document.getElementById('begindate');
	if (elem.type === 'text') {
		$('#begindate').datepicker({dateFormat: 'yy-mm-dd'});
	}
	elem = document.getElementById('enddate');
	if (elem.type === 'text') {
		$('#enddate').datepicker({dateFormat: 'yy-mm-dd'});
	}
    
	// and here
	var date = new Date().toISOString();
	console.log(date);
	console.log(date.substring(0, 10));
	
	var enddate = document.getElementById('enddate');
	if (enddate.type === 'text') {
		$('#enddate').datepicker("setDate",date.substring(0, 10));
	} else {
		enddate.valueAsDate = new Date();
	}
    
	// and here
	var bdate = document.getElementById('begindate');
	var beginDate = new Date();
	beginDate = new Date(beginDate.getTime() - (30 * 24 * 60 * 60 * 1000));

	if (bdate.type === 'text') {
		beginDate = beginDate.toISOString();
		beginDate.substring(0, 10);
		$('#begindate').datepicker("setDate",beginDate.substring(0, 10));
	} else {
		bdate.valueAsDate = beginDate;
	}
	
	$('#chartgetter').click(function() {
		// Parsing answer for chart data query
		// and even here...
        dataObj = {
            labels : [],
            datasets : []
        };
        var queryString = "";
		if ((enddate.type === 'text') || (bdate.type === 'text')) {
			var beg = $('#begindate').datepicker("getDate").toISOString().substring(0, 10);
			var end = $('#enddate').datepicker("getDate").toISOString().substring(0, 10);
			queryString = 'testjson/sendjson?begindate='+beg+'&enddate='+end+'&testname='+$('#testname').val();
		} else {
			queryString = 'testjson/sendjson?begindate='+$('#begindate').val()+'&enddate='+$('#enddate').val()+'&testname='+$('#testname').val();
		}
		$.getJSON(queryString, function(json) {    
			console.log(json);
            console.log("Building chart");
			// Filling structure from JSON
			console.log("Filling structure");
			$('#releases').empty();
			dataObj.labels = json.labels;
			for (var i = 0; i < json.datasets.length; i++) {
				var ds = {
						fillColor : "",
						strokeColor : "",
						pointColor : "",
						pointStrokeColor : "",
						data : []
				};
				dataObj.datasets.push(ds);
				if (hardcodedColors[i] !== undefined) {
					dataObj.datasets[i].fillColor = hardcodedColors[i][0];
					dataObj.datasets[i].strokeColor = hardcodedColors[i][1];
					dataObj.datasets[i].pointColor = dataObj.datasets[i].strokeColor;
				} else {
					dataObj.datasets[i].fillColor = "rgba("+Math.floor(Math.random()*(255-0)+0)+","+Math.floor(Math.random()*(255-0)+0)+","+Math.floor(Math.random()*(255-0)+0)+",0.3)";
					dataObj.datasets[i].strokeColor = "rgba("+Math.floor(Math.random()*(255-0)+0)+","+Math.floor(Math.random()*(255-0)+0)+","+Math.floor(Math.random()*(255-0)+0)+",1)";
					dataObj.datasets[i].pointColor = dataObj.datasets[i].strokeColor;
				}
				dataObj.datasets[i].pointStrokeColor = "#fff";
				dataObj.datasets[i].data = json.datasets[i].data;
				r = json.datasets[i].releaseName;
				$('#releases').append('<div id="'+r+'"><input type="checkbox" checked="checked" id="'+i+'" />'+r+'</div>');
				$('#'+r).css('display','inline-block');
				$('#'+r).css('background-color',dataObj.datasets[i].strokeColor);
			}
			console.log(dataObj);
			drawPlot(dataObj);
		});
	});

	$('#drawCharts').click(function(){
		var chartsForDraw = {
			labels : [],
			datasets : []
		};
		$('input[type=checkbox]').each(function(){
			if ($(this).is(':checked')) {
				chartsForDraw.labels = dataObj.labels;
				chartsForDraw.datasets.push(dataObj.datasets[Number($(this).attr("id"))]);
			}
		});
		console.log(chartsForDraw);
		drawPlot(chartsForDraw);
	});

/* For future use
    $('#tablegetter').click(function() {
		// Parsing answer for table data query
		$.getJSON('table.json', function(json) {
			console.log("Building table");
			// Filling table from JSON
			$.each(json.dataArray, function(i, obj) {
				$('.tb').append('<tr>' +
				'<td class="date">' + obj['date'] + '</td>' +
				'<td>' + obj['billingtime'] + '</td>' +
				'<td>' + obj['actprtime'] + '</td>' +
				'<td>' + obj['sfprinttime'] + '</td>' +
				'<td>' + obj['psformtime'] + '</td>' +
				'<td>' + obj['usruptime'] + '</td>' +
				'<td>' + obj['regtime'] + '</td>' +
				'<td>' + obj['usrreptime'] + '</td>' +
				'<td>' + obj['etc'] + '</td>' +
				'<td>' + obj['etc2'] + '</td>' + '</tr>');
			});
		});
	});*/

	var loadTestNames = function() {
		$.getJSON('testjson/gettestlist', function(json) {
			{
				console.log("Building test list");
				console.log(json)
				$('#testname').empty();
				// Filling table from JSON
				$.each(json.data, function(key,obj) {
					$('#testname').append('<option value="' +
					obj.value + '">' + obj.label + '</option>');
				});
			}
		});
	};
	loadTestNames();
    
    var clicks = 0;
    
    $('body').on('keyup',function (e) {
        if (e.keyCode === 67) {
            clicks===0?clicks++:clicks=0;
            easterEgg();
        }
        if (e.keyCode === 65) {
            clicks===1?clicks++:clicks=1;
            easterEgg();
        }
        if (e.keyCode === 84) {
            clicks===2?clicks++:clicks=2;
            easterEgg();
        }
    });

    function easterEgg() {
        if (clicks === 3) {
            var image = document.createElement('img');
            image.src = 'assets/cat_clean.png';
            image.onload = function () {
                var topMar = new Number(Math.floor(document.height / 2) - image.height);
                var leftMar = new Number(Math.floor(document.width / 2) - image.width);
                var welcomeText = document.createTextNode('Do not disturb a Cat!');
                $('#welcomeDiv')
                .empty()
                .css({
                    'font': '50pt bold',
                    'color': '#EEE',
                    'top': topMar + 'px',
                    'left': leftMar + 'px'
                }).append(image)
                .append('<br />')
                .append(welcomeText);
                
                $('#easterEgg')
                .css({
                    'position': 'absolute',
                    'z-index': '999',
                    'background-color': '#666',
                    'top': '0px',
                    'left': '0px',
                    'width': '100%',
                    'height': '100%'
                })
                .show('slow')
                .on('click',function () { $('#easterEgg').hide('slow');});
            };
        clicks = 0;
        }
    }
});


// Flexible chart construction
function drawPlot(aDataValues) {
	var ctx = document.getElementById('mainchart').getContext('2d');
	var oeChart = new Chart(ctx).Line(aDataValues);
}