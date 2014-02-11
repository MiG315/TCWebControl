require 'rubygems'
require 'mongo'
require 'bson'

include Mongo
	def testconnection
		begin
			mongo_client = MongoClient.new('172.20.1.20', 20017)
			mongo_client.database_names     # lists all database names
			mongo_client.database_info.each { |info| puts info.inspect }

			db = mongo_client.db("QualityDepartmentDB")
			puts db.collection_names
			coll = db.collection("TestLogItem")

			coll.find.each_slice(1) { |row| puts row }
			puts coll.count

			if db.authenticate("admin", "admin") == true
				puts "Authenticated."
			else
				puts "Not authenticated"
			end
			#db     = mongo_client['production']
			#mdsColl= db['mds']
		# rescue
		# 	puts "No DB with name @172.20.1.20 are available"
		end
	end

testconnection