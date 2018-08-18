---
layout: post
title: "Linux常用命令之sed"
date: 2017-10-01 08:35:06 -0700
comments: true
categories: 编程工具
---

* list element with functor item
{:toc}

`sed`是`stream editor`的简称，它是一种在线编辑器，用于处理一行一行的数据。处理时，首先把待处理的文件内容送到临时缓冲区中，
称为"模式空间"，接着用`sed`命令处理缓冲区中的内容，处理完成后，把缓冲区中的内容送往屏幕，接着处理下一行，不断重复，直至文件末尾。

<!--more-->

假设有文本文件`text`，内容如下：

{% blockquote %}
10 tiny toes
this is that
5 funny 0
one two three
tree twice
new newer
NEW
newer new
NEW new old
{% endblockquote %}

一. 基本用法：

* 将`text`文本中每行第一个小写字母`t`替换为大写字母`T`.  

```
$cat text | sed 's/t/T/'
$sed 's/t/T/' text
```

* 将`text`文本中每行所有的小写字母`t`替换为大写字母`T`.  

```
$sed 's/t/T/g' text
$sed 's/t/T/g' text > new.txt
$sed -i 's/t/T/g' text
```

二、与正则表达式结合

* 如果一行中第一个字符是`t`，就将它替换为`T`，其他字符不变。  

```
sed 's/^t/T/g' text
```

* 如果一行中最后一个字符是`t`，就将它替换为`T`，其他字符不变。  

```
sed 's/t$/T/g' text
```

* 将所有的数字/小写字母、大写字母、所有的字母替换为`*`。 

```
sed 's/[0-9]/*/g' text
sed 's/[a-z]/*/g' text
sed 's/[A-Z]/*/g' text
sed 's/[a-zA-Z]/*/g' text
```

三、同时替换多个字符串

```
sed 's/Twice/None/g' text | sed 's/Three/Two/g'
sed 's/Twice/None/g;s/Three/Two/g' text
sed 's/Twice/None/g;s/Three/Two/g;s/funny/tummy/g' text
```

四、删除最后一个字符串

```
sed ‘s/\w*//’ text
sed ‘s/\w*.//’ text
sed ‘s/\w*$//’ text
sed ‘s/\w*$/bob/’ text
```

五、只显示匹配行的结果

```
sed 's/T/t/g' text
sed -n 's/T/t/g' text
sed -n 's/T/t/pg' text
```

六、忽略大小写的替换

```
sed 's/that/bob/g' text
sed 's/that/bob/Ig' text
```

七、使用脚本文件,

```
sed -f mysedscript text
```

其中的`mysedscript`内容是：
{% blockquote %}
s/T/t/g
s/e/E/g
s/\w*.//
{% endblockquote %}

八、只替换完整的一个单词，使用边界符 

```
sed 's/\bnew\b/old/g' text
```

九、删除匹配行  

```
sed '/new$/D' text
sed '/^new$/D' text
sed '/\bnew\b/D' text
```

十、 替换文件夹内所有文件内容

如果想要替换某个文件夹下所有文件中的某个字符串，该如何操作呢，此时可以使用`sed`命令。例如，
替换`example_folder`文件夹下所有文件中的字符串`orig_str`，替换为`dst_str`，此时可以使用`sed`命令：  

```
sed -i "s/orig_str/dst_str/g" `grep "orig_str" -rl /example_folder`
```

