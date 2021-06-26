---
layout: post
title: "程序链接(Program Linking)"
date: 2020-06-25 15:22:39 -0700
comments: true
categories: 总结积累
---

* list element with functor item
{:toc}

**链接**是将各种代码和数据片段收集并组合成一个单一文件的过程，该文件可以被加载到内存并执行。理解链接的几个好处有：

<!--more-->

* 理解链接器将帮助你构造大型程序。
* 理解链接器将帮助你避免一些危险的编程错误。
* 理解链接器将帮助你理解语言的作用域规则是如何实现的。
* 理解链接器将帮助你理解其他重要的系统概念。
* 理解链接器将使你能够利用共享库

下面会介绍静态链接、加载时的共享库的动态链接、运行时的共享库动态链接等方面。

## 链接示例

通常说的编译程序包括如下四个方面：预处理(cpp)、编译(ccl)、汇编(as)、链接(ld)。比如，有如下 main.c 和 sum.c 两个文件。

```
int sum(int *a, int n);

int array[2] = {1, 2};

int main()
{
    int val = sum(array, 2);
    return val;
}

int sum(int *a, int n)
{
    int i, s = 0;
    
    for (i = 0; i < n; i++) {
        s += a[i];
    }
    
    return s;
}
```

编译命令：
```
$gcc -Og -o prog main.c sum.c 或
$gcc -Og -v -o prog main.c sum.c
```

对上面的源文件进行如下操作:   

main.c--->预处理(cpp)--->main.i--->编译器(ccl)--->main.s--->汇编器(as)--->main.o  
sum.c---->预处理(cpp)--->sum.i---->编译器(ccl)--->sum.s---->汇编器(as)--->sum.o  
main.o + sum.o--->链接器(ld)--->prog

## 静态链接

静态链接以一组可重定位目标文件和命令行参数作为输入，生成一个完全链接的、可以加载和运行可执行目标文件作为输出。

为构造可执行文件，链接器主要完成两项任务：

* **符号解析。** 符号解析的目的是使得目标文件中符号的定义和引用匹配起来。例如引用一个函数名符号时，符号解析的功能就是找到函数的引用和定义，并将其匹配起来。
* **重定位。** 由编译器和汇编器生成的 .code 和 .data 节，都是从地址 0 开始的。链接器通过将每个符号定义为一个与内存关联起来，完成重定位，然后修改所有对这些符号的引用，使得它们指向这个内存位置。

{% codeblock %}
main.o:     file format elf64-x86-64
Disassembly of section .text:

0000000000000000 <main>:
   0:	55                   	push   %rbp
   1:	48 89 e5             	mov    %rsp,%rbp
   4:	48 83 ec 10          	sub    $0x10,%rsp
   8:	be 02 00 00 00       	mov    $0x2,%esi
   d:	48 8d 3d 00 00 00 00 	lea    0x0(%rip),%rdi        # 14 <main+0x14>
  14:	e8 00 00 00 00       	callq  19 <main+0x19>
  19:	89 45 fc             	mov    %eax,-0x4(%rbp)
  1c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  1f:	c9                   	leaveq 
  20:	c3                   	retq   
  
sum.o:     file format elf64-x86-64

Disassembly of section .text:

0000000000000000 <sum>:
   0:	55                   	push   %rbp
   1:	48 89 e5             	mov    %rsp,%rbp
   4:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
   8:	89 75 e4             	mov    %esi,-0x1c(%rbp)
   b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  12:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
  19:	eb 1d                	jmp    38 <sum+0x38>
  1b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  1e:	48 98                	cltq   
  20:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
  27:	00 
  28:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  2c:	48 01 d0             	add    %rdx,%rax
  2f:	8b 00                	mov    (%rax),%eax
  31:	01 45 fc             	add    %eax,-0x4(%rbp)
  34:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
  38:	8b 45 f8             	mov    -0x8(%rbp),%eax
  3b:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  3e:	7c db                	jl     1b <sum+0x1b>
  40:	8b 45 fc             	mov    -0x4(%rbp),%eax
  43:	5d                   	pop    %rbp
  44:	c3                   	retq   
{% endcodeblock %}

上面 text section 是 main.o 和 sum.o 反编译出来的，可以看出，main 函数和 sum 函数都是从地址 0 开始的。将 main.o 和 sum.o 链接生成 prog 可执行文件，反编译可执行文件后，部分 section 如下：

