---
title: sed,awk
layout: detail
description: 工作，运维知识,sed,awk
category:  [扩展知识,linux]
tags: [linux]
---
Linux shell编程从初学到精通 

>最近工作时遇到了一个问题，就是查看进行时，只查看某些进行的进程号，若直接用ps aux|grep sms  这样会得到一大堆的东东，所以同事推荐用awk,同
时也提及了sed。

>这里抽时间对这两个命令做一个总结，仅为个人学习工作所用。

##sed、awk是什么？


    它们是linux\unix系统中的两种功能强大的文本处理工具。

- 有一个sed的编辑器，才有了sed（stream editor）这个名字,它是一个将一系列编辑命令作用于一个文本文件的理想工具。
- 由于创建awk的三个作者名称 是Aho、Weinberger和Kernighan，所以得名为AWK,是一种能够对结构化数据进行操作并产生格式化报表的编程语言。

##sed的使用

###使用场合

- 编辑相对交互式广西编辑器而言太大的文件
- 编辑命令太复杂，在交互式文本编辑器中难以输入的情况
- 对文件扫描一遍，但是需要执行多个编辑函数的情况

sed只对缓冲区中的原始文件的副本进行编辑，并不编辑原始的文件。so，若要保存个性后的文件，压根将输出重定向到另一个文件。如：
    
    sed 'sed command' source-file > target-file

###调用方式
`如何没有指定输入文件sed将从标准输入中接受输入`

- 在shell命令行输入命令调用sed，格式为：
    
    sed [option] 'sed command' 输入文件  
`注意此处为单引号将命令引起来`

- 将sed命令插入脚本文件后，然后通过sed命令调用它，格式为：

    sed [option] -f sed脚本文件 输入文件
    
- 将sed命令插入脚本文件后，最常用的方法是设置该脚本文件为可执行，然后直接执行该脚本，格式为：

    ./sed脚本文件 输入文件
    
`但此命令脚本文件，应该以sha-bang(#!)开头，sha-bang后面是解析这个脚本的程序名。`

####sed命令选项及其意义

- -n:不打印所有行到标准输出
- -e:将下一个字符串解析为sed编辑命令，如果只传递一个编辑命令给sed，-e选项可以省略
- -f:表示正在调用sed脚本文件

###命令组成方式

    定位文本行和编辑命令两部分组成

####定位文本

- 使用行号，指定一行，或指定行号范围
- 使用正则表达式

`下面是sed命令定位文本的方法`

- x 为指定的行号
- x，y 指定行号范围
- /pattern/ 查询包含模式的行
- /pattern/pattern/ 查询包含两个模式的行
- /pattern/，x 从与模式匹配到x号行之间的行  反之类似
- x，y！查询不包括x和y行号的行

####常用编辑命令

- p 打印匹配行
- = 打印文件行号
- a\ 在定位行号之后追加文本信息
- i\ 在定们行号之前插入文本信息
- d 删除定位行
- c\ 用新文本替换定位文本
- s 使用替换模式替换相应模式
- r 从另一个文件中读广西
- w 将文本写入到一个文件
- y 变换字符
- q 第一个模式匹配完成后退出
- l 显示与八进制ASCII码等价的控制字符
- {} 在定位行执行的命令组
- n 读取下一个输入行，用下一个命令处理新的行
- h 将模式缓冲区的文本复制到保持缓冲区
- H 将模式缓冲区的文本追加到保持缓冲区
- x 互换模式缓冲区和保持缓冲区的内容
- g 将保持缓冲区的内容复制到模式缓冲区
- G 将保持缓冲区的内容追加到模式缓冲区


###实例
我们就用下面这个文件内容作为事例参考：

    #!/usr/bin/env python
    import os
    import sys
    
    if __name__ == "__main__":
        os.environ.setdefault("DJANGO_SETTINGS_MODULE", "test.settings")
    
        from django.core.management import execute_from_command_line
    
        execute_from_command_line(sys.argv)

#### -n 选项的使用

- 使用-n 不输出所有的内容  1p 输出第一行


    ➜  linuxstudy  sed -n '1p' manage.py2
    #!/usr/bin/env python
    
- 打印3到6行


    ➜  linuxstudy  sed -n '3,6p' manage.py2
    import sys
    
    if __name__ == "__main__":
        os.environ.setdefault("DJANGO_SETTINGS_MODULE", "test.settings")


