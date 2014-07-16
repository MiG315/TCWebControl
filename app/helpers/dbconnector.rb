require 'rubygems'
require 'mongo'
require 'bson'
require 'singleton'

include Mongo

# this is interface
class DbConnectionHandler
	include Singleton
	# traditional GET/SET
	def getMds(_workerName)

	end

	def setMds(_workerName, _MDSStructure)

	end

	def getRunTime(_workerName)

	end

	def setRunTime(_workerName, _runTimeHash)

	end

	#####################
	## working with python
	#####################
	def setPython(_workerName, _PythonText)

	end

	def getPython(_workerName)

	end

	def getPythonLastChange(_workerName)

  	end

  	def setPythonLastChange(_workerName, _lastChangeDate)

  	end

  	def setPythonBackup(_workerName, _PythonTextBackup)

  	end

  	def getPythonBackup(_workerName)

  	end

	# working with whole object

	def getWorkerData(_workerName)

	end

	def setWorkerData(_workerName, _WorkerObj)

	end

	def getSelfInfo()

	end
end


class MongoMDSConnector
	include Singleton
	def initialize
		begin
			@client = MongoClient.new('localhost', 27017)
			@db     = @client['production']
			@mdsColl= @db['mds']
		rescue
			puts "No DB with name 'localhost'@27017 are available"
			raise "Cant connect to DB! Stop execution."
		end
	end

	def createMds(_name , _workerName, _release)
		if checkMdsForExistance(_name, _workerName, _release)
			puts "MongoMDSConnector.getMds MDS with params () already exists! name = #{_name}, workerName =  #{_workerName}, release = #{_release}"
		else
			@mdsColl.insert({"name" => _name, "workerName" => _workerName, "release" => _release, "runtimeMarker" => "byDefault", "Data" => Hash.new(), "modifTime" => ""})
		end
	end

	def getMds(_name, _workerName, _release)
		if not checkMdsForExistance(_name, _workerName, _release)
			raise "MongoMDSConnector.getMds No MDS with params {name = #{_name}, workerName =  #{_workerName}, release = #{_release}} are found!"
		else 
			puts "MongoMDSConnector.getMds(#{_name}, #{_workerName}, #{_release})"
			mds = @mdsColl.find("name" => _name, "workerName" => _workerName, "release" => _release).to_a[0]
			result = mds["Data"]
		end

	end

	def setMds(_name, _workerName, _release, _hash)
		if not checkMdsForExistance(_name, _workerName, _release)
			# нужно установить MDS
			puts "MongoMDSConnector.setMds No MDS with name = #{_name}, worker name = #{_workerName}, release = #{_release}"
			puts "creating record..."
			createMds(_name, _workerName, _release)
			#raise "No mds with params {name = #{_name}, workerName =  #{_workerName}, release = #{_release}} not found!"
		end 
		puts "MongoMDSConnector.setMds(#{_name}, #{_workerName}, #{_release})"
		@mdsColl.update({"name" => _name, "workerName" => _workerName, "release" => _release}, {"$set" => {"Data" => _hash}}, :upsert => true, :safe => true)
	end

	def checkMdsForExistance(_name, _workerName, _release)
		# check whether current worker exists
		if @mdsColl.find("name" => _name, "workerName" => _workerName, "release" => _release).to_a.length() == 0
			#raise FUUUU!
			puts "MongoMDSConnector.checkMdsForExistance No MDS with params {name = #{_name}, workerName =  #{_workerName}, release = #{_release}} not found!"
			result = false
		else
			result = true
		end
		return result
	end

	def removeMds(_name, _workerName, _release)
		if not checkMdsForExistance(_name, _workerName, _release)
			puts "MongoMDSConnector.removeMds No MDS with name = #{_name}, worker name = #{_workerName}, release = #{_release}"
		else
			@mdsColl.remove({"name" => _name, "workerName" => _workerName, "release" => _release})
		end				
	end

	def setName(_name, _workerName, _release, _newName)
		if checkMdsForExistance(_name, _workerName, _release)
			@mdsColl.update({"name" => _name, "workerName" => _workerName, "release" => _release}, {"$set" => {"name" => _newName}})
		end
	end

	def setRelease(_name, _workerName, _release, _newRelease)
		if checkMdsForExistance(_name, _workerName, _release)
			@mdsColl.update({"name" => _name, "workerName" => _workerName, "release" => _release}, {"$set" => {"release" => _newRelease}})
		end
	end

	def setWorker(_name, _workerName, _release, _newWorker)
		if checkMdsForExistance(_name, _workerName, _release)
			@mdsColl.update({"name" => _name, "workerName" => _workerName, "release" => _release}, {"$set" => {"workerName" => _newWorker}})
		end
	end

	def getModificationTime(_name, _workerName, _release)
		if checkMdsForExistance(_name, _workerName, _release)
			mds = @mdsColl.find("name" => _name, "workerName" => _workerName, "release" => _release).to_a[0]
			result = mds["modifTime"]
		else
			raise "MongoMDSConnector.getModificationTime [MDS NOT FOUND : {name = #{_name}, workerName =  #{_workerName}, release = #{_release}}]"
		end
	end

	def setModificationTime(_name, _workerName, _release, _time)
		if checkMdsForExistance(_name, _workerName, _release)
			@mdsColl.update({"name" => _name, "workerName" => _workerName, "release" => _release}, {"$set" => {"modifTime" => _time}}, :upsert => true, :safe => true)
		else
			raise "MongoMDSConnector.setModificationTime [MDS NOT FOUND : {name = #{_name}, workerName =  #{_workerName}, release = #{_release}}]"
		end
	end

	###========================================
	###  блок для работы с нескольками записями
	###========================================
	def getAllNamed()
		mdsWithName = @mdsColl.find("workerName" => "", "release" => "").to_a
		return mdsWithName
	end

	def getAllOfWorkerByRelease(_release)
		mdsOfWorker = @mdsColl.find("release" => _release, "name" => "").to_a
	end

	def getAllNamedRelease(_release)
		mdsWithName = @mdsColl.find("workerName" => "", "release" => _release).to_a
		return mdsWithName
	end

