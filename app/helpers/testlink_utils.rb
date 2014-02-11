# coding: utf-8
require 'rubygems'
require 'C:\RailsInstaller\Ruby1.9.3\bin\mysql.rb'
require 'bson'
require 'singleton'

class TestLinkUtils

	def connectToDB()
		#my = Mysql.new(hostname, username, password, databasename) 
		@con = Mysql.init
		@con = Mysql.real_connect('dev.oe-it.ru', 'test_ctrl_system', 'b5QWX$,mMsf}Kj_}', 'testlink')
				@con.options Mysql::SET_CHARSET_NAME, 'utf8'
		puts "mysql charset = #{@con.character_set_name}"
		puts "mysql charset = #{@con.charset}"
		#@con = Mysql.new('dev.oe-it.ru', 'test_ctrl_system', 'b5QWX$,mMsf}Kj_}', 'testlink')
	end

	def disconnectFromDB()
		@con.close
	end

	def getAllTests(_customFieldType)
		rs = @con.query('select nh1.id ,nh1.name, cfdv.value from nodes_hierarchy as nh1 inner join 
						nodes_hierarchy as nh2 on	
						nh1.id = nh2.parent_id inner join
							cfield_design_values as cfdv on
							cfdv.node_id = nh2.id inner join 
								tcversions as tcver on
								tcver.id = nh2.id 
								where cfdv.field_id = ' + _customFieldType +' and tcver.active =1')
		return rs
	end

	def getPriorities()
		rs = @con.query("select possible_values from custom_fields where name = 'TestPriority'")
		returnArray = Array.new()
		string = ""
		rs.each_hash { |h| string = h["possible_values"]}
		returnArray = string.split("|")
		return returnArray
	end

	def getTestExecType()
		rs = @con.query("select possible_values from custom_fields where name = 'TestExecutionInterval'")
		returnArray = Array.new()
		string = ""
		rs.each_hash { |h| string = h["possible_values"]}
		returnArray = string.split("|")
		return returnArray
	end

	def getAllTestsPriority()
		return getAllTests('11')
	end

	def getAllTestsExecType()
		return getAllTests('12')
	end

	def getAllTestAllParams()
		resHash = Hash.new()
		resHash2 = Hash.new()
		resresHash = Hash.new()
		rs = getAllTestsPriority()
		rs.each_hash { |h| resHash[h["name"].slice!(0, h["name"].index(" "))] = {"priority" => h["value"]}}
		rs = getAllTestsExecType()
		rs.each_hash { |h| resHash2[h["name"].slice!(0, h["name"].index(" "))] = {"exectype" => h["value"]}} 

		resHash.each do |key, value|
			digitalCode = /([\d]*_){1,3}([\d]*)/.match key
			#puts digitalCode
			resresHash[digitalCode.to_s] = {:name => key,  :priority => resHash[key]["priority"], :exectype => resHash2[key]["exectype"]}
		end
		return resresHash
	end


end

def test()
	testlink = TestLinkUtils.new()
	testlink.connectToDB()
	puts testlink.getPriorities
	puts testlink.getTestExecType
	#testlink.getAllTestsExecType
	#testlink.getPriorities
	#testlink.getTestExecType
	res = testlink.getAllTestAllParams
	testlink.disconnectFromDB()
end

# test()