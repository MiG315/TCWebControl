﻿$(document).ready(function() {
	$("body").height("100%").width("100%");

	$('#version').empty();
	$('#version').text('0.1.0 release');
	var sURL = 'http://172.20.5.130:3000/testcontrol/'; //server URL
	if (!window.editor) {
		window.editor = CodeMirror.fromTextArea(document.getElementById("plainscript"), {
			mode: "python",
			lineNumbers: true,
			matchBrackets: true,
			indentUnit: 2,
			indentWithTabs: true,
			enterMode: "keep",
			tabMode: "shift"
		});
	}

	// tabs init
	(function() {
		$("#tabs").tabs();
		$("#plainscript").height("100%").width("100%");
	})();

	// filling computer names
	(function() {
		$('#comp').empty();
		$('#stand').empty();
		$.getJSON(sURL+'getcomp/', function(json) {
			console.log("Building comp list");
			$('#comp').empty();
			// Filling table from JSON
			$.each(json.data, function(key,obj) {
				$('#comp').append('<option value="' +
					obj['value'] + '">' + obj['label'] + '</option>');
			});
			standGetter();
		});
	})();

	$("body").click(function specialForAlexanderBorodachBleat() {
		makeCheckedList("#criticalparam");
		makeCheckedList("#periodicparam");
	});
	// checks or uncheks selected nodes
	function nodeChecker(param) {
		var tree = $.jstree._reference('#testsTree');
		var selectedNodes = tree.get_selected();
		switch (param) {
			case 'check': tree.check_node(selectedNodes); break;
			case 'uncheck': tree.uncheck_node(selectedNodes); break;
			default : alert("Invalid check param for nodeChecker"); break;
		}
	}

	// makes string containing selected items in dropdown checkboxes
	function makeCheckedList(element) {
		var keyStr = '';
		var keyArr = $(element).dropdownCheckbox("checked");
		var len = keyArr.length;
		for (var i = 0; i < len; i++) {
			if (keyArr[i]["isChecked"]) {
				(i < len - 1)? keyStr += keyArr[i]["label"] + ",":keyStr += keyArr[i]["label"];
			}
		}
		$(element + "checked")[0].innerHTML = "Selected: [" + keyStr + "]";
		console.log(keyStr);
	}

	function getPriority() {
		$.getJSON(sURL+'getpriority/?release=' + $('#stand :selected').val(), function(json) {
			console.log("Building criticalparam list");
			// Filling table from JSON
			$("#criticalparam").dropdownCheckbox({
				data: json.data,
				title: "Test priority"
			});
			// displays list of checked priority items
			$("#criticalparam > button").click(function() { makeCheckedList("#criticalparam"); });
		});
	}
	
	function getExecType() {
		$.getJSON(sURL+'getexectype/?release=' + $('#stand :selected').val(), function(json) {
			console.log("Building periodicparam list");
			// Filling table from JSON
			$("#periodicparam").dropdownCheckbox({
				data: json.data,
				title: "Test periodic"
			});
			// displays list of checked periodic items
			$("#periodicparam > button").click(function() { makeCheckedList("#periodicparam"); });
		});
	}

	function standGetter(){
		$.getJSON(sURL+'getstand/?compname=' + $('#comp :selected').val(), function(json) {
			console.log("Building stand list");
			$('#stand').empty();
			$('#releasecoverage').empty();
			// Filling table from JSON
			$.each(json.data, function(key,obj) {
				$('#stand').append('<option value="' +
				obj['value'] + '">' + obj['label'] + '</option>');
				
				$('#releasecoverage').append('<option value="' +
				obj['value'] + '">' + obj['label'] + '</option>');
			});
			switch ("false") {
				case $('#testplan').attr('aria-hidden'): { MDSGetter('usual'); loadMDSCollection(); getExecType(); getPriority(); }; break;
				case $('#pythonscript').attr('aria-hidden'): pythonGetter('usual'); break;
				case $('#starttime').attr('aria-hidden'): timingGetter(); break;
				case $('#coverage').attr('aria-hidden'): coverageGetter(); break;
			}
		});
	}

	function loadMDSCollection() {
		$('#nameMDS').empty();
		$.getJSON(sURL+'getmdscollection/?standname='+$('#stand :selected').val(), function(json) {
			console.log("Building MDS list");
			$('#nameMDS').empty();
			// Filling table from JSON
			$.each(json.data, function(key,obj) {
				$('#nameMDS').append('<option value="' +
				obj['value'] + '">' + obj['value'] + '</option>');
			});
		});
	}

	// close\open nodes by '*' and check\uncheck nodes by space
	$(document).keyup(function(event) {
		var tree = $.jstree._reference('#testsTree')
		var selectedNodes = tree.get_selected();
		switch (event.keyCode) {
			case 106: {
				if (tree.is_open(selectedNodes)) {
					tree.close_node(selectedNodes);
				} else {
					tree.open_node(selectedNodes);
				}
				break;
			}
			case 32: {
				if (tree.is_checked(selectedNodes)) {
					tree.uncheck_node(selectedNodes);
				} else {
					tree.check_node(selectedNodes);
				}
				break;
			}
		}
	});

	function timingGetter() {
		$('#loaderScr').fadeOut('fast');
		// Parsing answer for table data query
		$.getJSON(sURL+'gettiming/?compname='+$('#comp :selected').val(), function(json) {
			console.log("Building table");
			$('#tbtiming').empty();
			$('#tbtiming').append(	'<td><b>Название</b></td>'+
									'<td><b>Старое время</b></td>'+
									'<td><b>Новое время</b></td>');
			// Filling table from JSON
			$.each(json.dataArray, function(i, obj) {
				$('#tbtiming').append('<tr>' +
				'<td>' + obj['label'] + '</td>' +
				'<td>' + obj['oldtime'] + '</td>' +
				'<td>' + '<input type="time" class="time" name="' + obj['label'] + '" value="'+obj['oldtime']+'" /></td>' + '</tr>');
			});
			$('#loaderScr').text('Time table from '+$('#comp :selected').val()+' is loaded');
			$('#loaderScr').fadeIn('fast');
		});
	}

	function testCoverageGetter() {
		$('#loaderScr').fadeOut('fast');
		var makeStringFromArray = function (aArr) {
			var str = '';
			aArr.forEach(function(val){
				str += '<div class="uncovered_test">'+val+'</div>\n';
			});
			return str;
		};

		// Parsing answer for table data query
		$.getJSON(sURL+'gettestcoverage/?release='+$('#releasecoverage :selected').val(), function(json) {
			console.log("Building coverage table");
			$('#covertable').empty();
			$('#covertable').append('<tr><td class="test_priority"><b>Приоритет</b></td>'+
									'<td class="uncovered_test"><b>Список выключенных из тестового плана тестов</b></td></tr>\n');
			// Filling table from JSON
			$.each(json.dataArray, function(i, obj) {
				$('#covertable').append('<tr>' +
				'<td class="test_priority">' + obj['name'] + '</td>' +
				'<td>' + makeStringFromArray(obj['value']) + '</td></tr>\n');
			});
			$('#loaderScr').text('Test coverage from '+$('#releasecoverage :selected').val()+' is loaded');
			$('#loaderScr').fadeIn('fast');
		});
	}

	function pythonGetter(receiveMode) {
		$('#loaderScr').fadeOut('fast');
		var sURLget;
		// Parsing answer for table data query
		switch (receiveMode) {
			case 'usual':	sURLget = sURL+'getPython/?compname='; break;
			case 'repo':	sURLget = sURL+'getPythonFromRepo/?compname='; break;
			case 'backup':	sURLget = sURL+'getPythonFromBackup/?compname='; break;
		}
		$.ajax({
			url: sURLget.toLowerCase()+$('#comp :selected').val()
		}).done(function(data){
			editor.setValue(data);
			$('#loaderScr').text('Python script from '+$('#comp :selected').val()+' is loaded');
			$('#loaderScr').fadeIn('fast');
		});
	}

	function MDSGetter(receiveMode) {
		$('#loaderScr').fadeOut('fast');
		var sURLget, loadedData;
		var prepareNodes = function (data) {
			var tree = $.jstree._reference('#testsTree');
			var undef = data["children"] === undefined;
			if (!undef) {
				var len = data["children"].length;
			}
			if (data && data["attr"] && data["attr"]["class"] && data["attr"]["id"]) {
				switch(true) {
					case (data["attr"]["class"] === "jstree-checked"): {
						tree.check_node('#'+data["attr"]["id"]);
						break;
					}
					case (data["attr"]["class"] === "jstree-unchecked"): {
						tree.uncheck_node('#'+data["attr"]["id"]);
						break;
					}
				}
			}
			if (len > 0 || !undef) {
				for (var i = 0;i < len; i++) {
					prepareNodes(data["children"][i]);
				}
			}
		};

		var makeKeyString = function (element) {
			var keyStr = '';
			var keyArr = element.dropdownCheckbox("checked");
			var len = keyArr.length;
			for (var i = 0; i < len; i++) {
				if (keyArr[i]["isChecked"]) {
					(i < len - 1)? keyStr += keyArr[i]["label"] + ",":keyStr += keyArr[i]["label"];
				}
			}
			return keyStr;
		};
		// Parsing answer for table data query
		switch (receiveMode) {
			case 'usual':			sURLget = sURL+'getMDS/?compname='; break;
			case 'repo':			sURLget = sURL+'getMDSRepo/?compname='; break;
			case 'backup':			sURLget = sURL+'getMDSBackup/?compname='; break;
			case 'getMDSByName':	sURLget = sURL+'getMDSByName/?compname='; break;
		}
		console.log(sURL+'generatesingletestplan?release=' + $('#stand :selected').val() + '&priority=' + $('#criticalparam :selected').val() + '&exectype=' + $('#periodicparam :selected').val() + '&timelimit=' + $('#workingtime').val());
		$.getJSON((receiveMode !== "applyToTree")? (sURLget.toLowerCase() + $('#comp :selected').val() + '&standname=' + $('#stand :selected').val() + ((receiveMode==='getMDSByName')?'&mdsname=' + $('#nameMDS').val():'')):
				  sURL+'generatesingletestplan?release=' + $('#stand :selected').val() + '&priority=' + makeKeyString($('#criticalparam')) + '&exectype=' + makeKeyString($('#periodicparam')) + '&timelimit=' + $('#workingtime').val(),
				  function(json) {
			loadedData = json.data;
			$("#testsTree")
				.jstree({
					"plugins" : ["themes","json_data","ui","checkbox","crrm","dnd","hotkeys","grid"],
					"json_data" : {
						"data" : json.data
					},
					"checkbox": {
						"two_state": true,
						"checked_parent_open": false
						},
					"grid": {
						"resizable": true,
						"columns": [
							{"width": 400, "header": "Test name"},
							{"width": 200, "header": "Test method name", "value": "MethodName"},
							{"width": 200, "header": "Test unit file name", "value": "UnitName"}
						]
					}
				}).bind('loaded.jstree', function() {
					prepareNodes(loadedData);
				});
			//console.log(json.data);
			$('#loaderScr').text('MDS ' + $('#stand :selected').val() + ' from '+$('#comp :selected').val()+' is loaded');
			$('#loaderScr').fadeIn('fast');
		}).error(function (jqXHR, textStatus, errorThrown) {
			console.log("error " + textStatus);
			console.log(jqXHR);
			if (errorThrown === 'Internal Server Error')
			{
				alert('Дерево тестов не существует');
				$("#testsTree").empty();
			}
		});
	}

	function pythonSetter(receiveMode) {
		var sURLset;
		$('#loaderScr').fadeOut('fast');
		switch (receiveMode) {
			case 'save':	sURLset = sURL+'receivePython/?compname='; break;
			case 'backup':	sURLset = sURL+'makePythonBackup/?compname='; break;
		}
		if (confirm('Вы уверены?')) {
			var pythonSc = {script:""};
			pythonSc.script = editor.getValue();
			console.log('Python forming success! Data = '/* + pythonSc*/);
			$.ajax({
				url:			sURLset.toLowerCase()+$('#comp :selected').val()+'&standname='+$('#stand :selected').val(),
				type:			'POST',
				data:			pythonSc,
				async:			false,
				success:		function() {
					console.log('Python sending success!'/* + pythonSc*/);
					$('#loaderScr').text('Python script for '+$('#comp :selected').val()+' is saved!');
					$('#loaderScr').fadeIn('fast');
				}
			});
		}
	}

	function MDSSetter(receiveMode) {
		var sURLset, tree;
		var makeEndResult = function (data) {
			var tree = $.jstree._reference('#testsTree');	
			var undef = data["children"] === undefined;
			if (!undef) {
				var len = data["children"].length;
			}
			if (tree.is_checked('#'+data["attr"]["id"])) {
				data["attr"]["class"] = "jstree-checked";
			} else {
				data["attr"]["class"] = "jstree-unchecked";
			}
			if (len > 0 || !undef) {
				for (var i = 0;i < len; i++) {
					makeEndResult(data["children"][i]);
				}
			}
			return data;
		};
		switch (receiveMode) {
			case 'save':	sURLset = sURL+'receiveMDS/?compname='; break;
			case 'backup':	sURLset = sURL+'makeMDSBackup/?compname='; break;
			case 'saveMDSWithName':	sURLset = sURL+'saveMDSWithName/?compname='; break;
		}
		if (confirm('Вы уверены?')) {
			var MDSData = {data:""};
			tree = $.jstree._reference('#testsTree');
			var endResult = tree.get_json(-1,['data','attr','id','class','metadata','children'])[0];
			MDSData.data = JSON.stringify(makeEndResult(endResult));
			console.log('MDS forming success! Data = '/* + MDSData.data*/);
			$.ajax({
				url:			sURLset.toLowerCase()+$('#comp :selected').val()+'&standname='+$('#stand :selected').val()+((receiveMode==='saveMDSWithName')?'&mdsname='+prompt('Введите новое имя',$('#nameMDS').val()):''),
				type:			'POST',
				data:			MDSData,
				async:			false,
				success:		function() {
					console.log('MDS sending success!');
					(receiveMode==='saveMDSWithName')?loadMDSCollection():'';
				},
				statusCode: {
					404: function() {
						alert("Не найдено");
					},
					500: function() {
						alert("500 service temporarily disabled! Ваше дерево устарело. Обновитесь!");
					}
				}
			});
		}
	}

	function timingSetter(){
		if (confirm('Вы уверены?')) {
			var timingArr = {name:[]};
			$('.time').each(function(){
				var a = { name : $(this).prop('name'), value : $(this).prop('value') };
				timingArr["name"].push(a);
			});
			console.log('timing forming success!'+timingArr);
			$.ajax({
				url:			sURL.toLowerCase()+'receivetiming?compname='+$('#comp :selected').val(),
				type:			'POST',
				data:			timingArr,
				dataType:		'json',
				async:			false,
				success:		function() {
					console.log('timing sending success!'+timingArr);
				}
			});
			timingGetter();
		}
	}

	function deleteMDSByName() {
		var sURLset = sURL+'deleteMDSByName/?compname=';
		if (confirm('Вы уверены?')) {
			$.ajax({
				url:			sURLset.toLowerCase()+$('#comp :selected').val()+'&standname='+$('#stand :selected').val()+'&mdsname='+$('#nameMDS').val(),
				type:			'POST',
				data:			'',
				async:			false,
				success:		function() {
					console.log('MDS deleting success!');
					loadMDSCollection();
				},
				statusCode: {
					404: function() {
						alert("Не найдено");
					},
					500: function() {
						alert("500 service temporarily disabled! Ваше дерево устарело. Обновитесь!");
					}
				}
			});
		}
	}

	/* ===Getting functions=== */
	// getting plain Python settings text
	$('#pythonscripthref').click(function (){ pythonGetter('usual'); });
	// getting plain Python settings text from repo
	$('#getPythonFromRepo').click(function (){ pythonGetter('repo'); });
	// getting plain Python settings text from backup
	$('#getPythonFromBackup').click(function (){ pythonGetter('backup'); });

	// getting MDS 
	// filling stand names of selected computer
	$('#comp').change(function (){ standGetter(); });
	// get MDS list and test plan
	$('#stand').change(function(){
		if (!!$('#testplan').attr('aria-hidden')) { MDSGetter('usual'); loadMDSCollection(); }
	});
	$('#testplanhref').click(function (){ MDSGetter('usual'); });
	// getting MDS from repo
	$('#getMDSFromRepo').click(function (){ MDSGetter('repo'); });
	// getting MDS from backup
	$('#getMDSFromBackup').click(function (){ MDSGetter('backup'); });
	// getting MDS by name
	$('#nameMDS').change(function (){ MDSGetter('getMDSByName'); });
	// getting MDS by name
	$('#applyMDS').click(function (){ MDSGetter('applyToTree'); });

	// getting start stand timing when tab clicked
	$('#starttimehref').click(function (){ timingGetter(); });

	// getting test coverage results
	$('#coveragehref').click(function (){ testCoverageGetter(); });
	$('#releasecoverage').change(function (){ testCoverageGetter(); });
	/* ===Getting functions=== */

	/* ===Saving and backups=== */
	// try to save current Python script on server
	$('#savePython').click(function (){ pythonSetter('save'); });
	// try to backup current Python script on server
	$('#makePythonBackup').click(function (){ pythonSetter('backup'); });

	// try to save current MDS on server
	$('#saveMDS').click(function (){ MDSSetter('save'); });
	// try to save current MDS on server with different name
	$('#saveMDSWithName').click(function (){ MDSSetter('saveMDSWithName'); });
	// try to save current MDS on server with different name
	$('#deleteMDSByName').click(function (){ deleteMDSByName(); });
	// try to backup current MDS on server
	$('#makeMDSBackup').click(function (){ MDSSetter('backup'); });
	// try to save current timing on server
	$('#savetiming').click(function (){ timingSetter(); });
	/* ===Saving and backups=== */

	/*===Click part of interface===*/
	// check selected items
	$('#v').click(function() { nodeChecker('check'); });
	// uncheck selected items
	$('#x').click(function() { nodeChecker('uncheck'); });
	/*===Click part of interface===*/
});