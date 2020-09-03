OBJS = src/lkcp.o 3rd/kcp/ikcp.o
LIBS = lkcp.so
INCLUDE = -I3rd/kcp

include ../common.mk
