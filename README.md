#### A sample of Docker & Jenkins & Node Express

#### 一、安装docker

参考 https://www.cnblogs.com/yufeng218/p/8370670.html

#### 二、利用docker安装jenkins

1、拉取jenkins镜像，拉取之前可先查询jenkins镜像列表

```shell
$ docker search jenkins
```
![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba51d6bc508e?w=952&h=339&f=png&s=12588)

2、这里我们就用jenkins官方镜像(第一个DESCRIPTION为OFFICLIAL )

```shell
$ docker pull jenkins:latest
```

3、启动jenkins容器

```shell
$ sudo docker run -d --name myjenkins --user=root -p 32771:8080 -v /var/jenkins_home:/var/jenkins_home jenkins:latest
# -d 表示后台运行容器
# --name myjenkins 表示容器别名
# --user=root 表示以root身份执行(很重要，原因是保证容器挂载到宿主机时创建的目录拥有读写权限，当然也可以用chmod命令给文件目录分配权限)
# -p 表示把容器的8080端口映射到宿主机的32771端口
# -v 表示把容器的/var/jenkins_home文件目录挂载到宿主机的/var/jenkins_home目录下
# jenkins:latest 表示运行容器的基础镜像
```

> 确保服务器32771端口可访问

#### 三、配置jenkins

1、浏览器访问jenkins，地址为 宿主机ip:32771，会看到
![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba5d626ab3c5?w=1216&h=508&f=png&s=179368)

2、访问jenkins需要初始密钥，此密钥可用命令docker logs 查看，亦可在/var/jenkins_home/secrets/
initialAdminPassword文件中查看

3、点击右下角Continue，在Customize Jenkins页面选择Install suggested plugins，下载推荐插件，有些下载失败不必在意
![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba6307d30ce9?w=1146&h=538&f=png&s=206065)
4、完成后Continue，Create First Admin User页面设置admin用户（记住下次登陆时，用户名和密码并不
是现在设置的，而是admin和第1步中的密钥，我们在/var/jenkins_home/users下可以看到对应的用户以及用户config.xml配置文件）

![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba664bf34a6c?w=1179&h=458&f=png&s=67713)
5、Continue，进入首页，点击"系统管理" -> "管理插件" --> "可选插件" --> "右上角过滤ssh" --> "选择Publish Over SSH" --> 点击"直接安装" (此插件用作ssh登陆)
![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba7307c31f53?w=1152&h=332&f=png&s=131089)
6、回到首页，点击"系统管理" --> "系统设置" --> 拉到最下面找到 "Publish over SSH" , 设置服务器的SSH信息
- 此处有两种设置方式，第一种是利用宿主机user和password登陆，配置如下：

  Passphrase项 为登陆宿主机password

  Name项 随意配置

  Hostname项 为宿主机ip

  Username项 为登陆宿主机username

  Remote Directory项 为配置宿主机工作目录


![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba8a3ee1f159?w=1408&h=782&f=png&s=54219)
- 配置Rsa免密登陆

  1、先在宿主机和容器中配置Rsa密钥

  ```shell
  # 新建 .ssh/authorized_keys文件 .ssh目录的权限设为700 .ssh/authorized_keys文件权限设为600
  $ mkdir ~/.ssh -m 7000 && cd ~/.ssh && touch authorized_keys
  # 从宿主机客户端进入我们刚启动的jenkins容器，目前容器名myjenkins，也可通过docker ps命令查看
  $ docker exec -it myjenkins /bin/bash
  # 进入容器后建立.ssh目录，创建密钥文件私钥id_rsa，公钥id_rsa.pub
  $ mkdir ~/.ssh && cd ~/.ssh 
  $ ssh-keygen -t rsa
  # 一直回车即可
  
  #将公钥拷贝到authorized_keys文件
  $ cat id_rsa.pub >> authorized_keys 
  # 将生成的authorized_keys拷贝到要连接的linux机器上的对应用户下的.ssh/authorized_keys文件
  	# root@116.62.189.37 root为登陆linux机器用户名，116.62.189.37为ip，此操作提示需要密码
  	# /root/.ssh/authorized_keys为linux机器上我们刚新建的.ssh/authorized_keys文件
  $ scp authorized_keys root@116.62.189.37:/root/.ssh/authorized_keys
  # 在此linux机器上的配置文件/etc/ssh/sshd_config,找到以下内容,并去掉注释符"#",没有则加上
  RSAAuthentication yes
  PubkeyAuthentication yes
  AuthorizedKeyFiles .ssh/authorized_keys # 默认公钥存放的位置
  StrictModes no
  # 退出容器
  $ exit 
  # 使配置生效
  $ service sshd restart
  ```

  2、在jenkins中配置ssh

  ​      Parh to key项 此路径为我们上一步在myjenkins容器中生成的id_rsa路径

  ​      Name项 随意配置

  ​      Hostname项 为宿主机ip

  ​      Username项 为登陆宿主机username

  ​      Remote Directory项 为配置宿主机工作目录


