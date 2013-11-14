module Datadb

	require 'sqlite3'
	require 'singleton'
	require 'csv'

# DBConnector =========== begin ============== DBConnnector
# класс для подключения к базе данных, создан в виде одиночки
# пока работет только с SQLite
class DBConnector
  include Singleton

	def initialize
		begin
			@database = SQLite3::Database.open( "db\\newdb.db" )
		rescue
			puts "No DB with Name 'newdb.db' are available"
		end
		# setting up necessary preconditions
		@database.execute "pragma foreign_keys = 1"
	end

	def closeDB
		@database.close
	end

	# далее процедуры для обращения к БД
	def selectTestsOnDate(_date)
		dateId = @database.get_first_row "select id from Date where Date = ?", _date
		return dateId
	end

	def checkDateInBase(_date)
		stm = @database.execute "SELECT * from Date Where Date = ?", _date
		if stm.length == 0
			return false
		else
			return true
		end
	end

	def checkTestExistanceAtDate(_testRepositoryName, _date, _releaseName)
		stm = @database.execute "Select * from Test inner join
										TestList on TestList.id = Test.TestListId inner join
										Date on Date.id = Test.DateKey inner join
										Release on Release.Id = Test.ReleaseId where
											Date.Date = ? and TestList.TestDataRepository = ? and
											Release.RepositoryName = ?", _date, _testRepositoryName, _releaseName
		if stm.length == 0
			return false
		else
			return true
		end
	end

	def addNewDate(_date)
		@database.execute "Insert into Date(Date) values(?)", _date
	end

	def addCurrentDate()
		@database.execute "Insert into Date(date) values(date('now'))"
	end

	def getCurrentLogRepository
		return @database.execute "SELECT RepositoryPath from settings rows 1"
	end

	def checkTestListExistanceInDB(_testRepositoryName)
		stm = @database.execute "Select * from TestList where TestDataRepository = ?", _testRepositoryName
		if stm.length == 0
			return false
		else
			return true
		end
	end

	# create new test with name at given date
	def createNewTestRow(_repositoryName, _execTime, _releaseName, _date)
		testListId = @database.get_first_row  "select id from TestList where TestDataRepository = ?", _repositoryName
		puts "Im in createNewTestRow, date is #{_date}, release name is #{_releaseName}"
		dateId = @database.get_first_row "select id from Date where Date = ?", _date
		puts "Im in createNewTestRow, dateId = " + dateId[0].to_s + " @ date "+ _date
		releaseId = @database.get_first_row "select id from Release where RepositoryName = ?", _releaseName
		puts "Im in createNewTestRow, selected release id is #{releaseId} @ name #{_releaseName}"
		@database.execute "Insert into Test(TestExecTime, DateKey, TestlistId, ReleaseId) values (?, ?, ?, ?)", _execTime, dateId, testListId, releaseId
		return @database.last_insert_row_id
	end

	def createNewTestOpRow(_repositoryName, _execTime, _testId)
		testOperationsListId = @database.get_first_row "select OperationList.id from OperationList inner join 
																TestList on OperationList.TestListId = TestList.Id inner join
																Test on TestList.Id = Test.TestListId
																 where Test.Id = ? and OperationList.RepositoryName =?",
																 _testId, _repositoryName
		@database.execute "Insert into TestOperations(TestExecTime, TestId, OperationListId) values(?, ?, ?)", 
				_execTime, _testId, testOperationsListId
	end

	def createNewOperationRow(_name, _repositoryName, _testListId)
		@database.execute "Insert into OperationList(Name, RepositoryName, testListId) values (?, ?, ?)",
				_name, _repositoryName, _testListId
	end

	def getTestListId(_repositoryName)
		testListId = @database.execute "select id from TestList where TestDataRepository = ?",
		_repositoryName
		return testListId
	end

	def createNewTestListRow(_name, _testSuiteName, _testDataRepository)
		@database.execute "Insert into TestList(Name, TestSuiteName, TestDataRepository) values(?, ?, ?)", 
		_name, _testSuiteName, _testDataRepository
	end

	def checkReleaseExistanceInDB(_releaseName)
		stm = @database.execute "Select * from Release where RepositoryName = ?", _releaseName
		if stm.length == 0
			return false
		else
			return true
		end
	end

	# процедуры на выборку данных из БД
	def getTestTimeExec(_beginDate, _endDate, _testRepositoryName, _releaseName)
		return @database.execute "select Test.TestExecTime, Date.Date from Test inner join
										Date on Test.DateKey = Date.Id inner join 
										   TestList on Test.TestListId = TestList.Id  inner join
										     Release on Test.ReleaseId = Release.Id 
										  where Date.Date >= ? and
										   Date.Date <= ? and 
										    TestList.TestDataRepository = ? and
										     Release.RepositoryName = ?
										  order by Date", 
										  _beginDate, _endDate, _testRepositoryName, _releaseName
	end

	# получить данные о релизах из базы
	def getReleases()
		return @database.execute "select Name, RepositoryName from Release"
	end

	def getTestList
		return @database.execute "select Name, TestDataRepository from TestList order by displayOrder"
	end
