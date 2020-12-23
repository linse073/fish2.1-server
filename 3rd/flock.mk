SRCS	= $(wildcard *.cpp)
SRCS	+= $(wildcard Asset/*.cpp)
SRCS	+= $(wildcard Bullet/*.cpp)
SRCS	+= $(wildcard Engine/*.cpp)
SRCS	+= $(wildcard FixedPoint/*.cpp)
SRCS	+= $(wildcard Flocking/*.cpp)
SRCS	+= $(wildcard Flocking/Behavior/*.cpp)
SRCS	+= $(wildcard Flocking/Shap/*.cpp)
SRCS	+= $(wildcard Flocking/Pilot/*.cpp)
OBJS	= $(patsubst %.cpp, %.o, $(SRCS))
INCLUDE	= -IAsset
INCLUDE	+= -IBullet
INCLUDE	+= -IEngine
INCLUDE	+= -IFixedPoint
INCLUDE	+= -IFlocking
INCLUDE	+= -IFlocking/Behavior
INCLUDE	+= -IFlocking/Shap
INCLUDE	+= -IFlocking/Pilot
LIBS 	= lflock.so

include ../cpp_common.mk