$(document).ready(function() {
	$(function() {
		$( "#tabs" ).tabs();
	});

	$('#savetiming').click(function(){
		var timingArr = {};
		$('.time').each(function(){
			timingArr[$(this).prop('name')] = $(this).val();
		});
		console.log('timing forming success!'+JSON.stringify(timingArr));
		$.ajax({
			url: 'testcontrol/receivetiming',
			type: 'POST',
			data: JSON.stringify(timingArr),
			contentType: 'application/json; charset=utf-8',
			dataType: 'json',
			async: false,
			success: function() {
				console.log('timing sending success!'+JSON.stringify(timingArr));
			}
		});
	});
	
	$('#starttimehref').click(function() {
		// Parsing answer for table data query
		$.getJSON('testcontrol/gettiming', function(json) {
			console.log("Building table");
			// Filling table from JSON
			$.each(json.dataArray, function(i, obj) {
				$('#tbtiming').append('<tr>' +
				'<td>' + obj['label'] + '</td>' +
				'<td>' + obj['oldtime'] + '</td>' +
				'<td>' + '<input type="text" class="time" name="' + obj['name'] + '" value="'+obj['oldtime']+'" /></td>' + '</tr>');
			});
		});
	});

	var loadTestData = function() {
		$('#comp').empty();
		$('#stand').empty();
		$.getJSON('getcomp', function(json) {
			{
				console.log("Building comp list");
				console.log(json)
				$('#comp').empty();
				// Filling table from JSON
				$.each(json.data, function(key,obj) {
					$('#comp').append('<option value="' +
					obj.value + '">' + obj.label + '</option>');
				});
			}
		});
		$.getJSON('getstand', function(json) {
			{
				console.log("Building comp list");
				console.log(json)
				$('#stand').empty();
				// Filling table from JSON
				$.each(json.data, function(key,obj) {
					$('#stand').append('<option value="' +
					obj.value + '">' + obj.label + '</option>');
				});
			}
		});
	};
	loadTestData();
});