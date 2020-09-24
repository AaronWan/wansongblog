---
title: Django,Mysql,空间数据是通过Google地图和高德地图进行采集的
layout: detail
description: 在做项目时遇到用点+半径的空间查询
category: [方案]
tags: [GIS,python,mysql]
---

##环境

Django,Mysql,空间数据是通过Google地图和高德地图进行采集的

```
$ mysql -V
mysql  Ver 14.14 Distrib 5.6.20, for osx10.9 (x86_64) using  EditLine wrapper
```

##需求描述

mysql中存储了一些地理空间点类型的数，要进行周边查询。

##MySQL空间相关的局限性

[MySQL空间扩展的功能](http://dev.mysql.com/doc/refman/5.6/en/spatial-relation-functions.html)仅支持包络框相关的操作(MySQL称之为最小边框，或简称为 MBR)。也就是说，MySQL符合OGC标准。

>目前,MySQL没有实现Contains,Crosses,Disjoint,Intersects,Overlaps,Touches函数，可以通过MBR来实现同样效果操作。

也就是说，在MySQL进行如contains类似的空间查询时，可以通过bbcontains来实现同样效果的操作。

`注意：`

```
只有MyISAM引擎的MySQL表才真正的支持空间索引(R-trees)。也就是说，当你要使用MySQL提供的空间扩展时，你要在快速查询空间数据和数据的完整性之间做一个选择 － MyISAM的表不支持事务和外键约束。
```


##数据库配置

空间表引擎 Engine:InnoDB

###创建数据库

```
mysql>GRANT ALL PRIVILEGES ON *.* TO project_test@localhost IDENTIFIED BY 'project_test' WITH GRANT OPTION; 
mysql>GRANT ALL PRIVILEGES ON *.* TO project_test@"%" IDENTIFIED BY 'project_test' WITH GRANT OPTION; 
```

- 第一句增加了一个 project_test 用户授权通过本地机（localhost)访问，密码“project_test”。

- 第二句则是授与 project_test 用户从任何其它主机发起的访问（通配符％）。 

###配置数据源

```
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.mysql',
        'NAME': 'project_test',        # Or path to database file if using sqlite3.
        'USER': 'project_test',
        'PASSWORD': 'project_test',
        'HOST': '127.0.0.1',           # Empty for localhost through domain sockets or '127.0.0.1' for localhost through TCP.
        'PORT': '3306',                # Set to empty string for default.
    },
```

##数据模型的构建


```
from django.contrib.gis.db import models as gismodels
class AppPoint(gismodels.Model):
    description = gismodels.TextField(verbose_name=_(u"描述信息"), max_length=500,
                                      blank=True, null=True)

    point = gismodels.PointField(spatial_index=False)

    objects = gismodels.GeoManager()
    
```

## [Django Geographic framework 1.7](https://docs.djangoproject.com/en/1.7/)