end
# DBConnector ========== end ================  DBConnector


class LogParser
	@currentRepository = ""
	#@currentDBConnection = DBConnector.new

	def initialize
		# initialize current repository path
		@currentRepository = self.getCurrentLogRepository()
		# initialize current date
		@currentDate = getCurrentDate
		# initialize DBConnector
		#@currentDBConnection = DBConnector.instance.@database
	end

	public
	def uploadDataFromTestRepositoryOnCurrentDate()
		# get current date
		currentDate = getCurrentDate()
		uploadDataFromTestRepository(currentDate)
	end

	public
	def uploadDataFromTestRepositoryOnDate(_date)
		uploadDataFromTestRepository(_date)
	end

	public
	def uploadDataFromTestRepository(_date)
		# get current date
		if not DBConnector.instance.checkDateInBase(_date)
			puts "Current date not found in DB, adding new date."
			puts "date is " + _date
			DBConnector.instance.addNewDate(_date)
		else
			puts "Current date found in DB, adding test"
		end
		# get tests in repository
		testsPath = getTestsOnCurrentDate(_date)
		uploadTests(testsPath, _date)
	end

	public
	def getCurrentLogRepository()
		#DBConnector.instance.getCurrentLogRepository() - after implementation of DBs
		return ("\\\\softpdc\\usrdata\\TestLogs" + "\\" + (Time.now).to_date.strftime("%m.%Y") + "\\" +
					 (Time.now).to_date.strftime("%d.%m.%Y"))
	end

	public
	def getCurrentLogRepositoryOnDate(_date)
		date = Date.parse(_date)
		return ("\\\\softpdc\\usrdata\\TestLogs" + "\\" + (date).to_date.strftime("%m.%Y") + "\\" +
					 (date).to_date.strftime("%d.%m.%Y"))
	end

	def uploadListOfTestOperationsFromFile()
		currentDate = getCurrentDate()
		array = getTestsOnCurrentDate(currentDate)
		array.each do |x|
			testRepositoryName = x[0]
			testRepositoryPath= x[1]
			releaseName = x[3]
			puts "test repository path = " + testRepositoryPath
			_CVSfilename = findFirstPerformanceCSV(testRepositoryPath, testRepositoryName)
			puts "CVS filename = " + _CVSfilename
			testFileData = testRepositoryPath + "\\" + _CVSfilename
			puts testFileData
			CSV.foreach(testFileData) do |row|
				repositoryOperationName = row[0]
				# createNewOperationRow(_name, _repositoryName, _testListId)
				# getTestListId(_repositoryName)
				testListId = DBConnector.instance.getTestListId(testRepositoryName)
				if testListId.length == 0
					raise "No test with name " + testRepositoryName + " are found."
				end
				repositoryName = row[0]
				DBConnector.instance.createNewOperationRow(repositoryOperationName, repositoryOperationName, testListId)
			end
		end
	end

	def readDataFromFile(_fileRepository)
		# 
	end

	def isThereTestsOnDate(_date)
		# 
	end

	def getTestExecTime(_repositoryPath)
		totalTime = 0
		CSV.foreach(_repositoryPath) do |row|
			begin
				totalTime +=row[1].to_i
			rescue 
				puts "Error in LogParser.getTestExecTime! while parsing csv file"
			ensure 
			end
		end
		return totalTime
	end

	def uploadTests(_testPath, _date)
		# now looking through all paths
		_testPath.each do |x|
			testRepositoryName = x[0]
			pathToTest =x[1]
			releaseName = x[2]
			if not DBConnector.instance.checkTestListExistanceInDB(testRepositoryName)
				puts "Test with name: '" + testRepositoryName + "' not found in TestList table."
				puts "Skipping this test data file."
				next
			end
			if DBConnector.instance.checkTestExistanceAtDate(testRepositoryName, _date, releaseName)
				puts "Test with name: '" + testRepositoryName + "' already loaded in DB at date:" + _date
				puts "Skipping this test data file."
				next
			end
			if not DBConnector.instance.checkReleaseExistanceInDB(releaseName)
				puts "Release with name: '#{releaseName}' at test '#{testRepositoryName}' not found in DB."
				puts "Skipping this test data file."
				next
			end
			_CVSfilename = findFirstPerformanceCSV(pathToTest, testRepositoryName)
			puts "_CVSfilename = " + _CVSfilename
			fullPathToTest = pathToTest + "\\" + _CVSfilename
			puts "adding test with rep name == [#{testRepositoryName}], release = [#{releaseName}]" 
			# create new test record
			testExecTime = getTestExecTime(fullPathToTest)
			testId = DBConnector.instance.createNewTestRow(testRepositoryName, testExecTime, releaseName, _date)
			# upload test operations
			uploadTestOperations(fullPathToTest, testId)
		end
	end

	private
	def getCurrentDate()
		return (Time.now).to_date.to_s
	end

	private
	def uploadTestOperations(_testRepositoryPath, _testId)
		CSV.foreach(_testRepositoryPath) do |row|
			repositoryName = row[0]
			execTime = row[1]
			if execTime == nil
				execTime = "0"
			end
			puts "exec time for " + repositoryName + " == " + execTime
			#puts row
			# createNewTestOpRow(_repositoryName, _execTime, _testId)
			DBConnector.instance.createNewTestOpRow(repositoryName, execTime, _testId)
		end
	end

	private
	def getTestsOnCurrentDate(_date)
		# array
		arr = []
		# collecting all test paths
		currentRepository = getCurrentLogRepositoryOnDate(_date)
		Dir.foreach(currentRepository) do  |f|
			# we found release path
			if (f.to_s.include? "Performance") and (f.to_s.include? "release")
				releaseName = f[f.to_s.index("release"), f.length]
				puts "getTestsOnCurrentDate, release name = #{releaseName}"
				puts "we are in #{f}"
				Dir.foreach(currentRepository + "\\" + f) do |f_release|
					if f_release.to_s.include? "Performance"
						puts ".. #{f_release}"
						arrInArr = []
						arrInArr.push(f_release.to_s) # pushing dir name
						arrInArr.push(currentRepository + "\\" + f.to_s + "\\" + f_release.to_s) # pushing full route
						arrInArr.push(releaseName) # pushing name of release
						arr.push(arrInArr) # pushing values into resulting array
					end
				end
			end
		end
		return arr
		#
	end

	private 
	def findFirstPerformanceCSV(_dir, _testRepositoryName)
		Dir.foreach(_dir) do |x|
			puts x.to_s
			if x.to_s.include? _testRepositoryName + "@"
				return x
			end
		end
		raise "File with 'Performance' not found! Check it for existance."
	end

	private
	def saveToDb(_date, _test, _testOperations)

	end
