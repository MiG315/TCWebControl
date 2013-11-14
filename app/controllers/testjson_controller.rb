	require 'json'
	include Datadb
class TestjsonController < ApplicationController

	def sendjson
		# входные параметры, все! танцуют локтями
		begindate = params[:begindate]
		enddate = params[:enddate]
		testname = params[:testname]

		# получаем данные из базы
		dbData = Datadb::PerformanceDataSupplier.instance.getTestTimeExecForAllReleases(begindate, enddate, testname)
		# формируем по ним нужный нам json
		
		# 1 - массив data
		#car = {:make => "bmw", :year => "2003"}
		#labels = []
		#data = []
		#dbData.each do |x|
		#	data.push(x[0].to_int)
		#	labels.push(x[1].to_s)
		#end

		#rawarray_labels = { :labels => labels}
		#rawarray_data = { :data => data}
		#rawarray = { :data => [rawarray_labels, rawarray_data]}
		#jsondata = rawarray.to_json
		
		render :text => dbData.to_json
	end
	
	def gettestlist
		dbData = Datadb::PerformanceDataSupplier.instance.getTestList()
		value = []
		
		dbData.each do |x|
			value.push({:value => x[1].to_s, :label => x[0].to_s})
		end

		rawarray = { :data => value}
		jsondata = rawarray.to_json
		render :text => jsondata
	end

	def index

	end

	def testsend
		# входные параметры, все! танцуют локтями
		begindate = params[:begindate]
		enddate = params[:enddate]
		testname = params[:testname]

		# получаем данные из базы
		dbData = Datadb::PerformanceDataSupplier.instance.getTestTimeExec(begindate, enddate, testname, ["release2_4", "release2_3"])
		# формируем по ним нужный нам json
		
		# 1 - массив data
		#car = {:make => "bmw", :year => "2003"}
		labels = []
		data = []
		#dbData.each do |x|
		#	data.push(x[0].to_int)
		#	labels.push(x[1].to_s)
		#end

		#rawarray_labels = { :labels => labels}
		#rawarray_data = { :data => data}
		
		data = 
		{
		        "labels" => ["01.01.2013", "01.01.2014", "01.01.2014", "01.01.2014"],
		        "datasets"=> [
		            {
		                "data" => [30, 40, 15, 43, 64, 22, 44],
		                "releaseName" => "r2_3"
		            },
		            {
		            	"data" => [50, 60, 234, 32, 11, 234, 112, 45],
		            	"releaseName" => "r2_4"
		            }
		        ]
		    }
	
		jsondata = dbData.to_json
		
		render :text => jsondata
	end

end
