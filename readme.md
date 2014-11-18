# dopersistenceframework

标签（空格分隔）： 持久化 sqlite objective-c ios

---

##简介
这个框架主要解决苹果开发过程中，数据本地持久化问题。开发初期，选用了sqlite，就一直折腾至今，没有用过coredata，或许它更加好用，不过人总有那么点执着，或者说固执，不是吗？
##方法说明

    - save:                    //保存或更新对象
    - deleteMe;                //删除自身对象
    - pk;                      //得到对象主键，默认为－1
    - queryByPk:               //根据主键查询对象
    + saveObjects:;            //批量保存对象
    + deleteAll;               //级连删除对象
    + deleteByPks:;            //批量删除对象，参数是主键数组
    + allObjects;              //查询所有对象
    #待添加
    + 条件查询
    + 分页查询
    + 保存文件（包括图片，视频等）
##方法使用说明
###一对一关系的对象及普通对象的操作
1，需要持久到本地的类均要继承自`DPDBObject`，例如
`@interface Test : DPDBObject`
2，如果非集合类型(NSSet/NSArray及它们的可变类型)，使用不需要做任何特殊处理，定义`Test`类

    @interface Test : DPDBObject
    @property (nonatomic,strong) NSString *str;
    @property (nonatomic)        NSInteger    aNumber;
    @property (nonatomic)        int          aInt;
    @property (nonatomic)        float        aFloat;
    @property (nonatomic)        double       aDouble;
    @property (nonatomic)        Test1        *t1;
    @end

把Test的实例赋值后保存到本地的做法是

    Test *test = [[Test alloc] init];
    test.str = @"...";
    //......此处省略赋值过程
    //保存到本地
    [test save];
注意`Test`类有个属性是`Test1`类型，它也继承自`DPDBObject`，对于这种一对一关系的对象，可以直接保存，查询时也会自动将相关对象关联起来；另外，目前暂时没有支持`NSDictionary`的保存。
怎样验证是否保存成功，第一种方法是查询所有保存好的对象`[Test allObjects]`，另一种方式是用保存后的`pk`查询，看能否查询到对象`[Test queryByPk:pk]`

###一对多对象的操作
一对多对象的操作需要在初始化对象方法里面做些处理，继续使用`Test`类来说明，在`Test`类里添加一个数组类型的属性
`@property (nonatomic,strong) NSArray  *arr;`
然后在`- init`方法里面加上

    _arr = [[NSArray alloc] init];
    _arr.DPInternalClazz = @"Test1";
    self = [super init];
    if (self) {
        
    }
    return self;
需要说明的是，初始化数组，并给数组设置DPInternalClazz属性，表示数组里面的元素是什么类型，这里的类型是`Test1`，里面的类名是大小写敏感的！

查询和新增的操作和一对一对象的操作一样，这里就不多做解释了。

##总结
总结来的如此突然，还请各位见谅！框架善不完整，目前把主要精力放在框架上，能写出优秀的东西分享给大家才是最重要的。如果在使用过程中发现什么问题，请及时反馈，谢谢！