{% codeblock %}
00000000000005fa <main>:
 5fa:	48 83 ec 08          	sub    $0x8,%rsp
 5fe:	be 02 00 00 00       	mov    $0x2,%esi
 603:	48 8d 3d 06 0a 20 00 	lea    0x200a06(%rip),%rdi        # 201010 <array>
 60a:	e8 05 00 00 00       	callq  614 <sum>
 60f:	48 83 c4 08          	add    $0x8,%rsp
 613:	c3                   	retq   

0000000000000614 <sum>:
 614:	b8 00 00 00 00       	mov    $0x0,%eax
 619:	ba 00 00 00 00       	mov    $0x0,%edx
 61e:	eb 09                	jmp    629 <sum+0x15>
 620:	48 63 ca             	movslq %edx,%rcx
 623:	03 04 8f             	add    (%rdi,%rcx,4),%eax
 626:	83 c2 01             	add    $0x1,%edx
 629:	39 f2                	cmp    %esi,%edx
 62b:	7c f3                	jl     620 <sum+0xc>
 62d:	f3 c3                	repz retq 
 62f:	90                   	nop
{% endcodeblock %}

从上面可以看出，可执行文件中的 main 和 sum 的地址已经不再是 0， main 中调用了 sum 的地址为 614,切好就是 sum 的地址。

## 目标文件

目标文件有三种形式：可重定位的目标文件、可执行的目标文件、共享目标文件。

* **可重定位的目标文件** 是包含二进制代码的数据，其可以在编译时与其他可重定位目标文件结合生成可执行文件。
* **可执行目标文件** 包含二进制代码和数据，可直接复制到内存中执行。
* **共享目标文件** 特殊的可重定位目标文件，可以在加载或运行时被动态地加载进内存并链接。

## 可重定位目标文件

| ELF 头  | 描述生成该文件的系统的字的大小和字节顺序，以及包含帮助链接器语法分析和解释目标文件的信息 |
| :----:  | :-----: |
| .text   | 已编译程序的机器代码 |
| .rodata | 只读数据，比如 printf 中的字符串 |
| .data   | 已初始化的全局和静态 C 变量 |
| .bss    | 未初始化的全局和静态 C 变量, 以及所有被初始化为 0 的全局或静态变量 |
| .symtab | 一个符号表，它存放在程序中定义和引用的函数和全局变量的信息 |
| .rel.text | 一个 .text 节中位置的列表，当链接器把这个目标文件和其他文件组合时，需要修改这些位置 |
| .rel.data | 被模块引用或定义的所有全局变量的重定位信息 |
| .debug | 调试符号表，与上面的 symtab 不同，它还包含了局部变量和类型定义，以及原始的 C 源文件 |
| .line  | 原始 C 源程序中的行号和 .text 节中机器指令之间的映射 |
| .strtab| 一个字符串表，包括 .symtab 和 .debug 节中的符号表 |
| 节点头部 | |

给出一个程序示例 obj.c：

```
#include <stdio.h>

int AAA = 3;

int sum(int a, int b)
{
    return a + b;
}

int main(int argc, char **argv)
{
    int a = 0;
    int b = 1;
    int c;

    static int aa = 0;
    static int bb = 1;
    static int cc;

    printf("a %d aa %d b %d bb %d c %d cc %d AAA %d\n", a, aa, b, bb, c, cc, AAA);
    c = sum(AAA, AAA);

    return 0;
}
```

编译该文件 obj.c ：
```
$ gcc -g -c obj.c
$ objdump -D obj.o > obj.txt
```

反编译生成的可重定位目标文件，下面给出几部分

{% codeblock %}
Disassembly of section .data:

0000000000000000 <AAA>:
   0:	03 00                	add    (%rax),%eax
	...

0000000000000004 <bb.2260>:
   4:	01 00                	add    %eax,(%rax)
	...

Disassembly of section .bss:

0000000000000000 <cc.2261>:
   0:	00 00                	add    %al,(%rax)
	...

0000000000000004 <aa.2259>:
   4:	00 00                	add    %al,(%rax)
	...

{% endcodeblock %}

可以看出，`.data` 包含了已初始化的全局变量 AAA、和静态变量 bb。`.bss`包含了未初始化的静态变量 cc 和初始化为零的静态变量 aa。但要注意，对于局部的变量 a、b、c并没有出现在上面的几个节中，因为局部变量在运行时被保护在栈中，既不出现在`.data`节中，也不出现在`.bss` 中。

