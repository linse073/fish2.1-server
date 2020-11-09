SRCS	= $(wildcard ./*.cpp)
SRCS	+= $(wildcard ./Asset/*.cpp)
SRCS	+= $(wildcard ./Bullet/*.cpp)
SRCS	+= $(wildcard ./Engine/*.cpp)
SRCS	+= $(wildcard ./FixedPoint/*.cpp)
SRCS	+= $(wildcard ./Flocking/*.cpp)
SRCS	+= $(wildcard ./Flocking/Behavior/*.cpp)
SRCS	+= $(wildcard ./Flocking/Shap/*.cpp)
OBJS	= $(patsubst ./%.cpp, ./%.o, $(SRCS))
INCS	= -I./Asset
INCS	+= -I./Bullet
INCS	+= -I./Engine
INCS	+= -I./FixedPoint
INCS	+= -I./Flocking
INCS	+= -I./Flocking/Behavior
INCS	+= -I./Flocking/Shap
LIBS 	= lflock.so

include ../cpp_common.mk