   	require 'socket'      # Sockets are in standard library
    require 'gserver'
    require 'json'
    require 'rubygems'
    require 'time'
    require './/app//helpers//dbconnector.rb'
    require './/app//helpers//testlink_utils.rb'
    require "interface"
    #require 'marshal'



# класс для получения учения
# класс для получения MDS из репозитория
###### IMPLEMENTS STRATEGY PATTERN ######
#=======================================#
WorkWithMDS = interface {
            required_methods :getMDS

}

# класс получения MDS через worker
class SWorkWithMDSThroughWorker
    def getMDS(_Worker, _Release)
        workerConnection = _Worker.getConnection
        puts "Working with MDS through Worker = [#{_Worker.getName}]"
        # сперва обращаемся к работнику - желательно рабочему
        # и получаем свежее дерево MDS
        jsonMDS = workerConnection.gets
        mds = JSON.parse(jsonMDS)
        puts "Class of mds #{mds.class}"
        puts "Saving MDS hash to DB, release = #{_Release}"
        _Worker.setMDS(mds, _Release)
        # проверяем, есть ли эталонная MDS для этого релиза
        if not MDSUtils.instance.checkEtalonMDS(_Release)
          MDSUtils.updateEtalonMDS(_Release, mds)
        end

        # проверяем, появились ли новые элементы в дереве - если да, то 
        # надо обновить дерево MDS и выстовить старые значения
    end

    def updateMDS(_Worker, _Release)

    end

    implements WorkWithMDS
end


class SWorkWithAllMDSThroughWorker
    def getMDS(_Worker, _Release)

    end

    def updateMDS(_Worker, _Release)

    end

    implements WorkWithMDS
end

# класс получения MDS непосредственно с VCS
class SWorkWithMDSThroughVCS
    def getMDS(_Worker, _Release)
        puts "StrategyTwo"
    end

    def updateMDS(_Worker, _Release)
    end
    implements WorkWithMDS
end

class MDSGetter

        attr_accessor :strategy
        def initialize strategy
                @strategy = strategy
        end
        def getMDS(_Worker, _Release)
                strategy.getMDS(_Worker, _Release)
        end

        def updateMDS(_Worker, _Release)
        end
end

#=======================================#
###### IMPLEMENTS STRATEGY PATTERN ######

#=======================================#
###### MDS UTILS ########################

