require 'rubygems'
require 'mongo'
require 'bson'
require 'time'

include Mongo
	def testconnection
		begin
			mongo_client = MongoClient.new('172.20.1.20', 20017)
			mongo_client.database_names     # lists all database names
			mongo_client.database_info.each { |info| puts info.inspect }

			db = mongo_client.db("QualityDepartmentDB")
			puts db.collection_names
			coll = db.collection("TestLogItem")

			#puts coll.find().skip(5000).limit(10).to_a
			#puts coll.count
			puts Time.now - 24*60*60*5
			puts coll.find({"EndTime" => {"$gt" => (Time.now - 30*24*60*60)}, "Name" => "billingtest12_52_new"}).count
			vTest = coll.find({"EndTime" => {"$gt" => (Time.now - 30*24*60*60)}, "Name" => "billingtest12_52_new"})
			vTest.each do |x|
				puts x
			end
			# db.blog.posts.findOne( { }, { "comments" : { "$slice" : -10 } } );

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