---
layout: post
title: "使用Octopress 搭建个人博客"
date: 2015-05-01 19:47:37 -0700
comments: true
categories: 总结积累
---
* list element with functor item
{:toc}

详细记录使用`Octopress`的搭建和使用过程中遇到的问题。
<!--more-->

##添加图片
在写 blog 的过程中，经常需要用到插入图片。示例如下：

1. 把图片 `meinv.png` copy 到 `source/images`下。

2. 在需要的位置添加代码.

{% codeblock %}
{% img /images/meinvp.png %}
{% endcodeblock %}

{% img /images/meinvping.png %}

更多技巧，请参见 Octopress 官网提供的[技术支持](http://octopress.org/docs/plugins/image-tag/)。

##添加文章目录

文章一旦长了之后，想要找某个点就需要目录来索引。添加文章目录方法：

首先，使用 kramdown 作为 Octopress 作为 Markdown 解析器。

①  在`Gemfile`中添加如下代码.
```
gem 'kramdown'
```

②  端执行如下命令。

```
bundle install
```

③  修改`_config.yml`文件中相关内容如下。

```
markdown: kramdown
kramdown:
    user_coderay: true
    coderay:
        coderay_line_numbers: table
        coderay_css: class
```

其次，在想要插入目录的地方，插入如下代码即可。

```
* list element with functor item
{:toc}
```

再次,在目录前自动添加`本页目录`,修改`sass/custom/_style.scss`,代码如下.

```
#markdown-toc:before{
    content: "本页目录";
    font-weitht: bold;
}
```
最后，为防止显示摘要时出现目录，在`sass/custom/_style.scss`添加代码。

```
.blog-index #markdown-toc{
    display: none;
}
```

##多台Mac上同时使用

### 在新的Mac上创建 ssh key 并添加到 github 中。

创建`ssh-key`。
```
$ ssh-keygen -t rsa -b 4096 -C "libinglimit@gmail.com"
```
把生成的`key`添加到`ssh-agent`中。
```
$ ssh-add ~/.ssh/id_rsa
```
把添加的`key`放到`github`中。

本地重建Octopress仓库。clone`source`分支/`master`分支：
```
$ git clone -b source git@github.com:lazybing/lazybing.github.io octopress
$ cd octopress
$ git clone git @github.com:lazybing/lazybing.github.io _deploy
```
参见 github 官方[帮助文档](https://help.github.com/articles/checking-for-existing-ssh-keys/#platform-mac)。

### 配置环境。

执行以下命令配置环境：
```
$ gem install bundler
$ rbenv rehash    # If you use rbenv, rehash to be able to run the bundle command
$ bundle install
$ rake setup_github_pages 
```

### 使用技巧

及时提交本地修改
```
$ rake generate
$ rake deploy
```
第一条命令会使用本地的修改生成最新的`blog`网站，并且生成的`blog`会存放到`Octopress`根目录下的`public/`目录下；

第二条命令主要做了两件事：

*用`generate`命令生成在`public/`目录下的内容覆盖`_deploy/`目录下内容；

*将`_deploy/`目录下的修改`add` 、 `commit`到`git`，并`push`到`git`的`master`分支。

除此之外，还需要把`source`分支中做到的修改提交到`git`仓库中，执行以下命令：
```
$ git add .
$ git commit -am "Some comment here." 
$ git push origin source  # update the remote source branch 
```
修改前先更新到最新的版本。
```
$ cd octopress
$ git pull origin source  # update the local source branch
$ cd ./_deploy
$ git pull origin master  # update the local master branch
```

参考博文:[让Octopress博客在多台Mac上同时使用](http://foggry.com/blog/2014/04/02/ru-he-pei-zhi-rang-ni-de-octopressbo-ke-zai-duo-tai-macshang-tong-shi-shi-yong/)