# класс управляем MDS объектами в БД
# Типичные функции : получить список объектов MDS по заданным параметрам
#                    все. Больше ничего
class MDSUtils
  include Singleton
  # получить MDS, у которых не указан релиз и воркер
  # т.е. те, которые являются пресетами и не привязаны к конкретному стенду
  def getPatternedMDSList
    
  end

  def getPatternedMDSByRelease(_release)
    mdsList = MongoMDSConnector.instance.getAllNamedRelease(_release)
  end

  def getAllOfWorkerByRelease(_release)
    mdsList = MongoMDSConnector.instance.getAllOfWorkerByRelease(_release)
  end

  def updateGentlyRelease(_release, _hash)
    namedMDS = getPatternedMDSByRelease(_release)
    puts "[DEBUG] updateGentlyRelease lenght of array = #{namedMDS.length}"

    if namedMDS.length > 0
      namedMDS.each do |x|
          puts ""
          mds = MDS.new(x["name"], "", _release)
          mds.updateGently(_hash)
      end
    end

    # creating Etalon MDS for release
    updateEtalonMDS(_release, _hash)
  end

  def updateEtalonMDS(_release, _hash)
    puts "[DEBUG] MDSUtils.updateEtalonMDS"
    mds = MDS.new("Etalon_#{_release}", "", _release)
    mds.update(_hash)
  end

  def getEtalonMDS(_release)
    mds = MDS.new("Etalon_#{_release}", "", _release)
    return mds.get
  end

  def checkEtalonMDS(_release)
    mds = MDS.new("Etalon_#{_release}", "", _release)
    return mds.Exists()
  end

  # получить все включенные тесты для заданного релиза в виде дерева
  # включает так же в себя и приориетет и тип запуска
  # позже, возможно, добавлю еще какие нибудь атрибуты
  def getAllEnabledForRelease(_release)
    puts "[DEBUG]MDSUtils.getAllEnabledForRelease(#{_release})"

    namedMDS = getAllOfWorkerByRelease(_release)
    etalonMDS = getEtalonMDS(_release)
    # строим новое дерево по эталонной MDS - включаем все включенные 
    # у всех воркеров с этим релизом 
    # попутно надо записать дубли тестов, их приориетет и переодичность запуска

    # зануляем MDS ку эталонную
    preparedEtalonTree = prepareDBTree(etalonMDS)
    emptyEtalon = generateEmptyEtalonMDS(preparedEtalonTree)
    # проходим для каждой из полученных поименованных MDS по зануленному эталону
    namedMDSPrepared = Array.new()
    if namedMDS.length > 0 
      namedMDS.each do |x|
        namedMDSPrepared.push(prepareDBTree(x["Data"]))
      end
    end

    #puts "[DEBUG]MDSUtils.getAllEnabledForRelease here are etalon mds"
    #puts preparedEtalonTree

    # на выходе у нас будет MDS, где проставленны все включенные тесты для данного релиза
    # с указанием их дублирования
    # создаем вектор, в котором хранятся начальные значения
    enabledVector = Array.new()
    namedMDSPrepared.each do |x|
      enabledVector.push(true)
    end
    treeMdsFromAllWorkers = createTreeCoverage(preparedEtalonTree, namedMDSPrepared, enabledVector)
    # возвращаем 
    result = treeMdsFromAllWorkers

    # TODO : подумать, ведь запуском конктретных машин управляет Python, а не система..
    # пока она не может выбирать, кто когда запустится.. Т.о. даже если у всех воркеров 
    # на определенном релизе покрытие полное - это не значит, что этот воркер будет 
    # участвовать в ночном прогоне

  end

  def generateEmptyEtalonMDS(_etalon)
      # строим дерево
    childItems = Array.new()
    resultTree = Hash.new()

    #puts "[DEBUG] generateEmptyEtalonMDS class of _etalon = #{_etalon.class}"
    if _etalon.class == BSON::OrderedHash
      _etalon["enabled"] = 0
    end
    #puts "[DEBUG] generateEmptyEtalonMDS - class of _etalon = #{_etalon.class}"
    if _etalon.has_key?("TestItem") == true
      if _etalon["TestItem"].class == BSON::OrderedHash
          childItems.push(generateEmptyEtalonMDS(_etalon["TestItem"]))
      else
        count = 0
          _etalon["TestItem"].each do |x|
            childItems.push(generateEmptyEtalonMDS(x))
            count = count + 1
          end
      end
    end

    return resultTree
  end

  # функция для создания дерева, где подсчитывается количество включенных тестов
  def createTreeCoverage(_treeEtalon, _treeCollection, _enabled)
    enabled = Marshal.load(Marshal.dump(_enabled))
    # генерируем параметры дерева
    resultTree = Hash.new()
    resultTree[:name] = _treeEtalon["name"].to_s
    resultTree[:MethodName] = "EmptyForNow"
    resultTree[:UnitName] = "EmptyForNow"
    resultTree[:attr] = "EmptyForNow"
    resultTree[:enableRate] = 0
    resultTree[:enabled] = 0

    ### подсчитываем количество элементов в полученной коллекции тестов
    # переменная, которая хранит количество вклечений
    enableRate = 0
    # переменная которая хранит.. 
    # если родитель выключен, то все потомки выключены
    if _treeCollection.length > 0 
      _treeCollection.each_with_index do |item, index|
        if item["enabled"] == "0" 
          enabled[index] = false
        end
      end
    end
    if _treeCollection.length > 0
      _treeCollection.each_with_index do |item, index|
        if item["enabled"] == "-1" and enabled[index] == true
          resultTree[:enableRate] = resultTree[:enableRate] + 1
        end
      end
    end
    # проставляем в новогенерируемом дереве
    resultTree[:name] = _treeEtalon["name"].to_s
    resultTree[:MethodName] = _treeEtalon["MethodName"]
    resultTree[:UnitName] = _treeEtalon["UnitName"]
    resultTree[:name] = _treeEtalon["name"]

    # строим дерево
    childItems = Array.new()
    # проверяем, есть ли дети
    #puts "[DEBUG] tree etalon = #{_treeEtalon}"
    if _treeEtalon.has_key?("TestItem") == true 
      #тут стоит хак для одного ребенка
      # если мы приходим к ребенку, как к хэшу
      # то его не надо итерировать
      if _treeEtalon["TestItem"].class == Hash or _treeEtalon["TestItem"].class == BSON::OrderedHash
        if _treeEtalon["TestItem"].has_key?("name")
          # если у нас нет детей в этой ноде, то надо передать хэш, где будет 
          # содержаться эта нода из всех MDS
          newMDSHash = Array.new()
          if _treeCollection.length > 0
            _treeCollection.each do |x|
              newMDSHash.push(x["TestItem"])
            end
          end

          childItems.push(createTreeCoverage(_treeEtalon["TestItem"], newMDSHash, enabled))
        else
          puts "[DEBUG] createTreeCoverage 261 - waay too bad - no key 'name'"
        end
      # в противном случае, его надо итерировать
      else
          count = 0
            _treeEtalon["TestItem"].each do |x|
                # теперь нам надо создать хэш, хранящий итерируемых детей из
                # хэша MDS ок
                newMDSHash = Array.new()
                if _treeCollection.length > 0
                  _treeCollection.each do |y| # y - итерируемая MDS, не нода MDS!
                    newMDSHash.push(y["TestItem"][count]) # а вот это уже нода MDS :)
                  end
                end
                childItems.push(createTreeCoverage(x, newMDSHash, enabled))
                count = count + 1
            end
      end
      resultTree[:TestItem] = childItems
    else 
    end

    return resultTree
  end

  def getTreeWIthTestLinkParams(_release)
    puts "MDSUtils.getTreeWIthTestLinkParams(#{_release})"
    # получаем дерево, где содержится включенные тесты
    enabledForRelease = getAllEnabledForRelease(_release)
    # строим хэш данных из TestLink
    testlink = TestLinkUtils.new()
    testlink.connectToDB()
    testlinkHash = testlink.getAllTestAllParams
    testlink.disconnectFromDB()
    # строим дерево, где будут включенные тесты + их параметры из TL
    resultTree = createTreeWithTestlinkParams(enabledForRelease, testlinkHash)
  end

  # процедура делает следующее
  # выставляет у заданного дерева тестов приориетет и время запуска
  def createTreeWithTestlinkParams(_tree, _TestLinkParams)
    # обходим все дерево и ставим там время запуска или приориетет
    resultTree = Hash.new()
    # проставляем в новогенерируемом дереве
    resultTree[:name] = _tree[:name].to_s
    resultTree[:MethodName] = _tree[:MethodName]
    resultTree[:UnitName] = _tree[:UnitName]
    resultTree[:name] = _tree[:name]
    resultTree[:enabled] = _tree[:enabled]

    if _tree.has_key?(:enableRate)
      resultTree[:enableRate] = _tree[:enableRate]
    end
    

    if _tree.has_key?(:UnitName)
      digitalUnitName = /([\d]*_){1,3}[\d]*/.match _tree[:UnitName]
      if _TestLinkParams.has_key?(digitalUnitName.to_s)
        param = Hash.new()
        param[:priority] = _TestLinkParams[digitalUnitName.to_s][:priority]
        param[:exectype] = _TestLinkParams[digitalUnitName.to_s][:exectype]
        resultTree[:param] = param
      else 
        #puts "NO KEY FOR #{digitalUnitName}"
      end
    end

    # строим дерево
    childItems = Array.new()
    if _tree.has_key?(:TestItem)
      if _tree[:TestItem].class == Hash or _tree[:TestItem].class == BSON::OrderedHash
        childItems.push(createTreeWithTestlinkParams(_tree[:TestItem], _TestLinkParams))
      else
        _tree[:TestItem].each do |x|
          childItems.push(createTreeWithTestlinkParams(x, _TestLinkParams))
        end
      end
    resultTree[:TestItem] = childItems
    end
    return resultTree
  end

    # создаеn хэш, где будут лежать наши данные
    # включает в себя только выключенные тесты
    # вида [{name => PriorityName, value => [testName1, testName2, ..., testName3]}, {...}, ...]
  def generateTestCoverage(_release)
    result = Array.new()
    # тут делаем всю херню

    # получаем список всех приориететов
    testlink = TestLinkUtils.new()
    testlink.connectToDB()
    priorities = testlink.getPriorities()
    puts " OLOLO  #{priorities}"
    # создаем хэш, где будут лежать наши данные
    # вида [{name => PriorityName, value => [testName1, testName2, ..., testName3]}, {...}, ...]
    sourceTree = getTreeWIthTestLinkParams(_release)
    priorities.each do |x|
      tempHash = Hash.new()
      tempHash[:name] = x.to_s
      tempHash[:value] = getSwitchedOffTestsByPriority(sourceTree, x.to_s)
      result.push tempHash
    end
    # возвращаем хэщ по приориететам :)
    return result
  end

  def getSwitchedOffTestsByPriority(_tree, _priority)
    # обходим все дерево и ставим там время запуска или приориетет
    result = Array.new()
    # проставляем в новогенерируемом дереве
    if _tree.has_key?(:param)
      if _tree[:param][:priority] == _priority
        if _tree.has_key?(:enableRate)
          if _tree[:enableRate] == 0 
            # засунуть туда тест
            result.push(_tree[:name])
          end
        end
      end
    end

    # строим дерево
    if _tree.has_key?(:TestItem)
      if _tree[:TestItem].class == Hash or _tree[:TestItem].class == BSON::OrderedHash
        temp = getSwitchedOffTestsByPriority(_tree[:TestItem], _priority)
        # нам вернули массив, надо прибавить его к текущему массиву
        result = result + temp
      else
        _tree[:TestItem].each do |x|
          temp = getSwitchedOffTestsByPriority(x, _priority)
          # нам вернули массив, надо прибавить его к текущему массиву
          result = result + temp
        end
      end
    end
    return result
  end


  # создать MDS с заданными ограничениями
  # _priority - приориететы, которые будут включены
  # _execType - тип запуска, который будет включен (ежедневно, раз в месяц, ежегодно, никогда..)
  def createTestPlanByParam(_release, _priority, _execType, _timeLimit)
    # получаем MDS с параметрами TL
    mds = getTreeWIthTestLinkParams(_release)
    # устанавливаем в неё значения
    resultMDS = generateMDSTreeWithRestriction(mds, _priority, _execType, _timeLimit)
    # возвращаем
    return resultMDS
  end

  def generateMDSTreeWithRestriction(_tree, _priority, _execType, _timeLimit)
    # обходим все дерево и ставим там время запуска или приориетет
    resultTree = Hash.new()
    # проставляем в новогенерируемом дереве
    resultTree[:name] = _tree[:name].to_s
    resultTree[:MethodName] = _tree[:MethodName]
    resultTree[:UnitName] = _tree[:UnitName]
    resultTree[:name] = _tree[:name]    
    resultTree[:enabled] = 0
    # проверяем параметры дерева, включить ноду или выключить
    if _tree.has_key?(:param)
      puts "DEBUG 434 - key param presents"
      if _priority.include?(_tree[:param][:priority]) and _execType.include?(_tree[:param][:exectype])
        puts "DEBUG 437 - test will be enabled"
        resultTree[:enabled] = -1
      else
        puts "DEBUG 440 - test will not be enabled"
        puts "test priority = #{_tree[:param][:priority]}"
        puts "test exec type = #{_tree[:param][:exectype]}"
      end
    else
      puts "DEBUG 438 - no key param"
              #param[:priority] = _TestLinkParams[digitalUnitName.to_s][:priority]
              #param[:execTime] = _TestLinkParams[digitalUnitName.to_s][:exectype]
    end
    # строим дерево
    childItems = Array.new()
    if _tree.has_key?(:TestItem)
      if _tree[:TestItem].class == Hash or _tree[:TestItem].class == BSON::OrderedHash
        childItems.push(generateMDSTreeWithRestriction(_tree[:TestItem], _priority, _execType, _timeLimit))
      else
        _tree[:TestItem].each do |x|
          childItems.push(generateMDSTreeWithRestriction(x, _priority, _execType, _timeLimit))
        end
      end
    resultTree[:TestItem] = childItems
    end
    return resultTree
  end

  ##### #### ####
  ##### helpers
  ##### #### ####
  def prepareDBTree(_dbTree)
    # получаем Root Node
    dbTree = _dbTree["Root"]
    dbTree = dbTree["TestItem"]
    # добавляем фиктивный элемент
    dbImprovedTree = Hash.new()
    dbImprovedTree["name"] = "Тестирование ФИКТИВНАЯ ВЕРШИНА"
    dbImprovedTree["enabled"] = "-1"
    # подготавливаем дерево
    childrens = Array.new()
    dbTree.each do |x|
      childrens.push(x)
    end
    dbImprovedTree["TestItem"] = childrens
    return dbImprovedTree
  end

  ##### #### ####
  ##### helpers
  ##### #### ####

