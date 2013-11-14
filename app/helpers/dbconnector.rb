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

class MongoDBConnector < DbConnectionHandler

	def initialize
		begin
			@client = MongoClient.new('localhost', 27017)
			@db     = @client['test']
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

def test()
	@client = MongoClient.new('localhost', 27017)
	@db     = @client['test']
	@coll   = @db['users']


	if @coll.find("name" => "worker1").to_a.length() == 0
		# create new row
		puts "no worker found, creating worker"
		@coll.insert({"name" => "worker1", "runtime" => ["startTime" => "2013-10-30", "stopTime" => "2013-12-30"], "python" => "", "stands" => "empty_for_now", "MDS" => "empty_for_now"})
	else 
		# update row
		puts "worker found"
		@coll.update({"name" => "worker1"}, {"$set" => {"runtime" => ["startTime" => "olool", "stopTime" => "shalala"]}})
	end

	puts "there are #{@coll.count} records."
	@coll.find.each { |doc| puts doc.inspect}

	puts "now we want to insert some data"
	3.times do |i|
		@coll.insert({"a" => i+1})
	end

	puts "now there are #{@coll.count} records"
	@coll.find.each {|doc| puts doc}

	puts "now lets delete all of new data"
	@coll.remove("a" => 1)
	@coll.remove("a" => 2)
	@coll.remove("a" => 3)
	#@coll.remove("name" => "worker1")

	puts @coll.find("name" => "worker1").to_a[0]["name"]


	puts "now there are #{@coll.count} records"
	@coll.find.each {|doc| puts doc}
end


#dbConn = new MongoDBConnector
#MongoDBConnector.instance.setRunTime("worker_test", "2013-01-06")
#puts MongoDBConnector.instance.getRunTime("worker_test")