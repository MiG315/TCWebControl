require './/app//helpers//Datadb.rb'
require './/app//helpers//dbconnector.rb'
require 'date'

logpareser = Datadb::LogParser.new
# logpareser.uploadDataFromTestRepositoryOnDate("2014-01-02")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-25")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-26")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-27")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-28")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-29")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-31")
# logpareser.uploadDataFromTestRepositoryOnDate("2013-12-30")

logpareser.uploadDataFromTestRepositoryOnCurrentDate()