end

class MongoDBConnector < DbConnectionHandler

	def initialize
		begin
			@client = MongoClient.new('localhost', 27017)
			@db     = @client['production']
			@workerColl = @db['workers']
		rescue
			puts "No DB with Name 'localhost'@27017 are available"
		end
		# setting up necessary preconditions
		# none
	end

	# traditional GET/SET

	def createNewObject(_workerName)
		@workerColl.insert({"name" => _workerName, "runtime" => "" , "python" => "", "pythonBackup" => "" ,"stands" => "empty_for_now", "MDS" => Array.new()})
	end

	def getMds(_workerName, _release)
		# check whether current worker exists
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			#raise FUUUU!
			raise "No worker with name #{_workerName} are found."
		else
			puts "dbconnector.getMds(#{_workerName}, #{_release})"
			mdsArr = @workerColl.find("name" => _workerName).to_a[0]["MDS"]
			mds = Hash.new()
			mdsArr.each do |x|
				if x.has_key?(_release)
					mds = x[_release]
					puts "MDS found."
				end
			end
			result = mds
		end
	end

	def setMds(_workerName, _MDSStructure, _release)
		# check whether current worker exists in collection
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			# create new row
			@workerColl.insert({"name" => _workerName, "runtime" => _runTimeHash, "python" => "", "stands" => "empty_for_now", "MDS" => Array.new(), "mdsLastChange" => Array.new()})
		else 
			# update row
			@workerColl.update({"name" => _workerName}, {"$pull" => {"MDS" => {"releaseName" => _release}}} )
			@workerColl.update({"name" => _workerName}, {"$push" => {"MDS" => {_release => _MDSStructure, "releaseName" => _release}}}, :upsert => true, :safe => true)
		end
	end

	def checkMDS(_workerName, _release)
		# check whether current worker exists
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			#raise FUUUU!
			raise "No worker with name #{_workerName} are found."
		else
			mdsArr = @workerColl.find("name" => _workerName).to_a[0]["MDS"]

			existance = false
			if mdsArr.length > 0 then
				mdsArr.each do |x|
					if x.has_key?(_release)
						existance = true
					end
				end
			end
			result = existance
		end
	end

	def getRunTime(_workerName)
		# check whether current worker exists
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			#raise FUUUU!
			raise "No worker with name #{_workerName} are found."
		else
			result = @workerColl.find("name" => _workerName).to_a[0]["runtime"]
		end
	end

	def setRunTime(_workerName, _runTimeHash)
		# check whether current worker exists in collection
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			# create new row
			@workerColl.insert({"name" => _workerName, "runtime" => _runTimeHash, "python" => "", "stands" => "empty_for_now", "MDS" => Array.new(), "mdsLastChange" => Array.new()})
		else 
			# update row
			@workerColl.update({"name" => _workerName}, {"$set" => {"runtime" => _runTimeHash}})
		end
	end

	def setPython(_workerName, _PythonText)
		# check whether current worker exists in collection
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			# create new row
			@workerColl.insert({"name" => _workerName, "runtime" => "" , "python" => _PythonText, "stands" => "empty_for_now", "MDS" => Array.new()})
		else 
			# update row
			@workerColl.update({"name" => _workerName}, {"$set" => {"python" => _PythonText}})
		end
	end

	def getPython(_workerName)
		# check whether current worker exists
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			#raise FUUUU!
			raise "No worker with name #{_workerName} are found."
		else
			result = @workerColl.find("name" => _workerName).to_a[0]["python"]
		end
	end

	def setPythonBackup(_workerName, _PythonTextBackup)
		#ckeck whether current worker exists in collection
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			# create new row
			MongoDBConnector.instance.createNewObject(_workerName)
			@workerColl.update({"name" => _workerName}, {"$set" => {"pythonBackup" => _PythonTextBackup}})
		else
			@workerColl.update({"name" => _workerName}, {"$set" => {"pythonBackup" => _PythonTextBackup}})
		end
  	end

  	def getPythonBackup(_workerName)
		#check whether current worker exists
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			raise "No worker with name #{_workerName} are found."
		else
			result = @workerColl.find("name" => _workerName).to_a[0]["pythonBackup"]
		end 
  	end


	# last change defs

	def getPythonLastChange(_workerName)
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			raise "No worker with name #{_workerName} are found"
		else 
			result = @workerColl.find("name" => _workerName).to_a[0]["pythonLastChange"]
    	end
  	end

  	def setPythonLastChange(_workerName, _lastChangeDate)
		if @workerColl.find("name" => _workerName).to_a.length() == 0
			@workerColl.insert({"name" => _workerName, "runtime" => "", "pythonLastChange" => _lastChangeDate, "python" => "", "stands" => "", "MDS" =>Array.new()} )
		else
			result = @workerColl.update({"name" => _workerName}, {"$set" => {"pythonLastChange" => _lastChangeDate}})
		end
  	end

  	def getRuntimeLastChange(_workerName)
  		if @workerColl.find("name" => _workerName).to_a.length() == 0
  			raise "No worker with name #{_workerName} are found"
  		else
  			result = @workerColl.find("name" => _workerName).to_a[0]["runtimeLastChange"]
  		end
  	end

  	def setRuntimeLastChange(_workerName, _lastChangeDate)
  		if @workerColl.find("name" => _workerName).to_a.length() == 0
  			@workerColl.insert({"name" => _workerName, "runtime" => "", "runtimeLastChange" => _lastChangeDate, "pythonLastChange" => "", "python" => "", "stands" => "", "MDS" =>Array.new()})
  		else
  			@workerColl.update({"name" => _workerName}, {"$set" => {"runtimeLastChange" => _lastChangeDate}})
  		end
  	end

   	def getMDSLastChange(_workerName, _release)
  		if @workerColl.find("name" => _workerName).to_a.length() == 0
  			raise "No worker with name #{_workerName} are found"
  		else
  			mdsArr = @workerColl.find("name" => _workerName).to_a[0]["mdsLastChange"]
			lct = Hash.new()
			mdsArr.each do |x|
				if x.has_key?(_release)
					lct = x[_release]
					puts "Last change time found found."
				end
			end
			result = lct
  			#result = @workerColl.find("name" => _workerName).to_a[0]["mdsLastChange"][_release]
  		end
  		return result
  	end

  	def setMDSLastChange(_workerName, _release, _lastChangeDate)
  		if @workerColl.find("name" => _workerName).to_a.length() == 0
  			@workerColl.insert({"name" => _workerName, "runtime" => "", "mdsLastChange" => Array.new(), "pythonLastChange" => "", "python" => "", "stands" => "", "MDS" => Array.new()})
  		else
  			@workerColl.update({"name" => _workerName}, {"$pull" => {"mdsLastChange" => {"releaseName" => _release}}} )
  			@workerColl.update({"name" => _workerName}, {"$push" => {"mdsLastChange" =>{ _release => _lastChangeDate, "releaseName" => _release}}})
  		end
  	end

	# working with whole object

	def getWorkerData(_workerName)

	end

	def setWorkerData(_workerName, _WorkerObj)

	end

	def getSelfInfo()

	end

end


#dbConn = new MongoDBConnector
#MongoDBConnector.instance.setRunTime("worker_test", "2013-01-06")
#puts MongoDBConnector.instance.getRunTime("worker_test")