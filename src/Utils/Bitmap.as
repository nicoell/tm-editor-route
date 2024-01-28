namespace Bitmap
{
class BitmapV4Header
{
	private uint16 BFH_Signature        = 0x4D42;
	private uint32 BFH_FileSize;
	private uint32 BFH_Reserved         = 0;
	private uint32 BFH_DataOffset       = 14 + 108;

	private uint32 BV4_Size             = 108;
	private int32  BV4_Width;
	private int32  BV4_Height;
	private int16  BV4_Planes           = 1;
	private int16  BV4_BitCount;
	private uint32 BV4_Compression      = 3;
	private uint32 BV4_SizeImage;
	private int32  BV4_XPelsPerMeter    = 0;
	private int32  BV4_YPelsPerMeter    = 0;
	private uint32 BV4_ClrUsed          = 0;
	private uint32 BV4_ClrImportant     = 0;
	private uint32 BV4_RedMask          = 0x000000FF;
	private uint32 BV4_GreenMask        = 0x0000FF00;
	private uint32 BV4_BlueMask         = 0x00FF0000;
	private uint32 BV4_AlphaMask        = 0xFF000000;
	private uint32 BV4_CSType           = 0x206E6957; // Win
	private int32  BV4_CIE_RedX         = 0;
	private int32  BV4_CIE_RedY         = 0;
	private int32  BV4_CIE_RedZ         = 0;
	private int32  BV4_CIE_GreenX       = 0;
	private int32  BV4_CIE_GreenY       = 0;
	private int32  BV4_CIE_GreenZ       = 0;
	private int32  BV4_CIE_BlueX        = 0;
	private int32  BV4_CIE_BlueY        = 0;
	private int32  BV4_CIE_BlueZ        = 0;
	private uint32 BV4_GammaRed         = 0;
	private uint32 BV4_GammaGreen       = 0;
	private uint32 BV4_GammaBlue        = 0;

	BitmapV4Header() {}
	BitmapV4Header(uint32 width, uint32 height, uint32 bitsPerPixel) { Init(width, height, bitsPerPixel); }
	void Init(int32 width, int32 height, uint32 bitsPerPixel)
	{
		if (width < 0) { warn("Negative Width ignored. Using absolute value.");}
		if (bitsPerPixel != 16 && bitsPerPixel != 32) { error("Only 16, 32 Bits per Pixel supported. Got " + bitsPerPixel + ". Fallback to 16."); bitsPerPixel = 16; }

		if (bitsPerPixel == 16) 
		{
			BV4_RedMask   = 0x000F;
			BV4_GreenMask = 0x00F0;
			BV4_BlueMask  = 0x0F00;
			BV4_AlphaMask = 0xF000;
		}

		BV4_Width = Math::Abs(width); // Width cannot be negative afaik
		BV4_Height = height; // Height can be negative for top-down images
		BV4_BitCount = bitsPerPixel;
		BV4_SizeImage = GetRowSizeInBytes() * Math::Abs(BV4_Height);
		BFH_FileSize = BV4_SizeImage + BFH_DataOffset;
	}

	uint32 GetRowSizeInBytes() const { return uint32(Math::Ceil((BV4_BitCount * BV4_Width)/32) * 4); }
	uint32 GetImageSizeInBytes() const { return BV4_SizeImage; }
	uint32 GetFileSizeInBytes() const { return BFH_FileSize; }
	uint32 GetDataOffsetInBytes() const { return BFH_DataOffset; }
	int32 GetWidth() const { return BV4_Width; }
	int32 GetHeight() const { return BV4_Height; }
	uint32 GetBitsPerPixel() const { return BV4_BitCount; }

	void WriteToBuffer(MemoryBuffer@ buf)
	{
		buf.Resize(buf.GetSize() + BFH_DataOffset);

		buf.Write(BFH_Signature);
		buf.Write(BFH_FileSize);
		buf.Write(BFH_Reserved);
		buf.Write(BFH_DataOffset);
		buf.Write(BV4_Size);
		buf.Write(BV4_Width);
		buf.Write(BV4_Height);
		buf.Write(BV4_Planes);
		buf.Write(BV4_BitCount);
		buf.Write(BV4_Compression);
		buf.Write(BV4_SizeImage);
		buf.Write(BV4_XPelsPerMeter);
		buf.Write(BV4_YPelsPerMeter);
		buf.Write(BV4_ClrUsed);
		buf.Write(BV4_ClrImportant);
		buf.Write(BV4_RedMask);
		buf.Write(BV4_GreenMask);
		buf.Write(BV4_BlueMask);
		buf.Write(BV4_AlphaMask);
		buf.Write(BV4_CSType);
		buf.Write(BV4_CIE_RedX);
		buf.Write(BV4_CIE_RedY);
		buf.Write(BV4_CIE_RedZ);
		buf.Write(BV4_CIE_GreenX);
		buf.Write(BV4_CIE_GreenY);
		buf.Write(BV4_CIE_GreenZ);
		buf.Write(BV4_CIE_BlueX);
		buf.Write(BV4_CIE_BlueY);
		buf.Write(BV4_CIE_BlueZ);
		buf.Write(BV4_GammaRed);
		buf.Write(BV4_GammaGreen);
		buf.Write(BV4_GammaBlue);
	}
	void ReadFromBuffer(MemoryBuffer@ buf)
	{
		BFH_Signature = buf.ReadUInt16();
		BFH_FileSize = buf.ReadUInt32();
		BFH_Reserved = buf.ReadUInt32();
		BFH_DataOffset = buf.ReadUInt32();
		BV4_Size = buf.ReadUInt32();
		BV4_Width = buf.ReadInt32();
		BV4_Height = buf.ReadInt32();
		BV4_Planes = buf.ReadInt16();
		BV4_BitCount = buf.ReadInt16();
		BV4_Compression = buf.ReadUInt32();
		BV4_SizeImage = buf.ReadUInt32();
		BV4_XPelsPerMeter = buf.ReadInt32();
		BV4_YPelsPerMeter = buf.ReadInt32();
		BV4_ClrUsed = buf.ReadUInt32();
		BV4_ClrImportant = buf.ReadUInt32();
		BV4_RedMask = buf.ReadUInt32();
		BV4_GreenMask = buf.ReadUInt32();
		BV4_BlueMask = buf.ReadUInt32();
		BV4_AlphaMask = buf.ReadUInt32();
		BV4_CSType = buf.ReadUInt32();
		BV4_CIE_RedX = buf.ReadInt32();
		BV4_CIE_RedY = buf.ReadInt32();
		BV4_CIE_RedZ = buf.ReadInt32();
		BV4_CIE_GreenX = buf.ReadInt32();
		BV4_CIE_GreenY = buf.ReadInt32();
		BV4_CIE_GreenZ = buf.ReadInt32();
		BV4_CIE_BlueX = buf.ReadInt32();
		BV4_CIE_BlueY = buf.ReadInt32();
		BV4_CIE_BlueZ = buf.ReadInt32();
		BV4_GammaRed = buf.ReadUInt32();
		BV4_GammaGreen = buf.ReadUInt32();
		BV4_GammaBlue = buf.ReadUInt32();
	}
	string ToString()
	{
		string ret;
		ret += "\nBitmapV4Header:\n";
		ret += DebugFormat("BFH_Signature", BFH_Signature);
		ret += DebugFormat("BFH_FileSize", BFH_FileSize);
		ret += DebugFormat("BFH_Reserved", BFH_Reserved);
		ret += DebugFormat("BFH_DataOffset", BFH_DataOffset);
		ret += DebugFormat("BV4_Size", BV4_Size);
		ret += DebugFormat("BV4_Width", BV4_Width);
		ret += DebugFormat("BV4_Height", BV4_Height);
		ret += DebugFormat("BV4_Planes", BV4_Planes);
		ret += DebugFormat("BV4_BitCount", BV4_BitCount);
		ret += DebugFormat("BV4_Compression", BV4_Compression);
		ret += DebugFormat("BV4_SizeImage", BV4_SizeImage);
		ret += DebugFormat("BV4_XPelsPerMeter", BV4_XPelsPerMeter);
		ret += DebugFormat("BV4_YPelsPerMeter", BV4_YPelsPerMeter);
		ret += DebugFormat("BV4_ClrUsed", BV4_ClrUsed);
		ret += DebugFormat("BV4_ClrImportant", BV4_ClrImportant);
		ret += DebugFormat("BV4_RedMask", BV4_RedMask);
		ret += DebugFormat("BV4_GreenMask", BV4_GreenMask);
		ret += DebugFormat("BV4_BlueMask", BV4_BlueMask);
		ret += DebugFormat("BV4_AlphaMask", BV4_AlphaMask);
		ret += DebugFormat("BV4_CSType", BV4_CSType);
		ret += DebugFormat("BV4_CIE_RedX", BV4_CIE_RedX);
		ret += DebugFormat("BV4_CIE_RedY", BV4_CIE_RedY);
		ret += DebugFormat("BV4_CIE_RedZ", BV4_CIE_RedZ);
		ret += DebugFormat("BV4_CIE_GreenX", BV4_CIE_GreenX);
		ret += DebugFormat("BV4_CIE_GreenY", BV4_CIE_GreenY);
		ret += DebugFormat("BV4_CIE_GreenZ", BV4_CIE_GreenZ);
		ret += DebugFormat("BV4_CIE_BlueX", BV4_CIE_BlueX);
		ret += DebugFormat("BV4_CIE_BlueY", BV4_CIE_BlueY);
		ret += DebugFormat("BV4_CIE_BlueZ", BV4_CIE_BlueZ);
		ret += DebugFormat("BV4_GammaRed", BV4_GammaRed);
		ret += DebugFormat("BV4_GammaGreen", BV4_GammaGreen);
		ret += DebugFormat("BV4_GammaBlue", BV4_GammaBlue);
		return ret;
	}
	string ToRawByteString()
	{
		string ret;
		ret += "\nBitmapV4Header RawBytes:\n";
		MemoryBuffer buf;
		WriteToBuffer(buf);
		buf.Seek(0);
		for(uint64 i = 0; i < BFH_DataOffset; i++)
		{
			ret += Text::Format("%02X", buf.ReadUInt8()) + " ";
		}
		ret += "\n";
		return ret;
	}
}

class Bitmap
{
	BitmapV4Header@ Header;
	MemoryBuffer@ Data;
	private uint32 XPos;
	private uint32 YPos;
	private uint32 RowSizeByte;
	private uint32 PixelSizeByte;

	Bitmap() {}
	Bitmap(int32 width, int32 height, uint32 bitsPerPixel) { Init(width, height, bitsPerPixel); }
	Bitmap(MemoryBuffer@ buf) 
	{
		@Header = BitmapV4Header();
		@Data = MemoryBuffer();
		ReadFromBuffer(buf);
	}
	void Init(int32 width, int32 height, uint32 bitsPerPixel)
	{
		@Header = BitmapV4Header(width, height, bitsPerPixel);
		RowSizeByte = Header.GetRowSizeInBytes();
		PixelSizeByte = Header.GetBitsPerPixel() / 8;

		@Data = MemoryBuffer(Header.GetFileSizeInBytes(), 0x0);
		Data.Seek(0);
		Header.WriteToBuffer(Data);
		SetPos(0, 0);
	}

	/** 
	 * Reads Bitmap Data from buffer. 
	 * CAREFUL: By far not all Bitmap formats are supported:
	 *  - Only BitmapV4Header can be loaded. 
	 *  - Optional Header Data is not loaded.
	 *  - Only 16/32 BitsPerPixel Data can be modified.
	 *  - Only predefined RGBA Channelmask are supported:
	 *      - BV4_RedMask   = (32Bits) 0x000000FF or (16Bits) 0x000F
	 *      - BV4_GreenMask = (32Bits) 0x0000FF00 or (16Bits) 0x00F0
	 *      - BV4_BlueMask  = (32Bits) 0x00FF0000 or (16Bits) 0x0F00
	 *      - BV4_AlphaMask = (32Bits) 0xFF000000 or (16Bits) 0xF000
	 */
	void ReadFromBuffer(MemoryBuffer@ buf)
	{
		Data.Resize(buf.GetSize());
		Data.WriteFromBuffer(buf, buf.GetSize());
		Data.Seek(0);
		Header.ReadFromBuffer(Data);
		Data.Resize(Header.GetFileSizeInBytes());
		SetPos(0, 0);
		
		RowSizeByte = Header.GetRowSizeInBytes();
		PixelSizeByte = Header.GetBitsPerPixel() / 8;
	}

	UI::Texture@ CreateUITexture() 
	{ 
		Data.Seek(0);
		Data.Resize(Header.GetFileSizeInBytes());
		auto texture = UI::LoadTexture(Data);
		SetPos(0, 0);
		return texture;
	}
	nvg::Texture@ CreateNanoVGTexture(int32 flags = 0) 
	{ 
		Data.Seek(0);
		Data.Resize(Header.GetFileSizeInBytes());
		auto texture = nvg::LoadTexture(Data, flags);
		SetPos(0, 0);
		return texture;
	}

	void MoveTo(uint32 x = 0, const uint32 y = 0)
	{
		SetPos(x, y);
	}

	void GetPos(uint32 &out x, uint32 &out y) { x = XPos; y = YPos; }

	void Write(const RGBAColor &in rgbaColor) { if (Header.GetBitsPerPixel() == 32) { Write32(rgbaColor); } else { Write16(rgbaColor); }}
	void Write(const uint8 r, const uint8 g, const uint8 b, const uint8 a) { if (Header.GetBitsPerPixel() == 32) { Write32(r, g, b, a); } else { Write16(r, g, b, a); }}
	void Write32(const RGBAColor &in rgbaColor)
	{
		Data.Write(rgbaColor.rgba);
		AdvancePos();
	}
	void Write32(const uint8 r, const uint8 g, const uint8 b, const uint8 a)
	{
		uint32 rgba = a << 24 | b << 16 | g << 8 | r;
		Data.Write(rgba);
		AdvancePos();
	}

	void Write16(const RGBAColor &in rgbaColor)
	{
		uint16 rgba = (rgbaColor.a >> 4) << 12 | (rgbaColor.b >> 4) << 8 | (rgbaColor.g >> 4) << 4 | (rgbaColor.r >> 4);
		Data.Write(rgba);
		AdvancePos();
	}
	void Write16(const uint8 r, const uint8 g, const uint8 b, const uint8 a)
	{
		uint16 rgba = (a >> 4) << 12 | (b >> 4) << 8 | (g >> 4) << 4 | (r >> 4);
		Data.Write(rgba);
		AdvancePos();
	}

	private void SetPos(uint32 x, uint32 y)
	{
		XPos = x; YPos = y;
		uint64 seek = Header.GetDataOffsetInBytes() + RowSizeByte * YPos + PixelSizeByte * XPos;
		Data.Seek(seek);
	}
	private void AdvancePos(uint32 pxDelta = 1)
	{
		int32 w = Header.GetWidth();
		XPos += pxDelta;
		int32 rowDelta = XPos / w;
		XPos -= rowDelta > 0 ? w : 0;
		YPos += rowDelta;
		uint64 seek = Header.GetDataOffsetInBytes() + RowSizeByte * YPos + PixelSizeByte * XPos;
		Data.Seek(seek);
	}

	string ToString()
	{
		string ret;
		ret += Header.ToString();
		ret += "\nPixelData (" + Header.GetBitsPerPixel() + "Bits Per Pixel):\n";
		SetPos(0, 0);
		int32 sizeInPx = Header.GetWidth() * Header.GetHeight();
		if (Header.GetBitsPerPixel() == 16)
		{
			for(int i = 0; i < sizeInPx; i++)
			{
				uint8 rg = Data.ReadUInt8();
				uint8 ba = Data.ReadUInt8();
				uint8 r = (rg & 0xF);
				uint8 g = (rg & 0xF0) >> 4;
				uint8 b = (ba & 0xF);
				uint8 a = (ba & 0xF0) >> 4;
				ret += "[" + XPos + "][" + YPos + "] = rgba (" + r + ", " + g + ", " + b + ", " + a + ")\n";
				AdvancePos();
			}
		}
		else 
		{
			for(int i = 0; i < sizeInPx; i++)
			{
				ret += "[" + XPos + "][" + YPos + "] = rgba (" + Data.ReadUInt8() + ", " + Data.ReadUInt8() + ", " + Data.ReadUInt8() + ", " + Data.ReadUInt8() + ")\n";
				AdvancePos();
			}
		}
		SetPos(0, 0);
		return ret;
	}

	string ToRawByteString()
	{
		string ret;
		ret += Header.ToRawByteString();
		ret += "\nPixelData RawBytes:\n";
		SetPos(0, 0);
		int32 sizeInBytes = RowSizeByte * Header.GetHeight();
		if (Header.GetBitsPerPixel() == 16)
		{
			for(int i = 0; i < sizeInBytes; i++)
			{
				uint8 data = Data.ReadUInt8();
				ret += Text::Format("%01X", data & 0xF);
				ret += Text::Format("%01X", (data & 0xF0) >> 4) + " ";
			}
		}
		else
		{
			for(int i = 0; i < sizeInBytes; i++)
			{
				ret += Text::Format("%02X", Data.ReadUInt8()) + " ";
			}
		}
		SetPos(0, 0);
		return ret;
	}
}

string DebugFormat(string &in name, uint16 i) 
{
	return Text::Format(Text::Format(name + ":\t %d", i) + "\t %04X\n", i);
}
string DebugFormat(string &in name, int16 i) 
{
	return Text::Format(Text::Format(name + ":\t %d", i) + "\t %04X\n", i);
}
string DebugFormat(string &in name, uint32 i) 
{
	return Text::Format(Text::Format(name + ":\t %d", i) + "\t %08X\n", i);
}
string DebugFormat(string &in name, int32 i) 
{
	return Text::Format(Text::Format(name + ":\t %d", i) + "\t %08X\n", i);
}
}