### 符号和符号表

对于一个可重定位的模块 m 来说，它包含的定义和引用的符号，包含三种类型：
* 由模块 m 定义并能被其他模块引用的全局符号。
* 由其他模块定义并被模块 m 引用的全局符号。
* 只被模块 m 定义和引用的局部符号。

注意，链接器符号和程序变量是不同的，.symtab 中的符号表不包含对应于本地非静态程序变量的任何符号，非静态程序变量符号在运行时在栈中管理，链接器对此类符号不感兴趣，（但带有static 属性的变量除外）。

下面给出符号表的一个示例 m.o 和 swap.o：

```
void swap();

int buf[2] = {1, 2};

int main()
{
    sawp();
    return 0;
}


extern int buf[];

int *bufp0 = &buf[0];
int *bufp1;

void swap()
{
    int temp;

    bufp1 = &buf[1];
    temp  = *bufp0;
    *bufp0 = *bufp1;
    *bufp1 = temp;
}
```

使用 readelf 工具对 swap.o 查看符号表如下:

{% codeblock %}
Symbol table '.symtab' contains 13 entries:
   Num:    Value          Size Type    Bind   Vis      Ndx Name
     0: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 0000000000000000     0 FILE    LOCAL  DEFAULT  ABS swap.c
     2: 0000000000000000     0 SECTION LOCAL  DEFAULT    1 
     3: 0000000000000000     0 SECTION LOCAL  DEFAULT    3 
     4: 0000000000000000     0 SECTION LOCAL  DEFAULT    4 
     5: 0000000000000000     0 SECTION LOCAL  DEFAULT    5 
     6: 0000000000000000     0 SECTION LOCAL  DEFAULT    8 
     7: 0000000000000000     0 SECTION LOCAL  DEFAULT    9 
     8: 0000000000000000     0 SECTION LOCAL  DEFAULT    7 
     9: 0000000000000000     8 OBJECT  GLOBAL DEFAULT    5 bufp0
    10: 0000000000000000     0 NOTYPE  GLOBAL DEFAULT  UND buf
    11: 0000000000000008     8 OBJECT  GLOBAL DEFAULT  COM bufp1
    12: 0000000000000000    63 FUNC    GLOBAL DEFAULT    1 swap
{% endcodeblock %}

从上面可以看出几个符号的解析如下:

| 符号 | .symtab 条目 | 符号类型 | 所属模块 | 节 |
| :---:| :----------: | :------: | :-------:|:---:|
| buf | Yes | extern | m.o | .data |
| bufp0 | Yes | GLOBAL | swap.o | .data |
| bufp1 | Yes | GLOBAL | swap.o | .common |
| swap | Yes | GLOBAL | swap.o | .text |
| temp | No | - | - | - |

### 符号解析

链接器解析符号引用的方法是将每个引用与它输入的可重定位目标文件的符号表中的一个确定的符号定义关联起来。对全局符号的解析，如果多个目标文件中定义相同名字的全局符号，链接器要么给出错误提示，要么以某种方法选出一个定义并抛弃其他定义。

#### 链接器如何解析多重定义的全局符号

编译时，编译器向汇编器输出每个全局符号，或者是强或者是弱，汇编器把这个信息隐含地编码在可重定位目标文件的符号表里。函数和已初始化的全局变量是强符号，未初始化的全局变量是弱符号。链接规则如下：
* 不允许有多个同名的强符号。
* 如果有一个强符号和多个弱符号同名，选择强符号。
* 如果有多个弱符号同名，从中任选一个。

#### 与静态库链接

静态库，将所有相关的目标文件模块打包成一个单独的文件，该文件可以作为链接器的输入，当链接器构造一个输出的可执行文件时，链接器只会复制该文件中被应用程序引用的目标模块，这样的文件称为静态库。

#### 链接器如何使用静态库来解析引用

解析阶段，链接器**从左到右(有序的)**按照它们在编译器驱动程序命令行上出现的顺序来扫描可重定位目标文件和存档文件。链接器会维护三个集合：可重定位目标文件集合E、未解析的符号集合U、已定义的符号集合D。链接器的解析过程如下:

* 对命令行上的每个输入文件 f，链接器判断是否为目标文件或静态库，如果是目标文件，将其添加到E，修改U 和 D，继续解析下一个文件。
* 如果 f 是静态库，链接器尝试匹配 U 中未解析的符号和由存档文件成员定义的符号。匹配成功，将模块添加到E 中，修改 U 和 D。
* 链接器扫描完输入文件后，U 非空，链接器输出一个错误并终止。否则，它会合并和重定位 E 中的目标文件，生成可执行文件。

