require './/app//helpers//Datadb.rb'
require './/app//helpers//dbconnector.rb'
require 'date'

#puts Date.parse("2011-06-02")
logpareser = Datadb::LogParser.new
#logpareser.uploadDataFromTestRepositoryOnDate("2013-10-23")
#logpareser.uploadDataFromTestRepositoryOnDate("2013-10-24")
logpareser.uploadDataFromTestRepositoryOnDate("2013-10-27")
#logpareser.uploadListOfTestOperationsFromFile
#Datadb::DBConnector.instance.addNewDate("2013-05-19")
#puts Datadb::PerformanceDataSupplier.instance.getReleaseList().to_s
#Datadb::PerformanceDataSupplier.instance.getTestTimeExecForAllReleases("2013-06-01", "2013-07-25", "REGFilePerformance")

#mds =  MongoDBConnector.instance.getMds("defaultWorkerName")
#File.open("c:\\testmdsjson.txt", 'w') { |file| file.write(mds.to_s.force_encoding(Encoding::CP1251)) }
#puts mds["Root"]["TestItem"][0]["name"].to_s

  	def createTreeForView(_tree)
		treeElem = Hash.new()
		#puts _tree
		#puts _tree["name"].to_s
		treeElem[:data] = _tree["name"]
		attrElem = Hash.new()
		attrElem[:id] = 0
		if _tree["enabled"] == '-1'
			attrElem[:class] = 'jstree-checked'
		else
			attrElem[:class] = ''
		end
		treeElem[:attr] = attrElem
		childItems = Array.new()
		# проверяем, есть ли дети
		if _tree.has_key?("TestItem") == true 
		    # тут стоит хак для одного ребенка, надо переписать
			if _tree["TestItem"].length == 4 # 4 - количество элементов у одного айтема
				if _tree["TestItem"].has_key?("name") # name - если есть нэйм и элементов = 4 - это точно один айтем
					childItems.push(treeHelper(_tree["TestItem"]))
				end
			else
				count = 0
				   _tree["TestItem"].each do |x|
				   		begin
				   			puts _tree["TestItem"][count]
				   			puts count
				   			childItems.push(createTreeForView(x))
				   			count = count +1
				   		rescue
				   			puts "Chto to poshlo ne tak"
				   		end
				   	end
				end
			#end
			 #treeHelper(_tree["TestItem"])
			 treeElem[:children] = childItems
		end
		return treeElem
	end


	#newTree = mds["Root"]
	#newTree = newTree["TestItem"][0]

	#value = createTreeForView(newTree)
	#puts value