require './/app//helpers//Datadb.rb'
require './/app//helpers//dbconnector.rb'
require 'date'

logpareser = Datadb::LogParser.new
#logpareser.uploadDataFromTestRepositoryOnDate("2013-11-09")
#logpareser.uploadDataFromTestRepositoryOnDate("2013-11-10")


logpareser.uploadDataFromTestRepositoryOnCurrentDate()