![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba8d5acdd6bb?w=1397&h=753&f=png&s=52444)
> 这两种方式选其一即可，配置完后可点击右下角Test Configuration验证配置是否正确,
>
> 亦可在容器中执行ssh -i ~/.ssh/id_rsa root@116.62.189.37
>
> 如果验证失败，可在linux机器var/log/secure文件中检查日志

7、回到首页，点击左上角“新建” --> "填写项目名称即可" --> "配置源码管理"： 填写项目地址(如果Git项目为私有项目，则需要点击Add添加你的Git账号，完成之后在这里选择你的Git账号)，附上我的sample地址 https://github.com/xiyoung/test-jenkins.git
![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba925e62a9c6?w=1158&h=707&f=png&s=173487)

--> 配置构建环境
![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba95c0fae8ba?w=1183&h=748&f=png&s=76311)

图中代码为
```shell
sudo docker stop testJenkinsNode || true \
     && sudo docker rm testJenkinsNode || true \
     && cd /var/jenkins_home/workspace/test-jenkins-node \
     && sudo docker build --rm --no-cache=true  -t test-jenkins-node:latest . \
     && sudo docker run -d  --name testJenkinsNode -p 3000:3000 test-jenkins-node:latest
```

8、保存后回到首页，选择刚刚创建的项目，点击"立即构建" -->"构建历史" --> "构建标签" --> "控制台输出" 可以看到构建日志
![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba9890046489?w=1271&h=566&f=png&s=84395)完成后在连接到的linux服务器上/var/jenkins_home/workspace/目录下会看到我们在Git上的项目( https://github.com/xiyoung/test-jenkins.git)

9、若构建成功且容器启动成功，浏览器输入116.62.189.37:3000应该能看到下图内容


![](https://user-gold-cdn.xitu.io/2018/11/16/1671ba9a5060f82e?w=676&h=391&f=png&s=24691)
> 注意两个步骤：
>
> ​	第9步配置ssh，建议用第一种方式
>
> ​	第10步配置构建环境的Exec command得细心，此配置是结合我个人sample的Dockerfile文件写的

#### 四、常用简单命令

```shell
	docker ps # 查看当前正在运行的容器

 	docker ps -a # 查看所有容器的状态

 	docker start/stop id/name # 启动/停止某个容器

 	docker attach id # 进入某个容器(使用exit退出后容器也跟着停止运行)

 	docker exec -ti id # 启动一个伪终端以交互式的方式进入某个容器（使用exit退出后容器不停止运行）

 	docker images/image ls # 查看本地所有镜像

 	docker rm id/name # 删除某个容器

 	docker rmi id/name # 删除某个镜像

 	docker run --name test -ti ubuntu /bin/bash  # 复制ubuntu容器并且重命名为test且运行，然	后以伪终端交互式方式进入容器，运行bash

 	docker build -t test-jenkins-node .  #通过当前目录下的Dockerfile创建一个名为test-		       jenkins-node的镜像

 	docker run -d -p 2222:22 --name test-jenkins-node test-jenkins-node:latest  # 以镜像     test-jenkins-node:latest创建名为test-jenkins-node的容器，并以后台模式运行，并做端口映射到主     机2222端口，P参数重启容器宿主机端口会发生改变
```
##### 五、目标

> **搭建类似于阿里云的自动化云效工作流水线**

![](https://user-gold-cdn.xitu.io/2018/11/16/1671bc90aa8417c3?w=1221&h=394&f=png&s=46407)