end

class MDS
  # MDS id #1 - name
  @name = ""
  # MDS id #2 - worker marker
  @workerName = ""
  # MDS id #3 - release markker 
  @release = ""
  # MB owner??
  @owner = "ownerByDefault"
  # runtime marker - указывает на переодичность 
  @runtimeMarker = nil
  # MDS structure
  @MDSStructure = Hash.new()
  # 

  def initialize(_mdsName, _workerName, _releaseName)
    @name = _mdsName
    @workerName = _workerName
    @release = _releaseName

  end

  # обновляет MDS и сохраняет выставленными тесты
  def updateGently(_newMDS)
    # хэш, где будут хранится все отмеченные группы тестов и тесты 1-го уровня
    # включенные тесты
    enabledTestList = Hash.new()
    # все тесты
    totalTestList = Hash.new()
    # подготовка к работе дерева из базы..
    _treeDB = get()

    _treeNew = _newMDS
    newTreeDB = _treeDB["Root"]
    #puts "_treeDB[Root] class = #{_treeDB["Root"].class}"
    newTreeDB = newTreeDB["TestItem"][0]
    #puts "newTreeDB[TestItem][0] calss = #{newTreeDB.class}"

    count = 0

    if newTreeDB.has_key?("TestItem") == true
        # тут стоит хак для одного потомка, проверяем, что он есть хэш
        puts " tree have TestItem"
      if newTreeDB["TestItem"].class == BSON::OrderedHash
          # жопа, нет у него детей
          puts " tree TEST ITEM IS BSON::OrderedHash"
      else
           newTreeDB["TestItem"].each do |x|
              # включен ли он
              count = count + 1
              if x["enabled"] == "-1"
                enabledTestList[x["name"]] = count
                puts "name of test  = #{x["name"]}"             
              end
              # добавляем во все тесты
              totalTestList[x["name"]] = count
           end
      end
    else
      # тут нет TestItem
    end

    # теперь идем по новой MDS и отмечаем нужные тесты
    # подготавливаем MDS ку

    newTreeWorker = _treeNew["Root"]
    newTreeWorker = newTreeWorker["TestItem"]

    childrens = Array.new()

    # {"Root":{"TestItem":[(в ячейках массива все и содержится)]
    #testGroups = newTreeWorker
    newTreeWorker.each do |testGroups|
      if testGroups.has_key?("TestItem") == true
        if testGroups["TestItem"].class == Hash
          # ну и тут жопа
        else
          count = 0
          testGroups["TestItem"].each do |x|
            count = count + 1
            if enabledTestList.has_key?(x["name"])
              # есть ключ в старой MDS - надо включить и в новой
              x["enabled"] = "-1"
            else
              # иначе - отметить как незапускаемое
              x["enabled"] = "0"
            end
            # теперь надо проверить, является ли этот тест новым для нас

            # теперь надо проверить - не находится ли он
            # посередине включенных тестов

            unless totalTestList.has_key?(x["name"]) 
              # напоролись на новый тест. ололо, плюс один к счетчику
              puts "new туц test name = #{x["name"]}"
              if enabledTestList.has_value?(count-1) and enabledTestList.has_value?(count)
                # значит, надо включить и его!
                x["enabled"] = "-1"
              end
              #count = count -1
            end
          end
          puts "total ammount of tests in new tree = #{count}"
        end
      end

    # теперь сохраняем новое дерево в базу. аххаха!
    end
    # формируем правильное дерево
    testItem = Hash.new()
    testItem[:TestItem] = newTreeWorker
    tree = Hash.new()
    tree[:Root] = testItem


    the_very_updated_MDS = tree
    # сохраняем все говно
    update(the_very_updated_MDS)
    # устанавливаем дату последнего обновления
    MongoMDSConnector.instance.setModificationTime(@name, @workerName, @release, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
  end

  # проверить, есть ли MDS на базе
  def Exists()
    return MongoMDSConnector.instance.checkMdsForExistance(@name, @workerName, @release)
  end

  # обновляет MDS без учета предидущего состояния тестов
  def update(_newMDS)
    MongoMDSConnector.instance.setMds(@name, @workerName, @release, _newMDS)
    # сразу устанавливаем время обновления
    MongoMDSConnector.instance.setModificationTime(@name, @workerName, @release, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
  end

  # получить MDS
  def get()
    puts "[DEBUG] MDS.get() state = [name = #{@name}, workerName = #{@workerName}, release = #{@release}]"
    return MongoMDSConnector.instance.getMds(@name, @workerName, @release)
  end

  # установить релиз
  def setRelease(_release)
    MongoMDSConnector.instance.setRelease(@name, @workerName, @release, _release)
    MongoMDSConnector.instance.setModificationTime(@name, @workerName, @release, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
  end

  # установить воркера
  def setWorkerName(_workerName)
    MongoMDSConnector.instance.setWorker(@name, @workerName, @release, _workerName)
    MongoMDSConnector.instance.setModificationTime(@name, @workerName, @release, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
  end

  # установить имя
  def setName(_name)
    MongoMDSConnector.instance.setName(@name, @workerName, @release, _name)
    MongoMDSConnector.instance.setModificationTime(@name, @workerName, @release, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
  end

end

###### MDS UTILS ########################
#=======================================#


###################################
### CLASS WORKER   -______________-
###################################

class Worker
  #hash for runtime ops
  @runtime = Hash.new()
  #hash for stands 
  @stands = Hash.new()
  # worker name
  @name
  # MDS structure
  @mds = Hash.new()
  # Python storage
  @python

  # system properties
  # tcp connection handler
  @connection = nil
  # something else...

  def initialize(_name)
    @name = _name
  end


  # methods
  def setName(_name)
    @name = _name
  end

  def getName()
    return @name
  end

  def setConnection(_connection)
    @connection = _connection
  end

  def getConnection()
    return @connection
  end

  def setRuntime(_runtimeHash)
    # set runtime in db
    MongoDBConnector.instance.setRunTime(@name, _runtimeHash)

    setRuntimeLastChange((Time.now).strftime("%d.%m.%Y %H:%M:%S"))
  end

  def getRuntime()
    # get runtime in db
    return MongoDBConnector.instance.getRunTime(@name)
  end

  # at this moment list of stands do not stores in db
  # in RAM only
  def setStands(_standsHash)
    # set stands in ...
    @stands = _standsHash
  end

  def getStands()
    # get stands from current instance
    return @stands
  end

  def setMDS(_mdsStructure, _release)
    # устанавливаем MDS используя класс MDS 
    mds = MDS.new("", @name, _release)
    mds.update(_mdsStructure)
    #MongoDBConnector.instance.setMds(@name, _mdsStructure, _release)
    #MongoDBConnector.instance.setMDSLastChange(@name, _release, (Time.now).strftime("%d.%m.%Y %H:%M:%S"))
    #puts "fuck you! its not implemented! Yet"
  end

  def getMDS(_release)
    # получаем MDS используя класс MDS
    mds = MDS.new("", @name, _release)
    mds.get()
    #return MongoDBConnector.instance.getMds(@name, _release)
    #puts "Also fuck you!! its also not implemented Yet."
  end

  def checkMDSExistance(_release)
    # проверим существование MDS на базе через новый класс
    mds = MDS.new("", @name, _release)
    return mds.Exists()
    #return MongoDBConnector.instance.checkMDS(@name, _release)
  end

  def updateMDSGently(_release, _hash)
    puts "[DEBUG] Worker.updateMDSGently(#{@name}, #{_release}, )"
    mds = MDS.new("", @name, _release)
    mds.updateGently(_hash)
  end

  def setPython(_PythonText)
    MongoDBConnector.instance.setPython(@name, _PythonText)
    # also, set the last pytest modification time
    #MongoDBConnector.instance.setPythonLastChange(@name, (Time.now).to_date.strftime("%d.%m.%Y %H:%M:%S"))
    setPythonLastChange((Time.now).strftime("%d.%m.%Y %H:%M:%S"))
  end

  def getPython()
    return MongoDBConnector.instance.getPython(@name)
  end

  # working with change times

  def getPythonLastChange()
    return MongoDBConnector.instance.getPythonLastChange(@name)
  end

  def setPythonLastChange(_lastChangeDate)
    MongoDBConnector.instance.setPythonLastChange(@name, _lastChangeDate)
  end

  def getRuntimeLastChange()
    return MongoDBConnector.instance.getRuntimeLastChange(@name)
  end

  def setRuntimeLastChange(_lastChangeDate)
    MongoDBConnector.instance.setRuntimeLastChange(@name, _lastChangeDate)
  end

  def getMDSLastChange(_release)
    return MongoDBConnector.instance.getMDSLastChange(@name, _release)
  end

  def setMDSLastChange(_release, _lastChangeDate)
    MongoDBConnector.instance.setMDSLastChange(@name, _release, _lastChangeDate)
  end

end

###################################
### CLASS WORKER   _-----^^^^-----_
###################################


class Server < GServer
    def initialize(*args)
      super(*args)
      @@worker_id = -1
      # в хэше храним объекты класса Worker
      @@workerIO = Hash.new()
      @@masterServer = 0

      @@run_time_mess = "2013-06-01 this is time"
      @@release_to_run = "releaseNum 2 release2_3PG"
    end

    def serve(client)
        message = *client.gets.chomp.split
        # проверяем, кто к нам пожаловал
        # здесь ждем воркера
        if (message[0] == "WorkerOnline" )
              # сохраняем ссылку на сессию для ввода/вывода
              workerObj = Worker.new(message[1])
              workerObj.setName(message[1])
              workerObj.setConnection(client)
              @@workerIO[message[1]] = workerObj
              puts "worker connected #{workerObj.getName}"
              workerObj.getConnection.puts "Hello #{workerObj.getName}"
        end
        # здесь ждем процесс сервера
        if (message[0] == "MasterOnline")
            puts "Master Connected!"
            @@masterServer = client
            @@masterServer.puts "Hello Master youre fuck."
        end
        # в этом цикле обрабатываем запросы на получение данных для воркера
        loop{
            message = client.gets.chomp.split
            if (message[0] == "worker_get")
              workerName = message[1]
              command = message[2]

              case command
              when "check_new_job"
                # check here for changed data
                # format - json 
                # checking last change date of python, runtime, mds
                # {"checkData" : [{"python_lastchange": "value"}, {"runtime_lastchange" : "value"}]}
                # 
                puts "Worker [" + workerName + "] asked for job check"
                # здесь нужна проверка на последние изменения..
                # можно даже методом отдельным оформить
                python_lastchange = @@workerIO[workerName].getPythonLastChange
                runtime_lastchange = @@workerIO[workerName].getRuntimeLastChange
                # тут отсылаем результаты воркеру - время последнего обновления времени запуска, питона и MDS
                lastChange = {:lastChange  => {:python_lastchange => python_lastchange, :runtime_lastchange => runtime_lastchange}}
                #puts "MDS LAST CHANGE TIME FOR #{workerName} is #{mds_lastchange}"
                jsonLastChange = lastChange.to_json
                client.puts jsonLastChange
              when "test_run_time"
                  # here i`m finding a run time for the client
                  puts "worker #{workerName} asked for test run time"
                  client.puts @@workerIO[workerName].getRuntime.to_json
              when "python_config"
                  # here i`m finding a releases to be run for the client
                  puts "worker [#{workerName}] asked python config"
                  pyString = @@workerIO[workerName].getPython.force_encoding(Encoding::UTF_8)
                  #puts pyString.force_encoding(Encoding::UTF_8)
                  client.puts pyString
              when "mdsImage"
                # получаем образ MDS
                  release = message[3]
                  puts "Worker [#{workerName}] ask for MDS for release [#{release}]"
                  mdsJson = @@workerIO[workerName].getMDS(release)
                  mdsJson = mdsJson.to_json.force_encoding(Encoding::UTF_8)
                  #puts mdsJson
                  client.puts mdsJson
              # сейчас воркер пытается нам помочь и хочет прислать нам новую структуру MDS
              when "sendMDS"
                # получаем MDS
                  # выбираем стратегию для получения MDS
                  context = MDSGetter.new SWorkWithMDSThroughWorker.new
                  # получаем объект worker
                  worker = @@workerIO[workerName]
                  # получаем релиз
                  release = message[3]
                  puts "Worker [#{worker.getName}] asks for MDS check for [#{release}]"
                  mds = context.getMDS(worker, release)
              when "mdsPresentCheck"
                # проверяем, есть ли MDS
                worker = @@workerIO[workerName]
                release = message[3]
                puts "Checking [#{release}] existance for worker [#{worker}]"
                mdsCheck = worker.checkMDSExistance(release).to_s
                puts "mdsPresentCheck #{mdsCheck}"
                if !worker.checkMDSExistance(release)
                  client.puts "no"
                end
              when "updateMDS"
                # получаем новую MDS и обновляем её у воркера
                  # получаем объект worker
                  worker = @@workerIO[workerName]
                  # получаем релиз
                  release = message[3]
                  puts "Worker [#{worker.getName}] asks to refresh MDS for [#{release}]"
                  # получаем новую MDS
                  workerConnection = worker.getConnection
                  jsonMDS = workerConnection.gets
                  mdsNew = JSON.parse(jsonMDS)
                  # теперь надо обновить MDS у этого релиза...
                  # ебать это сложно..
                  worker.updateMDSGently(release, mdsNew)
                  # обновляем все MDS с именем и с этим релизомм
                  MDSUtils.instance.updateGentlyRelease(release, mdsNew)
                  #oldMds = worker.getMDS(release)
                  #newMDS = _updateMDSGently(oldMds, mdsNew)
                  #worker.setMDS(newMDS, release)
              when "getLastChangeMDS"
                # отправляем последнее обновление MDS у релиза
                  # получаем объект worker;
                  worker = @@workerIO[workerName]
                  # получаем релиз
                  release = message[3]
                  puts "Worker [#{worker.getName}] asks last change of MDS for release [#{release}]"
                  mdsLastChange = worker.getMDSLastChange(release)
                  client.puts mdsLastChange.to_s
              when "checkNewVersion"
                  puts "Worker [#{workerName}] ask for new version"
                  # потом переделать, что бы версия бралась из репозитория..
                  workerVersionMajor = "1"
                  workerVersionMinor = "7"
                  client.puts workerVersionMajor
                  client.gets
                  client.puts workerVersionMinor
              when "getBinariesDirectory"
                  puts "Worker [#{workerName}] ask for new binaries"
                  # здесь выводим данные о том, где лежат новые бинарники
                  worker = @@workerIO[workerName]
                  workerConnection = worker.getConnection
                  #binariesPath = "\\\\test-09\\Project\\Demon\\TestDemon\\TestingForm\\bin\\Debug\\DaemonControl.exe"
                  binariesPath = "\\\\test-09\\Project\\Demon\\DaemonControl.exe.newBin"
                  client.puts binariesPath

                  answer = workerConnection.gets 
                  if answer.include? "Ok"
                    # выводим сообщение, что все хорошо и в консоль и в лог
                    puts "Worker [#{workerName}] successfully downloaded binaries"
                  else
                    # иначе говорим, что все плохо
                    puts "Worker [#{workerName}] failes to update binaries"
                  end
              when "getBinaryReplacementScript"
                  puts "Worker [#{workerName}] ask for binaries replacement script"
                  # это скрипт для подмены бинарников
                  # можно потом переделать на загрузку из ресурса, а не из хардкода
                  binaryReplacementScriptPath = "\\\\test-09\\Project\\Demon\\replacementScript.bat"
                  client.puts binaryReplacementScriptPath
              end
            end
            # нам воркер что то советует сделать..
            if (message[0] == "worker_set")
              workerName = message[1]
              command = message[2]

              case command
              when "set_stands"
                client.puts "waitingForStands"
                standsJson = client.gets
                standsOfWorker = []
                stands = JSON.parse(standsJson)
                standList = stands["data"]["stands"].chomp.split
                puts "Stands of #{workerName} is #{standList}"
                standList.each do |x| 
                  standsOfWorker.push(x)
                end
                @@workerIO[message[1]].setStands(standsOfWorker)
              when "set_run_time"
                puts "worker [#{workerName}] asked whether need to update run time"
                client.puts "waitingForRunTime"
                runtimesJson = client.gets
                runtimes = JSON.parse(runtimesJson) 
                # if number of tasks to run is more than in DB
                # we should update exclusive DB data
                numberOfItemsOnWorker = runtimes["data"].count
                begin
                  numberOfItemsInDB = @@workerIO[workerName].getRuntime.count  
                rescue
                  puts "cant get number of items in DB!"
                  numberOfItemsInDB = 0
                end
                
                # checkin it here
                runtimeHash = []
                runtimes["data"].each do |x|
                  #x.each do |y|
                    #runtimeHash[key] = value
                    runtimeHash.push(x["Key"].to_s => x["Value"].to_s)
                  #end
                end
                if (numberOfItemsInDB < numberOfItemsOnWorker)
                  puts "Saving runtime table for worker [#{workerName}]"
                  @@workerIO[workerName].setRuntime(runtimeHash)
                else
                  puts "No need to update runtime table for [#{workerName}]"
                end
              when "set_python"
                # cheching whether the python is present in DB
                # if python record is empty, then get it from 
                # worker
                pythonText = @@workerIO[workerName].getPython
                puts "worker [#{workerName}] asks whether needs to save Py"
                if(pythonText.empty?)
                  client.puts "sendMePy"
                  puts "Updating python config in DB for [#{workerName}]"
                  pythonTextJson = client.gets
                  pythonText = JSON.parse(pythonTextJson)

                  #puts pythonText.encoding
                  #puts pythonText.encode(Encoding::UTF_8)
                  @@workerIO[workerName].setPython(pythonText["data"]["python"])
                else
                  client.puts "dontSendMePy"
                  puts "No need to update python config in DB for [#{workerName}]"
                end
              when "close_connection"
                # ok lets close connection loop
                puts "Worker [#{workerName}] closed connection;"
                break
              end

            end
            # обрабатываем команды от сервера
            if (message[0] == "master_set")
              #if (client != @@masterServer)
              #  client.puts "Your tcp connection is differ of masters"
              #  client.close
              #  break;
                command = message[1]
                puts "master set command: [#{command}]"
                case command
                when "set_run_time"
                  # тут он принимает невротебенннейшое сообщение о том, что делать
                  run_time_mess = message[2]
                  puts run_time_mess
                  client.puts "ok, set time"
                  # здесь можно записать в базу

                when "set_release"
                  # тут еще более невротебеннейшее сообщение..
                  @@release_to_run = message[2]
                  client.puts "ok, set release"
                  # здесь тоже можно в базу захерачить..
                when "set_mds"
                  # тут он вообще должен сдохнуть от наглости запросившего
                  @@masterServer.puts "ok, set MDS"
                when "get_worker_list"
                  # спросим у мертвого сервера, какие воркеры у нас в сети
                  puts "Web server asks for worker list"
                  workerList = []

                  @@workerIO.keys.sort.each do |x|
                    workerList.push({:value => x[x].to_s, :label => x[x].to_s})
                  end
                  workerList = {:data => workerList}
                  #puts workerList

                  jsonworkerList = workerList.to_json
                  #puts jsonworkerList
                  client.puts jsonworkerList
                  #client.puts workerList.to_s
                when "get_worker_stands"
                  # спросим у теплого сервера, какие у воркера есть стенды
                  workerName = message[2]
                  puts "Web server asks for stand list for [#{workerName}]"
                  standList = []
                  @@workerIO[workerName].getStands.each do |x|
                    standList.push({:value => x, :label => x})
                  end
                  standList = {:data => standList}

                  jsonStandList = standList.to_json
                  client.puts jsonStandList
                  #puts jsonStandList
                
                when "get_test_coverage"
                  release = message[2]
                  testlist = MDSUtils.instance.generateTestCoverage(release)
                  resultHash = Hash.new()
                  resultHash[:dataArray] = testlist
                  client.puts resultHash.to_json

                when "get_priorities"
                  testlink = TestLinkUtils.new()
                  testlink.connectToDB()
                  priorities = testlink.getPriorities()
                  testlink.disconnectFromDB
                  client.puts priorities.to_json
                when "get_exectype"
                  testlink = TestLinkUtils.new()
                  testlink.connectToDB()
                  exectype = testlink.getTestExecType()
                  testlink.disconnectFromDB()
                  client.puts exectype.to_json
                when "close_connection"
                  # ok lets close connection loop
                  puts "Master closed connection;"
                  break
                end
              #end
            end
        }
    end
end


  # пацанская реализация обновления MDS
  # сука, переписать на стратегию с возможностью изменения алгоритма
  def _updateMDSGently(_treeDB, _treeNew)
    # хэш, где будут хранится все отмеченные группы тестов и тесты 1-го уровня
    # включенные тесты
    enabledTestList = Hash.new()
    # все тесты
    totalTestList = Hash.new()

    puts " _updateMDSGently"
    count = 0

    # подготовка к работе дерева из базы..
    newTreeDB = _treeDB["Root"]
    newTreeDB = newTreeDB["TestItem"][0]

    if newTreeDB.has_key?("TestItem") == true
        # тут стоит хак для одного потомка, проверяем, что он есть хэш
        puts " tree have TestItem"
      if newTreeDB["TestItem"].class == BSON::OrderedHash
          # жопа, нет у него детей
          puts " tree TEST ITEM IS BSON::OrderedHash"
      else
        puts " come to array TestItem"
           newTreeDB["TestItem"].each do |x|
              # включен ли он
              count = count + 1
              if x["enabled"] == "-1" 
                enabledTestList[x["name"]] = count
                puts "name of test  = #{x["name"]}"             
              end
              # добавляем во все тесты
              totalTestList[x["name"]] = count
           end
      end
    else
      # тут нет TestItem
    end

    # теперь идем по новой MDS и отмечаем нужные тесты
    # подготавливаем MDS ку

    newTreeWorker = _treeNew["Root"]
    newTreeWorker = newTreeWorker["TestItem"]

    childrens = Array.new()

    # {"Root":{"TestItem":[(в ячейках массива все и содержится)]
    #testGroups = newTreeWorker
    newTreeWorker.each do |testGroups|
      if testGroups.has_key?("TestItem") == true
        if testGroups["TestItem"].class == Hash
          # ну и тут жопа
        else
          count = 0
          testGroups["TestItem"].each do |x|
            count = count + 1
            if enabledTestList.has_key?(x["name"])
              # есть ключ в старой MDS - надо включить и в новой
              x["enabled"] = "-1"
            else
              # иначе - отметить как незапускаемое
              x["enabled"] = "0"
            end
            # теперь надо проверить, является ли этот тест новым для нас

            # теперь надо проверить - не находится ли он
            # посередине включенных тестов

            unless totalTestList.has_key?(x["name"]) 
              # напоролись на новый тест. ололо, плюс один к счетчику
              puts "new туц test name = #{x["name"]}"
              if enabledTestList.has_value?(count-1) and enabledTestList.has_value?(count)
                # значит, надо включить и его!
                x["enabled"] = "-1"
              end
              #count = count -1
            end
          end
          puts "total ammount of tests in new tree = #{count}"
        end
      end

    # теперь сохраняем новое дерево в базу. аххаха!
    end
    # формируем правильное дерево
    testItem = Hash.new()
    testItem[:TestItem] = newTreeWorker
    tree = Hash.new()
    tree[:Root] = testItem
    return tree
  end
 
hostname = '172.20.5.130'
port = 2001

serverNew = Server.new(port, hostname, 1000)

serverNew.audit = true
serverNew.debug = true
serverNew.start
serverNew.join

#### TEST ####
#puts "TESTTESTETS"
#puts MDSUtils.instance.generateTestCoverage("release2_3")
#MDSUtils.instance.createTestPlanByParam("release2_3", ["4", "5"], ["?????????"], 0)