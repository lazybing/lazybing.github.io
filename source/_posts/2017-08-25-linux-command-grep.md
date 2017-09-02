---
layout: post
title: "Linux常用命令之Grep "
date: 2017-08-25 22:46:22 -0700
comments: true
categories: 编程工具
---

* list element with functor item
{:toc}

本文主要记录 Linux 中常用命令之一 Grep 的使用方法。
[grep](https://en.wikipedia.org/wiki/Grep) 是个命令行工具，它主要用于搜索文件中与规则表达式的纯文本数据相匹配的行。它是`globally search a regular expression and print`的简写，主要用在类 Unix 系统中。

<!--more-->

## 语法结构

> grep [options] PATTERN [FILES...]

先来总结几个基本的`options`的作用：  

| 选项 | 含义 | 示例 | 备注 |   
| :----: | :----------: | :----------------: | :----: |  
|  --help  |  显示帮助信息 | grep --help | 一般选项 |  
| -V(--version) | 显示版本号信息 | grep -V | 一般选项 |  
| -e pattern | 匹配 pattern 所指的选项，可与`-f file`一起使用 | grep -e "abc" -e "def" test.txt | 匹配选项 |      
| -f file | 从 file 中获取 pattern，每行 | grep -f file test.txt | 匹配选项 |   
| -i(--ignore-case)/-y | 忽略匹配大小写 | grep -i "abc" test.txt | 匹配选项 |  
| -v(--invert-match) | 不匹配 pattern 中的某行 | grep -v "abc" test.txt | 匹配选项 |  
| -w(--word-regexp) | 只匹配全 pattern 字的行 | grep -w "abc" test.txt | 匹配选项 |  
| -x(--line-regexp) | 匹配全 pattern 行 | grep -x "abc" test.txt | 匹配选项 |  
| -c(--count) | 输出匹配的行数 | grep -c "abc" test.txt | 输出格式选项 |   
| -L(--files-without-match) | 输出没有匹配的文件 | grep -L "abc" * | 输出格式选项 |  
| -l(--files-with-matches) | 输出匹配的文件 | grep -l "abc" * | 输出格式选项 |
| -m num(--max-count=num) | 输出匹配的前 num 个 | grep -m 3 "abc" test.txt | 输出格式选项 |  
| -b(--byte-offset) | 每行输出匹配字符在文件中的偏移 | grep -b "abc" test.txt | 输出格式选项 |  
| -H(--with-filename) | 输出匹配的文件名 | grep -H "abc" * | 输出格式选项 |  
| -h(--no-filenmae) | 输出不匹配的文件名 | grep -h "abc" * | 输出格式选项 |   
| -n(--line-number) | 输出匹配所在文件的行号 | grep -n "abc" test.txt | 输出格式选项 |  
| -A num(--after-context=num) | 输出匹配行后的 num 行内容 | grep -A 2 "abc" test.txt | 输出内容选项 |  
| -B num(--before-context=num) | 输出匹配行前的 num 行内容 | grep -B 2 "abc" test.txt | 输出内容选项 |  
| -C num(-num/--context=num) | 输出匹配行前后 num 行的内容 | grep -C 2 "abc" test.txt | 输出内容选项 |  
| -r(--recursive) | 递归搜索目录文件，但不搜索链接文件 | grep -r "abc" ./ | 文件和目录选项 |  
| -R(--dereference-recursive) | 递归搜索所有目录文件，包含链接文件 | grep -R "abc" ./ | 文件和目录选项 |   


除了`options`外，下面记录下`PATTERN`的使用：  

* `.` : 匹配一个字符。  
* `?` : 最多匹配一个字符。  
* `*` : 匹配若干个字符，或者空字符。  
* `^` : 指代匹配字符位于一行的最开始。  
* `$` : 指代匹配字符位于一行的最末尾。    
* `{num}` : 重复匹配 num 次。  
* `{n,}` : 重复匹配至少 n 次。  
* `{,m}` : 重复匹配最多 m 次。    
* `{n,m}` : 重复匹配最少 n 次，最多 m 次。   
* `[   ]` : 包含匹配 [] 内的某个字符，如[a-d]代表'abcd'中的某个。  

## 基础应用

搜索`text.txt`文件中是否包含`abc`的字符串，并提示匹配的行号。  

```
grep -n abc text.txt
```

搜索`text.txt`文件中不包含`abc`字符串的行，并显示出来。
```
grep -ni abc text.txt
```

搜索`text.txt`文件中包含`abc`字符串的行，不区分大小写，并显示出来。
```
grep -nv abc text.txt
```

搜索包含特殊字符的字符串，并显示出来，如搜索`a*b`。  

```
grep -f "a*b" text.txt
```

搜索当前目录下所有文件包含`abc`字符串的行。  

```
grep -r abc *
```

搜索包含`abc`或`aabc`或`aaabc`字符串的行。

```
grep "a\{1,3\}bc" text.txt   
```

边界表示`\b`。

```
grep "\babc" text.txt //搜索起始字段为abc的字符串的行
grep "abc\b" text.txt //搜索结尾字段为abc的字符串的行
grep "\babc\b" text.txt //搜索起始结尾字段为abc的字符串的行，与-w选项相同
```

搜索多个文件，仅仅输出匹配到的文件名。

```
grep -l abc *
```

## 高阶应用

使用`grep`的 OR/AND/NOT 操作。比如想要搜索某个文件中是否含有`abc`或`def`字符串，就会用到 grep 的 OR 操作；想要同时搜索既含有`abc`又含有`def`字符串，就会用到 grep 的 AND 操作；想要搜索不包含`abc`的字符串，就会用到 grep 的 NOT 操作。  

OR 操作方法：  

```
grep "abc\|def" text.txt   //or   
grep -E "abc|def" text.txt //or  
egrep "abc|def" text.txt   //or  
grep -e "abc" -e "def" text.txt  //or  
```

AND 操作方法：  

```
grep -E "pattern1.*pattern2|pattern2.*pattern1" text.txt //and
grep -E "pattern1" text.txt | grep -E "pattern2"  //and
```

NOT 操作方法：  

```
grep -v "pattern1" text.txt
```

## 参考文献

1. [GNU Grep 3.0 - GNU.org](https://www.gnu.org/software/grep/manual/grep.html)
2. [GREP Command Wiki](https://en.wikipedia.org/wiki/Grep)
3. [Linux grep command](https://www.computerhope.com/unix/ugrep.htm)



<!--more-->

