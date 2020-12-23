#Makefile

#自定义变量
CC		= g++
#编译选项，生成所有警告、不优化、采用c++11标准、输出调试信息、只编译并生成目标文件
CFLAGS	= -Wall -O0 -std=c++17 -g -c -fPIC --shared
BFLAGS	= -Wall -O0 -std=c++17 -g -fPIC --shared
#wildcard为Makefile模式匹配关键字，获取目标目录符合匹配模式的所有文件名
SRCS	= $(wildcard *.cpp)
SRCS	+= $(wildcard Asset/*.cpp)
SRCS	+= $(wildcard Bullet/*.cpp)
SRCS	+= $(wildcard Engine/*.cpp)
SRCS	+= $(wildcard FixedPoint/*.cpp)
SRCS	+= $(wildcard Flocking/*.cpp)
SRCS	+= $(wildcard Flocking/Behavior/*.cpp)
SRCS	+= $(wildcard Flocking/Shap/*.cpp)
SRCS	+= $(wildcard Flocking/Pilot/*.cpp)
#patsubst为Makefile模式替换关键字，查找字符串SRCS中按空格分开的单词，并将符合模式%.cpp的字符串全部替换成%.o
OBJS	= $(patsubst %.cpp, %.o, $(SRCS))
INCS	= -IAsset
INCS	+= -IBullet
INCS	+= -IEngine
INCS	+= -IFixedPoint
INCS	+= -IFlocking
INCS	+= -IFlocking/Behavior
INCS	+= -IFlocking/Shap
INCS	+= -IFlocking/Pilot
INCS	+= -Ilua
SOS		= lflock.so
RM		= rm -f

C_CC		= gcc
C_CFLAGS	= -Wall -O0 -g -c -fPIC --shared
C_SRCS 		= $(filter-out lua/lua.c lua/luac.c, $(wildcard lua/*.c))
C_OBJS		= $(patsubst %.c, %.o, $(C_SRCS))
C_INCS		= -Ilua

#伪目标，声明clean为伪目标或标签，为了避免该清理任务与文件名相同而被错识别
.PHONY: clean all

#默认任务
all: $(SOS)
#默认任务要执行的命令，按上面的变量名替换为变量值后执行，前面必须有一个Tab符

#模式匹配,冒号前者为目标项，冒号后面为依赖项
$(SOS): $(OBJS) $(C_OBJS)
#$^表示规则中所有的依赖项，$@表示规则中的目标
	$(CC) $(BFLAGS) $^ -o $@

# %模式自动匹配符
%.o: %.cpp
# $<表示规则中的第一个依赖项
	$(CC) $(CFLAGS) $(INCS) $< -o $@

%.o: %.c
	$(C_CC) $(C_CFLAGS) $(C_INCS) $< -o $@

clean:
#清理之前的目标文件，以便下次完整的重新编译
	$(RM) $(OBJS) $(SOS) $(C_OBJS)