end

# CVSparser ============= end ==============  CVSparser


# PerformanceDataSupplier ==== begin ==== PerformanceDataSupplier 

class PerformanceDataSupplier
	include Singleton
	def initialize
		# initialize current date
		#@currentDate = getCurrentDate
	end

	def getTestTimeExec( _beginDate, _endDate, _testRepositoryName, _Releases)
		# creating array that contains all data from db
		# each data presentings [[TimeOfExec1, DateOfExec1], [TimeOfExec2, DateOfExec2]]
		dataFromDB = []

		_Releases.each do |x|
			#puts x
			#puts "Ho ho " + DBConnector.instance.getTestTimeExec(_beginDate, _endDate, _testRepositoryName, x).to_s
			dataFromDB.push([DBConnector.instance.getTestTimeExec(_beginDate, _endDate, _testRepositoryName, x), x])
		end
		# creating hash to search in
		allDatesHash = Hash.new
		# filling that hash with all date from all arrays
		dataFromDB.each do |x|
			#puts x[0].to_s
			x[0].each do |z|
				allDatesHash[z[1]] = z[1]
			end
		end
		#puts "Here are all hash #{allDatesHash}"
		allDatesHash.keys.sort

		# now creating ..
		# array of labels
		labels = []
		allDatesHash.each do |key, value|
			labels.push(key)
		end
		labels.sort! {|x,y| x <=> y}
		puts "Here are all labels: #{labels}"
		# array of "datasets"
		# consists of "data" and "releaseName"
		datasets = []
		# to sort 
		dataFromDB.each do |x| # each Release
			data = []
			xflat = x.flatten
			puts "flatten array for release #{x[1]} : #{xflat}"
			labels.each do |y| # for each item in dates
				if (xflat.index(y)) 
						# заносим данные о времени выполнения
						# dataArrayX.push(z[0])
						data.push([xflat[xflat.index(y)-1], y])
					else
						# данных нет, нужно занести ноль
						# dataArrayX.push(0)
						data.push([0, y])
				end
			end
			# sorting data array and remove the "date" element (it have index 1)
			data.sort! {|a,b| a[1] <=> b[1]}
			puts "there are data for #{x[1]}"
			puts data
			# ok, the data is sorted, lets get rid of "date" element
			tempDate = []
			data.each do |x|
				tempDate.push(x[0])
			end
			# pushing into dataset`s element release name
			# releaseName = x[1]
			releaseName = x[1]
			# datasets.push({:data => dataArrayX, :releaseName => releaseName})
			datasets.push({:data => tempDate, :releaseName => releaseName})
		end
		# creating final resulting array
		result = Hash.new
		result[:labels] = labels # ({:labels => labels, :datasets => datasets})
		result[:datasets] = datasets
		return result
	end


	def getTestList()
		result = DBConnector.instance.getTestList()
		return result
	end

	def getReleaseList()
		result = DBConnector.instance.getReleases
		return result
	end

	def getTestTimeExecForAllReleases(_beginDate, _endDate, _testRepositoryName)
		allRelease = getReleaseList
		resRelease = []
		allRelease.each do |x|
			resRelease.push(x[1])
		end
		#puts resRelease.to_s
		result = getTestTimeExec(_beginDate, _endDate, _testRepositoryName, resRelease)
		#puts result
	end

end

# PerformanceDataSupplier ==== end ==== PerformanceDataSupplier 

end