- 模式匹配


    ➜  linuxstudy  sed -n '/environ/p' manage.py2
        os.environ.setdefault("DJANGO_SETTINGS_MODULE", "test.settings")
 
#### - e 选项的使用

- 打印行号：
    
    
        ➜  linuxstudy  sed -n '/env/=' manage.py2
        1
        6

    添加e选项：
    
        ➜  linuxstudy  sed -n -e '/env/p' -e '/env/=' manage.py2 
        #!/usr/bin/env python
        1
            os.environ.setdefault("DJANGO_SETTINGS_MODULE", "test.settings")
        6

        `sed不支持多个编辑命令的用法，带多个编辑命令的用法，一般格式为：`
    
        sed [option] -e 编辑命令 -e 编辑命令 ... -e 编辑命令 输入文件
 
        将下面命令操作存放到一个后缀为.sed的文件中，让其可执行
        #!/usr/bin/sed -f 
        /command/a\
        we append a new line


#### sed文本定位
        
- 匹配元字符 $和.


        ➜  linuxstudy  sed -n '/\./p' manage.py2
            os.environ.setdefault("DJANGO_SETTINGS_MODULE", "test.settings")
            from django$.core.management import execute_from_command_line
            execute_from_command_line(sys.argv)
        ➜  linuxstudy  sed -n '/\$/p' manage.py2
            from django$.core.management import execute_from_command_line

- 元字符进行匹配

    
        $在正则中表示行尾，但在这里表示最后一行
        sed的基本命令，可以放在单引号外或内都行，根据自己的习惯
        ➜  linuxstudy  sed  '$p' manage.py2 得取最后一行
        
        ➜  linuxstudy sed  -n '/.*line/p' manage.py2 找出以line结尾的行
        
- ! 符号，表示取反，但是不能用于模式匹配的取反
        
        ➜  linuxstudy  sed -n '2,4!p' manage.py2 不打印2到4行 
        
- 使用行号与关键字匹配限定行范围

        /pattern/,x和x,/pattern/ 这两种形式其实与x,y一样的，只是将x或y代替罢了
        
        ➜  linuxstudy  sed -n '4,/mana/p' manage.py2  得到的是从第四行起到与mana匹配的行的内容
        
        if __name__ == "__main__":
            os.environ.setdefault("DJANGO_SETTINGS_MODULE", "hwbuluo.settings")
        
            from django$.core.management import execute_from_command_line
 
#### sed文本编辑
        
- 插入文本    i\
        
        在匹配行的前端插入
        sed '定位i\text' 文件
        
        修改上面的追加脚本：
        #!/usr/bin/sed -f 
        /command/i\
        we append a new line
        
- 修改文本 modify.sed    c\

        -------------------
        #!/usr/bin/sed -f
        
        /command/c\
        I modify the file.
        -------------------
        
        执行：./modify.sed
        
- 删除文本  d  与追加和插入修改有所不同，这里在后面不需要添加\
 
        sed '1,3d' manage.py2
        
- 替换文本 替换文本与修改文本类似，只是修改是对一整行的个性，替换则是对局部进行修改

        s/被替换的字符串/新字符串/[替换选项]
        
        替换选项及意义：
            g:替换文本中所有出现被替换字符串之处,若不使用此选项，则只替换每行的第一个匹配上的字符串
            p:与-n选项结合，只打印替换行
            w 文件名:表示将输出定向到一个文件
         
        ➜  linuxstudy  sed -n 's/command/============/p' manage.py2 
            from django$.core.management import execute_from_============_line
            execute_from_============_line(sys.argv)
             
        也可以 linuxstudy  sed -n 's/command/============/2p' manage.py2   来替换每行出现的第几个 
        
        
-         
        
        
        
##[awk的使用](http://www.cnblogs.com/chengmo/archive/2010/10/08/1845913.html)

###使用场合
###调用方式
###实例
    
    awk -F ':' 'BEGIN {count=0;} {name[count] = $1;count++;};END {for (i=0;i<NR;i++) print i,name[i]}'   /etc/passwd
    
    0 root
    1 daemon
    2 bin
    3 sys
    4 sync
    5 games
    6 man
    7 lp
    8 mail
    
    ls -l |awk 'BEGIN {size=0;} {size=size+$5;} END{print "[end]size is",size/1024/1024 ,"M"}'
    
    [end]size is 0.098505 M
    





   