从链接器解析静态库的原理可以看出，编译时，静态库存放的位置很重要，同样的目标文件和静态库，位置不同，可能编译结果就不同了。

```
$gcc -static ./libvector.a main.c
$gcc -static main.c ./libvector.a
```

### 重定位

链接器完成符号解析后，就把代码中的每个符号和定义关联起来了。现在链接器就可以重定位了，重定位由两步组成：

* 重定位节和符号定义。链接器将所有相同类型的 section 合并成一个新的 section。比如，将所有模块的 .data 合并成一个新的 .data。之后将运行时的内存地址赋给新的 section 以及每个模块的定义。
* 重定位节中的符号引用。链接器修改 .data 和 .text 中对每个符号的引用，使得它们指向正确的运行时地址。

#### 重定位条目

汇编器遇到对最终位置未知的目标引用，会生成一个重定位条目，告知链接器在将目标文件合并成可执行文件时如何修改该引用。代码的重定位条目放在 .rel.text 中，已初始化数据的重定位条目放在 .rel.data 中.

重定位类型有 32 种，最常用的两种是:

* **R_X86_64_P32**，重定位一个使用 32 位 PC  相对地址的引用。比如调用函数常用的 call 指令
* **R_X86_64_32**，重定位一个使用 32 位绝对地址的引用

#### 重定位符号引用
链接器的重定位算法的伪代码如下：
{% codeblock %}
foreach section s {
    foreach relocation entry r {
        refptr = s + r.offset;  /*ptr to reference to be relocated*/
        
        /* Relocate a PC-relative reference */
        if (r.type == R_X86_64_PC32) {
            refaddr = ADDR(s) + r.offset; /* ref's run-time address */
            *refptr = (unsigned)(ADDR(r.symbol) + r.addend - refaddr);
        }
        
        /* Relocate an absolute reference */
        if (r.type == R_X86_64_32) {
            *refptr = (unsigned)(ADDR(r.symbol) + r.addend);
        }
    }
}
{% endcodeblock %}

## 可执行目标文件

可执行目标文件格式类似于可重定位的目标文件格式，稍有不同的是：可执行目标文件有程序的入口点（程序运行时要执行的第一条指令地址）、`.text/.rodata/.data`节已经被重定位到它们最终运行时内存地址、可执行文件已经被重定位所以不需要 `.rel` 节。

加载器会将可执行目标文件中的代码和数据从磁盘复制到内存中，然后跳转到程序的第一条指令或入口点来运行该程序。

## 共享目标文件

静态库需要定期维护和更新，静态库的代码被复制到每个运行进程的文本段中，会极大的浪费内存系统资源。共享库可以解决静态库的问题，共享库是一个目标模块，在运行和加载时，可加载到任意的内存地址，并和内存中的程序连接起来。

动态加载和链接共享库:Linux系统为动态链接器提供了一个简单的接口，允许应用程序在运行时加载和链接共享库。

{% codeblock %}
#include <dlfcn.h>
void *dlopen(const char *filename, int flag);
void *dlsym(void *handle, char *symbol);
int dlclose(void *handle);
const char *dlerror(void);
{% endcodeblock %}


共享库的一个主要目的就是允许多个正在运行的进程共享内存中相同的库代码，从而节约宝贵的内存资源。现代系统以这样一种方式编译共享模块的代码段，使得可以把它们加载到内存的任何位置而无需链接器修改。使用该方法，无限多个进程可以共享一个共享模块的代码段的单一副本。加载而无需重定位的代码称为位置无关吗。

## 处理目标文件的工具
Linux系统中有很多工具可以帮忙处理目标文件。

* **ar** 创建静态库，插入、删除、列出和提取成员。
* **strings** 列出目标文件中所有可打印的字符串。
* **strip** 从目标文件中删除符号表信息。
* **nm** 列出一个目标文件的符号表中定义的符号。
* **size** 列出目标文件中节的名字和大小。
* **readelf** 显示目标文件的完整结构。
* **objdump** 所有二进制工具之母。能够显示目标文件中所有信息，最大作用是反编译 .text 节中的二进制指令。
* **ldd** 列出可执行文件在运行时所需要的共享库。
