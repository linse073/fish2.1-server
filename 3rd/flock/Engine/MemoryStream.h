#ifndef __MEMORY_STREAM_H__
#define __MEMORY_STREAM_H__

#include <stdint.h>
#include <vector>
#include <cstring>
#include <ctype.h>
#include "KBECommon.h"

namespace MemoryStreamConverter
{
	template <class T> 
	void swap(T& a, T& b)
	{
		T c(a); a = b; b = c;
	}

	template<size_t T>
	inline void convert(char *val)
	{
		swap(*val, *(val + T - 1));
		convert<T - 2>(val + 1);
	}

	template<> inline void convert<0>(char *) {}
	template<> inline void convert<1>(char *) {}            // ignore central byte

	template<typename T> inline void apply(T *val)
	{
		convert<sizeof(T)>((char *)(val));
	}

	inline void convert(char *val, size_t size)
	{
		if (size < 2)
			return;

		swap(*val, *(val + size - 1));
		convert(val + 1, size - 2);
	}
}

namespace KBEngine
{

template<typename T> inline void EndianConvert(T& val) 
{ 
	// if(!FGenericPlatformProperties::IsLittleEndian())
	// 	MemoryStreamConverter::apply<T>(&val); 
}

template<typename T> inline void EndianConvertReverse(T& val) 
{
	// if (FGenericPlatformProperties::IsLittleEndian())
	// 	MemoryStreamConverter::apply<T>(&val);
}

template<typename T> void EndianConvert(T*);         // will generate link error
template<typename T> void EndianConvertReverse(T*);  // will generate link error

inline void EndianConvert(uint8_t&) { }
inline void EndianConvert(int8_t&) { }
inline void EndianConvertReverse(uint8_t&) { }
inline void EndianConvertReverse(int8_t&) { }

/*
	二进制数据流模块
	能够将一些基本类型序列化(writeXXX)成二进制流同时也提供了反序列化(readXXX)等操作
*/
class MemoryStream
{
public:
	const static size_t DEFAULT_SIZE = 0x100;
	const static size_t MAX_SIZE = 10000000;

	MemoryStream() :
		rpos_(0), 
		wpos_(0)
	{
		data_resize(DEFAULT_SIZE);
	}

	virtual ~MemoryStream()
	{
		clear(false);
	}

public:
	uint8_t* data() {
		return data_.data();
	}

	const std::vector<uint8_t>& raw_data() const {
		return data_;
	}

	void clear(bool clearData)
	{
		if (clearData)
			data_.clear();

		rpos_ = wpos_ = 0;
	}

	// array的大小
	virtual uint32_t size() const { return data_.size(); }

	// array是否为空
	virtual bool empty() const { return data_.empty(); }

	// 读索引到与写索引之间的长度
	virtual uint32_t length() const { return rpos() >= wpos() ? 0 : wpos() - rpos(); }

	// 剩余可填充的大小
	virtual uint32_t space() const { return wpos() >= size() ? 0 : size() - wpos(); }

	// 将读索引强制设置到写索引，表示操作结束
	void done() { read_skip(length()); }

	void data_resize(uint32_t newsize)
	{
		KBE_ASSERT(newsize <= MAX_SIZE);
		data_.resize(newsize);
	}

	void resize(uint32_t newsize)
	{
		KBE_ASSERT(newsize <= MAX_SIZE);
		data_.resize(newsize);
		rpos_ = 0;
		wpos_ = size();
	}

	void reserve(uint32_t ressize)
	{
		KBE_ASSERT(ressize <= MAX_SIZE);
		if (ressize > size())
			data_.reserve(ressize);
	}

	uint32_t rpos() const { return rpos_; }

	uint32_t rpos(int rpos)
	{
		if (rpos < 0)
			rpos = 0;

		rpos_ = rpos;
		return rpos_;
	}

	uint32_t wpos() const { return wpos_; }

	uint32_t wpos(int wpos)
	{
		if (wpos < 0)
			wpos = 0;

		wpos_ = wpos;
		return wpos_;
	}

	uint8_t operator[](uint32_t pos)
	{
		return read<uint8_t>(pos);
	}

	MemoryStream &operator<<(uint8_t value)
	{
		append<uint8_t>(value);
		return *this;
	}

	MemoryStream &operator<<(uint16_t value)
	{
		append<uint16_t>(value);
		return *this;
	}

	MemoryStream &operator<<(uint32_t value)
	{
		append<uint32_t>(value);
		return *this;
	}

	MemoryStream &operator<<(uint64_t value)
	{
		append<uint64_t>(value);
		return *this;
	}

	MemoryStream &operator<<(int8_t value)
	{
		append<int8_t>(value);
		return *this;
	}

	MemoryStream &operator<<(int16_t value)
	{
		append<int16_t>(value);
		return *this;
	}

	MemoryStream &operator<<(int32_t value)
	{
		append<int32_t>(value);
		return *this;
	}

	MemoryStream &operator<<(int64_t value)
	{
		append<int64_t>(value);
		return *this;
	}

	MemoryStream &operator<<(float value)
	{
		append<float>(value);
		return *this;
	}

	MemoryStream &operator<<(double value)
	{
		append<double>(value);
		return *this;
	}

	MemoryStream &operator<<(const char *str)
	{
		append((uint8_t const *)str, str ? strlen(str) : 0);
		append((uint8_t)0);
		return *this;
	}

	MemoryStream &operator<<(bool value)
	{
		append<int8_t>(value);
		return *this;
	}

	MemoryStream &operator>>(bool &value)
	{
		value = read<char>() > 0 ? true : false;
		return *this;
	}

	MemoryStream &operator>>(uint8_t &value)
	{
		value = read<uint8_t>();
		return *this;
	}

