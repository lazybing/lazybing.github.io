---
layout: post
title: "ELF格式分析手册"
date: 2018-03-21 07:30:48 -0700
comments: true
categories: 总结积累
---

* list element with functor item
{:toc}

本文主要记录目标文件是`i386(32位架构、小端序)ELF`文件的加载过程。本文中的所有代码都是 C 风格，所有代码段都会使用最简单的例子。后面可能会扩展到其他类型的 ELF 文件。
<!--more-->

ELF Data Type
====

{% codeblock lang:c %}
#include <stdint.h>
typedef uint16_t Elf32_Half;    //Unsigned half int
typedef uint32_t Elf32_Off;     //Unsigned offset
typedef uint32_t Elf32_Addr;    //Unsigned address
typedef uint32_t Elf32_Word;    //Unsigned int
typedef int32_t  Elf32_Sword;   //Signed int
{% endcodeblock %}

The ELF Header
===

每个 ELF 格式文件都有位于文件开始的头部`Header`。

{% codeblock lang:c %}
#define ELF_NIDENT 16
typedef struct{
    uint8_t     e_ident[ELF_NIDENT];
    Elf32_Half  e_type;
    Elf32_Half  e_machine;
    Elf32_Word  e_version;
    Elf32_Addr  e_entry;
    Elf32_Off   e_phoff;
    Elf32_Off   e_shoff;
    Elf32_Word  e_flags;
    Elf32_Half  e_ehsize;
    Elf32_Half  e_phoff;
    Elf32_Half  e_shoff;
    Elf32_Word  e_flags;
    Elf32_Half  e_ehsize;
    Elf32_Half  e_phentsize;
    Elf32_Half  e_phnum;
    Elf32_Half  e_shentsize;
    Elf32_Half  e_shnum;
    Elf32_Half  e_shstrndx;
}ELF32_Ehdr;
{% endcodeblock %}

{% codeblock lang:c %}
enum Elf_Ident{
    EI_MAG0    = 0, //0x7F
    EI_MAG1    = 1, //‘E’
    EI_MAG2    = 2, //‘L’
    EI_MAG3    = 3, //‘F’
    EI_CLASS   = 4, //Architecture(32/64)
    EI_DATA    = 5,//Byte Order
    EI_VERSION = 6, //ELF Version
    EI_OSABI   = 7, //OS Specific
    EI_ABIVERSION = 8, //OS Specific
    EI_PAD        = 9  //Padding
};

#define ELFMAG0    0x7F   //e_ident[EI_MAG0]
#define ELFMAG1    'E'    //e_ident[EI_MAG1]
#define ELFMAG2    'L'    //e_ident[EI_MAG2]
#define ELFMAG3    'F'    //e_ident[EI_MAG3]

#define ELFDATA2LSB (1)   //Little Endian
#define ELFCLASS32  (1)   //32-bit Architecture
{% endcodeblock %}

{% codeblock lang:c %}
enum Elf_Type{
    ET_NONE    = 0, //Unknown Type
    ET_REL     = 1, //Relocatable File
    ET_EXEC    = 2  //Executable File
};
#define EM_386     (3) //x86 Machine Type
#define EV_CURRENT (1) //ELF Current Version
{% endcodeblock %}

Checking the ELF Header
===

在对`ELF`文件进行加载、链接、重定向或其他操作之前，首先要确保机器是否支持上述的操作。
{% codeblock lang:c %}
bool elf_check_file(Elf32_Ehdr *hdr){
    if(!hdr) return false;
    if(hdr->e_ident[EI_MAG0] != ELFMAG0){
        ERROR("ELF Header EI_MAG0 incorrect.\n"); 
        return false;
    }
    if(hdr->e_ident[EI_MAG1] != ELFMAG1){
        ERROR("ELF Header EI_MAG1 incorrect.\n"); 
        return false;
    }
    if(hdr->e_ident[EI_MAG2] != ELFMAG2){
        ERROR("ELF Header EI_MAG2 incorrect.\n"); 
        return false;
    }
    if(hdr->e_ident[EI_MAG3] != ELFMAG3){
        ERROR("ELF Header EI_MAG2 incorrect.\n"); 
        return false;
    }
    return true;
}
{% endcodeblock %}

{% codeblock lang:c %}
bool elf_check_supported(ELF32_Ehdr *hdr){
    if(!elf_check_file(hdr)){
        ERROR("Invalid ELF File.\n");
        return false;
    }
    if(hdr->e_ident[EI_CLASS] != ELFCLASS32){
        ERROR("Unsupported ELF File Class.\n");
        return false;
    }
    if(hdr->e_ident[EI_DATA] != ELFDATA2LSB){
        ERROR("Unsupported ELF File byte order.\n");
        return false;
    }
    if(hdr->e_machine != EM_386){
        ERROR("Unsupported ELF File target.\n");
        return false;
    }
    if(hdr->e_ident[EI_VERSION] != EV_CURRENT){
        ERROR("Unsupported ELF File version.\n");
        return false;
    }
    if(hdr->e_type != ET_REL && hdr->e_type != ET_EXEC){
        ERROR("Unsupported ELF File type.\n");
        return false;
    }
    return true;
}
{% endcodeblock %}

Loading the ELF File
===


