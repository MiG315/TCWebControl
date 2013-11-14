require 'json'
require 'socket'
require 'dbconnector'
require 'time'
require 'digest/sha1'
#require 'mongo'
#require 'bson'
#include Dbconnector

class TestcontrolController < ApplicationController
  def index
  end
  
  def getcomp
	value = []	
	# получить список тачек с сервера
	workerList = ''
	TCPSocket.open('172.20.5.130', 2000){ |client|
		# say Hello to server
		client.puts "MasterOnline"
		client.gets
		client.puts "master_set get_worker_list"
		workerList = JSON.parse(client.gets)
		client.puts "master_set close_connection"
	}
	
	#rawarray = { :data => value}
	jsondata = workerList.to_json
	
  	render :text => jsondata
  end
  
  def getstand
	value = []	
	# получить список стендов у конктретного воркера 
	worker = params[:compname]
	standList = ''
	workerList = ''
	TCPSocket.open('172.20.5.130', 2000){ |client|
		# say Hello to server
		client.puts "MasterOnline"
		client.gets
		client.puts "master_set get_worker_stands " + worker
		#workerList = JSON.parse(client.gets)
		workerList = client.gets
		client.puts "master_set close_connection"
	}
	
	#rawarray = { :data => value}
	#jsondata = workerList.to_json
	render :text => workerList
  end
  
  ################################
  ###  WORKING WITH SHEDULE TABLE
  ################################
  
  def gettiming
	worker = params[:compname]
	
	realdata = '{"dataArray":[{"label":"first","oldtime":"1245"}]}'
	
	time = MongoDBConnector.instance.getRunTime(worker)
	
	timeList = []
	time.each do |x|
		x.each do |key, value|
			timeList.push(:label => key, :oldtime => value )
		end
	end
	time = {:dataArray => timeList}
	time = time.to_json
	render :text => time
  end
  
  def receivetiming
	worker = params[:compname]
	date = params['name']
	timeToSave = []
	
	date.each do |key, value|
			timeToSave.push(value["name"].to_s => value["value"].to_s)
	end
	MongoDBConnector.instance.setRunTime(worker, timeToSave)
	MongoDBConnector.instance.setRuntimeLastChange(worker, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
    render :text => timeToSave
  end
  
  ################################
  ###  WORKING WITH PYTHON SETTINGS
  ################################
  def getpython
	worker = params[:compname]
  	render :text => MongoDBConnector.instance.getPython(worker)
  end
  
  def receivepython
	worker = params[:compname]
	stand = params[:standname]
	data = params['script']
	MongoDBConnector.instance.setPython(worker, data)
	MongoDBConnector.instance.setPythonLastChange(worker, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
  	render :text => "python savedd"
  
  end 
  
  def getpythonfrombackup
	worker = params[:compname]
	render :text => MongoDBConnector.instance.getPythonBackup(worker)
  end
  
  def getpythonfromrepo
	worker = params[:compname]
	render :text => MongoDBConnector.instance.getPythonFromSVN()
  end
  
  def makepythonbackup
	worker = params[:compname]
	data = params['script']
	MongoDBConnector.instance.setPythonBackup(worker, data)
	#MongoDBConnector.instance.setPythonLastChange(worker, (Time,now).strftime("%d.%m.%Y %H:%M:%S"))
	render :text => "python backup saved"
  end
  
  ################################
  ###  WORKING WITH MDS
  ################################
  
  def getmdsrepo
	worker = params[:compname]
	stand = params[:standname]
	jsonTree = '{"data" : [{"data" : "(1231) Тесты по производительности говнокода","attr" : {"id" : "1"},"children" : [ {"data":"(1) Говнокодраз","attr" : {"id" : "01"},"children" : [{"data" : "(011) Ну а тут говнокодик","attr" : {"id" : "2", "class":"jstree-checked"},"children" : []}]},{"data" : "(02) Говнокод два","attr" : {"id" : "3"},"children" : []}]},{"data" :"(666) Тесты поупадку в ад ТАМАТА","attr" : {"id" : "5", "class":"jstree-checked"}}]}'
	render :text => jsonTree
  end
  
  def receivemds
	worker = params[:compname]
	viewTree = params['data']
	stand = params[:standname]	
	# получаем MDS из базы
	jsonDBTree = MongoDBConnector.instance.getMds(worker, stand)
	# получаем Root Node
	dbTree = jsonDBTree["Root"]
	dbTree = dbTree["TestItem"]
	# добавляем фиктивный элемент
	dbImprovedTree = Hash.new()
	dbImprovedTree["Name"] = "Тестирование " + stand
	dbImprovedTree["enabled"] = "-1"
	# подготавливаем дерево
	childrens = Array.new()
	dbTree.each do |x|
		childrens.push(x)
	end
	dbImprovedTree["TestItem"] = childrens
	# теперь устанавливаем в неё значения из пришедшего из вьюхи дерева
	viewTree = JSON.parse(viewTree)
	createTreeForDB(dbImprovedTree, viewTree)
	
	helpArray = Array.new()
	dbImprovedTree["TestItem"].each do |x|
		helpArray.push(x)
	end
	tree = Hash.new()
	tree[:TestItem] =  helpArray
	treeNew = Hash.new()
	treeNew[:Root] = tree
	
	MongoDBConnector.instance.setMds(worker, treeNew, stand)
	MongoDBConnector.instance.setMDSLastChange(worker, stand, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
	render :text => "mds saved"
  end
  
  def getmds
	worker = params[:compname]
	stand = params[:standname]
	
	# получаем MDS из базы
	jsonNewTree = MongoDBConnector.instance.getMds(worker, stand)
	#puts "tree in db"
	#puts jsonNewTree
	# парсим MDS для отображения на странице
	# получаем Root Node
	newTree = jsonNewTree["Root"]
	#newTree = newTree["TestItem"][0]
	# новое дерево
	# вводим фиктивную вершину
	value = Hash.new()
	value[:data] = "Тестирование " + stand
		falseAttr = Hash.new()
		falseAttr[:class] = "jstree-checked"
		falseAttr[:id] = "0000"
		falseAttr[:MethodName] = ""
		falseAttr[:UnitName] = ""
	value[:attr] = falseAttr
	# получаем дерево
	childrens = Array.new()
	newTree["TestItem"].each do |x|
		tree = createTreeForView(x)
		childrens.push(tree)
	end
	value[:children] = childrens
	rawarray = { :data => value}
	
	render :text => rawarray.to_json
  end
  
  private
  	def createTreeForView(_tree)
		treeElem = Hash.new()

		treeElem[:data] = _tree["name"]
		attrElem = Hash.new()
		if _tree["enabled"] == '-1'
			attrElem[:class] = 'jstree-checked'
		else
			attrElem[:class] = 'jstree-unchecked'
		end
		attrElem[:id] = Digest::SHA1.hexdigest(_tree["name"])
		attrElem[:MethodName] = _tree["MethodName"]
		attrElem[:UnitName] = _tree["UnitName"]
		treeElem[:attr] = attrElem

		childItems = Array.new()
		# проверяем, есть ли дети
		if _tree.has_key?("TestItem") == true 
		    #тут стоит хак для одного ребенка
			# если мы приходим к ребенку, как к хэшу
			# то его не надо итерировать
			if _tree["TestItem"].class == BSON::OrderedHash
				if _tree["TestItem"].has_key?("name")
					childItems.push(createTreeForView(_tree["TestItem"]))
				end
			# в противном случае, его надо итерировать
			else
				   _tree["TestItem"].each do |x|
				   			childItems.push(createTreeForView(x))
				   	end
				end

		end
		treeElem[:children] = childItems
		return treeElem
	end
 
 # данный метод устанавливает значения в _treeDB из _treeView
 # ограничение - они должны иметь одинаковую структуру
  private
	def createTreeForDB(_treeDB, _treeView)
		# проверяем, кто ребенок - хэш или массив
		if _treeDB.class == BSON::OrderedHash and _treeView.class == Hash
			if _treeView["attr"]["class"]  == 'jstree-checked'
				_treeDB["enabled"] = '-1'
			else
				_treeDB["enabled"] = '0'
			end
		end
		if _treeDB.has_key?("TestItem") == true
		    # тут стоит хак для одного потомка, проверяем, что он есть хэш
			if _treeDB["TestItem"].class == BSON::OrderedHash
					createTreeForDB(_treeDB["TestItem"], _treeView["children"][0])
			else
				count = 0
				   _treeDB["TestItem"].each do |x|
						createTreeForDB(x, _treeView["children"][count])
						count = count + 1
				   end
			end
		end
	end
end