	MemoryStream &operator>>(uint16_t &value)
	{
		value = read<uint16_t>();
		return *this;
	}

	MemoryStream &operator>>(uint32_t &value)
	{
		value = read<uint32_t>();
		return *this;
	}

	MemoryStream &operator>>(uint64_t &value)
	{
		value = read<uint64_t>();
		return *this;
	}

	MemoryStream &operator>>(int8_t &value)
	{
		value = read<int8_t>();
		return *this;
	}

	MemoryStream &operator>>(int16_t &value)
	{
		value = read<int16_t>();
		return *this;
	}

	MemoryStream &operator>>(int32_t &value)
	{
		value = read<int32_t>();
		return *this;
	}

	MemoryStream &operator>>(int64_t &value)
	{
		value = read<int64_t>();
		return *this;
	}

	MemoryStream &operator>>(float &value)
	{
		value = read<float>();
		return *this;
	}

	MemoryStream &operator>>(double &value)
	{
		value = read<double>();
		return *this;
	}

	MemoryStream &operator>>(char *value)
	{
		while (length() > 0)
		{
			char c = read<char>();
			if (c == 0 || !isascii(c))
				break;

			*(value++) = c;
		}

		*value = '\0';
		return *this;
	}

	template<typename T>
	void read_skip() { read_skip(sizeof(T)); }

	void read_skip(uint32_t skip)
	{
		KBE_ASSERT(skip <= length());
		rpos_ += skip;
	}

	template <typename T> T read()
	{
		T r = read<T>(rpos_);
		rpos_ += sizeof(T);
		return r;
	}

	template <typename T> T read(uint32_t pos) 
	{
		KBE_ASSERT(sizeof(T) <= length());

		T val;
		memcpy((void*)&val, (data() + pos), sizeof(T));

		EndianConvertReverse(val);
		return val;
	}

	void read(uint8_t *dest, uint32_t len)
	{
		KBE_ASSERT(len <= length());

		memcpy(dest, data() + rpos_, len);
		rpos_ += len;
	}

	int8_t readInt8()
	{
		return read<int8_t>();
	}

	int16_t readInt16()
	{
		return read<int16_t>();
	}
		
	int32_t readInt32()
	{
		return read<int32_t>();
	}

	int64_t readInt64()
	{
		return read<int64_t>();
	}
	
	uint8_t readUint8()
	{
		return read<uint8_t>();
	}

	uint16_t readUint16()
	{
		return read<uint16_t>();
	}

	uint32_t readUint32()
	{
		return read<uint32_t>();
	}
	
	uint64_t readUint64()
	{
		return read<uint64_t>();
	}
	
	float readFloat()
	{
		return read<float>();
	}

	double readDouble()
	{
		return read<double>();
	}
	
	std::vector<uint8_t> readBlob()
	{
		std::vector<uint8_t> datas;
		readBlob(datas);
		return datas;
	}

	uint32_t readBlob(std::vector<uint8_t>& datas)
	{
		if (length() <= 0)
			return 0;

		uint32_t rsize = 0;
		(*this) >> rsize;
		if ((uint32_t)rsize > length())
			return 0;

		if (rsize > 0)
		{
			datas.resize(rsize);
			memcpy(datas.data(), data() + rpos(), rsize);
			read_skip(rsize);
		}

		return rsize;
	}

	template <typename T> void append(T value)
	{
		EndianConvertReverse(value);
		append((uint8_t *)&value, sizeof(value));
	}

	template<class T> void append(const T *src, uint32_t cnt)
	{
		return append((const uint8_t *)src, cnt * sizeof(T));
	}

	void append(const uint8_t *src, uint32_t cnt)
	{
		if (!cnt)
			return;

		KBE_ASSERT(size() < 10000000);

		if (size() < wpos_ + cnt)
			data_resize(wpos_ + cnt);

		memcpy((void*)&data()[wpos_], src, cnt);
		wpos_ += cnt;
	}

	void append(const uint8_t* datas, uint32_t offset, uint32_t size)
	{
		append(datas + offset, size);
	}

	void append(MemoryStream& stream)
	{
		wpos(stream.wpos());
		rpos(stream.rpos());
		data_resize(stream.size());
		memcpy(data(), stream.data(), stream.size());
	}

	void appendBlob(const std::vector<uint8_t>& datas)
	{
		uint32_t len = (uint32_t)datas.size();
		(*this) << len;

		if (len > 0)
			append(datas.data(), len);
	}

	void writeInt8(int8_t v)
	{
		(*this) << v;
	}
	
	void writeInt16(int16_t v)
	{	
		(*this) << v;
	}
			
	void writeInt32(int32_t v)
	{
		(*this) << v;
	}
	
	void writeInt64(int64_t v)
	{
		(*this) << v;
	}
	
	void writeUint8(uint8_t v)
	{
		(*this) << v;
	}
	
	void writeUint16(uint16_t v)
	{
		(*this) << v;
	}
			
	void writeUint32(uint32_t v)
	{
		(*this) << v;
	}
	
	void writeUint64(uint64_t v)
	{
		(*this) << v;
	}
		
	void writeFloat(float v)
	{
		(*this) << v;
	}
	
	void writeDouble(double v)
	{
		(*this) << v;
	}
	
	void writeBlob(const std::vector<uint8_t>& datas)
	{
		appendBlob(datas);
	}

protected:
	uint32_t rpos_;
	uint32_t wpos_;

	std::vector<uint8_t> data_;
};

template<>
inline void MemoryStream::read_skip<char*>()
{
	uint8_t temp = 1;
	while (temp != 0)
		temp = read<uint8_t>();
}

template<>
inline void MemoryStream::read_skip<char const*>()
{
	read_skip<char*>();
}

}

#endif // __MEMORY_STREAM_H__