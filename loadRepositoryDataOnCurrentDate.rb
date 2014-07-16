require './/app//helpers//Datadb.rb'
require './/app//helpers//dbconnector.rb'
require 'date'


# logpareser.uploadDataFromTestRepositoryOnDate("2014-02-20")
# logpareser.uploadDataFromTestRepositoryOnDate("2014-02-21")
# logpareser.uploadDataFromTestRepositoryOnDate("2014-02-22")
# logpareser.uploadDataFromTestRepositoryOnDate("2014-02-23")
# logpareser.uploadDataFromTestRepositoryOnDate("2014-02-24")
# logpareser.uploadDataFromTestRepositoryOnDate("2014-02-25")
# logpareser.uploadDataFromTestRepositoryOnDate("2014-02-26")
# logpareser.uploadDataFromTestRepositoryOnDate("2014-02-27")
# logpareser.uploadDataFromTestRepositoryOnDate("2014-03-05")

# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-28")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-29")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-31")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-30")

#logpareser.uploadDataFromTestRepositoryOnCurrentDate()

def logLoader(startDate, endDate)
	sDate = DateTime.parse(startDate)
	eDate = DateTime.parse(endDate)
	logpareser = Datadb::LogParser.new
	if (sDate <= eDate)
		logpareser.uploadDataFromTestRepositoryOnDate(sDate.to_date.to_s)
		sDate += 1
		logLoader(sDate.to_s, eDate.to_s)
	end
end

logLoader("2014-05-21", "2014-07-26")