#
#  Be sure to run `pod spec lint DPDBFramework.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "DPDBFramework"
  s.version      = "0.4.2"
  s.summary      = "面向对象的本地化持久方案，保存用 save，删除用 delete."

  s.description  = <<-DESC
                   #项目简介
框架主要解决苹果开发过程中，数据本地持久化问题。开发初期，选用了sqlite，就一直折腾至今，不爱用`coredata`，或许它更加好用，不过人总有那么点执着，或者说固执，不是吗？废话不多说，开始介绍。
#方法总览

    - save:                    //保存或更新对象
    - deleteMe;                //删除自身对象
    - pk;                      //得到对象主键，默认为－1
    + queryByPk:               //根据主键查询对象
    + saveObjects:;            //批量保存对象
    + deleteAll;               //级连删除对象
    + deleteByPks:;            //批量删除对象，参数是主键数组
    + allObjects;              //查询所有对象
    + (NSArray *)objectsWithPage:(NSInteger)page pageLimit:(NSInteger)pageLimit;    //分页查询
    + (NSArray *)findByCriteria:(NSString *)criteriaString
                       page:(NSInteger)page
                  pageLimit:(NSInteger)pageLimit;  //分页条件查询
    #待添加
    + 保存文件（包括图片，视频等）
#方法使用说明
此部分不一一讲解每个方法，根据实际项目中对象持久经常遇到的两种情况分别说明，无关联对象和有关联对象。
##无关联对象
直接上代码讲解简单明了



    <!-- NoRelationshipObject.h -->
    #import "DPDBObject.h"
    @interface NoRelationshipObject : DPDBObject
    @property (nonatomic,strong)        NSString *desc;
    @property (nonatomic,assign)        NSInteger    aNumber;
    @property (nonatomic,assign)        int          aInt;
    @property (nonatomic,assign)        float        aFloat;
    @property (nonatomic,assign)        double       aDouble;
    @end

上面申明了一个无关联对象，如何保存呢，请看下面


    <!-- lang: cpp -->
    NoRelationshipObject *nrObject = [[NoRelationshipObject alloc] init];
    nrObject.desc = @"这是在测试无关联对象";
    noObject.aInt = 2012;
    // 此处略去其它属性的赋值
    //保存到数据库
    [noObject save];

如何验证数据库中是否保存成功，打开数据库，查看数据库中是否存在此记录。

##一对一关联对象
新建一个类`OneToOneObject`

    <!-- OneToOneObject.h -->
    #import "DPDBObject.h"
    @interface OneToOneObject : DPDBObject
    @property (nonatomic,strong)        NSString *desc;
    @property (nonatomic,strong)        NoRelationshipObject *nrObject;
    @end

按照上面方法，创建一个`NoRelationshipObject `对象`nrObject`，再实例化一个`OneToOneObject`对象`otoObject`

    OneToOneObject *otoObject = [[OneToOneObject alloc] init];
    otoObject.desc = @"这是在测试一对一关联对象";
    otoObject.nrObject = nrObject;
    [otoObject save];
一切如你所料，没有任何意外，如何验证保存成功呢，当然可以在数据库中查找对应的记录是否产生，也可以通过程序检测

    //接上
    NSInteger pk = [otoObject pk];
    OneToOneObject *object = [OneToOneObject queryByPk:pk];
    if(object){
        //可以打断点验证，也可以写代码验证
    }else{
        NSLog(@"验证失败，没有保存成功");
    }
没有任何悬念的结束了，接下来将一对多关系的保存；
##一对多关联对象的保存
前两种情况都比较简单，第三种情况就比较复杂了，想了很多方法，包括动态判断类型，配置文件管理，命名判别等等，最后由于种种问题给pass掉了（如果有兴趣可以留言继续探讨这个问题）
还是直接上代码，新建一个类`OneToManyObject`

    <!-- OneToManyObject.h -->
    #import "DPDBObject.h"
    @interface OneToManyObject : DPDBObject
    @property (nonatomic,strong)        NSString *desc;
    @property (nonatomic,strong)        NSArray  *nrArrs;
    @end

类里面有个集合类型属性，由于无法像JAVA一样显式指定里面的类型，所以在第一次查询的时候不知道如何“包装”得到的数据，所以需要在`OneToManyObject.m`方法里面加上一个类方法`+ (NSDictionary *)collectionTypeInfo;`

    #import "OneToManyObject.h"
    @implementation OneToManyObject
    + (NSDictionary *)collectionTypeInfo
    {
        return
        @{
             @"nrArrs":NSStringFromClass([NoRelationshipObject class])
        };
    }
相信看到代码已经明白是什么意思了，指定集合类型的元素类型，这下我就明白了，原来里面装的是 `NoRelationshipObject`对象，那我就按照`NoRelationshipObject`方法包装。
使用代码如下

    OneToManyObject *otmObject = [[OneToManyObject alloc] init];
    NSMutableArray *objects = [NSMutableArray array];
    for (NSInteger i = 0 ; i < 10 ; i++){
        NoRelationshipObject *nrObject = [[NoRelationshipObject alloc] init];
        nrObject.desc = [NSString stringWithFormat:@"这是在测试无关联对象-%ld",(long)i];
        [objects addObject:nrObject];
    }
    otmObject.nrArrs = objects;
    [otmObject save];
全部搞定，接下来就是验证了，可以参考上面的验证方式进行验证！

#适用的情况
本框架善不完整，有几方面的功能没有实现，

 - 事务支持，整个框架没有涉及到事务处理，如果有这方面业务需要的，要让你们失望了
 - 属性类型修改，对于同一个属性名，有修改属性类型的，暂时没有实现，这个功能后期可能会加入进去
如果对上面两个需求不是很强烈的，可以尝试下哟，有问题欢迎一起探讨！！

#参考&致谢
这个是很重要滴，喝水不忘挖井人，框架的灵感来自sqliteobjectpersistence，从一行一行读里面代码学到了很多东西，它里面的某些功能至今也没有实现，不过对里面频繁计算部分做了优化，用了缓存换取CPU计算，带来了时间上的优势，再次感谢sqliteobjectpersistence作者。
                   DESC

  s.homepage     = "http://my.oschina.net/juwenz/blog"
  s.license      = "MIT"
  s.author             = { "juwenz" => "juwenz@icloud.com" }
  s.platform     = :ios, "5.0"


  s.source       = { :git => "https://git.oschina.net/juwenz/DoPersistenceFramework.git", :tag => s.version }

  s.source_files  = "Classes", "DoPersistenceFramework/Classes/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"


  # s.library   = "iconv"
  s.libraries = "sqlite3", "z"
  # s.requires_arc = true

end
