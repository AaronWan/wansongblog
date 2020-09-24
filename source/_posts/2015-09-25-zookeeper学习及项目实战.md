---
title: zookeeper学习及项目实践
layout: detail
description: 主要特点及项目中的实践,分布式协调技术
category: [技术]
tags: [java,分布式,zookeeper]
---
>> ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services. 。

    它设计一种新的数据结构——Znode，然后在该数据结构的基础上定义了一些原语，也就是一些关于该数据结构的一些操作。有了这些数据结构和原语还不够，因为我们的ZooKeeper是工作在一个分布式的环境下，我们的服务是通过消息以网络的形式发送给我们的分布式应用程序，所以还需要一个通知机制——Watcher机制。那么总结一下，ZooKeeper所提供的服务主要是通过：数据结构+原语+watcher机制，三个部分来实现的。

## 使用场景下会使用zookeeper

1. 项目中在监控mongodb的oplog来进行同步数据库的变更给别的部门.若想做的多机互备,就需要使用到分布式锁,由一台机器进行对oplog的变化进行同步
2. 项目在定时发送提醒,多台服务器进行周期扫库操作,也同样用到了1中的分布式锁
3. 假设我们有20个搜索引擎的服务器(每个负责总索引中的一部分的搜索任务)和一个总服务器(负责向这20个搜索引擎的服务器发出搜索请求并合并结果集)，一个备用的总服务器(负责当总服务器宕机时替换总服务器)，一个web的cgi(向总服务器发出搜索请求)。搜索引擎的服务器中的15个服务器提供搜索服务，5个服务器正在生成索引。这20个搜索引擎的服务器经常要让正在提供搜索服务的服务器停止提供服务开始生成索引，或生成索引的服务器已经把索引生成完成可以提供搜索服务了。使用Zookeeper可以保证总服务器自动感知有多少提供搜索引擎的服务器并向这些服务器发出搜索请求，当总服务器宕机时自动启用备用的总服务器.---[分布式系统协调 ZooKeeper](https://www.oschina.net/p/zookeeper)

## zookeeper来源是什么?

ZooKeeper是一种为分布式应用所设计的高可用、高性能且一致的开源协调服务，它提供了一项基本服务：分布式锁服务。由于ZooKeeper的开源特性，后来我们的开发者在分布式锁的基础上，摸索了出了其他的使用方法：配置维护、组服务、分布式消息队列、分布式通知/协调等。


## 协议

1. 每个Server在内存中存储了一份数据；
2. Zookeeper启动时，将从实例中选举一个leader（Leader选举算法采用了[Paxos协议](/2016/09/16/Paxos/)；Paxos核心思想：当多数Server写成功，则任务数据写成功。故 Server数目一般为奇数）；
3. Leader负责处理数据更新等操作（[Zab协议](http://blog.jobbole.com/104985/)）；
4. 一个更新操作成功，当且仅当大多数Server在内存中成功修改数据。

## 结构组成

1. Leader 负责进行投票的发起和决议,更新系统状态
2. Learner-->跟随者Follower 用于接收客户请求并向客户端返回结果,在选择中参与投票
3. Learner-->观察者Observer 可以接收客户端连接,将写请求转发给Leader节点,但其不参悟投票过程,只同步Leader的状态.其目的是为了扩展系统,提高读取速度
4. client 请求发起方

## 具体用在哪里

1. 配置管理,一处修改,监听者进行更新
2. 命名服务
3. 分布式锁 即 Leader Election
4. 集群管理
5. 队列管理



## Zookeeper文件系统

   每个子目录项如 NameService 都被称作为znode，和文件系统一样，我们能够自由的增加、删除znode，在一个znode下增加、删除子znode，唯一的不同在于znode是可以存储数据的。
   有四种类型的znode：

1. PERSISTENT-持久化目录节点:客户端与zookeeper断开连接后，该节点依旧存在
2. PERSISTENT_SEQUENTIAL-持久化顺序编号目录节点:客户端与zookeeper断开连接后，该节点依旧存在，只是Zookeeper给该节点名称进行顺序编号
3. EPHEMERAL-临时目录节点:客户端与zookeeper断开连接后，该节点被删除
4. EPHEMERAL_SEQUENTIAL-临时顺序编号目录节点:客户端与zookeeper断开连接后，该节点被删除，只是Zookeeper给该节点名称进行顺序编号

## Zookeeper的特点

1. 最终一致性：为客户端展示同一视图，这是zookeeper最重要的功能。
2. 可靠性：如果消息被到一台服务器接受，那么它将被所有的服务器接受。
3. 实时性：Zookeeper不能保证两个客户端能同时得到刚更新的数据，如果需要最新数据，应该在读数据之前调用sync()接口。
4. 等待无关（wait-free）：慢的或者失效的client不干预快速的client的请求。
5. 原子性：更新只能成功或者失败，没有中间状态。
6. 顺序性：所有Server，同一消息发布顺序一致。


## 场景分析

1. 分布式锁的场景使用


    ```sh
    zkCli.sh -server x.x.x.x:4180

    ls /key

    >[data, leader]
    
    [zk: x.x.x.x:4180(CONNECTED) 6] get /key/leader
    
    cZxid = 0xc1098cd0b0
    ctime = Sun Jul 16 13:10:01 CST 2017
    mZxid = 0xc1098cd0b0
    mtime = Sun Jul 16 13:10:01 CST 2017
    pZxid = 0xc112aec1c0
    cversion = 152
    dataVersion = 0
    aclVersion = 0
    ephemeralOwner = 0x0
    dataLength = 0
    numChildren = 2

    [zk: x.x.x.x:4180(CONNECTED) 7] ls /key/leader
    [_c_7ea9234d-3973-4e1d-8a6a-e2e30062cdc4-latch-0000000076, _c_5444e12a-c7ef-48bb-8ee6-271eea4a1c29-latch-0000000075]
    [zk: x.x.x.x:4180(CONNECTED) 8] get /key/leader/_c_7ea9234d-3973-4e1d-8a6a-e2e30062cdc4-latch-0000000076
    24
    cZxid = 0xc112aec1c0
    ctime = Fri Mar 30 16:58:50 CST 2018
    mZxid = 0xc112aec1c0
    mtime = Fri Mar 30 16:58:50 CST 2018
    pZxid = 0xc112aec1c0
    cversion = 0
    dataVersion = 0
    aclVersion = 0
    ephemeralOwner = 0xd5848ddc5ec71f6
    dataLength = 2
    numChildren = 0

    [zk: x.x.x.x:4180(CONNECTED) 9] get /key/leader/_c_5444e12a-c7ef-48bb-8ee6-271eea4a1c29-latch-0000000075
    5
    cZxid = 0xc1123e0f90
    ctime = Tue Mar 27 10:55:03 CST 2018
    mZxid = 0xc1123e0f90
    mtime = Tue Mar 27 10:55:03 CST 2018
    pZxid = 0xc1123e0f90
    cversion = 0
    dataVersion = 0
    aclVersion = 0
    ephemeralOwner = 0x259977a5b1b3de0
    dataLength = 1
    numChildren = 0
    

    ```



## 经典文章链接

[zookeeper系列](https://segmentfault.com/a/1190000012185902)
[Leader选举](https://blog.csdn.net/gaoshan12345678910/article/details/67638657)
[基本概念](https://www.cnblogs.com/jsStudyjj/p/5360740.html)
















