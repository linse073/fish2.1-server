SRCS	= $(wildcard ./*.cpp)
SRCS	+= $(wildcard ./Asset/*.cpp)
SRCS	+= $(wildcard ./Bullet/*.cpp)
SRCS	+= $(wildcard ./Engine/*.cpp)
SRCS	+= $(wildcard ./FixedPoint/*.cpp)
SRCS	+= $(wildcard ./Flocking/*.cpp)
SRCS	+= $(wildcard ./Flocking/Behavior/*.cpp)
SRCS	+= $(wildcard ./Flocking/Shap/*.cpp)
OBJS	= $(patsubst ./%.cpp, ./%.o, $(SRCS))
INCS	= -IAsset
INCS	+= -IBullet
INCS	+= -IEngine
INCS	+= -IFixedPoint
INCS	+= -IFlocking
INCS	+= -IFlocking/Behavior
INCS	+= -IFlocking/Shap
LIBS 	= lflock.so

include ../cpp_common.mk