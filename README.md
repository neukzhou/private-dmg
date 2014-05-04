private-dmg
===========

可以创建带密码的dmg文件，并且可以修改.dmg文件的密码、向其中添加文件，适合保存敏感文件。

你有不想告人的秘密么？

你有敏感材料需要进行加密么？

你已经厌烦每存一个敏感文件就需要重新加密了么？

那么这个脚本你值得拥有！


## 用法

首先给脚本设置权限：

  chmod a+x private-dmg.sh
  
执行脚本：
  
- 创建.dmg文件：

  ./private-dmg.sh create <image-name> <dest directory/file>
  
- 添加文件：

  ./private-dmg.sh add <image-name> <file/directory>
  
- 修改密码：

  ./private-dmg.sh chpass <image-name>

## Todo list
当前版本：
1.0.0

目前还有几个问题需要解决：

1. 重复添加同一个文件，.dmg文件大小会变大（文件并不会复制多份）；

2. 文件过大时速度太慢（可能无法解决）；  

3. 尚存在几个小bug。