[GeoDjango](https://docs.djangoproject.com/en/1.7/ref/contrib/gis/)打算做世界级的地理学Web框架。它的目标是尽可能方便是的利用强大空间数据构建GIS Web 应用。

###GeoQuerySet API

`class GeoQuerySet([model=None])`

####空间查询

正如使用[QuerySet API](https://docs.djangoproject.com/en/1.7/ref/models/querysets/#queryset-api)时一样，在过滤器链([chaining filters](https://docs.djangoproject.com/en/1.7/topics/db/queries/#chaining-filters))上加上GeoQuerySet进行筛选。除了通常的字段([Field lookups](https://docs.djangoproject.com/en/1.7/ref/models/querysets/#field-lookups))查询，它还提供了空间字段[GeometryField](https://docs.djangoproject.com/en/1.7/ref/contrib/gis/model-api/#django.contrib.gis.db.models.GeometryField)的查询。


可以在[这里](https://docs.djangoproject.com/en/1.7/ref/contrib/gis/db-api/#spatial-lookups-intro)查看空间查询介绍

下面Django对不同数据库 空间查询操作支持统计表：

        
        Lookup Type	        PostGIS	Oracle	MySQL [7]	SpatiaLite
        
        bbcontains	        X	            X	         X
        bboverlaps	        X	 	        X	         X
        contained	        X	 	        X	         X
        contains	        X	     X	    X	         X
        contains_properly	X	 	 	 
        coveredby	        X	     X	 	 
        covers	            X	     X	 	 
        crosses	            X	 	 	                 X
        disjoint	        X	     X	    X	         X
        distance_gt	        X	     X	 		         X
        distance_gte    	X	     X	 		         X
        distance_lt	        X	     X	 		         X
        distance_lte       	X	     X	 		         X
        dwithin	            X	     X	 	 
        equals	            X	     X	    X	         X
        exact	            X	     X	    X	         X
        intersects	        X	     X	    X	         X
        overlaps	        X	     X	    X	         X
        relate	            X	     X	    	         X
        same_as            	X	     X	    X	         X
        touches	            X	     X	    X	         X
        within	            X	     X	    X	         X
        left	            X	 	 	 
        right	            X	 	 	 
        overlaps_left   	X	 	 	 
        overlaps_right  	X	 	 	 
        overlaps_above  	X	 	 	 
        overlaps_below  	X	 	 	 
        strictly_above  	X	 	 	 
        strictly_below  	X	 	 	 
    
        
####我这里只关注一下对mysql的空间操作支持

>按我们的需要我们选用 `within`

1. bbcontains
    
    支持：`PostGIS`,`MySQL`,`SpatiaLite`
    
    查询数据库中空间数据的bbox包含在指定的空间bbox内的数据。
   
        数据库         操作  
   
        PostGIS       poly ~ geom
        MySQL         MBRContains(poly,geom)
        SpatiaLite    MbrContains(poly,geom)
    
    
    
        
2. bboverlaps

    支持：`PostGIS`,`MySQL`,`SpatiaLite`
    
    查询数据库中空间数据的bbox与指定的空间bbox相交的数据。
   
        数据库         操作  
   
        PostGIS       poly && geom
        MySQL         MBROverlops(poly,geom)
        SpatiaLite    MbrOverlops(poly,geom)

3. contained

    支持：`PostGIS`,`MySQL`,`SpatiaLite`
    
    查询数据库中空间数据的bbox完全包含指定的空间bbox的数据。
   
        数据库         操作  
   
        PostGIS       poly @ geom
        MySQL         MBRWithin(poly,geom)
        SpatiaLite    MbrWithin(poly,geom)
        
4. contains

    支持：`PostGIS`,`Oracle`,`MySQL`,`SpatiaLite`
    
    Example:
        
        Zipcode.objects.filter(poly__contains=geom)
    
    查询数据库中空间数据包含指定的空间图形的数据。
   
        数据库         操作  
   
        PostGIS       ST_Contains(poly, geom)
        Oracle        SDO_CONTAINS(poly, geom)
        MySQL         MBRContains(poly, geom)
        SpatiaLite    Contains(poly, geom)
        
        
5. disjoint

    支持：`PostGIS`,`Oracle`,`MySQL`,`SpatiaLite`
    
    Example:
        
        Zipcode.objects.filter(poly__disjoint=geom)
    
    查询数据库中与指定的空间图形相离的空间数据。
   
        数据库         操作  
   
        PostGIS       ST_Disjoint(poly, geom)
        Oracle        SDO_GEOM.RELATE(poly, geom)
        MySQL         MBRDisjoint(poly, geom)
        SpatiaLite    Disjoint(poly, geom)
        
6. equals

    支持：`PostGIS`,`Oracle`,`MySQL`,`SpatiaLite`
    
7. exact，same_as

    支持：`PostGIS`,`Oracle`,`MySQL`,`SpatiaLite`

8. intersects

    支持：`PostGIS`,`Oracle`,`MySQL`,`SpatiaLite`
    
    查询数据库中与指定的空间图形相交的空间数据。
    
    Example:
            
            Zipcode.objects.filter(poly__intersects=geom)
        
        
       
            数据库         操作  
       
            PostGIS       ST_Intersects(poly, geom)
            Oracle        SDO_OVERLAPBDYINTERSECT(poly, geom)
            MySQL         MBRIntersects(poly, geom)
            SpatiaLite    Intersects(poly, geom)
            
            
9. overlaps

    支持：`PostGIS`,`Oracle`,`MySQL`,`SpatiaLite`


10. touches

    支持：`PostGIS`,`Oracle`,`MySQL`,`SpatiaLite`
    
    Example:
                
            Zipcode.objects.filter(poly__touches=geom)
            
    查询与指定的空间几何图形相接的数据。
           
            数据库         操作  
       
            PostGIS       ST_Touches(poly, geom)
            Oracle        SDO_TOUCH(poly, geom)
            MySQL         MBRTouches(poly, geom)
            SpatiaLite    Touches(poly, geom)
    
11. within

    支持：`PostGIS`,`Oracle`,`MySQL`,`SpatiaLite`
    
    Example:
                
            Zipcode.objects.filter(poly__within=geom)
            
    查询包含在指定的空间几何图形中的数据。
           
            数据库         操作  
       
            PostGIS       ST_Within(poly, geom)
            Oracle        SDO_INSIDE(poly, geom)
            MySQL         MBRWithin(poly, geom)
            SpatiaLite    Within(poly, geom)


>现在知道了要用 within 来查询数据，另一个问题来了，如何生成半径大小为R中心坐标为(x,y)的geom呢。

####创建空间几何图形

可以通过多种方式创建[GeosGeometry](https://docs.djangoproject.com/en/1.7/ref/contrib/gis/geos/#django.contrib.gis.geos.GEOSGeometry)。第一种方法，就是通过一些参数直接实例化。

*  下面是分别通过WKT,HEX,WKB和GeoJSON方式直接创建 Geometry 的方法：

```python   
    In [30]: pnt = GEOSGeometry('POINT(5 23)')
    
    In [31]: pnt = GEOSGeometry('010100000000000000000014400000000000003740')
    
    In [32]: pnt = GEOSGeometry(buffer('\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x14@\x00\x00\x00\x00\x00\x007@'))
    
    In [33]: pnt = GEOSGeometry('{ "type": "Point", "coordinates": [ 5.000000, 23.000000 ] }') # GeoJSON   
            
```

*  另一种方式就是通过特定类型的空间几何对象的构造器来进行创建该类型的Geometry实例

```
In [34]: from django.contrib.gis.geos import Point

In [35]: pnt = Point(5,23)

In [36]: pnt
Out[36]: <Point object at 0x10735bb50>

```

* 最后一种方法就是通过 [fromstr()](https://docs.djangoproject.com/en/1.7/ref/contrib/gis/geos/#django.contrib.gis.geos.fromstr)和 [fromfile](https://docs.djangoproject.com/en/1.7/ref/contrib/gis/geos/#django.contrib.gis.geos.fromfile) 工厂方法来创建Geometry实例。它们分别接收字符串或文件

```python
In [37]: from django.contrib.gis.geos import fromstr,fromfile

In [38]: pnt = fromstr('POINT(5 23)')

In [39]: pnt = fromfile('/path/to/pnt.wkt')

In [34]: pnt = fromfile(open('/path/to/pnt.wkt'))
```
    


####实现查询周边几何点的功能

>通过上面的学习，在Django中实现mysql数据的周边查询只能通过模糊的查询，
我们这里通过构建一个包络框进行模糊查询：

* 构建一个包络框


```
    from django.contrib.gis.geos import (Polygon,Point)
    
    point = Point(130,39)
    
    buffer=point.buffer(degree)

```


* 进行within查询

```
AppPoint.objects.filter(point__within=buffer)
```


* 问题


这里给的半径通常是米为km，但是这个构建buffer的方法需要的参数是一个度。

    degree=l*180/(math.pi*6371)

##测试方法和数据
```
def get_point(point,r):
    EARTH_R=6378.137
    buffer = point.buffer(r*180/(math.pi*EARTH_R))
    aps=AppPoint.objects.filter(point__within=buffer)
    for ap in aps:
        print ap.point.json,(math.pi*EARTH_R*ap.point.distance(point)/180)
        
```
其中点与点间的距离方法distance在django中解释为：


```
   Returns the distance between the closest points on this Geometry
   and the other. Units will be in those of the coordinate system of
   the Geometry.
```

下面是测试数据：

```
b = [[116.27497,39.95708,2573],
[116.48103,39.96657,4292],
...
[116.13621,39.92686,528],
[116.39494,39.87986,138],
[116.389,39.8799,2151],
[116.4858,39.9361,4709]
]


创建数据：
for b in a:                                   
    AppPoint.objects.create(description=b.count,point=Point(b[0],b[1]))
    
输出结果：
 get_point(Point(116.4,39.8),8)
{ "type": "Point", "coordinates": [ 116.4214, 39.85925 ] } 7.01270604176
{ "type": "Point", "coordinates": [ 116.33663, 39.79076 ] } 7.1289114023
{ "type": "Point", "coordinates": [ 116.43555, 39.80307 ] } 3.97213681829
{ "type": "Point", "coordinates": [ 116.42803, 39.86696 ] } 8.08069287815
{ "type": "Point", "coordinates": [ 116.41776, 39.8526 ] } 6.18016458489
{ "type": "Point", "coordinates": [ 116.41467, 39.86627 ] } 7.5557334976
{ "type": "Point", "coordinates": [ 116.37254, 39.82765 ] } 4.33799658047
{ "type": "Point", "coordinates": [ 116.36128, 39.85648 ] } 7.62292984489
{ "type": "Point", "coordinates": [ 116.41574, 39.80051 ] } 1.75308830872
{ "type": "Point", "coordinates": [ 116.40075, 39.81592 ] } 1.77417182449
{ "type": "Point", "coordinates": [ 116.45339, 39.83341 ] } 7.01111345466
{ "type": "Point", "coordinates": [ 116.39799, 39.84366 ] } 4.86535674431
{ "type": "Point", "coordinates": [ 116.38116, 39.85952 ] } 6.94973919946
{ "type": "Point", "coordinates": [ 116.3385, 39.82914 ] } 7.57577153659
{ "type": "Point", "coordinates": [ 116.3777, 39.86207 ] } 7.34200348969
{ "type": "Point", "coordinates": [ 116.39454, 39.86518 ] } 7.28121719546
{ "type": "Point", "coordinates": [ 116.41095, 39.84127 ] } 4.75311465912
```

##总结

```
    from django.contrib.gis.geos import (Polygon,Point)
    import math
    point = Point(130,39)
    EARTH_R=6378.137
    buffer = point.buffer(r*180/(math.pi*EARTH_R))
    aps=AppPoint.objects.filter(point__within=buffer)

``` 

##新的问题
###上面这种方法得到的是没有排序的结果，目前要进行由近到远进行排序，通过
`SQRT(POW( ABS( X(Location) – X(@center)), 2) + POW(ABS(Y(Location) – Y(@center)), 2))`得到一个大致的距离因子，然后根据这个进行排序。

```
queryset.extra(select={'distance_factor': "SQRT(POWER(ABS(X(point) - "+str(x)+"),2) + POWER(ABS(Y(point) - "+str(y)+"),2))"}).order_by('distance_factor')
```

###在线上遇到了下面的问题：
```
rps[0].point.distance(rps[1].point)
python: GeometryComponentFilter.cpp:35: virtual void geos::geom::GeometryComponentFilter::filter_ro(const geos::geom::Geometry*): Assertion `0' failed.
```
线上直接使用distance时报错。

然后比较了一下python的distance得到的值，其实是和`SQRT(POW( ABS( X(Location) – X(@center)), 2) + POW(ABS(Y(Location) – Y(@center)), 2))`得到的值是一样的。

```
('.....python', 0.0071949078163964595)
('self', 0.0071949078163964595)
```
故处些最终到终心点的距离使用了 `distance_factor` 来代替。



##注意

###[经纬度坐标系采用GCJ-2标准,对于Google,高德地图和腾讯地图可以直接使用](http://wangsheng2008love.blog.163.com/blog/static/78201689201461674727642/)
###地球坐标系 (WGS-84) 到火星坐标系 (GCJ-02) 的转换算法


####下面是通过html5获取坐标，然后转化后的当前我的位置截图
![loading](/images/project/xy_trans_position.png =x400)
####腾讯高德对其转化都有现成的实现

```
        var a = 6378245.0
        var ee = 0.00669342162296594323

        function out_of_china(lat,lon){
            if (lon < 72.004 || lon > 137.8347)
                return true
            if (lat < 0.8293 || lat > 55.8271)
                return true
        }
        function transformlat(x, y) {

            var result = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * Math.sqrt(Math.abs(x))
            result += (20.0 * Math.sin(6.0 * Math.PI * x) + 20.0 * Math.sin(2.0 * Math.PI * x)) * 2.0 / 3.0
            result += (20.0 * Math.sin(Math.PI * y) + 40.0 * Math.sin(Math.PI / 3.0 * y)) * 2.0 / 3.0
            result += (160.0 * Math.sin(Math.PI / 12.0 * y) + 320.0 * Math.sin(Math.PI / 30.0 * y)) * 2.0 / 3.0
            return result
        }
        function transformlon(x, y) {
            var result = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * Math.sqrt(Math.abs(x))
            result += (20.0 * Math.sin(6.0 * Math.PI * x) + 20.0 * Math.sin(2.0 * Math.PI * x)) * 2.0 / 3.0
            result += (20.0 * Math.sin(Math.PI * x) + 40.0 * Math.sin(Math.PI / 3.0 * x)) * 2.0 / 3.0
            result += (150.0 * Math.sin(Math.PI / 12.0 * x) + 300.0 * Math.sin(Math.PI / 30.0 * x)) * 2.0 / 3.0
            return result
        }

        function wgs2gcj(wgslat, wgslon) {
            if (out_of_china(wgslat, wgslon)) {
                return [wgslat, wgslon]
            }
            var lat = transformlat(wgslon - 105.0, wgslat - 35.0)
            var lon = transformlon(wgslon - 105.0, wgslat - 35.0)
            var rad_lat = Math.PI / 180.0 * wgslat
           var  magic = Math.sin(rad_lat)
            magic = 1 - ee * magic * magic
            var sqrt_magic = Math.sqrt(magic)
            lat = (180.0 * lat) / (Math.PI * (a * (1 - ee)) / (magic * sqrt_magic))
            lon = (180.0 * lon) / (Math.PI * a * Math.cos(rad_lat) / sqrt_magic)
            var chnlat = wgslat + lat
            var chnlon = wgslon + lon
            return [chnlat, chnlon]
        }
```

##参考
>0. [JAVSCRIPT Math](http://www.w3school.com.cn/jsref/jsref_obj_math.asp)

>1. [MySQL空间数据库–查询点到多点间的最短路径](http://www.javabloger.com/article/mysql-spatial-database.html)

>2. [W3 Geolocation API Specification](http://www.w3.org/TR/geolocation-API/#position_interface)

>3. [关于百度map和高德map，关于map坐标系](http://wangsheng2008love.blog.163.com/blog/static/78201689201461674727642/)

>4. [iOS 火星坐标相关整理及解决方案汇总](http://it.taocms.org/04/507.htm)
                    
                    
